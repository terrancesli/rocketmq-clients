# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is the **Apache RocketMQ Clients** monorepo — a collection of gRPC-based client SDKs for RocketMQ 5.x. All clients follow the unified [rocketmq-apis](https://github.com/apache/rocketmq-apis) specification, replacing the legacy 4.x remoting-based clients.

### Supported Languages

| Language | Dir | Build System | Package |
|----------|-----|-------------|---------|
| Java | `java/` | Maven | `org.apache.rocketmq:rocketmq-client-java` |
| Golang | `golang/` | Go modules | `github.com/apache/rocketmq-clients/golang` |
| C++ | `cpp/` | Bazel / CMake | — |
| C# | `csharp/` | .NET SDK | `RocketMQ.Client` (NuGet) |
| Rust | `rust/` | Cargo | `rocketmq` (crates.io) |
| Python | `python/` | setuptools | `rocketmq` (PyPI) |
| Node.js | `nodejs/` | npm | `rocketmq-client-nodejs` (npm) |
| PHP | `php/` | Composer | — |

### Shared Protos

All languages share proto definitions from `protos/` and the `rocketmq-apis` git submodule. When modifying `.proto` files, regenerate language-specific bindings (see each language's README for protoc commands).

## Architecture

### Core Client Types

- **Producer** — sends NORMAL, FIFO, DELAY, TRANSACTION messages
- **Push Consumer** — managed consumer with message listener callbacks; handles load balancing, caching, and auto-retry
- **Simple Consumer** — manual receive/ack with explicit invisible-time control
- **Pull Consumer** — streaming-oriented; manual route info and queue binding

### Unified Workflow

All clients follow the same lifecycle:

1. **Startup**: fetch topic route → get settings from server via telemetry (server-client hot-update) → initialize
2. **Periodic tasks**: update topic route cache → heartbeat → telemetry
3. **Message publishing** (Producer): check route cache → select writable queue → attempt publish → isolate endpoint on failure → retry with next queue
4. **Message receiving** (Push Consumer): fetch queue assignment from server → cache messages → trigger listener → ack/nack

See [docs/design.md](docs/design.md) for the messaging model and [docs/workflow.md](docs/workflow.md) for detailed message flows.

### Key Concepts

- **Message Types**: NORMAL, FIFO (requires `message_group`), DELAY (requires `delivery_timestamp`), TRANSACTION — mutually exclusive
- **Consumer Group**: load-balancing unit with attributes like consume timeout, FIFO switch, retry policy
- **Server-Client Telemetry**: channel for hot-updating client settings from server
- **Endpoint Isolation**: failed publishing isolates the endpoint; periodic heartbeat checks health

## Development Commands

### Prerequisites

Clone with submodules (required for `rocketmq-apis` protos):
```sh
git clone --recursive git@github.com:apache/rocketmq-clients.git
```

### Java (`java/`)

```sh
cd java
mvn -B package --file pom.xml        # build + test
mvn test                              # run tests only
mvn clean install -DskipTests        # install to local maven, skip tests
```

Requires Java 8+ runtime, Java 11+ for build.

### Golang (`golang/`)

```sh
cd golang
go build ./...                        # build
go test ./...                         # test
go test -v                            # verbose test
```

After modifying `.proto` files:
```sh
protoc --go-grpc_out=. apache/rocketmq/v2/*.proto
protoc --go_out=. apache/rocketmq/v2/*.proto
```

### C++ (`cpp/`)

```sh
cd cpp
bazel build //...                     # build
bazel test //...                      # test
```

CMake alternative: `mkdir build && cd build && cmake .. && make -j $(nproc)`

### C# (`csharp/`)

```sh
cd csharp
dotnet build                          # build
dotnet test -l "console;verbosity=detailed"  # test
dotnet format style                   # style check
```

Requires .NET 6.0+ and .NET 8.0+.

### Rust (`rust/`)

```sh
cd rust
cargo build                           # build
cargo test -- --nocapture             # test
cargo fmt --check                     # format check
cargo clippy --all-features -- -D warnings  # lint
```

Requires protoc 3.15.0+. MSRV is 1.74.0.

### Node.js (`nodejs/`)

```sh
cd nodejs
npm install                           # install deps
npm run init                          # generate grpc code
npm run build                         # build
npm test                              # test
npm pack                              # package
```

Requires Node.js 18+.

### Python (`python/`)

```sh
cd python
flake8 --ignore=E501,W503 --exclude python/rocketmq/grpc_protocol python  # lint
isort --check --diff --skip python/rocketmq/grpc_protocol python           # import sort check
black --exclude "./python/protocol/" python                                # format check
```

### PHP (`php/`)

```sh
cd php
composer validate
composer install
```

## CI/CD

CI uses path-based filtering in [build.yml](.github/workflows/build.yml) — only languages with changed files are built and tested. Each language has its own workflow file in `.github/workflows/`.

## Docs

- [docs/design.md](docs/design.md) — messaging model, APIs, client categories
- [docs/workflow.md](docs/workflow.md) — startup, periodic tasks, message flows
- [docs/message_id.md](docs/message_id.md) — message identifier layout (v0x01: 17 bytes = version + MAC + PID + timestamp + seq)
- [docs/transport.md](docs/transport.md) — gRPC transport headers
- [docs/observability.md](docs/observability.md) — logging paths per language
