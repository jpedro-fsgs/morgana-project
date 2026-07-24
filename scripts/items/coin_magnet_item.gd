extends ItemBase
class_name CoinMagnetItem

func _init() -> void:
	id = &"coin_magnet"
	display_name = "Ímã de Moedas"
	description = "Moedas voam até você em vez de esperar no chão."
	cost = 50
	icon_path = "res://assets/items/magnet_big.png"
	icon_small_path = "res://assets/items/magnet_small.png"

func apply() -> void:
	GameManager.coin_magnet_enabled = true

func remove() -> void:
	GameManager.coin_magnet_enabled = false
