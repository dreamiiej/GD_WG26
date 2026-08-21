extends CharacterBody2D
## 敌人（文档 3.3）。
## 朝玩家移动；通过 player 的 HurtArea 触发造成伤害（反向检测）。
## 暴露 get_contact_damage 供玩家读取；死亡由 GameManager 调用 die()。

signal enemy_died(enemy: Node)
signal health_changed(current: float, max: float)

const HEALTH_BAR_SCENE := preload("res://src/ui/health_bar.gd")

@export var data: EnemyData

var _sprite: Sprite2D
var _player_ref: Node2D                           ## M6 缓存玩家引用，避免每帧全树查找
var _health_bar: Node2D
var _nav: Node2D                                  ## 流场寻路缓存（FlowField）
var _buff_system: Node                            ## Dota2 风格 buff（减速/中毒/护盾）

## 是否为需要顶部血条的精英/BOSS（数据驱动）
func is_highlighted() -> bool:
	return data != null and (data.is_elite or data.is_boss)


func get_display_name() -> String:
	if data != null and data.display_name != "":
		return data.display_name
	return "Enemy"


func _ready() -> void:
	add_to_group("enemy")
	if data == null:
		data = EnemyData.new()
	_sprite = $Sprite2D
	if _sprite:
		if data.sprite_texture != null:
			_sprite.texture = data.sprite_texture
		# 用 size 缩放外观（256 图源，size 约等于像素直径）
		var s := data.size / 140.0
		_sprite.scale = Vector2(s, s)
	var shape := $CollisionShape2D
	if shape != null and shape.shape is CircleShape2D:
		shape.shape = shape.shape.duplicate()
		shape.shape.radius = data.size

	# 初始化当前血量
	if data.current_health <= 0.0:
		data.current_health = data.max_health

	# Buff 系统（减速 / 中毒 / 护盾）
	_buff_system = get_node_or_null("BuffSystem")
	if _buff_system != null:
		_buff_system.target = self

	# 头顶血条（红色背景 + 绿色填充），非满血时显示
	_health_bar = HEALTH_BAR_SCENE.new()
	_health_bar.visible_when_full = true
	_health_bar.width = maxf(28.0, data.size * 1.6)
	_health_bar.offset_y = -data.size - 10.0
	add_child(_health_bar)
	_update_health_bar()


func _physics_process(delta: float) -> void:
	# Buff 计时（减速 / 中毒 / 护盾）
	if _buff_system != null and _buff_system.has_method("tick"):
		_buff_system.tick(delta)
	if not is_instance_valid(_player_ref):
		_player_ref = get_tree().get_first_node_in_group("player")
	if _player_ref == null:
		return
	# 优先使用流场寻路绕障；无寻路或不可达时退回直线追击
	if _nav == null or not is_instance_valid(_nav):
		_nav = get_tree().get_first_node_in_group("flow_field")
	var dir := (_player_ref.global_position - global_position).normalized()
	if _nav != null and _nav.has_method("get_walk_direction"):
		var nav_dir: Vector2 = _nav.get_walk_direction(global_position)
		if nav_dir.length_squared() > 0.0001:
			dir = nav_dir
	var slow := 1.0
	if _buff_system != null and _buff_system.has_method("get_slow_factor"):
		slow = _buff_system.get_slow_factor()
	velocity = dir * data.move_speed * slow
	move_and_slide()


func get_contact_damage() -> float:
	return data.contact_damage


func get_exp_value() -> int:
	return int(data.exp_value)


var _sfx_cd: float = 0.0                            ## M6 受击音效节流


func take_damage(amount: float) -> void:
	if data == null:
		return
	# 护盾吸收（技能减益/护甲类 buff）
	if _buff_system != null:
		amount = _buff_system.take_shield_damage(amount)
		if amount <= 0.0:
			return
	_sfx_cd -= get_process_delta_time() if Engine.is_in_physics_frame() else 0.0
	if _sfx_cd <= 0.0:
		var sfx := get_tree().get_first_node_in_group("sfx")
		if sfx != null and sfx.has_method("play_hit"):
			sfx.play_hit()
		_sfx_cd = 0.2
	data.current_health -= amount
	_update_health_bar()
	if data.current_health <= 0.0:
		die()


## 施加减益（技能 DEBUFF_AOE / 范围 buff）
func apply_buff(data: BuffData) -> void:
	if _buff_system != null and _buff_system.has_method("apply"):
		_buff_system.apply(data)


func _update_health_bar() -> void:
	if _health_bar != null and _health_bar.has_method("set_value"):
		_health_bar.set_value(data.current_health, data.max_health)
	health_changed.emit(data.current_health, data.max_health)


func die() -> void:
	enemy_died.emit(self)
	queue_free()
