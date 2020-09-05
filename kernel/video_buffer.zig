const video_memory_start = 0xb8000;

// video memory works in the following way: each character in the screen is
// dropped in 2 byte segments; upper 4 bits and lower 4 bits of the first
// byte are the foreground and background colors of the character and then
// the subsequent byte is the character itself.
pub fn print(what : [] const u8) void {
  for (what) | char, idx | {
    var slot : usize = video_memory_start + idx * 2;
    var vchar_ptr = @intToPtr(*u8, slot);
    vchar_ptr.* = char;
  }
}
