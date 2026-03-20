# 坦克对战 MVP 开发文档

> **闪电式开发原则**：先跑通核心循环，再迭代优化。最快速度实现「移动→射击→胜利」的完整体验。

---

## 1. 项目概述

### 1.1 游戏概念
- **类型**：2D 俯视角坦克射击
- **核心循环**：移动 → 瞄准 → 射击 → 击毁敌人 → 胜利庆祝
- **MVP 范围**：单人模式，单关卡，一个可击毁的目标

### 1.2 技术栈
| 项目 | 规格 |
|------|------|
| 引擎 | Godot 4.6.1 (Stable) |
| 语言 | GDScript |
| 渲染 | Forward+ |
| 目标平台 | Desktop (测试) → Mobile (后期) |

### 1.3 开发优先级
```
P0 (必须): 玩家移动、射击、目标销毁、胜利反馈
P1 (可选): 音效、简单UI、关卡边界
P2 (后期): 多敌人、AI、关卡系统
```

---

## 2. 项目结构

```
tank_battle/
├── project.godot
├── scenes/
│   ├── Main.tscn           # 主场景
│   ├── Player.tscn         # 玩家坦克
│   ├── Bullet.tscn         # 子弹
│   ├── Target.tscn         # 目标/敌人
│   └── VictoryEffect.tscn  # 胜利特效
├── scripts/
│   ├── Player.gd
│   ├── Bullet.gd
│   ├── Target.gd
│   ├── GameManager.gd
│   └── VictoryEffect.gd
└── assets/
    ├── sprites/
    │   ├── tank.png        # 坦克贴图 (临时用色块代替)
    │   ├── bullet.png
    │   └── target.png
    └── particles/
        └── fireworks.tres  # 粒子材质
```

---

## 3. 输入映射配置

### 3.1 项目设置 → 输入映射

手动配置或通过代码初始化：

| 动作名称 | 默认按键 |
|---------|---------|
| `move_up` | W |
| `move_down` | S |
| `move_left` | A |
| `move_right` | D |
| `shoot` | Space |

### 3.2 代码初始化（可选）

```gdscript
# 在项目首次运行时执行一次，或手动在 Project Settings 配置
static func setup_input_map() -> void:
    var actions := {
        "move_up": KEY_W,
        "move_down": KEY_S,
        "move_left": KEY_A,
        "move_right": KEY_D,
        "shoot": KEY_SPACE
    }
    
    for action in actions:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
            var event := InputEventKey.new()
            event.keycode = actions[action]
            InputMap.action_add_event(action, event)
```

---

## 4. 核心代码实现

### 4.1 Player.gd - 玩家坦克控制器

```gdscript
## Player.gd
## 玩家坦克控制器 - 负责移动和射击
class_name Player
extends CharacterBody2D

#region 配置参数
@export var move_speed: float = 200.0        ## 移动速度 (像素/秒)
@export var rotation_speed: float = 5.0      ## 旋转插值速度
@export var bullet_scene: PackedScene        ## 子弹场景引用
@export var fire_cooldown: float = 0.3       ## 射击冷却时间 (秒)
#endregion

#region 私有变量
var _can_fire: bool = true                   ## 是否可以射击
var _fire_timer: float = 0.0                 ## 射击冷却计时器
#endregion

#region 节点引用
@onready var _muzzle: Marker2D = $Muzzle     ## 炮口位置
#endregion


func _physics_process(delta: float) -> void:
    _handle_movement(delta)
    _handle_rotation()
    _handle_shooting(delta)
    move_and_slide()


func _handle_movement(_delta: float) -> void:
    """使用 get_vector 获取移动输入"""
    var input_direction := Input.get_vector(
        "move_left", "move_right",
        "move_up", "move_down"
    )
    velocity = input_direction * move_speed


func _handle_rotation() -> void:
    """坦克朝向移动方向"""
    if velocity.length_squared() > 0.1:
        var target_rotation := velocity.angle()
        rotation = lerp_angle(rotation, target_rotation, rotation_speed * get_physics_process_delta_time())


func _handle_shooting(delta: float) -> void:
    """射击逻辑"""
    # 冷却计时
    if not _can_fire:
        _fire_timer -= delta
        if _fire_timer <= 0:
            _can_fire = true
    
    # 检测射击输入
    if Input.is_action_just_pressed("shoot") and _can_fire:
        _fire()


func _fire() -> void:
    """发射子弹"""
    if bullet_scene == null:
        push_warning("Bullet scene not assigned!")
        return
    
    var bullet := bullet_scene.instantiate()
    get_tree().root.add_child(bullet)
    
    # 设置子弹位置和方向
    bullet.global_position = _muzzle.global_position
    bullet.set_direction(global_position.direction_to(_muzzle.global_position))
    
    # 启动冷却
    _can_fire = false
    _fire_timer = fire_cooldown
```

### 4.2 Bullet.gd - 子弹逻辑

```gdscript
## Bullet.gd
## 子弹 - 直线运动，碰撞检测
class_name Bullet
extends Area2D

#region 配置参数
@export var speed: float = 400.0          ## 飞行速度
@export var damage: int = 1               ## 伤害值
@export var max_distance: float = 1000.0  ## 最大飞行距离
#endregion

#region 私有变量
var _direction: Vector2 = Vector2.RIGHT
var _start_position: Vector2
#endregion


func _ready() -> void:
    _start_position = global_position
    # 连接碰撞信号
    body_entered.connect(_on_body_entered)
    area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
    # 直线运动
    position += _direction * speed * delta
    
    # 超出最大距离自动销毁
    if global_position.distance_to(_start_position) > max_distance:
        queue_free()


func set_direction(direction: Vector2) -> void:
    """设置子弹飞行方向"""
    _direction = direction.normalized()
    rotation = _direction.angle()


func _on_body_entered(body: Node2D) -> void:
    """碰撞物体（墙壁等）"""
    queue_free()


func _on_area_entered(area: Area2D) -> void:
    """碰撞区域（目标等）"""
    if area.has_method("take_damage"):
        area.take_damage(damage)
    queue_free()
```

### 4.3 Target.gd - 目标/敌人

```gdscript
## Target.gd
## 可击毁的目标
class_name Target
extends Area2D

#region 信号
signal destroyed
#endregion

#region 配置参数
@export var max_health: int = 3            ## 最大血量
@export var hit_flash_duration: float = 0.1 ## 受击闪烁时长
#endregion

#region 私有变量
var _current_health: int
var _sprite: Sprite2D
#endregion


func _ready() -> void:
    _current_health = max_health
    _sprite = $Sprite2D


func take_damage(amount: int) -> void:
    """受到伤害"""
    _current_health -= amount
    _play_hit_effect()
    
    if _current_health <= 0:
        _die()


func _play_hit_effect() -> void:
    """受击闪烁效果"""
    if _sprite:
        _sprite.modulate = Color.RED
        await get_tree().create_timer(hit_flash_duration).timeout
        _sprite.modulate = Color.WHITE


func _die() -> void:
    """死亡处理"""
    destroyed.emit()
    # 触发胜利特效（通过 GameManager 或直接生成）
    GameManager.trigger_victory(global_position)
    queue_free()
```

### 4.4 GameManager.gd - 游戏管理器

```gdscript
## GameManager.gd
## 全局游戏管理器 (Autoload 单例)
extends Node

#region 信号
signal game_victory
signal game_reset
#endregion

#region 配置参数
@export var victory_scene: PackedScene      ## 胜利特效场景
#endregion


func trigger_victory(position: Vector2) -> void:
    """触发胜利"""
    game_victory.emit()
    
    if victory_scene:
        var effect := victory_scene.instantiate()
        get_tree().root.add_child(effect)
        effect.global_position = position
        effect.play()
    
    # 延迟后显示提示
    await get_tree().create_timer(2.0).timeout
    print("🎉 Victory! Press R to restart.")


func restart_game() -> void:
    """重新开始游戏"""
    game_reset.emit()
    get_tree().reload_current_scene()
```

### 4.5 VictoryEffect.gd - 胜利礼花

```gdscript
## VictoryEffect.gd
## 胜利烟花特效
extends Node2D

#region 配置参数
@export var duration: float = 2.0           ## 特效持续时间
#endregion

#region 节点引用
@onready var _particles: CPUParticles2D = $CPUParticles2D
#endregion


func _ready() -> void:
    # 配置粒子系统（代码配置，无需外部资源）
    _setup_particles()


func play() -> void:
    """播放特效"""
    _particles.emitting = true
    await get_tree().create_timer(duration).timeout
    queue_free()


func _setup_particles() -> void:
    """配置烟花粒子效果"""
    var p := _particles
    
    # 基础设置
    p.emitting = false
    p.amount = 100
    p.one_shot = true
    p.explosiveness = 0.8
    p.lifetime = 1.5
    
    # 方向和速度
    p.direction = Vector2(0, -1)
    p.spread = 180.0
    p.initial_velocity_min = 200.0
    p.initial_velocity_max = 400.0
    
    # 重力和阻尼
    p.gravity = Vector2(0, 98)
    p.damping_min = 0.5
    p.damping_max = 1.0
    
    # 大小变化
    p.scale_amount_min = 3.0
    p.scale_amount_max = 8.0
    p.scale_curve = _create_scale_curve()
    
    # 颜色渐变（彩虹烟花）
    p.color_ramp = _create_fireworks_gradient()
    
    # 随机旋转
    p.angular_velocity_min = -360.0
    p.angular_velocity_max = 360.0


func _create_fireworks_gradient() -> GradientTexture1D:
    """创建彩虹渐变"""
    var gradient := Gradient.new()
    gradient.colors = PackedColorArray([
        Color.YELLOW,      # 黄
        Color.ORANGE,      # 橙
        Color.RED,         # 红
        Color.MAGENTA,     # 紫
        Color.CYAN,        # 青
        Color.WHITE,       # 白（消失）
        Color.TRANSPARENT  # 透明
    ])
    gradient.offsets = PackedFloat32Array([0.0, 0.15, 0.3, 0.45, 0.6, 0.8, 1.0])
    
    var texture := GradientTexture1D.new()
    texture.gradient = gradient
    return texture


func _create_scale_curve() -> CurveTexture:
    """创建大小变化曲线"""
    var curve := Curve.new()
    curve.add_point(Vector2(0, 1))      # 开始时最大
    curve.add_point(Vector2(0.5, 0.8))  # 中间略小
    curve.add_point(Vector2(1, 0))      # 结束时消失
    
    var texture := CurveTexture.new()
    texture.curve = curve
    return texture
```

---

## 5. 场景层级结构

### 5.1 Main.tscn (主场景)

```
Main (Node2D)
├── Background (ColorRect 或 Sprite2D)    # 地图背景
│   └── ColorRect: 尺寸覆盖视口，深色
├── Player (CharacterBody2D)              # 玩家
│   ├── CollisionShape2D (Rectangle)
│   ├── Sprite2D                          # 坦克图片
│   └── Muzzle (Marker2D)                 # 炮口位置
├── Target (Area2D)                       # 目标
│   ├── CollisionShape2D (Rectangle)
│   └── Sprite2D                          # 目标图片
└── UI (CanvasLayer)
    └── VictoryLabel (Label)              # 胜利提示
```

### 5.2 Player.tscn (独立场景)

```
Player (CharacterBody2D)
├── CollisionShape2D
│   └── Shape: RectangleShape2D (32x32)
├── Sprite2D
│   └── Texture: tank.png (临时用色块)
└── Muzzle (Marker2D)
    └── Position: (20, 0)  # 坦克前方
```

### 5.3 Bullet.tscn (独立场景)

```
Bullet (Area2D)
├── CollisionShape2D
│   └── Shape: CircleShape2D (半径 4)
└── Sprite2D
    └── Texture: bullet.png (小圆点)
```

### 5.4 VictoryEffect.tscn (独立场景)

```
VictoryEffect (Node2D)
└── CPUParticles2D
    └── (通过代码配置，无需手动设置)
```

---

## 6. 实现步骤（按顺序执行）

### Step 1: 项目初始化
1. 创建新项目 `tank_battle`
2. 配置输入映射（Project Settings → Input Map）
3. 创建目录结构 `scenes/`, `scripts/`, `assets/`

### Step 2: 创建子弹场景
1. 新建场景 `Bullet.tscn`
2. 根节点 `Area2D`，附加 `Bullet.gd`
3. 添加 `CollisionShape2D` + `Sprite2D`
4. 保存为独立场景

### Step 3: 创建玩家场景
1. 新建场景 `Player.tscn`
2. 根节点 `CharacterBody2D`，附加 `Player.gd`
3. 添加 `CollisionShape2D` + `Sprite2D` + `Marker2D`
4. 在 Inspector 中拖入 `Bullet.tscn`

### Step 4: 创建目标场景
1. 新建场景 `Target.tscn`
2. 根节点 `Area2D`，附加 `Target.gd`
3. 添加 `CollisionShape2D` + `Sprite2D`

### Step 5: 创建胜利特效
1. 新建场景 `VictoryEffect.tscn`
2. 根节点 `Node2D`，附加 `VictoryEffect.gd`
3. 添加 `CPUParticles2D` 子节点

### Step 6: 组装主场景
1. 新建场景 `Main.tscn`
2. 添加背景、玩家、目标
3. 创建 GameManager Autoload
4. 运行测试

---

## 7. 碰撞层设置

建议配置：

| 层级 | 名称 | 用途 |
|-----|------|-----|
| 1 | player | 玩家 |
| 2 | enemy | 敌人/目标 |
| 3 | projectile | 子弹 |
| 4 | wall | 墙壁 |

子弹碰撞设置：
- Layer: projectile
- Mask: enemy, wall

---

## 8. 测试检查清单

```
□ 玩家移动：WASD 四向移动
□ 坦克朝向：移动时朝向移动方向
□ 射击：空格发射子弹
□ 冷却：射击有间隔，不能连续发射
□ 子弹飞行：直线运动，超出距离消失
□ 目标受击：被击中会掉血、闪烁
□ 目标死亡：血量为0时销毁
□ 胜利特效：目标死亡后播放烟花
□ 控制台输出：显示胜利信息
```

---

## 9. 后续迭代方向

### Phase 2: 完善体验
- 添加音效（射击、爆炸）
- 添加 UI（血量条、分数）
- 添加关卡边界（墙壁）

### Phase 3: 游戏性扩展
- 多目标/敌人 AI
- 关卡系统
- 道具系统

### Phase 4: 打磨
- 视觉效果优化
- 移动端适配
- 性能优化

---

## 10. 快速启动命令

创建一个临时贴图（如果没有美术资源）：

```gdscript
# 在 Player._ready() 中生成临时贴图
var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
img.fill(Color.GREEN)
var tex := ImageTexture.create_from_image(img)
$Sprite2D.texture = tex
```

---

**文档版本**: 1.0  
**创建时间**: 2026-03-20  
**适用引擎**: Godot 4.6.1