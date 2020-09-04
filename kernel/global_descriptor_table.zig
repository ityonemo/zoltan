const Segment = @import("segment_descriptor.zig").SegmentDescriptor;

const MiB = 1024 * 1024;

pub const GlobalDescriptorTable = struct {
    null_segment: Segment = Segment.new(0, 0, 0),
    unused_segment: Segment = Segment.new(0, 0, 0),
    code_segment: Segment = Segment.new(0, 64 * MiB, Segment.CS_TYPE),
    data_segment: Segment = Segment.new(0, 64 * MiB, Segment.DS_TYPE),

    // initializes the GDT for the operating system.
    pub fn init(self: *const GlobalDescriptorTable) void {
        asm volatile("lgdt (%%eax)"
          : [gdt_ptr] "={eax}" (self)
        );
    }
};

// TODO: figure out how to test the GDT; and make sure that we have
// some sort of common interface that is portable between architectures
