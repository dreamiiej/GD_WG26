extends Node
## WaveManager（文档 3.4）。按时间驱动波次，难度随时间递增。
## 不直接控制敌人 AI，只管理"生成计划"。生成时把倍率应用到克隆的 EnemyData。
## v2 M7：额外按绝对时间刷出精英（每 elite_interval 秒）与关底 BOSS（boss_time 秒）。

signal wave_changed(wave_index: int)
signal enemy_spawned(enemy: Node)
signal elite_spawned(enemy: Node)
signal boss_spawned(enemy: Node)

@export var base_enemy_data: EnemyData
@export var wave_table: WaveTable
@export var wave_duration: float = 30.0
## 精英/BOSS 专用场景与数据（数据驱动，不改逻辑）
@export var elite_enemy_scene: PackedScene
@export var elite_enemy_data: EnemyData
@export var boss_enemy_scene: PackedScene
@export var boss_enemy_data: EnemyData
@export var elite_interval: float = 180.0    ## 每 3 分钟刷一只精英
@export var boss_time: float = 720.0         ## 第 12 分钟刷关底 BOSS

var _player: Node2D
var _enemies_node: Node2D
@export var spawn_margin: float = 60.0
@export var max_enemies: int = 300

var _running := false
var _wave_index: int = 0
var _wave_timer: float = 0.0
var _spawn_timer: float = 0.0
var _current: WaveConfig
var _elapsed: float = 0.0                    ## 真实运行时间（pause 不冻结）
var _next_elite_time: float = 180.0
var _boss_spawned := false
var _clock: Node                             ## RunClock（PROCESS_MODE_ALWAYS）

## 局外内容 M9：当前难度倍率（由 main 通过 apply_difficulty 注入）
var _difficulty: DifficultyConfig = null


func _ready() -> void:
	_clock = load("res://src/run_clock.gd").new()
	add_child(_clock)
	_clock.tick.connect(_on_run_tick)


func _on_run_tick(delta: float) -> void:
	if not _running:
		return
	_elapsed += delta
	# 精英：达到下一个 3 分钟整点刷出（3/6/9 分钟）
	if _next_elite_time <= _elapsed:
		_spawn_elite()
		_next_elite_time += elite_interval
	# 关底 BOSS：到 boss_time 刷一次
	if not _boss_spawned and _elapsed >= boss_time:
		_boss_spawned = true
		_spawn_boss()


func start(p_player: Node2D, p_enemies_node: Node2D) -> void:
	_player = p_player
	_enemies_node = p_enemies_node
	_running = true
	_wave_index = 0
	_wave_timer = wave_duration
	_elapsed = 0.0
	_next_elite_time = elite_interval
	_boss_spawned = false
	_apply_wave(0)


func stop() -> void:
	_running = false


func _process(delta: float) -> void:
	if not _running or _player == null or wave_table == null or wave_table.waves.is_empty():
		return
	_wave_timer -= delta
	if _wave_timer <= 0.0:
		_wave_index = min(_wave_index + 1, wave_table.waves.size() - 1)
		_wave_timer = wave_duration
		_apply_wave(_wave_index)

	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and _enemies_node.get_child_count() < max_enemies:
		var interval := _current.spawn_interval
		if _difficulty != null:
			interval *= _difficulty.spawn_interval_mult
		_spawn_timer = interval
		_spawn_enemy()


func _apply_wave(idx: int) -> void:
	_current = wave_table.waves[idx]
	_spawn_timer = 0.0
	wave_changed.emit(idx)


## 局外内容 M9：应用难度倍率（main 在开局时调用）
func apply_difficulty(cfg: DifficultyConfig) -> void:
	_difficulty = cfg
	if cfg == null:
		return
	if cfg.max_enemies > 0:
		max_enemies = cfg.max_enemies


## 调试用：返回当前应用难度的 id
func get_debug_difficulty() -> String:
	return _difficulty.id if _difficulty != null else "none"


func _spawn_elite() -> void:
	var e := _instantiate_special(elite_enemy_scene, elite_enemy_data)
	if e == null:
		return
	elite_spawned.emit(e)


func _spawn_boss() -> void:
	var e := _instantiate_special(boss_enemy_scene, boss_enemy_data)
	if e == null:
		return
	boss_spawned.emit(e)


## 通用：克隆数据并按绝对血量倍数生成精英/BOSS（不随波次倍率叠加）
func _instantiate_special(scene: PackedScene, data_ref: EnemyData) -> Node2D:
	if scene == null:
		return null
	var e: Node2D = scene.instantiate()
	var base := data_ref if data_ref != null else base_enemy_data
	var d: EnemyData = base.duplicate()
	# 局外内容 M9：应用难度对精英/BOSS 的血量倍率
	if _difficulty != null:
		d.max_health *= _difficulty.elite_boss_health_mult
	if d.current_health <= 0.0:
		d.current_health = d.max_health
	e.data = d
	e.global_position = _random_offscreen_position()
	_enemies_node.add_child(e)
	enemy_spawned.emit(e)
	return e


func _spawn_enemy() -> void:
	var use_extra := _current.extra_enemy_scene != null and randf() < _current.extra_chance
	var scene := _current.extra_enemy_scene if use_extra else _current.enemy_scene
	var data_ref := _current.extra_enemy_data if use_extra else _current.enemy_data
	if scene == null:
		scene = _current.enemy_scene
	if scene == null:
		return
	var e: Node2D = scene.instantiate()
	var base := data_ref if data_ref != null else base_enemy_data
	var d: EnemyData = base.duplicate()
	d.max_health *= _current.health_mult
	d.move_speed *= _current.speed_mult
	d.contact_damage *= _current.damage_mult
	d.exp_value = int(d.exp_value * _current.exp_mult)
	# 局外内容 M9：应用难度倍率（血量 / 移速 / 经验）
	if _difficulty != null:
		d.max_health *= _difficulty.enemy_health_mult
		d.move_speed *= _difficulty.enemy_speed_mult
		d.exp_value = int(d.exp_value * _difficulty.exp_mult)
	e.data = d
	e.global_position = _random_offscreen_position()
	_enemies_node.add_child(e)
	enemy_spawned.emit(e)


func _random_offscreen_position() -> Vector2:
	var cam := get_viewport().get_camera_2d()
	var view := get_viewport().get_visible_rect().size
	var half := view * 0.5 + Vector2(spawn_margin, spawn_margin)
	var side := randi() % 4
	var pos := Vector2.ZERO
	match side:
		0: pos = cam.global_position + Vector2(randf_range(-half.x, half.x), -half.y)
		1: pos = cam.global_position + Vector2(randf_range(-half.x, half.x), half.y)
		2: pos = cam.global_position + Vector2(-half.x, randf_range(-half.y, half.y))
		_: pos = cam.global_position + Vector2(half.x, randf_range(-half.y, half.y))
	# 确保刷怪点落在战场边界内（含内缩），避免刷到墙外
	var bf := get_tree().get_first_node_in_group("battlefield")
	if bf != null and bf.has_method("get_spawn_bounds"):
		var rb: Rect2 = bf.get_spawn_bounds()
		pos.x = clampf(pos.x, rb.position.x, rb.end.x)
		pos.y = clampf(pos.y, rb.position.y, rb.end.y)
	return pos
