class_name FlowField extends Node2D
## 流场寻路：把战场栅格化，以玩家为汇点做 BFS，得到每格到玩家的步数。
## 敌人查询"走向步数更少的邻格"即可绕开障碍，性能友好（每次重建 O(格数)）。

const CELL := 32.0
const INF := 1e9
const NEIGHBORS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]

var _rect := Rect2()
var _size := Vector2i.ZERO
var _origin := Vector2.ZERO
var _blocked := PackedByteArray()      # 1=障碍/墙
var _costs := PackedFloat32Array()     # 到玩家的最小步数，INF=不可达
var _player: Node2D
var _recompute_cd := 0.0
var _recompute_interval := 0.3


func _ready() -> void:
	add_to_group("flow_field")


## 由 main 在开局时调用：传入战场矩形与玩家引用
func setup(battlefield_rect: Rect2, player: Node2D) -> void:
	_rect = battlefield_rect
	_origin = _rect.position
	_player = player
	_size = Vector2i(ceili(_rect.size.x / CELL), ceili(_rect.size.y / CELL))
	_blocked.resize(_size.x * _size.y)
	_costs.resize(_size.x * _size.y)
	_mark_all_obstacles()
	_recompute()


func _process(delta: float) -> void:
	if _player == null or _size == Vector2i.ZERO:
		return
	_recompute_cd -= delta
	if _recompute_cd <= 0.0:
		_recompute_cd = _recompute_interval
		_recompute()


## 重新栅格化所有障碍/墙（开局调用一次）
func _mark_all_obstacles() -> void:
	_blocked.fill(0)
	for body in get_tree().get_nodes_in_group("obstacle"):
		for c in body.get_children():
			if c is CollisionShape2D and c.shape is RectangleShape2D:
				var sz: Vector2 = (c.shape as RectangleShape2D).size
				var half := sz * 0.5
				var c0 := _world_to_cell(body.global_position - half)
				var c1 := _world_to_cell(body.global_position + half)
				for y in range(c0.y, c1.y + 1):
					for x in range(c0.x, c1.x + 1):
						if _in_bounds(x, y):
							_blocked[y * _size.x + x] = 1


func _world_to_cell(w: Vector2) -> Vector2i:
	var local := w - _origin
	return Vector2i(int(floor(local.x / CELL)), int(floor(local.y / CELL)))


func _in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < _size.x and y < _size.y


## BFS：从玩家所在格出发，计算每格到玩家的最短步数（8 方向）
func _recompute() -> void:
	_costs.fill(INF)
	if _player == null:
		return
	var start := _world_to_cell(_player.global_position)
	start.x = clampi(start.x, 0, _size.x - 1)
	start.y = clampi(start.y, 0, _size.y - 1)
	# 用 head 指针模拟队列，避免 Array.pop_front() 的 O(n) 开销
	var queue: Array[Vector2i] = []
	var head := 0
	var s_idx := start.y * _size.x + start.x
	_costs[s_idx] = 0.0
	queue.append(start)
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		var base := _costs[c.y * _size.x + c.x]
		for n in NEIGHBORS:
			var nb: Vector2i = c + n
			if not _in_bounds(nb.x, nb.y):
				continue
			var idx := nb.y * _size.x + nb.x
			if _blocked[idx] == 0 and _costs[idx] > base + 1.0:
				_costs[idx] = base + 1.0
				queue.append(nb)


## 敌人调用：返回朝玩家前进的方向（已绕障）。目标不可达时退回直线追击。
func get_walk_direction(pos: Vector2) -> Vector2:
	if _player == null or _size == Vector2i.ZERO:
		return Vector2.ZERO
	# 接近玩家（约 2 格内）直接直线冲撞，确保能贴身造成接触伤害
	if pos.distance_to(_player.global_position) < CELL * 2.5:
		return (_player.global_position - pos).normalized()

	var c := _world_to_cell(pos)
	c.x = clampi(c.x, 0, _size.x - 1)
	c.y = clampi(c.y, 0, _size.y - 1)
	var cur := _costs[c.y * _size.x + c.x]
	if cur >= INF:
		return (_player.global_position - pos).normalized()

	var best_cost := cur
	var best_pos := pos
	for n in NEIGHBORS:
		var nb: Vector2i = c + n
		if not _in_bounds(nb.x, nb.y):
			continue
		var v := _costs[nb.y * _size.x + nb.x]
		if v < best_cost:
			best_cost = v
			best_pos = _origin + (Vector2(nb) + Vector2(0.5, 0.5)) * CELL

	var d := best_pos - pos
	if d.length_squared() < 0.01:
		return (_player.global_position - pos).normalized()
	return d.normalized()
