extends ItemBase
class_name ForceFieldItem

func _init() -> void:
	id = &"force_field"
	display_name = "Campo de Força"
	description = "Um anel de repulsão ao seu redor. Clique com o botão direito do mouse pra ativar."
	cost = 45
	# TODO: sprite próprio pro anel — hoje é um efeito desenhado por código.

func apply() -> void:
	var player := _find_player()
	if player:
		player.force_field_ability.unlock()

func _find_player() -> Player:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("player") as Player
