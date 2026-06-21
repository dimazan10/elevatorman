extends Node

var _score: float = 0.0
var _active_dangers: int = 0
var _player: Node2D
var _label: Label

const _DANGER_ZONE = preload("res://Scripts/DangerZone.gd")

var _show_danger_debug := false

func _ready() -> void:
	add_to_group("style_manager")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_F3 and event.pressed and not event.echo:
		_show_danger_debug = not _show_danger_debug
		_DANGER_ZONE.show_debug = _show_danger_debug
		for dz in get_tree().get_nodes_in_group("danger_zone"):
			dz.queue_redraw()

func _process(delta: float) -> void:
	if not _player or _player.process_mode == PROCESS_MODE_DISABLED:
		return
	if _active_dangers > 0:
		var mult = _calc_multiplier()
		_score += _active_dangers * mult * delta * 10.0
		if _label:
			_label.text = "СТИЛЬ: " + str(int(_score))

func add_danger() -> void:
	_active_dangers += 1
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
		if _player and _player.has_signal("health_changed"):
			_player.health_changed.connect(_reset_score)

func remove_danger() -> void:
	_active_dangers = maxi(0, _active_dangers - 1)

func _reset_score(_new_hp: int) -> void:
	_score *= 0.5
	if _label:
		_label.text = "СТИЛЬ: " + str(int(_score))

func _calc_multiplier() -> float:
	if not _player:
		return 1.0
	var lives = float(_player.current_lives)
	var max_lives = float(_player.max_lives)
	return 1.0 + (lives - 1.0) / (max_lives - 1.0) * 0.5

func setup_display(parent: Node) -> void:
	if _label and is_instance_valid(_label):
		_label.get_parent().get_parent().queue_free()
	_score = 0.0
	var ui = CanvasLayer.new()
	ui.name = "StyleUI"
	ui.layer = 128
	parent.add_child(ui)
	var container = Control.new()
	container.name = "StyleContainer"
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(container)
	_label = Label.new()
	_label.name = "StyleLabel"
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_label.add_theme_constant_override("outline_size", 4)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.size = Vector2(270, 40)
	var vp_size = parent.get_viewport_rect().size
	_label.position = Vector2(vp_size.x - 280, 10)
	_label.text = "СТИЛЬ: 0"
	container.add_child(_label)
