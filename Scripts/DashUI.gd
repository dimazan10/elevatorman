extends CanvasLayer

const MAX_CHARGES := 3
const COOLDOWN_TIME := 4.0

var bars: Array[ColorRect] = []
var bar_tweens: Array[Tween] = []

@onready var container: Control = $DashContainer

func _ready() -> void:
	for child in container.get_children():
		if child is ColorRect:
			bars.append(child)
			child.modulate = Color(1, 1, 1, 1)
	bar_tweens.resize(MAX_CHARGES)
	container.modulate = Color(1, 1, 1, 0)

	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.dash_used.connect(_on_dash_used)

func _on_dash_used(index: int) -> void:
	if index < 0 or index >= MAX_CHARGES:
		return
	if bar_tweens[index]:
		bar_tweens[index].kill()

	var bar := bars[index]
	bar_tweens[index] = create_tween().set_parallel(false)
	bar_tweens[index].tween_property(bar, "modulate:a", 0.0, 0.15)
	bar_tweens[index].tween_property(bar, "modulate:a", 1.0, COOLDOWN_TIME - 0.55)
	bar_tweens[index].tween_property(bar, "modulate", Color(5, 5, 5, 1), 0.08)
	bar_tweens[index].tween_property(bar, "modulate", Color(1, 1, 1, 1), 0.12)
	bar_tweens[index].tween_property(bar, "modulate", Color(5, 5, 5, 1), 0.08)
	bar_tweens[index].tween_property(bar, "modulate", Color(1, 1, 1, 1), 0.12)

func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return

	var any_cooldown := false
	for i in range(MAX_CHARGES):
		if player.dash_cooldowns[i] > 0:
			any_cooldown = true
			break

	var target := 1.0 if any_cooldown else 0.0
	container.modulate = container.modulate.lerp(Color(1, 1, 1, target), delta * 8.0)
