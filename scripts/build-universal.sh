#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CORE_DIR="${NM_CORE_DIR:-${ROOT_DIR}/NM_Core}"

PROFILE="debug"
if [[ "${CONFIGURATION:-}" == "Release" ]]; then
  PROFILE="release"
fi
if [[ "${1:-}" == "--release" || "${1:-}" == "release" ]]; then
  PROFILE="release"
fi

ARCHS=(arm64 amd64)

if ! command -v go >/dev/null 2>&1; then
  echo "go not found. Install Go first." >&2
  exit 1
fi

cd "${CORE_DIR}"

OUT_BASE="${TARGET_BUILD_DIR:-${ROOT_DIR}/build}"
OUT_DIR="${OUT_BASE}/go-universal"
mkdir -p "${OUT_DIR}"

LIBS=()
for ARCH in "${ARCHS[@]}"; do
  ARCH_DIR="${OUT_DIR}/${ARCH}"
  mkdir -p "${ARCH_DIR}"
  if [[ "${PROFILE}" == "release" ]]; then
    GOOS=darwin GOARCH="${ARCH}" CGO_ENABLED=1 \
      go build -ldflags "-s -w" -buildmode=c-archive -o "${ARCH_DIR}/libnm_core.a" .
  else
    GOOS=darwin GOARCH="${ARCH}" CGO_ENABLED=1 \
      go build -buildmode=c-archive -o "${ARCH_DIR}/libnm_core.a" .
  fi
  LIBS+=("${ARCH_DIR}/libnm_core.a")
done

lipo -create "${LIBS[@]}" -output "${OUT_DIR}/libnm_core.a"

# Header is emitted next to the archive by Go.
if [[ -f "${OUT_DIR}/arm64/libnm_core.h" ]]; then
  cp "${OUT_DIR}/arm64/libnm_core.h" "${OUT_DIR}/libnm_core.h"
fi

echo "Universal library: ${OUT_DIR}/libnm_core.a"
if [[ -f "${OUT_DIR}/nm_core.h" ]]; then
  echo "Header: ${OUT_DIR}/nm_core.h"
fi
