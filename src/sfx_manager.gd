extends Node
## 简单音效（M6）。用 AudioStreamGenerator 在运行时合成短音，无需外部音频文件。
## 提供 hit / levelup / hurt 三种提示音。

var _player: AudioStreamPlayer
var _generator: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback


func _ready() -> void:
	add_to_group("sfx")
	_generator = AudioStreamGenerator.new()
	_generator.mix_rate = 22050.0
	_player = AudioStreamPlayer.new()
	_player.stream = _generator
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()


func _tone(freq: float, dur: float, vol: float, type: int = 0) -> void:
	if _playback == null:
		return
	var frames := int(_generator.mix_rate * dur)
	var phase := 0.0
	var inc := TAU * freq / _generator.mix_rate
	for i in frames:
		var s: float
		match type:
			0:  # 方波
				s = 1.0 if sin(phase) >= 0.0 else -1.0
			1:  # 正弦
				s = sin(phase)
			_:  # 锯齿
				s = fmod(phase / TAU, 1.0) * 2.0 - 1.0
		_playback.push_frame(Vector2(s * vol, s * vol))
		phase += inc


func play_hit() -> void:
	_tone(440.0, 0.05, 0.15, 0)


func play_levelup() -> void:
	_tone(660.0, 0.12, 0.25, 1)
	_tone(880.0, 0.12, 0.25, 1)


func play_hurt() -> void:
	_tone(160.0, 0.18, 0.3, 2)


func play_pickup() -> void:
	_tone(880.0, 0.08, 0.2, 1)
	_tone(1320.0, 0.1, 0.2, 1)
