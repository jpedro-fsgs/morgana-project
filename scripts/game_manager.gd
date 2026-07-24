extends Node

signal village_integrity_changed(value: float)
signal time_changed(time_left: float)
signal enemy_defeated_changed(count: int)
signal score_changed(value: int)
signal money_changed(value: int)
signal combo_changed(multiplier: int, streak: int)
signal combo_broken
signal game_over
signal victory
signal wave_started(wave_num: int)
signal preparation_started(wave_num: int)

## TEMPORÁRIO (facilita testes): trava a partida na última wave configurada
## em vez de dar vitória, pra continuar spawnando nesse ritmo indefinidamente.
## Reverter quando o loop de jogo for definido.
const INFINITE_TESTING_MODE: bool = true

const STARTING_MONEY: int = 50

const WAVES_CONFIG = [
	{ "prep_time": 15.0, "wave_time": 60.0, "difficulty_mult": 1.0 },
	{ "prep_time": 12.0, "wave_time": 75.0, "difficulty_mult": 1.25 },
	{ "prep_time": 10.0, "wave_time": 90.0, "difficulty_mult": 1.5 },
	{ "prep_time": 10.0, "wave_time": 120.0, "difficulty_mult": 1.8 },
	{ "prep_time": 5.0,  "wave_time": 150.0, "difficulty_mult": 2.2 }
]

const TOTAL_EXPECTED_BATS: float = 200.0
const DAMAGE_PER_HIT: float = 100.0 / TOTAL_EXPECTED_BATS

enum GamePhase { PREPARATION, WAVE, ENDED }
var current_phase: GamePhase = GamePhase.PREPARATION
var current_wave_index: int = 0
var wave_difficulty_multiplier: float = 1.0

const COMBO_TIERS := [
	{"streak": 14, "mult": 10},
	{"streak": 10, "mult": 8},
	{"streak": 7, "mult": 5},
	{"streak": 4, "mult": 3},
	{"streak": 2, "mult": 2},
]
var enemies_defeated: int = 0
var village_integrity: float = 100.0
var time_left: float = WAVES_CONFIG[0].prep_time
var is_game_active: bool = true
var speed_multiplier: float = 1.0

var score: int = 0
var high_score: int = 0
var money: int = 0
var combo_streak: int = 0
var combo_multiplier: int = 1

## Ligado pelo item CoinMagnetItem (ver ItemManager) quando comprado: moedas
## voam até a Morgana; quando false, ela precisa andar até elas no chão.
var coin_magnet_enabled: bool = false

func _ready() -> void:
	_reset_state()

func _reset_state() -> void:
	village_integrity = 100.0
	time_left = WAVES_CONFIG[0].prep_time
	current_phase = GamePhase.PREPARATION
	current_wave_index = 0
	wave_difficulty_multiplier = 1.0
	enemies_defeated = 0
	is_game_active = true
	speed_multiplier = 1.0
	score = 0
	combo_streak = 0
	combo_multiplier = 1
	money = STARTING_MONEY

func _process(delta: float) -> void:
	if not is_game_active or current_phase == GamePhase.ENDED:
		return

	time_left = max(0.0, time_left - delta)
	time_changed.emit(time_left)

	if time_left <= 0.0:
		if current_phase == GamePhase.PREPARATION:
			_start_wave()
		elif current_phase == GamePhase.WAVE:
			_end_wave()

func _start_wave() -> void:
	current_phase = GamePhase.WAVE
	var config = WAVES_CONFIG[current_wave_index]
	time_left = config.wave_time
	wave_difficulty_multiplier = config.difficulty_mult
	speed_multiplier = wave_difficulty_multiplier
	wave_started.emit(current_wave_index + 1)

func _end_wave() -> void:
	current_wave_index += 1
	if current_wave_index >= WAVES_CONFIG.size():
		if INFINITE_TESTING_MODE:
			# Sem mais waves configuradas: repete a última indefinidamente
			# em vez de dar vitória.
			current_wave_index = WAVES_CONFIG.size() - 1
			time_left = WAVES_CONFIG[current_wave_index].wave_time
			return
		_trigger_victory()
	else:
		current_phase = GamePhase.PREPARATION
		time_left = WAVES_CONFIG[current_wave_index].prep_time
		preparation_started.emit(current_wave_index + 1)

func register_enemy_defeated(score_value: int = 10) -> void:
	if not is_game_active:
		return
	enemies_defeated += 1
	enemy_defeated_changed.emit(enemies_defeated)

	combo_streak += 1
	combo_multiplier = _multiplier_for_streak(combo_streak)
	combo_changed.emit(combo_multiplier, combo_streak)

	score += score_value * combo_multiplier
	score_changed.emit(score)

func add_money(amount: int = 1) -> void:
	money += amount
	money_changed.emit(money)

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

func heal_village(amount: float) -> void:
	if not is_game_active:
		return
	village_integrity = min(100.0, village_integrity + amount)
	village_integrity_changed.emit(village_integrity)

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
	current_phase = GamePhase.ENDED
	high_score = max(high_score, score)
	game_over.emit()

func _trigger_victory() -> void:
	if not is_game_active:
		return
	is_game_active = false
	current_phase = GamePhase.ENDED
	score += 1000 + int(round(village_integrity * 10.0))
	score_changed.emit(score)
	high_score = max(high_score, score)
	victory.emit()

func restart_match() -> void:
	ItemManager.reset()
	_reset_state()
	village_integrity_changed.emit(village_integrity)
	time_changed.emit(time_left)
	enemy_defeated_changed.emit(enemies_defeated)
	score_changed.emit(score)
	combo_changed.emit(combo_multiplier, combo_streak)
	money_changed.emit(money)
