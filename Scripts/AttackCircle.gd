extends Area2D

var circle_radius := 500.0
var circle_color := Color(1, 0, 0, 0.25)
var is_blue := false

var _active := false
var _damage_timer := 0.0

const DAMAGE_INTERVAL := 0.5
const MOVE_THRESHOLD := 30.0

static var _texture_cache: Dictionary = {}

func _ready() -> void:
	$CollisionShape2D.shape.radius = circle_radius

	var tex := _get_cached_texture(circle_radius)
	var sprite := Sprite2D.new()
	sprite.name = "Visual"
	sprite.texture = tex
	sprite.modulate = Color(circle_color.r, circle_color.g, circle_color.b, 1.0)
	add_child(sprite)
	move_child(sprite, 0)

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

	for body in get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			if is_blue:
				if body.velocity.length() > MOVE_THRESHOLD:
					body.take_damage(1)
					_damage_timer = DAMAGE_INTERVAL
			else:
				body.take_damage(1)
				_damage_timer = DAMAGE_INTERVAL

func _exit_tree() -> void:
	_active = false

static func _get_cached_texture(radius: float) -> Texture2D:
	var key := int(radius)
	if _texture_cache.has(key):
		return _texture_cache[key]

	var tex := _create_circle_texture(radius)
	_texture_cache[key] = tex
	return tex

static func _create_circle_texture(radius: float) -> Texture2D:
	var size := int(ceil(radius * 2))
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(radius, radius)
	var radius_sq := radius * radius
	for x in size:
		for y in size:
			var dx := x - center.x
			var dy := y - center.y
			var dist_sq := dx * dx + dy * dy
			if dist_sq <= radius_sq:
				var alpha := 1.0
				if dist_sq > (radius - 2.0) * (radius - 2.0):
					alpha = 1.0 - (sqrt(dist_sq) - (radius - 2.0)) / 2.0
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(image)
