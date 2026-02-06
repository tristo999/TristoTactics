# DamagePopup - Floating damage number that fades out
extends Label

@export var float_speed: float = 50.0
@export var fade_duration: float = 0.8
@export var crit_color: Color = Color.YELLOW
@export var normal_color: Color = Color.WHITE

var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(queue_free)

func _process(delta: float) -> void:
	position += velocity * delta
	velocity.y -= float_speed * delta * 0.5

func setup(amount: int, is_crit: bool) -> void:
	text = str(amount)
	if is_crit:
		text += "!"
		add_theme_color_override("font_color", crit_color)
		scale = Vector2(1.5, 1.5)
	else:
		add_theme_color_override("font_color", normal_color)
	velocity = Vector2(randf_range(-20, 20), -float_speed)
