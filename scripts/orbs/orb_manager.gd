extends Node2D
class_name OrbManager

const MAX_ORBS: int = 3

func _ready() -> void:
	add_to_group("orb_manager")
	# Atrasar levemente para garantir que as orbes foram instanciadas e prontas
	call_deferred("_organize_orbs")

func get_orbs() -> Array[OrbBase]:
	var orbs: Array[OrbBase] = []
	for child in get_children():
		if child is OrbBase:
			orbs.append(child)
	return orbs

func has_room() -> bool:
	return get_orbs().size() < MAX_ORBS

func has_kind(kind_id: StringName) -> bool:
	for orb in get_orbs():
		if orb.get_kind_id() == kind_id:
			return true
	return false

func _organize_orbs() -> void:
	var orbs := get_orbs()
	var count = orbs.size()
	if count == 0:
		return
		
	var angle_step = TAU / count
	for i in range(count):
		orbs[i].orbit_offset = i * angle_step

func add_orb(orb: OrbBase) -> void:
	add_child(orb)
	call_deferred("_organize_orbs")
