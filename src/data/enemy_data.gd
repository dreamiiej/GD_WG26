class_name EnemyData extends Resource
## 敌人数据资源（文档 3.3），属性全部数据驱动。

@export var display_name: String = "Enemy"
@export var max_health: float = 20.0
@export var move_speed: float = 80.0
@export var contact_damage: float = 8.0
@export var exp_value: int = 1
@export var size: float = 16.0
@export var color: Color = Color(0.8, 0.2, 0.2, 1.0)
@export var sprite_texture: Texture2D     ## 外观贴图（美术素材）

var current_health: float = 0.0           ## 当前血量，_ready 时初始化为 max_health
