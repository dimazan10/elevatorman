
extends Node

const GROUP_MANAGED := "cursor_managed"
const VISIBLE_SCENES := ["MainMenu", "Settings", "Shop"]

var _cursor_default: Texture2D
var _cursor_hover: Texture2D

func _ready() -> void:
	_cursor_default = _load_cursor("res://Assets/MainMenu/Crossed_0.png")
	_cursor_hover = _load_cursor("res://Assets/MainMenu/Crossed_1.png")
	Input.set_custom_mouse_cursor(_cursor_default)
	# Ensure the OS cursor is visible in gameplay (some systems/scenes may hide/capture it)
	# We'll set visible here; if a scene explicitly needs capture it can override this.
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Setup existing buttons in the current scene tree so cursors react everywhere
	setup_buttons(get_tree().get_root())
	# Watch for future buttons added/removed at runtime
	get_tree().connect("node_added", Callable(self, "_on_node_added"))
	get_tree().connect("node_removed", Callable(self, "_on_node_removed"))

	# Set initial mouse visibility according to current scenes
	_update_mouse_visibility()

func setup_buttons(root: Node) -> void:
	if not root:
		return
	# check the root itself
	if _is_interactive(root):
		_setup_hover(root)
	for c in root.get_children():
		if c is Node:
			setup_buttons(c)

func _on_node_added(node: Node) -> void:
	# When nodes are added at runtime, ensure interactive controls get the hover setup
	if _is_interactive(node):
		_setup_hover(node)
	# Also handle any interactive children that may come with the node
	for c in node.get_children():
		if c is Node:
			_on_node_added(c)

	# Update mouse visibility when scenes/nodes change
	_update_mouse_visibility()

func _on_node_removed(node: Node) -> void:
	# Update visibility when nodes are removed
	_update_mouse_visibility()

func _update_mouse_visibility() -> void:
	var root := get_tree().get_root()
	if _has_allowed_scene(root):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _has_allowed_scene(node: Node) -> bool:
	if not node:
		return false
	# If the node itself matches an allowed scene name
	if node.name in VISIBLE_SCENES:
		return true
	for c in node.get_children():
		if c is Node and _has_allowed_scene(c):
			return true
	return false

func _load_cursor(path: String) -> Texture2D:
	var tex = load(path) as Texture2D
	if not tex:
		return null
	var img = tex.get_image()
	var scale = 0.07
	img.resize(max(1, int(img.get_width() * scale)), max(1, int(img.get_height() * scale)), Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)

func _setup_hover(b: Control) -> void:
	# Avoid connecting the same button multiple times
	if b.is_in_group(GROUP_MANAGED):
		return
	b.add_to_group(GROUP_MANAGED)
	# Decide per-button whether scaling on hover is allowed.
	# We disable scaling for buttons that belong to scenes where resizing on hover isn't wanted
	var do_scale := _should_scale(b)

	b.mouse_entered.connect(func(do_scale = do_scale):
		Input.set_custom_mouse_cursor(_cursor_hover)
		if do_scale and b is Control:
			var t := (b as Control).create_tween()
			t.tween_property(b, "scale", Vector2(1.2, 1.2), 0.1)
	)
	b.mouse_exited.connect(func(do_scale = do_scale):
		Input.set_custom_mouse_cursor(_cursor_default)
		if do_scale and b is Control:
			var t := (b as Control).create_tween()
			t.tween_property(b, "scale", Vector2(1.0, 1.0), 0.1)
	)

func _get_scene_root(node: Node) -> Node:
	# Return the top-most ancestor whose parent is the SceneTree root.
	# This helps identify which scene the node belongs to.
	var p := node
	var rt := get_tree().get_root()
	while p and p.get_parent() and p.get_parent() != rt:
		p = p.get_parent()
	return p

func _should_scale(b: Control) -> bool:
	var scene_root := _get_scene_root(b)
	if not scene_root:
		return true
	# Disable scaling for MainMenu and Settings scenes per request
	var name := scene_root.name
	if name == "MainMenu" or name == "Settings":
		return false
	return true

func _is_interactive(node: Node) -> bool:
	# Recognize interactive UI elements: BaseButton and Range (HSlider/VSlider)
	if node is BaseButton:
		return true
	if node is Range:
		# Range covers HSlider/VSlider and others that receive mouse_entered/exited
		return true
	return false
