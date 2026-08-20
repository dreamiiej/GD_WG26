extends Camera2D
## 屏幕震动（M6 反馈）。提供 shake()，叠加随机偏移，自动衰减。
## 挂在 World/Camera2D 上（process_mode 默认跟随场景暂停）。

var _trauma: float = 0.0
var _max_offset: float = 10.0
var _time: float = 0.0


func shake(amount: float = 0.5) -> void:
	_trauma = min(_trauma + amount, 1.0)


func _process(delta: float) -> void:
	if _trauma <= 0.0:
		offset = Vector2.ZERO
		return
	_time += delta
	# trauma 平方衰减，手感更自然
	var shake := _trauma * _trauma
	var ox := randf_range(-1, 1) * _max_offset * shake
	var oy := randf_range(-1, 1) * _max_offset * shake
	offset = Vector2(ox, oy)
	_trauma = max(_trauma - delta * 1.5, 0.0)
