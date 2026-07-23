extends EnemyBase

const TYPE_CONFIG := {
	"common": {"hp": 25, "speed": 110.0, "damage": 1.0, "score": 10, "heal": 0.0, "scale": 1.0, "tint": Color(1,1,1)},
	"fast":   {"hp": 25, "speed": 220.0, "damage": 1.0, "score": 20, "heal": 0.0, "scale": 0.8, "tint": Color(1,0.95,0.6)},
	"giant":  {"hp": 50, "speed": 65.0,  "damage": 2.0, "score": 30, "heal": 2.0, "scale": 1.6, "tint": Color(0.75,0.6,1.0)},
}

var bat_type: String = "common"

func setup(type: String) -> void:
	bat_type = type

func _enemy_ready() -> void:
	var config = TYPE_CONFIG.get(bat_type, TYPE_CONFIG["common"])
	max_hp = config.hp
	hp = max_hp
	move_speed = config.speed
	village_damage = config.damage
	defeat_score = config.score
	defeat_heal = config.heal
	_animation.scale *= config.scale
	_animation.modulate = config.tint
	_animation.play("fly")
