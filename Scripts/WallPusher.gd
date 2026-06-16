extends Area2D

var _bodies: Array[CharacterBody2D] = []
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
	if body is CharacterBody2D:
		if body not in _bodies:
			_bodies.append(body)

func _on_body_exited(body: Node2D):
	if body is CharacterBody2D:
		_bodies.erase(body)

func _physics_process(delta: float) -> void:
	if angular_velocity == 0.0 or _bodies.is_empty():
		return
	var i := 0
	while i < _bodies.size():
		var body = _bodies[i]
		if not is_instance_valid(body):
			_bodies.remove_at(i)
			continue
		var r = body.global_position - rotation_center
		var push = Vector2(-angular_velocity * r.y, angular_velocity * r.x)
		body.move_and_collide(push * delta)
		i += 1
