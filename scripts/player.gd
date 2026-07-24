extends CharacterBody2D
class_name Player

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_box: Area2D = $HurtBox

# --- Movimentação e pulo (mecânica de plataforma, igual ao documento de referência) ---
const SPEED = 300.0
const MAX_JUMPS: int = 4
# Cada pulo extra impulsiona um pouco menos, para a maga alcançar a horda de
# morcegos no alto da tela sem jamais encostar na barra de vida (UI) no topo.
const JUMP_VELOCITIES: Array[float] = [-400.0, -380.0, -350.0, -310.0]
var jump_count: int = 0

# --- Sistema de Magia e Base de Tempo ---
var base_magic_cooldown: float = 1.0 # Tempo base. Alterar isso acelera/desacelera TODAS as magias

const MAGIC_COOLDOWN_MULT: float = 0.35
const MAGIC_DAMAGE = 25
const PARALYSIS_TIME = 0.5 # reduzido de 2.0 para o jogador ficar preso por menos tempo

var fireball_scene = preload("res://scenes/fireball.tscn")
var facing_right: bool = true
var is_paralyzed: bool = false
var is_attacking: bool = false

# Aura Attack Variables
const AURA_DAMAGE = 100
const AURA_COOLDOWN_MULT: float = 0.75
const AURA_MAX_RADIUS: float = 160.0

# Global Magic Cooldown System
var global_cooldown_timer: float = 0.0
var global_cooldown_max: float = 1.0

var cooldown_visualizer: CooldownVisualizer
var aura_visualizer: AuraVisualizer

var wand_ability: WandAbility
var force_field_ability: ForceFieldAbility

func start_global_cooldown(duration: float) -> void:
	global_cooldown_timer = duration
	global_cooldown_max = duration
	if cooldown_visualizer:
		cooldown_visualizer.update_cooldown(1.0 - (global_cooldown_timer / global_cooldown_max))

func is_global_cooldown_ready() -> bool:
	return global_cooldown_timer <= 0.0

func _ready() -> void:
	add_to_group("player")
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

	cooldown_visualizer = CooldownVisualizer.new()
	add_child(cooldown_visualizer)
	cooldown_visualizer.initialize(animation)

	aura_visualizer = AuraVisualizer.new()
	add_child(aura_visualizer)

	wand_ability = WandAbility.new()
	add_child(wand_ability)

	force_field_ability = ForceFieldAbility.new()
	add_child(force_field_ability)

## Itens já comprados que o pergaminho de evolução pode melhorar.
func get_evolvable_abilities() -> Array:
	var abilities: Array = []
	if wand_ability.unlocked:
		abilities.append(wand_ability)
	if force_field_ability.unlocked:
		abilities.append(force_field_ability)
	return abilities

func take_damage(amount: int, source: Node = null) -> void:
	# Reservado para uma futura vida da própria maga, se o jogo evoluir para isso.
	pass

func _on_match_ended() -> void:
	is_paralyzed = true

func _on_hurt_box_body_entered(body: Node) -> void:
	if is_paralyzed or not GameManager.is_game_active:
		return
	if body.is_in_group("enemies"):
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
	if wand_ability.auto_aim:
		var target := _find_nearest_enemy()
		if target:
			return (target.global_position - global_position).normalized()
	return (get_global_mouse_position() - global_position).normalized()

func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.get("is_dead") == true:
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest = enemy
			nearest_dist = dist
	return nearest

## Reservado: hoje não tem gatilho nenhum. Vai virar um item separado de
## "campo de força" mais pra frente — por ora fica só a função guardada.
func aura_attack() -> void:
	if not is_attacking and not is_paralyzed and is_global_cooldown_ready():
		is_attacking = true
		animation.play("morgana_attack") # Mantém como placeholder
		start_global_cooldown(AURA_COOLDOWN_MULT * base_magic_cooldown)
		
		# Efeito Visual 360
		if aura_visualizer:
			aura_visualizer.play_explosion(AURA_MAX_RADIUS)
		
		# Dano aos inimigos ao redor
		get_tree().create_timer(0.05).timeout.connect(func():
			if has_node("Hitbox"):
				var targets = $Hitbox.get_overlapping_bodies()
				for target in targets:
					if target != self and target.has_method("take_damage"):
						target.take_damage(AURA_DAMAGE, self)
		)

func _on_animated_sprite_2d_animation_finished() -> void:
	if is_attacking:
		is_attacking = false

func shoot_magic() -> void:
	is_attacking = true
	animation.play("morgana_attack_2")
	start_global_cooldown(MAGIC_COOLDOWN_MULT * base_magic_cooldown)
	var fireball = fireball_scene.instantiate()
	fireball.shooter = self
	fireball.damage = MAGIC_DAMAGE + wand_ability.damage_bonus
	fireball.speed += wand_ability.speed_bonus
	fireball.direction = _aim_direction()
	fireball.global_position = global_position + fireball.direction * 24.0
	get_parent().add_child(fireball)

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
		return

	# Pulo (até 4 pulos - seta ▲ / W - cada um um pouco mais baixo que o anterior
	# para a maga alcançar a horda de morcegos sem tocar a barra de vida no topo)
	if Input.is_action_just_pressed("jump") and jump_count < MAX_JUMPS:
		velocity.y = JUMP_VELOCITIES[jump_count]
		jump_count += 1

	# Tiro mágico acompanha o mouse e dispara com o clique — segurar o botão
	# mantém o disparo. Com a Varinha evoluída, atira sozinho sem precisar clicar.
	if (wand_ability.auto_fire or Input.is_action_pressed("attack")) and is_global_cooldown_ready():
		shoot_magic()

	# "shoot" (espaço/X) fica sem função por enquanto.

	# Movimento horizontal
	var direction := Input.get_axis("move_left", "move_right")

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func _process(delta: float) -> void:
	if global_cooldown_timer > 0:
		global_cooldown_timer -= delta
		
		if cooldown_visualizer and global_cooldown_max > 0:
			var progress = 1.0 - (global_cooldown_timer / global_cooldown_max)
			cooldown_visualizer.update_cooldown(progress)
			
		if global_cooldown_timer <= 0:
			if cooldown_visualizer:
				cooldown_visualizer.play_twinkle()

	if velocity.x > 0:
		facing_right = true
		animation.flip_h = false
	elif velocity.x < 0:
		facing_right = false
		animation.flip_h = true

	if is_paralyzed or is_attacking:
		return

	if is_on_floor():
		if velocity.x != 0:
			animation.play("morgana_walking2")
		else:
			animation.play("morgana_idle")
	else:
		animation.play("morgana_jump")
