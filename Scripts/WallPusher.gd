extends Area2D

@export var push_force: float = 600.0

var _bodies: Array[Node2D] = []

func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

func _on_enter(body: Node2D) -> void:
	if not body in _bodies:
		_bodies.append(body)

func _on_exit(body: Node2D) -> void:
	_bodies.erase(body)

func _physics_process(delta: float) -> void:
	if _bodies.is_empty():
		return
	var center = Vector2(640, 360)
	for body in _bodies:
		if not is_instance_valid(body):
			_bodies.erase(body)
			continue
		var dir = (center - body.global_position).normalized()
		if body is RigidBody2D:
			body.apply_central_impulse(dir * push_force * delta)
