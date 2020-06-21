#!/bin/bash

set -euf -o pipefail

APP_NAME="dexterleng/Vimac"

SHOW_MASTER_BUILDS=$(appcenter build branches show -b master -a $APP_NAME)
LATEST_MASTER_BUILD_ID=$(echo "$SHOW_MASTER_BUILDS" | awk '/^Build ID:/ {print $3}')

echo "Creating release for Build ID $LATEST_MASTER_BUILD_ID."

curl -X POST \
  "https://appcenter.ms/api/v0.1/apps/dexterleng/Vimac/builds/$LATEST_MASTER_BUILD_ID/distribute" \
  -H "authorization: $AUTH_TOKEN" \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d '{
	    "destinations": []
    }'


