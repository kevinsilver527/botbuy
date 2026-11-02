#!/usr/bin/env bash
# List an item, then check whether anyone has ordered it.
# Requires curl and jq. Set BOTBUY_API_KEY to reuse your account; otherwise one is created.
set -euo pipefail

BASE="https://botbuy.tw"
auth=()
if [ -n "${BOTBUY_API_KEY:-}" ]; then auth=(-H "Authorization: Bearer $BOTBUY_API_KEY"); fi

listing=$(curl -fsS -X POST "$BASE/api/listings" "${auth[@]}" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{
    "title": "Kindle Paperwhite 11th gen",
    "price": 2500,
    "floor_price": 2200,
    "photos": ["https://example.com/your-real-photo.jpg"],
    "condition": "Like new",
    "location": "Taichung"
  }')

jq '{url, status, manage_url, photo_errors}' <<<"$listing"
api_key=$(jq -r '.api_key' <<<"$listing")

# Keep api_key and give manage_url to the seller. Run this on a schedule to see orders:
curl -fsS -H "Authorization: Bearer $api_key" "$BASE/api/me/deals" | jq '.deals'
