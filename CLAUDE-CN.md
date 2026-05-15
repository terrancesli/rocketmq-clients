# CLAUDE.md

此文件为在 Apache RocketMQ Clients 代码仓库中工作的 Claude Code (claude.ai/code) 提供指导。

## 概览

本仓库为 **Apache RocketMQ Clients** 多语言 monorepo，包含基于 gRPC 的 RocketMQ 5.x 客户端 SDK。所有客户端均遵循统一的 [rocketmq-apis](https://github.com/apache/rocketmq-apis) 规范，替代旧版 4.x 基于 Remoting 的客户端。

### 支持的语言

| 语言 | 目录 | 构建系统 | 包 |
|------|------|---------|-----|
| Java | `java/` | Maven | `org.apache.rocketmq:rocketmq-client-java` |
| Golang | `golang/` | Go modules | `github.com/apache/rocketmq-clients/golang` |
| C++ | `cpp/` | Bazel / CMake | — |
| C# | `csharp/` | .NET SDK | `RocketMQ.Client` (NuGet) |
| Rust | `rust/` | Cargo | `rocketmq` (crates.io) |
| Python | `python/` | setuptools | `rocketmq` (PyPI) |
| Node.js | `nodejs/` | npm | `rocketmq-client-nodejs` (npm) |
| PHP | `php/` | Composer | — |

### 共享 Proto 定义

所有语言共享 `protos/` 目录及 `rocketmq-apis` git 子模块中的 proto 定义。修改 `.proto` 文件后，需要重新生成各语言对应的绑定代码（详见各语言的 README）。

## 架构

### 客户端类型

- **Producer（生产者）** — 发送 NORMAL、FIFO、DELAY、TRANSACTION 消息
- **Push Consumer（推送消费者）** — 全托管消费模式，提供消息监听回调；自动处理负载均衡、消息缓存和重试
- **Simple Consumer（简单消费者）** — 手动接收和确认消息，显式控制不可见时间
- **Pull Consumer（拉取消费者）** — 面向流式场景，手动获取路由信息和绑定消息队列

### 统一工作流程

所有客户端遵循相同的生命周期：

1. **启动**：获取主题路由 → 通过遥测从服务端获取配置（客户端热更新） → 初始化
2. **周期任务**：更新主题路由缓存 → 发送心跳 → 遥测同步
3. **消息发送**（Producer）：检查路由缓存 → 选择可写队列 → 尝试发送 → 失败时隔离端点 → 重试并切换到下一个队列
4. **消息接收**（Push Consumer）：从服务端获取队列分配 → 缓存消息 → 触发监听器 → 确认/拒绝

详见 [docs/design.md](docs/design.md) 的消息模型和 [docs/workflow.md](docs/workflow.md) 的消息流转细节。

### 核心概念

- **消息类型**：NORMAL（普通）、FIFO（顺序，需设置 `message_group`）、DELAY（定时/延时，需设置 `delivery_timestamp`）、TRANSACTION（事务）—— 互斥
- **消费组**：消费者负载均衡单元，配置有消费超时时间、FIFO 消费开关、重试策略等
- **端对端遥测**：服务端向客户端下发配置的热更新通道
- **端点隔离**：发送失败时隔离该端点，心跳检测恢复后自动解除隔离

## 开发命令

### 前置条件

克隆时需拉取子模块（依赖 `rocketmq-apis` proto 定义）：
```sh
git clone --recursive git@github.com:apache/rocketmq-clients.git
```

### Java (`java/`)

```sh
cd java
mvn -B package --file pom.xml        # 构建 + 测试
mvn test                              # 仅运行测试
mvn clean install -DskipTests        # 安装到本地 Maven 仓库，跳过测试
```

运行时需要 Java 8+，构建需要 Java 11+。

### Golang (`golang/`)

```sh
cd golang
go build ./...                        # 构建
go test ./...                         # 测试
go test -v                            # 详细输出测试
```

修改 `.proto` 文件后重新生成：
```sh
protoc --go-grpc_out=. apache/rocketmq/v2/*.proto
protoc --go_out=. apache/rocketmq/v2/*.proto
```

### C++ (`cpp/`)

```sh
cd cpp
bazel build //...                     # 构建
bazel test //...                      # 测试
```

CMake 方式：`mkdir build && cd build && cmake .. && make -j $(nproc)`

### C# (`csharp/`)

```sh
cd csharp
dotnet build                          # 构建
dotnet test -l "console;verbosity=detailed"  # 测试
dotnet format style                   # 代码风格检查
```

需要 .NET 6.0+ 和 .NET 8.0+。

### Rust (`rust/`)

```sh
cd rust
cargo build                           # 构建
cargo test -- --nocapture             # 测试
cargo fmt --check                     # 格式化检查
cargo clippy --all-features -- -D warnings  # 静态检查
```

需要 protoc 3.15.0+。MSRV 为 1.74.0。

### Node.js (`nodejs/`)

```sh
cd nodejs
npm install                           # 安装依赖
npm run init                          # 生成 gRPC 代码
npm run build                         # 构建
npm test                              # 测试
npm pack                              # 打包
```

需要 Node.js 18+。

### Python (`python/`)

```sh
cd python
flake8 --ignore=E501,W503 --exclude python/rocketmq/grpc_protocol python  # 代码检查
isort --check --diff --skip python/rocketmq/grpc_protocol python           # 导入排序检查
black --exclude "./python/protocol/" python                                # 格式检查
```

### PHP (`php/`)

```sh
cd php
composer validate
composer install
```

## CI/CD

CI 在 [build.yml](.github/workflows/build.yml) 中通过路径过滤实现 — 仅构建和测试发生变更的语言模块。每种语言有独立的 workflow 文件（`.github/workflows/` 下）。

## 文档

- [docs/design.md](docs/design.md) — 消息模型、API 设计、客户端分类
- [docs/workflow.md](docs/workflow.md) — 启动流程、周期任务、消息流转
- [docs/message_id.md](docs/message_id.md) — 消息 ID 布局（v0x01：17 字节 = 版本号 + MAC 地址 + 进程ID + 时间戳 + 序列号）
- [docs/transport.md](docs/transport.md) — gRPC 传输请求头
- [docs/observability.md](docs/observability.md) — 各语言日志路径
