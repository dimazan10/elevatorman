extends CharacterBody2D

const BULLET = preload("res://Objects/Bullet.tscn")

@export var speed: float = 150.0
@export var orbit_distance: float = 250.0
@export var shoot_spread: float = 15.0

@onready var sprite := $Sprite2D
@onready var anchor := $WeaponAnchor
@onready var muzzle := $WeaponAnchor/Muzzle
@onready var burst := $BurstTimer
@onready var shot_delay := $ShotDelayTimer
@onready var melee := $MeleeZone

var player: Node2D = null
var can_act := false
var _started := false

enum State { MOVE, SHOOT }
var state := State.MOVE
var burst_count := 0

func _ready() -> void:
	var p = get_tree().get_nodes_in_group("player")
	if p: player = p[0]
	burst.one_shot = true
	burst.timeout.connect(_on_burst)
	shot_delay.wait_time = 0.15
	shot_delay.timeout.connect(_on_shot_delay)
	melee.body_entered.connect(_on_melee)

func _physics_process(_delta: float) -> void:
	if not can_act or not player:
		return
	if not _started:
		_started = true
		state = State.MOVE
		burst.wait_time = randf_range(1.0, 2.0)
		burst.start()
	anchor.look_at(player.global_position)
	if player.global_position.x < global_position.x:
		sprite.flip_h = true
		anchor.scale.y = -1
	else:
		sprite.flip_h = false
		anchor.scale.y = 1
	match state:
		State.MOVE:
			var dir = (player.global_position - global_position).normalized()
			var tang = Vector2(-dir.y, dir.x)
			var dist = global_position.distance_to(player.global_position)
			var wish = tang
			if dist > orbit_distance + 20:
				wish = (tang + dir).normalized()
			elif dist < orbit_distance - 20:
				wish = (tang - dir).normalized()
			velocity = wish * speed
			move_and_slide()
		State.SHOOT:
			velocity = Vector2.ZERO
			move_and_slide()

func _on_burst() -> void:
	if not can_act or state != State.MOVE:
		return
	state = State.SHOOT
	burst_count = randi_range(3, 4)
	fire()

func fire() -> void:
	var b = BULLET.instantiate()
	b.global_position = muzzle.global_position
	var d = Vector2.RIGHT.rotated(anchor.global_rotation)
	d = d.rotated(deg_to_rad(randf_range(-shoot_spread, shoot_spread)))
	b.direction = d
	get_tree().current_scene.add_child(b)
	burst_count -= 1
	if burst_count > 0:
		shot_delay.start()
	else:
		state = State.MOVE
		burst.wait_time = randf_range(1.0, 2.0)
		burst.start()

func _on_shot_delay() -> void:
	if can_act:
		fire()

func _on_melee(body: Node2D) -> void:
	if not can_act or not body.is_in_group("player"):
		return
	if body.has_method("apply_stun_and_knockback"):
		var k = (body.global_position - global_position).normalized() * 500.0
		body.apply_stun_and_knockback(k, 1.0)

func reset() -> void:
	_started = false
	state = State.MOVE
	burst.stop()
	shot_delay.stop()
