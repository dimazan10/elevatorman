extends CanvasLayer

const GAMEPAD_ICON_SCALE := 0.1

@onready var wind_tex: Texture2D = preload("res://Assets/Inventory/Wind.png")
@onready var slots: Array[Control] = [
	$Panel/BgWind/Slot0,
	$Panel/BgWind/Slot1,
]
@onready var left_label := $Panel/LeftInterection as Label
@onready var right_label := $Panel/RightInterection as Label

var _left_gamepad_icon: TextureRect
var _right_gamepad_icon: TextureRect

func _ready() -> void:
	_setup_gamepad_icons()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	var p := get_tree().get_first_node_in_group("player")
	if p and p.has_signal("inventory_changed"):
		p.inventory_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if not p or not p.has_method("get_inventory"):
		return
	var inv = p.get_inventory()
	for i in range(slots.size()):
		var icon = slots[i].get_node("Icon") as TextureRect
		if not icon:
			continue
		if i < inv.size() and inv[i].icon:
			icon.texture = inv[i].icon
		else:
			icon.texture = null
		slots[i].visible = true

func _setup_gamepad_icons() -> void:
	_left_gamepad_icon = _make_gamepad_icon("res://Assets/Gamepad/LB.png", left_label)
	_right_gamepad_icon = _make_gamepad_icon("res://Assets/Gamepad/RB.png", right_label)
	_update_input_prompts()

func _make_gamepad_icon(path: String, anchor_label: Label) -> TextureRect:
	var icon := TextureRect.new()
	var texture := load(path) as Texture2D
	icon.texture = texture
	icon.modulate = anchor_label.modulate
	icon.position = anchor_label.position + Vector2(-1, 2)
	if texture:
		icon.size = texture.get_size() * GAMEPAD_ICON_SCALE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	$Panel.add_child(icon)
	return icon

func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_update_input_prompts()

func _update_input_prompts() -> void:
	var use_gamepad := not Input.get_connected_joypads().is_empty()
	left_label.visible = not use_gamepad
	right_label.visible = not use_gamepad
	if _left_gamepad_icon:
		_left_gamepad_icon.visible = use_gamepad
	if _right_gamepad_icon:
		_right_gamepad_icon.visible = use_gamepad
