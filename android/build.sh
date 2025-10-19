#!/bin/bash

set -e

[ -z "$OUT_DIR" ] && OUT_DIR=$PWD/out

[ -z "$ANDROID_NDK_ROOT" ] && echo "You must supply the ANDROID_NDK_ROOT environment variable." && exit 1
[ -z "$SSL_VERSION" ] && SSL_VERSION=3.5.2
[ -z "$ARCH" ] && ARCH=arm64
[ -z "$BUILD_DIR" ] && BUILD_DIR=build
[ -z "$ANDROID_API" ] && ANDROID_API=23
[ -z "$BUILD_TYPE" ] && BUILD_TYPE=no-asm

configure_ssl() {
    log_file=$1

    export ANDROID_NDK_HOME="$ANDROID_NDK_ROOT"

    declare hosts=("linux-x86_64" "linux-x86" "darwin-x86_64" "darwin-x86")
    for host in "${hosts[@]}"; do
        if [ -d "$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$host/bin" ]; then
            ANDROID_TOOLCHAIN="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$host/bin"
            export PATH="$ANDROID_TOOLCHAIN:$PATH"
            break
        fi
    done

    config_params=( "${BUILD_TYPE}" "shared" "android-${ARCH}"
                    "-U__ANDROID_API__" "-D__ANDROID_API__=${ANDROID_API}" )
    echo "Configuring OpenSSL $SSL_VERSION"
    echo "Configure parameters: ${config_params[@]}"

    ./Configure "${config_params[@]}" 2>&1 1>${log_file} | tee -a ${log_file} || exit 1
    make depend
}

build_ssl() {
    log_file=$1

    echo "Building..."
    make -j$(nproc) SHLIB_VERSION_NUMBER= build_libs 2>&1 1>>${log_file} \
        | tee -a ${log_file} || exit 1
}

strip_libs() {
    find . -name "libcrypto*.so" -exec llvm-strip --strip-all {} \;
    find . -name "libssl*.so" -exec llvm-strip --strip-all {} \;
}

copy_build_artifacts() {
    mkdir $OUT_DIR/lib

    cp lib{ssl,crypto}.{so,a} "$OUT_DIR/lib" || exit 1
}

copy_cmake() {
    cp $ROOTDIR/CMakeLists.txt "$OUT_DIR"
}

package() {
    mkdir -p "$ROOTDIR/artifacts"

    TARBALL=openssl-android-$SSL_VERSION.tar

    cd "$OUT_DIR"
    tar cf $ROOTDIR/artifacts/$TARBALL *

    cd "$ROOTDIR/artifacts"
    zstd -10 $TARBALL
    rm $TARBALL

    $ROOTDIR/tools/sums.sh $TARBALL.zst
}

ROOTDIR=$PWD

./tools/download-openssl.sh

[[ -e "$BUILD_DIR" ]] && rm -fr "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
pushd "$BUILD_DIR"

echo "Extracting OpenSSL $SSL_VERSION"
rm -fr "openssl-$SSL_VERSION"
tar xf "$ROOTDIR/openssl-$SSL_VERSION.tar.gz"

mv "openssl-$SSL_VERSION" "openssl-$SSL_VERSION-$ARCH"
pushd "openssl-$SSL_VERSION-$ARCH"

log_file="build_${ARCH}_${SSL_VERSION}.log"
configure_ssl ${log_file}

# Delete existing build artifacts
rm -fr "$OUT_DIR"
mkdir -p "$OUT_DIR"

build_ssl ${log_file}
strip_libs
copy_build_artifacts

if [ ! -d "$OUT_DIR/include" ]; then
    cp -a include "$OUT_DIR/"
	cp "$ROOTDIR"/cert.h "$OUT_DIR"/include

    # Clean include folder
    find "$OUT_DIR/" -name "*.in" -delete
    find "$OUT_DIR/" -name "*.def" -delete
fi

copy_cmake
package

popd
popd
