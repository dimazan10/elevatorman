extends Node

func _ready() -> void:
	_ensure_action("move_right", [KEY_D, KEY_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]], [JOY_BUTTON_DPAD_RIGHT])
	_ensure_action("move_left", [KEY_A, KEY_LEFT], [[JOY_AXIS_LEFT_X, -1.0]], [JOY_BUTTON_DPAD_LEFT])
	_ensure_action("move_up", [KEY_W, KEY_UP], [[JOY_AXIS_LEFT_Y, -1.0]], [JOY_BUTTON_DPAD_UP])
	_ensure_action("move_down", [KEY_S, KEY_DOWN], [[JOY_AXIS_LEFT_Y, 1.0]], [JOY_BUTTON_DPAD_DOWN])
	_ensure_action("dash", [KEY_SHIFT], [[JOY_AXIS_TRIGGER_RIGHT, 1.0]], [JOY_BUTTON_A])
	_ensure_action("use_item_1", [KEY_Q], [], [JOY_BUTTON_LEFT_SHOULDER])
	_ensure_action("use_item_2", [KEY_E], [], [JOY_BUTTON_RIGHT_SHOULDER])
	_ensure_action("pause_game", [KEY_ESCAPE, KEY_BACK], [], [JOY_BUTTON_START])
	_ensure_action("cheat_menu", [KEY_F2], [], [JOY_BUTTON_BACK])

	_ensure_action("ui_up", [KEY_UP], [[JOY_AXIS_LEFT_Y, -1.0]], [JOY_BUTTON_DPAD_UP])
	_ensure_action("ui_down", [KEY_DOWN], [[JOY_AXIS_LEFT_Y, 1.0]], [JOY_BUTTON_DPAD_DOWN])
	_ensure_action("ui_left", [KEY_LEFT], [[JOY_AXIS_LEFT_X, -1.0]], [JOY_BUTTON_DPAD_LEFT])
	_ensure_action("ui_right", [KEY_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]], [JOY_BUTTON_DPAD_RIGHT])
	_ensure_action("ui_accept", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE], [], [JOY_BUTTON_A])
	_ensure_action("ui_cancel", [KEY_ESCAPE], [], [JOY_BUTTON_B])

	_ensure_action("aim_right", [], [[JOY_AXIS_RIGHT_X, 1.0]], [])
	_ensure_action("aim_left", [], [[JOY_AXIS_RIGHT_X, -1.0]], [])
	_ensure_action("aim_up", [], [[JOY_AXIS_RIGHT_Y, -1.0]], [])
	_ensure_action("aim_down", [], [[JOY_AXIS_RIGHT_Y, 1.0]], [])

func _ensure_action(name: String, keys: Array, joy_axes: Array = [], joy_buttons: Array = []) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name, 0.5)
	for key in keys:
		var ev := InputEventKey.new()
		ev.keycode = key
		_add_event_if_missing(name, ev)
	for joy_axis in joy_axes:
		if joy_axis == null or joy_axis.size() < 2:
			continue
		var ev := InputEventJoypadMotion.new()
		ev.axis = joy_axis[0]
		ev.axis_value = joy_axis[1]
		_add_event_if_missing(name, ev)
	for btn in joy_buttons:
		var ev := InputEventJoypadButton.new()
		ev.button_index = btn
		_add_event_if_missing(name, ev)

func _add_event_if_missing(action: String, event: InputEvent) -> void:
	for existing in InputMap.action_get_events(action):
		if _events_match(existing, event):
			return
	InputMap.action_add_event(action, event)

func _events_match(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		return (a as InputEventKey).keycode == (b as InputEventKey).keycode
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return (a as InputEventJoypadButton).button_index == (b as InputEventJoypadButton).button_index
	if a is InputEventJoypadMotion and b is InputEventJoypadMotion:
		var motion_a := a as InputEventJoypadMotion
		var motion_b := b as InputEventJoypadMotion
		return motion_a.axis == motion_b.axis and is_equal_approx(motion_a.axis_value, motion_b.axis_value)
	return false
