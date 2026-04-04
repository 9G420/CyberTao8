extends Control
class_name UnitPortraitHUD

## 顶部单位头像 HUD（v0.1.69）
## 横排显示各方单位头像 + HP 条 + 名称，点击切换镜头
## 玩家单位左侧，敌方单位右侧

const PORTRAIT_W: float = 56.0
const PORTRAIT_H: float = 52.0
const PORTRAIT_GAP: float = 6.0
const BAR_Y: float = 46.0
const BAR_H: float = 4.0
const PLAYER_START_X: float = 90.0   # 避开左上角设置按钮
const ENEMY_END_X: float = 1280.0
const TOP_Y: float = 0.0

var _unit_manager: Node = null
var _portraits: Array = []  # Array of { id, rect, owner }
var _selected_id: String = ""
var _hover_id: String = ""

signal portrait_clicked(unit_id: String)

func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(1280, PORTRAIT_H + 4)
	mouse_filter = Control.MOUSE_FILTER_PASS

func bind_unit_manager(um: Node) -> void:
	_unit_manager = um
	if _unit_manager.has_signal("units_changed"):
		if not _unit_manager.units_changed.is_connected(_on_units_changed):
			_unit_manager.units_changed.connect(_on_units_changed)
	rebuild()

func set_selected(unit_id: String) -> void:
	if _selected_id != unit_id:
		_selected_id = unit_id
		queue_redraw()

func rebuild() -> void:
	_portraits.clear()
	if _unit_manager == null:
		queue_redraw()
		return
	var player_ids: Array = []
	var enemy_ids: Array = []
	for uid in _unit_manager.units_by_id.keys():
		var unit: Dictionary = _unit_manager.units_by_id[uid]
		if String(unit.get("owner", "")) == "player":
			var unit_id: String = String(uid)
			if _unit_manager.has_method("is_player_hero_unit") and not _unit_manager.is_player_hero_unit(unit_id):
				continue
			player_ids.append(unit_id)
		else:
			enemy_ids.append(String(uid))
	# 玩家单位从左排列
	var px: float = PLAYER_START_X
	for uid in player_ids:
		var r: Rect2 = Rect2(px, TOP_Y, PORTRAIT_W, PORTRAIT_H)
		_portraits.append({"id": uid, "rect": r, "owner": "player"})
		px += PORTRAIT_W + PORTRAIT_GAP
	# 敌方单位从右排列
	var ex: float = ENEMY_END_X - PORTRAIT_W - 8.0
	for i in range(enemy_ids.size() - 1, -1, -1):
		var uid: String = enemy_ids[i]
		var r: Rect2 = Rect2(ex, TOP_Y, PORTRAIT_W, PORTRAIT_H)
		_portraits.append({"id": uid, "rect": r, "owner": "enemy"})
		ex -= PORTRAIT_W + PORTRAIT_GAP
	queue_redraw()

func _on_units_changed() -> void:
	rebuild()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos: Vector2 = event.position
		for p in _portraits:
			if p["rect"].has_point(pos):
				emit_signal("portrait_clicked", p["id"])
				return
	if event is InputEventMouseMotion:
		var pos: Vector2 = event.position
		var new_hover: String = ""
		for p in _portraits:
			if p["rect"].has_point(pos):
				new_hover = p["id"]
				break
		if new_hover != _hover_id:
			_hover_id = new_hover
			queue_redraw()

func _draw() -> void:
	if _unit_manager == null or _portraits.is_empty():
		return
	# 半透明背景条
	draw_rect(Rect2(0, 0, 1280, PORTRAIT_H + 4), Color(0.01, 0.01, 0.04, 0.55))
	draw_line(Vector2(0, PORTRAIT_H + 4), Vector2(1280, PORTRAIT_H + 4), Color(0.0, 0.5, 0.7, 0.2), 1.0)
	var font: Font = get_theme_default_font()
	for p in _portraits:
		var uid: String = p["id"]
		var rect: Rect2 = p["rect"]
		var unit: Dictionary = _unit_manager.get_unit(uid)
		if unit.is_empty():
			continue
		var is_player: bool = String(unit.get("owner", "")) == "player"
		var is_selected: bool = uid == _selected_id
		var is_hover: bool = uid == _hover_id
		# 背景框
		var bg_col: Color
		if is_selected:
			bg_col = Color(0.0, 0.6, 0.9, 0.25)
		elif is_hover:
			bg_col = Color(0.0, 0.5, 0.7, 0.15)
		else:
			bg_col = Color(0.02, 0.02, 0.06, 0.4)
		draw_rect(rect, bg_col)
		var border_col: Color = CyberStyle.ACCENT_CYAN if is_player else CyberStyle.HP_ENEMY
		if is_selected:
			border_col = Color(border_col.r, border_col.g, border_col.b, 0.9)
		else:
			border_col = Color(border_col.r, border_col.g, border_col.b, 0.4)
		draw_rect(rect, border_col, false, 1.0)
		# 角色迷你头像（缩小版）
		var char_center: Vector2 = Vector2(rect.position.x + PORTRAIT_W * 0.5, rect.position.y + 22.0)
		var char_scale: float = 0.45
		if is_player:
			UnitRenderer._draw_player_char(self, char_center, char_scale, "", 0.5)
		else:
			var display_name: String = String(unit.get("display_name", ""))
			UnitRenderer._draw_enemy_char(self, char_center, char_scale, display_name, 0.5)
		# HP 条
		var hp: int = int(unit.get("hp", 1))
		var max_hp: int = int(unit.get("max_hp", 1))
		var hp_ratio: float = float(hp) / float(max_hp) if max_hp > 0 else 1.0
		var bar_x: float = rect.position.x + 4.0
		var bar_w: float = PORTRAIT_W - 8.0
		var bar_y: float = rect.position.y + BAR_Y
		draw_rect(Rect2(bar_x, bar_y, bar_w, BAR_H), Color(0.1, 0.1, 0.15, 0.8))
		var hp_col: Color
		if hp_ratio > 0.6:
			hp_col = CyberStyle.HP_PLAYER if is_player else Color(0.9, 0.25, 0.2)
		elif hp_ratio > 0.3:
			hp_col = Color(0.95, 0.75, 0.15)
		else:
			hp_col = Color(1.0, 0.2, 0.15)
		draw_rect(Rect2(bar_x, bar_y, bar_w * hp_ratio, BAR_H), hp_col)
		# 名称标签（底部小字）— 只显示缩写
		var display_name: String = String(unit.get("display_name", "?"))
		if display_name.length() > 4:
			display_name = display_name.substr(0, 4)
		var name_col: Color = CyberStyle.TEXT_SECONDARY if not is_selected else CyberStyle.TEXT_PRIMARY
		draw_string(font, Vector2(rect.position.x + 2, rect.position.y + PORTRAIT_H - 1), display_name, HORIZONTAL_ALIGNMENT_LEFT, PORTRAIT_W - 4, 8, name_col)
