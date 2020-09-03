#!/bin/sh

mv zig-cache/bin/zoltan .

qemu-system-i386 -kernel zoltan
