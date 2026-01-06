#!/bin/sh -e

## Common variables ##

# In some projects you will want to fetch latest from gh/fj api
VERSION="3.6.0"
export COMMIT="5707fd07531a4bf923a5a20b136691291e08bd57"
export PRETTY_NAME="OpenSSL"
export FILENAME="openssl"
export REPO="openssl/openssl"
export DIRECTORY="openssl-$COMMIT"
export ARTIFACT="$COMMIT.tar.gz"
export DOWNLOAD_URL="https://github.com/$REPO/archive/$ARTIFACT"

SHORTSHA=$(echo "$COMMIT" | cut -c1-10)
export VERSION="$VERSION-$SHORTSHA"
