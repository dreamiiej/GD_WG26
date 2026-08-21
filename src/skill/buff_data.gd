class_name BuffData extends Resource
## 增益/减益数据资源（数据驱动，参考 Dota2 的 Buff/Debuff 概念）。
## 每个 BuffData 描述一种可叠加、可刷新的状态效果，由 BuffSystem 统一管理。
## 作用对象可为玩家（属性增益/护盾/无敌/再生/灼烧）或敌人（减速/中毒/灼烧/破甲）。

enum BuffType {
	STAT_MULT,     ## 属性倍率（如 +30% 伤害 / +20% 移速 / -20% 受伤）
	STAT_ADD,      ## 属性增量（如 +10 拾取范围 / 冷却 -0.1）
	DOT,           ## 持续伤害（中毒/灼烧），按 interval 造成伤害
	HOT,           ## 持续治疗（再生/吸血），按 interval 恢复生命
	SHIELD,        ## 伤害吸收护盾，吸收 value 点伤害后消失
	INVINCIBLE,    ## 无敌，持续 duration 秒
	SLOW,          ## 减速（对敌人），移速乘以 (1 - value)
}

@export var buff_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var type: BuffType = BuffType.STAT_MULT
## STAT_MULT/STAT_ADD 作用于哪个属性（move_speed / damage_multiplier / cooldown_reduction / pickup_range / incoming_damage_mult / max_health / regen / exp_gain_mult）
@export var stat: String = ""
## STAT_MULT：倍率（如 0.3 = +30%）；STAT_ADD：增量；DOT/HOT：每 tick 数值；SHIELD：吸收量；SLOW：减速比例（0.3 = 减速 30%）
@export var value: float = 0.0
@export var duration: float = 0.0          ## 持续时间（秒），0 = 永久（直到显式移除）
@export var interval: float = 1.0          ## DOT/HOT 的触发间隔
@export var max_stacks: int = 1            ## 最大叠加层数
@export var color: Color = Color(0.6, 0.8, 1.0, 1.0)
