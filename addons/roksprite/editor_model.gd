@tool
class_name RokSpriteEditorModel
extends RefCounted


static func clone_images(images: Array[Image]) -> Array[Image]:
	var clones: Array[Image] = []
	for image in images:
		clones.append(image.duplicate() as Image if image != null else null)
	return clones


static func capture_snapshot(
		tiles: Array[Image],
		current_tile_index: int,
		palette_name: String,
		palette_colors: Array[Color],
		canvas_image: Image,
		export_columns: int,
		source_layout_locked: bool,
		source_cell_count: int,
		source_rows: int
) -> Dictionary:
	var canvas_copy := canvas_image.duplicate() as Image if canvas_image != null else null
	var tile_copies := clone_images(tiles)
	if current_tile_index >= 0 and current_tile_index < tile_copies.size() and canvas_copy != null:
		tile_copies[current_tile_index] = canvas_copy.duplicate() as Image
	return {
		"tiles": tile_copies,
		"current_tile_index": current_tile_index,
		"palette_name": palette_name,
		"palette_colors": palette_colors.duplicate(),
		"canvas_image": canvas_copy,
		"export_columns": export_columns,
		"source_layout_locked": source_layout_locked,
		"source_cell_count": source_cell_count,
		"source_rows": source_rows,
	}
