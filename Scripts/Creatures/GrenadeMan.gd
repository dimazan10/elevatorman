extends CharacterBody2D

const GRENADE_SCENE = preload("res://Objects/Summons/Grenade.tscn")

@export var speed: float = 120.0
@export var throw_cooldown: float = 1.8
@export var throw_range_min: float = 150.0
@export var throw_range_max: float = 400.0

var _player_ref: Node2D = null
var _enraged := false
var _speed_multiplier := 1.0
var _knockback := Vector2.ZERO
var _spawn_pos: Vector2 = Vector2.ZERO
var _zone_name: String = ""
var _is_waiting: bool = false
var _throw_timer: float = 0.0
var _is_throwing: bool = false
var _throw_anim_timer: float = 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("enemy")
	_spawn_pos = get_meta("spawn_position", global_position)
	_zone_name = get_meta("zone_name", "")
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player_ref = players[0]
	_throw_timer = randf_range(1.0, throw_cooldown)
	anim.play("idle")

func _physics_process(delta: float) -> void:
	if _check_zone_teleport():
		return

	if _knockback.length_squared() > 0:
		velocity = _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, 2000.0 * delta)
		move_and_slide()
		return

	if _is_throwing:
		_throw_anim_timer -= delta
		velocity = Vector2.ZERO
		if _throw_anim_timer <= 0:
			_is_throwing = false
			anim.play("idle")
		return

	if not is_instance_valid(_player_ref):
		return

	var dist := global_position.distance_to(_player_ref.global_position)

	_throw_timer -= delta
	if _throw_timer <= 0 and dist > throw_range_min and dist < throw_range_max:
		_start_throw()
		return

	var dir := global_position.direction_to(_player_ref.global_position)
	velocity = dir * speed * _speed_multiplier
	move_and_slide()

	if velocity.length() > 10:
		anim.play("walk")
		anim.flip_h = velocity.x < 0
	else:
		anim.play("idle")
		anim.flip_h = _player_ref.global_position.x < global_position.x

func _start_throw() -> void:
	_is_throwing = true
	_throw_anim_timer = 0.5
	velocity = Vector2.ZERO
	anim.play("throw")
	anim.flip_h = _player_ref.global_position.x < global_position.x

	await get_tree().create_timer(0.3).timeout
	if not is_instance_valid(self) or not is_instance_valid(_player_ref):
		return

	var grenade = GRENADE_SCENE.instantiate()
	grenade.global_position = global_position + Vector2(0, -20)
	grenade.target_pos = _player_ref.global_position
	get_tree().current_scene.add_child(grenade)

	_throw_timer = throw_cooldown + randf_range(-0.5, 0.5)

func _check_zone_teleport() -> bool:
	if _zone_name == "" or Engine.time_scale == 0:
		return false
	var main = get_tree().current_scene
	var player_zone := ""
	if main and main.has_method("get_player_zone"):
		player_zone = main.get_player_zone()
	if player_zone != _zone_name:
		if not _is_waiting:
			_is_waiting = true
			global_position = _spawn_pos
			velocity = Vector2.ZERO
			anim.play("idle")
		return true
	if _is_waiting:
		_is_waiting = false
		_throw_timer = randf_range(1.0, throw_cooldown)
		anim.play("walk")
	return false

func set_enraged(enraged: bool) -> void:
	_enraged = enraged
	if enraged:
		modulate = Color(1.8, 0.7, 0.7)
		_speed_multiplier = 1.5
		throw_cooldown = 1.2
	else:
		modulate = Color.WHITE
		_speed_multiplier = 1.0
		throw_cooldown = 1.8

func set_target(new_target: Node2D) -> void:
	_player_ref = new_target

func apply_knockback(impulse: Vector2) -> void:
	_knockback = impulse
