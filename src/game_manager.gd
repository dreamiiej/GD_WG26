extends Node
## GameManager（文档 2.2 / 3.4）。
## 负责：玩家死亡、重开、敌人死亡后的经验宝石掉落。
## 刷怪生成计划交由 WaveManager（文档 3.4），本类只监听 enemy_spawned。

signal game_over
signal victory

@export var gem_scene: PackedScene
@export var item_pickup_scene: PackedScene    ## 道具拾取物
@export var max_enemies: int = 300
@export var spawn_margin: float = 60.0
@export var damage_number_scene: PackedScene   ## M6 浮动数字
@export_range(0.0, 1.0) var item_drop_chance: float = 0.03 ## 普通怪道具掉落概率

var _wave_manager: Node
var _player: Node2D
var _enemies_node: Node2D
var _pickups_node: Node2D
var _vfx_node: Node2D                          ## 浮动数字挂载处（World）
var _camera: Camera2D                          ## 屏幕震动
var _running := false
var _pool: ObjectPool                         ## M6 经验宝石/道具对象池
var _items: Array[ItemData] = []              ## 道具池（10 种）


func attach_wave_manager(wm: Node) -> void:
	_wave_manager = wm
	if wm != null and wm.has_signal("enemy_spawned"):
		wm.enemy_spawned.connect(_on_enemy_spawned)


func _ready() -> void:
	_pool = ObjectPool.new()
	add_child(_pool)
	_items = ItemData.build_default_items()


func start(p_player: Node2D, p_enemies_node: Node2D, p_pickups_node: Node2D = null) -> void:
	_player = p_player
	_enemies_node = p_enemies_node
	_pickups_node = p_pickups_node
	_vfx_node = p_pickups_node.get_parent() if p_pickups_node != null else null
	_camera = get_viewport().get_camera_2d() as Camera2D
	_running = true
	for e in _enemies_node.get_children():
		e.queue_free()
	_recycle_all_gems()
	if _wave_manager != null:
		_wave_manager.max_enemies = max_enemies
		_wave_manager.spawn_margin = spawn_margin
		_wave_manager.start(_player, _enemies_node)


func _on_enemy_spawned(enemy: Node) -> void:
	if enemy != null and enemy.has_signal("enemy_died"):
		enemy.enemy_died.connect(_on_enemy_died)


func _on_enemy_died(enemy: Node) -> void:
	# 道具掉落（精英/BOSS 必掉，普通怪按概率）
	_maybe_drop_item(enemy)
	# v2 M7：关底 BOSS 死亡 → 当前关卡胜利
	if enemy != null and enemy.data != null and enemy.data.is_boss:
		on_boss_defeated()
		return
	# M3：敌人死亡掉落经验宝石（文档 3.5）
	if gem_scene == null or _pickups_node == null:
		return
	var gem: Area2D = _pool.obtain(gem_scene, _pickups_node)
	if gem == null:
		return
	var exp_val := 1
	if enemy.has_method("get_exp_value"):
		exp_val = enemy.get_exp_value()
	gem.setup(exp_val, _player, _player.get_pickup_range() if _player.has_method("get_pickup_range") else 60.0)
	gem.global_position = enemy.global_position
	gem.picked_up.connect(_on_gem_picked)
	gem.released.connect(_on_gem_released)
	# M6 反馈：浮动经验数字 + 屏幕震动（精英更明显）
	_spawn_damage_number("+%d" % exp_val, enemy.global_position, Color(0.3, 1, 0.6, 1))
	if _camera != null and _camera.has_method("shake"):
		var big := exp_val >= 8
		_camera.shake(0.35 if big else 0.08)


func _spawn_damage_number(text: String, pos: Vector2, color: Color) -> void:
	if damage_number_scene == null or _vfx_node == null:
		return
	var dn: Node2D = damage_number_scene.instantiate()
	dn.setup(text, color)
	dn.global_position = pos
	_vfx_node.add_child(dn)


func _on_gem_picked(amount: int) -> void:
	if _player != null and _player.has_method("gain_exp"):
		_player.gain_exp(amount)


func _on_gem_released(gem: Node) -> void:
	if gem.is_connected("picked_up", _on_gem_picked):
		gem.picked_up.disconnect(_on_gem_picked)
	if gem.is_connected("released", _on_gem_released):
		gem.released.disconnect(_on_gem_released)
	_pool.release(gem, gem_scene)


func _recycle_all_gems() -> void:
	if _pickups_node == null:
		return
	for g in _pickups_node.get_children():
		if not is_instance_valid(g) or not g.has_signal("released"):
			continue
		# 道具拾取物与经验宝石都带 released 信号；按脚本路径区分回收
		var scr: Script = g.get_script()
		if scr != null and scr.resource_path.ends_with("item_pickup.gd"):
			_on_item_released(g)
		else:
			_on_gem_released(g)


# ===================== 道具系统 =====================

## 根据敌人类型判定掉落概率并生成道具拾取物
func _maybe_drop_item(enemy: Node) -> void:
	if enemy == null or item_pickup_scene == null or _pickups_node == null:
		return
	if _items.is_empty():
		return
	var chance := item_drop_chance
	if enemy.data != null and (enemy.data.is_elite or enemy.data.is_boss):
		chance = 1.0
	if randf() > chance:
		return
	var data: ItemData = _items[randi() % _items.size()]
	var item: Area2D = _pool.obtain(item_pickup_scene, _pickups_node)
	if item == null:
		return
	item.setup(data, _player, _player.get_pickup_range() if _player != null and _player.has_method("get_pickup_range") else 60.0)
	item.global_position = enemy.global_position
	item.picked_up.connect(_on_item_picked)
	item.released.connect(_on_item_released)
	# 反馈：提示文字 + 音效
	if data.display_name != "":
		_spawn_damage_number(data.display_name, enemy.global_position + Vector2(0, -18), data.color)
	if _camera != null and _camera.has_method("shake"):
		_camera.shake(0.05)


func _on_item_picked(data: ItemData) -> void:
	if data == null or _player == null:
		return
	_apply_item(data)
	# 反馈音效
	var sfx: Node = get_tree().get_first_node_in_group("sfx")
	if sfx != null and sfx.has_method("play_pickup"):
		sfx.play_pickup()


func _apply_item(data: ItemData) -> void:
	var stats: Resource = _player.stats
	if stats == null:
		return
	match int(data.item_type):
		ItemData.ItemType.HEAL:
			stats.current_health = minf(stats.max_health, stats.current_health + stats.max_health * data.value / 100.0)
			if _player.has_signal("health_changed"):
				_player.health_changed.emit(stats.current_health, stats.max_health)
		ItemData.ItemType.SPEED:
			stats.apply_temp_mult("move_speed", 1.0 + data.value, data.duration)
		ItemData.ItemType.MAGNET:
			stats.apply_temp_add("pickup_range", data.value, data.duration)
		ItemData.ItemType.SHIELD:
			if _player.has_method("grant_invincibility"):
				_player.grant_invincibility(data.duration)
		ItemData.ItemType.EXP:
			if _player.has_method("gain_exp"):
				_player.gain_exp(int(data.value))
		ItemData.ItemType.BOMB:
			_damage_enemies_in_radius(_player.global_position, data.radius, data.value)
		ItemData.ItemType.BERSERK:
			stats.apply_temp_mult("damage_multiplier", 1.0 + data.value, data.duration)
		ItemData.ItemType.HASTE:
			stats.apply_temp_add("cooldown_reduction", data.value, data.duration)
		ItemData.ItemType.ARMOR:
			stats.apply_temp_mult("incoming_damage_mult", 1.0 - data.value, data.duration)
		ItemData.ItemType.CLEAR:
			_damage_all_enemies(data.value)


## 范围伤害（爆破雷管）
func _damage_enemies_in_radius(center: Vector2, radius: float, amount: float) -> void:
	if _enemies_node == null:
		return
	for e in _enemies_node.get_children():
		if is_instance_valid(e) and e.global_position.distance_to(center) <= radius and e.has_method("take_damage"):
			e.take_damage(amount)


## 清屏伤害（圣光净世）
func _damage_all_enemies(amount: float) -> void:
	if _enemies_node == null:
		return
	for e in _enemies_node.get_children():
		if is_instance_valid(e) and e.has_method("take_damage"):
			e.take_damage(amount)


func _on_item_released(item: Node) -> void:
	if item.is_connected("picked_up", _on_item_picked):
		item.picked_up.disconnect(_on_item_picked)
	if item.is_connected("released", _on_item_released):
		item.released.disconnect(_on_item_released)
	_pool.release(item, item_pickup_scene)


func on_player_died() -> void:
	_running = false
	if _wave_manager != null:
		_wave_manager.stop()
	# 死亡后暂停世界（敌人/子弹/计时器冻结），重开时由 main._start_run 解除。
	get_tree().paused = true
	game_over.emit()


## v2 M7：击败关底 BOSS → 结束当前关卡（胜利结算）
func on_boss_defeated() -> void:
	_running = false
	if _wave_manager != null:
		_wave_manager.stop()
	# 清理剩余敌人
	if _enemies_node != null:
		for e in _enemies_node.get_children():
			e.queue_free()
	_recycle_all_gems()
	get_tree().paused = true
	victory.emit()
