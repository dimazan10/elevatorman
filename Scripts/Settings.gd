extends Control

signal back_pressed

var return_to_game := false

@onready var master_slider := $VBoxContainer/MasterHSlider as HSlider
@onready var master_label := $VBoxContainer/MasterPct as Label
@onready var music_slider := $VBoxContainer/MusicHSlider as HSlider
@onready var music_label := $VBoxContainer/MusicPct as Label
@onready var effects_slider := $VBoxContainer/EffectsHSlider as HSlider
@onready var effects_label := $VBoxContainer/EffectsPct as Label

@onready var fps_checkbox := $VBoxContainer/FPSCheckbox as CheckBox

func _ready() -> void:
	master_slider.value = GameState.master_volume
	master_label.text = _db_to_pct(GameState.master_volume)
	music_slider.value = GameState.music_volume
	music_label.text = _db_to_pct(GameState.music_volume)
	effects_slider.value = GameState.effects_volume
	effects_label.text = _db_to_pct(GameState.effects_volume)
	fps_checkbox.button_pressed = GameState.show_fps

func _on_master_slider_value_changed(value: float) -> void:
	GameState.set_master_volume(value)
	master_label.text = _db_to_pct(value)

func _on_music_slider_value_changed(value: float) -> void:
	GameState.set_music_volume(value)
	music_label.text = _db_to_pct(value)

func _on_effects_slider_value_changed(value: float) -> void:
	GameState.set_effects_volume(value)
	effects_label.text = _db_to_pct(value)

func _on_fps_checkbox_toggled(enabled: bool) -> void:
	GameState.set_show_fps(enabled)
	var fps_label = get_tree().get_first_node_in_group("fps_label")
	if fps_label:
		fps_label.visible = enabled

func _on_back_pressed() -> void:
	if return_to_game:
		back_pressed.emit()
	else:
		get_tree().change_scene_to_file("res://Scenes/MainMenu/MainMenu.tscn")

func _db_to_pct(db: float) -> String:
	var pct = roundi((db + 40.0) / 40.0 * 100.0)
	return str(clampi(pct, 0, 100)) + "%"
