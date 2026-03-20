## LevelController.gd
## 关卡控制器基类
extends Node2D

@export var victory_effect_scene: PackedScene
@export var level_number: int = 1


func _ready() -> void:
	GameManager.victory_scene = victory_effect_scene
	_init_game_state()
	
	print("🎮 %s 开始第%d关！" % [GameManager.player_name, level_number])
	print("Controls: WASD to move, SPACE to shoot")


func _init_game_state() -> void:
	var level_config: Dictionary = GameManager.LEVEL_CONFIG[level_number]
	
	GameManager.is_game_active = true
	GameManager.is_paused = false
	GameManager.time_remaining = level_config.time
	GameManager.total_enemies = level_config.enemies
	GameManager.enemies_killed = 0
	GameManager.target_invincible = true
	
	# 如果不是第一关，保留玩家状态
	if level_number == 1:
		GameManager.score = 0
		GameManager.player_current_health = GameManager.player_max_health
		GameManager.has_shotgun = false