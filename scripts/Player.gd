## Player.gd
## 玩家坦克控制器
class_name Player
extends CharacterBody2D

#region 信号
signal died
#endregion

#region 配置参数
@export_group("Movement")
@export var move_speed: float = 200.0
@export var rotation_speed: float = 5.0

@export_group("Combat")
@export var max_health: int = 5
@export var fire_cooldown: float = 0.3
@export var bullet_scene: PackedScene
#endregion

#region 私有变量
var _current_health: int
var _can_fire: bool = true
var _fire_timer: float = 0.0
#endregion

#region 节点引用
@onready var _muzzle: Marker2D = $Muzzle
@onready var _body: ColorRect = $Body
@onready var _health_bar: ProgressBar = $HealthBar
#endregion


func _ready() -> void:
	_current_health = max_health
	_update_health_bar()
	GameManager.update_health(_current_health, max_health)


func _physics_process(delta: float) -> void:
	_handle_movement()
	_handle_rotation()
	_handle_shooting(delta)
	move_and_slide()


func _handle_movement() -> void:
	var input_direction := Input.get_vector(
		"move_left", "move_right",
		"move_up", "move_down"
	)
	velocity = input_direction * move_speed


func _handle_rotation() -> void:
	if velocity.length_squared() > 0.1:
		var target_rotation := velocity.angle()
		rotation = lerp_angle(rotation, target_rotation, rotation_speed * get_physics_process_delta_time())


func _handle_shooting(delta: float) -> void:
	if not _can_fire:
		_fire_timer -= delta
		if _fire_timer <= 0:
			_can_fire = true
	
	if Input.is_action_just_pressed("shoot") and _can_fire:
		_fire()


func _fire() -> void:
	if bullet_scene == null:
		return
	
	var bullet := bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	bullet.global_position = _muzzle.global_position
	bullet.set_direction(Vector2.RIGHT.rotated(rotation))
	
	_can_fire = false
	_fire_timer = fire_cooldown


func take_damage(amount: int) -> void:
	_current_health -= amount
	_update_health_bar()
	GameManager.update_health(_current_health, max_health)
	_play_hit_effect()
	
	if _current_health <= 0:
		die()


func _update_health_bar() -> void:
	if _health_bar:
		_health_bar.max_value = max_health
		_health_bar.value = _current_health


func _play_hit_effect() -> void:
	if _body:
		_body.color = Color.RED
		await get_tree().create_timer(0.1).timeout
		_body.color = Color(0.2, 0.6, 0.2)


func die() -> void:
	died.emit()
	GameManager.end_game()
	queue_free()