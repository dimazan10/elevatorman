extends Area2D

@export var push_force: float = 2000.0
@export var push_radius: float = 500.0

var _pushed: Array[Node] = []

func _ready() -> void:
	collision_mask = 7
	$DestroyTimer.start()
	call_deferred("_push_nearby")

func _push_nearby() -> void:
	var center = global_position
	var space_state = get_world_2d().direct_space_state

	for crate in get_tree().get_nodes_in_group("crate"):
		if crate in _pushed:
			continue
		var dist: float = center.distance_to(crate.global_position)
		if dist > push_radius:
			continue
		_pushed.append(crate)
		var dir := center.direction_to(crate.global_position)
		if dir.length_squared() < 0.001:
			dir = Vector2.RIGHT

		var push_dist := push_force * 0.15
		var other := crate as Node2D
		var from: Vector2 = other.global_position
		var to: Vector2 = from + dir * push_dist
		var query := PhysicsRayQueryParameters2D.create(from, to, 3)
		query.exclude = [crate.get_rid()]
		var result := space_state.intersect_ray(query)
		if result:
			var wall_dist: float = from.distance_to(result.position)
			if wall_dist < 20.0:
				if crate.has_method("take_damage"):
					crate.take_damage(1)
				continue
			push_dist = wall_dist - 5.0
		push_dist = maxf(push_dist, 0.0)

		var tw := create_tween()
		tw.tween_property(crate, "global_position", from + dir * push_dist, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	for body in get_overlapping_bodies():
		if body in _pushed:
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
