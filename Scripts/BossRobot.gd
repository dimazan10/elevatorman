extends Node2D

const HealthUI := preload("res://Objects/UI_HP.tscn")
const DashUI := preload("res://Objects/DashUI.tscn")
const InventoryUI := preload("res://Objects/InventoryUI.tscn")
const BossHPBar := preload("res://Scripts/BossHPBar.gd")

const DRUNK_KILLER := preload("res://Objects/Summons/DrunkKiller.tscn")
const SPIDER := preload("res://Objects/Summons/Spider.tscn")
const TELEPORT := preload("res://Objects/Summons/Teleport.tscn")

enum LiftState { NONE, START, EXITING, COMBAT, RETURNING }
var lift_state := LiftState.NONE

var _anim: AnimationPlayer
var _player_node: Node2D
var _spawn_zones: Array[Node2D] = []
var _spawn_active := false
var _spawn_timer := 6.0
var _enemies: Array[Node2D] = []
var _is_low_hp := false
var _player_at_computer := false
var _boss_active := false
var _floor_label: Label
var _quest_label: Label

func _ready() -> void:
	add_to_group("pausable")
	add_child(HealthUI.instantiate())
	add_child(DashUI.instantiate())
	add_child(InventoryUI.instantiate())

	var bar := BossHPBar.new()
	add_child(bar)
	var robot := get_node_or_null("Robot")
	if robot:
		robot.visible = false
		robot.set_can_attack(false)
		bar.setup(robot)
		robot.hp_changed.connect(_on_robot_hp_changed)
		robot.died.connect(_on_boss_died)

	var music := AudioStreamPlayer.new()
	music.name = "BossMusic"
	music.stream = load("res://Assets/Enemies/Boss/Sprite_Robot/Music.mp3")
	music.bus = &"Music"
	add_child(music)

	for name in ["SpawnZoneLeft", "SpawnZoneRight"]:
		var zone := get_node_or_null(name) as Node2D
		if zone:
			_spawn_zones.append(zone)

	var computer := get_node_or_null("Computer")
	if computer:
		computer.aiming_changed.connect(_on_computer_aiming_changed)

	_player_node = get_tree().get_first_node_in_group("player") as Node2D

	_reparent_collision_nodes()

	var hole_start := get_node_or_null("HoleStart/FloorElevator") as Sprite2D
	if hole_start:
		_anim = hole_start.get_node_or_null("AnimationPlayer") as AnimationPlayer

	_setup_floor_label()
	_setup_quest_ui()

	_arrival_sequence()

func _process(delta: float) -> void:
	if not _boss_active or not _spawn_active or _player_at_computer:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0:
		_spawn_timer = 6.0
		_spawn_enemies()

func _reparent_collision_nodes() -> void:
	var hole_start := get_node_or_null("HoleStart")
	if hole_start:
		var fe := hole_start.get_node_or_null("FloorElevator")
		if fe:
			for name in ["FloorCollision", "ElevatorArea", "ExitZone", "Top", "RightUpper", "LeftUpper"]:
				var child := fe.get_node_or_null(name)
				if child:
					child.reparent(hole_start)

	var hole_end := get_node_or_null("HoleEnd")
	if hole_end:
		var fe := hole_end.get_node_or_null("FloorElevator")
		if fe:
			for name in ["ElevatorArea", "TransportArea", "CutsceneTrigger", "Top", "RightUpper", "LeftUpper"]:
				var child := fe.get_node_or_null(name)
				if child:
					child.reparent(hole_end)

func _setup_floor_label() -> void:
	_floor_label = Label.new()
	_floor_label.name = "FloorLabel"
	_floor_label.text = "Floor 4"
	_floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_floor_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_floor_label.add_theme_font_size_override("font_size", 48)
	_floor_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	_floor_label.position = Vector2(640, 360) - _floor_label.size * 0.5
	_floor_label.set_anchors_preset(Control.PRESET_CENTER)
	_floor_label.modulate = Color(1, 1, 1, 0)
	_floor_label.hide()
	add_child(_floor_label)

func _setup_quest_ui() -> void:
	var ui := CanvasLayer.new()
	ui.name = "QuestUI"
	ui.layer = 128
	add_child(ui)
	_quest_label = Label.new()
	_quest_label.name = "QuestLabel"
	_quest_label.add_theme_font_size_override("font_size", 24)
	_quest_label.add_theme_color_override("font_color", Color.GOLD)
	_quest_label.add_theme_constant_override("outline_size", 3)
	_quest_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_quest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quest_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_quest_label.offset_top = 10
	_quest_label.offset_bottom = 50
	_quest_label.text = "Reach the other elevator"
	ui.add_child(_quest_label)

func _update_quest_text(text: String) -> void:
	if not _quest_label:
		return
	_quest_label.text = text
	var tw := create_tween()
	tw.tween_property(_quest_label, "modulate:a", 0.0, 0.15)
	tw.tween_property(_quest_label, "scale", Vector2(1.2, 1.2), 0.1)
	tw.tween_property(_quest_label, "modulate:a", 1.0, 0.15)
	tw.tween_property(_quest_label, "scale", Vector2(1.0, 1.0), 0.1)

func _arrival_sequence() -> void:
	lift_state = LiftState.START

	if _player_node:
		_hide_player()

	_hide_floor_label()

	var hole_start := get_node_or_null("HoleStart/FloorElevator") as Sprite2D
	if hole_start:
		hole_start.get_node("RoofElevator2").z_index = 3
		hole_start.get_node("Door1").visible = true
		hole_start.get_node("Door2").visible = true
		hole_start.self_modulate = Color(1, 1, 1, 1)

	if not _anim:
		return

	_show_floor_label()

	_anim.play("RESET")
	_anim.seek(0, true)
	_anim.stop()
	_anim.play("DownUp")
	await _anim.animation_finished
	_anim.play("Open")
	await _anim.animation_finished

	_hide_floor_label()

	if hole_start:
		hole_start.self_modulate = Color(1, 1, 1, 1)

	if _player_node:
		_show_player(_player_node)
		_player_node.can_move = true

	_restore_bucket_state()
	_restore_collar_state()
	_restore_inventory_state()

	_quest_label.modulate = Color(1, 1, 1, 0)
	_quest_label.scale = Vector2(0.8, 0.8)
	var tw := create_tween()
	tw.tween_property(_quest_label, "modulate:a", 1.0, 0.4)
	tw.tween_property(_quest_label, "scale", Vector2(1.0, 1.0), 0.3)

	var exit_zone := get_node_or_null("HoleStart/ExitZone") as Area2D
	if exit_zone:
		exit_zone.monitoring = true

func start_exit_sequence() -> void:
	if lift_state != LiftState.START:
		return
	lift_state = LiftState.EXITING

	if _player_node:
		_player_node.can_move = false

	if not _anim:
		return

	_anim.play("Close")
	await _anim.animation_finished
	_anim.play("DownClose")
	await _anim.animation_finished

	var hole_start := get_node_or_null("HoleStart/FloorElevator") as Sprite2D
	if hole_start:
		hole_start.get_node("RoofElevator2").z_index = 0
		hole_start.get_node("Door1").visible = false
		hole_start.get_node("Door2").visible = false
		hole_start.self_modulate = Color(1, 1, 1, 0)

		var hole_start_parent := hole_start.get_parent()
		if hole_start_parent:
			for child in hole_start_parent.get_children():
				if child is StaticBody2D or child is Area2D:
					child.set_process(false)
					child.set_physics_process(false)
					for shape in child.get_children():
						if shape is CollisionShape2D:
							shape.set_deferred("disabled", true)

	_update_quest_text("Defeat the boss")

	lift_state = LiftState.COMBAT

	if _player_node:
		_player_node.can_move = true

func is_boss_active() -> bool:
	return _boss_active

func activate_boss() -> void:
	_boss_active = true
	var robot := get_node_or_null("Robot")
	if robot and robot.has_method("set_can_attack"):
		robot.set_can_attack(true)

func _on_robot_hp_changed(current_hp: int, max_hp: int) -> void:
	if not _spawn_active:
		_spawn_active = true
		_spawn_timer = 6.0
	_is_low_hp = current_hp <= 1

func _on_boss_died() -> void:
	_spawn_active = false
	for e in _enemies:
		if is_instance_valid(e):
			e.queue_free()
	_enemies.clear()
	_update_quest_text("Enter the elevator")
	_open_exit()
	var music := get_node_or_null("BossMusic") as AudioStreamPlayer
	if not music:
		return
	var tw := create_tween()
	tw.tween_property(music, "volume_db", -80.0, 2.0)

func _open_exit() -> void:
	var hole_end := get_node_or_null("HoleEnd") as Sprite2D
	if not hole_end:
		return

	var elevator := hole_end.get_node_or_null("FloorElevator") as Sprite2D
	if elevator:
		elevator.self_modulate = Color(1, 1, 1, 1)
		var roof2 := elevator.get_node_or_null("RoofElevator2") as Sprite2D
		if roof2:
			roof2.z_index = 3
		var door1 := elevator.get_node_or_null("Door1") as Sprite2D
		if door1:
			door1.show()
		var door2 := elevator.get_node_or_null("Door2") as Sprite2D
		if door2:
			door2.show()

		var anim := elevator.get_node_or_null("AnimationPlayer") as AnimationPlayer
		if anim:
			anim.stop()
			anim.play("RESET")
			anim.seek(0, true)
			anim.stop()
			anim.play("Open")

	for name in ["ElevatorArea", "TransportArea", "Top", "RightUpper", "LeftUpper"]:
		var child := hole_end.get_node_or_null(name)
		if child is StaticBody2D or child is Area2D:
			child.set_process(true)
			child.set_physics_process(true)
			for shape in child.get_children():
				if shape is CollisionShape2D:
					shape.set_deferred("disabled", false)

	var transport := hole_end.get_node_or_null("TransportArea") as Area2D
	if transport:
		transport.monitoring = true


func _spawn_enemies() -> void:
	if _spawn_zones.is_empty():
		return
	var count := 5 if _is_low_hp else 3
	for i in range(count):
		var zone := _spawn_zones[randi() % _spawn_zones.size()]
		var shape := zone.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if not shape or not shape.shape is RectangleShape2D:
			continue
		var rect := (shape.shape as RectangleShape2D).get_rect()
		var zpos := zone.global_position
		var zscale := zone.global_scale
		var global_rect := Rect2(zpos + rect.position * zscale, rect.size * zscale)
		var pos := Vector2(
			randf_range(global_rect.position.x, global_rect.position.x + global_rect.size.x),
			randf_range(global_rect.position.y, global_rect.position.y + global_rect.size.y)
		)
		_spawn_teleport_effect(pos)
		var enemy := (DRUNK_KILLER if randi() % 2 == 0 else SPIDER).instantiate()
		enemy.set_meta("spawn_position", pos)
		enemy.global_position = pos
		add_child(enemy)
		_enemies.append(enemy)
		var tw := create_tween()
		tw.tween_interval(5.0)
		tw.tween_callback(func():
			_despawn_enemy(enemy)
		)

func _despawn_enemy(enemy: Node2D) -> void:
	if not is_instance_valid(enemy):
		return
	_spawn_teleport_effect(enemy.global_position)
	_enemies.erase(enemy)
	enemy.queue_free()

func _spawn_teleport_effect(pos: Vector2) -> void:
	var tp := TELEPORT.instantiate()
	tp.global_position = pos
	add_child(tp)
	var anim := tp.get_node("AnimatedSprite2D") as AnimatedSprite2D
	if anim:
		anim.play("default")
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(func():
		if is_instance_valid(tp):
			tp.queue_free()
	)

func _on_computer_aiming_changed(is_aiming: bool) -> void:
	_player_at_computer = is_aiming
	if is_aiming:
		for e in _enemies:
			if is_instance_valid(e):
				_spawn_teleport_effect(e.global_position)
				e.queue_free()
		_enemies.clear()
	else:
		_spawn_timer = 6.0

func _hide_floor_label() -> void:
	if not _floor_label:
		return
	var tw = create_tween()
	tw.tween_property(_floor_label, "modulate:a", 0.0, 0.5)

func _show_floor_label() -> void:
	if not _floor_label:
		return
	_floor_label.text = "Floor 4"
	_floor_label.modulate = Color(1, 1, 1, 0)
	_floor_label.show()
	var tw = create_tween()
	tw.tween_property(_floor_label, "modulate:a", 1.0, 0.5)

func _restore_bucket_state() -> void:
	if not GameState.has_bucket:
		return
	if not is_instance_valid(_player_node):
		return
	if _player_node.has_method("_setup_bucket"):
		_player_node._setup_bucket()
		if _player_node._bucket:
			_player_node._bucket.charges = GameState.bucket_charges

func _restore_collar_state() -> void:
	if not GameState.has_collar:
		return
	if not is_instance_valid(_player_node):
		return
	if _player_node.has_method("_setup_collar"):
		_player_node._setup_collar()
		if _player_node._collar:
			_player_node._collar.charges = GameState.collar_charges

func _restore_inventory_state() -> void:
	if not is_instance_valid(_player_node):
		return
	if not _player_node.has_method("set_slot"):
		return
	for i in range(GameState.inventory.size()):
		var slot = GameState.inventory[i]
		if slot.id != "":
			_player_node.set_slot(i, slot.id, slot.icon, slot.name)

func _hide_player() -> void:
	if not _player_node:
		return
	for child in _player_node.get_children():
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
	_player_node.set_process(false)
	_player_node.set_physics_process(false)

func _show_player(p: Node2D) -> void:
	for child in p.get_children():
		if child is Camera2D:
			continue
		if child is AnimatedSprite2D:
			child.show()
		if child is Sprite2D:
			child.show()
		if child is CollisionShape2D:
			child.set_deferred("disabled", false)
	p.set_process(true)
	p.set_physics_process(true)
