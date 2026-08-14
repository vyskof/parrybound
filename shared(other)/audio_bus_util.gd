class_name AudioBusUtil

static func remove_effect_safe(bus_idx: int, effect: AudioEffect) -> void:
	for i in AudioServer.get_bus_effect_count(bus_idx):
		if AudioServer.get_bus_effect(bus_idx, i) == effect:
			AudioServer.remove_bus_effect(bus_idx, i)
			return
