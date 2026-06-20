extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var sm = get_tree().get_first_node_in_group("style_manager")
		if sm and sm.has_method("add_danger"):
			sm.add_danger()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		var sm = get_tree().get_first_node_in_group("style_manager")
		if sm and sm.has_method("remove_danger"):
			sm.remove_danger()
