#!/bin/sh

# Downloads the specified OpenSSL version if the tarball doesn't already exist.
# Requires: wget, SSL_VERSION envvar

[ -z "$SSL_VERSION" ] && echo "-- You must specify the SSL_VERSION environment variable." && exit 1

while true; do
   if [ ! -f openssl-$SSL_VERSION.tar.gz ]; then
       wget https://github.com/openssl/openssl/releases/download/openssl-$SSL_VERSION/openssl-$SSL_VERSION.tar.gz && exit 0
       echo "-- Download failed, trying again in 5 seconds..."
       sleep 5
    else
        exit 0
    fi
done
