class_name AttackData extends Resource


@export var id: StringName = &""
@export var animations: Array[StringName] = []  ## animace v pořadí (laser = nabíjení + paprsek)
@export var combat_data: CombatData            ## damage, posture, knockback, unblockable

@export_group("Čitelnost")
@export var telegraph_time: float = 0.0       
@export var telegraph_color: Color = Color(1.5, 1.35, 0.85, 1.0)  ## barva záblesku během nápřahu 
@export var animation_speed: float = 1.0       

@export_group("Projektil")
@export var projectile: PackedScene            ## vystřelí se po animaci (null = nic)
@export var projectile_offset: Vector2 = Vector2.ZERO

@export_group("Použití")
@export var min_range: float = 0.0            
@export var max_range: float = 60.0           
