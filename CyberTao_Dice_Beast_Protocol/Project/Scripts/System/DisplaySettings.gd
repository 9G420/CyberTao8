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
	# 延迟一帧应用，确保引擎窗口系统完全初始化
	call_deferred("apply_settings")

func apply_settings() -> void:
	if not is_inside_tree():
		return
	var root: Window = get_tree().root
	if root == null:
		return

	# 1) 无论目标模式是什么，先强制回退到普通窗口模式
	#    解决从全屏/无边框切换到其他模式时 DisplayServer 忽略后续操作的问题
	var prev_mode: int = DisplayServer.window_get_mode()
	if prev_mode != DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)

	# 2) 更新视口虚拟分辨率（canvas_items 拉伸模式下控制渲染精度）
	root.content_scale_size = current_resolution

	# 3) 按目标模式应用
	match current_mode:
		0: # 窗口化
			DisplayServer.window_set_size(current_resolution)
			_center_window()
		1: # 全屏
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2: # 无边框窗口
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_size(current_resolution)
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
