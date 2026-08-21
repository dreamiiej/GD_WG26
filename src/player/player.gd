extends CharacterBody2D
## 玩家（文档 3.1 / 3.5）。
## 移动用 Input.get_vector；受伤用 Area2D 检测敌人接触；受伤后短暂无敌帧。
## 经验获取与升级触发（M3）。

signal health_changed(current: float, max: float)
signal player_died
signal exp_changed(xp: int, to_next: int, level: int)
signal request_level_up

@export var stats: PlayerStats

const INVINCIBLE_TIME: float = 0.6
const HEALTH_BAR_SCENE := preload("res://src/ui/health_bar.gd")

var _invincible_timer: float = 0.0
var _hurt_area: Area2D
var _leveling_up: bool = false
var _health_bar: Node2D
var _buff_system: Node
var _skill_system: Node

@onready var _body: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("player")
	if stats == null:
		stats = PlayerStats.new()
	stats.reset()
	stats.leveled_up.connect(_on_leveled_up)
	health_changed.emit(stats.current_health, stats.max_health)
	exp_changed.emit(stats.xp, stats.exp_to_next, stats.level)

	_hurt_area = $HurtArea
	_hurt_area.body_entered.connect(_on_hurt_area_body_entered)
	_hurt_area.area_entered.connect(_on_hurt_area_area_entered)

	# Dota2 风格技能 / Buff 系统接线
	_buff_system = $BuffSystem
	_skill_system = $SkillSystem
	if _buff_system != null:
		_buff_system.target = self
		_buff_system.stats = stats
	if _skill_system != null:
		_skill_system.stats = stats
		_skill_system.buff_system = _buff_system

	# 头顶血条（红色背景 + 绿色填充），玩家始终显示
	_health_bar = HEALTH_BAR_SCENE.new()
	_health_bar.visible_when_full = false
	_health_bar.width = 40.0
	_health_bar.height = 6.0
	_health_bar.offset_y = -30.0
	add_child(_health_bar)
	_health_bar.set_value(stats.current_health, stats.max_health)

	# 血量变化时同步血条（最大血量升级后也要刷新）
	stats.stats_changed.connect(_on_stats_changed)
	health_changed.connect(_on_health_changed)


func _on_health_changed(current: float, max_health: float) -> void:
	if _health_bar != null and _health_bar.has_method("set_value"):
		_health_bar.set_value(current, max_health)


func _on_stats_changed() -> void:
	if _health_bar != null and _health_bar.has_method("set_value"):
		_health_bar.set_value(stats.current_health, stats.max_health)


func _physics_process(delta: float) -> void:
	if _invincible_timer > 0.0:
		_invincible_timer -= delta
		_body.modulate.a = 0.4 if int(Time.get_ticks_msec() / 80.0) % 2 == 0 else 1.0
	else:
		_body.modulate.a = 1.0

	# 道具临时增益倒计时
	if stats.has_method("tick_temp_buffs"):
		stats.tick_temp_buffs(delta)

	# Buff 系统计时（护盾 / 无敌 / DOT / HOT / 属性增益）
	if _buff_system != null and _buff_system.has_method("tick"):
		_buff_system.tick(delta)

	# 再生（PASSIVE 升级）
	if stats.regen > 0.0 and stats.current_health < stats.max_health:
		stats.current_health = min(stats.max_health, stats.current_health + stats.regen * delta)
		health_changed.emit(stats.current_health, stats.max_health)

	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * stats.move_speed
	move_and_slide()


func get_pickup_range() -> float:
	return stats.pickup_range


func gain_exp(amount: int) -> void:
	var leveled := stats.gain_exp(amount)
	exp_changed.emit(stats.xp, stats.exp_to_next, stats.level)
	if leveled and not _leveling_up:
		_leveling_up = true
		request_level_up.emit()


func _on_leveled_up(_lvl: int) -> void:
	pass


func take_damage(amount: float) -> void:
	if _invincible_timer > 0.0 or stats.current_health <= 0:
		return
	# Buff 无敌
	if _buff_system != null and _buff_system.is_invincible():
		return
	# 护盾吸收
	if _buff_system != null:
		amount = _buff_system.take_shield_damage(amount)
		if amount <= 0.0:
			return
	stats.current_health -= amount * stats.incoming_damage_mult
	health_changed.emit(stats.current_health, stats.max_health)
	# M6 反馈：受伤屏幕震动 + 音效
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(0.4)
	var sfx := get_tree().get_first_node_in_group("sfx")
	if sfx != null and sfx.has_method("play_hurt"):
		sfx.play_hurt()
	if stats.current_health <= 0.0:
		player_died.emit()
		return
	_invincible_timer = INVINCIBLE_TIME


func _on_hurt_area_body_entered(body: Node) -> void:
	if body.is_in_group("enemy") and body.has_method("get_contact_damage"):
		take_damage(body.get_contact_damage())


func _on_hurt_area_area_entered(area: Area2D) -> void:
	var parent := area.get_parent()
	if parent != null and parent.is_in_group("enemy") and parent.has_method("get_contact_damage"):
		take_damage(parent.get_contact_damage())


## 由升级面板调用，解除升级锁定
func finish_level_up() -> void:
	_leveling_up = false


## 道具：授予短暂无敌（护盾）
func grant_invincibility(duration: float) -> void:
	_invincible_timer = maxf(_invincible_timer, duration)


# ===================== Buff / 技能接入（Dota2 风格） =====================

## 外部施加 buff（技能 BUFF_SELF / 道具）
func apply_buff(data: BuffData) -> void:
	if _buff_system != null and _buff_system.has_method("apply"):
		_buff_system.apply(data)


func get_buff_system() -> Node:
	return _buff_system


## 恢复生命（HOT / 圣疗）
func apply_heal(amount: float) -> void:
	if stats == null:
		return
	stats.current_health = minf(stats.max_health, stats.current_health + amount)
	health_changed.emit(stats.current_health, stats.max_health)


func get_skill_system() -> Node:
	return _skill_system


## 习得技能（由升级系统调用）
func learn_skill(data: SkillData) -> bool:
	if _skill_system != null and _skill_system.has_method("learn"):
		return _skill_system.learn(data)
	return false


## 提升技能等级
func upgrade_skill(skill_id: String) -> bool:
	if _skill_system != null and _skill_system.has_method("upgrade"):
		return _skill_system.upgrade(skill_id)
	return false
