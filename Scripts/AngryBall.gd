extends RigidBody2D

# Желаемая постоянная скорость шара (в пикселях в секунду)
@export var CONSTANT_SPEED: float = 650.0

func _ready():
	if linear_velocity == Vector2.ZERO:
		var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		linear_velocity = direction * CONSTANT_SPEED
		
	# Подключаем сигнал столкновения кодом, чтобы не делать это вручную через интерфейс
	body_entered.connect(_on_body_entered)

func _integrate_forces(_state: PhysicsDirectBodyState2D):
	if linear_velocity.length() > 0:
		linear_velocity = linear_velocity.normalized() * CONSTANT_SPEED

# Эта функция срабатывает каждый раз, когда шар бьется обо что-то твердое
func _on_body_entered(body: Node) -> void:
	# Проверяем, находится ли объект, в который мы врезались, в группе "player"
	if body.is_in_group("player"):
		# Если это игрок и у него есть функция take_damage, вызываем её
		if body.has_method("take_damage"):
			body.take_damage(1)
