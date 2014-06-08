#include"code16gcc.h"

__asm__("jmp main");

#define __NOINLINE __attribute__((noinline))
#define __REGPARM  __attribute__((regparm(3)))
#define __NORETURN __attribute__((noreturn))

#define TEXT_COLOR_WHITE 0x07

void __NOINLINE __REGPARM print(const char *s)
{
  while(*s) {
    __asm__ __volatile__ ("int 0x10" : : "a"(0x0E00 | *s), "b"(TEXT_COLOR_WHITE));
    s++;
  }
}

void __NORETURN main(void) {
  print("Hello, World!");

  while(1) {
    __asm__ __volatile__("hlt");
  }
}

