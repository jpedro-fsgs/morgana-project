extends CharacterBody2D
class_name EnemyBase

## --- Configuração base (pode ser sobrescrita por filhos ou via @export) ---
@export var max_hp: int = 25
@export var move_speed: float = 110.0
@export var village_damage: float = 1.0
@export var defeat_score: int = 10
@export var defeat_heal: float = 0.0  # cura à vila ao morrer (ex: giant = 2.0)
@export var coin_count: int = 3
@export var coin_scene: PackedScene = preload("res://scenes/coins/coin_silver.tscn")

const GATE_X: float = 200.0

var hp: int
var is_dead: bool = false

@onready var _animation: AnimatedSprite2D = $Animation
@onready var _collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	GameManager.victory.connect(_on_victory)
	_enemy_ready()  # hook para filhos

	var mult = GameManager.wave_difficulty_multiplier
	max_hp = int(max_hp * mult)
	hp = max_hp
	move_speed = move_speed * mult
	defeat_score = int(defeat_score * mult)

## Hook virtual — filhos sobrescrevem para inicialização extra
func _enemy_ready() -> void:
	pass

func take_damage(amount: int, source: Node = null) -> void:
	if is_dead:
		return
	hp -= amount
	if hp > 0:
		_flash_hurt()
		return
	die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	_collision.set_deferred("disabled", true)
	GameManager.register_enemy_defeated(defeat_score)
	if defeat_heal > 0:
		GameManager.heal_village(defeat_heal)
	_spawn_coins()
	_dissolve_into_smoke()

func _spawn_coins() -> void:
	for i in range(coin_count):
		var particle := coin_scene.instantiate()
		get_parent().add_child(particle)
		particle.global_position = global_position + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))

func _reach_village() -> void:
	GameManager.damage_village(village_damage)
	queue_free()

func _on_victory() -> void:
	if is_dead:
		return
	is_dead = true
	queue_free()

func _physics_process(_delta: float) -> void:
	if is_dead or not GameManager.is_game_active:
		return
	velocity = _get_movement_velocity()
	move_and_slide()
	if global_position.x <= GATE_X:
		_reach_village()

## Virtual — filhos podem sobrescrever para pathfinding, voo etc.
func _get_movement_velocity() -> Vector2:
	return Vector2(-move_speed * GameManager.speed_multiplier, 0)

func _flash_hurt() -> void:
	_animation.modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(0.08).timeout
	if not is_dead:
		_animation.modulate = Color(1, 1, 1)

func _dissolve_into_smoke() -> void:
	# (mesma lógica de partículas do bat.gd atual, movida para cá)
	var particles := CPUParticles2D.new()
	get_parent().add_child(particles)
	particles.global_position = global_position
	particles.amount = 14
	particles.lifetime = 0.6
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2(0, -25)
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 55.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color(0.55, 0.55, 0.55, 0.85)
	particles.emitting = true
	get_tree().create_timer(particles.lifetime + 0.2).timeout.connect(particles.queue_free)

	var tween := create_tween()
	tween.tween_property(_animation, "modulate", Color(0.6, 0.6, 0.6, 0.0), 0.35)
	tween.parallel().tween_property(_animation, "scale", _animation.scale * 1.3, 0.35)
	await tween.finished
	queue_free()
