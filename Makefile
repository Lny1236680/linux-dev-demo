# ============================================================
#  logstat Makefile —— 用 make 演示"增量编译"
#  用法:  make        正常构建(优化版)
#         make debug  调试版(-O0 -g，给 gdb 用)
#         make clean  清理
# ============================================================

CC      := gcc
CFLAGS  := -Wall -Wextra -g -O2 -std=c17 -Iinclude
LDFLAGS :=

SRC     := $(wildcard src/*.c)
OBJ     := $(SRC:.c=.o)
TARGET  := build/logstat

all: $(TARGET)

# 链接：把 .o 拼成可执行文件
$(TARGET): $(OBJ) | build
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

# 编译：每个 .c -> .o（头文件改了会重新编译）
%.o: %.c include/logstat.h
	$(CC) $(CFLAGS) -c $< -o $@

# 目录不存在就建出来（order-only 依赖）
build:
	mkdir -p build

# 调试版：覆盖 CFLAGS，关优化、开全部调试信息
debug: CFLAGS := -Wall -Wextra -g3 -O0 -std=c17 -Iinclude
debug: clean all

clean:
	rm -f $(OBJ)
	rm -rf build

.PHONY: all clean debug
