extends Polygon2D

const TILE_TEXTURE_PATH := "res://Assets/Art/FloorTile.jpg"
const TILE_SIZE := 320.0

func _ready() -> void:
	texture = load(TILE_TEXTURE_PATH)
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var poly := get_polygon()
	if poly.is_empty():
		return
	var bounds := Rect2(poly[0], Vector2.ZERO)
	for v in poly:
		bounds = bounds.expand(v)
	texture_scale = bounds.size / TILE_SIZE
	color = Color(0.5, 0.55, 0.6)
