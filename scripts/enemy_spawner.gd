extends Node2D
class_name EnemySpawner

## Entrada da tabela de spawn
class SpawnEntry:
	var scene: PackedScene
	var weight: float
	var setup_type: String  # passado a setup() se o inimigo tiver
	
	func _init(p_scene: PackedScene, p_weight: float = 1.0, p_type: String = "") -> void:
		scene = p_scene
		weight = p_weight
		setup_type = p_type

## --- Configuração de Posição ---
enum SpawnMode { CAMERA_RELATIVE, ABSOLUTE }
@export var spawn_mode: SpawnMode = SpawnMode.CAMERA_RELATIVE
@export var spawn_offset: Vector2 = Vector2(600, 0)  # Para CAMERA_RELATIVE
@export var spawn_position: Vector2 = Vector2.ZERO	 # Para ABSOLUTE
@export var spawn_y_min: float = 400.0
@export var spawn_y_max: float = 780.0
@export var randomize_y: bool = true

## --- Configuração de Tempo por Fase ---
@export var horde_interval_min: float = 0.35
@export var horde_interval_max: float = 0.65
@export var auto_start: bool = true

var spawn_table: Array[SpawnEntry] = []
var _spawning: bool = false
var _current_timer: SceneTreeTimer = null

func _ready() -> void:
	GameManager.game_over.connect(stop_spawning)
	GameManager.victory.connect(stop_spawning)
	GameManager.wave_started.connect(_on_wave_started)
	if auto_start:
		start_spawning()

func set_spawn_table(table: Array[SpawnEntry]) -> void:
	spawn_table = table

func start_spawning() -> void:
	if _spawning:
		return
	_spawning = true
	_spawn_loop()

func stop_spawning() -> void:
	_spawning = false

func _on_wave_started(_wave_num: int) -> void:
	if _current_timer:
		_current_timer.time_left = 0.0

func _spawn_loop() -> void:
	while _spawning:
		if GameManager.current_phase == GameManager.GamePhase.PREPARATION:
			_current_timer = get_tree().create_timer(9999.0)
			await _current_timer.timeout
			_current_timer = null
			continue
			
		var interval := _get_current_interval()
		_current_timer = get_tree().create_timer(interval)
		await _current_timer.timeout
		_current_timer = null
		if not _spawning:
			break
		if not GameManager.is_game_active:
			continue
		spawn_enemy()

func _get_current_interval() -> float:
	var mult = GameManager.wave_difficulty_multiplier
	return randf_range(horde_interval_min / mult, horde_interval_max / mult)

## Método público — pode ser chamado externamente para spawns "scriptados"
func spawn_enemy(override_entry: SpawnEntry = null) -> Node:
	var entry := override_entry if override_entry else _pick_from_table()
	if entry == null or entry.scene == null:
		push_warning("EnemySpawner: tabela de spawn vazia!")
		return null

	var enemy = entry.scene.instantiate()
	if entry.setup_type != "" and enemy.has_method("setup"):
		enemy.setup(entry.setup_type)
	
	enemy.global_position = _calculate_spawn_position()
	get_parent().call_deferred("add_child", enemy)
	return enemy

## Spawn manual de uma onda inteira (ex: 5 goblins de uma vez num ponto fixo)
func spawn_wave(entry: SpawnEntry, count: int, spread: float = 80.0) -> void:
	for i in count:
		var e = spawn_enemy(entry)
		if e:
			e.global_position.x += i * spread

func _calculate_spawn_position() -> Vector2:
	var pos: Vector2
	match spawn_mode:
		SpawnMode.CAMERA_RELATIVE:
			var camera = get_viewport().get_camera_2d()
			var cam_pos = camera.global_position if camera else Vector2(576, 600)
			pos = cam_pos + spawn_offset
		SpawnMode.ABSOLUTE:
			pos = spawn_position
	
	if randomize_y:
		pos.y = randf_range(spawn_y_min, spawn_y_max)
	return pos

func _pick_from_table() -> SpawnEntry:
	if spawn_table.is_empty():
		return null
	var total_weight := 0.0
	for entry in spawn_table:
		total_weight += entry.weight
	var roll := randf() * total_weight
	var cumulative := 0.0
	for entry in spawn_table:
		cumulative += entry.weight
		if roll <= cumulative:
			return entry
	return spawn_table[spawn_table.size() - 1]
