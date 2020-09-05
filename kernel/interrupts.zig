// temporary.
const Video = @import("video_buffer.zig");

/// type of interrupt id.
pub const int_t = u8;
/// type of the extended stack pointer.
pub const esp_t = u32;

/// handles interrupts.  is passed the byte corresponding
/// to the interrupt id and
export fn handle_interrupt(int: int_t, esp: esp_t) esp_t {
    Video.print("INTERRUPT");
    return esp;
}
