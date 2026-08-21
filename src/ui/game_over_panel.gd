extends Control
## GameOver 面板（文档 2.1）。玩家死亡（失败）或击败 BOSS（胜利）后显示。
## 局外内容 M9：新增"返回主菜单"按钮；在结算时把本局成绩记录到 GameFlow。

signal restart_requested
signal menu_requested

@onready var _title: Label = $Panel/Title
@onready var _restart_btn: Button = $Panel/RestartButton
@onready var _menu_btn: Button = $Panel/MenuButton


func _ready() -> void:
	# 游戏结束已 paused，需 ALWAYS 才能在暂停时响应按钮（文档 7.5）。
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_restart_btn.pressed.connect(_on_restart_pressed)
	_menu_btn.pressed.connect(_on_menu_pressed)


## 显示并记录本局成绩（结算时调用）。time_alive/level 用于存档。
func show_result(title: String, time_alive: float, level: int, victory: bool) -> void:
	_title.text = title
	_record_result(time_alive, level, victory)
	show()


func show_panel() -> void:
	show_result("游戏结束", 0.0, 0, false)


func show_victory() -> void:
	show_result("关卡胜利！", 0.0, 0, true)


## 把成绩写入 GameFlow 存档（最佳成绩 / 难度解锁）
func _record_result(time_alive: float, level: int, victory: bool) -> void:
	var flow := get_tree().get_first_node_in_group("game_flow")
	if flow != null and flow.has_method("record_result"):
		flow.record_result(time_alive, level, victory)


func _on_restart_pressed() -> void:
	hide()
	restart_requested.emit()


func _on_menu_pressed() -> void:
	hide()
	menu_requested.emit()
