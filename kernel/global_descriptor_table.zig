const Segment = @import("segment_descriptor.zig").SegmentDescriptor;

const MiB = 1024 * 1024;

pub const GlobalDescriptorTable = struct {
    null_segment: Segment = Segment.new(0, 0, 0),
    unused_segment: Segment = Segment.new(0, 0, 0),
    code_segment: Segment = Segment.new(0, 64 * MiB, Segment.CS_TYPE),
    data_segment: Segment = Segment.new(0, 64 * MiB, Segment.DS_TYPE),

    pub const off_t = u16;

    /// initializes the GDT for the operating system.
    pub fn init(self: *const GlobalDescriptorTable) void {
        asm volatile("lgdt (%%eax)"
          : [gdt_ptr] "={eax}" (self)
        );
    }

    /// returns the data segment offset
    pub fn ds_offset(self: *const GlobalDescriptorTable) off_t {
      var delta = @ptrToInt(&self.data_segment) - @ptrToInt(self);
      return @intCast(off_t, delta);
    }
    /// returns the code segment offset
    pub fn cs_offset(self: *const GlobalDescriptorTable) off_t {
      var delta = @ptrToInt(&self.code_segment) - @ptrToInt(self);
      return @intCast(off_t, delta);
    }
};

// TODO: figure out how to test the GDT; and make sure that we have
// some sort of common interface that is portable between architectures
