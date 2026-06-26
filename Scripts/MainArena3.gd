extends Node2D

const FadeTransition := preload("res://Scripts/FadeTransition.gd")
const WALL_PUSHER_SCRIPT = preload("res://Scripts/WallPusher.gd")

signal player_zone_changed(zone_name: String)

enum LiftState { NONE, START, EXITING, WAITING, COMBAT, RETURNING }
enum QuestMode { CLASSIC, TIME_ATTACK }
var lift_state := LiftState.NONE
var _quest_mode := QuestMode.CLASSIC

var combat_timer: Timer
var rage_timer: Timer
var time_label: Label
var floor_label: Label
var quest_label: Label
var _fps_label: Label
var _switch_count := 0
var _activated_switch_count := 0
var _first_switch_activated := false
var _first_switch_ref: Node = null
var _arena_rotator: Node2D
var _secondary_arenas: Array[Node2D] = []
var _arena_none: Node2D
var _arena_switch: Node2D
var _arena_switches: Array[Node2D] = []
var _none_pushers: Array[Node] = []
var _switch_pushers: Array[Node] = []
var _main_pushers: Array[Node] = []
var _arena_pushers: Dictionary = {}
var _player_zones: Array[String] = []
var _current_player_zone: String = ""
var _paused_saved_zone: String = ""
var _gate_audio: AudioStreamPlayer2D
var _arena_scale_factor := 1.0
var _floor_start_time: float = 0.0
const _ZONE_PRIORITY := {
	"main_arena": 1,
	"arena_none": 1,
	"arena_switch": 1,
	"corridor": 0,
}


@onready var anim := $Hole/FloorElevator/AnimationPlayer
@onready var player_node := get_tree().get_first_node_in_group("player") as Node2D
@onready var _spawner := $EnemySpawner
@onready var _arena_spawner := $ArenaSpawner

@onready var shaft_colliders := [
	$Hole/FloorElevator/Top/CollisionShape,
	$Hole/FloorElevator/RightUpper/CollisionShape,
	$Hole/FloorElevator/LeftUpper/CollisionShape
]

@onready var _pause_manager := get_node("/root/PauseManager")

func _ready() -> void:
	randomize()
	_quest_mode = QuestMode.CLASSIC if randi() % 2 == 0 else QuestMode.TIME_ATTACK
	var floor_num = GameState.current_floor
	_arena_scale_factor = 1.0 + (MAX_FLOOR - floor_num) * 0.15
	_setup_arena_rotation()
	_generate_world()
	_scale_arenas()
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
	$Hole/FloorElevator/RoofElevator2.z_index = 3
	$Hole/FloorElevator/Door1.visible = true
	$Hole/FloorElevator/Door2.visible = true
	anim.play("DownUp")
	await anim.animation_finished
	anim.play("Open")
	if _gate_audio:
		_gate_audio.play()
	await anim.animation_finished
	$Hole/FloorElevator.self_modulate = Color(1, 1, 1, 1)
	$Hole/FloorElevator/TransportArea/CollisionShape.set_deferred("disabled", false)
	_show_player()
	_hide_floor_label()
	_restore_bucket_state()
	_restore_inventory_state()
	player_node.can_move = true
	_floor_start_time = Time.get_ticks_msec() / 1000.0
	add_to_group("pausable")
	_pause_manager.paused_state_changed.connect(_on_pause_state_changed)

func _setup_arena_rotation() -> void:
	_arena_rotator = AnimatableBody2D.new()
	_arena_rotator.name = "ArenaRotator"
	_arena_rotator.position = Vector2(640, 360)
	add_child(_arena_rotator)

	var scaler = Node2D.new()
	scaler.name = "ArenaScaler"
	_arena_rotator.add_child(scaler)

	var floor = $Floor
	var walls = $Walls
	remove_child(floor)
	remove_child(walls)
	floor.position -= Vector2(640, 360)
	walls.position -= Vector2(640, 360)
	scaler.add_child(floor)
	scaler.add_child(walls)

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
	var main_zone = _arena_rotator.get_node("ArenaScaler/Floor/ZoneTrigger") as Area2D
	if main_zone:
		main_zone.body_entered.connect(_on_zone_entered.bind("main_arena"))
		main_zone.body_exited.connect(_on_zone_exited.bind("main_arena"))

	for child in get_children():
		var z = child.get_node_or_null("FloorPolygon/ZoneTrigger") as Area2D
		if z:
			z.body_entered.connect(_on_zone_entered.bind("corridor"))
			z.body_exited.connect(_on_zone_exited.bind("corridor"))

	if _arena_none:
		var none_zone = _arena_none.get_node_or_null("Pivot/Floor/ZoneTrigger") as Area2D
		if none_zone:
			none_zone.body_entered.connect(_on_zone_entered.bind("arena_none"))
			none_zone.body_exited.connect(_on_zone_exited.bind("arena_none"))
	for sw in _arena_switches:
		var switch_zone = sw.get_node_or_null("Pivot/Floor/ZoneTrigger") as Area2D
		if switch_zone:
			switch_zone.body_entered.connect(_on_zone_entered.bind("arena_switch"))
			switch_zone.body_exited.connect(_on_zone_exited.bind("arena_switch"))

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

	_fps_label = Label.new()
	_fps_label.name = "FPSLabel"
	_fps_label.add_theme_font_size_override("font_size", 20)
	_fps_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	_fps_label.add_theme_constant_override("outline_size", 2)
	_fps_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_fps_label.position = Vector2(10, 50)
	_fps_label.visible = GameState.show_fps
	_fps_label.add_to_group("fps_label")
	ui.add_child(_fps_label)

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

	quest_label = Label.new()
	quest_label.name = "QuestLabel"
	quest_label.add_theme_font_size_override("font_size", 24)
	quest_label.add_theme_color_override("font_color", Color.GOLD)
	quest_label.add_theme_constant_override("outline_size", 3)
	quest_label.add_theme_color_override("font_outline_color", Color.BLACK)
	quest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quest_label.position = Vector2(220, 80)
	quest_label.size = Vector2(800, 40)
	quest_label.text = "Активировать 3 рычага" if _quest_mode == QuestMode.CLASSIC else "Активировать 2 рычага"
	ui.add_child(quest_label)

	var music = AudioStreamPlayer.new()
	music.name = "MusicPlayer"
	music.stream = load("res://Assets/Sounds/music/neon-pulse_93545.mp3")
	music.bus = &"Music"
	music.autoplay = true
	music.finished.connect(music.play)
	add_child(music)

	_gate_audio = AudioStreamPlayer2D.new()
	_gate_audio.name = "GateAudio"
	_gate_audio.stream = load("res://Assets/Sounds/Effects/elevator-ringing.mp3")
	_gate_audio.bus = &"Effects"
	add_child(_gate_audio)

	var sm = get_node("/root/StyleManager")
	if sm and sm.has_method("setup_display"):
		sm.setup_display(self)

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
	$Hole/FloorElevator/RoofElevator2.z_index = 0
	$Hole/FloorElevator/Door1.visible = false
	$Hole/FloorElevator/Door2.visible = false
	$Hole/FloorElevator.self_modulate = Color(1, 1, 1, 0)
	_spawn_secondary_enemies(GameState.current_floor)
	_spawner.spawn(GameState.current_floor, self, "spawn_point_main", "main_arena")
	_spawn_switches(GameState.current_floor)
	_show_enemies()
	lift_state = LiftState.WAITING
	player_node.can_move = true
	_connect_switch()

func _spawn_secondary_enemies(level: int) -> void:
	if _arena_none:
		var none_spawner = _arena_none.get_node_or_null("Pivot/EnemySpawner")
		if none_spawner:
			none_spawner.spawn(level, self, "spawn_point_none", "arena_none", _arena_none)
	for sw in _arena_switches:
		var switch_spawner = sw.get_node_or_null("Pivot/EnemySpawner")
		if switch_spawner:
			switch_spawner.spawn(level, self, "spawn_point_switch", "arena_switch", sw)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.collision_mask |= 2

func _start_combat_timer() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.show()
		enemy.z_index = 6
		enemy.set_physics_process(true)
		enemy.collision_mask |= 2
		_enable_collision_shapes(enemy)
		for child in enemy.get_children():
			if child is Timer and child.has_method("start"):
				if child.has_method("stop") and child.is_stopped():
					child.start()
		if enemy is RigidBody2D:
			enemy.freeze = false
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
	_first_switch_activated = false
	_first_switch_ref = null
	for s in switches:
		if s.has_signal("activated"):
			s.activated.connect(_on_switch_activated.bind(s))

func _on_switch_activated(switch: Node) -> void:
	if lift_state != LiftState.WAITING:
		return

	if _quest_mode == QuestMode.CLASSIC:
		_activated_switch_count += 1
		if _activated_switch_count >= _switch_count:
			_start_combat_timer()
			lift_state = LiftState.COMBAT
			_update_quest_text("done")
	elif _quest_mode == QuestMode.TIME_ATTACK:
		if not _first_switch_activated:
			_first_switch_activated = true
			_first_switch_ref = switch
			_activated_switch_count = 1
			_enrage_enemies()
			_start_rage_timer(30.0)
			_update_quest_text("first_switch")
		else:
			_activated_switch_count = 2
			_unlock_elevator()

func _start_rage_timer(duration: float) -> void:
	rage_timer = Timer.new()
	rage_timer.name = "RageTimer"
	rage_timer.wait_time = duration
	rage_timer.one_shot = true
	rage_timer.timeout.connect(_on_rage_timeout)
	add_child(rage_timer)
	rage_timer.start()

func _on_rage_timeout() -> void:
	if is_instance_valid(_first_switch_ref) and _first_switch_ref.has_method("deactivate"):
		_first_switch_ref.deactivate()
	_first_switch_activated = false
	_first_switch_ref = null
	_activated_switch_count = 0
	_disband_enemies()
	_update_quest_text("reset")

func _enrage_enemies() -> void:
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.has_method("set_enraged"):
			e.set_enraged(true)

func _disband_enemies() -> void:
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.has_method("set_enraged"):
			e.set_enraged(false)

func _unlock_elevator() -> void:
	if rage_timer:
		rage_timer.stop()
		rage_timer.queue_free()
		rage_timer = null
	for s in get_tree().get_nodes_in_group("switch"):
		if s.has_method("play_ready"):
			s.play_ready()
	_set_shaft_collision(true)
	lift_state = LiftState.RETURNING
	_update_quest_text("done")
	$Hole/FloorElevator/RoofElevator2.z_index = 3
	$Hole/FloorElevator/Door1.visible = true
	$Hole/FloorElevator/Door2.visible = true
	anim.play("DownUp")
	await anim.animation_finished
	anim.play("Open")
	await anim.animation_finished
	$Hole/FloorElevator.self_modulate = Color(1, 1, 1, 1)

func _update_quest_text(state: String) -> void:
	match _quest_mode:
		QuestMode.CLASSIC:
			match state:
				"done":
					quest_label.text = "Идти к лифту"
				_:
					quest_label.text = "Активировать 3 рычага"
		QuestMode.TIME_ATTACK:
			match state:
				"first_switch":
					quest_label.text = "Найди второй рычаг"
				"done":
					quest_label.text = "Идти к лифту"
				"reset":
					quest_label.text = "Активировать 2 рычага"
				_:
					quest_label.text = "Активировать 2 рычага"

func _on_combat_timeout() -> void:
	if lift_state != LiftState.COMBAT:
		return
	_rotation_speed = 0.5
	for sa in _secondary_arenas:
		sa.rotation_speed = 0.5
	for s in get_tree().get_nodes_in_group("switch"):
		if is_instance_valid(s):
			s.queue_free()
	_set_shaft_collision(true)
	lift_state = LiftState.RETURNING
	$Hole/FloorElevator/RoofElevator2.z_index = 3
	$Hole/FloorElevator/Door1.visible = true
	$Hole/FloorElevator/Door2.visible = true
	anim.play("DownUp")
	await anim.animation_finished
	anim.play("Open")
	await anim.animation_finished
	$Hole/FloorElevator.self_modulate = Color(1, 1, 1, 1)

const MAX_FLOOR := 3

func _save_floor_state() -> void:
	GameState.has_bucket = false
	if not is_instance_valid(player_node):
		return
	if player_node.has_method("_try_bucket_hit") and player_node._bucket:
		GameState.has_bucket = true
		GameState.bucket_charges = player_node._bucket.charges
	if player_node.has_method("get_inventory"):
		GameState.inventory = player_node.get_inventory().duplicate(true)
	GameState.last_floor_hp = player_node.current_lives if "current_lives" in player_node else 0
	GameState.last_floor_time = (Time.get_ticks_msec() / 1000.0) - _floor_start_time

func _restore_bucket_state() -> void:
	if not GameState.has_bucket:
		return
	if not is_instance_valid(player_node):
		return
	if player_node.has_method("_setup_bucket"):
		player_node._setup_bucket()
		if player_node._bucket:
			player_node._bucket.charges = GameState.bucket_charges

func _restore_inventory_state() -> void:
	if not is_instance_valid(player_node):
		return
	if not player_node.has_method("set_slot"):
		return
	for i in range(GameState.inventory.size()):
		var slot = GameState.inventory[i]
		if slot.id != "":
			player_node.set_slot(i, slot.id, slot.icon, slot.name)

func start_restart() -> void:
	if lift_state != LiftState.RETURNING:
		return
	_save_floor_state()
	player_node.can_move = false
	lift_state = LiftState.NONE
	_hide_player()
	$Hole/FloorElevator/TransportArea.restarting = true
	anim.stop()
	anim.play("Close")
	await anim.animation_finished
	anim.play("Up")
	await anim.animation_finished
	_set_shaft_collision(false)
	$Hole/FloorElevator/Door1.visible = false
	$Hole/FloorElevator/Door2.visible = false
	$Hole/FloorElevator.self_modulate = Color(1, 1, 1, 0)
	await FadeTransition.fade_out()
	get_tree().change_scene_to_file("res://Scenes/Shop/Shop.tscn")

func _hide_player() -> void:
	player_node.process_mode = Node.PROCESS_MODE_DISABLED
	for child in player_node.get_children():
		if child is Camera2D:
			continue
		if child is AnimatedSprite2D:
			child.hide()
		if child is Sprite2D:
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
		if child is Sprite2D:
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
	_arena_switches.clear()
	_arena_pushers.clear()
	var floor_rect = preload("res://Objects/Rooms/Floor_Rectangle.tscn")
	var arena_none_scene = preload("res://Objects/Rooms/ArenaNone.tscn")
	var arena_switch_scene = preload("res://Objects/Rooms/ArenaSwitch.tscn")
	var arena_radius = 532.5 * _arena_scale_factor
	var corridor_dist = 570.0 * _arena_scale_factor
	var center = Vector2(640, 360)
	var door_offset = Vector2(1090, 0)
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
	arena.position = corridor_end + dir * arena_radius - Vector2(640, 360)
	_secondary_arenas.append(arena)

	var none_walls = arena.get_node_or_null("Pivot/Walls")
	if none_walls:
		for wall in none_walls.get_children():
			var p = _add_pusher_to_wall(wall)
			if p:
				_none_pushers.append(p)
				if not _arena_pushers.has(arena):
					_arena_pushers[arena] = []
				_arena_pushers[arena].append(p)

	_arena_none = arena

	var hex_angles := [0, 60, 120, 180, 240, 300]
	var main_idx = hex_angles.find(chosen)
	var second_indices := []
	for i in 6:
		if i != main_idx and i != (main_idx + 3) % 6:
			second_indices.append(i)
	second_indices.shuffle()
	var arena_none_pivot = corridor_end + dir * arena_radius

	if _quest_mode == QuestMode.TIME_ATTACK:
		for j in range(2):
			var s_angle = hex_angles[second_indices[j]]
			var s_rad = deg_to_rad(s_angle)
			var s_dir = Vector2(cos(s_rad), sin(s_rad))
			var s_inst = floor_rect.instantiate()
			s_inst.rotation = s_rad
			s_inst.position = arena_none_pivot + s_dir * corridor_dist - door_offset.rotated(s_rad)
			add_child(s_inst)
			for child in s_inst.get_children():
				if child is Area2D and child.script and child.script.resource_path == "res://Scripts/DoorTrigger.gd":
					child.add_to_group("gate_trigger")
			var s_corridor_end = arena_none_pivot + s_dir * corridor_dist + Vector2(2043, 0).rotated(s_rad) - door_offset.rotated(s_rad)
			var arena_switch = arena_switch_scene.instantiate()
			arena_switch.name = "ArenaSwitch" + str(j + 1)
			add_child(arena_switch)
			arena_switch.position = s_corridor_end + s_dir * arena_radius - Vector2(640, 360)
			_secondary_arenas.append(arena_switch)
			_arena_switches.append(arena_switch)
			if j == 0:
				_arena_switch = arena_switch
			var switch_walls = arena_switch.get_node_or_null("Pivot/Walls")
			if switch_walls:
				for wall in switch_walls.get_children():
					var p = _add_pusher_to_wall(wall)
					if p:
						_switch_pushers.append(p)
						if not _arena_pushers.has(arena_switch):
							_arena_pushers[arena_switch] = []
						_arena_pushers[arena_switch].append(p)
	else:
		var second_chosen = hex_angles[second_indices[0]]
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
		arena_switch.position = second_corridor_end + second_dir * arena_radius - Vector2(640, 360)
		_secondary_arenas.append(arena_switch)
		_arena_switches.append(arena_switch)

		_arena_switch = arena_switch
		var switch_walls = arena_switch.get_node_or_null("Pivot/Walls")
		if switch_walls:
			for wall in switch_walls.get_children():
				var p = _add_pusher_to_wall(wall)
				if p:
					_switch_pushers.append(p)
					if not _arena_pushers.has(arena_switch):
						_arena_pushers[arena_switch] = []
					_arena_pushers[arena_switch].append(p)

func get_player_zone() -> String:
	if _pause_manager and _pause_manager.is_paused():
		return _paused_saved_zone
	return _current_player_zone

func _scale_arenas() -> void:
	if _arena_scale_factor == 1.0:
		return
	var scaler = _arena_rotator.get_node_or_null("ArenaScaler")
	if scaler:
		scaler.scale = Vector2(_arena_scale_factor, _arena_scale_factor)
	for sa in _secondary_arenas:
		var pivot = sa.get_node_or_null("Pivot")
		if pivot:
			pivot.scale = Vector2(_arena_scale_factor, _arena_scale_factor)

func _spawn_switches(level: int) -> void:
	var spawner = preload("res://Objects/SwitchSpawner.tscn").instantiate()
	add_child(spawner)
	spawner.spawn(level, self, _quest_mode)

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
	var gates := [_arena_rotator.get_node("ArenaScaler/Walls/W4/Gate") as StaticBody2D]
	for sa in _secondary_arenas:
		var g = sa.get_node_or_null("Pivot/Walls/W4/Gate") as StaticBody2D
		if g:
			gates.append(g)

	var in_corridor = _current_player_zone == "corridor"
	if lift_state != LiftState.COMBAT:
		for sa in _secondary_arenas:
			sa.rotation_speed = 1.0 if in_corridor else 0.5

	var main_near = false
	for gate in gates:
		if lift_state == LiftState.COMBAT:
			gate.collision_layer = 3
			gate.get_node("Visual").modulate = Color(1, 0.15, 0.15)
			continue
		var gate_pos = gate.global_position
		var is_near = false
		for t in get_tree().get_nodes_in_group("gate_trigger"):
			if gate_pos.distance_to(t.global_position) < 80.0:
				is_near = true
				break
		gate.collision_layer = 2 if is_near else 3
		gate.get_node("Visual").modulate = Color(1, 1, 1, 0.3 if is_near else 1.0)
		if is_near and lift_state != LiftState.COMBAT:
			var sa_owner = _arena_none if _arena_none and _arena_none.is_ancestor_of(gate) else null
			if not sa_owner:
				for sw in _arena_switches:
					if sw.is_ancestor_of(gate):
						sa_owner = sw
						break
			if sa_owner:
				sa_owner.rotation_speed = 0.05
			else:
				main_near = true

	if lift_state != LiftState.COMBAT:
		_rotation_speed = 0.05 if main_near else (1.0 if in_corridor else 0.5)


func _physics_process(delta: float) -> void:
	_arena_rotator.rotation += delta * _rotation_speed
	_update_gate()

	var main_center = _arena_rotator.global_position
	for p in _main_pushers:
		if is_instance_valid(p):
			p.angular_velocity = _rotation_speed
			p.rotation_center = main_center

	for sa in _secondary_arenas:
		if not is_instance_valid(sa):
			continue
		var pivot = sa.get_node_or_null("Pivot")
		if not pivot:
			continue
		var center = pivot.global_position
		var pushers = _arena_pushers.get(sa, [])
		for p in pushers:
			if is_instance_valid(p):
				p.angular_velocity = sa.rotation_speed
				p.rotation_center = center

func _process(delta: float) -> void:
	if _fps_label:
		_fps_label.text = "FPS: " + str(Engine.get_frames_per_second())
	if combat_timer and not combat_timer.is_stopped():
		var remaining: float = ceil(combat_timer.time_left)
		var m := int(remaining / 60.0)
		var s := int(remaining) % 60
		time_label.text = "%02d:%02d" % [m, s]
	elif rage_timer and not rage_timer.is_stopped():
		var remaining: float = ceil(rage_timer.time_left)
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
