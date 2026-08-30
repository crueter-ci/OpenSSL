#!/bin/sh

# shellcheck disable=SC1091

set -e

. tools/common.sh

cd "$DIRECTORY"

if android; then
	: "${ANDROID_NDK_ROOT:?-- You must supply the ANDROID_NDK_ROOT environment variable.}"
	: "${ANDROID_API:=23}"
	android_paths
fi

configure() {
	_group "Configuring $PRETTY_NAME"

    if android; then
		case "$ARCH" in
			amd64) ANDROID_ARCH=x86_64 ;;
			aarch64) ANDROID_ARCH=arm64 ;;
		esac

		export CROSS_COMPILE="${CROSS_PREFIX}"

	    ./Configure android-"${ANDROID_ARCH}" no-asm no-shared no-makedepend --release threads no-tests \
			-D__ANDROID_API__="${ANDROID_API}" \
			no-docs enable-camellia enable-ec enable-ec2m enable-sm2 enable-srp enable-idea enable-mdc2 enable-rc5 enable-rfc3779 \
			enable-quic enable-fips --prefix="$PWD/../out" --libdir=lib no-apps

		# bruh
		sed -i "s|CROSS_COMPILE=|CROSS_COMPILE=${CROSS_PREFIX}\/|" Makefile

		# shellcheck disable=SC2016
		sed -i 's/RANLIB=$(CROSS_COMPILE):/RANLIB=$(CROSS_COMPILE)llvm-ranlib/' Makefile
	else
		./Configure "$CONFIGURE_TARGET" no-asm no-shared no-makedepend --release threads no-tests \
			no-docs enable-camellia enable-ec enable-ec2m enable-sm2 enable-srp enable-idea enable-mdc2 enable-rc5 enable-rfc3779 enable-asm \
			enable-quic enable-fips --prefix="$PWD/../out" --libdir=lib no-apps
	fi

	# ccache
	if [ -n "$SCCACHE_PATH" ]; then
		if windows; then
			SCCACHE_PATH="$(cygpath -u "$SCCACHE_PATH")"
		fi

		sed -i "s|^CC=|CC=${SCCACHE_PATH} |" Makefile
		sed -i "s|^CXX=|CXX=${SCCACHE_PATH} |" Makefile
	fi

	_end
}

configure