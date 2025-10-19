#!/bin/bash

set -e

[ -z "$OUT_DIR" ] && OUT_DIR=$PWD/out

[ -z "$SSL_VERSION" ] && SSL_VERSION=3.5.2
[ -z "$ARCH" ] && ARCH=amd64
[ -z "$BUILD_DIR" ] && BUILD_DIR=build
[ -z "$BUILD_TYPE" ] && BUILD_TYPE=no-asm

configure_ssl() {
    log_file=$1

    case "$ARCH" in
        (x86)
            TARGET="VC-WIN32"
            ;;
        (amd64|x64|x86_64)
            TARGET="VC-WIN64A"
            ;;
        (aarch64|arm|arm64)
            TARGET="VC-WIN64-ARM"
            ;;
    esac

    config_params=( "${BUILD_TYPE}" "shared" "$TARGET" "no-makedepend" "--release")

    echo "Configuring OpenSSL $SSL_VERSION"
    echo "Configure parameters: ${config_params[@]}"

		./Configure "${config_params[@]}" 2>&1 1>${log_file} | tee -a ${log_file} || exit 1

    echo "Making dependencies..."
    nmake depend
}

build_ssl() {
    log_file=$1

    echo "Building..."
    export CL=" /MP"

    # hacky crap caused by git bash
    TOOLSDIR=`cygpath -u "$VCToolsInstallDir"`
    echo $TOOLSDIR
    export PATH="$TOOLSDIR/bin/Host${VSCMD_ARG_HOST_ARCH}/${VSCMD_ARG_TGT_ARCH}/:$PATH"
    nmake build_libs 2>&1 1>>${log_file} \
        | tee -a ${log_file} || (cat $log_file && exit 1)
}

copy_build_artifacts() {
    echo "Copying artifacts..."
    mkdir -p $OUT_DIR/lib

    mv libssl-*.dll libssl.dll
    mv libcrypto-*.dll libcrypto.dll

    cp lib{ssl,crypto}*.{dll,lib} "$OUT_DIR/lib" || exit 1
}

copy_cmake() {
    cp $ROOTDIR/CMakeLists.txt "$OUT_DIR"
}

package() {
    echo "Packaging..."
    mkdir -p "$ROOTDIR/artifacts"

    TARBALL=openssl-windows-$ARCH-$SSL_VERSION.tar

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
mkdir -p "$OUT_DIR" || exit 1

build_ssl ${log_file}
copy_build_artifacts

if [ ! -d "$OUT_DIR/include" ]; then
    cp -a include "$OUT_DIR/" || exit 1
	cp "$ROOTDIR"/cert.h "$OUT_DIR"/include
fi

# Clean include folder
/bin/find "$OUT_DIR/" -name "*.in" -delete
/bin/find "$OUT_DIR/" -name "*.def" -delete

copy_cmake
package

echo "Done! Artifacts are in $ROOTDIR/artifacts, raw lib/include data is in $OUT_DIR"

popd
popd
