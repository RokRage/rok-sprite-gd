@tool
class_name RokSpriteCommandHistory
extends RefCounted

var _undo: Array[Dictionary] = []
var _redo: Array[Dictionary] = []
var _capacity: int


func _init(capacity: int = 32) -> void:
	_capacity = maxi(1, capacity)


func clear() -> void:
	_undo.clear()
	_redo.clear()


func push(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	_undo.append(snapshot)
	if _undo.size() > _capacity:
		_undo.pop_front()
	_redo.clear()


func can_undo() -> bool:
	return not _undo.is_empty()


func can_redo() -> bool:
	return not _redo.is_empty()


func undo(current: Dictionary) -> Dictionary:
	if _undo.is_empty():
		return {}
	_redo.append(current)
	return _undo.pop_back()


func redo(current: Dictionary) -> Dictionary:
	if _redo.is_empty():
		return {}
	_undo.append(current)
	return _redo.pop_back()


func undo_count() -> int:
	return _undo.size()


func redo_count() -> int:
	return _redo.size()
