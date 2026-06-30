extends CanvasLayer

signal fire_requested

var _crosshair_pos := Vector2(640, 360)

func _ready() -> void:
	layer = 131

	var ch := Node2D.new()
	ch.name = "Crosshair"
	var h := ColorRect.new()
	h.name = "H"
	h.size = Vector2(40, 4)
	h.color = Color(1, 0.2, 0.2, 0.6)
	h.position = Vector2(-20, -2)
	ch.add_child(h)
	var v := ColorRect.new()
	v.name = "V"
	v.size = Vector2(4, 40)
	v.color = Color(1, 0.2, 0.2, 0.6)
	v.position = Vector2(-2, -20)
	ch.add_child(v)
	add_child(ch)

	_set_circle_cursor()

func _set_circle_cursor() -> void:
	var size := 48
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var cx := size / 2
	var cy := size / 2
	var r := 12.0
	var col := Color(1, 0.2, 0.2, 200.0 / 255.0)
	for x in range(size):
		for y in range(size):
			var d := Vector2(x - cx, y - cy).length()
			if d > r - 1.5 and d < r + 1.5:
				img.set_pixel(x, y, col)
	var tex := ImageTexture.create_from_image(img)
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, Vector2(cx, cy))

func _exit_tree() -> void:
	Input.set_custom_mouse_cursor(null)

func set_crosshair_pos(pos: Vector2) -> void:
	_crosshair_pos = pos

func _process(_delta: float) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var ch := get_node_or_null("Crosshair") as Node2D
	if ch:
		ch.global_position = _crosshair_pos

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		fire_requested.emit()
