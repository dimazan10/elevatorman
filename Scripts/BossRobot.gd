extends Node2D

const HealthUI := preload("res://Objects/UI_HP.tscn")
const DashUI := preload("res://Objects/DashUI.tscn")
const InventoryUI := preload("res://Objects/InventoryUI.tscn")
const BossHPBar := preload("res://Scripts/BossHPBar.gd")

const DRUNK_KILLER := preload("res://Objects/Summons/DrunkKiller.tscn")
const SPIDER := preload("res://Objects/Summons/Spider.tscn")
const TELEPORT := preload("res://Objects/Summons/Teleport.tscn")

var _spawn_zones: Array[Node2D] = []
var _spawn_active := false
var _spawn_timer := 6.0
var _enemies: Array[Node2D] = []
var _is_low_hp := false
var _player_at_computer := false

func _ready() -> void:
	add_to_group("pausable")
	add_child(HealthUI.instantiate())
	add_child(DashUI.instantiate())
	add_child(InventoryUI.instantiate())

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
