## Bullet.gd
## 子弹 - 直线运动，碰撞检测
class_name Bullet
extends Area2D

#region 配置参数
@export var speed: float = 400.0
@export var damage: int = 1
@export var max_distance: float = 2000.0
#endregion

#region 私有变量
var _direction: Vector2 = Vector2.RIGHT
var _start_position: Vector2
#endregion


func _ready() -> void:
	_start_position = global_position
	# 确保碰撞检测开启
	monitoring = true
	monitorable = true
	# 连接碰撞信号
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	# 使用全局坐标移动
	global_position += _direction * speed * delta
	
	# 超出最大距离自动销毁
	if global_position.distance_to(_start_position) > max_distance:
		queue_free()


func set_direction(direction: Vector2) -> void:
	_direction = direction.normalized()
	rotation = _direction.angle()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
	queue_free()
