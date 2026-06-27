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
	var bounds := get_polygon().get_rect()
	var cols := ceili(bounds.size.x / TILE_SIZE.x) + 1
	var rows := ceili(bounds.size.y / TILE_SIZE.y) + 1
	for y in rows:
		for x in cols:
			var pos := bounds.position + Vector2(x * TILE_SIZE.x, y * TILE_SIZE.y)
			draw_texture_rect(_texture, Rect2(pos, TILE_SIZE), false)
