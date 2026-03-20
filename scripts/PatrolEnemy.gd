## PatrolEnemy.gd
## 黄色巡逻坦克 - 击败后掉落散弹道具
class_name PatrolEnemy
extends CharacterBody2D

#region 信号
signal died
#endregion

#region 配置参数
@export_group("Movement")
@export var move_speed: float = 100.0
@export var patrol_speed: float = 80.0
@export var rotation_speed: float = 4.0

@export_group("Combat")
@export var max_health: int = 4
@export var damage: int = 1
@export var fire_rate: float = 2.0
@export var detection_range: float = 350.0
@export var attack_range: float = 250.0

@export_group("Patrol")
@export var patrol_points: Array[Vector2] = []
@export var patrol_wait_time: float = 1.0

@export_group("References")
@export var bullet_scene: PackedScene
@export var powerup_scene: PackedScene
#endregion

#region 私有变量
var _current_health: int
var _fire_timer: float = 0.0
var _state: String = "patrol"
var _player_ref: Node2D = null
var _patrol_index: int = 0
var _wait_timer: float = 0.0
var _original_color: Color = Color(0.9, 0.7, 0.1)  # 黄色
var _is_dying: bool = false  # 防止重复死亡
var _death_position: Vector2 = Vector2.ZERO  # 死亡位置
#endregion

#region 节点引用
@onready var _muzzle: Marker2D = $Muzzle
@onready var _detection_area: Area2D = $DetectionArea
@onready var _body: ColorRect = $Body
@onready var _turret: ColorRect = $Turret
@onready var _health_bar: ProgressBar = $HealthBar
#endregion


func _ready() -> void:
	_current_health = max_health
	_fire_timer = fire_rate
	
	if _body:
		_body.color = _original_color
	if _turret:
		_turret.color = Color(0.7, 0.5, 0.05)
	
	if _health_bar:
		_health_bar.max_value = max_health
		_health_bar.value = max_health
	
	if _detection_area:
		_detection_area.body_entered.connect(_on_player_detected)
		_detection_area.body_exited.connect(_on_player_lost)
	
	if patrol_points.is_empty():
		patrol_points = [
			global_position + Vector2(-150, 0),
			global_position + Vector2(150, 0)
		]


func _physics_process(delta: float) -> void:
	match _state:
		"patrol":
			_patrol(delta)
		"chase":
			_chase(delta)
		"attack":
			_attack(delta)
	
	move_and_slide()


func _patrol(delta: float) -> void:
	if _wait_timer > 0:
		_wait_timer -= delta
		velocity = Vector2.ZERO
		return
	
	if patrol_points.is_empty():
		return
	
	var target_pos: Vector2 = patrol_points[_patrol_index]
	var to_target := target_pos - global_position
	
	if to_target.length() < 10:
		_patrol_index = (_patrol_index + 1) % patrol_points.size()
		_wait_timer = patrol_wait_time
		return
	
	velocity = to_target.normalized() * patrol_speed
	_rotate_towards_movement(delta)


func _chase(delta: float) -> void:
	if not _is_player_valid():
		_state = "patrol"
		return
	
	var to_player := _player_ref.global_position - global_position
	var distance := to_player.length()
	
	if distance <= attack_range:
		_state = "attack"
		return
	
	velocity = to_player.normalized() * move_speed
	_rotate_towards_movement(delta)


func _attack(delta: float) -> void:
	if not _is_player_valid():
		_state = "patrol"
		return
	
	var to_player := _player_ref.global_position - global_position
	var distance := to_player.length()
	
	if distance > attack_range * 1.5:
		_state = "chase"
		return
	
	velocity = Vector2.ZERO
	var target_rotation := to_player.angle()
	rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta * 2)
	
	_fire_timer -= delta
	if _fire_timer <= 0:
		_fire()
		_fire_timer = fire_rate


func _rotate_towards_movement(delta: float) -> void:
	if velocity.length_squared() > 0.1:
		var target_rotation := velocity.angle()
		rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)


func _fire() -> void:
	var bullet_scene := preload("res://scenes/EnemyBullet.tscn")
	var bullet := bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	bullet.global_position = _muzzle.global_position
	bullet.set_direction(Vector2.RIGHT.rotated(rotation))
	bullet.damage = damage


func _spawn_powerup() -> void:
	# 使用 call_deferred 避免物理查询冲突
	call_deferred("_do_spawn_powerup")


func _do_spawn_powerup() -> void:
	var powerup_scene := preload("res://scenes/Powerup.tscn")
	var powerup := powerup_scene.instantiate()
	get_tree().root.add_child(powerup)
	# 使用保存的死亡位置
	powerup.global_position = _death_position
	print("⭐ 散弹道具已掉落在位置: %s" % _death_position)


func _is_player_valid() -> bool:
	return _player_ref != null and is_instance_valid(_player_ref) and _player_ref.is_inside_tree()


func _on_player_detected(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_ref = body
		_state = "chase"


func _on_player_lost(body: Node2D) -> void:
	if body == _player_ref:
		_player_ref = null
		_state = "patrol"


func take_damage(amount: int) -> void:
	if _is_dying:
		return
	_current_health -= amount
	_play_hit_effect()
	if _health_bar:
		_health_bar.value = _current_health
	if _current_health <= 0:
		die()


func _play_hit_effect() -> void:
	if _body:
		_body.color = Color.WHITE
		await get_tree().create_timer(0.1).timeout
		_body.color = _original_color


func die() -> void:
	if _is_dying:
		return
	_is_dying = true
	# 保存死亡位置
	_death_position = global_position
	died.emit()
	GameManager.add_score(50)
	GameManager.register_enemy_death()  # 注册敌人死亡
	_spawn_powerup()
	queue_free()