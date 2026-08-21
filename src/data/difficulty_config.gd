class_name DifficultyConfig extends Resource
## 难度配置（局外内容 M9）。三档难度各自一份 .tres，数据驱动不改逻辑。

@export var id: String = "normal"                ## 唯一标识：easy / normal / hard
@export var display_name: String = "普通"
@export var description: String = "标准体验"
@export var enemy_health_mult: float = 1.0       ## 普通怪血量倍率
@export var enemy_speed_mult: float = 1.0        ## 敌人移速倍率
@export var spawn_interval_mult: float = 1.0     ## 刷怪间隔倍率（>1 更稀疏）
@export var elite_boss_health_mult: float = 1.0  ## 精英/BOSS 血量倍率
@export var exp_mult: float = 1.0                ## 全局经验倍率
@export var max_enemies: int = 300               ## 场上敌人上限（困难可提高）
