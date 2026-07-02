extends Control

var _hp_input: LineEdit
var _currency_input: LineEdit
var _speed_input: LineEdit
var _error_label: Label
var _panel: Panel
var _dragging := false
var _drag_offset := Vector2.ZERO

func _ready() -> void:
	_panel = Panel.new()
	_panel.size = Vector2(400, 540)
	_panel.position = Vector2(10, 10)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.gui_input.connect(_on_panel_gui_input)
	add_child(_panel)

	var y := 0

	var title = Label.new()
	title.text = "ЧИТЫ"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, y + 10)
	title.size = Vector2(400, 35)
	_panel.add_child(title)
	y += 50

	var section1 = Label.new()
	section1.text = "── Значения ──"
	section1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section1.position = Vector2(0, y)
	section1.size = Vector2(400, 20)
	section1.add_theme_font_size_override("font_size", 13)
	section1.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_panel.add_child(section1)
	y += 22

	var hp_label = Label.new()
	hp_label.text = "HP:"
	hp_label.position = Vector2(20, y)
	hp_label.size = Vector2(55, 28)
	_panel.add_child(hp_label)

	_hp_input = LineEdit.new()
	_hp_input.position = Vector2(80, y - 2)
	_hp_input.size = Vector2(140, 30)
	_hp_input.placeholder_text = "кол-во HP"
	_hp_input.text_changed.connect(_on_hp_text_changed)
	_panel.add_child(_hp_input)

	var hp_btn = Button.new()
	hp_btn.text = "OK"
	hp_btn.position = Vector2(225, y - 2)
	hp_btn.size = Vector2(50, 30)
	hp_btn.pressed.connect(_apply_hp)
	_panel.add_child(hp_btn)
	y += 36

	var currency_label = Label.new()
	currency_label.text = "Монеты:"
	currency_label.position = Vector2(20, y)
	currency_label.size = Vector2(55, 28)
	_panel.add_child(currency_label)

	_currency_input = LineEdit.new()
	_currency_input.position = Vector2(80, y - 2)
	_currency_input.size = Vector2(140, 30)
	_currency_input.placeholder_text = "кол-во монет"
	_currency_input.text_changed.connect(_on_currency_text_changed)
	_panel.add_child(_currency_input)

	var currency_btn = Button.new()
	currency_btn.text = "OK"
	currency_btn.position = Vector2(225, y - 2)
	currency_btn.size = Vector2(50, 30)
	currency_btn.pressed.connect(_apply_currency)
	_panel.add_child(currency_btn)
	y += 36

	var speed_label = Label.new()
	speed_label.text = "Скорость:"
	speed_label.position = Vector2(20, y)
	speed_label.size = Vector2(55, 28)
	_panel.add_child(speed_label)

	_speed_input = LineEdit.new()
	_speed_input.position = Vector2(80, y - 2)
	_speed_input.size = Vector2(140, 30)
	_speed_input.placeholder_text = "550"
	_speed_input.text_changed.connect(_on_speed_text_changed)
	_panel.add_child(_speed_input)

	var speed_btn = Button.new()
	speed_btn.text = "OK"
	speed_btn.position = Vector2(225, y - 2)
	speed_btn.size = Vector2(50, 30)
	speed_btn.pressed.connect(_apply_speed)
	_panel.add_child(speed_btn)
	y += 40

	var section2 = Label.new()
	section2.text = "── Предметы ──"
	section2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section2.position = Vector2(0, y)
	section2.size = Vector2(400, 20)
	section2.add_theme_font_size_override("font_size", 13)
	section2.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_panel.add_child(section2)
	y += 22

	var bucket_btn = Button.new()
	bucket_btn.text = "Ведро"
	bucket_btn.position = Vector2(20, y)
	bucket_btn.size = Vector2(85, 30)
	bucket_btn.pressed.connect(_add_bucket)
	bucket_btn.add_theme_color_override("font_color", Color.GOLD)
	_panel.add_child(bucket_btn)

	var infinit_btn = Button.new()
	infinit_btn.text = "Infinit"
	infinit_btn.position = Vector2(110, y)
	infinit_btn.size = Vector2(85, 30)
	infinit_btn.pressed.connect(_add_infinit)
	infinit_btn.add_theme_color_override("font_color", Color.WHITE)
	_panel.add_child(infinit_btn)

	var tube_btn = Button.new()
	tube_btn.text = "Tube"
	tube_btn.position = Vector2(200, y)
	tube_btn.size = Vector2(85, 30)
	tube_btn.pressed.connect(_add_tube)
	tube_btn.add_theme_color_override("font_color", Color.WHITE)
	_panel.add_child(tube_btn)

	var clone_btn = Button.new()
	clone_btn.text = "Clone"
	clone_btn.position = Vector2(290, y)
	clone_btn.size = Vector2(85, 30)
	clone_btn.pressed.connect(_add_clone)
	clone_btn.add_theme_color_override("font_color", Color.WHITE)
	_panel.add_child(clone_btn)
	y += 42

	var section3 = Label.new()
	section3.text = "── Призвать ──"
	section3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section3.position = Vector2(0, y)
	section3.size = Vector2(400, 20)
	section3.add_theme_font_size_override("font_size", 13)
	section3.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_panel.add_child(section3)
	y += 22

	var spawn_angry = Button.new()
	spawn_angry.text = "AngryBall"
	spawn_angry.position = Vector2(20, y)
	spawn_angry.size = Vector2(85, 30)
	spawn_angry.pressed.connect(_spawn_creature.bind("res://Objects/Summons/angry_ball.tscn"))
	spawn_angry.add_theme_color_override("font_color", Color(1, 0.5, 0.3))
	_panel.add_child(spawn_angry)

	var spawn_drunk = Button.new()
	spawn_drunk.text = "DrunkKiller"
	spawn_drunk.position = Vector2(110, y)
	spawn_drunk.size = Vector2(85, 30)
	spawn_drunk.pressed.connect(_spawn_creature.bind("res://Objects/Summons/DrunkKiller.tscn"))
	spawn_drunk.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	_panel.add_child(spawn_drunk)

	var spawn_spider = Button.new()
	spawn_spider.text = "Spider"
	spawn_spider.position = Vector2(200, y)
	spawn_spider.size = Vector2(85, 30)
	spawn_spider.pressed.connect(_spawn_creature.bind("res://Objects/Summons/Spider.tscn"))
	spawn_spider.add_theme_color_override("font_color", Color(0.5, 0.8, 0.3))
	_panel.add_child(spawn_spider)

	var spawn_turret = Button.new()
	spawn_turret.text = "Turret"
	spawn_turret.position = Vector2(290, y)
	spawn_turret.size = Vector2(85, 30)
	spawn_turret.pressed.connect(_spawn_creature.bind("res://Objects/Summons/Turret.tscn"))
	spawn_turret.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	_panel.add_child(spawn_turret)
	y += 38

	var spawn_switch = Button.new()
	spawn_switch.text = "Switch"
	spawn_switch.position = Vector2(20, y)
	spawn_switch.size = Vector2(85, 30)
	spawn_switch.pressed.connect(_spawn_creature.bind("res://Objects/Summons/Switch.tscn"))
	spawn_switch.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_panel.add_child(spawn_switch)

	var spawn_two = Button.new()
	spawn_two.text = "TwoSwitch"
	spawn_two.position = Vector2(110, y)
	spawn_two.size = Vector2(85, 30)
	spawn_two.pressed.connect(_spawn_creature.bind("res://Objects/Summons/TwoSwitch.tscn"))
	spawn_two.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	_panel.add_child(spawn_two)

	var spawn_crate = Button.new()
	spawn_crate.text = "Коробка"
	spawn_crate.position = Vector2(200, y)
	spawn_crate.size = Vector2(85, 30)
	spawn_crate.pressed.connect(_spawn_crate)
	spawn_crate.add_theme_color_override("font_color", Color(0.6, 0.4, 0.2))
	_panel.add_child(spawn_crate)

	var spawn_clown = Button.new()
	spawn_clown.text = "Clown"
	spawn_clown.position = Vector2(290, y)
	spawn_clown.size = Vector2(85, 30)
	spawn_clown.pressed.connect(_spawn_creature.bind("res://Objects/Summons/Clown.tscn"))
	spawn_clown.add_theme_color_override("font_color", Color(1.0, 0.3, 0.5))
	_panel.add_child(spawn_clown)

	var spawn_slime = Button.new()
	spawn_slime.text = "Slime"
	spawn_slime.position = Vector2(380, y)
	spawn_slime.size = Vector2(85, 30)
	spawn_slime.pressed.connect(_spawn_creature.bind("res://Objects/Summons/Slime.tscn"))
	spawn_slime.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	_panel.add_child(spawn_slime)
	y += 42

	var return_btn = Button.new()
	return_btn.text = "Следующий этаж"
	return_btn.position = Vector2(20, y)
	return_btn.size = Vector2(170, 30)
	return_btn.pressed.connect(_return_elevator)
	return_btn.add_theme_color_override("font_color", Color.CORNFLOWER_BLUE)
	_panel.add_child(return_btn)

	_error_label = Label.new()
	_error_label.position = Vector2(20, y + 38)
	_error_label.size = Vector2(360, 24)
	_error_label.add_theme_font_size_override("font_size", 13)
	_error_label.add_theme_color_override("font_color", Color.RED)
	_panel.add_child(_error_label)

	var close_btn = Button.new()
	close_btn.text = "Закрыть"
	close_btn.position = Vector2(140, y + 65)
	close_btn.size = Vector2(120, 30)
	close_btn.pressed.connect(_close)
	_panel.add_child(close_btn)

	_panel.size.y = y + 110

	if Input.get_connected_joypads().is_empty():
		_hp_input.grab_focus()
	else:
		hp_btn.grab_focus()

func _on_hp_text_changed(new_text: String) -> void:
	var filtered = ""
	for c in new_text:
		if c >= "0" and c <= "9":
			filtered += c
	if filtered != new_text:
		_hp_input.text = filtered
		_hp_input.caret_column = filtered.length()

func _on_currency_text_changed(new_text: String) -> void:
	var filtered = ""
	for c in new_text:
		if c >= "0" and c <= "9":
			filtered += c
	if filtered != new_text:
		_currency_input.text = filtered
		_currency_input.caret_column = filtered.length()

func _on_speed_text_changed(new_text: String) -> void:
	var filtered = ""
	for c in new_text:
		if (c >= "0" and c <= "9") or c == ".":
			filtered += c
	if filtered != new_text:
		_speed_input.text = filtered
		_speed_input.caret_column = filtered.length()

func _apply_hp() -> void:
	var val = _hp_input.text.strip_edges().to_int()
	if val < 1:
		_error_label.text = "HP должно быть >= 1"
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		_error_label.text = "Игрок не найден"
		return
	player.current_lives = val
	player.max_lives = val
	player.health_changed.emit(val)
	_hp_input.text = ""
	_error_label.text = ""

func _apply_currency() -> void:
	var val = _currency_input.text.strip_edges().to_int()
	if val < 0:
		_error_label.text = "Валюта не может быть отрицательной"
		return
	GameState.currency = val
	_currency_input.text = ""
	_error_label.text = "Валюта: " + str(val)

func _apply_speed() -> void:
	var val = _speed_input.text.strip_edges().to_float()
	if val <= 0:
		_error_label.text = "Скорость должна быть > 0"
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		_error_label.text = "Игрок не найден"
		return
	player.speed = val
	_speed_input.text = ""
	_error_label.text = "Скорость: " + str(val)

func _add_bucket() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	if player.has_node("Bucket"):
		_error_label.text = "Ведро уже есть"
		return
	var bucket = preload("res://Objects/Bucket.tscn").instantiate()
	bucket.name = "Bucket"
	bucket.position = Vector2(0, -33)
	bucket.scale = Vector2(0.05, 0.05)
	bucket.z_index = player.z_index
	player.add_child(bucket)
	player._bucket = bucket
	_error_label.text = ""

func _add_infinit() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.has_method("set_slot"):
		_error_label.text = "Игрок не найден"
		return
	for i in range(player.inventory.size()):
		if player.inventory[i].id == "":
			player.set_slot(i, "infinit", preload("res://Assets/Inventory/Infinit.png"), "Infinit")
			_error_label.text = ""
			return
	_error_label.text = "Нет свободных слотов"

func _add_tube() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.has_method("set_slot"):
		_error_label.text = "Игрок не найден"
		return
	for i in range(player.inventory.size()):
		if player.inventory[i].id == "":
			player.set_slot(i, "tube", preload("res://Assets/Inventory/Tube.png"), "Tube")
			_error_label.text = ""
			return
	_error_label.text = "Нет свободных слотов"

func _add_clone() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.has_method("set_slot"):
		_error_label.text = "Игрок не найден"
		return
	for i in range(player.inventory.size()):
		if player.inventory[i].id == "":
			player.set_slot(i, "clone", preload("res://Assets/Inventory/Clone.png"), "Clone")
			_error_label.text = ""
			return
	_error_label.text = "Нет свободных слотов"

func _return_elevator() -> void:
	var arena = get_tree().current_scene.get_node_or_null("MainArena3")
	if not arena:
		_error_label.text = "Арена не найдена"
		return
	if arena.has_method("start_restart"):
		arena.lift_state = 5
		arena.start_restart()

func _spawn_creature(scene_path: String) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		_error_label.text = "Игрок не найден"
		return
	var scene = load(scene_path)
	if not scene:
		_error_label.text = "Сцена не найдена"
		return
	var inst = scene.instantiate()
	var offset = Vector2(randf_range(-80, 80), randf_range(-80, 80))
	inst.global_position = player.global_position + offset
	get_tree().current_scene.add_child(inst)
	if not inst.is_in_group("enemy"):
		inst.add_to_group("enemy")
	for child in inst.get_children():
		if child is Timer and child.has_method("start"):
			if child.has_method("stop") and child.is_stopped():
				child.start()
	_error_label.text = ""

func _spawn_crate() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		_error_label.text = "Игрок не найден"
		return
	var crate_scene = load("res://Objects/Crate.tscn")
	if not crate_scene:
		_error_label.text = "Сцена коробки не найдена"
		return
	var inst = crate_scene.instantiate()
	var offset = Vector2(randf_range(-80, 80), randf_range(-80, 80))
	inst.global_position = player.global_position + offset
	get_tree().current_scene.add_child(inst)
	_error_label.text = ""

func _close() -> void:
	queue_free()

func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
			if _dragging:
				_drag_offset = _panel.global_position - event.global_position

func _input(event: InputEvent) -> void:
	if _dragging and event is InputEventMouseMotion:
		_panel.global_position = event.global_position + _drag_offset
