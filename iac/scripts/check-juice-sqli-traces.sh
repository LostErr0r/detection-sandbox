#!/usr/bin/env bash
set -euo pipefail

ES="http://localhost:9200"
INDEX="juice-shop-access-*"

WINDOW="now-2h"
THRESHOLD=1

# Базовый индикатор: успешный логин (200) на /rest/user/login.
# UA "curl" добавляем как дополнительный сигнал, но не делаем обязательным.
QUERY=$(cat <<EOF
{
  "size": 0,
  "query": {
    "bool": {
      "filter": [
        { "range": { "@timestamp": { "gte": "${WINDOW}" } } },
        { "term": { "verb": "POST" } },
        { "term": { "request": "/rest/user/login" } },
        { "term": { "response": "200" } }
      ],
      "should": [
        { "wildcard": { "http_user_agent": "*curl*" } }
      ]
    }
  }
}
EOF
)

if ! command -v jq >/dev/null 2>&1; then
  echo "[!] jq не установлен. Установи: sudo apt install jq -y"
  exit 2
fi

echo "[*] Checking SQLi-like success traces in Elasticsearch: $ES"
echo "[*] Index: $INDEX | Window: $WINDOW | Threshold: $THRESHOLD"

ES_HTTP="$(curl -s -o /dev/null -w "%{http_code}" "$ES" || true)"
if [ "$ES_HTTP" != "200" ]; then
  echo "[!] Elasticsearch not OK. HTTP: $ES_HTTP"
  exit 2
fi

RESP="$(curl -sS -X POST "$ES/$INDEX/_search" \
  -H 'Content-Type: application/json' \
  -d "$QUERY")"

if echo "$RESP" | jq -e '.error' >/dev/null 2>&1; then
  echo "[!] Elasticsearch returned an error:"
  echo "$RESP" | jq '.error'
  exit 2
fi

COUNT="$(echo "$RESP" | jq -r '.hits.total.value // 0')"
echo "[*] Successful login events (200) in window: $COUNT"

if [ "$COUNT" -ge "$THRESHOLD" ]; then
  echo "[+] PASS"
  exit 0
else
  echo "[!] FAIL (no 200 logins found)"
  exit 2
fi
