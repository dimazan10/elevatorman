extends Node

func _ready() -> void:
	_ensure_action("move_right", [KEY_D, KEY_RIGHT], [JOY_AXIS_LEFT_X, 1.0])
	_ensure_action("move_left", [KEY_A, KEY_LEFT], [JOY_AXIS_LEFT_X, -1.0])
	_ensure_action("move_up", [KEY_W, KEY_UP], [JOY_AXIS_LEFT_Y, -1.0])
	_ensure_action("move_down", [KEY_S, KEY_DOWN], [JOY_AXIS_LEFT_Y, 1.0])
	_ensure_action("dash", [KEY_SHIFT], [JOY_AXIS_TRIGGER_RIGHT, 1.0])
	_ensure_action("use_item_1", [KEY_Q], [], [JOY_BUTTON_LEFT_SHOULDER])
	_ensure_action("use_item_2", [KEY_E], [], [JOY_BUTTON_RIGHT_SHOULDER])

	_add_joy("ui_up", JOY_BUTTON_DPAD_UP)
	_add_joy("ui_down", JOY_BUTTON_DPAD_DOWN)
	_add_joy("ui_left", JOY_BUTTON_DPAD_LEFT)
	_add_joy("ui_right", JOY_BUTTON_DPAD_RIGHT)
	_add_joy("ui_accept", JOY_BUTTON_A)
	_add_joy("ui_cancel", JOY_BUTTON_B)

func _ensure_action(name: String, keys: Array, joy_axis: Array = [], joy_buttons: Array = []) -> void:
	if InputMap.has_action(name):
		return
	InputMap.add_action(name, 0.5)
	for key in keys:
		var ev := InputEventKey.new()
		ev.keycode = key
		InputMap.action_add_event(name, ev)
	if joy_axis and joy_axis.size() >= 2:
		var ev := InputEventJoypadMotion.new()
		ev.axis = joy_axis[0]
		ev.axis_value = joy_axis[1]
		InputMap.action_add_event(name, ev)
	for btn in joy_buttons:
		var ev := InputEventJoypadButton.new()
		ev.button_index = btn
		InputMap.action_add_event(name, ev)

func _add_joy(action: String, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.5)
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
