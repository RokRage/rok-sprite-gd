@tool
class_name RokSpriteTilesetPngIO
extends RefCounted


static func slice(image: Image, tile_size: int, trim_trailing_empty: bool = true) -> Dictionary:
	if image == null or image.is_empty() or tile_size <= 0:
		return {}
	var columns := image.get_width() / tile_size
	var rows := image.get_height() / tile_size
	if columns <= 0 or rows <= 0:
		return {}
	var tiles: Array[Image] = []
	for row in range(rows):
		for column in range(columns):
			var tile := image.get_region(Rect2i(column * tile_size, row * tile_size, tile_size, tile_size))
			if tile == null:
				continue
			if tile.get_format() != Image.FORMAT_RGBA8:
				tile.convert(Image.FORMAT_RGBA8)
			tiles.append(tile)
	var source_cell_count := tiles.size()
	if trim_trailing_empty:
		while tiles.size() > 1 and is_fully_transparent(tiles.back()):
			tiles.pop_back()
	return {
		"tiles": tiles,
		"columns": columns,
		"rows": rows,
		"source_cell_count": source_cell_count,
		"dropped_width": image.get_width() - (columns * tile_size),
		"dropped_height": image.get_height() - (rows * tile_size),
	}


static func build(
		tiles: Array[Image],
		tile_size: int,
		columns: int,
		minimum_cell_count: int = 0,
		current_tile_index: int = -1,
		current_tile_override: Image = null
) -> Image:
	if tile_size <= 0:
		return null
	var cell_count := maxi(tiles.size(), minimum_cell_count)
	if cell_count <= 0:
		return current_tile_override
	columns = clampi(columns, 1, cell_count)
	var rows := int(ceil(float(cell_count) / float(columns)))
	var output := Image.create_empty(columns * tile_size, rows * tile_size, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	for index in range(tiles.size()):
		var source := current_tile_override if index == current_tile_index and current_tile_override != null else tiles[index]
		if source == null or source.is_empty():
			continue
		var tile := source.duplicate() as Image
		if tile.get_width() != tile_size or tile.get_height() != tile_size:
			tile.resize(tile_size, tile_size, Image.INTERPOLATE_NEAREST)
		if tile.get_format() != Image.FORMAT_RGBA8:
			tile.convert(Image.FORMAT_RGBA8)
		var destination := Vector2i((index % columns) * tile_size, (index / columns) * tile_size)
		output.blit_rect(tile, Rect2i(Vector2i.ZERO, Vector2i(tile_size, tile_size)), destination)
	return output


static func is_fully_transparent(tile: Image) -> bool:
	if tile == null or tile.is_empty():
		return true
	for y in range(tile.get_height()):
		for x in range(tile.get_width()):
			if tile.get_pixel(x, y).a > 0.0:
				return false
	return true
