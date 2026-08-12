# RokSprite

RokSprite is a Godot 4 editor plugin for drawing square pixel-art tiles, managing TileSets, applying palette operations, and loading/saving PNG sprite sheets.

## Highlights

- Pencil, eraser, line, rectangle, fill, picker, selection, and transform tools.
- Chronological undo/redo across canvas, palette, and tile-list changes.
- PNG sheet import/export that preserves the dimensions of loaded sheets, including transparent trailing cells.
- Versioned crash/session recovery stored only under `user://roksprite/`.
- Optional sync to an explicitly selected PNG path.

See [INSTALL.md](INSTALL.md) for installation and enablement. The plugin is distributed under [the MIT licence](LICENSE); bundled third-party material is listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Compatibility

The plugin targets Godot 4.x and is tested headlessly with Godot 4.7.
