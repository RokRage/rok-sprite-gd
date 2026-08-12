@tool
extends EditorPlugin

const MAIN_SCENE := preload("res://addons/roksprite/sprite_editor.tscn")
const ICON := preload("res://addons/roksprite/PixelRageIcon.png")

var _instance: Control


func _enter_tree() -> void:
	_instance = MAIN_SCENE.instantiate()
	EditorInterface.get_editor_main_screen().add_child(_instance)
	_make_visible(false)


func _exit_tree() -> void:
	if is_instance_valid(_instance):
		_instance.queue_free()
	_instance = null


func _has_main_screen() -> bool:
	return true


func _get_plugin_name() -> String:
	return "RokSprite"


func _get_plugin_icon() -> Texture2D:
	return ICON


func _make_visible(visible: bool) -> void:
	if is_instance_valid(_instance):
		if not visible and _instance.has_method("release_plugin_cursor"):
			_instance.release_plugin_cursor()
		_instance.visible = visible
