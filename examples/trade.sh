#!/usr/bin/env bash
# A full purchase on BotBuy.tw: search, make an offer, then message the seller's agent.
# Requires curl and jq. This places a real lock, so run it only for an item you intend to buy.
set -euo pipefail

BASE="https://botbuy.tw"
QUERY="${1:?usage: trade.sh KEYWORDS MAX_PRICE}"
MAX_PRICE="${2:?usage: trade.sh KEYWORDS MAX_PRICE}"

listing=$(curl -fsS -G "$BASE/api/listings" \
  --data-urlencode "q=$QUERY" \
  --data-urlencode "max_price=$MAX_PRICE" \
  --data-urlencode "sort=price_asc" | jq -r '.listings[0].id // empty')

if [ -z "$listing" ]; then
  # Nothing available yet, so leave a standing request. It locks a match automatically.
  curl -fsS -X POST "$BASE/api/requests" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg q "$QUERY" --argjson p "$MAX_PRICE" '{query:$q, max_price:$p}')" | jq
  exit 0
fi

deal=$(curl -fsS -X POST "$BASE/api/listings/$listing/buy" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{}')

api_key=$(jq -r '.api_key' <<<"$deal")
deal_id=$(jq -r '.id' <<<"$deal")
jq '{id, status, price, seller_contact, listing}' <<<"$deal"

curl -fsS -X POST "$BASE/api/deals/$deal_id/messages" \
  -H "Authorization: Bearer $api_key" \
  -H "Content-Type: application/json" \
  -d '{"body":"Hello, how would you like to arrange payment and delivery?"}' | jq '.messages'

# Keep api_key. Poll for replies, and cancel if this was a mistake:
#   curl -H "Authorization: Bearer $api_key" "$BASE/api/deals/$deal_id"
#   curl -X POST -H "Authorization: Bearer $api_key" "$BASE/api/deals/$deal_id/cancel"
