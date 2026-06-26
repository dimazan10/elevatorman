extends CanvasLayer

const MAX_CHARGES := 3
const COOLDOWN_TIME := 4.0
const GAMEPAD_ICON_SCALE := 0.1

var bars: Array[ColorRect] = []
var bar_tweens: Array[Tween] = []
var _dash_icon: TextureRect

@onready var container: Control = $DashContainer

func _ready() -> void:
	_setup_gamepad_icon()
	for child in container.get_children():
		if child is ColorRect:
			bars.append(child)
			child.modulate = Color(1, 1, 1, 1)
	bar_tweens.resize(MAX_CHARGES)
	container.modulate = Color(1, 1, 1, 0)

	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.dash_used.connect(_on_dash_used)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _on_dash_used(index: int) -> void:
	if index < 0 or index >= MAX_CHARGES:
		return
	if bar_tweens[index]:
		bar_tweens[index].kill()

	var bar := bars[index]
	bar_tweens[index] = create_tween().set_parallel(false)
	bar_tweens[index].tween_property(bar, "modulate:a", 0.0, 0.15)
	bar_tweens[index].tween_property(bar, "modulate:a", 1.0, COOLDOWN_TIME - 0.55)
	bar_tweens[index].tween_property(bar, "modulate", Color(5, 5, 5, 1), 0.08)
	bar_tweens[index].tween_property(bar, "modulate", Color(1, 1, 1, 1), 0.12)
	bar_tweens[index].tween_property(bar, "modulate", Color(5, 5, 5, 1), 0.08)
	bar_tweens[index].tween_property(bar, "modulate", Color(1, 1, 1, 1), 0.12)

func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return

	var any_cooldown := false
	for i in range(MAX_CHARGES):
		if player.dash_cooldowns[i] > 0:
			any_cooldown = true
			break

	var target := 1.0 if any_cooldown else 0.0
	container.modulate = container.modulate.lerp(Color(1, 1, 1, target), delta * 8.0)
	if _dash_icon:
		var icon_target := target if not Input.get_connected_joypads().is_empty() else 0.0
		_dash_icon.modulate = _dash_icon.modulate.lerp(Color(1, 1, 1, icon_target), delta * 8.0)

func _setup_gamepad_icon() -> void:
	_dash_icon = TextureRect.new()
	_dash_icon.name = "DashGamepadIcon"
	var texture := load("res://Assets/Gamepad/RT.png") as Texture2D
	_dash_icon.texture = texture
	var icon_size := texture.get_size() * GAMEPAD_ICON_SCALE if texture else Vector2(24, 24)
	_dash_icon.custom_minimum_size = icon_size
	_dash_icon.size = icon_size
	_dash_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_dash_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dash_icon.anchor_left = 0.5
	_dash_icon.anchor_right = 0.5
	_dash_icon.anchor_top = 1.0
	_dash_icon.anchor_bottom = 1.0
	_dash_icon.offset_left = -118
	_dash_icon.offset_top = -196
	_dash_icon.offset_right = _dash_icon.offset_left + icon_size.x
	_dash_icon.offset_bottom = _dash_icon.offset_top + icon_size.y
	_dash_icon.modulate = Color(1, 1, 1, 0)
	add_child(_dash_icon)

func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	if _dash_icon and not _connected and Input.get_connected_joypads().is_empty():
		_dash_icon.modulate = Color(1, 1, 1, 0)
