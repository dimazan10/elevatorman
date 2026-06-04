extends Area2D

func _ready() -> void:
	body_exited.connect(_on_body_exited)

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	var game = get_tree().current_scene
	if game and game.has_method("start_exit_sequence"):
		game.start_exit_sequence()
