@tool
class_name PixelCanvas
extends Control

signal color_picked(color: Color)
signal quick_color_picked(color: Color)
signal image_changed
## Emitted once after a user edit is committed. Pointer-driven tools emit this
## when their initiating mouse button is released, so external previews update
## from the final image instead of tool-specific intermediate states.
signal edit_committed
signal edit_started(before_image: Image)
signal zoom_changed(value: int)
signal hover_pixel_changed(pixel: Vector2i, valid: bool)

const MIN_SIZE := 8
const MAX_SIZE := 256
const MIN_ZOOM := 1
const MAX_ZOOM := 1024
const DEFAULT_MAX_ZOOM := 48
const WHEEL_ZOOM_STEP_LOW := 1
const WHEEL_ZOOM_STEP_MID := 2
const WHEEL_ZOOM_STEP_HIGH := 3
const PINCH_ZOOM_LOG_STEP := 0.06
const UNDO_CAP := 64
const MIN_CURSOR_SCALE := 1
const MAX_CURSOR_SCALE := 8
const DEFAULT_CURSOR_SCALE := 2
const CHECKER_A := Color(0.78, 0.78, 0.78)
const CHECKER_B := Color(0.62, 0.62, 0.62)
const DEFAULT_GRID_COLOR := Color(0, 0, 0, 0.25)

var image: Image
var canvas_size: int = 32
var zoom: int = 16
var current_tool: int = SpriteTools.Tool.PENCIL
var primary_color: Color = Color(0, 0, 0, 1)
var show_grid: bool = true
var grid_color: Color = DEFAULT_GRID_COLOR
var grid_thickness: int = 1
var pan_speed: float = 1.0
var cursor_scale: int = DEFAULT_CURSOR_SCALE

var _undo_stack: Array[Image] = []
var _redo_stack: Array[Image] = []

var _drawing: bool = false
var _draw_with_eraser: bool = false
var _active_draw_button: int = MOUSE_BUTTON_LEFT
var _pending_draw_start: bool = false
var _pending_draw_button: int = MOUSE_BUTTON_LEFT
var _pending_draw_with_eraser: bool = false
var _stroke_start: Vector2i = Vector2i.ZERO
var _last_draw_pos: Vector2i = Vector2i.ZERO
var _preview_image: Image = null
var _pre_stroke_image: Image = null
var _checker_tex: ImageTexture
var _display_tex: ImageTexture
var _grid_tex: ImageTexture
var _checker_rect: TextureRect
var _display_rect: TextureRect
var _grid_rect: TextureRect
var _last_hover_valid: bool = false
var _last_hover_pixel: Vector2i = Vector2i(-1, -1)
var _pan_offset: Vector2 = Vector2.ZERO
var _panning: bool = false
var _pan_last_local: Vector2 = Vector2.ZERO
var _selection_mode: bool = false
var _selection_copy_move_mode: bool = false
var _selection_active: bool = false
var _selection_selecting: bool = false
var _selection_moving: bool = false
var _selection_rect: Rect2i = Rect2i(Vector2i.ZERO, Vector2i.ZERO)
var _selection_anchor: Vector2i = Vector2i.ZERO
var _selection_move_start_pixel: Vector2i = Vector2i.ZERO
var _selection_move_origin: Vector2i = Vector2i.ZERO
var _selection_move_size: Vector2i = Vector2i.ZERO
var _selection_move_base_image: Image = null
var _selection_move_content: Image = null
var _selection_rect_node: RokSpriteSelectionOverlay
var _custom_cursor_rect: TextureRect
var _cursor_preview_panel: Panel
var _cross_cursor_tex: Texture2D
var _cross_cursor_tex_dark: Texture2D
var _cross_cursor_tex_light: Texture2D
var _cross_cursor_img: Image
var _cross_cursor_hotspot: Vector2 = Vector2(8, 8)
var _cross_cursor_installed: bool = false
var _dynamic_cursor_contrast_enabled: bool = true
var _mouse_hidden_for_custom_cursor: bool = false
var _previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE
var _custom_cursor_blocked: bool = false
var _pinch_zoom_accum: float = 0.0
var _wheel_zoom_blocked: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	set_process(true)
	_apply_cross_cursor_style()
	_ensure_display_nodes()
	if image == null:
		_new_image(canvas_size)
	_rebuild_checker()
	_refresh_display_texture()
	resized.connect(_on_resized)
	mouse_entered.connect(_on_mouse_entered_canvas)
	mouse_exited.connect(_on_mouse_exited_canvas)


func _exit_tree() -> void:
	_set_custom_cursor_installed(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_set_custom_cursor_installed(false)
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_OUT \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		# When focus leaves Godot (e.g., Launchpad/app switcher/other apps),
		# force-restore OS cursor state even if hover-exit signals are skipped.
		_set_custom_cursor_installed(false)


func _process(_delta: float) -> void:
	_sync_custom_cursor_scope()


func _apply_cross_cursor_style() -> void:
	var external_cursor: Texture2D = null
	var cursor_paths := [
		"res://addons/roksprite/cursor_sprite.png",
		"res://cursor_sprite.png"
	]
	for p in cursor_paths:
		if ResourceLoader.exists(p):
			external_cursor = load(p) as Texture2D
			if external_cursor != null:
				break
	if external_cursor != null and external_cursor.get_image() != null:
		_cross_cursor_img = _scale_cursor_image(external_cursor.get_image(), cursor_scale)
	else:
		_cross_cursor_img = _scale_cursor_image(_build_cross_cursor_image(), cursor_scale)
	if _cross_cursor_img == null:
		return
	_cross_cursor_tex_dark = ImageTexture.create_from_image(_cross_cursor_img)
	_cross_cursor_tex_light = ImageTexture.create_from_image(_invert_cursor_image(_cross_cursor_img))
	_cross_cursor_tex = _cross_cursor_tex_dark
	_cross_cursor_hotspot = Vector2(8, 8)
	if _cross_cursor_tex.get_width() > 0 and _cross_cursor_tex.get_height() > 0:
		_cross_cursor_hotspot = Vector2(floor(_cross_cursor_tex.get_width() * 0.5), floor(_cross_cursor_tex.get_height() * 0.5))
	if _cross_cursor_installed:
		_set_custom_cursor_installed(false)
		_set_custom_cursor_installed(true)


func _invert_cursor_image(src: Image) -> Image:
	var out := src.duplicate()
	if out == null:
		return src
	for y in range(out.get_height()):
		for x in range(out.get_width()):
			var c: Color = out.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			out.set_pixel(x, y, Color(1.0 - c.r, 1.0 - c.g, 1.0 - c.b, c.a))
	return out


func _build_cross_cursor_image() -> Image:
	var size := 17
	var center := size / 2
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var outline := Color(0, 0, 0, 1)
	var core := Color(1, 1, 1, 1)
	# Outline ring around the cross.
	for i in range(-3, 4):
		img.set_pixel(center + i, center - 1, outline)
		img.set_pixel(center + i, center + 1, outline)
		img.set_pixel(center - 1, center + i, outline)
		img.set_pixel(center + 1, center + i, outline)
	# White cross core.
	for i in range(-2, 3):
		img.set_pixel(center + i, center, core)
		img.set_pixel(center, center + i, core)
	return img


func _scale_cursor_image(src: Image, factor: int) -> Image:
	if src == null:
		return null
	var safe_factor := maxi(1, factor)
	if safe_factor == 1:
		return src.duplicate()
	var out_w := src.get_width() * safe_factor
	var out_h := src.get_height() * safe_factor
	var out := Image.create_empty(out_w, out_h, false, Image.FORMAT_RGBA8)
	for y in range(src.get_height()):
		for x in range(src.get_width()):
			var c := src.get_pixel(x, y)
			var ox := x * safe_factor
			var oy := y * safe_factor
			out.fill_rect(Rect2i(ox, oy, safe_factor, safe_factor), c)
	return out


# ---------------------------------------------------------------- Public API

func new_canvas(new_size: int) -> void:
	new_size = clampi(new_size, MIN_SIZE, MAX_SIZE)
	_new_image(new_size)
	_clear_selection_state()
	_undo_stack.clear()
	_redo_stack.clear()
	_rebuild_checker()
	_refresh_display_texture()
	queue_redraw()
	image_changed.emit()


func resize_canvas(new_size: int) -> void:
	# Alias used from UI.
	new_canvas(new_size)


func load_from_png(path: String) -> bool:
	var img := Image.new()
	var err := img.load(path)
	if err != OK:
		push_error("Failed to load PNG: %s" % path)
		return false
	if img.get_width() != img.get_height():
		push_warning("Loaded image is not square; it will be cropped to a square.")
		var s: int = mini(img.get_width(), img.get_height())
		img = img.get_region(Rect2i(0, 0, s, s))
	var new_size: int = clampi(img.get_width(), MIN_SIZE, MAX_SIZE)
	if img.get_width() != new_size:
		img.resize(new_size, new_size, Image.INTERPOLATE_NEAREST)
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	_push_undo()
	image = img
	canvas_size = new_size
	_clear_selection_state()
	_rebuild_checker()
	_refresh_display_texture()
	queue_redraw()
	image_changed.emit()
	return true


func save_to_png(path: String) -> bool:
	var err := image.save_png(path)
	if err != OK:
		push_error("Failed to save PNG: %s" % path)
		return false
	return true


func set_image_from_image(src: Image, commit_edit: bool = false) -> void:
	if src == null:
		return
	if commit_edit and image != null:
		_push_undo()
	var img := src.duplicate() as Image
	if img == null:
		return
	if img.get_width() != img.get_height():
		var s: int = mini(img.get_width(), img.get_height())
		img = img.get_region(Rect2i(0, 0, s, s))
	var new_size: int = clampi(img.get_width(), MIN_SIZE, MAX_SIZE)
	if img.get_width() != new_size:
		img.resize(new_size, new_size, Image.INTERPOLATE_NEAREST)
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	image = img
	canvas_size = new_size
	_clear_selection_state()
	_rebuild_checker()
	_refresh_display_texture()
	queue_redraw()
	if commit_edit:
		_emit_edit_committed()
	else:
		image_changed.emit()


func has_drawn_pixels() -> bool:
	if image == null:
		return false
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.0:
				return true
	return false


# ---------------------------------------------------------------- Transforms

func flip_horizontal() -> void:
	if _apply_flip_h_selection():
		return
	_push_undo()
	image.flip_x()
	_refresh_display_texture()
	queue_redraw()
	_emit_edit_committed()


func flip_vertical() -> void:
	if _apply_flip_v_selection():
		return
	_push_undo()
	image.flip_y()
	_refresh_display_texture()
	queue_redraw()
	_emit_edit_committed()


func rotate_90_cw() -> void:
	if _selection_rect_valid():
		_apply_rotate_cw_selection()
		return
	_push_undo()
	var src := image.duplicate() as Image
	var s := canvas_size
	for y in s:
		for x in s:
			image.set_pixel(s - 1 - y, x, src.get_pixel(x, y))
	_refresh_display_texture()
	queue_redraw()
	_emit_edit_committed()


func rotate_90_ccw() -> void:
	if _selection_rect_valid():
		_apply_rotate_ccw_selection()
		return
	_push_undo()
	var src := image.duplicate() as Image
	var s := canvas_size
	for y in s:
		for x in s:
			image.set_pixel(y, s - 1 - x, src.get_pixel(x, y))
	_refresh_display_texture()
	queue_redraw()
	_emit_edit_committed()


# dir.x: -1 left, +1 right. dir.y: -1 up, +1 down. Wraps.
func shift(dir: Vector2i) -> void:
	if dir == Vector2i.ZERO:
		return
	if _apply_shift_selection(dir):
		return
	_push_undo()
	var src := image.duplicate() as Image
	var s := canvas_size
	for y in s:
		for x in s:
			var sx := posmod(x - dir.x, s)
			var sy := posmod(y - dir.y, s)
			image.set_pixel(x, y, src.get_pixel(sx, sy))
	_refresh_display_texture()
	queue_redraw()
	_emit_edit_committed()


# ---------------------------------------------------------------- Undo/Redo

func undo() -> void:
	if _undo_stack.is_empty():
		return
	_redo_stack.append(image.duplicate() as Image)
	image = _undo_stack.pop_back()
	_refresh_display_texture()
	queue_redraw()
	_emit_edit_committed()


func redo() -> void:
	if _redo_stack.is_empty():
		return
	_undo_stack.append(image.duplicate() as Image)
	image = _redo_stack.pop_back()
	_refresh_display_texture()
	queue_redraw()
	_emit_edit_committed()


# ---------------------------------------------------------------- Zoom

func set_zoom(z: int) -> void:
	set_zoom_at(z, size * 0.5)


func set_zoom_at(z: int, focus_local: Vector2) -> void:
	var new_zoom := clampi(z, MIN_ZOOM, get_max_zoom_limit())
	if new_zoom == zoom:
		return
	var focus_inside_canvas := _in_canvas_rect(focus_local)
	var old_off := _draw_offset()
	var focus_pixel := (focus_local - old_off) / float(maxi(1, zoom))
	zoom = new_zoom
	if focus_inside_canvas:
		var px: float = canvas_size * zoom
		var centered_off := ((size - Vector2(px, px)) * 0.5).floor()
		var desired_off := focus_local - (focus_pixel * float(zoom))
		_pan_offset = desired_off - centered_off
		_clamp_pan_offset()
	_rebuild_checker()
	queue_redraw()
	zoom_changed.emit(zoom)


func zoom_fit_vertical() -> void:
	if canvas_size <= 0:
		return
	var fit_zoom := int(floor(size.y / float(canvas_size)))
	set_zoom(clampi(fit_zoom, MIN_ZOOM, get_max_zoom_limit()))


func zoom_fit_screen() -> void:
	if canvas_size <= 0:
		return
	var fit_zoom := int(floor(minf(size.x, size.y) / float(canvas_size)))
	_pan_offset = Vector2.ZERO
	set_zoom(clampi(fit_zoom, MIN_ZOOM, get_max_zoom_limit()))
	_layout_display_nodes()
	queue_redraw()


func set_show_grid(enabled: bool) -> void:
	show_grid = enabled
	_rebuild_grid_overlay()
	queue_redraw()


func set_grid_style(color: Color, thickness: int) -> void:
	grid_color = color
	grid_thickness = clampi(thickness, 1, 8)
	_rebuild_grid_overlay()
	queue_redraw()


func set_pan_speed(speed: float) -> void:
	pan_speed = clampf(speed, 0.1, 8.0)


func set_cursor_scale(scale: int) -> void:
	cursor_scale = clampi(scale, MIN_CURSOR_SCALE, MAX_CURSOR_SCALE)
	_apply_cross_cursor_style()


func set_dynamic_cursor_contrast_enabled(enabled: bool) -> void:
	_dynamic_cursor_contrast_enabled = enabled


func set_wheel_zoom_blocked(blocked: bool) -> void:
	_wheel_zoom_blocked = blocked


func set_custom_cursor_blocked(blocked: bool) -> void:
	_custom_cursor_blocked = blocked
	if blocked:
		_set_custom_cursor_installed(false)


func set_selection_mode(enabled: bool) -> void:
	_selection_mode = enabled
	if not enabled:
		_selection_active = false
		_selection_selecting = false
		_selection_moving = false
	_rebuild_selection_overlay()
	queue_redraw()


func set_selection_copy_move_mode(enabled: bool) -> void:
	_selection_copy_move_mode = enabled


func delete_selection_if_any() -> bool:
	if not _selection_active:
		return false
	_push_undo()
	_clear_rect_on_image(image, _selection_rect)
	_selection_active = false
	_selection_selecting = false
	_selection_moving = false
	_selection_rect = Rect2i(Vector2i.ZERO, Vector2i.ZERO)
	_selection_move_base_image = null
	_selection_move_content = null
	_refresh_display_texture()
	_rebuild_selection_overlay()
	queue_redraw()
	_emit_edit_committed()
	return true


func pick_color_under_mouse() -> bool:
	if image == null:
		return false
	var vp := get_viewport()
	if vp == null:
		return false
	var local_pos := _viewport_to_local(vp.get_mouse_position())
	if not _in_control_rect(local_pos):
		return false
	if not _in_canvas_rect(local_pos):
		return false
	var p := _pixel_at(local_pos)
	quick_color_picked.emit(image.get_pixel(p.x, p.y))
	return true


# ---------------------------------------------------------------- Internals

func _new_image(size: int) -> void:
	canvas_size = size
	image = Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_preview_image = null
	_refresh_display_texture()
	_rebuild_grid_overlay()


func _emit_edit_committed() -> void:
	image_changed.emit()
	edit_committed.emit()


func _clear_selection_state() -> void:
	_selection_active = false
	_selection_selecting = false
	_selection_moving = false
	_selection_rect = Rect2i(Vector2i.ZERO, Vector2i.ZERO)
	_selection_anchor = Vector2i.ZERO
	_selection_move_start_pixel = Vector2i.ZERO
	_selection_move_origin = Vector2i.ZERO
	_selection_move_size = Vector2i.ZERO
	_selection_move_base_image = null
	_selection_move_content = null
	_rebuild_selection_overlay()


func _push_undo() -> void:
	var snapshot := image.duplicate() as Image
	edit_started.emit(snapshot)
	_undo_stack.append(snapshot)
	if _undo_stack.size() > UNDO_CAP:
		_undo_stack.pop_front()
	_redo_stack.clear()


func get_max_zoom_limit() -> int:
	if canvas_size <= 0:
		return DEFAULT_MAX_ZOOM
	var view_edge := maxf(size.x, size.y)
	if view_edge <= 0.0:
		return DEFAULT_MAX_ZOOM
	var fit_edge_zoom := int(ceil(view_edge / float(canvas_size)))
	return clampi(maxi(DEFAULT_MAX_ZOOM, fit_edge_zoom), MIN_ZOOM, MAX_ZOOM)


func _draw_offset() -> Vector2:
	var px: float = canvas_size * zoom
	return ((size - Vector2(px, px)) * 0.5).floor() + _pan_offset


func _clamp_pan_offset() -> void:
	var px: float = canvas_size * zoom
	var lim_x := (size.x + px) * 0.5
	var lim_y := (size.y + px) * 0.5
	_pan_offset.x = clampf(_pan_offset.x, -lim_x, lim_x)
	_pan_offset.y = clampf(_pan_offset.y, -lim_y, lim_y)


func _ensure_display_nodes() -> void:
	if _checker_rect == null:
		_checker_rect = TextureRect.new()
		_checker_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_checker_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_checker_rect.stretch_mode = TextureRect.STRETCH_TILE
		add_child(_checker_rect)
	if _display_rect == null:
		_display_rect = TextureRect.new()
		_display_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_display_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_display_rect.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(_display_rect)
	if _grid_rect == null:
		_grid_rect = TextureRect.new()
		_grid_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_grid_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_grid_rect.stretch_mode = TextureRect.STRETCH_TILE
		add_child(_grid_rect)
	if _selection_rect_node == null:
		_selection_rect_node = RokSpriteSelectionOverlay.new()
		_selection_rect_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_selection_rect_node.z_as_relative = true
		_selection_rect_node.z_index = 5
		add_child(_selection_rect_node)
	if _cursor_preview_panel == null:
		_cursor_preview_panel = Panel.new()
		_cursor_preview_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_cursor_preview_panel.visible = false
		_cursor_preview_panel.z_as_relative = true
		_cursor_preview_panel.z_index = 10
		add_child(_cursor_preview_panel)
	if _custom_cursor_rect == null:
		_custom_cursor_rect = TextureRect.new()
		_custom_cursor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_custom_cursor_rect.visible = false
		_custom_cursor_rect.top_level = true
		_custom_cursor_rect.z_as_relative = true
		_custom_cursor_rect.z_index = 100
		_custom_cursor_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_custom_cursor_rect.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(_custom_cursor_rect)


func _layout_display_nodes() -> void:
	if _checker_rect == null or _display_rect == null or _grid_rect == null:
		return
	var px: float = canvas_size * zoom
	var off := _draw_offset()
	var rect_size := Vector2(px, px)
	_checker_rect.position = off
	_checker_rect.size = rect_size
	_display_rect.position = off
	_display_rect.size = rect_size
	_grid_rect.position = off
	_grid_rect.size = rect_size
	_selection_rect_node.position = off
	_selection_rect_node.size = rect_size
	_update_cursor_preview_overlay()


func _on_resized() -> void:
	if zoom > get_max_zoom_limit():
		zoom = get_max_zoom_limit()
		zoom_changed.emit(zoom)
	_layout_display_nodes()
	_rebuild_grid_overlay()
	queue_redraw()


func _on_mouse_entered_canvas() -> void:
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	_sync_custom_cursor_scope()


func _on_mouse_exited_canvas() -> void:
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	_set_custom_cursor_installed(false)


func release_custom_cursor() -> void:
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	_set_custom_cursor_installed(false)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_sync_custom_cursor_scope()


func _sync_custom_cursor_scope() -> void:
	var should_install := _should_install_custom_cursor()
	if should_install == _cross_cursor_installed:
		_update_custom_cursor_overlay(should_install)
		return
	_set_custom_cursor_installed(should_install)
	_update_custom_cursor_overlay(should_install)


func _should_install_custom_cursor() -> bool:
	if _custom_cursor_blocked:
		return false
	if not is_inside_tree() or not is_visible_in_tree():
		return false
	if not DisplayServer.window_is_focused():
		return false
	if _cross_cursor_tex == null:
		return false
	var vp := get_viewport()
	if vp == null:
		return false
	if not get_global_rect().has_point(vp.get_mouse_position()):
		return false
	if vp.has_method("gui_get_hovered_control"):
		var hovered := vp.call("gui_get_hovered_control") as Control
		if hovered != null and hovered != self and not is_ancestor_of(hovered):
			return false
	return true


func _set_custom_cursor_installed(enabled: bool) -> void:
	if enabled:
		if _cross_cursor_tex == null:
			return
		Input.set_custom_mouse_cursor(_cross_cursor_tex, Input.CURSOR_ARROW, _cross_cursor_hotspot)
		Input.set_custom_mouse_cursor(_cross_cursor_tex, Input.CURSOR_CROSS, _cross_cursor_hotspot)
		if not _mouse_hidden_for_custom_cursor:
			_previous_mouse_mode = Input.mouse_mode
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
			_mouse_hidden_for_custom_cursor = true
		_cross_cursor_installed = true
		return
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW, Vector2.ZERO)
	Input.set_custom_mouse_cursor(null, Input.CURSOR_CROSS, Vector2.ZERO)
	if _mouse_hidden_for_custom_cursor:
		Input.mouse_mode = _previous_mouse_mode
		_mouse_hidden_for_custom_cursor = false
	if _custom_cursor_rect != null:
		_custom_cursor_rect.visible = false
	_cross_cursor_installed = false


func _update_custom_cursor_overlay(visible: bool) -> void:
	if _custom_cursor_rect == null:
		return
	if not visible or _cross_cursor_tex == null:
		_custom_cursor_rect.visible = false
		return
	var vp := get_viewport()
	if vp == null:
		_custom_cursor_rect.visible = false
		return
	var global_pos := vp.get_mouse_position()
	var local_pos := _viewport_to_local(global_pos)
	var use_light := false
	if image != null and _in_control_rect(local_pos) and _in_canvas_rect(local_pos):
		var p := _pixel_at(local_pos)
		if p.x >= 0 and p.y >= 0 and p.x < image.get_width() and p.y < image.get_height():
			var px: Color = image.get_pixel(p.x, p.y)
			if _is_cursor_preview_active() and _last_hover_valid and p == _last_hover_pixel:
				var draw_color := _active_stroke_color()
				if draw_color.a > 0.0:
					px = draw_color
			if _dynamic_cursor_contrast_enabled:
				var luma := (px.r * 0.2126) + (px.g * 0.7152) + (px.b * 0.0722)
				use_light = luma > 0.55
	var tex := _cross_cursor_tex_light if use_light else _cross_cursor_tex_dark
	if tex == null:
		tex = _cross_cursor_tex
	_custom_cursor_rect.texture = tex
	_custom_cursor_rect.size = Vector2(tex.get_width(), tex.get_height())
	_custom_cursor_rect.global_position = global_pos - _cross_cursor_hotspot
	_custom_cursor_rect.visible = true


func _is_cursor_preview_active() -> bool:
	if image == null or _selection_mode or not _last_hover_valid:
		return false
	var tool := _active_stroke_tool()
	if tool == SpriteTools.Tool.PICKER:
		return false
	return tool == SpriteTools.Tool.PENCIL \
			or tool == SpriteTools.Tool.ERASER \
			or tool == SpriteTools.Tool.LINE \
			or tool == SpriteTools.Tool.RECT_OUTLINE \
			or tool == SpriteTools.Tool.RECT_FILLED \
			or tool == SpriteTools.Tool.BUCKET


func _rebuild_checker() -> void:
	# Build tiny repeating 2x2 checker tile, then let TextureRect tile it.
	var cell: int = maxi(4, zoom / 2)
	var tile := cell * 2
	var ci := Image.create_empty(tile, tile, false, Image.FORMAT_RGBA8)
	ci.fill(CHECKER_A)
	ci.fill_rect(Rect2i(cell, 0, cell, cell), CHECKER_B)
	ci.fill_rect(Rect2i(0, cell, cell, cell), CHECKER_B)
	_checker_tex = ImageTexture.create_from_image(ci)
	if _checker_rect:
		_checker_rect.texture = _checker_tex
	_layout_display_nodes()
	_rebuild_grid_overlay()


func _rebuild_grid_overlay() -> void:
	if _grid_rect == null:
		return
	if not show_grid or zoom < 4:
		var blank := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
		blank.fill(Color(0, 0, 0, 0))
		_grid_tex = ImageTexture.create_from_image(blank)
		_grid_rect.texture = _grid_tex
		_layout_display_nodes()
		_rebuild_selection_overlay()
		return

	# Build one zoom-cell tile; tiled TextureRect draws full grid.
	var cell_px := maxi(1, zoom)
	var gi := Image.create_empty(cell_px, cell_px, false, Image.FORMAT_RGBA8)
	gi.fill(Color(0, 0, 0, 0))
	var tmax := clampi(grid_thickness, 1, 8)
	for t in range(mini(tmax, cell_px)):
		gi.fill_rect(Rect2i(t, 0, 1, cell_px), grid_color) # vertical edge
		gi.fill_rect(Rect2i(0, t, cell_px, 1), grid_color) # horizontal edge
	_grid_tex = ImageTexture.create_from_image(gi)
	_grid_rect.texture = _grid_tex
	_layout_display_nodes()
	_rebuild_selection_overlay()


func _rebuild_selection_overlay() -> void:
	if _selection_rect_node == null:
		return
	_selection_rect_node.set_selection(_selection_rect, zoom, _selection_active)
	_layout_display_nodes()


# ---------------------------------------------------------------- Drawing

func _draw() -> void:
	if image == null:
		return


# ---------------------------------------------------------------- Input

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if image == null:
		return
	if event is InputEventPanGesture:
		var pg := event as InputEventPanGesture
		var vp_pan := get_viewport()
		if vp_pan == null:
			return
		var local_pos_pan := _viewport_to_local(vp_pan.get_mouse_position())
		if not _in_control_rect(local_pos_pan):
			return
		# Trackpad pan gestures report scroll-style delta; invert so canvas follows finger motion.
		_pan_offset -= pg.delta * pan_speed
		_clamp_pan_offset()
		_layout_display_nodes()
		queue_redraw()
		accept_event()
		return
	if event is InputEventMagnifyGesture:
		var mg := event as InputEventMagnifyGesture
		if mg.factor <= 0.0:
			return
		var vp := get_viewport()
		if vp == null:
			return
		var local_pos_gesture := _viewport_to_local(vp.get_mouse_position())
		if not _in_control_rect(local_pos_gesture):
			return
		_pinch_zoom_accum += log(mg.factor)
		var zoom_delta := 0
		while _pinch_zoom_accum >= PINCH_ZOOM_LOG_STEP:
			zoom_delta += 1
			_pinch_zoom_accum -= PINCH_ZOOM_LOG_STEP
		while _pinch_zoom_accum <= -PINCH_ZOOM_LOG_STEP:
			zoom_delta -= 1
			_pinch_zoom_accum += PINCH_ZOOM_LOG_STEP
		if zoom_delta != 0:
			set_zoom_at(zoom + zoom_delta, local_pos_gesture)
		accept_event()
		return
	if not (event is InputEventMouseButton or event is InputEventMouseMotion):
		return
	var me := event as InputEventMouse
	var local_pos := _mouse_local_pos(me)
	_emit_hover_from_local(local_pos)
	var over_control := _in_control_rect(local_pos)
	var over_canvas := _in_canvas_rect(local_pos)
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				if over_control:
					_panning = true
					_pan_last_local = local_pos
					accept_event()
			else:
				if _panning:
					_panning = false
					accept_event()
			return
		if mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			if over_control and not _wheel_zoom_blocked:
				var step := WHEEL_ZOOM_STEP_LOW
				if zoom >= 24:
					step = WHEEL_ZOOM_STEP_HIGH
				elif zoom >= 12:
					step = WHEEL_ZOOM_STEP_MID
				var delta := step if mb.button_index == MOUSE_BUTTON_WHEEL_UP else -step
				# Wheel zoom should focus on pixel-canvas center, not mouse.
				var canvas_center_local := _draw_offset() + Vector2(canvas_size * zoom * 0.5, canvas_size * zoom * 0.5)
				set_zoom_at(zoom + delta, canvas_center_local)
				accept_event()
			return
		if _selection_mode:
			if mb.button_index == MOUSE_BUTTON_LEFT:
				if mb.pressed:
					if over_control and _in_canvas_interaction_zone(local_pos):
						var draw_off := _draw_offset()
						var draw_size := float(canvas_size * zoom)
						var min_pos := draw_off
						var max_pos := draw_off + Vector2(draw_size - 1.0, draw_size - 1.0)
						var clamped_pos := local_pos.clamp(min_pos, max_pos)
						var psel := _pixel_at(clamped_pos)
						# Move only if click starts inside live selection and inside canvas area.
						if _in_canvas_rect(local_pos) and _selection_active and _point_in_selection(psel):
							_begin_selection_move(psel)
						else:
							_begin_selection_drag(psel)
						accept_event()
				else:
					if _selection_selecting:
						_selection_selecting = false
						_selection_active = true
						_rebuild_selection_overlay()
						accept_event()
					elif _selection_moving:
						_end_selection_move(_pixel_at(local_pos))
						accept_event()
			return
		if mb.button_index != MOUSE_BUTTON_LEFT:
			if mb.button_index != MOUSE_BUTTON_RIGHT:
				return
		if mb.pressed:
			if over_control and _in_canvas_rect(local_pos):
				_draw_with_eraser = (mb.button_index == MOUSE_BUTTON_RIGHT)
				_active_draw_button = mb.button_index
				_pending_draw_start = false
				_begin_stroke(_pixel_at(local_pos))
				accept_event()
			elif over_control and _in_canvas_interaction_zone(local_pos):
				# Allow draw press from outside pixel area; start once drag enters canvas.
				_pending_draw_start = true
				_pending_draw_button = mb.button_index
				_pending_draw_with_eraser = (mb.button_index == MOUSE_BUTTON_RIGHT)
				accept_event()
		else:
			if _pending_draw_start and mb.button_index == _pending_draw_button:
				_pending_draw_start = false
			if _drawing and mb.button_index == _active_draw_button:
				_end_stroke(_pixel_at(local_pos))
				accept_event()
	elif event is InputEventMouseMotion:
		if _panning:
			var delta := local_pos - _pan_last_local
			_pan_offset += delta * pan_speed
			_clamp_pan_offset()
			_pan_last_local = local_pos
			_layout_display_nodes()
			queue_redraw()
			accept_event()
			return
		if _selection_mode:
			if _selection_selecting:
				var draw_off := _draw_offset()
				var draw_size := float(canvas_size * zoom)
				var min_pos := draw_off
				var max_pos := draw_off + Vector2(draw_size - 1.0, draw_size - 1.0)
				var clamped_pos := local_pos.clamp(min_pos, max_pos)
				var psel := _pixel_at(clamped_pos)
				_selection_rect = _rect_from(_selection_anchor, psel)
				_selection_active = true
				_rebuild_selection_overlay()
				accept_event()
			elif _selection_moving:
				_update_selection_move(_pixel_at(local_pos))
				accept_event()
			return
		if not _drawing and _pending_draw_start:
			var mm := event as InputEventMouseMotion
			var held := false
			if _pending_draw_button == MOUSE_BUTTON_LEFT:
				held = (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
			elif _pending_draw_button == MOUSE_BUTTON_RIGHT:
				held = (mm.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0
			if not held:
				_pending_draw_start = false
			elif _in_canvas_rect(local_pos):
				_draw_with_eraser = _pending_draw_with_eraser
				_active_draw_button = _pending_draw_button
				_pending_draw_start = false
				_begin_stroke(_pixel_at(local_pos))
				accept_event()
				return
		if _drawing:
			var draw_pos := local_pos
			if not over_control:
				draw_pos = local_pos.clamp(Vector2.ZERO, size - Vector2.ONE)
			_continue_stroke(_pixel_at(draw_pos))
			accept_event()


func _emit_hover_from_local(local_pos: Vector2) -> void:
	var valid := _in_control_rect(local_pos) and _in_canvas_rect(local_pos)
	var p := Vector2i(-1, -1)
	if valid:
		p = _pixel_at(local_pos)
	if valid == _last_hover_valid and p == _last_hover_pixel:
		return
	_last_hover_valid = valid
	_last_hover_pixel = p
	hover_pixel_changed.emit(p, valid)
	_update_cursor_preview_overlay()
	queue_redraw()


func refresh_cursor_preview() -> void:
	_update_cursor_preview_overlay()


func _update_cursor_preview_overlay() -> void:
	if _cursor_preview_panel == null:
		return
	if image == null or not _last_hover_valid or _selection_mode:
		_cursor_preview_panel.visible = false
		return
	if _last_hover_pixel.x < 0 or _last_hover_pixel.y < 0:
		_cursor_preview_panel.visible = false
		return
	var tool := _active_stroke_tool()
	if tool == SpriteTools.Tool.PICKER:
		_cursor_preview_panel.visible = false
		return
	if tool != SpriteTools.Tool.PENCIL \
			and tool != SpriteTools.Tool.ERASER \
			and tool != SpriteTools.Tool.LINE \
			and tool != SpriteTools.Tool.RECT_OUTLINE \
			and tool != SpriteTools.Tool.RECT_FILLED \
			and tool != SpriteTools.Tool.BUCKET:
		_cursor_preview_panel.visible = false
		return
	var off := _draw_offset()
	var cell_size := float(maxi(1, zoom))
	_cursor_preview_panel.position = off + Vector2(float(_last_hover_pixel.x * zoom), float(_last_hover_pixel.y * zoom))
	_cursor_preview_panel.size = Vector2(cell_size, cell_size)
	var draw_color := _active_stroke_color()
	var style := StyleBoxFlat.new()
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.bg_color = draw_color
	_cursor_preview_panel.add_theme_stylebox_override("panel", style)
	_cursor_preview_panel.visible = true


func is_interacting() -> bool:
	return _drawing \
			or _panning \
			or _selection_selecting \
			or _selection_moving


func get_display_image() -> Image:
	return _preview_image if _preview_image != null else image


func _mouse_local_pos(event: InputEventMouse) -> Vector2:
	# _input() mouse positions are reported in viewport space.
	return _viewport_to_local(event.position)


func _viewport_to_local(viewport_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * viewport_pos


func _in_canvas_rect(pos: Vector2) -> bool:
	var off := _draw_offset()
	var px: float = canvas_size * zoom
	return pos.x >= off.x and pos.y >= off.y \
			and pos.x < off.x + px and pos.y < off.y + px


func _in_canvas_interaction_zone(pos: Vector2) -> bool:
	# Allow starting just outside canvas, but not far-off UI regions (tile panel, toolbar rows).
	var off := _draw_offset()
	var px: float = canvas_size * zoom
	var pad := float(maxi(24, zoom * 2))
	return pos.x >= off.x - pad and pos.y >= off.y - pad \
			and pos.x < (off.x + px + pad) and pos.y < (off.y + px + pad)


func _in_control_rect(pos: Vector2) -> bool:
	return pos.x >= 0.0 and pos.y >= 0.0 and pos.x < size.x and pos.y < size.y


func _pixel_at(pos: Vector2) -> Vector2i:
	var local := pos - _draw_offset()
	var p := Vector2i(int(floor(local.x / zoom)), int(floor(local.y / zoom)))
	p.x = clampi(p.x, 0, canvas_size - 1)
	p.y = clampi(p.y, 0, canvas_size - 1)
	return p


func _in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.x < canvas_size and p.y >= 0 and p.y < canvas_size


# ---------------------------------------------------------------- Tool dispatch

func _begin_stroke(p: Vector2i) -> void:
	_drawing = true
	_stroke_start = p
	_last_draw_pos = p
	var tool := _active_stroke_tool()
	var stroke_color := _active_stroke_color()
	match tool:
		SpriteTools.Tool.PENCIL:
			_push_undo()
			_plot(p, stroke_color)
			_refresh_display_texture()
			queue_redraw()
		SpriteTools.Tool.ERASER:
			_push_undo()
			_plot(p, Color(0, 0, 0, 0))
			_refresh_display_texture()
			queue_redraw()
		SpriteTools.Tool.LINE, SpriteTools.Tool.RECT_OUTLINE, SpriteTools.Tool.RECT_FILLED:
			_pre_stroke_image = image.duplicate() as Image
			_preview_image = image.duplicate() as Image
			_update_shape_preview(p, tool, stroke_color)
		SpriteTools.Tool.BUCKET:
			_push_undo()
			_flood_fill(p, stroke_color)
			_refresh_display_texture()
			queue_redraw()
			# Keep the stroke active until button release so previews receive the
			# same single commit event as pencil, eraser, line and rectangle tools.
		SpriteTools.Tool.PICKER:
			var c := image.get_pixel(p.x, p.y)
			color_picked.emit(c)
			_drawing = false


func _continue_stroke(p: Vector2i) -> void:
	var tool := _active_stroke_tool()
	var stroke_color := _active_stroke_color()
	if p == _last_draw_pos and tool != SpriteTools.Tool.LINE \
			and tool != SpriteTools.Tool.RECT_OUTLINE \
			and tool != SpriteTools.Tool.RECT_FILLED:
		return
	match tool:
		SpriteTools.Tool.PENCIL:
			_line_plot(_last_draw_pos, p, stroke_color)
			_last_draw_pos = p
			_refresh_display_texture()
			queue_redraw()
		SpriteTools.Tool.ERASER:
			_line_plot(_last_draw_pos, p, Color(0, 0, 0, 0))
			_last_draw_pos = p
			_refresh_display_texture()
			queue_redraw()
		SpriteTools.Tool.LINE, SpriteTools.Tool.RECT_OUTLINE, SpriteTools.Tool.RECT_FILLED:
			_update_shape_preview(p, tool, stroke_color)


func _end_stroke(p: Vector2i) -> void:
	if not _drawing:
		return
	_drawing = false
	var tool := _active_stroke_tool()
	var stroke_color := _active_stroke_color()
	match tool:
		SpriteTools.Tool.LINE, SpriteTools.Tool.RECT_OUTLINE, SpriteTools.Tool.RECT_FILLED:
			_push_undo_with(_pre_stroke_image)
			_commit_shape(p, tool, stroke_color)
			_preview_image = null
			_pre_stroke_image = null
			_refresh_display_texture()
			queue_redraw()
	_draw_with_eraser = false
	_active_draw_button = MOUSE_BUTTON_LEFT
	_emit_edit_committed()


func _push_undo_with(snapshot: Image) -> void:
	# Used by shape tools so that undo returns to the pre-drag state even
	# though the preview image has been shown during the drag.
	edit_started.emit(snapshot.duplicate() as Image)
	_undo_stack.append(snapshot)
	if _undo_stack.size() > UNDO_CAP:
		_undo_stack.pop_front()
	_redo_stack.clear()


func _refresh_display_texture() -> void:
	var display_img := _preview_image if _preview_image != null else image
	if display_img == null:
		_display_tex = null
		return
	if _display_tex == null \
			or _display_tex.get_width() != display_img.get_width() \
			or _display_tex.get_height() != display_img.get_height():
		_display_tex = ImageTexture.create_from_image(display_img)
	else:
		_display_tex.update(display_img)
	if _display_rect:
		_display_rect.texture = _display_tex
	_layout_display_nodes()


func _update_shape_preview(p: Vector2i, tool: int, color: Color) -> void:
	_preview_image = _pre_stroke_image.duplicate() as Image
	_stamp_shape_on(_preview_image, _stroke_start, p, color, tool)
	_refresh_display_texture()
	queue_redraw()


func _commit_shape(p: Vector2i, tool: int, color: Color) -> void:
	_stamp_shape_on(image, _stroke_start, p, color, tool)


func _stamp_shape_on(target: Image, a: Vector2i, b: Vector2i, color: Color, tool: int) -> void:
	match tool:
		SpriteTools.Tool.LINE:
			_bresenham(a, b, func(x, y): _plot_on(target, Vector2i(x, y), color))
		SpriteTools.Tool.RECT_OUTLINE:
			var r := _rect_from(a, b)
			for x in range(r.position.x, r.position.x + r.size.x):
				_plot_on(target, Vector2i(x, r.position.y), color)
				_plot_on(target, Vector2i(x, r.position.y + r.size.y - 1), color)
			for y in range(r.position.y, r.position.y + r.size.y):
				_plot_on(target, Vector2i(r.position.x, y), color)
				_plot_on(target, Vector2i(r.position.x + r.size.x - 1, y), color)
		SpriteTools.Tool.RECT_FILLED:
			var r2 := _rect_from(a, b)
			for y in range(r2.position.y, r2.position.y + r2.size.y):
				for x in range(r2.position.x, r2.position.x + r2.size.x):
					_plot_on(target, Vector2i(x, y), color)


func _active_stroke_tool() -> int:
	if not _draw_with_eraser:
		return current_tool
	match current_tool:
		SpriteTools.Tool.PENCIL, SpriteTools.Tool.LINE, SpriteTools.Tool.RECT_OUTLINE, SpriteTools.Tool.RECT_FILLED, SpriteTools.Tool.BUCKET:
			return current_tool
	return SpriteTools.Tool.ERASER


func _active_stroke_color() -> Color:
	return Color(0, 0, 0, 0) if _draw_with_eraser else primary_color


func _rect_from(a: Vector2i, b: Vector2i) -> Rect2i:
	var x0: int = mini(a.x, b.x)
	var y0: int = mini(a.y, b.y)
	var x1: int = maxi(a.x, b.x)
	var y1: int = maxi(a.y, b.y)
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)


func _point_in_selection(p: Vector2i) -> bool:
	if not _selection_active:
		return false
	return p.x >= _selection_rect.position.x and p.y >= _selection_rect.position.y \
			and p.x < (_selection_rect.position.x + _selection_rect.size.x) \
			and p.y < (_selection_rect.position.y + _selection_rect.size.y)


func _begin_selection_drag(p: Vector2i) -> void:
	_selection_selecting = true
	_selection_moving = false
	_selection_anchor = p
	_selection_rect = Rect2i(p, Vector2i.ONE)
	_selection_active = true
	_rebuild_selection_overlay()


func _begin_selection_move(p: Vector2i) -> void:
	if not _selection_active:
		return
	_push_undo()
	_selection_selecting = false
	_selection_moving = true
	_selection_move_start_pixel = p
	_selection_move_origin = _selection_rect.position
	_selection_move_size = _selection_rect.size
	_selection_move_base_image = image.duplicate() as Image
	_selection_move_content = _extract_rect_from_image(image, _selection_rect)
	if not _selection_copy_move_mode:
		_clear_rect_on_image(_selection_move_base_image, _selection_rect)
	_update_selection_move(p)


func _update_selection_move(p: Vector2i) -> void:
	if not _selection_moving:
		return
	var delta := p - _selection_move_start_pixel
	var new_pos := _selection_move_origin + delta
	image = _selection_move_base_image.duplicate() as Image
	_blit_image_with_clip(image, _selection_move_content, new_pos)
	_selection_rect = Rect2i(new_pos, _selection_move_size)
	_refresh_display_texture()
	_rebuild_selection_overlay()
	queue_redraw()


func _end_selection_move(p: Vector2i) -> void:
	if not _selection_moving:
		return
	_update_selection_move(p)
	_selection_moving = false
	# After dropping, commit at final location and return to fresh marquee state.
	_selection_active = false
	_selection_rect = Rect2i(Vector2i.ZERO, Vector2i.ZERO)
	_selection_move_base_image = null
	_selection_move_content = null
	_rebuild_selection_overlay()
	_emit_edit_committed()


func _extract_rect_from_image(src: Image, rect: Rect2i) -> Image:
	var out := Image.create_empty(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			var sx := rect.position.x + x
			var sy := rect.position.y + y
			if sx < 0 or sy < 0 or sx >= canvas_size or sy >= canvas_size:
				continue
			out.set_pixel(x, y, src.get_pixel(sx, sy))
	return out


func _clear_rect_on_image(target: Image, rect: Rect2i) -> void:
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			var tx := rect.position.x + x
			var ty := rect.position.y + y
			if tx < 0 or ty < 0 or tx >= canvas_size or ty >= canvas_size:
				continue
			target.set_pixel(tx, ty, Color(0, 0, 0, 0))


func _blit_image_with_clip(target: Image, src: Image, pos: Vector2i) -> void:
	if src == null:
		return
	for y in range(src.get_height()):
		for x in range(src.get_width()):
			var tx := pos.x + x
			var ty := pos.y + y
			if tx < 0 or ty < 0 or tx >= canvas_size or ty >= canvas_size:
				continue
			var src_px := src.get_pixel(x, y)
			# Merge move result: transparent source keeps destination pixel.
			if src_px.a <= 0.0:
				continue
			target.set_pixel(tx, ty, src_px)


func _selection_rect_valid() -> bool:
	return _selection_active and _selection_rect.size.x > 0 and _selection_rect.size.y > 0


func _apply_flip_h_selection() -> bool:
	if not _selection_rect_valid():
		return false
	_push_undo()
	var rect := _selection_rect
	var src := _extract_rect_from_image(image, rect)
	var w := rect.size.x
	var h := rect.size.y
	var out := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			out.set_pixel(w - 1 - x, y, src.get_pixel(x, y))
	_blit_rect_overwrite(image, out, rect.position)
	_refresh_display_texture()
	_rebuild_selection_overlay()
	queue_redraw()
	_emit_edit_committed()
	return true


func _apply_flip_v_selection() -> bool:
	if not _selection_rect_valid():
		return false
	_push_undo()
	var rect := _selection_rect
	var src := _extract_rect_from_image(image, rect)
	var w := rect.size.x
	var h := rect.size.y
	var out := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			out.set_pixel(x, h - 1 - y, src.get_pixel(x, y))
	_blit_rect_overwrite(image, out, rect.position)
	_refresh_display_texture()
	_rebuild_selection_overlay()
	queue_redraw()
	_emit_edit_committed()
	return true


func _apply_rotate_cw_selection() -> bool:
	if not _selection_rect_valid():
		return false
	var rect := _selection_rect
	if rect.size.x != rect.size.y:
		# Keep behavior predictable; 90deg rotate changes dimensions for non-square rects.
		return false
	_push_undo()
	var src := _extract_rect_from_image(image, rect)
	var s := rect.size.x
	var out := Image.create_empty(s, s, false, Image.FORMAT_RGBA8)
	for y in range(s):
		for x in range(s):
			out.set_pixel(s - 1 - y, x, src.get_pixel(x, y))
	_blit_rect_overwrite(image, out, rect.position)
	_refresh_display_texture()
	_rebuild_selection_overlay()
	queue_redraw()
	_emit_edit_committed()
	return true


func _apply_rotate_ccw_selection() -> bool:
	if not _selection_rect_valid():
		return false
	var rect := _selection_rect
	if rect.size.x != rect.size.y:
		# Keep behavior predictable; 90deg rotate changes dimensions for non-square rects.
		return false
	_push_undo()
	var src := _extract_rect_from_image(image, rect)
	var s := rect.size.x
	var out := Image.create_empty(s, s, false, Image.FORMAT_RGBA8)
	for y in range(s):
		for x in range(s):
			out.set_pixel(y, s - 1 - x, src.get_pixel(x, y))
	_blit_rect_overwrite(image, out, rect.position)
	_refresh_display_texture()
	_rebuild_selection_overlay()
	queue_redraw()
	_emit_edit_committed()
	return true


func _apply_shift_selection(dir: Vector2i) -> bool:
	if not _selection_rect_valid():
		return false
	_push_undo()
	var rect := _selection_rect
	var src := _extract_rect_from_image(image, rect)
	var w := rect.size.x
	var h := rect.size.y
	var out := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var sx := posmod(x - dir.x, w)
			var sy := posmod(y - dir.y, h)
			out.set_pixel(x, y, src.get_pixel(sx, sy))
	_blit_rect_overwrite(image, out, rect.position)
	_refresh_display_texture()
	_rebuild_selection_overlay()
	queue_redraw()
	_emit_edit_committed()
	return true


func _blit_rect_overwrite(target: Image, src: Image, pos: Vector2i) -> void:
	if target == null or src == null:
		return
	for y in range(src.get_height()):
		for x in range(src.get_width()):
			var tx := pos.x + x
			var ty := pos.y + y
			if tx < 0 or ty < 0 or tx >= canvas_size or ty >= canvas_size:
				continue
			target.set_pixel(tx, ty, src.get_pixel(x, y))


# ---------------------------------------------------------------- Pixel plot

func _plot(p: Vector2i, color: Color) -> void:
	_plot_on(image, p, color)


func _plot_on(target: Image, p: Vector2i, color: Color) -> void:
	if p.x < 0 or p.y < 0 or p.x >= canvas_size or p.y >= canvas_size:
		return
	target.set_pixel(p.x, p.y, color)


func _line_plot(a: Vector2i, b: Vector2i, color: Color) -> void:
	_bresenham(a, b, func(x, y): _plot(Vector2i(x, y), color))


func _bresenham(a: Vector2i, b: Vector2i, cb: Callable) -> void:
	var x0: int = a.x
	var y0: int = a.y
	var x1: int = b.x
	var y1: int = b.y
	var dx: int = absi(x1 - x0)
	var dy: int = -absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	while true:
		cb.call(x0, y0)
		if x0 == x1 and y0 == y1:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


func _flood_fill(start: Vector2i, replacement: Color) -> void:
	if not _in_bounds(start):
		return
	var target := image.get_pixel(start.x, start.y)
	if _color_equal(target, replacement):
		return
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if not _in_bounds(p):
			continue
		if not _color_equal(image.get_pixel(p.x, p.y), target):
			continue
		image.set_pixel(p.x, p.y, replacement)
		stack.append(Vector2i(p.x + 1, p.y))
		stack.append(Vector2i(p.x - 1, p.y))
		stack.append(Vector2i(p.x, p.y + 1))
		stack.append(Vector2i(p.x, p.y - 1))


func _color_equal(a: Color, b: Color) -> bool:
	return is_equal_approx(a.r, b.r) and is_equal_approx(a.g, b.g) \
			and is_equal_approx(a.b, b.b) and is_equal_approx(a.a, b.a)
