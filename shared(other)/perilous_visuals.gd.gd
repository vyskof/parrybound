class_name PerilousVisuals

static func get_color(type: CombatData.PerilousType) -> Color:
	match type:
		CombatData.PerilousType.SWEEP:  return Color(1.0, 0.75, 0.15, 1.0)   # oranžová — široký zásah, uhni do strany
		CombatData.PerilousType.THRUST: return Color(1.0, 0.13, 0.13, 1.0)   # červená — přímý zásah, uhni do strany/dozadu
		CombatData.PerilousType.GRAB:   return Color(0.7, 0.15, 0.9, 1.0)    # fialová — musí se dodgeovat včas, chytací útok
		_: return Color(1.0, 0.13, 0.13, 1.0)

static func get_symbol(type: CombatData.PerilousType) -> String:
	match type:
		CombatData.PerilousType.SWEEP:  return "↔"
		CombatData.PerilousType.THRUST: return "!"
		CombatData.PerilousType.GRAB:   return "◆"
		_: return "!"
