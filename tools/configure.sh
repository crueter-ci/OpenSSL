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

	    ./Configure android-"${ANDROID_ARCH}" no-asm no-shared no-makedepend --release threads no-tests \
			-D__ANDROID_API__="${ANDROID_API}" \
			no-docs enable-camellia enable-ec enable-ec2m enable-sm2 enable-srp enable-idea enable-mdc2 enable-rc5 enable-rfc3779 enable-asm \
			enable-quic enable-fips --prefix="$PWD/../out" --libdir=lib no-apps
	else
		./Configure "$CONFIGURE_TARGET" no-asm no-shared no-makedepend --release threads no-tests \
			no-docs enable-camellia enable-ec enable-ec2m enable-sm2 enable-srp enable-idea enable-mdc2 enable-rc5 enable-rfc3779 enable-asm \
			enable-quic enable-fips --prefix="$PWD/../out" --libdir=lib no-apps
	fi

	_end
}

configure