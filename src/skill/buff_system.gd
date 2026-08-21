extends Node
## BuffSystem：挂在目标（玩家/敌人）上的统一 Buff/Debuff 管理器。
## 数据驱动：BuffData 描述状态，Buff 为运行时实例，本类负责施加、刷新、叠加、计时与回退。
## 信号解耦：属性类 buff 通过 PlayerStats 读写；伤害/治疗/护盾类 buff 通过目标方法回调。
##
## 能力矩阵：
##   STAT_MULT/STAT_ADD → 需要 stats（PlayerStats），修改属性并回退
##   DOT                → 每 interval 调用 target.take_damage(value)
##   HOT                → 每 interval 恢复 target 生命（调 target.apply_heal）
##   SHIELD             → 累加 target.shield，由目标 take_damage 吸收
##   INVINCIBLE         → 设置 target 无敌标记
##   SLOW               → 设置 target 减速系数（敌人移动用）

signal buff_applied(buff: Buff)
signal buff_expired(buff: Buff)

@export var target: Node2D                       ## 被 buff 的目标（通常为父节点）
@export var stats: Resource = null               ## PlayerStats（STAT 类 buff 需要）

var _buffs: Array[Buff] = []
var _stat_base: Dictionary = {}                  ## stat -> 未被 STAT buff 污染前的底值
var _stat_adds: Dictionary = {}                  ## stat -> 累加增量总和
var _stat_mults: Dictionary = {}                 ## stat -> 累乘倍率总和
var _shield: float = 0.0
var _invincible: bool = false
var _slow: float = 0.0                           ## 减速比例（0~1，1 = 完全定身）


func _ready() -> void:
	if target == null:
		target = get_parent()


func reset() -> void:
	for b in _buffs:
		_rollback_buff(b)
	_buffs.clear()
	_stat_base.clear()
	_stat_adds.clear()
	_stat_mults.clear()
	_shield = 0.0
	_invincible = false
	_slow = 0.0


## 施加一个 buff。已有同 id 则刷新/叠加。
func apply(data: BuffData, p_stacks: int = 1) -> Buff:
	if data == null:
		return null
	var existing: Buff = _find_buff(data.buff_id)
	if existing != null:
		# 重复施加前先回退其属性效果，避免污染 base
		_rollback_buff(existing)
		existing.refresh(p_stacks)
		_apply_buff_effect(existing)
		buff_applied.emit(existing)
		return existing
	var b := Buff.new(data, p_stacks)
	_buffs.append(b)
	_apply_buff_effect(b)
	buff_applied.emit(b)
	return b


func has_buff(buff_id: String) -> bool:
	return _find_buff(buff_id) != null


func get_shield() -> float:
	return _shield


func is_invincible() -> bool:
	return _invincible


## 敌人移速乘数（SLOW buff 决定）
func get_slow_factor() -> float:
	return 1.0 - _slow


func take_shield_damage(amount: float) -> float:
	## 尝试用护盾吸收 amount，返回未被吸收的剩余伤害
	if _shield <= 0.0:
		return amount
	var absorbed := minf(_shield, amount)
	_shield -= absorbed
	amount -= absorbed
	if _shield <= 0.0:
		_shield = 0.0
	return amount


func add_shield(amount: float) -> void:
	_shield += amount


func tick(delta: float) -> void:
	if _buffs.is_empty():
		return
	var expired: Array[Buff] = []
	for b in _buffs:
		if b.permanent:
			continue
		b.remaining -= delta
		if b.remaining <= 0.0:
			expired.append(b)
			continue
		# DOT / HOT 计时
		if b.data.type == BuffData.BuffType.DOT or b.data.type == BuffData.BuffType.HOT:
			b.tick_timer -= delta
			if b.tick_timer <= 0.0:
				b.tick_timer = b.data.interval
				_tick_damage_or_heal(b)
	for b in expired:
		_remove_buff(b)


func clear_dots() -> void:
	## 清理所有持续伤害 buff（可由道具/技能触发）
	var to_remove: Array[Buff] = []
	for b in _buffs:
		if b.data.type == BuffData.BuffType.DOT:
			to_remove.append(b)
	for b in to_remove:
		_remove_buff(b)


func _find_buff(buff_id: String) -> Buff:
	for b in _buffs:
		if b.data.buff_id == buff_id:
			return b
	return null


func _remove_buff(b: Buff) -> void:
	_rollback_buff(b)
	_buffs.erase(b)
	buff_expired.emit(b)


## 应用 buff 的即时效果（属性/护盾/无敌/减速）
func _apply_buff_effect(b: Buff) -> void:
	var d := b.data
	match int(d.type):
		BuffData.BuffType.STAT_MULT, BuffData.BuffType.STAT_ADD:
			_apply_stat_buff(b)
		BuffData.BuffType.SHIELD:
			_shield += d.value * b.stacks
		BuffData.BuffType.INVINCIBLE:
			_invincible = true
		BuffData.BuffType.SLOW:
			_slow = minf(1.0, _slow + d.value * b.stacks)


## 回退 buff 的效果
func _rollback_buff(b: Buff) -> void:
	var d := b.data
	match int(d.type):
		BuffData.BuffType.STAT_MULT, BuffData.BuffType.STAT_ADD:
			_rollback_stat_buff(b)
		BuffData.BuffType.SHIELD:
			_shield = maxf(0.0, _shield - d.value * b.stacks)
		BuffData.BuffType.INVINCIBLE:
			_invincible = false
		BuffData.BuffType.SLOW:
			_slow = maxf(0.0, _slow - d.value * b.stacks)


# ---------------------------------------------------------------------------
# 属性类 buff：基于底值 + 增量累加 + 倍率累乘 重新计算并写入 PlayerStats
# ---------------------------------------------------------------------------

func _apply_stat_buff(b: Buff) -> void:
	var d := b.data
	if stats == null:
		return
	_ensure_base(d.stat)
	if int(d.type) == BuffData.BuffType.STAT_ADD:
		_stat_adds[d.stat] = _stat_adds.get(d.stat, 0.0) + d.value * b.stacks
	else:
		_stat_mults[d.stat] = _stat_mults.get(d.stat, 1.0) * (1.0 + d.value * b.stacks)
	_recalc_stat(d.stat)


func _rollback_stat_buff(b: Buff) -> void:
	var d := b.data
	if stats == null:
		return
	if int(d.type) == BuffData.BuffType.STAT_ADD:
		_stat_adds[d.stat] = _stat_adds.get(d.stat, 0.0) - d.value * b.stacks
		if absf(_stat_adds[d.stat]) < 0.0001:
			_stat_adds.erase(d.stat)
	else:
		var cur: float = _stat_mults.get(d.stat, 1.0)
		var factor := 1.0 + d.value * b.stacks
		if factor > 0.0:
			cur /= factor
		else:
			cur = 1.0
		if absf(cur - 1.0) < 0.0001:
			_stat_mults.erase(d.stat)
		else:
			_stat_mults[d.stat] = cur
	_recalc_stat(d.stat)


func _ensure_base(stat: String) -> void:
	if not _stat_base.has(stat):
		_stat_base[stat] = stats.get_stat(stat)


func _recalc_stat(stat: String) -> void:
	if not _stat_base.has(stat):
		return
	var base: float = _stat_base[stat]
	var adds: float = _stat_adds.get(stat, 0.0)
	var mult: float = _stat_mults.get(stat, 1.0)
	stats.set_stat(stat, (base + adds) * mult)


# ---------------------------------------------------------------------------
# DOT / HOT
# ---------------------------------------------------------------------------

func _tick_damage_or_heal(b: Buff) -> void:
	if target == null or not is_instance_valid(target):
		return
	var amount: float = b.data.value * b.stacks
	match int(b.data.type):
		BuffData.BuffType.DOT:
			if target.has_method("take_damage"):
				target.take_damage(amount)
		BuffData.BuffType.HOT:
			if target.has_method("apply_heal"):
				target.apply_heal(amount)
			elif stats != null:
				stats.current_health = minf(stats.max_health, stats.current_health + amount)
				if target.has_signal("health_changed"):
					target.health_changed.emit(stats.current_health, stats.max_health)
