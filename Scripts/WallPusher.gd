extends Area2D

var _bodies: Array[Node2D] = []
var angular_velocity: float = 0.0
var rotation_center: Vector2 = Vector2.ZERO

func _ready():
	collision_layer = 1
	collision_mask = 1
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D):
	if body is CharacterBody2D or body.is_in_group("crate"):
		if body not in _bodies:
			_bodies.append(body)

func _on_body_exited(body: Node2D):
	if body is CharacterBody2D or body.is_in_group("crate"):
		_bodies.erase(body)

func _physics_process(delta: float) -> void:
	if angular_velocity == 0.0 or _bodies.is_empty():
		return
	var space_state = get_world_2d().direct_space_state
	var i := 0
	while i < _bodies.size():
		var body = _bodies[i]
		if not is_instance_valid(body):
			_bodies.remove_at(i)
			continue
		var r = body.global_position - rotation_center
		var push = Vector2(-angular_velocity * r.y, angular_velocity * r.x)
		if body is CharacterBody2D:
			body.move_and_collide(push * delta)
		else:
			body.global_position += push * delta
			if push.length() > 50.0:
				var from: Vector2 = body.global_position
				var to := from + push.normalized() * 12.0
				var query := PhysicsRayQueryParameters2D.create(from, to, 3)
				query.exclude = [body.get_rid()]
				var result := space_state.intersect_ray(query)
				if result and body.has_method("take_damage"):
					body.take_damage(1)
		i += 1
