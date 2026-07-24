extends PlayerAbility
class_name WandAbility

const MAX_LEVEL: int = 5
const SPEED_STEP: float = 60.0
const DAMAGE_STEP: int = 5

var auto_fire: bool = false
var auto_aim: bool = false
var speed_level: int = 0
var damage_level: int = 0

var speed_bonus: float = 0.0
var damage_bonus: int = 0

func total_evolution_level() -> int:
	return int(auto_fire) + int(auto_aim) + speed_level + damage_level

func is_fully_evolved() -> bool:
	return auto_fire and auto_aim and speed_level >= MAX_LEVEL and damage_level >= MAX_LEVEL

## Ordem: dispara sozinha primeiro, mira sozinha depois — só então
## velocidade/dano entram no sorteio junto com o resto.
func apply_random_evolution() -> void:
	var options: Array[String] = []
	if not auto_fire:
		options.append("auto_fire")
	elif not auto_aim:
		options.append("auto_aim")
	if speed_level < MAX_LEVEL:
		options.append("speed")
	if damage_level < MAX_LEVEL:
		options.append("damage")
	if options.is_empty():
		return

	options.shuffle()
	match options[0]:
		"auto_fire":
			auto_fire = true
		"auto_aim":
			auto_aim = true
		"speed":
			speed_level += 1
			speed_bonus += SPEED_STEP
		"damage":
			damage_level += 1
			damage_bonus += DAMAGE_STEP
