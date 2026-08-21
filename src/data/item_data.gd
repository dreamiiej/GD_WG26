class_name ItemData extends Resource
## 战场道具数据资源。掉落与效果数据驱动（数据驱动约定）。

enum ItemType {
	HEAL,          ## 恢复生命百分比
	SPEED,         ## 临时移速
	MAGNET,        ## 临时拾取范围
	SHIELD,        ## 短暂无敌
	EXP,           ## 立即经验
	BOMB,          ## 范围伤害
	BERSERK,       ## 临时伤害
	HASTE,         ## 临时冷却
	ARMOR,         ## 临时减伤
	CLEAR,         ## 清屏伤害
}

@export var item_type: ItemType = ItemType.HEAL
@export var display_name: String = ""
@export var description: String = ""
@export var value: float = 0.0
@export var duration: float = 0.0
@export var radius: float = 0.0
@export var color: Color = Color(1, 1, 1, 1)


## 构建 10 种基础道具（血瓶 / 加速鞋 + 8 种创意道具）
static func build_default_items() -> Array[ItemData]:
	var items: Array[ItemData] = []
	items.append(_mk(ItemType.HEAL, "血瓶", "恢复 10% 生命", 10.0, 0.0, 0.0, Color(0.9, 0.2, 0.2)))
	items.append(_mk(ItemType.SPEED, "加速鞋", "+20% 移速，持续 10 秒", 0.2, 10.0, 0.0, Color(0.3, 0.9, 1.0)))
	items.append(_mk(ItemType.MAGNET, "磁铁", "拾取范围 +100，持续 10 秒", 100.0, 10.0, 0.0, Color(1.0, 0.6, 0.2)))
	items.append(_mk(ItemType.SHIELD, "护盾", "无敌 3 秒", 0.0, 3.0, 0.0, Color(0.4, 0.7, 1.0)))
	items.append(_mk(ItemType.EXP, "经验卷轴", "立即获得 30 点经验", 30.0, 0.0, 0.0, Color(0.3, 1.0, 0.6)))
	items.append(_mk(ItemType.BOMB, "爆破雷管", "对周围敌人造成 120 伤害", 120.0, 0.0, 220.0, Color(1.0, 0.4, 0.1)))
	items.append(_mk(ItemType.BERSERK, "狂暴药剂", "+50% 伤害，持续 8 秒", 0.5, 8.0, 0.0, Color(1.0, 0.3, 0.5)))
	items.append(_mk(ItemType.HASTE, "攻速手套", "冷却 -40%，持续 8 秒", 0.4, 8.0, 0.0, Color(0.5, 1.0, 0.5)))
	items.append(_mk(ItemType.ARMOR, "铁壁护甲", "受伤 -50%，持续 8 秒", 0.5, 8.0, 0.0, Color(0.6, 0.6, 0.7)))
	items.append(_mk(ItemType.CLEAR, "圣光净世", "对所有敌人造成 500 伤害", 500.0, 0.0, 0.0, Color(1.0, 0.9, 0.3)))
	return items


static func _mk(t: ItemType, name: String, desc: String, value: float, duration: float, radius: float, color: Color) -> ItemData:
	var it := ItemData.new()
	it.item_type = t
	it.display_name = name
	it.description = desc
	it.value = value
	it.duration = duration
	it.radius = radius
	it.color = color
	return it
