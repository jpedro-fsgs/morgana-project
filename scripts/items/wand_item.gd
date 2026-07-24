extends ItemBase
class_name WandItem

func _init() -> void:
	id = &"wand"
	display_name = "Varinha Encantada"
	description = "Evolui seu tiro mágico: disparo automático, mira automática, velocidade e dano."
	cost = 45
	# TODO: ícone próprio quando existir um sprite.

func apply() -> void:
	var player := _find_player()
	if player:
		player.wand_ability.unlock()

func _find_player() -> Player:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("player") as Player
