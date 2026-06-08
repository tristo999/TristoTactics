# ComboSystem reaction-stack test. Verifies follow-ups resolve SEQUENTIALLY and on a
# stack: pushed reactions drain LIFO, and a reaction triggered by another reaction
# (a cascade) resolves before older pending entries (depth-first). Headless-safe.
extends Node

# A fake follow-up that logs its id when it resolves, and can push a cascade.
class _LogFollow extends FollowUp:
	var log_ref: Array
	var id: String
	var trig: int
	var cascade: Callable = Callable()
	func reacts_to() -> Trigger:
		return trig as Trigger
	func is_eligible(_owner, _ctx: Dictionary) -> bool:
		return true
	func resolve(_owner, _ctx: Dictionary) -> void:
		log_ref.append(id)
		if cascade.is_valid():
			cascade.call()

var _results: Array = []

func _ready() -> void:
	await _run()
	var passed := 0
	for r in _results:
		if r[0]:
			passed += 1
		print(("  PASS " if r[0] else "  FAIL ") + r[1])
	var ok := passed == _results.size()
	print("\n[ComboStackSelfTest] %d/%d checks passed — %s" % [passed, _results.size(), "ALL PASS" if ok else "FAILURES"])
	await get_tree().create_timer(0.1).timeout
	get_tree().quit(0 if ok else 1)

func _check(c: bool, label: String) -> void:
	_results.append([c, label])

func _run() -> void:
	var log: Array = []

	# A reacts to trigger 0, B to 1 (and cascades a push of trigger 2), C to 2.
	var fa := _LogFollow.new(); fa.log_ref = log; fa.id = "A"; fa.trig = 0
	var fb := _LogFollow.new(); fb.log_ref = log; fb.id = "B"; fb.trig = 1
	fb.cascade = func() -> void: ComboSystem._push(2, {})
	var fc := _LogFollow.new(); fc.log_ref = log; fc.id = "C"; fc.trig = 2

	var cd := CharacterData.new()
	cd.follow_ups = [fa, fb, fc] as Array[FollowUp]
	var unit := CharacterBase.new()
	unit.character_data = cd
	add_child(unit)                      # joins GROUP_ALL_CHARACTERS; alive at default HP
	await get_tree().process_frame

	# Empty drain is a safe no-op.
	await ComboSystem.resolve_reactions()
	_check(log.is_empty(), "draining an empty stack is a no-op")

	# Push A then B. LIFO → B resolves first; B cascades C, which resolves before A.
	ComboSystem._push(0, {})
	ComboSystem._push(1, {})
	await ComboSystem.resolve_reactions()
	_check(log == ["B", "C", "A"],
		"reactions resolve LIFO with cascades depth-first (got %s)" % str(log))

	unit.queue_free()
