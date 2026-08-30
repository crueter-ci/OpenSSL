#!/bin/sh -e

set -e

# shellcheck disable=SC1091

. tools/common.sh

ROOTDIR="$PWD"

copy_build_artifacts() {
	_group "Copying build artifacts"

	make install -C "$DIRECTORY"
	rm -rf out/lib/cmake out/lib/ossl-modules out/lib/pkgconfig out/ssl out/bin
	cp cert.h out/include/openssl

	_end
}

copy_build_artifacts
copy_cmake
package

echo "-- Done! Artifacts are in $ROOTDIR/artifacts, raw lib/include data is in out"