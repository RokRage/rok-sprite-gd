@tool
class_name RokSpriteSelectionOverlay
extends Control

const FILL_COLOR := Color(0.98, 0.93, 0.16, 0.12)
const BORDER_COLOR := Color(0.98, 0.93, 0.16, 0.95)

var _selection_rect := Rect2()
var _active := false


func set_selection(rect: Rect2i, pixel_scale: int, active: bool) -> void:
	_active = active and rect.size.x > 0 and rect.size.y > 0
	_selection_rect = Rect2(
		Vector2(rect.position * pixel_scale),
		Vector2(rect.size * pixel_scale)
	)
	queue_redraw()


func _draw() -> void:
	if not _active:
		return
	draw_rect(_selection_rect, FILL_COLOR, true)
	draw_rect(_selection_rect, BORDER_COLOR, false, 1.0)
