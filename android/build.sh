#!/bin/sh -e

: "${OUT_DIR:=$PWD/out}"
: "${ANDROID_NDK_ROOT:?-- You must supply the ANDROID_NDK_ROOT environment variable.}"
: "${SSL_VERSION:=3.5.2}"
: "${ARCH:=arm64}"
: "${BUILD_DIR:=build}"
: "${ANDROID_API:=23}"
: "${BUILD_TYPE:=no-asm}"

configure_ssl() {
    export ANDROID_NDK_HOME="$ANDROID_NDK_ROOT"

    for host in linux-x86_64 linux-x86 darwin-x86_64 darwin-x86 windows-x86_64; do
        if [ -d "$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$host/bin" ]; then
            ANDROID_TOOLCHAIN="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$host/bin"
            export PATH="$ANDROID_TOOLCHAIN:$PATH"
            break
        fi
    done

    echo "-- Configuring OpenSSL $SSL_VERSION"

    ./Configure "${BUILD_TYPE}" shared android-"${ARCH}" -U__ANDROID_API__ -D__ANDROID_API__="${ANDROID_API}"
    make depend
}

build_ssl() {
    echo "-- Building..."
    make SHLIB_VERSION_NUMBER= build_libs -j"$(nproc)"
}

strip_libs() {
    find . -name "libcrypto*.so" -exec llvm-strip --strip-all {} \;
    find . -name "libssl*.so" -exec llvm-strip --strip-all {} \;
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

package() {
    mkdir -p "$ROOTDIR/artifacts"

    TARBALL=openssl-android-$SSL_VERSION.tar

    cd "$OUT_DIR"
    tar cf "$ROOTDIR/artifacts/$TARBALL" ./*

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
tar xf "$ROOTDIR/openssl-$SSL_VERSION.tar.gz"

mv "openssl-$SSL_VERSION" "openssl-$SSL_VERSION-$ARCH"
cd "openssl-$SSL_VERSION-$ARCH"

configure_ssl

# Delete existing build artifacts
rm -fr "$OUT_DIR"
mkdir -p "$OUT_DIR"

build_ssl
strip_libs
copy_build_artifacts

if [ ! -d "$OUT_DIR/include" ]; then
    cp -a include "$OUT_DIR/"
	cp "$ROOTDIR"/cert.h "$OUT_DIR"/include/openssl

    # Clean include folder
    find "$OUT_DIR/" -name "*.in" -delete
    find "$OUT_DIR/" -name "*.def" -delete
fi

copy_cmake
package