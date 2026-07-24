extends OrbBase
class_name OrbBlade

@export var damage_amount: int = 8
@export var contact_radius: float = 90.0
@export var hit_cooldown: float = 0.35

const ATTACK_STEP: int = 4
const CONTACT_RADIUS_STEP: float = 10.0

func _ready() -> void:
	super._ready()
	detection_radius = contact_radius
	attack_cooldown = hit_cooldown

func get_kind_id() -> StringName:
	return &"orb_blade"

func _on_size_evolved() -> void:
	super._on_size_evolved()
	contact_radius += CONTACT_RADIUS_STEP
	detection_radius = contact_radius

func _on_attack_evolved() -> void:
	damage_amount += ATTACK_STEP

func _find_target() -> Node2D:
	# Lâmina giratória: só "acha" alvo quando ele já está encostando na órbita
	return get_nearest_entity_in_radius("enemies")

func _execute_attack(target: Node2D) -> void:
	target.take_damage(damage_amount, self)
	_flash()
	start_cooldown(attack_cooldown)

func _flash() -> void:
	var orb := get_node_or_null("Orb")
	if orb == null:
		return
	var tween := create_tween()
	tween.tween_property(orb, "scale", Vector2(1.4, 1.4), 0.06)
	tween.tween_property(orb, "scale", Vector2(1.0, 1.0), 0.12)
