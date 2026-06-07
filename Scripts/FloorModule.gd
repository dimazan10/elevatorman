extends Node2D
# Base script for floor modules
# Each floor module inherits this or uses this directly

@export var floor_index: int = 0
@export var quest_type: String = "SURVIVE"  # SURVIVE, LEVERS, OTHER_LIFT, TRADER
@export var timer_duration: int = 15
@export var spawn_point: NodePath = NodePath("SpawnPoint")

signal quest_started
signal quest_completed

var timer: Timer

func _ready() -> void:
	# Create timer if not exists
	timer = Timer.new()
	timer.name = "QuestTimer"
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)

func start_quest() -> void:
	emit_signal("quest_started")
	match quest_type:
		"SURVIVE":
			timer.start(timer_duration)

func _on_timer_timeout() -> void:
	emit_signal("quest_completed")

func get_spawn_point() -> Vector2:
	var sp = get_node_or_null(spawn_point)
	if sp:
		return sp.global_position
	return global_position

func stop_quest() -> void:
	if timer:
		timer.stop()
