
extends Node

const GROUP_MANAGED := "cursor_managed"

var _cursor_default: Texture2D
var _cursor_hover: Texture2D

func _ready() -> void:
	_cursor_default = _load_cursor("res://Assets/MainMenu/Crossed_0.png")
	_cursor_hover = _load_cursor("res://Assets/MainMenu/Crossed_1.png")
	Input.set_custom_mouse_cursor(_cursor_default)

	# Setup existing buttons in the current scene tree so cursors react everywhere
	setup_buttons(get_tree().get_root())
	# Watch for future buttons added at runtime
	get_tree().connect("node_added", Callable(self, "_on_node_added"))

func setup_buttons(root: Node) -> void:
	if not root:
		return
	# check the root itself
	if root is BaseButton:
		_setup_hover(root)
	for c in root.get_children():
		if c is Node:
			setup_buttons(c)

func _on_node_added(node: Node) -> void:
	# When nodes are added at runtime, ensure any BaseButton gets the hover setup
	if node is BaseButton:
		_setup_hover(node)
	# Also handle any BaseButton children that may come with the node
	for c in node.get_children():
		if c is BaseButton:
			_setup_hover(c)
		elif c is Node:
			_on_node_added(c)

func _load_cursor(path: String) -> Texture2D:
	var tex = load(path) as Texture2D
	if not tex:
		return null
	var img = tex.get_image()
	var scale = 0.07
	img.resize(max(1, int(img.get_width() * scale)), max(1, int(img.get_height() * scale)), Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)

func _setup_hover(b: BaseButton) -> void:
	# Avoid connecting the same button multiple times
	if b.is_in_group(GROUP_MANAGED):
		return
	b.add_to_group(GROUP_MANAGED)

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
