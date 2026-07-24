extends EvolutionScrollBase
class_name ScrollWandItem

func _init() -> void:
	id = &"scroll_wand"
	display_name = "Pergaminho — Varinha"
	description = "Evolui a varinha ao acaso: disparo automático, mira automática, velocidade ou dano."
	cost = BASE_COST
	stackable = true
	icon_path = "res://assets/items/scroll_base.png"
	# TODO: ícone da varinha pra compor sobre o pergaminho quando existir um sprite.

func _find_target():
	var player := _find_player()
	if player and player.wand_ability.unlocked:
		return player.wand_ability
	return null
