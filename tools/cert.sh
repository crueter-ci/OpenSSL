#!/bin/sh -e

# Build root certificate file.
# Only supported on Gentoo.

[ -d cert-cmake ] || git clone --depth=1 https://github.com/jimmy-park/cert-cmake
cd cert-cmake
cmake -S . -B build -DCERT_SOURCE="/etc/ssl/certs/ca-certificates.crt"
cmake --build build

cp build/include/cert.h ..