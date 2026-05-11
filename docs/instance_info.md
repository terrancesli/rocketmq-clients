# RocketMQ 测试实例信息

> 本文档记录 RocketMQ 测试实例的连接信息，供开发和调试使用。
>
> **实际凭证请配置在 `.env` 文件中（参考 `.env.example`），不要硬编码在代码里。**

## 实例详情

| 字段        | 值                                                           |
| ----------- | ------------------------------------------------------------ |
| 实例 ID | `rmq-cn-u7c3giqmw0s` |
| 接入点 | 见 `.env.example` 中的 `ROCKETMQ_ENDPOINTS` |
| 地域 | 杭州（cn-hangzhou） |
| 协议 | gRPC（8080 端口） |

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

## 环境变量配置

所有语言的示例代码统一通过以下环境变量注入连接信息：

| 环境变量 | 说明 | 示例值 |
| --- | --- | --- |
| `ROCKETMQ_ENDPOINTS` | 接入点地址 | `xxx.rmq.aliyuncs.com:8080` |
| `ROCKETMQ_ACCESS_KEY` | 访问密钥 | `your-access-key` |
| `ROCKETMQ_SECRET_KEY` | 密钥 | `your-secret-key` |

### 各语言配置方式参考

```bash
# Java / Python / Node.js / PHP
export ROCKETMQ_ENDPOINTS="your-endpoint:8080"
export ROCKETMQ_ACCESS_KEY="your-access-key"
export ROCKETMQ_SECRET_KEY="your-secret-key"

# Golang (使用 ROCKETMQ_ENDPOINT，无 S)
export ROCKETMQ_ENDPOINT="your-endpoint:8080"
export ROCKETMQ_ACCESS_KEY="your-access-key"
export ROCKETMQ_SECRET_KEY="your-secret-key"
```

## 注意事项

- 8080 端口为 VPC 内网接入点，仅支持在阿里云 VPC 网络内访问
- 如从公网访问，需使用公网接入点（如有）
