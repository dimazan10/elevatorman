extends HBoxContainer

const MAX_HEARTS = 5

var pulse_tween: Tween
var _heart_tex: Texture2D = preload("res://Assets/UI/heart.png")
var _overflow_label: Label

func _ready() -> void:
	await get_tree().process_frame
	for heart in get_children():
		heart.pivot_offset = Vector2(32, 32)
	_overflow_label = Label.new()
	_overflow_label.add_theme_font_size_override("font_size", 28)
	_overflow_label.add_theme_color_override("font_color", Color.WHITE)
	_overflow_label.visible = false
	add_child(_overflow_label)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(update_hearts)

func update_hearts(current_health: int):
	var hearts = []
	for c in get_children():
		if c is TextureRect:
			hearts.append(c)

	var heart_count = mini(current_health, MAX_HEARTS)

	while hearts.size() > heart_count:
		var last = hearts.pop_back()
		last.queue_free()

	var template = _heart_tex
	while hearts.size() < heart_count:
		var new_heart = TextureRect.new()
		new_heart.texture = template
		new_heart.custom_minimum_size = Vector2(64, 64)
		new_heart.expand_mode = 1
		new_heart.stretch_mode = 5
		new_heart.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		new_heart.pivot_offset = Vector2(32, 32)
		add_child(new_heart)
		hearts.append(new_heart)

	move_child(_overflow_label, get_child_count() - 1)

	if current_health > MAX_HEARTS:
		_overflow_label.text = str(current_health)
		_overflow_label.visible = true
	else:
		_overflow_label.visible = false

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
