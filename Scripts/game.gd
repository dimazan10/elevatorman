extends Node2D

const MainArenaScene := preload("res://Objects/Rooms/main.tscn")
var _arena: Node

func _ready() -> void:
	_arena = MainArenaScene.instantiate()
	add_child(_arena)

func start_exit_sequence() -> void:
	if _arena and _arena.has_method("start_exit_sequence"):
		_arena.start_exit_sequence()

func start_restart() -> void:
	if _arena and _arena.has_method("start_restart"):
		_arena.start_restart()

func get_player_zone() -> String:
	if _arena and _arena.has_method("get_player_zone"):
		return _arena.get_player_zone()
	return ""
