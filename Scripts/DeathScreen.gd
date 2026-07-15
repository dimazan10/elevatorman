extends CanvasLayer

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Control/RestartButton.pressed.connect(_on_restart)

func _on_restart():
	get_tree().paused = false
	get_tree().reload_current_scene()
