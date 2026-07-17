extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var boss := get_tree().current_scene
		if boss and boss.has_method("activate_boss"):
			boss.activate_boss()
			queue_free()
