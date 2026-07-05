extends Area2D

var circle_radius: float = 500.0
var circle_color: Color = Color(1, 0, 0, 0.25)
var is_blue: bool = false

var _active: bool = false
var _damage_timer: float = 0.0
var _bodies_inside: Array[Node2D] = []

const DAMAGE_INTERVAL: float = 0.5
const MOVE_THRESHOLD: float = 30.0
const CIRCLE_SEGMENTS: int = 96

static var _polygon_cache: Dictionary = {}

func _ready() -> void:
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = circle_radius
	$CollisionShape2D.shape = shape

	var visual: Polygon2D = Polygon2D.new()
	visual.name = "Visual"
	visual.polygon = _get_cached_polygon(circle_radius)
	visual.color = Color(circle_color.r, circle_color.g, circle_color.b, 1.0)
	add_child(visual)
	move_child(visual, 0)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	modulate = Color(1, 1, 1, 0.0)

	await get_tree().create_timer(0.35).timeout
	if is_instance_valid(self):
		_active = true

func _process(delta: float) -> void:
	if not _active:
		return

	_damage_timer -= delta
	if _damage_timer > 0:
		return

	for body: Node2D in _bodies_inside:
		if not is_instance_valid(body):
			continue
		if body.is_in_group("player") and body.has_method("take_damage"):
			if is_blue:
				var character: CharacterBody2D = body as CharacterBody2D
				if character and character.velocity.length() > MOVE_THRESHOLD:
					body.call("take_damage", 1)
					_damage_timer = DAMAGE_INTERVAL
			else:
				body.call("take_damage", 1)
				_damage_timer = DAMAGE_INTERVAL

func _exit_tree() -> void:
	_active = false
	_bodies_inside.clear()

func _on_body_entered(body: Node2D) -> void:
	if not _bodies_inside.has(body):
		_bodies_inside.append(body)

func _on_body_exited(body: Node2D) -> void:
	_bodies_inside.erase(body)

static func _get_cached_polygon(radius: float) -> PackedVector2Array:
	var key: int = int(radius)
	if _polygon_cache.has(key):
		return _polygon_cache[key] as PackedVector2Array

	var points: PackedVector2Array = PackedVector2Array()
	points.resize(CIRCLE_SEGMENTS)
	for i: int in range(CIRCLE_SEGMENTS):
		var angle: float = TAU * float(i) / float(CIRCLE_SEGMENTS)
		points[i] = Vector2(cos(angle), sin(angle)) * radius
	_polygon_cache[key] = points
	return points
