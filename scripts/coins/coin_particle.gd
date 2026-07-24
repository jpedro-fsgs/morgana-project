extends CharacterBody2D
class_name CoinParticle

@export var coin_value: int = 10
const GRAVITY: float = 900.0
const GROUND_FRICTION: float = 400.0
const BOUNCE_DAMPING: float = 0.35
const MIN_BOUNCE_SPEED: float = 40.0

const ATTRACT_DELAY: float = 0.25
const ATTRACT_SPEED: float = 260.0
const ATTRACT_ACCEL: float = 700.0
const PICKUP_DISTANCE: float = 18.0

const LIFETIME: float = 12.0

@onready var pickup_area: Area2D = $PickupArea

var _time: float = 0.0
var _attract_speed: float = 0.0

func _ready() -> void:
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	get_tree().create_timer(LIFETIME).timeout.connect(func():
		if is_instance_valid(self):
			queue_free()
	)
	# Impulso inicial pra cima e pro lado, como uma moeda pulando ao cair no chão
	var spread := deg_to_rad(50.0)
	var angle := -PI / 2.0 + randf_range(-spread, spread)
	var speed := randf_range(90.0, 160.0)
	velocity = Vector2(cos(angle), sin(angle)) * speed

func _physics_process(delta: float) -> void:
	_time += delta

	if GameManager.coin_magnet_enabled and _attract_to_player(delta):
		return

	_fall_with_weight(delta)

func _fall_with_weight(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		if velocity.y > MIN_BOUNCE_SPEED:
			velocity.y *= -BOUNCE_DAMPING
		else:
			velocity.y = 0.0
		velocity.x = move_toward(velocity.x, 0.0, GROUND_FRICTION * delta)
	move_and_slide()

func _attract_to_player(delta: float) -> bool:
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if not player or not is_instance_valid(player):
		return false
	if _time < ATTRACT_DELAY:
		return false

	_attract_speed = min(_attract_speed + ATTRACT_ACCEL * delta, ATTRACT_SPEED)
	var direction := (player.global_position - global_position).normalized()
	velocity = velocity.move_toward(direction * _attract_speed, ATTRACT_ACCEL * delta)
	move_and_slide()

	if global_position.distance_to(player.global_position) <= PICKUP_DISTANCE:
		_collect()
	return true

func _on_pickup_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_collect()

func _collect() -> void:
	GameManager.add_money(coin_value)
	queue_free()
