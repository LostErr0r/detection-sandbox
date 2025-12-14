#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

ELK_COMPOSE="$ROOT_DIR/docker/docker-compose.yml"
JS_COMPOSE="$ROOT_DIR/app/juice-shop/docker-compose.yml"

ES="http://localhost:9200"

wait_es() {
  echo "[*] Waiting for Elasticsearch at $ES ..."
  for i in {1..60}; do
    if curl -s "$ES" >/dev/null 2>&1; then
      echo "[+] Elasticsearch is up"
      return 0
    fi
    sleep 2
  done
  echo "[!] Elasticsearch did not start in time"
  exit 1
}

wait_kibana() {
  echo "[*] Waiting for Kibana at http://localhost:5601 ..."
  for i in {1..90}; do
    if curl -s "http://localhost:5601/api/status" >/dev/null 2>&1; then
      echo "[+] Kibana is up"
      return 0
    fi
    sleep 2
  done
  echo "[!] Kibana did not start in time"
  exit 1
}

import_dashboards() {
  local file="$ROOT_DIR/export.ndjson"

  if [ ! -f "$file" ]; then
    echo "[!] export.ndjson not found: $file"
    return 0
 fi

  echo "[*] Importing saved objects from export.ndjson..."

 curl -sS -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" \
  -H "kbn-xsrf: true" \
  --form file=@"./export.ndjson"


  echo "[+] Dashboards imported"
}

put_template_from_devtools_file() {
  local name="$1"
  local filepath="$2"

  if [ ! -f "$filepath" ]; then
    echo "[!] Template file not found: $filepath"
    exit 1
  fi

  local tmp
  tmp="$(mktemp)"
  # Вырезаем первую строку "PUT ..." -> остаётся чистый JSON
 tail -n +2 "$filepath" > "$tmp"

  # На всякий случай проверим, что это валидный JSON
  python3 -m json.tool < "$tmp" >/dev/null

  curl -sS -X PUT "$ES/_index_template/$name" \
    -H 'Content-Type: application/json' \
    --data-binary @"$tmp" >/dev/null

  rm -f "$tmp"
  echo "[+] Applied template: $name"
}

apply_templates() {
  echo "[*] Applying index templates..."
  put_template_from_devtools_file "juice-shop-access-template" "$ROOT_DIR/templates/juice-shop-access-template.json"
  put_template_from_devtools_file "system-audit-template"      "$ROOT_DIR/templates/system-audit-template.json"
}

echo "[*] Starting ELK..."
docker compose -f "$ELK_COMPOSE" up -d

echo "[*] Starting Juice Shop..."
docker compose -f "$JS_COMPOSE" up -d

wait_es
wait_kibana
apply_templates
import_dashboards

echo "[+] Done."
echo "    Kibana:    http://localhost:5601"
echo "    JuiceShop: http://localhost:3000"
