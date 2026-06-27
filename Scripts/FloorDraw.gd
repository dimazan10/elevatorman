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
			var tile_rect := Rect2(tile_pos, TILE_SIZE)
			if _rect_intersects_polygon(tile_rect, poly):
				draw_texture_rect(_texture, tile_rect, false)

func _rect_intersects_polygon(rect: Rect2, poly: PackedVector2Array) -> bool:
	if _point_in_polygon(rect.position, poly):
		return true
	if _point_in_polygon(rect.end, poly):
		return true
	if _point_in_polygon(Vector2(rect.position.x, rect.end.y), poly):
		return true
	if _point_in_polygon(Vector2(rect.end.x, rect.position.y), poly):
		return true
	var center := rect.position + rect.size * 0.5
	if _point_in_polygon(center, poly):
		return true
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		if _segment_intersects_rect(a, b, rect):
			return true
	return false

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

func _segment_intersects_rect(a: Vector2, b: Vector2, r: Rect2) -> bool:
	if r.has_point(a) or r.has_point(b):
		return true
	var corners: Array[Vector2] = [
		r.position, Vector2(r.end.x, r.position.y),
		r.end, Vector2(r.position.x, r.end.y),
	]
	for i in 4:
		var c1: Vector2 = corners[i]
		var c2: Vector2 = corners[(i + 1) % 4]
		if _segments_intersect(a, b, c1, c2):
			return true
	return false

func _segments_intersect(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> bool:
	var d1 := a2 - a1
	var d2 := b2 - b1
	var cross := d1.x * d2.y - d1.y * d2.x
	if abs(cross) < 0.0001:
		return false
	var t := ((b1.x - a1.x) * d2.y - (b1.y - a1.y) * d2.x) / cross
	var u := ((b1.x - a1.x) * d1.y - (b1.y - a1.y) * d1.x) / cross
	return t >= 0.0 and t <= 1.0 and u >= 0.0 and u <= 1.0
