#!/bin/bash

set -e -o pipefail

APP_NAME="dexterleng/Vimac"

# SHOW_RELEASES=$(appcenter distribute releases list -a $APP_NAME)
# LATEST_RELEASE_ID=$(echo "$SHOW_RELEASES" | awk '/^ID:/ {print $2}')

echo $LATEST_RELEASE_ID

RELEASE_API="https://appcenter.ms/api/v0.1/apps/dexterleng/Vimac/releases/${LATEST_RELEASE_ID}"

RELEASE_DOWNLOAD_URL=$(curl -X GET \
  "${RELEASE_API}" \
  -H "authorization: $AUTH_TOKEN" \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  | jq -r '.download_url')

echo $RELEASE_DOWNLOAD_URL

BINARY_FILE_LOCATION=$(mktemp)

curl "$RELEASE_DOWNLOAD_URL" > $BINARY_FILE_LOCATION

# Run this script from project root instead of script/
SIGN_UPDATE_OUTPUT=$(./Pods/Sparkle/bin/sign_update $BINARY_FILE_LOCATION)
SIGNATURE=$(echo $SIGN_UPDATE_OUTPUT | awk -F '"' '{print $2}')

echo $SIGN_UPDATE_OUTPUT
echo $SIGNATURE

# echo "Adding EdDSA signature and Sparkl destination for release $RELEASE_ID."

curl -X PATCH \
  "${RELEASE_API}" \
  -H "authorization: $AUTH_TOKEN" \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d "{
	\"destinations\": [
		{
			\"name\": \"Sparkle\"
		}
	],
	\"metadata\": {
	    \"ed_signature\": \"$SIGNATURE\"
	}
  }"
