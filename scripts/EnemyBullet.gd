## EnemyBullet.gd
## 敌人子弹
class_name EnemyBullet
extends Area2D

@export var speed: float = 300.0
@export var damage: int = 1
@export var max_distance: float = 800.0

var _direction: Vector2 = Vector2.RIGHT
var _start_position: Vector2


func _ready() -> void:
	_start_position = global_position
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position += _direction * speed * delta
	
	if global_position.distance_to(_start_position) > max_distance:
		queue_free()


func set_direction(direction: Vector2) -> void:
	_direction = direction.normalized()
	rotation = _direction.angle()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	queue_free()