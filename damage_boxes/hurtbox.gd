class_name Hurtbox extends Area2D

signal hurt(combat_data: CombatData, hitbox: Hitbox)

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area is not Hitbox:
		return
	
	var hitbox := area as Hitbox
	if not hitbox.can_hit(self):
		return
	hitbox.register_hit(self)
	hurt.emit(hitbox.combat_data, hitbox)
