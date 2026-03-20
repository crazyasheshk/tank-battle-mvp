## GameUI.gd
## 游戏界面控制器
extends CanvasLayer

@onready var _health_label: Label = $TopBar/HealthLabel
@onready var _score_label: Label = $TopBar/ScoreLabel
@onready var _timer_label: Label = $TopBar/TimerLabel
@onready var _game_over_panel: Panel = $GameOverPanel
@onready var _victory_panel: Panel = $VictoryPanel
@onready var _pause_panel: Panel = $PausePanel
@onready var _final_score: Label = $GameOverPanel/FinalScore
@onready var _victory_score: Label = $VictoryPanel/Score


func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.game_ended.connect(_show_game_over)
	GameManager.game_victory.connect(_show_victory)
	GameManager.game_paused.connect(_on_pause_changed)
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.timer_changed.connect(_on_timer_changed)
	_on_health_changed(GameManager.player_current_health, GameManager.player_max_health)
	_on_timer_changed(GameManager.time_remaining)


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


func _on_pause_changed(is_paused: bool) -> void:
	_pause_panel.visible = is_paused


func _show_game_over() -> void:
	_game_over_panel.visible = true
	_final_score.text = "Score: %d" % GameManager.score


func _show_victory() -> void:
	_victory_panel.visible = true
	_victory_score.text = "Score: %d" % GameManager.score
