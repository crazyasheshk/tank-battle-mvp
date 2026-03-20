## Target.gd
## 可击毁的目标
class_name Target
extends Area2D

#region 信号
signal destroyed
#endregion

#region 配置参数
@export var max_health: int = 3
@export var hit_flash_duration: float = 0.1
#endregion

#region 私有变量
var _current_health: int
var _visual: ColorRect
var _health_bar: ProgressBar
#endregion


func _ready() -> void:
	_current_health = max_health
	_visual = $Sprite2D
	_health_bar = $HealthBar
	_update_health_bar()


func _update_health_bar() -> void:
	if _health_bar:
		_health_bar.max_value = max_health
		_health_bar.value = _current_health


func take_damage(amount: int) -> void:
	_current_health -= amount
	_update_health_bar()
	_play_hit_effect()
	
	if _current_health <= 0:
		_die()


func _play_hit_effect() -> void:
	if _visual:
		_visual.color = Color.WHITE
		await get_tree().create_timer(hit_flash_duration).timeout
		_visual.color = Color(0.8, 0.2, 0.2)


func _die() -> void:
	destroyed.emit()
	GameManager.add_score(50)
	GameManager.trigger_victory(global_position)
	queue_free()