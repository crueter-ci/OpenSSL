#!/bin/sh -e

## Common variables ##

# TAG/COMMIT must be set.

# In some projects you will want to fetch latest from gh/fj api
# TIMESTAMP="$(date +%s)"
# export TIMESTAMP
export PRETTY_NAME="OpenSSL"
export FILENAME="openssl"
export REPO="openssl/openssl"
export DIRECTORY="openssl-$COMMIT"
export ARTIFACT="$COMMIT.tar.gz"
export DOWNLOAD_URL="https://github.com/$REPO/archive/$ARTIFACT"
TIMESTAMP="$(cat TIMESTAMP)"
export TIMESTAMP

SHORTSHA=$(echo "$COMMIT" | cut -c1-10)
export VERSION="$TAG-$SHORTSHA-$TIMESTAMP"
