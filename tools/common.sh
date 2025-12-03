#!/bin/sh -e

## Build variables ##

# shellcheck disable=SC1091
. ./tools/vars.sh

ROOTDIR="$PWD"
: "${OUT_DIR:=$PWD/out}"
: "${PLATFORM:?-- You must supply the PLATFORM environment variable.}"

## Command Checks ##

must_install() {
	for cmd in "$@"; do
		command -v "$cmd" >/dev/null 2>&1 || { echo "-- $cmd must be installed" && exit 1; }
	done
}

must_install curl zstd

case "$ARTIFACT" in
	*.zip) must_install unzip ;;
	*.tar.*) ;;
	*.7z) must_install 7z ;;
	*) echo "-- Unsupported extension ${ARTIFACT##.*}"; exit 1 ;;
esac

## Utility Functions ##

# download
download() {
	TRIES=0
	[ -f "$ARTIFACT" ] && return

	while [ "$TRIES" -le 30 ]; do
		curl -L "$DOWNLOAD_URL" -o "$ARTIFACT" && return
		TRIES=$((TRIES + 1))
		echo "-- Download failed, trying again in 5 seconds..."
		sleep 0
	done

	echo "-- Download failed after 30 tries, aborting"
	exit 1
}

# extract the archive + apply patches
extract() {
	echo "-- Extracting $PRETTY_NAME $VERSION"
	rm -fr "$DIRECTORY"

	case "$ARTIFACT" in
		*.zip) unzip "$ROOTDIR/$ARTIFACT" >/dev/null ;;
		*.tar.*) $TAR xf "$ROOTDIR/$ARTIFACT" >/dev/null ;;
		*.7z) 7z x "$ROOTDIR/$ARTIFACT" >/dev/null ;;
	esac
}

# generate sha1, 256, and 512 sums for a file
sums() {
	for file in "$@"; do
		for algo in 1 256 512; do
			if ! command -v sha${algo}sum >/dev/null 2>&1; then
				sha${algo} "$file" | awk '{print $4}' | tr -d "\n" > "$file".sha${algo}sum
			else
				sha${algo}sum "$file" | cut -d " " -f1 | tr -d "\n" > "$file".sha${algo}sum
			fi
		done
	done
}

# nproc
num_procs() {
	nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null \
		|| getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4
}

## Packaging ##
copy_cmake() {
	echo "-- Copying CMake artifacts..."

    cp "$ROOTDIR"/CMakeLists.txt "$OUT_DIR"
}

package() {
    echo "-- Packaging..."
    mkdir -p "$ROOTDIR/artifacts"

	TARBALL=$FILENAME-$PLATFORM-$ARCH-$VERSION.tar

    cd "$OUT_DIR"
    tar cf "$ROOTDIR/artifacts/$TARBALL" ./*

    cd "$ROOTDIR/artifacts"
    zstd -10 "$TARBALL"
    rm "$TARBALL"

    sums "$TARBALL.zst"
}

## Platform Stuff ##

SHARED_SUFFIX=so
STATIC_SUFFIX=a
MAKE="make"
TAR="tar"

case "$PLATFORM" in
	linux) ;;
	freebsd|openbsd|solaris)
		MAKE="gmake"
		TAR="gtar"
		;;
	macos)
		SHARED_SUFFIX=dylib
		CONFIGURE_TARGET=darwin64-arm64-cc
		;;
	windows)
		SHARED_SUFFIX=dll
		STATIC_SUFFIX=lib
		MAKE=nmake
		;;
	mingw)
		SHARED_SUFFIX=dll
		# the consequences of your actions
		if [ "$ARCH" = arm64 ]; then
			CONFIGURE_TARGET=mingwarm64
			export CC=clang
			export CXX=clang++
			export RC=llvm-windres
		fi
		;;
esac

must_install "$MAKE" "$TAR"

export SHARED_SUFFIX
export STATIC_SUFFIX
export MAKE
export TAR
export CONFIGURE_TARGET

android_paths() {
	export ANDROID_NDK_HOME="$ANDROID_NDK_ROOT"

    for host in linux-x86_64 linux-x86 darwin-x86_64 darwin-x86 windows-x86_64; do
        if [ -d "$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$host/bin" ]; then
            ANDROID_TOOLCHAIN="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$host/bin"
            export PATH="$ANDROID_TOOLCHAIN:$PATH"
            break
        fi
    done
}