class_name BossAttackState extends State


const PerilousWarning := preload("res://effects/perilous_warning.tscn")
const WARNING_OFFSET := Vector2(0, -70)

@onready var hitbox: Hitbox = owner.find_child("Hitbox")

var _current_warning: Node2D = null


func enter() -> void:
	super.enter()
	owner.set_physics_process(true)
	_run_combo()


func exit() -> void:
	super.exit()
	owner.set_physics_process(false)
	animation_player.speed_scale = 1.0
	owner.stop_telegraph_flash()
	if hitbox:
		hitbox.clear_hit_targets()
	_clear_warning()


func _run_combo() -> void:
	var moveset: BossMoveset = owner.moveset
	if moveset == null:
		push_error("%s: chybí moveset, útok se nedá provést." % owner.name)
		get_parent().change_state("Follow")
		return

	while is_active:
		var combo := moveset.pick_combo(owner.phase_number, owner.direction.length())
		if combo == null:
			push_warning("%s: pro fázi %d není žádné kombo." % [owner.name, owner.phase_number])
			get_parent().change_state("Follow")
			return

		for attack_id in combo.attack_ids:
			if not is_active:
				return
			var attack := moveset.get_attack(attack_id)
			if attack == null:
				continue
			await _perform(attack)
			if not is_active:
				return

		if combo.next_state != &"":
			get_parent().change_state(String(combo.next_state))
			return

		await get_tree().create_timer(randf_range(combo.pause_min, combo.pause_max)).timeout
		if not is_active:
			return
		if owner.direction.length() > owner.attack_range:
			get_parent().change_state("Follow")
			return


func _perform(attack: AttackData) -> void:
	if attack.combat_data and hitbox:
		hitbox.combat_data = attack.combat_data
		hitbox.clear_hit_targets()

	if attack.telegraph_time > 0.0:
		_begin_telegraph(attack)
		await get_tree().create_timer(attack.telegraph_time, true, false, true).timeout
		if not is_active:
			return

	owner.stop_telegraph_flash()
	animation_player.speed_scale = attack.animation_speed
	for animation_name in attack.animations:
		await await_animation(String(animation_name))
		if not is_active:
			animation_player.speed_scale = 1.0
			return
	animation_player.speed_scale = 1.0
	_clear_warning()

	if attack.projectile:
		_spawn_projectile(attack)


func _spawn_projectile(attack: AttackData) -> void:
	var projectile := attack.projectile.instantiate()
	get_tree().current_scene.add_child(projectile)
	if projectile is Node2D:
		projectile.global_position = owner.global_position + attack.projectile_offset


func _begin_telegraph(attack: AttackData) -> void:
	var perilous: bool = attack.combat_data and attack.combat_data.is_unblockable
	var perilous_type: int = attack.combat_data.perilous_type if attack.combat_data else 0
	var flash_color := PerilousVisuals.get_color(perilous_type) if perilous else attack.telegraph_color
	owner.play_telegraph_flash(flash_color, attack.telegraph_time)
	if not perilous:
		return
	_current_warning = PerilousWarning.instantiate()
	owner.add_child(_current_warning)
	_current_warning.position = WARNING_OFFSET
	_current_warning.init(
		PerilousVisuals.get_color(perilous_type),
		PerilousVisuals.get_symbol(perilous_type)
	)
	var cam := character.get_node_or_null("Camera2D") if is_instance_valid(character) else null
	if cam and cam.has_method("zoom_pulse"):
		cam.zoom_pulse(Vector2(0.94, 0.94), attack.telegraph_time + 0.15)


func _clear_warning() -> void:
	if is_instance_valid(_current_warning):
		_current_warning.queue_free()
	_current_warning = null
