#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${CRYSTAL_DEPS_PREFIX:-${HOME}/.local}"
CACHE_DIR="${CRYSTAL_DEPS_CACHE:-${HOME}/.cache/crystal-build}"
BUILD_DIR="${CRYSTAL_BUILD_DIR:-build-native}"
BUILD_TYPE="${CRYSTAL_BUILD_TYPE:-RelWithDebInfo}"
JOBS="${JOBS:-}"
CLEAN_BUILD=0
SKIP_DEPS=0
FORCE_OS=0
ASAN_BUILD=0
VALGRIND_BUILD=0
RUN_AFTER_BUILD=0
NO_RUN_AFTER_BUILD=0
SERVER_ARGS=()

if [[ -t 1 ]]; then
  BOLD=$'\033[1m'
  RED=$'\033[31m'
  GREEN=$'\033[32m'
  YELLOW=$'\033[33m'
  BLUE=$'\033[34m'
  CYAN=$'\033[36m'
  RESET=$'\033[0m'
else
  BOLD=""
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  CYAN=""
  RESET=""
fi

info() { printf '%b[INFO]%b %s\n' "${BLUE}" "${RESET}" "$*"; }
ok() { printf '%b[OK]%b %s\n' "${GREEN}" "${RESET}" "$*"; }
warn() { printf '%b[WARN]%b %s\n' "${YELLOW}" "${RESET}" "$*"; }
fail() { printf '%b[ERRO]%b %s\n' "${RED}" "${RESET}" "$*" >&2; }
die() { fail "$*"; exit 1; }

usage() {
  cat <<'EOF'
Uso: ./build.sh [opcoes]

Compila Crystal Server no Ubuntu 24.04 sem vcpkg.

Opcoes:
  --clean          Limpa a pasta de build atual antes de configurar
  --debug          Usa CMAKE_BUILD_TYPE=Debug
  --release        Usa CMAKE_BUILD_TYPE=Release
  --asan           Build Debug com AddressSanitizer
  --valgrind       Build RelWithDebInfo amigavel para Valgrind
  --run            Roda o servidor apos compilar
  --no-run         So compila; nao abre ASan/Valgrind automaticamente
  --jobs N         Numero de jobs paralelos
  --skip-deps      Pula instalacao/verificacao de dependencias
  --force-os       Permite rodar fora do Ubuntu 24.04
  -h, --help       Mostra esta ajuda
  --               Passa os argumentos seguintes para o servidor

Variaveis:
  CRYSTAL_DEPS_PREFIX   Prefixo dos headers manuais (padrao: $HOME/.local)
  CRYSTAL_BUILD_DIR     Pasta de build (padrao: build-native)
  JOBS                  Jobs paralelos

Exemplos:
  ./build.sh
  ./build.sh --valgrind
  ./build.sh --asan
  ./build.sh --valgrind --no-run
EOF
}

parse_args() {
  while (($#)); do
    case "$1" in
      --)
        shift
        SERVER_ARGS=("$@")
        break
        ;;
      --clean)
        CLEAN_BUILD=1
        shift
        ;;
      --debug)
        BUILD_TYPE="Debug"
        shift
        ;;
      --release)
        BUILD_TYPE="Release"
        shift
        ;;
      --asan|asan|--run-asan|run-asan)
        ASAN_BUILD=1
        RUN_AFTER_BUILD=1
        BUILD_TYPE="Debug"
        if [[ -z "${CRYSTAL_BUILD_DIR:-}" ]]; then
          BUILD_DIR="build-asan-linux"
        fi
        shift
        ;;
      --valgrind|valgrind|--run-valgrind|run-valgrind|--valriqd|valriqd|--run-valriqd|run-valriqd)
        VALGRIND_BUILD=1
        RUN_AFTER_BUILD=1
        BUILD_TYPE="RelWithDebInfo"
        if [[ -z "${CRYSTAL_BUILD_DIR:-}" ]]; then
          BUILD_DIR="build-valgrind-linux"
        fi
        shift
        ;;
      --run|run)
        RUN_AFTER_BUILD=1
        shift
        ;;
      --no-run|--build-only|build-only)
        NO_RUN_AFTER_BUILD=1
        shift
        ;;
      --jobs)
        [[ $# -ge 2 ]] || die "--jobs precisa de um valor"
        JOBS="$2"
        shift 2
        ;;
      --skip-deps)
        SKIP_DEPS=1
        shift
        ;;
      --force-os)
        FORCE_OS=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Opcao desconhecida: $1"
        ;;
    esac
  done

  if [[ "${ASAN_BUILD}" -eq 1 && "${VALGRIND_BUILD}" -eq 1 ]]; then
    die "Use --asan ou --valgrind, nao os dois juntos."
  fi

  if [[ "${NO_RUN_AFTER_BUILD}" -eq 1 ]]; then
    RUN_AFTER_BUILD=0
  fi
}

init_jobs() {
  if [[ -z "${JOBS}" ]]; then
    JOBS="$(nproc 2>/dev/null || printf '2')"
  fi
}

init_sudo() {
  if [[ "${EUID}" -eq 0 ]]; then
    SUDO=()
  else
    command -v sudo >/dev/null 2>&1 || die "sudo nao encontrado. Instale sudo ou rode como root."
    SUDO=(sudo)
  fi
}

check_os() {
  [[ -r /etc/os-release ]] || die "Nao consegui ler /etc/os-release"
  # shellcheck disable=SC1091
  source /etc/os-release

  info "Sistema detectado: ${PRETTY_NAME:-unknown}"
  if [[ "${ID:-}" != "ubuntu" || "${VERSION_ID:-}" != "24.04" ]]; then
    if [[ "${FORCE_OS}" -eq 1 ]]; then
      warn "Script feito para Ubuntu 24.04; continuando por --force-os."
    else
      die "Este build.sh foi feito para Ubuntu 24.04. Use --force-os se quiser tentar mesmo assim."
    fi
  fi
}

apt_install_missing() {
  local -a missing=()
  local pkg

  for pkg in "$@"; do
    if ! dpkg-query -W -f='${Status}' "${pkg}" 2>/dev/null | grep -q "install ok installed"; then
      missing+=("${pkg}")
    fi
  done

  if ((${#missing[@]} == 0)); then
    ok "Pacotes apt ja instalados."
    return
  fi

  info "Instalando pacotes apt: ${missing[*]}"
  "${SUDO[@]}" apt-get install -y "${missing[@]}"
}

install_apt_deps() {
  command -v apt-get >/dev/null 2>&1 || die "apt-get nao encontrado."
  command -v dpkg-query >/dev/null 2>&1 || die "dpkg-query nao encontrado."

  info "Atualizando indices apt"
  "${SUDO[@]}" apt-get update
  apt_install_missing software-properties-common

  if command -v add-apt-repository >/dev/null 2>&1; then
    info "Garantindo repositorio universe"
    "${SUDO[@]}" add-apt-repository -y universe >/dev/null
    "${SUDO[@]}" apt-get update
  fi

  local -a packages=(
    git
    ca-certificates
    curl
    build-essential
    cmake
    ninja-build
    pkg-config
    ccache
    valgrind
    tar
    unzip
    zip
    libcurl4-openssl-dev
    libgmp-dev
    libluajit-5.1-dev
    libmariadb-dev
    libmariadb-dev-compat
    libprotobuf-dev
    protobuf-compiler
    zlib1g-dev
    libabsl-dev
    libasio-dev
    libboost-locale-dev
    libpugixml-dev
    libspdlog-dev
    libfmt-dev
    nlohmann-json3-dev
    libargon2-dev
    libmagicenum-dev
    libparallel-hashmap-dev
  )

  apt_install_missing "${packages[@]}"
}

sync_repo() {
  local name="$1"
  local url="$2"
  local dir="${CACHE_DIR}/${name}"

  mkdir -p "${CACHE_DIR}"
  if [[ -d "${dir}/.git" ]]; then
    info "Atualizando ${name}" >&2
    git -C "${dir}" pull --ff-only >&2 || warn "Nao consegui atualizar ${name}; usando copia local." >&2
  else
    info "Baixando ${name}" >&2
    git clone --depth 1 "${url}" "${dir}" >&2
  fi

  printf '%s\n' "${dir}"
}

copy_dir_candidate() {
  local repo="$1"
  local dest_rel="$2"
  shift 2

  local candidate
  for candidate in "$@"; do
    if [[ -d "${repo}/${candidate}" ]]; then
      mkdir -p "$(dirname "${PREFIX}/include/${dest_rel}")"
      rm -rf "${PREFIX}/include/${dest_rel}"
      cp -a "${repo}/${candidate}" "${PREFIX}/include/${dest_rel}"
      ok "Header instalado: ${dest_rel}"
      return
    fi
  done

  die "Nao encontrei headers para ${dest_rel} em ${repo}"
}

copy_file_candidate() {
  local repo="$1"
  local dest_rel="$2"
  shift 2

  local candidate
  for candidate in "$@"; do
    if [[ -f "${repo}/${candidate}" ]]; then
      mkdir -p "$(dirname "${PREFIX}/include/${dest_rel}")"
      cp "${repo}/${candidate}" "${PREFIX}/include/${dest_rel}"
      ok "Header instalado: ${dest_rel}"
      return
    fi
  done

  die "Nao encontrei header ${dest_rel} em ${repo}"
}

install_header_deps() {
  mkdir -p "${PREFIX}/include"

  local repo

  repo="$(sync_repo eventpp https://github.com/wqking/eventpp.git)"
  copy_dir_candidate "${repo}" eventpp include/eventpp eventpp

  repo="$(sync_repo mio https://github.com/vimpunk/mio.git)"
  copy_dir_candidate "${repo}" mio include/mio single_include/mio mio

  repo="$(sync_repo magic_enum https://github.com/Neargye/magic_enum.git)"
  copy_dir_candidate "${repo}" magic_enum include/magic_enum magic_enum

  repo="$(sync_repo atomic_queue https://github.com/max0x7ba/atomic_queue.git)"
  copy_dir_candidate "${repo}" atomic_queue include/atomic_queue atomic_queue

  repo="$(sync_repo boost_di https://github.com/boost-ext/di.git)"
  copy_file_candidate "${repo}" boost/di.hpp include/boost/di.hpp boost/di.hpp
  if [[ -d "${repo}/include/boost/di" ]]; then
    rm -rf "${PREFIX}/include/boost/di"
    cp -a "${repo}/include/boost/di" "${PREFIX}/include/boost/di"
  fi

  repo="$(sync_repo bshoshany_thread_pool https://github.com/bshoshany/thread-pool.git)"
  copy_file_candidate "${repo}" BS_thread_pool.hpp include/BS_thread_pool.hpp BS_thread_pool.hpp

  [[ -f "${PREFIX}/include/eventpp/eventdispatcher.h" ]] || die "eventpp nao foi instalado corretamente."
  [[ -f "${PREFIX}/include/mio/mmap.hpp" ]] || die "mio nao foi instalado corretamente."
  [[ -f "${PREFIX}/include/magic_enum/magic_enum.hpp" ]] || die "magic_enum nao foi instalado corretamente."
  [[ -f "${PREFIX}/include/atomic_queue/atomic_queue.h" ]] || die "atomic_queue nao foi instalado corretamente."
  [[ -f "${PREFIX}/include/boost/di.hpp" ]] || die "boost-ext/di nao foi instalado corretamente."
  [[ -f "${PREFIX}/include/BS_thread_pool.hpp" ]] || die "BS_thread_pool nao foi instalado corretamente."
}

configure_build() {
  cd "${SCRIPT_DIR}"

  if [[ "${CLEAN_BUILD}" -eq 1 ]]; then
    info "Limpando ${BUILD_DIR}"
    rm -rf "${SCRIPT_DIR:?}/${BUILD_DIR}"
  fi

  mkdir -p "${BUILD_DIR}"

  if [[ ! -f config.lua && -f config.lua.dist ]]; then
    info "Criando config.lua a partir de config.lua.dist"
    cp config.lua.dist config.lua
  fi

  unset VCPKG_ROOT
  unset VCPKG_DEFAULT_TRIPLET

  info "Configurando CMake sem vcpkg"
  local -a cmake_args=(
    -S "${SCRIPT_DIR}"
    -B "${SCRIPT_DIR}/${BUILD_DIR}"
    -G Ninja
    -DUSE_VCPKG=OFF
    -DCMAKE_BUILD_TYPE="${BUILD_TYPE}"
    -DCMAKE_PREFIX_PATH="${PREFIX}"
    -DCMAKE_INCLUDE_PATH="${PREFIX}/include"
    -DCMAKE_LIBRARY_PATH="${PREFIX}/lib;${PREFIX}/lib64"
    -DBUILD_TESTS=OFF
    -DFEATURE_METRICS=OFF
    -DOPTIONS_ENABLE_CCACHE=ON
    -DOPTIONS_ENABLE_SCCACHE=OFF
  )

  if [[ "${ASAN_BUILD}" -eq 1 ]]; then
    cmake_args+=(
      -DASAN_ENABLED=ON
      -DVALGRIND_ENABLED=OFF
      -DOPTIONS_ENABLE_IPO=OFF
      -DSPEED_UP_BUILD_UNITY=OFF
      -DUSE_PRECOMPILED_HEADER=ON
    )
  elif [[ "${VALGRIND_BUILD}" -eq 1 ]]; then
    cmake_args+=(
      -DASAN_ENABLED=OFF
      -DVALGRIND_ENABLED=ON
      -DOPTIONS_ENABLE_IPO=OFF
      -DSPEED_UP_BUILD_UNITY=OFF
      -DUSE_PRECOMPILED_HEADER=ON
    )
  else
    cmake_args+=(
      -DASAN_ENABLED=OFF
      -DVALGRIND_ENABLED=OFF
    )
  fi

  cmake "${cmake_args[@]}"
}

build_project() {
  info "Compilando com ${JOBS} jobs"
  cmake --build "${SCRIPT_DIR}/${BUILD_DIR}" --parallel "${JOBS}"
}

copy_binary() {
  local built_bin="${SCRIPT_DIR}/${BUILD_DIR}/bin/crystalserver"
  local final_bin="${SCRIPT_DIR}/crystalserver"

  if [[ ! -f "${built_bin}" && -f "${SCRIPT_DIR}/${BUILD_DIR}/bin/crystalserver-debug" ]]; then
    built_bin="${SCRIPT_DIR}/${BUILD_DIR}/bin/crystalserver-debug"
  fi

  [[ -f "${built_bin}" ]] || die "Binario nao encontrado em ${built_bin}"

  if [[ -f "${final_bin}" ]]; then
    info "Salvando binario antigo em crystalserver.old"
    cp "${final_bin}" "${final_bin}.old"
  fi

  cp "${built_bin}" "${final_bin}"
  chmod +x "${final_bin}"
  ok "Binario pronto: ${final_bin}"

  if command -v ldd >/dev/null 2>&1; then
    info "Verificando bibliotecas dinamicas"
    if ldd "${final_bin}" | tee "${SCRIPT_DIR}/${BUILD_DIR}/ldd.log" | grep -q "not found"; then
      warn "ldd encontrou biblioteca ausente. Veja ${BUILD_DIR}/ldd.log"
    else
      ok "ldd sem bibliotecas ausentes."
    fi
  fi
}

finish_or_run() {
  if [[ "${RUN_AFTER_BUILD}" -eq 1 ]]; then
    if [[ "${VALGRIND_BUILD}" -eq 1 ]]; then
      ok "Build Valgrind pronto. Abrindo com Valgrind agora."
      info "Log: ${CRYSTAL_VALGRIND_LOG:-${SCRIPT_DIR}/valgrind.log}"
      exec bash "${SCRIPT_DIR}/run-valgrind.sh" "${SERVER_ARGS[@]}"
    fi

    if [[ "${ASAN_BUILD}" -eq 1 ]]; then
      ok "Build ASan pronto. Abrindo com AddressSanitizer agora."
      exec bash "${SCRIPT_DIR}/run-asan.sh" "${SERVER_ARGS[@]}"
    fi

    ok "Build pronto. Abrindo Crystal Server agora."
    exec "${SCRIPT_DIR}/crystalserver" "${SERVER_ARGS[@]}"
  fi

  if [[ "${VALGRIND_BUILD}" -eq 1 ]]; then
    printf '\n%bTudo pronto.%b Rode: %s\n' "${GREEN}" "${RESET}" "${SCRIPT_DIR}/run-valgrind.sh"
  elif [[ "${ASAN_BUILD}" -eq 1 ]]; then
    printf '\n%bTudo pronto.%b Rode: %s\n' "${GREEN}" "${RESET}" "${SCRIPT_DIR}/run-asan.sh"
  else
    printf '\n%bTudo pronto.%b Rode: %s\n' "${GREEN}" "${RESET}" "${SCRIPT_DIR}/crystalserver"
  fi
}

main() {
  parse_args "$@"
  init_jobs
  init_sudo
  check_os

  printf '\n%bCrystal Server native build - Ubuntu 24.04 sem vcpkg%b\n\n' "${BOLD}${CYAN}" "${RESET}"
  info "Prefixo de headers manuais: ${PREFIX}"
  info "Build dir: ${BUILD_DIR}"
  info "Build type: ${BUILD_TYPE}"
  if [[ "${ASAN_BUILD}" -eq 1 ]]; then
    info "Diagnostico: AddressSanitizer"
  elif [[ "${VALGRIND_BUILD}" -eq 1 ]]; then
    info "Diagnostico: Valgrind"
  fi

  if [[ "${SKIP_DEPS}" -eq 0 ]]; then
    install_apt_deps
    install_header_deps
  else
    warn "Pulando dependencias por --skip-deps"
  fi

  configure_build
  build_project
  copy_binary
  finish_or_run
}

main "$@"
