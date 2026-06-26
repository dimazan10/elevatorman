extends StaticBody2D

# --- НАСТРОЙКИ ТУРЕЛИ ---
@export var laser_range: float = 10000.0
@export var warning_duration: float = 1.0    # Время прицеливания (предупреждающий луч)
@export var laser_duration: float = 2.0      # Как долго держится сам выстрел
@export var cooldown: float = 2.0            # Пауза между атаками
@export var damage_per_second: float = 50.0  # Урон в секунду

# Состояния турели
enum TurretState { TRACKING, WARNING, FIRING }
var current_state: TurretState = TurretState.TRACKING

var muzzle: Marker2D
var raycast: RayCast2D
var line: Line2D
var cooldown_timer: Timer
var player: Node2D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	
	
	var pivot_node = get_node_or_null("Node2D")
	if not pivot_node:
		push_error("Узел 'Node2D' не найден!")
		return

	
	muzzle = Marker2D.new()
	muzzle.position = Vector2(35,1.5)
	pivot_node.add_child(muzzle)
	
	
	raycast = RayCast2D.new()
	raycast.target_position = Vector2(laser_range, 0)
	raycast.enabled = false
	muzzle.add_child(raycast)
	
	
	line = Line2D.new()
	line.visible = false
	line.add_point(Vector2.ZERO)
	line.add_point(Vector2.ZERO)
	muzzle.add_child(line)
	
	
	cooldown_timer = Timer.new()
	cooldown_timer.wait_time = cooldown
	cooldown_timer.autostart = true
	cooldown_timer.timeout.connect(_on_cooldown_timeout)
	add_child(cooldown_timer)

func _process(delta: float) -> void:
	
	var pivot_node = get_node_or_null("Node2D")
	
	match current_state:
		TurretState.TRACKING:
			
			if pivot_node and is_instance_valid(player):
				pivot_node.look_at(player.global_position)
				
		TurretState.WARNING, TurretState.FIRING:
			
			raycast.force_raycast_update()
			var cast_point = raycast.target_position
			
			if raycast.is_colliding():
				cast_point = muzzle.to_local(raycast.get_collision_point())
				
				
				if current_state == TurretState.FIRING:
					var collider = raycast.get_collider()
					if collider == player and collider.has_method("take_damage"):
						collider.take_damage(damage_per_second * delta)
			
			
			line.set_point_position(1, cast_point)

func _has_line_of_sight() -> bool:
	var space_state = get_world_2d().direct_space_state
	var from = muzzle.global_position if muzzle else global_position
	var query = PhysicsRayQueryParameters2D.create(
		from,
		player.global_position,
		0b11111111,
		[self.get_rid()]
	)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	if result.is_empty():
		return false
	return result.collider == player

func _on_cooldown_timeout() -> void:
	if is_instance_valid(player) and current_state == TurretState.TRACKING:
		if _has_line_of_sight():
			start_attack_sequence()

func start_attack_sequence() -> void:
	cooldown_timer.stop()
	
	# -
	current_state = TurretState.WARNING
	raycast.enabled = true
	line.visible = true
	
	line.width = 2.0
	line.default_color = Color(1.0, 0.2, 0.2, 0.4) 
	
	await get_tree().create_timer(warning_duration).timeout
	
	# -
	current_state = TurretState.FIRING
	
	line.width = 6.0
	line.default_color = Color(1.0, 0.0, 0.0, 1.0) 
	
	await get_tree().create_timer(laser_duration).timeout
	
	# -
	current_state = TurretState.TRACKING
	line.visible = false
	raycast.enabled = false
	line.set_point_position(1, Vector2.ZERO)
	
	cooldown_timer.start()
