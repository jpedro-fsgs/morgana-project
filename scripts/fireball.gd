extends Area2D

var direction: int = 1
var speed: float = 400.0
var shooter: Node = null
var damage: int = 25

func _ready():
	if direction > 0:
		$Projectile.flip_h = true
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position.x += direction * speed * delta
	
	if abs(global_position.x) > 3000:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == shooter:
		return
		
	if body.has_method("take_damage"):
		body.take_damage(damage, shooter)
		queue_free()
