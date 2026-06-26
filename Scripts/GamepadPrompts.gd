extends CanvasLayer

var _a_tex: Texture2D
var _b_tex: Texture2D
var _prompts: Control

func _ready() -> void:
	layer = 130

	_a_tex = load("res://Assets/Gamepad/A.png")
	_b_tex = load("res://Assets/Gamepad/B.png")

	_prompts = Control.new()
	_prompts.name = "GamepadPrompts"
	_prompts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_prompts)

	var left := HBoxContainer.new()
	left.name = "Left"
	left.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	left.offset_left = 20
	left.offset_bottom = -20
	_prompts.add_child(left)

	var a_icon := TextureRect.new()
	a_icon.texture = _a_tex
	a_icon.custom_minimum_size = Vector2(32, 32)
	a_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	left.add_child(a_icon)

	var a_lbl := Label.new()
	a_lbl.text = "Выбрать"
	a_lbl.add_theme_font_size_override("font_size", 20)
	a_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	a_lbl.add_theme_constant_override("outline_size", 2)
	a_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	left.add_child(a_lbl)

	var right := HBoxContainer.new()
	right.name = "Right"
	right.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	right.offset_right = -20
	right.offset_bottom = -20
	_prompts.add_child(right)

	var b_lbl := Label.new()
	b_lbl.text = "Назад"
	b_lbl.add_theme_font_size_override("font_size", 20)
	b_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	b_lbl.add_theme_constant_override("outline_size", 2)
	b_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	right.add_child(b_lbl)

	var b_icon := TextureRect.new()
	b_icon.texture = _b_tex
	b_icon.custom_minimum_size = Vector2(32, 32)
	b_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	right.add_child(b_icon)

	_update_visibility()
	Input.device_changed.connect(_update_visibility)

func _update_visibility() -> void:
	_prompts.visible = Input.get_connected_joypads().size() > 0
