# Installation

1. Copy the complete `roksprite` directory into your project as `addons/roksprite`.
2. Open the project in Godot.
3. Open **Project > Project Settings > Plugins**.
4. Enable **RokSprite**.
5. Open the **RokSprite** editor dock.

Keep the directory intact: scripts, the scene, palettes, font, and `assets/ui` resources are all required.

## Updating

Disable the plugin, replace `addons/roksprite`, then re-enable it. User preferences and the versioned recovery session remain under the project-specific `user://` data directory; the addon directory is never used for session state.

## Uninstalling

Disable RokSprite in **Project Settings > Plugins**, then remove `addons/roksprite`. Project PNGs are not removed. Recovery state under `user://roksprite/` may be removed separately if it is no longer wanted.
