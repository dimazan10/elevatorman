extends Area2D

@export var push_force: float = 800.0

var _pushed: Array[Node] = []

func _ready() -> void:
	$DestroyTimer.start()
	_push_nearby_enemies()

func _push_nearby_enemies() -> void:
	var center = global_position
	for body in get_overlapping_bodies():
		if body.is_in_group("enemy") and body not in _pushed:
			_pushed.append(body)
			var dir = body.global_position - center
			if dir.length_squared() < 0.001:
				dir = Vector2.RIGHT
			dir = dir.normalized()
			var impulse = dir * push_force
			if body.has_method("apply_knockback"):
				body.apply_knockback(impulse)
			else:
				body.linear_velocity = impulse

func _on_body_entered(body: Node2D) -> void:
	if body in _pushed:
		return
	if not body.is_in_group("enemy"):
		return
	_pushed.append(body)
	var center = global_position
	var dir = body.global_position - center
	if dir.length_squared() < 0.001:
		dir = Vector2.RIGHT
	dir = dir.normalized()
	var impulse = dir * push_force
	if body.has_method("apply_knockback"):
		body.apply_knockback(impulse)
	else:
		body.linear_velocity = impulse

func _on_destroy_timeout() -> void:
	queue_free()
