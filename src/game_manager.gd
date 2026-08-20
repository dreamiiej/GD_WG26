extends Node
## GameManager（文档 2.2 / 3.4）。
## 负责：玩家死亡、重开、敌人死亡后的经验宝石掉落。
## 刷怪生成计划交由 WaveManager（文档 3.4），本类只监听 enemy_spawned。

signal game_over

@export var gem_scene: PackedScene
@export var max_enemies: int = 300
@export var spawn_margin: float = 60.0
@export var damage_number_scene: PackedScene   ## M6 浮动数字

var _wave_manager: Node
var _player: Node2D
var _enemies_node: Node2D
var _pickups_node: Node2D
var _vfx_node: Node2D                          ## 浮动数字挂载处（World）
var _camera: Camera2D                          ## 屏幕震动
var _running := false
var _pool: ObjectPool                         ## M6 经验宝石对象池


func attach_wave_manager(wm: Node) -> void:
	_wave_manager = wm
	if wm != null and wm.has_signal("enemy_spawned"):
		wm.enemy_spawned.connect(_on_enemy_spawned)


func _ready() -> void:
	_pool = ObjectPool.new()
	add_child(_pool)


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
		_on_gem_released(g)


func on_player_died() -> void:
	_running = false
	if _wave_manager != null:
		_wave_manager.stop()
	# 死亡后暂停世界（敌人/子弹/计时器冻结），重开时由 main._start_run 解除。
	get_tree().paused = true
	game_over.emit()
