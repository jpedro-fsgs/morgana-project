extends CharacterBody2D
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const MAX_JUMPS: int = 3
var jump_count: int = 0

var is_attacking: bool = false

func attack() -> void:
	if not is_attacking:
		is_attacking = true
		animation.play("attack2")

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
	
	#scale.x = 1 if direction > 0 else -1
		
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
