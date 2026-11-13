extends Node

const SAVE_PATH = "user://settings.cfg"
var config: ConfigFile = ConfigFile.new()

func _ready() -> void:
	config.load(SAVE_PATH)
	var fullscreen = config.get_value("display", "fullscreen", false)
	
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	for bus_name in ["SFX", "Music"]:
		var id = AudioServer.get_bus_index(bus_name)
		var value = config.get_value("audio", bus_name, 1.0)
		AudioServer.set_bus_volume_db(id, linear_to_db(value))

func get_setting(section, key, default):
	return config.get_value(section, key, default)

func set_setting(section, key, value):
	config.set_value(section, key, value)

func save():
	config.save(SAVE_PATH)
