extends Control

const HEX_RADIUS := 14.0
const LINE_WIDTH := 2.0
const BG_COLOR := Color(0, 0, 0, 0.3)

var _arena_positions: Array[Vector2] = []
var _arena_colors: Array[Color] = []
var _corridors: Array = []
var _closest_idx := 0
var _scale := 0.01
var _offset := Vector2.ZERO
var _player: Node2D = null

func setup(positions: Array[Vector2], colors: Array[Color], corridors: Array, player: Node2D) -> void:
	_arena_positions = positions
	_arena_colors = colors
	_corridors = corridors
	_player = player
	_calc_scale_and_offset()
	_update_closest()
	queue_redraw()

func _process(_delta: float) -> void:
	_update_closest()

func _update_closest() -> void:
	if _player == null or _arena_positions.is_empty():
		return
	var player_pos := _player.global_position
	var best := 0
	var best_dist := player_pos.distance_squared_to(_arena_positions[0])
	for i in range(1, _arena_positions.size()):
		var dist := player_pos.distance_squared_to(_arena_positions[i])
		if dist < best_dist:
			best_dist = dist
			best = i
	if best != _closest_idx:
		_closest_idx = best
		queue_redraw()

func _calc_scale_and_offset() -> void:
	if _arena_positions.size() < 2:
		_scale = 0.01
		_offset = Vector2.ZERO
		return
	var min_pos := _arena_positions[0]
	var max_pos := _arena_positions[0]
	for p in _arena_positions:
		min_pos.x = min(min_pos.x, p.x)
		min_pos.y = min(min_pos.y, p.y)
		max_pos.x = max(max_pos.x, p.x)
		max_pos.y = max(max_pos.y, p.y)
	var range_vec := max_pos - min_pos
	var max_range := maxf(range_vec.x, range_vec.y)
	_offset = (min_pos + max_pos) * 0.5
	if max_range > 0:
		_scale = (minf(size.x, size.y) - 40.0) / max_range
	else:
		_scale = 0.01

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)
	var center := size * 0.5

	for conn in _corridors:
		var from_pos := center + (_arena_positions[conn[0]] - _offset) * _scale
		var to_pos := center + (_arena_positions[conn[1]] - _offset) * _scale
		draw_line(from_pos, to_pos, Color(0.5, 0.5, 0.5, 0.6), LINE_WIDTH)

	for i in _arena_positions.size():
		var pos := center + (_arena_positions[i] - _offset) * _scale
		_draw_hex(pos, HEX_RADIUS, _arena_colors[i], i == _closest_idx)

func _draw_hex(c: Vector2, radius: float, color: Color, highlight: bool) -> void:
	var pts: PackedVector2Array
	for i in 6:
		var angle := deg_to_rad(60 * i - 30)
		pts.append(c + Vector2(cos(angle), sin(angle)) * radius)
	var draw_color := color.lightened(0.3) if highlight else color * Color(1, 1, 1, 0.6)
	draw_colored_polygon(pts, draw_color)
	var outline := color.darkened(0.4)
	outline.a = 1.0
	for i in 6:
		draw_line(pts[i], pts[(i + 1) % 6], outline, 1.5)
