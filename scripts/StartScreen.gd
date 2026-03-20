## StartScreen.gd
## 游戏开始界面 - 输入姓名后开始游戏
extends Control

@onready var _name_input: LineEdit = $NameInput
@onready var _start_button: Button = $StartButton


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_name_input.text_submitted.connect(_on_text_submitted)
	# 聚焦到输入框
	_name_input.grab_focus()


func _on_start_pressed() -> void:
	_start_game()


func _on_text_submitted(_text: String) -> void:
	_start_game()


func _start_game() -> void:
	var player_name := _name_input.text.strip_edges()
	
	if player_name.is_empty():
		player_name = "玩家"
	
	# 保存玩家姓名
	GameManager.player_name = player_name
	
	# 重置游戏状态
	GameManager._reset_game_state()
	
	# 切换到第一关
	get_tree().change_scene_to_file("res://scenes/Level1.tscn")
