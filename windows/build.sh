#!/bin/sh -e

# I just discovered this syntax and it's awesome
: "${OUT_DIR:=$PWD/out}"
: "${SSL_VERSION:=3.5.2}"
: "${ARCH:=amd64}"
: "${BUILD_DIR:=build}"
: "${BUILD_TYPE:=no-asm}"
: "${PLATFORM:=windows}"

mingw() {
    [ "$PLATFORM" = "mingw" ]
}

{ mingw && MAKE="make" && export PATH="/$MSYSTEM/bin:$PATH"; } || MAKE="nmake"
mingw && [ "$ARCH" = arm64 ] && export CC=aarch64-w64-mingw32-clang && export CXX=aarch64-w64-mingw32-clang++

configure_ssl() {
    echo "-- Configuring OpenSSL $SSL_VERSION"

    ./Configure "${BUILD_TYPE}" shared no-makedepend --release

    echo "-- Making dependencies..."
    $MAKE depend
}

build_ssl() {
    echo "-- Building..."

    # hacky crap caused by MICROSHIT
    if ! mingw; then
        export CL=" /MP"
        
        # shellcheck disable=SC2154
        TOOLSDIR=$(cygpath -u "$VCToolsInstallDir")
        export PATH="${TOOLSDIR}/bin/Host${VSCMD_ARG_HOST_ARCH}/${VSCMD_ARG_TGT_ARCH}/:$PATH"
        $MAKE build_libs
    else
        $MAKE build_libs -j"$(nproc)"
    fi
}

copy_build_artifacts() {
    echo "-- Copying artifacts..."
    mkdir -p "$OUT_DIR/lib"

    mv libssl-*.dll libssl.dll
    mv libcrypto-*.dll libcrypto.dll

    ls libssl*
    ls libcrypto*

    # OAKSDNFKJDSNFKJFDSNKDSNKJFNKNDSKJNFKJSDNJDSFIUQHE9IU02984309QSFJDKOKM
    for lib in ssl crypto; do
        cp lib${lib}*.dll "$OUT_DIR"/lib
        mingw && SUFFIX=a || SUFFIX=lib
        cp lib${lib}*."${SUFFIX}" "$OUT_DIR"/lib
    done
}

copy_cmake() {
    cp "$ROOTDIR"/CMakeLists.txt "$OUT_DIR"
}

package() {
    echo "-- Packaging..."
    mkdir -p "$ROOTDIR/artifacts"

    TARBALL=openssl-$PLATFORM-$ARCH-$SSL_VERSION.tar

    cd "$OUT_DIR"
    tar cf "$ROOTDIR/artifacts/$TARBALL" ./*

    cd "$ROOTDIR/artifacts"
    zstd -10 "$TARBALL"
    rm "$TARBALL"

    "$ROOTDIR/tools/sums.sh" "$TARBALL".zst
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
mkdir -p "$OUT_DIR" || exit 1

build_ssl
copy_build_artifacts

if [ ! -d "$OUT_DIR/include" ]; then
    cp -a include "$OUT_DIR/" || exit 1
	cp "$ROOTDIR"/cert.h "$OUT_DIR"/include/openssl
fi

# Clean include folder
/bin/find "$OUT_DIR/" -name "*.in" -delete
/bin/find "$OUT_DIR/" -name "*.def" -delete

copy_cmake
package

echo "-- Done! Artifacts are in $ROOTDIR/artifacts, raw lib/include data is in $OUT_DIR"
