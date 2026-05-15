# syntax=docker/dockerfile:1
# ============================================
# Java — RocketMQ Client Test
# 国内源: Maven 阿里云
# ============================================
FROM maven:3.9-eclipse-temurin-11 AS builder

# 配置 Maven 阿里云镜像
RUN cat > /usr/share/maven/conf/settings.xml <<'EOF'
<settings>
  <mirrors>
    <mirror>
      <id>aliyun</id>
      <name>Aliyun Maven</name>
      <url>https://maven.aliyun.com/repository/public</url>
      <mirrorOf>central</mirrorOf>
    </mirror>
  </mirrors>
</settings>
EOF

WORKDIR /build
COPY java/ ./java/

# 构建客户端库并安装到本地仓库
RUN cd java && mvn install -pl client -am -DskipTests \
    -Dcheckstyle.skip=true -Dmaven.javadoc.skip=true -Dspotbugs.skip=true -q

# 拷贝依赖到 /app/lib
RUN cd java/client && mvn dependency:copy-dependencies \
    -DoutputDirectory=/app/lib -Dcheckstyle.skip=true -Dspotbugs.skip=true -q \
    && cp target/rocketmq-client-java-noshade-*.jar /app/lib/

# 编译 all-demo 示例 (不缓存，源码改动后必定重编译)
ARG CACHEBUST=1
COPY all-demo/java/example/ /tmp/examples/
RUN rm -rf /app/classes && mkdir -p /app/classes \
    && javac -cp "/app/lib/*" -d /app/classes /tmp/examples/*.java

# ---------- runtime ----------
FROM eclipse-temurin:11-jre

WORKDIR /app
COPY --from=builder /app/lib /app/lib
COPY --from=builder /app/classes /app/classes
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
