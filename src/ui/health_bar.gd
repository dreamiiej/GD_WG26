extends Node2D
## 通用血条组件：红色背景 + 绿色填充。
## 通过 set_value(current, max) 更新血量。
## visible_when_full 为 true 时，满血状态下隐藏（怪物用）。
##
## 绘制方式：背景和填充共用一个左上角原点，绿色按比例从左向右覆盖红色，
## 通过 z_index 严格控制绘制顺序，避免错位。

@export var width: float = 40.0
@export var height: float = 5.0
@export var background_color: Color = Color(0.7, 0.1, 0.1, 0.9)   ## 红色背景
@export var fill_color: Color = Color(0.2, 0.85, 0.2, 1.0)        ## 绿色填充
@export var offset_y: float = -24.0                                ## 相对目标头顶的偏移
@export var visible_when_full: bool = false                        ## 满血时是否隐藏

var _fill_rect: ColorRect
var _inner_width: float
var _inner_height: float


func _ready() -> void:
	# 让血条节点不随父节点缩放，保持像素尺寸稳定
	top_level = false

	_inner_width = maxf(1.0, width - 2.0)
	_inner_height = maxf(1.0, height - 2.0)

	# 原点：背景的左上角，挂在 offset_y 处（红条稍后再在视觉上居中于此点）
	# 实际让条带中心位于 x=0（水平居中于父节点）
	var origin := Vector2(-width / 2.0, offset_y)

	# 背景（红色）
	var bg := ColorRect.new()
	bg.color = background_color
	bg.size = Vector2(width, height)
	bg.position = origin
	bg.z_index = 0
	add_child(bg)

	# 填充（绿色），与背景同原点，按比例缩放宽度
	_fill_rect = ColorRect.new()
	_fill_rect.color = fill_color
	_fill_rect.size = Vector2(_inner_width, _inner_height)
	_fill_rect.position = origin + Vector2(1.0, 1.0)
	_fill_rect.pivot_offset = Vector2.ZERO
	_fill_rect.z_index = 1
	add_child(_fill_rect)


func set_value(current: float, max_value: float) -> void:
	if max_value <= 0.0 or _fill_rect == null:
		return
	var ratio: float = clampf(current / max_value, 0.0, 1.0)
	# 缩放宽度：保持 origin 不变，从左向右展开
	_fill_rect.scale.x = ratio
	if visible_when_full and ratio >= 0.999:
		visible = false
	else:
		visible = true
