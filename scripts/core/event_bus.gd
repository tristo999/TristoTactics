# EventBus - Global signal bus for decoupled communication
extends Node

# Battle Flow
signal battle_started
signal battle_ended(victory: bool)
signal turn_started(character: CharacterBase)
signal turn_ended(character: CharacterBase)

# Character Events
signal character_moved(character: Node2D, from_tile: Vector2i, to_tile: Vector2i)
signal character_movement_started(character: Node2D)
signal character_movement_finished(character: Node2D)
signal character_attacked(attacker: Node2D, target: Node2D, damage: int, is_crit: bool)
signal character_damaged(character: Node2D, amount: int, source: Node2D)
signal character_healed(character: Node2D, amount: int, source: Node2D)
signal character_died(character: Node2D)

# Story Events
signal story_event_triggered(event: StoryEvent)

# Tile Events
signal tile_hovered(tile_pos: Vector2i)
