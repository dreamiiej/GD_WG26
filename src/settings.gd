extends Node
## Settings：设置单例（局外内容 M9）。自动加载。
## 负责：音量 / 画质 / 操作键位 的读取、应用与持久化（user://settings.cfg）。
## _ready 只做轻量加载，避免在启动阶段调用 AudioServer/DisplayServer 引发 headless 异常。

const SETTINGS_PATH := "user://settings.cfg"
const KEY_ACTIONS := ["move_up", "move_down", "move_left", "move_right"]

var _volumes: Dictionary = {}
var _fullscreen: bool = false
var key_bindings: Dictionary = {}


func _ready() -> void:
	add_to_group("settings")
	load_settings()


func get_volume(bus: String) -> float:
	if _volumes.has(bus):
		return _volumes[bus]
	return _volumes.get("Master", 1.0)


func set_volume(bus: String, linear: float) -> void:
	var v := clampf(linear, 0.0, 1.0)
	_volumes[bus] = v
	apply_audio()
	_save()


func apply_audio() -> void:
	var bus := bus_to_master("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(clampf(_volumes.get("Master", 1.0), 0.0, 1.0)))
	bus = bus_to_master("SFX")
	AudioServer.set_bus_volume_db(bus, linear_to_db(clampf(_volumes.get("SFX", 1.0), 0.0, 1.0)))


func bus_to_master(bus: String) -> int:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		idx = AudioServer.get_bus_index("Master")
	return idx


func set_fullscreen(on: bool) -> void:
	_fullscreen = on
	_save()


func is_fullscreen() -> bool:
	return _fullscreen


func get_key(action: String):
	if key_bindings.has(action):
		return key_bindings[action]
	var k := 0
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			k = ev.physical_keycode
			break
	return k


func set_key(action: String, physical_keycode: int) -> void:
	if not KEY_ACTIONS.has(action):
		return
	var old := InputMap.action_get_events(action)
	for ev in old:
		if ev is InputEventKey:
			InputMap.action_erase_event(action, ev)
	var ne := InputEventKey.new()
	ne.physical_keycode = physical_keycode
	InputMap.action_add_event(action, ne)
	key_bindings[action] = physical_keycode
	_save()


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", get_volume("Master"))
	cfg.set_value("audio", "sfx", get_volume("SFX"))
	cfg.set_value("audio", "music", get_volume("Music"))
	cfg.set_value("display", "fullscreen", _fullscreen)
	var binds := {}
	for action in KEY_ACTIONS:
		binds[action] = get_key(action)
	cfg.set_value("input", "key_bindings", binds)
	cfg.save(SETTINGS_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	_volumes["Master"] = float(cfg.get_value("audio", "master", 1.0))
	_volumes["SFX"] = float(cfg.get_value("audio", "sfx", 1.0))
	_volumes["Music"] = float(cfg.get_value("audio", "music", 1.0))
	_fullscreen = bool(cfg.get_value("display", "fullscreen", false))
	var binds: Dictionary = cfg.get_value("input", "key_bindings", {})
	key_bindings.clear()
	for action in KEY_ACTIONS:
		if binds.has(action):
			key_bindings[action] = binds[action]
