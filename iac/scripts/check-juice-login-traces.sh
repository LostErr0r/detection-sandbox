#!/usr/bin/env bash
set -euo pipefail

ES="http://localhost:9200"
INDEX="juice-shop-access-*"

# Окно времени и порог
WINDOW="now-30m"
THRESHOLD=10

QUERY=$(cat <<EOF
{
  "size": 0,
  "query": {
    "bool": {
      "filter": [
        { "range": { "@timestamp": { "gte": "${WINDOW}" } } },
        { "match_phrase":  { "request": "/rest/user/login" } },
        { "match_phrase":  { "verb": "POST" } }
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

echo "[*] Checking Elasticsearch: $ES"
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
echo "[*] login attempts (POST /rest/user/login) in window: $COUNT"

if [ "$COUNT" -ge "$THRESHOLD" ]; then
  echo "[+] PASS"
  exit 0
else
  echo "[!] FAIL (too few events)"
  exit 2
fi
