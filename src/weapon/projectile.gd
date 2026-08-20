extends Area2D
## 子弹（文档 3.2 发射型）。命中敌人造成伤害，穿透用完销毁。
## M6：配合 ObjectPool 复用，死亡改为发 released 信号由 WeaponManager 回收。

signal released(node: Node)

@export var speed: float = 360.0
@export var damage: float = 10.0
@export var pierce: int = 0

var _velocity: Vector2 = Vector2.ZERO
var _life_timer: float = 0.0
var _hit_targets: Array[Node] = []


func setup(p_damage: float, p_speed: float, p_pierce: int, dir: Vector2) -> void:
	damage = p_damage
	speed = p_speed
	pierce = p_pierce
	_velocity = dir.normalized() * speed
	_life_timer = 0.0
	_hit_targets.clear()


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position += _velocity * delta
	_life_timer += delta
	if _life_timer > 3.0:
		_recycle()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		_apply_hit(body)


func _on_area_entered(area: Area2D) -> void:
	var parent := area.get_parent()
	if parent != null and parent.is_in_group("enemy"):
		_apply_hit(parent)


func _apply_hit(target: Node) -> void:
	if target in _hit_targets:
		return
	_hit_targets.append(target)
	if target.has_method("take_damage"):
		target.take_damage(damage)
	pierce -= 1
	if pierce < 0:
		_recycle()


func _recycle() -> void:
	released.emit(self)
