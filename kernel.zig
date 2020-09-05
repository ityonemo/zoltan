const Video = @import("kernel/video_buffer.zig");
const Gdt = @import("kernel/global_descriptor_table.zig").GlobalDescriptorTable;
const Idt = @import("kernel/interrupts.zig").InterruptDescriptorTable;
const Interrupts = @import("kernel/interrupts.zig");

const int_t = Interrupts.int_t;

export fn kernel_main(multiboot : *c_void, magicnumber : u32) void {
  // create a global descriptor table value and initialize it.
  // NOTE: by putting this as `const`, its memory space is declared
  // in the binary, if we put it as `var`, it causes problems likely due
  // to limited stack space.
  const gdt = Gdt{};
  gdt.init();

  Idt.init(&gdt);
  Idt.activate();

  Video.print("Hello Zoltan-foo");

  while (true) {}
}
