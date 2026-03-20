## VictoryEffect.gd
## 胜利烟花特效
extends Node2D

#region 配置参数
@export var duration: float = 2.0           ## 特效持续时间
#endregion

#region 节点引用
@onready var _particles: CPUParticles2D = $CPUParticles2D
#endregion


func _ready() -> void:
	_setup_particles()


func play() -> void:
	_particles.emitting = true
	await get_tree().create_timer(duration).timeout
	queue_free()


func _setup_particles() -> void:
	var p := _particles
	
	p.emitting = false
	p.amount = 100
	p.one_shot = true
	p.explosiveness = 0.8
	p.lifetime = 1.5
	
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 200.0
	p.initial_velocity_max = 400.0
	
	p.gravity = Vector2(0, 98)
	p.damping_min = 0.5
	p.damping_max = 1.0
	
	p.scale_amount_min = 3.0
	p.scale_amount_max = 8.0
	
	# 简化颜色设置
	p.color = Color.YELLOW
	
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0