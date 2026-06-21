extends Node

signal paused_state_changed(is_paused: bool)

var _paused := false
var _pause_env: Environment
var _world_env: WorldEnvironment
var _pause_layer: CanvasLayer
var _cheat_menu: Control


func _ready() -> void:
	_pause_env = Environment.new()
	_pause_env.adjustment_enabled = true
	_pause_env.adjustment_saturation = 0.0
	_world_env = WorldEnvironment.new()
	_world_env.name = "PauseWorldEnvironment"
	_world_env.environment = _pause_env
	add_child(_world_env)
	_world_env.environment = null

	_pause_layer = CanvasLayer.new()
	_pause_layer.name = "PauseLayer"
	_pause_layer.layer = 129
	_pause_layer.visible = false
	add_child(_pause_layer)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not get_tree().get_nodes_in_group("pausable").is_empty():
			toggle_pause()
			get_viewport().set_input_as_handled()
	if event is InputEventKey and event.keycode == KEY_F2 and event.pressed and not event.echo:
		if _cheat_menu and is_instance_valid(_cheat_menu):
			_cheat_menu.queue_free()
			_cheat_menu = null
			if not _paused:
				_pause_layer.visible = false
		else:
			_cheat_menu = preload("res://Scripts/CheatMenu.gd").new()
			_pause_layer.add_child(_cheat_menu)
			_pause_layer.visible = true
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	if _paused:
		_on_resume()
	else:
		_on_pause()


func is_paused() -> bool:
	return _paused


func _on_pause() -> void:
	_paused = true
	Engine.time_scale = 0.0
	_world_env.environment = _pause_env
	_set_process_mode_all(Node.PROCESS_MODE_DISABLED)
	_show_pause_menu()
	paused_state_changed.emit(true)


func _on_resume() -> void:
	_clear_pause_ui()
	_paused = false
	Engine.time_scale = 1.0
	_world_env.environment = null
	_set_process_mode_all(Node.PROCESS_MODE_INHERIT)
	paused_state_changed.emit(false)


func _on_exit() -> void:
	_clear_pause_ui()
	_paused = false
	Engine.time_scale = 1.0
	_world_env.environment = null
	_set_process_mode_all(Node.PROCESS_MODE_INHERIT)
	paused_state_changed.emit(false)
	GameState.current_floor = 1
	get_tree().change_scene_to_file("res://Scenes/MainMenu/MainMenu.tscn")


func _show_pause_menu() -> void:
	var menu = preload("res://Scripts/PauseMenu.gd").new()
	menu.resume_pressed.connect(_on_resume)
	menu.exit_pressed.connect(_on_exit)
	_pause_layer.add_child(menu)
	_pause_layer.visible = true


func _clear_pause_ui() -> void:
	_pause_layer.visible = false
	_cheat_menu = null
	for c in _pause_layer.get_children():
		c.queue_free()


func _set_process_mode_all(mode: Node.ProcessMode) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.process_mode = mode
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e):
			e.process_mode = mode
	for s in get_tree().get_nodes_in_group("switch"):
		if is_instance_valid(s):
			s.process_mode = mode
