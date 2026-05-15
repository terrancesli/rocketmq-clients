# RocketMQ C++ Client

Apache RocketMQ C++ gRPC client SDK. Source: [cpp/](../../cpp/)

## Quick Build

```bash
# Using CMake (recommended)
cd cpp
mkdir -p build && cd build
cmake .. && make -j $(nproc)

# Using Bazel
cd cpp
bazel build //...
bazel test //...
```

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| GCC | 11.5.0+ | C++17 compiler |
| CMake | 3.30.2+ | Build system |
| Bazel | 7.2.1 | Alternative build system |
| protobuf | 3.20.1 | Message serialization |
| gRPC | 1.46.3 | Transport layer |
| gflags | 2.2.2 | Command-line flags |
| JDK | 11+ | Required by Bazel |
| OpenSSL | system | TLS for gRPC |

### Install all dependencies

Run the automated script:

```bash
bash all-demo/cpp/setup.sh
```

Or follow [SETUP.md](SETUP.md) for manual step-by-step instructions.

## Running Examples

Examples are in [examples/](examples/). All examples accept `--access_point` and `--topic` via command-line arguments.

```bash
cd cpp/build

# Normal producer
./ExampleProducer --access_point="<endpoint>" --topic=NormalTest

# FIFO producer
./ExampleProducerWithFifoMessage --access_point="<endpoint>" --topic=OrderTest

# Timed/delay producer
./ExampleProducerWithTimedMessage --access_point="<endpoint>" --topic=TimerTest

# Transactional producer
./ExampleProducerWithTransactionalMessage --access_point="<endpoint>" --topic=TransTest

# Push consumer (runs until killed)
./ExamplePushConsumer --access_point="<endpoint>" --topic=NormalTest

# Simple consumer (runs until killed)
./ExampleSimpleConsumer --access_point="<endpoint>" --topic=NormalTest
```

## Topic Mapping

| Message Type | Topic | Example Binary |
|-------------|-------|---------------|
| Normal | `NormalTest` | `ExampleProducer` |
| FIFO | `OrderTest` | `ExampleProducerWithFifoMessage` |
| Delay | `TimerTest` | `ExampleProducerWithTimedMessage` |
| Transaction | `TransTest` | `ExampleProducerWithTransactionalMessage` |

## Key Technical Notes

### ABI Compatibility
GCC 4.9.2 and GCC 5.x+ use different C++ ABIs (`_GLIBCXX_USE_CXX11_ABI`). If you encounter linker errors, ensure your GCC version matches the one used to build the SDK binary. See: <https://gcc.gnu.org/onlinedocs/libstdc++/manual/using_dual_abi.html>

### Port Shifting
When communicating with NameServer/Broker via gRPC, the client port is shifted by +10:
- NameServer: `host:9876` → `host:9886`
- Broker addresses from route responses are also shifted by +10

### Static vs Dynamic Linking
The SDK supports both static and dynamic linking. For deployment, static linking avoids dependency version conflicts. Ensure `LD_LIBRARY_PATH` includes `/usr/local/lib` and any custom install paths (e.g., `$HOME/grpc/lib`).

### Known Issues
- **Latency spikes**: Can occur when using unary-rpc instead of server-stream for large data transfers. See protobuf large data techniques: <https://developers.google.com/protocol-buffers/docs/techniques#large-data>
- **curl dependency**: NameServer list retrieval uses curl. If using cpp-httplib as alternative, be aware of known library bugs.

## Reference Links

- Development Guide: <https://aliyuque.antfin.com/terrance.lzm/igha71/gcfarcyvu549a9lx>
- RocketMQ-apis (gRPC v2 IDL): <https://github.com/apache/rocketmq-apis>
- Latency Analysis: <https://yuque.antfin-inc.com/docs/share/b4be7fdb-c850-4240-9205-67d2705df042>
- Core Dump Analysis: <https://yuque.antfin-inc.com/docs/share/1df33bde-c2c5-4c73-9510-8bc67d188e7e>
