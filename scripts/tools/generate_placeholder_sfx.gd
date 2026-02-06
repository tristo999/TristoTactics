# Placeholder SFX Generator
# Run this script from Godot's Script Editor (File > Run) to generate
# simple placeholder WAV files in res://assets/audio/sfx/
#
# These are basic procedural sounds so you have something audible while
# developing. Replace them with real sound effects later.
@tool
extends EditorScript

const SFX_DIR := "res://assets/audio/sfx/"
const SAMPLE_RATE := 22050
const MIX_RATE := 22050

func _run() -> void:
	print("=== Generating Placeholder SFX ===")
	DirAccess.make_dir_recursive_absolute(SFX_DIR)
	
	# UI sounds
	_generate_wav("button_click", _make_click())
	_generate_wav("select", _make_select())
	
	# Movement
	_generate_wav("move", _make_move())
	
	# Combat
	_generate_wav("attack", _make_attack())
	_generate_wav("hit", _make_hit())
	_generate_wav("crit", _make_crit())
	_generate_wav("miss", _make_miss())
	
	# Status
	_generate_wav("death", _make_death())
	_generate_wav("heal", _make_heal())
	
	# Turn flow
	_generate_wav("turn_start", _make_turn_start())
	_generate_wav("enemy_turn", _make_enemy_turn())
	
	print("=== Done! %d SFX files generated in %s ===" % [11, SFX_DIR])

func _generate_wav(sfx_name: String, samples: PackedByteArray) -> void:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = samples
	
	var path := SFX_DIR + sfx_name + ".wav"
	var err := wav.save_to_wav(path)
	if err == OK:
		print("  Created: %s" % path)
	else:
		push_error("  Failed to save: %s (error %d)" % [path, err])

# -- Sound generators (8-bit signed samples, centered at 128) --

func _make_click() -> PackedByteArray:
	# Short sharp click - 30ms
	var length := int(MIX_RATE * 0.03)
	var samples := PackedByteArray()
	samples.resize(length)
	for i in length:
		var t := float(i) / MIX_RATE
		var env := 1.0 - (float(i) / length)
		var val := sin(t * 3000.0 * TAU) * env * 0.6
		samples[i] = int(clamp(val * 127.0 + 128.0, 0, 255))
	return samples

func _make_select() -> PackedByteArray:
	# Rising two-tone blip - 100ms
	var length := int(MIX_RATE * 0.1)
	var samples := PackedByteArray()
	samples.resize(length)
	for i in length:
		var t := float(i) / MIX_RATE
		var progress := float(i) / length
		var freq: float = lerp(600.0, 900.0, progress)
		var env := 1.0 - progress
		var val := sin(t * freq * TAU) * env * 0.5
		samples[i] = int(clamp(val * 127.0 + 128.0, 0, 255))
	return samples

func _make_move() -> PackedByteArray:
	# Soft shuffle/step sound - 80ms
	var length := int(MIX_RATE * 0.08)
	var samples := PackedByteArray()
	samples.resize(length)
	for i in length:
		var t := float(i) / MIX_RATE
		var env := (1.0 - float(i) / length) * 0.3
		# Low noise-like texture with a soft thud
		var val := sin(t * 200.0 * TAU) * env + sin(t * 350.0 * TAU) * env * 0.5
		samples[i] = int(clamp(val * 127.0 + 128.0, 0, 255))
	return samples

func _make_attack() -> PackedByteArray:
	# Swoosh/swing sound - 150ms
	var length := int(MIX_RATE * 0.15)
	var samples := PackedByteArray()
	samples.resize(length)
	for i in length:
		var t := float(i) / MIX_RATE
		var progress := float(i) / length
		# Descending frequency sweep for swoosh feel
		var freq: float = lerp(1200.0, 300.0, progress)
		var env := sin(progress * PI) * 0.6  # Bell curve envelope
		var val := sin(t * freq * TAU) * env
		samples[i] = int(clamp(val * 127.0 + 128.0, 0, 255))
	return samples

func _make_hit() -> PackedByteArray:
	# Impact thud - 120ms
	var length := int(MIX_RATE * 0.12)
	var samples := PackedByteArray()
	samples.resize(length)
	for i in length:
		var t := float(i) / MIX_RATE
		var progress := float(i) / length
		var env := (1.0 - progress) * 0.7
		# Low frequency impact with some grit
		var val := sin(t * 150.0 * TAU) * env + sin(t * 80.0 * TAU) * env * 0.5
		samples[i] = int(clamp(val * 127.0 + 128.0, 0, 255))
	return samples

func _make_crit() -> PackedByteArray:
	# Louder, punchier hit with high-frequency crack - 180ms
	var length := int(MIX_RATE * 0.18)
	var samples := PackedByteArray()
	samples.resize(length)
	for i in length:
		var t := float(i) / MIX_RATE
		var progress := float(i) / length
		var env := (1.0 - progress)
		# Sharp crack followed by impact
		var crack: float = sin(t * 2000.0 * TAU) * maxf(0.0, 1.0 - progress * 5.0) * 0.4
		var impact := sin(t * 120.0 * TAU) * env * 0.6
		var val: float = crack + impact
		samples[i] = int(clamp(val * 127.0 + 128.0, 0, 255))
	return samples

func _make_miss() -> PackedByteArray:
	# Soft whoosh that trails off - 200ms
	var length := int(MIX_RATE * 0.2)
	var samples := PackedByteArray()
	samples.resize(length)
	for i in length:
		var t := float(i) / MIX_RATE
		var progress := float(i) / length
		var freq: float = lerp(800.0, 200.0, progress)
		var env := (1.0 - progress) * 0.3
		var val := sin(t * freq * TAU) * env
		samples[i] = int(clamp(val * 127.0 + 128.0, 0, 255))
	return samples

func _make_death() -> PackedByteArray:
	# Descending tone that fades - 400ms
	var length := int(MIX_RATE * 0.4)
	var samples := PackedByteArray()
	samples.resize(length)
	for i in length:
		var t := float(i) / MIX_RATE
		var progress := float(i) / length
		var freq: float = lerp(500.0, 80.0, progress * progress)
		var env := (1.0 - progress) * 0.6
		var val := sin(t * freq * TAU) * env
		samples[i] = int(clamp(val * 127.0 + 128.0, 0, 255))
	return samples

func _make_heal() -> PackedByteArray:
	# Bright ascending sparkle - 250ms
	var length := int(MIX_RATE * 0.25)
	var samples := PackedByteArray()
	samples.resize(length)
	for i in length:
		var t := float(i) / MIX_RATE
		var progress := float(i) / length
		var freq: float = lerp(400.0, 1200.0, progress)
		var env := sin(progress * PI) * 0.5
		# Two harmonics for shimmer effect
		var val := sin(t * freq * TAU) * env + sin(t * freq * 1.5 * TAU) * env * 0.3
		samples[i] = int(clamp(val * 127.0 + 128.0, 0, 255))
	return samples

func _make_turn_start() -> PackedByteArray:
	# Pleasant chime - two ascending notes - 200ms
	var length := int(MIX_RATE * 0.2)
	var samples := PackedByteArray()
	samples.resize(length)
	for i in length:
		var t := float(i) / MIX_RATE
		var progress := float(i) / length
		var env := (1.0 - progress) * 0.5
		# Two notes: C then E
		var note: float
		if progress < 0.5:
			note = 523.25  # C5
		else:
			note = 659.25  # E5
		var val := sin(t * note * TAU) * env
		samples[i] = int(clamp(val * 127.0 + 128.0, 0, 255))
	return samples

func _make_enemy_turn() -> PackedByteArray:
	# Ominous low two descending notes - 200ms
	var length := int(MIX_RATE * 0.2)
	var samples := PackedByteArray()
	samples.resize(length)
	for i in length:
		var t := float(i) / MIX_RATE
		var progress := float(i) / length
		var env := (1.0 - progress) * 0.5
		var note: float
		if progress < 0.5:
			note = 330.0  # E4
		else:
			note = 262.0  # C4
		var val := sin(t * note * TAU) * env + sin(t * note * 0.5 * TAU) * env * 0.3
		samples[i] = int(clamp(val * 127.0 + 128.0, 0, 255))
	return samples
