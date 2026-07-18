extends Control

@onready var bg := $TextureRect
@onready var logo := $Logo
@onready var play_btn := $VBoxContainer/ButtonPlay as TextureButton
@onready var settings_btn := $VBoxContainer/ButtonSettings as TextureButton
@onready var quit_btn := $VBoxContainer/ButtonQuit as TextureButton
@onready var discord_btn := $DiscordButton as Button

var extra := 60.0
var max_move := 25.0

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
	GameState.current_floor = 1
	GameState.has_bucket = false
	GameState.has_collar = false
	GameState.currency = 0
	GameState.last_floor_hp = 0
	StyleManager.reset_score()
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://Scenes/Game/start.tscn")

func _on_settings_pressed() -> void:
	_play_click()
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://Scenes/Settings/Settings.tscn")

func _on_discord_button_pressed() -> void:
	OS.shell_open("https://discord.gg/3p8UC7txYK")
