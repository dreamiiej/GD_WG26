extends Node
## WeaponManager（文档 3.2）。统一管理所有武器，按冷却自动攻击。
## M5 扩展：支持发射型 / 光环型 / 近战型三类武器，
## 并支持升级系统解锁新武器、强化已有武器（upgrade_weapon）。
## 寻找最近敌人做了节流（默认 0.15s），避免每帧全量查找（文档 4.2）。

@export var stats: PlayerStats
@export var projectile_container: Node2D
@export var aura_container: Node2D
@export var default_weapon: WeaponData

var _weapons: Array[WeaponData] = []
var _damage_mult: Array[float] = []   ## 每把武器的伤害倍率（升级强化用）
var _cooldowns: Array[float] = []
var _aura_nodes: Array[Area2D] = []   ## AURA/MELEE 常驻效果节点
var _target_query_timer: float = 0.0
var _cached_target: Node2D = null
var _owner: Node2D
var _pool: ObjectPool                       ## M6 子弹对象池


func _ready() -> void:
	_owner = get_node_or_null("../Player")
	if _owner == null:
		_owner = get_parent()
	_pool = ObjectPool.new()
	add_child(_pool)
	if default_weapon != null:
		add_weapon(default_weapon)


func reset() -> void:
	for n in _aura_nodes:
		if is_instance_valid(n):
			n.queue_free()
	# 回收所有在场子弹
	for p in projectile_container.get_children():
		_release_projectile(p)
	_weapons.clear()
	_damage_mult.clear()
	_cooldowns.clear()
	_aura_nodes.clear()
	if default_weapon != null:
		add_weapon(default_weapon)


func has_weapon(weapon_id: String) -> bool:
	for w in _weapons:
		if w.weapon_id == weapon_id:
			return true
	return false


func add_weapon(data: WeaponData) -> void:
	if has_weapon(data.weapon_id):
		return
	_weapons.append(data)
	_damage_mult.append(1.0)
	_cooldowns.append(0.0)
	if data.weapon_type != WeaponData.WeaponType.PROJECTILE:
		_spawn_aura_node(data)


## 升级系统调用：强化某把武器（value 为倍率增量，如 0.2 = +20% 伤害）
func upgrade_weapon(weapon_id: String, value: float) -> void:
	for i in _weapons.size():
		if _weapons[i].weapon_id == weapon_id:
			_damage_mult[i] += value
			return


func _spawn_aura_node(data: WeaponData) -> void:
	var node: Area2D
	if data.effect_scene != null:
		node = data.effect_scene.instantiate()
	else:
		node = Area2D.new()
		var poly := Polygon2D.new()
		poly.color = Color(0.6, 0.8, 1.0, 0.2)
		var pts: PackedVector2Array = []
		var n := 24
		for k in n:
			var a := float(k) / float(n) * TAU
			pts.append(Vector2(cos(a), sin(a)) * data.radius)
		poly.polygon = pts
		node.add_child(poly)
	var shape := CircleShape2D.new()
	shape.radius = data.radius
	var cs := CollisionShape2D.new()
	cs.shape = shape
	node.add_child(cs)
	node.collision_layer = 0
	node.collision_mask = 2
	node.monitoring = true
	_owner.add_child(node)
	_aura_nodes.append(node)


func _process(delta: float) -> void:
	_target_query_timer -= delta
	if _target_query_timer <= 0.0:
		_target_query_timer = 0.15
		_cached_target = _find_nearest_enemy()

	for i in _weapons.size():
		_cooldowns[i] -= delta
		if _cooldowns[i] > 0.0:
			continue
		var cd := _weapons[i].cooldown * (1.0 - clampf(stats.cooldown_reduction, 0.0, 0.9))
		_cooldowns[i] = cd
		match int(_weapons[i].weapon_type):
			WeaponData.WeaponType.PROJECTILE:
				if _cached_target != null:
					_fire_projectile(_weapons[i], _damage_mult[i])
			WeaponData.WeaponType.AURA:
				_tick_area_damage(_weapons[i], _damage_mult[i], _aura_nodes[i] if i < _aura_nodes.size() else null)
			WeaponData.WeaponType.MELEE:
				_tick_area_damage(_weapons[i], _damage_mult[i], _aura_nodes[i] if i < _aura_nodes.size() else null)


func _find_nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e):
			continue
		var d := _owner.global_position.distance_squared_to(e.global_position)
		if d < best_dist:
			best_dist = d
			best = e
	return best


func _fire_projectile(data: WeaponData, dmg_mult: float) -> void:
	var origin := _owner.global_position
	var base_dir := (_cached_target.global_position - origin).normalized()
	var count: int = max(1, data.projectile_count)
	for k in count:
		var spread := deg_to_rad(data.spread_deg)
		var offset := 0.0
		if count > 1:
			offset = lerp(-spread * 0.5, spread * 0.5, float(k) / float(count - 1))
		var dir := base_dir.rotated(offset)
		var p: Area2D = _pool.obtain(data.projectile_scene, projectile_container)
		if p == null:
			continue
		p.set_meta("pool_scene", data.projectile_scene)
		if not p.is_connected("released", _on_projectile_released):
			p.released.connect(_on_projectile_released)
		p.global_position = origin
		p.setup(data.damage * stats.damage_multiplier * dmg_mult, data.projectile_speed, data.pierce, dir)


func _on_projectile_released(node: Node) -> void:
	var scene: PackedScene = node.get_meta("pool_scene", null)
	_pool.release(node, scene)


func _release_projectile(node: Node) -> void:
	if node.is_connected("released", _on_projectile_released):
		node.released.disconnect(_on_projectile_released)
	var scene: PackedScene = node.get_meta("pool_scene", null)
	_pool.release(node, scene)


## 对光环/近战范围节点内的敌人造成伤害（每 cooldown 一次）
func _tick_area_damage(data: WeaponData, dmg_mult: float, node: Area2D) -> void:
	if node == null:
		return
	var dmg := data.damage * stats.damage_multiplier * dmg_mult
	for area in node.get_overlapping_areas():
		var parent := area.get_parent()
		if parent != null and parent.is_in_group("enemy") and parent.has_method("take_damage"):
			parent.take_damage(dmg)
	for body in node.get_overlapping_bodies():
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			body.take_damage(dmg)
