# syntax=docker/dockerfile:1
# ============================================
# C++ — RocketMQ Client Test
# 注意: C++ 依赖需从源码编译，Docker 构建时间较长
# gRPC 子模块需预先在宿主机克隆好
# ============================================
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# 系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake git \
    libssl-dev zlib1g-dev pkg-config \
    libprotobuf-dev protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# 如果宿主机已预编译 gRPC，直接 COPY；否则从源码编译
ARG COPY_GRPC=0

# 预安装 gflags
RUN git clone --depth 1 https://github.com/gflags/gflags.git /tmp/gflags \
    && cd /tmp/gflags && mkdir build && cd build \
    && cmake -DCMAKE_INSTALL_PREFIX=/usr/local .. && make -j$(nproc) && make install \
    && rm -rf /tmp/gflags

# 拷贝项目源码
COPY cpp/ ./cpp/

# 构建
RUN cd cpp && mkdir -p build && cd build \
    && cmake .. -DCMAKE_BUILD_TYPE=Release \
    && make -j$(nproc)

# ---------- runtime ----------
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl3 zlib1g libprotobuf32 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /build/cpp/build/ExampleProducer /app/bin/
COPY --from=builder /build/cpp/build/ExampleFifoProducer /app/bin/
COPY --from=builder /build/cpp/build/ExampleProducerWithTimedMessage /app/bin/
COPY --from=builder /build/cpp/build/ExampleProducerWithTransactionalMessage /app/bin/
COPY --from=builder /build/cpp/build/ExamplePushConsumer /app/bin/
COPY --from=builder /build/cpp/build/ExampleSimpleConsumer /app/bin/
COPY docker/run-cpp-test.sh /app/

ENV ROCKETMQ_ENDPOINT="127.0.0.1:8080"
ENV ROCKETMQ_ACCESS_KEY=""
ENV ROCKETMQ_SECRET_KEY=""

RUN chmod +x /app/run-cpp-test.sh

ENTRYPOINT ["/app/run-cpp-test.sh"]
