extends Node

var click_sfx = preload("res://assets/audio/click.mp3")

var sounds: Dictionary = {
	"jump": click_sfx,
	"shoot": click_sfx,
	"aura": click_sfx,
	"player_hurt": click_sfx,
	"enemy_hit": click_sfx,
	"enemy_die": click_sfx,
	"village_hit": click_sfx,
	"button": click_sfx
}

var players: Array[AudioStreamPlayer] = []
const POOL_SIZE = 12
var current_player_index: int = 0

func _ready() -> void:
	for i in POOL_SIZE:
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		players.append(p)

func play_sfx(sound_name: String) -> void:
	if not sounds.has(sound_name):
		return
	
	# Round-robin: Pega sempre o próximo player do pool. 
	# Isso garante que se o pool lotar (ex: arquivo de som com muito silêncio no final),
	# o sistema força a execução cortando o som mais antigo da fila.
	var p = players[current_player_index]
	p.stream = sounds[sound_name]
	p.play()
	
	current_player_index = (current_player_index + 1) % POOL_SIZE
