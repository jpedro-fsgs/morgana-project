extends CharacterBody2D
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const MAX_JUMPS: int = 3
var jump_count: int = 0

var is_attacking: bool = false
var fireball_scene = preload("res://scenes/fireball.tscn")
var facing_right: bool = true
var HP: int = 100

func take_damage(amount: int, source: Node = null) -> void:
	HP -= amount
	print("Player took damage! HP: ", HP)
	
	animation.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	animation.modulate = Color(1, 1, 1)
	
	if HP <= 0:
		die()

func die() -> void:
	print("Player morreu!")
	# Aqui pode entrar animação de morte depois
	queue_free()

func attack() -> void:
	if not is_attacking:
		is_attacking = true
		animation.play("attack2")
		
		# Forçar atualização do RayCast2D
		$RayCast2D.force_raycast_update()
		if $RayCast2D.is_colliding():
			var target = $RayCast2D.get_collider()
			if target != self and target.has_method("take_damage"):
				target.take_damage(20, self)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		jump_count = 0

	# Handle jump.
	if Input.is_action_just_pressed("jump") and jump_count < MAX_JUMPS:
		velocity.y = JUMP_VELOCITY
		jump_count += 1
		
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	move_and_slide()
	
func _process(_delta):
	var direction = velocity.x
	
	if direction > 0:
		facing_right = true
		animation.flip_h = false
		$RayCast2D.target_position.x = 80
	elif direction < 0:
		facing_right = false
		animation.flip_h = true
		$RayCast2D.target_position.x = -80
		
	if is_attacking:
		return
		
	if is_on_floor():
		if direction != 0:
			animation.play("walking2")
		else:
			animation.play("idle2")
	else:
		animation.play("jump")


func _on_animated_sprite_2d_animation_finished() -> void:
	if is_attacking:
		is_attacking = false

func shoot_fireball() -> void:
	var fireball = fireball_scene.instantiate()
	fireball.shooter = self
	fireball.direction = 1 if facing_right else -1
	fireball.global_position = global_position + Vector2(20 * fireball.direction, 0)
	get_parent().add_child(fireball)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		shoot_fireball()
