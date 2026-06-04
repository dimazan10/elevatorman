extends Node2D

const FadeTransition := preload("res://Scripts/FadeTransition.gd")

enum LiftState { NONE, START, EXITING, COMBAT, RETURNING }
var lift_state := LiftState.NONE

var combat_timer: Timer
var time_label: Label

@onready var anim := $Hole/FloorElevator/AnimationPlayer
@onready var player_node := get_tree().get_first_node_in_group("player") as Node2D

@onready var shaft_colliders := [
	$Hole/FloorElevator/Top/CollisionShape,
	$Hole/FloorElevator/RightUpper/CollisionShape,
	$Hole/FloorElevator/LeftUpper/CollisionShape
]

func _ready() -> void:
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
	_show_enemies()
	_start_combat_timer()
	lift_state = LiftState.COMBAT
	player_node.can_move = true

func _start_combat_timer() -> void:
	combat_timer = Timer.new()
	combat_timer.name = "CombatTimer"
	combat_timer.wait_time = 15.0
	combat_timer.one_shot = true
	combat_timer.timeout.connect(_on_combat_timeout)
	add_child(combat_timer)
	combat_timer.start()

func _on_combat_timeout() -> void:
	if lift_state != LiftState.COMBAT:
		return
	_hide_enemies()
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


func _process(_delta: float) -> void:
	if combat_timer and not combat_timer.is_stopped():
		var remaining: float = ceil(combat_timer.time_left)
		var m := int(remaining / 60.0)
		var s := int(remaining) % 60
		time_label.text = "%02d:%02d" % [m, s]
	else:
		time_label.text = "00:00"
