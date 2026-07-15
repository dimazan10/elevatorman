extends CanvasLayer

var _black: ColorRect
var _label: Label

func _ready() -> void:
	layer = 128
	process_mode = PROCESS_MODE_ALWAYS

	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.anchors_preset = Control.PRESET_FULL_RECT
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black.modulate = Color(1, 1, 1, 0)
	add_child(_black)

	_label = Label.new()
	_label.text = "свет погас"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.anchors_preset = Control.PRESET_CENTER
	_label.modulate = Color(1, 0, 0, 0)
	_label.add_theme_font_size_override("font_size", 64)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)

	_run()

func _run() -> void:
	create_tween().tween_property(_black, "modulate:a", 0.6, 1.5).set_delay(0.5)

	await get_tree().create_timer(1.0).timeout

	create_tween().tween_property(_label, "modulate:a", 1.0, 0.3)
	var orig_x := _label.offset.x
	for i in range(6):
		_label.offset.x = orig_x + (6 if i % 2 == 0 else -6)
		await get_tree().create_timer(0.03).timeout
	_label.offset.x = orig_x

	await get_tree().create_timer(0.32).timeout

	create_tween().set_parallel() \
		.tween_property(_label, "modulate:a", 0.0, 0.5) \
		.tween_property(_black, "modulate:a", 1.0, 0.5)

	await get_tree().create_timer(1.0).timeout

	get_tree().reload_current_scene()

	await get_tree().create_timer(1.0).timeout

	var brighten := create_tween()
	brighten.tween_property(_black, "modulate:a", 0.0, 1.0)
	await brighten.finished
	queue_free()
