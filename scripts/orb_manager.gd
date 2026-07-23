extends Node2D
class_name OrbManager

func _ready() -> void:
	# Atrasar levemente para garantir que as orbes foram instanciadas e prontas
	call_deferred("_organize_orbs")

func _organize_orbs() -> void:
	var orbs := []
	for child in get_children():
		if child is OrbBase:
			orbs.append(child)
			
	var count = orbs.size()
	if count == 0:
		return
		
	var angle_step = TAU / count
	for i in range(count):
		orbs[i].orbit_offset = i * angle_step
