extends CanvasLayer
## HUD（文档 2.1）。显示玩家血量、经验、等级、波次与存活时间。
## v2 M7：新增精英/BOSS 顶部血条（屏幕靠上、全局显示，无论敌人在哪）。

@onready var _health_label: Label = $HealthLabel
@onready var _exp_label: Label = $ExpLabel
@onready var _level_label: Label = $LevelLabel
@onready var _wave_label: Label = $WaveLabel
@onready var _time_label: Label = $TimeLabel
@onready var _elite_bar: Control = $EliteBar
@onready var _elite_name: Label = $EliteBar/NameLabel
@onready var _elite_fill: ColorRect = $EliteBar/Fill

var _elapsed: float = 0.0
var _tracked: Node = null                ## 当前正在顶部血条显示的精英/BOSS


func _ready() -> void:
	_health_label.text = "HP: 100/100"
	_exp_label.text = "EXP: 0/5"
	_level_label.text = "Lv: 1"
	_wave_label.text = "Wave: 1"
	_elite_bar.hide()


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
	_elite_name.text = name_text if name_text != "" else "精英"
	_elite_bar.show()
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
	var ratio: float = clampf(current / max_value, 0.0, 1.0)
	_elite_fill.scale.x = ratio


func hide_elite_bar() -> void:
	_elite_bar.hide()
	if is_instance_valid(_tracked):
		_untrack(_tracked)
	_tracked = null


func _untrack(enemy: Node) -> void:
	if is_instance_valid(enemy):
		if enemy.is_connected("health_changed", _on_tracked_health_changed):
			enemy.health_changed.disconnect(_on_tracked_health_changed)
		if enemy.is_connected("enemy_died", _on_tracked_died):
			enemy.enemy_died.disconnect(_on_tracked_died)


func update_health(current: float, max_hp: float) -> void:
	_health_label.text = "HP: %d/%d" % [int(current), int(max_hp)]


func update_exp(xp: int, to_next: int, level: int) -> void:
	_exp_label.text = "EXP: %d/%d" % [xp, to_next]
	_level_label.text = "Lv: %d" % level


func update_wave(wave_index: int) -> void:
	_wave_label.text = "Wave: %d" % (wave_index + 1)


func _process(delta: float) -> void:
	_elapsed += delta
	_time_label.text = "时间: %d" % int(_elapsed)


func reset_time() -> void:
	_elapsed = 0.0
	hide_elite_bar()
