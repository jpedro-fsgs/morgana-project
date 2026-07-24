extends EvolutionScrollBase
class_name ScrollOrbBladeItem

func _init() -> void:
	id = &"scroll_orb_blade"
	display_name = "Pergaminho — Lâmina Giratória"
	description = "Evolui a lâmina giratória ao acaso: velocidade, raio ou ataque."
	cost = BASE_COST
	stackable = true
	icon_path = "res://assets/items/scroll_base.png"
	icon_overlay_path = "res://assets/items/orb_icon_blade.png"

func _find_target():
	var manager := _find_manager()
	if manager == null:
		return null
	for orb in manager.get_orbs():
		if orb.get_kind_id() == &"orb_blade":
			return orb
	return null
