class_name CombatTuning extends Resource


@export_group("Pohyb")
@export var speed: float = 150.0
@export var attack_move_speed_mult: float = 0.40
@export var low_stamina_ratio: float = 0.25
@export var low_stamina_speed_mult: float = 0.85

@export_group("Parry")
@export var deflect_window: float = 0.16
@export var parry_action_duration: float = 0.25
@export var parry_cooldown: float = 0.30
@export var deflect_recovery: float = 0.08
@export var input_buffer_time: float = 0.25
@export var parry_spam_decay_time: float = 2.0
@export var parry_spam_max_count: int = 3
@export var deflect_stamina_reward: float = 12.0
@export var parry_posture_restore: float = 8.0
@export var deflect_pushback: float = 90.0

@export_group("Counter a streak")
@export var counter_window_duration: float = 0.30
@export var counter_posture_mult: float = 1.5
@export var streak_reset_time: float = 2.5
@export var streak_max: int = 4
@export var streak_posture_per_level: float = 0.15

@export_group("Útok")
@export var attack_startup: float = 0.12     
@export var attack_active: float = 0.10      
@export var attack_recovery: float = 0.28    
@export var attack_reach: float = 22.0      
@export var attack_stamina_cost: float = 15.0
@export var base_attack_damage: float = 10.0
@export var base_attack_posture_dmg: float = 10.0
@export var combo_pulse_window: float = 0.15
@export var combo_attack_speed: float = 1.15
@export var riposte_attack_speed: float = 1.4
@export var riposte_lunge_distance: float = 14.0

@export_group("Dodge")
@export var dodge_speed: float = 400.0
@export var dodge_duration: float = 0.11
@export var dodge_iframes: float = 0.10
@export var dodge_stamina_cost: float = 25.0
@export var dodge_cooldown: float = 0.25
@export var dodge_cancel_stamina_mult: float = 1.3

@export_group("Fast move")
@export var fast_move_speed: float = 300.0
@export var fast_move_duration: float = 1.0
@export var fast_move_stamina_cost: float = 30.0
@export var fast_move_cooldown: float = 2.0

@export_group("Stamina")
@export var stamina_regen_rate: float = 40.0
@export var stamina_regen_delay: float = 1.0

@export_group("Posture")
@export var posture_regen_rate: float = 15.0
@export var posture_regen_delay: float = 2.5
@export var stagger_duration: float = 1.8
@export var posture_recovery_on_hit: float = 4.0

@export_group("Vlastní zásah")
@export var own_hit_hitstop: float = 0.05
@export var own_hit_shake: float = 1.2

@export_group("Knockback")
@export var knockback_friction: float = 400.0

@export_group("Regain")
@export var regain_ratio: float = 0.5
@export var regain_decay_delay: float = 1.0
@export var regain_decay_rate: float = 15.0
