extends Control
## 选职业界面（职业选择系统）。
## 显示 3 个职业卡片，点击选择职业后进入选难度界面。

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
	if _flow == null or not _flow.has_method("get_all_classes"):
		return
	for cfg in _flow.get_all_classes():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(520, 110)
		var title: String = str(cfg.display_name)
		var desc: String = "%s\n初始生命 %d   移速 %d   伤害 %s" % [
			str(cfg.description),
			int(cfg.base_max_health),
			int(cfg.base_move_speed),
			("%d%%" % int(cfg.base_damage_multiplier * 100)) if cfg.base_damage_multiplier > 0.0 else "100%",
		]
		btn.text = "%s\n%s" % [title, desc]
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(_on_pick.bind(cfg))
		_list.add_child(btn)


func _on_pick(cfg: Resource) -> void:
	if _flow != null and _flow.has_method("set_class"):
		_flow.set_class(cfg)
	get_tree().change_scene_to_file("res://src/menu/difficulty_select.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://src/menu/main_menu.tscn")
