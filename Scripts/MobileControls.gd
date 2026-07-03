extends CanvasLayer

const JOYSTICK_RADIUS := 140.0
const KNOB_RADIUS := 50.0
const DEADZONE := 0.15
const MARGIN := 80.0

var _base: Panel
var _knob: Panel
var _dragging := false
var _direction := Vector2.ZERO
var _prev_actions := {"move_left": false, "move_right": false, "move_up": false, "move_down": false}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_create_ui()

func _process(_delta: float) -> void:
	var scene_name = ""
	if get_tree().current_scene:
		scene_name = get_tree().current_scene.name
	var in_game = not scene_name.begins_with("MainMenu") and scene_name != "Settings"
	var should_show = GameState.use_mobile_controls and in_game

	if should_show and not visible:
		visible = true
		_reset_knob()
	elif not should_show and visible:
		visible = false
		_release_all()
		return

	if not visible:
		return

	_update_knob_from_input()
	_apply_direction()

func _create_ui() -> void:
	var vp_size := get_viewport().get_visible_rect().size
	var base_pos := Vector2(MARGIN, vp_size.y - JOYSTICK_RADIUS * 2 - MARGIN)

	_base = Panel.new()
	_base.size = Vector2(JOYSTICK_RADIUS * 2, JOYSTICK_RADIUS * 2)
	_base.position = base_pos
	_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Color(1, 1, 1, 0.3)
	base_style.corner_radius_top_left = int(JOYSTICK_RADIUS)
	base_style.corner_radius_top_right = int(JOYSTICK_RADIUS)
	base_style.corner_radius_bottom_left = int(JOYSTICK_RADIUS)
	base_style.corner_radius_bottom_right = int(JOYSTICK_RADIUS)
	base_style.border_width_top = 2
	base_style.border_width_bottom = 2
	base_style.border_width_left = 2
	base_style.border_width_right = 2
	base_style.border_color = Color(1, 1, 1, 0.5)
	_base.add_theme_stylebox_override("panel", base_style)
	add_child(_base)

	_knob = Panel.new()
	_knob.size = Vector2(KNOB_RADIUS * 2, KNOB_RADIUS * 2)
	_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(1, 1, 1, 0.5)
	knob_style.corner_radius_top_left = int(KNOB_RADIUS)
	knob_style.corner_radius_top_right = int(KNOB_RADIUS)
	knob_style.corner_radius_bottom_left = int(KNOB_RADIUS)
	knob_style.corner_radius_bottom_right = int(KNOB_RADIUS)
	_knob.add_theme_stylebox_override("panel", knob_style)
	_base.add_child(_knob)

	_reset_knob()

	var dash_btn = Button.new()
	dash_btn.text = "DASH"
	dash_btn.size = Vector2(400, 400)
	dash_btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	dash_btn.offset_left = -450
	dash_btn.offset_top = -200
	dash_btn.modulate = Color(1, 0, 0, 0.4)
	dash_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	dash_btn.button_down.connect(_on_dash_pressed)
	add_child(dash_btn)

func _on_dash_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("perform_dash"):
		player.perform_dash()

func _reset_knob() -> void:
	_knob.position = Vector2(JOYSTICK_RADIUS - KNOB_RADIUS, JOYSTICK_RADIUS - KNOB_RADIUS)
	_direction = Vector2.ZERO
	_dragging = false

func _release_all() -> void:
	for action in _prev_actions:
		if _prev_actions[action]:
			var ev = InputEventAction.new()
			ev.action = action
			ev.pressed = false
			Input.parse_input_event(ev)
		_prev_actions[action] = false
	_direction = Vector2.ZERO

func _update_knob_from_input() -> void:
	var center := Vector2(JOYSTICK_RADIUS, JOYSTICK_RADIUS)
	var base_center := _base.position + center
	var mouse_pos := get_viewport().get_mouse_position()
	var local_mouse := mouse_pos - base_center

	var is_hovering = local_mouse.length() <= JOYSTICK_RADIUS + 20.0

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and is_hovering:
		_dragging = true
	elif not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_dragging = false

	if _dragging:
		var offset = local_mouse
		if offset.length() > JOYSTICK_RADIUS:
			offset = offset.normalized() * JOYSTICK_RADIUS
		_knob.position = offset + center - Vector2(KNOB_RADIUS, KNOB_RADIUS)
		_direction = offset / JOYSTICK_RADIUS
		if _direction.length() < DEADZONE:
			_direction = Vector2.ZERO
	else:
		_knob.position = center - Vector2(KNOB_RADIUS, KNOB_RADIUS)
		_direction = Vector2.ZERO

func _apply_direction() -> void:
	var actions = {
		"move_right": _direction.x > DEADZONE,
		"move_left":  _direction.x < -DEADZONE,
		"move_up":    _direction.y < -DEADZONE,
		"move_down":  _direction.y > DEADZONE,
	}
	for action in actions:
		var ev = InputEventAction.new()
		ev.action = action
		if actions[action] and not _prev_actions[action]:
			ev.pressed = true
			Input.parse_input_event(ev)
		elif not actions[action] and _prev_actions[action]:
			ev.pressed = false
			Input.parse_input_event(ev)
		_prev_actions[action] = actions[action]
