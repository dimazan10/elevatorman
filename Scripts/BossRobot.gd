extends Node2D

const HealthUI := preload("res://Objects/UI_HP.tscn")
const DashUI := preload("res://Objects/DashUI.tscn")
const InventoryUI := preload("res://Objects/InventoryUI.tscn")
const BossHPBar := preload("res://Scripts/BossHPBar.gd")

const DRUNK_KILLER := preload("res://Objects/Summons/DrunkKiller.tscn")
const SPIDER := preload("res://Objects/Summons/Spider.tscn")
const TELEPORT := preload("res://Objects/Summons/Teleport.tscn")
const ElevatorDoorScript := preload("res://Scripts/ElevatorDoor.gd")

var _spawn_zones: Array[Node2D] = []
var _spawn_active := false
var _spawn_timer := 6.0
var _enemies: Array[Node2D] = []
var _is_low_hp := false
var _player_at_computer := false

func _ready() -> void:
	print("[BossRobot] _ready called! Scene loaded successfully.")
	add_to_group("pausable")
	add_child(HealthUI.instantiate())
	add_child(DashUI.instantiate())
	add_child(InventoryUI.instantiate())

	if GameState.dark_mode:
		var cm := CanvasModulate.new()
		cm.name = "DarkOverlay"
		cm.color = Color(0.0, 0.0, 0.0)
		cm.z_index = -10
		add_child(cm)
		for light in get_tree().get_nodes_in_group(""):
			pass
		var area := get_node_or_null("Area")
		if area:
			for child in area.get_children():
				if child is PointLight2D:
					child.queue_free()

	var bar := BossHPBar.new()
	add_child(bar)
	var robot := get_node_or_null("Robot")
	if robot:
		bar.setup(robot)
		robot.hp_changed.connect(_on_robot_hp_changed)
		robot.died.connect(_on_boss_died)

	var music := AudioStreamPlayer.new()
	music.name = "BossMusic"
	music.stream = load("res://Assets/Enemies/Boss/Sprite_Robot/Music.mp3")
	music.bus = &"Music"
	add_child(music)
	music.play()

	for name in ["SpawnZoneLeft", "SpawnZoneRight"]:
		var zone := get_node_or_null(name) as Node2D
		if zone:
			_spawn_zones.append(zone)

	var computer := get_node_or_null("Computer")
	if computer:
		computer.aiming_changed.connect(_on_computer_aiming_changed)

	_setup_boss_elevator()

func _setup_boss_elevator() -> void:
	var player := get_node_or_null("Player") as Node2D
	if not player:
		return

	var gun := get_node_or_null("Gun") as Node2D
	var gun_pos := Vector2(466, 1488) if not gun else gun.global_position
	var elevator_x := gun_pos.x
	var elevator_start_y := gun_pos.y + 80.0
	var elevator_end_y := 1246.0

	var elevator := Node2D.new()
	elevator.name = "BossElevator"
	elevator.position = Vector2(elevator_x, elevator_start_y)
	add_child(elevator)

	var platform := Sprite2D.new()
	platform.name = "Platform"
	platform.texture = load("res://Assets/SpritesElevator/Lift.png")
	platform.scale = Vector2(0.32, 0.57)
	platform.z_index = 2
	elevator.add_child(platform)

	var door1 := Sprite2D.new()
	door1.name = "Door1"
	door1.texture = load("res://Assets/SpritesElevator/Lift2.png")
	door1.position = Vector2(0, -5)
	door1.z_index = 3
	elevator.add_child(door1)

	var door2 := Sprite2D.new()
	door2.name = "Door2"
	door2.texture = load("res://Assets/SpritesElevator/Lift.png")
	door2.position = Vector2(0, -5)
	door2.z_index = 3
	elevator.add_child(door2)

	var roof := Sprite2D.new()
	roof.name = "Roof"
	roof.texture = load("res://Assets/SpritesElevator/roof3.png")
	roof.position = Vector2(0, -12)
	roof.z_index = 3
	elevator.add_child(roof)

	var shaft_visual := Sprite2D.new()
	shaft_visual.name = "ShaftVisual"
	shaft_visual.texture = load("res://Assets/SpritesElevator/Hole.png")
	shaft_visual.position = Vector2(0, 0)
	shaft_visual.scale = Vector2(0.5, 1.0)
	shaft_visual.z_index = -1
	shaft_visual.modulate = Color(0.15, 0.15, 0.2)
	elevator.add_child(shaft_visual)

	player.global_position = Vector2(elevator_x, elevator_start_y)
	player.z_index = 4
	_hide_player_visual(player)

	var tw := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_interval(1.0)
	tw.tween_property(elevator, "position:y", elevator_end_y, 3.0)
	tw.tween_callback(func():
		_show_player_visual(player)
		player.z_index = 1
		var door_tw := create_tween().set_parallel(true)
		door_tw.tween_property(door1, "position:x", 72.0, 0.4)
		door_tw.tween_property(door2, "position:x", -72.0, 0.4)
		door_tw.tween_callback(func():
			elevator.queue_free()
		).set_delay(0.5)
	)

func _hide_player_visual(p: Node2D) -> void:
	for child in p.get_children():
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
	p.set_process(false)
	p.set_physics_process(false)

func _show_player_visual(p: Node2D) -> void:
	p.set_process(true)
	p.set_physics_process(true)
	for child in p.get_children():
		if child is Camera2D:
			continue
		if child is AnimatedSprite2D:
			child.show()
		if child is Sprite2D:
			child.show()
		if child is CollisionShape2D:
			child.set_deferred("disabled", false)

func _process(delta: float) -> void:
	if not _spawn_active or _player_at_computer:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0:
		_spawn_timer = 6.0
		_spawn_enemies()

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

func _on_robot_hp_changed(current_hp: int, max_hp: int) -> void:
	if not _spawn_active:
		_spawn_active = true
		_spawn_timer = 6.0
	_is_low_hp = current_hp <= 1

func _on_boss_died() -> void:
	print("[BossRobot] Boss died!")
	_spawn_active = false
	for e in _enemies:
		if is_instance_valid(e):
			e.queue_free()
	_enemies.clear()
	var music := get_node_or_null("BossMusic") as AudioStreamPlayer
	if not music:
		return
	var tw := create_tween()
	tw.tween_property(music, "volume_db", -80.0, 2.0)
