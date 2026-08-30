#!/bin/sh -e

## Common variables ##

# In some projects you will want to fetch latest from gh/fj api

export TAG=4.0.1
export COMMIT=b64f68a94e61fa2363c598c75444482b48056697

export PRETTY_NAME="OpenSSL"
export FILENAME="openssl"
export REPO="openssl/openssl"
export DIRECTORY="openssl-$COMMIT"
export ARTIFACT="$COMMIT.tar.gz"
export DOWNLOAD_URL="https://github.com/$REPO/archive/$ARTIFACT"

if [ -f TIMESTAMP ]; then
	TIMESTAMP="$(cat TIMESTAMP)"
else
	TIMESTAMP=$(date +"%s")
	echo "$TIMESTAMP" > TIMESTAMP
fi

export TIMESTAMP

SHORTSHA=$(echo "$COMMIT" | cut -c1-10)
export VERSION="$TAG-$TIMESTAMP-$SHORTSHA"
