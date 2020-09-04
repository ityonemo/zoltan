usingnamespace @import("segment_descriptor.zig");

const CS_TYPE: segflag_t = 0x9A;
const DS_TYPE: segflag_t = 0x92;
const MiB = 1024 * 1024;

pub const GlobalDescriptorTable = struct {
    null_segment: SegmentDescriptor = SegmentDescriptor.new(0, 0, 0),
    unused_segment: SegmentDescriptor = SegmentDescriptor.new(0, 0, 0),
    code_segment: SegmentDescriptor = SegmentDescriptor.new(0, 64 * MiB, CS_TYPE),
    data_segment: SegmentDescriptor = SegmentDescriptor.new(0, 64 * MiB, DS_TYPE),

    // initializes the GDT for the operating system.
    pub fn init(self: *const GlobalDescriptorTable) void {
        asm volatile("lgdt (%%eax)"
          : [gdt_ptr] "={eax}" (self)
        );
    }
};

// TODO: figure out how to test the GDT; and make sure that we have
// some sort of common interface that is portable between architectures
