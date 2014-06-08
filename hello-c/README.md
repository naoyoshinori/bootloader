# ブートストラップローダ領域でHello, World!

## はじめに

[前回][1]の「アセンブリ言語でHello, World!」をC言語に置き換えました。サンプルプログラムは[こちら](https://github.com/yoshi-naoyuki/bootloader)です。

開発環境は[前回][1]と同じ環境です。

## ブートストラップローダ領域

PCの電源を投入するとBIOSと呼ばれるソフトウェアが起動します。このBIOSはデバイスの初期化などが終わると、ブートデバイス（FDDやHDDなど）のMBR（Master Boot Record）をメモリ上にロードし、MBR領域にあるプログラムに制御を移します。このMBR領域にあるプログラムをブートストラップローダと呼びます。

![ブートローダー.png](https://qiita-image-store.s3.amazonaws.com/0/33079/9afe755a-7c20-1c1d-8e6d-86494308380d.png "ブートローダー.png")

## プログラムの作成

`code16gcc.h` はGCCにプログラムが16BITモードであることを伝えます。

code16gcc.h

```c
#ifndef _CODE16GCC_H_
#define _CODE16GCC_H_
__asm__(".code16gcc\n");
#endif
```

インラインアセンブラを使用して、[前回][1]と同じように「Hello, World!」を出力するプログラムを作成します。

hello.c

```c
#include"code16gcc.h"

__asm__("jmp main");

#define TEXT_COLOR_WHITE 0x07

void print(const char *s)
{
  while(*s) {
    // BIOSの機能を呼び出して、画面に一文字出力する
    __asm__ __volatile__ ("int 0x10" : : "a"(0x0E00 | *s), "b"(TEXT_COLOR_WHITE));
    s++;
  }
}

void main(void) {
  print("Hello, World!");

  while(1) {
    // CPUの動作を停止する
    __asm__ __volatile__("hlt");
  }
}
```

BIOSはメモリ上の0x7C00番地にMBRをロードします。よってプログラムの開始位置は0x7C00番地となります。ブートシグニチャ（0xAA55）はMBRが有効であるという署名のようなもので、ブートシグニチャがないとMBRが無効なものとして扱われます。ブートシグニチャはMBRの510〜511バイトにあります。ブートシグニチャのメモリ上のアドレスは0x7DFE番地（0x7C00 + 510バイト = 0x7DFE）です。

linker.ld

```ld
ENTRY(main);
SECTIONS
{
  /* プログラムの開始位置 */
  . = 0x7C00;
  .data : { hello.o; }
  /* ブートシグニチャ */
  . = 0x7DFE;
  .sig : { SHORT(0xaa55); }
}
```

## バイナリファイルの作成

標準ライブラリのリンク情報（デバック情報など）を取り除いた、オブジェクトファイル(hello.o)を作成します。

```bash
# コンパイル
gcc -m32 -ffreestanding -fno-common -fno-builtin -fomit-frame-pointer -O2 -c -o hello.o hello.c
```

リンカーを使用してオブジェクトファイル(hello.o)からバイナリファイル(hello.bin)を作成します。

```bash
# バイナリファイルの作成
ld -m elf_i386 -s -static -Tlinker.ld -nostdlib -nmagic --oformat binary -o hello.bin hello.o
```

[前回][1]と同じようにフロッピーディスクイメージにバイナリファイルを書き込みます。QEMUを実行して「Hello, World!」と出力されたら成功です。

![kobito.1402210360.448893.png](https://qiita-image-store.s3.amazonaws.com/0/33079/fe27c307-11e7-1e64-24ab-be4916bad9a0.png "kobito.1402210360.448893.png")

## サンプルプログラムの実行

```bash
# Vagrantの起動と接続
host$ vagrant up
host$ vagrant ssh

# サンプルプログラムの実行
vagrant$ cd /vagrant/hello-c
vagrant$ rake
```

Rakefile

```ruby
OBJECT_FILE = 'hello.o'
BINARY_FILE = 'hello.bin'
IMAGE_FILE  = 'floppy.img'
LINKER_FILE = 'linker.ld'

task :default => :run

task :run => [ BINARY_FILE, IMAGE_FILE ] do
  sh "dd status=noxfer conv=notrunc if=#{BINARY_FILE} of=#{IMAGE_FILE}"
  sh "qemu -boot a -fda #{IMAGE_FILE} -curses -monitor stdio"
end

file BINARY_FILE => [ LINKER_FILE,  OBJECT_FILE ] do
  sh "ld -m elf_i386 -s -static -T#{LINKER_FILE} -nostdlib -nmagic --oformat binary -o #{BINARY_FILE} #{OBJECT_FILE}"
end

file IMAGE_FILE do
  sh "qemu-img create -f raw #{IMAGE_FILE} 1440K"
end

rule '.o' => '.c' do |t|
  sh "gcc -masm=intel -m32 -ffreestanding -fno-common -fno-builtin -fomit-frame-pointer -O2 -c -o #{t.name} #{t.source}"
end

rule '.s' => '.c' do |t|
  sh "gcc -S -masm=intel -m32 -ffreestanding -fno-common -fno-builtin -fomit-frame-pointer -O2 -c -o #{t.name} #{t.source}"
end

require 'rake/clean'
CLEAN.include([ '*.bin', '*.img', '*.o' ])
```

## おまけ

C言語をアセンブリ言語に変換して、[前回][1]のプログラムと比較してみましょう。
次のコマンドを実行すると `hello.c` から `hello.s` が作成されます。

```bash
cd /vagrant/hello-c-optimization
rake hello.s
```

次のプログラムは読み易くするために、不要なディレクティブ(.xxxx)を取り除いています。
NASMとGCCの出力するアセンブリ言語では若干構文が異なります。

/vagrant/hello-c-optimization/hello.s

```nasm
    .file   "hello.c"
    .intel_syntax noprefix
    .code16gcc

    jmp main
print:
    push    ebx
    mov edx, eax                 // EDX レジスタに文字列の先頭アドレスを設定する
    movzx   eax, BYTE PTR [eax]  // 文字列から一文字を取得し EAX レジスタに設定する
    test    al, al
    je  .L1
    mov ebx, 7                   // 文字色（白）(0x07)
.L4:
    movsx   eax, al
    or  ah, 14                   // BIOSに一文字表示を伝える(0x0E)
    int 0x10                     // BIOSの機能を呼び出す。Call video interrupt.
    add edx, 1                   // EDX レジスタをインクリメントする
    movzx   eax, BYTE PTR [edx]  // 文字列から一文字を取得し EAX レジスタに設定する
    test    al, al
    jne .L4
.L1:
    pop ebx
    ret
.LC0:
    .string "Hello, World!"
main:
    mov eax, OFFSET FLAT:.LC0    // EAX レジスタに文字列の先頭アドレスを設定する
    call    print
.L8:
    hlt
    jmp .L8
```

[1]: http://qiita.com/yoshi-naoyuki/items/fb958e3c914c56baef40
