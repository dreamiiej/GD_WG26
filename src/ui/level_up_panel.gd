extends Control
## 升级面板（文档 3.5）。弹出时暂停游戏，三选一，点击后应用并恢复。
## process_mode = ALWAYS 以保证在 paused 时仍能响应按钮（文档 7.5）。

signal upgrade_chosen(data: UpgradeData)

@export var pool: Array[UpgradeData] = []

@onready var _title: Label = $Panel/Title
@onready var _buttons: Array[Button] = [$Panel/Opt1, $Panel/Opt2, $Panel/Opt3]

var _current: Array[UpgradeData] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	for b in _buttons:
		b.pressed.connect(_on_option_pressed.bind(b))


func show_choices() -> void:
	_current = _roll_choices(3)
	for i in _buttons.size():
		if i < _current.size():
			_buttons[i].visible = true
			_buttons[i].text = _current[i].title + "\n" + _current[i].description
		else:
			_buttons[i].visible = false
	show()


func _roll_choices(n: int) -> Array[UpgradeData]:
	var src := pool.duplicate()
	var out: Array[UpgradeData] = []
	src.shuffle()
	for i in min(n, src.size()):
		out.append(src[i])
	return out


func _on_option_pressed(btn: Button) -> void:
	var idx := _buttons.find(btn)
	if idx < 0 or idx >= _current.size():
		return
	hide()
	var chosen := _current[idx]
	upgrade_chosen.emit(chosen)
	get_tree().paused = false
