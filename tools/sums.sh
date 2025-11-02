#!/bin/sh -e

# Generate SHA1, SHA256, SHA512 sums for all input files.
# Requires: sha*sum, tr, cut

for file in "$@"; do
    for algo in 1 256 512; do
        if [ "$PLATFORM" = "openbsd" ]; then
            sha${algo} "$file" | awk '{print $4}' | tr -d "\n" > "$file".sha${algo}sum
        else
            sha${algo}sum "$file" | cut -d " " -f1 | tr -d "\n" > "$file".sha${algo}sum
        fi
    done
done