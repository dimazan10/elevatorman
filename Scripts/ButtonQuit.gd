extends TextureButton

func _on_pressed() -> void:
	var mm = get_tree().current_scene
	if mm and mm.has_node("ClickSound"):
		mm.get_node("ClickSound").play()
	get_tree().quit()
