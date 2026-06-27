extends CanvasLayer

func _ready() -> void:
	if not OS.has_feature("mobile"):
		queue_free()
		return
	
	# Стик перемещения (визуальная заглушка)
	var joy_rect = ColorRect.new()
	joy_rect.size = Vector2(150, 150)
	joy_rect.position = Vector2(50, 500)
	joy_rect.color = Color(1, 1, 1, 0.3) # Полупрозрачный белый
	add_child(joy_rect)
	
	var joy_label = Label.new()
	joy_label.text = "MOVE"
	joy_label.position = Vector2(60, 550)
	add_child(joy_label)
	
	# Кнопка рывка (Dash)
	var dash_btn = TouchScreenButton.new()
	dash_btn.action = "dash"
	
	# Визуальная заглушка для кнопки
	var dash_rect = ColorRect.new()
	dash_rect.size = Vector2(100, 100)
	dash_rect.color = Color(1, 0, 0, 0.5) # Полупрозрачный красный
	dash_btn.add_child(dash_rect)
	
	dash_btn.position = Vector2(1100, 500)
	add_child(dash_btn)
	
	var dash_label = Label.new()
	dash_label.text = "DASH"
	dash_label.position = Vector2(1130, 540)
	add_child(dash_label)
