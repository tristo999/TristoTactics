# Ability - Base resource for character abilities (heal, fireball, buff, etc.)
# Subclass this and override execute() for each concrete ability type.
class_name Ability
extends Resource

enum TargetType {
	ALLY, ## Target a friendly unit
	ENEMY, ## Target a hostile unit
	SELF, ## Targets self only (no selection needed)
	TILE, ## Target an empty tile
	ALL_ALLIES, ## Hits all allies (no selection needed)
	ALL_ENEMIES ## Hits all enemies (no selection needed)
}

@export var ability_name: String = "Ability"
@export var description: String = ""
@export var icon: Texture2D

@export_group("Targeting")
@export var target_type: TargetType = TargetType.ENEMY
@export var range_min: int = 1
@export var range_max: int = 1

@export_group("Cost")
## Uses per battle (0 = unlimited).
@export var max_uses: int = 0

## Runtime uses remaining — set at battle start.
var uses_left: int = 0

## Initialize uses at battle start.
func reset_uses() -> void:
	uses_left = max_uses

## Whether this ability can still be used.
func can_use() -> bool:
	return max_uses == 0 or uses_left > 0

## Consume a use. Call this inside execute().
func consume_use() -> void:
	if max_uses > 0:
		uses_left = max(0, uses_left - 1)

## Get valid target tiles from `origin` for highlighting.
func get_target_tiles(origin: Vector2i, tilemap: Node2D) -> Array:
	var tiles: Array = []
	for x in range(-range_max, range_max + 1):
		for y in range(-range_max, range_max + 1):
			var dist = abs(x) + abs(y)
			if dist >= range_min and dist <= range_max:
				var tile = origin + Vector2i(x, y)
				if tilemap.astar_grid.is_in_boundsv(tile):
					tiles.append(tile)
	return tiles

## Override in subclasses. Executes the ability on the given target.
## `caster` is the CharacterBase using the ability.
## `target` is either a CharacterBase or Vector2i depending on target_type.
## Returns a result dictionary.
func execute(caster, target) -> Dictionary:
	push_warning("Ability.execute() not overridden for %s" % ability_name)
	return {"success": false}
