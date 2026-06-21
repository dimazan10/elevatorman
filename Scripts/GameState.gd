extends Node

const SAVE_PATH := "user://settings.cfg"

var current_floor: int = 1
var master_volume: float = 0.0
var music_volume: float = 0.0
var effects_volume: float = 0.0
var show_fps: bool = false

func _ready() -> void:
	_load_settings()

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	var err = cfg.load(SAVE_PATH)
	if err != OK:
		return
	master_volume = cfg.get_value("audio", "master_volume", 0.0)
	music_volume = cfg.get_value("audio", "music_volume", 0.0)
	effects_volume = cfg.get_value("audio", "effects_volume", 0.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), master_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), music_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"), effects_volume)
	current_floor = 1
	show_fps = cfg.get_value("display", "show_fps", false)

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "effects_volume", effects_volume)
	cfg.set_value("game", "current_floor", current_floor)
	cfg.set_value("display", "show_fps", show_fps)
	cfg.save(SAVE_PATH)

func set_master_volume(db: float) -> void:
	master_volume = db
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	_save_settings()

func set_music_volume(db: float) -> void:
	music_volume = db
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)
	_save_settings()

func set_effects_volume(db: float) -> void:
	effects_volume = db
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"), db)
	_save_settings()

func set_show_fps(enabled: bool) -> void:
	show_fps = enabled
	_save_settings()
