## Main.gd
## 主场景控制器
extends Node2D

@export var victory_effect_scene: PackedScene


func _ready() -> void:
	# 设置 GameManager 的胜利特效
	GameManager.victory_scene = victory_effect_scene
	print("🎮 Tank Battle MVP Started!")
	print("Controls: WASD to move, SPACE to shoot")