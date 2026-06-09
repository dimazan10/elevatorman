extends CharacterBody2D

const WEB_SCENE = preload("res://Objects/Web.tscn")

@export var speed: float = 150.0
@export var web_boost_multiplier: float = 2.5
@export var separation_force: float = 80.0
@export var shoot_interval: float = 4.0
@export var melee_damage: int = 1
@export var health: int = 80

var player: Node2D = null
var _web_boost := false

@onready var animated_sprite := $AnimatedSprite2D
@onready var shoot_timer := $ShootTimer
@onready var melee_zone := $MeleeZone
@onready var separation_zone := $SeparationZone

func _ready() -> void:
	add_to_group("enemy")
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	shoot_timer.wait_time = shoot_interval
	shoot_timer.one_shot = false
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	shoot_timer.start()

	melee_zone.body_entered.connect(_on_melee_zone_body_entered)

	if animated_sprite and animated_sprite.sprite_frames.has_animation("walk"):
		animated_sprite.play("walk")

func set_web_boost(enabled: bool) -> void:
	_web_boost = enabled

func _get_separation_vector() -> Vector2:
	var sep := Vector2.ZERO
	for body in separation_zone.get_overlapping_bodies():
		if body == self or body == player:
			continue
		if body is CharacterBody2D or body.is_in_group("enemy"):
			var diff = global_position - body.global_position
			if diff.length() > 0:
				sep += diff.normalized() / diff.length()
	if sep.length() > 0:
		sep = sep.normalized()
	return sep

func _physics_process(_delta: float) -> void:
	if not player:
		return

	var to_player = player.global_position - global_position
	var direction = to_player.normalized()
	var current_speed = speed * (web_boost_multiplier if _web_boost else 1.0)

	var separation = _get_separation_vector()
	velocity = direction * current_speed + separation * separation_force
	move_and_slide()

	if direction.x > 0:
		animated_sprite.flip_h = false
	else:
		animated_sprite.flip_h = true

func _on_shoot_timer_timeout() -> void:
	if not player:
		return

	var web = WEB_SCENE.instantiate()
	web.global_position = global_position
	web.z_index = 1
	get_parent().add_child(web)

func _get_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var min_dist := INF
	for e in get_tree().get_nodes_in_group("enemy"):
		if e == self:
			continue
		var d = global_position.distance_squared_to(e.global_position)
		if d < min_dist:
			min_dist = d
			nearest = e
	return nearest

func _on_melee_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var target = _get_nearest_enemy()
		if target and body.has_method("apply_pull_toward"):
			body.apply_pull_toward(target, 1.0, Vector2(0, -40))
		if body.has_method("take_damage"):
			body.take_damage(melee_damage)

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()
