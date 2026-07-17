extends CharacterBody2D

const BULLET_SCENE = preload("res://Objects/Summons/Bullet.tscn")

@export var speed: float = 150.0
@export var orbit_distance: float = 250.0
@export var melee_range: float = 60.0
@export var shoot_spread_degrees: float = 15.0
@export var separation_force: float = 80.0

var _enraged := false
var _speed_multiplier := 1.0

@onready var enemy_sprite := $AnimatedSprite2D
@onready var weapon_anchor := $WeaponAnchor
@onready var weapon_sprite := $WeaponAnchor/WeaponSprite
@onready var muzzle := $WeaponAnchor/Muzzle
@onready var burst_timer := $BurstTimer
@onready var shot_delay_timer := $ShotDelayTimer
@onready var melee_zone := $MeleeZone
@onready var separation_zone := $SeparationZone

var _player_ref: Node2D = null
var target: Node2D = null
var _knockback := Vector2.ZERO
var _spawn_pos: Vector2 = Vector2.ZERO
var _zone_name: String = ""
var _is_waiting: bool = false
var _current_scene: Node = null
var _spread_cos: float = 0.0

enum States { MOVING, SHOOTING }
var current_state = States.MOVING
var bullets_in_burst: int = 0

func _ready() -> void:
	_current_scene = get_tree().current_scene
	_spread_cos = cos(deg_to_rad(shoot_spread_degrees))

	if has_meta("spawn_position"):
		_spawn_pos = get_meta("spawn_position")
	if has_meta("zone_name"):
		_zone_name = get_meta("zone_name")

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player_ref = players[0]
		target = _player_ref

	burst_timer.one_shot = true
	burst_timer.timeout.connect(_on_burst_timer_timeout)
	set_random_burst_pause()

	shot_delay_timer.wait_time = 0.15
	shot_delay_timer.timeout.connect(_on_shot_delay_timer_timeout)

	melee_zone.body_entered.connect(_on_melee_zone_body_entered)
	_ready_add_shot_audio()

	if enemy_sprite and enemy_sprite.sprite_frames.has_animation("walk"):
		enemy_sprite.play("walk")

func on_zone_entered() -> void:
	_is_waiting = false
	set_random_burst_pause()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		target = _player_ref
	if not target:
		return

	if _knockback.length_squared() > 0:
		velocity = _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, 2000.0 * delta)
		move_and_slide()
		return

	weapon_anchor.look_at(target.global_position)

	if target.global_position.x < global_position.x:
		enemy_sprite.flip_h = true
		weapon_anchor.scale.y = -1
	else:
		enemy_sprite.flip_h = false
		weapon_anchor.scale.y = 1

	match current_state:
		States.MOVING:
			_move_around_player(delta)
			if not enemy_sprite.is_playing():
				enemy_sprite.play("walk")
		States.SHOOTING:
			velocity = _calculate_separation_vector() * (separation_force * 0.5)
			if not velocity.is_finite():
				velocity = Vector2.ZERO
			move_and_slide()
			enemy_sprite.stop()
			enemy_sprite.frame = 0

func _move_around_player(_delta: float) -> void:
	var to_target := target.global_position - global_position
	var distance := to_target.length()
	if distance < 0.001:
		return
	var direction_to_target := to_target / distance

	if _enraged:
		var surround_target := _get_surround_target()
		var surround_vec := surround_target - global_position
		if surround_vec.length() > 5.0:
			velocity = surround_vec.normalized() * speed * _speed_multiplier
			if not velocity.is_finite():
				velocity = Vector2.ZERO
			move_and_slide()
			return

	var tangent: Vector2
	if abs(target.velocity.x) > 10.0:
		if target.velocity.x > 0:
			tangent = Vector2(direction_to_target.y, -direction_to_target.x)
		else:
			tangent = Vector2(-direction_to_target.y, direction_to_target.x)
	else:
		tangent = Vector2(-direction_to_target.y, direction_to_target.x)

	var desired_velocity: Vector2
	if distance > orbit_distance + 20:
		var raw := tangent + direction_to_target
		desired_velocity = raw.normalized() if raw.is_finite() else tangent
	else:
		desired_velocity = tangent

	var movement_vector := desired_velocity * speed * _speed_multiplier
	var separation_vector := _calculate_separation_vector()

	velocity = movement_vector + (separation_vector * separation_force)
	if not velocity.is_finite():
		velocity = Vector2.ZERO
	move_and_slide()

func _calculate_separation_vector() -> Vector2:
	var separation := Vector2.ZERO
	var overlapping_bodies: Array = separation_zone.get_overlapping_bodies()

	for body in overlapping_bodies:
		if body == self or body == _player_ref:
			continue
		if not body.is_in_group("enemy") and not (body is CharacterBody2D):
			continue
		var diff: Vector2 = global_position - (body as Node2D).global_position
		if diff.length_squared() < 0.001:
			continue
		separation += diff.normalized() / diff.length()

	return separation.normalized() if separation.length_squared() > 0 else Vector2.ZERO

func set_random_burst_pause() -> void:
	burst_timer.wait_time = randf_range(0.8, 1.5) if _enraged else randf_range(1.0, 2.0)
	burst_timer.start()

func _on_burst_timer_timeout() -> void:
	if _is_waiting or current_state != States.MOVING:
		return
	current_state = States.SHOOTING
	bullets_in_burst = randi_range(3, 4)
	_fire_single_shot()

func _fire_single_shot() -> void:
	var bullet := BULLET_SCENE.instantiate()
	bullet.global_position = muzzle.global_position

	var base_direction := Vector2.RIGHT.rotated(weapon_anchor.global_rotation)
	var spread_radians := deg_to_rad(randf_range(-shoot_spread_degrees, shoot_spread_degrees))
	bullet.direction = base_direction.rotated(spread_radians)

	_current_scene.add_child(bullet)
	_play_shot_sound()

	bullets_in_burst -= 1

	if bullets_in_burst > 0:
		shot_delay_timer.start()
	else:
		current_state = States.MOVING
		set_random_burst_pause()

func _on_shot_delay_timer_timeout() -> void:
	if not _is_waiting:
		_fire_single_shot()

func _on_melee_zone_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if body.has_method("apply_stun_and_knockback"):
		var kb_vec := body.global_position - global_position
		var knockback_dir := kb_vec.normalized() if kb_vec.length_squared() > 0.0001 else Vector2.DOWN
		body.apply_stun_and_knockback(knockback_dir * 500.0, 1.0)

	if body.has_method("take_damage"):
		body.take_damage(1)

	if current_state == States.MOVING:
		burst_timer.stop()
		set_random_burst_pause()

var _shot_audio_pool: Array[AudioStreamPlayer2D] = []
var _shot_audio_idx := 0

func _ready_add_shot_audio() -> void:
	for i in 4:
		var ap := AudioStreamPlayer2D.new()
		ap.name = "ShotAudio" + str(i)
		ap.stream = preload("res://Assets/Sounds/Effects/KillerShot.mp3")
		ap.bus = &"Effects"
		add_child(ap)
		_shot_audio_pool.append(ap)

func _play_shot_sound() -> void:
	_shot_audio_pool[_shot_audio_idx].play()
	_shot_audio_idx = (_shot_audio_idx + 1) % _shot_audio_pool.size()

func set_enraged(enraged: bool) -> void:
	_enraged = enraged
	modulate = Color(1.8, 0.7, 0.7) if enraged else Color.WHITE

func set_target(new_target: Node2D) -> void:
	target = new_target

func apply_knockback(impulse: Vector2) -> void:
	_knockback = impulse

func _get_surround_target() -> Vector2:
	if not is_instance_valid(_player_ref):
		return global_position
	var player_pos := _player_ref.global_position
	var my_angle := (player_pos - global_position).angle()
	var occupied: Array[float] = [my_angle]

	for body in separation_zone.get_overlapping_bodies():
		if body != self and body is CharacterBody2D and body.is_in_group("enemy"):
			occupied.append((player_pos - body.global_position).angle())

	occupied.sort()
	var best_gap := 0.0
	var best_angle := my_angle
	for i in occupied.size():
		var gap: float = occupied[(i + 1) % occupied.size()] - occupied[i]
		if gap < 0:
			gap += TAU
		if gap > best_gap:
			best_gap = gap
			best_angle = (occupied[i] + occupied[(i + 1) % occupied.size()]) * 0.5
			if best_angle > PI:
				best_angle -= TAU

	return player_pos + Vector2(cos(best_angle), sin(best_angle)) * orbit_distance
