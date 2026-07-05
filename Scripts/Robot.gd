extends CharacterBody2D

enum State { IDLE, LEFT_ATTACK, RIGHT_ATTACK, BOTH_ATTACK }

var current_state := State.IDLE
var _circles_spawned := false
var _attack_cooldown := 0.0
var _audio: AudioStreamPlayer2D

const IMPACT_TIME := 1.3
const CIRCLE_RADIUS_RED := 800.0
const CIRCLE_RADIUS_BLUE := 780.0
const CIRCLE_LIFETIME := 2.5
const DAMAGE := 1
const MOVE_THRESHOLD := 30.0

const CIRCLE_SCENE := preload("res://Objects/Boss/Robot/AttackCircle.tscn")

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
	var left_marker = $LeftCircleMarker
	var right_marker = $RightCircleMarker
	if not left_marker or not right_marker:
		return

	match current_state:
		State.LEFT_ATTACK:
			_spawn_random_circle(left_marker.global_position)
		State.RIGHT_ATTACK:
			_spawn_random_circle(right_marker.global_position)
		State.BOTH_ATTACK:
			_spawn_random_circle(left_marker.global_position)
			_spawn_random_circle(right_marker.global_position)

func _spawn_random_circle(pos: Vector2) -> void:
	if randi() % 2 == 0:
		_spawn_circle(pos, CIRCLE_RADIUS_RED, Color(1, 0, 0, 0.25), false)
	else:
		_spawn_circle(pos, CIRCLE_RADIUS_BLUE, Color(0, 0, 1, 0.25), true)

func _spawn_circle(pos: Vector2, radius: float, color: Color, is_blue: bool) -> void:
	var area := CIRCLE_SCENE.instantiate()
	area.global_position = pos
	area.circle_radius = radius
	area.circle_color = color
	area.is_blue = is_blue

	get_parent().add_child(area)

	area.scale = Vector2.ZERO
	var tw := area.create_tween()
	tw.tween_property(area, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(area, "modulate:a", color.a, 0.4).from(0.0)

	await get_tree().create_timer(CIRCLE_LIFETIME - 0.5).timeout
	if not is_instance_valid(area):
		return

	area._active = false
	var fade := area.create_tween()
	fade.tween_property(area, "modulate:a", 0.0, 0.5)
	await fade.finished
	if is_instance_valid(area):
		area.queue_free()

func _on_animation_finished(anim_name: String) -> void:
	current_state = State.IDLE
	_attack_cooldown = 2.0 + randf() * 3.0
	$WaistBone/AnimationPlayer.play("Idle")
