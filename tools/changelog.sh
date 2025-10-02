#!/bin/sh

# Generates a "changelog"/download utility table
# Requires: echo

BASE_DOWNLOAD_URL="https://github.com/crueter/OpenSSL-CI/releases/download"
TAG=v$SSL_VERSION

artifact() {
  NAME="$1"
  ARTIFACT="$2"

  BASE_URL="${BASE_DOWNLOAD_URL}/${TAG}/openssl-${ARTIFACT}-${SSL_VERSION}.tar.zst"

  echo -n "| "
  echo -n "[$NAME]($BASE_URL) | "
  for sum in 1 256 512; do
    echo -n "[Download]($BASE_URL.sha${sum}sum) |"
  done
  echo
}

echo "Builds for OpenSSL $SSL_VERSION"
echo
echo "| Build | sha1sum | sha256sum | sha512sum |"
echo "| ----- | ------- | --------- | --------- |"

artifact Android android
artifact "Windows (amd64)" windows-amd64
artifact "Windows (arm64)" windows-arm64
artifact "Linux (amd64)" linux-amd64
artifact "Linux (aarch64)" linux-aarch64
artifact "Solaris (amd64)" solaris-amd64
artifact "FreeBSD (amd64)" freebsd-amd64
artifact "OpenBSD (amd64)" openbsd-amd64