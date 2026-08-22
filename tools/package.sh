#!/bin/sh -e

set -e

# shellcheck disable=SC1091

. tools/common.sh

copy_build_artifacts() {
	_group "Copying build artifacts"

	rm -rf out/lib/cmake out/lib/ossl-modules out/lib/pkgconfig out/ssl out/bin
	cp cert.h out/include/openssl

	_end
}

copy_cmake() {
	_group "Copying CMake artifacts"

    cp "$ROOTDIR"/CMakeLists.txt out

	_end
}

sums() {
	for file in "$@"; do
		if ! command -v sha512sum >/dev/null 2>&1; then
			must_install sha512
			sha512 "$file" | awk '{print $4}' | tr -d "\n" >"$file".sha512sum
		else
			must_install sha512sum
			sha512sum "$file" | cut -d " " -f1 | tr -d "\n" >"$file".sha512sum
		fi
	done
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

copy_build_artifacts
package

echo "-- Done! Artifacts are in $ROOTDIR/artifacts, raw lib/include data is in out"