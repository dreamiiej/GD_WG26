class_name PlayerStats extends Resource
## 玩家集中属性模块（文档 3.6）。
## 武器、被动、升级都读写这个资源，避免属性散落在各节点。

signal stats_changed
signal leveled_up(level: int)

@export var max_health: float = 100.0
@export var move_speed: float = 220.0
@export var damage_multiplier: float = 1.0
@export var cooldown_reduction: float = 0.0
@export var pickup_range: float = 60.0
@export var exp_gain_mult: float = 1.0      ## 经验获取倍率（PASSIVE 升级）
@export var regen: float = 0.0               ## 每秒回血（PASSIVE 升级，由 player 每帧应用）

var current_health: float:
	get:
		return _current_health
	set(v):
		_current_health = clampf(v, 0.0, max_health)
		stats_changed.emit()

var _current_health: float = 100.0

# 经验 / 等级（文档 3.5）
var level: int = 1
var xp: int = 0
var exp_to_next: int = 5


func reset() -> void:
	_current_health = max_health
	level = 1
	xp = 0
	exp_to_next = 5
	stats_changed.emit()


## 获得经验，返回是否触发升级
func gain_exp(amount: int) -> bool:
	xp += int(amount * exp_gain_mult)
	var leveled := false
	while xp >= exp_to_next:
		xp -= exp_to_next
		level += 1
		exp_to_next = int(exp_to_next * 1.25 + 3)  # 平滑成长，避免指数爆炸（文档 7.3）
		leveled = true
	if leveled:
		leveled_up.emit(level)
	return leveled


## 应用一个升级项（文档 3.5）
func apply_upgrade(data: UpgradeData) -> void:
	if data.type != UpgradeData.UpgradeType.STAT:
		return
	match data.stat:
		"max_health":
			if data.is_percent:
				max_health *= (1.0 + data.value / 100.0)
			else:
				max_health += data.value
			_current_health += data.value if not data.is_percent else max_health * data.value / 100.0
		"move_speed":
			if data.is_percent:
				move_speed *= (1.0 + data.value / 100.0)
			else:
				move_speed += data.value
		"damage_multiplier":
			if data.is_percent:
				damage_multiplier *= (1.0 + data.value / 100.0)
			else:
				damage_multiplier += data.value
		"cooldown_reduction":
			if data.is_percent:
				cooldown_reduction = clampf(cooldown_reduction + data.value / 100.0, 0.0, 0.85)
			else:
				cooldown_reduction = clampf(cooldown_reduction + data.value, 0.0, 0.85)
		"pickup_range":
			pickup_range += data.value
		"exp_gain_mult":
			if data.is_percent:
				exp_gain_mult *= (1.0 + data.value / 100.0)
			else:
				exp_gain_mult += data.value
		"regen":
			regen += data.value
	stats_changed.emit()
