extends Control
## 设置面板（局外内容 M9）。音量 / 画质 / 操作键位 / 存档进度。

@onready var _back_btn: Button = $TopBar/BackButton
@onready var _master_slider: HSlider = $Center/Scroll/Margin/VBox/AudioSection/MasterSlider
@onready var _sfx_slider: HSlider = $Center/Scroll/Margin/VBox/AudioSection/SfxSlider
@onready var _fullscreen_chk: CheckButton = $Center/Scroll/Margin/VBox/DisplaySection/FullscreenCheck
@onready var _reset_progress_btn: Button = $Center/Scroll/Margin/VBox/ProgressSection/ResetProgressButton
@onready var _progress_label: Label = $Center/Scroll/Margin/VBox/ProgressSection/ProgressLabel

var _settings: Node
var _flow: Node


func _ready() -> void:
	_settings = get_tree().get_first_node_in_group("settings")
	_flow = get_tree().get_first_node_in_group("game_flow")
	_back_btn.pressed.connect(_on_back_pressed)
	_load_values()
	_master_slider.value_changed.connect(_on_master_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_fullscreen_chk.toggled.connect(_on_fullscreen_toggled)
	_reset_progress_btn.pressed.connect(_on_reset_progress)


func _load_values() -> void:
	if _settings != null:
		_master_slider.value = _settings.get_volume("Master")
		_sfx_slider.value = _settings.get_volume("SFX")
		_fullscreen_chk.button_pressed = _settings.is_fullscreen()
	if _flow != null:
		var wins: int = _flow.total_wins
		var games: int = _flow.total_games
		var best: float = _flow.best_survive_time
		_progress_label.text = "局数 %d   胜利 %d   最佳存活 %s" % [games, wins, _fmt(best)]


func _fmt(sec: float) -> String:
	var t := int(sec)
	return "%02d:%02d" % [t / 60, t % 60]


func _on_master_changed(v: float) -> void:
	if _settings != null:
		_settings.set_volume("Master", v)


func _on_sfx_changed(v: float) -> void:
	if _settings != null:
		_settings.set_volume("SFX", v)


func _on_fullscreen_toggled(on: bool) -> void:
	if _settings != null:
		_settings.set_fullscreen(on)


func _on_reset_progress() -> void:
	if _flow != null:
		_flow.reset_progress()
		_progress_label.text = "局数 0   胜利 0   最佳存活 00:00"


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://src/menu/main_menu.tscn")
