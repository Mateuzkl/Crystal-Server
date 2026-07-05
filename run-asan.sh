#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ -n "${CRYSTAL_ASAN_BIN:-}" ]]; then
  BIN="${CRYSTAL_ASAN_BIN}"
elif [[ -x "${SCRIPT_DIR}/build-asan-linux/bin/crystalserver-debug" ]]; then
  BIN="${SCRIPT_DIR}/build-asan-linux/bin/crystalserver-debug"
elif [[ -x "${SCRIPT_DIR}/build-asan-linux/bin/crystalserver" ]]; then
  BIN="${SCRIPT_DIR}/build-asan-linux/bin/crystalserver"
else
  BIN="${SCRIPT_DIR}/crystalserver"
fi

if [[ ! -x "${BIN}" ]]; then
  echo "Binario ASan nao encontrado. Rode: ./build.sh --asan" >&2
  exit 1
fi

export ASAN_OPTIONS="${ASAN_OPTIONS:-detect_leaks=1:halt_on_error=1:abort_on_error=1:symbolize=1}"

cd "${SCRIPT_DIR}"
exec "${BIN}" "$@"
