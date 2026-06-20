extends Area2D

@export var radius: float = 250.0

func _ready() -> void:
	var cs = $CollisionShape2D
	if cs and cs.shape is CircleShape2D:
		cs.shape.radius = radius
	queue_redraw()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _draw() -> void:
	var cs = $CollisionShape2D
	if not cs or not cs.shape:
		return
	if cs.shape is CircleShape2D:
		var r = cs.shape.radius
		draw_circle(Vector2.ZERO, r, Color(1, 0, 0, 0.08))
		draw_arc(Vector2.ZERO, r, 0, TAU, 64, Color(1, 0, 0, 0.4), 1.0)
	elif cs.shape is RectangleShape2D:
		var s = cs.shape.size
		var rect = Rect2(-s * 0.5, s)
		draw_rect(rect, Color(1, 0, 0, 0.08))
		draw_rect(rect, Color(1, 0, 0, 0.4), false, 1.0)

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
