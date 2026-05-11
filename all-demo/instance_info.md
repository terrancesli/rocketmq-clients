# RocketMQ 测试实例信息

> 实例连接信息统一保存在同目录下的 `.env.example` 文件中。

## Topic 信息

| 消息类型 | Topic | 说明 |
| - | - | - |
| 普通消息 | NormalTest | 基础消息收发 |
| 顺序消息 | OrderTest | FIFO 顺序消息，需指定 message_group |
| 定时消息 | TimerTest | 延时/定时消息，需设置 delivery_timestamp |
| 事务消息 | TransTest | 事务消息，需实现 TransactionChecker |

## 消费组信息

| 消费组名称 | 消费者类别 | 是否顺序 |
| - | - | - |
| PushConsumer | Push Consumer | 否 |
| PushOrderConsumer | Push Consumer | 是 |
| SimpleConsumer | Simple Consumer | 否 |
| SimpleOrderConsumer | Simple Consumer | 是 |

## 注意事项

- VPC 内网接入点仅支持在阿里云 VPC 网络内访问
- 如从公网访问，需使用公网接入点（如有）
