extends SceneTree

func _initialize() -> void:
	for p in ["res://src/data/weapon_default.tres", "res://src/data/enemy_base.tres", "res://src/data/wave_configs.tres"]:
		var r = load(p)
		if r == null or r == ERR_CANT_OPEN:
			print("RESULT FAIL ", p)
		else:
			print("RESULT OK ", p, " -> ", r)
	quit()
