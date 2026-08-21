extends Area2D
## 战场道具拾取物。靠近自动吸附，接触玩家即拾取并应用效果。
## 数据由 ItemData 驱动；拾取后发 picked_up / released 由 GameManager 回收。

signal picked_up(data: ItemData)
signal released(node: Node)

var _data: ItemData
var _player: Node2D
var _pickup_range: float = 60.0
var _attracting: bool = false


func setup(p_data: ItemData, p_player: Node2D, p_range: float) -> void:
	_data = p_data
	_player = p_player
	_pickup_range = p_range
	_attracting = false
	_update_visual()


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_update_visual()


func _update_visual() -> void:
	var poly := get_node_or_null("Polygon2D") as Polygon2D
	if poly != null and _data != null:
		poly.color = _data.color


func _physics_process(delta: float) -> void:
	if _player == null:
		return
	if _player.has_method("get_pickup_range"):
		_pickup_range = _player.get_pickup_range()
	var dist := global_position.distance_to(_player.global_position)
	# 进入拾取范围即吸附
	if dist <= _pickup_range:
		_attracting = true
	if _attracting:
		var dir: Vector2 = (_player.global_position - global_position).normalized()
		var speed: float = lerp(120.0, 420.0, 1.0 - clampf(dist / max(_pickup_range, 1.0), 0.0, 1.0))
		global_position += dir * speed * delta


func _on_area_entered(area: Area2D) -> void:
	# 玩家通过 HurtArea（Area2D）被检测，取父节点判断分组
	var parent := area.get_parent()
	if parent != null and parent.is_in_group("player"):
		# 物理回调内禁止直接回收节点，延迟执行
		_collect.call_deferred()


func _collect() -> void:
	if not is_instance_valid(self):
		return
	if _data != null:
		picked_up.emit(_data)
	released.emit(self)
