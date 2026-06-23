extends HBoxContainer

var pulse_tween: Tween
var _heart_tex: Texture2D = preload("res://Assets/heart.png")

func _ready() -> void:
	await get_tree().process_frame
	for heart in get_children():
		heart.pivot_offset = Vector2(32, 32)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(update_hearts)

func update_hearts(current_health: int):
	var hearts = get_children()
	var diff = hearts.size() - current_health

	if diff > 0:
		var hearts_to_remove = clampi(diff, 0, hearts.size())
		for i in range(hearts_to_remove):
			var last_heart = hearts[hearts.size() - 1 - i]
			last_heart.queue_free()
	elif diff < 0:
		var template = hearts[0] if hearts.size() > 0 else null
		for i in range(-diff):
			var new_heart: TextureRect
			if template:
				new_heart = template.duplicate()
			else:
				new_heart = TextureRect.new()
				new_heart.texture = _heart_tex
				new_heart.custom_minimum_size = Vector2(64, 64)
				new_heart.stretch_mode = 5
				new_heart.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			new_heart.pivot_offset = Vector2(32, 32)
			add_child(new_heart)

	if current_health == 1:
		start_last_heart_effect()
	else:
		stop_last_heart_effect()

func start_last_heart_effect():
	var hearts = get_children()
	if hearts.is_empty():
		return
	var last_heart = hearts[0]

	if pulse_tween:
		pulse_tween.kill()

	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(last_heart, "scale", Vector2(1.15, 1.15), 0.15)
	pulse_tween.parallel().tween_property(last_heart, "self_modulate", Color(2, 2, 2, 1), 0.1)
	pulse_tween.tween_property(last_heart, "scale", Vector2(1.0, 1.0), 0.35)
	pulse_tween.parallel().tween_property(last_heart, "self_modulate", Color(1, 1, 1, 1), 0.4)
	pulse_tween.tween_interval(0.3)

func stop_last_heart_effect():
	if pulse_tween:
		pulse_tween.kill()
		pulse_tween = null
	var hearts = get_children()
	if hearts.is_empty():
		return
	hearts[0].scale = Vector2(1, 1)
	hearts[0].self_modulate = Color(1, 1, 1, 1)
