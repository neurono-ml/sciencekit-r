#!/usr/bin/env bash
# Build the `sciencekit_ffi` static library (`libsciencekit_ffi.a`) from a
# checkout of https://github.com/neurono-ml/sciencekit and install it into
# `tools/native/` where `src/Makevars` links it into `sciencekitr.so`.
#
# Usage:
#   scripts/build-native-library.sh [path-to-sciencekit-checkout]
set -euo pipefail

binding_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repository_root="${1:-${SCIENCEKIT_REPOSITORY:-}}"

if [[ -z "$repository_root" ]]; then
  candidate="$binding_root/../sciencekit"
  if [[ -f "$candidate/Cargo.toml" ]]; then
    repository_root="$(cd "$candidate" && pwd)"
  fi
fi

if [[ -z "$repository_root" || ! -f "$repository_root/Cargo.toml" ]]; then
  cat >&2 <<'USAGE'
error: no sciencekit checkout found.

Pass the path to a checkout of https://github.com/neurono-ml/sciencekit:

  scripts/build-native-library.sh /path/to/sciencekit

or set SCIENCEKIT_REPOSITORY to the same path.
USAGE
  exit 2
fi

cd "$repository_root"

if [[ ! -f "$repository_root/Cargo.lock" ]]; then
  cargo update -p psm --precise 0.1.24
fi

echo "Building sciencekit_ffi from $repository_root"
cargo build -p sciencekit_ffi --release

target_directory="${CARGO_TARGET_DIR:-$repository_root/target}"
library_path="$target_directory/release/libsciencekit_ffi.a"

if [[ ! -f "$library_path" ]]; then
  echo "error: expected static archive $library_path was not produced" >&2
  exit 1
fi

mkdir -p "$binding_root/tools/native"
install -m 0644 "$library_path" "$binding_root/tools/native/libsciencekit_ffi.a"
echo "Installed $binding_root/tools/native/libsciencekit_ffi.a"
