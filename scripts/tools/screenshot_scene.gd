extends Node
func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var target := args[0] if args.size() > 0 else "res://scenes/levels/dev_sandbox_scene.tscn"
	var outp := args[1] if args.size() > 1 else "docs/maps/dev_sandbox_shot.png"
	var ps: PackedScene = load(target)
	var scene = ps.instantiate()
	add_child(scene)
	var gm = scene.get_node_or_null("GameManager")
	if gm:
		gm.intro_event = null   # skip the blocking intro dialogue
		gm.victory_event = null
	await get_tree().create_timer(2.5).timeout   # let it render + settle
	var img := get_viewport().get_texture().get_image()
	img.save_png(outp)
	print("[SHOT] saved %s %s" % [outp, str(img.get_size())])
	get_tree().quit()
