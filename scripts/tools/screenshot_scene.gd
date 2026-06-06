extends Node

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var target := "res://scenes/levels/dev_sandbox_scene.tscn"
	if args.size() > 0:
		target = args[0]
	var outp := "docs/maps/dev_sandbox_shot.png"
	if args.size() > 1:
		outp = args[1]
	var ps: PackedScene = load(target)
	var scene = ps.instantiate()
	add_child(scene)
	var gm = scene.get_node_or_null("GameManager")
	if gm:
		gm.intro_event = null
		gm.victory_event = null
	await get_tree().create_timer(2.5).timeout
	var cam = get_viewport().get_camera_2d()
	if cam != null:
		print("[DIAG] vp=", get_viewport().get_visible_rect().size, " pos=", cam.global_position, " zoom=", cam.zoom, " limT=", cam.limit_top, " limB=", cam.limit_bottom)
	var img := get_viewport().get_texture().get_image()
	img.save_png(outp)
	print("[SHOT] saved ", outp, " ", img.get_size())
	get_tree().quit()
