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

## 当前选择的难度
var current_difficulty: DifficultyConfig = DIFFICULTY_RESOURCES["easy"]

## 已通关的难度集合（id → true），决定难度解锁
var _cleared: Dictionary = {}

## 最佳成绩缓存
var best_survive_time: float = 0.0
var best_level: int = 0
var total_games: int = 0
var total_wins: int = 0


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
	best_survive_time = float(cfg.get_value("progress", "best_survive_time", 0.0))
	best_level = int(cfg.get_value("progress", "best_level", 0))
	total_games = int(cfg.get_value("progress", "total_games", 0))
	total_wins = int(cfg.get_value("progress", "total_wins", 0))


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "cleared", _cleared.keys())
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
	best_survive_time = 0.0
	best_level = 0
	total_games = 0
	total_wins = 0
	var cfg := ConfigFile.new()
	cfg.save(SAVE_PATH)
	load_save()


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


func start_game() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/main.tscn")


func go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/menu/main_menu.tscn")
