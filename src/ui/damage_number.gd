extends Node2D
## 浮动数字（M6 反馈）：经验值/击杀提示，向上飘并淡出后回收。

var _life: float = 0.0
var _duration: float = 0.8
var _rise: float = 36.0


func setup(text: String, color: Color) -> void:
	$Label.text = text
	$Label.modulate = color
	global_position += Vector2(randf_range(-8, 8), randf_range(-8, 8))


func _process(delta: float) -> void:
	_life += delta
	position.y -= _rise * delta
	var a := 1.0 - (_life / _duration)
	$Label.modulate.a = clampf(a, 0.0, 1.0)
	if _life >= _duration:
		queue_free()
