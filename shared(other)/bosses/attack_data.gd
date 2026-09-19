class_name AttackData extends Resource


@export var id: StringName = &""
@export var animation: StringName = &""        ## jméno animace v AnimationPlayeru bosse
@export var combat_data: CombatData            ## damage, posture, knockback, unblockable

@export_group("Čitelnost")
@export var telegraph_time: float = 0.0        
@export var animation_speed: float = 1.0       

@export_group("Použití")
@export var min_range: float = 0.0            
@export var max_range: float = 60.0           
