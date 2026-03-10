#pragma once
#include <windows.h>
#include <cstdio>

static void Log(const char* fmt, ...) {
    FILE* f;
    if (fopen_s(&f, "Transmorpher.log", "a") == 0) {
        SYSTEMTIME st;
        GetLocalTime(&st);
        fprintf(f, "[%02d:%02d:%02d.%03d] ", st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);
        va_list args;
        va_start(args, fmt);
        vfprintf(f, fmt, args);
        va_end(args);
        fprintf(f, "\n");
        fclose(f);
    }
}
