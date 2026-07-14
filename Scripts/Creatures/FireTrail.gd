extends Area2D

@export var duration: float = 6.0
@export var damage_interval: float = 0.5
@export var damage: int = 1

var _elapsed: float = 0.0
var _damage_timer: float = 0.0
var _sprite: AnimatedSprite2D
var _col: CollisionShape2D

func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.z_index = 2
	_sprite.scale = Vector2(2.5, 2.5)
	add_child(_sprite)

	var frames := SpriteFrames.new()
	frames.add_animation(&"default")
	frames.set_animation_loop(&"default", true)
	frames.set_animation_speed(&"default", 12.0)
	for i in 16:
		var tex = load("res://Assets/Enemies/GrenadeMan/fire_%d.png" % i) as Texture2D
		if tex:
			frames.add_frame(&"default", tex)
	_sprite.sprite_frames = frames
	_sprite.play(&"default")
	_sprite.frame_changed.connect(_on_frame_changed)
	_update_collision_shape()

func _on_frame_changed() -> void:
	_update_collision_shape()

func _update_collision_shape() -> void:
	var tex = _sprite.sprite_frames.get_frame_texture(&"default", _sprite.frame)
	if tex:
		var sz = tex.get_size() * _sprite.scale.x * 0.45
		_col.shape.radius = sz

	_col = CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 50.0
	_col.shape = shape
	add_child(_col)

	collision_layer = 0
	collision_mask = 1
	monitoring = true

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	_elapsed += delta
	_damage_timer -= delta

	if _damage_timer <= 0:
		_damage_timer = damage_interval
		for body in get_overlapping_bodies():
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(damage)

	var t := _elapsed / duration
	if t > 0.7:
		_sprite.modulate.a = maxf(1.0 - (t - 0.7) / 0.3, 0.0)
		if t > 0.85:
			set_deferred("monitoring", false)

	if _elapsed >= duration:
		queue_free()

func _on_body_entered(_body: Node2D) -> void:
	pass

func _on_body_exited(_body: Node2D) -> void:
	pass
