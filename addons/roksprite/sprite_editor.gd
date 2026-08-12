@tool
extends Control

const CommandHistory := preload("res://addons/roksprite/command_history.gd")
const EditorModel := preload("res://addons/roksprite/editor_model.gd")
const PaletteProcessor := preload("res://addons/roksprite/palette_processor.gd")
const SessionStore := preload("res://addons/roksprite/session_store.gd")
const TilesetPngIO := preload("res://addons/roksprite/tileset_png_io.gd")

static var _session_owner_id: int = 0

@onready var _canvas: PixelCanvas = %PixelCanvas
@onready var _color_btn: ColorPickerButton = %ColorButton
@onready var _status: Label = %StatusLabel
@onready var _cursor_status: Label = %CursorLabel if has_node("%CursorLabel") else null
@onready var _zoom_spin: SpinBox = %ZoomSpin
@onready var _fit_v_btn: Button = %FitVBtn
@onready var _grid_toggle: Button = %GridToggle
@onready var _settings_btn: Button = %SettingsBtn
@onready var _sync_btn: Button = %SyncBtn if has_node("%SyncBtn") else null
@onready var _help_btn: Button = %HelpBtn if has_node("%HelpBtn") else null
@onready var _dev_refresh_btn: Button = %DevRefreshBtn if has_node("%DevRefreshBtn") else null
@onready var _palette_select: OptionButton = %PaletteSelect
@onready var _palette_derive_btn: Button = %PaletteDeriveBtn if has_node("%PaletteDeriveBtn") else null
@onready var _palette_remap_btn: Button = %PaletteRemapBtn if has_node("%PaletteRemapBtn") else null
@onready var _palette_import_btn: Button = %PaletteImportBtn if has_node("%PaletteImportBtn") else null
@onready var _palette_balance_btn: Button = %PaletteBalanceBtn if has_node("%PaletteBalanceBtn") else null
@onready var _swatch_scroll: ScrollContainer = %PaletteSwatchScroll if has_node("%PaletteSwatchScroll") else null
@onready var _palette_swatches: GridContainer = %PaletteSwatches
@onready var _main_area: Control = $"MarginContainer/VBox/MainArea" if has_node("MarginContainer/VBox/MainArea") else null
@onready var _swatch_center: Control = $"MarginContainer/VBox/SwatchCenter" if has_node("MarginContainer/VBox/SwatchCenter") else ($"MarginContainer/VBox/MainArea/SwatchCenter" if has_node("MarginContainer/VBox/MainArea/SwatchCenter") else null)
@onready var _swatch_panel: Control = $"MarginContainer/VBox/SwatchCenter/PaletteSwatchesPanel" if has_node("MarginContainer/VBox/SwatchCenter/PaletteSwatchesPanel") else ($"MarginContainer/VBox/MainArea/SwatchCenter/PaletteSwatchesPanel" if has_node("MarginContainer/VBox/MainArea/SwatchCenter/PaletteSwatchesPanel") else null)
@onready var _thumb_preview: TextureRect = %ThumbPreview
@onready var _thumb_scale_slider: HSlider = %ThumbScaleSlider
@onready var _thumb_repeat_toggle: CheckBox = %ThumbRepeatToggle if has_node("%ThumbRepeatToggle") else null
@onready var _thumb_overlay: Control = $"ThumbOverlay"
@onready var _thumb_vbox: VBoxContainer = $"ThumbOverlay/ThumbVBox" if has_node("ThumbOverlay/ThumbVBox") else null
@onready var _thumb_panel: PanelContainer = $"ThumbOverlay/ThumbVBox/ThumbPanel" if has_node("ThumbOverlay/ThumbVBox/ThumbPanel") else null
@onready var _thumb_scale_label: Label = $"ThumbOverlay/ThumbVBox/ThumbScaleRow/ThumbScaleLabel"
@onready var _canvas_panel: Control = $"MarginContainer/VBox/MainArea/CanvasStack/CanvasPanel" if has_node("MarginContainer/VBox/MainArea/CanvasStack/CanvasPanel") else null
@onready var _tile_overlay: Control = $"TileOverlay" if has_node("TileOverlay") else null
@onready var _tile_vbox: VBoxContainer = $"TileOverlay/TileVBox" if has_node("TileOverlay/TileVBox") else null
@onready var _tile_header: Label = $"TileOverlay/TileVBox/TileHeader" if has_node("TileOverlay/TileVBox/TileHeader") else null
@onready var _tile_list: ItemList = %TileList if has_node("%TileList") else null
@onready var _palette_picker_center: Control = $"MarginContainer/VBox/PalettePickerCenter"
@onready var _bottom_row: HBoxContainer = $"MarginContainer/VBox/PalettePickerCenter/BottomRow" if has_node("MarginContainer/VBox/PalettePickerCenter/BottomRow") else null
@onready var _palette_picker_row: HBoxContainer = $"MarginContainer/VBox/PalettePickerCenter/BottomRow/PalettePickerRow" if has_node("MarginContainer/VBox/PalettePickerCenter/BottomRow/PalettePickerRow") else null
@onready var _transform_row: HBoxContainer = $"MarginContainer/VBox/PalettePickerCenter/BottomRow/TransformRow" if has_node("MarginContainer/VBox/PalettePickerCenter/BottomRow/TransformRow") else null
@onready var _tool_row: HBoxContainer = $"MarginContainer/VBox/PalettePickerCenter/BottomRow/ToolRow" if has_node("MarginContainer/VBox/PalettePickerCenter/BottomRow/ToolRow") else null
@onready var _zoom_label: Label = $"MarginContainer/VBox/TopRowCenter/TopRowPanel/FileRow/ZoomLabel"
@onready var _transform_label: Label = $"MarginContainer/VBox/PalettePickerCenter/BottomRow/TransformRow/Pos"
@onready var _draw_label: Label = $"MarginContainer/VBox/PalettePickerCenter/BottomRow/ToolRow/Label"
@onready var _action_label: Label = $"MarginContainer/VBox/PalettePickerCenter/BottomRow/ActionRow/ActionLabel" if has_node("MarginContainer/VBox/PalettePickerCenter/BottomRow/ActionRow/ActionLabel") else null
@onready var _palette_label: Label = $"MarginContainer/VBox/PalettePickerCenter/BottomRow/PalettePickerRow/PaletteLabel"
@onready var _rect_btn: Button = %RectBtn
@onready var _rect_fill_btn: Button = %RectFillBtn
@onready var _flip_h_btn: Button = %FlipHBtn
@onready var _flip_v_btn: Button = %FlipVBtn
@onready var _rotate_btn: Button = %RotateBtn
@onready var _shift_up_btn: Button = %ShiftUpBtn
@onready var _shift_down_btn: Button = %ShiftDownBtn
@onready var _shift_left_btn: Button = %ShiftLeftBtn
@onready var _shift_right_btn: Button = %ShiftRightBtn
@onready var _copy_btn: Button = %CopyBtn if has_node("%CopyBtn") else null
@onready var _paste_btn: Button = %PasteBtn if has_node("%PasteBtn") else null
@onready var _select_btn: Button = %SelectBtn if has_node("%SelectBtn") else null

@onready var _tool_btns := {
	SpriteTools.Tool.PENCIL: %PencilBtn,
	SpriteTools.Tool.ERASER: %EraserBtn,
	SpriteTools.Tool.LINE: %LineBtn,
	SpriteTools.Tool.RECT_OUTLINE: %RectBtn,
	SpriteTools.Tool.BUCKET: %BucketBtn,
	SpriteTools.Tool.PICKER: %PickerBtn,
}

var _file_dialog: FileDialog
var _confirm_dialog: ConfirmationDialog
var _tile_delete_confirm_dialog: ConfirmationDialog
var _palette_action_confirm_dialog: ConfirmationDialog
var _palette_balance_dialog: ConfirmationDialog
var _palette_balance_sat_slider: HSlider
var _palette_balance_bri_slider: HSlider
var _palette_balance_con_slider: HSlider
var _palette_balance_sat_value: Label
var _palette_balance_bri_value: Label
var _palette_balance_con_value: Label
var _palette_balance_preview_check: CheckBox
var _palette_balance_target_select: OptionButton
var _new_set_dialog: ConfirmationDialog
var _new_set_margin: MarginContainer
var _new_set_grid: GridContainer
var _new_set_size_preset: OptionButton
var _new_set_size_x_spin: SpinBox
var _new_set_palette_select: OptionButton
var _new_set_export_cols_select: OptionButton
var _settings_dialog: ConfirmationDialog
var _settings_margin: MarginContainer
var _settings_grid: GridContainer
var _settings_tile_size_select: OptionButton
var _settings_zoom_spin: SpinBox
var _settings_palette_select: OptionButton
var _settings_grid_color_btn: ColorPickerButton
var _settings_canvas_gradient_start_btn: ColorPickerButton
var _settings_canvas_gradient_end_btn: ColorPickerButton
var _settings_canvas_gradient_enabled_check: CheckBox
var _settings_auto_sync_check: CheckBox
var _settings_auto_sync_interval_slider: HSlider
var _settings_auto_sync_interval_value_label: Label
var _settings_grid_thickness_spin: SpinBox
var _settings_cursor_scale_spin: SpinBox
var _settings_dynamic_cursor_contrast_check: CheckBox
var _settings_session_save_interval_spin: SpinBox
var _settings_pan_speed_spin: SpinBox
var _settings_show_grid_check: CheckBox
var _settings_show_dev_button_check: CheckBox
var _shortcuts_dialog: AcceptDialog
var _shortcuts_text: RichTextLabel
var _bottom_rows_stack: VBoxContainer
var _bottom_row_secondary: HBoxContainer
var _bottom_row_wrapped: bool = false
var _pending_size: int = 32
var _pending_palette_name: String = ""
var _pending_new_from_startup: bool = false
var _pending_new_resets_tileset: bool = false
var _pending_new_set_mode: int = 0
var _pending_load_path: String = ""
var _pending_export_columns: int = 0
var _pending_tile_delete_index: int = -1
var _pending_palette_action: int = 0
var _selected_palette_name: String = "None"
var _palette_colors: Array[Color] = []
var _selected_swatch_index: int = -1
var _thumb_tex: ImageTexture
var _thumb_scale: int = 4
var _thumb_repeat_tile: bool = false
var _tileset_images: Array[Image] = []
var _current_tile_index: int = -1
var _loading_tile_to_canvas: bool = false
var _tile_preview_textures: Array[Texture2D] = []
var _tile_drag_source_index: int = -1
var _tile_drag_active: bool = false
var _tile_drag_start_pos: Vector2 = Vector2.ZERO
var _swatch_size: int = 24
var _hover_pixel_valid: bool = false
var _hover_pixel: Vector2i = Vector2i.ZERO
var _rect_filled_mode: bool = false
var _last_rect_toggle_ms: int = -1000
var _icon_button_size_px: int = BASE_ICON_BUTTON_SIZE
var _default_tile_size: int = 32
var _default_zoom: int = 16
var _default_palette: String = ""
var _default_grid_color: Color = PixelCanvas.DEFAULT_GRID_COLOR
var _default_canvas_gradient_start: Color = DEFAULT_CANVAS_GRADIENT_START
var _default_canvas_gradient_end: Color = DEFAULT_CANVAS_GRADIENT_END
var _default_canvas_gradient_enabled: bool = true
var _default_grid_thickness: int = 1
var _default_cursor_scale: int = PixelCanvas.DEFAULT_CURSOR_SCALE
var _default_dynamic_cursor_contrast: bool = true
var _default_show_grid: bool = true
var _default_pan_speed: float = 1.0
var _show_dev_button: bool = false
var _status_flash_id: int = 0
var _status_base_modulate: Variant = Color(1, 1, 1, 1)
var _status_flash_tween: Tween = null
var _transform_button_tweens: Dictionary = {}
var _layout_warmup_frames: int = 0
var _new_set_sync_lock: bool = false
var _new_set_mode: int = 0
var _session_dirty: bool = false
var _session_dirty_at_ms: int = 0
var _session_save_interval_sec: int = 5
var _last_save_display: String = "--"
var _saved_tileset_path: String = ""
var _sync_target_dirty: bool = false
var _export_columns: int = 0
var _source_layout_locked: bool = false
var _source_cell_count: int = 0
var _source_rows: int = 0
var _auto_sync_enabled: bool = false
var _auto_sync_interval_sec: int = 10
var _last_auto_sync_at_ms: int = 0
var _copied_tile_image: Image = null
var _select_copy_drag_mode: bool = false
var _last_layout_poll_ms: int = 0
var _last_layout_size: Vector2i = Vector2i(-1, -1)
var _last_thumb_live_update_ms: int = 0
var _last_layout_signature: String = ""
var _thumbnail_dirty: bool = true
var _history := CommandHistory.new(EDITOR_UNDO_CAP)
var _tile_pulse_phase: float = 0.0
var _last_tile_pulse_update_ms: int = 0
var _palette_balance_original_colors: Array[Color] = []
var _palette_balance_preview_active: bool = false
var _palette_balance_original_tiles: Array[Image] = []
var _palette_balance_original_canvas_image: Image = null
var _palette_balance_original_tile_index: int = -1
var _palette_balance_preview_target: int = 0
var _canvas_gradient_bg: TextureRect = null

const ICON_FONT_PATH := "res://addons/roksprite/fonts/MaterialSymbolsOutlined-Regular.ttf"
const TOOL_BTN_BG_NORMAL := Color(0.18, 0.18, 0.2, 0.85)
const TOOL_BTN_BG_ACTIVE := Color(0.28, 0.38, 0.62, 0.95)
const TOOL_BTN_BORDER_NORMAL := Color(0.25, 0.25, 0.28, 1.0)
const TOOL_BTN_BORDER_ACTIVE := Color(0.84, 0.92, 1.0, 1.0)
const SELECT_COPY_BG_NORMAL := Color(0.14, 0.30, 0.16, 0.90)
const SELECT_COPY_BG_ACTIVE := Color(0.20, 0.56, 0.26, 0.98)
const SELECT_COPY_BORDER := Color(0.78, 1.0, 0.82, 1.0)
const SYNC_BTN_BG_DIRTY := Color(0.58, 0.16, 0.16, 0.95)
const SYNC_BTN_BG_CLEAN := Color(0.16, 0.50, 0.24, 0.95)
const SYNC_BTN_BORDER_DIRTY := Color(0.98, 0.58, 0.58, 1.0)
const SYNC_BTN_BORDER_CLEAN := Color(0.64, 1.0, 0.74, 1.0)
const TOOL_ICON_COLOR_ACTIVE := Color(0.95, 0.97, 1.0, 1.0)
const TOOL_ICON_COLOR_INACTIVE := Color(0.74, 0.76, 0.80, 1.0)
const BASE_ICON_FONT_SIZE := 22
const BASE_ICON_BUTTON_SIZE := 36
const ICON_FONT_TO_BUTTON_RATIO := 0.58
const BASE_SWATCH_SIZE := 34
const BASE_SWATCH_GAP := 2
const MAX_SWATCH_SIZE := 44
const MIN_SWATCH_SIZE := 20
const MAX_SWATCH_GAP := 3
const MIN_SWATCH_GAP := 1
const BASE_THUMB_PREVIEW_SIZE := 184
const BASE_THUMB_EXTRA_HEIGHT := 86
const BASE_THUMB_MARGIN_RIGHT := 16
const BASE_THUMB_MARGIN_TOP := 96
const BASE_THUMB_MARGIN_BOTTOM := 8
const BASE_THUMB_LABEL_FONT_SIZE := 14
const BASE_THUMB_SLIDER_MIN_WIDTH := 80
const BASE_TILE_WIDTH := 300
const BASE_TILE_HEIGHT := 260
const BASE_TILE_MARGIN_LEFT := 16
const BASE_TILE_MARGIN_TOP := 96
const BASE_TILE_MARGIN_BOTTOM := 8
const BASE_TILE_PREVIEW_SIZE := 56
const BASE_TILE_MIN_HEIGHT := 120
const TILE_PANEL_COLUMNS := 4
const TILE_PANEL_MIN_VISIBLE_ROWS := 4
const TILE_SELECTED_BORDER_OUTER := Color(1, 1, 1, 1)
const TILE_SELECTED_BORDER_THICKNESS := 2
const TILE_SELECTED_GAP_PX := 1
const TILE_SELECTED_FRAME_PAD := TILE_SELECTED_BORDER_THICKNESS + TILE_SELECTED_GAP_PX
const TILE_PULSE_REFRESH_MS := 100
const TILE_PULSE_SPEED := 1.0
const TILE_DRAG_START_DISTANCE := 6.0
const BASE_UI_TEXT_FONT_SIZE := 14
const BASE_UI_SMALL_LABEL_FONT_SIZE := 12
const BASE_STATUS_FONT_SIZE := 13
const BASE_SPINBOX_WIDTH := 76
const BASE_COLOR_BUTTON_WIDTH := 72
const BASE_COLOR_BUTTON_HEIGHT := 36
const BASE_PALETTE_SELECT_WIDTH := 180
const BASE_SETTINGS_SIDE := 420
const BASE_SETTINGS_PADDING := 16
const BASE_SETTINGS_ROW_GAP := 12
const BASE_SETTINGS_COL_GAP := 14
const BASE_SWATCH_ROW_HEIGHT := 44
const SETTINGS_FILE_PATH := "user://roksprite_settings.cfg"
const RECT_SYMBOL_FONT_RATIO := 0.58
const DEFAULT_CANVAS_GRADIENT_START := Color(0.16, 0.12, 0.28, 1.0)
const DEFAULT_CANVAS_GRADIENT_END := Color(0.09, 0.07, 0.19, 1.0)
const TILE_SIZE_PRESETS := [8, 16, 32, 64, 128, 256]
const EXPORT_COLUMN_PRESETS := [1, 2, 3, 4, 6, 8]
const TILE_PRESET_CUSTOM_INDEX := 6
const NEW_SET_MODE_STARTUP := 0
const NEW_SET_MODE_NEW := 1
const NEW_SET_MODE_LOAD := 2
const PALETTE_ACTION_NONE := 0
const PALETTE_ACTION_DERIVE := 1
const PALETTE_ACTION_REMAP := 2
const PALETTE_BALANCE_TARGET_PALETTE := 0
const PALETTE_BALANCE_TARGET_TILESET := 1
const SESSION_STATE_FILE_PATH := "user://roksprite/session-v2.dat"
const LAYOUT_POLL_INTERVAL_MS := 250
const THUMB_LIVE_REFRESH_MS := 2000
const MAX_DERIVED_PALETTE_COLORS := 256
const EDITOR_UNDO_CAP := 32
const SHORTCUTS_BBCODE := "[b]Keyboard[/b]\n" \
	+ "- Ctrl/Cmd + Z: Undo\n" \
	+ "- Ctrl/Cmd + Shift + Z or Ctrl/Cmd + Y: Redo\n" \
	+ "- Ctrl/Cmd + S: Sync to linked PNG\n" \
	+ "- Space: Pick color under cursor\n" \
	+ "- Apostrophe ('): Toggle grid\n" \
	+ "- Delete/Backspace: Delete active selection\n\n" \
	+ "[b]Mouse[/b]\n" \
	+ "- Mouse Wheel: Zoom in/out\n" \
	+ "- Middle Mouse Drag: Pan canvas\n" \
	+ "- Right Mouse Drag: Temporary erase\n" \
	+ "- Right-click Rotate button: 90° CCW\n" \
	+ "- Over Tiles panel: Mouse Wheel scrolls tile list\n\n" \
	+ "[b]Sync[/b]\n" \
	+ "- Save once to set Sync target path\n" \
	+ "- Sync button color: Red = pending changes, Green = up to date\n\n" \
	+ "[b]Tiles[/b]\n" \
	+ "- Drag tile onto + tile: Duplicate tile\n" \
	+ "- Right-click selected tile: Confirm delete/clear\n\n" \
	+ "[b]Palette Balance[/b]\n" \
	+ "- Right-click slider: Reset that slider to 0%\n\n" \
	+ "[b]Selection[/b]\n" \
	+ "- Select tool + drag: Create selection marquee\n" \
	+ "- Drag inside selection: Move selection\n" \
	+ "- Double-click Select: Enable copy-drag mode\n" \
	+ "- Select button color: Blue = move mode, Green = copy-drag mode\n\n" \
	+ "[b]Tool Toggle[/b]\n" \
	+ "- Double-click Square tool: Toggle outline/solid mode\n"

func _ready() -> void:
	_claim_session_owner()
	_ensure_bottom_row_secondary()
	_ensure_action_row()
	_ensure_palette_derive_button()
	_ensure_palette_remap_button()
	_ensure_palette_import_button()
	_ensure_palette_balance_button()
	_apply_button_glyphs()
	_configure_palette_row_layout()
	_load_preferences()
	_ensure_canvas_gradient_background()
	_apply_canvas_background_gradient()
	_apply_dev_button_visibility()
	_apply_hidpi_layout()
	if _thumb_overlay != null:
		_thumb_overlay.clip_contents = true
	if _tile_overlay != null:
		_tile_overlay.clip_contents = true
	resized.connect(_on_editor_resized)

	# Toolbar wiring -------------------------------------------------------
	%NewBtn.pressed.connect(_on_new_pressed)
	%LoadBtn.pressed.connect(_on_load_pressed)
	%SaveBtn.pressed.connect(_on_save_pressed)
	if _sync_btn != null:
		_sync_btn.pressed.connect(_on_sync_push_pressed)
	_settings_btn.pressed.connect(_on_settings_pressed)
	if _help_btn != null:
		_help_btn.pressed.connect(_on_help_pressed)
	if _dev_refresh_btn != null:
		_dev_refresh_btn.pressed.connect(_on_dev_refresh_pressed)
	if _palette_derive_btn != null and not _palette_derive_btn.pressed.is_connected(_on_palette_derive_pressed):
		_palette_derive_btn.pressed.connect(_on_palette_derive_pressed)
	if _palette_remap_btn != null and not _palette_remap_btn.pressed.is_connected(_on_palette_remap_pressed):
		_palette_remap_btn.pressed.connect(_on_palette_remap_pressed)
	if _palette_import_btn != null and not _palette_import_btn.pressed.is_connected(_on_palette_import_pressed):
		_palette_import_btn.pressed.connect(_on_palette_import_pressed)
	if _palette_balance_btn != null and not _palette_balance_btn.pressed.is_connected(_on_palette_balance_pressed):
		_palette_balance_btn.pressed.connect(_on_palette_balance_pressed)
	%UndoBtn.pressed.connect(_on_undo_pressed)
	%RedoBtn.pressed.connect(_on_redo_pressed)
	_fit_v_btn.pressed.connect(_on_fit_vertical_pressed)
	if _tile_list != null:
		_tile_list.item_selected.connect(_on_tile_list_selected)
		_tile_list.item_clicked.connect(_on_tile_list_item_clicked)
		_tile_list.gui_input.connect(_on_tile_list_gui_input)
	if _tile_overlay != null:
		_tile_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		if not _tile_overlay.mouse_entered.is_connected(_on_tile_overlay_mouse_entered):
			_tile_overlay.mouse_entered.connect(_on_tile_overlay_mouse_entered)
		if not _tile_overlay.mouse_exited.is_connected(_on_tile_overlay_mouse_exited):
			_tile_overlay.mouse_exited.connect(_on_tile_overlay_mouse_exited)
		if not _tile_overlay.gui_input.is_connected(_on_tile_overlay_gui_input):
			_tile_overlay.gui_input.connect(_on_tile_overlay_gui_input)

	if _canvas != null and not _canvas.has_drawn_pixels():
		_canvas.new_canvas(_default_tile_size)

	_sync_zoom_spin_limits()
	_zoom_spin.value = _canvas.zoom
	_zoom_spin.value_changed.connect(func(v: float): _canvas.set_zoom(int(v)); _update_status())
	_canvas.zoom_changed.connect(func(v: int): _sync_zoom_spin_limits(); _zoom_spin.set_value_no_signal(v); _update_status())
	_canvas.set_zoom(_default_zoom)
	_sync_zoom_spin_limits()
	_zoom_spin.set_value_no_signal(_canvas.zoom)
	_canvas.set_grid_style(_default_grid_color, _default_grid_thickness)
	_canvas.set_show_grid(_default_show_grid)
	_canvas.set_pan_speed(_default_pan_speed)
	_canvas.set_cursor_scale(_default_cursor_scale)
	_canvas.set_dynamic_cursor_contrast_enabled(_default_dynamic_cursor_contrast)
	_grid_toggle.button_pressed = _default_show_grid
	_grid_toggle.toggled.connect(_on_grid_toggled)
	_thumb_scale = int(_thumb_scale_slider.value)
	_thumb_scale_slider.value_changed.connect(_on_thumb_scale_changed)
	if _thumb_repeat_toggle != null:
		_thumb_repeat_tile = _thumb_repeat_toggle.button_pressed
		_thumb_repeat_toggle.toggled.connect(_on_thumb_repeat_toggled)
	if _swatch_scroll != null:
		_swatch_scroll.gui_input.connect(_on_swatch_scroll_gui_input)
	_configure_swatch_scroll_ui()
	_init_palette_dropdown()
	_try_restore_session_state()

	_color_btn.color = _canvas.primary_color
	_color_btn.color_changed.connect(func(c: Color): _canvas.primary_color = c; _canvas.refresh_cursor_preview(); _update_status())

	for tool_id in _tool_btns.keys():
		var btn: Button = _tool_btns[tool_id]
		btn.toggle_mode = true
		btn.pressed.connect(_on_tool_pressed.bind(tool_id))
	_rect_btn.gui_input.connect(_on_rect_btn_gui_input)
	_rect_fill_btn.visible = false
	_rect_fill_btn.disabled = true
	_tool_btns[SpriteTools.Tool.PENCIL].button_pressed = true
	_canvas.current_tool = SpriteTools.Tool.PENCIL
	_sync_rect_tool_mode_ui()
	_refresh_tool_button_visuals()
	_update_sync_button_visuals()

	# Transforms -----------------------------------------------------------
	%FlipHBtn.pressed.connect(_on_transform_flip_h)
	%FlipVBtn.pressed.connect(_on_transform_flip_v)
	%RotateBtn.pressed.connect(_on_transform_rotate_cw)
	%RotateBtn.gui_input.connect(_on_rotate_btn_gui_input)
	%ShiftUpBtn.pressed.connect(func(): _on_transform_shift(Vector2i(0, -1)))
	%ShiftDownBtn.pressed.connect(func(): _on_transform_shift(Vector2i(0, 1)))
	%ShiftLeftBtn.pressed.connect(func(): _on_transform_shift(Vector2i(-1, 0)))
	%ShiftRightBtn.pressed.connect(func(): _on_transform_shift(Vector2i(1, 0)))
	if _copy_btn != null:
		_copy_btn.pressed.connect(_on_action_copy_pressed)
	if _paste_btn != null:
		_paste_btn.pressed.connect(_on_action_paste_pressed)
	if _select_btn != null:
		_select_btn.toggled.connect(_on_action_select_toggled)
		_select_btn.gui_input.connect(_on_select_btn_gui_input)

	# Canvas signals -------------------------------------------------------
	_canvas.color_picked.connect(_on_color_picked)
	_canvas.quick_color_picked.connect(_on_quick_color_picked)
	_canvas.edit_started.connect(_on_canvas_edit_started)
	_canvas.edit_committed.connect(_on_canvas_edit_committed)
	_canvas.hover_pixel_changed.connect(_on_hover_pixel_changed)

	# File dialog ----------------------------------------------------------
	_file_dialog = FileDialog.new()
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.add_filter("*.png", "PNG image")
	add_child(_file_dialog)

	_confirm_dialog = ConfirmationDialog.new()
	_confirm_dialog.dialog_text = "This will replace current TileSet/canvas. Continue?"
	_confirm_dialog.confirmed.connect(_apply_pending_resize)
	_confirm_dialog.canceled.connect(_cancel_pending_resize)
	add_child(_confirm_dialog)
	_build_tile_delete_confirm_dialog()
	_build_palette_action_confirm_dialog()
	_build_palette_balance_dialog()
	_build_new_set_dialog()
	_build_settings_dialog()
	_build_shortcuts_dialog()
	_init_tileset_panel()

	_update_status()
	_status_base_modulate = _status.modulate
	_update_thumbnail_preview()
	_last_layout_size = Vector2i(int(round(size.x)), int(round(size.y)))
	_last_layout_poll_ms = Time.get_ticks_msec()
	_last_thumb_live_update_ms = _last_layout_poll_ms
	_layout_warmup_frames = 10
	_schedule_layout_refresh()


func _ensure_canvas_gradient_background() -> void:
	if _canvas_panel == null:
		return
	if _canvas_gradient_bg == null or not is_instance_valid(_canvas_gradient_bg):
		var existing := _canvas_panel.get_node_or_null("CanvasGradientBg") as TextureRect
		if existing != null:
			_canvas_gradient_bg = existing
		else:
			_canvas_gradient_bg = TextureRect.new()
			_canvas_gradient_bg.name = "CanvasGradientBg"
			_canvas_gradient_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_canvas_gradient_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			_canvas_gradient_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			_canvas_gradient_bg.stretch_mode = TextureRect.STRETCH_SCALE
			_canvas_gradient_bg.z_as_relative = true
			_canvas_gradient_bg.z_index = 0
			_canvas_panel.add_child(_canvas_gradient_bg)
	if _canvas_gradient_bg.get_parent() == _canvas_panel:
		_canvas_gradient_bg.z_as_relative = true
		_canvas_gradient_bg.z_index = 0
		_canvas_gradient_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_canvas_panel.move_child(_canvas_gradient_bg, 0)


func _apply_canvas_background_gradient() -> void:
	_ensure_canvas_gradient_background()
	if _canvas_gradient_bg == null or not is_instance_valid(_canvas_gradient_bg):
		return
	_canvas_gradient_bg.visible = _default_canvas_gradient_enabled
	if not _default_canvas_gradient_enabled:
		return
	var gradient_start := _safe_color(_default_canvas_gradient_start, DEFAULT_CANVAS_GRADIENT_START)
	var gradient_end := _safe_color(_default_canvas_gradient_end, DEFAULT_CANVAS_GRADIENT_END)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([gradient_start, gradient_end])
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	texture.width = 8
	texture.height = 256
	_canvas_gradient_bg.texture = texture


func _ensure_action_row() -> void:
	if _bottom_row == null:
		return
	var action_row: HBoxContainer = null
	if _palette_picker_center != null:
		var existing := _palette_picker_center.find_child("ActionRow", true, false)
		if existing is HBoxContainer:
			action_row = existing as HBoxContainer
	if action_row == null:
		action_row = HBoxContainer.new()
		action_row.name = "ActionRow"
		action_row.add_theme_constant_override("separation", 4)
		_bottom_row.add_child(action_row)
	if action_row == null:
		return
	var action_label := action_row.get_node_or_null("ActionLabel") as Label
	if action_label == null:
		action_label = Label.new()
		action_label.name = "ActionLabel"
		action_label.text = "ACTION :"
		action_row.add_child(action_label)
	var copy_btn := action_row.get_node_or_null("CopyBtn") as Button
	if copy_btn == null:
		copy_btn = Button.new()
		copy_btn.name = "CopyBtn"
		copy_btn.unique_name_in_owner = true
		copy_btn.custom_minimum_size = Vector2(72, 72)
		copy_btn.tooltip_text = "content_copy"
		copy_btn.text = "content_copy"
		action_row.add_child(copy_btn)
	var paste_btn := action_row.get_node_or_null("PasteBtn") as Button
	if paste_btn == null:
		paste_btn = Button.new()
		paste_btn.name = "PasteBtn"
		paste_btn.unique_name_in_owner = true
		paste_btn.custom_minimum_size = Vector2(72, 72)
		paste_btn.tooltip_text = "content_paste"
		paste_btn.text = "content_paste"
		action_row.add_child(paste_btn)
	var select_btn := action_row.get_node_or_null("SelectBtn") as Button
	if select_btn == null:
		select_btn = Button.new()
		select_btn.name = "SelectBtn"
		select_btn.unique_name_in_owner = true
		select_btn.custom_minimum_size = Vector2(72, 72)
		select_btn.tooltip_text = "select"
		select_btn.text = "select"
		select_btn.toggle_mode = true
		action_row.add_child(select_btn)
	_action_label = action_label
	_copy_btn = copy_btn
	_paste_btn = paste_btn
	_select_btn = select_btn


func _ensure_bottom_row_secondary() -> void:
	if _palette_picker_center == null:
		return
	if _bottom_rows_stack != null and is_instance_valid(_bottom_rows_stack) and _bottom_row_secondary != null and is_instance_valid(_bottom_row_secondary):
		return
	var stack_existing := _palette_picker_center.get_node_or_null("BottomRowsStack")
	if stack_existing is VBoxContainer:
		_bottom_rows_stack = stack_existing as VBoxContainer
	else:
		_bottom_rows_stack = VBoxContainer.new()
		_bottom_rows_stack.name = "BottomRowsStack"
		_bottom_rows_stack.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_bottom_rows_stack.alignment = BoxContainer.ALIGNMENT_CENTER
		_bottom_rows_stack.add_theme_constant_override("separation", 4)
		_palette_picker_center.add_child(_bottom_rows_stack)
	if _bottom_row != null and _bottom_row.get_parent() != _bottom_rows_stack:
		_bottom_row.reparent(_bottom_rows_stack)
	_bottom_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var existing := _bottom_rows_stack.get_node_or_null("BottomRowSecondary")
	if existing is HBoxContainer:
		_bottom_row_secondary = existing as HBoxContainer
	else:
		_bottom_row_secondary = HBoxContainer.new()
		_bottom_row_secondary.name = "BottomRowSecondary"
		_bottom_row_secondary.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_bottom_row_secondary.alignment = BoxContainer.ALIGNMENT_CENTER
		_bottom_row_secondary.add_theme_constant_override("separation", 8)
		_bottom_rows_stack.add_child(_bottom_row_secondary)
	_bottom_row_secondary.visible = false


func _ensure_palette_derive_button() -> void:
	if _palette_picker_row == null:
		return
	var btn := _palette_picker_row.get_node_or_null("PaletteDeriveBtn") as Button
	if btn == null:
		btn = Button.new()
		btn.name = "PaletteDeriveBtn"
		btn.unique_name_in_owner = true
		btn.custom_minimum_size = Vector2(41, 41)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.tooltip_text = "Derive palette from current loaded PNG"
		btn.text = "palette"
		_palette_picker_row.add_child(btn)
	_palette_derive_btn = btn


func _ensure_palette_remap_button() -> void:
	if _palette_picker_row == null:
		return
	var btn := _palette_picker_row.get_node_or_null("PaletteRemapBtn") as Button
	if btn == null:
		btn = Button.new()
		btn.name = "PaletteRemapBtn"
		btn.unique_name_in_owner = true
		btn.custom_minimum_size = Vector2(41, 41)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.tooltip_text = "Remap current tiles to selected palette"
		btn.text = "sync_alt"
		_palette_picker_row.add_child(btn)
	_palette_remap_btn = btn


func _ensure_palette_import_button() -> void:
	if _palette_picker_row == null:
		return
	var btn := _palette_picker_row.get_node_or_null("PaletteImportBtn") as Button
	if btn == null:
		btn = Button.new()
		btn.name = "PaletteImportBtn"
		btn.unique_name_in_owner = true
		btn.custom_minimum_size = Vector2(41, 41)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.tooltip_text = "Import palette .hex file"
		btn.text = "upload_file"
		_palette_picker_row.add_child(btn)
	_palette_import_btn = btn


func _ensure_palette_balance_button() -> void:
	if _palette_picker_row == null:
		return
	var btn := _palette_picker_row.get_node_or_null("PaletteBalanceBtn") as Button
	if btn == null:
		btn = Button.new()
		btn.name = "PaletteBalanceBtn"
		btn.unique_name_in_owner = true
		btn.custom_minimum_size = Vector2(41, 41)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.tooltip_text = "Adjust palette saturation/brightness/contrast"
		btn.text = "tune"
		_palette_picker_row.add_child(btn)
	_palette_balance_btn = btn


func _configure_palette_row_layout() -> void:
	if _palette_picker_row == null:
		return
	_update_bottom_row_wrapping()
	if _bottom_row_wrapped:
		_palette_picker_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_palette_picker_row.alignment = BoxContainer.ALIGNMENT_CENTER
	else:
		_palette_picker_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_palette_picker_row.alignment = BoxContainer.ALIGNMENT_CENTER


func _estimate_control_row_width(ctrl: Control) -> float:
	if ctrl == null:
		return 0.0
	if ctrl is BoxContainer:
		var box := ctrl as BoxContainer
		var sum_w := 0.0
		var count := 0
		for child in box.get_children():
			if not (child is Control):
				continue
			var c := child as Control
			if not c.visible:
				continue
			var cw := c.get_combined_minimum_size().x
			if cw <= 0.0:
				cw = c.size.x
			sum_w += maxf(0.0, cw)
			count += 1
		var sep := float(box.get_theme_constant("separation")) if box.has_theme_constant("separation") else 0.0
		if count > 1:
			sum_w += sep * float(count - 1)
		return sum_w
	var w := ctrl.get_combined_minimum_size().x
	if w <= 0.0:
		w = ctrl.size.x
	return maxf(0.0, w)


func _update_bottom_row_wrapping() -> void:
	if _bottom_row == null or _palette_picker_center == null:
		return
	_ensure_bottom_row_secondary()
	if _bottom_row_secondary == null:
		return
	var action_row := _action_label.get_parent() as HBoxContainer if _action_label != null else (_palette_picker_center.find_child("ActionRow", true, false) as HBoxContainer)
	if action_row == null or _palette_picker_row == null:
		return
	var row_one_required := _estimate_control_row_width(_transform_row) + _estimate_control_row_width(_tool_row) + _estimate_control_row_width(action_row) + _estimate_control_row_width(_palette_picker_row)
	var row_sep := float(_bottom_row.get_theme_constant("separation")) if _bottom_row.has_theme_constant("separation") else 8.0
	row_one_required += row_sep * 3.0 + 12.0
	var available := _palette_picker_center.size.x
	if available <= 0.0:
		available = _bottom_row.size.x
	if available <= 0.0:
		available = size.x
	var should_wrap := available > 0.0 and row_one_required > (available - 6.0)
	if should_wrap == _bottom_row_wrapped and action_row.get_parent() == (_bottom_row_secondary if _bottom_row_wrapped else _bottom_row):
		return
	_bottom_row_wrapped = should_wrap
	if should_wrap:
		if action_row.get_parent() != _bottom_row_secondary:
			action_row.reparent(_bottom_row_secondary)
		if _palette_picker_row.get_parent() != _bottom_row_secondary:
			_palette_picker_row.reparent(_bottom_row_secondary)
		_bottom_row_secondary.visible = true
		_bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
		_bottom_row_secondary.alignment = BoxContainer.ALIGNMENT_CENTER
	else:
		if action_row.get_parent() != _bottom_row:
			action_row.reparent(_bottom_row)
		if _palette_picker_row.get_parent() != _bottom_row:
			_palette_picker_row.reparent(_bottom_row)
		_bottom_row_secondary.visible = false
		_bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		_claim_session_owner()
		_schedule_layout_refresh()
	elif what == NOTIFICATION_PREDELETE \
			or what == NOTIFICATION_EXIT_TREE \
			or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_session_state()
		if _session_owner_id == get_instance_id():
			_session_owner_id = 0


func _schedule_layout_refresh() -> void:
	call_deferred("_run_layout_refresh_pass")


func _run_layout_refresh_pass() -> void:
	if not is_inside_tree():
		return
	_configure_palette_row_layout()
	_refresh_layout_if_needed(true)
	_last_layout_size = Vector2i(int(round(size.x)), int(round(size.y)))
	_last_layout_poll_ms = Time.get_ticks_msec()
	_init_tileset_panel()
	_refresh_tile_list_ui()
	_thumbnail_dirty = true
	_try_update_thumbnail_preview()


func _process(delta: float) -> void:
	var now := Time.get_ticks_msec()
	if _canvas != null:
		_canvas.set_wheel_zoom_blocked(_is_mouse_over_tile_overlay())
		if _canvas.has_method("set_custom_cursor_blocked"):
			_canvas.set_custom_cursor_blocked(_is_plugin_dialog_visible())
	if _layout_warmup_frames > 0:
		_layout_warmup_frames -= 1
		_refresh_layout_if_needed()
		_update_bottom_row_wrapping()
		_last_layout_size = Vector2i(int(round(size.x)), int(round(size.y)))
		_last_layout_poll_ms = now
	elif (now - _last_layout_poll_ms) >= LAYOUT_POLL_INTERVAL_MS:
		_last_layout_poll_ms = now
		var current_size := Vector2i(int(round(size.x)), int(round(size.y)))
		_last_layout_size = current_size
		_refresh_layout_if_needed()
		_update_bottom_row_wrapping()
	var save_interval_ms := maxi(1, _session_save_interval_sec) * 1000
	if _session_dirty and (now - _session_dirty_at_ms) >= save_interval_ms:
		_save_session_state()
	_try_auto_sync(now)
	_try_update_thumbnail_preview()
	_update_selected_tile_pulse_preview(now, delta)


func _on_thumb_scale_changed(value: float) -> void:
	_thumb_scale = maxi(1, int(value))
	_thumbnail_dirty = true
	_try_update_thumbnail_preview(true)
	_mark_session_dirty()


func _on_thumb_repeat_toggled(enabled: bool) -> void:
	_thumb_repeat_tile = enabled
	_thumbnail_dirty = true
	_try_update_thumbnail_preview(true)
	_mark_session_dirty()


func _on_canvas_edit_committed() -> void:
	_sync_zoom_spin_limits()
	_store_canvas_into_current_tile()
	# Refresh both preview surfaces from the same committed canvas image.
	_refresh_current_tile_preview_ui()
	_update_status()
	_thumbnail_dirty = true
	_try_update_thumbnail_preview(true)
	_mark_session_dirty()
	_mark_sync_target_dirty()


func _on_canvas_edit_started(before_image: Image) -> void:
	if _loading_tile_to_canvas or before_image == null:
		return
	var snapshot := _capture_editor_snapshot()
	snapshot["canvas_image"] = before_image.duplicate() as Image
	var tiles: Array[Image] = snapshot.get("tiles", [])
	if _current_tile_index >= 0 and _current_tile_index < tiles.size():
		tiles[_current_tile_index] = before_image.duplicate() as Image
		snapshot["tiles"] = tiles
	_history.push(snapshot)


func _init_tileset_panel() -> void:
	if _tile_list == null or _canvas == null or _canvas.image == null:
		return
	_configure_tileset_list_visuals()
	if _tileset_images.is_empty():
		_tileset_images.append(_canvas.image.duplicate() as Image)
	_current_tile_index = clampi(_current_tile_index, 0, _tileset_images.size() - 1)
	if _current_tile_index < 0:
		_current_tile_index = 0
	_refresh_tile_list_ui()


func _configure_tileset_list_visuals() -> void:
	if _tile_list == null:
		return
	var tile_list_w := int(round(_tile_list.size.x))
	var columns := maxi(1, TILE_PANEL_COLUMNS)
	var cell_w := int(floor((float(maxi(1, tile_list_w)) - 24.0) / float(columns)))
	# Fit target columns first, then size previews to match available cell width.
	var icon_size := clampi(maxi(22, cell_w - 6), 22, 96)
	var content_size := maxi(1, icon_size - (TILE_SELECTED_FRAME_PAD * 2))
	icon_size = content_size + (TILE_SELECTED_FRAME_PAD * 2)
	_tile_list.fixed_icon_size = Vector2i(icon_size, icon_size)
	_tile_list.max_columns = columns
	_tile_list.same_column_width = true
	_tile_list.icon_mode = ItemList.ICON_MODE_TOP
	_tile_list.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var row_gap := 8
	var min_rows := maxi(1, TILE_PANEL_MIN_VISIBLE_ROWS)
	var min_tile_list_h := (icon_size * min_rows) + (row_gap * (min_rows - 1)) + 10
	_tile_list.custom_minimum_size = Vector2(0, min_tile_list_h)
	_configure_tile_list_scroll_ui()


func _compute_integer_scaled_preview_size(src_size: int, max_size: int) -> int:
	src_size = maxi(1, src_size)
	max_size = maxi(1, max_size)
	if src_size == max_size:
		return src_size
	# Upscale path: integer multiples only.
	if src_size < max_size:
		var mul := maxi(1, int(floor(float(max_size) / float(src_size))))
		return src_size * mul
	# Downscale path: integer divisors only.
	var div := maxi(1, int(ceil(float(src_size) / float(max_size))))
	return maxi(1, int(floor(float(src_size) / float(div))))


func _configure_tile_list_scroll_ui() -> void:
	if _tile_list == null:
		return
	var vbar := _get_tile_list_v_scroll_bar()
	if vbar == null:
		return
	vbar.visible = false
	vbar.modulate = Color(1, 1, 1, 0)
	vbar.custom_minimum_size = Vector2.ZERO
	vbar.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _get_tile_list_v_scroll_bar() -> VScrollBar:
	if _tile_list == null:
		return null
	if _tile_list.has_method("get_v_scroll_bar"):
		var direct := _tile_list.get_v_scroll_bar()
		if direct != null:
			return direct
	return _find_v_scroll_bar_recursive(_tile_list)


func _find_v_scroll_bar_recursive(node: Node) -> VScrollBar:
	if node == null:
		return null
	for child in node.get_children():
		if child is VScrollBar:
			return child as VScrollBar
		var nested := _find_v_scroll_bar_recursive(child)
		if nested != null:
			return nested
	return null


func _is_mouse_over_tile_overlay() -> bool:
	if _tile_overlay == null or not _tile_overlay.visible:
		return false
	var vp := get_viewport()
	if vp == null:
		return false
	var mouse_pos := vp.get_mouse_position()
	return _tile_overlay.get_global_rect().has_point(mouse_pos)


func _make_tile_preview_texture(src: Image, is_selected: bool = false, border_color: Color = TILE_SELECTED_BORDER_OUTER) -> Texture2D:
	var icon_size := int(_tile_list.fixed_icon_size.x) if _tile_list != null and _tile_list.fixed_icon_size.x > 0 else clampi(maxi(BASE_TILE_PREVIEW_SIZE, _swatch_size + 10), 48, 96)
	var content_limit := maxi(1, icon_size - (TILE_SELECTED_FRAME_PAD * 2))
	if src == null or src.is_empty():
		var fallback := Image.create_empty(icon_size, icon_size, false, Image.FORMAT_RGBA8)
		fallback.fill(Color(0, 0, 0, 0))
		return ImageTexture.create_from_image(fallback)
	var size := mini(src.get_width(), src.get_height())
	size = maxi(1, size)
	var content_size := _compute_integer_scaled_preview_size(size, content_limit)
	var square := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	square.blit_rect(src, Rect2i(0, 0, size, size), Vector2i.ZERO)
	square.resize(content_size, content_size, Image.INTERPOLATE_NEAREST)
	var icon := Image.create_empty(icon_size, icon_size, false, Image.FORMAT_RGBA8)
	icon.fill(Color(0, 0, 0, 0))
	var content_offset := Vector2i((icon_size - content_size) / 2, (icon_size - content_size) / 2)
	icon.blit_rect(square, Rect2i(Vector2i.ZERO, Vector2i(content_size, content_size)), content_offset)
	if is_selected:
		var border := TILE_SELECTED_BORDER_THICKNESS
		icon.fill_rect(Rect2i(0, 0, icon_size, border), border_color)
		icon.fill_rect(Rect2i(0, icon_size - border, icon_size, border), border_color)
		icon.fill_rect(Rect2i(0, 0, border, icon_size), border_color)
		icon.fill_rect(Rect2i(icon_size - border, 0, border, icon_size), border_color)
	return ImageTexture.create_from_image(icon)


func _make_tile_add_texture() -> Texture2D:
	var preview_size := int(_tile_list.fixed_icon_size.x) if _tile_list != null and _tile_list.fixed_icon_size.x > 0 else clampi(maxi(BASE_TILE_PREVIEW_SIZE, _swatch_size + 10), 48, 96)
	var img := Image.create_empty(preview_size, preview_size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.20, 0.20, 0.22, 1.0))
	img.fill_rect(Rect2i(1, 1, preview_size - 2, preview_size - 2), Color(0.16, 0.16, 0.18, 1.0))
	var plus_color := Color(0.92, 0.94, 1.0, 1.0)
	var plus_thickness := maxi(2, int(round(preview_size * 0.10)))
	var arm := maxi(6, int(round(preview_size * 0.28)))
	var cx := preview_size / 2
	var cy := preview_size / 2
	img.fill_rect(Rect2i(cx - (plus_thickness / 2), cy - arm, plus_thickness, arm * 2), plus_color)
	img.fill_rect(Rect2i(cx - arm, cy - (plus_thickness / 2), arm * 2, plus_thickness), plus_color)
	return ImageTexture.create_from_image(img)


func _refresh_tile_list_ui() -> void:
	if _tile_list == null:
		return
	_configure_tileset_list_visuals()
	_tile_list.clear()
	_tile_preview_textures.clear()
	var selected_border := _current_selected_tile_border_color()
	for i in range(_tileset_images.size()):
		var is_selected := (i == _current_tile_index)
		var tex := _make_tile_preview_texture(_tileset_images[i], is_selected, selected_border)
		_tile_preview_textures.append(tex)
		_tile_list.add_item("", tex)
		_tile_list.set_item_tooltip(i, "Tile %d%s" % [i + 1, " (selected)" if is_selected else ""])
	var add_tex := _make_tile_add_texture()
	_tile_preview_textures.append(add_tex)
	_tile_list.add_item("", add_tex)
	_tile_list.set_item_tooltip(_tileset_images.size(), "Create Tile")
	if _current_tile_index >= 0 and _current_tile_index < _tileset_images.size():
		_tile_list.select(_current_tile_index)


func _refresh_current_tile_preview_ui() -> void:
	if _tile_list == null:
		return
	if _current_tile_index < 0 or _current_tile_index >= _tileset_images.size():
		return
	var src := _tileset_images[_current_tile_index]
	if src == null or src.is_empty():
		return
	var tex := _make_tile_preview_texture(src, true, _current_selected_tile_border_color())
	if _current_tile_index < _tile_preview_textures.size():
		_tile_preview_textures[_current_tile_index] = tex
	_tile_list.set_item_icon(_current_tile_index, tex)
	_tile_list.select(_current_tile_index)


func _current_selected_tile_border_color() -> Color:
	var pulse := 0.70 + (0.30 * (0.5 + 0.5 * sin(_tile_pulse_phase)))
	return Color(pulse, pulse, pulse, 1.0)


func _update_selected_tile_pulse_preview(now_ms: int, delta: float) -> void:
	_tile_pulse_phase += delta * TAU * TILE_PULSE_SPEED
	if _tile_list == null:
		return
	if _current_tile_index < 0 or _current_tile_index >= _tileset_images.size():
		return
	if (now_ms - _last_tile_pulse_update_ms) < TILE_PULSE_REFRESH_MS:
		return
	_last_tile_pulse_update_ms = now_ms
	var src := _tileset_images[_current_tile_index]
	if src == null or src.is_empty():
		return
	var tex := _make_tile_preview_texture(src, true, _current_selected_tile_border_color())
	if _current_tile_index >= 0 and _current_tile_index < _tile_preview_textures.size():
		_tile_preview_textures[_current_tile_index] = tex
	_tile_list.set_item_icon(_current_tile_index, tex)


func _store_canvas_into_current_tile() -> void:
	if _loading_tile_to_canvas:
		return
	if _canvas == null or _canvas.image == null:
		return
	if _current_tile_index < 0 or _current_tile_index >= _tileset_images.size():
		return
	_tileset_images[_current_tile_index] = _canvas.image.duplicate() as Image


func _load_tile_into_canvas(index: int) -> void:
	if _canvas == null:
		return
	if index < 0 or index >= _tileset_images.size():
		return
	var tile_img := _tileset_images[index]
	if tile_img == null:
		return
	_loading_tile_to_canvas = true
	_canvas.set_image_from_image(tile_img)
	_loading_tile_to_canvas = false
	_current_tile_index = index
	_refresh_tile_list_ui()
	_update_status()
	_update_thumbnail_preview()


func _on_tile_list_selected(index: int) -> void:
	if index == _tileset_images.size():
		_store_canvas_into_current_tile()
		_on_tile_add_pressed()
		return
	if index < 0 or index >= _tileset_images.size():
		return
	if index == _current_tile_index:
		return
	_store_canvas_into_current_tile()
	_load_tile_into_canvas(index)
	_mark_session_dirty()


func _on_tile_list_item_clicked(index: int, _at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_RIGHT:
		return
	if index < 0 or index >= _tileset_images.size():
		return
	if index != _current_tile_index:
		_on_tile_list_selected(index)
		return
	_request_tile_delete(index)


func _on_tile_overlay_gui_input(event: InputEvent) -> void:
	if _tile_list == null:
		return
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or (mb.button_index != MOUSE_BUTTON_WHEEL_UP and mb.button_index != MOUSE_BUTTON_WHEEL_DOWN):
		return
	var vbar := _get_tile_list_v_scroll_bar()
	if vbar != null:
		var step := maxi(8.0, float(_tile_list.fixed_icon_size.y + 8))
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			vbar.value -= step
		else:
			vbar.value += step
	accept_event()


func _on_tile_overlay_mouse_entered() -> void:
	if _canvas != null:
		_canvas.set_wheel_zoom_blocked(true)


func _on_tile_overlay_mouse_exited() -> void:
	if _canvas != null:
		_canvas.set_wheel_zoom_blocked(false)


func _on_tile_list_gui_input(event: InputEvent) -> void:
	if _tile_list == null:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var vbar := _get_tile_list_v_scroll_bar()
			if vbar != null:
				var step := maxi(8.0, float(_tile_list.fixed_icon_size.y + 8))
				if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
					vbar.value -= step
				else:
					vbar.value += step
			accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var hit_index := _tile_list.get_item_at_position(mb.position, true)
			if hit_index >= 0 and hit_index < _tileset_images.size():
				_tile_drag_source_index = hit_index
				_tile_drag_start_pos = mb.position
				_tile_drag_active = false
			else:
				_tile_drag_source_index = -1
				_tile_drag_active = false
		elif mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			if _tile_drag_source_index >= 0 and _tile_drag_active:
				var drop_index := _tile_list.get_item_at_position(mb.position, true)
				if drop_index == _tileset_images.size():
					_duplicate_tile_from_index(_tile_drag_source_index)
					accept_event()
			_tile_drag_source_index = -1
			_tile_drag_active = false
	elif event is InputEventMouseMotion:
		if _tile_drag_source_index < 0:
			return
		var mm := event as InputEventMouseMotion
		if (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			_tile_drag_source_index = -1
			_tile_drag_active = false
			return
		if not _tile_drag_active and mm.position.distance_to(_tile_drag_start_pos) >= TILE_DRAG_START_DISTANCE:
			_tile_drag_active = true


func _duplicate_tile_from_index(source_index: int) -> void:
	if source_index < 0 or source_index >= _tileset_images.size():
		return
	_store_canvas_into_current_tile()
	_push_editor_undo_snapshot()
	var src := _tileset_images[source_index]
	if src == null:
		return
	var copy := src.duplicate() as Image
	if copy == null:
		return
	_tileset_images.append(copy)
	_load_tile_into_canvas(_tileset_images.size() - 1)
	_mark_session_dirty()
	_mark_sync_target_dirty()
	_show_temporary_status("Tile duplicated", 0.9)


func _on_tile_add_pressed() -> void:
	_store_canvas_into_current_tile()
	_push_editor_undo_snapshot()
	var s := _canvas.canvas_size if _canvas != null else 32
	var img := Image.create_empty(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_tileset_images.append(img)
	_load_tile_into_canvas(_tileset_images.size() - 1)
	_mark_session_dirty()
	_mark_sync_target_dirty()


func _request_tile_delete(index: int) -> void:
	if index < 0 or index >= _tileset_images.size():
		return
	if _tile_delete_confirm_dialog == null or not is_instance_valid(_tile_delete_confirm_dialog):
		_build_tile_delete_confirm_dialog()
	_pending_tile_delete_index = index
	if _tileset_images.size() <= 1:
		_tile_delete_confirm_dialog.dialog_text = "Clear current tile?"
	else:
		_tile_delete_confirm_dialog.dialog_text = "Delete tile %d?" % (index + 1)
	_tile_delete_confirm_dialog.popup_centered(Vector2i(420, 170))


func _on_tile_delete_confirmed() -> void:
	if _pending_tile_delete_index < 0 or _pending_tile_delete_index >= _tileset_images.size():
		_pending_tile_delete_index = -1
		return
	_delete_tile_at_index(_pending_tile_delete_index)
	_pending_tile_delete_index = -1


func _on_tile_delete_canceled() -> void:
	_pending_tile_delete_index = -1


func _on_tile_delete_pressed() -> void:
	_delete_tile_at_index(_current_tile_index)


func _delete_tile_at_index(index: int) -> void:
	if _tileset_images.is_empty():
		return
	if index < 0 or index >= _tileset_images.size():
		return
	_store_canvas_into_current_tile()
	_push_editor_undo_snapshot()
	_current_tile_index = index
	if _tileset_images.size() == 1:
		var s := _canvas.canvas_size if _canvas != null else 32
		var blank := Image.create_empty(s, s, false, Image.FORMAT_RGBA8)
		blank.fill(Color(0, 0, 0, 0))
		_tileset_images[0] = blank
		_load_tile_into_canvas(0)
		_mark_session_dirty()
		_mark_sync_target_dirty()
		return
	if _current_tile_index < 0 or _current_tile_index >= _tileset_images.size():
		_current_tile_index = _tileset_images.size() - 1
	_tileset_images.remove_at(_current_tile_index)
	var next_index := mini(_current_tile_index, _tileset_images.size() - 1)
	_load_tile_into_canvas(next_index)
	_mark_session_dirty()
	_mark_sync_target_dirty()


# ---------------------------------------------------------------- Tools

func _apply_button_glyphs() -> void:
	if not ResourceLoader.exists(ICON_FONT_PATH):
		return
	var icon_font := load(ICON_FONT_PATH) as FontFile
	if icon_font == null:
		return
	var ui_scale := _get_ui_scale()
	var icon_button_size := maxi(BASE_ICON_BUTTON_SIZE, int(round(BASE_ICON_BUTTON_SIZE * ui_scale)))
	var icon_font_size := maxi(18, int(round(icon_button_size * ICON_FONT_TO_BUTTON_RATIO)))
	_icon_button_size_px = icon_button_size
	var glyphs := {
		%NewBtn: "",
		%LoadBtn: "",
		%SaveBtn: "",
		%SyncBtn: "",
		%GridToggle: "",
		%UndoBtn: "",
		%RedoBtn: "",
		%PencilBtn: "",
		%EraserBtn: "",
		%LineBtn: "",
		%RectBtn: "",
		%BucketBtn: "",
		%PickerBtn: "",
		%FlipHBtn: "",
		%FlipVBtn: "",
		%RotateBtn: "",
		%ShiftUpBtn: "",
		%ShiftDownBtn: "",
			%ShiftLeftBtn: "",
			%ShiftRightBtn: "",
			%SettingsBtn: "",
			%HelpBtn: "",
			%FitVBtn: "",
		}
	var tips := {
		%NewBtn: "New TileSet",
		%LoadBtn: "Load PNG into TileSet",
		%SaveBtn: "Save TileSet PNG",
		%SyncBtn: "Sync to linked PNG path (Ctrl/Cmd+S). Red dirty / green up to date",
		%GridToggle: "Toggle pixel grid overlay",
		%UndoBtn: "Undo (Ctrl/Cmd+Z)",
		%RedoBtn: "Redo (Ctrl/Cmd+Shift+Z or Ctrl/Cmd+Y)",
		%PencilBtn: "Pencil: draw pixels",
		%EraserBtn: "Eraser: erase pixels",
		%LineBtn: "Line: draw straight line",
		%RectBtn: "Square: outline/solid (double-click to toggle)",
		%BucketBtn: "Bucket: fill connected area",
		%PickerBtn: "Color Picker: pick from canvas (Space = quick pick under cursor)",
		%FlipHBtn: "Flip Horizontal (selection or canvas)",
		%FlipVBtn: "Flip Vertical (selection or canvas)",
		%RotateBtn: "Rotate 90° CW (selection/canvas). Right-click: 90° CCW",
		%ShiftUpBtn: "Shift Up (selection or canvas)",
		%ShiftDownBtn: "Shift Down (selection or canvas)",
		%ShiftLeftBtn: "Shift Left (selection or canvas)",
		%ShiftRightBtn: "Shift Right (selection or canvas)",
		%SettingsBtn: "Settings",
		%HelpBtn: "Shortcuts Help",
		%FitVBtn: "Fit canvas to view",
	}
	if _copy_btn != null:
		glyphs[_copy_btn] = ""
		tips[_copy_btn] = "Copy current tile"
	if _paste_btn != null:
		glyphs[_paste_btn] = ""
		tips[_paste_btn] = "Paste copied tile"
	if _select_btn != null:
		glyphs[_select_btn] = ""
		tips[_select_btn] = "Select: drag area, drag inside move, double-click copy-drag, Del/Backspace clear selection"
	if _dev_refresh_btn != null:
		glyphs[_dev_refresh_btn] = ""
		tips[_dev_refresh_btn] = "Dev Refresh: rebuild plugin UI/runtime state"
	if _palette_derive_btn != null:
		glyphs[_palette_derive_btn] = ""
		tips[_palette_derive_btn] = "Derive palette from current loaded PNG"
	if _palette_remap_btn != null:
		glyphs[_palette_remap_btn] = ""
		tips[_palette_remap_btn] = "Remap all tiles to selected palette"
	if _palette_import_btn != null:
		glyphs[_palette_import_btn] = ""
		tips[_palette_import_btn] = "Import palette .hex file into plugin palettes"
	if _palette_balance_btn != null:
		glyphs[_palette_balance_btn] = ""
		tips[_palette_balance_btn] = "Adjust palette saturation, brightness, contrast (preview before apply)"
	for btn in glyphs.keys():
		var b := btn as Button
		if b == null:
			continue
		b.tooltip_text = str(tips.get(btn, b.text))
		b.text = glyphs[btn]
		b.add_theme_font_override("font", icon_font)
		b.add_theme_font_size_override("font_size", icon_font_size)
		b.custom_minimum_size = Vector2(icon_button_size, icon_button_size)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_update_select_button_tooltip()
	_sync_rect_tool_mode_ui()
	_update_sync_button_visuals()


func _get_ui_scale() -> float:
	var scale := 1.0
	var theme_btn_font_size := get_theme_font_size("font_size", "Button")
	if theme_btn_font_size > 0:
		scale = maxf(scale, float(theme_btn_font_size) / 14.0)
	if DisplayServer.has_method("screen_get_scale"):
		var screen := DisplayServer.window_get_current_screen()
		var display_scale := DisplayServer.screen_get_scale(screen)
		if display_scale > 0.0:
			# Retina/backing scale can be much higher than intended UI scale inside editor plugins.
			# Cap its influence so controls don't become oversized and trigger premature row wrapping.
			scale = maxf(scale, minf(display_scale, 1.25))
	return clampf(scale, 1.0, 3.0)


func _apply_hidpi_layout() -> void:
	var ui_scale := _get_ui_scale()

	var swatch_scale := maxf(1.0, minf(ui_scale, 1.6))
	_swatch_size = clampi(int(round(BASE_SWATCH_SIZE * swatch_scale)), MIN_SWATCH_SIZE, MAX_SWATCH_SIZE)
	var swatch_gap := clampi(int(round(BASE_SWATCH_GAP * swatch_scale)), MIN_SWATCH_GAP, MAX_SWATCH_GAP)
	var swatch_row_h := maxi(BASE_SWATCH_ROW_HEIGHT, _swatch_size + (swatch_gap * 2) + 4)
	_palette_swatches.add_theme_constant_override("h_separation", swatch_gap)
	_palette_swatches.add_theme_constant_override("v_separation", swatch_gap)
	_palette_swatches.custom_minimum_size = Vector2(maxi(_swatch_size, _swatch_size + 8), swatch_row_h)
	_palette_swatches.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if _swatch_center != null:
		_swatch_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_swatch_center.custom_minimum_size = Vector2(0, swatch_row_h)
		if _swatch_center is BoxContainer:
			(_swatch_center as BoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
	if _swatch_panel != null:
		_swatch_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_swatch_panel.custom_minimum_size = Vector2(maxi(_swatch_size, _swatch_size + 8), swatch_row_h)
	if _swatch_scroll != null:
		_swatch_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_swatch_scroll.custom_minimum_size = Vector2(maxi(_swatch_size, _swatch_size + 8), swatch_row_h)
		_swatch_scroll.scroll_horizontal_custom_step = maxi(8, _swatch_size + 4)
		_swatch_scroll.queue_sort()
	_apply_swatch_row_layout(swatch_row_h, swatch_gap)
	if _swatch_panel != null:
		_swatch_panel.queue_sort()
	if _swatch_center != null:
		_swatch_center.queue_sort()

	var thumb_preview_size := maxi(BASE_THUMB_PREVIEW_SIZE, int(round(BASE_THUMB_PREVIEW_SIZE * ui_scale)))
	var thumb_w := thumb_preview_size
	var thumb_h := thumb_preview_size + maxi(BASE_THUMB_EXTRA_HEIGHT, int(round(BASE_THUMB_EXTRA_HEIGHT * ui_scale)))
	var thumb_right := maxi(BASE_THUMB_MARGIN_RIGHT, int(round(BASE_THUMB_MARGIN_RIGHT * ui_scale)))
	var thumb_top := maxi(BASE_THUMB_MARGIN_TOP, int(round(BASE_THUMB_MARGIN_TOP * ui_scale)))
	var thumb_bottom_margin := maxi(BASE_THUMB_MARGIN_BOTTOM, int(round(BASE_THUMB_MARGIN_BOTTOM * ui_scale)))
	if _thumb_overlay != null:
		_thumb_overlay.offset_left = -float(thumb_w + thumb_right)
		_thumb_overlay.offset_right = -float(thumb_right)
		_thumb_overlay.offset_top = float(thumb_top)
		_thumb_overlay.offset_bottom = float(thumb_top + thumb_h)
	if _thumb_vbox != null:
		_thumb_vbox.anchor_left = 0.0
		_thumb_vbox.anchor_top = 0.0
		_thumb_vbox.anchor_right = 0.0
		_thumb_vbox.anchor_bottom = 0.0
		_thumb_vbox.offset_left = 0.0
		_thumb_vbox.offset_top = 0.0
		_thumb_vbox.offset_right = float(thumb_w)
		_thumb_vbox.offset_bottom = float(thumb_h)
	if _thumb_panel != null:
		_thumb_panel.custom_minimum_size = Vector2(thumb_preview_size, thumb_preview_size)
		_thumb_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_thumb_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var tile_w := maxi(BASE_TILE_WIDTH, int(round(BASE_TILE_WIDTH * ui_scale)))
	var tile_left := maxi(BASE_TILE_MARGIN_LEFT, int(round(BASE_TILE_MARGIN_LEFT * ui_scale)))
	var tile_top := maxi(BASE_TILE_MARGIN_TOP, int(round(BASE_TILE_MARGIN_TOP * ui_scale)))
	if _main_area != null:
		tile_top = int(round((_main_area.global_position.y - global_position.y) + float(maxi(0, int(round(2.0 * ui_scale))))))
	if _canvas_panel != null:
		var canvas_top := int(round((_canvas_panel.global_position.y - global_position.y) + float(maxi(0, int(round(2.0 * ui_scale))))))
		tile_top = maxi(tile_top, canvas_top)
	var tile_bottom_margin := maxi(BASE_TILE_MARGIN_BOTTOM, int(round(BASE_TILE_MARGIN_BOTTOM * ui_scale)))
	var tile_overlay_h := 0.0
	if _tile_overlay != null:
		_tile_overlay.offset_left = float(tile_left)
		_tile_overlay.offset_right = float(tile_left + tile_w)
		_tile_overlay.offset_top = float(tile_top)
		var desired_tile_bottom := size.y - float(tile_bottom_margin)
		var max_tile_bottom := desired_tile_bottom
		var min_allowed_tile_bottom := _tile_overlay.offset_top
		if _canvas_panel != null:
			var canvas_bottom := ((_canvas_panel.global_position.y - global_position.y) + _canvas_panel.size.y) - float(tile_bottom_margin)
			if canvas_bottom > min_allowed_tile_bottom:
				max_tile_bottom = minf(max_tile_bottom, canvas_bottom)
		if _main_area != null:
			var main_area_bottom := ((_main_area.global_position.y - global_position.y) + _main_area.size.y) - float(tile_bottom_margin)
			if main_area_bottom > min_allowed_tile_bottom:
				max_tile_bottom = minf(max_tile_bottom, main_area_bottom)
		if _swatch_center != null:
			var swatch_top := (_swatch_center.global_position.y - global_position.y) - float(tile_bottom_margin)
			if swatch_top > 0.0:
				max_tile_bottom = minf(max_tile_bottom, swatch_top)
		if _palette_picker_center != null:
			var palette_picker_top := (_palette_picker_center.global_position.y - global_position.y) - float(tile_bottom_margin)
			if palette_picker_top > 0.0:
				max_tile_bottom = minf(max_tile_bottom, palette_picker_top)
		if max_tile_bottom <= min_allowed_tile_bottom:
			# During early startup/layout, global positions can be stale and collapse this panel.
			# Ignore invalid constraint and use viewport bottom until layout stabilizes.
			if _canvas_panel != null:
				max_tile_bottom = ((_canvas_panel.global_position.y - global_position.y) + _canvas_panel.size.y) - float(tile_bottom_margin)
			elif _main_area != null:
				max_tile_bottom = ((_main_area.global_position.y - global_position.y) + _main_area.size.y) - float(tile_bottom_margin)
			else:
				max_tile_bottom = desired_tile_bottom
		var bounded_bottom := minf(desired_tile_bottom, max_tile_bottom)
		_tile_overlay.offset_bottom = maxf(_tile_overlay.offset_top, bounded_bottom)
		tile_overlay_h = maxf(0.0, _tile_overlay.offset_bottom - _tile_overlay.offset_top)
	if _tile_vbox != null:
		_tile_vbox.anchor_left = 0.0
		_tile_vbox.anchor_top = 0.0
		_tile_vbox.anchor_right = 0.0
		_tile_vbox.anchor_bottom = 0.0
		_tile_vbox.offset_left = 0.0
		_tile_vbox.offset_top = 0.0
		_tile_vbox.offset_right = float(tile_w)
		_tile_vbox.offset_bottom = tile_overlay_h

	var label_font_size := maxi(BASE_THUMB_LABEL_FONT_SIZE, int(round(BASE_THUMB_LABEL_FONT_SIZE * ui_scale)))
	_thumb_scale_label.add_theme_font_size_override("font_size", label_font_size)
	if _thumb_repeat_toggle != null:
		_thumb_repeat_toggle.add_theme_font_size_override("font_size", label_font_size)
	if _tile_header != null:
		_tile_header.add_theme_font_size_override("font_size", label_font_size)
	if _tile_list != null:
		_tile_list.add_theme_font_size_override("font_size", label_font_size)
		_configure_tileset_list_visuals()
	_thumb_scale_slider.custom_minimum_size = Vector2(maxf(BASE_THUMB_SLIDER_MIN_WIDTH, BASE_THUMB_SLIDER_MIN_WIDTH * ui_scale), 0)

	var ui_text_font_size := maxi(BASE_UI_TEXT_FONT_SIZE, int(round(BASE_UI_TEXT_FONT_SIZE * ui_scale)))
	var ui_small_font_size := maxi(BASE_UI_SMALL_LABEL_FONT_SIZE, int(round(BASE_UI_SMALL_LABEL_FONT_SIZE * ui_scale)))
	var status_font_size := maxi(BASE_STATUS_FONT_SIZE, int(round(BASE_STATUS_FONT_SIZE * ui_scale)))

	_zoom_label.add_theme_font_size_override("font_size", ui_text_font_size)
	_palette_label.add_theme_font_size_override("font_size", ui_small_font_size)
	_transform_label.add_theme_font_size_override("font_size", ui_small_font_size)
	_draw_label.add_theme_font_size_override("font_size", ui_small_font_size)
	if _action_label != null:
		_action_label.add_theme_font_size_override("font_size", ui_small_font_size)
	_status.add_theme_font_size_override("font_size", status_font_size)
	if _cursor_status != null:
		_cursor_status.add_theme_font_size_override("font_size", status_font_size)

	var grid_icon_font_size := maxi(ui_text_font_size, int(round(float(_icon_button_size_px) * ICON_FONT_TO_BUTTON_RATIO)))
	_grid_toggle.add_theme_font_size_override("font_size", grid_icon_font_size)
	_zoom_spin.add_theme_font_size_override("font_size", ui_text_font_size)
	_palette_select.add_theme_font_size_override("font_size", ui_text_font_size)
	_color_btn.add_theme_font_size_override("font_size", ui_text_font_size)

	var spin_w := maxf(BASE_SPINBOX_WIDTH, BASE_SPINBOX_WIDTH * ui_scale)
	_zoom_spin.custom_minimum_size = Vector2(spin_w, 0)
	_color_btn.custom_minimum_size = Vector2(maxf(BASE_COLOR_BUTTON_WIDTH, BASE_COLOR_BUTTON_WIDTH * ui_scale), maxf(BASE_COLOR_BUTTON_HEIGHT, BASE_COLOR_BUTTON_HEIGHT * ui_scale))
	_palette_select.custom_minimum_size = Vector2(maxf(BASE_PALETTE_SELECT_WIDTH, BASE_PALETTE_SELECT_WIDTH * ui_scale), 0)
	_update_bottom_row_wrapping()


func _apply_swatch_row_layout(swatch_row_h: int, swatch_gap: int) -> void:
	var count := maxi(1, _palette_colors.size())
	var strip_w := (count * _swatch_size) + (maxi(0, count - 1) * swatch_gap)
	var padding := 8
	var desired_w := strip_w + padding
	var available_w := int(size.x) - 24
	if _swatch_center != null and _swatch_center.size.x > 0.0:
		available_w = mini(available_w, int(_swatch_center.size.x) - 8)
	var min_w := maxi(_swatch_size + padding, 64)
	var clamped_w := clampi(desired_w, min_w, maxi(min_w, available_w))
	if _swatch_panel != null:
		_swatch_panel.custom_minimum_size = Vector2(clamped_w, swatch_row_h)
	if _swatch_scroll != null:
		_swatch_scroll.custom_minimum_size = Vector2(clamped_w, swatch_row_h)
	if _palette_swatches != null:
		_palette_swatches.custom_minimum_size = Vector2(strip_w, swatch_row_h)


func _sync_zoom_spin_limits() -> void:
	if _zoom_spin == null or _canvas == null:
		return
	var max_zoom := _canvas.get_max_zoom_limit()
	_zoom_spin.min_value = PixelCanvas.MIN_ZOOM
	_zoom_spin.max_value = max_zoom
	if _canvas.zoom > max_zoom:
		_canvas.set_zoom(max_zoom)
	_zoom_spin.set_value_no_signal(_canvas.zoom)


func _on_editor_resized() -> void:
	_refresh_layout_if_needed(true)
	_try_update_thumbnail_preview(true)
	# Keep layout hot for a few frames after resize so tile panel catches dependent control shifts.
	_layout_warmup_frames = maxi(_layout_warmup_frames, 6)
	_last_layout_size = Vector2i(int(round(size.x)), int(round(size.y)))
	_last_layout_poll_ms = Time.get_ticks_msec()


func _quantize_layout(value: float) -> int:
	return int(round(value / 2.0)) * 2


func _build_layout_signature() -> String:
	var main_y := 0
	var main_h := 0
	if _main_area != null:
		main_y = _quantize_layout(_main_area.global_position.y - global_position.y)
		main_h = _quantize_layout(_main_area.size.y)
	var canvas_y := 0
	var canvas_h := 0
	if _canvas_panel != null:
		canvas_y = _quantize_layout(_canvas_panel.global_position.y - global_position.y)
		canvas_h = _quantize_layout(_canvas_panel.size.y)
	var swatch_y := 0
	if _swatch_center != null:
		swatch_y = _quantize_layout(_swatch_center.global_position.y - global_position.y)
	var picker_y := 0
	if _palette_picker_center != null:
		picker_y = _quantize_layout(_palette_picker_center.global_position.y - global_position.y)
	var ui_scale_i := int(round(_get_ui_scale() * 100.0))
	return "%d|%d|%d|%d|%d|%d|%d|%d|%d" % [
		_quantize_layout(size.x),
		_quantize_layout(size.y),
		ui_scale_i,
		main_y,
		main_h,
		canvas_y,
		canvas_h,
		swatch_y,
		picker_y
	]


func _refresh_layout_if_needed(force: bool = false) -> void:
	var sig := _build_layout_signature()
	if not force and sig == _last_layout_signature:
		return
	_last_layout_signature = sig
	_apply_hidpi_layout()
	_sync_zoom_spin_limits()
	_thumbnail_dirty = true


func _try_update_thumbnail_preview(force: bool = false) -> void:
	if _thumb_preview == null or _canvas == null:
		return
	var now := Time.get_ticks_msec()
	if not force and not _thumbnail_dirty:
		return
	if force or (now - _last_thumb_live_update_ms) >= THUMB_LIVE_REFRESH_MS:
		_update_thumbnail_preview()
		_thumbnail_dirty = false
		_last_thumb_live_update_ms = now


func _configure_swatch_scroll_ui() -> void:
	if _swatch_scroll == null:
		return
	_swatch_scroll.clip_contents = true
	for prop in _swatch_scroll.get_property_list():
		var prop_name := str(prop.get("name", ""))
		if prop_name == "horizontal_scroll_mode" or prop_name == "vertical_scroll_mode":
			# Force "show never" so no scrollbar track/handle is drawn.
			_swatch_scroll.set(prop_name, 2)
	var hbar := _swatch_scroll.get_h_scroll_bar()
	if hbar != null:
		hbar.visible = false
		hbar.modulate = Color(1, 1, 1, 0)
		hbar.custom_minimum_size = Vector2.ZERO
		hbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vbar := _swatch_scroll.get_v_scroll_bar()
	if vbar != null:
		vbar.visible = false
		vbar.modulate = Color(1, 1, 1, 0)
		vbar.custom_minimum_size = Vector2.ZERO
		vbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_swatch_scroll.scroll_vertical = 0


func _on_swatch_scroll_gui_input(event: InputEvent) -> void:
	if _swatch_scroll == null:
		return
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed:
		return
	if mb.button_index != MOUSE_BUTTON_WHEEL_UP and mb.button_index != MOUSE_BUTTON_WHEEL_DOWN:
		return
	var step := maxi(8, _swatch_size + 4)
	if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
		_swatch_scroll.scroll_horizontal -= step
	else:
		_swatch_scroll.scroll_horizontal += step
	_swatch_scroll.scroll_vertical = 0
	accept_event()


func _apply_dev_button_visibility() -> void:
	if _dev_refresh_btn != null:
		_dev_refresh_btn.visible = _show_dev_button


func _on_dev_refresh_pressed() -> void:
	_force_refresh_plugin()
	if _canvas != null:
		_canvas.grab_focus()
	_show_temporary_status("Plugin Refreshed", 1.2)


func _force_refresh_plugin() -> void:
	if _status_flash_tween != null:
		_status_flash_tween.kill()
		_status_flash_tween = null
	for key in _transform_button_tweens.keys():
		var tw := _transform_button_tweens[key] as Tween
		if tw != null:
			tw.kill()
	_transform_button_tweens.clear()
	_rebuild_runtime_dialogs()
	_load_preferences()
	_ensure_palette_derive_button()
	_ensure_palette_remap_button()
	_ensure_palette_import_button()
	_ensure_palette_balance_button()
	_apply_button_glyphs()
	if _palette_derive_btn != null and not _palette_derive_btn.pressed.is_connected(_on_palette_derive_pressed):
		_palette_derive_btn.pressed.connect(_on_palette_derive_pressed)
	if _palette_remap_btn != null and not _palette_remap_btn.pressed.is_connected(_on_palette_remap_pressed):
		_palette_remap_btn.pressed.connect(_on_palette_remap_pressed)
	if _palette_import_btn != null and not _palette_import_btn.pressed.is_connected(_on_palette_import_pressed):
		_palette_import_btn.pressed.connect(_on_palette_import_pressed)
	if _palette_balance_btn != null and not _palette_balance_btn.pressed.is_connected(_on_palette_balance_pressed):
		_palette_balance_btn.pressed.connect(_on_palette_balance_pressed)
	_apply_dev_button_visibility()
	_apply_hidpi_layout()
	_configure_swatch_scroll_ui()
	_init_palette_dropdown()
	_init_tileset_panel()
	_refresh_tile_list_ui()
	_canvas.set_zoom(_default_zoom)
	_zoom_spin.set_value_no_signal(_canvas.zoom)
	_canvas.set_grid_style(_default_grid_color, _default_grid_thickness)
	_canvas.set_show_grid(_default_show_grid)
	_canvas.set_pan_speed(_default_pan_speed)
	_canvas.set_cursor_scale(_default_cursor_scale)
	_canvas.set_dynamic_cursor_contrast_enabled(_default_dynamic_cursor_contrast)
	_grid_toggle.set_pressed_no_signal(_default_show_grid)
	_thumb_scale = int(_thumb_scale_slider.value)
	if _thumb_repeat_toggle != null:
		_thumb_repeat_toggle.set_pressed_no_signal(_thumb_repeat_tile)
	_hover_pixel_valid = false
	_hover_pixel = Vector2i.ZERO
	_status_base_modulate = _status.modulate
	_canvas.queue_redraw()
	_update_thumbnail_preview()
	_sync_rect_tool_mode_ui()
	_refresh_tool_button_visuals()
	_update_status()
	queue_redraw()


func _rebuild_runtime_dialogs() -> void:
	if _file_dialog != null and is_instance_valid(_file_dialog):
		_file_dialog.queue_free()
	_file_dialog = FileDialog.new()
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.add_filter("*.png", "PNG image")
	add_child(_file_dialog)

	if _confirm_dialog != null and is_instance_valid(_confirm_dialog):
		_confirm_dialog.queue_free()
	_confirm_dialog = ConfirmationDialog.new()
	_confirm_dialog.dialog_text = "This will replace current TileSet/canvas. Continue?"
	_confirm_dialog.confirmed.connect(_apply_pending_resize)
	_confirm_dialog.canceled.connect(_cancel_pending_resize)
	add_child(_confirm_dialog)
	_pending_tile_delete_index = -1
	_build_tile_delete_confirm_dialog()
	_pending_palette_action = PALETTE_ACTION_NONE
	_build_palette_action_confirm_dialog()
	_build_palette_balance_dialog()

	if _new_set_dialog != null and is_instance_valid(_new_set_dialog):
		_new_set_dialog.queue_free()
	_new_set_dialog = null
	_new_set_margin = null
	_new_set_grid = null
	_new_set_size_preset = null
	_new_set_size_x_spin = null
	_new_set_palette_select = null
	_new_set_export_cols_select = null
	_build_new_set_dialog()

	if _settings_dialog != null and is_instance_valid(_settings_dialog):
		_settings_dialog.queue_free()
	_settings_dialog = null
	_settings_margin = null
	_settings_grid = null
	_settings_tile_size_select = null
	_settings_zoom_spin = null
	_settings_palette_select = null
	_settings_grid_color_btn = null
	_settings_canvas_gradient_start_btn = null
	_settings_canvas_gradient_end_btn = null
	_settings_canvas_gradient_enabled_check = null
	_settings_auto_sync_check = null
	_settings_auto_sync_interval_slider = null
	_settings_auto_sync_interval_value_label = null
	_settings_grid_thickness_spin = null
	_settings_cursor_scale_spin = null
	_settings_dynamic_cursor_contrast_check = null
	_settings_session_save_interval_spin = null
	_settings_pan_speed_spin = null
	_settings_show_grid_check = null
	_settings_show_dev_button_check = null
	_build_settings_dialog()

	if _shortcuts_dialog != null and is_instance_valid(_shortcuts_dialog):
		_shortcuts_dialog.queue_free()
	_shortcuts_dialog = null
	_shortcuts_text = null
	_build_shortcuts_dialog()


func release_plugin_cursor() -> void:
	if _canvas != null and _canvas.has_method("release_custom_cursor"):
		_canvas.release_custom_cursor()


func _is_plugin_dialog_visible() -> bool:
	var dialogs := [
		_file_dialog,
		_confirm_dialog,
		_tile_delete_confirm_dialog,
		_palette_action_confirm_dialog,
		_palette_balance_dialog,
		_new_set_dialog,
		_settings_dialog,
		_shortcuts_dialog
	]
	for dialog in dialogs:
		if dialog != null and is_instance_valid(dialog) and dialog.visible:
			return true
	if _is_option_popup_visible(_palette_select):
		return true
	return false


func _is_option_popup_visible(select: OptionButton) -> bool:
	if select == null or not is_instance_valid(select):
		return false
	var popup := select.get_popup()
	return popup != null and is_instance_valid(popup) and popup.visible


func _build_palette_action_confirm_dialog() -> void:
	if _palette_action_confirm_dialog != null and is_instance_valid(_palette_action_confirm_dialog):
		_palette_action_confirm_dialog.queue_free()
	_palette_action_confirm_dialog = ConfirmationDialog.new()
	_palette_action_confirm_dialog.title = "Confirm Palette Action"
	_palette_action_confirm_dialog.dialog_text = "Apply palette action?"
	_palette_action_confirm_dialog.confirmed.connect(_on_palette_action_confirmed)
	_palette_action_confirm_dialog.canceled.connect(_on_palette_action_canceled)
	add_child(_palette_action_confirm_dialog)


func _build_tile_delete_confirm_dialog() -> void:
	if _tile_delete_confirm_dialog != null and is_instance_valid(_tile_delete_confirm_dialog):
		_tile_delete_confirm_dialog.queue_free()
	_tile_delete_confirm_dialog = ConfirmationDialog.new()
	_tile_delete_confirm_dialog.title = "Confirm Tile Delete"
	_tile_delete_confirm_dialog.dialog_text = "Delete current tile?"
	_tile_delete_confirm_dialog.confirmed.connect(_on_tile_delete_confirmed)
	_tile_delete_confirm_dialog.canceled.connect(_on_tile_delete_canceled)
	add_child(_tile_delete_confirm_dialog)


func _show_palette_action_confirm(action: int) -> void:
	if _palette_action_confirm_dialog == null or not is_instance_valid(_palette_action_confirm_dialog):
		_build_palette_action_confirm_dialog()
	_pending_palette_action = action
	match action:
		PALETTE_ACTION_DERIVE:
			_palette_action_confirm_dialog.dialog_text = "Derive palette from current loaded PNG and replace current palette swatches?"
		PALETTE_ACTION_REMAP:
			_palette_action_confirm_dialog.dialog_text = "Remap all current tiles to selected palette? This changes tile pixels."
		_:
			_palette_action_confirm_dialog.dialog_text = "Apply palette action?"
	_palette_action_confirm_dialog.popup_centered(Vector2i(620, 180))


func _on_palette_action_confirmed() -> void:
	match _pending_palette_action:
		PALETTE_ACTION_DERIVE:
			_apply_palette_derive()
		PALETTE_ACTION_REMAP:
			_apply_palette_remap()
	_pending_palette_action = PALETTE_ACTION_NONE


func _on_palette_action_canceled() -> void:
	_pending_palette_action = PALETTE_ACTION_NONE


func _build_palette_balance_dialog() -> void:
	if _palette_balance_dialog != null and is_instance_valid(_palette_balance_dialog):
		_palette_balance_dialog.queue_free()
	_palette_balance_dialog = ConfirmationDialog.new()
	_palette_balance_dialog.title = "Palette Balance"
	_palette_balance_dialog.min_size = Vector2i(520, 520)
	_palette_balance_dialog.get_ok_button().text = "Apply"
	_palette_balance_dialog.confirmed.connect(_on_palette_balance_confirmed)
	_palette_balance_dialog.canceled.connect(_on_palette_balance_canceled)
	_palette_balance_dialog.window_input.connect(_on_palette_balance_dialog_window_input)
	add_child(_palette_balance_dialog)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 8)
	_palette_balance_dialog.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var note := Label.new()
	note.text = "Adjust current palette then preview before applying."
	vbox.add_child(note)

	var target_row := HBoxContainer.new()
	target_row.add_theme_constant_override("separation", 10)
	vbox.add_child(target_row)
	var target_label := Label.new()
	target_label.text = "Target"
	target_row.add_child(target_label)
	_palette_balance_target_select = OptionButton.new()
	_palette_balance_target_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_palette_balance_target_select.add_item("Current Palette", PALETTE_BALANCE_TARGET_PALETTE)
	_palette_balance_target_select.add_item("Current TileSet", PALETTE_BALANCE_TARGET_TILESET)
	_palette_balance_target_select.selected = 0
	_palette_balance_target_select.item_selected.connect(_on_palette_balance_controls_changed)
	target_row.add_child(_palette_balance_target_select)

	_palette_balance_preview_check = CheckBox.new()
	_palette_balance_preview_check.text = "Preview changes"
	_palette_balance_preview_check.button_pressed = true
	_palette_balance_preview_check.toggled.connect(_on_palette_balance_controls_changed)
	vbox.add_child(_palette_balance_preview_check)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(grid)

	var sat_label := Label.new()
	sat_label.text = "Saturation"
	grid.add_child(sat_label)
	_palette_balance_sat_slider = HSlider.new()
	_palette_balance_sat_slider.min_value = -100.0
	_palette_balance_sat_slider.max_value = 100.0
	_palette_balance_sat_slider.step = 1.0
	_palette_balance_sat_slider.value = 0.0
	_palette_balance_sat_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_palette_balance_sat_slider.value_changed.connect(_on_palette_balance_controls_changed)
	_palette_balance_sat_slider.gui_input.connect(_on_palette_balance_slider_gui_input.bind(_palette_balance_sat_slider))
	grid.add_child(_palette_balance_sat_slider)
	_palette_balance_sat_value = Label.new()
	_palette_balance_sat_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(_palette_balance_sat_value)

	var bri_label := Label.new()
	bri_label.text = "Brightness"
	grid.add_child(bri_label)
	_palette_balance_bri_slider = HSlider.new()
	_palette_balance_bri_slider.min_value = -100.0
	_palette_balance_bri_slider.max_value = 100.0
	_palette_balance_bri_slider.step = 1.0
	_palette_balance_bri_slider.value = 0.0
	_palette_balance_bri_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_palette_balance_bri_slider.value_changed.connect(_on_palette_balance_controls_changed)
	_palette_balance_bri_slider.gui_input.connect(_on_palette_balance_slider_gui_input.bind(_palette_balance_bri_slider))
	grid.add_child(_palette_balance_bri_slider)
	_palette_balance_bri_value = Label.new()
	_palette_balance_bri_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(_palette_balance_bri_value)

	var con_label := Label.new()
	con_label.text = "Contrast"
	grid.add_child(con_label)
	_palette_balance_con_slider = HSlider.new()
	_palette_balance_con_slider.min_value = -100.0
	_palette_balance_con_slider.max_value = 100.0
	_palette_balance_con_slider.step = 1.0
	_palette_balance_con_slider.value = 0.0
	_palette_balance_con_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_palette_balance_con_slider.value_changed.connect(_on_palette_balance_controls_changed)
	_palette_balance_con_slider.gui_input.connect(_on_palette_balance_slider_gui_input.bind(_palette_balance_con_slider))
	grid.add_child(_palette_balance_con_slider)
	_palette_balance_con_value = Label.new()
	_palette_balance_con_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(_palette_balance_con_value)
	_update_palette_balance_value_labels()


func _on_palette_balance_pressed() -> void:
	if _palette_colors.is_empty():
		_show_temporary_status("No active palette to adjust", 1.6)
		return
	if _palette_balance_dialog == null or not is_instance_valid(_palette_balance_dialog):
		_build_palette_balance_dialog()
	_palette_balance_original_colors = _palette_colors.duplicate()
	_palette_balance_original_tiles = _clone_image_array(_tileset_images)
	_palette_balance_original_canvas_image = _canvas.image.duplicate() as Image if _canvas != null and _canvas.image != null else null
	_palette_balance_original_tile_index = _current_tile_index
	_palette_balance_preview_active = false
	_palette_balance_preview_target = PALETTE_BALANCE_TARGET_PALETTE
	if _palette_balance_target_select != null:
		_palette_balance_target_select.select(PALETTE_BALANCE_TARGET_PALETTE)
	_palette_balance_sat_slider.set_value_no_signal(0.0)
	_palette_balance_bri_slider.set_value_no_signal(0.0)
	_palette_balance_con_slider.set_value_no_signal(0.0)
	_palette_balance_preview_check.set_pressed_no_signal(true)
	_update_palette_balance_value_labels()
	var ui_scale := _get_ui_scale()
	var dialog_side := int(round(540.0 * ui_scale))
	_palette_balance_dialog.popup_centered(Vector2i(dialog_side, dialog_side))


func _on_palette_balance_controls_changed(_value: Variant = null) -> void:
	if _palette_balance_dialog == null or not is_instance_valid(_palette_balance_dialog):
		return
	_update_palette_balance_value_labels()
	var preview_enabled := _palette_balance_preview_check != null and _palette_balance_preview_check.button_pressed
	var target := _get_palette_balance_target()
	if _palette_balance_preview_active and _palette_balance_preview_target != target:
		_restore_palette_balance_original_target(_palette_balance_preview_target)
		_palette_balance_preview_active = false
	if not preview_enabled:
		if _palette_balance_preview_active:
			_restore_palette_balance_original_target(_palette_balance_preview_target)
			_palette_balance_preview_active = false
		return
	if target == PALETTE_BALANCE_TARGET_TILESET:
		_preview_balance_to_tileset()
	else:
		var preview_colors := _compute_palette_balance_colors(_palette_balance_original_colors)
		_apply_palette_colors_direct(preview_colors)
		_palette_balance_preview_active = true
		_palette_balance_preview_target = PALETTE_BALANCE_TARGET_PALETTE


func _on_palette_balance_confirmed() -> void:
	var target := _get_palette_balance_target()
	if target == PALETTE_BALANCE_TARGET_TILESET:
		_apply_balance_to_tileset_committed()
		return
	var base := _palette_balance_original_colors.duplicate()
	var final_colors := _compute_palette_balance_colors(base)
	if _palette_colors_equal(base, final_colors):
		_apply_palette_colors_direct(base)
		_palette_balance_preview_active = false
		return
	_apply_palette_colors_direct(base)
	_push_editor_undo_snapshot()
	_apply_palette_colors_direct(final_colors)
	_mark_session_dirty()
	_show_temporary_status("Palette balance applied to palette", 1.4)
	_palette_balance_original_colors = final_colors.duplicate()
	_palette_balance_preview_active = false


func _on_palette_balance_canceled() -> void:
	if _palette_balance_preview_active:
		_restore_palette_balance_original_target(_palette_balance_preview_target)
	_palette_balance_preview_active = false


func _on_palette_balance_slider_gui_input(event: InputEvent, slider: HSlider) -> void:
	if slider == null:
		return
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_RIGHT or not mb.pressed:
		return
	slider.value = 0.0
	accept_event()


func _on_palette_balance_dialog_window_input(event: InputEvent) -> void:
	if _palette_balance_dialog == null or not _palette_balance_dialog.visible:
		return
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_RIGHT or not mb.pressed:
		return
	var slider := _get_palette_balance_slider_under_mouse()
	if slider == null:
		return
	slider.value = 0.0
	get_viewport().set_input_as_handled()


func _get_palette_balance_slider_under_mouse() -> HSlider:
	var mouse_global := get_global_mouse_position()
	var sliders: Array[HSlider] = [_palette_balance_sat_slider, _palette_balance_bri_slider, _palette_balance_con_slider]
	for slider in sliders:
		if slider == null or not slider.visible:
			continue
		if slider.get_global_rect().has_point(mouse_global):
			return slider
	return null


func _update_palette_balance_value_labels() -> void:
	if _palette_balance_sat_value != null and _palette_balance_sat_slider != null:
		_palette_balance_sat_value.text = "%+d%%" % int(round(_palette_balance_sat_slider.value))
	if _palette_balance_bri_value != null and _palette_balance_bri_slider != null:
		_palette_balance_bri_value.text = "%+d%%" % int(round(_palette_balance_bri_slider.value))
	if _palette_balance_con_value != null and _palette_balance_con_slider != null:
		_palette_balance_con_value.text = "%+d%%" % int(round(_palette_balance_con_slider.value))


func _get_palette_balance_target() -> int:
	if _palette_balance_target_select == null:
		return PALETTE_BALANCE_TARGET_PALETTE
	var selected_idx := _palette_balance_target_select.selected
	if selected_idx < 0:
		return PALETTE_BALANCE_TARGET_PALETTE
	return int(_palette_balance_target_select.get_item_id(selected_idx))


func _restore_palette_balance_original_target(target: int) -> void:
	if target == PALETTE_BALANCE_TARGET_TILESET:
		_restore_original_tileset_after_balance()
	else:
		_apply_palette_colors_direct(_palette_balance_original_colors)


func _restore_original_tileset_after_balance() -> void:
	_tileset_images = _clone_image_array(_palette_balance_original_tiles)
	var restored_index := _palette_balance_original_tile_index
	if not _tileset_images.is_empty():
		restored_index = clampi(restored_index, 0, _tileset_images.size() - 1)
		_load_tile_into_canvas(restored_index)
		_current_tile_index = restored_index
	else:
		if _canvas != null and _palette_balance_original_canvas_image != null:
			_canvas.set_image_from_image(_palette_balance_original_canvas_image)
	_refresh_tile_list_ui()
	_thumbnail_dirty = true
	_try_update_thumbnail_preview(true)
	_update_status()


func _preview_balance_to_tileset() -> void:
	var sat_factor := 1.0 + (_palette_balance_sat_slider.value / 100.0)
	var bri_delta := _palette_balance_bri_slider.value / 100.0
	var con_factor := 1.0 + (_palette_balance_con_slider.value / 100.0)
	var result := _build_balanced_tileset_from_source(_palette_balance_original_tiles, _palette_balance_original_canvas_image, sat_factor, bri_delta, con_factor)
	if bool(result.get("has_tiles", false)):
		_tileset_images = result.get("tiles", [])
		if not _tileset_images.is_empty():
			var preview_index := clampi(_palette_balance_original_tile_index, 0, _tileset_images.size() - 1)
			_load_tile_into_canvas(preview_index)
			_current_tile_index = preview_index
	elif _canvas != null and result.has("canvas"):
		var img := result.get("canvas", null) as Image
		if img != null:
			_canvas.set_image_from_image(img)
	_refresh_tile_list_ui()
	_thumbnail_dirty = true
	_try_update_thumbnail_preview(true)
	_update_status()
	_palette_balance_preview_active = true
	_palette_balance_preview_target = PALETTE_BALANCE_TARGET_TILESET


func _apply_balance_to_tileset_committed() -> void:
	var sat_factor := 1.0 + (_palette_balance_sat_slider.value / 100.0)
	var bri_delta := _palette_balance_bri_slider.value / 100.0
	var con_factor := 1.0 + (_palette_balance_con_slider.value / 100.0)
	var result := _build_balanced_tileset_from_source(_palette_balance_original_tiles, _palette_balance_original_canvas_image, sat_factor, bri_delta, con_factor)
	var changed := bool(result.get("changed", false))
	_restore_original_tileset_after_balance()
	if not changed:
		_palette_balance_preview_active = false
		_show_temporary_status("No tile changes from current balance settings", 1.4)
		return
	_push_editor_undo_snapshot()
	if bool(result.get("has_tiles", false)):
		_tileset_images = result.get("tiles", [])
		if not _tileset_images.is_empty():
			var apply_index := clampi(_palette_balance_original_tile_index, 0, _tileset_images.size() - 1)
			_load_tile_into_canvas(apply_index)
			_current_tile_index = apply_index
	elif _canvas != null and result.has("canvas"):
		var canvas_img := result.get("canvas", null) as Image
		if canvas_img != null:
			_canvas.set_image_from_image(canvas_img)
	_refresh_tile_list_ui()
	_thumbnail_dirty = true
	_try_update_thumbnail_preview(true)
	_update_status()
	_mark_session_dirty()
	_mark_sync_target_dirty()
	_palette_balance_original_tiles = _clone_image_array(_tileset_images)
	_palette_balance_original_canvas_image = _canvas.image.duplicate() as Image if _canvas != null and _canvas.image != null else null
	_palette_balance_original_tile_index = _current_tile_index
	_palette_balance_preview_active = false
	_show_temporary_status("Palette balance applied to tileset", 1.5)


func _build_balanced_tileset_from_source(source_tiles: Array[Image], source_canvas: Image, sat_factor: float, bri_delta: float, con_factor: float) -> Dictionary:
	var out := {}
	var balanced_tiles: Array[Image] = []
	var changed := false
	for src in source_tiles:
		if src == null or src.is_empty():
			balanced_tiles.append(src)
			continue
		var adjusted := _balance_image(src, sat_factor, bri_delta, con_factor)
		balanced_tiles.append(adjusted.get("image", src))
		changed = changed or bool(adjusted.get("changed", false))
	if not balanced_tiles.is_empty():
		out["has_tiles"] = true
		out["tiles"] = balanced_tiles
		out["changed"] = changed
		return out
	out["has_tiles"] = false
	if source_canvas != null and not source_canvas.is_empty():
		var adjusted_canvas := _balance_image(source_canvas, sat_factor, bri_delta, con_factor)
		out["canvas"] = adjusted_canvas.get("image", source_canvas)
		out["changed"] = bool(adjusted_canvas.get("changed", false))
	else:
		out["changed"] = false
	return out


func _balance_image(source: Image, sat_factor: float, bri_delta: float, con_factor: float) -> Dictionary:
	var out := source.duplicate() as Image
	if out == null or out.is_empty():
		return {"image": out, "changed": false}
	var changed := false
	var w := out.get_width()
	var h := out.get_height()
	for y in range(h):
		for x in range(w):
			var c := out.get_pixel(x, y)
			var balanced := _balance_color(c, sat_factor, bri_delta, con_factor)
			if not _colors_approx_equal(c, balanced):
				changed = true
			out.set_pixel(x, y, balanced)
	return {"image": out, "changed": changed}


func _balance_color(color: Color, sat_factor: float, bri_delta: float, con_factor: float) -> Color:
	# Better perceptual behavior: do color balance in linear light.
	var lr := _srgb_to_linear(color.r)
	var lg := _srgb_to_linear(color.g)
	var lb := _srgb_to_linear(color.b)
	var luma := (0.2126 * lr) + (0.7152 * lg) + (0.0722 * lb)

	# Saturation: preserve luminance and scale chroma from gray axis.
	lr = luma + ((lr - luma) * sat_factor)
	lg = luma + ((lg - luma) * sat_factor)
	lb = luma + ((lb - luma) * sat_factor)

	# Brightness: exposure-like scaling in linear light.
	var exposure := pow(2.0, bri_delta * 2.0)
	lr *= exposure
	lg *= exposure
	lb *= exposure

	# Contrast: around perceptual midpoint converted to linear.
	var pivot := _srgb_to_linear(0.5)
	lr = ((lr - pivot) * con_factor) + pivot
	lg = ((lg - pivot) * con_factor) + pivot
	lb = ((lb - pivot) * con_factor) + pivot

	lr = clampf(lr, 0.0, 1.0)
	lg = clampf(lg, 0.0, 1.0)
	lb = clampf(lb, 0.0, 1.0)
	return Color(_linear_to_srgb(lr), _linear_to_srgb(lg), _linear_to_srgb(lb), color.a)


func _colors_approx_equal(a: Color, b: Color) -> bool:
	if absf(a.r - b.r) > 0.0001:
		return false
	if absf(a.g - b.g) > 0.0001:
		return false
	if absf(a.b - b.b) > 0.0001:
		return false
	if absf(a.a - b.a) > 0.0001:
		return false
	return true


func _compute_palette_balance_colors(base: Array[Color]) -> Array[Color]:
	var out: Array[Color] = []
	if base.is_empty():
		return out
	var sat_factor := 1.0 + (_palette_balance_sat_slider.value / 100.0)
	var bri_delta := _palette_balance_bri_slider.value / 100.0
	var con_delta := _palette_balance_con_slider.value / 100.0
	var con_factor := pow(2.0, con_delta * 1.5)
	for color in base:
		out.append(_balance_color(color, sat_factor, bri_delta, con_factor))
	return out


func _apply_palette_colors_direct(colors: Array[Color]) -> void:
	_palette_colors = colors.duplicate()
	_rebuild_palette_swatches(_palette_colors)
	_update_status()


func _palette_colors_equal(a: Array[Color], b: Array[Color]) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if absf(a[i].r - b[i].r) > 0.0001:
			return false
		if absf(a[i].g - b[i].g) > 0.0001:
			return false
		if absf(a[i].b - b[i].b) > 0.0001:
			return false
		if absf(a[i].a - b[i].a) > 0.0001:
			return false
	return true


func _build_shortcuts_dialog() -> void:
	_shortcuts_dialog = AcceptDialog.new()
	_shortcuts_dialog.title = "Shortcuts"
	_shortcuts_dialog.get_ok_button().text = "Close"
	add_child(_shortcuts_dialog)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	_shortcuts_dialog.add_child(margin)

	_shortcuts_text = RichTextLabel.new()
	_shortcuts_text.bbcode_enabled = true
	_shortcuts_text.fit_content = false
	_shortcuts_text.scroll_active = true
	_shortcuts_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shortcuts_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_shortcuts_text.custom_minimum_size = Vector2(640, 500)
	_shortcuts_text.text = SHORTCUTS_BBCODE
	margin.add_child(_shortcuts_text)


func _on_help_pressed() -> void:
	if _shortcuts_dialog == null or not is_instance_valid(_shortcuts_dialog):
		_build_shortcuts_dialog()
	if _shortcuts_dialog == null:
		return
	var ui_scale := _get_ui_scale()
	var w := int(round(760 * ui_scale))
	var h := int(round(620 * ui_scale))
	_shortcuts_dialog.popup_centered(Vector2i(w, h))


func _show_temporary_status(message: String, duration_sec: float = 1.2) -> void:
	if _status == null:
		return
	_status_flash_id += 1
	var flash_id := _status_flash_id
	if _status_flash_tween != null:
		_status_flash_tween.kill()
		_status_flash_tween = null
	_status.text = message
	_status.modulate = Color(1.0, 0.92, 0.2, 1.0)
	_status_flash_tween = create_tween()
	_status_flash_tween.set_loops()
	_status_flash_tween.tween_property(_status, "modulate:a", 0.4, 0.18)
	_status_flash_tween.tween_property(_status, "modulate:a", 1.0, 0.18)
	var tree := get_tree()
	if tree == null:
		return
	await tree.create_timer(duration_sec).timeout
	if flash_id != _status_flash_id:
		return
	if _status_flash_tween != null:
		_status_flash_tween.kill()
		_status_flash_tween = null
	var restore_color := _status_base_modulate
	if typeof(restore_color) != TYPE_COLOR:
		restore_color = Color(1, 1, 1, 1)
	_status.modulate = restore_color
	_update_status()

func _on_tool_pressed(tool_id: int) -> void:
	if _select_btn != null and _select_btn.button_pressed:
		_select_btn.set_pressed_no_signal(false)
		if _canvas != null:
			_canvas.set_selection_mode(false)
	if _select_copy_drag_mode:
		_select_copy_drag_mode = false
		if _canvas != null:
			_canvas.set_selection_copy_move_mode(false)
		_update_select_button_tooltip()
	for t in _tool_btns.keys():
		(_tool_btns[t] as Button).button_pressed = (t == tool_id)
	if tool_id == SpriteTools.Tool.RECT_OUTLINE:
		_canvas.current_tool = SpriteTools.Tool.RECT_FILLED if _rect_filled_mode else SpriteTools.Tool.RECT_OUTLINE
	else:
		_canvas.current_tool = tool_id
	_refresh_tool_button_visuals()
	_update_status()


func _refresh_tool_button_visuals() -> void:
	var select_active := (_select_btn != null and _select_btn.button_pressed)
	for k in _tool_btns.keys():
		var tool_id: int = int(k)
		var btn := _tool_btns[tool_id] as Button
		if btn == null:
			continue
		var active: bool = false
		if not select_active:
			if tool_id == SpriteTools.Tool.RECT_OUTLINE:
				active = _canvas.current_tool == SpriteTools.Tool.RECT_OUTLINE \
						or _canvas.current_tool == SpriteTools.Tool.RECT_FILLED
			else:
				active = (tool_id == _canvas.current_tool)
		var normal := _make_tool_style(active, false)
		var hover := _make_tool_style(active, true)
		var pressed := _make_tool_style(active, true)
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_stylebox_override("hover_pressed", pressed)
		btn.add_theme_stylebox_override("focus", pressed)
		_apply_button_font_color(btn, active)
	if _select_btn != null:
		var copy_mode := _get_select_copy_drag_mode()
		var sel_normal := _make_select_style(select_active, false, copy_mode)
		var sel_hover := _make_select_style(select_active, true, copy_mode)
		var sel_pressed := _make_select_style(true, true, copy_mode)
		_select_btn.add_theme_stylebox_override("normal", sel_normal)
		_select_btn.add_theme_stylebox_override("hover", sel_hover)
		_select_btn.add_theme_stylebox_override("pressed", sel_pressed)
		_select_btn.add_theme_stylebox_override("hover_pressed", sel_pressed)
		_select_btn.add_theme_stylebox_override("focus", sel_pressed)
		_apply_button_font_color(_select_btn, select_active)


func _make_tool_style(active: bool, hover: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = TOOL_BTN_BG_ACTIVE if active else TOOL_BTN_BG_NORMAL
	if hover and not active:
		style.bg_color = style.bg_color.lightened(0.08)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = TOOL_BTN_BORDER_ACTIVE if active else TOOL_BTN_BORDER_NORMAL
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	return style


func _make_select_style(active: bool, hover: bool, copy_mode: bool) -> StyleBoxFlat:
	if not copy_mode:
		return _make_tool_style(active, hover)
	var style := StyleBoxFlat.new()
	style.bg_color = SELECT_COPY_BG_ACTIVE if active else SELECT_COPY_BG_NORMAL
	if hover and not active:
		style.bg_color = style.bg_color.lightened(0.08)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = SELECT_COPY_BORDER if active else TOOL_BTN_BORDER_NORMAL
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	return style


func _apply_button_font_color(btn: Button, active: bool) -> void:
	if btn == null:
		return
	var c := TOOL_ICON_COLOR_ACTIVE if active else TOOL_ICON_COLOR_INACTIVE
	btn.add_theme_color_override("font_color", c)
	btn.add_theme_color_override("font_hover_color", c)
	btn.add_theme_color_override("font_pressed_color", c)
	btn.add_theme_color_override("font_hover_pressed_color", c)
	btn.add_theme_color_override("font_focus_color", c)
	btn.add_theme_color_override("font_disabled_color", c)


func _on_color_picked(c: Color) -> void:
	_apply_picked_color(c)
	_on_tool_pressed(SpriteTools.Tool.PENCIL)


func _on_quick_color_picked(c: Color) -> void:
	_apply_picked_color(c)
	# Space is a temporary picker: preserve the active drawing/selection tool.
	_update_status()


func _apply_picked_color(c: Color) -> void:
	_color_btn.color = c
	_canvas.primary_color = c
	_canvas.refresh_cursor_preview()


func _on_hover_pixel_changed(pixel: Vector2i, valid: bool) -> void:
	_hover_pixel = pixel
	_hover_pixel_valid = valid
	_update_status()


func _on_fit_vertical_pressed() -> void:
	_canvas.zoom_fit_screen()
	_update_status()


func _on_transform_flip_h() -> void:
	_canvas.flip_horizontal()
	_pulse_transform_button(_flip_h_btn)


func _on_transform_flip_v() -> void:
	_canvas.flip_vertical()
	_pulse_transform_button(_flip_v_btn)


func _on_transform_rotate_cw() -> void:
	_canvas.rotate_90_cw()
	_pulse_transform_button(_rotate_btn)


func _on_transform_rotate_ccw() -> void:
	_canvas.rotate_90_ccw()
	_pulse_transform_button(_rotate_btn)


func _on_rotate_btn_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_RIGHT or not mb.pressed:
		return
	_on_transform_rotate_ccw()
	accept_event()


func _on_transform_shift(dir: Vector2i) -> void:
	_canvas.shift(dir)
	match dir:
		Vector2i(0, -1):
			_pulse_transform_button(_shift_up_btn)
		Vector2i(0, 1):
			_pulse_transform_button(_shift_down_btn)
		Vector2i(-1, 0):
			_pulse_transform_button(_shift_left_btn)
		Vector2i(1, 0):
			_pulse_transform_button(_shift_right_btn)


func _on_action_copy_pressed() -> void:
	if _canvas == null or _canvas.image == null:
		return
	_copied_tile_image = _canvas.image.duplicate() as Image
	if _copied_tile_image == null:
		return
	_show_temporary_status("Tile copied.", 1.0)


func _on_action_paste_pressed() -> void:
	if _canvas == null or _canvas.image == null:
		return
	if _copied_tile_image == null or _copied_tile_image.is_empty():
		_show_temporary_status("Nothing copied.", 1.0)
		return
	var s := _canvas.canvas_size
	var pasted := _copied_tile_image.duplicate() as Image
	if pasted == null:
		return
	if pasted.get_width() != pasted.get_height():
		var min_s := mini(pasted.get_width(), pasted.get_height())
		pasted = pasted.get_region(Rect2i(0, 0, min_s, min_s))
	if pasted.get_width() != s:
		pasted.resize(s, s, Image.INTERPOLATE_NEAREST)
	if pasted.get_format() != Image.FORMAT_RGBA8:
		pasted.convert(Image.FORMAT_RGBA8)
	_canvas.set_image_from_image(pasted, true)
	_show_temporary_status("Tile pasted.", 1.0)


func _on_action_select_toggled(enabled: bool) -> void:
	if _canvas == null:
		return
	_canvas.set_selection_mode(enabled)
	_canvas.set_selection_copy_move_mode(_get_select_copy_drag_mode())
	if enabled:
		for t in _tool_btns.keys():
			var tool_btn := _tool_btns[t] as Button
			if tool_btn != null:
				tool_btn.set_pressed_no_signal(false)
	else:
		for t in _tool_btns.keys():
			var is_active_tool := false
			if int(t) == SpriteTools.Tool.RECT_OUTLINE:
				is_active_tool = _canvas.current_tool == SpriteTools.Tool.RECT_OUTLINE \
						or _canvas.current_tool == SpriteTools.Tool.RECT_FILLED
			else:
				is_active_tool = int(t) == _canvas.current_tool
			var tool_btn := _tool_btns[t] as Button
			if tool_btn != null:
				tool_btn.set_pressed_no_signal(is_active_tool)
	_refresh_tool_button_visuals()
	_show_temporary_status("Select mode %s." % ("on" if enabled else "off"), 0.8)


func _on_select_btn_gui_input(event: InputEvent) -> void:
	if _select_btn == null:
		return
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	var copy_mode := mb.double_click
	_select_copy_drag_mode = copy_mode
	if not _select_btn.button_pressed:
		_select_btn.set_pressed_no_signal(true)
	_on_action_select_toggled(true)
	_update_select_button_tooltip()
	_refresh_tool_button_visuals()
	if copy_mode:
		_show_temporary_status("Select copy-drag on.", 1.0)
	else:
		_show_temporary_status("Select move mode.", 1.0)
	accept_event()


func _update_select_button_tooltip() -> void:
	if _select_btn == null:
		return
	var mode_text := "ON" if _get_select_copy_drag_mode() else "OFF"
	var color_text := "Green" if _get_select_copy_drag_mode() else "Blue"
	_select_btn.tooltip_text = "Select tool. Drag area to select; drag inside to move. Double-click: copy-drag %s. Color: %s." % [mode_text, color_text]


func _get_select_copy_drag_mode() -> bool:
	# Hot-reload/stale instances can surface null here; force safe bool.
	return true if _select_copy_drag_mode == true else false


func _pulse_transform_button(btn: Button) -> void:
	if btn == null:
		return
	var key := btn.get_instance_id()
	if _transform_button_tweens.has(key):
		var old_tween := _transform_button_tweens[key] as Tween
		if old_tween != null:
			old_tween.kill()
	var flash_a := Color(1.0, 1.0, 0.12, 1.0)
	var flash_b := Color(1.0, 0.55, 0.12, 1.0)
	btn.self_modulate = flash_a
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(btn, "self_modulate", flash_b, 0.08)
	tw.tween_property(btn, "self_modulate", flash_a, 0.08)
	tw.tween_property(btn, "self_modulate", flash_b, 0.08)
	tw.tween_property(btn, "self_modulate", flash_a, 0.08)
	tw.tween_property(btn, "self_modulate", Color(1, 1, 1, 1), 0.12)
	_transform_button_tweens[key] = tw


func _on_rect_btn_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.double_click:
		return
	var now_ms := Time.get_ticks_msec()
	if now_ms - _last_rect_toggle_ms < 250:
		return
	_last_rect_toggle_ms = now_ms
	_rect_filled_mode = not _rect_filled_mode
	_sync_rect_tool_mode_ui()
	if _canvas.current_tool == SpriteTools.Tool.RECT_OUTLINE \
			or _canvas.current_tool == SpriteTools.Tool.RECT_FILLED:
		_canvas.current_tool = SpriteTools.Tool.RECT_FILLED if _rect_filled_mode else SpriteTools.Tool.RECT_OUTLINE
	_refresh_tool_button_visuals()
	_update_status()


func _sync_rect_tool_mode_ui() -> void:
	if _rect_btn == null:
		return
	# Keep square glyph unambiguous regardless icon-ligature font mode.
	_rect_btn.remove_theme_font_override("font")
	_rect_btn.custom_minimum_size = Vector2(_icon_button_size_px, _icon_button_size_px)
	_rect_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_rect_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_rect_btn.add_theme_font_size_override("font_size", maxi(12, int(round(_icon_button_size_px * RECT_SYMBOL_FONT_RATIO))))
	_rect_btn.text = "■" if _rect_filled_mode else "□"
	_rect_btn.tooltip_text = "Square: %s (double-click to toggle)" % ("Solid" if _rect_filled_mode else "Outline")


# ---------------------------------------------------------------- Resize

func _build_new_set_dialog() -> void:
	_new_set_dialog = ConfirmationDialog.new()
	_new_set_dialog.title = "New TileSet"
	_new_set_dialog.get_ok_button().text = "Create"
	_new_set_dialog.confirmed.connect(_on_new_set_confirmed)
	add_child(_new_set_dialog)

	_new_set_margin = MarginContainer.new()
	_new_set_margin.add_theme_constant_override("margin_left", BASE_SETTINGS_PADDING)
	_new_set_margin.add_theme_constant_override("margin_top", BASE_SETTINGS_PADDING)
	_new_set_margin.add_theme_constant_override("margin_right", BASE_SETTINGS_PADDING)
	_new_set_margin.add_theme_constant_override("margin_bottom", BASE_SETTINGS_PADDING)
	_new_set_dialog.add_child(_new_set_margin)

	_new_set_grid = GridContainer.new()
	_new_set_grid.columns = 2
	_new_set_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_new_set_grid.add_theme_constant_override("h_separation", BASE_SETTINGS_COL_GAP)
	_new_set_grid.add_theme_constant_override("v_separation", BASE_SETTINGS_ROW_GAP)
	_new_set_margin.add_child(_new_set_grid)

	var preset_label := Label.new()
	preset_label.text = "Size Preset"
	_new_set_grid.add_child(preset_label)
	_new_set_size_preset = OptionButton.new()
	_new_set_size_preset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for s in TILE_SIZE_PRESETS:
		_new_set_size_preset.add_item("%dx%d" % [s, s])
	_new_set_size_preset.add_item("Custom")
	_new_set_size_preset.item_selected.connect(_on_new_set_preset_selected)
	_new_set_grid.add_child(_new_set_size_preset)

	var width_label := Label.new()
	width_label.text = "Tile Size (square)"
	_new_set_grid.add_child(width_label)
	_new_set_size_x_spin = SpinBox.new()
	_new_set_size_x_spin.min_value = PixelCanvas.MIN_SIZE
	_new_set_size_x_spin.max_value = PixelCanvas.MAX_SIZE
	_new_set_size_x_spin.step = 1
	_new_set_size_x_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_new_set_size_x_spin.value_changed.connect(_on_new_set_size_x_changed)
	_new_set_grid.add_child(_new_set_size_x_spin)

	var palette_label := Label.new()
	palette_label.text = "Palette Preset"
	_new_set_grid.add_child(palette_label)
	_new_set_palette_select = OptionButton.new()
	_new_set_palette_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_new_set_grid.add_child(_new_set_palette_select)

	var export_cols_label := Label.new()
	export_cols_label.text = "Export Columns"
	_new_set_grid.add_child(export_cols_label)
	_new_set_export_cols_select = OptionButton.new()
	_new_set_export_cols_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_new_set_export_cols_select.add_item("Auto")
	for c in EXPORT_COLUMN_PRESETS:
		_new_set_export_cols_select.add_item(str(c))
	_new_set_grid.add_child(_new_set_export_cols_select)


func _open_new_set_dialog(mode: int, load_path: String = "") -> void:
	if _new_set_dialog == null:
		return
	_new_set_mode = mode
	_pending_new_from_startup = (mode == NEW_SET_MODE_STARTUP)
	_pending_load_path = load_path
	match mode:
		NEW_SET_MODE_LOAD:
			_new_set_dialog.title = "Load TileSet PNG"
			_new_set_dialog.get_ok_button().text = "Load"
			if _new_set_export_cols_select != null:
				_new_set_export_cols_select.disabled = true
				_new_set_export_cols_select.selected = 0
		_:
			_new_set_dialog.title = "New TileSet"
			_new_set_dialog.get_ok_button().text = "Create"
			if _new_set_export_cols_select != null:
				_new_set_export_cols_select.disabled = false
				var sel := 0
				if _export_columns > 0:
					for i in range(EXPORT_COLUMN_PRESETS.size()):
						if int(EXPORT_COLUMN_PRESETS[i]) == _export_columns:
							sel = i + 1
							break
				_new_set_export_cols_select.selected = sel
	_populate_new_set_palette_options()
	var initial_size := clampi(_default_tile_size, PixelCanvas.MIN_SIZE, PixelCanvas.MAX_SIZE)
	if mode == NEW_SET_MODE_LOAD and load_path != "":
		initial_size = _guess_tile_size_for_image(load_path)
	_new_set_sync_lock = true
	_new_set_size_x_spin.value = initial_size
	_sync_new_set_preset_for_size(initial_size)
	_new_set_sync_lock = false
	var ui_scale := _get_ui_scale()
	var dialog_scale := 1.0 + ((ui_scale - 1.0) * 0.55)
	var pad := int(round(BASE_SETTINGS_PADDING * dialog_scale))
	var row_gap := int(round(BASE_SETTINGS_ROW_GAP * dialog_scale * 1.35))
	var col_gap := int(round(BASE_SETTINGS_COL_GAP * dialog_scale))
	if _new_set_margin != null:
		_new_set_margin.add_theme_constant_override("margin_left", pad)
		_new_set_margin.add_theme_constant_override("margin_top", pad)
		_new_set_margin.add_theme_constant_override("margin_right", pad)
		_new_set_margin.add_theme_constant_override("margin_bottom", pad)
	if _new_set_grid != null:
		_new_set_grid.add_theme_constant_override("h_separation", col_gap)
		_new_set_grid.add_theme_constant_override("v_separation", row_gap)
	var dialog_side := int(round(BASE_SETTINGS_SIDE * dialog_scale))
	_new_set_dialog.popup_centered(Vector2i(dialog_side, dialog_side))


func _populate_new_set_palette_options() -> void:
	if _new_set_palette_select == null:
		return
	_new_set_palette_select.clear()
	var files := _list_palette_files()
	if files.is_empty():
		_new_set_palette_select.add_item("No palettes found")
		_new_set_palette_select.disabled = true
		return
	_new_set_palette_select.disabled = false
	for f in files:
		_add_palette_option_item(_new_set_palette_select, f)
	var selected_idx := 0
	var target := _selected_palette_name if _selected_palette_name != "None" else _default_palette
	if target != "":
		for i in range(files.size()):
			if files[i] == target:
				selected_idx = i
				break
	_new_set_palette_select.selected = selected_idx


func _sync_new_set_preset_for_size(size_value: int) -> void:
	if _new_set_size_preset == null:
		return
	var idx := TILE_PRESET_CUSTOM_INDEX
	for i in range(TILE_SIZE_PRESETS.size()):
		if TILE_SIZE_PRESETS[i] == size_value:
			idx = i
			break
	_new_set_size_preset.selected = idx


func _on_new_set_preset_selected(index: int) -> void:
	if _new_set_sync_lock:
		return
	if index < 0 or index >= TILE_SIZE_PRESETS.size():
		return
	var preset_size: int = int(TILE_SIZE_PRESETS[index])
	_new_set_sync_lock = true
	_new_set_size_x_spin.value = preset_size
	_new_set_sync_lock = false


func _on_new_set_size_x_changed(value: float) -> void:
	if _new_set_sync_lock:
		return
	var v := clampi(int(value), PixelCanvas.MIN_SIZE, PixelCanvas.MAX_SIZE)
	_new_set_sync_lock = true
	_sync_new_set_preset_for_size(v)
	_new_set_sync_lock = false


func _on_new_set_confirmed() -> void:
	_pending_size = clampi(int(_new_set_size_x_spin.value), PixelCanvas.MIN_SIZE, PixelCanvas.MAX_SIZE)
	_pending_new_set_mode = _new_set_mode
	_pending_palette_name = ""
	_pending_export_columns = 0
	if _new_set_palette_select != null and not _new_set_palette_select.disabled \
			and _new_set_palette_select.item_count > 0 and _new_set_palette_select.selected >= 0:
		_pending_palette_name = _palette_file_from_option(_new_set_palette_select, _new_set_palette_select.selected)
	if _new_set_export_cols_select != null and not _new_set_export_cols_select.disabled:
		var sel := _new_set_export_cols_select.selected
		if sel > 0 and sel - 1 < EXPORT_COLUMN_PRESETS.size():
			_pending_export_columns = int(EXPORT_COLUMN_PRESETS[sel - 1])
	_default_tile_size = _pending_size
	if _pending_palette_name != "":
		_default_palette = _pending_palette_name
	_save_preferences()
	_pending_new_resets_tileset = (_pending_new_set_mode != NEW_SET_MODE_LOAD)
	if _pending_new_from_startup:
		_apply_pending_resize()
		return
	if _canvas.has_drawn_pixels() or _tileset_images.size() > 1:
		_confirm_dialog.popup_centered()
	else:
		_apply_pending_resize()


func _apply_pending_resize() -> void:
	var reset_sync_link := false
	var loaded_sync_path := ""
	if _pending_new_set_mode == NEW_SET_MODE_LOAD and _pending_load_path != "":
		if not _load_tileset_from_png_with_size(_pending_load_path, _pending_size):
			_show_temporary_status("Load failed: PNG could not be sliced into tiles.", 1.6)
			_pending_palette_name = ""
			_pending_new_resets_tileset = false
			_pending_new_from_startup = false
			_pending_load_path = ""
			return
		loaded_sync_path = _pending_load_path
	else:
		_canvas.new_canvas(_pending_size)
		if _pending_new_resets_tileset:
			_tileset_images.clear()
			if _canvas.image != null:
				_tileset_images.append(_canvas.image.duplicate() as Image)
			_current_tile_index = 0
			_refresh_tile_list_ui()
			reset_sync_link = true
		_source_layout_locked = false
		_source_cell_count = 0
		_source_rows = 0
		_export_columns = maxi(0, _pending_export_columns)
	if reset_sync_link:
		_reset_sync_target_link_for_new_tileset()
	if loaded_sync_path != "":
		_set_sync_target_link_from_loaded_png(loaded_sync_path)
	if _pending_palette_name != "":
		_set_active_palette_by_name(_pending_palette_name)
	_pending_palette_name = ""
	_pending_new_set_mode = NEW_SET_MODE_NEW
	_pending_new_resets_tileset = false
	_pending_new_from_startup = false
	_pending_load_path = ""
	_pending_export_columns = 0
	_history.clear()
	_update_status()
	_update_thumbnail_preview()
	_mark_session_dirty()


func _reset_sync_target_link_for_new_tileset() -> void:
	if _saved_tileset_path == "":
		_sync_target_dirty = false
		_update_sync_button_visuals()
		return
	_saved_tileset_path = ""
	_sync_target_dirty = false
	_last_auto_sync_at_ms = 0
	_update_sync_button_visuals()
	_show_temporary_status("Sync link reset for new TileSet.", 1.2)


func _set_sync_target_link_from_loaded_png(path: String) -> void:
	if path == "":
		return
	_saved_tileset_path = path
	_sync_target_dirty = false
	_last_auto_sync_at_ms = Time.get_ticks_msec()
	_update_sync_button_visuals()
	_show_temporary_status("Sync target linked to loaded PNG.", 1.2)


func _cancel_pending_resize() -> void:
	_pending_palette_name = ""
	_pending_new_set_mode = NEW_SET_MODE_NEW
	_pending_new_from_startup = false
	_pending_new_resets_tileset = false
	_pending_load_path = ""
	_pending_export_columns = 0


func _mark_session_dirty() -> void:
	_session_dirty = true
	_session_dirty_at_ms = Time.get_ticks_msec()


func _mark_sync_target_dirty() -> void:
	_sync_target_dirty = true
	_update_sync_button_visuals()


func _try_auto_sync(now_ms: int) -> void:
	if not _auto_sync_enabled:
		return
	if _saved_tileset_path == "":
		return
	if not _sync_target_dirty:
		return
	var interval_ms := maxi(1, _auto_sync_interval_sec) * 1000
	if (now_ms - _last_auto_sync_at_ms) < interval_ms:
		return
	_last_auto_sync_at_ms = now_ms
	if _save_tileset_png_autosync(_saved_tileset_path):
		_sync_target_dirty = false
		_update_sync_button_visuals()


func _claim_session_owner() -> void:
	if not is_visible_in_tree():
		return
	_session_owner_id = get_instance_id()


func _save_session_state() -> void:
	if _session_owner_id != get_instance_id():
		return
	if not is_visible_in_tree():
		return
	if _canvas == null:
		return
	if _tileset_images.is_empty() and _canvas.image != null:
		_tileset_images.append(_canvas.image.duplicate() as Image)
		_current_tile_index = maxi(0, _current_tile_index)
	_store_canvas_into_current_tile()
	var export_img := _build_tileset_export_image()
	if export_img == null or export_img.is_empty():
		return
	var png_buf := export_img.save_png_to_buffer()
	if png_buf.is_empty():
		print("[PSE Session] save failed: png buffer empty")
		return
	var had_dirty := _session_dirty
	if had_dirty:
		_last_save_display = Time.get_datetime_string_from_system(false, true)
	var metadata := {
		"tile_size": _canvas.canvas_size,
		"current_tile_index": _current_tile_index,
		"palette": _selected_palette_name,
		"zoom": _canvas.zoom,
		"show_grid": _canvas.show_grid,
		"thumb_scale": _thumb_scale,
		"thumb_repeat": _thumb_repeat_tile,
		"last_save_display": _last_save_display,
		"saved_tileset_path": _saved_tileset_path,
		"sync_target_dirty": _sync_target_dirty,
		"export_columns": _export_columns,
		"source_layout_locked": _source_layout_locked,
		"source_cell_count": _source_cell_count,
		"source_rows": _source_rows,
	}
	var save_error := SessionStore.save_atomic(metadata, png_buf, SESSION_STATE_FILE_PATH)
	if save_error != OK:
		print("[PSE Session] atomic save failed: err=%d" % save_error)
		return
	_session_dirty = false
	if had_dirty:
		_update_status()


func _try_restore_session_state() -> bool:
	var session := SessionStore.load_session(SESSION_STATE_FILE_PATH)
	if session.is_empty():
		print("[PSE Session] restore skipped: no valid v2 session")
		return false
	var metadata := session.get("metadata", {}) as Dictionary
	var tile_size := clampi(int(metadata.get("tile_size", _default_tile_size)), PixelCanvas.MIN_SIZE, PixelCanvas.MAX_SIZE)
	var image := Image.new()
	if image.load_png_from_buffer(session.get("png_data", PackedByteArray())) != OK \
			or not _load_tileset_from_image_with_size(image, tile_size):
		print("[PSE Session] restore failed: invalid embedded PNG")
		return false
	var current_tile := clampi(int(metadata.get("current_tile_index", _current_tile_index)), 0, maxi(0, _tileset_images.size() - 1))
	_current_tile_index = current_tile
	_load_tile_into_canvas(current_tile)
	_last_save_display = str(metadata.get("last_save_display", _last_save_display))
	if _last_save_display == "":
		_last_save_display = "--"
	_saved_tileset_path = str(metadata.get("saved_tileset_path", _saved_tileset_path))
	_sync_target_dirty = bool(metadata.get("sync_target_dirty", _sync_target_dirty))
	_export_columns = maxi(0, int(metadata.get("export_columns", _export_columns)))
	_source_layout_locked = bool(metadata.get("source_layout_locked", _source_layout_locked))
	_source_cell_count = maxi(_tileset_images.size(), int(metadata.get("source_cell_count", _source_cell_count)))
	_source_rows = maxi(0, int(metadata.get("source_rows", _source_rows)))
	var palette_name := str(metadata.get("palette", ""))
	if palette_name != "":
		_set_active_palette_by_name(palette_name)
	var restored_zoom := clampi(int(metadata.get("zoom", _default_zoom)), PixelCanvas.MIN_ZOOM, PixelCanvas.MAX_ZOOM)
	_canvas.set_zoom(restored_zoom)
	_zoom_spin.set_value_no_signal(_canvas.zoom)
	var restored_show_grid := bool(metadata.get("show_grid", _default_show_grid))
	_canvas.set_show_grid(restored_show_grid)
	_grid_toggle.set_pressed_no_signal(restored_show_grid)
	_thumb_scale = clampi(int(metadata.get("thumb_scale", _thumb_scale)), 1, 16)
	_thumb_scale_slider.set_value_no_signal(_thumb_scale)
	_thumb_repeat_tile = bool(metadata.get("thumb_repeat", _thumb_repeat_tile))
	if _thumb_repeat_toggle != null:
		_thumb_repeat_toggle.set_pressed_no_signal(_thumb_repeat_tile)
	_update_thumbnail_preview()
	_update_status()
	_update_sync_button_visuals()
	_session_dirty = false
	return true


# ---------------------------------------------------------------- File I/O

func _on_new_pressed() -> void:
	_open_new_set_dialog(NEW_SET_MODE_NEW)


func _on_load_pressed() -> void:
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.title = "Load PNG"
	_file_dialog.clear_filters()
	_file_dialog.add_filter("*.png", "PNG image")
	_show_file_dialog(_on_file_selected_load)


func _on_save_pressed() -> void:
	_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_file_dialog.title = "Save PNG"
	_file_dialog.clear_filters()
	_file_dialog.add_filter("*.png", "PNG image")
	_show_file_dialog(_on_file_selected_save)


func _on_palette_import_pressed() -> void:
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.title = "Import Palette .hex"
	_file_dialog.clear_filters()
	_file_dialog.add_filter("*.hex", "Palette HEX")
	_show_file_dialog(_on_file_selected_import_palette)


func _show_file_dialog(cb: Callable) -> void:
	for c in _file_dialog.file_selected.get_connections():
		_file_dialog.file_selected.disconnect(c.callable)
	_file_dialog.file_selected.connect(cb, CONNECT_ONE_SHOT)
	_file_dialog.popup_centered_ratio(0.6)


func _build_settings_dialog() -> void:
	_settings_dialog = ConfirmationDialog.new()
	_settings_dialog.title = "Settings"
	_settings_dialog.get_ok_button().text = "Apply"
	_settings_dialog.confirmed.connect(_on_settings_confirmed)
	add_child(_settings_dialog)

	_settings_margin = MarginContainer.new()
	_settings_margin.add_theme_constant_override("margin_left", BASE_SETTINGS_PADDING)
	_settings_margin.add_theme_constant_override("margin_top", BASE_SETTINGS_PADDING)
	_settings_margin.add_theme_constant_override("margin_right", BASE_SETTINGS_PADDING)
	_settings_margin.add_theme_constant_override("margin_bottom", BASE_SETTINGS_PADDING)
	_settings_dialog.add_child(_settings_margin)

	_settings_grid = GridContainer.new()
	_settings_grid.columns = 2
	_settings_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_settings_grid.add_theme_constant_override("h_separation", BASE_SETTINGS_COL_GAP)
	_settings_grid.add_theme_constant_override("v_separation", BASE_SETTINGS_ROW_GAP)
	_settings_margin.add_child(_settings_grid)

	var zoom_label := Label.new()
	zoom_label.text = "Default Zoom"
	_settings_grid.add_child(zoom_label)
	_settings_zoom_spin = SpinBox.new()
	_settings_zoom_spin.min_value = PixelCanvas.MIN_ZOOM
	_settings_zoom_spin.max_value = PixelCanvas.MAX_ZOOM
	_settings_zoom_spin.step = 1
	_settings_zoom_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_settings_grid.add_child(_settings_zoom_spin)

	var tile_size_label := Label.new()
	tile_size_label.text = "Default Tile Size"
	_settings_grid.add_child(tile_size_label)
	_settings_tile_size_select = OptionButton.new()
	_settings_tile_size_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for s in TILE_SIZE_PRESETS:
		_settings_tile_size_select.add_item("%dx%d" % [s, s])
	_settings_grid.add_child(_settings_tile_size_select)

	var palette_label := Label.new()
	palette_label.text = "Default Palette"
	_settings_grid.add_child(palette_label)
	_settings_palette_select = OptionButton.new()
	_settings_palette_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_settings_grid.add_child(_settings_palette_select)

	var grid_color_label := Label.new()
	grid_color_label.text = "Grid Color"
	_settings_grid.add_child(grid_color_label)
	_settings_grid_color_btn = ColorPickerButton.new()
	_settings_grid_color_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_settings_grid.add_child(_settings_grid_color_btn)

	var canvas_gradient_start_label := Label.new()
	canvas_gradient_start_label.text = "Canvas Gradient Start"
	_settings_grid.add_child(canvas_gradient_start_label)
	_settings_canvas_gradient_start_btn = ColorPickerButton.new()
	_settings_canvas_gradient_start_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_settings_grid.add_child(_settings_canvas_gradient_start_btn)

	var canvas_gradient_end_label := Label.new()
	canvas_gradient_end_label.text = "Canvas Gradient End"
	_settings_grid.add_child(canvas_gradient_end_label)
	_settings_canvas_gradient_end_btn = ColorPickerButton.new()
	_settings_canvas_gradient_end_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_settings_grid.add_child(_settings_canvas_gradient_end_btn)

	var canvas_gradient_enabled_label := Label.new()
	canvas_gradient_enabled_label.text = "Canvas Gradient Enabled"
	_settings_grid.add_child(canvas_gradient_enabled_label)
	_settings_canvas_gradient_enabled_check = CheckBox.new()
	_settings_canvas_gradient_enabled_check.text = ""
	_settings_canvas_gradient_enabled_check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_settings_grid.add_child(_settings_canvas_gradient_enabled_check)

	var grid_thickness_label := Label.new()
	grid_thickness_label.text = "Grid Thickness"
	_settings_grid.add_child(grid_thickness_label)
	_settings_grid_thickness_spin = SpinBox.new()
	_settings_grid_thickness_spin.min_value = 1
	_settings_grid_thickness_spin.max_value = 8
	_settings_grid_thickness_spin.step = 1
	_settings_grid_thickness_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_settings_grid.add_child(_settings_grid_thickness_spin)

	var cursor_scale_label := Label.new()
	cursor_scale_label.text = "Cursor Scale"
	_settings_grid.add_child(cursor_scale_label)
	_settings_cursor_scale_spin = SpinBox.new()
	_settings_cursor_scale_spin.min_value = PixelCanvas.MIN_CURSOR_SCALE
	_settings_cursor_scale_spin.max_value = PixelCanvas.MAX_CURSOR_SCALE
	_settings_cursor_scale_spin.step = 1
	_settings_cursor_scale_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_settings_grid.add_child(_settings_cursor_scale_spin)

	var session_save_label := Label.new()
	session_save_label.text = "Session Save Interval (sec)"
	_settings_grid.add_child(session_save_label)
	_settings_session_save_interval_spin = SpinBox.new()
	_settings_session_save_interval_spin.min_value = 1
	_settings_session_save_interval_spin.max_value = 120
	_settings_session_save_interval_spin.step = 1
	_settings_session_save_interval_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_settings_grid.add_child(_settings_session_save_interval_spin)

	var dynamic_cursor_contrast_label := Label.new()
	dynamic_cursor_contrast_label.text = "Dynamic Cursor Contrast"
	_settings_grid.add_child(dynamic_cursor_contrast_label)
	_settings_dynamic_cursor_contrast_check = CheckBox.new()
	_settings_dynamic_cursor_contrast_check.text = ""
	_settings_dynamic_cursor_contrast_check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_settings_grid.add_child(_settings_dynamic_cursor_contrast_check)

	var auto_sync_label := Label.new()
	auto_sync_label.text = "Auto Sync"
	_settings_grid.add_child(auto_sync_label)
	_settings_auto_sync_check = CheckBox.new()
	_settings_auto_sync_check.text = ""
	_settings_auto_sync_check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_settings_grid.add_child(_settings_auto_sync_check)

	var auto_sync_interval_label := Label.new()
	auto_sync_interval_label.text = "Auto Sync Frequency (sec)"
	_settings_grid.add_child(auto_sync_interval_label)
	var auto_sync_interval_row := HBoxContainer.new()
	auto_sync_interval_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	auto_sync_interval_row.add_theme_constant_override("separation", 8)
	_settings_auto_sync_interval_slider = HSlider.new()
	_settings_auto_sync_interval_slider.min_value = 1
	_settings_auto_sync_interval_slider.max_value = 120
	_settings_auto_sync_interval_slider.step = 1
	_settings_auto_sync_interval_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	auto_sync_interval_row.add_child(_settings_auto_sync_interval_slider)
	_settings_auto_sync_interval_value_label = Label.new()
	_settings_auto_sync_interval_value_label.custom_minimum_size = Vector2(44, 0)
	_settings_auto_sync_interval_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	auto_sync_interval_row.add_child(_settings_auto_sync_interval_value_label)
	_settings_grid.add_child(auto_sync_interval_row)
	_settings_auto_sync_interval_slider.value_changed.connect(_on_settings_auto_sync_interval_changed)

	var pan_speed_label := Label.new()
	pan_speed_label.text = "Pan Speed"
	_settings_grid.add_child(pan_speed_label)
	_settings_pan_speed_spin = SpinBox.new()
	_settings_pan_speed_spin.min_value = 0.1
	_settings_pan_speed_spin.max_value = 8.0
	_settings_pan_speed_spin.step = 0.1
	_settings_pan_speed_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_settings_grid.add_child(_settings_pan_speed_spin)

	var show_grid_label := Label.new()
	show_grid_label.text = "Default Grid"
	_settings_grid.add_child(show_grid_label)
	_settings_show_grid_check = CheckBox.new()
	_settings_show_grid_check.text = ""
	_settings_show_grid_check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_settings_grid.add_child(_settings_show_grid_check)

	var show_dev_label := Label.new()
	show_dev_label.text = "Show Dev Button"
	_settings_grid.add_child(show_dev_label)
	_settings_show_dev_button_check = CheckBox.new()
	_settings_show_dev_button_check.text = ""
	_settings_show_dev_button_check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_settings_grid.add_child(_settings_show_dev_button_check)


func _on_settings_auto_sync_interval_changed(value: float) -> void:
	if _settings_auto_sync_interval_value_label != null:
		_settings_auto_sync_interval_value_label.text = "%ds" % int(round(value))


func _on_settings_pressed() -> void:
	if _settings_tile_size_select != null:
		var nearest_size := _nearest_tile_size_preset(_default_tile_size)
		for i in range(TILE_SIZE_PRESETS.size()):
			if int(TILE_SIZE_PRESETS[i]) == nearest_size:
				_settings_tile_size_select.selected = i
				break
	_settings_zoom_spin.min_value = PixelCanvas.MIN_ZOOM
	_settings_zoom_spin.max_value = _canvas.get_max_zoom_limit() if _canvas != null else PixelCanvas.DEFAULT_MAX_ZOOM
	_settings_zoom_spin.value = _default_zoom
	_settings_grid_color_btn.color = _default_grid_color
	_default_canvas_gradient_start = _safe_color(_default_canvas_gradient_start, DEFAULT_CANVAS_GRADIENT_START)
	_default_canvas_gradient_end = _safe_color(_default_canvas_gradient_end, DEFAULT_CANVAS_GRADIENT_END)
	if _settings_canvas_gradient_start_btn != null:
		_settings_canvas_gradient_start_btn.color = _default_canvas_gradient_start
	if _settings_canvas_gradient_end_btn != null:
		_settings_canvas_gradient_end_btn.color = _default_canvas_gradient_end
	if _settings_canvas_gradient_enabled_check != null:
		_settings_canvas_gradient_enabled_check.button_pressed = _default_canvas_gradient_enabled
	_settings_grid_thickness_spin.value = _default_grid_thickness
	if _settings_cursor_scale_spin != null:
		_settings_cursor_scale_spin.value = _default_cursor_scale
	if _settings_session_save_interval_spin != null:
		_settings_session_save_interval_spin.value = _session_save_interval_sec
	if _settings_dynamic_cursor_contrast_check != null:
		_settings_dynamic_cursor_contrast_check.button_pressed = true if _default_dynamic_cursor_contrast == true else false
	if _settings_auto_sync_check != null:
		_settings_auto_sync_check.button_pressed = _auto_sync_enabled
	if _settings_auto_sync_interval_slider != null:
		_settings_auto_sync_interval_slider.value = _auto_sync_interval_sec
		_on_settings_auto_sync_interval_changed(_settings_auto_sync_interval_slider.value)
	if _settings_pan_speed_spin != null:
		_settings_pan_speed_spin.value = _default_pan_speed
	if _settings_show_grid_check != null:
		_settings_show_grid_check.button_pressed = _default_show_grid
	if _settings_show_dev_button_check != null:
		_settings_show_dev_button_check.button_pressed = _show_dev_button
	_settings_palette_select.clear()
	var files := _list_palette_files()
	for f in files:
		_add_palette_option_item(_settings_palette_select, f)
	if not files.is_empty():
		var idx := 0
		for i in range(files.size()):
			if files[i] == _default_palette:
				idx = i
				break
		_settings_palette_select.selected = idx
	var ui_scale := _get_ui_scale()
	var dialog_scale := 1.0 + ((ui_scale - 1.0) * 0.55)
	var pad := int(round(BASE_SETTINGS_PADDING * dialog_scale))
	var row_gap := int(round(BASE_SETTINGS_ROW_GAP * dialog_scale * 1.35))
	var col_gap := int(round(BASE_SETTINGS_COL_GAP * dialog_scale))
	if _settings_margin != null:
		_settings_margin.add_theme_constant_override("margin_left", pad)
		_settings_margin.add_theme_constant_override("margin_top", pad)
		_settings_margin.add_theme_constant_override("margin_right", pad)
		_settings_margin.add_theme_constant_override("margin_bottom", pad)
	if _settings_grid != null:
		_settings_grid.add_theme_constant_override("h_separation", col_gap)
		_settings_grid.add_theme_constant_override("v_separation", row_gap)
	var dialog_side := int(round(BASE_SETTINGS_SIDE * dialog_scale))
	_settings_dialog.popup_centered(Vector2i(
		dialog_side,
		dialog_side
	))


func _on_settings_confirmed() -> void:
	if _settings_tile_size_select != null and _settings_tile_size_select.selected >= 0 \
			and _settings_tile_size_select.selected < TILE_SIZE_PRESETS.size():
		_default_tile_size = int(TILE_SIZE_PRESETS[_settings_tile_size_select.selected])
	_default_zoom = clampi(int(_settings_zoom_spin.value), PixelCanvas.MIN_ZOOM, PixelCanvas.MAX_ZOOM)
	_default_grid_color = _settings_grid_color_btn.color
	if _settings_canvas_gradient_start_btn != null:
		_default_canvas_gradient_start = _settings_canvas_gradient_start_btn.color
	if _settings_canvas_gradient_end_btn != null:
		_default_canvas_gradient_end = _settings_canvas_gradient_end_btn.color
	if _settings_canvas_gradient_enabled_check != null:
		_default_canvas_gradient_enabled = _settings_canvas_gradient_enabled_check.button_pressed
	_default_grid_thickness = clampi(int(_settings_grid_thickness_spin.value), 1, 8)
	if _settings_cursor_scale_spin != null:
		_default_cursor_scale = clampi(int(_settings_cursor_scale_spin.value), PixelCanvas.MIN_CURSOR_SCALE, PixelCanvas.MAX_CURSOR_SCALE)
	if _settings_dynamic_cursor_contrast_check != null:
		_default_dynamic_cursor_contrast = true if _settings_dynamic_cursor_contrast_check.button_pressed == true else false
	if _settings_session_save_interval_spin != null:
		_session_save_interval_sec = clampi(int(_settings_session_save_interval_spin.value), 1, 120)
	if _settings_auto_sync_check != null:
		_auto_sync_enabled = _settings_auto_sync_check.button_pressed
	if _settings_auto_sync_interval_slider != null:
		_auto_sync_interval_sec = clampi(int(round(_settings_auto_sync_interval_slider.value)), 1, 120)
		_on_settings_auto_sync_interval_changed(_auto_sync_interval_sec)
	_last_auto_sync_at_ms = Time.get_ticks_msec()
	if _settings_pan_speed_spin != null:
		_default_pan_speed = clampf(float(_settings_pan_speed_spin.value), 0.1, 8.0)
	if _settings_show_grid_check != null:
		_default_show_grid = _settings_show_grid_check.button_pressed
	if _settings_show_dev_button_check != null:
		_show_dev_button = _settings_show_dev_button_check.button_pressed
	_apply_dev_button_visibility()
	if _settings_palette_select.item_count > 0 and _settings_palette_select.selected >= 0:
		_default_palette = _palette_file_from_option(_settings_palette_select, _settings_palette_select.selected)
	_save_preferences()

	_canvas.set_grid_style(_default_grid_color, _default_grid_thickness)
	_canvas.set_show_grid(_default_show_grid)
	_canvas.set_pan_speed(_default_pan_speed)
	_canvas.set_cursor_scale(_default_cursor_scale)
	_canvas.set_dynamic_cursor_contrast_enabled(_default_dynamic_cursor_contrast)
	_apply_canvas_background_gradient()
	_grid_toggle.set_pressed_no_signal(_default_show_grid)
	if _default_palette != "":
		for i in range(_palette_select.item_count):
			if _palette_file_from_option(_palette_select, i) == _default_palette:
				_palette_select.selected = i
				_apply_palette_file(_default_palette)
				break
	_update_status()


func _safe_color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	return fallback


func _safe_bool(value: Variant, fallback: bool) -> bool:
	if value is bool:
		return value
	return fallback


func _parse_color_pref(raw_value: Variant, fallback_value: Variant, hard_fallback: Color) -> Color:
	var fallback := _safe_color(fallback_value, hard_fallback)
	if raw_value is Color:
		return raw_value
	if raw_value is String:
		var s := str(raw_value)
		if not s.begins_with("#"):
			s = "#" + s
		if Color.html_is_valid(s):
			return Color.html(s)
	return fallback


func _load_preferences() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_FILE_PATH)
	if err != OK:
		return
	_default_tile_size = clampi(int(cfg.get_value("defaults", "tile_size", _default_tile_size)), PixelCanvas.MIN_SIZE, PixelCanvas.MAX_SIZE)
	_default_zoom = clampi(int(cfg.get_value("defaults", "zoom", _default_zoom)), PixelCanvas.MIN_ZOOM, PixelCanvas.MAX_ZOOM)
	_default_palette = str(cfg.get_value("defaults", "palette", _default_palette))
	_default_grid_color = _parse_color_pref(cfg.get_value("defaults", "grid_color", _default_grid_color.to_html(true)), _default_grid_color, PixelCanvas.DEFAULT_GRID_COLOR)
	_default_canvas_gradient_start = _parse_color_pref(cfg.get_value("defaults", "canvas_gradient_start", _default_canvas_gradient_start.to_html(true)), _default_canvas_gradient_start, DEFAULT_CANVAS_GRADIENT_START)
	_default_canvas_gradient_end = _parse_color_pref(cfg.get_value("defaults", "canvas_gradient_end", _default_canvas_gradient_end.to_html(true)), _default_canvas_gradient_end, DEFAULT_CANVAS_GRADIENT_END)
	_default_canvas_gradient_enabled = bool(cfg.get_value("defaults", "canvas_gradient_enabled", _default_canvas_gradient_enabled))
	_default_grid_thickness = clampi(int(cfg.get_value("defaults", "grid_thickness", _default_grid_thickness)), 1, 8)
	_default_cursor_scale = clampi(int(cfg.get_value("defaults", "cursor_scale", _default_cursor_scale)), PixelCanvas.MIN_CURSOR_SCALE, PixelCanvas.MAX_CURSOR_SCALE)
	_default_dynamic_cursor_contrast = _safe_bool(cfg.get_value("defaults", "dynamic_cursor_contrast", _default_dynamic_cursor_contrast), _default_dynamic_cursor_contrast)
	_session_save_interval_sec = clampi(int(cfg.get_value("defaults", "session_save_interval_sec", _session_save_interval_sec)), 1, 120)
	_auto_sync_enabled = bool(cfg.get_value("defaults", "auto_sync_enabled", _auto_sync_enabled))
	_auto_sync_interval_sec = clampi(int(cfg.get_value("defaults", "auto_sync_interval_sec", _auto_sync_interval_sec)), 1, 120)
	_default_pan_speed = clampf(float(cfg.get_value("defaults", "pan_speed", _default_pan_speed)), 0.1, 8.0)
	_default_show_grid = bool(cfg.get_value("defaults", "show_grid", _default_show_grid))
	_show_dev_button = bool(cfg.get_value("defaults", "show_dev_button", _show_dev_button))


func _save_preferences() -> void:
	var cfg := ConfigFile.new()
	_default_canvas_gradient_start = _safe_color(_default_canvas_gradient_start, DEFAULT_CANVAS_GRADIENT_START)
	_default_canvas_gradient_end = _safe_color(_default_canvas_gradient_end, DEFAULT_CANVAS_GRADIENT_END)
	cfg.set_value("defaults", "tile_size", _default_tile_size)
	cfg.set_value("defaults", "zoom", _default_zoom)
	cfg.set_value("defaults", "palette", _default_palette)
	cfg.set_value("defaults", "grid_color", _default_grid_color.to_html(true))
	cfg.set_value("defaults", "canvas_gradient_start", _default_canvas_gradient_start.to_html(true))
	cfg.set_value("defaults", "canvas_gradient_end", _default_canvas_gradient_end.to_html(true))
	cfg.set_value("defaults", "canvas_gradient_enabled", _default_canvas_gradient_enabled)
	cfg.set_value("defaults", "grid_thickness", _default_grid_thickness)
	cfg.set_value("defaults", "cursor_scale", _default_cursor_scale)
	cfg.set_value("defaults", "dynamic_cursor_contrast", _default_dynamic_cursor_contrast)
	cfg.set_value("defaults", "session_save_interval_sec", _session_save_interval_sec)
	cfg.set_value("defaults", "auto_sync_enabled", _auto_sync_enabled)
	cfg.set_value("defaults", "auto_sync_interval_sec", _auto_sync_interval_sec)
	cfg.set_value("defaults", "pan_speed", _default_pan_speed)
	cfg.set_value("defaults", "show_grid", _default_show_grid)
	cfg.set_value("defaults", "show_dev_button", _show_dev_button)
	cfg.save(SETTINGS_FILE_PATH)


func _on_file_selected_load(path: String) -> void:
	_open_new_set_dialog(NEW_SET_MODE_LOAD, path)


func _guess_tile_size_for_image(path: String) -> int:
	var img := Image.new()
	if img.load(path) != OK:
		return clampi(_default_tile_size, PixelCanvas.MIN_SIZE, PixelCanvas.MAX_SIZE)
	if img.get_width() <= 0 or img.get_height() <= 0:
		return clampi(_default_tile_size, PixelCanvas.MIN_SIZE, PixelCanvas.MAX_SIZE)
	# Prefer largest preset that cleanly tiles both dimensions.
	for i in range(TILE_SIZE_PRESETS.size() - 1, -1, -1):
		var s: int = int(TILE_SIZE_PRESETS[i])
		if img.get_width() >= s and img.get_height() >= s \
				and img.get_width() % s == 0 and img.get_height() % s == 0:
			return s
	# Fallback: use clamped default.
	return clampi(_default_tile_size, PixelCanvas.MIN_SIZE, PixelCanvas.MAX_SIZE)


func _nearest_tile_size_preset(size_value: int) -> int:
	var target := clampi(size_value, PixelCanvas.MIN_SIZE, PixelCanvas.MAX_SIZE)
	var best := int(TILE_SIZE_PRESETS[0])
	var best_dist := abs(target - best)
	for i in range(1, TILE_SIZE_PRESETS.size()):
		var candidate := int(TILE_SIZE_PRESETS[i])
		var d := abs(target - candidate)
		if d < best_dist:
			best = candidate
			best_dist = d
	return best


func _load_tileset_from_png_with_size(path: String, tile_size: int) -> bool:
	var img := Image.new()
	if img.load(path) != OK:
		return false
	return _load_tileset_from_image_with_size(img, tile_size)


func _load_tileset_from_image_with_size(img: Image, tile_size: int) -> bool:
	if img.get_width() <= 0 or img.get_height() <= 0:
		return false
	tile_size = clampi(tile_size, PixelCanvas.MIN_SIZE, PixelCanvas.MAX_SIZE)
	var sliced := TilesetPngIO.slice(img, tile_size, true)
	if sliced.is_empty():
		return false
	var parsed_tiles: Array[Image] = sliced.get("tiles", [])
	if parsed_tiles.is_empty():
		return false
	var cols := int(sliced.get("columns", 0))
	var rows := int(sliced.get("rows", 0))
	var dropped_w := int(sliced.get("dropped_width", 0))
	var dropped_h := int(sliced.get("dropped_height", 0))
	if dropped_w > 0 or dropped_h > 0:
		_show_temporary_status("Loaded full %dx%d blocks; ignored partial edge pixels." % [tile_size, tile_size], 1.6)
	_tileset_images = parsed_tiles
	_current_tile_index = 0
	_pending_size = tile_size
	_source_layout_locked = true
	_export_columns = maxi(1, cols)
	_source_rows = maxi(1, rows)
	_source_cell_count = maxi(_tileset_images.size(), int(sliced.get("source_cell_count", cols * rows)))
	_load_tile_into_canvas(0)
	return true


func _is_tile_fully_transparent(tile: Image) -> bool:
	if tile == null:
		return true
	if tile.is_empty():
		return true
	var w := tile.get_width()
	var h := tile.get_height()
	for y in range(h):
		for x in range(w):
			if tile.get_pixel(x, y).a > 0.0:
				return false
	return true


func _on_file_selected_save(path: String) -> void:
	if not path.to_lower().ends_with(".png"):
		path += ".png"
	if _save_tileset_png(path):
		_saved_tileset_path = path
		_sync_target_dirty = false
		_last_auto_sync_at_ms = Time.get_ticks_msec()
		_update_sync_button_visuals()
		_show_temporary_status("Sync target set.", 1.0)


func _sync_saved_tileset_file() -> bool:
	if _saved_tileset_path == "":
		return true
	return _save_tileset_png(_saved_tileset_path)


func _on_sync_push_pressed() -> void:
	if _saved_tileset_path == "":
		_show_temporary_status("Save once first to set Sync target.", 1.4)
		return
	if _sync_saved_tileset_file():
		_sync_target_dirty = false
		_last_auto_sync_at_ms = Time.get_ticks_msec()
		_update_sync_button_visuals()
		_show_temporary_status("Synced to saved PNG.", 1.0)


func _update_sync_button_visuals() -> void:
	if _sync_btn == null:
		return
	var dirty := _sync_target_dirty or _saved_tileset_path == ""
	var bg := SYNC_BTN_BG_DIRTY if dirty else SYNC_BTN_BG_CLEAN
	var border := SYNC_BTN_BORDER_DIRTY if dirty else SYNC_BTN_BORDER_CLEAN
	var base := StyleBoxFlat.new()
	base.bg_color = bg
	base.border_width_left = 2
	base.border_width_top = 2
	base.border_width_right = 2
	base.border_width_bottom = 2
	base.border_color = border
	base.corner_radius_top_left = 3
	base.corner_radius_top_right = 3
	base.corner_radius_bottom_right = 3
	base.corner_radius_bottom_left = 3
	var hover := base.duplicate() as StyleBoxFlat
	hover.bg_color = hover.bg_color.lightened(0.08)
	_sync_btn.add_theme_stylebox_override("normal", base)
	_sync_btn.add_theme_stylebox_override("hover", hover)
	_sync_btn.add_theme_stylebox_override("pressed", base.duplicate())
	_sync_btn.add_theme_stylebox_override("hover_pressed", base.duplicate())
	_sync_btn.add_theme_stylebox_override("focus", base.duplicate())
	_apply_button_font_color(_sync_btn, true)
	if _saved_tileset_path == "":
		_sync_btn.tooltip_text = "Sync (Ctrl/Cmd+S): save once first to set target path"
	else:
		_sync_btn.tooltip_text = "Sync (Ctrl/Cmd+S): pending changes" if dirty else "Sync (Ctrl/Cmd+S): up to date"


func _save_tileset_png(path: String) -> bool:
	_store_canvas_into_current_tile()
	var export_img := _build_tileset_export_image_with_override(null)
	var ok := false
	if export_img == null or export_img.is_empty():
		ok = _canvas.save_to_png(path)
	else:
		ok = (export_img.save_png(path) == OK)
	if not ok:
		push_error("Failed to save PNG: %s" % path)
		return false
	_refresh_editor_for_saved_png(path)
	_last_save_display = Time.get_datetime_string_from_system(false, true)
	_update_status()
	return true


func _save_tileset_png_autosync(path: String) -> bool:
	# Keep export data current without forcing tile-panel or thumbnail UI refreshes.
	_store_canvas_into_current_tile()
	var live_canvas_override: Image = null
	if _canvas != null and _canvas.image != null and not _canvas.image.is_empty():
		live_canvas_override = _canvas.image.duplicate() as Image
	var export_img := _build_tileset_export_image_with_override(live_canvas_override)
	var ok := false
	if export_img == null or export_img.is_empty():
		ok = _canvas != null and _canvas.save_to_png(path)
	else:
		ok = (export_img.save_png(path) == OK)
	if not ok:
		push_error("Auto sync failed to save PNG: %s" % path)
		return false
	# Intentionally avoid editor scan refresh, status updates, and thumbnail/tile-panel refresh side effects.
	return true


func _refresh_editor_for_saved_png(saved_path: String) -> void:
	var res_path := _to_res_path_if_project_file(saved_path)
	if res_path == "":
		return
	var fs = EditorInterface.get_resource_filesystem()
	if fs == null:
		return
	if fs.has_method("update_file"):
		fs.update_file(res_path)
	fs.scan()


func _to_res_path_if_project_file(path: String) -> String:
	var normalized := path.replace("\\", "/")
	if normalized.begins_with("res://"):
		return normalized
	var root := ProjectSettings.globalize_path("res://").replace("\\", "/")
	if not root.ends_with("/"):
		root += "/"
	if not normalized.begins_with(root):
		return ""
	var rel := normalized.substr(root.length())
	return "res://%s" % rel


func _build_tileset_export_image() -> Image:
	return _build_tileset_export_image_with_override(null)


func _build_tileset_export_image_with_override(current_tile_override: Image = null) -> Image:
	if _tileset_images.is_empty():
		if current_tile_override != null and not current_tile_override.is_empty():
			return current_tile_override
		return _canvas.image if _canvas != null else null
	var tile_size := _canvas.canvas_size if _canvas != null else 32
	tile_size = clampi(tile_size, PixelCanvas.MIN_SIZE, PixelCanvas.MAX_SIZE)
	var count := _tileset_images.size()
	var layout_count := maxi(count, _source_cell_count if _source_layout_locked else 0)
	var cols := 0
	if _source_layout_locked and _export_columns > 0:
		cols = _export_columns
	elif _export_columns > 0:
		cols = _export_columns
	else:
		cols = mini(3, layout_count)
	cols = clampi(cols, 1, maxi(1, layout_count))
	var minimum_cells := _source_cell_count if _source_layout_locked else 0
	return TilesetPngIO.build(_tileset_images, tile_size, cols, minimum_cells, _current_tile_index, current_tile_override)


# ---------------------------------------------------------------- Palettes

func _on_grid_toggled(enabled: bool) -> void:
	_canvas.set_show_grid(enabled)
	_update_status()
	_mark_session_dirty()


func _on_palette_derive_pressed() -> void:
	_show_palette_action_confirm(PALETTE_ACTION_DERIVE)


func _apply_palette_derive() -> void:
	var source: Image = _build_tileset_export_image()
	if source == null and _canvas != null:
		source = _canvas.get_display_image()
	if source == null or source.is_empty():
		_show_temporary_status("No PNG data available to derive palette", 1.5)
		return
	var derived := _extract_palette_from_image(source, MAX_DERIVED_PALETTE_COLORS)
	if derived.is_empty():
		_show_temporary_status("No visible colors found in current PNG", 1.5)
		return
	_push_editor_undo_snapshot()
	derived = _order_palette_colors_by_similarity(derived)
	_selected_palette_name = "Derived (Current PNG)"
	_palette_colors = derived
	_rebuild_palette_swatches(_palette_colors)
	_update_status()
	_mark_session_dirty()
	if derived.size() >= MAX_DERIVED_PALETTE_COLORS:
		_show_temporary_status("Derived %d colors (capped at %d)" % [derived.size(), MAX_DERIVED_PALETTE_COLORS], 1.8)
	else:
		_show_temporary_status("Derived %d colors from current PNG" % derived.size(), 1.6)


func _on_palette_remap_pressed() -> void:
	_show_palette_action_confirm(PALETTE_ACTION_REMAP)


func _apply_palette_remap() -> void:
	if _palette_colors.is_empty():
		_show_temporary_status("No active palette to remap to", 1.5)
		return
	if _tileset_images.is_empty() and (_canvas == null or _canvas.image == null):
		_show_temporary_status("No tile data to remap", 1.5)
		return
	_push_editor_undo_snapshot()
	var remapped_count := 0
	for i in range(_tileset_images.size()):
		var src := _tileset_images[i]
		if src == null or src.is_empty():
			continue
		_tileset_images[i] = _remap_image_to_palette(src, _palette_colors)
		remapped_count += 1
	if remapped_count > 0 and _current_tile_index >= 0 and _current_tile_index < _tileset_images.size():
		_load_tile_into_canvas(_current_tile_index)
	elif _canvas != null and _canvas.image != null and not _canvas.image.is_empty():
		_canvas.set_image_from_image(_remap_image_to_palette(_canvas.image, _palette_colors))
		remapped_count = 1
	if remapped_count <= 0:
		_show_temporary_status("No remappable tiles found", 1.4)
		return
	_refresh_tile_list_ui()
	_thumbnail_dirty = true
	_try_update_thumbnail_preview(true)
	_update_status()
	_mark_session_dirty()
	_mark_sync_target_dirty()
	_show_temporary_status("Remapped %d tile(s) to palette" % remapped_count, 1.6)


func _remap_image_to_palette(source: Image, palette: Array[Color]) -> Image:
	return PaletteProcessor.remap(source, palette)


func _build_palette_match_cache(palette: Array[Color]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in palette:
		out.append({
			"color": p,
			"oklab": _color_to_oklab(p),
		})
	return out


func _nearest_palette_color(color: Color, palette: Array[Color], palette_cache: Array[Dictionary] = []) -> Color:
	var best := palette[0]
	var best_dist := 1e30
	var target_lab := _color_to_oklab(color)
	var source := palette_cache if not palette_cache.is_empty() else _build_palette_match_cache(palette)
	for entry in source:
		var p := entry["color"] as Color
		var lab := entry["oklab"] as Vector3
		var d_l := target_lab.x - lab.x
		var d_a := target_lab.y - lab.y
		var d_b := target_lab.z - lab.z
		var dist := (d_l * d_l * 2.0) + (d_a * d_a) + (d_b * d_b)
		if dist < best_dist:
			best_dist = dist
			best = p
	return best


func _srgb_to_linear(v: float) -> float:
	if v <= 0.04045:
		return v / 12.92
	return pow((v + 0.055) / 1.055, 2.4)


func _linear_to_srgb(v: float) -> float:
	v = clampf(v, 0.0, 1.0)
	if v <= 0.0031308:
		return 12.92 * v
	return (1.055 * pow(v, 1.0 / 2.4)) - 0.055


func _cbrt(v: float) -> float:
	if v == 0.0:
		return 0.0
	return signf(v) * pow(absf(v), 1.0 / 3.0)


func _color_to_oklab(c: Color) -> Vector3:
	var r := _srgb_to_linear(c.r)
	var g := _srgb_to_linear(c.g)
	var b := _srgb_to_linear(c.b)
	var l := 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
	var m := 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
	var s := 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
	var l_ := _cbrt(l)
	var m_ := _cbrt(m)
	var s_ := _cbrt(s)
	return Vector3(
		0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
		1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
		0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
	)


func _extract_palette_from_image(source: Image, limit: int) -> Array[Color]:
	return PaletteProcessor.extract(source, limit)


func _order_palette_colors_by_similarity(colors: Array[Color]) -> Array[Color]:
	if colors.size() <= 2:
		return colors
	var ordered: Array[Color] = []
	var used := PackedByteArray()
	used.resize(colors.size())
	for i in range(colors.size()):
		used[i] = 0
	var seed_idx := 0
	var seed_luma := 999999.0
	for i in range(colors.size()):
		var c := colors[i]
		var luma := (c.r * 0.2126) + (c.g * 0.7152) + (c.b * 0.0722)
		if luma < seed_luma:
			seed_luma = luma
			seed_idx = i
	ordered.append(colors[seed_idx])
	used[seed_idx] = 1
	while ordered.size() < colors.size():
		var last := ordered[ordered.size() - 1]
		var best_idx := -1
		var best_dist := 1e30
		for i in range(colors.size()):
			if used[i] != 0:
				continue
			var c := colors[i]
			var dr := last.r - c.r
			var dg := last.g - c.g
			var db := last.b - c.b
			var da := last.a - c.a
			var dist := (dr * dr) + (dg * dg) + (db * db) + (da * da * 0.25)
			if dist < best_dist:
				best_dist = dist
				best_idx = i
		if best_idx < 0:
			break
		ordered.append(colors[best_idx])
		used[best_idx] = 1
	return ordered


func _clone_image_array(images: Array[Image]) -> Array[Image]:
	return EditorModel.clone_images(images)


func _capture_editor_snapshot() -> Dictionary:
	var canvas_image := _canvas.image if _canvas != null else null
	return EditorModel.capture_snapshot(
		_tileset_images,
		_current_tile_index,
		_selected_palette_name,
		_palette_colors,
		canvas_image,
		_export_columns,
		_source_layout_locked,
		_source_cell_count,
		_source_rows
	)


func _push_editor_undo_snapshot() -> void:
	_history.push(_capture_editor_snapshot())


func _apply_editor_snapshot(snap: Dictionary) -> void:
	if snap.is_empty():
		return
	if snap.has("tiles"):
		_tileset_images = _clone_image_array(snap.get("tiles", []))
	_selected_palette_name = str(snap.get("palette_name", _selected_palette_name))
	_palette_colors = snap.get("palette_colors", []).duplicate()
	_export_columns = int(snap.get("export_columns", _export_columns))
	_source_layout_locked = bool(snap.get("source_layout_locked", _source_layout_locked))
	_source_cell_count = int(snap.get("source_cell_count", _source_cell_count))
	_source_rows = int(snap.get("source_rows", _source_rows))
	_rebuild_palette_swatches(_palette_colors)
	var tile_index := int(snap.get("current_tile_index", _current_tile_index))
	if not _tileset_images.is_empty():
		tile_index = clampi(tile_index, 0, _tileset_images.size() - 1)
		_load_tile_into_canvas(tile_index)
	else:
		var canvas_img := snap.get("canvas_image", null) as Image
		if _canvas != null and canvas_img != null:
			_canvas.set_image_from_image(canvas_img)
	_current_tile_index = tile_index
	_refresh_tile_list_ui()
	_thumbnail_dirty = true
	_try_update_thumbnail_preview(true)
	_update_status()
	_mark_session_dirty()
	_mark_sync_target_dirty()


func _on_undo_pressed() -> void:
	if not _history.can_undo():
		return
	_apply_editor_snapshot(_history.undo(_capture_editor_snapshot()))


func _on_redo_pressed() -> void:
	if not _history.can_redo():
		return
	_apply_editor_snapshot(_history.redo(_capture_editor_snapshot()))


func _palette_display_name(file_name: String) -> String:
	if file_name.to_lower().ends_with(".hex"):
		return file_name.substr(0, file_name.length() - 4)
	return file_name


func _add_palette_option_item(select: OptionButton, file_name: String) -> void:
	if select == null:
		return
	select.add_item(_palette_display_name(file_name))
	var idx := select.item_count - 1
	if idx >= 0:
		select.set_item_metadata(idx, file_name)


func _palette_file_from_option(select: OptionButton, index: int) -> String:
	if select == null or index < 0 or index >= select.item_count:
		return ""
	var meta := select.get_item_metadata(index)
	if meta is String and str(meta) != "":
		return str(meta)
	var text := select.get_item_text(index)
	if text == "":
		return ""
	if not text.to_lower().ends_with(".hex"):
		return "%s.hex" % text
	return text


func _init_palette_dropdown() -> void:
	_palette_select.clear()
	var palette_files := _list_palette_files()
	for f in palette_files:
		_add_palette_option_item(_palette_select, f)
	if not _palette_select.item_selected.is_connected(_on_palette_selected):
		_palette_select.item_selected.connect(_on_palette_selected)
	if palette_files.is_empty():
		_selected_palette_name = "None"
		_palette_select.add_item("No palettes found")
		_palette_select.disabled = true
		_rebuild_palette_swatches([])
		return
	_palette_select.disabled = false
	var initial_index := 0
	if _default_palette != "":
		for i in range(palette_files.size()):
			if palette_files[i] == _default_palette:
				initial_index = i
				break
	_palette_select.selected = initial_index
	_apply_palette_file(palette_files[initial_index])
	_update_status()


func _list_palette_files() -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open("res://addons/roksprite/palettes")
	if dir == null:
		return files
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name == "":
			break
		if dir.current_is_dir():
			continue
		if name.begins_with("."):
			continue
		if name.get_extension().to_lower() == "hex":
			files.append(name)
	dir.list_dir_end()
	files.sort()
	return files


func _set_active_palette_by_name(file_name: String) -> bool:
	if file_name == "" or _palette_select == null:
		return false
	for i in range(_palette_select.item_count):
		if _palette_file_from_option(_palette_select, i) == file_name:
			_palette_select.selected = i
			_apply_palette_file(file_name)
			return true
	return false


func _on_palette_selected(index: int) -> void:
	_apply_palette_file(_palette_file_from_option(_palette_select, index))
	_update_status()
	_mark_session_dirty()


func _apply_palette_file(file_name: String) -> void:
	_selected_palette_name = file_name
	_palette_colors = _load_palette_colors(file_name)
	_rebuild_palette_swatches(_palette_colors)
	_update_status()


func _load_palette_colors(file_name: String) -> Array[Color]:
	var colors: Array[Color] = []
	var path := "res://addons/roksprite/palettes/%s" % file_name
	if not FileAccess.file_exists(path):
		return colors
	return _load_palette_colors_from_path(path)


func _load_palette_colors_from_path(path: String) -> Array[Color]:
	var colors: Array[Color] = []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return colors
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line == "" or line.begins_with(";"):
			continue
		line = line.trim_prefix("0x")
		line = line.trim_prefix("#")
		if line.length() == 6:
			line += "ff"
		if line.length() != 8:
			continue
		var c := Color("#" + line)
		colors.append(c)
	return colors


func _on_file_selected_import_palette(path: String) -> void:
	if path == "":
		return
	if path.get_extension().to_lower() != "hex":
		_show_temporary_status("Select a .hex palette file", 1.6)
		return
	var imported_colors := _load_palette_colors_from_path(path)
	if imported_colors.is_empty():
		_show_temporary_status("Palette import failed: no valid colors in file", 1.8)
		return
	var src_name := path.get_file().strip_edges()
	if src_name == "":
		src_name = "imported_palette.hex"
	var base_name := src_name.get_basename()
	if base_name == "":
		base_name = "imported_palette"
	var out_path := _unique_palette_path("%s.hex" % base_name)
	var src_file := FileAccess.open(path, FileAccess.READ)
	if src_file == null:
		_show_temporary_status("Palette import failed: could not read file", 1.8)
		return
	var content := src_file.get_as_text()
	src_file.close()
	var out_file := FileAccess.open(out_path, FileAccess.WRITE)
	if out_file == null:
		_show_temporary_status("Palette import failed: cannot write to plugin palettes", 1.8)
		return
	out_file.store_string(content)
	out_file.close()
	_init_palette_dropdown()
	var imported_file := out_path.get_file()
	_set_active_palette_by_name(imported_file)
	_default_palette = imported_file
	_save_preferences()
	_mark_session_dirty()
	_show_temporary_status("Imported palette: %s (%d colors)" % [imported_file, imported_colors.size()], 1.8)


func _unique_palette_path(file_name: String) -> String:
	var dir_path := "res://addons/roksprite/palettes"
	var base := file_name.get_basename()
	if base == "":
		base = "imported_palette"
	var ext := file_name.get_extension().to_lower()
	if ext == "":
		ext = "hex"
	var candidate := "%s/%s.%s" % [dir_path, base, ext]
	var idx := 1
	while FileAccess.file_exists(candidate):
		candidate = "%s/%s_%d.%s" % [dir_path, base, idx, ext]
		idx += 1
	return candidate


func _rebuild_palette_swatches(colors: Array[Color]) -> void:
	for child in _palette_swatches.get_children():
		child.free()
	_selected_swatch_index = -1
	if colors.is_empty():
		return
	for i in range(colors.size()):
		var color := colors[i]
		var swatch := Button.new()
		swatch.toggle_mode = true
		swatch.focus_mode = Control.FOCUS_NONE
		swatch.custom_minimum_size = Vector2(_swatch_size, _swatch_size)
		swatch.tooltip_text = "#" + color.to_html(false).to_upper()
		swatch.add_theme_stylebox_override("normal", _make_swatch_style(color, false))
		swatch.add_theme_stylebox_override("hover", _make_swatch_style(color.lightened(0.06), false))
		swatch.add_theme_stylebox_override("pressed", _make_swatch_style(color, true))
		swatch.add_theme_stylebox_override("focus", _make_swatch_style(color, true))
		swatch.pressed.connect(_on_swatch_pressed.bind(i))
		_palette_swatches.add_child(swatch)
	_apply_swatch_row_layout(maxi(BASE_SWATCH_ROW_HEIGHT, _swatch_size + 8), _palette_swatches.get_theme_constant("h_separation"))
	_palette_swatches.queue_sort()
	if _swatch_scroll != null:
		_swatch_scroll.queue_sort()
	if _swatch_panel != null:
		_swatch_panel.queue_sort()
	if _swatch_center != null:
		_swatch_center.queue_sort()
	_select_swatch(0)


func _make_swatch_style(c: Color, selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = c
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 1, 1, 1) if selected else Color(0, 0, 0, 0.4)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.corner_radius_bottom_left = 2
	return style


func _on_swatch_pressed(index: int) -> void:
	_select_swatch(index)


func _select_swatch(index: int) -> void:
	if index < 0 or index >= _palette_colors.size():
		return
	_selected_swatch_index = index
	var children := _palette_swatches.get_children()
	for i in range(children.size()):
		var swatch := children[i] as Button
		if swatch == null:
			continue
		var is_selected := (i == index)
		swatch.button_pressed = is_selected
		var color := _palette_colors[i]
		swatch.add_theme_stylebox_override("normal", _make_swatch_style(color, is_selected))
		swatch.add_theme_stylebox_override("hover", _make_swatch_style(color.lightened(0.06), is_selected))
		swatch.add_theme_stylebox_override("pressed", _make_swatch_style(color, true))
		swatch.add_theme_stylebox_override("focus", _make_swatch_style(color, true))
	var picked := _palette_colors[index]
	_canvas.primary_color = picked
	_canvas.refresh_cursor_preview()
	_color_btn.color = picked
	_update_status()


# ---------------------------------------------------------------- Shortcuts

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not _is_space_pick_shortcut(k):
		return
	# Consume both press and release so focused buttons (ColorPickerButton/ui_accept)
	# cannot reopen dialogs after Space quick-pick.
	accept_event()
	if k.pressed and not k.echo and _canvas != null:
		_canvas.pick_color_under_mouse()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if _is_space_pick_shortcut(k):
			accept_event()
			if _canvas != null:
				_canvas.pick_color_under_mouse()
			return
		if _handle_grid_shortcut(k):
			accept_event()
			return
		if k.keycode == KEY_DELETE or k.keycode == KEY_BACKSPACE:
			if _canvas != null and _canvas.delete_selection_if_any():
				_show_temporary_status("Selection deleted.", 1.0)
				accept_event()
			return
		if _handle_sync_shortcut(k):
			accept_event()
			return
		if _handle_undo_redo_shortcut(k):
			accept_event()


func _shortcut_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	if _is_space_pick_shortcut(k):
		accept_event()
		if _canvas != null:
			_canvas.pick_color_under_mouse()
		return
	if _handle_grid_shortcut(k):
		accept_event()
		return
	if _handle_sync_shortcut(k):
		accept_event()
		return
	if _handle_undo_redo_shortcut(k):
		accept_event()


func _handle_undo_redo_shortcut(k: InputEventKey) -> bool:
	if _canvas == null:
		return false
	if not (k.ctrl_pressed or k.meta_pressed):
		return false
	if _is_key_z(k):
		if k.shift_pressed:
			_on_redo_pressed()
		else:
			_on_undo_pressed()
		return true
	if _is_key_y(k):
		_on_redo_pressed()
		return true
	return false


func _is_space_pick_shortcut(k: InputEventKey) -> bool:
	return k.keycode == KEY_SPACE and not (k.ctrl_pressed or k.meta_pressed or k.alt_pressed)


func _handle_grid_shortcut(k: InputEventKey) -> bool:
	if _canvas == null or _grid_toggle == null:
		return false
	if k.ctrl_pressed or k.meta_pressed or k.alt_pressed or k.shift_pressed:
		return false
	if k.keycode != KEY_APOSTROPHE and k.physical_keycode != KEY_APOSTROPHE:
		return false
	var enabled := not _canvas.show_grid
	_grid_toggle.set_pressed_no_signal(enabled)
	_on_grid_toggled(enabled)
	return true


func _handle_sync_shortcut(k: InputEventKey) -> bool:
	if not (k.ctrl_pressed or k.meta_pressed):
		return false
	if k.alt_pressed:
		return false
	if not _is_key_s(k):
		return false
	_on_sync_push_pressed()
	return true


func _is_key_z(k: InputEventKey) -> bool:
	return k.keycode == KEY_Z or k.physical_keycode == KEY_Z


func _is_key_y(k: InputEventKey) -> bool:
	return k.keycode == KEY_Y or k.physical_keycode == KEY_Y


func _is_key_s(k: InputEventKey) -> bool:
	return k.keycode == KEY_S or k.physical_keycode == KEY_S


# ---------------------------------------------------------------- Status

func _update_status() -> void:
	var tool_name := _tool_name(_canvas.current_tool)
	var c := _canvas.primary_color
	_status.text = "%dx%d  |  %s  |  #%s" % [
		_canvas.canvas_size, _canvas.canvas_size,
		tool_name,
		c.to_html(true).to_upper(),
	]
	_status.text += "  |  Palette: %s" % _selected_palette_name
	_status.text += "  |  Grid: %s" % ("On" if _canvas.show_grid else "Off")
	var cols_text := "Auto"
	if _export_columns > 0:
		cols_text = str(_export_columns)
	if _source_layout_locked:
		cols_text += " (Locked)"
	_status.text += "  |  Cols: %s" % cols_text
	if not _tileset_images.is_empty() and _current_tile_index >= 0:
		_status.text += "  |  Tile: %d/%d" % [_current_tile_index + 1, _tileset_images.size()]
	if _selected_swatch_index >= 0 and _selected_swatch_index < _palette_colors.size():
		_status.text += "  |  Swatch: #%s" % _palette_colors[_selected_swatch_index].to_html(false).to_upper()
	if _cursor_status != null:
		var save_text := "Last Save: %s" % _last_save_display
		if _hover_pixel_valid:
			_cursor_status.text = "Cursor: %d,%d  |  %s" % [_hover_pixel.x + 1, _hover_pixel.y + 1, save_text]
		else:
			_cursor_status.text = "Cursor: --,--  |  %s" % save_text
	else:
		if _hover_pixel_valid:
			_status.text += "  |  Cursor: %d,%d" % [_hover_pixel.x + 1, _hover_pixel.y + 1]
		else:
			_status.text += "  |  Cursor: --,--"
		_status.text += "  |  Last Save: %s" % _last_save_display


func _update_thumbnail_preview() -> void:
	if _thumb_preview == null or _canvas == null or _canvas.image == null:
		return
	var src := _canvas.get_display_image()
	if src == null:
		return
	var preview_img: Image
	if _thumb_repeat_tile:
		var tile_img := src if _thumb_scale <= 1 else src.duplicate() as Image
		if _thumb_scale > 1:
			tile_img.resize(src.get_width() * _thumb_scale, src.get_height() * _thumb_scale, Image.INTERPOLATE_NEAREST)
		var out_w := maxi(1, int(round(_thumb_preview.size.x)))
		var out_h := maxi(1, int(round(_thumb_preview.size.y)))
		preview_img = Image.create_empty(out_w, out_h, false, Image.FORMAT_RGBA8)
		preview_img.fill(Color(0, 0, 0, 0))
		var tw := maxi(1, tile_img.get_width())
		var th := maxi(1, tile_img.get_height())
		var x := int(floor((out_w - tw) * 0.5))
		var y_start := int(floor((out_h - th) * 0.5))
		while x > 0:
			x -= tw
		while y_start > 0:
			y_start -= th
		while x < out_w:
			var y := y_start
			while y < out_h:
				preview_img.blit_rect(tile_img, Rect2i(Vector2i.ZERO, Vector2i(tw, th)), Vector2i(x, y))
				y += th
			x += tw
	else:
		preview_img = src if _thumb_scale <= 1 else src.duplicate() as Image
		if _thumb_scale > 1:
			preview_img.resize(src.get_width() * _thumb_scale, src.get_height() * _thumb_scale, Image.INTERPOLATE_NEAREST)
	if _thumb_tex == null \
			or _thumb_tex.get_width() != preview_img.get_width() \
			or _thumb_tex.get_height() != preview_img.get_height():
		_thumb_tex = ImageTexture.create_from_image(preview_img)
	else:
		_thumb_tex.update(preview_img)
	_thumb_preview.texture = _thumb_tex
	_last_thumb_live_update_ms = Time.get_ticks_msec()


func _tool_name(t: int) -> String:
	match t:
		SpriteTools.Tool.PENCIL: return "Pencil"
		SpriteTools.Tool.ERASER: return "Eraser"
		SpriteTools.Tool.LINE: return "Line"
		SpriteTools.Tool.RECT_OUTLINE: return "Square Outline"
		SpriteTools.Tool.RECT_FILLED: return "Square Solid"
		SpriteTools.Tool.BUCKET: return "Bucket"
		SpriteTools.Tool.PICKER: return "Picker"
	return "?"
