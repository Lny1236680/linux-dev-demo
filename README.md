# logstat —— Linux 开发环境入门练习

[![CI](https://github.com/Lny1236680/linux-dev-demo/actions/workflows/ci.yml/badge.svg)](https://github.com/Lny1236680/linux-dev-demo/actions/workflows/ci.yml)

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

## 九、调试记录

### 9.1 段错误：循环条件写成 `<=`

**现象**

`logstat.c:19` 的 `for (i = 0; i < logf->count; i++)` 误写成 `<=` 后，
编译零警告，运行直接崩溃：

```console
$ ./build/logstat tests/sample.log ERROR
Segmentation fault (core dumped)
$ echo $?
139
```

`139 = 128 + 11`，11 是 `SIGSEGV`（段错误信号）。

**定位**

用调试版重新编译，让 gdb 接住崩溃现场：

```console
$ make debug
$ gdb ./build/logstat
(gdb) run tests/sample.log ERROR

Program received signal SIGSEGV, Segmentation fault.
__strlen_avx2 () at ../sysdeps/x86_64/multiarch/strlen-avx2.S:76
```

崩溃点是 C 库的 `strlen`，不是本工程代码。用 `bt` 往上找自己的帧：

```console
(gdb) backtrace
#0  __strlen_avx2 () at ../sysdeps/.../strlen-avx2.S:76
#1  0x... in log_stats (logf=0x7fffffffc980, keyword=0x7fffffffde58 "ERROR",
                        st=0x7fffffffc960) at src/logstat.c:20
#2  0x... in main (argc=3, argv=0x7fffffffdab8) at src/main.c:40
```

`#1` 是本工程代码：`logstat.c:20` 的 `strlen(logf->lines[i])`。
切到这一帧，打印变量：

```console
(gdb) frame 1
20	        int len = (int)strlen(logf->lines[i]);
(gdb) info locals
len = 40
i = 10
total_len = 446
(gdb) print logf->count
$1 = 10
(gdb) print logf->lines[i]
$2 = 0x0
(gdb) print i < logf->count
$3 = 0
```

**根因**

`i == 10`、`count == 10`，`lines[10]` 越界。`main()` 里先
`memset(&logf, 0, sizeof(logf))` 把整个结构体清零，随后只填了 10 行
（下标 0~9），第 11 个槽位从未被写过，因此是 `NULL`。
`strlen(NULL)` 解引用空指针，必然段错误。

**修复**

```diff
-    for (i = 0; i <= logf->count; i++) {
+    for (i = 0; i < logf->count; i++) {
```

```console
$ make debug && ./tools/run_tests.sh
结果: 2 通过, 0 失败
```

### 9.2 内存泄漏：漏掉 `log_free`

**现象**

注释掉 `main.c` 里的 `log_free(&logf);` 后，程序输出看起来完全正常，
但每次运行都会泄漏全部按行分配的内存。

**定位**

```console
$ valgrind --leak-check=full --show-leak-kinds=all \
           ./build/logstat tests/sample.log ERROR
==1940== HEAP SUMMARY:
==1940==     in use at exit: 456 bytes in 10 blocks
==1940==   total heap usage: 14 allocs, 4 frees, 9,240 bytes allocated
==1940==
==1940== 456 bytes in 10 blocks are definitely lost in loss record 1 of 1
==1940==    at 0x4846828: malloc (...)
==1940==    by 0x491443E: strdup (strdup.c:42)
==1940==    by 0x1093EA: log_read (fileio.c:40)
==1940==    by 0x1098B7: main (main.c:29)
```

**读法**

- `14 allocs, 4 frees`：分配 14 次只释放 4 次
- `definitely lost`：指针已丢失，确定无法回收
- 调用栈从下往上是 `main → log_read → strdup → malloc`，即
  `fileio.c:40` 每行 `strdup` 的内存没人释放
- `10 blocks` 正好对应日志的 10 行，`456 bytes` 是 10 行字符串总长

**修复与验证**

恢复 `log_free(&logf);` 后：

```console
$ valgrind --leak-check=full ./build/logstat tests/sample.log ERROR
==1918==     in use at exit: 0 bytes in 0 blocks
==1918==   total heap usage: 14 allocs, 14 frees, 9,240 bytes allocated
==1918== All heap blocks were freed -- no leaks are possible
==1918== ERROR SUMMARY: 0 errors from 0 contexts
```

**泄漏分类**

| 分类 | 含义 | 严重程度 |
|---|---|---|
| `definitely lost` | 指针丢失，确定回收不了 | 最严重 |
| `indirectly lost` | 父对象泄漏导致子对象也泄漏 | 严重 |
| `possibly lost` | 指针指向内存中间，可能泄漏 | 需确认 |
| `still reachable` | 退出时仍能找到指针，通常无害 | 一般可忽略 |

### 9.3 调试方法总结

**崩溃定位四步**：

1. `bt` —— 看调用栈，找到第一个属于自己的帧
2. `frame N` —— 切到那一帧
3. `info locals` —— 一次看全部局部变量
4. `print 表达式` —— 验证猜想（可打印比较运算的结果）

**错误分层**：先判断问题出在哪一层，再决定用什么工具。

| 输出 | 来源 | 性质 | 退出码 |
|---|---|---|---|
| `读取 xxx 失败` | 程序自身逻辑 | 应用层错误 | 1 |
| `Segmentation fault` | 操作系统信号 | 崩溃，用 gdb | 139 |

**`$?` 的陷阱**：`echo $?` 打印的是上一条命令的退出码，而 `echo`
自身永远返回 0。连续执行 `echo $?` 时，第二次开始看到的都是 0。
要保存真实退出码，应先赋值：

```bash
./build/logstat tests/sample.log ERROR
rc=$?
echo "退出码=$rc"
```
