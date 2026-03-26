#!/bin/sh

set -e

# shellcheck disable=SC1091

. tools/common.sh

## Platform Stuff ##

android() {
	[ "$PLATFORM" = android ]
}

DEFAULT_ARCH=amd64
if android; then
	DEFAULT_ARCH=aarch64
	: "${ANDROID_NDK_ROOT:?-- You must supply the ANDROID_NDK_ROOT environment variable.}"
	: "${ANDROID_API:=23}"
	android_paths
fi

## Buildtime/Input Variables ##

: "${ARCH:=$DEFAULT_ARCH}"
: "${BUILD_DIR:=build}"
: "${BUILD_TYPE:=no-asm}"

## Build Functions ##

configure() {
	target="$1"

	echo "-- Configuring $PRETTY_NAME..."

    # shellcheck disable=SC2086
    if android; then
		case "$ARCH" in
			x86_64|amd64) ANDROID_ARCH=x86_64 ;;
			*) ANDROID_ARCH=arm64 ;;
		esac

	    ./Configure android-"${ANDROID_ARCH}" "${BUILD_TYPE}" shared no-makedepend --release threads no-tests \
			-D__ANDROID_API__="${ANDROID_API}"
	else
		./Configure "$target" "${BUILD_TYPE}" shared no-makedepend --release threads no-tests
	fi

    echo "-- Making dependencies..."
    $MAKE depend
}

build() {
    echo "-- Building $PRETTY_NAME..."

	# ksdjbdfkjsjsdbfjhb
	if [ "$PLATFORM" = windows ]; then
	    export CL=" /MP /DEBUG:NONE"

		# microsoft
		# shellcheck disable=SC2154
        TOOLSDIR=$(cygpath -u "$VCToolsInstallDir")
        export PATH="${TOOLSDIR}/bin/Host${VSCMD_ARG_HOST_ARCH}/${VSCMD_ARG_TGT_ARCH}/:$PATH"

		$MAKE build_libs
	elif [ "$PLATFORM" = macos ] || [ "$PLATFORM" = ios ]; then
    	$MAKE SHLIB_VERSION_NUMBER=4 build_libs -j"$(num_procs)"
	else
    	$MAKE SHLIB_VERSION_NUMBER= build_libs -j"$(num_procs)"
	fi
}

strip_libs() {
	echo "-- Stripping shared libraries..."

	case "$PLATFORM" in
		windows) ;;
		android) find "$OUT_DIR" -name "*.so" -exec llvm-strip --strip-all {} \; ;;
		*) find "$OUT_DIR" -name "*.$SHARED_SUFFIX" -exec strip {} \; ;;
	esac
}

## Packaging ##
copy_build_artifacts() {
	outdir="$1"

    echo "-- Copying artifacts..."
	mkdir -p "$outdir"/lib

	# make sometimes does not respect SHLIB_VERSION_NUMBER because fuck you
	mv libssl-*."${SHARED_SUFFIX}" libssl."${SHARED_SUFFIX}"       || true
	mv libcrypto-*."${SHARED_SUFFIX}" libcrypto."${SHARED_SUFFIX}" || true

	for lib in ssl crypto; do
        cp lib${lib}*."${SHARED_SUFFIX}" "$outdir"/lib
        cp lib${lib}*."${STATIC_SUFFIX}" "$outdir"/lib
    done

    # FUCK
    if [ "$PLATFORM" = windows ]; then
        find . -name "*.pdb" -exec cp {} "$outdir" \;
    fi

    cp -r include "$outdir/"
	cp "$ROOTDIR"/cert.h "$outdir"/include/openssl
}

## Cleanup ##
rm -rf "$BUILD_DIR" "$OUT_DIR"
mkdir -p "$BUILD_DIR" "$OUT_DIR"

## Download + Extract ##
download
cd "$BUILD_DIR"
extract

## Configure ##
cd "$DIRECTORY"
configure "$CONFIGURE_TARGET"

## Build ##
build

## Package ##
copy_build_artifacts "$OUT_DIR"

# macOS extra fun: make x86_64 lib too
if [ "$PLATFORM" = macos ]; then
	# cleanup old libs/object files
	rm libcrypto.* libssl.*
	find . -name "*.o" -exec rm {} \;

	TMPDIR="$ROOTDIR"/tmp
	configure darwin64-x86_64-cc
	build

	copy_build_artifacts "$TMPDIR"

	# the fun part
	mkdir -p templibs
	for suffix in a dylib; do
		for lib in crypto ssl; do
			libname=lib${lib}.${suffix}
			lipo "$TMPDIR"/lib/$libname "$OUT_DIR"/lib/$libname \
				-create -output templibs/$libname

			mv templibs/$libname "$OUT_DIR"/lib/$libname
		done
	done
	rm -rf tmp
fi

copy_cmake

strip_libs
package

echo "-- Done! Artifacts are in $ROOTDIR/artifacts, raw lib/include data is in $OUT_DIR"
