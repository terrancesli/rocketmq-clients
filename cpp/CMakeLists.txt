cmake_minimum_required(VERSION 3.16)
project(rocketmq)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(gRPC_DEBUG ON)

list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)

# Try gRPC from source install (cmake config); fallback to pkg-config shim
find_package(gRPC CONFIG QUIET)
if(NOT gRPC_FOUND)
    include(gRPCPkgConfigShim)
    set(GRPC_FROM_PKG ON)
endif()

# Try protobuf from source install (cmake config), fallback to CMake module
find_package(protobuf CONFIG QUIET)
if(NOT protobuf_FOUND)
    find_package(Protobuf QUIET)
endif()

find_package(absl QUIET)
if(NOT absl_FOUND)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(ABSL REQUIRED absl)
endif()

find_package(OpenSSL REQUIRED)

add_subdirectory(proto)

add_library(api INTERFACE)
target_include_directories(api INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/include)

add_subdirectory(third_party)

add_subdirectory(source)

option(BUILD_EXAMPLES "Build example programs or not" ON)
if (BUILD_EXAMPLES)
    message("Would build examples")
    list(APPEND CMAKE_PREFIX_PATH $ENV{HOME}/gflags)
    find_package(gflags REQUIRED)
    find_package(ZLIB REQUIRED)
    add_subdirectory(examples)
endif ()
