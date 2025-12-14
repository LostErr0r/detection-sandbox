#!/usr/bin/env bash
set -euo pipefail

ES="${ES:-http://localhost:9200}"
INDEX="${INDEX:-system-audit-*}"
WINDOW="${WINDOW:-now-30m}"

count() {
  local query="$1"
  curl -sS "$ES/$INDEX/_count" \
    -H 'Content-Type: application/json' \
    -d '{
      "query": {
        "bool": {
          "filter": [
            { "range": { "@timestamp": { "gte": "'"$WINDOW"'" } } },
            '"$query"'
          ]
        }
      }
    }' | sed -n 's/.*"count":\([0-9]\+\).*/\1/p'
}

echo "[*] ES=$ES INDEX=$INDEX WINDOW=$WINDOW"

# 1) cron create/remove (ищем /etc/cron)
CRON=$(count '{ "query_string": { "query": "auditd.path.name:/etc/cron* OR path:/etc/cron*" } }')
echo "[check] cron-related events: $CRON"

# 2) authorized_keys
AUTH=$(count '{ "query_string": { "query": "auditd.key:ssh_authkeys OR authorized_keys" } }')
echo "[check] authorized_keys events: $AUTH"

# 3) sudo
SUDO=$(count '{ "query_string": { "query": "process.name:sudo OR proctitle:sudo*" } }')
echo "[check] sudo events: $SUDO"

# 4) useradd/userdel
USERMGMT=$(count '{ "query_string": { "query": "process.name:(useradd OR userdel) OR proctitle:(useradd* OR userdel*)" } }')
echo "[check] user management events: $USERMGMT"
