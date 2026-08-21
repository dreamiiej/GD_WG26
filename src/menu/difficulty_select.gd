extends Control
## 选难度界面（局外内容 M9）。
## 显示 3 档难度卡片；未解锁的档位置灰（需通关上一难度解锁）。初始仅解锁"简单"。

@onready var _back_btn: Button = $TopBar/BackButton
@onready var _list: VBoxContainer = $Center/List

var _flow: Node


func _ready() -> void:
	_flow = get_tree().get_first_node_in_group("game_flow")
	_back_btn.pressed.connect(_on_back_pressed)
	_rebuild()


func _rebuild() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	if _flow == null:
		return
	var cards: Array = _flow.get_all_difficulties()
	for cfg in cards:
		var unlocked: bool = _flow.is_unlocked(cfg.id)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(520, 84)
		var title: String = str(cfg.display_name) + ("（已通关）" if _flow.is_cleared(cfg.id) else "")
		var desc: String = "%s\n%s" % [str(cfg.description), ("已解锁" if unlocked else "未解锁：需通关上一难度")]
		btn.text = "%s\n%s" % [title, desc]
		btn.disabled = not unlocked
		btn.add_theme_font_size_override("font_size", 22)
		if unlocked:
			btn.pressed.connect(_on_pick.bind(cfg))
		_list.add_child(btn)


func _on_pick(cfg: Resource) -> void:
	if _flow != null:
		_flow.set_difficulty(cfg)
		_flow.start_game()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://src/menu/main_menu.tscn")
