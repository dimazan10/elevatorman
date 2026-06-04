extends HBoxContainer

var pulse_tween: Tween

func _ready() -> void:
	await get_tree().process_frame
	for heart in get_children():
		heart.pivot_offset = Vector2(32, 32)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(update_hearts)

func update_hearts(current_health: int):
	var hearts = get_children()
	var hearts_to_remove = clampi(hearts.size() - current_health, 0, hearts.size())

	for i in range(hearts_to_remove):
		var last_heart = hearts[hearts.size() - 1 - i]
		last_heart.queue_free()

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
