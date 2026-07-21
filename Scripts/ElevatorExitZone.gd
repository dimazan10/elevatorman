extends Area2D

func _ready() -> void:
	monitoring = false
	body_exited.connect(_on_body_exited)

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	monitoring = false
	var boss := get_tree().current_scene
	if boss and boss.has_method("start_exit_sequence"):
		boss.start_exit_sequence()
