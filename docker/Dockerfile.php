# syntax=docker/dockerfile:1
# ============================================
# PHP — RocketMQ Client Test (WIP)
# 国内源: 阿里云 Composer
# ============================================
FROM php:8.2-cli

# 配置 Composer 阿里云镜像
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer config -g repos.packagist composer https://mirrors.aliyun.com/composer/

RUN docker-php-ext-install pcntl

WORKDIR /app
COPY php/ ./php/

RUN cd php && composer install --no-dev --no-interaction || true

COPY all-demo/php/ /app/examples/
COPY docker/run-php-test.sh /app/

ENV ROCKETMQ_ENDPOINT="127.0.0.1:8080"
ENV ROCKETMQ_ACCESS_KEY=""
ENV ROCKETMQ_SECRET_KEY=""

RUN chmod +x /app/run-php-test.sh

ENTRYPOINT ["/app/run-php-test.sh"]
