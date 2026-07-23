extends Node2D
class_name BatSpawner

@export var bat_scene: PackedScene
@export var spawn_x: float = 1050.0       # fora da tela, à direita
@export var spawn_y_min: float = 400.0    # topo da faixa de voo
@export var spawn_y_max: float = 780.0    # base da faixa de voo (perto do chão da vila)
@export var auto_start: bool = true

# Distribuição de tipos do documento: comum 70%, rápido 20%, gigante 10%
const TYPE_WEIGHTS := {"common": 0.7, "fast": 0.2, "giant": 0.1}

var _spawning: bool = false

func _ready() -> void:
	GameManager.game_over.connect(stop_spawning)
	GameManager.victory.connect(stop_spawning)

	if auto_start:
		start_spawning()

func start_spawning() -> void:
	if _spawning:
		return
	_spawning = true
	_spawn_loop()

func stop_spawning() -> void:
	_spawning = false

func _spawn_loop() -> void:
	while _spawning:
		var stage: Dictionary = GameManager.get_current_stage()
		await get_tree().create_timer(randf_range(stage.spawn_min, stage.spawn_max)).timeout
		if not _spawning:
			break
		if not GameManager.is_game_active:
			continue # partida ainda não começou (ex.: contagem regressiva inicial) ou está pausada
		_spawn_bat()

func _spawn_bat() -> void:
	if not bat_scene:
		push_warning("BatSpawner: nenhuma cena de morcego foi definida!")
		return

	var bat = bat_scene.instantiate()
	bat.setup(_pick_bat_type())
	bat.global_position = Vector2(spawn_x, randf_range(spawn_y_min, spawn_y_max))
	get_parent().call_deferred("add_child", bat)

func _pick_bat_type() -> String:
	var roll := randf()
	var cumulative := 0.0
	for type in TYPE_WEIGHTS.keys():
		cumulative += TYPE_WEIGHTS[type]
		if roll <= cumulative:
			return type
	return "common"
