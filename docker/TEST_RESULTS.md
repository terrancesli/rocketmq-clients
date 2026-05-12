# RocketMQ Multi-Language Docker Test Results

## Summary

| Language | Build | Runtime | Status |
|----------|-------|---------|--------|
| **Go** | ✅ | ✅ | **PASSED** |
| **Python** | ✅ | ✅ | **PASSED** |
| **Node.js** | ✅ | ⚠️ | **PARTIAL** |
| **C#** | ✅ | ❌ | **FAILED** |
| **Java** | ✅ | ❌ | **FAILED** |
| **PHP** | ✅ | ❌ | **FAILED (WIP)** |
| **C++** | ❌ | — | **SKIPPED** |
| **Rust** | ❌ | — | **SKIPPED** |

---

## PASSED

### Go ✅
- **Image**: `rocketmq-test:golang` (199MB, golang:1.24-alpine)
- **Mirror**: goproxy.cn
- **Tests**: Normal, FIFO, Delay, Transaction producers all send messages successfully
- **Config**: Reads `ROCKETMQ_ENDPOINT`, `ROCKETMQ_ACCESS_KEY`, `ROCKETMQ_SECRET_KEY` from env vars
- **SSL**: Disabled via `EnableSsl = false` in examples

### Python ✅
- **Image**: `rocketmq-test:python` (166MB, python:3.9-slim)
- **Mirror**: PyPI Aliyun (pypi.tuna.tsinghua.edu.cn)
- **Tests**: Normal, FIFO, Delay, Transaction producers all send messages successfully
- **Config**: Reads `ROCKETMQ_ENDPOINT`, `ROCKETMQ_ACCESS_KEY`, `ROCKETMQ_SECRET_KEY` from env vars

---

## PARTIAL

### Node.js ⚠️
- **Image**: `rocketmq-test:nodejs` (327MB, node:18-alpine)
- **Mirror**: npmmirror (npm), Aliyun (apk)
- **Build**: ✅ Success — protobuf and gRPC code generation works
- **Runtime**: Connects and sends messages successfully, but **hangs on producer close** (timeout waiting for graceful shutdown)
- **Fixes applied**:
  1. Added Aliyun mirror for `apk` packages (`dl-cdn.alpinelinux.org` → `mirrors.aliyun.com`)
  2. Fixed example path: copied to `./nodejs/examples/` instead of `/app/examples/` so `../src` imports resolve
  3. Added `ROCKETMQ_NODEJS_CLIENT_ENDPOINTS` to `.env` (Node.js uses this var name, not `ROCKETMQ_ENDPOINTS`)

---

## FAILED

### C# ❌ — Hardcoded Topics
- **Image**: `rocketmq-test:csharp` (197MB, dotnet:8.0)
- **Build**: ✅ Success
- **Runtime**: Fails with `UnauthorizedException: the topic of yourNormalTopic is not found`
- **Root cause**: All 4 example files use hardcoded topic names:
  - `ProducerNormalMessageExample.cs:46` → `const string topic = "yourNormalTopic"`
  - `ProducerFifoMessageExample.cs:46` → `const string topic = "yourFifoTopic"`
  - `ProducerDelayMessageExample.cs:46` → `const string topic = "yourDelayTopic"`
  - `ProducerTransactionMessageExample.cs:55` → `const string topic = "yourTransactionTopic"`
- **Fix needed**: Replace hardcoded `const string topic = ...` with `Environment.GetEnvironmentVariable("ROCKETMQ_TOPIC_NORMAL") ?? "DefaultNormalTopic"` (and similar for other types). The `all-demo/csharp/examples/` directory already has this pattern — use those instead.

### Java ❌ — Stale Class Files / SSL Issue
- **Image**: `rocketmq-test:java` (328MB, eclipse-temurin:11-jre)
- **Build**: ✅ Success (Aliyun Maven mirror, mvn install + javac)
- **Runtime**: Connects to `foobar.com` instead of the configured endpoint, despite `ROCKETMQ_ENDPOINTS` being correct in the container
- **Root cause**: The `javac` compilation step uses Docker layer caching. Even with `--no-cache`, the compiled classes reference `foobar.com`. The `ProducerSingleton.java` was modified to add `.enableSsl(false)` but the debug `System.out.println` never appears in output, indicating stale `.class` files.
- **Fix needed**:
  1. Add `COPY` of example source **before** the `javac` RUN step to bust cache
  2. Verify `ProducerSingleton.java` actually reads from `System.getenv("ROCKETMQ_ENDPOINTS")` (not a hardcoded default)
  3. Clean `/tmp/examples/` in the builder stage before `javac`

### PHP ❌ — Missing Composer Install (WIP)
- **Image**: `rocketmq-test:php` (530MB, php:8.2-cli)
- **Build**: ✅ Success
- **Runtime**: `Fatal error: Failed opening required 'vendor/autoload.php'`
- **Root cause**: Dockerfile copies `all-demo/php/` examples but doesn't run `composer install` to generate `vendor/autoload.php`. The Dockerfile is marked WIP.
- **Fix needed**: Add `RUN composer install` in the Dockerfile after copying examples, or copy the pre-built `vendor/` from the original `php/` directory.

---

## SKIPPED

### C++ ❌ — Network (gflags git clone)
- **Build fails**: `git clone --depth 1 https://github.com/gflags/gflags.git` → exit code 128 (network unreachable)
- **Dockerfile**: `docker/Dockerfile.cpp` compiles gRPC v1.54.3 and gflags from source
- **Root cause**: GitHub is unreachable from Docker build context
- **Fix needed**: Use domestic mirror for gflags (e.g., gitee mirror or pre-download the archive). Alternatively, use system package: `apt-get install -y libgflags-dev` (may be older but sufficient).
- **Note**: gRPC compilation is cached after first successful build (~30 min), subsequent builds are instant.

### Rust ❌ — Network (crate downloads too slow)
- **Build fails**: Timeout during `cargo build --release`
- **Issues encountered**:
  1. `rust:1.74` → edition 2024 error (indexmap 2.14 requires newer Rust)
  2. `rust:1.85` → `time@0.3.47` requires rustc 1.88.0
  3. `rust:1.88` → crate downloads from rustcc mirror are extremely slow (>10 min, incomplete)
- **Mirror configured**: `rustcc.cn/crates.io-index.git` (working but slow)
- **Fix needed**: Consider using a different crate mirror (e.g., `rsproxy.cn`) or pre-building the dependencies outside Docker and caching them.

---

## Configuration Issues Discovered

### 1. `.env` File Quoting
Docker `--env-file` preserves literal quotes. `"value"` becomes the string `"value"` (with quotes). **Solution**: Never quote values in `.env` files.

### 2. Env Var Name Inconsistency
Different languages use different env var names for the same configuration:
| Var | Go | Java | Python | Node.js | C# | Rust |
|-----|----|----|--------|---------|----|----|
| Endpoint | `ROCKETMQ_ENDPOINT` | `ROCKETMQ_ENDPOINTS` | `ROCKETMQ_ENDPOINT` | `ROCKETMQ_NODEJS_CLIENT_ENDPOINTS` | hardcoded | hardcoded |
| Access Key | `ROCKETMQ_ACCESS_KEY` | `ROCKETMQ_ACCESS_KEY` | `ROCKETMQ_ACCESS_KEY` | `ROCKETMQ_ACCESS_KEY` | `ROCKETMQ_ACCESS_KEY` | hardcoded |

**Recommendation**: Standardize on `ROCKETMQ_ENDPOINT` (singular) for all languages, or have each Dockerfile map the common vars to language-specific ones.

### 3. Topic Mapping
Only Go and Python read topic names from env vars. Java, C#, Node.js, Rust, C++ all have hardcoded topic names in their examples.

---

## Domestic Mirror Reference

| Language | Package Manager | Mirror |
|----------|----------------|--------|
| Go | go modules | `https://goproxy.cn,direct` |
| Java | Maven | `https://maven.aliyun.com/repository/public` |
| Node.js | npm | `https://registry.npmmirror.com` |
| Node.js | apk (Alpine) | `mirrors.aliyun.com` |
| Python | pip | `https://pypi.tuna.tsinghua.edu.cn/simple` |
| Rust | crates.io | `https://mirrors.rustcc.cn/crates.io-index.git` |
| C# | NuGet | Default (nuget.org, CDN removed) |
| PHP | Composer | `https://mirrors.aliyun.com/composer/` |
| C++ | apt (Ubuntu) | `mirrors.aliyun.com` |
| C++ | git (GitHub) | No mirror configured |

---

## Files Modified

| File | Change |
|------|--------|
| `docker/Dockerfile.java` | Changed base image to `maven:3.9-eclipse-temurin-11`, added `-Dspotbugs.skip=true` |
| `docker/Dockerfile.nodejs` | Added Aliyun apk mirror, fixed example paths, added `ROCKETMQ_NODEJS_CLIENT_ENDPOINTS` |
| `docker/Dockerfile.rust` | Upgraded Rust from 1.85 to 1.88 |
| `docker/run-nodejs-test.sh` | Changed example path from `/app/examples/` to `examples/` |
| `all-demo/java/example/ProducerSingleton.java` | Added `.enableSsl(false)` |
| `all-demo/java/example/ProducerNormalMessageExample.java` | Added debug `System.out.println` |
| `docker/.env` | Added `ROCKETMQ_NODEJS_CLIENT_ENDPOINTS` |
| `docker/CHINA_MIRRORS.md` | Created — mirror configuration reference |

---

## Next Steps

1. **C#**: Replace `csharp/examples/` with `all-demo/csharp/examples/` (already has env var support)
2. **Java**: Fix Dockerfile cache busting for `javac` step; verify `ProducerSingleton` reads env correctly
3. **PHP**: Add `composer install` to Dockerfile
4. **C++**: Use `apt-get install libgflags-dev` instead of git clone
5. **Rust**: Try `rsproxy.cn` as alternative crate mirror, or pre-build dependencies
6. **Node.js**: Investigate producer close hang (may be a client bug or server-side issue)
7. **Env vars**: Standardize env var names across all `all-demo` examples
