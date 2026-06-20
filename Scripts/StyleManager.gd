extends Node

var _score: float = 0.0
var _active_dangers: int = 0
var _player: Node2D
var _label: Label

func _ready() -> void:
	add_to_group("style_manager")

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
	_score = 0.0
	if _label:
		_label.text = "СТИЛЬ: 0"

func _calc_multiplier() -> float:
	if not _player:
		return 1.0
	return 1.0 + float(_player.max_lives - _player.current_lives) * 1.0

func setup_display(parent: Node) -> void:
	if _label and is_instance_valid(_label):
		_label.get_parent().queue_free()
	_score = 0.0
	var ui = CanvasLayer.new()
	ui.name = "StyleUI"
	ui.layer = 128
	parent.add_child(ui)
	_label = Label.new()
	_label.name = "StyleLabel"
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_label.add_theme_constant_override("outline_size", 4)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.size = Vector2(270, 40)
	_label.position = Vector2(1000, 10)
	_label.text = "СТИЛЬ: 0"
	ui.add_child(_label)
