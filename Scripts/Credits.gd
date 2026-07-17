extends CanvasLayer

var _exiting := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var timer := $Timer as Timer
	timer.timeout.connect(_go_to_menu)
	timer.start()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not _exiting:
		_go_to_menu()

func _go_to_menu() -> void:
	if _exiting:
		return
	_exiting = true
	get_tree().change_scene_to_file("res://Scenes/MainMenu/MainMenu.tscn")
