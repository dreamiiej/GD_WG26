extends Node2D
## Main 场景根脚本（文档 2.1）。
## 负责组织 World / UI / GameManager / WeaponManager / WaveManager，连接玩家与游戏流程信号。

@onready var _player: Node2D = $World/Player
@onready var _enemies: Node2D = $World/Enemies
@onready var _pickups: Node2D = $World/Pickups
@onready var _weapon_manager: Node = $World/WeaponManager
@onready var _wave_manager: Node = $World/WaveManager
@onready var _game_manager: Node = $GameManager
@onready var _hud: CanvasLayer = $UI/HUD
@onready var _game_over: Control = $UI/GameOverPanel
@onready var _level_up: Control = $UI/LevelUpPanel

var _full_pool: Array[UpgradeData] = []
var _weapon_upgrade_stacks: Dictionary = {}   ## weapon_id -> 已强化层数


func _ready() -> void:
	_player.health_changed.connect(_hud.update_health)
	_player.exp_changed.connect(_hud.update_exp)
	_player.player_died.connect(_on_player_died)
	_player.request_level_up.connect(_on_request_level_up)
	_game_manager.game_over.connect(_game_over.show_panel)
	_game_manager.victory.connect(_game_over.show_victory)
	_game_over.restart_requested.connect(_restart)
	_level_up.upgrade_chosen.connect(_on_upgrade_chosen)
	# 升级池（文档 3.5，数据驱动）
	_full_pool = UpgradePool.build_default_pool()
	# 波次系统（文档 3.4）：GameManager 监听 WaveManager 生成
	_game_manager.attach_wave_manager(_wave_manager)
	_wave_manager.wave_changed.connect(_hud.update_wave)
	# v2 M7：精英/BOSS 刷出 → 顶部血条
	_wave_manager.elite_spawned.connect(_hud.track_elite)
	_wave_manager.boss_spawned.connect(_hud.track_elite)
	_start_run()


func _start_run() -> void:
	_player.finish_level_up()
	_player.stats.reset()
	_player.health_changed.emit(_player.stats.current_health, _player.stats.max_health)
	_player.exp_changed.emit(_player.stats.xp, _player.stats.exp_to_next, _player.stats.level)
	_weapon_manager.stats = _player.stats
	_weapon_manager.reset()
	_weapon_upgrade_stacks.clear()
	_hud.reset_time()
	_hud.update_wave(0)
	get_tree().paused = false
	_game_manager.start(_player, _enemies, _pickups)


func _on_request_level_up() -> void:
	get_tree().paused = true
	_level_up.pool = _build_available_upgrades()
	_level_up.show_choices()


## 根据当前状态过滤可用升级项（已解锁武器不再出现，强化层数达上限移除）
func _build_available_upgrades() -> Array[UpgradeData]:
	var out: Array[UpgradeData] = []
	for u in _full_pool:
		if u.type == UpgradeData.UpgradeType.WEAPON:
			if u.unlock_weapon:
				if _weapon_manager.has_weapon(u.weapon_id):
					continue
			else:
				var stacks: int = _weapon_upgrade_stacks.get(u.weapon_id, 0)
				if stacks >= u.max_stacks:
					continue
		out.append(u)
	return out


func _on_upgrade_chosen(data: UpgradeData) -> void:
	match int(data.type):
		UpgradeData.UpgradeType.STAT:
			_player.stats.apply_upgrade(data)
		UpgradeData.UpgradeType.WEAPON:
			if data.unlock_weapon:
				_grant_weapon(data.weapon_id)
			else:
				_weapon_manager.upgrade_weapon(data.weapon_id, data.value)
				_weapon_upgrade_stacks[data.weapon_id] = _weapon_upgrade_stacks.get(data.weapon_id, 0) + 1
	_player.health_changed.emit(_player.stats.current_health, _player.stats.max_health)
	_player.finish_level_up()
	# M6 反馈：升级音效
	var sfx := get_tree().get_first_node_in_group("sfx")
	if sfx != null and sfx.has_method("play_levelup"):
		sfx.play_levelup()


## 解锁新武器（按 weapon_id 查找数据资源并交给 WeaponManager）
func _grant_weapon(weapon_id: String) -> void:
	var data := _find_weapon_data(weapon_id)
	if data != null:
		_weapon_manager.add_weapon(data)


func _find_weapon_data(weapon_id: String) -> WeaponData:
	# 已加载到场景的武器资源通过预置映射查找（避免遍历文件系统）
	var map := {
		"missile": preload("res://src/data/weapon_default.tres"),
		"multishot": preload("res://src/data/weapon_multishot.tres"),
		"aura": preload("res://src/data/weapon_aura.tres"),
	}
	return map.get(weapon_id, null)


func _on_player_died() -> void:
	_game_manager.on_player_died()


func _restart() -> void:
	_start_run()
