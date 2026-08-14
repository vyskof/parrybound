extends Node2D

@export var area_size: Vector2 = Vector2(160, 40)
@export var particle_count: int = 40
@export var fog_color: Color = Color(0.6, 0.65, 0.7, 0.35)

@onready var _particles: CPUParticles2D = $CPUParticles2D

func _ready() -> void:
	add_to_group("fog_wall")
	_particles.amount = particle_count
	_particles.emission_rect_extents = area_size / 2.0
	_particles.color = fog_color
	deactivate()

func activate() -> void:
	visible = true
	_particles.emitting = true

func deactivate() -> void:
	_particles.emitting = false
	visible = false
