# 多语言 RocketMQ 客户端测试记录

## 测试环境

- **操作系统**: Alibaba Cloud Linux 3 (内核 5.10.134-19.2.al8.x86_64)
- **RocketMQ 实例**: rmq-cn-u7c3giqmw0s
- **接入点**: 见 `.env.example` 中的 `ROCKETMQ_ENDPOINTS`
- **代码仓库**: https://github.com/apache/rocketmq-clients (master 分支)

### Topic 映射

| Topic | 消息类型 |
|-------|----------|
| NormalTest | 普通消息 |
| OrderTest | 顺序消息 (FIFO) |
| TimerTest | 定时/延时消息 |
| TransTest | 事务消息 |

## 测试结果总览

| 语言 | 普通消息 | FIFO | 延时消息 | 事务消息 | 状态 |
|------|----------|------|----------|----------|------|
| Java | ✅ | ✅ | ✅ | ✅ | 通过 |
| Golang | ✅ | ✅ | ✅ | ✅ | 通过 |
| Rust | ✅ | ✅ | ✅ | ✅ | 通过 |
| Python | ✅ | ✅ | ✅ | ✅ | 通过 |
| Node.js | ✅ | ✅ | ✅ | ✅ | 通过 |
| C# | ✅ | ✅ | ✅ | ✅ | 通过 (重试成功) |
| C++ | ✅ | ✅ | ✅ | ✅ | 通过 (修复后) |
| PHP | ⚠️ | - | - | - | 仅验证依赖 |

## 各语言安装与测试详情

### 1. Java

**安装**: Maven 3.9.9，通过阿里云镜像下载。系统已有 JDK 17。

**测试方式**: 创建了 `QuickTest.java` 统一运行 4 种 Producer 测试。

**踩坑**:
- **凭证为空**: `ProducerSingleton.java` 中 AccessKey/SecretKey 为空字符串，报错 "username cannot be null"。修复: 填入真实凭证。
- **CheckStyle 检查**: 新创建的 QuickTest.java 有 11 个 CheckStyle 违规 (缺少 License header, 使用 System.out 等)。修复: 用 `-Dcheckstyle.skip=true` 跳过。
- **IOException 未捕获**: `producer.close()` 抛出 IOException。修复: 加 try-catch 包裹。

**Maven 镜像**: 阿里云 `https://maven.aliyun.com/repository/public`

### 2. Golang

**安装**: Go 1.22.5。官方镜像 `golang.google.cn` 连接超时，改用阿里云镜像 `https://mirrors.aliyun.com/golang/` 下载。GOPROXY 设置为 `https://goproxy.cn,direct`。

**踩坑**:
- **golang.google.cn 不可达**: 连接超时。修复: 使用阿里云镜像站下载 Go 安装包。
- **4 个 Producer 示例均通过**，每个发送 10 条消息。

### 3. Rust

**安装**: Rust 1.95.0，通过 rustup 安装。

**测试方式**: `cargo run --example producer`, `fifo_producer`, `delay_producer`, `transaction_producer`。

**踩坑**:
- **Cargo 镜像全部失败**: 阿里云 crates 镜像 (rsproxy.cn) 报 "config.json not found"，Tsinghua 镜像超时。修复: 删除 `~/.cargo/config.toml`，使用 crates.io 直连 (慢但最终能下载完)。
- **编译时间极长**: 首次编译依赖下载 + 编译耗时约 64 分钟 (ring, petgraph, tokio 等大 crate 下载缓慢，大量 "spurious network error" 重试)。
- **编译成功后 4 个 Producer 全部通过**。

### 4. Python

**安装**: Python 3.8.17 (系统默认 python3 是 3.6 版本，但 pip 安装的是 3.8 的包)。

**踩坑**:
- **python3 指向 3.6**: 系统 `python3` 指向 3.6，但 `pip3 install` 装到了 3.8。修复: 使用 `python3.8` 运行脚本。
- **依赖缺失**: `opentelemetry`, `grpcio`, `protobuf` 需要手动安装。修复: `pip3 install opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp-proto-grpc grpcio grpcio-tools protobuf`。
- **4 个 Producer 全部通过**，正常消息发送 10 条。

### 5. Node.js

**安装**: Node.js 18.20.8，通过 nvm 安装。

**测试方式**: `npx ts-node examples/ProducerNormalMessageExample.ts` 等。

**踩坑**:
- **Transaction 示例导入路径错误**: `ProducerTransactionMessageExample.ts` 使用了 `rocketmq-client-nodejs/proto/apache/rocketmq/v2/definition_pb.js` 这个不存在的路径。修复: 改为 `../proto/apache/rocketmq/v2/definition_pb` (相对路径)。
- **日志文件句柄关闭报错**: 多个 Producer 顺序运行时 log stream had been closed 错误。不影响消息发送，是 shutdown 时的时序问题。
- **4 个 Producer 全部通过**。

### 6. C#

**安装**: .NET 8.0.420。

**测试方式**: 修改 `QuickStart.cs` 取消注释 4 个 Producer 示例，`dotnet run --project examples/examples.csproj --framework net8.0`。

**第一次尝试失败原因**: proto 子模块未初始化 (GitHub 不可达)，`dotnet build` 失败。

**重试成功**: `git submodule update --init --recursive` 最终成功克隆了 rocketmq-apis 仓库。

**踩坑**:
- **GitHub 不可达**: 首次克隆子模块时连接 github.com 超时。修复: 等待网络恢复后重试 `git submodule update --init`。
- **4 个 Producer 全部通过**。

### 7. C++

**安装**: CMake 3.26.5, GCC 10.2.1。需要手动编译 gRPC 和 gflags。

**踩坑** (最多的语言):

1. **GitHub 不可达导致 proto 子模块无法克隆**: 修复: 等待网络恢复后 `git submodule update --init` 成功。

2. **gRPC 未预装**: 需要从源码编译。修复:
   - 克隆 `grpc v1.54.3` 源码
   - `git submodule update --init` 初始化 gRPC 子模块
   - `cmake -DCMAKE_INSTALL_PREFIX=$HOME/grpc -DgRPC_BUILD_TESTS=OFF .. && make -j $(nproc) && make install`
   - 编译耗时约 30 分钟

3. **gflags 未预装**: 修复: 从源码编译安装到 `$HOME/gflags`。

4. **C++11 不支持 `std::make_unique`**: 项目 CMakeLists.txt 设置了 `CMAKE_CXX_STANDARD 11`，但代码使用了 `std::make_unique` (C++14+)。修复: 改为 `CMAKE_CXX_STANDARD 14`。

5. **`absl::make_unique` 编译失败**: 源码使用了 `absl::make_unique` 但新版 Abseil 中该函数签名不兼容。修复: 全局替换为 `std::make_unique`。

6. **线程注解宏不兼容**: 代码使用旧版 `GUARDED_BY`, `LOCKS_EXCLUDED`, `ACQUIRED_AFTER` 等宏，但新版 Abseil 改用 `ABSL_` 前缀。修复: 全局替换为 `ABSL_GUARDED_BY`, `ABSL_LOCKS_EXCLUDED`, `ABSL_ACQUIRED_AFTER` 等。

7. **Telemetry 握手死循环**: 这是最关键的坑。客户端通过 Telemetry 协议向服务端发送设置信息，期望服务端返回配置。但阿里云 RocketMQ 代理返回的命令不被客户端识别，导致:
   - 客户端打印 "Telemetry command receive unsupported command"
   - 连接断开
   - `OnDone()` 回调自动重连
   - 无限循环，永远到不了发送消息的步骤
   
   **修复**:
   - 修改 `TelemetryBidiReactor.cpp` 中 `awaitApplyingSettings()`: 超时后返回 `true` 而非 `false` (Producer 不依赖服务端配置也能工作)
   - 修改 `OnDone()`: 移除自动重连逻辑 `client->createSession(peer_address_, true)`

8. **认证凭证未传入**: C++ 示例支持 `--access_key` 和 `--access_secret` 命令行参数，但首次测试未传。修复: 运行示例时显式传入凭证参数。

9. **Transaction 示例等待 5 分钟**: `ExampleProducerWithTransactionalMessage.cpp` 末尾有 `sleep_for(std::chrono::minutes(5))`。修复: 改为 10 秒。

10. **FIFO 示例成功输出被注释**: 发送成功后打印 Message-ID 的代码行被注释掉了。修复: 取消注释并添加错误信息打印。

### 8. PHP

**状态**: 仅验证依赖。PHP 7.4.33 已安装，但 Composer 不可用且无法下载。PHP 示例代码不完整 (仅做路由查询，无消息发送功能)。

## 通用踩坑记录

### 网络问题
- **GitHub 连接不稳定**: `git submodule update` 多次失败，最终在网络恢复时成功。
- **DingTalk Webhook Token 过期**: 部分钉钉通知发送失败 (token is not exist / 签名不匹配)。

### 凭证管理
- 所有语言的示例代码初始都使用占位符凭证，需要逐一替换为真实的 AccessKey/SecretKey 和 Endpoint。
- C++ 是唯一通过命令行参数传入凭证的语言，其他语言都需要改源代码。

### 协议子模块
- 所有语言依赖 `protos/` 子模块 (rocketmq-apis)。首次克隆仓库时务必使用 `git clone --recursive` 或随后运行 `git submodule update --init --recursive`。

## 中文镜像总结

| 工具 | 推荐镜像 | 备选 | 不可用 |
|------|----------|------|--------|
| Go | goproxy.cn | mirrors.aliyun.com/golang | golang.google.cn |
| Python | mirrors.aliyun.com/pypi | - | - |
| Maven | maven.aliyun.com/repository/public | - | - |
| Rust (crates) | - | - | rsproxy.cn, Tsinghua, Aliyun |
| Node.js | npmmirror.com (npm 默认) | - | - |
