extends State

@onready var hitbox: Hitbox = owner.find_child("Hitbox")

const PerilousWarning := preload("res://effects/perilous_warning.tscn")
const PERILOUS_CHANCE            := 0.25
const PERILOUS_CHANCE_PHASE_TWO  := 0.4

var _current_warning: Node2D = null

func enter() -> void:
	super.enter()
	is_active = true
	owner.set_physics_process(true)
	_setup_hitbox()
	combo()

func exit() -> void:
	super.exit()
	is_active = false
	owner.set_physics_process(false)
	hitbox.clear_hit_targets()
	_clear_perilous_state()

func _setup_hitbox() -> void:
	if hitbox.combat_data:
		hitbox.combat_data.damage          = 20.0
		hitbox.combat_data.posture_damage  = 15.0
		hitbox.combat_data.knockback_force = 150.0
	else:
		hitbox.damage = 20.0


const PERILOUS_TELEGRAPH_LEAD := 0.35   

func attack(move: String = "1", perilous: bool = false) -> void:
	if perilous:
		_begin_perilous_telegraph()
		await get_tree().create_timer(PERILOUS_TELEGRAPH_LEAD, true, false, true).timeout
		if not is_active:
			return

	animation_player.speed_scale = 1.5 if owner.phase_two else 1.0
	animation_player.play("attack_" + move)
	await animation_player.animation_finished

	if perilous:
		_clear_perilous_state()

func combo() -> void:
	while is_active:
		var combo_length = randi_range(1, 3) if not owner.phase_two else randi_range(2, 4)
		var move_set: Array[String] = []
		for i in combo_length:
			move_set.append(str(randi_range(1, 2)))

		for move in move_set:
			if not is_active:
				return
			var chance := PERILOUS_CHANCE_PHASE_TWO if owner.phase_two else PERILOUS_CHANCE
			var is_perilous := move == "2" and randf() < chance
			await attack(move, is_perilous)

		var wait = randf_range(0.4, 0.9) if not owner.phase_two else randf_range(0.2, 0.4)
		await get_tree().create_timer(wait).timeout
		
		if not is_active:
			return

		if owner.direction.length() > 40:
			get_parent().change_state("Follow")
			return

func _begin_perilous_telegraph() -> void:
	if hitbox.combat_data:
		hitbox.combat_data.is_unblockable = true
		hitbox.combat_data.perilous_type  = CombatData.PerilousType.SWEEP
		hitbox.combat_data.posture_damage = 0.0   

	_current_warning = PerilousWarning.instantiate()
	owner.add_child(_current_warning)
	_current_warning.position = Vector2(0, -70)
	_current_warning.init(
		PerilousVisuals.get_color(CombatData.PerilousType.SWEEP),
		PerilousVisuals.get_symbol(CombatData.PerilousType.SWEEP)
	)

	var cam := character.get_node_or_null("Camera2D") if is_instance_valid(character) else null
	if cam and cam.has_method("zoom_pulse"):
		cam.zoom_pulse(Vector2(0.94, 0.94), PERILOUS_TELEGRAPH_LEAD + 0.15)

func _clear_perilous_state() -> void:
	if hitbox.combat_data:
		hitbox.combat_data.is_unblockable = false
		hitbox.combat_data.perilous_type  = CombatData.PerilousType.NONE
		hitbox.combat_data.posture_damage = 15.0 

	if is_instance_valid(_current_warning):
		_current_warning.queue_free()
		_current_warning = null

func transition():
	pass
