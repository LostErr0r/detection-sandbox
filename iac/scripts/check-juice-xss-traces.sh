#!/usr/bin/env bash
set -euo pipefail

ES="http://localhost:9200"
INDEX="juice-shop-access-*"

WINDOW="now-2h"
THRESHOLD=5   # можно 1/5/10 — зависит сколько payload'ов шлёшь

if ! command -v jq >/dev/null 2>&1; then
  echo "[!] jq не установлен. Установи: sudo apt install jq -y"
  exit 2
fi

echo "[*] Checking XSS attack traces in Elasticsearch: $ES"
echo "[*] Index: $INDEX | Window: $WINDOW | Threshold: $THRESHOLD"

ES_HTTP="$(curl -s -o /dev/null -w "%{http_code}" "$ES" || true)"
if [ "$ES_HTTP" != "200" ]; then
  echo "[!] Elasticsearch not OK. HTTP: $ES_HTTP"
  exit 2
fi

# Ищем GET запросы, где request начинается с /rest/products/search (с ?q=... или без)
QUERY=$(cat <<EOF
{
  "size": 0,
  "query": {
    "bool": {
      "filter": [
        { "range": { "@timestamp": { "gte": "${WINDOW}" } } },
        { "term":  { "verb": "GET" } },
        { "wildcard": { "request": "/rest/products/search*" } }
      ],
      "should": [
        { "wildcard": { "http_user_agent": "*curl*" } }
      ]
    }
  }
}
EOF
)

RESP="$(curl -sS -X POST "$ES/$INDEX/_search" \
  -H 'Content-Type: application/json' \
  -d "$QUERY")"

if echo "$RESP" | jq -e '.error' >/dev/null 2>&1; then
  echo "[!] Elasticsearch returned an error:"
  echo "$RESP" | jq '.error'
  exit 2
fi

COUNT="$(echo "$RESP" | jq -r '.hits.total.value // 0')"
echo "[*] GET /rest/products/search* in window: $COUNT"

if [ "$COUNT" -ge "$THRESHOLD" ]; then
  echo "[+] PASS"
  exit 0
else
  echo "[!] FAIL (too few requests)"
  echo "    Если payload'ов мало — снизь THRESHOLD, или запусти make attack-xss ещё раз."
  exit 2
fi
