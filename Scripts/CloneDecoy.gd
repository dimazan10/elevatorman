extends CharacterBody2D

signal decoy_destroyed

@export var wander_speed: float = 200.0
@export var lifetime: float = 5.0
@export var change_direction_interval: float = 1.0

var _direction: Vector2 = Vector2.RIGHT
var _change_dir_timer: float = 0.0
var _animated_sprite: AnimatedSprite2D

func _ready() -> void:
	modulate = Color(0.3, 0.5, 1.0, 0.9)
	_animated_sprite = $AnimatedSprite2D
	_setup_sprite_frames()
	_randomize_direction()
	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_end)

func _setup_sprite_frames() -> void:
	if not _animated_sprite:
		return
	var frames = SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 5)
	for i in range(1, 5):
		var tex = load("res://Assets/Sprites_Player/gg" + str(i) + ".png")
		frames.add_frame("idle", tex)
	frames.set_animation_loop("idle", true)
	frames.add_animation("walk_up")
	frames.set_animation_speed("walk_up", 5)
	for i in range(1, 5):
		var tex = load("res://Assets/Sprites_Player/ggspina" + str(i) + ".png")
		frames.add_frame("walk_up", tex)
	frames.set_animation_loop("walk_up", true)
	_animated_sprite.sprite_frames = frames
	_animated_sprite.play("walk_up")

func _randomize_direction() -> void:
	var angle = randf_range(0, TAU)
	_direction = Vector2(cos(angle), sin(angle)).normalized()
	if not _direction.is_finite():
		_direction = Vector2.RIGHT

func _physics_process(delta: float) -> void:
	_change_dir_timer += delta
	if _change_dir_timer >= change_direction_interval:
		_change_dir_timer = 0.0
		if randf() < 0.5:
			_randomize_direction()

	var collision = move_and_collide(_direction * wander_speed * delta)
	if collision:
		_direction = _direction.bounce(collision.get_normal())
		if not _direction.is_finite():
			_direction = Vector2.RIGHT

	if _animated_sprite:
		if _direction.x > 0:
			_animated_sprite.flip_h = false
		else:
			_animated_sprite.flip_h = true

func _on_lifetime_end() -> void:
	decoy_destroyed.emit()
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	await tw.finished
	queue_free()
