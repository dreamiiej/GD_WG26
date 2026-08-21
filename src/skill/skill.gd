class_name Skill extends RefCounted
## 运行时技能实例（由 SkillSystem 管理）。持有数据、等级与当前冷却。

signal cooldown_started(skill: Skill)

var data: SkillData
var level: int = 1
var cooldown_remaining: float = 0.0

var _cooldown_total: float = 0.0


func _init(p_data: SkillData) -> void:
	data = p_data


func setup(p_data: SkillData) -> void:
	data = p_data
	level = 1
	cooldown_remaining = 0.0
	_cooldown_total = 0.0


func is_ready() -> bool:
	return cooldown_remaining <= 0.0


func upgrade() -> void:
	if level < data.max_level:
		level += 1


func tick(delta: float) -> void:
	if cooldown_remaining > 0.0:
		cooldown_remaining = maxf(0.0, cooldown_remaining - delta)


## 计算考虑冷却缩减后的实际冷却
func effective_cooldown(stats) -> float:
	if stats != null and stats.has_method("get_stat"):
		var cdr: float = stats.get_stat("cooldown_reduction")
		return data.cooldown * (1.0 - clampf(cdr, 0.0, 0.9))
	return data.cooldown


## 开始冷却
func start_cooldown(stats) -> void:
	_cooldown_total = effective_cooldown(stats)
	cooldown_remaining = _cooldown_total
	cooldown_started.emit(self)


func get_cooldown_ratio() -> float:
	if _cooldown_total <= 0.0:
		return 0.0
	return clampf(cooldown_remaining / _cooldown_total, 0.0, 1.0)
