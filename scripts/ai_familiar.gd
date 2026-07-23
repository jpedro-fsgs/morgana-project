extends Node2D
class_name AIFamiliar

## Familiar Mágico: um pequeno aliado com IA simples que orbita a jogadora e
## ataca automaticamente o morcego mais próximo dentro do raio de detecção.
## Serve como assistência automática para facilitar a defesa da vila.

@export var detection_radius: float = 380.0
@export var attack_cooldown: float = 1.6
@export var damage: int = 15
@export var orbit_radius: float = 42.0
@export var orbit_speed: float = 2.2

var fireball_scene := preload("res://scenes/fireball.tscn")

var _player: Node2D
var _can_attack: bool = true
var _orbit_angle: float = randf() * TAU
var _pierce: bool = false

# --- Dificuldade adaptativa: o familiar fica mais forte junto com o combo da jogadora. ---
# Os limiares de "mult" espelham os multiplicadores de combo do GameManager (×1 a ×10).
const POWER_TIERS := [
	{"mult": 10, "damage": 45, "cooldown": 0.55, "radius": 520.0, "orbit_speed": 4.2, "pierce": true, "visual_scale": 2.0, "color": Color(1.0, 0.85, 0.3)},
	{"mult": 8, "damage": 36, "cooldown": 0.7, "radius": 480.0, "orbit_speed": 3.6, "pierce": true, "visual_scale": 1.7, "color": Color(1.0, 0.55, 0.85)},
	{"mult": 5, "damage": 28, "cooldown": 0.9, "radius": 450.0, "orbit_speed": 3.0, "pierce": false, "visual_scale": 1.45, "color": Color(0.75, 0.6, 1.0)},
	{"mult": 3, "damage": 22, "cooldown": 1.15, "radius": 420.0, "orbit_speed": 2.6, "pierce": false, "visual_scale": 1.25, "color": Color(0.55, 0.85, 1.0)},
	{"mult": 2, "damage": 18, "cooldown": 1.35, "radius": 400.0, "orbit_speed": 2.4, "pierce": false, "visual_scale": 1.1, "color": Color(0.6, 0.9, 1.0)},
	{"mult": 1, "damage": 15, "cooldown": 1.6, "radius": 380.0, "orbit_speed": 2.2, "pierce": false, "visual_scale": 1.0, "color": Color(0.75, 0.9, 1.0)},
]

func _ready() -> void:
	_player = get_parent()
	add_to_group("ai_familiar")
	GameManager.combo_changed.connect(_on_combo_changed)
	_apply_tier(_tier_for_multiplier(GameManager.combo_multiplier))

func _on_combo_changed(multiplier: int, _streak: int) -> void:
	_apply_tier(_tier_for_multiplier(multiplier))

func _tier_for_multiplier(multiplier: int) -> Dictionary:
	for tier in POWER_TIERS:
		if multiplier >= tier.mult:
			return tier
	return POWER_TIERS[POWER_TIERS.size() - 1]

func _apply_tier(tier: Dictionary) -> void:
	damage = tier.damage
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

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(visual_scale, visual_scale), 0.35)

func _process(delta: float) -> void:
	_orbit_angle += orbit_speed * delta
	position = Vector2(cos(_orbit_angle) * orbit_radius, sin(_orbit_angle) * orbit_radius * 0.5 - 55.0)

	if not GameManager.is_game_active:
		return

	if _can_attack:
		var target := _find_nearest_bat()
		if target:
			_attack(target)

func _find_nearest_bat() -> Node2D:
	var bats := get_tree().get_nodes_in_group("bats")
	var nearest: Node2D = null
	var nearest_dist := detection_radius
	for bat in bats:
		if not is_instance_valid(bat):
			continue
		if bat.get("is_dead") == true:
			continue
		var dist := global_position.distance_to(bat.global_position)
		if dist < nearest_dist:
			nearest = bat
			nearest_dist = dist
	return nearest

func _attack(target: Node2D) -> void:
	_can_attack = false

	var direction := (target.global_position - global_position).normalized()
	var bolt := fireball_scene.instantiate()
	bolt.shooter = _player
	bolt.damage = damage
	bolt.pierce = _pierce
	bolt.direction = direction
	bolt.global_position = global_position
	_player.get_parent().add_child(bolt)

	_flash()

	await get_tree().create_timer(attack_cooldown).timeout
	_can_attack = true

func _flash() -> void:
	var orb := get_node_or_null("Orb")
	if orb == null:
		return
	var tween := create_tween()
	tween.tween_property(orb, "scale", Vector2(1.6, 1.6), 0.08)
	tween.tween_property(orb, "scale", Vector2(1.0, 1.0), 0.16)
