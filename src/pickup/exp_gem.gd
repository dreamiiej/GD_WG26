extends Area2D
## 经验宝石（文档 3.5）。玩家靠近自动吸附，接触后被拾取。
## M6：配合 ObjectPool 复用，拾取后发 released 由 GameManager 回收。

signal picked_up(amount: int)
signal released(node: Node)

@export var exp_value: int = 1

var _player: Node2D
var _pickup_range: float = 60.0
var _attracting: bool = false


func setup(p_exp: int, p_player: Node2D, p_range: float) -> void:
	exp_value = p_exp
	_player = p_player
	_pickup_range = p_range
	_attracting = false


func _ready() -> void:
	# 玩家是 CharacterBody2D（含 HurtArea/Area2D），宝石本身是 Area2D，
	# 必须用 area_entered 而非 body_entered 才能被检测到（文档 3.5）。
	area_entered.connect(_on_area_entered)


func _physics_process(_delta: float) -> void:
	if _player == null:
		return
	if _player.has_method("get_pickup_range"):
		_pickup_range = _player.get_pickup_range()
	var dist := global_position.distance_to(_player.global_position)
	# 进入拾取范围即吸附（文档 3.5：靠近后自动吸附）
	if dist <= _pickup_range:
		_attracting = true
	if _attracting:
		var dir: Vector2 = (_player.global_position - global_position).normalized()
		var speed: float = lerp(120.0, 420.0, 1.0 - clampf(dist / max(_pickup_range, 1.0), 0.0, 1.0))
		global_position += dir * speed * _delta


func _on_area_entered(area: Area2D) -> void:
	# 玩家通过 HurtArea（Area2D）被检测，需取其父节点判断分组。
	var parent := area.get_parent()
	if parent != null and parent.is_in_group("player"):
		picked_up.emit(exp_value)
		released.emit(self)


func set_range(r: float) -> void:
	_pickup_range = r
