#!/bin/bash -e

set -e

[ -z "$OUT_DIR" ] && OUT_DIR=$PWD/out

SSL_VERSION=${SSL_VERSION:-3.6.0}
BUILD_TYPE=${BUILD_TYPE:-no-asm}
OUT_DIR=${OUT_DIR:-$PWD/out}
ARCH=${ARCH:-amd64}
BUILD_DIR=${BUILD_DIR:-build}
PLATFORM=${PLATFORM:-linux}

[ "$PLATFORM" == "solaris" ] || [ "$PLATFORM" == "openbsd" ] && MAKE=gmake && TAR=gtar
MAKE=${MAKE:-make}
TAR=${TAR:-tar}

configure_ssl() {
    log_file=$1

    config_params=( "${BUILD_TYPE}" "shared" "no-makedepend" "--release")

    echo "Configuring OpenSSL $SSL_VERSION"
    echo "Configure parameters: ${config_params[@]}"

    ./Configure "${config_params[@]}" 2>&1 1>${log_file} | tee -a ${log_file} || exit 1

    echo "Making dependencies..."
    $MAKE depend
}

build_ssl() {
    log_file=$1

    echo "Building..."
    $MAKE SHLIB_VERSION_NUMBER= build_libs -j$(nproc) 2>&1 1>>${log_file} \
        | tee -a ${log_file} || exit 1
}

strip_libs() {
    find . -name "libcrypto*.so" -exec strip {} \;
    find . -name "libssl*.so" -exec strip {} \;

}

copy_build_artifacts() {
    echo "Copying artifacts..."
    mkdir -p $OUT_DIR/lib

    cp lib{ssl,crypto}.{so,a} "$OUT_DIR/lib" || exit 1
}

copy_cmake() {
    cp $ROOTDIR/CMakeLists.txt "$OUT_DIR"
}

package() {
    echo "Packaging..."
    mkdir -p "$ROOTDIR/artifacts"

    TARBALL=openssl-$PLATFORM-$ARCH-$SSL_VERSION.tar

    cd "$OUT_DIR"
    $TAR cf $ROOTDIR/artifacts/$TARBALL *

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
$TAR xf "$ROOTDIR/openssl-$SSL_VERSION.tar.gz"

mv "openssl-$SSL_VERSION" "openssl-$SSL_VERSION-$ARCH"
pushd "openssl-$SSL_VERSION-$ARCH"

log_file="build_${ARCH}_${SSL_VERSION}.log"
configure_ssl ${log_file}

# Delete existing build artifacts
rm -fr "$OUT_DIR"
mkdir -p "$OUT_DIR" || exit 1

build_ssl ${log_file}
strip_libs
copy_build_artifacts

if [ ! -d "$OUT_DIR/include" ]; then
    cp -p -R include "$OUT_DIR/" || exit 1
fi

# Clean include folder
find "$OUT_DIR/" -name "*.in" -exec rm -f {} \;
find "$OUT_DIR/" -name "*.def" -exec rm -f {} \;

copy_cmake
package

echo "Done! Artifacts are in $ROOTDIR/artifacts, raw lib/include data is in $OUT_DIR"

popd
popd
