extends CanvasLayer

signal fire_requested

var _crosshair_pos := Vector2(640, 360)

func _ready() -> void:
	layer = 131
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0, 0, 0, 0.6)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

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
	add_child(ch)

func set_crosshair_pos(pos: Vector2) -> void:
	_crosshair_pos = pos

func _process(_delta: float) -> void:
	var ch := get_node_or_null("Crosshair") as Node2D
	if ch:
		ch.global_position = _crosshair_pos

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		fire_requested.emit()
