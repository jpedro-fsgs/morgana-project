extends ItemBase
class_name EvolutionScrollBase

const BASE_COST: int = 30
const COST_PER_LEVEL: int = 15

func compute_cost() -> int:
	var target = _find_target()
	if target == null:
		return BASE_COST
	return BASE_COST + COST_PER_LEVEL * target.total_evolution_level()

func is_available() -> bool:
	var target = _find_target()
	return target != null and not target.is_fully_evolved()

func apply() -> void:
	var target = _find_target()
	if target:
		target.apply_random_evolution()

## Filhos sobrescrevem: devolvem a orbe/habilidade específica que esse
## pergaminho evolui, ou null se ela ainda não foi comprada/equipada.
func _find_target():
	return null

func _find_manager() -> OrbManager:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("orb_manager") as OrbManager

func _find_player() -> Player:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("player") as Player
