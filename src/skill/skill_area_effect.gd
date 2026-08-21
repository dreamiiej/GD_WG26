extends Area2D
## 技能范围效果节点：承担 NOVA（单次爆发）/ WHIRLWIND（环绕玩家持续）/ ZONE（静态毒区）三类。
## 由 SkillSystem 生成，负责对范围内敌人造成伤害、附加减益，并在结束后自行销毁。

var damage: float = 0.0
var radius: float = 120.0
var duration: float = 0.5            ## 总持续（NOVA 用 0 表示一次性脉冲）
var hit_interval: float = 0.5
var follow_player: bool = false      ## true=跟随玩家（WHIRLWIND）
var apply_debuff: BuffData = null    ## 命中敌人时附加的减益
var _player_ref: Node2D = null
var _life: float = 0.0
var _tick: float = 0.0
var _hit_once: bool = false


func setup(p_damage: float, p_radius: float, p_duration: float, p_interval: float, p_follow: bool, p_debuff: BuffData, color: Color) -> void:
	damage = p_damage
	radius = maxf(p_radius, 1.0)
	duration = p_duration
	hit_interval = maxf(p_interval, 0.01)
	follow_player = p_follow
	apply_debuff = p_debuff
	# 更新碰撞形状
	var shape := CircleShape2D.new()
	shape.radius = radius
	var cs: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if cs == null:
		cs = CollisionShape2D.new()
		cs.name = "CollisionShape2D"
		add_child(cs)
	cs.shape = shape
	# 更新视觉多边形
	var poly: Polygon2D = get_node_or_null("Polygon2D")
	if poly == null:
		poly = Polygon2D.new()
		poly.name = "Polygon2D"
		add_child(poly)
	var pts: PackedVector2Array = []
	var n := 20
	for k in n:
		var a := float(k) / float(n) * TAU
		pts.append(Vector2(cos(a), sin(a)) * radius)
	poly.polygon = pts
	poly.color = Color(color.r, color.g, color.b, 0.16)
	collision_layer = 0
	collision_mask = 2
	monitoring = true


func _ready() -> void:
	_player_ref = get_tree().get_first_node_in_group("player")
	_tick = 0.0
	_life = 0.0


func _physics_process(delta: float) -> void:
	_life += delta
	_tick += delta
	if follow_player and _player_ref != null and is_instance_valid(_player_ref):
		global_position = _player_ref.global_position
	# NOVA（一次性脉冲）：首帧打一次
	if duration <= 0.0 and not _hit_once:
		_pulse()
		_hit_once = true
		queue_free()
		return
	# 持续型：按 interval 触发
	if _tick >= hit_interval:
		_tick = 0.0
		_pulse()
	# 到期销毁
	if duration > 0.0 and _life >= duration:
		queue_free()


func _pulse() -> void:
	for area in get_overlapping_areas():
		var parent := area.get_parent()
		if parent != null and parent.is_in_group("enemy") and parent.has_method("take_damage"):
			_damage_enemy(parent)
	for body in get_overlapping_bodies():
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			_damage_enemy(body)


func _damage_enemy(e: Node) -> void:
	if damage > 0.0 and e.has_method("take_damage"):
		e.take_damage(damage)
	if apply_debuff != null and e.has_method("apply_buff"):
		e.apply_buff(apply_debuff)
