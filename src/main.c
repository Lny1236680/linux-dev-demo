#include "logstat.h"

#include <stdio.h>
#include <string.h>

static void usage(const char *prog)
{
    fprintf(stderr, "用法: %s <日志文件> [关键字]\n", prog);
    fprintf(stderr, "示例: %s tests/sample.log ERROR\n", prog);
}

int main(int argc, char *argv[])
{
    LogFile logf;
    Stats   st;
    const char *keyword;
    int ret;

    if (argc < 2) {
        usage(argv[0]);
        return 1;
    }

    keyword = (argc >= 3) ? argv[2] : "ERROR";

    memset(&logf, 0, sizeof(logf));
    memset(&st, 0, sizeof(st));

    ret = log_read(argv[1], &logf);
    if (ret < 0) {
        fprintf(stderr, "读取 %s 失败\n", argv[1]);
        return 1;
    }

    if (ret == 0) {
        fprintf(stderr, "%s 是空文件\n", argv[1]);
        return 1;
    }

    log_stats(&logf, keyword, &st);
    stats_print(&st, keyword);

    log_free(&logf);
    return 0;
}
