## GameManager.gd
## 全局游戏管理器
extends Node

#region 信号
signal game_victory
signal game_ended
signal game_paused(is_paused: bool)
signal score_changed(new_score: int)
signal health_changed(current: int, maximum: int)
signal timer_changed(time_remaining: float)
signal enemies_changed(count: int)
signal victory_with_leaderboard(rank: int, completion_time: float)
signal level_changed(level: int)
signal powerup_collected(powerup_type: String)
#endregion

#region 配置参数
@export var victory_scene: PackedScene
@export var game_time_limit: float = 40.0
#endregion

#region 关卡配置
const LEVEL_CONFIG := {
	1: {
		"time": 40.0,
		"enemies": 3,
		"scene": "res://scenes/Level1.tscn"
	},
	2: {
		"time": 30.0,
		"enemies": 4,
		"scene": "res://scenes/Level2.tscn"
	}
}
const MAX_LEVEL := 2
#endregion

#region 状态
var player_name: String = "玩家"
var score: int = 0
var is_game_active: bool = true
var is_paused: bool = false
var player_max_health: int = 5
var player_current_health: int = 5
var time_remaining: float = 40.0
var total_enemies: int = 3
var enemies_killed: int = 0
var target_invincible: bool = true
var last_completion_time: float = 0.0
var last_rank: int = 0

# 关卡系统
var current_level: int = 1
var level_completion_times: Array[float] = []

# 道具系统
var has_shotgun: bool = false
#endregion


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	time_remaining = game_time_limit


func _process(delta: float) -> void:
	if is_game_active and not is_paused:
		time_remaining -= delta
		timer_changed.emit(time_remaining)
		
		if time_remaining <= 0:
			time_up()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F5:
			if get_tree().paused and is_game_active:
				toggle_pause()
			elif not is_game_active:
				restart_game()
			get_viewport().set_input_as_handled()
		
		if event.keycode == KEY_F6:
			if is_game_active:
				toggle_pause()
			get_viewport().set_input_as_handled()
		
		if event.keycode == KEY_F7:
			restart_game()
			get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	game_paused.emit(is_paused)
	print("⏸️ Game %s" % ("Paused" if is_paused else "Resumed"))


func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)


func update_health(current: int, maximum: int) -> void:
	player_current_health = current
	player_max_health = maximum
	health_changed.emit(current, maximum)


func register_enemy_death() -> void:
	enemies_killed += 1
	enemies_changed.emit(total_enemies - enemies_killed)
	print("💀 敌人击杀: %d/%d" % [enemies_killed, total_enemies])
	
	if enemies_killed >= total_enemies:
		target_invincible = false
		print("🎯 目标已解锁！现在可以攻击红色目标了！")


func is_target_attackable() -> bool:
	return not target_invincible


func time_up() -> void:
	if not is_game_active:
		return
	
	is_game_active = false
	game_ended.emit()
	get_tree().paused = true
	print("⏰ 时间耗尽！最终得分: %d" % score)


func trigger_victory(position: Vector2) -> void:
	var completion_time: float = LEVEL_CONFIG[current_level].time - time_remaining
	level_completion_times.append(completion_time)
	
	add_score(100)
	
	if victory_scene:
		var effect := victory_scene.instantiate()
		get_tree().root.add_child(effect)
		effect.global_position = position
		if effect.has_method("play"):
			effect.play()
	
	# 检查是否还有下一关
	if current_level < MAX_LEVEL:
		await get_tree().create_timer(1.5).timeout
		_advance_to_next_level()
	else:
		# 游戏全部通关
		await get_tree().create_timer(2.0).timeout
		_final_victory()


func _advance_to_next_level() -> void:
	current_level += 1
	level_changed.emit(current_level)
	
	# 保存当前状态
	var saved_name := player_name
	var saved_score := score
	var saved_health := player_current_health
	var saved_max_health := player_max_health
	var saved_shotgun := has_shotgun
	
	# 加载下一关
	var level_config: Dictionary = LEVEL_CONFIG[current_level]
	time_remaining = level_config.time
	game_time_limit = level_config.time
	total_enemies = level_config.enemies
	enemies_killed = 0
	target_invincible = true
	is_game_active = true
	
	# 恢复状态
	player_name = saved_name
	score = saved_score
	player_current_health = saved_health
	player_max_health = saved_max_health
	has_shotgun = saved_shotgun
	
	get_tree().change_scene_to_file(level_config.scene)
	print("🎮 进入第 %d 关！" % current_level)


func _final_victory() -> void:
	# 计算总用时
	var total_time := 0.0
	for t: float in level_completion_times:
		total_time += t
	
	# 添加到排行榜
	var rank := Leaderboard.add_entry(player_name, total_time, score)
	
	game_victory.emit()
	print("🎉🎉🎉 %s 全部通关！总得分: %d, 总用时: %.1f秒" % [player_name, score, total_time])
	
	victory_with_leaderboard.emit(rank, total_time)


func collect_powerup(powerup_type: String) -> void:
	match powerup_type:
		"shotgun":
			has_shotgun = true
			print("🔫 获得散弹道具！")
		_:
			return
	
	powerup_collected.emit(powerup_type)


func has_powerup(powerup_type: String) -> bool:
	match powerup_type:
		"shotgun":
			return has_shotgun
		_:
			return false


func end_game() -> void:
	if not is_game_active:
		return
	
	is_game_active = false
	is_paused = false
	game_ended.emit()
	get_tree().paused = true
	print("💀 游戏结束！%s 的最终得分: %d" % [player_name, score])


func restart_game() -> void:
	var saved_name := player_name
	_reset_game_state()
	player_name = saved_name
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Level1.tscn")


func _reset_game_state() -> void:
	score = 0
	is_game_active = true
	is_paused = false
	current_level = 1
	time_remaining = LEVEL_CONFIG[1].time
	game_time_limit = LEVEL_CONFIG[1].time
	player_current_health = 5
	player_max_health = 5
	total_enemies = LEVEL_CONFIG[1].enemies
	enemies_killed = 0
	target_invincible = true
	has_shotgun = false
	last_completion_time = 0.0
	last_rank = 0
	level_completion_times.clear()


func back_to_start() -> void:
	get_tree().change_scene_to_file("res://scenes/StartScreen.tscn")