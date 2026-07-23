extends Node2D
class_name AuraVisualizer

var _current_radius: float = 0.0
var _current_alpha: float = 0.0

func play_explosion(max_radius: float, expand_duration: float = 0.25, fade_duration: float = 0.3) -> void:
	_current_radius = 20.0
	_current_alpha = 0.6
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "_current_radius", max_radius, expand_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_current_alpha", 0.0, fade_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func(): _current_radius = 0.0)

func _process(_delta: float) -> void:
	if _current_radius > 0:
		queue_redraw()

func _draw() -> void:
	if _current_radius > 0:
		draw_circle(Vector2.ZERO, _current_radius, Color(0.3, 0.8, 1.0, _current_alpha))
		draw_arc(Vector2.ZERO, _current_radius, 0, TAU, 32, Color(0.8, 0.95, 1.0, _current_alpha * 1.5), 2.0)
