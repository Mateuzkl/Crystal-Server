#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${CRYSTAL_VALGRIND_LOG:-${SCRIPT_DIR}/valgrind.log}"

if [[ -n "${CRYSTAL_VALGRIND_BIN:-}" ]]; then
  BIN="${CRYSTAL_VALGRIND_BIN}"
elif [[ -x "${SCRIPT_DIR}/build-valgrind-linux/bin/crystalserver" ]]; then
  BIN="${SCRIPT_DIR}/build-valgrind-linux/bin/crystalserver"
else
  BIN="${SCRIPT_DIR}/crystalserver"
fi

if [[ ! -x "${BIN}" ]]; then
  echo "Binario Valgrind nao encontrado. Rode: ./build.sh --valgrind" >&2
  exit 1
fi

command -v valgrind >/dev/null 2>&1 || {
  echo "valgrind nao encontrado. Instale com: sudo apt install valgrind" >&2
  exit 1
}

cd "${SCRIPT_DIR}"
exec valgrind \
  --leak-check=full \
  --show-leak-kinds=definite,indirect,possible \
  --track-origins=yes \
  --num-callers=30 \
  --error-exitcode=99 \
  --log-file="${LOG_FILE}" \
  "${BIN}" "$@"
