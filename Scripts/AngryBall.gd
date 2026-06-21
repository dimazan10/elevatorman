extends RigidBody2D

@export var CONSTANT_SPEED: float = 650.0
@export var ROTATION_SPEED: float = 12.0

var _direction: Vector2
var _bounce_audio: AudioStreamPlayer2D

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
			linear_velocity = _direction * CONSTANT_SPEED
	_bounce_audio = AudioStreamPlayer2D.new()
	_bounce_audio.name = "BounceAudio"
	_bounce_audio.stream = preload("res://Assets/Sounds/Effects/AngryBallHit.mp3")
	_bounce_audio.bus = &"Effects"
	_bounce_audio.volume_db = -8.0
	add_child(_bounce_audio)

	body_entered.connect(_on_body_entered)

func _integrate_forces(_state: PhysicsDirectBodyState2D):
	if linear_velocity.is_finite() and linear_velocity.length() > 0:
		_direction = linear_velocity.normalized()
	elif not _direction.is_finite():
		_direction = Vector2.RIGHT
	linear_velocity = _direction * CONSTANT_SPEED
	angular_velocity = ROTATION_SPEED

func _on_body_entered(body: Node) -> void:
	if _bounce_audio:
		_bounce_audio.play()
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
