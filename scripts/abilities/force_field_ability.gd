extends PlayerAbility
class_name ForceFieldAbility

const MAX_LEVEL: int = 5
const RADIUS_STEP: float = 20.0
const DAMAGE_STEP: int = 15
const BASE_RADIUS: float = 120.0
const BASE_DAMAGE: int = 60
const TRIGGER_COOLDOWN: float = 3.0

var auto_trigger: bool = false
var radius_level: int = 0
var damage_level: int = 0

var radius: float = BASE_RADIUS
var damage: int = BASE_DAMAGE

var _player: Node2D
var _can_trigger: bool = true
var _visual: AuraVisualizer

func _ready() -> void:
	_player = get_parent()
	_visual = AuraVisualizer.new()
	_player.add_child(_visual)

func _process(_delta: float) -> void:
	if not unlocked or not GameManager.is_game_active:
		return
	if not _can_trigger:
		return
	if auto_trigger:
		_trigger()
	elif Input.is_action_just_pressed("magic_attack"):
		_trigger()

func total_evolution_level() -> int:
	return int(auto_trigger) + radius_level + damage_level

func is_fully_evolved() -> bool:
	return auto_trigger and radius_level >= MAX_LEVEL and damage_level >= MAX_LEVEL

func apply_random_evolution() -> void:
	var options: Array[String] = []
	if not auto_trigger:
		options.append("auto_trigger")
	if radius_level < MAX_LEVEL:
		options.append("radius")
	if damage_level < MAX_LEVEL:
		options.append("damage")
	if options.is_empty():
		return

	options.shuffle()
	match options[0]:
		"auto_trigger":
			auto_trigger = true
		"radius":
			radius_level += 1
			radius += RADIUS_STEP
		"damage":
			damage_level += 1
			damage += DAMAGE_STEP

func _trigger() -> void:
	_can_trigger = false
	# TODO: trocar por um sprite/animação de anel próprios quando existirem.
	_visual.play_explosion(radius)
	for target in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(target):
			continue
		if target.get("is_dead") == true:
			continue
		if _player.global_position.distance_to(target.global_position) <= radius:
			target.take_damage(damage, _player)
	get_tree().create_timer(TRIGGER_COOLDOWN).timeout.connect(func():
		_can_trigger = true
	)
