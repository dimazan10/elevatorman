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
	h.color = Color(1, 0.3, 0.3)
	h.position = Vector2(-20, -2)
	ch.add_child(h)
	var v := ColorRect.new()
	v.name = "V"
	v.size = Vector2(4, 40)
	v.color = Color(1, 0.3, 0.3)
	v.position = Vector2(-2, -20)
	ch.add_child(v)

	var ring := Line2D.new()
	ring.name = "Ring"
	ring.width = 3.0
	ring.default_color = Color(1, 0.3, 0.3)
	var pts := PackedVector2Array()
	for i in range(33):
		var a := i * TAU / 32.0
		pts.append(Vector2(cos(a), sin(a)) * 30)
	ring.points = pts
	ch.add_child(ring)

	add_child(ch)

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
