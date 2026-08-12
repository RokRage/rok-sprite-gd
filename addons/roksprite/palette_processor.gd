@tool
class_name RokSpritePaletteProcessor
extends RefCounted


static func extract(source: Image, limit: int) -> Array[Color]:
	var colors: Array[Color] = []
	if source == null or source.is_empty() or limit <= 0:
		return colors
	var image := source
	if image.get_format() != Image.FORMAT_RGBA8:
		image = image.duplicate() as Image
		image.convert(Image.FORMAT_RGBA8)
	var seen := {}
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a <= 0.0:
				continue
			var key := color.to_html(true).to_upper()
			if seen.has(key):
				continue
			seen[key] = true
			colors.append(color)
			if colors.size() >= limit:
				return colors
	return colors


static func remap(source: Image, palette: Array[Color]) -> Image:
	var output := source.duplicate() as Image
	if output == null or output.is_empty() or palette.is_empty():
		return source
	if output.get_format() != Image.FORMAT_RGBA8:
		output.convert(Image.FORMAT_RGBA8)
	var palette_lab: Array[Vector3] = []
	for color in palette:
		palette_lab.append(_to_oklab(color))
	for y in range(output.get_height()):
		for x in range(output.get_width()):
			var color := output.get_pixel(x, y)
			if color.a <= 0.0:
				continue
			var target := _to_oklab(color)
			var best_index := 0
			var best_distance := INF
			for index in range(palette.size()):
				var delta := target - palette_lab[index]
				var distance := (delta.x * delta.x * 2.0) + (delta.y * delta.y) + (delta.z * delta.z)
				if distance < best_distance:
					best_distance = distance
					best_index = index
			output.set_pixel(x, y, palette[best_index])
	return output


static func _to_oklab(color: Color) -> Vector3:
	var red := _srgb_to_linear(color.r)
	var green := _srgb_to_linear(color.g)
	var blue := _srgb_to_linear(color.b)
	var l_value := _cube_root(0.4122214708 * red + 0.5363325363 * green + 0.0514459929 * blue)
	var m_value := _cube_root(0.2119034982 * red + 0.6806995451 * green + 0.1073969566 * blue)
	var s_value := _cube_root(0.0883024619 * red + 0.2817188376 * green + 0.6299787005 * blue)
	return Vector3(
		0.2104542553 * l_value + 0.7936177850 * m_value - 0.0040720468 * s_value,
		1.9779984951 * l_value - 2.4285922050 * m_value + 0.4505937099 * s_value,
		0.0259040371 * l_value + 0.7827717662 * m_value - 0.8086757660 * s_value
	)


static func _srgb_to_linear(value: float) -> float:
	return value / 12.92 if value <= 0.04045 else pow((value + 0.055) / 1.055, 2.4)


static func _cube_root(value: float) -> float:
	return signf(value) * pow(absf(value), 1.0 / 3.0) if value != 0.0 else 0.0
