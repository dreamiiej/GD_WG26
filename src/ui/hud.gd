extends CanvasLayer
## HUD（明日方舟风格）。左上角显示干员状态（等级/经验/血量/波次/计时），
## 下方为技能列表（显示当前升级后已选择的技能），顶部为精英/BOSS 血条。
## v2 M8：重构为方舟式暗色技术面板，新增技能列表与血量/经验条可视化。

@onready var _lv_value: Label = $Root/StatusCard/LvValue
@onready var _exp_fill: ColorRect = $Root/StatusCard/ExpBarBg/ExpBarFill
@onready var _exp_text: Label = $Root/StatusCard/ExpText
@onready var _hp_fill: ColorRect = $Root/StatusCard/HpBarBg/HpBarFill
@onready var _hp_text: Label = $Root/StatusCard/HpText
@onready var _wave_value: Label = $Root/StatusCard/WaveValue
@onready var _time_value: Label = $Root/StatusCard/TimeValue
@onready var _elite_notice: Label = $Root/StatusCard/EliteNotice
@onready var _elite_bar: Control = $EliteBar
@onready var _elite_name: Label = $EliteBar/NameLabel
@onready var _elite_fill: ColorRect = $EliteBar/FillBar/Fill
@onready var _skill_list: VBoxContainer = $Root/SkillsCard/SkillList
@onready var _skill_list_empty: Label = $Root/SkillsCard/SkillList/SkillListEmpty

var _elapsed: float = 0.0
var _tracked: Node = null                ## 当前正在顶部血条显示的精英/BOSS

## 技能列表显示颜色（方舟风：武器=青色，被动/属性=暖黄）
const COLOR_WEAPON := Color(0.3, 0.82, 0.92, 1)
const COLOR_STAT := Color(0.9, 0.72, 0.28, 1)


func _ready() -> void:
	_lv_value.text = "01"
	_exp_text.text = "EXP 0 / 5"
	_wave_value.text = "01"
	_time_value.text = "00:00"
	_set_bar(_hp_fill, 1.0)
	_set_bar(_exp_fill, 0.0)
	_hp_text.text = "HP 100 / 100"
	_elite_bar.hide()
	_refresh_skill_list()


# ---------------------------------------------------------------------------
# 状态面板
# ---------------------------------------------------------------------------

func update_health(current: float, max_hp: float) -> void:
	var safe_max := maxf(max_hp, 1.0)
	_hp_text.text = "HP %d / %d" % [int(current), int(max_hp)]
	_set_bar(_hp_fill, current / safe_max)


func update_exp(xp: int, to_next: int, level: int) -> void:
	_exp_text.text = "EXP %d / %d" % [xp, to_next]
	_lv_value.text = "%02d" % level
	var ratio := 0.0
	if to_next > 0:
		ratio = clampf(float(xp) / float(to_next), 0.0, 1.0)
	_set_bar(_exp_fill, ratio)


func update_wave(wave_index: int) -> void:
	_wave_value.text = "%02d" % (wave_index + 1)


## 高亮提示（精英/BOSS 出现时的顶部警告语）
func show_elite_notice(text: String) -> void:
	_elite_notice.text = text
	_elite_notice.show()


func hide_elite_notice() -> void:
	_elite_notice.hide()


# ---------------------------------------------------------------------------
# 技能列表：显示当前已选择的升级项
# ---------------------------------------------------------------------------

## 由 main 在每次升级后调用，刷新已选技能列表
func update_skills(entries: Array) -> void:
	# 清空旧条目（保留占位空标签）
	for c in _skill_list.get_children():
		if c != _skill_list_empty:
			_skill_list.remove_child(c)
			c.queue_free()
	for e in entries:
		var row := _build_skill_row(e)
		_skill_list.add_child(row)
	_refresh_skill_list()


## 构建单条技能条目。e 结构：{ title, description, type }（type 为 String）
func _build_skill_row(e: Dictionary) -> Control:
	var row := Panel.new()
	row.custom_minimum_size = Vector2(240, 30)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.08, 1)
	sb.border_color = Color(0.16, 0.19, 0.24, 1)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	row.add_theme_stylebox_override("panel", sb)

	# 左侧色条区分类型
	var strip := ColorRect.new()
	strip.color = COLOR_WEAPON if e.get("type", "") == "weapon" else COLOR_STAT
	strip.size = Vector2(3, 30)
	strip.position = Vector2(0, 0)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(strip)

	var title := Label.new()
	title.text = str(e.get("title", ""))
	title.position = Vector2(9, 2)
	title.size = Vector2(130, 16)
	title.add_theme_color_override("font_color", Color(0.92, 0.93, 0.94, 1))
	title.add_theme_font_size_override("font_size", 13)
	row.add_child(title)

	var desc := Label.new()
	desc.text = str(e.get("description", ""))
	desc.position = Vector2(9, 17)
	desc.size = Vector2(220, 13)
	desc.add_theme_color_override("font_color", Color(0.55, 0.6, 0.68, 1))
	desc.add_theme_font_size_override("font_size", 10)
	row.add_child(desc)

	return row


func _refresh_skill_list() -> void:
	var has_skill := false
	for c in _skill_list.get_children():
		if c != _skill_list_empty:
			has_skill = true
			break
	_skill_list_empty.visible = not has_skill


# ---------------------------------------------------------------------------
# 精英 / BOSS 顶部血条
# ---------------------------------------------------------------------------

## 精英/BOSS 刷出：注册到顶部血条并开始跟踪
func track_elite(enemy: Node) -> void:
	if enemy == null or not enemy.has_signal("health_changed") or not enemy.has_signal("enemy_died"):
		return
	# 同时只跟踪一个（后刷出的覆盖，通常为 BOSS）
	if is_instance_valid(_tracked):
		_untrack(_tracked)
	_tracked = enemy
	enemy.health_changed.connect(_on_tracked_health_changed)
	enemy.enemy_died.connect(_on_tracked_died)
	var name_text := ""
	if enemy.has_method("get_display_name"):
		name_text = enemy.get_display_name()
	_elite_name.text = name_text if name_text != "" else "高危目标"
	_elite_bar.show()
	show_elite_notice("高危目标已锁定")
	# 初始化血量
	var cur: float = enemy.data.current_health if enemy.data != null else 1.0
	var mx: float = enemy.data.max_health if enemy.data != null else 1.0
	_update_elite_fill(cur, mx)


func _on_tracked_health_changed(current: float, max_value: float) -> void:
	_update_elite_fill(current, max_value)


func _on_tracked_died(_enemy: Node) -> void:
	hide_elite_bar()


func _update_elite_fill(current: float, max_value: float) -> void:
	if max_value <= 0.0:
		return
	_set_bar(_elite_fill, clampf(current / max_value, 0.0, 1.0))


func hide_elite_bar() -> void:
	_elite_bar.hide()
	hide_elite_notice()
	if is_instance_valid(_tracked):
		_untrack(_tracked)
	_tracked = null


func _untrack(enemy: Node) -> void:
	if is_instance_valid(enemy):
		if enemy.is_connected("health_changed", _on_tracked_health_changed):
			enemy.health_changed.disconnect(_on_tracked_health_changed)
		if enemy.is_connected("enemy_died", _on_tracked_died):
			enemy.enemy_died.disconnect(_on_tracked_died)


# ---------------------------------------------------------------------------
# 计时
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	_elapsed += delta
	var total := int(_elapsed)
	var m := total / 60.0
	var s := total % 60
	_time_value.text = "%02d:%02d" % [int(m), s]


func reset_time() -> void:
	_elapsed = 0.0
	_time_value.text = "00:00"
	hide_elite_bar()


# ---------------------------------------------------------------------------
# 工具
# ---------------------------------------------------------------------------

## 设置横向填充条比例（0~1），并自动处理全宽 ColorRect 的缩放
func _set_bar(bar: ColorRect, ratio: float) -> void:
	if bar == null:
		return
	bar.scale.x = clampf(ratio, 0.0, 1.0)
