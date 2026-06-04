extends RigidBody2D

# Желаемая постоянная скорость шара (в пикселях в секунду)
@export var CONSTANT_SPEED: float = 650.0

var _direction: Vector2

func _ready():
	_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	body_entered.connect(_on_body_entered)

func _integrate_forces(state: PhysicsDirectBodyState2D):
	if not freeze:
		var vel := state.linear_velocity
		if vel.length() > 0:
			state.linear_velocity = vel.normalized() * CONSTANT_SPEED
		else:
			state.linear_velocity = _direction * CONSTANT_SPEED

# Эта функция срабатывает каждый раз, когда шар бьется обо что-то твердое
func _on_body_entered(body: Node) -> void:
	# Проверяем, находится ли объект, в который мы врезались, в группе "player"
	if body.is_in_group("player"):
		# Если это игрок и у него есть функция take_damage, вызываем её
		if body.has_method("take_damage"):
			body.take_damage(1)
