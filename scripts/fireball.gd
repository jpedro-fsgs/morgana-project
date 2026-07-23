extends Area2D

var direction: Vector2 = Vector2.RIGHT  # direção normalizada (agora mira em qualquer ângulo, não só esquerda/direita)
var speed: float = 500.0
var shooter: Node = null
var damage: int = 25
var pierce: bool = false          # true = raio carregado, atravessa vários morcegos

var _traveled: float = 0.0
var _hit_bodies: Array = []
const MAX_RANGE: float = 1500.0

func _ready():
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	if pierce:
		scale *= 1.5

func _process(delta: float) -> void:
	var step = direction * speed * delta
	position += step
	_traveled += step.length()

	if _traveled > MAX_RANGE:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == shooter or body in _hit_bodies:
		return

	if body.has_method("take_damage"):
		body.take_damage(damage, shooter)
		_hit_bodies.append(body)
		if not pierce:
			queue_free()
