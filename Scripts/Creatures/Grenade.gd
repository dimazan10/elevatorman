extends Area2D

const FIRE_TRAIL_SCENE = preload("res://Objects/Summons/FireTrail.tscn")

@export var speed: float = 400.0
@export var arc_height: float = 250.0
@export var peak_time: float = 0.35
@export var flight_time: float = 1.0

var target_pos: Vector2 = Vector2.ZERO
var _start_pos: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0
var _arrived: bool = false
var _sprite: AnimatedSprite2D

func _ready() -> void:
	add_to_group("grenade")
	_start_pos = global_position

	_sprite = AnimatedSprite2D.new()
	_sprite.z_index = 10
	add_child(_sprite)

	var frames := SpriteFrames.new()
	if not frames.has_animation(&"default"):
		frames.add_animation(&"default")
	frames.set_animation_loop(&"default", true)
	frames.set_animation_speed(&"default", 10.0)
	for i in 5:
		var tex = load("res://Assets/Enemies/GrenadeMan/grenade_%d.png" % i) as Texture2D
		if tex:
			frames.add_frame(&"default", tex)
	_sprite.sprite_frames = frames
	_sprite.play(&"default")

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 8.0
	col.shape = shape
	add_child(col)

	collision_layer = 1
	collision_mask = 0

	monitoring = false

func _physics_process(delta: float) -> void:
	if _arrived:
		return

	_elapsed += delta
	var t := clampf(_elapsed / flight_time, 0.0, 1.0)

	var flat_pos := _start_pos.lerp(target_pos, t)

	var arc: float
	if t < peak_time:
		arc = arc_height * (t / peak_time)
	else:
		arc = arc_height * (1.0 - (t - peak_time) / (1.0 - peak_time))

	global_position = flat_pos + Vector2(0, -arc)

	_sprite.rotation += delta * 8.0

	if t >= 1.0:
		_explode()

func _explode() -> void:
	_arrived = true

	var fire = FIRE_TRAIL_SCENE.instantiate()
	fire.global_position = target_pos
	get_tree().current_scene.add_child(fire)

	var nearby := get_overlapping_bodies() if monitoring else []
	for body in nearby:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(2)

	queue_free()
