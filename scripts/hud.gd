extends CanvasLayer

@onready var village_bar: ProgressBar = $TopBar/VillageBar
@onready var timer_label: Label = $TopBar/TimerLabel
@onready var score_label: Label = $BottomRight/ScoreLabel
@onready var combo_label: Label = $BottomRight/ComboLabel
@onready var money_label: Label = $BottomRight/MoneyLabel
@onready var magnet_icon: TextureRect = $ActiveItemsBar/MagnetIcon
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var result_panel: Panel = $ResultPanel
@onready var result_title: Label = $ResultPanel/VBox/ResultTitle
@onready var result_subtitle: Label = $ResultPanel/VBox/ResultSubtitle
@onready var stats_label: Label = $ResultPanel/VBox/StatsLabel
@onready var restart_button: Button = $ResultPanel/VBox/ButtonRow/RestartButton
@onready var menu_button: Button = $ResultPanel/VBox/ButtonRow/MenuButton

func _ready() -> void:
	result_panel.visible = false
	fade_overlay.modulate.a = 0.0
	timer_label.pivot_offset = timer_label.size / 2.0

	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

	GameManager.village_integrity_changed.connect(_on_village_changed)
	GameManager.time_changed.connect(_on_time_changed)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.combo_changed.connect(_on_combo_changed)
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.game_over.connect(_on_game_over)
	GameManager.victory.connect(_on_victory)
	ItemManager.item_acquired.connect(_on_item_acquired)

	_on_village_changed(GameManager.village_integrity)
	_on_time_changed(GameManager.time_left)
	_on_score_changed(GameManager.score)
	_on_combo_changed(GameManager.combo_multiplier, GameManager.combo_streak)
	_on_money_changed(GameManager.money)
	magnet_icon.visible = ItemManager.is_owned(&"coin_magnet")

var _last_village_value: float = 100.0

func _on_village_changed(value: float) -> void:
	village_bar.value = value
	if value < _last_village_value:
		_flash_village_bar()
	_last_village_value = value

func _flash_village_bar() -> void:
	village_bar.modulate = Color(1.6, 0.5, 0.5)
	var tween := create_tween()
	tween.tween_property(village_bar, "modulate", Color(1, 1, 1), 0.3)

var _last_pulsed_second: int = -1

func _on_time_changed(time_left: float) -> void:
	var minutes := int(time_left) / 60
	var seconds := int(time_left) % 60
	
	if GameManager.current_phase == GameManager.GamePhase.PREPARATION:
		timer_label.text = "PREPARAÇÃO: %02d:%02d" % [minutes, seconds]
		timer_label.remove_theme_color_override("font_color")
	else:
		timer_label.text = "WAVE %d: %02d:%02d" % [GameManager.current_wave_index + 1, minutes, seconds]
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
		
		# Apenas pulsa dramático nos últimos 10 segundos da Horda
		if time_left <= 10.0:
			var whole_second := int(ceil(time_left))
			if whole_second != _last_pulsed_second:
				_last_pulsed_second = whole_second
				_pulse_timer()

func _pulse_timer() -> void:
	var tween := create_tween()
	tween.tween_property(timer_label, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(timer_label, "scale", Vector2(1.0, 1.0), 0.2)

func _on_score_changed(value: int) -> void:
	score_label.text = "Pontos: %d" % value

func _on_combo_changed(multiplier: int, streak: int) -> void:
	if streak >= 2:
		combo_label.text = "Combo ×%d (%d)" % [multiplier, streak]
		combo_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	else:
		combo_label.text = ""

func _on_money_changed(value: int) -> void:
	money_label.text = "Moedas: %d" % value

func _on_item_acquired(item: ItemBase) -> void:
	if item.id == &"coin_magnet":
		magnet_icon.visible = true

func _on_game_over() -> void:
	_show_result("GAME OVER", "A vila caiu...", Color(0.85, 0.2, 0.2))

func _on_victory() -> void:
	_show_result("VITÓRIA!", "O sol nasceu. As trevas recuaram.", Color(1.0, 0.85, 0.3))

func _show_result(title: String, subtitle: String, color: Color) -> void:
	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.75, 1.0)
	await tween.finished
	await get_tree().create_timer(0.4).timeout

	result_title.text = title
	result_title.add_theme_color_override("font_color", color)
	result_subtitle.text = subtitle
	stats_label.text = "Inimigos derrotados: %d\nIntegridade final da vila: %d%%\nPontuação final: %d\nRecorde da sessão: %d" % [
		GameManager.enemies_defeated,
		int(round(GameManager.village_integrity)),
		GameManager.score,
		GameManager.high_score
	]
	result_panel.visible = true

func _on_restart_pressed() -> void:
	GameManager.restart_match()
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title.tscn")
