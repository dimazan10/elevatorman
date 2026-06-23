extends Node

var _cursor_default: Texture2D
var _cursor_hover: Texture2D

func _ready() -> void:
	_cursor_default = _load_cursor("res://Assets/MainMenu/Crossed_0.png")
	_cursor_hover = _load_cursor("res://Assets/MainMenu/Crossed_1.png")
	Input.set_custom_mouse_cursor(_cursor_default)

func setup_buttons(root: Node) -> void:
	for c in root.get_children():
		if c is BaseButton:
			_setup_hover(c)
		setup_buttons(c)

func _load_cursor(path: String) -> Texture2D:
	var tex = load(path) as Texture2D
	if not tex:
		return null
	var img = tex.get_image()
	var scale = 0.07
	img.resize(max(1, int(img.get_width() * scale)), max(1, int(img.get_height() * scale)), Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)

func _setup_hover(b: BaseButton) -> void:
	b.mouse_entered.connect(func():
		Input.set_custom_mouse_cursor(_cursor_hover)
		if b is Control:
			var t := (b as Control).create_tween()
			t.tween_property(b, "scale", Vector2(1.2, 1.2), 0.1)
	)
	b.mouse_exited.connect(func():
		Input.set_custom_mouse_cursor(_cursor_default)
		if b is Control:
			var t := (b as Control).create_tween()
			t.tween_property(b, "scale", Vector2(1.0, 1.0), 0.1)
	)
