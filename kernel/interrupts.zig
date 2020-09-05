const Gdt = @import("global_descriptor_table.zig").GlobalDescriptorTable;
const Port = @import("port.zig").X86Port;
// temporary.
const Video = @import("video_buffer.zig");

// ////////////////////////////////////////////////////////////////////
// TYPES

/// type of interrupt id.
pub const int_t = u8;
/// type of the extended stack pointer.
pub const esp_t = u32;

// gate type, privilege, and exists flags.
const gate_type_t = u5;
const gate_priv_t = u2;
const gate_exists_t = u1;

/// handles interrupts.  is passed the byte corresponding
/// to the interrupt id and stack pointer.
export fn handle_interrupt(int: int_t, esp: esp_t) esp_t {
    Video.print("INTERRUPT");
    return esp;
}

// /////////////////////////////////////////////////////////////////////
// Gate Descriptor functions

// these are bindings that happen externally, and we need to be able
// to address these to populate the IDT.
extern fn ignore_irq() void;
extern fn handle_irq0x00() void;
extern fn handle_irq0x01() void;

const gate_func_t = *const fn() callconv(.C) void;

// /////////////////////////////////////////////////////////////////////
// Gate DESCRIPTOR structure and array

const GateDescriptor = packed struct {
    addr_lo:   u16,       // address, low bytes
    gdt_css:   Gdt.off_t, // code segment selector
    _reserved: u8 = 0,
    gate_type: gate_type_t,
    gate_priv: gate_type_t,
    exists:    gate_exists_t,
    addr_hi:   u16,       // address, high bytes
};

export var gates: [256]GateDescriptor = undefined;

const IDT_INTERRUPT_GATE = 0xE;
const IRQ_BASE = 0x20;

// programmable interrupt controller ports.
const PIC_PRIMARY_CMD = 0x20;
const PIC_PRIMARY_DATA = 0x21;
const PIC_SECONDARY_CMD = 0xA0;
const PIC_SECONDARY_DATA = 0xA1;

const PIC_CMD_SET_OFFSET = 0x11;

const PIC_PRIMARY_INT_OFFSET = 0x20;
const PIC_SECONDARY_INT_OFFSET = 0x28;
const PIC_SET_PRIMARY = 0x04;
const PIC_SET_SECONDARY = 0x02;
// /////////////////////////////////////////////////////////////////////
// IDT structure

pub const InterruptDescriptorTable = packed struct {
  size: u16,
  addr: u32,

  pub fn init(gdt: *const Gdt) void {
    var cs_offset = gdt.cs_offset();
    var idx: int_t = 0;

    // set up all gates with preliminary trapping functions.
    while (idx < 255) {
        init_gate(idx, cs_offset, &ignore_irq, 0, IDT_INTERRUPT_GATE);
        idx = idx + 1;
    }
    // manually set 255
    init_gate(255, cs_offset, &ignore_irq, 0, IDT_INTERRUPT_GATE);

    init_gate(0x00 + IRQ_BASE, cs_offset, &handle_irq0x00, 0, IDT_INTERRUPT_GATE);
    init_gate(0x01 + IRQ_BASE, cs_offset, &handle_irq0x01, 0, IDT_INTERRUPT_GATE);

    // program the PICs.
    Port.write_slow(u8, PIC_PRIMARY_CMD, PIC_CMD_SET_OFFSET);
    Port.write_slow(u8, PIC_PRIMARY_DATA, PIC_PRIMARY_INT_OFFSET);
    Port.write_slow(u8, PIC_SECONDARY_CMD, PIC_CMD_SET_OFFSET);
    Port.write_slow(u8, PIC_SECONDARY_DATA, PIC_SECONDARY_INT_OFFSET);

    Port.write_slow(u8, PIC_PRIMARY_DATA, PIC_SET_PRIMARY);
    Port.write_slow(u8, PIC_SECONDARY_DATA, PIC_SET_SECONDARY);

    // flush commands
    Port.write_slow(u8, PIC_PRIMARY_DATA, 0x01);
    Port.write_slow(u8, PIC_SECONDARY_DATA, 0x01);
    Port.write_slow(u8, PIC_PRIMARY_DATA, 0x00);
    Port.write_slow(u8, PIC_SECONDARY_DATA, 0x00);

    var idt = InterruptDescriptorTable{
      .size = 256 * @sizeOf(GateDescriptor) - 1,
      .addr = @intCast(u32, @ptrToInt(&gates[0])),
    };

    load_idt(&idt);
  }

  pub fn activate() void {
      // TODO: understand why setting sti fails?
      asm volatile("sti");
  }

  fn init_gate(
      entry: int_t,
      cs_offset: Gdt.off_t,
      gate_func: gate_func_t,
      gate_priv: gate_priv_t,
      gate_type: gate_type_t) void {

    var gate_addr = @intCast(u32, @ptrToInt(gate_func));
    gates[entry].addr_lo   = @intCast(u16, gate_addr & 0x0000_FFFF);
    gates[entry].addr_hi   = @intCast(u16, gate_addr >> 16);
    gates[entry].gdt_css   = cs_offset;
    gates[entry].gate_type = gate_type;
    gates[entry].gate_priv = gate_priv;
    gates[entry].exists    = 1;
  }

  fn load_idt(idt_ptr: *const InterruptDescriptorTable) void {
      asm volatile("lidt (%%eax)"
        :
        : [idt_ptr] "{eax}" (idt_ptr));
  }
};
