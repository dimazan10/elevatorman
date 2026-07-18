extends Control

@onready var bg := $TextureRect
@onready var logo := $Logo
@onready var play_btn := $VBoxContainer/ButtonPlay as TextureButton
@onready var settings_btn := $VBoxContainer/ButtonSettings as TextureButton
@onready var quit_btn := $VBoxContainer/ButtonQuit as TextureButton
@onready var discord_btn := $DiscordButton as Button
@onready var dark_mode_btn := $TextureRect/DarkModeButton as Button

var extra := 60.0
var max_move := 25.0
var _achievements_panel: Control = null
var _achievements_btn: Button = null

const ACHIEVEMENTS := [
	{"id": "completed_game", "name": "Thanks for Playing", "desc": "Complete the game"},
	{"id": "no_damage_run", "name": "Perfect Run", "desc": "Complete the game without taking damage"},
	{"id": "dark_mode_clear", "name": "Hope for a Bright Future", "desc": "Complete the game in dark mode"},
	{"id": "dark_mode_no_damage", "name": "That Was Easy", "desc": "Complete the game in dark mode without taking damage"},
]

func _ready() -> void:
	CursorManager.setup_buttons(self)
	_animate_logo()
	bg.offset_left -= extra
	bg.offset_top -= extra
	bg.offset_right += extra
	bg.offset_bottom += extra

	# Увеличиваем кнопки в 1.5 раза
	play_btn.scale = Vector2(1.5, 1.5)
	settings_btn.scale = Vector2(1.5, 1.5)
	quit_btn.scale = Vector2(1.5, 1.5)

	_setup_discord_button()
	_setup_dark_mode_button()
	_setup_achievements_button()
	play_btn.grab_focus.call_deferred()

func _setup_discord_button() -> void:
	var discord_tex = preload("res://Assets/discord_macos_bigsur_icon_190238.webp")
	discord_btn.icon = discord_tex
	discord_btn.custom_minimum_size = Vector2(80, 80)
	discord_btn.size = Vector2(80, 80)
	discord_btn.expand_icon = true
	discord_btn.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	discord_btn.anchor_left = 1.0
	discord_btn.anchor_top = 1.0
	discord_btn.anchor_right = 1.0
	discord_btn.anchor_bottom = 1.0
	discord_btn.offset_left = -90.0
	discord_btn.offset_top = -90.0
	discord_btn.offset_right = -10.0
	discord_btn.offset_bottom = -10.0
	discord_btn.visible = true

func _animate_logo() -> void:
	var tw = create_tween().set_loops()
	var start_y = logo.position.y
	tw.tween_property(logo, "position:y", start_y + 15, 2.5).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(logo, "position:y", start_y, 2.5).set_ease(Tween.EASE_IN_OUT)
	tw.tween_interval(2.0)

func _process(_delta: float) -> void:
	var center := get_viewport_rect().size * 0.5
	var mouse := get_global_mouse_position()
	var rel := (mouse - center) / center
	var dx := -rel.x * max_move
	var dy := -rel.y * max_move

	bg.offset_left = -extra + dx
	bg.offset_top = -extra + dy
	bg.offset_right = extra + dx
	bg.offset_bottom = extra + dy

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func _play_click() -> void:
	var cs = get_node_or_null("ClickSound")
	if cs:
		cs.play()

func _on_play_pressed() -> void:
	_play_click()
	GameState.dark_mode = false
	GameState.current_floor = 1
	GameState.has_bucket = false
	GameState.has_collar = false
	GameState.currency = 0
	GameState.last_floor_hp = 0
	GameState.took_damage_this_run = false
	StyleManager.reset_score()
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://Scenes/Game/start.tscn")

func _on_settings_pressed() -> void:
	_play_click()
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://Scenes/Settings/Settings.tscn")

func _on_discord_button_pressed() -> void:
	OS.shell_open("https://discord.gg/3p8UC7txYK")

func _setup_dark_mode_button() -> void:
	if OS.is_debug_build():
		dark_mode_btn.modulate = Color(1, 1, 1, 0.3)

func _setup_achievements_button() -> void:
	_achievements_btn = Button.new()
	_achievements_btn.text = "Achievements"
	_achievements_btn.custom_minimum_size = Vector2(140, 40)
	_achievements_btn.anchors_preset = Control.PRESET_BOTTOM_LEFT
	_achievements_btn.anchor_left = 0.0
	_achievements_btn.anchor_top = 1.0
	_achievements_btn.anchor_right = 0.0
	_achievements_btn.anchor_bottom = 1.0
	_achievements_btn.offset_left = 10.0
	_achievements_btn.offset_top = -50.0
	_achievements_btn.offset_right = 150.0
	_achievements_btn.offset_bottom = -10.0
	_achievements_btn.pressed.connect(_on_achievements_pressed)
	add_child(_achievements_btn)

func _on_achievements_pressed() -> void:
	_play_click()
	if _achievements_panel:
		_achievements_panel.queue_free()
		_achievements_panel = null
		return
	_achievements_panel = Control.new()
	_achievements_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_achievements_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_achievements_panel)
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_achievements_panel.add_child(overlay)
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -250
	panel.offset_top = -200
	panel.offset_right = 250
	panel.offset_bottom = 200
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_achievements_panel.add_child(panel)
	var title := Label.new()
	title.text = "ACHIEVEMENTS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 10)
	title.size = Vector2(500, 35)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.GOLD)
	panel.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.position = Vector2(190, 355)
	close_btn.size = Vector2(100, 30)
	close_btn.pressed.connect(_on_achievements_close)
	panel.add_child(close_btn)
	var y := 55
	for ach in ACHIEVEMENTS:
		var unlocked = GameState.is_achievement_unlocked(ach["id"])
		var row := HBoxContainer.new()
		row.position = Vector2(20, y)
		row.size = Vector2(460, 50)
		row.add_theme_constant_override("separation", 12)
		panel.add_child(row)
		var icon := Label.new()
		icon.text = "[x]" if unlocked else "[ ]"
		icon.add_theme_font_size_override("font_size", 20)
		icon.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3) if unlocked else Color(0.5, 0.5, 0.5))
		icon.custom_minimum_size = Vector2(30, 0)
		row.add_child(icon)
		var info := VBoxContainer.new()
		info.add_theme_constant_override("separation", 2)
		row.add_child(info)
		var name_label := Label.new()
		name_label.text = ach["name"]
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.add_theme_color_override("font_color", Color.WHITE if unlocked else Color(0.6, 0.6, 0.6))
		info.add_child(name_label)
		var desc_label := Label.new()
		desc_label.text = ach["desc"]
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7) if unlocked else Color(0.4, 0.4, 0.4))
		info.add_child(desc_label)
		y += 55
	panel.size.y = y + 55

func _on_achievements_close() -> void:
	if _achievements_panel:
		_achievements_panel.queue_free()
		_achievements_panel = null

func _on_dark_mode_pressed() -> void:
	_play_click()
	GameState.dark_mode = true
	GameState.current_floor = 1
	GameState.has_bucket = false
	GameState.has_collar = false
	GameState.currency = 0
	GameState.last_floor_hp = 0
	GameState.took_damage_this_run = false
	StyleManager.reset_score()
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://Scenes/Game/start.tscn")
