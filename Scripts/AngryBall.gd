extends RigidBody2D

# Желаемая постоянная скорость шара (в пикселях в секунду)
@export var CONSTANT_SPEED: float = 650.0

func _ready():
	# Даем стартовый случайный импульс, если шар еще не двигается
	if linear_velocity == Vector2.ZERO:
		var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		linear_velocity = direction * CONSTANT_SPEED

# Эта функция вызывается движком на каждом физическом кадре
func _integrate_forces(state: PhysicsDirectBodyState2D):
	# Проверяем, движется ли вообще шар (чтобы не делить на ноль)
	if linear_velocity.length() > 0:
		# .normalized() оставляет только направление полета
		# Умножая его на CONSTANT_SPEED, мы гарантируем строго фиксированную скорость
		linear_velocity = linear_velocity.normalized() * CONSTANT_SPEED
