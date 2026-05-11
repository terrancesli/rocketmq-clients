# 各语言客户端功能对比评估

本文档对 RocketMQ Clients 仓库中 8 个语言实现的**功能完整度**和**实现质量**进行系统性对比评估。

> 评估时间：2026-05-09
> 数据来源：仓库代码静态分析

## 一、客户端类型覆盖

| 客户端类型 | Java | Go | C++ | C# | Rust | Python | Node.js | PHP |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Producer（同步） | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| Producer（异步） | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Producer（事务） | ✅ | ✅ | ✅ | ✅ | ⚠️ 部分 | ✅ | ✅ | ❌ |
| Push Consumer | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Simple Consumer | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| **Lite Push Consumer** | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ |
| **Lite Simple Consumer** | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Pull Consumer | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

> ⚠️ 部分：Rust 有 transaction 模块但缺少 TransactionChecker 示例；PHP 仅为最小化 stub

## 二、消息类型支持

| 消息类型 | Java | Go | C++ | C# | Rust | Python | Node.js | PHP |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| NORMAL（普通） | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| FIFO（顺序） | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| DELAY/TIMED（定时/延时） | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| TRANSACTION（事务） | ✅ | ✅ | ✅ | ✅ | ⚠️ 部分 | ✅ | ✅ | ❌ |
| **PRIORITY（优先级）** | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ |

## 三、高级功能

| 功能 | Java | Go | C++ | C# | Rust | Python | Node.js | PHP |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 消息撤回（Recall） | ✅ | ✅ | ✅ | ✅ | ❌ | ⚠️ proto 已定义无 API | ✅ | ❌ |
| 批量发送 | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ |
| Tag 过滤 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| SQL 过滤 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| 可观测性（Trace/Metric） | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| 自动重试/退避 | ✅ | ✅ | ✅ | ✅ | ⚠️ 部分 | ✅ | ✅ | ❌ |
| 负载均衡 | ✅ | ✅ | ✅ | ✅ | ⚠️ 部分 | ✅ | ✅ | ❌ |
| 端点隔离 | ✅ | ✅ | ⚠️ 部分 | ⚠️ 部分 | ❌ | ❌ | ⚠️ 部分 | ❌ |
| TLS/SSL | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ 部分 | ⚠️ 部分 | ❌ |

## 四、实现质量指标

| 指标 | Java | Go | C++ | C# | Rust | Python | Node.js | PHP |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 源码文件数 | 127 | 53 | 84+29h | 103 | 15 | 43 | 71 | 3 |
| 测试文件数 | 34 | 10 | 25 | 36 | 3 | 3 | 14 | 0 |
| 示例代码 | ✅ 丰富 | ✅ | ✅ 丰富 | ✅ | ✅ | ✅ | ✅ | ❌ |
| 包管理发布 | Maven Central | Go modules | 无 | NuGet | Crates.io | PyPI | npm | 无 |
| README 质量 | 优秀 | 基础 | 优秀 | 良好 | 极简 | 缺失 | 良好 | 缺失 |
| CI/CD | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 整体成熟度 | **完备** | **成熟** | **成熟** | **成熟** | **成长中** | **可用** | **成熟** | **原型** |

> 84+29h = 84 个 .cpp 源文件 + 29 个 .h 头文件

## 五、各语言详细说明

### Java — 最完整实现（成熟度：完备）

- **源码**: 127 个主文件，34 个测试文件
- **包**: `org.apache.rocketmq:rocketmq-client-java`（Maven Central），Java 8+ 运行 / Java 11+ 构建
- **独特能力**: 唯一同时拥有 Lite Push Consumer **和** Lite Simple Consumer 的实现；唯一完整实现 PRIORITY 消息类型和消息撤回功能的客户端
- **可观测性**: 完整的 `ClientMeterManager` + `MessageMeterInterceptor` + OpenTelemetry 指标
- **构建**: `mvn -B package --file pom.xml`

### Golang — 核心功能齐全（成熟度：成熟）

- **源码**: 53 个 .go 文件，10 个测试文件
- **包**: Go modules（`github.com/apache/rocketmq-clients/golang`）
- **亮点**: 支持 Lite Push Consumer 和消息撤回（含 `delay_recall` 示例）
- **不足**: 缺少 Lite Simple Consumer
- **构建**: `go build ./...` && `go test ./...`

### C++ — 工程级实现（成熟度：成熟）

- **源码**: 84 个 .cpp + 29 个 .h 文件，25 个测试文件
- **构建**: Bazel（`bazel build //...`）或 CMake
- **亮点**: 示例最丰富（sync/async/FIFO/transaction producer + push/simple consumer），OpenCensus 集成
- **不足**: 缺少 Lite 变体；不支持 PRIORITY 消息类型；端点隔离仅部分实现
- **无包管理**: 仅通过 Bazel/CMake 构建

### C# — 功能丰富（成熟度：成熟）

- **源码**: 103 个 .cs 文件，36 个测试文件
- **包**: `RocketMQ.Client`（NuGet），.NET 5+ / .NET Core 3.1
- **亮点**: 支持 Lite Push Consumer、消息撤回（含定时消息撤回示例）、完整的 PRIORITY 消息
- **日志**: NLog 作为默认实现，支持通过 `MqLogManager.UseLoggerFactory` 自定义
- **构建**: `dotnet build` && `dotnet test`

### Rust — 成长中的实现（成熟度：成长中）

- **源码**: 15 个 .rs 文件，3 个测试文件
- **包**: `rocketmq`（Crates.io v5.0.0），MSRV 1.74.0
- **亮点**: 原生 async/await；OpenTelemetry + minitrace 双重可观测性支持
- **不足**: 缺少消息撤回、批量发送、PRIORITY、Lite 变体、端点隔离；测试覆盖率低
- **构建**: `cargo build` && `cargo test`

### Python — 基本可用（成熟度：可用）

- **源码**: 43 个 .py 文件，3 个测试文件
- **包**: `rocketmq`（PyPI，有 setup.py 但无 README 文档）
- **亮点**: 支持 Producer / Push Consumer / Simple Consumer / Lite Push Consumer / 事务消息 / PRIORITY
- **不足**: 缺少批量发送；Recall RPC 已在 proto 中定义但无公开 API；无可观测性；仅 3 个测试文件
- **构建**: 无明确的 `python setup.py test` 流程

### Node.js — 意外地成熟（成熟度：成熟）

- **源码**: 71 个 .ts 文件，14 个测试文件
- **包**: `rocketmq-client-nodejs`（npm），Node.js 18+
- **亮点**: 唯一除了 Java 之外拥有 Lite Simple Consumer 的实现；完整的消息撤回 + 批量发送 + PRIORITY
- **不足**: 无可观测性模块；TLS 支持不显式配置
- **构建**: `npm run init && npm run build && npm test`

### PHP — 原型级别（成熟度：原型）

- **源码**: 3 个 .php 文件，0 个测试文件
- **状态**: 仅为概念验证（POC），代码中硬编码了连接凭证
- **不足**: 缺少全部高级功能、测试、README、包发布
- **建议**: 不适用于生产环境

## 六、共性结论

1. **Pull Consumer** 在所有 8 个语言中均未实现
2. **SQL 过滤** 在所有 8 个语言中均未实现
3. **Java** 是功能最全面的参考实现，新增功能应优先在 Java 中验证
4. **Node.js** 和 **C#** 的成熟度超出预期，功能覆盖接近 Java
5. **Rust** 和 **Python** 是主要差距所在：缺少批量发送、消息撤回、端点隔离
6. **PHP** 需要大量工作才能达到生产可用
