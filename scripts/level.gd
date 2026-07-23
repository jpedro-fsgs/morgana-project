extends Node2D

## Reforça o tema "countdown": antes da defesa da vila começar de verdade,
## a partida fica em suspenso por uma contagem regressiva dramática.
## Isso usa a própria flag is_game_active do GameManager, então tempo,
## spawns e a física da jogadora ficam naturalmente congelados até o "VAI!".

@onready var intro_layer: CanvasLayer = $IntroCountdown
@onready var countdown_label: Label = $IntroCountdown/CountdownLabel
@onready var camera: Camera2D = $Player/Camera2D

const COUNTDOWN_STEPS := [
	{"text": "3", "color": Color(1, 1, 1), "hold": 0.7},
	{"text": "2", "color": Color(1, 1, 1), "hold": 0.7},
	{"text": "1", "color": Color(1, 1, 1), "hold": 0.7},
	{"text": "DEFENDA A VILA!", "color": Color(1.0, 0.85, 0.3), "hold": 0.9},
]

func _ready() -> void:
	GameManager.village_integrity_changed.connect(_on_village_damaged)
	GameManager.is_game_active = false
	await _run_intro_countdown()
	GameManager.is_game_active = true
	intro_layer.queue_free()

var _last_village_integrity: float = 100.0

func _on_village_damaged(value: float) -> void:
	# Um morcego furou a defesa: um tremor rápido de câmera deixa isso claro na hora.
	if value < _last_village_integrity:
		_shake_camera()
	_last_village_integrity = value

func _shake_camera() -> void:
	var original_offset: Vector2 = camera.offset
	var tween := create_tween()
	for i in range(5):
		var shake_offset = Vector2(randf_range(-6, 6), randf_range(-6, 6))
		tween.tween_property(camera, "offset", shake_offset, 0.035)
	tween.tween_property(camera, "offset", original_offset, 0.035)

func _run_intro_countdown() -> void:
	for step in COUNTDOWN_STEPS:
		countdown_label.text = step.text
		countdown_label.add_theme_color_override("font_color", step.color)
		countdown_label.scale = Vector2(1.5, 1.5)
		var tween := create_tween()
		tween.tween_property(countdown_label, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK)
		await get_tree().create_timer(step.hold).timeout
