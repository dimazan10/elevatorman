extends CharacterBody2D

const WEB_SCENE = preload("res://Objects/Web.tscn")

@export var speed: float = 250.0
@export var web_boost_multiplier: float = 1.5
@export var separation_force: float = 80.0
@export var shoot_interval: float = 4.0
@export var melee_damage: int = 1


var _player_ref: Node2D = null
var target: Node2D = null
var _web_boost := false
var _spawn_pos: Vector2 = Vector2.ZERO
var _zone_name: String = ""
var _is_waiting: bool = false
var _melee_cooldown := false
var _knockback := Vector2.ZERO
var _run_audio_playing := false
var _enraged := false
var _speed_multiplier := 1.0

@onready var animated_sprite := $AnimatedSprite2D
@onready var shoot_timer := $ShootTimer
@onready var melee_zone := $MeleeZone
@onready var separation_zone := $SeparationZone

var spawn_web_audio: AudioStreamPlayer2D
var run_audio: AudioStreamPlayer2D
var bite_audio: AudioStreamPlayer2D

func _ready() -> void:
	add_to_group("enemy")
	if has_meta("spawn_position"):
		_spawn_pos = get_meta("spawn_position")
	if has_meta("zone_name"):
		_zone_name = get_meta("zone_name")
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player_ref = players[0]
		target = _player_ref
		add_collision_exception_with(_player_ref)
		spawn_web_audio = AudioStreamPlayer2D.new()
		spawn_web_audio.name = "SpawnWebAudio"
		spawn_web_audio.stream = preload("res://Assets/Sounds/Effects/SpawnWeb.mp3")
		spawn_web_audio.bus = &"Effects"
		add_child(spawn_web_audio)
		run_audio = AudioStreamPlayer2D.new()
		run_audio.name = "RunAudio"
		run_audio.stream = preload("res://Assets/Sounds/Effects/spider-run-stop-2.mp3")
		run_audio.bus = &"Effects"
		run_audio.volume_db = -3.0
		run_audio.finished.connect(run_audio.play)
		add_child(run_audio)
		bite_audio = AudioStreamPlayer2D.new()
		bite_audio.name = "BiteAudio"
		bite_audio.stream = preload("res://Assets/Sounds/Effects/insect-chew-bite_mkkbnnvd.mp3")
		bite_audio.bus = &"Effects"
		bite_audio.volume_db = 3.0
		add_child(bite_audio)

	shoot_timer.one_shot = true
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	shoot_timer.start(3.0)

	melee_zone.body_entered.connect(_on_melee_zone_body_entered)

	if animated_sprite and animated_sprite.sprite_frames.has_animation("walk"):
		animated_sprite.play("walk")

func set_web_boost(enabled: bool) -> void:
	_web_boost = enabled

func _stop_run_audio() -> void:
	if _run_audio_playing and run_audio:
		run_audio.stop()
		_run_audio_playing = false

func _get_separation_vector() -> Vector2:
	var sep := Vector2.ZERO
	for body in separation_zone.get_overlapping_bodies():
		if body == self or body == _player_ref:
			continue
		if body is CharacterBody2D or body.is_in_group("enemy"):
			var diff = global_position - body.global_position
			if diff.length() > 0.001 and diff.is_finite():
				sep += diff.normalized() / diff.length()
	if sep.length() > 0:
		sep = sep.normalized()
	return sep

func _check_zone_teleport() -> bool:
	if _zone_name == "" or Engine.time_scale == 0:
		return false
	var main = get_tree().current_scene
	var player_zone = ""
	if main and main.has_method("get_player_zone"):
		player_zone = main.get_player_zone()
	if player_zone != _zone_name:
		if not _is_waiting:
			_is_waiting = true
			global_position = _spawn_pos
			velocity = Vector2.ZERO
			shoot_timer.stop()
			visible = false
			_set_collision_enabled(false)
			if run_audio:
				run_audio.stop()
				_run_audio_playing = false
			if animated_sprite and animated_sprite.sprite_frames.has_animation("walk"):
				animated_sprite.stop()
		return true
	if _is_waiting:
		_is_waiting = false
		visible = true
		_set_collision_enabled(true)
		shoot_timer.start(randf_range(8.0, 12.0))
		if animated_sprite and animated_sprite.sprite_frames.has_animation("walk"):
			animated_sprite.play("walk")
	return false

func _set_collision_enabled(enabled: bool) -> void:
	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", not enabled)
		elif child is Area2D:
			for sub in child.get_children():
				if sub is CollisionShape2D:
					sub.set_deferred("disabled", not enabled)

func set_enraged(enraged: bool) -> void:
	_enraged = enraged
	if enraged:
		modulate = Color(1.8, 0.7, 0.7)
		shoot_timer.wait_time = randf_range(6.0, 9.0)
	else:
		modulate = Color.WHITE
		shoot_timer.wait_time = randf_range(8.0, 12.0)

func _physics_process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		target = _player_ref
	if not target:
		_stop_run_audio()
		return
	if _check_zone_teleport():
		animated_sprite.flip_h = target.global_position.x < global_position.x
		_stop_run_audio()
		return

	if _knockback.length_squared() > 0:
		velocity = _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, 2000.0 * delta)
		move_and_slide()
		_stop_run_audio()
		return

	var to_target = target.global_position - global_position
	var dist = to_target.length()
	if dist < 0.001:
		_stop_run_audio()
		return

	if not _run_audio_playing and run_audio:
		run_audio.play()
		_run_audio_playing = true
	var direction = to_target / dist
	var current_speed = speed * (web_boost_multiplier if _web_boost else 1.0) * _speed_multiplier

	var separation = _get_separation_vector()
	velocity = direction * current_speed + separation * separation_force
	if not velocity.is_finite():
		velocity = Vector2.ZERO
	move_and_slide()

	if direction.x > 0:
		animated_sprite.flip_h = false
	else:
		animated_sprite.flip_h = true

func _on_shoot_timer_timeout() -> void:
	if _is_waiting or not target or not is_instance_valid(target):
		return

	var web = WEB_SCENE.instantiate()
	web.global_position = global_position
	web.z_index = 1
	get_parent().add_child(web)
	spawn_web_audio.play()
	shoot_timer.start(randf_range(8.0, 12.0))

func _get_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var min_dist := INF
	for e in get_tree().get_nodes_in_group("enemy"):
		if e == self:
			continue
		var d = global_position.distance_squared_to(e.global_position)
		if d < min_dist:
			min_dist = d
			nearest = e
	return nearest

func _on_melee_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _melee_cooldown:
		_melee_cooldown = true
		var target = _get_nearest_enemy()
		if target and body.has_method("apply_pull_toward"):
			body.apply_pull_toward(target, 0.6, Vector2(0, -40))
		if body.has_method("take_damage"):
			body.take_damage(melee_damage)
		if bite_audio:
			bite_audio.play()
		_knockback = (global_position - body.global_position).normalized() * 400.0
		await get_tree().create_timer(1.5).timeout
		_melee_cooldown = false

func set_target(new_target: Node2D) -> void:
	target = new_target

func apply_knockback(impulse: Vector2) -> void:
	_knockback = impulse
