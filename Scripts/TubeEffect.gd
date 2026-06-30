extends Area2D

@export var push_force: float = 2000.0

var _pushed: Array[Node] = []

func _ready() -> void:
	collision_mask = 7
	$DestroyTimer.start()
	call_deferred("_push_nearby_enemies")

func _push_nearby_enemies() -> void:
	var center = global_position
	for body in get_overlapping_bodies():
		if body.is_in_group("crate") and body not in _pushed:
			_pushed.append(body)
			var dir = body.global_position - center
			if dir.length_squared() < 0.001:
				dir = Vector2.RIGHT
			dir = dir.normalized()
			if body is StaticBody2D:
				var tw = create_tween()
				tw.tween_property(body, "global_position", body.global_position + dir * push_force * 0.1, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			continue
		if body.is_in_group("enemy") and body not in _pushed:
			_pushed.append(body)
			var dir = body.global_position - center
			if dir.length_squared() < 0.001:
				dir = Vector2.RIGHT
			dir = dir.normalized()
			var impulse = dir * push_force
			if body.has_method("apply_knockback"):
				body.apply_knockback(impulse)
			elif body is RigidBody2D:
				body.apply_central_impulse(impulse)
			else:
				body.linear_velocity = impulse

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("bullet"):
		body.queue_free()
		return
	if body.is_in_group("crate") and body not in _pushed:
		_pushed.append(body)
		var center = global_position
		var dir = body.global_position - center
		if dir.length_squared() < 0.001:
			dir = Vector2.RIGHT
		dir = dir.normalized()
		var impulse = dir * push_force
		if body is StaticBody2D:
			var tw = create_tween()
			tw.tween_property(body, "global_position", body.global_position + dir * push_force * 0.1, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		return
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
	elif body is RigidBody2D:
		body.apply_central_impulse(impulse)
	else:
		body.linear_velocity = impulse

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullet"):
		area.queue_free()

func _on_destroy_timeout() -> void:
	queue_free()
