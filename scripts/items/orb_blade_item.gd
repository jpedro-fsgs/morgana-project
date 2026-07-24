extends ItemBase
class_name OrbBladeItem

const ORB_SCENE: PackedScene = preload("res://scenes/orbs/orb_blade.tscn")

func _init() -> void:
	id = &"orb_blade"
	display_name = "Lâmina Giratória"
	description = "Gira ao seu redor e corta qualquer inimigo que encostar."
	cost = 55
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
