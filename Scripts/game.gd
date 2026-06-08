extends Node2D

const FadeTransition := preload("res://Scripts/FadeTransition.gd")

enum LiftState { NONE, START, EXITING, WAITING, COMBAT, RETURNING }
var lift_state := LiftState.NONE

var combat_timer: Timer
var time_label: Label
var _switch_count := 0
var _activated_switch_count := 0
var _arena_rotator: Node2D

@onready var anim := $Hole/FloorElevator/AnimationPlayer
@onready var player_node := get_tree().get_first_node_in_group("player") as Node2D
@onready var _spawner := $EnemySpawner
@onready var _switch_spawner := $SwitchSpawner

@onready var shaft_colliders := [
	$Hole/FloorElevator/Top/CollisionShape,
	$Hole/FloorElevator/RightUpper/CollisionShape,
	$Hole/FloorElevator/LeftUpper/CollisionShape
]

func _ready() -> void:
	_setup_arena_rotation()
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
	anim.play("DownUp")
	await anim.animation_finished
	anim.play("Open")
	await anim.animation_finished
	$Hole/FloorElevator/TransportArea/CollisionShape.set_deferred("disabled", false)
	_show_player()
	player_node.can_move = true

func _setup_arena_rotation() -> void:
	_arena_rotator = Node2D.new()
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
		_add_wall_pusher(wall)

func _add_wall_pusher(wall: StaticBody2D) -> void:
	var pusher := Area2D.new()
	pusher.name = "WallPusher"
	pusher.set_script(preload("res://Scripts/WallPusher.gd"))
	for child in wall.get_children():
		var cs := child as CollisionShape2D
		if cs and cs.shape:
			var copy := CollisionShape2D.new()
			copy.shape = cs.shape
			pusher.add_child(copy)
	wall.add_child(pusher)
	if wall.name == "W4":
		var gate = wall.get_node("Gate") as StaticBody2D
		if gate:
			_add_wall_pusher(gate)

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
	_hide_enemies()
	_spawner.clear_spawned()
	_switch_spawner.clear_spawned()
	_set_shaft_collision(true)
	lift_state = LiftState.RETURNING
	anim.play("DownUp")
	await anim.animation_finished
	anim.play("Open")
	await anim.animation_finished

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
			if child is Timer and child.name == "BurstTimer":
				if enemy.has_method("set_random_burst_pause"):
					enemy.set_random_burst_pause()
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

func _spawn_enemies(level: int) -> void:
	_spawner.spawn(level, self)

func _spawn_switches(level: int) -> void:
	_switch_spawner.spawn(level, self)

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
	var gate = _arena_rotator.get_node("Walls/W4/Gate") as StaticBody2D
	var trigger_pos = $DoorTrigger.global_position
	var gate_pos = gate.global_position
	var dist = gate_pos.distance_to(trigger_pos)
	var is_near = dist < 80.0

	gate.get_node("CollisionShape").set_deferred("disabled", is_near)
	gate.get_node("Visual").modulate = Color(1, 1, 1, 0.3 if is_near else 1.0)

	var pusher = gate.get_node("WallPusher") as Area2D
	if pusher:
		for child in pusher.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", is_near)

	_rotation_speed = 0.05 if is_near else 0.5


func _process(delta: float) -> void:
	_arena_rotator.rotation += delta * _rotation_speed
	_update_gate()

	if combat_timer and not combat_timer.is_stopped():
		var remaining: float = ceil(combat_timer.time_left)
		var m := int(remaining / 60.0)
		var s := int(remaining) % 60
		time_label.text = "%02d:%02d" % [m, s]
	else:
		time_label.text = "00:00"
