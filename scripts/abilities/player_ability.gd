extends Node
class_name PlayerAbility

var unlocked: bool = false

## Chamado pelo item correspondente (ver ItemManager) quando comprado.
func unlock() -> void:
	unlocked = true

func total_evolution_level() -> int:
	return 0

func is_fully_evolved() -> bool:
	return true

## Chamado pelo pergaminho de evolução — filhos sobrescrevem.
func apply_random_evolution() -> void:
	pass
