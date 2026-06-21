extends Control

var _input: LineEdit
var _error_label: Label

func _ready() -> void:
	var panel = Panel.new()
	panel.size = Vector2(400, 240)
	panel.position = Vector2(440, 230)
	add_child(panel)

	var label = Label.new()
	label.text = "ЧИТЫ"
	label.add_theme_font_size_override("font_size", 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(0, 20)
	label.size = Vector2(400, 40)
	panel.add_child(label)

	var hp_label = Label.new()
	hp_label.text = "HP:"
	hp_label.position = Vector2(30, 80)
	hp_label.size = Vector2(50, 30)
	panel.add_child(hp_label)

	_input = LineEdit.new()
	_input.position = Vector2(80, 75)
	_input.size = Vector2(150, 35)
	_input.placeholder_text = "кол-во HP"
	_input.text_changed.connect(_on_text_changed)
	panel.add_child(_input)

	var btn = Button.new()
	btn.text = "Применить"
	btn.position = Vector2(250, 75)
	btn.size = Vector2(120, 35)
	btn.pressed.connect(_apply_hp)
	panel.add_child(btn)

	_error_label = Label.new()
	_error_label.position = Vector2(30, 155)
	_error_label.size = Vector2(340, 30)
	_error_label.add_theme_color_override("font_color", Color.RED)
	panel.add_child(_error_label)

	var bucket_btn = Button.new()
	bucket_btn.text = "+ Ведро"
	bucket_btn.position = Vector2(30, 120)
	bucket_btn.size = Vector2(150, 30)
	bucket_btn.pressed.connect(_add_bucket)
	bucket_btn.add_theme_color_override("font_color", Color.GOLD)
	panel.add_child(bucket_btn)

	var close_btn = Button.new()
	close_btn.text = "Закрыть"
	close_btn.position = Vector2(140, 195)
	close_btn.size = Vector2(120, 30)
	close_btn.pressed.connect(_close)
	panel.add_child(close_btn)

	_input.grab_focus()

func _on_text_changed(new_text: String) -> void:
	var filtered = ""
	for c in new_text:
		if c >= "0" and c <= "9":
			filtered += c
	if filtered != new_text:
		_input.text = filtered
		_input.caret_column = filtered.length()

func _apply_hp() -> void:
	var val = _input.text.strip_edges().to_int()
	if val < 1:
		_error_label.text = "HP должно быть >= 1"
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		_error_label.text = "Игрок не найден"
		return
	if not player.has_signal("health_changed"):
		_error_label.text = "Нет сигнала health_changed"
		return
	player.current_lives = val
	player.max_lives = val
	player.health_changed.emit(val)
	_input.text = ""
	_error_label.text = ""

func _add_bucket() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	if player.has_node("Bucket"):
		_error_label.text = "Ведро уже есть"
		return
	var bucket = preload("res://Objects/Bucket.tscn").instantiate()
	bucket.name = "Bucket"
	bucket.position = Vector2(0, -30)
	player.add_child(bucket)
	_error_label.text = ""

func _close() -> void:
	queue_free()
