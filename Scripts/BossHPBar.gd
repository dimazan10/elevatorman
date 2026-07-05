extends CanvasLayer

var _bg: ColorRect
var _bar: ColorRect
var _max_hp := 1

func setup(robot: Node) -> void:
	var vp_size := get_viewport().get_visible_rect().size
	var bar_w := vp_size.x * 0.6
	var bar_h := 24.0
	var bar_x := (vp_size.x - bar_w) / 2.0
	var bar_y := 20.0

	_bg = ColorRect.new()
	_bg.name = "Bg"
	_bg.size = Vector2(bar_w, bar_h)
	_bg.position = Vector2(bar_x, bar_y)
	_bg.color = Color(0.15, 0.15, 0.15)
	add_child(_bg)

	_bar = ColorRect.new()
	_bar.name = "Bar"
	_bar.size = Vector2(bar_w, bar_h)
	_bar.position = Vector2(bar_x, bar_y)
	_bar.color = Color(0.8, 0.08, 0.08)
	add_child(_bar)

	if robot.has_signal("hp_changed"):
		_max_hp = robot.max_hp
		robot.hp_changed.connect(_on_hp_changed)

func _on_hp_changed(current: int, max_hp: int) -> void:
	if _bar:
		var ratio := float(current) / float(max_hp) if max_hp > 0 else 0.0
		_bar.size.x = _bg.size.x * ratio
