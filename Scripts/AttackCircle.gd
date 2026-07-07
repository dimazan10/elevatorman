extends Area2D

var circle_radius: float = 500.0
var circle_color: Color = Color(1, 0, 0, 0.25)
var is_blue: bool = false

var _hit_bodies: Array[Node2D] = []

const MOVE_THRESHOLD: float = 30.0
const CIRCLE_SEGMENTS: int = 64

static var _points_cache: Dictionary = {}

func _ready() -> void:
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = circle_radius
	$CollisionShape2D.shape = shape

	var visual := Line2D.new()
	visual.name = "Visual"
	visual.points = _get_cached_points(circle_radius)
	visual.width = 8.0
	visual.default_color = Color(circle_color.r, circle_color.g, circle_color.b, 1.0)
	add_child(visual)
	move_child(visual, 0)

	body_entered.connect(_on_body_entered)

	modulate.a = 0.0

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or not body.has_method("take_damage"):
		return
	if _hit_bodies.has(body):
		return
	_hit_bodies.append(body)
	if is_blue:
		var character: CharacterBody2D = body as CharacterBody2D
		if character and character.velocity.length() > MOVE_THRESHOLD:
			body.call("take_damage", 1)
	else:
		body.call("take_damage", 1)

func _exit_tree() -> void:
	_hit_bodies.clear()

static func _get_cached_points(radius: float) -> PackedVector2Array:
	var key: int = int(radius)
	if _points_cache.has(key):
		return _points_cache[key] as PackedVector2Array

	var points: PackedVector2Array = PackedVector2Array()
	points.resize(CIRCLE_SEGMENTS + 1)
	for i: int in range(CIRCLE_SEGMENTS):
		var angle: float = TAU * float(i) / float(CIRCLE_SEGMENTS)
		points[i] = Vector2(cos(angle), sin(angle)) * radius
	points[CIRCLE_SEGMENTS] = points[0]
	_points_cache[key] = points
	return points
