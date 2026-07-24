extends OrbBase
class_name OrbCombo

var fireball_scene := preload("res://scenes/fireball.tscn")
var damage_amount: int = 15
var _pierce: bool = false
var _player: Node2D

const SIZE_MULT: float = 0.5

# Bônus de evolução — somados por cima do tier de combo, já que _apply_tier()
# reatribui damage_amount/orbit_speed/scale toda vez que o combo muda.
var _evo_damage_bonus: int = 0
var _evo_speed_bonus: float = 0.0
var _evo_scale_mult: float = 1.0

const EVO_DAMAGE_STEP: int = 4
const EVO_SPEED_STEP: float = 0.6
const EVO_SCALE_STEP: float = 0.12

const POWER_TIERS := [
	{"mult": 10, "damage": 45, "cooldown": 0.55, "radius": 520.0, "orbit_speed": 4.2, "pierce": true, "visual_scale": 1.6, "color": Color(1.0, 0.85, 0.3)},
	{"mult": 8, "damage": 36, "cooldown": 0.7, "radius": 480.0, "orbit_speed": 3.6, "pierce": true, "visual_scale": 1.45, "color": Color(1.0, 0.55, 0.85)},
	{"mult": 5, "damage": 28, "cooldown": 0.9, "radius": 450.0, "orbit_speed": 3.0, "pierce": false, "visual_scale": 1.3, "color": Color(0.75, 0.6, 1.0)},
	{"mult": 3, "damage": 22, "cooldown": 1.15, "radius": 420.0, "orbit_speed": 2.6, "pierce": false, "visual_scale": 1.15, "color": Color(0.55, 0.85, 1.0)},
	{"mult": 2, "damage": 18, "cooldown": 1.35, "radius": 400.0, "orbit_speed": 2.4, "pierce": false, "visual_scale": 1.05, "color": Color(0.6, 0.9, 1.0)},
	{"mult": 1, "damage": 15, "cooldown": 1.6, "radius": 380.0, "orbit_speed": 2.2, "pierce": false, "visual_scale": 1.0, "color": Color(0.75, 0.9, 1.0)},
]

func _ready() -> void:
	super._ready()
	# O Player agora é o "avô" (AIFamiliar -> OrbManager -> Player)
	_player = get_parent().get_parent()
	add_to_group("ai_familiar")
	GameManager.combo_changed.connect(_on_combo_changed)
	_apply_tier(_tier_for_multiplier(GameManager.combo_multiplier))

func get_kind_id() -> StringName:
	return &"orb_combo"

func _on_speed_evolved() -> void:
	_evo_speed_bonus += EVO_SPEED_STEP
	_apply_tier(_tier_for_multiplier(GameManager.combo_multiplier))

func _on_size_evolved() -> void:
	_evo_scale_mult *= 1.0 + EVO_SCALE_STEP
	orbit_radius += 6.0
	_apply_tier(_tier_for_multiplier(GameManager.combo_multiplier))

func _on_attack_evolved() -> void:
	_evo_damage_bonus += EVO_DAMAGE_STEP
	_apply_tier(_tier_for_multiplier(GameManager.combo_multiplier))

func _on_combo_changed(multiplier: int, _streak: int) -> void:
	_apply_tier(_tier_for_multiplier(multiplier))

func _tier_for_multiplier(multiplier: int) -> Dictionary:
	for tier in POWER_TIERS:
		if multiplier >= tier.mult:
			return tier
	return POWER_TIERS[POWER_TIERS.size() - 1]

func _apply_tier(tier: Dictionary) -> void:
	damage_amount = tier.damage
	attack_cooldown = tier.cooldown
	detection_radius = tier.radius
	orbit_speed = tier.orbit_speed
	_pierce = tier.pierce
	_update_visual(tier.color, tier.visual_scale)

func _update_visual(color: Color, visual_scale: float) -> void:
	var orb := get_node_or_null("Orb")
	var glow := get_node_or_null("Glow")
	if orb:
		orb.color = color
	if glow:
		glow.color = Color(color.r, color.g, color.b, 0.28)

	var final_scale := visual_scale * SIZE_MULT
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(final_scale, final_scale), 0.35)

func _find_target() -> Node2D:
	# Como essa é uma orbe de combate padrão, ela busca o morcego mais perto
	return get_nearest_entity_in_radius("enemies")

func _execute_attack(target: Node2D) -> void:
	var direction := (target.global_position - global_position).normalized()
	var bolt := fireball_scene.instantiate()
	bolt.shooter = _player
	bolt.damage = damage_amount
	bolt.pierce = _pierce
	bolt.direction = direction
	bolt.global_position = global_position
	# Adiciona o raio no Level (avô do Player)
	_player.get_parent().add_child(bolt)

	_flash()
	start_cooldown(attack_cooldown)

func _flash() -> void:
	var orb := get_node_or_null("Orb")
	if orb == null:
		return
	var tween := create_tween()
	tween.tween_property(orb, "scale", Vector2(1.6, 1.6), 0.08)
	tween.tween_property(orb, "scale", Vector2(1.0, 1.0), 0.16)
