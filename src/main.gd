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
@onready var _battlefield: Node2D = $World/Battlefield
@onready var _flow_field: Node2D = $World/FlowField
@onready var _camera: Camera2D = $World/Camera2D

var _full_pool: Array[UpgradeData] = []
var _weapon_upgrade_stacks: Dictionary = {}   ## weapon_id -> 已强化层数
var _skill_upgrade_stacks: Dictionary = {}    ## skill_id -> 已升级层数
var _acquired: Array[Dictionary] = []         ## 已选择的技能（供 HUD 技能列表展示）
var _run_elapsed: float = 0.0                 ## 本局存活时间（结算存档用）
var _run_active: bool = false                 ## 本局是否进行中（用于累计存活时间）
var _difficulty_retries: int = 0              ## 难度应用重试计数
var _skill_map: Dictionary = {}               ## skill_id -> SkillData


func _ready() -> void:
	_player.health_changed.connect(_hud.update_health)
	_player.exp_changed.connect(_hud.update_exp)
	_player.player_died.connect(_on_player_died)
	_player.request_level_up.connect(_on_request_level_up)
	_game_manager.game_over.connect(_on_game_over)
	_game_manager.victory.connect(_on_victory)
	_game_over.restart_requested.connect(_restart)
	_game_over.menu_requested.connect(_on_menu_requested)
	_level_up.upgrade_chosen.connect(_on_upgrade_chosen)
	# 升级池（文档 3.5，数据驱动）
	_full_pool = UpgradePool.build_default_pool()
	# Dota2 风格技能池
	_skill_map = SkillPool.skill_map()
	_wire_skill_system()
	# 波次系统（文档 3.4）：GameManager 监听 WaveManager 生成
	_game_manager.attach_wave_manager(_wave_manager)
	_wave_manager.wave_changed.connect(_hud.update_wave)
	# v2 M7：精英/BOSS 刷出 → 顶部血条
	_wave_manager.elite_spawned.connect(_hud.track_elite)
	_wave_manager.boss_spawned.connect(_hud.track_elite)
	# 流场寻路：基于战场矩形与玩家建立导航
	if _battlefield != null and _flow_field != null and _flow_field.has_method("setup"):
		_flow_field.setup(_battlefield.bounds, _player)
	_start_run()


## 相机跟随玩家中心，边界由相机 limit 限制在战场内
func _process(delta: float) -> void:
	if _camera != null and is_instance_valid(_player):
		_camera.global_position = _player.global_position
	if _run_active:
		_run_elapsed += delta


func _start_run() -> void:
	_player.finish_level_up()
	_player.stats.reset()
	_player.health_changed.emit(_player.stats.current_health, _player.stats.max_health)
	_player.exp_changed.emit(_player.stats.xp, _player.stats.exp_to_next, _player.stats.level)
	_weapon_manager.stats = _player.stats
	_weapon_manager.reset()
	_weapon_upgrade_stacks.clear()
	_skill_upgrade_stacks.clear()
	_acquired.clear()
	# 重置 Buff / 技能系统
	var buff: Node = _player.get_buff_system()
	if buff != null and buff.has_method("reset"):
		buff.reset()
	var skillsys: Node = _player.get_skill_system()
	if skillsys != null and skillsys.has_method("clear_all"):
		skillsys.clear_all()
	_refresh_skillbar()
	_run_elapsed = 0.0
	_run_active = true
	_hud.reset_time()
	_hud.update_wave(0)
	_hud.update_skills(_acquired)
	# 局外内容 M9：从 GameFlow 读取当前难度并应用到刷怪
	_apply_difficulty()
	get_tree().paused = false
	_game_manager.start(_player, _enemies, _pickups)


## 接线技能系统：设置效果/弹幕挂载节点，连接施放信号到 HUD
func _wire_skill_system() -> void:
	var skillsys: Node = _player.get_skill_system()
	if skillsys == null:
		return
	skillsys.effect_container = $World
	skillsys.projectile_container = $World/Projectiles
	skillsys.stats = _player.stats
	var buff: Node = _player.get_buff_system()
	if buff != null:
		skillsys.buff_system = buff
	if skillsys.has_signal("skill_cast") and not skillsys.skill_cast.is_connected(_on_skill_cast):
		skillsys.skill_cast.connect(_on_skill_cast)


func _on_skill_cast(skill_data: SkillData, level: int) -> void:
	if _hud != null and _hud.has_method("flash_skill"):
		_hud.flash_skill(skill_data.skill_id)


## 用当前已习得技能刷新底部技能栏
func _refresh_skillbar() -> void:
	var skillsys: Node = _player.get_skill_system()
	if _hud == null:
		return
	if skillsys == null or not skillsys.has_method("get_owned_skills"):
		_hud.update_skillbar([])
		return
	_hud.update_skillbar(skillsys.get_owned_skills())


## 局外内容 M9：读取 GameFlow 当前难度并应用到 WaveManager
func _apply_difficulty() -> void:
	if not _flow_valid():
		_difficulty_retries += 1
		if _difficulty_retries <= 600:
			call_deferred("_apply_difficulty")
		return
	_difficulty_retries = 0
	var cfg: Resource = _game_flow().current_difficulty
	if cfg == null:
		return
	if _wave_manager != null and _wave_manager.has_method("apply_difficulty"):
		_wave_manager.apply_difficulty(cfg)


func _flow_valid() -> bool:
	return _game_flow() != null


## GameFlow 为自动加载单例，从场景树根节点访问
func _game_flow() -> Node:
	if get_tree() == null:
		return null
	return get_tree().root.get_node_or_null("GameFlow")


func _on_request_level_up() -> void:
	get_tree().paused = true
	_level_up.pool = _build_available_upgrades()
	_level_up.show_choices()


## 根据当前状态过滤可用升级项（已解锁武器不再出现，强化层数达上限移除；技能同理）
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
		elif u.type == UpgradeData.UpgradeType.SKILL:
			var skillsys: Node = _player.get_skill_system()
			var owned: bool = skillsys != null and skillsys.has_skill(u.skill_id)
			if u.unlock_skill:
				if owned:
					continue
			else:
				if not owned:
					continue
				var sstacks: int = _skill_upgrade_stacks.get(u.skill_id, 0)
				if sstacks >= u.max_stacks:
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
		UpgradeData.UpgradeType.SKILL:
			if data.unlock_skill:
				_grant_skill(data.skill_id)
			else:
				_player.upgrade_skill(data.skill_id)
				_skill_upgrade_stacks[data.skill_id] = _skill_upgrade_stacks.get(data.skill_id, 0) + 1
	_player.health_changed.emit(_player.stats.current_health, _player.stats.max_health)
	# 记录已选技能并刷新 HUD 技能列表 + 底部技能栏
	_record_acquired(data)
	_hud.update_skills(_acquired)
	_refresh_skillbar()
	_player.finish_level_up()
	# M6 反馈：升级音效
	var sfx := get_tree().get_first_node_in_group("sfx")
	if sfx != null and sfx.has_method("play_levelup"):
		sfx.play_levelup()


## 记录本次选择的升级项到技能列表（相同武器/技能强化会累加显示层数）
func _record_acquired(data: UpgradeData) -> void:
	var type_tag := "weapon"
	match int(data.type):
		UpgradeData.UpgradeType.WEAPON:
			type_tag = "weapon"
		UpgradeData.UpgradeType.SKILL:
			type_tag = "skill"
		_:
			type_tag = "stat"
	var title := data.title
	var display_key := data.title
	if data.type == UpgradeData.UpgradeType.WEAPON and not data.unlock_weapon:
		var wstacks: int = _weapon_upgrade_stacks.get(data.weapon_id, 0)
		title = "%s  Lv.%d" % [data.title, wstacks]
		display_key = data.title
	elif data.type == UpgradeData.UpgradeType.SKILL and not data.unlock_skill:
		var sstacks: int = _skill_upgrade_stacks.get(data.skill_id, 0)
		title = "%s  Lv.%d" % [data.title, sstacks + 1]
		display_key = data.skill_id
	elif data.type == UpgradeData.UpgradeType.SKILL:
		display_key = data.skill_id
	# 若已存在同名技能（仅强化叠加），更新描述，避免重复行
	for i in _acquired.size():
		if _acquired[i].get("key", "") == display_key and _acquired[i].get("type", "") == type_tag:
			_acquired[i] = {"key": display_key, "title": title, "description": data.description, "type": type_tag}
			return
	_acquired.append({"key": display_key, "title": title, "description": data.description, "type": type_tag})


## 解锁新武器（按 weapon_id 查找数据资源并交给 WeaponManager）
func _grant_weapon(weapon_id: String) -> void:
	var data := _find_weapon_data(weapon_id)
	if data != null:
		_weapon_manager.add_weapon(data)


## 解锁新技能（按 skill_id 查找 SkillData 并交给玩家 SkillSystem）
func _grant_skill(skill_id: String) -> void:
	var data: SkillData = _skill_map.get(skill_id)
	if data != null:
		_player.learn_skill(data)


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


func _on_game_over() -> void:
	_run_active = false
	var level: int = _player.stats.level if _player != null and _player.stats != null else 0
	_game_over.show_result("游戏结束", _run_elapsed, level, false)


func _on_victory() -> void:
	_run_active = false
	var level: int = _player.stats.level if _player != null and _player.stats != null else 0
	_game_over.show_result("关卡胜利！", _run_elapsed, level, true)


func _on_menu_requested() -> void:
	var flow := _game_flow()
	if flow != null and flow.has_method("go_to_menu"):
		flow.go_to_menu()


func _restart() -> void:
	_start_run()
