extends ItemBase
class_name OrbExplosiveItem

const ORB_SCENE: PackedScene = preload("res://scenes/orbs/orb_explosive.tscn")

func _init() -> void:
	id = &"orb_explosive"
	display_name = "Orbe Explosiva"
	description = "Dispara bombas que causam dano em área ao acertar."
	cost = 75
	# TODO: ícone próprio quando existir um sprite.

func is_available() -> bool:
	var manager := _find_manager()
	return manager != null and manager.has_room() and not manager.has_kind(id)

func apply() -> void:
	var manager := _find_manager()
	if manager:
		manager.add_orb(ORB_SCENE.instantiate())

func _find_manager() -> OrbManager:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("orb_manager") as OrbManager
