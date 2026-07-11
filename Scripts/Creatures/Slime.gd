extends CharacterBody2D

@export var speed: float = 220.0
@export var separation_force: float = 60.0
@export var aggro_range: float = 350.0
@export var melee_range: float = 50.0
@export var melee_damage: int = 1
@export var melee_cooldown: float = 1.5
@export var trail_interval: float = 0.2
@export var steal_slow_factor: float = 0.4
@export var steal_duration: float = 3.0

var _player_ref: Node2D = null
var _melee_timer: float = 0.0
var _trail_timer: float = 0.0
var _spawn_pos: Vector2 = Vector2.ZERO
var _zone_name: String = ""
var _is_waiting: bool = false
var _enraged: bool = false
var _attack_timer: float = 0.0

const TRAIL_SCENE = preload("res://Objects/Summons/SlimeTrail.tscn")

enum State { IDLE, CHASING, ATTACKING, STUNNED }
var current_state: State = State.CHASING
var _stun_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemy")
	_spawn_pos = get_meta("spawn_position", global_position)
	_zone_name = get_meta("zone_name", "")
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player_ref = players[0]
	_setup_animated_sprite()

func _setup_animated_sprite() -> void:
	var anim := AnimatedSprite2D.new()
	anim.name = "AnimatedSprite2D"
	anim.scale = Vector2(0.55, 0.55)
	add_child(anim)

	var frames := SpriteFrames.new()
	frames.add_animation(&"idle")
	frames.add_animation(&"walk")
	frames.add_animation(&"attack")

	var dir := DirAccess.open("res://Assets/Enemies/Slime/")
	if dir:
		for anim_name in ["idle", "walk", "attack"]:
			var file_names: PackedStringArray = []
			dir.list_dir_begin()
			var fname := dir.get_next()
			while fname != "":
				if fname.begins_with(anim_name + "_") and fname.ends_with(".png"):
					file_names.append(fname)
				fname = dir.get_next()
			dir.list_dir_end()
			file_names.sort()
			for fn in file_names:
				var tex := load("res://Assets/Enemies/Slime/" + fn) as Texture2D
				if tex:
					frames.add_frame(anim_name, tex)

	frames.set_animation_speed(&"idle", 5)
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_speed(&"walk", 8)
	frames.set_animation_loop(&"walk", true)
	frames.set_animation_speed(&"attack", 10)
	frames.set_animation_loop(&"attack", false)

	anim.sprite_frames = frames
	anim.modulate = Color(0.75, 0.8, 0.75)
	anim.play(&"walk")

func _physics_process(delta: float) -> void:
	if _check_zone_teleport():
		return

	_melee_timer = maxf(_melee_timer - delta, 0.0)
	_trail_timer -= delta
	_attack_timer -= delta

	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.CHASING:
			_process_chasing(delta)
		State.ATTACKING:
			_process_attacking(delta)
		State.STUNNED:
			_stun_timer -= delta
			if _stun_timer <= 0:
				current_state = State.CHASING

	_handle_separation(delta)

func _process_idle(_delta: float) -> void:
	if not is_instance_valid(_player_ref):
		return
	if global_position.distance_to(_player_ref.global_position) < aggro_range:
		current_state = State.CHASING

func _process_chasing(delta: float) -> void:
	if not is_instance_valid(_player_ref):
		return

	var dist := global_position.distance_to(_player_ref.global_position)
	if dist < melee_range and _melee_timer <= 0:
		current_state = State.ATTACKING
		_play_anim("attack")
		velocity = Vector2.ZERO
		_melee_timer = melee_cooldown
		_attack_timer = 0.6
		if _player_ref.has_method("take_damage"):
			_player_ref.take_damage(melee_damage)
		_steal_speed()
		return

	var dir := global_position.direction_to(_player_ref.global_position)
	velocity = dir * speed * (1.4 if _enraged else 1.0)
	move_and_slide()
	_play_anim("walk")

	var anim := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if anim and velocity.length() > 10:
		anim.flip_h = velocity.x < 0

	_drop_trail()

func _process_attacking(_delta: float) -> void:
	velocity = Vector2.ZERO
	if _attack_timer <= 0:
		current_state = State.CHASING
		_play_anim("walk")
		return

	if is_instance_valid(_player_ref) and _melee_timer <= 0:
		var dist := global_position.distance_to(_player_ref.global_position)
		if dist < melee_range + 15:
			if _player_ref.has_method("take_damage"):
				_player_ref.take_damage(melee_damage)
			_melee_timer = melee_cooldown

func _drop_trail() -> void:
	if _trail_timer > 0:
		return
	_trail_timer = trail_interval
	_drop_trail_at(global_position)

func _drop_trail_at(pos: Vector2) -> void:
	var trail := TRAIL_SCENE.instantiate()
	trail.global_position = pos
	get_tree().current_scene.add_child(trail)

func _play_anim(anim_name: String) -> void:
	var anim := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if anim and anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)

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
			visible = false
			_set_collision_enabled(false)
			_stop_all_audio()
			_play_anim("idle")
		return true
	if _is_waiting:
		_is_waiting = false
		visible = true
		_set_collision_enabled(true)
		_play_anim("walk")
	return false

func _set_collision_enabled(enabled: bool) -> void:
	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", not enabled)
		elif child is Area2D:
			for sub in child.get_children():
				if sub is CollisionShape2D:
					sub.set_deferred("disabled", not enabled)

func _stop_all_audio() -> void:
	for child in get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer2D:
			child.stop()

func _handle_separation(delta: float) -> void:
	var sep := Vector2.ZERO
	for body in get_tree().get_nodes_in_group("enemy"):
		if body == self or not body is Node2D:
			continue
		var other := body as Node2D
		var diff: Vector2 = global_position - other.global_position
		if diff.length() > 0.001 and diff.is_finite():
			sep += diff.normalized() / diff.length()
	if sep.length() > 0:
		global_position += sep.normalized() * separation_force * delta

func apply_knockback(impulse: Vector2) -> void:
	velocity = impulse * 0.5
	current_state = State.STUNNED
	_stun_timer = 0.3

func _steal_speed() -> void:
	if not is_instance_valid(_player_ref):
		return
	if _player_ref.has_method("apply_slow"):
		_player_ref.apply_slow(steal_slow_factor, steal_duration)
	if _player_ref.has_method("set_slime_vfx"):
		_player_ref.set_slime_vfx(true)
		await get_tree().create_timer(steal_duration).timeout
		if is_instance_valid(_player_ref) and _player_ref.has_method("set_slime_vfx"):
			_player_ref.set_slime_vfx(false)

func set_enraged(enraged: bool) -> void:
	_enraged = enraged
