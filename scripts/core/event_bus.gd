# EventBus - Global signal bus for decoupled communication
extends Node

# Battle Flow
signal battle_started
signal battle_ended(victory: bool)
signal turn_started(character: Node2D)
signal turn_ended(character: Node2D)
signal turn_order_changed(new_order: Array)

# Character Events
signal character_moved(character: Node2D, from_tile: Vector2i, to_tile: Vector2i)
signal character_movement_started(character: Node2D)
signal character_movement_finished(character: Node2D)
signal character_damaged(character: Node2D, amount: int, source: Node2D)
signal character_healed(character: Node2D, amount: int, source: Node2D)
signal character_died(character: Node2D)

# Tile Events
signal tile_hovered(tile_pos: Vector2i)

# UI Events
signal show_damage_popup(position: Vector2, amount: int, is_crit: bool)
signal update_turn_indicator(character: Node2D, is_enemy: bool)
