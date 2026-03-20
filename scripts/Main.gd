## Main.gd
## 主场景控制器
extends Node2D

@export var victory_effect_scene: PackedScene


func _ready() -> void:
	# 设置 GameManager 的胜利特效
	GameManager.victory_scene = victory_effect_scene
	
	# 初始化游戏状态
	_init_game_state()
	
	print("🎮 %s 开始游戏！" % GameManager.player_name)
	print("Controls: WASD to move, SPACE to shoot")


func _init_game_state() -> void:
	# 重置游戏状态（保留玩家姓名）
	GameManager.score = 0
	GameManager.is_game_active = true
	GameManager.is_paused = false
	GameManager.time_remaining = GameManager.game_time_limit
	GameManager.player_current_health = GameManager.player_max_health
	GameManager.enemies_killed = 0
	GameManager.target_invincible = true
	GameManager.last_completion_time = 0.0
	GameManager.last_rank = 0
