#!/bin/sh -e

# TODO: Timestamp-based builds
# Fetch/extract a single time, then have other builds consume that artifact.

## Build variables ##

# shellcheck disable=SC1091
. ./tools/vars.sh

_group() {
    if [ -n "$GITHUB_RUN_ID" ]; then
		echo "##[group]$*"
	else
		echo "======= $* ======="
	fi
}

_end() {
	if [ -n "$GITHUB_RUN_ID" ]; then
		echo "##[endgroup]"
	fi
}

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
	_group "Downloading"
	TRIES=0
	[ -f "$ARTIFACT" ] && return

	while [ "$TRIES" -le 30 ]; do
		if curl -L "$DOWNLOAD_URL" -o "$ARTIFACT"; then
			_end
			return
		fi

		TRIES=$((TRIES + 1))
		echo "-- Download failed, trying again in 5 seconds..."
		sleep 0
	done

	echo "-- Download failed after 30 tries, aborting"
	_end
	exit 1
}

# extract the archive + apply patches
extract() {
	_group "Extracting $PRETTY_NAME $VERSION"
	rm -fr "$DIRECTORY"

	case "$ARTIFACT" in
		*.zip) unzip "$ROOTDIR/$ARTIFACT" >/dev/null ;;
		*.tar.*) $TAR xf "$ROOTDIR/$ARTIFACT" >/dev/null ;;
		*.7z) 7z x "$ROOTDIR/$ARTIFACT" >/dev/null ;;
	esac
	_end
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
	# default to 4 because github actions
	if command -v nproc >/dev/null 2>&1; then
		nproc
	elif command -v sysctl >/dev/null 2>&1; then
		sysctl -n hw.logicalcpu
	elif command -v getconf >/dev/null 2>&1; then
		getconf _NPROCESSORS_ONLN
	else
		echo 4
	fi
}

## Packaging ##
copy_cmake() {
	echo "-- Copying CMake artifacts..."

    cp "$ROOTDIR"/CMakeLists.txt "$OUT_DIR"
}

package() {
    _group "Packaging"
    mkdir -p "$ROOTDIR/artifacts"

	TARBALL=$FILENAME-$PLATFORM-$ARCH-$VERSION.tar

    cd "$OUT_DIR"
    tar cf "$ROOTDIR/artifacts/$TARBALL" ./*

    cd "$ROOTDIR/artifacts"
    zstd -10 "$TARBALL"
    rm "$TARBALL"

    sums "$TARBALL.zst"
	_end
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
	ios)
		SHARED_SUFFIX=dylib
		CONFIGURE_TARGET=ios64-xcrun

		export CFLAGS="-mios-version-min=16.0"
		export CXXFLAGS="-mios-version-min=16.0"
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

## Platform Utility Functions ##

linux() {
	[ "$PLATFORM" = linux ]
}

macos() {
	[ "$PLATFORM" = macos ]
}

msvc() {
	[ "$PLATFORM" = windows ]
}

mingw() {
	[ "$PLATFORM" = mingw ]
}

windows() {
	msvc || mingw
}

android() {
	[ "$PLATFORM" = android ]
}

arm64() {
	[ "$ARCH" = arm64 ] || [ "$ARCH" = aarch64 ]
}

amd64() {
	[ "$ARCH" = amd64 ] || [ "$ARCH" = x86_64 ]
}