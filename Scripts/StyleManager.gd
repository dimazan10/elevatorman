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
	if OS.is_debug_build() and event is InputEventKey and event.keycode == KEY_F3 and event.pressed and not event.echo:
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
			_label.text = "STYLE: " + str(int(_score))

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
		_label.text = "STYLE: " + str(int(_score))

func _calc_multiplier() -> float:
	if not _player:
		return 1.0
	var lives = float(_player.current_lives)
	var max_lives = float(_player.max_lives)
	return 1.0 + (lives - 1.0) / (max_lives - 1.0) * 0.5

func reset_score() -> void:
	_score = 0.0
	if _label and is_instance_valid(_label):
		_label.text = "STYLE: 0"

func setup_display(_parent: Node) -> void:
	pass
