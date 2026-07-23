extends Node2D
class_name OrbBase

@export var detection_radius: float = 380.0
@export var attack_cooldown: float = 1.6
@export var orbit_radius: float = 42.0
@export var orbit_speed: float = 2.2

var orbit_offset: float = 0.0
var _current_angle: float = 0.0
var _can_attack: bool = true

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	_current_angle += orbit_speed * delta
	var final_angle = _current_angle + orbit_offset
	position = Vector2(cos(final_angle) * orbit_radius, sin(final_angle) * orbit_radius * 0.5 - 55.0)
	
	if not GameManager.is_game_active:
		return
		
	if _can_attack:
		var target := _find_target()
		if target:
			_execute_attack(target)

# Função virtual para ser sobrescrita pelos filhos
func _find_target() -> Node2D:
	return null

# Função utilitária (helper) que as orbes filhas podem chamar se quiserem
func get_nearest_entity_in_radius(group_name: String) -> Node2D:
	var entities := get_tree().get_nodes_in_group(group_name)
	var nearest: Node2D = null
	var nearest_dist := detection_radius
	for entity in entities:
		if not is_instance_valid(entity): continue
		if entity.get("is_dead") == true: continue
		var dist := global_position.distance_to(entity.global_position)
		if dist < nearest_dist:
			nearest = entity
			nearest_dist = dist
	return nearest

# Função virtual para ser sobrescrita pelas orbes específicas
func _execute_attack(_target: Node2D) -> void:
	pass

func start_cooldown(time: float) -> void:
	_can_attack = false
	await get_tree().create_timer(time).timeout
	_can_attack = true
