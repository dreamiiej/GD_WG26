extends CanvasLayer
## HUD（文档 2.1）。显示玩家血量、经验、等级、波次与存活时间。

@onready var _health_label: Label = $HealthLabel
@onready var _exp_label: Label = $ExpLabel
@onready var _level_label: Label = $LevelLabel
@onready var _wave_label: Label = $WaveLabel
@onready var _time_label: Label = $TimeLabel

var _elapsed: float = 0.0


func _ready() -> void:
	_health_label.text = "HP: 100/100"
	_exp_label.text = "EXP: 0/5"
	_level_label.text = "Lv: 1"
	_wave_label.text = "Wave: 1"


func update_health(current: float, max_hp: float) -> void:
	_health_label.text = "HP: %d/%d" % [int(current), int(max_hp)]


func update_exp(xp: int, to_next: int, level: int) -> void:
	_exp_label.text = "EXP: %d/%d" % [xp, to_next]
	_level_label.text = "Lv: %d" % level


func update_wave(wave_index: int) -> void:
	_wave_label.text = "Wave: %d" % (wave_index + 1)


func _process(delta: float) -> void:
	_elapsed += delta
	_time_label.text = "时间: %d" % int(_elapsed)


func reset_time() -> void:
	_elapsed = 0.0
