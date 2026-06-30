extends RigidBody2D

@export var CONSTANT_SPEED: float = 650.0
@export var ROTATION_SPEED: float = 12.0

var _direction: Vector2
var _bounce_audio: AudioStreamPlayer2D
var _enraged := false
var _speed_multiplier := 1.0
var _kb_timer := 0.0

func _ready():
	if linear_velocity == Vector2.ZERO:
		_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		if not _direction.is_finite():
			_direction = Vector2.RIGHT
		linear_velocity = _direction * CONSTANT_SPEED
	else:
		if linear_velocity.is_finite():
			_direction = linear_velocity.normalized()
			if not _direction.is_finite():
				_direction = Vector2.RIGHT
		else:
			_direction = Vector2.RIGHT
	linear_velocity = _direction * CONSTANT_SPEED * _speed_multiplier
	_bounce_audio = AudioStreamPlayer2D.new()
	_bounce_audio.name = "BounceAudio"
	_bounce_audio.stream = preload("res://Assets/Sounds/Effects/AngryBallHit.mp3")
	_bounce_audio.bus = &"Effects"
	_bounce_audio.volume_db = -8.0
	add_child(_bounce_audio)

	body_entered.connect(_on_body_entered)

func _integrate_forces(state: PhysicsDirectBodyState2D):
	if _kb_timer > 0:
		_kb_timer -= state.step
	elif linear_velocity.is_finite() and linear_velocity.length() > 0:
		_direction = linear_velocity.normalized()
	if not _direction.is_finite():
		_direction = Vector2.RIGHT
	for i in state.get_contact_count():
		var normal = state.get_contact_local_normal(i)
		if normal.dot(_direction) > 0.1:
			_direction = _direction.bounce(normal)
			if not _direction.is_finite():
				_direction = Vector2.RIGHT
			break
	if state.get_contact_count() == 0:
		linear_velocity = _direction * CONSTANT_SPEED * _speed_multiplier
	else:
		linear_velocity = linear_velocity.move_toward(_direction * CONSTANT_SPEED * _speed_multiplier, 200.0)
	linear_velocity = linear_velocity.limit_length(CONSTANT_SPEED * _speed_multiplier * 1.5)
	if not linear_velocity.is_finite():
		linear_velocity = _direction * CONSTANT_SPEED * _speed_multiplier
	angular_velocity = ROTATION_SPEED

func _on_body_entered(body: Node) -> void:
	if _bounce_audio:
		_bounce_audio.play()
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1)

func set_target(_new_target: Node2D) -> void:
	pass

func apply_knockback(impulse: Vector2) -> void:
	_direction = impulse.normalized()
	if not _direction.is_finite():
		_direction = Vector2.RIGHT
	_kb_timer = 0.3

func set_enraged(enraged: bool) -> void:
	_enraged = enraged
	if enraged:
		modulate = Color(1.8, 0.7, 0.7)
		_speed_multiplier = 1.5
	else:
		modulate = Color.WHITE
		_speed_multiplier = 1.0
