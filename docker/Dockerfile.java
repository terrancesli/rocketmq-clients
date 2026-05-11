# syntax=docker/dockerfile:1
# ============================================
# Java — RocketMQ Client Test
# 国内源: Maven 阿里云
# ============================================
FROM maven:3.9-eclipse-temurin-11 AS builder

# Maven 阿里云镜像
RUN sed -i 's|https://repo.maven.apache.org/maven2|https://maven.aliyun.com/repository/public|g' /usr/share/maven/conf/settings.xml \
    && cat >> /usr/share/maven/conf/settings.xml <<'EOF'
  <mirrors>
    <mirror>
      <id>aliyun</id>
      <mirrorOf>central</mirrorOf>
      <name>Aliyun Maven</name>
      <url>https://maven.aliyun.com/repository/public</url>
    </mirror>
  </mirrors>
EOF

WORKDIR /build

# 先拷贝 pom 文件利用 Docker 层缓存
COPY java/pom.xml java/client/pom.xml ./java/client/
COPY java/client-sdk-compatibility/pom.xml ./java/client-sdk-compatibility/ 2>/dev/null || true
COPY java/pom.xml ./

# 预下载依赖
RUN mvn dependency:go-offline -pl java/client -f java/pom.xml -DskipTests \
    -Dcheckstyle.skip=true -Dmaven.javadoc.skip=true || true

# 拷贝全部源码并编译
COPY java/ ./java/
RUN mvn package -pl java/client -am -DskipTests \
    -Dcheckstyle.skip=true -Dmaven.javadoc.skip=true

# ---------- runtime ----------
FROM eclipse-temurin:11-jre

WORKDIR /app
COPY --from=builder /build/java/client/target/classes /app/classes
COPY --from=builder /build/java/client/target/dependency /app/lib
COPY all-demo/java/example/ /app/examples/
COPY docker/run-java-test.sh /app/

ENV ROCKETMQ_ENDPOINTS=""
ENV ROCKETMQ_ACCESS_KEY=""
ENV ROCKETMQ_SECRET_KEY=""
ENV ROCKETMQ_TOPIC_NORMAL="NormalTest"
ENV ROCKETMQ_TOPIC_FIFO="OrderTest"
ENV ROCKETMQ_TOPIC_DELAY="TimerTest"
ENV ROCKETMQ_TOPIC_TRANSACTION="TransTest"

RUN chmod +x /app/run-java-test.sh

ENTRYPOINT ["/app/run-java-test.sh"]
