extends Node

# --- Sinais que a HUD, o jogador e os morcegos escutam ---
signal village_integrity_changed(value: float)
signal time_changed(time_left: float)
signal bat_defeated_changed(count: int)
signal score_changed(value: int)
signal combo_changed(multiplier: int, streak: int)
signal combo_broken
signal game_over
signal victory

# --- Configuração da partida ---
const MATCH_DURATION: float = 180.0          # 3 minutos, exatamente como pede o documento
const TOTAL_EXPECTED_BATS: float = 45.0      # aumentado (era 30) para a vila aguentar mais mordidas
const DAMAGE_PER_HIT: float = 100.0 / TOTAL_EXPECTED_BATS  # ~2,22% por morcego que entra na vila (era ~3,33%)

# --- Progressão de dificuldade (tempo restante -> intervalo de spawn / multiplicador de velocidade) ---
# Suavizada: intervalos de spawn maiores e velocidade máxima menor, para dar mais respiro ao jogador
const DIFFICULTY_STAGES := [
	{"time": 180.0, "spawn_min": 1.8, "spawn_max": 2.6, "speed_mult": 1.0},
	{"time": 165.0, "spawn_min": 1.5, "spawn_max": 2.2, "speed_mult": 1.0},
	{"time": 150.0, "spawn_min": 1.3, "spawn_max": 1.9, "speed_mult": 1.0},
	{"time": 135.0, "spawn_min": 1.1, "spawn_max": 1.7, "speed_mult": 1.0},
	{"time": 120.0, "spawn_min": 1.0, "spawn_max": 1.5, "speed_mult": 1.0},
	{"time": 105.0, "spawn_min": 0.85, "spawn_max": 1.3, "speed_mult": 1.05},
	{"time": 90.0, "spawn_min": 0.75, "spawn_max": 1.2, "speed_mult": 1.1},
	{"time": 75.0, "spawn_min": 0.65, "spawn_max": 1.05, "speed_mult": 1.1},
	{"time": 60.0, "spawn_min": 0.55, "spawn_max": 0.95, "speed_mult": 1.15},
	{"time": 45.0, "spawn_min": 0.48, "spawn_max": 0.8, "speed_mult": 1.15},
	{"time": 30.0, "spawn_min": 0.4, "spawn_max": 0.65, "speed_mult": 1.2},
	{"time": 15.0, "spawn_min": 0.32, "spawn_max": 0.5, "speed_mult": 1.25},
]

# --- Sistema de combo (kill chain ×2 → ×3 → ×5 → ×8 → ×10) ---
const COMBO_TIERS := [
	{"streak": 14, "mult": 10},
	{"streak": 10, "mult": 8},
	{"streak": 7, "mult": 5},
	{"streak": 4, "mult": 3},
	{"streak": 2, "mult": 2},
]
const BAT_SCORE := {"common": 10, "fast": 20, "giant": 30}

var village_integrity: float = 100.0
var time_left: float = MATCH_DURATION
var bats_defeated: int = 0
var is_game_active: bool = true
var speed_multiplier: float = 1.0

var score: int = 0
var high_score: int = 0
var combo_streak: int = 0
var combo_multiplier: int = 1

func _ready() -> void:
	_reset_state()

func _reset_state() -> void:
	village_integrity = 100.0
	time_left = MATCH_DURATION
	bats_defeated = 0
	is_game_active = true
	speed_multiplier = 1.0
	score = 0
	combo_streak = 0
	combo_multiplier = 1

func _process(delta: float) -> void:
	if not is_game_active:
		return

	time_left = max(0.0, time_left - delta)
	time_changed.emit(time_left)
	speed_multiplier = get_current_stage().speed_mult

	if time_left <= 0.0:
		_trigger_victory()

# Retorna o estágio de dificuldade ativo para o tempo restante atual.
# Usado pelo spawner para decidir o intervalo entre spawns.
func get_current_stage() -> Dictionary:
	var chosen: Dictionary = DIFFICULTY_STAGES[0]
	for stage in DIFFICULTY_STAGES:
		if time_left <= stage.time:
			chosen = stage
	return chosen

func register_bat_defeated(bat_type: String = "common") -> void:
	if not is_game_active:
		return
	bats_defeated += 1
	bat_defeated_changed.emit(bats_defeated)

	combo_streak += 1
	combo_multiplier = _multiplier_for_streak(combo_streak)
	combo_changed.emit(combo_multiplier, combo_streak)

	var base_score: int = BAT_SCORE.get(bat_type, 10)
	score += base_score * combo_multiplier
	score_changed.emit(score)

func _multiplier_for_streak(streak: int) -> int:
	for tier in COMBO_TIERS:
		if streak >= tier.streak:
			return tier.mult
	return 1

func _break_combo() -> void:
	if combo_streak == 0:
		return
	combo_streak = 0
	combo_multiplier = 1
	combo_broken.emit()
	combo_changed.emit(combo_multiplier, combo_streak)

func damage_village(hits: float = 1.0) -> void:
	if not is_game_active:
		return
	_break_combo()
	village_integrity = max(0.0, village_integrity - DAMAGE_PER_HIT * hits)
	village_integrity_changed.emit(village_integrity)

	if village_integrity <= 0.0:
		_trigger_game_over()

func _trigger_game_over() -> void:
	if not is_game_active:
		return
	is_game_active = false
	high_score = max(high_score, score)
	game_over.emit()

func _trigger_victory() -> void:
	if not is_game_active:
		return
	is_game_active = false
	# Bônus de vitória: pontos fixos + integridade restante × 10 (regra do documento)
	score += 1000 + int(round(village_integrity * 10.0))
	score_changed.emit(score)
	high_score = max(high_score, score)
	victory.emit()

# Permite reiniciar a partida sem recarregar a cena inteira, se quiser usar futuramente
func restart_match() -> void:
	_reset_state()
	village_integrity_changed.emit(village_integrity)
	time_changed.emit(time_left)
	bat_defeated_changed.emit(bats_defeated)
	score_changed.emit(score)
	combo_changed.emit(combo_multiplier, combo_streak)
