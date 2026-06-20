extends Node2D

const FadeTransition := preload("res://Scripts/FadeTransition.gd")
const WALL_PUSHER_SCRIPT = preload("res://Scripts/WallPusher.gd")

signal player_zone_changed(zone_name: String)

enum LiftState { NONE, START, EXITING, WAITING, COMBAT, RETURNING }
var lift_state := LiftState.NONE

var combat_timer: Timer
var time_label: Label
var floor_label: Label
var _switch_count := 0
var _activated_switch_count := 0
var _arena_rotator: Node2D
var _secondary_arenas: Array[Node2D] = []
var _arena_none: Node2D
var _arena_switch: Node2D
var _none_pushers: Array[Node] = []
var _switch_pushers: Array[Node] = []
var _main_pushers: Array[Node] = []
var _player_zones: Array[String] = []
var _current_player_zone: String = ""
var _paused_saved_zone: String = ""
const _ZONE_PRIORITY := {
	"main_arena": 1,
	"corridor": 0,
	"secondary_arena": 1,
}


@onready var anim := $Hole/FloorElevator/AnimationPlayer
@onready var player_node := get_tree().get_first_node_in_group("player") as Node2D
@onready var _spawner := $EnemySpawner
@onready var _arena_spawner := $ArenaSpawner
@onready var _switch_spawner := $SwitchSpawner

@onready var shaft_colliders := [
	$Hole/FloorElevator/Top/CollisionShape,
	$Hole/FloorElevator/RightUpper/CollisionShape,
	$Hole/FloorElevator/LeftUpper/CollisionShape
]

@onready var _pause_manager := get_node("/root/PauseManager")

func _ready() -> void:
	randomize()
	_setup_arena_rotation()
	_generate_world()
	_setup_zone_triggers()
	_hide_enemies()
	_hide_player()
	_set_shaft_collision(true)
	_setup_ui()
	FadeTransition.fade_in()

	lift_state = LiftState.START
	$Hole/FloorElevator/TransportArea/CollisionShape.set_deferred("disabled", true)
	anim.play("RESET")
	anim.seek(0, true)
	anim.stop()
	_show_floor_label()
	anim.play("DownUp")
	await anim.animation_finished
	anim.play("Open")
	await anim.animation_finished
	$Hole/FloorElevator.self_modulate = Color(1, 1, 1, 1)
	$Hole/FloorElevator/TransportArea/CollisionShape.set_deferred("disabled", false)
	_show_player()
	_hide_floor_label()
	player_node.can_move = true
	add_to_group("pausable")
	_pause_manager.paused_state_changed.connect(_on_pause_state_changed)

func _setup_arena_rotation() -> void:
	_arena_rotator = AnimatableBody2D.new()
	_arena_rotator.name = "ArenaRotator"
	_arena_rotator.position = Vector2(640, 360)
	add_child(_arena_rotator)

	var floor = $Floor
	var walls = $Walls
	remove_child(floor)
	remove_child(walls)
	floor.position -= Vector2(640, 360)
	walls.position -= Vector2(640, 360)
	_arena_rotator.add_child(floor)
	_arena_rotator.add_child(walls)

	for wall in walls.get_children():
		var p = _add_pusher_to_wall(wall)
		if p:
			_main_pushers.append(p)

func _add_pusher_to_wall(wall: Node) -> Node:
	if not wall is StaticBody2D or wall.name == "Gate":
		return null
	var pusher = WALL_PUSHER_SCRIPT.new()
	pusher.name = "WallPusher"
	wall.add_child(pusher)
	for child in wall.get_children():
		if child is CollisionShape2D:
			var dup = CollisionShape2D.new()
			if child.shape is RectangleShape2D:
				var r = RectangleShape2D.new()
				r.size = child.shape.size + Vector2(0, 12)
				dup.shape = r
			else:
				dup.shape = child.shape
			dup.transform = child.transform
			pusher.add_child(dup)
	return pusher

func _on_zone_entered(body: Node2D, zone_name: String) -> void:
	if body.is_in_group("player"):
		if zone_name not in _player_zones:
			_player_zones.append(zone_name)
		var prio: int = _ZONE_PRIORITY.get(zone_name, 0)
		var cur_prio: int = _ZONE_PRIORITY.get(_current_player_zone, -1)
		if prio >= cur_prio:
			_current_player_zone = zone_name
		player_zone_changed.emit(_current_player_zone)

func _on_zone_exited(body: Node2D, zone_name: String) -> void:
	if body.is_in_group("player"):
		_player_zones.erase(zone_name)
		var best := ""
		var best_prio := -1
		for z in _player_zones:
			var p: int = _ZONE_PRIORITY.get(z, 0)
			if p > best_prio:
				best = z
				best_prio = p
		_current_player_zone = best
		player_zone_changed.emit(_current_player_zone)

func _setup_zone_triggers() -> void:
	var main_zone = _arena_rotator.get_node("Floor/ZoneTrigger") as Area2D
	if main_zone:
		main_zone.body_entered.connect(_on_zone_entered.bind("main_arena"))
		main_zone.body_exited.connect(_on_zone_exited.bind("main_arena"))

	for child in get_children():
		var z = child.get_node_or_null("FloorPolygon/ZoneTrigger") as Area2D
		if z:
			z.body_entered.connect(_on_zone_entered.bind("corridor"))
			z.body_exited.connect(_on_zone_exited.bind("corridor"))
			break

	for sa in _secondary_arenas:
		var sec_zone = sa.get_node_or_null("Pivot/Floor/ZoneTrigger") as Area2D
		if sec_zone:
			sec_zone.body_entered.connect(_on_zone_entered.bind("secondary_arena"))
			sec_zone.body_exited.connect(_on_zone_exited.bind("secondary_arena"))

func _setup_ui() -> void:
	var ui := CanvasLayer.new()
	ui.name = "TimerUI"
	ui.layer = 128
	add_child(ui)
	time_label = Label.new()
	time_label.name = "TimeLabel"
	time_label.add_theme_font_size_override("font_size", 32)
	time_label.add_theme_color_override("font_color", Color.WHITE)
	time_label.add_theme_constant_override("outline_size", 4)
	time_label.add_theme_color_override("font_outline_color", Color.BLACK)
	time_label.position = Vector2(10, 10)
	ui.add_child(time_label)

	floor_label = Label.new()
	floor_label.name = "FloorLabel"
	floor_label.add_theme_font_size_override("font_size", 64)
	floor_label.add_theme_color_override("font_color", Color.WHITE)
	floor_label.add_theme_constant_override("outline_size", 6)
	floor_label.add_theme_color_override("font_outline_color", Color.BLACK)
	floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floor_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	floor_label.size = Vector2(600, 100)
	floor_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	floor_label.modulate = Color(1, 1, 1, 0)
	floor_label.text = "Этаж " + str(GameState.current_floor)
	ui.add_child(floor_label)

	var music = AudioStreamPlayer.new()
	music.name = "MusicPlayer"
	music.stream = load("res://Assets/Sounds/music/neon-pulse_93545.mp3")
	music.bus = &"Music"
	music.autoplay = true
	add_child(music)

func start_exit_sequence() -> void:
	if lift_state != LiftState.START:
		return
	lift_state = LiftState.EXITING
	player_node.can_move = false
	anim.stop()
	anim.play("Close")
	await anim.animation_finished
	_shake_camera()
	_set_shaft_collision(false)
	anim.play("DownClose")
	await anim.animation_finished
	$Hole/FloorElevator.self_modulate = Color(1, 1, 1, 0)
	_spawn_enemies(1)
	_spawn_switches(1)
	_show_enemies()
	lift_state = LiftState.WAITING
	player_node.can_move = true
	_connect_switch()

func _start_combat_timer() -> void:
	combat_timer = Timer.new()
	combat_timer.name = "CombatTimer"
	combat_timer.wait_time = 15.0
	combat_timer.one_shot = true
	combat_timer.timeout.connect(_on_combat_timeout)
	add_child(combat_timer)
	combat_timer.start()
	_rotation_speed = 0.0
	for sa in _secondary_arenas:
		sa.rotation_speed = 0.0

func _connect_switch() -> void:
	var switches := get_tree().get_nodes_in_group("switch")
	if switches.is_empty():
		_start_combat_timer()
		lift_state = LiftState.COMBAT
		return

	_switch_count = switches.size()
	_activated_switch_count = 0
	for s in switches:
		if s.has_signal("activated"):
			s.activated.connect(_on_switch_activated)

func _on_switch_activated() -> void:
	if lift_state != LiftState.WAITING:
		return
	_activated_switch_count += 1
	if _activated_switch_count >= _switch_count:
		_start_combat_timer()
		lift_state = LiftState.COMBAT

func _on_combat_timeout() -> void:
	if lift_state != LiftState.COMBAT:
		return
	_rotation_speed = 0.5
	for sa in _secondary_arenas:
		sa.rotation_speed = 0.5
	_switch_spawner.clear_spawned()
	_set_shaft_collision(true)
	lift_state = LiftState.RETURNING
	anim.play("DownUp")
	await anim.animation_finished
	anim.play("Open")
	await anim.animation_finished
	$Hole/FloorElevator.self_modulate = Color(1, 1, 1, 1)

func start_restart() -> void:
	if lift_state != LiftState.RETURNING:
		return
	player_node.can_move = false
	lift_state = LiftState.NONE
	_hide_player()
	$Hole/FloorElevator/TransportArea.restarting = true
	anim.stop()
	anim.play("Close")
	await anim.animation_finished
	GameState.current_floor += 1
	anim.play("Up")
	await anim.animation_finished
	await FadeTransition.fade_out()
	get_tree().reload_current_scene()

func _hide_player() -> void:
	player_node.process_mode = Node.PROCESS_MODE_DISABLED
	for child in player_node.get_children():
		if child is Camera2D:
			continue
		if child is AnimatedSprite2D:
			child.hide()
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
		if child is AudioStreamPlayer2D:
			child.stop()

func _show_player() -> void:
	player_node.process_mode = Node.PROCESS_MODE_INHERIT
	for child in player_node.get_children():
		if child is Camera2D:
			continue
		if child is AnimatedSprite2D:
			child.show()
		if child is CollisionShape2D:
			child.set_deferred("disabled", false)

func _hide_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.hide()
		enemy.z_index = 0
		enemy.set_physics_process(false)
		_disable_collision_shapes(enemy)
		for child in enemy.get_children():
			if child is Timer:
				if child.has_method("stop"):
					child.stop()
		if enemy is RigidBody2D:
			enemy.freeze = true

func _show_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.show()
		enemy.z_index = 6
		enemy.set_physics_process(true)
		_enable_collision_shapes(enemy)
		for child in enemy.get_children():
			if child is Timer and child.has_method("start"):
				if child.has_method("stop") and child.is_stopped():
					child.start()
		if enemy is RigidBody2D:
			enemy.freeze = false

func _disable_collision_shapes(node: Node) -> void:
	if node is CollisionShape2D:
		node.set_deferred("disabled", true)
	for child in node.get_children():
		_disable_collision_shapes(child)

func _enable_collision_shapes(node: Node) -> void:
	if node is CollisionShape2D:
		node.set_deferred("disabled", false)
	for child in node.get_children():
		_enable_collision_shapes(child)

func _generate_world() -> void:
	var floor_rect = preload("res://Objects/Floor_Rectangle.tscn")
	var arena_none_scene = preload("res://Objects/ArenaNone.tscn")
	var arena_switch_scene = preload("res://Objects/ArenaSwitch.tscn")
	var center = Vector2(640, 360)
	var door_offset = Vector2(1090, 0)
	var corridor_dist = 570
	var angles := [0, 60, 120, 180, 240, 300]
	var chosen = angles[randi() % angles.size()]
	var rad = deg_to_rad(chosen)
	var dir = Vector2(cos(rad), sin(rad))
	var inst = floor_rect.instantiate()
	inst.rotation = rad
	inst.position = center + dir * corridor_dist - door_offset.rotated(rad)
	add_child(inst)
	for child in inst.get_children():
		if child is Area2D and child.script and child.script.resource_path == "res://Scripts/DoorTrigger.gd":
			child.add_to_group("gate_trigger")
	var corridor_end = center + dir * corridor_dist + Vector2(2043, 0).rotated(rad) - door_offset.rotated(rad)
	var arena = arena_none_scene.instantiate()
	arena.name = "ArenaNone"
	add_child(arena)
	arena.position = corridor_end + dir * 532.5 - Vector2(640, 360)
	_secondary_arenas.append(arena)

	_arena_none = arena
	var none_walls = arena.get_node_or_null("Pivot/Walls")
	if none_walls:
		for wall in none_walls.get_children():
			var p = _add_pusher_to_wall(wall)
			if p:
				_none_pushers.append(p)

	var arena_none_pivot = arena.position + Vector2(640, 360)
	var second_angles := angles.duplicate()
	second_angles.erase(chosen)
	second_angles.erase((chosen + 180) % 360)
	var second_chosen = second_angles[randi() % second_angles.size()]
	var second_rad = deg_to_rad(second_chosen)
	var second_dir = Vector2(cos(second_rad), sin(second_rad))
	var second_inst = floor_rect.instantiate()
	second_inst.rotation = second_rad
	second_inst.position = arena_none_pivot + second_dir * corridor_dist - door_offset.rotated(second_rad)
	add_child(second_inst)
	for child in second_inst.get_children():
		if child is Area2D and child.script and child.script.resource_path == "res://Scripts/DoorTrigger.gd":
			child.add_to_group("gate_trigger")
	var second_corridor_end = arena_none_pivot + second_dir * corridor_dist + Vector2(2043, 0).rotated(second_rad) - door_offset.rotated(second_rad)
	var arena_switch = arena_switch_scene.instantiate()
	arena_switch.name = "ArenaSwitch"
	add_child(arena_switch)
	arena_switch.position = second_corridor_end + second_dir * 532.5 - Vector2(640, 360)
	_secondary_arenas.append(arena_switch)

	_arena_switch = arena_switch
	var switch_walls = arena_switch.get_node_or_null("Pivot/Walls")
	if switch_walls:
		for wall in switch_walls.get_children():
			var p = _add_pusher_to_wall(wall)
			if p:
				_switch_pushers.append(p)

func get_player_zone() -> String:
	if _pause_manager and _pause_manager.is_paused():
		return _paused_saved_zone
	return _current_player_zone

func _spawn_enemies(level: int) -> void:
	_spawner.spawn(level, self, "spawn_point_main", "main_arena")
	_arena_spawner.spawn(level, self, "spawn_point_arena", "secondary_arena")
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.collision_mask |= 2

func _spawn_switches(level: int) -> void:
	_switch_spawner.spawn(level, self)

func _show_floor_label() -> void:
	if not floor_label:
		return
	floor_label.text = "Этаж " + str(GameState.current_floor)
	floor_label.modulate = Color(1, 1, 1, 0)
	floor_label.show()
	var tw = create_tween()
	tw.tween_property(floor_label, "modulate:a", 1.0, 0.5)

func _hide_floor_label() -> void:
	if not floor_label:
		return
	var tw = create_tween()
	tw.tween_property(floor_label, "modulate:a", 0.0, 0.5)

func _shake_camera(intensity: float = 8.0, duration: float = 0.4) -> void:
	var camera := player_node.get_node("PlayerCamera") as Camera2D
	if not camera:
		return
	var original := camera.offset
	var tween := create_tween()
	for _i in range(8):
		var target := original + Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(camera, "offset", target, duration / 8.0)
	tween.tween_property(camera, "offset", original, duration / 8.0)

func _set_shaft_collision(enabled: bool) -> void:
	for cs in shaft_colliders:
		cs.set_deferred("disabled", not enabled)


var _rotation_speed := 0.5

func _update_gate() -> void:
	var gates := [_arena_rotator.get_node("Walls/W4/Gate") as StaticBody2D]
	for sa in _secondary_arenas:
		var g = sa.get_node_or_null("Pivot/Walls/W4/Gate") as StaticBody2D
		if g:
			gates.append(g)

	var main_near = false
	var sec_near = false
	for gate in gates:
		if lift_state == LiftState.COMBAT:
			gate.collision_layer = 3
			gate.get_node("Visual").modulate = Color(1, 1, 1, 1.0)
			continue
		var gate_pos = gate.global_position
		var is_near = false
		for t in get_tree().get_nodes_in_group("gate_trigger"):
			if gate_pos.distance_to(t.global_position) < 80.0:
				is_near = true
				break
		gate.collision_layer = 2 if is_near else 3
		gate.get_node("Visual").modulate = Color(1, 1, 1, 0.3 if is_near else 1.0)
		if is_near:
			var in_secondary := false
			for sa in _secondary_arenas:
				if sa.is_ancestor_of(gate):
					sec_near = true
					in_secondary = true
					break
			if not in_secondary:
				main_near = true

	if lift_state != LiftState.COMBAT:
		_rotation_speed = 0.05 if main_near else 0.5
		for sa in _secondary_arenas:
			sa.rotation_speed = 0.05 if sec_near else 0.5


func _physics_process(delta: float) -> void:
	_arena_rotator.rotation += delta * _rotation_speed
	_update_gate()

	var main_center = _arena_rotator.global_position
	for p in _main_pushers:
		if is_instance_valid(p):
			p.angular_velocity = _rotation_speed
			p.rotation_center = main_center

	for sa in [_arena_none, _arena_switch]:
		if not is_instance_valid(sa):
			continue
		var pivot = sa.get_node_or_null("Pivot")
		if not pivot:
			continue
		var center = pivot.global_position
		var pushers = _none_pushers if sa == _arena_none else _switch_pushers
		for p in pushers:
			if is_instance_valid(p):
				p.angular_velocity = sa.rotation_speed
				p.rotation_center = center

func _process(delta: float) -> void:
	if combat_timer and not combat_timer.is_stopped():
		var remaining: float = ceil(combat_timer.time_left)
		var m := int(remaining / 60.0)
		var s := int(remaining) % 60
		time_label.text = "%02d:%02d" % [m, s]
	else:
		time_label.text = "00:00"


func _on_pause_state_changed(is_paused: bool) -> void:
	if is_paused:
		_paused_saved_zone = _current_player_zone
	else:
		_current_player_zone = _paused_saved_zone
