<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:051923,45:0f766e,100:22c55e&height=220&section=header&text=Crystal%20Server&fontSize=56&fontColor=ffffff&fontAlignY=38&desc=Open-source%20MMORPG%20server%20emulator&descAlignY=60&descSize=17&animation=fadeIn" alt="Crystal Server" />
</p>

<div align="center">

[![Ubuntu Build](https://github.com/Mateuzkl/Crystal-Server/actions/workflows/build-ubuntu.yml/badge.svg)](https://github.com/Mateuzkl/Crystal-Server/actions/workflows/build-ubuntu.yml)
[![License](https://img.shields.io/github/license/Mateuzkl/Crystal-Server?style=flat-square)](LICENSE)
[![Discord](https://img.shields.io/discord/1310943869923495988?style=flat-square&logo=discord&logoColor=white)](https://discord.gg/zm4MTKtQQh)

<br />

![Engine](https://img.shields.io/badge/ENGINE-Crystal%20Server-0f766e?style=for-the-badge)
![Protocol](https://img.shields.io/badge/PROTOCOL-15.25-22c55e?style=for-the-badge)
![C++](https://img.shields.io/badge/C++-23-00599C?style=for-the-badge&logo=cplusplus&logoColor=white)
![LuaJIT](https://img.shields.io/badge/LuaJIT-5.1-2C2D72?style=for-the-badge&logo=lua&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=for-the-badge&logo=mariadb&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)

<br />
<br />

**Crystal Server** is a free and open-source MMORPG server emulator written in C++.

It is based on [The Forgotten Server](https://github.com/otland/forgottenserver), forked from [Open Tibia](https://github.com/opentibia/server), and focused on a stable OTServ experience.

[Discord](https://discord.gg/zm4MTKtQQh) | [Issues](https://github.com/Mateuzkl/Crystal-Server/issues) | [Game Client](https://github.com/zimbadev/gameclient/releases) | [Map Editor](https://github.com/zimbadev/rme-crystalserver/releases)

</div>

---

## Highlights

| Area | Details |
|---|---|
| Core | C++23, CMake, LuaJIT, MySQL/MariaDB and modern Crystal systems |
| Protocol | Client protocol 15.25, with old protocol support controlled by config |
| Build | Native Ubuntu/WSL build through one simple `build.sh` command |
| Diagnostics | AddressSanitizer and Valgrind builds that can run automatically |
| Tools | Compatible with the Crystal game client, Mehah OTClient and RME Crystal |

---

## Quick Start

For Ubuntu 24.04 or WSL:

```bash
git clone https://github.com/Mateuzkl/Crystal-Server.git
cd Crystal-Server

chmod +x build.sh run-asan.sh run-valgrind.sh
./build.sh
./crystalserver
```

The script installs the required packages, prepares header-only dependencies in `$HOME/.local`, configures CMake without vcpkg and copies the final binary to `./crystalserver`.

---

## Build Commands

| Goal | Command |
|---|---|
| Normal build | `./build.sh` |
| Build and run | `./build.sh --run` |
| Clean normal build | `./build.sh --clean` |
| Release build | `./build.sh --release` |
| Debug build | `./build.sh --debug` |
| Build ASan | `./build.sh --asan` |
| Build Valgrind | `./build.sh --valgrind` |
| Build and run ASan | `./build.sh --asan --run` |
| Build and run Valgrind | `./build.sh --valgrind --run` |
| Use custom jobs | `./build.sh --jobs 4` |
| Skip dependency install | `./build.sh --skip-deps` |
| Try outside Ubuntu 24.04 | `./build.sh --force-os` |

---

## ASan

Use AddressSanitizer when you are hunting crashes, use-after-free bugs, invalid memory access or leaks.

Build:

```bash
./build.sh --asan
```

Build and run in one command:

```bash
./build.sh --asan --run
```

Run an existing ASan build:

```bash
./run-asan.sh
```

If the ASan binary is missing, `run-asan.sh` builds it first. The ASan build uses `build-asan-linux` and runs with strict defaults:

```bash
ASAN_OPTIONS=detect_leaks=1:halt_on_error=1:abort_on_error=1:symbolize=1
```

---

## Valgrind

Use Valgrind when you need a slower but very detailed memory report.

Build:

```bash
./build.sh --valgrind
```

Build and run in one command:

```bash
./build.sh --valgrind --run
```

Run an existing Valgrind build:

```bash
./run-valgrind.sh
```

If the Valgrind binary is missing, `run-valgrind.sh` builds it first. The Valgrind build uses `build-valgrind-linux` and writes the report to:

```bash
valgrind.log
```

To use a custom binary or log path:

```bash
CRYSTAL_VALGRIND_BIN=./build-valgrind-linux/bin/crystalserver \
CRYSTAL_VALGRIND_LOG=./valgrind.log \
./run-valgrind.sh
```

---

## Clients And Tools

| Tool | Link |
|---|---|
| Crystal game client | [Download](https://github.com/zimbadev/gameclient/releases) |
| Mehah OTClient | [Repository](https://github.com/mehah/otclient) |
| Remere's Map Editor for Crystal | [Download](https://github.com/zimbadev/rme-crystalserver/releases) |
| Monster Loot and Elements tool | [Open](https://crystalsever.vercel.app/) |

---

## Contributing

Bug reports and pull requests are welcome.

Keep pull requests focused, avoid map-only changes, follow the project indentation and explain what changed and why.

Use the [GitHub issue tracker](https://github.com/Mateuzkl/Crystal-Server/issues) for bugs, build problems and reproducible crashes. Logs from ASan or Valgrind are especially helpful.

---

## Credits

Crystal Server exists thanks to:

- [Open Tibia](https://github.com/opentibia/server) and its contributors.
- [The Forgotten Server](https://github.com/otland/forgottenserver) and its contributors.
- [Crystal Server](https://github.com/zimbadev/crystalserver) and its contributors.

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:22c55e,55:0f766e,100:051923&height=120&section=footer&text=Crystal%20Server&fontSize=18&fontColor=ffffff&fontAlignY=68" alt="Crystal Server footer" />
</p>
