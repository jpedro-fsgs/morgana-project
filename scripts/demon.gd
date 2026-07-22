extends CharacterBody2D
@onready var animation: AnimatedSprite2D = $Animation
@onready var death_timer: Timer = $DeathTimer

var fireball_scene = preload("res://scenes/fireball.tscn")


const SPEED = 75.0

var HP = 100
var is_dead = false

func take_damage(amount: int, source: Node = null) -> void:
	if is_dead: return
	HP -= amount
	print("Demon took damage! HP: ", HP)
	
	# Feedback visual (piscar em vermelho)
	animation.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	animation.modulate = Color(1, 1, 1)
	
	if HP <= 0:
		die()
func die() -> void:
	is_dead = true
	$CollisionShape2D.set_deferred("disabled", true)
	animation.play("die")
	
	death_timer.start(1)
	
func _on_fireball() -> void:
	var fireball = fireball_scene.instantiate()
	fireball.shooter = self
	fireball.direction = -1 # Atira para a esquerda por padrão
	fireball.global_position = global_position + Vector2(-30, 0)
	get_parent().add_child(fireball)

func _ready() -> void:
	pass
	

func _physics_process(_delta: float) -> void:
	if is_dead: return
	velocity.x = -SPEED
	move_and_slide()


func _on_timer_timeout() -> void:
	queue_free()
