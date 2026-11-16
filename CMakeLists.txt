# ============================================================
#  logstat CMake 工程
#  用法:
#    cmake -B build-static -DBUILD_SHARED_LIBS=OFF   # 静态库
#    cmake -B build-shared -DBUILD_SHARED_LIBS=ON    # 动态库
#    cmake --build build-static -j
#    ./build-static/logstat tests/sample.log ERROR
# ============================================================

cmake_minimum_required(VERSION 3.16)
project(logstat VERSION 1.0 LANGUAGES C)

set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
add_compile_options(-Wall -Wextra)

# 核心逻辑（不含 main）打成库：
#   BUILD_SHARED_LIBS=OFF（默认）→ liblogstat_core.a
#   BUILD_SHARED_LIBS=ON          → liblogstat_core.so（自动加 -fPIC）
add_library(logstat_core
    src/logstat.c
    src/fileio.c
)
target_include_directories(logstat_core PUBLIC include)

# 可执行文件只含 main.c，链接上面的库
add_executable(logstat src/main.c)
target_link_libraries(logstat PRIVATE logstat_core)

# 可选：make install 时装到系统 bin 目录
install(TARGETS logstat RUNTIME DESTINATION bin)
