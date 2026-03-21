## StartScreen.gd
## 游戏开始界面 - 输入姓名后开始游戏
extends Control

# 预加载字体（编译时嵌入，确保 Web 端可用）
var _chinese_font: FontFile = preload("res://fonts/NotoSansSC-Regular.ttf")

@onready var _name_input: LineEdit = $NameInput
@onready var _start_button: Button = $StartButton


func _ready() -> void:
	# 设置中文字体
	_setup_chinese_font()
	
	_start_button.pressed.connect(_on_start_pressed)
	_name_input.text_submitted.connect(_on_text_submitted)
	_name_input.grab_focus()


func _setup_chinese_font() -> void:
	if _chinese_font:
		_apply_font_recursive(self, _chinese_font)
		print("✅ StartScreen: 中文字体已应用")
	else:
		push_error("❌ 无法加载中文字体！")


func _apply_font_recursive(node: Node, font: FontFile) -> void:
	for child in node.get_children():
		if child is Label or child is Button or child is LineEdit:
			child.add_theme_font_override("font", font)
		if child.get_child_count() > 0:
			_apply_font_recursive(child, font)


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
