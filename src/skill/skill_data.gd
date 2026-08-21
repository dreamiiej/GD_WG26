class_name SkillData extends Resource
## 技能数据资源（数据驱动，参考 Dota2 英雄技能与 Dota2 吸血鬼幸存者 arcade 的技能设计）。
## 技能在升级系统中习得/升级，由 SkillSystem 按冷却自动向最近敌人/自身施放，
## 数值随等级成长（damage/radius/duration 各带每级增量）。

enum SkillType {
	NOVA,          ## 范围爆发：对以目标/自身为中心的半径内敌人造成一次伤害（可选附加减益）
	WHIRLWIND,     ## 旋刃风暴：围绕自身持续旋转造成多段伤害，持续 duration 秒
	ZONE,          ## 部署毒区：在目标位置部署持续伤害区域，持续 duration 秒
	VOLLEY,        ## 弹幕齐射：向四周发射 projectile_count 颗子弹
	HEAL,          ## 自我治疗：立即回复最大生命一定百分比
	BUFF_SELF,     ## 自身增益：对自身施加 apply_buff（狂暴/加速/护盾/再生）
	DEBUFF_AOE,    ## 范围减益：对半径内所有敌人施加 apply_buff（减速/中毒/破甲）
}

@export var skill_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var type: SkillType = SkillType.NOVA
@export var cooldown: float = 8.0
@export var max_level: int = 5
@export var color: Color = Color(0.6, 0.8, 1.0, 1.0)

## 数值（base = 1 级，per_level = 每级增量）
@export var damage: float = 0.0
@export var damage_per_level: float = 0.0
@export var radius: float = 120.0
@export var radius_per_level: float = 0.0
@export var duration: float = 2.0            ## WHIRLWIND / ZONE 持续
@export var duration_per_level: float = 0.0
@export var hit_interval: float = 0.5        ## WHIRLWIND / ZONE 伤害间隔

## VOLLEY
@export var projectile_count: int = 8
@export var projectile_speed: float = 420.0
@export var projectile_pierce: int = 0
@export var projectile_scene: PackedScene

## HEAL：回复最大生命百分比（0.15 = 15%）
@export var heal_percent: float = 0.0
@export var heal_percent_per_level: float = 0.0

## BUFF_SELF / DEBUFF_AOE：关联的增益/减益
@export var apply_buff: BuffData

## 视觉效果场景（NOVA/ZONE 外观，可选）
@export var effect_scene: PackedScene


func get_damage(level: int) -> float:
	return damage + damage_per_level * (level - 1)


func get_radius(level: int) -> float:
	return radius + radius_per_level * (level - 1)


func get_duration(level: int) -> float:
	return duration + duration_per_level * (level - 1)


func get_heal_percent(level: int) -> float:
	return heal_percent + heal_percent_per_level * (level - 1)
