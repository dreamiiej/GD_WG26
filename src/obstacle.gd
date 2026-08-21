extends StaticBody2D
## 战场障碍物：矩形静态碰撞体 + 色块外观。由 Battlefield 批量生成并随机化。

@export var size := Vector2(80, 80)
@export var color := Color(0.3, 0.34, 0.42, 1)

@onready var _cs: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("obstacle")
	_apply()


## 由 Battlefield 在 add_child 前调用设置随机尺寸与颜色
func setup(p_size: Vector2, p_color: Color) -> void:
	size = p_size
	color = p_color


func _apply() -> void:
	if _cs != null:
		var r := RectangleShape2D.new()
		r.size = size
		_cs.shape = r
	# 清理旧视觉
	for c in get_children():
		if c is Polygon2D:
			c.queue_free()
	# 绘制矩形色块（带轻微描边感：亮色边框）
	var h := size * 0.5
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-h.x, -h.y), Vector2(h.x, -h.y),
		Vector2(h.x, h.y), Vector2(-h.x, h.y),
	])
	poly.color = color
	add_child(poly)
