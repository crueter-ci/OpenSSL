#!/bin/sh

# Grabs the latest OpenSSL version from the GitHub API.
# Requires: curl, jq, cut

API_URL=https://api.github.com/repos/openssl/openssl/releases/latest

while true; do
    VERSION=$(curl $API_URL | jq -r '.tag_name' | cut -d "-" -f2)
    [ "$VERSION" != "null" ] && echo "$VERSION" && exit 0
    sleep 5
done
