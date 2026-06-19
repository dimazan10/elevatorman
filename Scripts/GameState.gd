extends Node

var current_floor: int = 1
var master_volume: float = 0.0
var music_volume: float = 0.0

func _ready() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), master_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), music_volume)

func set_master_volume(db: float) -> void:
	master_volume = db
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func set_music_volume(db: float) -> void:
	music_volume = db
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)
