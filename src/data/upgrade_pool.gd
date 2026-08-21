class_name UpgradePool extends RefCounted
## 升级池（文档 3.5）。返回可用升级项列表；后续可换成 JSON 数据表。
## M5 扩展：12+ 项，覆盖 STAT / WEAPON（解锁+强化）/ PASSIVE。

static func build_default_pool() -> Array[UpgradeData]:
	var pool: Array[UpgradeData] = []
	# ---- STAT（直接改 PlayerStats）----
	pool.append(_mk("最大生命 +20", "生命上限提升 20", UpgradeData.UpgradeType.STAT, "max_health", 20.0, false))
	pool.append(_mk("生命强化 +10%", "生命上限提升 10%", UpgradeData.UpgradeType.STAT, "max_health", 10.0, true))
	pool.append(_mk("移动速度 +12%", "移速提升 12%", UpgradeData.UpgradeType.STAT, "move_speed", 12.0, true))
	pool.append(_mk("伤害 +10%", "武器伤害提升 10%", UpgradeData.UpgradeType.STAT, "damage_multiplier", 10.0, true))
	pool.append(_mk("冷却 -8%", "攻击间隔缩短 8%", UpgradeData.UpgradeType.STAT, "cooldown_reduction", -8.0, true))
	pool.append(_mk("拾取范围 +25", "经验吸附范围 +25", UpgradeData.UpgradeType.STAT, "pickup_range", 25.0, false))

	# ---- PASSIVE ----
	pool.append(_mk("经验贪婪 +15%", "经验获取提升 15%", UpgradeData.UpgradeType.STAT, "exp_gain_mult", 15.0, true))
	pool.append(_mk("再生 +1/s", "每秒恢复 1 点生命", UpgradeData.UpgradeType.STAT, "regen", 1.0, false))

	# ---- WEAPON 解锁（最多叠 1 层）----
	pool.append(_mk_weapon("解锁·多重飞弹", "同时发射 3 发飞弹", "multishot", true, 1))
	pool.append(_mk_weapon("解锁·冰霜光环", "环绕自身持续伤害", "aura", true, 1))

	# ---- WEAPON 强化（可叠加，倍率增量）----
	pool.append(_mk_weapon("飞弹伤害 +25%", "基础飞弹伤害提升 25%", "missile", false, 99, 0.25))
	pool.append(_mk_weapon("多重飞弹 +25%", "多重飞弹伤害提升 25%", "multishot", false, 99, 0.25))
	pool.append(_mk_weapon("冰霜光环 +30%", "冰霜光环伤害提升 30%", "aura", false, 99, 0.3))

	# ---- SKILL 解锁（Dota2 风格主动技能，最多叠 1 层）----
	pool.append(_mk_skill("解锁·剑刃风暴", "旋风斩击周围敌人（自动施放）", "blade_fury", true, 1))
	pool.append(_mk_skill("解锁·剧毒新星", "爆发毒雾并使敌人中毒（自动施放）", "nova", true, 1))
	pool.append(_mk_skill("解锁·冰霜新星", "冻结区域内敌人使其减速（自动施放）", "frost_nova", true, 1))
	pool.append(_mk_skill("解锁·弹幕风暴", "向四周倾泻弹幕（自动施放）", "volley", true, 1))
	pool.append(_mk_skill("解锁·圣疗", "危急时恢复自身生命（自动施放）", "heal", true, 1))
	pool.append(_mk_skill("解锁·嗜血狂暴", "提升自身伤害（自动施放）", "berserk", true, 1))

	# ---- SKILL 升级（提升已有技能等级）----
	pool.append(_mk_skill("剑刃风暴升级", "提升剑刃风暴的威力", "blade_fury", false, 4))
	pool.append(_mk_skill("剧毒新星升级", "提升剧毒新星的威力", "nova", false, 4))
	pool.append(_mk_skill("冰霜新星升级", "提升冰霜新星的威力", "frost_nova", false, 4))
	pool.append(_mk_skill("弹幕风暴升级", "提升弹幕风暴的威力", "volley", false, 4))
	pool.append(_mk_skill("圣疗升级", "提升圣疗的回复量", "heal", false, 4))
	pool.append(_mk_skill("嗜血狂暴升级", "提升嗜血狂暴的效果", "berserk", false, 4))

	return pool


static func _mk(title: String, desc: String, type: UpgradeData.UpgradeType, stat: String, value: float, is_pct: bool) -> UpgradeData:
	var u := UpgradeData.new()
	u.title = title
	u.description = desc
	u.type = type
	u.stat = stat
	u.value = value
	u.is_percent = is_pct
	return u


static func _mk_weapon(title: String, desc: String, weapon_id: String, unlock: bool, max_stacks: int, value: float = 0.0) -> UpgradeData:
	var u := UpgradeData.new()
	u.title = title
	u.description = desc
	u.type = UpgradeData.UpgradeType.WEAPON
	u.weapon_id = weapon_id
	u.unlock_weapon = unlock
	u.max_stacks = max_stacks
	u.value = value
	return u


static func _mk_skill(title: String, desc: String, skill_id: String, unlock: bool, max_stacks: int) -> UpgradeData:
	var u := UpgradeData.new()
	u.title = title
	u.description = desc
	u.type = UpgradeData.UpgradeType.SKILL
	u.skill_id = skill_id
	u.unlock_skill = unlock
	u.max_stacks = max_stacks
	return u
