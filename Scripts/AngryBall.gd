extends RigidBody2D

@export var CONSTANT_SPEED: float = 650.0
@export var ROTATION_SPEED: float = 12.0

var _direction: Vector2

func _ready():
	if linear_velocity == Vector2.ZERO:
		_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		if not _direction.is_finite():
			_direction = Vector2.RIGHT
		linear_velocity = _direction * CONSTANT_SPEED
	else:
		_direction = linear_velocity.normalized()
		if not _direction.is_finite():
			_direction = Vector2.RIGHT
	body_entered.connect(_on_body_entered)

func _integrate_forces(_state: PhysicsDirectBodyState2D):
	if linear_velocity.is_finite() and linear_velocity.length() > 0:
		_direction = linear_velocity.normalized()
	elif not _direction.is_finite():
		_direction = Vector2.RIGHT
	linear_velocity = _direction * CONSTANT_SPEED
	angular_velocity = ROTATION_SPEED

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
