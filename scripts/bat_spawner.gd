extends Node2D
class_name BatSpawner

@export var bat_scene: PackedScene
@export var spawn_x_offset: float = 600.0   # distância à direita da câmera
@export var spawn_y_min: float = 400.0    # topo da faixa de voo
@export var spawn_y_max: float = 780.0    # base da faixa de voo (perto do chão da vila)
@export var auto_start: bool = true

const COUNTDOWN_SPAWN_INTERVAL: float = 4.0
const HORDE_SPAWN_INTERVAL_MIN: float = 0.35
const HORDE_SPAWN_INTERVAL_MAX: float = 0.65

# Distribuição de tipos do documento: comum 70%, rápido 20%, gigante 10%
const TYPE_WEIGHTS := {"common": 0.7, "fast": 0.2, "giant": 0.1}

var _spawning: bool = false
var _current_timer: SceneTreeTimer = null

func _ready() -> void:
	GameManager.game_over.connect(stop_spawning)
	GameManager.victory.connect(stop_spawning)
	GameManager.horde_started.connect(_on_horde_started)

	if auto_start:
		start_spawning()

func start_spawning() -> void:
	if _spawning:
		return
	_spawning = true
	_spawn_loop()

func stop_spawning() -> void:
	_spawning = false

func _on_horde_started() -> void:
	# Interrompe a espera longa de 4s para começar o bombardeio frenético na mesma hora
	if _current_timer:
		_current_timer.time_left = 0.0

func _spawn_loop() -> void:
	while _spawning:
		var interval := COUNTDOWN_SPAWN_INTERVAL
		if GameManager.current_phase == GameManager.GamePhase.HORDE:
			interval = randf_range(HORDE_SPAWN_INTERVAL_MIN, HORDE_SPAWN_INTERVAL_MAX)
		
		_current_timer = get_tree().create_timer(interval)
		await _current_timer.timeout
		_current_timer = null
		
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
	var camera = get_viewport().get_camera_2d()
	var cam_x = camera.global_position.x if camera else 576.0
	var actual_spawn_x = cam_x + spawn_x_offset
	bat.global_position = Vector2(actual_spawn_x, randf_range(spawn_y_min, spawn_y_max))
	get_parent().call_deferred("add_child", bat)

func _pick_bat_type() -> String:
	var roll := randf()
	var cumulative := 0.0
	for type in TYPE_WEIGHTS.keys():
		cumulative += TYPE_WEIGHTS[type]
		if roll <= cumulative:
			return type
	return "common"
