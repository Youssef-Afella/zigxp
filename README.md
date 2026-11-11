# zigxp

A little project trying to bring zig back to windows xp.<br>
It aiming to be a fast, simple (and unsafe for now) drop in solution to see your code running in winxp.

I just got my hands on a VAIO TX3XP laptop and I love this thing. Sadely, anything I compile with zig fail to run on it due to linking errors.<br>
Zig relies on some new ntdll functions that are not available in the old api.<br>
Luckely though, Zig uses a very very small subset of the ntdll lib. At first I thought it would take a long time to port the missing functions, but they turned out to be a very small number (exactly 34) and most of them are not even needed by my projects.<br>

I'm not a windows/os expert by any meaning so any contributions, corrections, smarter approaches to implement anything is very welcomed.

## How to use

Add "zigxp.zig" to your project directory then link it to your projet through your "build.zig".<br>
Make sure to only include it when you target windows xp and in release builds only.

```zig
if (target_is_xp) {
    const zigxp = b.addObject(.{
        .name = "zigxp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("zigxp.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.root_module.addObject(zigxp);
}
```