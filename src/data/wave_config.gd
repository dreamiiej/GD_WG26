class_name WaveConfig extends Resource
## 波次配置（文档 3.4）。时间驱动：每 wave_duration 秒进入下一波，难度递增。

@export var display_name: String = "Wave"
@export var enemy_scene: PackedScene
@export var enemy_data: EnemyData            ## 该波敌人基础数据；为空则用 WaveManager.base_enemy_data
@export var extra_enemy_scene: PackedScene   ## 混入的第二种敌人场景（可选）
@export var extra_enemy_data: EnemyData      ## 混入的第二种敌人数据（可选）
@export var extra_chance: float = 0.0        ## 混入概率 0~1
@export var spawn_interval: float = 1.0      ## 该波刷怪间隔（秒）
@export var health_mult: float = 1.0         ## 血量倍率
@export var speed_mult: float = 1.0          ## 移速倍率
@export var damage_mult: float = 1.0         ## 接触伤害倍率
@export var exp_mult: float = 1.0            ## 经验倍率
@export var tint: Color = Color(1, 1, 1, 1)  ## 外观染色（可选）
