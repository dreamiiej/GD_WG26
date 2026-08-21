extends Control
## 主菜单（局外内容 M9）。标题 + 开始 / 设置 / 退出。

@onready var _best_label: Label = $Center/VBox/BestLabel
@onready var _start_btn: Button = $Center/VBox/StartButton
@onready var _collection_btn: Button = $Center/VBox/CollectionButton
@onready var _settings_btn: Button = $Center/VBox/SettingsButton
@onready var _quit_btn: Button = $Center/VBox/QuitButton


func _ready() -> void:
	_start_btn.pressed.connect(_on_start_pressed)
	_collection_btn.pressed.connect(_on_collection_pressed)
	_settings_btn.pressed.connect(_on_settings_pressed)
	_quit_btn.pressed.connect(_on_quit_pressed)
	_update_best()


func _update_best() -> void:
	var flow: Node = get_tree().get_first_node_in_group("game_flow")
	if flow != null:
		var t: float = flow.best_survive_time
		var lvl: int = flow.best_level
		_best_label.text = "最佳成绩  存活 %s  等级 %d" % [_format_time(t), lvl]
	else:
		_best_label.text = "最佳成绩  --"


func _format_time(sec: float) -> String:
	var total := int(sec)
	return "%02d:%02d" % [total / 60, total % 60]


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://src/menu/class_select.tscn")


func _on_collection_pressed() -> void:
	get_tree().change_scene_to_file("res://src/ui/collection_panel.tscn")


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://src/menu/settings_panel.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
