# ============================================================
#  logstat CMake 工程
#  用法:
#    cmake -B build            # 生成构建系统
#    cmake --build build -j    # 编译
#    ./build/logstat tests/sample.log ERROR
# ============================================================

cmake_minimum_required(VERSION 3.16)
project(logstat VERSION 1.0 LANGUAGES C)

set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra")

add_executable(logstat
    src/main.c
    src/logstat.c
    src/fileio.c
)

target_include_directories(logstat PRIVATE include)

# 可选：make install 时装到系统 bin 目录
install(TARGETS logstat RUNTIME DESTINATION bin)
