extends TextureButton

func _on_pressed() -> void:
	var mm = get_tree().current_scene
	if mm and mm.has_node("ClickSound"):
		mm.get_node("ClickSound").play()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()
