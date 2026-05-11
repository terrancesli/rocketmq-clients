# 国内镜像源参考文档

> 基于 2025-2026 年实测，用于 RocketMQ 多语言客户端服务端测试集构建。

## Docker Hub 加速

| 镜像源 | 地址 | 状态 |
|--------|------|------|
| 轩辕 | `https://docker.xuanyuan.me` | 推荐，Cloudflare+境内CDN |
| 毫秒 | `https://docker.1ms.run` | 可用 |
| DaoCloud | `https://docker.m.daocloud.io` | 可用 |

### 配置方法

```bash
# /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://docker.xuanyuan.me",
    "https://docker.1ms.run",
    "https://docker.m.daocloud.io"
  ]
}
```

## 语言运行时 & 包管理

### Go
- **SDK 下载**: `https://mirrors.aliyun.com/golang/`
- **GOPROXY**: `https://goproxy.cn,https://goproxy.io,direct`
- `golang.google.cn` 已不可达

### Rust / Cargo
- **首选**: `https://mirrors.rustcc.cn/crates.io-index.git` (RustCC 专属源)
- **备选**: 清华 `https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git`
- **rsproxy.cn**: `https://rsproxy.cn/rustup-init.sh` (仅 rustup 安装)
- 注意：阿里/中科大 crates 镜像近年已不稳定

### Node.js / npm
- **npm registry**: `https://registry.npmmirror.com` (淘宝旧域名已迁移)
- **Node.js 二进制**: `https://npmmirror.com/mirrors/node/`

### Python / pip
- **PyPI**: `https://mirrors.aliyun.com/pypi/simple/`

### Java / Maven
- **Maven**: `https://maven.aliyun.com/repository/public`
- **JDK**: 使用官方基础镜像或 `https://mirrors.aliyun.com/adoptium/`

### .NET / NuGet
- **NuGet**: `https://nuget.cdn.azure.cn/v3/index.json` (微软中国 CDN)
- **备选**: 华为云 `https://repo.huaweicloud.com/repository/nuget/v3/index.json`
- **.NET SDK 下载**: 清华源 `https://mirrors.tuna.tsinghua.edu.cn/dotnet/`

### PHP / Composer
- **Packagist**: 阿里云 Composer 源

### C++ 依赖
- **gRPC**: 需从源码编译或本地预先克隆 `https://github.com/grpc/grpc`
- **子模块**: boringssl, protobuf, absl, re2, c-ares 等均需从 GitHub 拉取
- **建议**: 预先在本机克隆 gRPC 子模块，Dockerfile 中 COPY 进去
- 无可靠的国内 gRPC 二进制镜像

## 已知不可用的旧源

| 源 | 状态 |
|----|------|
| `registry.npm.taobao.org` | 已停用，迁移至 npmmirror.com |
| `golang.google.cn` | 不可达 |
| rsproxy.cn crates 源 | config.json not found |
| 中科大 crates 镜像 | 不稳定 |
| Docker Hub 官方直连 | 国内基本超时 |
