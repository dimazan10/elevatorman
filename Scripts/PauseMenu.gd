extends Control

signal resume_pressed
signal exit_pressed

var master_slider: HSlider
var master_label: Label
var music_slider: HSlider
var music_label: Label


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.position = Vector2(0, 80)
	vbox.size = Vector2(get_viewport_rect().size.x, 0)
	vbox.add_theme_constant_override("separation", 16)
	add_child(vbox)

	var title := Label.new()
	title.text = "ПАУЗА"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	vbox.add_child(title)

	var resume_btn := Button.new()
	resume_btn.text = "Продолжить"
	resume_btn.size = Vector2(250, 50)
	resume_btn.pressed.connect(_on_resume)
	vbox.add_child(resume_btn)

	master_slider = HSlider.new()
	master_label = Label.new()
	music_slider = HSlider.new()
	music_label = Label.new()

	var master_box := HBoxContainer.new()
	master_box.name = "Master"
	var master_lbl := Label.new()
	master_lbl.text = "Общая громкость"
	master_lbl.size_flags_horizontal = SIZE_EXPAND
	master_box.add_child(master_lbl)

	master_slider.min_value = -40.0
	master_slider.max_value = 0.0
	master_slider.size_flags_horizontal = SIZE_EXPAND
	master_slider.value = GameState.master_volume
	master_slider.value_changed.connect(_on_master_changed)
	master_box.add_child(master_slider)

	master_label.text = _db_to_pct(GameState.master_volume)
	master_label.custom_minimum_size = Vector2(50, 0)
	master_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	master_box.add_child(master_label)
	vbox.add_child(master_box)

	var music_box := HBoxContainer.new()
	music_box.name = "Music"
	var music_lbl := Label.new()
	music_lbl.text = "Громкость музыки"
	music_lbl.size_flags_horizontal = SIZE_EXPAND
	music_box.add_child(music_lbl)

	music_slider.min_value = -40.0
	music_slider.max_value = 0.0
	music_slider.size_flags_horizontal = SIZE_EXPAND
	music_slider.value = GameState.music_volume
	music_slider.value_changed.connect(_on_music_changed)
	music_box.add_child(music_slider)

	music_label.text = _db_to_pct(GameState.music_volume)
	music_label.custom_minimum_size = Vector2(50, 0)
	music_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	music_box.add_child(music_label)
	vbox.add_child(music_box)

	var exit_btn := Button.new()
	exit_btn.text = "Выход в главное меню"
	exit_btn.size = Vector2(250, 50)
	exit_btn.pressed.connect(_on_exit)
	vbox.add_child(exit_btn)


func _on_master_changed(value: float) -> void:
	GameState.set_master_volume(value)
	master_label.text = _db_to_pct(value)

func _on_music_changed(value: float) -> void:
	GameState.set_music_volume(value)
	music_label.text = _db_to_pct(value)

func _on_resume() -> void:
	resume_pressed.emit()

func _on_exit() -> void:
	exit_pressed.emit()


func _db_to_pct(db: float) -> String:
	var pct = roundi((db + 40.0) / 40.0 * 100.0)
	return str(clampi(pct, 0, 100)) + "%"
