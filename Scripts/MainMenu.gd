extends Control

@onready var bg := $TextureRect
var extra := 60.0
var max_move := 25.0

func _ready() -> void:
	scale = Vector2(GameState.ui_scale, GameState.ui_scale)
	bg.offset_left -= extra
	bg.offset_top -= extra
	bg.offset_right += extra
	bg.offset_bottom += extra
	for b in get_tree().get_nodes_in_group("menu_buttons"):
		_setup_hover(b)

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

func _setup_hover(b: TextureButton) -> void:
	b.mouse_entered.connect(func():
		var t := create_tween()
		t.tween_property(b, "scale", Vector2(1.2, 1.2), 0.1)
	)
	b.mouse_exited.connect(func():
		var t := create_tween()
		t.tween_property(b, "scale", Vector2(1.0, 1.0), 0.1)
	)

func _play_click() -> void:
	var cs = get_node_or_null("ClickSound")
	if cs:
		cs.play()

func _on_play_pressed() -> void:
	_play_click()
	GameState.current_floor = 1
	GameState.has_bucket = false
	GameState.currency = 0
	GameState.last_floor_hp = 0
	StyleManager.reset_score()
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://Scenes/Game/start.tscn")

func _on_settings_pressed() -> void:
	_play_click()
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://Scenes/Settings/Settings.tscn")
