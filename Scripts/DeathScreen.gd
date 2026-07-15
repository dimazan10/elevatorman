extends CanvasLayer

func _ready():
	$DeathAnimation.play("death")
	$RestartButton.pressed.connect(_on_restart)

func _on_restart():
	get_tree().paused = false
	get_tree().reload_current_scene()
