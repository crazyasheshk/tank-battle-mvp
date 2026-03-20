## GameUI.gd
## 游戏界面控制器
extends CanvasLayer

# 预加载字体路径
const CHINESE_FONT_PATH := "res://fonts/NotoSansSC-Regular.ttf"

@onready var _health_label: Label = $TopBar/HealthLabel
@onready var _score_label: Label = $TopBar/ScoreLabel
@onready var _timer_label: Label = $TopBar/TimerLabel
@onready var _enemies_label: Label = $TopBar/EnemiesLabel
@onready var _player_name_label: Label = $TopBar/PlayerNameLabel
@onready var _level_label: Label = $TopBar/LevelLabel
@onready var _powerup_label: Label = $TopBar/PowerupLabel
@onready var _game_over_panel: Panel = $GameOverPanel
@onready var _victory_panel: Panel = $VictoryPanel
@onready var _pause_panel: Panel = $PausePanel
@onready var _final_score: Label = $GameOverPanel/FinalScore
@onready var _victory_score: Label = $VictoryPanel/Score
@onready var _hint_label: Label = $HintPanel/HintText
@onready var _leaderboard_panel: Panel = $LeaderboardPanel
@onready var _leaderboard_list: VBoxContainer = $LeaderboardPanel/ScrollContainer/LeaderboardList
@onready var _victory_time: Label = $VictoryPanel/Time
@onready var _victory_rank: Label = $VictoryPanel/Rank


func _ready() -> void:
	# 设置中文字体
	_setup_chinese_font()
	
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.game_ended.connect(_show_game_over)
	GameManager.game_victory.connect(_show_victory)
	GameManager.game_paused.connect(_on_pause_changed)
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.timer_changed.connect(_on_timer_changed)
	GameManager.enemies_changed.connect(_on_enemies_changed)
	GameManager.victory_with_leaderboard.connect(_show_victory_with_leaderboard)
	GameManager.level_changed.connect(_on_level_changed)
	GameManager.powerup_collected.connect(_on_powerup_collected)
	
	_on_health_changed(GameManager.player_current_health, GameManager.player_max_health)
	_on_timer_changed(GameManager.time_remaining)
	_on_enemies_changed(GameManager.total_enemies - GameManager.enemies_killed)
	_update_player_name()
	_update_hint()
	_update_level()
	_update_powerup_status()


func _setup_chinese_font() -> void:
	var font := ResourceLoader.load(CHINESE_FONT_PATH, "FontFile", ResourceLoader.CACHE_MODE_REPLACE) as FontFile
	if font:
		_apply_font_recursive(self, font)
		print("✅ 游戏界面字体已应用")


func _apply_font_recursive(node: Node, font: FontFile) -> void:
	for child in node.get_children():
		if child is Label or child is Button or child is LineEdit:
			child.add_theme_font_override("font", font)
		if child.get_child_count() > 0:
			_apply_font_recursive(child, font)


func _update_player_name() -> void:
	if _player_name_label:
		_player_name_label.text = GameManager.player_name


func _update_hint() -> void:
	if _hint_label:
		if GameManager.is_target_attackable():
			_hint_label.text = "🎯 目标已解锁！"
			_hint_label.modulate = Color.GREEN
		else:
			var remaining := GameManager.total_enemies - GameManager.enemies_killed
			_hint_label.text = "🔒 还需消灭 %d 个敌人" % remaining
			_hint_label.modulate = Color.YELLOW


func _on_health_changed(current: int, maximum: int) -> void:
	_health_label.text = "HP: %d/%d" % [current, maximum]
	if current <= maximum * 0.3:
		_health_label.modulate = Color.RED
	else:
		_health_label.modulate = Color.WHITE


func _on_score_changed(new_score: int) -> void:
	_score_label.text = "Score: %d" % new_score


func _on_timer_changed(time_remaining: float) -> void:
	var seconds := int(time_remaining)
	_timer_label.text = "Time: %ds" % seconds
	if time_remaining <= 10.0:
		_timer_label.modulate = Color.RED
	else:
		_timer_label.modulate = Color.WHITE


func _on_enemies_changed(count: int) -> void:
	if _enemies_label:
		_enemies_label.text = "敌人: %d" % count
	_update_hint()


func _on_level_changed(level: int) -> void:
	_update_level()


func _on_powerup_collected(_powerup_type: String) -> void:
	_update_powerup_status()


func _update_level() -> void:
	if _level_label:
		_level_label.text = "第 %d 关" % GameManager.current_level


func _update_powerup_status() -> void:
	if _powerup_label:
		if GameManager.has_shotgun:
			_powerup_label.text = "🔫 散弹"
			_powerup_label.modulate = Color.ORANGE
		else:
			_powerup_label.text = ""


func _on_pause_changed(is_paused: bool) -> void:
	_pause_panel.visible = is_paused


func _show_game_over() -> void:
	_game_over_panel.visible = true
	_final_score.text = "%s 的得分: %d" % [GameManager.player_name, GameManager.score]


func _show_victory() -> void:
	_victory_panel.visible = true
	_victory_score.text = "得分: %d" % GameManager.score
	_victory_time.text = "用时: " + Leaderboard.format_time(GameManager.last_completion_time)
	if GameManager.last_rank > 0:
		_victory_rank.text = "🏆 排名: 第 %d 名" % GameManager.last_rank
		_victory_rank.modulate = Color.GOLD if GameManager.last_rank <= 3 else Color.WHITE
	else:
		_victory_rank.text = ""


func _show_victory_with_leaderboard(rank: int, completion_time: float) -> void:
	GameManager.last_completion_time = completion_time
	GameManager.last_rank = rank
	_show_victory()
	_show_leaderboard(rank)


func _show_leaderboard(highlight_rank: int) -> void:
	# 清空现有列表
	for child: Node in _leaderboard_list.get_children():
		child.queue_free()
	
	# 添加标题
	var title := Label.new()
	title.text = "🏆 世界排行榜"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	_leaderboard_list.add_child(title)
	
	# 添加分割线
	var separator := HSeparator.new()
	_leaderboard_list.add_child(separator)
	
	# 获取排行榜数据
	var entries := Leaderboard.get_entries()
	
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "暂无记录"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_leaderboard_list.add_child(empty_label)
	else:
		for i: int in entries.size():
			var entry: Leaderboard.Entry = entries[i]
			var rank_num := i + 1
			
			var entry_label := Label.new()
			var medal := ""
			match rank_num:
				1: medal = "🥇 "
				2: medal = "🥈 "
				3: medal = "🥉 "
				_: medal = "%d. " % rank_num
			
			entry_label.text = "%s%s - %s | %d分" % [
				medal,
				entry.player_name,
				Leaderboard.format_time(entry.completion_time),
				entry.score
			]
			entry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			
			# 高亮当前玩家的记录
			if rank_num == highlight_rank:
				entry_label.modulate = Color.YELLOW
				entry_label.add_theme_font_size_override("font_size", 20)
			else:
				entry_label.add_theme_font_size_override("font_size", 16)
			
			_leaderboard_list.add_child(entry_label)
	
	_leaderboard_panel.visible = true
