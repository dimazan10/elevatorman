extends Control

signal resume_pressed
signal exit_pressed
signal restart_pressed

var _settings_panel: Control = null
var _click: AudioStreamPlayer
var _resume_btn: Button


func _ready() -> void:
	_click = AudioStreamPlayer.new()
	_click.stream = load("res://Assets/Sounds/Effects/Click_Button.mp3")
	add_child(_click)

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
	vbox.anchor_left = 0.0
	vbox.anchor_top = 0.0
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.alignment = VBoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	add_child(vbox)

	var title := Label.new()
	title.text = "ПАУЗА"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(title)

	var resume_btn := Button.new()
	resume_btn.text = "Продолжить"
	resume_btn.custom_minimum_size = Vector2(200, 40)
	resume_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	resume_btn.pressed.connect(_on_resume)
	vbox.add_child(resume_btn)
	_resume_btn = resume_btn
	resume_btn.grab_focus.call_deferred()

	var restart_btn := Button.new()
	restart_btn.text = "Рестарт"
	restart_btn.custom_minimum_size = Vector2(200, 40)
	restart_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart_btn.pressed.connect(_on_restart)
	vbox.add_child(restart_btn)

	var settings_btn := Button.new()
	settings_btn.text = "Настройки"
	settings_btn.custom_minimum_size = Vector2(200, 40)
	settings_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	settings_btn.pressed.connect(_on_settings)
	vbox.add_child(settings_btn)

	var exit_btn := Button.new()
	exit_btn.text = "Главное меню"
	exit_btn.custom_minimum_size = Vector2(200, 40)
	exit_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	exit_btn.pressed.connect(_on_exit)
	vbox.add_child(exit_btn)


func _on_settings() -> void:
	_click.play()
	_settings_panel = preload("res://Scenes/Settings/Settings.tscn").instantiate()
	_settings_panel.return_to_game = true
	_settings_panel.back_pressed.connect(_close_settings)
	add_child(_settings_panel)
	$VBox.visible = false


func _close_settings() -> void:
	if _settings_panel:
		_settings_panel.queue_free()
		_settings_panel = null
	$VBox.visible = true
	if _resume_btn:
		_resume_btn.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _settings_panel:
			_close_settings()
		else:
			_on_resume()

func _on_resume() -> void:
	_click.play()
	resume_pressed.emit()

func _on_restart() -> void:
	_click.play()
	restart_pressed.emit()

func _on_exit() -> void:
	_click.play()
	exit_pressed.emit()
