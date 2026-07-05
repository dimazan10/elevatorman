extends StaticBody2D

@export var laser_range: float = 10000.0
@export var warning_duration: float = 1.0
@export var laser_duration: float = 2.0
@export var cooldown: float = 2.0
@export var damage_per_second: float = 50.0

enum TurretState { TRACKING, WARNING, FIRING }
var current_state: TurretState = TurretState.TRACKING

var muzzle: Marker2D
var raycast: RayCast2D
var line: Line2D
var cooldown_timer: Timer
var player: Node2D
var _damage_accum: float = 0.0
var _enraged: bool = false
var _shoot_audio: AudioStreamPlayer2D
var _frame_count: int = 0

func _ready() -> void:
	add_to_group("turret")
	player = get_tree().get_first_node_in_group("player")

	var pivot_node = get_node_or_null("Node2D")
	if not pivot_node:
		push_error("Turret: 'Node2D' не найден!")
		return

	muzzle = pivot_node.get_node_or_null("Marker2D")
	if not muzzle:
		push_error("Turret: 'Marker2D' не найден!")
		return

	raycast = muzzle.get_node_or_null("RayCast2D")
	if not raycast:
		push_error("Turret: 'RayCast2D' не найден!")
		return

	line = muzzle.get_node_or_null("Line2D")
	if not line:
		push_error("Turret: 'Line2D' не найден!")
		return

	cooldown_timer = get_node_or_null("Timer")
	if not cooldown_timer:
		push_error("Turret: 'Timer' не найден!")
		return

	raycast.target_position = Vector2(laser_range, 0)
	raycast.collision_mask = 3
	raycast.enabled = false

	line.visible = false
	line.clear_points()
	line.add_point(Vector2.ZERO)
	line.add_point(Vector2.ZERO)

	_shoot_audio = AudioStreamPlayer2D.new()
	_shoot_audio.name = "ShootAudio"
	_shoot_audio.stream = load("res://Assets/Enemies/Turret/laser_shot.mp3")
	_shoot_audio.bus = &"Effects"
	add_child(_shoot_audio)

	cooldown_timer.wait_time = cooldown
	cooldown_timer.autostart = true
	cooldown_timer.timeout.connect(_on_cooldown_timeout)

func _process(delta: float) -> void:
	var pivot_node = get_node_or_null("Node2D")
	if not pivot_node:
		return

	match current_state:
		TurretState.TRACKING:
			if is_instance_valid(player):
				pivot_node.look_at(player.global_position)

		TurretState.WARNING, TurretState.FIRING:
			if not raycast or not line or not muzzle:
				return

			_frame_count += 1
			var skip: int = 2 if current_state == TurretState.FIRING else 3
			if _frame_count % skip != 0:
				return

			raycast.force_raycast_update()
			var cast_point: Vector2 = raycast.target_position
			var hit_player := false
			if raycast.is_colliding():
				cast_point = muzzle.to_local(raycast.get_collision_point())
				var collider = raycast.get_collider()
				if collider and (collider == player or collider.is_in_group("player")):
					hit_player = true

			line.set_point_position(1, cast_point)

			if current_state == TurretState.FIRING and hit_player:
				_damage_accum += damage_per_second * delta * skip
				if _damage_accum >= 1.0:
					var dmg := int(_damage_accum)
					_damage_accum -= dmg
					if player and player.has_method("take_damage"):
						player.take_damage(dmg)

func _has_line_of_sight() -> bool:
	if not is_instance_valid(player) or not muzzle:
		return false

	var space_state = get_world_2d().direct_space_state
	var from = muzzle.global_position
	var query = PhysicsRayQueryParameters2D.create(from, player.global_position)
	query.exclude = [self.get_rid()]
	var result = space_state.intersect_ray(query)
	if result.is_empty():
		return false
	return result.collider == player

func _on_cooldown_timeout() -> void:
	if is_instance_valid(player) and current_state == TurretState.TRACKING:
		if _has_line_of_sight():
			start_attack_sequence()

func start_attack_sequence() -> void:
	cooldown_timer.stop()

	current_state = TurretState.WARNING
	raycast.enabled = true
	line.visible = true

	line.width = 2.0
	line.default_color = Color(1.0, 0.2, 0.2, 0.4)

	var warn_time := warning_duration * 0.5 if _enraged else warning_duration
	await get_tree().create_timer(warn_time).timeout
	if not is_instance_valid(self):
		return

	current_state = TurretState.FIRING
	_shoot_audio.play()

	line.width = 6.0
	line.default_color = Color(1.0, 0.0, 0.0, 1.0)

	var fire_time := laser_duration * 1.5 if _enraged else laser_duration
	await get_tree().create_timer(fire_time).timeout
	if not is_instance_valid(self):
		return

	current_state = TurretState.TRACKING
	_damage_accum = 0.0
	line.visible = false
	raycast.enabled = false
	line.set_point_position(1, Vector2.ZERO)

	cooldown_timer.start(cooldown * 0.5 if _enraged else cooldown)

func set_enraged(enraged: bool) -> void:
	_enraged = enraged
