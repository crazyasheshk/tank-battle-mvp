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
#endregion

#region 配置参数
@export var victory_scene: PackedScene
@export var game_time_limit: float = 40.0  # 40秒限时
#endregion

#region 状态
var score: int = 0
var is_game_active: bool = true
var is_paused: bool = false
var player_max_health: int = 5
var player_current_health: int = 5
var time_remaining: float = 40.0
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
		# F5 - 开始/继续游戏
		if event.keycode == KEY_F5:
			if get_tree().paused and is_game_active:
				toggle_pause()
			elif not is_game_active:
				restart_game()
			get_viewport().set_input_as_handled()
		
		# F6 - 暂停/继续
		if event.keycode == KEY_F6:
			if is_game_active:
				toggle_pause()
			get_viewport().set_input_as_handled()
		
		# F7 - 重新开始
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


func time_up() -> void:
	"""时间耗尽"""
	if not is_game_active:
		return
	
	is_game_active = false
	game_ended.emit()
	get_tree().paused = true
	print("⏰ Time Up! Final Score: %d" % score)


func trigger_victory(position: Vector2) -> void:
	game_victory.emit()
	add_score(100)
	
	if victory_scene:
		var effect := victory_scene.instantiate()
		get_tree().root.add_child(effect)
		effect.global_position = position
		if effect.has_method("play"):
			effect.play()
	
	await get_tree().create_timer(2.0).timeout
	print("🎉 Victory! Score: %d" % score)


func end_game() -> void:
	if not is_game_active:
		return
	
	is_game_active = false
	is_paused = false
	game_ended.emit()
	get_tree().paused = true
	print("💀 Game Over! Final Score: %d" % score)


func restart_game() -> void:
	score = 0
	is_game_active = true
	is_paused = false
	time_remaining = game_time_limit
	player_current_health = player_max_health
	get_tree().paused = false
	get_tree().reload_current_scene()