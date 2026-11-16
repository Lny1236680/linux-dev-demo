/* getline / strdup 是 POSIX 函数，-std=c17 严格模式下默认不声明。
 * 必须在所有 include 之前定义这个宏，否则编译器按"隐式返回 int"处理，
 * 指针被截断成 32 位 —— 运行到 strdup 返回处直接段错误。 */
#define _POSIX_C_SOURCE 200809L

#include "logstat.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*
 * 读取日志文件，每行保存到 logf->lines[]。
 * 返回实际读到的行数，出错返回 -1。
 */
int log_read(const char *path, LogFile *logf)
{
    FILE *fp;
    char *line = NULL;
    size_t cap = 0;
    int n = 0;

    fp = fopen(path, "r");
    if (fp == NULL) {
        perror(path);          /* 输出 "路径: 错误原因" */
        return -1;
    }

    logf->count = 0;

    while (getline(&line, &cap, fp) != -1) {
        if (n >= MAX_LINES) {
            fprintf(stderr, "警告: 文件超过 %d 行，其余忽略\n", MAX_LINES);
            break;
        }

        /* 去掉行尾的换行符 */
        line[strcspn(line, "\n")] = '\0';

        logf->lines[n] = strdup(line);
        if (logf->lines[n] == NULL) {
            fprintf(stderr, "错误: 内存不足\n");
            free(line);
            fclose(fp);
            logf->count = n;
            return -1;
        }
        n++;
    }

    free(line);
    fclose(fp);

    logf->count = n;
    return n;
}

void log_free(LogFile *logf)
{
    int i;

    for (i = 0; i < logf->count; i++) {
        free(logf->lines[i]);
        logf->lines[i] = NULL;
    }
    logf->count = 0;
}
