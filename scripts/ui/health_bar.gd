# HealthBar - Reusable HP bar for characters
# Create via HealthBar.new(); call setup() after adding to the tree.
extends ProgressBar
class_name HealthBar

const BAR_SIZE := Vector2(16, 3)
const BAR_OFFSET := Vector2(-8, -12)
const CORNER_RADIUS := 1

# Each bar stores its own fill style so colours stay independent per character
var _fill_style: StyleBoxFlat


func _ready() -> void:
	show_percentage = false
	size = BAR_SIZE
	position = BAR_OFFSET
	_apply_background_style()
	_create_fill_style()

# =========================================================================
# PUBLIC API
# =========================================================================

## Call once after adding to the tree to set initial HP and team colour.
func setup(max_hp_value: int, current_hp_value: int, team: String) -> void:
	max_value = max_hp_value
	value = current_hp_value
	_fill_style.bg_color = _get_fill_color(team, current_hp_value, max_hp_value)

## Update the bar after HP changes.
func update_hp(current_hp_value: int, max_hp_value: int, team: String) -> void:
	value = current_hp_value
	_fill_style.bg_color = _get_fill_color(team, current_hp_value, max_hp_value)

# =========================================================================
# STYLING
# =========================================================================

func _apply_background_style() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	bg.corner_radius_top_left = CORNER_RADIUS
	bg.corner_radius_top_right = CORNER_RADIUS
	bg.corner_radius_bottom_left = CORNER_RADIUS
	bg.corner_radius_bottom_right = CORNER_RADIUS
	add_theme_stylebox_override("background", bg)

func _create_fill_style() -> void:
	_fill_style = StyleBoxFlat.new()
	_fill_style.corner_radius_top_left = CORNER_RADIUS
	_fill_style.corner_radius_top_right = CORNER_RADIUS
	_fill_style.corner_radius_bottom_left = CORNER_RADIUS
	_fill_style.corner_radius_bottom_right = CORNER_RADIUS
	add_theme_stylebox_override("fill", _fill_style)

func _get_fill_color(team: String, hp: int, hp_max: int) -> Color:
	var pct := float(hp) / float(hp_max) if hp_max > 0 else 0.0
	if pct > 0.5:
		return Color.GREEN if team == Constants.TEAM_PLAYER else Color.RED
	elif pct > 0.25:
		return Color.YELLOW
	return Color.ORANGE_RED
