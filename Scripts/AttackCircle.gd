extends Area2D

var circle_radius := 500.0
var circle_color := Color(1, 0, 0, 0.25)
var is_blue := false

func _ready() -> void:
	$CollisionShape2D.shape.radius = circle_radius

	var tex := _create_circle_texture(circle_radius)
	var sprite := Sprite2D.new()
	sprite.name = "Visual"
	sprite.texture = tex
	sprite.modulate = Color(circle_color.r, circle_color.g, circle_color.b, 1.0)
	add_child(sprite)
	move_child(sprite, 0)

	modulate = Color(1, 1, 1, 0.0)

func _create_circle_texture(radius: float) -> Texture2D:
	var size := int(ceil(radius * 2))
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(radius, radius)
	for x in size:
		for y in size:
			var dist := Vector2(x, y).distance_to(center)
			if dist <= radius:
				var alpha := 1.0
				if dist > radius - 2.0:
					alpha = 1.0 - (dist - (radius - 2.0)) / 2.0
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(image)
