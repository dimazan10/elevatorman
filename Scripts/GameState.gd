extends Node

const SAVE_PATH := "user://settings.cfg"

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

var current_floor: int = 1
var master_volume: float = 0.0
var music_volume: float = 0.0
var effects_volume: float = 0.0
var show_fps: bool = false
var use_mobile_controls: bool = false
var fullscreen: bool = true
var resolution_index: int = 2
var has_bucket: bool = false
var bucket_charges: int = 2
var has_collar: bool = false
var collar_charges: int = 3
var currency: int = 0
var last_floor_hp: int = 0
var last_floor_time: float = 0.0
var death_counts: Dictionary = {}
var inventory: Array[Dictionary] = [
	{id = "", icon = null, name = ""},
	{id = "", icon = null, name = ""},
]
var dark_mode: bool = false

func add_death(floor_num: int) -> int:
	if not death_counts.has(floor_num):
		death_counts[floor_num] = 0
	death_counts[floor_num] += 1
	return death_counts[floor_num]

func get_deaths(floor_num: int) -> int:
	return death_counts.get(floor_num, 0)

func _ready() -> void:
	_load_settings()
	_apply_resolution()

func _apply_resolution() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, true)
	var res: Vector2i = RESOLUTIONS[resolution_index]
	DisplayServer.window_set_size(res)

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
	use_mobile_controls = cfg.get_value("display", "use_mobile_controls", false)
	fullscreen = cfg.get_value("display", "fullscreen", true)
	resolution_index = cfg.get_value("display", "resolution_index", 2)

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "effects_volume", effects_volume)
	cfg.set_value("display", "show_fps", show_fps)
	cfg.set_value("display", "use_mobile_controls", use_mobile_controls)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "resolution_index", resolution_index)
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

func set_mobile_controls(enabled: bool) -> void:
	use_mobile_controls = enabled
	_save_settings()

func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_resolution()
	_save_settings()

func set_resolution(index: int) -> void:
	resolution_index = index
	_apply_resolution()
	_save_settings()
