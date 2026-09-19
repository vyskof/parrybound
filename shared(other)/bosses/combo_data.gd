class_name ComboData extends Resource


@export var attack_ids: Array[StringName] = []
@export var weight: float = 1.0               
@export var phase: int = 0             
@export var min_range: float = 0.0             ## vzdálenost k hráči, od které se kombo hodí
@export var max_range: float = 9999.0
@export var next_state: StringName = &""       ## stav po kombu (prázdné = Follow)       

@export_group("Pauza po kombu")
@export var pause_min: float = 0.6
@export var pause_max: float = 0.9
