extends Control
## GameOver 面板（文档 2.1）。玩家死亡后显示，点击重开。

signal restart_requested

@onready var _restart_btn: Button = $Panel/RestartButton


func _ready() -> void:
	# 死亡后游戏已 paused，需 ALWAYS 才能在暂停时响应重开按钮（文档 7.5）。
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_restart_btn.pressed.connect(_on_restart_pressed)


func show_panel() -> void:
	show()


func _on_restart_pressed() -> void:
	hide()
	restart_requested.emit()
