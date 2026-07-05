extends CharacterBody2D

@export var speed: float = 300.0

@export var enrage_interval: float = 8.0
@export var enrage_duration: float = 5.0
@export var separation_force: float = 60.0
@export var walk_fps: float = 10.0

var _player_ref: Node2D = null
var _enrage_timer: float = 0.0
var _stun_timer: float = 0.0
var _direction: Vector2 = Vector2.ZERO
var _change_dir_timer: float = 0.0
var _change_dir_interval: float = 1.5
var _enraged_visual: bool = false
var _spawn_pos: Vector2 = Vector2.ZERO
var _zone_name: String = ""
var _is_waiting: bool = false
var _player_prev_lives: int = -1
var _melody_playing: bool = false

var _melody_player: AudioStreamPlayer2D
var _horn_player: AudioStreamPlayer2D
var _laugh_player: AudioStreamPlayer2D

enum State { WANDERING, STUNNED }
var current_state: State = State.WANDERING

const ENRAGE_TINT := Color(1.8, 0.5, 0.5)

const MELODY_PATH := "res://Assets/Enemies/Clown/SoundEffect/melody-clown-in-the-circus.mp3"
const HORN_PATH := "res://Assets/Enemies/Clown/SoundEffect/festive-horn-single-close-sonorous.mp3"
const LAUGH_PATH := "res://Assets/Enemies/Clown/SoundEffect/komik-hohochet--gromko.mp3"

func _ready() -> void:
	add_to_group("enemy")
	_spawn_pos = get_meta("spawn_position", global_position)
	_zone_name = get_meta("zone_name", "")
	_enrage_timer = enrage_interval

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player_ref = players[0]
		if _player_ref.has_signal("health_changed"):
			_player_ref.health_changed.connect(_on_player_health_changed)
			_player_prev_lives = _player_ref.current_lives if "current_lives" in _player_ref else -1

	_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	_change_dir_timer = randf_range(0.5, _change_dir_interval)

	_setup_animated_sprite()
	_setup_audio()

func _setup_animated_sprite() -> void:
	var anim := AnimatedSprite2D.new()
	anim.name = "AnimatedSprite2D"
	add_child(anim)

	var frames := SpriteFrames.new()
	frames.add_animation(&"walk")

	var dir := DirAccess.open("res://Assets/Enemies/Clown/")
	if dir:
		var file_names: PackedStringArray = []
		dir.list_dir_begin()
		var fname := dir.get_next()
		while fname != "":
			if fname.begins_with("walk_") and fname.ends_with(".png"):
				file_names.append(fname)
			fname = dir.get_next()
		dir.list_dir_end()

		file_names.sort()
		for fn in file_names:
			var tex := load("res://Assets/Enemies/Clown/" + fn) as Texture2D
			if tex:
				frames.add_frame(&"walk", tex)

	if frames.get_frame_count(&"walk") == 0:
		push_warning("Clown: no walk frames found")

	frames.set_animation_speed(&"walk", walk_fps)
	frames.set_animation_loop(&"walk", true)
	anim.sprite_frames = frames
	anim.play(&"walk")

func _setup_audio() -> void:
	_melody_player = AudioStreamPlayer2D.new()
	_melody_player.name = "MelodyPlayer"
	_melody_player.bus = &"Effects"
	_melody_player.stream = load(MELODY_PATH)
	add_child(_melody_player)

	_horn_player = AudioStreamPlayer2D.new()
	_horn_player.name = "HornPlayer"
	_horn_player.bus = &"Effects"
	_horn_player.stream = load(HORN_PATH)
	add_child(_horn_player)

	_laugh_player = AudioStreamPlayer2D.new()
	_laugh_player.name = "LaughPlayer"
	_laugh_player.bus = &"Effects"
	_laugh_player.stream = load(LAUGH_PATH)
	add_child(_laugh_player)

func _physics_process(delta: float) -> void:
	if _check_zone_teleport():
		return

	_enrage_timer -= delta

	match current_state:
		State.WANDERING:
			_process_wandering(delta)
		State.STUNNED:
			_stun_timer -= delta
			if _stun_timer <= 0:
				current_state = State.WANDERING

	_handle_separation(delta)
	queue_redraw()

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
			_melody_player.stop()
			_melody_playing = false
			var anim := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
			if anim:
				anim.stop()
		return true
	if _is_waiting:
		_is_waiting = false
		var anim := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if anim:
			anim.play(&"walk")
	return false

func _process_wandering(delta: float) -> void:
	_change_dir_timer -= delta
	if _change_dir_timer <= 0:
		_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		_change_dir_timer = randf_range(0.8, _change_dir_interval)

	velocity = _direction * speed
	move_and_slide()

	if velocity.length() > 10:
		var anim := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if anim and anim.is_playing():
			anim.flip_h = velocity.x < 0

	_update_melody()
	_check_enrage()

func _update_melody() -> void:
	var main = get_tree().current_scene
	var player_zone := ""
	if main and main.has_method("get_player_zone"):
		player_zone = main.get_player_zone()

	var same_zone := player_zone == _zone_name and _zone_name != ""
	if same_zone and not _melody_playing:
		_melody_player.play()
		_melody_playing = true
	elif not same_zone and _melody_playing:
		_melody_player.stop()
		_melody_playing = false

func _check_enrage() -> void:
	if _enrage_timer <= 0:
		_enrage_timer = enrage_interval
		_trigger_enrage()

func _trigger_enrage() -> void:
	_horn_player.play()
	_enraged_visual = true
	var tween := create_tween()
	tween.tween_interval(enrage_duration)
	tween.tween_callback(_end_enrage)

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == self:
			continue
		if enemy.has_method("set_enraged"):
			enemy.set_enraged(true)

func _end_enrage() -> void:
	_enraged_visual = false
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == self:
			continue
		if enemy.has_method("set_enraged"):
			enemy.set_enraged(false)

func _on_player_health_changed(new_health: int) -> void:
	if _player_prev_lives >= 0 and new_health < _player_prev_lives:
		if not _is_waiting:
			_laugh_player.play()
	_player_prev_lives = new_health

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

func set_target(new_target: Node2D) -> void:
	pass

func set_enraged(enraged: bool) -> void:
	pass
