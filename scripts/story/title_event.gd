# TitleEvent - A StoryEvent that displays the game title via TitleCard.
# Awaits the full fade-in → hold → fade-out cycle before completing.
class_name TitleEvent
extends StoryEvent

## The text to display (defaults to game title).
@export var text: String = "TRISTO TACTICS"
## Seconds to fade in.
@export var fade_in: float = 1.0
## Seconds to hold at full opacity.
@export var hold: float = 4.0
## Seconds to fade out.
@export var fade_out: float = 1.5

func execute(scene_tree: SceneTree) -> void:
	# Find the TitleCard — it should be added by the corridor scene
	var title_cards := scene_tree.get_nodes_in_group("title_card")
	var title: TitleCard = null
	if title_cards.size() > 0:
		title = title_cards[0] as TitleCard
	if not title:
		# Fallback: search all nodes
		for node in scene_tree.root.get_children():
			title = _find_title_card(node)
			if title:
				break
	if not title:
		push_warning("TitleEvent: No TitleCard found")
		return
	# Fire-and-forget — don't await so the player can keep walking
	title.show_title(text, fade_in, hold, fade_out)

func _find_title_card(node: Node) -> TitleCard:
	if node is TitleCard:
		return node as TitleCard
	for child in node.get_children():
		var found := _find_title_card(child)
		if found:
			return found
	return null
