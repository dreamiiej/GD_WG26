extends Control
## 收藏系统面板（局外养成）。
## 展示游戏内全部战场道具；玩家使用过（拾取并应用）的道具已解锁并显示效果，
## 未解锁的道具显示为"？？？"并置灰，鼓励玩家在局内去获取。

@onready var _back_btn: Button = $TopBar/BackButton
@onready var _summary_label: Label = $SummaryLabel
@onready var _grid: GridContainer = $Center/Scroll/Margin/Grid

var _flow: Node


func _ready() -> void:
	_flow = get_tree().get_first_node_in_group("game_flow")
	_back_btn.pressed.connect(_on_back_pressed)
	_rebuild()


## 从 ItemData 生成全部道具（10 种），逐条渲染
func _rebuild() -> void:
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()

	var items: Array[ItemData] = ItemData.build_default_items()
	var unlocked_count := 0
	for it in items:
		var unlocked: bool = _flow != null and _flow.is_item_unlocked(it.item_type)
		if unlocked:
			unlocked_count += 1
		_grid.add_child(_make_card(it, unlocked))

	if _flow != null:
		_summary_label.text = "收藏  %d / %d" % [unlocked_count, items.size()]
	else:
		_summary_label.text = "收藏  0 / %d" % items.size()


## 生成一张道具卡片：已解锁显示名称/效果并保留原色，未解锁置灰并隐藏文字
func _make_card(it: ItemData, unlocked: bool) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(260, 150)
	card.add_theme_stylebox_override("panel", _card_style(unlocked))

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	# 颜色方块（道具色板）
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(0, 10)
	swatch.color = it.color
	if not unlocked:
		swatch.color = Color(0.35, 0.35, 0.38)
	vbox.add_child(swatch)

	# 名称
	var name_label := Label.new()
	name_label.text = it.display_name if unlocked else "？？？"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.modulate = Color(1, 1, 1) if unlocked else Color(0.6, 0.6, 0.62)
	vbox.add_child(name_label)

	# 效果描述 / 未解锁提示
	var desc_label := Label.new()
	desc_label.text = it.description if unlocked else "未解锁"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 15)
	desc_label.modulate = Color(0.8, 0.82, 0.85) if unlocked else Color(0.5, 0.5, 0.52)
	vbox.add_child(desc_label)

	return card


## 卡片背景样式：解锁=略亮，未解锁=暗色
func _card_style(unlocked: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.18, 0.22, 1) if unlocked else Color(0.11, 0.12, 0.14, 1)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.border_width_bottom = 2
	sb.border_color = Color(0.4, 0.45, 0.5, 1) if unlocked else Color(0.2, 0.21, 0.24, 1)
	return sb


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://src/menu/main_menu.tscn")
