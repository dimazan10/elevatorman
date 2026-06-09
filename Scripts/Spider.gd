extends CharacterBody2D

const WEB_SCENE = preload("res://Objects/Web.tscn")

@export var speed: float = 150.0
@export var shoot_interval: float = 4.0
@export var melee_damage: int = 1
@export var health: int = 80

var player: Node2D = null

@onready var animated_sprite := $AnimatedSprite2D
@onready var shoot_timer := $ShootTimer
@onready var melee_zone := $MeleeZone

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

func _physics_process(_delta: float) -> void:
	if not player:
		return

	var to_player = player.global_position - global_position
	var direction = to_player.normalized()

	velocity = direction * speed
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

func _on_melee_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("apply_pull_toward"):
			body.apply_pull_toward(self, 1.0, Vector2(0, -40))
		if body.has_method("take_damage"):
			body.take_damage(melee_damage)

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()
