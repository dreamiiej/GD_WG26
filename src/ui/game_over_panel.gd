extends Control
## GameOver 面板（文档 2.1）。玩家死亡（失败）或击败 BOSS（胜利）后显示，点击重开。

signal restart_requested

@onready var _title: Label = $Panel/Title
@onready var _restart_btn: Button = $Panel/RestartButton


func _ready() -> void:
	# 游戏结束已 paused，需 ALWAYS 才能在暂停时响应重开按钮（文档 7.5）。
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_restart_btn.pressed.connect(_on_restart_pressed)


func show_panel() -> void:
	_title.text = "游戏结束"
	show()


func show_victory() -> void:
	_title.text = "关卡胜利！"
	show()


func _on_restart_pressed() -> void:
	hide()
	restart_requested.emit()
