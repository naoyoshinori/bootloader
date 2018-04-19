アセンブリ言語でHello, World!

## アセンブリ言語でHello, World!

アセンブリ言語でHello World!を出力するプログラムを作成します。サンプルプログラムは[こちら](https://github.com/yoshi-naoyuki/bootloader)です。

## 開発環境

* 開発環境に[Vagrant](http://www.vagrantup.com)と[VirtualBox](https://www.virtualbox.org)をインストールしてください。

* Vagrantのbox `http://files.vagrantup.com/precise32.box` をprecise32という名前でローカルに置いてください。
このVagrantのboxを新たにローカルに置く場合は、次のコマンドを実行してください。

```bash
vagrant box add precise32 http://files.vagrantup.com/precise32.box
```

## プロジェクトの作成

プロジェクトのルートとなるディレクトリを作成して、次のファイルをサンプルプログラムからコピーしてください。

* Vagrantfile
* bootstrap.sh

## Vagrantの操作

仮想マシンを起動するには、次のコマンドを実行します。起動時に `bootstrap.sh` が実行されて、必要なパッケージがインストールされます。

```bash
vagrant up
```

仮想マシンに接続するには、次のコマンドを実行します。

```bash
vagrant ssh
```

仮想マンシを停止するには、次のコマンドを実行します。

```bash
vagrant halt
```


## 必要なパッケージのインストール

`vagrant up` で仮想マシンを起動すると、次のパッケージが自動でインストールされます。

|パッケージ|内容         |
|--------|-------------|
|qemu    |CPUエミュレータ|
|nasm    |アセンブリ言語 |
|rake    |ビルドツール   |

bootstrap.sh
```bash
#!/usr/bin/env bash

sudo apt-get update
sudo apt-get install -y qemu nasm rake
sudo update-alternatives --install /usr/bin/qemu qemu /usr/bin/qemu-system-i386 10
```

Vagrant
```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "precise32"
  config.vm.provision :shell, path: "bootstrap.sh"
end
```

## プログラムの作成

次に「Hello, World!」を出力するプログラムをアセンブリ言語で作成します。

hello.asm
```nasm
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

times 510 - ($ - $$) db 0 ; ブートシグネチャまで0埋めする
dw 0xaa55                 ; ブートシグネチャ
```

## プログラムをアセンブル

プログラムをアセンブルして、バイナリファイルを作成します。

```bash
nasm -f bin -o hello.bin hello.asm
```

* nasm -f <フォーマット> [-o <出力ファイル名>] <ファイル名>

## ディスクイメージにプログラムを書き込む

フロッピーディスクイメージを作成して、バイナリファイルを書き込みます。

```bash
# フロッピーディスクイメージの作成
qemu-img create -f raw floppy.img 1440K
# バイナリファイルの書き込み
dd conv=notrunc if=hello.bin of=floppy.img
```

* qemu-img create [-f <フォーマット>] <ファイル名> [サイズ]

* dd [conv=notrunc] [if=<入力ファイル名>] [of=<出力ファイル名>]
`conv=notrunc` 出力ファイルを切り詰めずに書き込みます。

## QEMUの実行と終了

QEMUにフロッピーディスクイメージをマウントして、プログラムを実行します。

```bash
# QEMUの起動
qemu -boot a -fda floppy.img -curses -monitor stdio
# QEMUの終了
(qemu) quit[enter]
```

* qemu [options] [ディスクイメージ]  
`-boot [a]` フロッピーディスク(Aドライブ)から起動します。  
`-fda <ファイル名>` フロッピーディスク(Aドライブ)にマウントするディスクイメージを指定します。  
`-cursess` VGA出力を cursess インターフェースを使用して、端末に出力します。  
`-monitor stdio` モニターをホストのデバイスにリダイレクトします。CUI の場合は stdio を指定します。

### QEMU実行時の注意

QEMUのオプションに`-monitor stdio`を付け忘れた場合、ターミナルから入力を受け付けなくなるので、QEMUを終了できなくなります。別のターミナルを開いてpkillコマンドなどでプロセスを終了させてください。

```bash
pkill qemu
```

![kobito.1402131317.135501.png](https://qiita-image-store.s3.amazonaws.com/0/33079/5c1896ea-6a6d-875c-a7ae-40b02ad215e3.png "kobito.1402131317.135501.png")

## サンプルプログラムの実行

```bash
# Vagrantの起動と接続
host$ vagrant up
host$ vagrant ssh

# サンプルプログラムの実行
vagrant$ cd /vagrant/hello-asm
vagrant$ rake
```

Rakefile
```ruby
SOURCE_FILE = 'hello.asm'
BINARY_FILE = 'hello.bin'
IMAGE_FILE  = 'floppy.img'

task :default => :run

task :run => [ BINARY_FILE, IMAGE_FILE ] do
  sh "dd status=noxfer conv=notrunc if=#{BINARY_FILE} of=#{IMAGE_FILE}"
  sh "qemu -boot a -fda #{IMAGE_FILE} -curses -monitor stdio"
end

file BINARY_FILE => SOURCE_FILE do
  sh "nasm -f bin -o #{BINARY_FILE} #{SOURCE_FILE}"
end

file IMAGE_FILE do
  sh "qemu-img create -f raw #{IMAGE_FILE} 1440K"
end

require 'rake/clean'
CLEAN.include([ '*.bin', '*.img' ])
```
