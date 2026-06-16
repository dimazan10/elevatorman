extends CharacterBody2D

const BULLET_SCENE = preload("res://Objects/Bullet.tscn")

@export var speed: float = 150.0
@export var orbit_distance: float = 250.0 
@export var melee_range: float = 60.0    
@export var shoot_spread_degrees: float = 15.0 
@export var health: int = 100

# Настройки расталкивания врагов между собой
@export var separation_force: float = 80.0 # Сила расталкивания (чем выше, тем жестче держат дистанцию)

# Ссылки на узлы
@onready var enemy_sprite := $AnimatedSprite2D
@onready var weapon_anchor := $WeaponAnchor
@onready var weapon_sprite := $WeaponAnchor/WeaponSprite
@onready var muzzle := $WeaponAnchor/Muzzle

@onready var burst_timer := $BurstTimer
@onready var shot_delay_timer := $ShotDelayTimer
@onready var melee_zone := $MeleeZone
@onready var separation_zone := $SeparationZone # Наша новая зона личного пространства

var player: Node2D = null

enum States { MOVING, SHOOTING }
var current_state = States.MOVING
var bullets_in_burst: int = 0

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	
	burst_timer.one_shot = true
	burst_timer.timeout.connect(_on_burst_timer_timeout)
	set_random_burst_pause()
	
	shot_delay_timer.wait_time = 0.15
	shot_delay_timer.timeout.connect(_on_shot_delay_timer_timeout)
	
	melee_zone.body_entered.connect(_on_melee_zone_body_entered)
	
	if enemy_sprite and enemy_sprite.sprite_frames.has_animation("walk"):
		enemy_sprite.play("walk")

func _physics_process(_delta: float) -> void:
	if not player:
		return
		
	# 1. ПЛАВНОЕ ВРАЩЕНИЕ ОРУЖИЯ ЗА ИГРОКОМ
	weapon_anchor.look_at(player.global_position)
	
	# 2. МЕХАНИКА ОТЗЕРКАЛИВАНИЯ
	if player.global_position.x < global_position.x:
		enemy_sprite.flip_h = true 
		weapon_anchor.scale.y = -1 
	else:
		enemy_sprite.flip_h = false
		weapon_anchor.scale.y = 1

	# 3. ОБРАБОТКА СОСТОЯНИЙ И УПРАВЛЕНИЕ АНИМАЦИЕЙ
	match current_state:
		States.MOVING:
			move_around_player()
			if not enemy_sprite.is_playing():
				enemy_sprite.play("walk")
		States.SHOOTING:
			# Даже когда враг стоит и стреляет, мы позволяем ему немного расталкиваться,
			# чтобы они не перекрывали друг другу обзор во время стрельбы
			velocity = calculate_separation_vector() * (separation_force * 0.5)
			move_and_slide()
			enemy_sprite.stop()
			enemy_sprite.frame = 0

func move_around_player() -> void:
	var to_player = player.global_position - global_position
	var distance = to_player.length()
	var direction_to_player = to_player.normalized()
	
	var clockwise_tangent = Vector2(-direction_to_player.y, direction_to_player.x)
	var desired_velocity = Vector2.ZERO
	
	# Твоя базовая логика орбиты вокруг игрока
	if distance > orbit_distance + 20:
		desired_velocity = (clockwise_tangent + direction_to_player).normalized()
	elif distance < orbit_distance - 20:
		desired_velocity = (clockwise_tangent - direction_to_player).normalized()
	else:
		desired_velocity = clockwise_tangent
		
	# Считаем вектор движения по орбите
	var movement_vector = desired_velocity * speed
	
	# ДОБАВЛЯЕМ СИЛУ РАСТАЛКИВАНИЯ ОТ ДРУГИХ ВРАГОВ
	var separation_vector = calculate_separation_vector()
	
	# Финальная скорость — это смесь орбиты и расталкивания
	velocity = movement_vector + (separation_vector * separation_force)
	move_and_slide()

func calculate_separation_vector() -> Vector2:
	var separation = Vector2.ZERO
	var overlapping_bodies = separation_zone.get_overlapping_bodies()
	
	for body in overlapping_bodies:
		# Нас интересуют только другие враги DrunkKiller (но не мы сами и не игрок)
		if body != self and body.is_in_group("enemy") or body is CharacterBody2D and body != player and body != self:
			var diff = global_position - body.global_position
			# Чем ближе к нам чужой враг, тем сильнее мы от него толкаемся
			if diff.length() > 0:
				separation += diff.normalized() / diff.length()
				
	return separation.normalized()

func set_random_burst_pause() -> void:
	burst_timer.wait_time = randf_range(1.0, 2.0)
	burst_timer.start()

func _on_burst_timer_timeout() -> void:
	if current_state == States.MOVING:
		current_state = States.SHOOTING
		bullets_in_burst = randi_range(3, 4)
		fire_single_shot()

func fire_single_shot() -> void:
	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = muzzle.global_position
	
	var base_direction = Vector2.RIGHT.rotated(weapon_anchor.global_rotation)
	
	var random_offset = randf_range(-shoot_spread_degrees, shoot_spread_degrees)
	var spread_radians = deg_to_rad(random_offset)
	var final_direction = base_direction.rotated(spread_radians)
	
	bullet.direction = final_direction
	get_tree().current_scene.add_child(bullet)
	
	bullets_in_burst -= 1
	
	if bullets_in_burst > 0:
		shot_delay_timer.start()
	else:
		current_state = States.MOVING
		set_random_burst_pause()

func _on_shot_delay_timer_timeout() -> void:
	fire_single_shot()

func _on_melee_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("apply_stun_and_knockback"):
			var knockback_dir = (body.global_position - global_position).normalized()
			var knockback_force = 500.0
			var stun_duration = 1.0
			body.apply_stun_and_knockback(knockback_dir * knockback_force, stun_duration)
		
		if body.has_method("take_damage"):
			body.take_damage(1)
			
		if current_state == States.MOVING:
			burst_timer.stop() 
			set_random_burst_pause() 

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()
