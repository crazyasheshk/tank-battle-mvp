# 坦克对战 MVP

一个极简的坦克射击游戏原型。

## 快速开始

1. 用 Godot 4.6.1 打开项目文件夹
2. 点击运行按钮 (F5)
3. 开始游戏！

## 控制方式

| 按键 | 功能 |
|-----|------|
| W | 向上移动 |
| S | 向下移动 |
| A | 向左移动 |
| D | 向右移动 |
| 空格 | 射击 |

## 游戏目标

击中目标 3 次，观看胜利烟花！🎉

## 项目结构

```
tank-battle-mvp/
├── project.godot      # 项目配置
├── scenes/            # 场景文件
│   ├── Main.tscn      # 主场景
│   ├── Player.tscn    # 玩家坦克
│   ├── Bullet.tscn    # 子弹
│   ├── Target.tscn    # 目标
│   └── VictoryEffect.tscn  # 胜利特效
├── scripts/           # GDScript 脚本
│   ├── Player.gd
│   ├── Bullet.gd
│   ├── Target.gd
│   ├── GameManager.gd
│   ├── VictoryEffect.gd
│   └── Main.gd
└── assets/            # 资源文件（预留）
```

## 技术细节

- **玩家**: CharacterBody2D，使用 `get_vector()` 获取四向输入
- **子弹**: Area2D，直线运动，碰撞检测
- **目标**: Area2D，血量系统，受击反馈
- **胜利特效**: CPUParticles2D，代码配置烟花效果

## 下一步

- 添加音效
- 添加敌人 AI
- 多关卡系统
- 网络对战