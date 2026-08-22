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

# default platform
case "$(uname -s)" in
Linux) : "${PLATFORM:=linux}" ;;
Darwin) : "${PLATFORM:=macos}" ;;
# TODO: detect msys2
*) : "${PLATFORM:?-- You must supply the PLATFORM environment variable.}" ;;
esac

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

## Platform Stuff ##

SHARED_SUFFIX=so
STATIC_SUFFIX=a
MAKE="make"
TAR="tar"

case "$PLATFORM" in
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
		if [ "$ARCH" = aarch64 ]; then
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