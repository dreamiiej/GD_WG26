extends Node
## SkillSystem：挂在玩家上的技能管理节点（参考 Dota2 英雄技能 + Dota2 吸血鬼幸存者 arcade）。
## 负责：习得/升级技能、按冷却自动施放、向玩家技能范围效果 / 弹幕 / 治疗 / 增益 / 减益分发。
## 数据驱动：SkillData 描述技能，数值随等级成长；效果通过 SkillAreaEffect 与 BuffSystem 落地。

signal skill_learned(skill_data: SkillData, level: int)
signal skill_leveled(skill_data: SkillData, level: int)
signal skill_cast(skill_data: SkillData, level: int)

const AREA_EFFECT_SCENE := preload("res://src/skill/skill_area_effect.tscn")

@export var stats: Resource = null               ## PlayerStats
@export var buff_system: Node = null             ## BuffSystem（BUFF_SELF 施加自身增益用）
@export var effect_container: Node2D = null      ## 技能效果挂载节点（World）
@export var projectile_container: Node2D = null  ## 弹幕挂载节点（复用 Projectiles）

var _skills: Array[Skill] = []
var _owner: Node2D


func _ready() -> void:
	_owner = get_parent() as Node2D
	if effect_container == null:
		effect_container = get_tree().current_scene
	if buff_system == null:
		buff_system = get_node_or_null("../BuffSystem")


func reset() -> void:
	for s in _skills:
		s.cooldown_remaining = 0.0


func clear_all() -> void:
	_skills.clear()


func has_skill(skill_id: String) -> bool:
	for s in _skills:
		if s.data.skill_id == skill_id:
			return true
	return false


func get_skill(skill_id: String) -> Skill:
	for s in _skills:
		if s.data.skill_id == skill_id:
			return s
	return null


## 习得新技能（SkillSystem 侧）
func learn(data: SkillData) -> bool:
	if has_skill(data.skill_id):
		return false
	var s := Skill.new(data)
	_skills.append(s)
	skill_learned.emit(data, s.level)
	return true


## 升级已有技能
func upgrade(skill_id: String) -> bool:
	var s := get_skill(skill_id)
	if s == null:
		return false
	s.upgrade()
	skill_leveled.emit(s.data, s.level)
	return true


func get_owned_skills() -> Array[Skill]:
	return _skills.duplicate()


func _process(delta: float) -> void:
	for s in _skills:
		s.tick(delta)
		if s.is_ready():
			_cast_if_valid(s)


## 满足条件时施放：范围/目标技能需存在敌人或朝最近敌人；无目标要求（HEAL/BUFF_SELF）直接放
func _cast_if_valid(s: Skill) -> void:
	match int(s.data.type):
		SkillData.SkillType.HEAL, SkillData.SkillType.BUFF_SELF:
			_cast(s)
		_:
			if _nearest_enemy() != null:
				_cast(s)


func _cast(s: Skill) -> void:
	_execute(s)
	s.start_cooldown(stats)
	skill_cast.emit(s.data, s.level)


func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e):
			continue
		var d := _owner.global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


# ---------------------------------------------------------------------------
# 施放分发
# ---------------------------------------------------------------------------

func _execute(s: Skill) -> void:
	var d := s.data
	var level := s.level
	match int(d.type):
		SkillData.SkillType.NOVA:
			_cast_nova(d, level)
		SkillData.SkillType.WHIRLWIND:
			_cast_whirlwind(d, level)
		SkillData.SkillType.ZONE:
			_cast_zone(d, level)
		SkillData.SkillType.VOLLEY:
			_cast_volley(d, level)
		SkillData.SkillType.HEAL:
			_cast_heal(d, level)
		SkillData.SkillType.BUFF_SELF:
			_cast_buff_self(d, level)
		SkillData.SkillType.DEBUFF_AOE:
			_cast_debuff_aoe(d, level)


func _spawn_area(pos: Vector2, d: SkillData, level: int, follow: bool, debuff: BuffData) -> void:
	if effect_container == null:
		return
	var node := AREA_EFFECT_SCENE.instantiate()
	effect_container.add_child(node)
	node.global_position = pos
	node.setup(d.get_damage(level), d.get_radius(level), d.get_duration(level), d.hit_interval, follow, debuff, d.color)


func _cast_nova(d: SkillData, level: int) -> void:
	_spawn_area(_owner.global_position, d, level, false, d.apply_buff)


func _cast_whirlwind(d: SkillData, level: int) -> void:
	_spawn_area(_owner.global_position, d, level, true, d.apply_buff)


func _cast_zone(d: SkillData, level: int) -> void:
	var target := _nearest_enemy()
	var pos := target.global_position if target != null else _owner.global_position
	_spawn_area(pos, d, level, false, d.apply_buff)


func _cast_volley(d: SkillData, level: int) -> void:
	if d.projectile_scene == null:
		return
	var container := projectile_container if projectile_container != null else effect_container
	if container == null:
		return
	var count: int = maxi(2, d.projectile_count)
	var dmg: float = d.get_damage(level)
	for k in count:
		var angle := float(k) / float(count) * TAU
		var dir := Vector2(cos(angle), sin(angle))
		var p := d.projectile_scene.instantiate()
		container.add_child(p)
		p.global_position = _owner.global_position
		if p.has_method("setup"):
			p.setup(dmg, d.projectile_speed, d.projectile_pierce, dir)
		# 技能弹幕不池化，直接回收（否则 released 无人监听会泄漏）
		if p.has_signal("released"):
			p.released.connect(_free_projectile)


func _free_projectile(n: Node) -> void:
	if is_instance_valid(n):
		n.queue_free()


func _cast_heal(d: SkillData, level: int) -> void:
	if stats == null:
		return
	var amount: float = stats.max_health * d.get_heal_percent(level)
	if _owner.has_method("apply_heal"):
		_owner.apply_heal(amount)
	else:
		stats.current_health = minf(stats.max_health, stats.current_health + amount)
		if _owner.has_signal("health_changed"):
			_owner.health_changed.emit(stats.current_health, stats.max_health)


func _cast_buff_self(d: SkillData, level: int) -> void:
	if buff_system != null and buff_system.has_method("apply") and d.apply_buff != null:
		buff_system.apply(d.apply_buff)
	elif _owner.has_method("apply_buff") and d.apply_buff != null:
		_owner.apply_buff(d.apply_buff)


func _cast_debuff_aoe(d: SkillData, level: int) -> void:
	_spawn_area(_owner.global_position, d, level, false, d.apply_buff)
