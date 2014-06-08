#include"code16gcc.h"

__asm__("jmp main");

extern void print_string(const char *s);

void main(void) {
  print_string("Hello, World!");

  while(1) {
    // CPUの動作を停止する
    __asm__ __volatile__("hlt");
  }
}

