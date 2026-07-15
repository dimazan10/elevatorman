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
	_label.offset_left = -200
	_label.offset_top = -50
	_label.offset_right = 200
	_label.offset_bottom = 30
	_label.modulate = Color(1, 0, 0, 0)
	_label.add_theme_font_size_override("font_size", 64)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)

	var tween: Tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(_black, "modulate:a", 0.6, 1.0)
	tween.tween_property(_label, "modulate:a", 1.0, 0.3)
	tween.tween_callback(_shake)
	tween.tween_interval(0.2)
	tween.tween_property(_label, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(_black, "modulate:a", 1.0, 0.5)
	tween.tween_interval(0.5)
	tween.tween_callback(_reload)
	tween.tween_interval(1.0)
	tween.tween_property(_black, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)

func _shake() -> void:
	var orig_x: float = _label.offset_left
	var shake: Tween = create_tween()
	shake.tween_property(_label, "offset_left", orig_x + 6, 0.03)
	shake.tween_property(_label, "offset_left", orig_x - 6, 0.03)
	shake.tween_property(_label, "offset_left", orig_x + 6, 0.03)
	shake.tween_property(_label, "offset_left", orig_x - 6, 0.03)
	shake.tween_property(_label, "offset_left", orig_x + 6, 0.03)
	shake.tween_property(_label, "offset_left", orig_x - 6, 0.03)
	shake.tween_property(_label, "offset_left", orig_x, 0.03)

func _reload() -> void:
	get_tree().reload_current_scene()
