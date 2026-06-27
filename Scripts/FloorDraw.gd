extends Polygon2D

const TILE_TEXTURE_PATH := "res://Assets/FloorTile.jpg"
const TILE_SIZE := Vector2(320, 320)

var _texture: Texture2D

func _ready() -> void:
	_texture = load(TILE_TEXTURE_PATH)
	color = Color(1, 1, 1, 1)
	queue_redraw()

func _draw() -> void:
	if not _texture:
		return
	var poly := get_polygon()
	if poly.is_empty():
		return
	var bounds := Rect2(poly[0], Vector2.ZERO)
	for v in poly:
		bounds = bounds.expand(v)
	var cols := ceili(bounds.size.x / TILE_SIZE.x) + 1
	var rows := ceili(bounds.size.y / TILE_SIZE.y) + 1
	for y in rows:
		for x in cols:
			var tile_pos := bounds.position + Vector2(x * TILE_SIZE.x, y * TILE_SIZE.y)
			var center := tile_pos + TILE_SIZE * 0.5
			if _point_in_polygon(center, poly):
				draw_texture_rect(_texture, Rect2(tile_pos, TILE_SIZE), false)

func _point_in_polygon(point: Vector2, poly: PackedVector2Array) -> bool:
	var inside := false
	var n := poly.size()
	var j := n - 1
	for i in n:
		var vi := poly[i]
		var vj := poly[j]
		if ((vi.y > point.y) != (vj.y > point.y)) and (point.x < (vj.x - vi.x) * (point.y - vi.y) / (vj.y - vi.y) + vi.x):
			inside = not inside
		j = i
	return inside
