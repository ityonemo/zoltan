/// Segment Descriptor Spec
pub const segsize_t = u32;
pub const segaddr_t = u32;
pub const segflag_t = u8;
pub const segtype_t = u4;

/// Segment Descriptor and their structures.
pub const SegmentDescriptor = packed struct {
    // const values
    pub const CS_TYPE: segflag_t = 0x9A;
    pub const DS_TYPE: segflag_t = 0x92;

    // internal constants referring to 32- and
    // 64- bit addressing types
    const ADDR16B = 0x4;
    const ADDR32B = 0xC;

    // fields
    size_lo: u16       = 0,
    addr_lo: u24       = 0,
    flags:   segflag_t = 0,
    segtype: segtype_t = ADDR16B,
    size_hi: u4        = 0,
    addr_hi: u8        = 0,

    /// generates a segment descriptor struct based off of address,
    /// size, and flags parameters.
    pub fn new(addr_: segaddr_t, size_: segsize_t, flags_: segflag_t) SegmentDescriptor {
        const addr_lo = @intCast(u24, addr_ & 0xFF_FFFF);
        const addr_hi = @intCast(u8, addr_ >> 24);
        var size_adj : segsize_t = undefined;
        var segtype : segtype_t = undefined;

        if (size_ < 0x1_0000) {
            size_adj = size_;
            segtype = ADDR16B;
        } else if ((size_ & 0xFFF) != 0xFFF) {
            size_adj = (size_ >> 12) - 1;
            segtype = ADDR32B;
        } else {
            size_adj = size_ >> 12;
            segtype = ADDR32B;
        }

        const size_lo = @intCast(u16, size_adj & 0xFFFF);
        const size_hi = @intCast(u4, size_adj >> 16);

        return SegmentDescriptor{
            .size_lo = size_lo,
            .addr_lo = addr_lo,
            .flags   = flags_,
            .segtype = segtype,
            .size_hi = size_hi,
            .addr_hi = addr_hi
        };
    }

    /// calculates the 32-bit value of the segment address, reassembling it
    /// from the awkward struct presented by the system.
    pub fn addr(self: *SegmentDescriptor) segaddr_t {
        const addr_lo_32 = @intCast(segaddr_t, self.addr_lo);
        const addr_hi_32 = @intCast(segaddr_t, self.addr_hi);
        return (addr_hi_32 << 24) | addr_lo_32;
    }

    /// calculates the 32-bit value of the segment size, reassembling it
    /// from the awkward struct presented by the system.
    pub fn size(self: *SegmentDescriptor) segsize_t {
        const size_lo_32 = @intCast(segsize_t, self.size_lo);
        const size_hi_32 = @intCast(segsize_t, self.size_hi);
        const size_all = (size_hi_32 << 16) | size_lo_32;

        return switch (self.segtype) {
            ADDR16B => size_all,
            ADDR32B => _calc_32b_segaddr(size_all),
            else => unreachable,
        };
    }

    fn _calc_32b_segaddr(size_all: segsize_t) segsize_t {
        // check the parity on this function
        if ((size_all & 0x1) != 0) {
            // if it's odd, bitshift on the incremented value
            return (size_all + 1) << 12;
        } else {
            // if it's even, do a normal bitshift and append secret Fs.
            return (size_all << 12) | 0xFFF;
        }
    }
};

// ////////////////////////////////////////////////////////////////////////
// TESTING

const assert = @import("std").debug.assert;

test "the new function places addr value as expected" {
    // address segment is split into high and low.
    var seg_1 = SegmentDescriptor.new(0x1234_5678, 0, 0);
    assert(seg_1.addr_lo == 0x34_5678);
    assert(seg_1.addr_hi == 0x12);
}

test "the new function places size value as expected" {
    // segment size is split into high and low, for < 16 bit limit
    // addressing
    var seg_2 = SegmentDescriptor.new(0, 0x02345, 0);
    assert(seg_2.size_lo == 0x2345);
    assert(seg_2.size_hi == 0x0);
    assert(seg_2.segtype == SegmentDescriptor.ADDR16B);

    // segment size is split into high and low, for > 16 bit limit
    // addressing
    var seg_3 = SegmentDescriptor.new(0, 0x10000, 0);
    assert(seg_3.size_lo == 0x000F);
    assert(seg_3.size_hi == 0x0);
    assert(seg_3.segtype == SegmentDescriptor.ADDR32B);

    // segment size is split into high and low, for > 16 bit limit
    // addressing with special tail flag
    var seg_4 = SegmentDescriptor.new(0, 0x10FFF, 0);
    assert(seg_4.size_lo == 0x0010);
    assert(seg_4.size_hi == 0x0);
    assert(seg_4.segtype == SegmentDescriptor.ADDR32B);
}

test "the addr function retrieves the address value as expected" {
    var seg_addr = SegmentDescriptor{
        .addr_lo = 0x345678,
        .addr_hi = 0x12,
    };
    assert(seg_addr.addr() == 0x12345678);
}

test "the size function retrieves the size value as expected" {
    // when the segment type is specifying that 16-bit addressing
    // is used.
    var seg_size1 = SegmentDescriptor{
        .size_lo = 0x2345,
        .size_hi = 1,
    };
    assert(seg_size1.size() == 0x12345);

    // when the segment type is specifying that 32-bit addressing
    // is used.
    var seg_size2 = SegmentDescriptor{
        .size_lo = 0x000F,
        .size_hi = 0x0,
        .segtype = SegmentDescriptor.ADDR32B,
    };
    assert(seg_size2.size() == 0x10000);

    // when the segment type is specifying that 32-bit addressing
    // is used.
    var seg_size3 = SegmentDescriptor{
        .size_lo = 0x0010,
        .size_hi = 0x0,
        .segtype = SegmentDescriptor.ADDR32B,
    };
    assert(seg_size3.size() == 0x10FFF);
}
