class_name CombatData extends Resource

enum PerilousType { NONE, SWEEP, THRUST, GRAB }

@export var damage: float = 10.0
@export var posture_damage: float = 8.0
@export var perilous_type: PerilousType = PerilousType.NONE

@export var parry_posture_reward: float = 35.0

@export var hitstop_duration: float = 0.10
@export var knockback_force: float = 60.0
@export var knockback_direction_override: Vector2 = Vector2.ZERO

@export var is_unblockable: bool = false
