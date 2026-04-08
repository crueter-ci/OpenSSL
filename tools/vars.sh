#!/bin/sh -e

## Common variables ##

# In some projects you will want to fetch latest from gh/fj api
VERSION="3.6.2"
export COMMIT="72d5e8dcd2977234e47e840d2173917daa8bb0fa"
export PRETTY_NAME="OpenSSL"
export FILENAME="openssl"
export REPO="openssl/openssl"
export DIRECTORY="openssl-$COMMIT"
export ARTIFACT="$COMMIT.tar.gz"
export DOWNLOAD_URL="https://github.com/$REPO/archive/$ARTIFACT"

SHORTSHA=$(echo "$COMMIT" | cut -c1-10)
export VERSION="$VERSION-$SHORTSHA"
