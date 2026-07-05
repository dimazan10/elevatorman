extends CharacterBody2D

enum State { IDLE, LEFT_ATTACK, RIGHT_ATTACK, BOTH_ATTACK }

var current_state := State.IDLE
var _circles_spawned := false
var _attack_cooldown := 0.0
var _audio: AudioStreamPlayer2D

const IMPACT_TIME := 1.3
const CIRCLE_RADIUS_RED := 50.0
const CIRCLE_RADIUS_BLUE := 40.0
const CIRCLE_LIFETIME := 2.5
const DAMAGE := 1
const MOVE_THRESHOLD := 30.0

const CIRCLE_DRAW := preload("res://Scripts/CircleDraw.gd")

func _ready() -> void:
	add_to_group("enemy")
	$WaistBone/AnimationPlayer.play("Idle")
	$WaistBone/AnimationPlayer.animation_finished.connect(_on_animation_finished)

	_audio = AudioStreamPlayer2D.new()
	_audio.name = "AttackAudio"
	_audio.stream = load("res://Assets/Boss/RobotBoss/Sprite_Robot/Attack.mp3")
	_audio.bus = &"Effects"
	add_child(_audio)

func _process(delta: float) -> void:
	if current_state != State.IDLE and not _circles_spawned:
		if $WaistBone/AnimationPlayer.current_animation_position >= IMPACT_TIME:
			_spawn_attack_circles()
			_circles_spawned = true

	if current_state == State.IDLE:
		_attack_cooldown -= delta
		if _attack_cooldown <= 0:
			_do_random_attack()

func _do_random_attack() -> void:
	var attacks := [State.LEFT_ATTACK, State.RIGHT_ATTACK, State.BOTH_ATTACK]
	_start_attack(attacks[randi() % attacks.size()])

func _start_attack(attack: State) -> void:
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

func _spawn_attack_circles() -> void:
	var left_hand = $WaistBone/TorsoBone/LeftHandBone.global_position
	var right_hand = $WaistBone/TorsoBone/RightHandBone.global_position

	match current_state:
		State.LEFT_ATTACK:
			_spawn_random_circle(left_hand)
		State.RIGHT_ATTACK:
			_spawn_random_circle(right_hand)
		State.BOTH_ATTACK:
			_spawn_random_circle(left_hand)
			_spawn_random_circle(right_hand)

func _spawn_random_circle(pos: Vector2) -> void:
	if randi() % 2 == 0:
		_spawn_red_circle(pos)
	else:
		_spawn_blue_circle(pos)

func _spawn_red_circle(pos: Vector2) -> void:
	var area := Area2D.new()
	area.global_position = pos

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = CIRCLE_RADIUS_RED
	shape.shape = circle
	area.add_child(shape)

	var visual := Node2D.new()
	visual.set_script(CIRCLE_DRAW)
	visual.radius = CIRCLE_RADIUS_RED
	visual.color = Color(1, 0, 0, 0.25)
	area.add_child(visual)

	area.body_entered.connect(_on_red_circle_entered)
	area.scale = Vector2.ZERO
	var tw := area.create_tween()
	tw.tween_property(area, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT)

	get_parent().add_child(area)

	await get_tree().create_timer(CIRCLE_LIFETIME).timeout
	if is_instance_valid(area):
		area.queue_free()

func _spawn_blue_circle(pos: Vector2) -> void:
	var area := Area2D.new()
	area.global_position = pos

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = CIRCLE_RADIUS_BLUE
	shape.shape = circle
	area.add_child(shape)

	var visual := Node2D.new()
	visual.set_script(CIRCLE_DRAW)
	visual.radius = CIRCLE_RADIUS_BLUE
	visual.color = Color(0, 0, 1, 0.25)
	area.add_child(visual)

	area.body_entered.connect(_on_blue_circle_entered)
	area.scale = Vector2.ZERO
	var tw := area.create_tween()
	tw.tween_property(area, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT)

	get_parent().add_child(area)

	await get_tree().create_timer(CIRCLE_LIFETIME).timeout
	if is_instance_valid(area):
		area.queue_free()

func _on_red_circle_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(DAMAGE)

func _on_blue_circle_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		if body.velocity.length() > MOVE_THRESHOLD:
			body.take_damage(DAMAGE)

func _on_animation_finished(anim_name: String) -> void:
	current_state = State.IDLE
	_attack_cooldown = 2.0 + randf() * 3.0
	$WaistBone/AnimationPlayer.play("Idle")
