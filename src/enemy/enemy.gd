extends CharacterBody2D
## 敌人（文档 3.3）。
## 朝玩家移动；通过 player 的 HurtArea 触发造成伤害（反向检测）。
## 暴露 get_contact_damage 供玩家读取；死亡由 GameManager 调用 die()。

signal enemy_died(enemy: Node)

@export var data: EnemyData

var _poly: Polygon2D
var _player_ref: Node2D                           ## M6 缓存玩家引用，避免每帧全树查找


func _ready() -> void:
	add_to_group("enemy")
	if data == null:
		data = EnemyData.new()
	_poly = $Polygon2D
	if _poly:
		_poly.color = data.color
		# 用 size 缩放外观
		var s := data.size / 16.0
		_poly.scale = Vector2(s, s)
	var shape := $CollisionShape2D
	if shape != null and shape.shape is CircleShape2D:
		shape.shape = shape.shape.duplicate()
		shape.shape.radius = data.size


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_player_ref):
		_player_ref = get_tree().get_first_node_in_group("player")
	if _player_ref == null:
		return
	var dir := (_player_ref.global_position - global_position).normalized()
	velocity = dir * data.move_speed
	move_and_slide()


func get_contact_damage() -> float:
	return data.contact_damage


func get_exp_value() -> int:
	return int(data.exp_value)


var _sfx_cd: float = 0.0                            ## M6 受击音效节流


func take_damage(amount: float) -> void:
	if data == null:
		return
	_sfx_cd -= get_process_delta_time() if Engine.is_in_physics_frame() else 0.0
	if _sfx_cd <= 0.0:
		var sfx := get_tree().get_first_node_in_group("sfx")
		if sfx != null and sfx.has_method("play_hit"):
			sfx.play_hit()
		_sfx_cd = 0.2
	data.max_health -= amount
	if data.max_health <= 0.0:
		die()


func die() -> void:
	enemy_died.emit(self)
	queue_free()
