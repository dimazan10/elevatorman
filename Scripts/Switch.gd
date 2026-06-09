extends CharacterBody2D

signal activated

var _activated := false
var _chasing := false

var _move_speed := 350.0
var _move_direction := Vector2.ZERO
var _change_dir_interval := 0.0
var _change_dir_timer := 0.0

func _ready() -> void:
	add_to_group("switch")
	call_deferred("_disable_player_collision")
	$Lag.hide()

func _disable_player_collision() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		add_collision_exception_with(player)

func _on_wake_up() -> void:
	_chasing = true
	$Lag.show()
	$Lag.play("default")
	_pick_random_direction()

func _pick_random_direction() -> void:
	_move_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	_change_dir_interval = randf_range(1.0, 3.0)
	_change_dir_timer = 0.0

func _physics_process(delta: float) -> void:
	if _activated:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dist := global_position.distance_to(player.global_position)

	if not _chasing and dist < 200.0:
		_on_wake_up()

	if not _chasing:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if dist < 20.0:
		_activate()
		return

	_change_dir_timer += delta
	if _change_dir_timer >= _change_dir_interval:
		_pick_random_direction()

	velocity = _move_direction * _move_speed
	move_and_slide()

	var hit_wall := false
	for i in range(get_slide_collision_count()):
		if get_slide_collision(i).get_collider() is StaticBody2D:
			hit_wall = true
	if hit_wall:
		_pick_random_direction()

func _activate() -> void:
	_activated = true
	_chasing = false
	velocity = Vector2.ZERO
	$"Switch".play("default")
	await $"Switch".animation_finished
	$Lag.hide()
	activated.emit()
