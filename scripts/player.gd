extends CharacterBody2D

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_box: Area2D = $HurtBox

# --- Movimentação e pulo (mecânica de plataforma, igual ao documento de referência) ---
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const MAX_JUMPS: int = 3
var jump_count: int = 0

const ATTACK_COOLDOWN = 0.35
const MAGIC_DAMAGE = 25
const PARALYSIS_TIME = 1.1 # reduzido de 2.0 para o jogador ficar preso por menos tempo

# Ataque carregado: segurar a tecla A por 1s dispara um raio perfurante (atinge vários morcegos)
const CHARGE_TIME = 1.0
const CHARGED_DAMAGE = 40
const CHARGED_COOLDOWN = 2.0

var fireball_scene = preload("res://scenes/fireball.tscn")
var facing_right: bool = true
var can_attack: bool = true
var is_paralyzed: bool = false

var _is_charging: bool = false
var _charge_time: float = 0.0
var can_charged_attack: bool = true

func _ready() -> void:
	set_collision_mask_value(2, true) # colide com as paredes invisíveis (Layer 2)
	hurt_box.body_entered.connect(_on_hurt_box_body_entered)
	GameManager.game_over.connect(_on_match_ended)
	GameManager.victory.connect(_on_match_ended)

func take_damage(amount: int, source: Node = null) -> void:
	# Reservado para uma futura vida da própria maga, se o jogo evoluir para isso.
	pass

func _on_match_ended() -> void:
	is_paralyzed = true

func _on_hurt_box_body_entered(body: Node) -> void:
	if is_paralyzed or not GameManager.is_game_active:
		return
	if body.is_in_group("bats"):
		_paralyze()

func _paralyze() -> void:
	is_paralyzed = true
	animation.modulate = Color(0.55, 0.55, 1.0)
	_shake_camera()
	# TODO: tocar um som agudo aqui assim que houver um asset de áudio no projeto

	await get_tree().create_timer(PARALYSIS_TIME).timeout

	is_paralyzed = false
	animation.modulate = Color(1, 1, 1)

func _shake_camera() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var original_offset: Vector2 = camera.offset
	var tween := create_tween()
	for i in range(6):
		var shake_offset = Vector2(randf_range(-8, 8), randf_range(-8, 8))
		tween.tween_property(camera, "offset", shake_offset, 0.04)
	tween.tween_property(camera, "offset", original_offset, 0.04)

func _aim_direction() -> Vector2:
	# Mira pela direção que a maga está encarando (controle todo pelo teclado)
	return Vector2.RIGHT if facing_right else Vector2.LEFT

func shoot_magic() -> void:
	var fireball = fireball_scene.instantiate()
	fireball.shooter = self
	fireball.damage = MAGIC_DAMAGE
	fireball.direction = _aim_direction()
	fireball.global_position = global_position + fireball.direction * 24.0
	get_parent().add_child(fireball)

func shoot_charged_magic() -> void:
	# Raio perfurante: atinge vários morcegos em linha, dano maior
	var beam = fireball_scene.instantiate()
	beam.pierce = true
	beam.shooter = self
	beam.damage = CHARGED_DAMAGE
	beam.direction = _aim_direction()
	beam.global_position = global_position + beam.direction * 24.0
	get_parent().add_child(beam)

func _start_attack_cooldown() -> void:
	can_attack = false
	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	can_attack = true

func _start_charged_cooldown() -> void:
	can_charged_attack = false
	await get_tree().create_timer(CHARGED_COOLDOWN).timeout
	can_charged_attack = true

func _physics_process(delta: float) -> void:
	if not GameManager.is_game_active:
		return

	# Gravidade (igual ao documento de referência)
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		jump_count = 0

	if is_paralyzed:
		velocity.x = 0
		move_and_slide()
		_is_charging = false
		_charge_time = 0.0
		return

	# Pulo (até 3 pulos, igual ao documento de referência)
	if Input.is_action_just_pressed("jump") and jump_count < MAX_JUMPS:
		velocity.y = JUMP_VELOCITY
		jump_count += 1

	# Segurar a tecla A (ação "attack") carrega o raio perfurante; soltar rápido dispara o tiro normal
	if Input.is_action_just_pressed("attack") and can_attack:
		_is_charging = true
		_charge_time = 0.0
	elif Input.is_action_pressed("attack") and _is_charging:
		_charge_time += delta
	elif Input.is_action_just_released("attack") and _is_charging:
		if _charge_time >= CHARGE_TIME and can_charged_attack:
			shoot_charged_magic()
			_start_charged_cooldown()
		elif can_attack:
			shoot_magic()
			_start_attack_cooldown()
		_is_charging = false
		_charge_time = 0.0

	# Movimento horizontal (igual ao documento de referência)
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _process(_delta: float) -> void:
	if velocity.x > 0:
		facing_right = true
		animation.flip_h = false
	elif velocity.x < 0:
		facing_right = false
		animation.flip_h = true

	if is_paralyzed:
		return

	if is_on_floor():
		if velocity.x != 0:
			animation.play("walking2")
		else:
			animation.play("idle2")
	else:
		animation.play("jump")
