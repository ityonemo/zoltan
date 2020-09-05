// TODO: make this general
const port_t = u16;

const OUT8X86  = "outb %[data], %[port]";
const OUT16X86 = "outw %[data], %[port]";
const OUT32X86 = "outl %[data], %[port]";

const OUTS8X86  = "outb %[data], %[port]\njmp 1f\n1: jmp 1f\n 1:";
const OUTS16X86 = "outw %[data], %[port]\njmp 1f\n1: jmp 1f\n 1:";
const OUTS32X86 = "outl %[data], %[port]\njmp 1f\n1: jmp 1f\n 1:";

const IN8X86  = "inb %[data], %[port]";
const IN16X86 = "inw %[data], %[port]";
const IN32X86 = "inl %[data], %[port]";

pub const X86Port = struct {
  pub fn write(comptime T: type, port: port_t, data: T) void {
      const out_cmd = switch (T) {
          u8 => OUT8X86,
          u16 => OUT16X86,
          u32 => OUT32X86,
          else => unreachable
      };
      asm volatile(out_cmd
        :
        : [port] "{dx}" (port),
          [data] "{al}" (data));
  }

  // same as slow, but append extra unimportant ops afterwards to slow it
  // down.
  pub fn write_slow(comptime T: type, port: port_t, data: T) void {
      const out_cmd = switch (T) {
          u8 => OUTS8X86,
          u16 => OUTS16X86,
          u32 => OUTS32X86,
          else => unreachable
      };
      asm volatile(out_cmd
        :
        : [port] "{dx}" (port),
          [data] "{al}" (data));
  }

  pub fn read(comptime T: type, port: port_t) T {
      const in_cmd = switch (T) {
          u8 => IN8X86,
          u16 => IN16X86,
          u32 => IN32X86,
          else => unreachable
      };
      return asm volatile (in_cmd
        : [result] "={al}" (-> u8),
        : [port] "N{dx}" (port));
  }
};
