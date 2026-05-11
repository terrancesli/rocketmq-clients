# 执行计划：安装环境 + 多语言消息收发测试

> 目标：在当前机器上安装所有 RocketMQ 客户端语言环境，使用 `docs/instance_info.md` 中的实例信息，按顺序测试各语言的 Producer/Consumer 消息收发。

## 当前状态

| 组件 | 状态 |
| --- | --- |
| OS | Alibaba Cloud Linux 3 (RHEL 系) |
| Java | 已安装 (OpenJDK 11.0.25) |
| Python | 已安装 (3.6.8，需 3.9+) |
| Go / .NET / Rust / Node.js / C++ 构建 / PHP | 均未安装 |

## 实例信息映射（来自 `docs/instance_info.md`）

| 字段 | 值 |
| --- | --- |
| 接入点 | `rmq-cn-u7c3giqmw0s-vpc.cn-hangzhou.rmq.aliyuncs.com:8080` |

### Topic 映射

| 消息类型 | Topic | 说明 |
| --- | --- | --- |
| 普通消息 | `NormalTest` | 基础消息收发 |
| 顺序消息 | `OrderTest` | FIFO，需 `message_group` |
| 定时消息 | `TimerTest` | 延时消息，需 `delivery_timestamp` |
| 事务消息 | `TransTest` | 事务消息，需 `TransactionChecker` |

### 消费组映射

| 消费组 | 消费者类型 | 是否顺序 |
| --- | --- | --- |
| `PushConsumer` | Push Consumer | 否 |
| `PushOrderConsumer` | Push Consumer | 是 |
| `SimpleConsumer` | Simple Consumer | 否 |
| `SimpleOrderConsumer` | Simple Consumer | 是 |

> **注意**：当前实例未提供 AccessKey/SecretKey，所有语言配置中不设置凭据（ACL 未启用时不需要）。

## 国内源总览

| 软件 | 国内源 |
| --- | --- |
| Go | `https://golang.google.cn/dl/`，代理 `https://goproxy.cn` |
| .NET | 清华源 `https://mirrors.tuna.tsinghua.edu.cn/dotnet/` |
| Rust | rsproxy.cn `https://rsproxy.cn`，crates 阿里源 |
| Node.js | npmmirror `https://npmmirror.com/mirrors/node/` |
| pip | 阿里 PyPI `https://mirrors.aliyun.com/pypi/simple/` |
| npm | `https://registry.npmmirror.com` |
| Composer | 阿里源 `https://mirrors.aliyun.com/composer/` |
| Maven | 阿里中央仓库 `maven.aliyun.com` |

---

## 钉钉通知机制

每完成一个 Step（或第一阶段/第二阶段整体完成），必须通过钉钉发送进度通知。

**通知脚本模板**：

```bash
source /root/IdeaProjects/rocketmq-clients/.env
timestamp=$(date +%s000)
string_to_sign="${timestamp}\n${DINGTALK_TEST_SECRET}"
sign=$(echo -ne "$string_to_sign" | openssl dgst -sha256 -hmac "$DINGTALK_TEST_SECRET" -binary | base64 | python3 -c "import sys,urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip()))")
url="${DINGTALK_TEST_WEBHOOK}&timestamp=${timestamp}&sign=${sign}"
curl -s -X POST "$url" -H 'Content-Type: application/json' -d '{"msgtype":"text","text":{"content":"你的通知内容"}}'
```

**通知时机**：

- 第一阶段：每安装完 2-3 个语言环境 → 发送一次进度通知
- 第二阶段：每完成一种语言的完整测试（Producer + Consumer） → 发送一次结果通知
- 全部完成后 → 发送总结通知

---

## 第一阶段：安装所有语言环境

### Step 1: 系统级依赖

```bash
sudo dnf install -y \
  wget curl git unzip tar gcc gcc-c++ make autoconf automake \
  openssl-devel zlib-devel bzip2-devel libffi-devel readline-devel \
  protobuf-compiler protobuf-devel cmake
```

> 已执行，需检查是否完成。

### Step 2: 安装 Go

- 从 `https://golang.google.cn/dl/go1.22.5.linux-amd64.tar.gz` 下载
- 解压到 `/usr/local`，配置 `/etc/profile.d/golang.sh`
- 设置 `GOPROXY=https://goproxy.cn,direct`
- 验证：`go version`

### Step 3: 安装 .NET 8.0 SDK

- 首选：清华源 `https://mirrors.tuna.tsinghua.edu.cn/dotnet/dotnet/` 下载二进制包
- 备选：`dotnet-install.sh` + Azure 中国 CDN
- 安装到 `/usr/share/dotnet`，链接到 `/usr/bin/dotnet`
- 验证：`dotnet --version`

### Step 4: 安装 Rust

- 使用 rsproxy.cn：`curl -sSf https://rsproxy.cn/rustup-init.sh | sh -s -- -y`
- 配置 `~/.cargo/config.toml` 使用阿里 crates 源
- 验证：`rustc --version`（需 >= 1.74.0）

### Step 5: 安装 Node.js 18

- 从 `https://npmmirror.com/mirrors/node/v18.20.4/node-v18.20.4-linux-x64.tar.xz` 下载
- 解压到 `/usr/local`
- 设置 `npm config set registry https://registry.npmmirror.com`
- 验证：`node --version`

### Step 6: 安装 Python 3.9

- `sudo dnf install -y python39 python39-pip python39-devel`
- 配置 pip 阿里源
- 安装：`grpcio grpcio-tools protobuf flake8 isort black`
- 验证：`python3.9 --version`

### Step 7: 安装 PHP & Composer

- `sudo dnf install -y php php-cli php-mbstring php-xml`
- 从阿里源下载 `composer.phar`
- 配置 Composer 阿里源
- 验证：`php --version`

### Step 8: 安装 Maven（Java 构建用）

- 检查是否已安装，未安装则 `sudo dnf install -y maven`
- 配置 `~/.m2/settings.xml` 添加阿里云 mirror

---

## 第二阶段：按顺序测试各语言

### 测试执行规则

1. **发送先行**：先运行 Producer 发送消息，再运行 Consumer 消费
2. **Topic 严格匹配**：
   - 普通 Producer → `NormalTest`
   - 顺序 Producer → `OrderTest`
   - 定时 Producer → `TimerTest`
   - 事务 Producer → `TransTest`
3. **Consumer 类型覆盖**：每个语言至少测试 Push Consumer 和 Simple Consumer
4. **超时控制**：Consumer 运行 15-30 秒后停止，Producer 发送 3-10 条消息

### 各语言配置修改策略

| 语言 | 配置方式 | 需修改的文件 |
| --- | --- | --- |
| Java | 修改 `ProducerSingleton.java` 常量 + 各 example 中 topic | `ProducerSingleton.java` + 4 个 Producer example + 2 个 Consumer example |
| Golang | 修改各 `main.go` 中的 `const` 块 | 每个 producer/consumer 子目录的 `main.go` |
| C++ | 通过 `--access_point` 和 `--topic` 命令行参数传入，无需改代码 | 运行命令时传参 |
| C# | 设置环境变量 `ROCKETMQ_ACCESS_KEY`/`ROCKETMQ_SECRET_KEY`/`ROCKETMQ_ENDPOINT`，修改 topic | 各 Example 文件中的 topic 常量 |
| Rust | 修改 example 中的 `set_access_url` 和 topic | 各 example 文件 |
| Python | 修改 example 中的 `endpoints` 和 `topic` 变量 | 各 example 文件 |
| Node.js | 设置环境变量 `ROCKETMQ_NODEJS_CLIENT_ENDPOINTS`，修改 `ProducerSingleton.ts` 中的 topics | `ProducerSingleton.ts` |
| PHP | 仅 WIP stub，跳过消息收发测试 | — |

---

### Step 9: 测试 Java

```bash
cd java && mvn -B compile --file pom.xml -DskipTests
```

**修改配置**：
- `ProducerSingleton.java`：`ENDPOINTS` 改为 `rmq-cn-u7c3giqmw0s-vpc.cn-hangzhou.rmq.aliyuncs.com:8080`，清空 `ACCESS_KEY`/`SECRET_KEY`
- `ProducerNormalMessageExample.java`：topic → `NormalTest`
- `ProducerFifoMessageExample.java`：topic → `OrderTest`
- `ProducerDelayMessageExample.java`：topic → `TimerTest`
- `ProducerTransactionMessageExample.java`：topic → `TransTest`
- `PushConsumerExample.java`：endpoints/topic(consumerGroup→`PushConsumer`, topic→`NormalTest`)
- `SimpleConsumerExample.java`：endpoints/topic(consumerGroup→`SimpleConsumer`, topic→`NormalTest`)

**Producer 测试**（按顺序运行）：
1. `ProducerNormalMessageExample` → 发送到 `NormalTest`
2. `ProducerFifoMessageExample` → 发送到 `OrderTest`
3. `ProducerDelayMessageExample` → 发送到 `TimerTest`
4. `ProducerTransactionMessageExample` → 发送到 `TransTest`

**Consumer 测试**（每个运行 15 秒后 kill）：
1. `PushConsumerExample` → 消费组 `PushConsumer`，订阅 `NormalTest`
2. `SimpleConsumerExample` → 消费组 `SimpleConsumer`，订阅 `NormalTest`

### Step 10: 测试 Golang

```bash
cd golang && go build ./...
```

**修改配置**：每个 producer/consumer 的 `main.go`：
- `Endpoint` → `rmq-cn-u7c3giqmw0s-vpc.cn-hangzhou.rmq.aliyuncs.com:8080`
- 清空 `AccessKey`/`SecretKey`
- `Topic` 按类型设置

**Producer 测试**：
1. `producer/normal/main.go` → `NormalTest`
2. `producer/fifo/main.go` → `OrderTest`
3. `producer/delay/main.go` → `TimerTest`
4. `producer/transaction/main.go` → `TransTest`

**Consumer 测试**（每个运行 15 秒后 kill）：
1. `consumer/push_consumer/main.go` → `PushConsumer`，`NormalTest`
2. `consumer/simple_consumer/main.go` → `SimpleConsumer`，`NormalTest`

### Step 11: 测试 C++

```bash
cd cpp && mkdir -p build && cd build && cmake .. && make -j $(nproc)
```

> 需先安装 gRPC、protobuf、absl、gflags 等 C++ 依赖（从源码编译或使用 vcpkg）

**Producer 测试**（命令行传参）：
1. `ExampleProducer` → `--access_point=rmq-cn-u7c3giqmw0s-vpc.cn-hangzhou.rmq.aliyuncs.com:8080 --topic=NormalTopic`
2. `ExampleFifoProducer` → `--access_point=... --topic=OrderTest`
3. `ExampleProducerWithTimedMessage` → `--access_point=... --topic=TimerTest`
4. `ExampleProducerWithTransactionalMessage` → `--access_point=... --topic=TransTest`

**Consumer 测试**（每个运行 15 秒后 kill）：
1. `ExamplePushConsumer` → 消费组 `PushConsumer`，`NormalTopic`
2. `ExampleSimpleConsumer` → 消费组 `SimpleConsumer`，`NormalTopic`

### Step 12: 测试 C#

```bash
cd csharp && dotnet build
```

**修改配置**：
- 设置环境变量 `ROCKETMQ_ENDPOINT=rmq-cn-u7c3giqmw0s-vpc.cn-hangzhou.rmq.aliyuncs.com:8080`
- 修改各 Example 文件中的 topic 常量

**Producer 测试**：
1. `ProducerNormalMessageExample` → `NormalTest`
2. `ProducerFifoMessageExample` → `OrderTest`
3. `ProducerDelayMessageExample` → `TimerTest`
4. `ProducerTransactionMessageExample` → `TransTest`

**Consumer 测试**（每个运行 15 秒后 kill）：
1. `PushConsumerExample` → `PushConsumer`，`NormalTest`
2. `SimpleConsumerExample` → `SimpleConsumer`，`NormalTest`

### Step 13: 测试 Rust

```bash
cd rust && cargo build
```

**修改配置**：
- 各 example 中 `set_access_url` → `rmq-cn-u7c3giqmw0s-vpc.cn-hangzhou.rmq.aliyuncs.com:8080`
- topic 按类型设置

**Producer 测试**：
1. `producer.rs` → `NormalTest`
2. `fifo_producer.rs` → `OrderTest`
3. `delay_producer.rs` → `TimerTest`
4. `transaction_producer.rs` → `TransTest`

**Consumer 测试**（每个运行 15 秒后 kill）：
1. `push_consumer.rs` → `PushConsumer`，`NormalTest`
2. `simple_consumer.rs` → `SimpleConsumer`，`NormalTest`

### Step 14: 测试 Python

```bash
cd python && python3.9 -c "pass"
```

**修改配置**：
- 各 example 中 `endpoints` → `rmq-cn-u7c3giqmw0s-vpc.cn-hangzhou.rmq.aliyuncs.com:8080`
- topic 按类型设置

**Producer 测试**：
1. `normal_producer_example.py` → `NormalTest`
2. `fifo_producer_example.py` → `OrderTest`
3. `delay_producer_example.py` → `TimerTest`
4. `transaction_producer_example.py` → `TransTest`

**Consumer 测试**（每个运行 15 秒后 kill）：
1. `push_consumer_example.py` → `PushConsumer`，`NormalTest`
2. `simple_consumer_example.py` → `SimpleConsumer`，`NormalTest`

### Step 15: 测试 Node.js

```bash
cd nodejs && npm install && npm run init && npm run build
```

**修改配置**：
- 设置环境变量 `ROCKETMQ_NODEJS_CLIENT_ENDPOINTS=rmq-cn-u7c3giqmw0s-vpc.cn-hangzhou.rmq.aliyuncs.com:8080`
- 修改 `ProducerSingleton.ts` 中 topics 映射

**Producer 测试**：
1. `ProducerNormalMessageExample.ts` → `NormalTest`
2. `ProducerFifoMessageExample.ts` → `OrderTest`
3. `ProducerDelayMessageExample.ts` → `TimerTest`
4. `ProducerTransactionMessageExample.ts` → `TransTest`

**Consumer 测试**（每个运行 15 秒后 kill）：
1. `PushConsumer.ts` → `PushConsumer`，`NormalTest`
2. `SimpleConsumer.ts` → `SimpleConsumer`，`NormalTest`

### Step 16: 验证 PHP（仅编译）

```bash
cd php && composer validate && composer install
```

> PHP 为 WIP 状态，仅验证依赖安装和编译，不执行消息收发测试。

---

## 注意事项

1. **Python 3.6 不可替换**：使用 python3.9 并行安装
2. **磁盘空间**：安装所有 SDK + C++ 依赖预计 3-5GB
3. **C++ 依赖**：CMake 需要 gRPC、protobuf、absl、gflags、zlib、openssl 等 C++ 库，可能需要从源码编译（耗时较长）
4. **Consumer 超时**：Push Consumer 会阻塞等待消息，需设置 timeout 或手动 kill
5. **消息隔离**：各语言测试同一 Topic 时消息会混在一起，通过日志中的 language 标识区分
6. **顺序 Consumer**：`PushOrderConsumer` 和 `SimpleOrderConsumer` 专门用于消费 `OrderTest` 的顺序消息
