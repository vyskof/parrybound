class_name Stats extends Resource


@export var health: float = 100.0:
	set(value):
		var previous_health = health
		health= clampf(value, 0.0, max_health)
		if health != previous_health: health_changed.emit(health) 
		if health <= 0.0 and previous_health > 0.0:  
			no_health.emit()
 

@export var max_health: float = 100.0

signal health_changed(new_health)
signal no_health()

@export var posture: float = 0 :
	set(value):
		var previous_posture = posture
		posture = clampf(value, 0.0, max_posture)
		if posture != previous_posture: posture_changed.emit(posture)
		if posture >= float(max_posture) and previous_posture < float(max_posture):
			posture_broken.emit()

@export var max_posture: float = 100.0

signal posture_changed(new_posture)
signal posture_broken
