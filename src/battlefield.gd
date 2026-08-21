extends Node2D
## 战场管理（限定大小 ~4 个屏幕宽高，中心为世界原点）。
## 负责：定义战场矩形、生成四周边界墙、随机生成少量障碍物。

## 战场半宽 / 半高（约 4 个 1920x1080 屏幕）
const HALF_W := 3840.0
const HALF_H := 2160.0
const WALL_THICK := 120.0
const OBSTACLE_MARGIN := 260.0
const SPAWN_CLEAR_RADIUS := 360.0      ## 玩家出生点周围无障碍半径

@export var obstacle_count := 60
@export_range(40, 200, 1) var obstacle_min_size := 50
@export_range(40, 200, 1) var obstacle_max_size := 150
@export var obstacle_scene: PackedScene

## 战场世界矩形（中心为原点）
var bounds := Rect2(-HALF_W, -HALF_H, HALF_W * 2.0, HALF_H * 2.0)

var _placed: Array[Rect2] = []


func _ready() -> void:
	add_to_group("battlefield")
	_build_walls()
	_spawn_obstacles()


## 四周边界墙：静态碰撞体（障碍层），把玩家与敌人限制在战场内
func _build_walls() -> void:
	var hw := HALF_W + WALL_THICK
	var hh := HALF_H + WALL_THICK
	var walls := [
		{"pos": Vector2(0, -HALF_H), "size": Vector2(hw * 2.0, WALL_THICK)},   # 上
		{"pos": Vector2(0,  HALF_H), "size": Vector2(hw * 2.0, WALL_THICK)},   # 下
		{"pos": Vector2(-HALF_W, 0), "size": Vector2(WALL_THICK, hh * 2.0)},   # 左
		{"pos": Vector2( HALF_W, 0), "size": Vector2(WALL_THICK, hh * 2.0)},   # 右
	]
	for w in walls:
		var body := StaticBody2D.new()
		body.collision_layer = 16    # obstacle 层
		body.add_to_group("obstacle")
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = w.size
		cs.shape = r
		body.add_child(cs)
		body.position = w.pos
		add_child(body)


## 在战场内部随机放置障碍物，避开玩家出生点且避免彼此重叠
func _spawn_obstacles() -> void:
	if obstacle_scene == null:
		return
	var interior := Rect2(
		bounds.position + Vector2(OBSTACLE_MARGIN, OBSTACLE_MARGIN),
		bounds.size - Vector2(OBSTACLE_MARGIN, OBSTACLE_MARGIN) * 2.0
	)
	var attempts := 0
	var placed := 0
	while placed < obstacle_count and attempts < obstacle_count * 30:
		attempts += 1
		var sz := Vector2(
			randf_range(obstacle_min_size, obstacle_max_size),
			randf_range(obstacle_min_size, obstacle_max_size)
		)
		var p := Vector2(
			randf_range(interior.position.x, interior.end.x),
			randf_range(interior.position.y, interior.end.y)
		)
		# 避开玩家出生点
		if p.distance_to(Vector2.ZERO) < SPAWN_CLEAR_RADIUS + sz.length() * 0.5:
			continue
		var rect := Rect2(p - sz * 0.5, sz)
		# 与已放置障碍保持间距，避免密集堆叠
		if _overlaps(rect, 24.0):
			continue
		var o := obstacle_scene.instantiate()
		o.setup(sz, _random_color())
		o.position = p
		add_child(o)
		_placed.append(rect)
		placed += 1


func _overlaps(rect: Rect2, pad: float) -> bool:
	var grown := rect.grow(pad)
	for r in _placed:
		if grown.intersects(r):
			return true
	return false


## 供刷怪使用的可生成区域（战场内部，远离边界墙）
func get_spawn_bounds() -> Rect2:
	var inset := OBSTACLE_MARGIN * 0.5
	return bounds.grow(-inset)


func _random_color() -> Color:
	var base := [
		Color(0.30, 0.34, 0.42, 1),
		Color(0.24, 0.29, 0.38, 1),
		Color(0.35, 0.31, 0.27, 1),
		Color(0.28, 0.36, 0.34, 1),
	]
	return base[randi() % base.size()]
