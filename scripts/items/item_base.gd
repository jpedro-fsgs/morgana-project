extends Resource
class_name ItemBase

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var cost: int = 0
@export var icon_path: String = ""          # ícone grande, usado na loja
@export var icon_overlay_path: String = "" # composto por cima do ícone grande (ex: orbe dentro do pergaminho)
@export var icon_small_path: String = ""    # ícone pequeno, usado na HUD

## Itens não-empilháveis só podem ser comprados uma vez (ex: ímã de moedas).
## Itens empilháveis (ex: pergaminho de evolução) podem ser comprados várias vezes.
@export var stackable: bool = false

## Chamado quando o item é adquirido — filhos sobrescrevem para aplicar o efeito.
func apply() -> void:
	pass

## Chamado se o item precisar ser revertido (ex: perdido ao morrer, se algum dia existir isso).
func remove() -> void:
	pass

## Filhos sobrescrevem para esconder o item da loja quando não há mais o que aplicar
## (ex: pergaminho quando o orbe já está no nível máximo).
func is_available() -> bool:
	return true

## Filhos sobrescrevem para preço dinâmico (ex: pergaminho fica mais caro a cada compra).
func compute_cost() -> int:
	return cost
