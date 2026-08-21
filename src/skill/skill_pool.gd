class_name SkillPool extends RefCounted
## 技能池与默认 Buff（数据驱动）。供升级池解锁技能 / BuffSystem 施加增益减益。
## 技能设计参考 Dota2：主动技能按冷却自动施放，数值随等级成长。

static func build_buffs() -> Dictionary:
	## buff_id -> BuffData
	var buffs := {}
	buffs["poison"] = _mk_buff("poison", "剧毒", "持续中毒", BuffData.BuffType.DOT, "max_health", 4.0, 3.0, 0.5, Color(0.4, 0.9, 0.3))
	buffs["burn"] = _mk_buff("burn", "灼烧", "持续灼烧", BuffData.BuffType.DOT, "max_health", 6.0, 3.0, 0.5, Color(1.0, 0.5, 0.2))
	buffs["slow"] = _mk_buff("slow", "减速", "移动速度降低", BuffData.BuffType.SLOW, "", 0.35, 3.0, 0.0, Color(0.5, 0.8, 1.0))
	buffs["armor_shred"] = _mk_buff("armor_shred", "破甲", "受到的伤害增加", BuffData.BuffType.STAT_MULT, "incoming_damage_mult", 0.5, 3.0, 0.0, Color(0.9, 0.7, 0.3))
	buffs["berserk"] = _mk_buff("berserk", "嗜血狂暴", "伤害提升", BuffData.BuffType.STAT_MULT, "damage_multiplier", 0.5, 8.0, 0.0, Color(1.0, 0.4, 0.4))
	buffs["haste"] = _mk_buff("haste", "急速", "冷却缩短", BuffData.BuffType.STAT_ADD, "cooldown_reduction", 0.25, 6.0, 0.0, Color(0.4, 1.0, 0.6))
	buffs["shield"] = _mk_buff("shield", "圣盾", "吸收伤害", BuffData.BuffType.SHIELD, "", 60.0, 0.0, 0.0, Color(0.6, 0.8, 1.0))
	buffs["invuln"] = _mk_buff("invuln", "无敌", "短暂无敌", BuffData.BuffType.INVINCIBLE, "", 0.0, 2.0, 0.0, Color(1.0, 1.0, 1.0))
	buffs["regen"] = _mk_buff("regen", "再生", "持续治疗", BuffData.BuffType.HOT, "max_health", 8.0, 5.0, 0.5, Color(0.6, 1.0, 0.6))
	return buffs


static func build_skills() -> Array[SkillData]:
	var buffs := build_buffs()
	var skills: Array[SkillData] = []

	# 剑刃风暴（旋风斩）：围绕自身持续多段伤害，附加灼烧
	skills.append(_mk_skill("blade_fury", "剑刃风暴", "旋风斩击周围的敌人", SkillData.SkillType.WHIRLWIND,
		8.0, 10.0, 3.0, 120.0, 0.0, 2.0, 0.0, 0.4, buffs["burn"], Color(0.9, 0.9, 0.95)))
	# 剧毒新星：范围爆发 + 群体中毒
	skills.append(_mk_skill("nova", "剧毒新星", "爆发毒雾并让敌人中毒", SkillData.SkillType.NOVA,
		10.0, 14.0, 4.0, 150.0, 10.0, 0.0, 0.0, 0.0, buffs["poison"], Color(0.4, 0.9, 0.3)))
	# 毒雾领域：部署持续中毒区域
	skills.append(_mk_skill("poison_zone", "毒雾领域", "部署一片持续中毒的区域", SkillData.SkillType.ZONE,
		12.0, 6.0, 2.0, 130.0, 8.0, 4.0, 1.0, 0.5, buffs["poison"], Color(0.3, 0.7, 0.3)))
	# 冰霜新星：范围减速
	skills.append(_mk_skill("frost_nova", "冰霜新星", "冻结区域内的敌人使其减速", SkillData.SkillType.DEBUFF_AOE,
		9.0, 12.0, 4.0, 140.0, 0.0, 0.0, 0.0, 0.0, buffs["slow"], Color(0.5, 0.85, 1.0)))
	# 弹幕风暴：向四周倾泻子弹
	skills.append(_mk_skill("volley", "弹幕风暴", "向四周发射一片弹幕", SkillData.SkillType.VOLLEY,
		10.0, 8.0, 3.0, 0.0, 0.0, 0.0, 0.0, 0.0, null, Color(1.0, 0.85, 0.3)))
	# 圣疗：治疗自己
	skills.append(_mk_skill("heal", "圣疗", "恢复自身生命", SkillData.SkillType.HEAL,
		14.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, null, Color(0.6, 1.0, 0.6)))
	# 嗜血狂暴：提升自身伤害与攻速
	skills.append(_mk_skill("berserk", "嗜血狂暴", "提升自身伤害", SkillData.SkillType.BUFF_SELF,
		12.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, buffs["berserk"], Color(1.0, 0.4, 0.4)))

	# 数值按技能分别设定：HEAL/BUFF 用百分比与每级增量
	var heal: SkillData = skills[5]
	heal.heal_percent = 0.25
	heal.heal_percent_per_level = 0.08
	heal.max_level = 5

	var bskill: SkillData = skills[6]
	bskill.max_level = 5

	var volley: SkillData = skills[4]
	volley.projectile_count = 10
	volley.projectile_speed = 460.0
	volley.projectile_pierce = 1
	volley.projectile_scene = preload("res://src/weapon/projectile.tscn")
	volley.max_level = 5
	return skills


## skill_id → SkillData 映射（供 main.gd 按 id 查找）
static func skill_map() -> Dictionary:
	var map := {}
	for s in build_skills():
		map[s.skill_id] = s
	return map


static func _mk_buff(id: String, name: String, desc: String, type: BuffData.BuffType, stat: String, value: float, duration: float, interval: float, color: Color) -> BuffData:
	var b := BuffData.new()
	b.buff_id = id
	b.display_name = name
	b.description = desc
	b.type = type
	b.stat = stat
	b.value = value
	b.duration = duration
	b.interval = interval
	b.color = color
	return b


static func _mk_skill(id: String, name: String, desc: String, type: SkillData.SkillType, cooldown: float,
		damage: float, dmg_lvl: float, radius: float, radius_lvl: float, duration: float, dur_lvl: float, interval: float,
		buff: BuffData, color: Color) -> SkillData:
	var s := SkillData.new()
	s.skill_id = id
	s.display_name = name
	s.description = desc
	s.type = type
	s.cooldown = cooldown
	s.damage = damage
	s.damage_per_level = dmg_lvl
	s.radius = radius
	s.radius_per_level = radius_lvl
	s.duration = duration
	s.duration_per_level = dur_lvl
	s.hit_interval = interval
	s.apply_buff = buff
	s.color = color
	return s
