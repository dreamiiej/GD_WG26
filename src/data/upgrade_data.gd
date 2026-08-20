class_name UpgradeData extends Resource
## 升级项数据资源（文档 3.5）。

enum UpgradeType {
	STAT,       ## 直接改 PlayerStats 数值
	WEAPON,     ## 武器强化（M5 扩展）
	PASSIVE,    ## 被动效果（M5 扩展）
}

@export var title: String = ""
@export var description: String = ""
@export var type: UpgradeType = UpgradeType.STAT
@export var stat: String = ""          ## 改哪个属性：max_health / move_speed / damage_multiplier / cooldown_reduction / pickup_range
@export var value: float = 0.0          ## 增量（绝对值）；百分比类用倍率增量（如 -0.1 表示 -10%% 冷却）
@export var is_percent: bool = false
## WEAPON 类型专用：解锁或强化某把武器
@export var weapon_id: String = ""      ## 对应 WeaponData.weapon_id
@export var unlock_weapon: bool = false ## true=解锁新武器；false=强化已拥有武器（value 作为该武器倍率增量）
@export var max_stacks: int = 99        ## 该升级项最多可叠多少层（避免数值爆炸，文档 7.3）
