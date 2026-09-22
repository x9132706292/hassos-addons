    def _write_key_file(self, prepared: dict[str, Any]) -> Optional[str]:
        """
        Записывает приватный ключ из конфигурации в файл с правами 600.
        Возвращает путь к файлу.
        """

        raw_key = prepared.get("private_key", "")
        if not raw_key or not raw_key.strip():
            return None

        name = prepared["name"]

        # Убираем BOM, если он случайно попал.
        key_text = raw_key.lstrip("\ufeff")

        # Поддерживаем literal \n, если UI/JSON сохранил ключ одной строкой.
        key_text = (
            key_text.replace("\\r\\n", "\n")
            .replace("\\n", "\n")
            .replace("\r\n", "\n")
            .replace("\r", "\n")
        )

        lines: list[str] = []
        inside_payload = False

        for raw_line in key_text.splitlines():
            line = raw_line.strip()

            if not line:
                continue

            if line.startswith("-----BEGIN "):
                lines.append(line)
                inside_payload = True
                continue

            if line.startswith("-----END "):
                lines.append(line)
                inside_payload = False
                continue

            # Внутри base64-блока убираем все пробелы/табуляции.
            # Это спасает, если ключ вставили с переносами/лишними пробелами.
            if inside_payload:
                cleaned = "".join(line.split())
                if cleaned:
                    lines.append(cleaned)
            else:
                lines.append(line)

        if not lines:
            raise ConfigError(f"[{name}] private_key пуст после очистки")

        if lines[0].startswith("PuTTY-User-Key-File"):
            raise ConfigError(
                f"[{name}] Похоже, вставлен PuTTY .ppk ключ. "
                "Нужен OpenSSH private key."
            )

        if "Private-Lines:" in key_text or "Public-Lines:" in key_text:
            raise ConfigError(
                f"[{name}] Похоже, вставлен PuTTY .ppk ключ. "
                "Нужен OpenSSH private key."
            )

        if not lines[0].startswith("-----BEGIN ") or not lines[-1].startswith("-----END "):
            raise ConfigError(
                f"[{name}] private_key выглядит невалидным. "
                "Ожидается блок вида -----BEGIN ... ----- / -----END ... -----"
            )

        key_text = "\n".join(lines) + "\n"

        safe_name = "".join(
            ch if ch.isalnum() or ch in "-_" else "_"
            for ch in name
        )

        digest = hashlib.sha256(name.encode("utf-8")).hexdigest()[:8]

        KEYS_DIR.mkdir(parents=True, exist_ok=True)
        KEYS_DIR.chmod(0o700)

        key_path = KEYS_DIR / f"{safe_name}_{digest}_id"

        key_path.write_text(key_text, encoding="utf-8")
        key_path.chmod(0o600)

        log(f"[{name}] Приватный ключ записан в {key_path}")

        # Если ключ без passphrase, сразу проверим, читает ли его ssh-keygen.
        # Это даст понятную ошибку вместо загадочного libcrypto позже.
        if not prepared.get("key_passphrase"):
            check = subprocess.run(
                [
                    "ssh-keygen",
                    "-y",
                    "-f", str(key_path),
                    "-P", "",
                ],
                capture_output=True,
                text=True,
            )

            if check.returncode != 0:
                err = check.stderr.strip() or check.stdout.strip()
                raise ConfigError(
                    f"[{name}] SSH-ключ не проходит проверку ssh-keygen: {err}"
                )

            log(f"[{name}] Формат приватного ключа успешно проверен")

        return str(key_path)
