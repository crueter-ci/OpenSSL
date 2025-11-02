#!/bin/sh -e

: "${OUT_DIR:=$PWD/out}"
: "${SSL_VERSION:=3.5.2}"
: "${BUILD_TYPE:=no-asm}"
: "${ARCH:=amd64}"
: "${BUILD_DIR:=build}"
: "${PLATFORM:=linux}"

case $PLATFORM in solaris|openbsd)
  MAKE=gmake
  TAR=gtar
esac
: "${MAKE:=make}"
: "${TAR:=tar}"

configure_ssl() {
    echo "-- Configuring OpenSSL $SSL_VERSION"

    ./Configure "${BUILD_TYPE}" shared no-makedepend --release threads no-tests

    echo "-- Making dependencies..."
    $MAKE depend
}

build_ssl() {
    echo "-- Building..."
    $MAKE SHLIB_VERSION_NUMBER= build_libs -j"$(nproc)"
}

strip_libs() {
    find . -name "libcrypto*.so" -exec strip {} \;
    find . -name "libssl*.so" -exec strip {} \;
}

copy_build_artifacts() {
    echo "-- Copying artifacts..."
    mkdir -p "$OUT_DIR/lib"

    for lib in ssl crypto; do
        cp lib${lib}*.so "$OUT_DIR"/lib
        cp lib${lib}*.a "$OUT_DIR"/lib
    done
}

copy_cmake() {
    cp "$ROOTDIR"/CMakeLists.txt "$OUT_DIR"
}

# TODO: Make this a common function
package() {
    echo "-- Packaging..."
    mkdir -p "$ROOTDIR/artifacts"

    TARBALL=openssl-$PLATFORM-$ARCH-$SSL_VERSION.tar

    cd "$OUT_DIR"
    $TAR cf "$ROOTDIR/artifacts/$TARBALL" ./*

    cd "$ROOTDIR/artifacts"
    zstd -10 "$TARBALL"
    rm "$TARBALL"

    "$ROOTDIR"/tools/sums.sh "$TARBALL".zst
}

ROOTDIR=$PWD

./tools/download-openssl.sh

[ -e "$BUILD_DIR" ] && rm -fr "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "-- Extracting OpenSSL $SSL_VERSION"
rm -fr "openssl-$SSL_VERSION"
$TAR xf "$ROOTDIR/openssl-$SSL_VERSION.tar.gz"

mv "openssl-$SSL_VERSION" "openssl-$SSL_VERSION-$ARCH"
cd "openssl-$SSL_VERSION-$ARCH"

configure_ssl

# Delete existing build artifacts
rm -fr "$OUT_DIR"
mkdir -p "$OUT_DIR" || exit 1

build_ssl
strip_libs
copy_build_artifacts

if [ ! -d "$OUT_DIR/include" ]; then
    cp -p -R include "$OUT_DIR/" || exit 1
	cp "$ROOTDIR"/cert.h "$OUT_DIR"/include/openssl
fi

# Clean include folder
find "$OUT_DIR/" -name "*.in" -exec rm -f {} \;
find "$OUT_DIR/" -name "*.def" -exec rm -f {} \;

copy_cmake
package

echo "-- Done! Artifacts are in $ROOTDIR/artifacts, raw lib/include data is in $OUT_DIR"
