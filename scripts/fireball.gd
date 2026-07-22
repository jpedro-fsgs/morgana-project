extends Area2D

var direction: int = 1
var speed: float = 400.0

func _ready():
	if direction < 0:
		$Projectile.flip_h = true

func _process(delta: float) -> void:
	position.x += direction * speed * delta
	
	if abs(global_position.x) > 3000:
		queue_free()
