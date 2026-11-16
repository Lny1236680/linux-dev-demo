#include "logstat.h"

#include <stdio.h>
#include <string.h>

/*
 * 遍历所有行，统计总数、关键字命中数、行长信息。
 */
void log_stats(const LogFile *logf, const char *keyword, Stats *st)
{
    int i;
    int total_len = 0;

    st->total   = logf->count;
    st->matched = 0;
    st->max_len = 0;
    st->min_len = 0;

    for (i = 0; i < logf->count; i++) {
        int len = (int)strlen(logf->lines[i]);

        if (strstr(logf->lines[i], keyword) != NULL)
            st->matched++;

        if (len > st->max_len)
            st->max_len = len;

        if (i == 0 || len < st->min_len)
            st->min_len = len;

        total_len += len;
    }

    st->avg_len = (logf->count > 0)
                ? (double)total_len / logf->count
                : 0.0;
}

void stats_print(const Stats *st, const char *keyword)
{
    double pct = 0.0;

    if (st->total > 0)
        pct = 100.0 * st->matched / st->total;

    printf("========== 日志统计 ==========\n");
    printf("总行数    : %d\n", st->total);
    printf("关键字    : %s\n", keyword);
    printf("匹配行数  : %d (%.1f%%)\n", st->matched, pct);
    printf("最长行长  : %d\n", st->max_len);
    printf("最短行长  : %d\n", st->min_len);
    printf("平均行长  : %.2f\n", st->avg_len);
    printf("==============================\n");
}
