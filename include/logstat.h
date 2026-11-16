#ifndef LOGSTAT_H
#define LOGSTAT_H

#define MAX_LINES 512

/* 一个日志文件读进来的所有行 */
typedef struct {
    char *lines[MAX_LINES];
    int   count;
} LogFile;

/* 统计结果 */
typedef struct {
    int    total;      /* 总行数 */
    int    matched;    /* 含关键字的行数 */
    int    max_len;    /* 最长行长度 */
    int    min_len;    /* 最短行长度 */
    double avg_len;    /* 平均行长度 */
} Stats;

int  log_read(const char *path, LogFile *logf);
void log_free(LogFile *logf);
void log_stats(const LogFile *logf, const char *keyword, Stats *st);
void stats_print(const Stats *st, const char *keyword);

#endif /* LOGSTAT_H */
