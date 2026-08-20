extends Node
## RunClock（v2 M7）。以 PROCESS_MODE_ALWAYS 运行的真实时间时钟。
## 升级暂停（get_tree().paused）不会冻结它，用于精英/BOSS 的绝对时间触发与胜利判定。

signal tick(delta: float)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	tick.emit(delta)
