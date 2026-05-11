# RocketMQ 测试实例信息

> 本文档记录 RocketMQ 测试实例的连接信息，供开发和调试使用。

## 实例详情

| 字段        | 值                                                           |
| ----------- | ------------------------------------------------------------ |
| 实例 ID     | `rmq-cn-u7c3giqmw0s`                                         |
| 接入点      | `rmq-cn-u7c3giqmw0s-vpc.cn-hangzhou.rmq.aliyuncs.com:8080`   |
| 地域        | 杭州（cn-hangzhou）                                          |
| 协议        | gRPC（8080 端口）                                            |

## Topic 信息

| 消息类型   | Topic     | 说明                                             |
| ---------- | --------- | ------------------------------------------------ |
| 普通消息   | NormalTest | 基础消息收发                                     |
| 顺序消息   | OrderTest | FIFO 顺序消息，需指定 message_group              |
| 定时消息   | TimerTest | 延时/定时消息，需设置 delivery_timestamp         |
| 事务消息   | TransTest | 事务消息，需实现 TransactionChecker              |

## 消费组信息

| 消费组名称          | 消费者类别    | 是否顺序 |
| ------------------- | ------------- | -------- |
| PushConsumer        | Push Consumer | 否       |
| PushOrderConsumer   | Push Consumer | 是       |
| SimpleConsumer      | Simple Consumer | 否     |
| SimpleOrderConsumer | Simple Consumer | 是     |

## 使用示例

### Java

```java
ClientConfiguration configuration = ClientConfiguration.newBuilder()
    .setEndpoints("rmq-cn-u7c3giqmw0s-vpc.cn-hangzhou.rmq.aliyuncs.com:8080")
    .build();
```

### Golang

```go
config := &config.Config{
    Endpoints: []string{"rmq-cn-u7c3giqmw0s-vpc.cn-hangzhou.rmq.aliyuncs.com:8080"},
}
```

### C++

```cpp
rocketmq::ClientConfiguration config;
config.SetEndpoints("rmq-cn-u7c3giqmw0s-vpc.cn-hangzhou.rmq.aliyuncs.com:8080");
```

### C#

```csharp
var config = new ClientConfig.Builder()
    .Endpoints("rmq-cn-u7c3giqmw0s-vpc.cn-hangzhou.rmq.aliyuncs.com:8080")
    .Build();
```

### Rust

```rust
let config = rocketmq::Config::new("rmq-cn-u7c3giqmw0s-vpc.cn-hangzhou.rmq.aliyuncs.com:8080");
```

### Python

```python
config = rocketmq.Config(
    endpoints="rmq-cn-u7c3giqmw0s-vpc.cn-hangzhou.rmq.aliyuncs.com:8080"
)
```

### Node.js

```typescript
const client = new Producer({
  endpoint: 'rmq-cn-u7c3giqmw0s-vpc.cn-hangzhou.rmq.aliyuncs.com:8080'
});
```

## 注意事项

- 8080 端口为 VPC 内网接入点，仅支持在阿里云 VPC 网络内访问
- 如从公网访问，需使用公网接入点（如有）
