class_name CombatData extends Resource

@export var damage: float = 10.0
@export var posture: float = 8.0

@export var parry_posture_reward: float = 35.0
@export var guard_posture_reward: float = 12.0
@export var guard_chip: float = 6.0

@export var hitstop_duration: float = 0.10
@export var knockback_force: float = 60.0
@export var knockback_direction_override: Vector2 = Vector2.ZERO

@export var is_unblockable: bool = false
@export var pierces_guard: bool = false
@export var ignore_parry_counter: bool = false
