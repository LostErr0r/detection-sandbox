#!/usr/bin/env bash
set -euo pipefail

# Директория, где лежит сам скрипт
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET_URL="http://localhost:3000"
WORDLIST="$SCRIPT_DIR/dirsearch.txt"
THREADS=200

# Проверка наличия gobuster
if ! command -v gobuster >/dev/null 2>&1; then
  echo "[!] gobuster не установлен"
  echo "    Установи: sudo apt install gobuster -y"
  exit 1
fi

# Проверка wordlist
if [ ! -f "$WORDLIST" ]; then
  echo "[!] Wordlist не найден: $WORDLIST"
  exit 1
fi

echo "[*] Запуск поиска скрытых директорий"
echo "    URL:       $TARGET_URL"
echo "    Wordlist:  $WORDLIST"
echo "    Threads:   $THREADS"
echo

gobuster dir \
  -u "$TARGET_URL" \
  -w "$WORDLIST" \
  -t "$THREADS" \
  -b 200 \
  --no-error

echo
echo "[+] Сканирование директорий завершено"
