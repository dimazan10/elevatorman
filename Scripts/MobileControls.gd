extends CanvasLayer

func _ready() -> void:
	if not GameState.use_mobile_controls:
		queue_free()
		return
	
	# Настройки для кнопок
	var btn_size = Vector2(180, 180)

	# 1. D-Pad (Перемещение слева внизу)
	var directions = {"ui_up": Vector2(120, 300), "ui_down": Vector2(120, 500), "ui_left": Vector2(20, 400), "ui_right": Vector2(220, 400)}
	
	for action in directions:
		var btn = TouchScreenButton.new()
		btn.action = action
		
		var rect = ColorRect.new()
		rect.size = btn_size
		rect.color = Color(1, 1, 1, 0.3)
		btn.add_child(rect)
		
		btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		btn.offset_left = directions[action].x
		btn.offset_top = directions[action].y - 600
		add_child(btn)

	# 2. Кнопка рывка (Dash справа посередине)
	var dash_btn = TouchScreenButton.new()
	dash_btn.action = "dash"
	
	var dash_rect = ColorRect.new()
	dash_rect.size = Vector2(225, 225)
	dash_rect.color = Color(1, 0, 0, 0.4)
	dash_btn.add_child(dash_rect)
	
	dash_btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	dash_btn.offset_left = -250
	dash_btn.offset_top = -112
	add_child(dash_btn)
