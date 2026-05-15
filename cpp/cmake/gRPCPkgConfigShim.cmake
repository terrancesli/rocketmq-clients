# Shim: create gRPC and protobuf cmake imported targets from pkg-config results
# Used when Ubuntu system packages are installed (no gRPCConfig.cmake / protobufConfig.cmake)

find_package(PkgConfig REQUIRED)
pkg_check_modules(GRPC_PKG REQUIRED grpc++ grpc)

# Create gRPC::grpc target
add_library(gRPC::grpc INTERFACE IMPORTED)
set_target_properties(gRPC::grpc PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${GRPC_PKG_INCLUDE_DIRS}"
    INTERFACE_LINK_LIBRARIES "${GRPC_PKG_LIBRARIES}"
    INTERFACE_COMPILE_OPTIONS "${GRPC_PKG_CFLAGS_OTHER}")

# Create gRPC::grpc++ target
add_library(gRPC::grpc++ INTERFACE IMPORTED)
set_target_properties(gRPC::grpc++ PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${GRPC_PKG_INCLUDE_DIRS}"
    INTERFACE_LINK_LIBRARIES "${GRPC_PKG_LIBRARIES}")

# Create gRPC::grpc_cpp_plugin target (Ubuntu provides /usr/bin/grpc_cpp_plugin)
add_executable(gRPC::grpc_cpp_plugin IMPORTED)
find_program(GRPC_CPP_PLUGIN_PATH grpc_cpp_plugin)
set_target_properties(gRPC::grpc_cpp_plugin PROPERTIES
    IMPORTED_LOCATION "${GRPC_CPP_PLUGIN_PATH}")
