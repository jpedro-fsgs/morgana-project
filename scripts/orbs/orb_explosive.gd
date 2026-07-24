extends OrbBase
class_name OrbExplosive

@export var damage_amount: int = 20
@export var explosion_radius: float = 70.0

const ATTACK_STEP: int = 5
const EXPLOSION_RADIUS_STEP: float = 8.0

var projectile_scene := preload("res://scenes/orbs/bomb_projectile.tscn")
var _player: Node2D

func _ready() -> void:
	super._ready()
	# O Player é o "avô" (OrbExplosive -> OrbManager -> Player), igual ao OrbCombo
	_player = get_parent().get_parent()
	attack_cooldown = 2.0

func get_kind_id() -> StringName:
	return &"orb_explosive"

func _on_size_evolved() -> void:
	super._on_size_evolved()
	explosion_radius += EXPLOSION_RADIUS_STEP

func _on_attack_evolved() -> void:
	damage_amount += ATTACK_STEP

func _find_target() -> Node2D:
	return get_nearest_entity_in_radius("enemies")

func _execute_attack(target: Node2D) -> void:
	var direction := (target.global_position - global_position).normalized()
	var bolt := projectile_scene.instantiate()
	bolt.shooter = _player
	bolt.damage = damage_amount
	bolt.explosive = true
	bolt.explosion_radius = explosion_radius
	bolt.direction = direction
	bolt.global_position = global_position
	_player.get_parent().add_child(bolt)

	_flash()
	start_cooldown(attack_cooldown)

func _flash() -> void:
	var orb := get_node_or_null("Orb")
	if orb == null:
		return
	var tween := create_tween()
	tween.tween_property(orb, "scale", Vector2(1.5, 1.5), 0.08)
	tween.tween_property(orb, "scale", Vector2(1.0, 1.0), 0.16)
