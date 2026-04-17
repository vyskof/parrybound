class_name Parrybox extends Area2D

signal parried(hitbox: Hitbox)

func _ready() -> void:
	monitoring = false
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		parried.emit(area)
