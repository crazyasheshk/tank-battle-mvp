## StartScreen.gd
## 游戏开始界面 - 输入姓名后开始游戏
extends Control

@onready var _name_input: LineEdit = $NameInput
@onready var _start_button: Button = $StartButton

var _chinese_font: FontFile


func _ready() -> void:
	# 加载中文字体
	_load_chinese_font()
	
	_start_button.pressed.connect(_on_start_pressed)
	_name_input.text_submitted.connect(_on_text_submitted)
	# 聚焦到输入框
	_name_input.grab_focus()


func _load_chinese_font() -> void:
	var font := load("res://fonts/NotoSansSC-Regular.ttf") as FontFile
	if font:
		_chinese_font = font
		# 为所有 Label 和 Button 设置字体
		_set_font_recursive(self)
		print("✅ 开始界面字体已设置")


func _set_font_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Label or child is Button or child is LineEdit:
			if _chinese_font:
				child.add_theme_font_override("font", _chinese_font)
		if child.get_child_count() > 0:
			_set_font_recursive(child)


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
