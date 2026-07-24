extends Area2D

var direction: Vector2 = Vector2.RIGHT  # direção normalizada (agora mira em qualquer ângulo, não só esquerda/direita)
var speed: float = 500.0
var shooter: Node = null
var damage: int = 25
var pierce: bool = false          # true = raio carregado, atravessa vários morcegos
var explosive: bool = false       # true = explode em área ao acertar, em vez de só atravessar/parar
var explosion_radius: float = 70.0

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
		if explosive:
			_explode()
			return
		if not pierce:
			queue_free()

func _explode() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy in _hit_bodies or not is_instance_valid(enemy):
			continue
		if enemy.get("is_dead") == true:
			continue
		if global_position.distance_to(enemy.global_position) <= explosion_radius:
			enemy.take_damage(damage, shooter)
			_hit_bodies.append(enemy)
	_spawn_explosion_visual()
	queue_free()

func _spawn_explosion_visual() -> void:
	var particles := CPUParticles2D.new()
	get_parent().add_child(particles)
	particles.global_position = global_position
	particles.amount = 20
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 180.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color(1.0, 0.5, 0.1, 0.9)
	particles.emitting = true
	get_tree().create_timer(particles.lifetime + 0.2).timeout.connect(particles.queue_free)
