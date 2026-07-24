extends Node

signal item_acquired(item: ItemBase)

var _owned: Dictionary = {}  # id (StringName) -> ItemBase

func is_owned(id: StringName) -> bool:
	return _owned.has(id)

func get_owned_items() -> Array[ItemBase]:
	var items: Array[ItemBase] = []
	for item in _owned.values():
		items.append(item)
	return items

## Tenta comprar o item com o dinheiro do GameManager. Retorna true se conseguiu.
func purchase(item: ItemBase) -> bool:
	if not item.stackable and is_owned(item.id):
		return false
	var price := item.compute_cost()
	if GameManager.money < price:
		return false
	GameManager.add_money(-price)
	if item.stackable:
		item.apply()
		item_acquired.emit(item)
	else:
		_acquire(item)
	return true

## Concede o item diretamente, sem custo (ex: recompensa, debug).
func grant(item: ItemBase) -> bool:
	if is_owned(item.id):
		return false
	_acquire(item)
	return true

func _acquire(item: ItemBase) -> void:
	_owned[item.id] = item
	item.apply()
	item_acquired.emit(item)

## Reverte e esquece todos os itens adquiridos (ex: ao reiniciar a partida).
func reset() -> void:
	for item in _owned.values():
		item.remove()
	_owned.clear()
