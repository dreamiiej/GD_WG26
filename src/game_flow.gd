extends Node
## GameFlow：局外内容流程状态（M9）。自动加载单例。
## 负责：主菜单/选难度/游戏场景切换、当前难度存取、进度存档（最佳成绩/难度解锁）。
## 难度解锁规则：通关（击败 BOSS 胜利）当前难度 → 解锁下一难度；初始仅解锁"简单"。

const SAVE_PATH := "user://save.cfg"
const DIFFICULTY_ORDER := ["easy", "normal", "hard"]

## 难度数据资源映射（数据驱动，id → DifficultyConfig）
const DIFFICULTY_RESOURCES := {
	"easy": preload("res://src/data/difficulty_easy.tres"),
	"normal": preload("res://src/data/difficulty_normal.tres"),
	"hard": preload("res://src/data/difficulty_hard.tres"),
}

## 职业数据资源映射（数据驱动，id → PlayerClass）
const CLASS_RESOURCES := {
	"warrior": preload("res://src/data/player_class_warrior.tres"),
	"mage": preload("res://src/data/player_class_mage.tres"),
	"ranger": preload("res://src/data/player_class_ranger.tres"),
}

## 当前选择的难度
var current_difficulty: DifficultyConfig = DIFFICULTY_RESOURCES["easy"]

## 当前选择的职业
var current_class: PlayerClass = CLASS_RESOURCES["warrior"]

## 已通关的难度集合（id → true），决定难度解锁
var _cleared: Dictionary = {}

## 最佳成绩缓存
var best_survive_time: float = 0.0
var best_level: int = 0
var total_games: int = 0
var total_wins: int = 0

## 收藏系统：已使用（解锁）过的战场道具（item_type int → true）。
## 玩家拾取并使用某道具后解锁，未解锁的道具在收藏界面置灰。
var _unlocked_items: Dictionary = {}


func _ready() -> void:
	add_to_group("game_flow")
	load_save()


# ---------------------------------------------------------------------------
# 存档
# ---------------------------------------------------------------------------

func load_save() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		_cleared.clear()
		return
	_cleared.clear()
	var cleared: Array = cfg.get_value("progress", "cleared", [])
	for id in cleared:
		_cleared[str(id)] = true
	_unlocked_items.clear()
	var unlocked: Array = cfg.get_value("progress", "unlocked_items", [])
	for t in unlocked:
		_unlocked_items[int(t)] = true
	best_survive_time = float(cfg.get_value("progress", "best_survive_time", 0.0))
	best_level = int(cfg.get_value("progress", "best_level", 0))
	total_games = int(cfg.get_value("progress", "total_games", 0))
	total_wins = int(cfg.get_value("progress", "total_wins", 0))


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "cleared", _cleared.keys())
	cfg.set_value("progress", "unlocked_items", _unlocked_items.keys())
	cfg.set_value("progress", "best_survive_time", best_survive_time)
	cfg.set_value("progress", "best_level", best_level)
	cfg.set_value("progress", "total_games", total_games)
	cfg.set_value("progress", "total_wins", total_wins)
	cfg.save(SAVE_PATH)


## 是否已解锁某难度
func is_unlocked(difficulty_id: String) -> bool:
	if difficulty_id == "easy":
		return true
	var prev := _prev_id(difficulty_id)
	return prev != "" and _cleared.has(prev)


## 是否已通关某难度
func is_cleared(difficulty_id: String) -> bool:
	return _cleared.has(difficulty_id)


func _prev_id(id: String) -> String:
	var idx := DIFFICULTY_ORDER.find(id)
	if idx <= 0:
		return ""
	return DIFFICULTY_ORDER[idx - 1]


## 记录一局结束：返回本局是否胜利，并据此解锁下一难度
func record_result(time_alive: float, level: int, victory: bool) -> void:
	total_games += 1
	if victory:
		total_wins += 1
		var id := current_difficulty.id if current_difficulty != null else "easy"
		if not _cleared.has(id):
			_cleared[id] = true
	best_survive_time = maxf(best_survive_time, time_alive)
	best_level = maxi(best_level, level)
	_save()


## 重置全部进度
func reset_progress() -> void:
	_cleared.clear()
	_unlocked_items.clear()
	best_survive_time = 0.0
	best_level = 0
	total_games = 0
	total_wins = 0
	var cfg := ConfigFile.new()
	cfg.save(SAVE_PATH)
	load_save()


# ---------------------------------------------------------------------------
# 收藏系统
# ---------------------------------------------------------------------------

## 记录玩家使用过某道具（拾取即视为使用），解锁对应收藏条目并写盘。
func unlock_item(item_type: int) -> void:
	if _unlocked_items.has(item_type):
		return
	_unlocked_items[item_type] = true
	_save()


## 某道具是否已解锁（使用过）
func is_item_unlocked(item_type: int) -> bool:
	return _unlocked_items.has(item_type)


## 当前已解锁的道具类型集合（用于收藏界面统计）
func get_unlocked_item_count() -> int:
	return _unlocked_items.size()


func get_all_difficulties() -> Array:
	var out: Array = []
	for id in DIFFICULTY_ORDER:
		out.append(DIFFICULTY_RESOURCES[id])
	return out


func get_difficulty(id: String) -> DifficultyConfig:
	return DIFFICULTY_RESOURCES.get(id, DIFFICULTY_RESOURCES["easy"])


# ---------------------------------------------------------------------------
# 流程切换
# ---------------------------------------------------------------------------

func set_difficulty(cfg: DifficultyConfig) -> void:
	if cfg != null:
		current_difficulty = cfg


## 选择职业
func set_class(cfg: PlayerClass) -> void:
	if cfg != null:
		current_class = cfg


func get_all_classes() -> Array:
	var out: Array = []
	for id in CLASS_RESOURCES:
		out.append(CLASS_RESOURCES[id])
	return out


func get_class_by_id(id: String) -> PlayerClass:
	return CLASS_RESOURCES.get(id, CLASS_RESOURCES["warrior"])


func start_game() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/main.tscn")


func go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/menu/main_menu.tscn")
