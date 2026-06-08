# Regression test for AttackAnimationOverlay. The healer's follow-up heal used to
# `await` a tween that had already finished, which hangs forever — the overlay stayed
# on screen and froze the battle. This drives heal + attack animations to completion
# and asserts the overlay always releases (_is_playing back to false). If the hang
# regressed, the first await never returns and this scene times out with no output.
extends Node

var _results: Array = []

func _ready() -> void:
	await _run()
	var passed := 0
	for r in _results:
		if r[0]:
			passed += 1
		print(("  PASS " if r[0] else "  FAIL ") + r[1])
	var ok := passed == _results.size()
	print("\n[CombatAnimSelfTest] %d/%d checks passed — %s" % [passed, _results.size(), "ALL PASS" if ok else "FAILURES"])
	await get_tree().create_timer(0.1).timeout
	get_tree().quit(0 if ok else 1)

func _check(c: bool, label: String) -> void:
	_results.append([c, label])

func _make_actor(actor_name: String) -> CharacterBase:
	var n := CharacterBase.new()
	n.name = actor_name
	var spr := AnimatedSprite2D.new()
	spr.name = "AnimatedSprite2D"           # CharacterBase._ready looks up this node
	var sf := SpriteFrames.new()            # has a "default" animation by default
	sf.add_frame("default", PlaceholderTexture2D.new())
	spr.sprite_frames = sf
	spr.animation = "default"
	n.add_child(spr)
	add_child(n)                            # triggers CharacterBase._ready (no data = defaults)
	return n

func _run() -> void:
	var a := _make_actor("Healer")
	var b := _make_actor("Ally")

	# The exact regression: the heal animation must COMPLETE (not hang on an
	# already-finished tween) and hand the overlay back.
	await AttackAnimationOverlay.play_heal_animation(a, b, 4)
	_check(not AttackAnimationOverlay._is_playing, "heal animation completes and releases the overlay")

	# Attack path still completes (unchanged, but verify the shared overlay is sane).
	await AttackAnimationOverlay.play_attack_animation(a, b, 5, false)
	_check(not AttackAnimationOverlay._is_playing, "attack animation completes and releases the overlay")

	# Back-to-back heal proves no stuck state lingers between plays.
	await AttackAnimationOverlay.play_heal_animation(a, b, 3)
	_check(not AttackAnimationOverlay._is_playing, "second heal completes (no stuck _is_playing)")
