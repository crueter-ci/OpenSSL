#!/bin/sh -e

# Generate build matrix

# {runs-on, arch, platform}
target() {
	os="$1"
	arch="$2"
	platform="$3"

	cat <<EOF
    {"runs-on": "$os", "arch": "$arch", "platform": "$platform"}
EOF
}

echo "{"

# winblows
for plat in windows mingw; do
	echo "$(target windows-latest amd64 $plat),"
	echo "$(target windows-11-arm aarch64 $plat),"
done

# loonix
echo "$(target ubuntu-latest amd64 linux),"
echo "$(target ubuntu-24.04-arm aarch64 linux),"

# android
for arch in amd64 aarch64; do
	echo "$(target ubuntu-latest $arch android),"
done

# apple
echo "$(target macos-latest aarch64 macos),"
target macos-latest aarch64 ios

echo "}"