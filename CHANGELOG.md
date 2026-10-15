# Changelog

All notable changes to this project are documented here. The format is based
on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Versions follow
the title's `contentVersion` in `sce_sys/param.json`.

## [00.001.000] - 2026-10-15

First build of Wave Race 64: Recompiled (main at `b7c677a`, after v1.0.2) as a
native PS5 title.

### Added
- Native title `PPSA69424`, rendering with RT64 through Vulkan on Mihawk's RADV
  port, output at 3840x2160 on the console's display plane.
- The game starts straight away: the ROM is imported from the title folder on
  the first start; settings and saves are kept there.
- Frame interpolation to the console's 60 Hz.
- The touchpad opens the Wave Race 64: Recompiled menu.
- `wr64.log` in the title folder with the start-up steps, errors and crash
  reports; the previous session's log is kept as `wr64.prev.log`.
- Home screen icon and background.

### Known issues
- Tested on one console (FW 13.60, ShadowMountPlus) only.
- One crash was seen in the first test; its cause is unknown.
- Native code mods cannot be loaded.
- The first start compiles the renderer's shaders and takes longer.
