extends CanvasLayer

const ICON_SCALE := 0.01
const GAMEPLAY_SCENES := ["Start", "MainArena"]
const UI_SCENES := ["MainMenu", "Settings", "Shop"]

var _bar: HBoxContainer
var _last_mode := ""

func _ready() -> void:
	layer = 130

	_bar = HBoxContainer.new()
	_bar.name = "GamepadPrompts"
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.alignment = HBoxContainer.ALIGNMENT_CENTER
	_bar.add_theme_constant_override("separation", 10)
	_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_bar.offset_left = 16
	_bar.offset_right = -16
	_bar.offset_bottom = -70
	_bar.offset_top = -98
	add_child(_bar)

	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_update_prompts()

func _process(_delta: float) -> void:
	_update_prompts()

func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_update_prompts(true)

func _update_prompts(force := false) -> void:
	var mode := _get_prompt_mode()
	if not force and mode == _last_mode:
		return
	_last_mode = mode

	_bar.visible = mode != ""
	for child in _bar.get_children():
		child.queue_free()
	if mode == "":
		return

	if mode == "gameplay":
		_add_hint("res://Assets/Gamepad/A.png", "Dash")
		_add_hint("res://Assets/Gamepad/LB.png", "Item 1")
		_add_hint("res://Assets/Gamepad/RB.png", "Item 2")
		_add_hint("res://Assets/Gamepad/START.png", "Pause")
		_add_hint("res://Assets/Gamepad/SELECT.png", "Cheats")
	else:
		_add_hint("res://Assets/Gamepad/A.png", "Select")
		_add_hint("res://Assets/Gamepad/B.png", "Back")
		if mode == "cheat":
			_add_hint("res://Assets/Gamepad/SELECT.png", "Cheats")

func _get_prompt_mode() -> String:
	if Input.get_connected_joypads().is_empty():
		return ""
	if _is_cheat_menu_open():
		return "cheat"
	if _is_pause_layer_visible():
		return "ui"

	var scene := get_tree().current_scene
	if not scene:
		return ""
	if scene.name in UI_SCENES:
		return "ui"
	if scene.name in GAMEPLAY_SCENES or not get_tree().get_nodes_in_group("pausable").is_empty():
		return "gameplay"
	return ""

func _add_hint(icon_path: String, text: String) -> void:
	var hint := HBoxContainer.new()
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_constant_override("separation", 4)
	_bar.add_child(hint)

	var icon := TextureRect.new()
	var texture := load(icon_path) as Texture2D
	icon.texture = texture
	if texture:
		icon.custom_minimum_size = texture.get_size() * ICON_SCALE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_child(icon)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_child(label)

func _is_pause_layer_visible() -> bool:
	var pause_layer := get_node_or_null("/root/PauseManager/PauseLayer") as CanvasLayer
	return pause_layer != null and pause_layer.visible

func _is_cheat_menu_open() -> bool:
	var pause_layer := get_node_or_null("/root/PauseManager/PauseLayer")
	if not pause_layer:
		return false
	return pause_layer.get_node_or_null("CheatMenu") != null
