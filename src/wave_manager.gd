extends Node
## WaveManager（文档 3.4）。按时间驱动波次，难度随时间递增。
## 不直接控制敌人 AI，只管理"生成计划"。生成时把倍率应用到克隆的 EnemyData。

signal wave_changed(wave_index: int)
signal enemy_spawned(enemy: Node)

@export var base_enemy_data: EnemyData
@export var wave_table: WaveTable
@export var wave_duration: float = 30.0

var _player: Node2D
var _enemies_node: Node2D
@export var spawn_margin: float = 60.0
@export var max_enemies: int = 300

var _running := false
var _wave_index: int = 0
var _wave_timer: float = 0.0
var _spawn_timer: float = 0.0
var _current: WaveConfig


func start(p_player: Node2D, p_enemies_node: Node2D) -> void:
	_player = p_player
	_enemies_node = p_enemies_node
	_running = true
	_wave_index = 0
	_wave_timer = wave_duration
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
		_spawn_timer = _current.spawn_interval
		_spawn_enemy()


func _apply_wave(idx: int) -> void:
	_current = wave_table.waves[idx]
	_spawn_timer = 0.0
	wave_changed.emit(idx)


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
	e.data = d
	e.global_position = _random_offscreen_position()
	_enemies_node.add_child(e)
	enemy_spawned.emit(e)


func _random_offscreen_position() -> Vector2:
	var cam := get_viewport().get_camera_2d()
	var view := get_viewport().get_visible_rect().size
	var half := view * 0.5 + Vector2(spawn_margin, spawn_margin)
	var side := randi() % 4
	match side:
		0: return cam.global_position + Vector2(randf_range(-half.x, half.x), -half.y)
		1: return cam.global_position + Vector2(randf_range(-half.x, half.x), half.y)
		2: return cam.global_position + Vector2(-half.x, randf_range(-half.y, half.y))
		_: return cam.global_position + Vector2(half.x, randf_range(-half.y, half.y))
