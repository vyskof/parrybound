extends StaticBody2D

const REGEN_DELAY := 1.5
const HIT_FLASH_COLOR := Color(1.6, 0.5, 0.5, 1.0)

@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _sprite: ColorRect = $Sprite
@onready var _label: Label = $HitCountLabel

var _damage: int = 0
var _regen_timer: float = 0.0

func _ready() -> void:
	_hurtbox.hurt.connect(_on_hurt)
	_update_label()

func _process(delta: float) -> void:
	if _damage == 0:
		return
	_regen_timer += delta
	if _regen_timer >= REGEN_DELAY:
		_damage = 0
		_regen_timer = 0.0
		_update_label()

func _on_hurt(_combat_data: CombatData, _hitbox: Hitbox) -> void:
	_damage += _hitbox.combat_data.damage
	_regen_timer = 0.0
	_update_label()
	_flash()

func _update_label() -> void:
	_label.text = "Hits: %d" % _damage

func _flash() -> void:
	_sprite.modulate = HIT_FLASH_COLOR
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.15)
