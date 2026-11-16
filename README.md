# logstat —— Linux 开发环境入门练习

一个多文件的 C 小项目，用来把 **GCC 编译 / Makefile / CMake / gdb 调试 / Shell 自动化** 这条链走一遍。

## 功能

读取日志文件，统计总行数、关键字命中行数、最长/最短/平均行长。

```bash
./build/logstat tests/sample.log ERROR
```

## 目录结构

```
linux-dev-demo/
├── include/logstat.h      # 公共头文件
├── src/
│   ├── main.c             # 程序入口、参数解析
│   ├── logstat.c          # 核心统计逻辑
│   └── fileio.c           # 文件读取（getline/strdup）
├── tests/sample.log       # 测试数据
├── tools/
│   ├── build.sh           # 一键构建脚本
│   └── run_tests.sh       # 自动测试脚本
├── Makefile
├── CMakeLists.txt
└── README.md
```

## 一、直接用 gcc（理解编译过程）

```bash
# 分步：编译 -> 目标文件
gcc -Wall -Wextra -g -O2 -std=c17 -Iinclude -c src/main.c -o src/main.o

# 链接：目标文件 -> 可执行文件
gcc -o build/logstat src/main.o src/logstat.o src/fileio.o

# 一步到位
gcc -Wall -Wextra -g -O2 -std=c17 -Iinclude -o build/logstat src/*.c
```

参数含义：

| 参数 | 作用 |
|---|---|
| `-Wall -Wextra` | 打开警告，必须开，能挡住一半低级错误 |
| `-g` | 生成调试信息（gdb 需要） |
| `-O2` | 优化等级 |
| `-Iinclude` | 头文件搜索路径 |
| `-c` | 只编译不链接，产出 `.o` |
| `-o` | 指定输出文件名 |

## 二、Makefile（增量编译）

```bash
make          # 只编译改动过的文件
make debug    # 生成 -O0 -g 调试版，给 gdb 用
make clean    # 清理
```

学了什么：

- 目标 / 依赖 / 命令三要素
- `$(wildcard)`、`$(SRC:.c=.o)` 变量替换
- `| build` order-only 依赖（目录不存在才创建）
- `.PHONY` 声明伪目标

## 三、CMake（跨平台构建）

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j4
```

学了什么：

- 源文件显式列出 vs Makefile 通配符
- `CMAKE_C_STANDARD`、`target_include_directories`
- 构建目录与源码目录分离（out-of-source build）
- `Release` / `Debug` 构建类型

## 四、gdb 调试

```bash
make debug                       # -O0 -g 才有完整调试信息
gdb ./build/logstat
```

常用命令：

| 命令 | 作用 |
|---|---|
| `run tests/sample.log ERROR` | 带参数运行 |
| `break log_stats` | 在函数入口下断点 |
| `break logstat.c:42` | 按文件行号下断点 |
| `next` / `step` | 单步（不进入/进入函数） |
| `print st->matched` | 打印变量 |
| `display st->total` | 每次停下都自动打印 |
| `backtrace` / `bt` | 查看调用栈 |
| `watch st->matched` | 变量变化时自动停下 |
| `info locals` | 看所有局部变量 |
| `continue` | 继续运行 |
| `quit` | 退出 |

## 五、Shell 自动化

```bash
./tools/build.sh          # 查看用法
./tools/build.sh run      # 构建并运行
./tools/build.sh clean    # 清理
./tools/run_tests.sh      # 自动测试（用 grep/awk 独立算期望值再比对）
```

脚本里用到的关键点：

- `set -euo pipefail`：出错即停、未定义变量报错、管道失败可见
- `trap ... EXIT`：退出时清理临时文件
- `"$ROOT"` 路径推导：脚本不依赖当前目录
- `case` 子命令分发
- `awk -F: '$1 ~ n'` 从输出里提取字段做断言

定时执行（了解即可）：

```bash
crontab -e
# 每分钟跑一次测试，输出追加到日志
* * * * * /home/yang/linux-dev-demo/tools/run_tests.sh >> /tmp/logstat-test.log 2>&1
```

## 六、踩坑记录

### 1. `strdup` 隐式声明导致段错误

`-std=c17` 是严格 ISO 模式，`getline`/`strdup` 属于 POSIX 接口，默认不声明。编译器会按
"隐式返回 int"处理，指针被截断为 32 位，运行到 `strdup` 返回值处直接段错误。

修复：在**所有 include 之前**加

```c
#define _POSIX_C_SOURCE 200809L
```

或者改用 `-std=gnu17`。

**教训**：编译警告里的 `implicit declaration of function` 和
`makes pointer from integer without a cast` 都是真错误，不能无视。

### 2. 优化会改变调试体验

`-O2` 下变量可能被寄存器优化掉，`print` 显示 `<optimized out>`。
调 bug 一律先 `make debug`（`-O0 -g`），定位完再用 `-O2` 验证。

## 七、验收清单（面试前自查）

- [ ] 能说清 `.c → .o → 可执行文件` 每一步在干什么
- [ ] 能解释 `-Wall -Wextra -g -O2 -I` 每个参数
- [ ] 能写出一个带变量、通配符、`.PHONY` 的 Makefile
- [ ] 能用 gdb 跑程序、下断点、单步、打印变量、看调用栈
- [ ] 能解释 `make` 为什么第二次几乎不编译
- [ ] 能写带 `set -euo pipefail`、`trap`、函数、`case` 的脚本
- [ ] 能说出静态库（`.a`）和动态库（`.so`）的区别

## 八、练习手册

gdb 单步观察、段错误定位、valgrind 内存检查的逐步练习（含预期输出）见
[练习手册.md](练习手册.md)。
