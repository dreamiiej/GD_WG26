# GD_WG26 — 吸血鬼幸存者原型 (Godot 4.7)

基于 `初稿.md`（架构蓝图）→ `v2稿.md`（M7 关卡化 / M8 美术化）→ `局外内容策划案.md`（M9 局外内容）迭代实现，并自行扩展到 **M10+**（技能 / 职业 / 道具 / 收藏 / 流场）。

最小可玩闭环（移动 → 打怪 → 掉宝 → 升级 → 死亡/胜利重开）已完整跑通，并包裹进完整的局外流程。

## 运行方式
1. 用 Godot 4.7 打开本目录（`project.godot` 已自动识别）。
2. F5 运行，主场景 = `res://src/menu/main_menu.tscn`，从主菜单启动。
3. 完整流程：**主菜单 → 选职业 → 选难度 → 游戏 → 结算 → 返回主菜单 / 再来一局**。
   - 调试局内时也可直接运行 `res://src/main.tscn`（默认 easy + warrior）。

## 已实现总览（M1 ~ M10+）

| 里程碑 | 状态 | 要点 |
|--------|------|------|
| M1 最小原型 | ✅ | 玩家移动、敌人追击、0.6s 无敌帧、血条/时间 HUD、死亡重开 |
| M2 自动攻击 | ✅ | WeaponManager + 最近敌人查找节流（0.15s）+ 飞弹 + 穿透 |
| M3 经验升级 | ✅ | 宝石掉落 + 吸附拾取 + 升级三选一（暂停）+ PlayerStats 加成 |
| M4 波次系统 | ✅ | WaveManager 时间驱动、难度倍率递增、Wave 2/4 混入快怪/精英 |
| M5 内容填充 | ✅ | 3 武器、3 敌人、12 项升级 |
| M6 优化打磨 | ✅ | ObjectPool、碰撞优化、屏幕震动、浮动数字、运行时合成音效 |
| M7 关卡化 | ✅ | 精英/BOSS、顶部血条、胜利结算、RunClock 不冻结 |
| M8 美术化 | 🟡 部分 | player + 3 敌人贴图已入库并接入 Sprite2D，背景/特效仍为色块 |
| M9 局外内容 | ✅ | 主菜单 / 选职业 / 选难度 / 设置 / 存档 / 退出 |
| M10+ 扩展 | ✅ | 技能 + Buff、职业、战场道具、收藏、战场流场寻路 |

## M1 ~ M6：核心闭环与打磨
- **M1**：玩家移动、敌人追击、接触掉血（0.6s 无敌帧）、血条/时间 HUD、死亡重开。
- **M2**：自动攻击武器（WeaponManager + 最近敌人查找节流 + 飞弹子弹 + 穿透）。
- **M3**：经验宝石掉落 + 吸附拾取 + 升级三选一（暂停）+ 属性加成（PlayerStats）。
- **M4**：波次系统（WaveManager，时间驱动，难度递增）。
- **M5**：内容填充与平衡。
  - **3 种武器**（WeaponManager 支持发射/光环/近战三类）
    - 飞弹 missile（发射型，初始武器）
    - 多重飞弹 multishot（发射型，3 发散射，升级解锁）
    - 冰霜光环 aura（光环型，环绕自身持续伤害，升级解锁）
    - 武器强化：升级可叠加提升已有武器伤害倍率
  - **3 种敌人**（数据驱动，靠 EnemyData 区分外观/数值）
    - Grunt 红方块（基础）、Wraith 紫快怪、Brute 深蓝精英（高血高伤）
    - 波次混刷：Wave 2 起混入快怪，Wave 4+ 起混入精英
  - **12 项升级**（STAT 6 + PASSIVE 2 + WEAPON 解锁 2 + WEAPON 强化 3）
    - PASSIVE 新增经验贪婪、再生
  - 数值平衡：波次倍率平滑递增，升级成长受 max_stacks 限制避免爆炸（文档 7.3）
- **M6**：优化与打磨。
  - 对象池 `ObjectPool`：`weapon_manager` 池化子弹、`game_manager` 池化经验宝石，减少 instantiate/free 开销（文档 4.1）
  - 碰撞/查找优化：敌人缓存玩家引用避免每帧 `get_first_node_in_group`；敌人 `collision_mask=0` 互不碰撞（文档 4.3）
  - 反馈：`DamageNumber` 浮动经验数字、`Camera2D` 屏幕震动（受伤/精英死亡/升级）、玩家受伤红屏闪烁
  - 音效 `SfxManager`：用 `AudioStreamGenerator` 运行时合成 hit/levelup/hurt 短音，无需外部音频文件

## M7：关卡化（精英/BOSS/胜利）
- 精英敌人：每 3 分钟刷出一只（3/6/9 分钟），血量 = 普通怪 10 倍（Grunt 20 → 200），数据在 `src/data/enemy_elite.tres`。
- 关底 BOSS：第 12 分钟刷出，血量 = 普通怪 20 倍（Grunt 20 → 400），数据在 `src/data/enemy_final_boss.tres`。
- 顶部血条：精英/BOSS 存活期间，屏幕靠上位置显示其名字与长条血量（无论敌人位置），随 `health_changed` 实时更新，死亡后隐藏。
- 胜利结算：击败关底 BOSS 后结束当前关卡，弹出"关卡胜利"结算面板，可重开或返回主菜单。
- 时间触发用 `RunClock`（PROCESS_MODE_ALWAYS），升级暂停不会冻结精英/BOSS 刷出与计时。

## M8：美术化（部分落地）
- 已入库：player + 3 敌人（boss/fast/weak）的 png/svg，位于 `assets/characters/`。
- player 与 enemy 均已改用 `Sprite2D`，由 `EnemyData.sprite_texture` / 节点配置驱动贴图（数据驱动外观）。
- 背景与 VFX 仍为色块占位，待按 `美术设计文档.md` 继续替换。

## M9：局外内容（主菜单 / 难度 / 设置 / 存档）
- **主菜单** `src/menu/main_menu.tscn`：标题 + 开始 / 收藏 / 设置 / 退出，显示最佳成绩。
- **选职业** `src/menu/class_select.tscn`：3 职业卡片 → 开始。
- **选难度** `src/menu/difficulty_select.tscn`：3 档（easy / normal / hard），初始仅"简单"，通关上一档才解锁下一档，未解锁置灰。
- **设置** `src/menu/settings_panel.tscn` + `Settings` 自动加载单例：
  - 音量（Master / SFX / Music，`AudioServer` 总线）
  - 全屏切换
  - 自定义键位（上下左右，运行时替换 `InputMap`）
  - 全部即时生效并持久化到 `user://settings.cfg`，重启保留。
- **存档** `GameFlow` 自动加载单例，`user://save.cfg`：
  - 最佳存活时间 / 最佳等级 / 总局数 / 胜利数
  - 已通关难度集合（决定难度解锁）
  - 已解锁道具集合（决定收藏显示）
  - 提供"重置进度"入口。
- **三档难度**（`DifficultyConfig`，数据驱动，只做线性倍率不改成长曲线，呼应文档 7.3）：

  | 档位 | 普通怪血量 | 刷怪间隔 | 精英/BOSS 血量 | 经验 |
  |------|-----------|---------|---------------|------|
  | 简单 | ×0.7 | ×1.3（更稀疏） | ×0.8 | ×1.3 |
  | 普通 | ×1.0 | ×1.0 | ×1.0 | ×1.0 |
  | 困难 | ×1.5 | ×0.8（更密集） | ×1.6 | ×0.8 |

## M10+：扩展系统（技能 / 职业 / 道具 / 收藏 / 流场）

> 本节为 `初稿` / `v2稿` / `局外策划案` 三份文档之外自行扩展的内容。

### 职业系统
- `PlayerClass`（`src/data/player_class.gd`）数据驱动，3 职业各一份 `.tres`，决定开局基础数值 + 初始武器 + 初始技能，由 `main.gd._apply_class()` 在开局应用。

  | 职业 | 血量 | 移速 | 伤害 | 初始武器 | 初始技能 |
  |------|------|------|------|---------|---------|
  | 剑士 warrior | 150 | 210 | 1.0× | — | 剑刃风暴 |
  | 术士 mage | 90 | 215 | 1.3× | — | 剧毒新星 |
  | 猎手 ranger | 100 | 245 | 1.1× | 多重飞弹 | 弹幕风暴 |

### 技能与 Buff 系统（Dota2 风格）
- `SkillSystem`（`src/skill/skill_system.gd`）挂在玩家上：习得 / 升级 / 按冷却自动施放，无需手动操作。效果通过 `SkillAreaEffect` 与 `BuffSystem` 落地。
- **7 种主动技能**（`SkillPool` 数据驱动，数值随等级成长）：
  - 剑刃风暴（WHIRLWIND，围绕自身持续多段伤害 + 灼烧）
  - 剧毒新星（NOVA，范围爆发 + 群体中毒）
  - 毒雾领域（ZONE，部署持续中毒区域）
  - 冰霜新星（DEBUFF_AOE，范围减速）
  - 弹幕风暴（VOLLEY，向四周倾泻子弹）
  - 圣疗（HEAL，按最大生命百分比回血）
  - 嗜血狂暴（BUFF_SELF，提升自身伤害）
  - 其中 6 种接入升级解锁池（毒雾领域暂未接入升级池）。
- **BuffSystem**（`src/skill/buff_system.gd`）：玩家/敌人共用的统一 Buff/Debuff 管理器，支持施加/刷新/叠加/计时/回退。
  - 9 种 Buff：剧毒（DOT）、灼烧（DOT）、减速（SLOW）、破甲（STAT_MULT 受伤增加）、嗜血（STAT_MULT 伤害）、急速（STAT_ADD 冷却）、圣盾（SHIELD 吸收）、无敌（INVINCIBLE）、再生（HOT）。
  - 属性类 buff 基于"底值 + 累加增量 + 累乘倍率"重算并写入 PlayerStats，到期自动回退。
- **HUD 技能栏**：底部 Dota2 风格槽位，显示已习得技能名 / 等级 / 冷却遮罩 / 施放闪光；左侧列表展示本局已选升级项（武器青色 / 属性暖黄色条区分）。

### 战场道具与掉落
- `ItemData`（`src/data/item_data.gd`）数据驱动，**10 种道具**：血瓶 / 加速鞋 / 磁铁 / 护盾 / 经验卷轴 / 爆破雷管 / 狂暴药剂 / 攻速手套 / 铁壁护甲 / 圣光净世。
- `item_pickup.gd` 拾取物：进入拾取范围自动吸附，接触玩家即应用效果。
- **掉落规则**（`game_manager.gd`）：普通怪 3% 概率掉落，精英/BOSS **必掉**；效果通过 PlayerStats 临时增益或 BuffSystem 落地（护盾/无敌/范围伤害/清屏伤害等）。

### 收藏系统
- `collection_panel.gd` 局外养成面板：展示全部 10 种战场道具，拾取并使用过的道具解锁显示名称/效果，未解锁置灰显示"？？？"，进度写入存档。主菜单"收藏"按钮进入。

### 战场与流场寻路
- `battlefield.gd`：限定战场（约 4 个 1920×1080 屏幕宽高），生成四周边界墙 + 随机障碍物（避开玩家出生点，互不重叠）。
- `flow_field.gd`：流场寻路。把战场栅格化（32px/格），以玩家为汇点做 BFS，敌人查询"步数更少的邻格"即可绕开障碍。每 0.3s 重建一次，接近玩家（2.5 格内）退回直线冲撞以贴身造成接触伤害。
- 敌人 `enemy.gd` 已接入：优先用流场方向，无寻路或不可达时退回直线追击；同时带 BuffSystem（减速/中毒/护盾）。

## 目录结构
```
src/
├── main.gd / .tscn              # 局内总装，连接玩家/武器/波次/技能/HUD/结算
├── game_flow.gd                 # AutoLoad：流程切换 / 难度 / 职业 / 进度存档
├── settings.gd                  # AutoLoad：音量 / 全屏 / 键位持久化
├── battlefield.gd               # 战场边界 + 障碍物
├── flow_field.gd                # 流场寻路（BFS 栅格）
├── wave_manager.gd              # 波次 + 精英 + BOSS（按绝对时间）
├── game_manager.gd              # 掉落 / 死亡 / 重开 / 道具掉落 / 胜利
├── run_clock.gd                 # PROCESS_MODE_ALWAYS 计时
├── object_pool.gd / camera_shake.gd / sfx_manager.gd
├── data/                        # 全部 Resource 数据
│   ├── enemy_*.tres / enemy_data.gd         # 敌人
│   ├── weapon_*.tres / weapon_data.gd       # 武器
│   ├── wave_config.gd / wave_table.gd / wave_configs.tres
│   ├── player_stats.gd / upgrade_data.gd / upgrade_pool.gd  # 25 项升级
│   ├── player_class.gd / player_class_*.tres # 3 职业
│   ├── difficulty_config.gd / difficulty_*.tres  # 3 档难度
│   └── item_data.gd                          # 10 种道具
├── player/   player.gd/.tscn                  # 玩家 + BuffSystem + SkillSystem
├── enemy/    enemy.gd/.tscn                   # 敌人（流场 + BuffSystem）
├── pickup/   exp_gem.gd / item_pickup.gd      # 经验宝石 / 道具拾取
├── weapon/   weapon_manager.gd / projectile.* / aura_effect / melee_effect
├── skill/    skill_system.gd / buff_system.gd / skill_pool.gd / skill_data.gd / buff_data.gd / skill.gd / skill_area_effect.*
├── ui/       hud.gd / health_bar / damage_number / level_up_panel / game_over_panel / collection_panel.*
├── menu/     main_menu / class_select / difficulty_select / settings_panel.*
```

## 设计要点
- 信号解耦：`WaveManager.wave_changed / enemy_spawned / elite_spawned / boss_spawned`；`GameManager` 监听掉落；`SkillSystem.skill_cast` 驱动 HUD 闪光。
- 数据驱动：波次 / 敌人 / 武器 / 升级 / 技能 / Buff / 职业 / 道具 / 难度 / 设置全部为 `Resource` 或配置文件，改数值不动代码。
- 碰撞层：player=1, enemy=2, bullet=3, pickup=4, obstacle=5（`project.godot` 已命名）。
- 暂停处理：升级暂停用 `get_tree().paused`；Boss 刷出 / 胜利判定 / 计时用 `process_mode=ALWAYS` 节点（`RunClock`），避免被冻结（文档 7.5）。
- AutoLoad 单例：`GameFlow`（流程/存档）、`Settings`（设置）。

## 升级池（共 25 项）
- STAT 6 + PASSIVE 2（经验贪婪 / 再生）
- WEAPON 解锁 2（多重飞弹 / 冰霜光环）+ WEAPON 强化 3（飞弹 / 多重飞弹 / 冰霜光环伤害）
- SKILL 解锁 6（剑刃风暴 / 剧毒新星 / 冰霜新星 / 弹幕风暴 / 圣疗 / 嗜血狂暴）+ SKILL 升级 6（对应强化，每项最多 4 层）

## 备注
- 敌人实例采用即时 free（受 `max_enemies=300` 限制且生命周期长，池化收益低）；子弹/宝石/道具高频短生命周期已池化。
- `melee_effect.tscn`（近战）场景已建但未在升级池解锁，留作后续扩展。
- M5/M6 通过 Godot 4.7.1 headless 编辑器导入校验；M7 之后的新增系统建议在改动后复测一次 headless 导入。
