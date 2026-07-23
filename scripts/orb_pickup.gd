extends Area2D
class_name OrbPickup

const FLOAT_AMPLITUDE: float = 8.0
const FLOAT_SPEED: float = 2.5

var _base_y: float
var _time: float = 0.0
var orb_scene: PackedScene = preload("res://scenes/ai_familiar.tscn")

func _ready() -> void:
	_base_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_time += delta
	position.y = _base_y + sin(_time * FLOAT_SPEED) * FLOAT_AMPLITUDE

func _on_body_entered(body: Node) -> void:
	if body.has_node("OrbManager"):
		var orb_manager: OrbManager = body.get_node("OrbManager")
		var orb = orb_scene.instantiate()
		orb_manager.add_orb(orb)
		queue_free()
