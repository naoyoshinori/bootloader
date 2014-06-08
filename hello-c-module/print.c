#include"code16gcc.h"

#define TEXT_COLOR_WHITE 0x07

void print(const char *s)
{
  while(*s) {
    // BIOSの機能を呼び出して、画面に一文字出力する
    __asm__ __volatile__ ("int 0x10" : : "a"(0x0E00 | *s), "b"(TEXT_COLOR_WHITE));
    s++;
  }
}

