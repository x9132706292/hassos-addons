#!/usr/bin/env python3
"""
SSH Tunnel Manager for Home Assistant.

Поддерживает:
- несколько SSH туннелей;
- аутентификацию по паролю;
- аутентификацию по приватному ключу, вставленному текстом;
- passphrase для приватного ключа;
- local port forwarding: ssh -L;
- dynamic SOCKS proxy: ssh -D;
- комбинацию local + dynamic в одном SSH соединении;
- автопереподключение.
"""

import hashlib
import json
import os
import signal
import subprocess
import sys
import threading
import time
from pathlib import Path
from typing import Any, Optional

OPTIONS_PATH = Path("/data/options.json")
KEYS_DIR = Path("/data/ssh_keys")

ALLOWED_FORWARD_TYPES = {"local", "dynamic"}
ALLOWED_AUTH_TYPES = {"password", "key"}

# Регулярка для sshpass: ловим и password, и passphrase prompts.
SSHPASS_PROMPT_RE = r"[Pp]assword|[Pp]assphrase"


def log(message: str) -> None:
    print(message, flush=True)


class ConfigError(ValueError):
    """Ошибка конфигурации аддона."""


def load_tunnels_json() -> str:
    """
    Загружает список tunnels.

    Приоритет:
    1. JSON-аргумент командной строки, если он передан.
    2. /data/options.json, как в Home Assistant add-on.
    """

    if len(sys.argv) > 1:
        arg = sys.argv[1].strip()
        if arg.startswith("[") or arg.startswith("{"):
            try:
                data = json.loads(arg)
            except json.JSONDecodeError as exc:
                raise ConfigError(f"Некорректный JSON из argv: {exc}") from exc

            if isinstance(data, dict):
                tunnels = data.get("tunnels")
            elif isinstance(data, list):
                tunnels = data
            else:
                raise ConfigError("Ожидался список tunnels или объект с полем tunnels")

            if tunnels is None:
                tunnels = []

            if not isinstance(tunnels, list):
                raise ConfigError("Поле tunnels должно быть списком")

            return json.dumps(tunnels)

    if not OPTIONS_PATH.exists():
        log(f"Файл конфигурации {OPTIONS_PATH} не найден. Запускаюсь без туннелей.")
        return "[]"

    try:
        raw = OPTIONS_PATH.read_text(encoding="utf-8")
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise ConfigError(f"Некорректный JSON в {OPTIONS_PATH}: {exc}") from exc
    except OSError as exc:
        raise ConfigError(f"Не удалось прочитать {OPTIONS_PATH}: {exc}") from exc

    if isinstance(data, dict):
        tunnels = data.get("tunnels")
    elif isinstance(data, list):
        tunnels = data
    else:
        raise ConfigError("Ожидался объект с полем tunnels или список tunnels")

    if tunnels is None:
        tunnels = []

    if not isinstance(tunnels, list):
        raise ConfigError("Поле tunnels должно быть списком")

    return json.dumps(tunnels)


class SSHTunnelManager:
    def __init__(self, config_json: str):
        try:
            parsed = json.loads(config_json)
        except json.JSONDecodeError as exc:
            raise ConfigError(f"Некорректный JSON конфигурации tunnels: {exc}") from exc

        if not isinstance(parsed, list):
            raise ConfigError("Ожидается список tunnels")

        self.tunnels = parsed
        self.processes: dict[str, dict[str, Any]] = {}

    # ------------------------------------------------------------------ #
    #  Helpers
    # ------------------------------------------------------------------ #

    @staticmethod
    def _as_str(value: Any, default: str = "") -> str:
        if value is None:
            return default
        return str(value)

    @staticmethod
    def _as_bool(value: Any, default: bool = True) -> bool:
        if value is None:
            return default
        if isinstance(value, bool):
            return value
        if isinstance(value, str):
            return value.strip().lower() not in {"false", "0", "no", "off", ""}
        return bool(value)

    @staticmethod
    def _as_int(
        value: Any,
        field: str,
        minimum: int = 1,
        maximum: int = 65535,
    ) -> int:
        try:
            ivalue = int(value)
        except (TypeError, ValueError) as exc:
            raise ConfigError(f"Поле '{field}' должно быть числом") from exc

        if ivalue < minimum or ivalue > maximum:
            raise ConfigError(f"Поле '{field}' вне диапазона {minimum}-{maximum}")

        return ivalue

    def _normalize_forward_types(self, tunnel: dict[str, Any]) -> list[str]:
        """
        Нормализует forward_type.

        Поддерживает:
        - отсутствие поля => local;
        - строку => [строка];
        - список значений.
        """

        raw = tunnel.get("forward_type")

        if raw is None or raw == "":
            return ["local"]

        if isinstance(raw, str):
            raw = [raw]

        if not isinstance(raw, list):
            raise ConfigError("forward_type должен быть списком: local и/или dynamic")

        result: list[str] = []

        for item in raw:
            if item is None:
                continue

            value = str(item).strip().lower()
            if not value:
                continue

            if value not in ALLOWED_FORWARD_TYPES:
                raise ConfigError(
                    f"Недопустимый forward_type '{value}'. "
                    "Разрешены: local, dynamic"
                )

            if value not in result:
                result.append(value)

        return result or ["local"]

    def _prepare_tunnel(self, tunnel: dict[str, Any]) -> dict[str, Any]:
        """
        Валидирует и нормализует один туннель.
        """

        name = self._as_str(tunnel.get("name")).strip()
        if not name:
            raise ConfigError("Поле name обязательно")

        host = self._as_str(tunnel.get("host")).strip()
        user = self._as_str(tunnel.get("user")).strip()

        if not host:
            raise ConfigError(f"[{name}] Поле host обязательно")
        if not user:
            raise ConfigError(f"[{name}] Поле user обязательно")

        auth_type = self._as_str(tunnel.get("auth_type"), "password").strip().lower()
        if auth_type not in ALLOWED_AUTH_TYPES:
            raise ConfigError(f"[{name}] auth_type должен быть password или key")

        password = self._as_str(tunnel.get("password"))
        private_key = self._as_str(tunnel.get("private_key"))
        key_passphrase = self._as_str(tunnel.get("key_passphrase"))

        if auth_type == "password" and not password:
            raise ConfigError(
                f"[{name}] Для auth_type=password обязателен password"
            )

        if auth_type == "key" and not private_key.strip():
            raise ConfigError(
                f"[{name}] Для auth_type=key обязателен private_key"
            )

        forward_types = self._normalize_forward_types(tunnel)

        ssh_port_raw = tunnel.get("port")
        if ssh_port_raw is None or ssh_port_raw == "":
            ssh_port_raw = 22

        prepared: dict[str, Any] = {
            "name": name,
            "host": host,
            "user": user,
            "ssh_port": self._as_int(ssh_port_raw, "port"),
            "auth_type": auth_type,
            "password": password,
            "private_key": private_key,
            "key_passphrase": key_passphrase,
            "forward_types": forward_types,
            "auto_reconnect": self._as_bool(tunnel.get("auto_reconnect"), True),
        }

        # -------------------------------------------------------------- #
        #  Local forwarding: ssh -L local_port:remote_host:remote_port
        # -------------------------------------------------------------- #
        if "local" in forward_types:
            local_port_raw = tunnel.get("local_port")
            if local_port_raw is None or local_port_raw == "":
                raise ConfigError(
                    f"[{name}] Для local forwarding обязателен local_port"
                )

            remote_host = self._as_str(tunnel.get("remote_host")).strip()
            if not remote_host:
                raise ConfigError(
                    f"[{name}] Для local forwarding обязателен remote_host"
                )

            remote_port_raw = tunnel.get("remote_port")
            if remote_port_raw is None or remote_port_raw == "":
                raise ConfigError(
                    f"[{name}] Для local forwarding обязателен remote_port"
                )

            prepared["local_port"] = self._as_int(local_port_raw, "local_port")
            prepared["remote_host"] = remote_host
            prepared["remote_port"] = self._as_int(remote_port_raw, "remote_port")

        # -------------------------------------------------------------- #
        #  Dynamic forwarding: ssh -D [bind_address:]socks_port
        # -------------------------------------------------------------- #
        if "dynamic" in forward_types:
            socks_port_raw = tunnel.get("socks_port")

            # Удобство: если включён только dynamic, можно указать порт
            # в local_port вместо socks_port.
            if (
                (socks_port_raw is None or socks_port_raw == "")
                and forward_types == ["dynamic"]
            ):
                socks_port_raw = tunnel.get("local_port")

            if socks_port_raw is None or socks_port_raw == "":
                raise ConfigError(
                    f"[{name}] Для dynamic forwarding обязателен socks_port"
                )

            prepared["socks_port"] = self._as_int(socks_port_raw, "socks_port")
            prepared["socks_bind_address"] = self._as_str(
                tunnel.get("socks_bind_address")
            ).strip()

        return prepared

    @staticmethod
    def _port_numbers(prepared: dict[str, Any]) -> list[int]:
        """
        Возвращает список локальных портов, которые займёт туннель.
        """

        ports: list[int] = []

        if "local" in prepared["forward_types"]:
            ports.append(prepared["local_port"])

        if "dynamic" in prepared["forward_types"]:
            ports.append(prepared["socks_port"])

        return ports

    def _write_key_file(self, prepared: dict[str, Any]) -> Optional[str]:
        """
        Записывает приватный ключ из конфигурации в файл с правами 600.
        Возвращает путь к файлу.
        """

        raw_key = prepared.get("private_key", "")
        if not raw_key or not raw_key.strip():
            return None

        # Нормализуем переносы строк.
        # Также поддерживаем случай, если пользователь вставил literal \n.
        key_text = (
            raw_key.replace("\\r\\n", "\n")
            .replace("\\n", "\n")
            .replace("\r\n", "\n")
            .replace("\r", "\n")
        )

        # Убираем хвостовые пробелы в каждой строке.
        lines = [line.rstrip() for line in key_text.splitlines()]
        key_text = "\n".join(lines).strip() + "\n"

        safe_name = "".join(
            ch if ch.isalnum() or ch in "-_" else "_"
            for ch in prepared["name"]
        )

        digest = hashlib.sha256(
            prepared["name"].encode("utf-8")
        ).hexdigest()[:8]

        KEYS_DIR.mkdir(parents=True, exist_ok=True)
        KEYS_DIR.chmod(0o700)

        key_path = KEYS_DIR / f"{safe_name}_{digest}_id"

        key_path.write_text(key_text, encoding="utf-8")
        key_path.chmod(0o600)

        log(f"[{prepared['name']}] Приватный ключ записан в {key_path}")
        return str(key_path)

    @staticmethod
    def _socks_spec(prepared: dict[str, Any]) -> str:
        """
        Формирует аргумент для ssh -D.

        Примеры:
          1080
          127.0.0.1:1080
          0.0.0.0:1080
          [::1]:1080
        """

        port = prepared["socks_port"]
        bind = prepared.get("socks_bind_address", "").strip()

        if bind in {"*", "all", "any"}:
            bind = "0.0.0.0"

        if not bind:
            return str(port)

        # IPv6 адрес нужно оборачивать в квадратные скобки.
        if ":" in bind and not bind.startswith("["):
            bind = f"[{bind}]"

        return f"{bind}:{port}"

    def _build_ssh_command(
        self,
        prepared: dict[str, Any],
        key_file: Optional[str],
    ) -> list[str]:
        """
        Собирает команду SSH.

        Важно: все опции ssh должны идти до destination user@host.
        """

        base = [
            "ssh",
            "-N",
            "-T",
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-o", "ConnectTimeout=15",
            "-o", "ServerAliveInterval=30",
            "-o", "ServerAliveCountMax=3",
            "-o", "ExitOnForwardFailure=yes",
            "-o", "NumberOfPasswordPrompts=1",
        ]

        # -------------------------------------------------------------- #
        #  Authentication
        # -------------------------------------------------------------- #
        if prepared["auth_type"] == "password":
            base.extend([
                "-o", "PreferredAuthentications=password,keyboard-interactive",
                "-o", "PubkeyAuthentication=no",
            ])
        else:
            if not key_file:
                raise ConfigError(
                    f"[{prepared['name']}] Не удалось подготовить файл ключа"
                )

            base.extend([
                "-o", "PreferredAuthentications=publickey",
                "-o", "PubkeyAuthentication=yes",
                "-i", key_file,
            ])

        # -------------------------------------------------------------- #
        #  Forwarding
        # -------------------------------------------------------------- #
        if "local" in prepared["forward_types"]:
            base.extend([
                "-L",
                (
                    f"{prepared['local_port']}:"
                    f"{prepared['remote_host']}:"
                    f"{prepared['remote_port']}"
                ),
            ])

        if "dynamic" in prepared["forward_types"]:
            base.extend([
                "-D",
                self._socks_spec(prepared),
            ])

        # -------------------------------------------------------------- #
        #  SSH port and destination
        # -------------------------------------------------------------- #
        if prepared["ssh_port"] != 22:
            base.extend([
                "-p",
                str(prepared["ssh_port"]),
            ])

        base.append(f"{prepared['user']}@{prepared['host']}")

        # -------------------------------------------------------------- #
        #  Wrap with sshpass if needed
        # -------------------------------------------------------------- #
        if prepared["auth_type"] == "password":
            return [
                "sshpass",
                "-P", SSHPASS_PROMPT_RE,
                "-p", prepared["password"],
            ] + base

        if prepared["auth_type"] == "key" and prepared.get("key_passphrase"):
            return [
                "sshpass",
                "-P", SSHPASS_PROMPT_RE,
                "-p", prepared["key_passphrase"],
            ] + base

        return base

    @staticmethod
    def _mask_command(cmd: list[str]) -> list[str]:
        """
        Маскирует секрет в команде для логов.

        Маскируется только пароль sshpass, не порт ssh -p.
        """

        masked = list(cmd)

        if masked and masked[0] == "sshpass":
            # Ожидаемая структура:
            # ["sshpass", "-P", regex, "-p", secret, "ssh", ...]
            for idx in range(1, min(len(masked), 6)):
                if masked[idx] == "-p" and idx + 1 < len(masked):
                    masked[idx + 1] = "***"
                    break

        return masked

    @staticmethod
    def _drain_stderr(name: str, stream: Any) -> None:
        """
        Читает stderr процесса в отдельном потоке, чтобы pipe не переполнился.
        """

        try:
            for line in iter(stream.readline, b""):
                text = line.decode(errors="replace").rstrip()
                if text:
                    log(f"[{name}] {text}")
        except Exception:
            pass
        finally:
            try:
                stream.close()
            except Exception:
                pass

    # ------------------------------------------------------------------ #
    #  Lifecycle
    # ------------------------------------------------------------------ #

    def start_tunnel(self, prepared: dict[str, Any]) -> None:
        name = prepared["name"]

        key_file = self._write_key_file(prepared)
        cmd = self._build_ssh_command(prepared, key_file)

        log(f"[{name}] CMD: {' '.join(self._mask_command(cmd))}")

        process = subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
            start_new_session=True,
        )

        threading.Thread(
            target=self._drain_stderr,
            args=(name, process.stderr),
            daemon=True,
        ).start()

        self.processes[name] = {
            "process": process,
            "prepared": prepared,
            "key_file": key_file,
        }

        log(f"[{name}] Запущен (PID {process.pid})")

    def start_all(self) -> None:
        KEYS_DIR.mkdir(parents=True, exist_ok=True)
        KEYS_DIR.chmod(0o700)

        prepared_items = []
        used_ports = set()
        seen_names = set()

        # Первый проход: валидация и проверка конфликтов.
        for raw_tunnel in self.tunnels:
            try:
                prepared = self._prepare_tunnel(raw_tunnel)

                if prepared["name"] in seen_names:
                    raise ConfigError(
                        f"Дублирующееся имя туннеля: {prepared['name']}"
                    )
                seen_names.add(prepared["name"])

                for port in self._port_numbers(prepared):
                    if port in used_ports:
                        raise ConfigError(
                            f"[{prepared['name']}] Конфликт портов: "
                            f"локальный порт {port} уже используется другим туннелем"
                        )
                    used_ports.add(port)

                prepared_items.append(prepared)

            except ConfigError as exc:
                log(f"Ошибка конфигурации: {exc}")
            except Exception as exc:
                log(f"Неизвестная ошибка подготовки туннеля: {exc}")

        if not prepared_items:
            log("Нет корректно настроенных туннелей для запуска")
            return

        # Второй проход: запуск.
        for prepared in prepared_items:
            try:
                self.start_tunnel(prepared)
            except Exception as exc:
                log(f"[{prepared['name']}] Ошибка запуска: {exc}")

    def monitor(self) -> None:
        """
        Бесконечный цикл мониторинга и автопереподключения.
        """

        while True:
            for name, data in list(self.processes.items()):
                process = data["process"]
                prepared = data["prepared"]

                if process.poll() is not None:
                    log(
                        f"[{name}] Процесс завершился "
                        f"(код {process.returncode})"
                    )

                    if prepared.get("auto_reconnect", True):
                        log(f"[{name}] Переподключение через 5 с ...")
                        time.sleep(5)

                        try:
                            self.start_tunnel(prepared)
                        except Exception as exc:
                            log(f"[{name}] Ошибка перезапуска: {exc}")
                    else:
                        log(f"[{name}] Автопереподключение отключено")
                        del self.processes[name]

            time.sleep(10)

    def stop_all(self) -> None:
        for name, data in list(self.processes.items()):
            process = data["process"]
            log(f"[{name}] Остановка ...")

            try:
                # Убиваем всю группу процессов, чтобы гарантированно закрыть ssh.
                os.killpg(os.getpgid(process.pid), signal.SIGTERM)
            except ProcessLookupError:
                pass
            except Exception as exc:
                log(f"[{name}] Ошибка отправки SIGTERM: {exc}")

            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                try:
                    os.killpg(os.getpgid(process.pid), signal.SIGKILL)
                except Exception:
                    process.kill()

        self.processes.clear()


# ====================================================================== #
#  Entry point
# ====================================================================== #

def main() -> int:
    try:
        config_json = load_tunnels_json()
        manager = SSHTunnelManager(config_json)
    except ConfigError as exc:
        log(f"Фатальная ошибка конфигурации: {exc}")
        return 1

    def shutdown(signum, frame):
        log("Получен сигнал завершения, останавливаю туннели ...")
        manager.stop_all()
        sys.exit(0)

    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)

    manager.start_all()
    manager.monitor()

    return 0


if __name__ == "__main__":
    sys.exit(main())
