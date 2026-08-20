class_name WeaponData extends Resource
## 武器数据资源（文档 3.2），全部数据驱动。
## M5 扩展：支持发射型 / 光环型 / 近战型三类武器。

enum WeaponType {
	PROJECTILE,  ## 发射型：生成子弹朝最近敌人飞行
	AURA,        ## 光环型：围绕玩家持续对范围内敌人造成伤害
	MELEE,       ## 近战型：围绕玩家生成 Area2D 持续短暂时间
}

@export var weapon_id: String = "missile"   ## 唯一标识，升级系统据此解锁/强化
@export var display_name: String = "飞弹"
@export var weapon_type: WeaponType = WeaponType.PROJECTILE
@export var damage: float = 10.0
@export var cooldown: float = 0.6
@export var projectile_scene: PackedScene    ## PROJECTILE 类型使用
@export var projectile_speed: float = 360.0
@export var pierce: int = 0
@export var projectile_count: int = 1
@export var spread_deg: float = 0.0

## AURA / MELEE 类型使用
@export var radius: float = 80.0             ## 作用半径
@export var duration: float = 0.25           ## MELEE：每次挥砍持续时长（秒）
@export var effect_scene: PackedScene        ## AURA/MELEE 外观节点（可选）
