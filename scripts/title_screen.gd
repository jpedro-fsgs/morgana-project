extends Control

const KEYBOARD_CONTROLS = "A / D / ◄ ►  Mover     W / ▲  Pular (até 4x, sem tocar a barra de vida)     S / ▼  Agachar\nX ou Espaço  Atirar     Botão Esquerdo  Espada     Botão Direito  Magia (segure p/ carregar)"
const JOYPAD_CONTROLS = "Analógico / D-Pad  Mover     Botão Inferior (A/Cruz)  Pular (até 4x)     D-Pad ▼  Agachar\nDireito (X/Quadrado)  Atirar     Esquerdo (X/Quadrado)  Espada     Superior (Y/Triângulo)  Magia (segure)"

@onready var controls_label: Label = $VBox/ControlsLabel

func _ready() -> void:
	$VBox/StartButton.pressed.connect(_on_start_pressed)
	$VBox/StartButton.grab_focus()
	
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_update_controls_text()

func _update_controls_text() -> void:
	if Input.get_connected_joypads().size() > 0:
		controls_label.text = JOYPAD_CONTROLS
	else:
		controls_label.text = KEYBOARD_CONTROLS

func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_update_controls_text()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_start_pressed()

func _on_start_pressed() -> void:
	AudioManager.play_sfx("button")
	GameManager.restart_match()
	get_tree().change_scene_to_file("res://scenes/level.tscn")
