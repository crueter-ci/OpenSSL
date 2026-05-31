#!/bin/sh -e

## Common variables ##

# In some projects you will want to fetch latest from gh/fj api
VERSION="4.0.0"
export COMMIT="11b7b6ea3b65a584e1d31408ed1bdb139465cffd"
# TIMESTAMP="$(date +%s)"
# export TIMESTAMP
export PRETTY_NAME="OpenSSL"
export FILENAME="openssl"
export REPO="openssl/openssl"
export DIRECTORY="openssl-$COMMIT"
export ARTIFACT="$COMMIT.tar.gz"
export DOWNLOAD_URL="https://github.com/$REPO/archive/$ARTIFACT"

SHORTSHA=$(echo "$COMMIT" | cut -c1-10)
export VERSION="$VERSION-$SHORTSHA"
