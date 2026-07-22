extends Node2D
class_name EnemySpawner

@export var enemy_scene: PackedScene
@export var default_spawn_position: Vector2 = Vector2(1050, 629) # Fora da tela à direita, configurável no inspector
@export var spawn_interval: float = 3.0
@export var auto_start: bool = true

var spawn_timer: Timer

func _ready() -> void:
	# Configura um timer dinamicamente para o ciclo de spawn
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	
	if auto_start:
		start_spawning()

func start_spawning() -> void:
	spawn_timer.start()

func stop_spawning() -> void:
	spawn_timer.stop()

func spawn_enemy(spawn_position: Vector2 = default_spawn_position) -> void:
	if not enemy_scene:
		push_warning("EnemySpawner: Nenhuma cena de inimigo foi definida!")
		return
		
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_position
	# Usamos call_deferred para adicionar a cena com segurança durante cálculos de física
	get_parent().call_deferred("add_child", enemy)

func _on_spawn_timer_timeout() -> void:
	spawn_enemy()
