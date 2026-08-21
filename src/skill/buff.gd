class_name Buff extends RefCounted
## 运行时增益实例（由 BuffSystem 创建并持有）。
## 记录来源、剩余时间、叠加层数与 tick 计时；DOT/HOT 由 BuffSystem 每帧驱动。

signal expired(buff: Buff)

var data: BuffData
var stacks: int = 1
var remaining: float = 0.0
var tick_timer: float = 0.0
var permanent: bool = false   ## duration <= 0 时为常驻

## 应用于目标前的记录：STAT 类记录该属性被 buff 修改前的值，用于回退
var old_stat_value: float = 0.0


func _init(p_data: BuffData, p_stacks: int = 1) -> void:
	data = p_data
	stacks = p_stacks
	if data.duration <= 0.0:
		permanent = true
		remaining = INF
	else:
		remaining = data.duration
		tick_timer = data.interval


## 刷新（同 buff 再次施加）：重置剩余时间，并按 new_stacks 处理层数
func refresh(p_stacks: int) -> void:
	if not permanent:
		remaining = data.duration
		tick_timer = data.interval
	if data.max_stacks > 1:
		stacks = mini(data.max_stacks, stacks + p_stacks)
