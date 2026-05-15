# C++ 客户端环境搭建

## 系统要求

- OS: Alibaba Cloud Linux 3 / CentOS / RHEL 系列
- 磁盘: 预计 3-5GB（所有依赖 + 源码编译）
- 内存: 编译 gRPC 建议 4GB+

## Step 1: 基础开发工具

```bash
sudo yum groupinstall -y "Development Tools"
sudo yum install -y openssl-devel wget curl make automake gcc-c++ flex bison \
  libgomp glibc-devel glibc-headers kernel-headers libmpc-devel mpfr-devel
```

## Step 2: 安装 GCC 11.5.0

```bash
cd /tmp
wget 'https://ftp.gnu.org/gnu/gcc/gcc-11.5.0/gcc-11.5.0.tar.gz'
tar -xzf gcc-11.5.0.tar.gz
cd gcc-11.5.0
./contrib/download_prerequisites
mkdir build && cd build
../configure --prefix=/usr/local/gcc-11.5.0 \
  --enable-bootstrap --enable-languages=c,c++ \
  --enable-shared --with-system-zlib --enable-threads=posix \
  --enable-checking=release --with-demangler-in-ld --enable-multilib
make -j$(nproc)
sudo make install

echo 'export PATH=/usr/local/gcc-11.5.0/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
gcc --version  # 应显示 11.5.0
```

> 如果系统已有满足版本的 GCC，可跳过此步。

## Step 3: 安装 JDK 11（Bazel 需要）

```bash
sudo yum install -y java-11-openjdk-devel
rm -f /usr/bin/java && ln -s /usr/lib/jvm/java-11-openjdk/bin/java /usr/bin/java
java -version
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk' >> ~/.bashrc
echo 'export PATH="${JAVA_HOME}/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Step 4: 安装 CMake 3.30.2

```bash
cd /tmp
wget 'https://github.com/Kitware/CMake/releases/download/v3.30.2/cmake-3.30.2.tar.gz'
tar zxvf cmake-3.30.2.tar.gz
cd cmake-3.30.2
./configure --prefix=/usr/local/cmake
make -j$(nproc) && sudo make install
echo 'export CMAKE_HOME=/usr/local/cmake' >> ~/.bashrc
echo 'export PATH="${CMAKE_HOME}/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
cmake --version
```

## Step 5: 安装 Bazel 7.2.1

```bash
cd /tmp
wget 'https://github.com/bazelbuild/bazel/releases/download/7.2.1/bazel-7.2.1-linux-x86_64'
chmod +x bazel-7.2.1-linux-x86_64
sudo mv bazel-7.2.1-linux-x86_64 /usr/local/bin/bazel
bazel version
```

## Step 6: 安装 protobuf 3.20.1

```bash
cd /tmp
wget 'https://shutian.oss-cn-hangzhou.aliyuncs.com/cdn/protobuf/protobuf-3.20.1.tar.gz'
tar zxvf protobuf-3.20.1.tar.gz
cd protobuf-3.20.1
./autogen.sh
./configure --prefix=/usr/local/protobuf
sudo make -j$(nproc)
sudo make install
sudo ldconfig

echo 'export PATH=/usr/local/protobuf/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/protobuf/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc
protoc --version  # 应显示 3.20.1
```

## Step 7: 安装 gflags 2.2.2

```bash
cd /tmp
wget -O gflags-2.2.2.tar.gz https://github.com/gflags/gflags/archive/v2.2.2.tar.gz
tar -xvzf gflags-2.2.2.tar.gz
cd gflags-2.2.2
mkdir build && cd build
cmake -DBUILD_SHARED_LIBS=ON -DBUILD_STATIC_LIBS=ON \
  -DINSTALL_HEADERS=ON -DINSTALL_SHARED_LIBS=ON -DINSTALL_STATIC_LIBS=ON ..
make -j$(nproc)
sudo make install
cd

cat >> ~/.bashrc << 'EOF'
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
export PATH=/usr/local/gflags/bin:$PATH
EOF
source ~/.bashrc
```

## Step 8: 编译安装 gRPC 1.46.3

```bash
export MY_INSTALL_DIR=$HOME/grpc
mkdir -p "$MY_INSTALL_DIR"

cd /tmp
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
make -j$(nproc)
sudo make install
popd

# 添加环境变量
cat >> ~/.bashrc << EOF
export PATH="\$MY_INSTALL_DIR/bin:\$PATH"
export LD_LIBRARY_PATH="\$MY_INSTALL_DIR/lib:\$LD_LIBRARY_PATH"
EOF
source ~/.bashrc
```

> `--depth 1` 只拉取最新 tag，大幅减少下载量。`--recurse-submodules` 确保拉取第三方依赖。

## Step 9: 下载 C++ 客户端源码

```bash
# 如果已有 rocketmq-clients 仓库，确保 submodule 已初始化
git submodule update --init --recursive

# 或全新克隆
git clone --recursive https://github.com/apache/rocketmq-clients.git
```

## Step 10: 编译客户端

### 方式一：CMake

```bash
cd cpp
mkdir -p build && cd build
cmake .. && make -j $(nproc)
```

### 方式二：Bazel

```bash
cd cpp
bazel build //...
bazel test //...
```

## 环境变量汇总

编译和运行时需要的关键环境变量：

```bash
# GCC 11.5.0
export PATH=/usr/local/gcc-11.5.0/bin:$PATH

# CMake
export CMAKE_HOME=/usr/local/cmake
export PATH="${CMAKE_HOME}/bin:$PATH"

# protobuf
export PATH=/usr/local/protobuf/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/protobuf/lib:$LD_LIBRARY_PATH

# gflags & common libs
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

# gRPC
export MY_INSTALL_DIR=$HOME/grpc
export PATH="$MY_INSTALL_DIR/bin:$PATH"
export LD_LIBRARY_PATH="$MY_INSTALL_DIR/lib:$LD_LIBRARY_PATH"
```
