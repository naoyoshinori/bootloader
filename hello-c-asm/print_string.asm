; print_string.asm
[BITS 16]           ; リアルモード

global print_string ; 他のモジュールからシンボル(print_string)を利用できるようにする

print_char:
mov   ah, 0x0E      ; BIOSに一文字表示を伝える
mov   bh, 0x00
mov   bl, 0x07      ; 文字色（白）

int   0x10          ; BIOSの機能を呼び出す。Call video interrupt.
ret

print_string:
mov   edx, [esp+4]  ; 呼び出し元の次のアドレスがスタックされるので、現在のスタック領域に+4した先に引数のデータを指すアドレスがある
                    ; call function = push eip; jmp function
next:
mov   al, [edx]     ; 文字列から一文字を取得し AL レジスタに設定する
inc   edx           ; EDX レジスタをインクリメントする
or    al, al
jz    exit
call  print_char
jmp   next
exit:
ret                 ; ret = pop eip

