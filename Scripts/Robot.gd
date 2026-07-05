extends CharacterBody2D

signal hp_changed(current_hp: int, max_hp: int)

enum State { IDLE, LEFT_ATTACK, RIGHT_ATTACK, BOTH_ATTACK }

var current_state := State.IDLE
var _circles_spawned := false
var _attack_cooldown := 0.0
var _audio: AudioStreamPlayer2D
var _death_audio: AudioStreamPlayer2D
var _is_dead := false

var max_hp := 3
var current_hp := 3
var _damaged_parts := {}

var _laser_state := LaserState.READY
var _laser_cooldown := 0.0
var _laser_timer := 0.0
var _laser_damage_accum := 0.0
var _laser_muzzle: Marker2D
var _laser_ray: RayCast2D
var _laser_line: Line2D
var _laser_audio: AudioStreamPlayer2D

const IMPACT_TIME := 1.3
const CIRCLE_RADIUS_RED := 800.0
const CIRCLE_RADIUS_BLUE := 780.0
const CIRCLE_LIFETIME := 2.5
const DAMAGE := 1
const MOVE_THRESHOLD := 30.0
const DEATH_CAMERA_ZOOM := Vector2(0.65, 0.65)
const DEATH_CAMERA_DURATION := 1.0
const DEATH_ANIMATION := &"Death_Animation"

enum LaserState { READY, WARNING, FIRING }
const LASER_WARN_DURATION := 1.0
const LASER_FIRE_DURATION := 2.0
const LASER_COOLDOWN := 4.0
const LASER_DPS := 50.0
const LASER_RANGE := 10000.0

const CIRCLE_SCENE := preload("res://Objects/Boss/Robot/AttackCircle.tscn")

func _ready() -> void:
	add_to_group("enemy")
	$WaistBone/AnimationPlayer.play("Idle")
	$WaistBone/AnimationPlayer.animation_finished.connect(_on_animation_finished)

	_audio = AudioStreamPlayer2D.new()
	_audio.name = "AttackAudio"
	_audio.stream = load("res://Assets/Boss/RobotBoss/Sprite_Robot/Attack.mp3")
	_audio.bus = &"Effects"
	add_child(_audio)

	_death_audio = AudioStreamPlayer2D.new()
	_death_audio.name = "DeathAudio"
	_death_audio.stream = load("res://Assets/Boss/RobotBoss/Sprite_Robot/Death.mp3")
	_death_audio.bus = &"Effects"
	add_child(_death_audio)

	_setup_hitboxes()
	_setup_laser()

func _setup_laser() -> void:
	_laser_muzzle = $WaistBone/TorsoBone/HeadBone/LaserMuzzle
	_laser_ray = _laser_muzzle.get_node_or_null("RayCast2D") as RayCast2D
	_laser_line = _laser_muzzle.get_node_or_null("Line2D") as Line2D
	if not _laser_ray or not _laser_line:
		return
	_laser_ray.target_position = Vector2(LASER_RANGE, 0)
	_laser_line.clear_points()
	_laser_line.add_point(Vector2.ZERO)
	_laser_line.add_point(Vector2.ZERO)

	_laser_audio = AudioStreamPlayer2D.new()
	_laser_audio.name = "LaserAudio"
	_laser_audio.stream = load("res://Assets/Turret/laser_shot.mp3")
	_laser_audio.bus = &"Effects"
	add_child(_laser_audio)

func _setup_hitboxes() -> void:
	var hitbox: Area2D = $Hitbox
	if hitbox:
		hitbox.area_entered.connect(_on_part_hit)

func _on_part_hit(area: Area2D) -> void:
	if not area.is_in_group("bullet"):
		return
	try_hit_with_bullet(area, area.global_position)

func try_hit_with_bullet(bullet: Node, hit_position: Vector2) -> bool:
	if _is_dead:
		return false
	if not bullet or not bullet.is_in_group("bullet"):
		return false
	if not bullet.has_method("is_used") or not bullet.has_method("mark_used") or not bullet.has_method("on_hit"):
		return false
	var already_used: bool = bool(bullet.call("is_used"))
	if already_used:
		return false

	var local_y: float = to_local(hit_position).y
	var part: String = "Waist"
	if local_y < -90:
		part = "Head"
	elif local_y < 65:
		part = "Torso"
	if _damaged_parts.has(part):
		return false

	bullet.call("mark_used")
	if bullet is Node2D:
		var bullet_2d: Node2D = bullet as Node2D
		bullet_2d.global_position = hit_position
	bullet.call("on_hit")
	take_damage_to_part(part)
	return true

func take_damage_to_part(part_name: String) -> void:
	if _damaged_parts.has(part_name):
		return
	_damaged_parts[part_name] = true
	current_hp = maxi(current_hp - 1, 0)
	_darken_part_sprite(part_name)
	hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		_die()

func _darken_part_sprite(part_name: String) -> void:
	var sprite: Sprite2D = null
	match part_name:
		"Waist":
			sprite = $WaistBone/Waist
		"Torso":
			sprite = $WaistBone/TorsoBone/Frame
		"Head":
			sprite = $WaistBone/TorsoBone/HeadBone/Head
	if sprite:
		sprite.modulate = Color(0.1, 0.1, 0.1)

func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	current_state = State.IDLE
	_attack_cooldown = INF
	_circles_spawned = true
	_laser_state = LaserState.READY
	_laser_cooldown = INF
	if _laser_ray:
		_laser_ray.enabled = false
	if _laser_line:
		_laser_line.visible = false
	_play_death_sequence()

func _play_death_sequence() -> void:
	var camera: Camera2D = _get_player_camera()
	var camera_position: Vector2 = Vector2.ZERO
	var camera_zoom: Vector2 = Vector2.ONE
	if camera:
		camera_position = camera.position
		camera_zoom = camera.zoom
		_focus_camera_on_boss(camera)

	_death_audio.play()
	var animation_player: AnimationPlayer = $WaistBone/AnimationPlayer
	animation_player.play(DEATH_ANIMATION)

	var wait_time: float = animation_player.current_animation_length
	if _death_audio.stream:
		wait_time = maxf(wait_time, _death_audio.stream.get_length())
	await get_tree().create_timer(wait_time).timeout

	if camera:
		_return_camera_to_player(camera, camera_position, camera_zoom)

func _get_player_camera() -> Camera2D:
	var player: Node = get_tree().get_first_node_in_group("player")
	if not player:
		return null

	return player.get_node_or_null("PlayerCamera") as Camera2D

func _focus_camera_on_boss(camera: Camera2D) -> void:
	if not camera:
		return

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(camera, "global_position", global_position, DEATH_CAMERA_DURATION).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "zoom", DEATH_CAMERA_ZOOM, DEATH_CAMERA_DURATION).set_ease(Tween.EASE_IN_OUT)

func _return_camera_to_player(camera: Camera2D, camera_position: Vector2, camera_zoom: Vector2) -> void:
	if not camera:
		return

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(camera, "position", camera_position, DEATH_CAMERA_DURATION).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "zoom", camera_zoom, DEATH_CAMERA_DURATION).set_ease(Tween.EASE_IN_OUT)

func _process(delta: float) -> void:
	if _is_dead:
		return

	if current_state != State.IDLE and not _circles_spawned:
		if $WaistBone/AnimationPlayer.current_animation_position >= IMPACT_TIME:
			_spawn_attack_circles()
			_shake_camera(1.5, 20.0)
			_circles_spawned = true

	_update_laser(delta)

	if current_state == State.IDLE:
		_attack_cooldown -= delta
		if _attack_cooldown <= 0:
			_do_random_attack()

func _update_laser(delta: float) -> void:
	if _is_dead or not _laser_ray or not _laser_line:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return

	match _laser_state:
		LaserState.READY:
			_laser_cooldown -= delta
			if _laser_cooldown <= 0 and _has_los(player):
				_start_laser_warning(player)
		LaserState.WARNING, LaserState.FIRING:
			_laser_timer -= delta
			var muzzle := _laser_muzzle
			muzzle.look_at(player.global_position)
			_laser_ray.force_raycast_update()
			var cast_point := _laser_ray.target_position
			if _laser_ray.is_colliding():
				cast_point = muzzle.to_local(_laser_ray.get_collision_point())
			_laser_line.set_point_position(1, cast_point)

			if _laser_state == LaserState.FIRING:
				if _laser_ray.is_colliding():
					_laser_damage_accum += LASER_DPS * delta
					if _laser_damage_accum >= 1.0:
						var dmg := int(_laser_damage_accum)
						_laser_damage_accum -= dmg
						var collider := _laser_ray.get_collider()
						if collider and collider.has_method("take_damage"):
							collider.call("take_damage", dmg)

			if _laser_timer <= 0:
				_end_laser()

func _has_los(player: Node2D) -> bool:
	if not _laser_muzzle or not is_instance_valid(player):
		return false
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(_laser_muzzle.global_position, player.global_position)
	query.exclude = [get_rid()]
	var result := space.intersect_ray(query)
	if result.is_empty():
		return false
	var hit := result.collider as Node
	return hit and (hit == player or hit.is_in_group("player"))

func _start_laser_warning(player: Node2D) -> void:
	_laser_state = LaserState.WARNING
	_laser_timer = LASER_WARN_DURATION
	_laser_ray.enabled = true
	_laser_line.visible = true
	_laser_line.width = 2.0
	_laser_line.default_color = Color(1.0, 0.2, 0.2, 0.4)
	_laser_muzzle.look_at(player.global_position)

func _end_laser() -> void:
	if _laser_state == LaserState.WARNING:
		_laser_state = LaserState.FIRING
		_laser_timer = LASER_FIRE_DURATION
		_laser_damage_accum = 0.0
		_laser_line.width = 6.0
		_laser_line.default_color = Color(1.0, 0.0, 0.0, 1.0)
		if _laser_audio:
			_laser_audio.play()
	else:
		_laser_state = LaserState.READY
		_laser_cooldown = LASER_COOLDOWN
		_laser_ray.enabled = false
		_laser_line.visible = false
		_laser_line.set_point_position(1, Vector2.ZERO)

func _do_random_attack() -> void:
	var attacks := [State.LEFT_ATTACK, State.RIGHT_ATTACK, State.BOTH_ATTACK]
	_start_attack(attacks[randi() % attacks.size()])

func _start_attack(attack: State) -> void:
	if _is_dead:
		return
	current_state = attack
	_circles_spawned = false
	_audio.play()
	match attack:
		State.LEFT_ATTACK:
			$WaistBone/AnimationPlayer.play("Left_Attack_Hand")
		State.RIGHT_ATTACK:
			$WaistBone/AnimationPlayer.play("Right_Attack_Hand")
		State.BOTH_ATTACK:
			$WaistBone/AnimationPlayer.play("Attack_Hands")

func _shake_camera(duration: float, intensity: float) -> void:
	var camera := _get_player_camera()
	if not camera:
		return
	var orig_offset := camera.offset
	var tw := create_tween()
	tw.tween_method(
		func(progress: float) -> void:
			var decay: float = 1.0 - progress
			var cur: float = intensity * decay
			camera.offset = Vector2(randf_range(-cur, cur), randf_range(-cur, cur)),
		0.0, 1.0, duration
	)
	tw.tween_callback(func() -> void: camera.offset = orig_offset)

func _spawn_attack_circles() -> void:
	var left_marker = $LeftCircleMarker
	var right_marker = $RightCircleMarker
	if not left_marker or not right_marker:
		return

	match current_state:
		State.LEFT_ATTACK:
			_spawn_random_circle(left_marker.global_position)
		State.RIGHT_ATTACK:
			_spawn_random_circle(right_marker.global_position)
		State.BOTH_ATTACK:
			_spawn_random_circle(left_marker.global_position)
			_spawn_random_circle(right_marker.global_position)

func _spawn_random_circle(pos: Vector2) -> void:
	if randi() % 2 == 0:
		_spawn_circle(pos, CIRCLE_RADIUS_RED, Color(1, 0, 0, 0.25), false)
	else:
		_spawn_circle(pos, CIRCLE_RADIUS_BLUE, Color(0, 0, 1, 0.25), true)

func _spawn_circle(pos: Vector2, radius: float, color: Color, is_blue: bool) -> void:
	var area := CIRCLE_SCENE.instantiate()
	area.global_position = pos
	area.circle_radius = radius
	area.circle_color = color
	area.is_blue = is_blue

	get_parent().add_child(area)

	area.scale = Vector2.ZERO
	var tw := area.create_tween()
	tw.tween_property(area, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(area, "modulate:a", color.a, 0.4).from(0.0)

	await get_tree().create_timer(CIRCLE_LIFETIME - 0.5).timeout
	if not is_instance_valid(area):
		return

	area._active = false
	var fade := area.create_tween()
	fade.tween_property(area, "modulate:a", 0.0, 0.5)
	await fade.finished
	if is_instance_valid(area):
		area.queue_free()

func _on_animation_finished(anim_name: String) -> void:
	if _is_dead:
		return
	current_state = State.IDLE
	_attack_cooldown = 2.0 + randf() * 3.0
	$WaistBone/AnimationPlayer.play("Idle")
