class_name BossMoveset extends Resource


@export var attacks: Array[AttackData] = []
@export var combos: Array[ComboData] = []


func get_attack(attack_id: StringName) -> AttackData:
	for attack in attacks:
		if attack and attack.id == attack_id:
			return attack
	push_warning("BossMoveset: útok '%s' není v movesetu." % attack_id)
	return null


## Vybere kombo pro danou fázi. Váhy fungují jako los: kombo s váhou 2
## vypadne dvakrát častěji než kombo s váhou 1.
func pick_combo(phase_number: int, rng: RandomNumberGenerator = null) -> ComboData:
	var pool: Array[ComboData] = []
	var total := 0.0
	for combo in combos:
		if combo == null or combo.attack_ids.is_empty():
			continue
		if combo.phase != 0 and combo.phase != phase_number:
			continue
		pool.append(combo)
		total += maxf(combo.weight, 0.0)
	if pool.is_empty():
		return null
	var roll := (rng.randf() if rng else randf()) * total
	for combo in pool:
		roll -= maxf(combo.weight, 0.0)
		if roll <= 0.0:
			return combo
	return pool[pool.size() - 1]


## Útoky, které se dají použít na dané vzdálenosti.
func attacks_in_range(distance: float) -> Array[AttackData]:
	var result: Array[AttackData] = []
	for attack in attacks:
		if attack and distance >= attack.min_range and distance <= attack.max_range:
			result.append(attack)
	return result
