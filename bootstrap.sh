#!/usr/bin/env bash

sudo apt-get update
sudo apt-get install -y qemu nasm rake
sudo update-alternatives --install /usr/bin/qemu qemu /usr/bin/qemu-system-i386 10

