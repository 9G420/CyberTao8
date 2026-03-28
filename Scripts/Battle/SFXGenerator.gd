# ============================================================
# SFXGenerator.gd - Procedural Audio Engine
# Theme: Retro 8bit Chiptune + Cyberpunk Synthwave + EVA Dark Ambient
# Runtime-generated sound effects and BGM loops, no external audio files
# ============================================================
class_name SFXGenerator
extends RefCounted

# ---- Constants ----
const SR: int = 22050
const TWO_PI: float = TAU

# ---- Helper: oscillator functions ----

## Square wave with variable duty cycle
static func _square(phase: float, duty: float = 0.5) -> float:
	return 1.0 if fmod(phase, 1.0) < duty else -1.0

## Saw wave (naive, band-limited enough for 8bit)
static func _saw(phase: float) -> float:
	return 2.0 * fmod(phase, 1.0) - 1.0

## Triangle wave
static func _tri(phase: float) -> float:
	var p: float = fmod(phase, 1.0)
	return 4.0 * absf(p - 0.5) - 1.0

## Sine wave from phase (0-1 range per cycle)
static func _sine(phase: float) -> float:
	return sin(phase * TWO_PI)

## Pulse wave with PWM
static func _pulse(phase: float, width: float) -> float:
	return 1.0 if fmod(phase, 1.0) < width else -1.0

## Noise generator - deterministic from seed index for consistency
static func _noise_from_index(idx: int) -> float:
	# Simple hash-based noise for determinism in BGM loops
	var h: int = ((idx * 1103515245 + 12345) >> 16) & 0x7FFF
	return float(h) / 16383.5 - 1.0

## ADSR envelope helper
static func _adsr(t: float, duration: float, attack: float, decay: float, sustain: float, release: float) -> float:
	var rel_start: float = duration - release
	if t < attack:
		return t / attack
	elif t < attack + decay:
		return 1.0 - (1.0 - sustain) * ((t - attack) / decay)
	elif t < rel_start:
		return sustain
	else:
		return sustain * maxf(0.0, 1.0 - (t - rel_start) / release)

## Soft clipping / saturation
static func _saturate(val: float, drive: float = 1.0) -> float:
	var x: float = val * drive
	return x / (1.0 + absf(x))

## Convert float sample to 8-bit byte
static func _to_byte(val: float) -> int:
	return int(clampf(val * 127.0 + 128.0, 0.0, 255.0))

## Create a finalized AudioStreamWAV from data
static func _make_stream(data: PackedByteArray, is_loop: bool = false) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = SR
	stream.stereo = false
	stream.data = data
	if is_loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = data.size()
	return stream

# ---- Legacy helper (kept for compatibility) ----
static func generate_square_wave(frequency: float, duration: float, volume: float = 0.3, sample_rate: int = 22050) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	var num_samples: int = int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples)
	var period: float = sample_rate / frequency
	for i in num_samples:
		var t: float = float(i)
		var val: float = 1.0 if fmod(t, period) < period / 2.0 else -1.0
		var envelope: float = 1.0 - (float(i) / float(num_samples))
		val *= volume * envelope
		data[i] = int(clampf(val * 127.0 + 128.0, 0.0, 255.0))
	stream.data = data
	return stream

# ============================================================
# 1. ATTACK SFX - Impactful: freq sweep + distortion + punch
# ============================================================
static func generate_attack_sfx() -> AudioStreamWAV:
	var duration: float = 0.3
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	var phase1: float = 0.0
	var phase2: float = 0.0
	for i in num_samples:
		var t: float = float(i) / float(SR)
		var p: float = float(i) / float(num_samples)
		# Punch: fast exponential decay on low freq
		var punch_env: float = exp(-p * 20.0)
		var punch_freq: float = lerpf(180.0, 50.0, minf(p * 3.0, 1.0))
		phase1 += punch_freq / float(SR)
		var punch: float = _sine(phase1) * punch_env * 0.5
		# Main sweep: 900Hz -> 120Hz square with PWM
		var sweep_freq: float = lerpf(900.0, 120.0, p * p)
		phase2 += sweep_freq / float(SR)
		var duty: float = lerpf(0.5, 0.2, p)
		var sweep_env: float = _adsr(t, duration, 0.005, 0.05, 0.6, 0.1)
		var sweep: float = _pulse(phase2, duty) * sweep_env * 0.35
		# Noise burst at start
		var noise_env: float = exp(-p * 15.0)
		var noise: float = _noise_from_index(i) * noise_env * 0.25
		# Distorted mix
		var mix: float = _saturate(punch + sweep + noise, 2.0)
		data[i] = _to_byte(mix * 0.7)
	return _make_stream(data)

# ============================================================
# 2. DEFENSE SFX - Resonant shield: rising harmonics + metallic ring
# ============================================================
static func generate_defense_sfx() -> AudioStreamWAV:
	var duration: float = 0.35
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	var phase1: float = 0.0
	var phase2: float = 0.0
	var phase3: float = 0.0
	for i in num_samples:
		var t: float = float(i) / float(SR)
		var p: float = float(i) / float(num_samples)
		var env: float = _adsr(t, duration, 0.01, 0.08, 0.5, 0.15)
		# Rising fundamental
		var freq1: float = lerpf(300.0, 800.0, p * p)
		phase1 += freq1 / float(SR)
		var osc1: float = _tri(phase1) * 0.3
		# Metallic harmonic (inharmonic ratio ~2.76)
		var freq2: float = freq1 * 2.76
		phase2 += freq2 / float(SR)
		var osc2: float = _sine(phase2) * 0.15 * exp(-p * 5.0)
		# High shimmer
		var freq3: float = freq1 * 5.04
		phase3 += freq3 / float(SR)
		var osc3: float = _sine(phase3) * 0.08 * exp(-p * 8.0)
		# Resonant filter simulation via feedback
		var mix: float = (osc1 + osc2 + osc3) * env
		data[i] = _to_byte(mix * 0.8)
	return _make_stream(data)

# ============================================================
# 3. DRAW SFX - Card flip: quick sweep + click
# ============================================================
static func generate_draw_sfx() -> AudioStreamWAV:
	var duration: float = 0.15
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	var phase1: float = 0.0
	for i in num_samples:
		var t: float = float(i) / float(SR)
		var p: float = float(i) / float(num_samples)
		# Initial click transient
		var click_env: float = exp(-p * 60.0)
		var click: float = _noise_from_index(i) * click_env * 0.4
		# Quick upward sweep
		var sweep_freq: float = lerpf(800.0, 2500.0, p)
		phase1 += sweep_freq / float(SR)
		var sweep_env: float = _adsr(t, duration, 0.005, 0.03, 0.3, 0.05)
		var sweep: float = _tri(phase1) * sweep_env * 0.25
		# Subtle tail tone
		var tail: float = _sine(phase1 * 0.5) * exp(-p * 12.0) * 0.1
		var mix: float = click + sweep + tail
		data[i] = _to_byte(mix * 0.8)
	return _make_stream(data)

# ============================================================
# 4. RESONANCE SFX - Ethereal harmony: major chord arpeggio + reverb-like decay + bell overtones
# ============================================================
static func generate_resonance_sfx() -> AudioStreamWAV:
	var duration: float = 1.2
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	# C5=523, E5=659, G5=784 arpeggio with staggered entry
	var freqs: Array[float] = [523.0, 659.0, 784.0, 1047.0]
	var phases: Array[float] = [0.0, 0.0, 0.0, 0.0]
	var bell_phases: Array[float] = [0.0, 0.0, 0.0, 0.0]
	var entry_times: Array[float] = [0.0, 0.12, 0.24, 0.36]
	for i in num_samples:
		var t: float = float(i) / float(SR)
		var p: float = float(i) / float(num_samples)
		var mix: float = 0.0
		for n in 4:
			if t < entry_times[n]:
				continue
			var local_t: float = t - entry_times[n]
			var note_env: float = exp(-local_t * 2.5) * 0.2
			# Main tone (triangle for warmth)
			phases[n] += freqs[n] / float(SR)
			mix += _tri(phases[n]) * note_env
			# Bell overtone (inharmonic)
			bell_phases[n] += (freqs[n] * 2.414) / float(SR)
			mix += _sine(bell_phases[n]) * note_env * 0.3 * exp(-local_t * 5.0)
		# Subtle vibrato LFO
		var vib: float = sin(t * 5.0 * TWO_PI) * 0.02
		mix *= (1.0 + vib)
		# Reverb-like tail: feed delayed energy
		var reverb_tail: float = 0.0
		if i > 4000:
			var d_idx: int = i - 4000
			reverb_tail = _sine(float(d_idx) * 0.01) * exp(-p * 3.0) * 0.05
		mix += reverb_tail
		data[i] = _to_byte(clampf(mix, -1.0, 1.0) * 0.85)
	return _make_stream(data)

# ============================================================
# 5. BACKLASH SFX - Terrifying glitch: bitcrushed noise + dissonant frequencies + alarm
# ============================================================
static func generate_backlash_sfx() -> AudioStreamWAV:
	var duration: float = 0.5
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	var phase_alarm: float = 0.0
	var phase_dis1: float = 0.0
	var phase_dis2: float = 0.0
	for i in num_samples:
		var t: float = float(i) / float(SR)
		var _p: float = float(i) / float(num_samples)
		var env: float = _adsr(t, duration, 0.005, 0.05, 0.8, 0.15)
		# Bitcrushed noise (sample-and-hold at low rate)
		var crush_rate: int = 6
		@warning_ignore("integer_division")
		var noise_idx: int = (i / crush_rate) * crush_rate
		var noise: float = _noise_from_index(noise_idx) * 0.35
		# Dissonant tone pair (tritone)
		phase_dis1 += 185.0 / float(SR)
		phase_dis2 += 261.6 / float(SR)  # b5 interval
		var dissonance: float = (_square(phase_dis1, 0.3) + _square(phase_dis2, 0.7)) * 0.15
		# Alarm tone - alternating pitch
		var alarm_freq: float = 880.0 if fmod(t, 0.1) < 0.05 else 660.0
		phase_alarm += alarm_freq / float(SR)
		var alarm: float = _square(phase_alarm, 0.5) * 0.12 * (0.5 + 0.5 * sin(t * 20.0 * TWO_PI))
		# Gate effect - periodic cuts
		var gate: float = 1.0 if fmod(float(i), 800.0) < 500.0 else 0.2
		var mix: float = (noise + dissonance + alarm) * env * gate
		# Extra distortion
		mix = _saturate(mix, 3.0)
		data[i] = _to_byte(mix * 0.7)
	return _make_stream(data)

# ============================================================
# 6. BELL SFX - Deep Taoist temple bell: rich harmonics + long decay + subtle vibrato
# ============================================================
static func generate_bell_sfx() -> AudioStreamWAV:
	var duration: float = 2.0
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	# Temple bell partials (inharmonic, typical of struck bells)
	# Ratios based on real bell spectra: 1.0, 2.0, 2.414, 3.0, 4.236, 5.0
	var partial_ratios: Array[float] = [1.0, 2.0, 2.414, 3.0, 4.236, 5.0]
	var partial_amps: Array[float] = [0.35, 0.2, 0.15, 0.1, 0.06, 0.04]
	var partial_decays: Array[float] = [2.0, 3.0, 4.0, 5.0, 7.0, 9.0]
	var fundamental: float = 180.0  # Deep bell
	var phases: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	for i in num_samples:
		var t: float = float(i) / float(SR)
		var p: float = float(i) / float(num_samples)
		# Vibrato (slow, subtle, increases over time)
		var vib_depth: float = lerpf(0.0, 0.008, minf(p * 2.0, 1.0))
		var vib: float = sin(t * 4.5 * TWO_PI) * vib_depth
		var mix: float = 0.0
		for n in 6:
			var freq: float = fundamental * partial_ratios[n] * (1.0 + vib)
			phases[n] += freq / float(SR)
			var partial_env: float = exp(-t * partial_decays[n])
			mix += _sine(phases[n]) * partial_amps[n] * partial_env
		# Strike transient
		var strike: float = _noise_from_index(i) * exp(-t * 40.0) * 0.15
		mix += strike
		data[i] = _to_byte(mix * 0.8)
	return _make_stream(data)

# ============================================================
# 7. VICTORY SFX - Triumphant ascending arpeggio
# ============================================================
static func generate_victory_sfx() -> AudioStreamWAV:
	var duration: float = 1.5
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	# C5-E5-G5-C6 arpeggio, then full chord with cymbal
	var notes: Array[float] = [523.0, 659.0, 784.0, 1047.0]
	var note_dur: float = 0.2  # Each note duration
	var chord_start: float = 0.8
	var phases: Array[float] = [0.0, 0.0, 0.0, 0.0]
	var arp_phase: float = 0.0
	for i in num_samples:
		var t: float = float(i) / float(SR)
		var _p: float = float(i) / float(num_samples)
		var mix: float = 0.0
		# Arpeggio phase (first 0.8s)
		if t < chord_start:
			var note_idx: int = mini(int(t / note_dur), 3)
			var note_t: float = t - float(note_idx) * note_dur
			var freq: float = notes[note_idx]
			arp_phase += freq / float(SR)
			var note_env: float = _adsr(note_t, note_dur, 0.005, 0.03, 0.7, 0.05)
			# Rich square + triangle layered
			mix += _square(arp_phase, 0.4) * 0.2 * note_env
			mix += _tri(arp_phase) * 0.15 * note_env
			# Octave shimmer
			mix += _sine(arp_phase * 2.0) * 0.05 * note_env
		# Full chord phase
		if t >= chord_start:
			var chord_t: float = t - chord_start
			var chord_env: float = exp(-chord_t * 2.0)
			for n in 4:
				phases[n] += notes[n] / float(SR)
				mix += _tri(phases[n]) * 0.12 * chord_env
				mix += _sine(phases[n] * 2.0) * 0.04 * chord_env
			# Cymbal shimmer
			var cymbal: float = _noise_from_index(i) * exp(-chord_t * 4.0) * 0.15
			# Metallic shimmer on cymbal
			cymbal += _sine(float(i) * 6000.0 / float(SR)) * exp(-chord_t * 6.0) * 0.05
			mix += cymbal
		data[i] = _to_byte(clampf(mix, -1.0, 1.0) * 0.8)
	return _make_stream(data)

# ============================================================
# 8. DEFEAT SFX - Devastating: chromatic descent + bit-crushed ending + low rumble
# ============================================================
static func generate_defeat_sfx() -> AudioStreamWAV:
	var duration: float = 1.2
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	# Chromatic descent: E4-Eb4-D4-Db4-C4-B3-Bb3-A3
	var descent_notes: Array[float] = [329.6, 311.1, 293.7, 277.2, 261.6, 246.9, 233.1, 220.0]
	var note_dur: float = 0.1
	var phase_main: float = 0.0
	var phase_rumble: float = 0.0
	for i in num_samples:
		var t: float = float(i) / float(SR)
		var p: float = float(i) / float(num_samples)
		var mix: float = 0.0
		# Chromatic descent (first 0.8s)
		if t < 0.8:
			var note_idx: int = mini(int(t / note_dur), 7)
			var freq: float = descent_notes[note_idx]
			phase_main += freq / float(SR)
			var note_t: float = t - float(note_idx) * note_dur
			var note_env: float = _adsr(note_t, note_dur, 0.005, 0.02, 0.6, 0.02)
			# Increasingly harsh: duty cycle narrows
			var duty: float = lerpf(0.5, 0.15, p)
			mix += _pulse(phase_main, duty) * 0.3 * note_env
			mix += _saw(phase_main * 0.5) * 0.1 * note_env
		# Bitcrushed tail (0.6s onward, overlapping)
		if t > 0.6:
			var crush_p: float = (t - 0.6) / 0.6
			var crush_rate: int = int(lerpf(2.0, 12.0, crush_p))
			crush_rate = maxi(crush_rate, 1)
			@warning_ignore("integer_division")
			var crush_idx: int = (i / crush_rate) * crush_rate
			var crushed: float = _noise_from_index(crush_idx) * 0.2
			# Decaying envelope
			var crush_env: float = exp(-crush_p * 3.0)
			mix += crushed * crush_env
		# Low rumble throughout
		phase_rumble += 45.0 / float(SR)
		var rumble_env: float = lerpf(0.05, 0.2, p) * (1.0 - p * 0.5)
		mix += _sine(phase_rumble) * rumble_env
		# Sub bass hit
		mix += _sine(phase_rumble * 0.5) * exp(-t * 3.0) * 0.15
		data[i] = _to_byte(_saturate(mix, 1.5) * 0.75)
	return _make_stream(data)

# ============================================================
# 9. CYBER GLITCH SFX - Digital corruption: random freq jumps + gate + static
# ============================================================
static func generate_cyber_glitch_sfx() -> AudioStreamWAV:
	var duration: float = 0.4
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	var phase1: float = 0.0
	var phase2: float = 0.0
	var current_freq: float = 440.0
	var freq_hold_counter: int = 0
	for i in num_samples:
		var t: float = float(i) / float(SR)
		var p: float = float(i) / float(num_samples)
		var env: float = _adsr(t, duration, 0.002, 0.02, 0.7, 0.1)
		# Random frequency jumps every ~30-80 samples
		freq_hold_counter += 1
		if freq_hold_counter > 30 + (i * 37 + 7) % 50:
			freq_hold_counter = 0
			# Pick from random set of frequencies
			var freq_options: Array[float] = [220.0, 440.0, 880.0, 1320.0, 1760.0, 110.0, 660.0]
			var idx: int = (i * 7 + 13) % freq_options.size()
			current_freq = freq_options[idx]
		phase1 += current_freq / float(SR)
		# Gate effect: periodic on/off
		var gate_period: float = lerpf(600.0, 200.0, p)
		var gate: float = 1.0 if fmod(float(i), gate_period) < gate_period * 0.6 else 0.0
		# Main tone
		var tone: float = _square(phase1, 0.3) * 0.25
		# Static bursts
		var burst_trig: float = 1.0 if fmod(t, 0.08) < 0.02 else 0.0
		var static_burst: float = _noise_from_index(i) * burst_trig * 0.3
		# Digital artifact - aliased high frequency
		phase2 += 5500.0 / float(SR)
		var artifact: float = _square(phase2, 0.1) * 0.06 * (0.5 + 0.5 * sin(t * 30.0 * TWO_PI))
		var mix: float = (tone * gate + static_burst + artifact) * env
		data[i] = _to_byte(_saturate(mix, 2.0) * 0.7)
	return _make_stream(data)

# ============================================================
# 10. CLICK SFX - Crisp UI click: short bright tone
# ============================================================
static func generate_click_sfx() -> AudioStreamWAV:
	var duration: float = 0.06
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	var phase1: float = 0.0
	for i in num_samples:
		var _t: float = float(i) / float(SR)
		var p: float = float(i) / float(num_samples)
		# Sharp transient
		var click_env: float = exp(-p * 30.0)
		phase1 += 2200.0 / float(SR)
		var tone: float = _tri(phase1) * click_env * 0.3
		# Tiny noise burst
		var noise: float = _noise_from_index(i) * exp(-p * 50.0) * 0.15
		var mix: float = tone + noise
		data[i] = _to_byte(mix * 0.8)
	return _make_stream(data)

# ============================================================
# 11. BATTLE BGM LOOP - Nintendo-style 8bit, Dm, 140 BPM, 4s
# Square melody + triangle bass + pulse arp + noise drums
# Clean chiptune like Pokemon battle / Megaman
# ============================================================
static func generate_battle_bgm_loop() -> AudioStreamWAV:
	var bpm: float = 140.0
	var duration: float = 4.0  # ~9.3 beats
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	var beat_len: float = 60.0 / bpm
	var sixteenth: float = beat_len * 0.25
	# Melody (square): 16th notes, Dm pentatonic, 0=rest
	# D4=293.7 F4=349.2 G4=392.0 A4=440.0 C5=523.3 D5=587.3
	var mel: Array[float] = [
		293.7, 0.0, 349.2, 293.7, 440.0, 0.0, 392.0, 0.0,
		349.2, 0.0, 293.7, 0.0, 523.3, 440.0, 392.0, 349.2,
		293.7, 0.0, 440.0, 0.0, 587.3, 0.0, 523.3, 440.0,
		392.0, 349.2, 293.7, 0.0, 349.2, 392.0, 293.7, 0.0,
		440.0, 0.0, 523.3, 440.0
	]
	# Bass (triangle): quarter notes, D2=73.4 A2=110 Bb2=116.5 C3=130.8
	var bass: Array[float] = [73.4, 73.4, 110.0, 110.0, 116.5, 116.5, 130.8, 110.0, 73.4, 73.4]
	var phase_mel: float = 0.0
	var phase_bass: float = 0.0
	var phase_arp: float = 0.0
	var phase_kick: float = 0.0
	for i in num_samples:
		var t: float = float(i) / float(SR)
		var beat_f: float = t / beat_len
		var beat_pos: float = fmod(beat_f, 1.0)
		var sixteenth_f: float = t / sixteenth
		var six_idx: int = int(sixteenth_f) % mel.size()
		var six_pos: float = fmod(sixteenth_f, 1.0)
		var beat_idx: int = int(beat_f) % bass.size()
		var mix: float = 0.0
		# --- Square melody (25% duty, classic NES lead) ---
		var mf: float = mel[six_idx]
		if mf > 0.0:
			phase_mel += mf / float(SR)
			var mel_env: float = _adsr(six_pos * sixteenth, sixteenth, 0.003, 0.02, 0.7, 0.02)
			mix += _square(phase_mel, 0.25) * mel_env * 0.18
		# --- Triangle bass ---
		var bf: float = bass[beat_idx]
		phase_bass += bf / float(SR)
		var bass_env: float = _adsr(beat_pos * beat_len, beat_len, 0.005, 0.03, 0.8, 0.03)
		mix += _tri(phase_bass) * bass_env * 0.22
		# --- Pulse arpeggio (fast 16th note arps on chord tones) ---
		# Dm chord: D4=293.7 F4=349.2 A4=440.0
		var arp_notes: Array[float] = [293.7, 349.2, 440.0]
		var arp_idx: int = int(sixteenth_f) % arp_notes.size()
		phase_arp += arp_notes[arp_idx] / float(SR)
		var arp_env: float = _adsr(six_pos * sixteenth, sixteenth, 0.003, 0.01, 0.4, 0.01)
		mix += _pulse(phase_arp, 0.125) * arp_env * 0.06
		# --- Noise drums (kick + snare + hat) ---
		# Kick on 1 and 3
		if (beat_idx % 2 == 0) and beat_pos < 0.08:
			var kick_env: float = exp(-beat_pos * 50.0) * 0.18
			var kf: float = lerpf(160.0, 50.0, minf(beat_pos * 10.0, 1.0))
			phase_kick += kf / float(SR)
			mix += _tri(phase_kick) * kick_env
		# Snare on 2 and 4
		if (beat_idx % 2 == 1) and beat_pos < 0.10:
			var snr_env: float = exp(-beat_pos * 30.0) * 0.10
			mix += _noise_from_index(i) * snr_env
		# Hi-hat on every 8th
		var eighth_pos: float = fmod(beat_f * 2.0, 1.0)
		var hh_env: float = exp(-eighth_pos * 60.0) * 0.03
		mix += _noise_from_index(i + 7777) * hh_env
		# --- Clean output ---
		data[i] = _to_byte(clampf(mix, -0.95, 0.95) * 0.55)
	return _make_stream(data, true)

# ============================================================
# 12. TITLE BGM LOOP - Mysterious 8bit, Am, 90 BPM, 6s
# Clean square melody + triangle bass + gentle pulse pad
# Dark but melodic like Pokemon Lavender Town / Castlevania menu
# ============================================================
static func generate_title_bgm_loop() -> AudioStreamWAV:
	var bpm: float = 90.0
	var duration: float = 6.0
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	var beat_len: float = 60.0 / bpm
	var eighth: float = beat_len * 0.5
	# Melody (square 12.5% duty): 8th notes, Am scale, haunting
	# A4=440 B4=493.9 C5=523.3 D5=587.3 E5=659.3 F5=698.5 G4=392 E4=329.6
	var mel: Array[float] = [
		440.0, 0.0, 523.3, 0.0, 493.9, 440.0, 0.0, 0.0,
		392.0, 0.0, 329.6, 0.0, 392.0, 440.0, 0.0, 0.0,
		523.3, 0.0, 587.3, 523.3, 493.9, 0.0, 440.0, 0.0,
		392.0, 329.6, 392.0, 0.0, 0.0, 0.0, 0.0, 0.0
	]
	# Bass (triangle): half notes, Am-F-Dm-E
	# A2=110 F2=87.3 D2=73.4 E2=82.4
	var bass_notes: Array[float] = [110.0, 110.0, 87.3, 87.3, 73.4, 73.4, 82.4, 82.4, 110.0, 110.0, 87.3, 87.3, 73.4, 82.4]
	var phase_mel: float = 0.0
	var phase_bass: float = 0.0
	var phase_pad1: float = 0.0
	var phase_pad2: float = 0.0
	for i in num_samples:
		var t: float = float(i) / float(SR)
		var beat_f: float = t / beat_len
		var beat_pos: float = fmod(beat_f, 1.0)
		var eighth_f: float = t / eighth
		var ei: int = int(eighth_f) % mel.size()
		var epos: float = fmod(eighth_f, 1.0)
		var bass_idx: int = int(beat_f) % bass_notes.size()
		var mix: float = 0.0
		# --- Square melody (12.5% duty = thin, haunting NES sound) ---
		var mf: float = mel[ei]
		if mf > 0.0:
			phase_mel += mf / float(SR)
			var mel_env: float = _adsr(epos * eighth, eighth, 0.005, 0.04, 0.6, 0.04)
			mix += _square(phase_mel, 0.125) * mel_env * 0.16
		# --- Triangle bass ---
		phase_bass += bass_notes[bass_idx] / float(SR)
		var bass_env: float = _adsr(beat_pos * beat_len, beat_len, 0.005, 0.05, 0.7, 0.05)
		mix += _tri(phase_bass) * bass_env * 0.18
		# --- Quiet pad: Am chord (A3=220, C4=261.6) with slow pulse ---
		phase_pad1 += 220.0 / float(SR)
		phase_pad2 += 261.6 / float(SR)
		var pad_vol: float = 0.03 + 0.015 * sin(t * 0.8 * TWO_PI)
		mix += _pulse(phase_pad1, 0.125) * pad_vol
		mix += _pulse(phase_pad2, 0.125) * pad_vol * 0.7
		# --- Clean output ---
		data[i] = _to_byte(clampf(mix, -0.95, 0.95) * 0.50)
	return _make_stream(data, true)

# ============================================================
# 13. MAP BGM LOOP - Calm exploration 8bit, Am, 100 BPM, 4s
# Triangle melody + triangle bass + light pulse harmony
# Gentle but slightly melancholic, like Pokemon route music
# ============================================================
static func generate_map_bgm_loop() -> AudioStreamWAV:
	var bpm: float = 100.0
	var duration: float = 4.0
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	var beat_len: float = 60.0 / bpm
	var eighth: float = beat_len * 0.5
	# Melody (square 25%): 8th notes, Am pentatonic, gentle walking feel
	# A4=440 C5=523.3 D5=587.3 E5=659.3 G4=392 E4=329.6
	var mel: Array[float] = [
		440.0, 523.3, 587.3, 523.3, 440.0, 0.0, 392.0, 440.0,
		329.6, 0.0, 392.0, 440.0, 523.3, 0.0, 440.0, 392.0
	]
	# Bass (triangle): quarter notes walking
	# A2=110 C3=130.8 E2=82.4 G2=98.0
	var bass: Array[float] = [110.0, 130.8, 82.4, 98.0, 110.0, 82.4, 130.8, 98.0]
	var phase_mel: float = 0.0
	var phase_bass: float = 0.0
	var phase_harm: float = 0.0
	for i in num_samples:
		var t: float = float(i) / float(SR)
		var beat_f: float = t / beat_len
		var beat_pos: float = fmod(beat_f, 1.0)
		var eighth_f: float = t / eighth
		var ei: int = int(eighth_f) % mel.size()
		var epos: float = fmod(eighth_f, 1.0)
		var bass_idx: int = int(beat_f) % bass.size()
		var mix: float = 0.0
		# --- Square melody ---
		var mf: float = mel[ei]
		if mf > 0.0:
			phase_mel += mf / float(SR)
			var mel_env: float = _adsr(epos * eighth, eighth, 0.005, 0.03, 0.65, 0.04)
			mix += _square(phase_mel, 0.25) * mel_env * 0.14
		# --- Triangle bass ---
		phase_bass += bass[bass_idx] / float(SR)
		var bass_env: float = _adsr(beat_pos * beat_len, beat_len, 0.005, 0.04, 0.7, 0.04)
		mix += _tri(phase_bass) * bass_env * 0.20
		# --- Light harmony (pulse 12.5%, 3rd above bass) ---
		var harm_freq: float = bass[bass_idx] * 2.5  # ~major 3rd up an octave
		phase_harm += harm_freq / float(SR)
		var harm_env: float = _adsr(beat_pos * beat_len, beat_len, 0.01, 0.05, 0.3, 0.05)
		mix += _pulse(phase_harm, 0.125) * harm_env * 0.04
		# --- Minimal percussion: soft hi-hat on 8ths ---
		var hh_env: float = exp(-epos * 50.0) * 0.025
		mix += _noise_from_index(i + 3333) * hh_env
		# --- Clean output ---
		data[i] = _to_byte(clampf(mix, -0.95, 0.95) * 0.50)
	return _make_stream(data, true)

# ============================================================
# 14. BOSS BGM LOOP - Intense 8bit boss, Dm, 160 BPM, 4s
# Aggressive square melody + heavy triangle bass + fast drums
# Intense like Pokemon Gym Leader / Megaman boss
# ============================================================
static func generate_boss_bgm_loop() -> AudioStreamWAV:
	var bpm: float = 160.0
	var duration: float = 4.0
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	var beat_len: float = 60.0 / bpm
	var sixteenth: float = beat_len * 0.25
	# Melody (square 25%): 16th notes, Dm, aggressive phrases
	# D5=587.3 F5=698.5 A5=880.0 E5=659.3 C5=523.3 Bb4=466.2 G4=392.0
	var mel: Array[float] = [
		587.3, 587.3, 698.5, 587.3, 880.0, 0.0, 698.5, 659.3,
		587.3, 0.0, 523.3, 587.3, 698.5, 880.0, 698.5, 587.3,
		466.2, 0.0, 523.3, 466.2, 587.3, 0.0, 698.5, 0.0,
		880.0, 698.5, 587.3, 523.3, 587.3, 0.0, 466.2, 523.3,
		587.3, 698.5, 880.0, 698.5, 587.3, 0.0, 523.3, 587.3
	]
	# Bass (triangle): 8th notes, driving rhythm
	# D2=73.4 A2=110 Bb2=116.5 C3=130.8 F2=87.3
	var bass: Array[float] = [
		73.4, 73.4, 110.0, 110.0, 116.5, 130.8, 73.4, 73.4,
		87.3, 87.3, 110.0, 73.4, 116.5, 116.5, 130.8, 110.0,
		73.4, 73.4, 110.0, 110.0, 87.3, 87.3
	]
	var phase_mel: float = 0.0
	var phase_bass: float = 0.0
	var phase_kick: float = 0.0
	var phase_counter: float = 0.0
	for i in num_samples:
		var t: float = float(i) / float(SR)
		var beat_f: float = t / beat_len
		var beat_pos: float = fmod(beat_f, 1.0)
		var sixteenth_f: float = t / sixteenth
		var six_idx: int = int(sixteenth_f) % mel.size()
		var six_pos: float = fmod(sixteenth_f, 1.0)
		var eighth_f: float = beat_f * 2.0
		var eighth_idx: int = int(eighth_f) % bass.size()
		var eighth_pos: float = fmod(eighth_f, 1.0)
		var beat_idx: int = int(beat_f) % 8
		var mix: float = 0.0
		# --- Square melody (25% duty, loud) ---
		var mf: float = mel[six_idx]
		if mf > 0.0:
			phase_mel += mf / float(SR)
			var mel_env: float = _adsr(six_pos * sixteenth, sixteenth, 0.002, 0.015, 0.75, 0.015)
			mix += _square(phase_mel, 0.25) * mel_env * 0.18
		# --- Triangle bass (8th note rhythm) ---
		phase_bass += bass[eighth_idx] / float(SR)
		var bass_env: float = _adsr(eighth_pos * beat_len * 0.5, beat_len * 0.5, 0.003, 0.02, 0.8, 0.02)
		mix += _tri(phase_bass) * bass_env * 0.24
		# --- Counter melody (pulse 12.5%, octave below main) ---
		if mf > 0.0:
			phase_counter += (mf * 0.5) / float(SR)
			var ct_env: float = _adsr(six_pos * sixteenth, sixteenth, 0.003, 0.01, 0.35, 0.01)
			mix += _pulse(phase_counter, 0.125) * ct_env * 0.06
		# --- Drums: kick every beat, snare on 2/4, hat on every 16th ---
		if beat_pos < 0.06:
			var kick_env: float = exp(-beat_pos * 60.0) * 0.20
			var kf: float = lerpf(180.0, 50.0, minf(beat_pos * 12.0, 1.0))
			phase_kick += kf / float(SR)
			mix += _tri(phase_kick) * kick_env
		if (beat_idx % 2 == 1) and beat_pos < 0.08:
			var snr_env: float = exp(-beat_pos * 25.0) * 0.12
			mix += _noise_from_index(i) * snr_env
		# Hi-hat 16th notes
		var hh_env: float = exp(-six_pos * 70.0) * 0.025
		mix += _noise_from_index(i + 5555) * hh_env
		# --- Clean output ---
		data[i] = _to_byte(clampf(mix, -0.95, 0.95) * 0.55)
	return _make_stream(data, true)

# ============================================================
# 15. SUMMON SFX - Rising whoosh + crystalline chime
# ============================================================
static func generate_summon_sfx() -> AudioStreamWAV:
	var duration: float = 0.8
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	var phase_whoosh: float = 0.0
	var phase_chime1: float = 0.0
	var phase_chime2: float = 0.0
	var phase_chime3: float = 0.0
	for i in num_samples:
		var t: float = float(i) / float(SR)
		var p: float = float(i) / float(num_samples)
		var mix: float = 0.0
		# Rising whoosh: filtered noise with rising center freq
		var whoosh_env: float = sin(p * PI) * 0.3  # peaks in middle
		var whoosh_freq: float = lerpf(200.0, 3000.0, p * p)
		phase_whoosh += whoosh_freq / float(SR)
		# Use oscillator to modulate noise for "filtered" effect
		var whoosh_mod: float = (0.5 + 0.5 * _sine(phase_whoosh))
		var whoosh: float = _noise_from_index(i) * whoosh_mod * whoosh_env
		mix += whoosh
		# Crystalline chimes at end (t > 0.4)
		if t > 0.4:
			var chime_t: float = t - 0.4
			var chime_env: float = exp(-chime_t * 4.0) * 0.2
			phase_chime1 += 1047.0 / float(SR)  # C6
			phase_chime2 += 1318.5 / float(SR)  # E6
			phase_chime3 += 1568.0 / float(SR)  # G6
			mix += _sine(phase_chime1) * chime_env
			mix += _sine(phase_chime2) * chime_env * 0.7
			mix += _sine(phase_chime3) * chime_env * 0.5
			# Bell overtones
			mix += _sine(phase_chime1 * 2.414) * chime_env * 0.15
		data[i] = _to_byte(clampf(mix, -1.0, 1.0) * 0.8)
	return _make_stream(data)

# ============================================================
# 16. HEAL SFX - Gentle ascending tones + soft chime
# ============================================================
static func generate_heal_sfx() -> AudioStreamWAV:
	var duration: float = 0.6
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	# Ascending: C5, E5, G5 with overlap
	var heal_notes: Array[float] = [523.0, 659.0, 784.0]
	var note_start: Array[float] = [0.0, 0.15, 0.3]
	var phases: Array[float] = [0.0, 0.0, 0.0]
	for i in num_samples:
		var t: float = float(i) / float(SR)
		var mix: float = 0.0
		for n in 3:
			if t < note_start[n]:
				continue
			var nt: float = t - note_start[n]
			var note_env: float = exp(-nt * 5.0) * 0.18
			phases[n] += heal_notes[n] / float(SR)
			mix += _tri(phases[n]) * note_env
			# Soft overtone
			mix += _sine(phases[n] * 2.0) * note_env * 0.2
		# Final chime at 0.35
		if t > 0.35:
			var ct: float = t - 0.35
			var chime_env: float = exp(-ct * 6.0) * 0.12
			mix += _sine(float(i) * 1568.0 / float(SR)) * chime_env  # G6
			mix += _sine(float(i) * 1568.0 * 2.0 / float(SR)) * chime_env * 0.3
		data[i] = _to_byte(clampf(mix, -1.0, 1.0) * 0.85)
	return _make_stream(data)

# ============================================================
# 17. CARD HOVER SFX - Subtle: very short soft tone
# ============================================================
static func generate_card_hover_sfx() -> AudioStreamWAV:
	var duration: float = 0.04
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	var phase1: float = 0.0
	for i in num_samples:
		var p: float = float(i) / float(num_samples)
		var env: float = exp(-p * 20.0) * 0.15
		phase1 += 1800.0 / float(SR)
		var mix: float = _sine(phase1) * env
		data[i] = _to_byte(mix)
	return _make_stream(data)

# ============================================================
# 18. TRANSITION SFX - Scene transition: whoosh + digital sweep
# ============================================================
static func generate_transition_sfx() -> AudioStreamWAV:
	var duration: float = 0.5
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	var phase_sweep: float = 0.0
	for i in num_samples:
		var _t: float = float(i) / float(SR)
		var p: float = float(i) / float(num_samples)
		var mix: float = 0.0
		# Whoosh: noise with bandpass sweep
		var whoosh_env: float = sin(p * PI)
		var center_freq: float = lerpf(100.0, 4000.0, p)
		phase_sweep += center_freq / float(SR)
		var bp_mod: float = 0.5 + 0.5 * _sine(phase_sweep)
		mix += _noise_from_index(i) * bp_mod * whoosh_env * 0.3
		# Digital sweep: rising square
		var _sweep_freq: float = lerpf(200.0, 5000.0, p * p)
		mix += _square(phase_sweep, lerpf(0.5, 0.1, p)) * 0.1 * whoosh_env
		# Sub thump at start
		mix += _sine(float(i) * 80.0 / float(SR)) * exp(-p * 10.0) * 0.15
		data[i] = _to_byte(clampf(mix, -1.0, 1.0) * 0.8)
	return _make_stream(data)

# ============================================================
# 19. OPENING BGM LOOP - Dreamy cyberpunk 8bit, Am, 80 BPM, 8s
# Gentle triangle melody + sine pad chords + soft triangle bass
# Atmospheric and pleasant, like a lo-fi chiptune intro
# ============================================================
static func generate_opening_bgm_loop() -> AudioStreamWAV:
	var bpm: float = 80.0
	var duration: float = 8.0
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	var beat_len: float = 60.0 / bpm
	var eighth: float = beat_len * 0.5
	# Melody (triangle wave): eighth notes, Am pentatonic, gentle & flowing
	# A4=440 C5=523.3 D5=587.3 E5=659.3 G5=784 A5=880
	# Rest=0, pattern spans 2 bars (8 beats = 16 eighths)
	var mel: Array[float] = [
		440.0, 0.0, 523.3, 0.0, 659.3, 523.3, 0.0, 440.0,
		587.3, 0.0, 523.3, 440.0, 0.0, 392.0, 440.0, 0.0,
		523.3, 0.0, 659.3, 0.0, 784.0, 659.3, 0.0, 523.3,
		659.3, 0.0, 587.3, 523.3, 440.0, 0.0, 0.0, 0.0
	]
	# Bass (triangle): half notes, Am-F-C-G progression
	# A2=110 F2=87.3 C3=130.8 G2=98.0
	var bass_notes: Array[float] = [110.0, 110.0, 87.3, 87.3, 130.8, 130.8, 98.0, 98.0,
		110.0, 110.0, 87.3, 87.3, 130.8, 130.8, 98.0, 98.0]
	# Pad chords (sine): whole notes, Am-Fmaj7-Cmaj7-G
	# Am:  A3=220, C4=261.6, E4=329.6
	# F:   F3=174.6, A3=220, C4=261.6 (Fmaj7 feel)
	# C:   C4=261.6, E4=329.6, G4=392
	# G:   G3=196, B3=246.9, D4=293.7
	var pad_roots: Array[float] = [220.0, 174.6, 261.6, 196.0]
	var pad_thirds: Array[float] = [261.6, 220.0, 329.6, 246.9]
	var pad_fifths: Array[float] = [329.6, 261.6, 392.0, 293.7]
	var phase_mel: float = 0.0
	var phase_bass: float = 0.0
	var phase_p1: float = 0.0
	var phase_p2: float = 0.0
	var phase_p3: float = 0.0
	var prev_mel_freq: float = 0.0
	for i in num_samples:
		var t: float = float(i) / float(SR)
		var beat_f: float = t / beat_len
		# Eighth-note index for melody
		var ei: float = t / eighth
		var eidx: int = int(ei) % mel.size()
		var epos: float = fmod(ei, 1.0)
		# Half-note index for bass
		var half_f: float = t / (beat_len)
		var bidx: int = int(half_f) % bass_notes.size()
		var bpos: float = fmod(half_f, 1.0)
		# Whole-note index for pad (2 beats per chord)
		var chord_idx: int = int(beat_f / 2.0) % pad_roots.size()
		var mix: float = 0.0
		# --- Triangle melody (warm, smooth) ---
		var mf: float = mel[eidx]
		if mf > 0.0:
			prev_mel_freq = mf
			phase_mel += mf / float(SR)
			# Soft envelope: slow attack, long sustain, gentle release
			var mel_env: float = _adsr(epos * eighth, eighth, 0.02, 0.08, 0.6, 0.05)
			mix += _tri(phase_mel) * mel_env * 0.14
		elif prev_mel_freq > 0.0:
			# Let note tail ring out briefly
			phase_mel += prev_mel_freq / float(SR)
			var tail: float = maxf(0.0, 1.0 - epos * 4.0) * 0.04
			mix += _tri(phase_mel) * tail
		# --- Triangle bass (deep, warm) ---
		var bf: float = bass_notes[bidx]
		phase_bass += bf / float(SR)
		var bass_env: float = _adsr(bpos * beat_len, beat_len, 0.015, 0.1, 0.65, 0.08)
		mix += _tri(phase_bass) * bass_env * 0.16
		# --- Sine pad chords (ethereal, gentle) ---
		phase_p1 += pad_roots[chord_idx] / float(SR)
		phase_p2 += pad_thirds[chord_idx] / float(SR)
		phase_p3 += pad_fifths[chord_idx] / float(SR)
		# Slow breathing volume via LFO
		var pad_vol: float = 0.04 + 0.015 * sin(t * 0.3 * TWO_PI)
		mix += _sine(phase_p1) * pad_vol
		mix += _sine(phase_p2) * pad_vol * 0.7
		mix += _sine(phase_p3) * pad_vol * 0.5
		# --- Subtle shimmer: high-freq sine arpeggio ---
		var shimmer_idx: int = int(t / 0.375) % 4
		var shimmer_freqs: Array[float] = [880.0, 1046.5, 1318.5, 1046.5]
		var shimmer_phase: float = t * shimmer_freqs[shimmer_idx] / float(SR) * float(SR)
		var shimmer_env: float = maxf(0.0, 1.0 - fmod(t / 0.375, 1.0) * 2.5)
		mix += _sine(shimmer_phase / float(SR) * shimmer_freqs[shimmer_idx]) * shimmer_env * 0.018
		# --- Clean output ---
		data[i] = _to_byte(clampf(mix, -0.95, 0.95) * 0.5)
	return _make_stream(data, true)

# ============================================================
# 20. TYPING SFX - Quick click/tick for text character display, ~0.03s
# ============================================================
static func generate_typing_sfx() -> AudioStreamWAV:
	var duration: float = 0.03
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	var phase1: float = 0.0
	for i in num_samples:
		var p: float = float(i) / float(num_samples)
		var env: float = exp(-p * 40.0)
		phase1 += 3500.0 / float(SR)
		var tone: float = _pulse(phase1, 0.25) * env * 0.2
		var click: float = _noise_from_index(i) * exp(-p * 80.0) * 0.15
		var mix: float = tone + click
		data[i] = _to_byte(mix * 0.7)
	return _make_stream(data)

# ============================================================
# 21. SPELL SFX - Magical shimmer, rising arpeggio with decay, ~0.4s
# ============================================================
static func generate_spell_sfx() -> AudioStreamWAV:
	var duration: float = 0.4
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	var spell_notes: Array[float] = [523.3, 659.3, 784.0, 1047.0, 1318.5]
	var note_dur: float = 0.07
	var phases: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
	for i in num_samples:
		var t: float = float(i) / float(SR)
		var p: float = float(i) / float(num_samples)
		var mix: float = 0.0
		for n in spell_notes.size():
			var start: float = float(n) * note_dur
			if t < start:
				continue
			var nt: float = t - start
			phases[n] += spell_notes[n] / float(SR)
			var note_env: float = exp(-nt * 6.0) * 0.15
			mix += _tri(phases[n]) * note_env
			mix += _sine(phases[n] * 2.0) * note_env * 0.3
			mix += _sine(phases[n] * 3.01) * note_env * 0.1 * exp(-nt * 12.0)
		mix += _noise_from_index(i + 8888) * exp(-p * 8.0) * 0.04
		data[i] = _to_byte(clampf(mix, -1.0, 1.0) * 0.8)
	return _make_stream(data)

# ============================================================
# 22. BOSS ATTACK SFX - Heavy impact, low boom + distortion, ~0.5s
# ============================================================
static func generate_boss_attack_sfx() -> AudioStreamWAV:
	var duration: float = 0.5
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	var phase_boom: float = 0.0
	var phase_hit: float = 0.0
	for i in num_samples:
		var _t: float = float(i) / float(SR)
		var p: float = float(i) / float(num_samples)
		var mix: float = 0.0
		var boom_freq: float = lerpf(200.0, 35.0, minf(p * 2.0, 1.0))
		phase_boom += boom_freq / float(SR)
		var boom_env: float = exp(-p * 6.0) * 0.5
		mix += _sine(phase_boom) * boom_env
		mix += _sine(phase_boom * 0.5) * boom_env * 0.4
		var hit_freq: float = lerpf(600.0, 80.0, minf(p * 5.0, 1.0))
		phase_hit += hit_freq / float(SR)
		var hit_env: float = exp(-p * 15.0) * 0.4
		mix += _square(phase_hit, 0.3) * hit_env
		var crack_env: float = exp(-p * 25.0) * 0.35
		mix += _noise_from_index(i) * crack_env
		mix = _saturate(mix, 2.5)
		mix += _sine(float(i) * 30.0 / float(SR)) * exp(-p * 4.0) * 0.1
		data[i] = _to_byte(clampf(mix, -1.0, 1.0) * 0.75)
	return _make_stream(data)

# ============================================================
# 23. BOSS HURT SFX - Metallic clang, satisfying hit feedback, ~0.3s
# ============================================================
static func generate_boss_hurt_sfx() -> AudioStreamWAV:
	var duration: float = 0.3
	var num_samples: int = int(duration * SR)
	var data := PackedByteArray()
	data.resize(num_samples)
	var phase1: float = 0.0
	var phase2: float = 0.0
	var phase3: float = 0.0
	for i in num_samples:
		var t: float = float(i) / float(SR)
		var p: float = float(i) / float(num_samples)
		var mix: float = 0.0
		var base_freq: float = 520.0
		phase1 += base_freq / float(SR)
		phase2 += (base_freq * 2.76) / float(SR)
		phase3 += (base_freq * 4.13) / float(SR)
		var clang_env: float = exp(-t * 12.0)
		mix += _tri(phase1) * clang_env * 0.25
		mix += _sine(phase2) * clang_env * 0.15 * exp(-t * 18.0)
		mix += _sine(phase3) * clang_env * 0.08 * exp(-t * 25.0)
		var click_env: float = exp(-p * 50.0) * 0.3
		mix += _noise_from_index(i) * click_env
		var sweep_freq: float = lerpf(1200.0, 400.0, minf(p * 4.0, 1.0))
		mix += _square(float(i) * sweep_freq / float(SR), 0.25) * exp(-p * 20.0) * 0.12
		data[i] = _to_byte(clampf(mix, -1.0, 1.0) * 0.8)
	return _make_stream(data)
