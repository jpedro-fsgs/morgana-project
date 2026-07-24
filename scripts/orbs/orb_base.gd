extends Node2D
class_name OrbBase

@export var detection_radius: float = 380.0
@export var attack_cooldown: float = 1.6
@export var orbit_radius: float = 42.0
@export var orbit_speed: float = 2.2

var orbit_offset: float = 0.0
var _current_angle: float = 0.0
var _can_attack: bool = true

## --- Evolução (pergaminho de evolução, ver ItemManager) ---
const MAX_EVOLUTION_LEVEL: int = 5
const EVOLUTION_FEEDBACK := {
	"speed": "Velocidade ↑",
	"size": "Raio ↑",
	"attack": "Ataque ↑",
}

var speed_level: int = 0
var size_level: int = 0
var attack_level: int = 0

func _ready() -> void:
	var kind := get_kind_id()
	if kind != &"":
		add_to_group(kind)

## Filhos sobrescrevem com um id único (ex: &"orb_blade") pra loja identificar o tipo.
func get_kind_id() -> StringName:
	return &""

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

func total_evolution_level() -> int:
	return speed_level + size_level + attack_level

func is_fully_evolved() -> bool:
	return speed_level >= MAX_EVOLUTION_LEVEL \
		and size_level >= MAX_EVOLUTION_LEVEL \
		and attack_level >= MAX_EVOLUTION_LEVEL

## Chamado pelo pergaminho de evolução: melhora uma das 3 características ao acaso.
func apply_random_evolution() -> void:
	var options := ["speed", "size", "attack"]
	options.shuffle()
	for kind in options:
		if _evolve(kind):
			_show_evolution_feedback(kind)
			_pulse_evolution()
			return

func _evolve(kind: String) -> bool:
	match kind:
		"speed":
			if speed_level >= MAX_EVOLUTION_LEVEL:
				return false
			speed_level += 1
			_on_speed_evolved()
			return true
		"size":
			if size_level >= MAX_EVOLUTION_LEVEL:
				return false
			size_level += 1
			_on_size_evolved()
			return true
		"attack":
			if attack_level >= MAX_EVOLUTION_LEVEL:
				return false
			attack_level += 1
			_on_attack_evolved()
			return true
	return false

## Hooks virtuais — cada orbe sabe como aplicar o próprio bônus.
func _on_speed_evolved() -> void:
	orbit_speed += 0.6

func _on_size_evolved() -> void:
	# Cresce o orbe, mas afasta um pouco a órbita pra continuar cobrindo
	# a Morgana em vez de invadir o corpo dela.
	scale *= 1.12
	orbit_radius += 6.0

func _on_attack_evolved() -> void:
	pass

func _show_evolution_feedback(kind: String) -> void:
	var label := Label.new()
	label.text = EVOLUTION_FEEDBACK.get(kind, "Evoluiu!")
	label.z_index = 100
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 4)

	get_parent().add_child(label)
	label.global_position = global_position + Vector2(-30.0, -50.0)

	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 34.0, 0.9)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.9)
	tween.finished.connect(label.queue_free)

func _pulse_evolution() -> void:
	var orb := get_node_or_null("Orb")
	if orb == null:
		return
	var tween := create_tween()
	tween.tween_property(orb, "modulate", Color(1.8, 1.8, 1.8), 0.1)
	tween.tween_property(orb, "modulate", Color(1, 1, 1), 0.35)
