# GD_WG26 — 吸血鬼幸存者原型 (Godot 4.7)

基于 \`初稿.md\` 实现，已推进到 M5。

## 已实现 (M1 ~ M5)
- M1：玩家移动、敌人追击、接触掉血（0.6s 无敌帧）、血条/时间 HUD、死亡重开
- M2：自动攻击武器（WeaponManager + 最近敌人查找节流 + 飞弹子弹 + 穿透）
- M3：经验宝石掉落 + 吸附拾取 + 升级三选一（暂停）+ 属性加成（PlayerStats）
- M4：波次系统（WaveManager，时间驱动，难度递增）
- M5：内容填充与平衡
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

## 运行方式
1. 用 Godot 4.7 打开本目录（project.godot 已自动识别）。
2. F5 运行（主场景 = res://src/main.tscn）。

## 已实现 (M7 关卡化：精英/BOSS/胜利)
- 精英敌人：每 3 分钟刷出一只（3/6/9 分钟），血量 = 普通怪 10 倍（Grunt 20 → 200），数据在 `src/data/enemy_elite.tres`。
- 关底 BOSS：第 12 分钟刷出，血量 = 普通怪 20 倍（Grunt 20 → 400），数据在 `src/data/enemy_final_boss.tres`。
- 顶部血条：精英/BOSS 存活期间，屏幕靠上位置显示其名字与长条血量（无论敌人位置），随 `health_changed` 实时更新，死亡后隐藏。
- 胜利结算：击败关底 BOSS 后结束当前关卡，弹出"关卡胜利"结算面板，可重开。
- 时间触发用 `RunClock`（PROCESS_MODE_ALWAYS），升级暂停不会冻结精英/BOSS 刷出与计时。

## 目录结构（M5 新增/变更）
```
src/
├── main.gd / .tscn
├── game_manager.gd            # 仅掉落/死亡/重开，刷怪委托 WaveManager
├── wave_manager.gd            # 波次调度（支持 per-wave 敌人数据 + 混入敌人）
├── data/
│   ├── wave_config.gd         # 单波配置（含 enemy_data / extra_* 混入字段）
│   ├── wave_table.gd
│   ├── wave_configs.tres      # 5 波递增 + 混合敌人数据
│   ├── enemy_base.tres / enemy_fast.tres / enemy_boss.tres
│   ├── weapon_data.gd         # 三类武器字段（weapon_type / weapon_id / radius / duration）
│   ├── weapon_default.tres / weapon_multishot.tres / weapon_aura.tres
│   ├── enemy_data.gd / player_stats.gd   # 新增 exp_gain_mult / regen
│   └── upgrade_data.gd / upgrade_pool.gd  # 12 项升级
├── weapon/
│   ├── weapon_manager.gd      # 三类武器 + 解锁/强化
│   ├── aura_effect.tscn / melee_effect.tscn
├── player/ enemy/ pickup/ ui/ ...
```

## 已实现 (M6 优化与打磨)
- 对象池 `ObjectPool`：`weapon_manager` 池化子弹、`game_manager` 池化经验宝石，减少 instantiate/free 开销（文档 4.1）
- 碰撞/查找优化：敌人缓存玩家引用避免每帧 `get_first_node_in_group`；敌人 `collision_mask=0` 互不碰撞（文档 4.3）
- 反馈：`DamageNumber` 浮动经验数字（敌人死亡弹出）、`Camera2D` 屏幕震动（受伤/精英死亡/升级），玩家受伤红屏闪烁保留
- 音效 `SfxManager`：用 `AudioStreamGenerator` 运行时合成 hit/levelup/hurt 短音，无需外部音频文件
- 校验：用 Godot 4.7.1 headless 编辑器模式完整导入项目通过（全局类注册、脚本解析、资源加载均无错）

## 目录结构（M6 新增/变更）
```
src/
├── object_pool.gd            # M6 通用对象池
├── camera_shake.gd           # M6 屏幕震动（挂在 World/Camera2D）
├── sfx_manager.gd            # M6 运行时合成音效（加入 sfx 分组）
├── weapon/weapon_manager.gd  # 接入子弹池
├── pickup/exp_gem.gd         # 接入宝石池（released 信号）
├── game_manager.gd           # 接入宝石池 + 浮动数字 + 震动触发
├── enemy/enemy.gd            # 缓存玩家引用 + 受击音效
├── player/player.gd          # 受伤震动 + 音效
├── ui/damage_number.gd/.tscn # M6 浮动数字
```

## 设计要点
- 信号解耦：WaveManager.wave_changed / enemy_spawned；GameManager 监听掉落
- 数据驱动：波次/敌人/武器/升级全部为 Resource，改数值不动代码
- 碰撞层：player=1, enemy=2, bullet=3, pickup=4
- 暂停处理：升级暂停用 process_mode=ALWAYS（文档 7.5）

## 备注
- 敌人实例采用即时 free（受 max_enemies=300 限制且生命周期长，池化收益低）；子弹/宝石高频短生命周期已池化。
- M5/M6 均通过 Godot 4.7.1 headless 编辑器导入校验。
