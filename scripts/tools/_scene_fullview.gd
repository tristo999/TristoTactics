# One-off: load a full game scene, then zoom the active camera out to fit the
# whole map — to compare the SCENE's tile rendering against the isolated map
# render. Usage:
#   <godot> --rendering-driver opengl3 --path . res://scenes/dev/scene_fullview.tscn -- <scene.tscn> <out.png>
extends Node

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var target := "res://scenes/levels/tutorial_spar_scene.tscn"
	var outp := "docs/maps/scene_fullview.png"
	if args.size() > 0: target = args[0]
	if args.size() > 1: outp = args[1]
	var scene = (load(target) as PackedScene).instantiate()
	add_child(scene)
	var gm = scene.get_node_or_null("GameManager")
	if gm:
		gm.intro_event = null
		gm.victory_event = null
	await get_tree().create_timer(2.5).timeout
	var tiles_w := 42.0
	var tiles_h := 32.0
	if args.size() > 2: tiles_w = float(args[2])
	if args.size() > 3: tiles_h = float(args[3])
	var cam := get_viewport().get_camera_2d()
	if cam:
		var vp := get_viewport().get_visible_rect().size
		var z: float = min(vp.x / (tiles_w * 16.0), vp.y / (tiles_h * 16.0))
		cam.zoom = Vector2(z, z)
		cam.global_position = Vector2(tiles_w * 16 / 2.0, tiles_h * 16 / 2.0)
		cam.limit_left = -100000; cam.limit_top = -100000
		cam.limit_right = 100000; cam.limit_bottom = 100000
	await get_tree().create_timer(0.4).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(outp)
	print("[SCENEVIEW] saved ", outp, " ", img.get_size())
	get_tree().quit()
