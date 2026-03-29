extends Node
class_name DisplaySettings

const SETTINGS_PATH: String = "user://display_settings.cfg"

const RESOLUTIONS: Array = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

const DEFAULT_RESOLUTION: Vector2i = Vector2i(1280, 720)
const DEFAULT_MODE: int = 0 # 0=windowed, 1=fullscreen, 2=borderless

var current_resolution: Vector2i = DEFAULT_RESOLUTION
var current_mode: int = DEFAULT_MODE

func _ready() -> void:
	load_settings()
	apply_settings()

func apply_settings() -> void:
	# 更新视口虚拟分辨率，使不同分辨率有真实视觉变化
	var root: Window = null
	if get_tree():
		root = get_tree().root
	if root:
		root.content_scale_size = Vector2i(current_resolution.x, current_resolution.y)
	match current_mode:
		0: # Windowed
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_size(Vector2i(current_resolution.x, current_resolution.y))
			_center_window()
		1: # Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2: # Borderless windowed
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_size(Vector2i(current_resolution.x, current_resolution.y))
			_center_window()

func _center_window() -> void:
	var screen_size: Vector2i = DisplayServer.screen_get_size()
	var win_size: Vector2i = DisplayServer.window_get_size()
	var pos_x: int = (screen_size.x - win_size.x) / 2
	var pos_y: int = (screen_size.y - win_size.y) / 2
	DisplayServer.window_set_position(Vector2i(pos_x, pos_y))

func save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("display", "resolution_x", current_resolution.x)
	config.set_value("display", "resolution_y", current_resolution.y)
	config.set_value("display", "mode", current_mode)
	config.save(SETTINGS_PATH)

func load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: int = config.load(SETTINGS_PATH)
	if err != OK:
		return
	current_resolution.x = int(config.get_value("display", "resolution_x", DEFAULT_RESOLUTION.x))
	current_resolution.y = int(config.get_value("display", "resolution_y", DEFAULT_RESOLUTION.y))
	current_mode = int(config.get_value("display", "mode", DEFAULT_MODE))

func reset_to_defaults() -> void:
	current_resolution = DEFAULT_RESOLUTION
	current_mode = DEFAULT_MODE
