; hello.asm
[BITS 16]           ; リアルモード
[ORG 0x7C00]        ; 開始位置

start:
mov   si, msg       ; msg の先頭位置を SI レジスタに設定する。
call  print_string

fin:
hlt
jmp   fin

print_char:
mov   ah, 0x0E      ; BIOSに一文字表示を伝える
mov   bh, 0x00
mov   bl, 0x07      ; 文字色（白）

int   0x10          ; BIOSの機能を呼び出す。Call video interrupt.
ret

print_string:
next:
mov   al, [si]      ; 文字列から一文字を取得し AL レジスタに設定する
inc   si            ; SI レジスタをインクリメントする
or    al, al
jz    exit
call  print_char
jmp   next
exit:
ret

msg   db 'Hello World!', 0

times 510 - ($ - $$) db 0 ; ブートシグニチャまで0埋めする
dw 0xaa55                 ; ブートシグニチャ

