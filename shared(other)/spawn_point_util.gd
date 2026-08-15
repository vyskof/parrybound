class_name SpawnPointUtil

static func apply(character: Node2D, root: Node, spawn_point: String) -> void:
	if not character or not root:
		return
	var marker_name := "DefaultSpawn" if spawn_point == "default" or spawn_point.is_empty() else spawn_point
	var marker: Node2D = root.get_node_or_null(marker_name)
	if not marker:
		marker = root.get_node_or_null("DefaultSpawn")
	if marker:
		character.global_position = marker.global_position
