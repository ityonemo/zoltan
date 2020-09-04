const GDT = @import("kernel/global_descriptor_table.zig").GlobalDescriptorTable;

const video_memory_start = 0xb8000;

// video memory works in the following way: each character in the screen is
// dropped in 2 byte segments; upper 4 bits and lower 4 bits of the first
// byte are the foreground and background colors of the character and then
// the subsequent byte is the character itself.
fn kprint(what : [] const u8) void {
  for (what) | char, idx | {
    var slot : usize = video_memory_start + idx * 2;
    var vchar_ptr = @intToPtr(*u8, slot);
    vchar_ptr.* = char;
  }
}

export fn kernel_main(multiboot : *c_void, magicnumber : u32) void {
  // create a global descriptor table value and initialize it.
  // NOTE: by putting this as, it's memory space is declared
  // in the binary, if we put it as 'var', it causes problems likely due
  // to limited stack space.
  const gdt = GDT{};
  gdt.init();

  kprint("Hello Zoltan-gdt");

  while (true) {}
}
