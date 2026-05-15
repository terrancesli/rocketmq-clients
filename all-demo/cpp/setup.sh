#!/usr/bin/env bash
# RocketMQ C++ Client 依赖安装脚本
# 适用于 Alibaba Cloud Linux 3 / CentOS / RHEL
# 用法: bash setup.sh [--skip-gcc] [--skip-cmake] [--skip-bazel] [--skip-protobuf] [--skip-grpc] [--dry-run]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$SCRIPT_DIR/setup.log"

# ─── 颜色输出 ───
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*"; }

# ─── 选项解析 ───
SKIP_GCC=false; SKIP_CMAKE=false; SKIP_BAZEL=false
SKIP_PROTOBUF=false; SKIP_GRPC=false; DRY_RUN=false
NPROC=$(nproc)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-gcc)       SKIP_GCC=true;       shift ;;
    --skip-cmake)     SKIP_CMAKE=true;     shift ;;
    --skip-bazel)     SKIP_BAZEL=true;     shift ;;
    --skip-protobuf)  SKIP_PROTOBUF=true;  shift ;;
    --skip-grpc)      SKIP_GRPC=true;      shift ;;
    --dry-run)        DRY_RUN=true;        shift ;;
    *)                err "Unknown option: $1"; exit 1 ;;
  esac
done

run() {
  if $DRY_RUN; then
    echo "  [DRY-RUN] $*"
  else
    "$@" 2>&1 | tee -a "$LOG_FILE"
  fi
}

# ─── 前置检查 ───
if [[ $EUID -ne 0 ]]; then
  err "请使用 root 权限运行此脚本: sudo bash $0"
  exit 1
fi

log "========================================="
log "RocketMQ C++ 依赖安装"
log "========================================="
log "CPU 核心数: $NPROC"
log "日志文件:   $LOG_FILE"

# ─── Step 1: 系统基础工具 ───
log "[1/7] 安装系统基础工具..."
run yum groupinstall -y "Development Tools"
run yum install -y openssl-devel wget curl make automake gcc-c++ flex bison \
  libgomp glibc-devel glibc-headers kernel-headers libmpc-devel mpfr-devel

# ─── Step 2: GCC 11.5.0 ───
if ! $SKIP_GCC; then
  if command -v gcc &>/dev/null && gcc -dumpversion | grep -q '^11\.'; then
    log "GCC 11.x 已安装，跳过。"
  else
    log "[2/7] 安装 GCC 11.5.0..."
    TMPDIR=$(mktemp -d)
    cd "$TMPDIR"
    wget -q 'https://ftp.gnu.org/gnu/gcc/gcc-11.5.0/gcc-11.5.0.tar.gz'
    tar -xzf gcc-11.5.0.tar.gz
    cd gcc-11.5.0
    ./contrib/download_prerequisites
    mkdir -p build && cd build
    ../configure --prefix=/usr/local/gcc-11.5.0 \
      --enable-bootstrap --enable-languages=c,c++ \
      --enable-shared --with-system-zlib --enable-threads=posix \
      --enable-checking=release --with-demangler-in-ld --enable-multilib
    make -j"$NPROC"
    make install
    echo 'export PATH=/usr/local/gcc-11.5.0/bin:$PATH' >> ~/.bashrc
    export PATH=/usr/local/gcc-11.5.0/bin:$PATH
    rm -rf "$TMPDIR"
    log "GCC $(gcc --version | head -1) 安装完成"
  fi
fi

# ─── Step 3: JDK 11 ───
log "[3/7] 安装 JDK 11..."
if ! command -v java &>/dev/null || ! java -version 2>&1 | grep -q '11\.'; then
  run yum install -y java-11-openjdk-devel
  rm -f /usr/bin/java && ln -s /usr/lib/jvm/java-11-openjdk/bin/java /usr/bin/java
  echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk' >> ~/.bashrc
  echo 'export PATH="${JAVA_HOME}/bin:$PATH"' >> ~/.bashrc
else
  log "JDK 11 已安装"
fi

# ─── Step 4: CMake 3.30.2 ───
if ! $SKIP_CMAKE; then
  if command -v cmake &>/dev/null && cmake --version | grep -q '3\.3[0-9]\|3\.[4-9]'; then
    log "CMake 3.30+ 已安装，跳过。"
  else
    log "[4/7] 安装 CMake 3.30.2..."
    TMPDIR=$(mktemp -d)
    cd "$TMPDIR"
    wget -q 'https://github.com/Kitware/CMake/releases/download/v3.30.2/cmake-3.30.2.tar.gz'
    tar zxvf cmake-3.30.2.tar.gz
    cd cmake-3.30.2
    ./configure --prefix=/usr/local/cmake
    make -j"$NPROC"
    make install
    echo 'export CMAKE_HOME=/usr/local/cmake' >> ~/.bashrc
    echo 'export PATH="${CMAKE_HOME}/bin:$PATH"' >> ~/.bashrc
    export CMAKE_HOME=/usr/local/cmake
    export PATH="${CMAKE_HOME}/bin:$PATH"
    rm -rf "$TMPDIR"
    log "CMake $(cmake --version | head -1) 安装完成"
  fi
fi

# ─── Step 5: Bazel 7.2.1 ───
if ! $SKIP_BAZEL; then
  if command -v bazel &>/dev/null; then
    log "Bazel 已安装 ($(bazel version | head -1))，跳过。"
  else
    log "[5/7] 安装 Bazel 7.2.1..."
    cd /tmp
    wget -q 'https://github.com/bazelbuild/bazel/releases/download/7.2.1/bazel-7.2.1-linux-x86_64'
    chmod +x bazel-7.2.1-linux-x86_64
    mv bazel-7.2.1-linux-x86_64 /usr/local/bin/bazel
    echo 'export PATH="$PATH:/usr/local/bin"' >> ~/.bashrc
    log "Bazel $(bazel version | head -1) 安装完成"
  fi
fi

# ─── Step 6: protobuf 3.20.1 ───
if ! $SKIP_PROTOBUF; then
  if command -v protoc &>/dev/null && protoc --version | grep -q '3.20'; then
    log "protobuf 3.20.1 已安装，跳过。"
  else
    log "[6/7] 安装 protobuf 3.20.1..."
    TMPDIR=$(mktemp -d)
    cd "$TMPDIR"
    wget -q 'https://shutian.oss-cn-hangzhou.aliyuncs.com/cdn/protobuf/protobuf-3.20.1.tar.gz'
    tar zxvf protobuf-3.20.1.tar.gz
    cd protobuf-3.20.1
    ./autogen.sh
    ./configure --prefix=/usr/local/protobuf
    make -j"$NPROC"
    make install
    ldconfig
    echo 'export PATH=/usr/local/protobuf/bin:$PATH' >> ~/.bashrc
    echo 'export LD_LIBRARY_PATH=/usr/local/protobuf/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
    export PATH=/usr/local/protobuf/bin:$PATH
    export LD_LIBRARY_PATH=/usr/local/protobuf/lib:$LD_LIBRARY_PATH
    rm -rf "$TMPDIR"
    log "protobuf $(protoc --version) 安装完成"
  fi
fi

# ─── Step 6b: gflags 2.2.2 ───
log "安装 gflags 2.2.2..."
if pkg-config --exists gflags 2>/dev/null; then
  log "gflags 已安装，跳过。"
else
  TMPDIR=$(mktemp -d)
  cd "$TMPDIR"
  wget -q -O gflags-2.2.2.tar.gz https://github.com/gflags/gflags/archive/v2.2.2.tar.gz
  tar -xvzf gflags-2.2.2.tar.gz
  cd gflags-2.2.2
  mkdir -p build && cd build
  cmake -DBUILD_SHARED_LIBS=ON -DBUILD_STATIC_LIBS=ON \
    -DINSTALL_HEADERS=ON -DINSTALL_SHARED_LIBS=ON -DINSTALL_STATIC_LIBS=ON ..
  make -j"$NPROC"
  make install
  rm -rf "$TMPDIR"
  # 更新 LD_LIBRARY_PATH（幂等写入）
  if ! grep -q '/usr/local/lib' ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc << 'EOF'
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
EOF
  fi
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
  log "gflags 安装完成"
fi

# ─── Step 7: gRPC 1.46.3 ───
if ! $SKIP_GRPC; then
  export MY_INSTALL_DIR="${MY_INSTALL_DIR:-$HOME/grpc}"
  if [[ -d "$MY_INSTALL_DIR/lib" ]] && [[ -f "$MY_INSTALL_DIR/lib/libgrpc.so" ]]; then
    log "gRPC 已安装于 $MY_INSTALL_DIR，跳过。"
  else
    log "[7/7] 编译安装 gRPC 1.46.3..."
    mkdir -p "$MY_INSTALL_DIR"
    TMPDIR=$(mktemp -d)
    cd "$TMPDIR"
    git clone --recurse-submodules \
      -b v1.46.3 --depth 1 --shallow-submodules \
      https://github.com/grpc/grpc
    cd grpc
    mkdir -p cmake/build
    pushd cmake/build
    cmake -DgRPC_INSTALL=ON \
      -DgRPC_BUILD_TESTS=OFF \
      -DCMAKE_INSTALL_PREFIX="$MY_INSTALL_DIR" \
      ../..
    make -j"$NPROC"
    make install
    popd
    rm -rf "$TMPDIR"
    echo "export MY_INSTALL_DIR=$MY_INSTALL_DIR" >> ~/.bashrc
    echo 'export PATH="$MY_INSTALL_DIR/bin:$PATH"' >> ~/.bashrc
    echo 'export LD_LIBRARY_PATH="$MY_INSTALL_DIR/lib:$LD_LIBRARY_PATH"' >> ~/.bashrc
    export PATH="$MY_INSTALL_DIR/bin:$PATH"
    export LD_LIBRARY_PATH="$MY_INSTALL_DIR/lib:$LD_LIBRARY_PATH"
    log "gRPC 安装完成 (install dir: $MY_INSTALL_DIR)"
  fi
fi

# ─── 最终环境写入 ───
if ! grep -q 'LD_LIBRARY_PATH.*:/usr/local/lib' ~/.bashrc 2>/dev/null; then
  cat >> ~/.bashrc << 'EOF'
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
EOF
fi

log "========================================="
log "安装完成！请运行以下命令使环境变量生效："
log "  source ~/.bashrc"
log ""
log "然后编译 C++ 客户端："
log "  cd cpp && mkdir -p build && cd build"
log "  cmake .. && make -j $(nproc)"
log "========================================="
