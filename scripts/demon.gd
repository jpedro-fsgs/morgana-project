extends CharacterBody2D
@onready var animation: AnimatedSprite2D = $Animation
@onready var death_timer: Timer = $DeathTimer

var fireball_scene = preload("res://scenes/fireball.tscn")


const SPEED = 75.0

var HP = 100

func hit(damage: int) -> void:
	HP -= damage
	print(HP)
	if HP <= 0:
		die()
	
func die() -> void:
	animation.play("die")
	death_timer.start(1)
	
func _on_fireball() -> void:
	var fireball = fireball_scene.instantiate()
	add_child(fireball)

func _ready() -> void:
	_on_fireball()
	

func _physics_process(_delta: float) -> void:
	
	#velocity = direction * SPEED
	move_and_slide()


func _on_timer_timeout() -> void:
	queue_free()
