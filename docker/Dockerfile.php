# syntax=docker/dockerfile:1
# ============================================
# PHP — RocketMQ Client Test
# 手动安装依赖，避免 composer 网络问题
# ============================================
FROM php:8.2-cli

RUN docker-php-ext-install pcntl

# 通过 PECL 安装 protobuf 和 grpc 扩展
# grpc 扩展需要编译，安装 zlib 等编译依赖
RUN apt-get update && apt-get install -y --no-install-recommends zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* \
    && pecl install protobuf grpc && docker-php-ext-enable protobuf grpc

WORKDIR /app

# 拷贝 SDK 源码（包含预生成的 grpc/ 代码）
COPY php/ ./php/
COPY all-demo/php/ ./examples/

# 拷贝 grpc 代码到 examples 使 autoloader 路径生效
RUN cp -r /app/php/grpc /app/examples/grpc

# 下载 gRPC PHP stubs (v1.80.0 匹配 PECL 版本) 并配置 autoloader
RUN GRPC_VER="v1.80.0" && mkdir -p /app/php/vendor/grpc/Grpc && \
    curl -sSL "https://gitee.com/mirrors/grpc/raw/${GRPC_VER}/src/php/lib/Grpc/BaseStub.php" -o /app/php/vendor/grpc/Grpc/BaseStub.php && \
    curl -sSL "https://gitee.com/mirrors/grpc/raw/${GRPC_VER}/src/php/lib/Grpc/UnaryCall.php" -o /app/php/vendor/grpc/Grpc/UnaryCall.php && \
    curl -sSL "https://gitee.com/mirrors/grpc/raw/${GRPC_VER}/src/php/lib/Grpc/ClientStreamingCall.php" -o /app/php/vendor/grpc/Grpc/ClientStreamingCall.php && \
    curl -sSL "https://gitee.com/mirrors/grpc/raw/${GRPC_VER}/src/php/lib/Grpc/ServerStreamingCall.php" -o /app/php/vendor/grpc/Grpc/ServerStreamingCall.php && \
    curl -sSL "https://gitee.com/mirrors/grpc/raw/${GRPC_VER}/src/php/lib/Grpc/BidiStreamingCall.php" -o /app/php/vendor/grpc/Grpc/BidiStreamingCall.php && \
    curl -sSL "https://gitee.com/mirrors/grpc/raw/${GRPC_VER}/src/php/lib/Grpc/Call.php" -o /app/php/vendor/grpc/Grpc/Call.php && \
    curl -sSL "https://gitee.com/mirrors/grpc/raw/${GRPC_VER}/src/php/lib/Grpc/AbstractCall.php" -o /app/php/vendor/grpc/Grpc/AbstractCall.php && \
    curl -sSL "https://gitee.com/mirrors/grpc/raw/${GRPC_VER}/src/php/lib/Grpc/Status.php" -o /app/php/vendor/grpc/Grpc/Status.php && \
    curl -sSL "https://gitee.com/mirrors/grpc/raw/${GRPC_VER}/src/php/lib/Grpc/DefaultCallInvoker.php" -o /app/php/vendor/grpc/Grpc/DefaultCallInvoker.php && \
    curl -sSL "https://gitee.com/mirrors/grpc/raw/${GRPC_VER}/src/php/lib/Grpc/CallInvoker.php" -o /app/php/vendor/grpc/Grpc/CallInvoker.php && \
    curl -sSL "https://gitee.com/mirrors/grpc/raw/${GRPC_VER}/src/php/lib/Grpc/Channel.php" -o /app/php/vendor/grpc/Grpc/Channel.php && \
    curl -sSL "https://gitee.com/mirrors/grpc/raw/${GRPC_VER}/src/php/lib/Grpc/CallInvocationOptions.php" -o /app/php/vendor/grpc/Grpc/CallInvocationOptions.php && \
    cp php/autoload.php /app/php/vendor/autoload.php

# 拷贝示例并将 vendor 依赖一起放入
RUN cp -r /app/php/vendor /app/examples/vendor

COPY docker/run-php-test.sh /app/

ENV ROCKETMQ_ENDPOINT="127.0.0.1:8080"
ENV ROCKETMQ_ACCESS_KEY=""
ENV ROCKETMQ_SECRET_KEY=""

RUN chmod +x /app/run-php-test.sh

ENTRYPOINT ["/app/run-php-test.sh"]
