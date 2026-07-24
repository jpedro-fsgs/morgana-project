extends EvolutionScrollBase
class_name ScrollForceFieldItem

func _init() -> void:
	id = &"scroll_force_field"
	display_name = "Pergaminho — Campo de Força"
	description = "Evolui o campo de força ao acaso: ativação automática, raio ou dano."
	cost = BASE_COST
	stackable = true
	icon_path = "res://assets/items/scroll_base.png"
	# TODO: ícone do campo de força pra compor sobre o pergaminho quando existir um sprite.

func _find_target():
	var player := _find_player()
	if player and player.force_field_ability.unlocked:
		return player.force_field_ability
	return null
