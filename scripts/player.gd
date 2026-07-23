extends CharacterBody2D

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_box: Area2D = $HurtBox

# --- Movimentação e pulo (mecânica de plataforma, igual ao documento de referência) ---
const SPEED = 300.0
const CROUCH_SPEED = 130.0
const MAX_JUMPS: int = 4
# Cada pulo extra impulsiona um pouco menos, para a maga alcançar a horda de
# morcegos no alto da tela sem jamais encostar na barra de vida (UI) no topo.
const JUMP_VELOCITIES: Array[float] = [-400.0, -380.0, -350.0, -310.0]
var jump_count: int = 0
var is_crouching: bool = false

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
var is_attacking: bool = false
const SWORD_ATTACK_DAMAGE = 100

# Aura Attack Variables
var current_aura_radius: float = 0.0
var current_aura_alpha: float = 0.0
var aura_cooldown_timer: float = 0.0
const AURA_COOLDOWN: float = 1.5
const AURA_MAX_RADIUS: float = 160.0

func _ready() -> void:
	set_collision_mask_value(2, true) # colide com as paredes invisíveis (Layer 2)
	hurt_box.body_entered.connect(_on_hurt_box_body_entered)
	GameManager.game_over.connect(_on_match_ended)
	GameManager.victory.connect(_on_match_ended)
	animation.animation_finished.connect(_on_animated_sprite_2d_animation_finished)
	
	# Transforma o Hitbox retangular antigo numa Área Circular 360
	if has_node("Hitbox/CollisionShape2D"):
		var aura_shape = CircleShape2D.new()
		aura_shape.radius = AURA_MAX_RADIUS
		$Hitbox/CollisionShape2D.shape = aura_shape
		$Hitbox.position = Vector2.ZERO # Centraliza na maga

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

func attack() -> void:
	if not is_attacking and not is_paralyzed and aura_cooldown_timer <= 0.0:
		is_attacking = true
		animation.play("attack2") # Mantém como placeholder
		aura_cooldown_timer = AURA_COOLDOWN
		
		# Efeito Visual 360
		current_aura_radius = 20.0
		current_aura_alpha = 0.6
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "current_aura_radius", AURA_MAX_RADIUS, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "current_aura_alpha", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.finished.connect(func(): current_aura_radius = 0.0)
		
		# Dano aos inimigos ao redor
		get_tree().create_timer(0.05).timeout.connect(func():
			if has_node("Hitbox"):
				var targets = $Hitbox.get_overlapping_bodies()
				for target in targets:
					if target != self and target.has_method("take_damage"):
						target.take_damage(SWORD_ATTACK_DAMAGE, self)
		)

func _on_animated_sprite_2d_animation_finished() -> void:
	if is_attacking:
		is_attacking = false

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

	# Pulo (até 4 pulos - seta ▲ / W - cada um um pouco mais baixo que o anterior
	# para a maga alcançar a horda de morcegos sem tocar a barra de vida no topo)
	if Input.is_action_just_pressed("jump") and jump_count < MAX_JUMPS and not is_crouching:
		velocity.y = JUMP_VELOCITIES[jump_count]
		jump_count += 1

	# Agachar (S / ▼): reduz a velocidade e a hurtbox, útil para passar sob morcegos rasantes
	is_crouching = Input.is_action_pressed("move_down") and is_on_floor() and not is_attacking

	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

	if Input.is_action_just_pressed("shoot") and can_attack:
		shoot_magic()
		_start_attack_cooldown()

	var magic_pressed = Input.is_action_pressed("magic_attack")
	if magic_pressed and can_attack and not _is_charging:
		_is_charging = true
		_charge_time = 0.0
	elif magic_pressed and _is_charging:
		_charge_time += delta
	elif not magic_pressed and _is_charging:
		if _charge_time >= CHARGE_TIME and can_charged_attack:
			shoot_charged_magic()
			_start_charged_cooldown()
		elif can_attack:
			shoot_magic()
			_start_attack_cooldown()
		_is_charging = false
		_charge_time = 0.0

	# Movimento horizontal
	var direction := Input.get_axis("move_left", "move_right")
	var current_speed := CROUCH_SPEED if is_crouching else SPEED

	if direction:
		velocity.x = direction * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)

	move_and_slide()

func _draw() -> void:
	# Desenho da Aura
	if current_aura_radius > 0:
		draw_circle(Vector2.ZERO, current_aura_radius, Color(0.3, 0.8, 1.0, current_aura_alpha))
		draw_arc(Vector2.ZERO, current_aura_radius, 0, TAU, 32, Color(0.8, 0.95, 1.0, current_aura_alpha * 1.5), 2.0)
	
	# Desenho do Cooldown
	if aura_cooldown_timer > 0:
		var progress = 1.0 - (aura_cooldown_timer / AURA_COOLDOWN)
		draw_arc(Vector2(0, 35), 10.0, -PI/2, -PI/2 + (progress * TAU), 16, Color(1.0, 1.0, 1.0, 0.75), 3.0)

func _process(delta: float) -> void:
	if aura_cooldown_timer > 0:
		aura_cooldown_timer -= delta
		queue_redraw()
	if current_aura_radius > 0:
		queue_redraw()

	if velocity.x > 0:
		facing_right = true
		animation.flip_h = false
	elif velocity.x < 0:
		facing_right = false
		animation.flip_h = true

	if is_paralyzed or is_attacking:
		return

	if is_crouching:
		var crouch_anim := "crouching_walk" if velocity.x != 0 else "crouching_idle"
		if animation.sprite_frames and animation.sprite_frames.has_animation(crouch_anim):
			animation.play(crouch_anim)
		else:
			animation.play("idle1") # placeholder até as animações de agachar serem importadas no SpriteFrames
	elif is_on_floor():
		if velocity.x != 0:
			animation.play("walking2")
		else:
			animation.play("idle2")
	else:
		animation.play("jump")
