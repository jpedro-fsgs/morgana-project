extends CharacterBody2D

@onready var animation: AnimatedSprite2D = $Animation
@onready var collision: CollisionShape2D = $CollisionShape2D

const LEFT_DESPAWN_X: float = 130.0  # posição x onde o morcego "entra na vila"

# --- Tipos de morcego (documento de design): comum 70%, rápido 20%, gigante 10% ---
const TYPE_CONFIG := {
	"common": {"hp": 25, "speed": 110.0, "damage_hits": 1.0, "scale_mult": 1.0, "tint": Color(1, 1, 1)},
	"fast": {"hp": 25, "speed": 220.0, "damage_hits": 1.0, "scale_mult": 0.8, "tint": Color(1, 0.95, 0.6)},
	"giant": {"hp": 50, "speed": 65.0, "damage_hits": 2.0, "scale_mult": 1.6, "tint": Color(0.75, 0.6, 1.0)},
}

var bat_type: String = "common"
var SPEED: float = 110.0
var damage_hits: float = 1.0
var HP: int = 25                  # morre com 1 raio de magia (25 de dano) no tipo comum
var is_dead: bool = false

# Chamado pelo spawner ANTES de add_child, para configurar o tipo do morcego
func setup(type: String) -> void:
	bat_type = type

func _ready() -> void:
	add_to_group("bats")
	var config: Dictionary = TYPE_CONFIG.get(bat_type, TYPE_CONFIG["common"])
	SPEED = config.speed
	HP = config.hp
	damage_hits = config.damage_hits
	animation.scale *= config.scale_mult
	animation.modulate = config.tint
	animation.play("fly")
	GameManager.victory.connect(_on_victory)

func take_damage(amount: int, source: Node = null) -> void:
	if is_dead:
		return
	HP -= amount

	if HP > 0:
		animation.modulate = Color(1, 0.4, 0.4)
		await get_tree().create_timer(0.08).timeout
		if not is_dead:
			animation.modulate = Color(1, 1, 1)
		return

	die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	collision.set_deferred("disabled", true)
	GameManager.register_bat_defeated(bat_type)
	_dissolve_into_smoke()

func _dissolve_into_smoke() -> void:
	# Estouro de partículas cinza simulando fumaça.
	# Colocamos as partículas no nível (não no morcego), assim a nuvem termina de se
	# desfazer sozinha, mesmo depois que o morcego já tiver sumido da cena.
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
	tween.tween_property(animation, "modulate", Color(0.6, 0.6, 0.6, 0.0), 0.35)
	tween.parallel().tween_property(animation, "scale", animation.scale * 1.3, 0.35)
	await tween.finished
	queue_free()

func _reach_village() -> void:
	# Não foi atingido a tempo: entra na vila, causa dano (gigante causa o dobro) e desaparece intacto
	GameManager.damage_village(damage_hits)
	queue_free()

func _on_victory() -> void:
	# "Quando o primeiro raio de luz aparecer... os morcegos desaparecerão."
	if is_dead:
		return
	is_dead = true
	queue_free()

func _physics_process(_delta: float) -> void:
	if is_dead or not GameManager.is_game_active:
		return

	# IA simples do documento: vai sempre em linha reta, da direita para a esquerda
	# A velocidade é escalada pelo multiplicador de dificuldade do GameManager
	velocity = Vector2(-SPEED * GameManager.speed_multiplier, 0)
	move_and_slide()

	if global_position.x <= LEFT_DESPAWN_X:
		_reach_village()
