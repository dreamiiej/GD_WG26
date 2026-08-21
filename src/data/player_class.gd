class_name PlayerClass extends Resource
## 职业配置资源（数据驱动）。
## 描述一个职业的展示信息、初始基础数值、以及开局自带武器与技能。
## 数值字段与 PlayerStats 的导出属性同名，开局时由 main.gd 应用。

@export var class_id: String = "warrior"        ## 唯一标识：warrior / mage / ranger
@export var display_name: String = "剑士"
@export var description: String = "攻守均衡的近战职业"

## 初始基础数值（与 PlayerStats 字段同名；留 0 / 默认表示不覆盖）
@export var base_max_health: float = 0.0
@export var base_move_speed: float = 0.0
@export var base_damage_multiplier: float = 0.0
@export var base_cooldown_reduction: float = 0.0
@export var base_regen: float = 0.0

## 开局自带武器（可选，WeaponData 资源）
@export var start_weapon: WeaponData = null

## 开局自带技能 id 列表（对应 SkillPool.skill_map() 的键，main.gd 按 id 查找）
@export var start_skill_ids: Array[String] = []
