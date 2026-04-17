class_name Stats extends Resource


@export var health: = 100 :
	set(value):
		var previous_health = health
		health = value
		if health != previous_health: health_changed.emit(health) 
		if health <= 0: no_health.emit() 

@export var max_health: = 100

signal health_changed(new_health)
signal no_health()

@export var posture: float = 0 :
	set(value):
		var previous_posture = posture
		posture = value
		if posture != previous_posture: posture_changed.emit(posture)
		if posture >= max_posture: posture_broken.emit()

@export var max_posture: = 100

signal posture_changed(new_posture)
signal posture_broken
