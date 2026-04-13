extends Node

## Procedural audio helper — no external WAV files.
## Generates all sounds at _ready() using AudioStreamWAV with 16-bit PCM data.
## Usage: Sfx.play("key_click")

const SAMPLE_RATE := 22050.0
const MAX_PLAYERS := 8

var _player_pool: Array[AudioStreamPlayer] = []
var _player_index: int = 0
var _streams: Dictionary = {}


func _ready() -> void:
	for i in MAX_PLAYERS:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_player_pool.append(player)
	_generate_all()


func play(sound_name: String) -> void:
	if not _streams.has(sound_name):
		return
	var player := _player_pool[_player_index]
	if player.playing:
		player.stop()
	player.stream = _streams[sound_name]
	player.play()
	_player_index = (_player_index + 1) % MAX_PLAYERS


# ── Sound catalogue ───────────────────────────────────────────

func _generate_all() -> void:
	_streams["boot"]              = _make_sweep(200.0, 600.0, 0.8, 0.30)
	_streams["key_click"]         = _make_tone(880.0, 0.04, 0.20)
	_streams["backspace"]         = _make_tone(440.0, 0.06, 0.18)
	_streams["password_error"]    = _make_buzzer(180.0, 0.35, 0.30)
	_streams["password_success"]  = _make_arpeggio([523.0, 659.0, 784.0], 0.13, 0.28)
	_streams["transition_whoosh"] = _make_whoosh(0.45, 0.22)
	_streams["eat_item"]          = _make_sweep(500.0, 1200.0, 0.10, 0.30)
	_streams["game_over"]         = _make_sweep(400.0, 100.0, 0.55, 0.35)
	_streams["direction_tick"]    = _make_tone(1200.0, 0.022, 0.12)
	_streams["victory_fanfare"]   = _make_arpeggio([523.0, 659.0, 784.0, 1047.0], 0.17, 0.30)
	_streams["retry"]             = _make_sweep(300.0, 500.0, 0.2, 0.25)


# ── Waveform generators ───────────────────────────────────────

func _make_tone(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var n := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / float(n)
		var amp := volume * (1.0 - t)
		var sample := amp * sin(2.0 * PI * freq * float(i) / SAMPLE_RATE)
		_write_s16(data, i * 2, sample)
	return _as_stream(data)


func _make_sweep(start_freq: float, end_freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var n := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		var freq := lerpf(start_freq, end_freq, t)
		var amp := volume * (1.0 - t * 0.6)
		phase += 2.0 * PI * freq / SAMPLE_RATE
		_write_s16(data, i * 2, amp * sin(phase))
	return _as_stream(data)


func _make_buzzer(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var n := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / float(n)
		var amp := volume * (1.0 - t)
		var s1 := 1.0 if sin(2.0 * PI * freq * float(i) / SAMPLE_RATE) >= 0.0 else -1.0
		var s2 := 1.0 if sin(2.0 * PI * freq * 1.502 * float(i) / SAMPLE_RATE) >= 0.0 else -1.0
		_write_s16(data, i * 2, amp * (s1 * 0.65 + s2 * 0.35))
	return _as_stream(data)


func _make_arpeggio(freqs: Array, note_dur: float, volume: float) -> AudioStreamWAV:
	var all := PackedByteArray()
	for freq in freqs:
		all.append_array(_sine_chunk(freq, note_dur, volume))
	return _as_stream(all)


func _make_whoosh(duration: float, volume: float) -> AudioStreamWAV:
	var n := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	var state := 12345
	for i in n:
		var t := float(i) / float(n)
		var env := sin(PI * t)
		state = (state * 1103515245 + 12345) & 0x7FFFFFFF
		var noise := (float(state & 0xFFFF) / 32768.0 - 1.0)
		_write_s16(data, i * 2, volume * env * noise)
	return _as_stream(data)


# ── Helpers ────────────────────────────────────────────────────

func _sine_chunk(freq: float, duration: float, volume: float) -> PackedByteArray:
	var n := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / float(n)
		var amp := volume * (1.0 - t * 0.5)
		var sample := amp * sin(2.0 * PI * freq * float(i) / SAMPLE_RATE)
		_write_s16(data, i * 2, sample)
	return data


func _write_s16(data: PackedByteArray, offset: int, sample: float) -> void:
	var s := clampi(int(sample * 32767.0), -32768, 32767)
	data[offset] = s & 0xFF
	data[offset + 1] = (s >> 8) & 0xFF


func _as_stream(data: PackedByteArray) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = int(SAMPLE_RATE)
	s.data = data
	return s
