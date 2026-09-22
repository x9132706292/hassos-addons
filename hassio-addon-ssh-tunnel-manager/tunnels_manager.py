#!/usr/bin/env python3
"""
SSH Tunnel Manager for Home Assistant
Управляет множественными SSH туннелями с автопереподключением.
"""

import json
import sys
import subprocess
import time
import os
import signal
import hashlib
import tempfile
from pathlib import Path
KEYS_DIR = Path("/data/ssh_keys")
class SSHTunnelManager:
def init(self, config_json: str):
self.tunnels = json.loads(config_json)
self.processes: dict = {}

# ------------------------------------------------------------------ #
#  Работа с ключами
# ------------------------------------------------------------------ #
def _write_key_file(self, tunnel: dict) -> str | None:
    """
    Записывает приватный ключ из конфигурации во временный файл
    и возвращает путь к нему. Если ключ не задан — возвращает None.
    """
    raw_key = tunnel.get("private_key", "")
    if not raw_key or not raw_key.strip():
        return None

    # Гарантируем, что ключ заканчивается переводом строки
    key_text = raw_key.strip() + "\n"

    # Стабильное имя файла на основе имени туннеля
    safe_name = "".join(
        c if c.isalnum() or c in "-_" else "_" for c in tunnel["name"]
    )
    key_path = KEYS_DIR / f"{safe_name}_id"

    key_path.write_text(key_text, encoding="utf-8")
    key_path.chmod(0o600)

    print(f"[{tunnel['name']}] Приватный ключ записан в {key_path}")
    return str(key_path)

# ------------------------------------------------------------------ #
#  Построение команды
# ------------------------------------------------------------------ #
def _build_ssh_command(self, tunnel: dict, key_file: str | None) -> list[str]:
    cmd = [
        "ssh",
        "-N",
        "-T",
        "-o", "StrictHostKeyChecking=no",
        "-o", "UserKnownHostsFile=/dev/null",
        "-o", "ServerAliveInterval=30",
        "-o", "ServerAliveCountMax=3",
        "-o", "ExitOnForwardFailure=yes",
    ]

    # --- Аутентификация ---
    if tunnel["auth_type"] == "password":
        password = tunnel.get("password", "")
        if not password:
            raise ValueError(f"Туннель '{tunnel['name']}': пароль не задан")
        cmd = ["sshpass", "-p", password] + cmd

    elif tunnel["auth_type"] == "key":
        if not key_file:
            raise ValueError(
                f"Туннель '{tunnel['name']}': выбран тип 'key', "
                "но приватный ключ пуст"
            )
        cmd.extend(["-i", key_file])

        # Если у ключа есть passphrase — используем sshpass
        passphrase = tunnel.get("key_passphrase", "")
        if passphrase:
            cmd = ["sshpass", "-p", passphrase] + cmd

    # --- Проброс портов ---
    fwd = f"{tunnel['local_port']}:{tunnel['remote_host']}:{tunnel['remote_port']}"
    cmd.extend(["-L", fwd])

    # --- Хост и порт ---
    cmd.append(f"{tunnel['user']}@{tunnel['host']}")
    if tunnel.get("port", 22) != 22:
        cmd.extend(["-p", str(tunnel["port"])])

    return cmd

# ------------------------------------------------------------------ #
#  Жизненный цикл туннеля
# ------------------------------------------------------------------ #
def _ensure_sshpass(self):
    """Устанавливает sshpass, если его нет."""
    try:
        subprocess.run(
            ["which", "sshpass"],
            check=True,
            capture_output=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("Установка sshpass …")
        subprocess.run(
            ["apk", "add", "--no-cache", "sshpass"],
            check=True,
        )

def start_tunnel(self, tunnel: dict):
    name = tunnel["name"]
    print(f"[{name}] Запуск туннеля …")

    key_file = self._write_key_file(tunnel)

    if tunnel["auth_type"] == "password" or tunnel.get("key_passphrase"):
        self._ensure_sshpass()

    cmd = self._build_ssh_command(tunnel, key_file)

    # Логируем команду (скрываем пароль/ключ)
    safe_cmd = [
        "***" if i > 0 and cmd[i - 1] == "-p" and cmd[0] == "sshpass"
        else c
        for i, c in enumerate(cmd)
    ]
    print(f"[{name}] CMD: {' '.join(safe_cmd)}")

    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    self.processes[name] = {
        "process": process,
        "config": tunnel,
        "key_file": key_file,
    }
    print(f"[{name}] Запущен (PID {process.pid})")

def monitor(self):
    """Бесконечный цикл мониторинга и автопереподключения."""
    while True:
        for name, data in list(self.processes.items()):
            proc = data["process"]
            cfg = data["config"]

            if proc.poll() is not None:
                stderr = proc.stderr.read().decode(errors="replace").strip()
                print(
                    f"[{name}] Процесс завершился "
                    f"(код {proc.returncode})"
                )
                if stderr:
                    print(f"[{name}] stderr: {stderr}")

                if cfg.get("auto_reconnect", True):
                    print(f"[{name}] Переподключение через 5 с …")
                    time.sleep(5)
                    try:
                        self.start_tunnel(cfg)
                    except Exception as exc:
                        print(f"[{name}] Ошибка перезапуска: {exc}")
                else:
                    print(f"[{name}] Автопереподключение отключено")
                    del self.processes[name]

        time.sleep(10)

# ------------------------------------------------------------------ #
#  Публичные методы
# ------------------------------------------------------------------ #
def start_all(self):
    KEYS_DIR.mkdir(parents=True, exist_ok=True)
    KEYS_DIR.chmod(0o700)

    for tunnel in self.tunnels:
        try:
            self.start_tunnel(tunnel)
        except Exception as exc:
            print(f"[{tunnel['name']}] Ошибка запуска: {exc}")

def stop_all(self):
    for name, data in self.processes.items():
        proc = data["process"]
        print(f"[{name}] Остановка …")
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
    self.processes.clear()
