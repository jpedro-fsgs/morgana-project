extends Node

signal village_integrity_changed(value: float)
signal time_changed(time_left: float)
signal enemy_defeated_changed(count: int)
signal score_changed(value: int)
signal combo_changed(multiplier: int, streak: int)
signal combo_broken
signal game_over
signal victory
signal horde_started

const COUNTDOWN_DURATION: float = 15.0
const HORDE_DURATION: float = 60.0
const TOTAL_EXPECTED_BATS: float = 45.0
const DAMAGE_PER_HIT: float = 100.0 / TOTAL_EXPECTED_BATS

enum GamePhase { COUNTDOWN, HORDE, ENDED }
var current_phase: GamePhase = GamePhase.COUNTDOWN

const COMBO_TIERS := [
	{"streak": 14, "mult": 10},
	{"streak": 10, "mult": 8},
	{"streak": 7, "mult": 5},
	{"streak": 4, "mult": 3},
	{"streak": 2, "mult": 2},
]
var enemies_defeated: int = 0
var village_integrity: float = 100.0
var time_left: float = COUNTDOWN_DURATION
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
	time_left = COUNTDOWN_DURATION
	current_phase = GamePhase.COUNTDOWN
	enemies_defeated = 0
	is_game_active = true
	speed_multiplier = 1.0
	score = 0
	combo_streak = 0
	combo_multiplier = 1

func _process(delta: float) -> void:
	if not is_game_active or current_phase == GamePhase.ENDED:
		return

	time_left = max(0.0, time_left - delta)
	time_changed.emit(time_left)

	if time_left <= 0.0:
		if current_phase == GamePhase.COUNTDOWN:
			_start_horde()
		elif current_phase == GamePhase.HORDE:
			_trigger_victory()

func _start_horde() -> void:
	current_phase = GamePhase.HORDE
	time_left = HORDE_DURATION
	speed_multiplier = 1.25 # Morcegos mais agressivos na Horda
	horde_started.emit()

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
	_reset_state()
	village_integrity_changed.emit(village_integrity)
	time_changed.emit(time_left)
	enemy_defeated_changed.emit(enemies_defeated)
	score_changed.emit(score)
	combo_changed.emit(combo_multiplier, combo_streak)
