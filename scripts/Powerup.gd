## Powerup.gd
## 道具基类 - 碰撞后赋予玩家能力
class_name Powerup
extends Area2D

#region 配置
@export var powerup_type: String = "shotgun"  # 道具类型
@export var lifetime: float = 15.0  # 存在时间（秒）
#endregion

#region 私有变量
var _lifetime_timer: float = 0.0
#endregion

#region 节点引用
@onready var _sprite: ColorRect = $Sprite
@onready var _label: Label = $Label
#endregion


func _ready() -> void:
	_lifetime_timer = lifetime
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# 添加浮动动画效果
	_start_float_animation()


func _process(delta: float) -> void:
	_lifetime_timer -= delta
	
	# 闪烁效果（最后3秒）
	if _lifetime_timer <= 3.0:
		_sprite.modulate.a = 0.5 + 0.5 * sin(_lifetime_timer * 10)
	
	if _lifetime_timer <= 0:
		queue_free()


func _start_float_animation() -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - 5, 0.5)
	tween.tween_property(self, "position:y", position.y + 5, 0.5)


func get_powerup_type() -> String:
	return powerup_type


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect_powerup()


func _on_area_entered(area: Area2D) -> void:
	# 检测玩家的 PowerupDetector
	if area.is_in_group("player_detector"):
		_collect_powerup()


func _collect_powerup() -> void:
	# 拾取效果
	print("🎁 拾取道具: %s" % powerup_type)
	GameManager.collect_powerup(powerup_type)
	queue_free()