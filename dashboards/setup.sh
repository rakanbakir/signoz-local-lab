#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIGNOZ_URL="${SIGNOZ_URL:-http://signoz.local}"

echo "========================================="
echo "  SigNoz Dashboard Setup"
echo "========================================="
echo ""

if [ -z "$SIGNOZ_TOKEN" ]; then
  echo "AUTH_TOKEN not set. Get it from your browser:"
  echo ""
  echo "  1. Open $SIGNOZ_URL in your browser and log in"
  echo "  2. Open DevTools (F12) → Console"
  echo "  3. Run: JSON.parse(localStorage.getItem('AUTH_TOKEN')).accessJwt"
  echo "  4. Copy the token value"
  echo ""
  echo "Then run:"
  echo "  SIGNOZ_TOKEN=<your-token> bash $0"
  echo ""
  exit 1
fi

api_call() {
  local method="$1" url="$2" data="${3:-}"
  local args=(-s -w "\n%{http_code}" -H "Authorization: Bearer $SIGNOZ_TOKEN")
  [ "$method" != "GET" ] && args+=(-X "$method")
  [ -n "$data" ] && args+=(-H "Content-Type: application/json" -d "$data")
  curl "${args[@]}" "$url" 2>&1
}

# Get existing dashboards to handle updates
echo "Fetching existing dashboards..."
EXISTING=$(api_call "GET" "$SIGNOZ_URL/api/v1/dashboards")
EXISTING_BODY=$(echo "$EXISTING" | sed '$d')

import_dashboard() {
  local file="$1"
  local title=$(python3 -c "import json; print(json.load(open('$file'))['title'])")
  
  # Delete existing dashboard with same title
  echo "$EXISTING_BODY" | python3 -c "
import json, sys
dashboards = json.load(sys.stdin)
for d in dashboards:
    if d.get('data', {}).get('title') == '$title':
        print(d['data']['uuid'])
" 2>/dev/null | while read uuid; do
    api_call "DELETE" "$SIGNOZ_URL/api/v1/dashboards/$uuid" > /dev/null
  done

  echo -n "  Importing: $title ... "
  
  JSON_DATA=$(cat "$file" | python3 -c "import json,sys; json.dump(json.load(sys.stdin), sys.stdout)")
  RESPONSE=$(api_call "POST" "$SIGNOZ_URL/api/v1/dashboards" "$JSON_DATA")
  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  
  if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    echo "OK"
  else
    echo "FAILED (HTTP $HTTP_CODE)"
    echo "$RESPONSE" | sed '$d' | head -3
  fi
}

echo ""
echo "Importing dashboard templates..."

for json in "$SCRIPT_DIR"/*.json; do
  [ -f "$json" ] || continue
  import_dashboard "$json"
done

echo ""
echo "Done! Open $SIGNOZ_URL → Dashboards"
