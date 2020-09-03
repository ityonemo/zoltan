const Builder = @import("std").build.Builder;
const CrossTarget = @import("std").zig.CrossTarget;


pub fn build(b: *Builder) void {
    const exe = b.addExecutable("zoltan", "kernel.zig");

    exe.setTarget(CrossTarget{
       .cpu_arch = .i386,
       .os_tag = .freestanding,
       .abi = .none,
    });
    exe.addAssemblyFile("loader.s");
    exe.setLinkerScriptPath("kernel.ld");
    
    exe.install();
}
