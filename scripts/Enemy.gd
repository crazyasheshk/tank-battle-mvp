## Enemy.gd
## 敌人坦克 AI - 支持巡逻、追击、攻击、守卫模式
class_name Enemy
extends CharacterBody2D

#region 信号
signal died
#endregion

#region 配置参数
@export_group("Movement")
@export var move_speed: float = 80.0
@export var patrol_speed: float = 40.0
@export var rotation_speed: float = 3.0

@export_group("Combat")
@export var max_health: int = 3
@export var damage: int = 1
@export var fire_rate: float = 1.5
@export var detection_range: float = 300.0
@export var attack_range: float = 200.0

@export_group("Behavior")
@export var is_guard: bool = false
@export var guard_position: Vector2 = Vector2.ZERO
@export var guard_radius: float = 100.0

@export_group("References")
@export var bullet_scene: PackedScene
#endregion

#region 私有变量
var _current_health: int
var _fire_timer: float = 0.0
var _state: String = "idle"
var _patrol_direction: Vector2 = Vector2.ZERO
var _patrol_timer: float = 0.0
var _player_ref: Node2D = null
var _initial_position: Vector2
var _original_color: Color
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
	_initial_position = global_position
	
	# 根据类型设置颜色
	if is_guard:
		_original_color = Color(0.2, 0.4, 0.8)  # 蓝色 - 守卫
		if _body:
			_body.color = _original_color
		if _turret:
			_turret.color = Color(0.15, 0.3, 0.6)
	else:
		_original_color = Color(0.6, 0.2, 0.6)  # 紫色 - 攻击者
	
	# 更新血量条
	if _health_bar:
		_health_bar.max_value = max_health
		_health_bar.value = max_health
	
	# 连接检测区域信号
	if _detection_area:
		_detection_area.body_entered.connect(_on_player_detected)
		_detection_area.body_exited.connect(_on_player_lost)
	
	# 设置初始状态
	if is_guard:
		_state = "guard"
		if guard_position == Vector2.ZERO:
			guard_position = global_position
	else:
		_state = "idle"


func _physics_process(delta: float) -> void:
	match _state:
		"idle":
			_idle(delta)
		"patrol":
			_patrol(delta)
		"chase":
			_chase(delta)
		"attack":
			_attack(delta)
		"guard":
			_guard(delta)
	
	move_and_slide()


func _idle(_delta: float) -> void:
	velocity = Vector2.ZERO


func _patrol(delta: float) -> void:
	_patrol_timer -= delta
	
	if _patrol_timer <= 0:
		_patrol_direction = Vector2.RIGHT.rotated(randf() * TAU)
		_patrol_timer = randf_range(2.0, 4.0)
	
	velocity = _patrol_direction * patrol_speed
	_rotate_towards_movement(delta)


func _chase(delta: float) -> void:
	if not _is_player_valid():
		_state = "idle" if not is_guard else "guard"
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
		_state = "idle" if not is_guard else "guard"
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


func _guard(delta: float) -> void:
	if _is_player_valid():
		var to_player := _player_ref.global_position - global_position
		var distance := to_player.length()
		
		if distance <= attack_range:
			_state = "attack"
			return
		elif distance <= detection_range:
			_state = "chase"
			return
	
	_patrol_timer -= delta
	if _patrol_timer <= 0:
		_patrol_direction = Vector2.RIGHT.rotated(randf() * TAU)
		_patrol_timer = randf_range(1.5, 3.0)
	
	var to_guard_pos := guard_position - global_position
	if to_guard_pos.length() > guard_radius:
		_patrol_direction = to_guard_pos.normalized()
	
	velocity = _patrol_direction * patrol_speed * 0.5
	_rotate_towards_movement(delta)


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


func _is_player_valid() -> bool:
	return _player_ref != null and is_instance_valid(_player_ref) and _player_ref.is_inside_tree()


func _on_player_detected(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_ref = body
		_state = "chase"


func _on_player_lost(body: Node2D) -> void:
	if body == _player_ref:
		_player_ref = null
		_state = "guard" if is_guard else "idle"


func take_damage(amount: int) -> void:
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
	died.emit()
	GameManager.add_score(25)
	queue_free()
