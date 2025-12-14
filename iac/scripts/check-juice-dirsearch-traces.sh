#!/usr/bin/env bash
set -euo pipefail

ES="http://localhost:9200"
INDEX="juice-shop-access-*"

WINDOW="now-30m"
THRESHOLD=50   # сколько запросов считаем признаком сканирования

if ! command -v jq >/dev/null 2>&1; then
  echo "[!] jq не установлен. Установи: sudo apt install jq -y"
  exit 2
fi

echo "[*] Checking dirsearch/gobuster traces in Elasticsearch: $ES"
echo "[*] Index: $INDEX | Window: $WINDOW | Threshold: $THRESHOLD"

ES_HTTP="$(curl -s -o /dev/null -w "%{http_code}" "$ES" || true)"
if [ "$ES_HTTP" != "200" ]; then
  echo "[!] Elasticsearch not OK. HTTP: $ES_HTTP"
  exit 2
fi

search_count () {
  local query_json="$1"
  local resp
  resp="$(curl -sS -X POST "$ES/$INDEX/_search" \
    -H 'Content-Type: application/json' \
    -d "$query_json")"

  if echo "$resp" | jq -e '.error' >/dev/null 2>&1; then
    echo "[!] Elasticsearch error:"
    echo "$resp" | jq '.error'
    exit 2
  fi

  echo "$resp" | jq -r '.hits.total.value // 0'
}

# 1) Основной вариант: ловим user-agent gobuster
QUERY_UA=$(cat <<EOF
{
  "size": 0,
  "query": {
    "bool": {
      "filter": [
        { "range": { "@timestamp": { "gte": "${WINDOW}" } } },
        { "term":  { "verb": "GET" } },
        { "wildcard": { "http_user_agent": "*gobuster*" } }
      ]
    }
  }
}
EOF
)

COUNT_UA="$(search_count "$QUERY_UA")"
echo "[*] gobuster UA GET requests in window: $COUNT_UA"

if [ "$COUNT_UA" -ge "$THRESHOLD" ]; then
  echo "[+] PASS (found gobuster user-agent activity)"
  exit 0
fi

# 2) Fallback: если UA не парсится, ищем паттерн сканирования:
# много GET с "ошибочными" кодами (301/403/404/500) за окно времени
QUERY_FALLBACK=$(cat <<EOF
{
  "size": 0,
  "query": {
    "bool": {
      "filter": [
        { "range": { "@timestamp": { "gte": "${WINDOW}" } } },
        { "term":  { "verb": "GET" } },
        { "terms": { "response": ["301","403","404","500"] } }
      ]
    }
  }
}
EOF
)

COUNT_FB="$(search_count "$QUERY_FALLBACK")"
echo "[*] fallback GET (301/403/404/500) in window: $COUNT_FB"

if [ "$COUNT_FB" -ge "$THRESHOLD" ]; then
  echo "[+] PASS (scan-like pattern detected)"
  exit 0
else
  echo "[!] FAIL (too few scan-like requests)"
  echo "    Подсказка: если скан был давно — увеличь WINDOW (например now-2h) или снизь THRESHOLD."
  exit 2
fi
