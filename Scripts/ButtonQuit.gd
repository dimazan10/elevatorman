extends TextureButton

# У этой функции на полях ОБЯЗАТЕЛЬНО должен гореть зеленый значок штекера
func _on_pressed() -> void:
	get_tree().quit() # Перенесли код сюда, не забыв отступ (Tab)
