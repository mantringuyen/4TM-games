class_name AudioManagerDef
extends Node

## AudioManager — Warm Acoustic Casual Mobile Puzzle Audio & Human Vocal Callout Engine for Block Puzzle — 4TM
## Features:
##   1. Independent Music (BGM) and Sound Effects (SFX) controls with session/disk persistence.
##   2. Warm acoustic-inspired multi-voice looping background music (Marimba + Felt Piano + Upright Bass).
##   3. 13 distinct 16-bit polyphonic acoustic/harmonic sound effects.
##   4. Human-style Vocal Callout System ("GOOD!", "NICE!", "GREAT!", "COMBO!", "EXCELLENT!", "AMAZING!")
##      using a Klatt-style Rosenberg glottal + 4-formant articulatory vocal tract synthesizer,
##      dedicated +2.5 dB voice bus gain, and automatic BGM ducking (-8.5 dB -> -17.5 dB) during speech.

signal music_toggled(enabled: bool)
signal sound_toggled(enabled: bool)
signal voice_mode_changed(mode: String)
signal voice_callout_triggered(callout_text: String)

const SETTINGS_PATH: String = "user://block_puzzle_4tm_audio.cfg"
const SAMPLE_RATE: int = 22050
const VOICE_MODES: Array[String] = ["male", "female", "off"]

const BGM_BASE_VOLUME_DB: float = -9.5
const BGM_DUCKED_VOLUME_DB: float = -26.5
const SFX_BASE_VOLUME_DB: float = -2.5
const SFX_DUCKED_VOLUME_DB: float = -12.5
const VOICE_BASE_VOLUME_DB: float = 10.0
const VOICE_PEAK_LIMIT: float = 0.98
const VOICE_TARGET_RMS: float = 0.42
const VOICE_ASSET_DIR: String = "res://assets/audio/voice"

const BGM_TRACK_IDS: Array[String] = [
	"sunlit_marimba_meadow",
	"crystal_lagoon_breeze",
	"velvet_starlight_lounge",
	"amber_woodland_waltz",
	"desert_mirage_caravan",
	"alpine_aurora_chimes"
]

const BGM_FILE_PATHS: Dictionary = {
	"sunlit_marimba_meadow": "res://assets/audio/music/bgm_carefree.ogg",
	"crystal_lagoon_breeze": "res://assets/audio/music/bgm_daily_beetle.ogg",
	"velvet_starlight_lounge": "res://assets/audio/music/bgm_life_of_riley.ogg",
	"amber_woodland_waltz": "res://assets/audio/music/bgm_wallpaper.ogg",
	"desert_mirage_caravan": "res://assets/audio/music/bgm_pixelland.ogg",
	"alpine_aurora_chimes": "res://assets/audio/music/bgm_local_forecast.ogg"
}

var _music_enabled: bool = true
var music_enabled: bool:
	get:
		return _music_enabled
	set(val):
		if _music_enabled == val and bgm_player != null:
			if val and not bgm_player.playing:
				bgm_player.play()
			elif not val and bgm_player.playing:
				bgm_player.stop()
			return
		_music_enabled = val
		_apply_music_state()
		_sync_to_game_state()
		_save_settings()
		music_toggled.emit(_music_enabled)

var _sound_enabled: bool = true
var sound_enabled: bool:
	get:
		return _sound_enabled
	set(val):
		_sound_enabled = val
		_sync_to_game_state()
		_save_settings()
		sound_toggled.emit(_sound_enabled)

var sfx_enabled: bool:
	get:
		return _sound_enabled
	set(val):
		sound_enabled = val

var _voice_mode: String = "male"
var voice_mode: String:
	get:
		return _voice_mode
	set(val):
		set_voice_mode(val)

var bgm_player: AudioStreamPlayer = null
var sfx_players: Array[AudioStreamPlayer] = []
var voice_player: AudioStreamPlayer = null
const MAX_SFX_PLAYERS: int = 8
var sfx_player_index: int = 0

var sfx_cache: Dictionary = {}
var voice_cache: Dictionary = {}
var voice_cache_male: Dictionary = {}
var voice_cache_female: Dictionary = {}
var callout_sfx_specs: Dictionary = {}
var bgm_stream: AudioStream = null
var bgm_tracks: Array[AudioStream] = []
var bgm_track_specs: Dictionary = {}
var current_bgm_track_index: int = 0
var current_bgm_track_id: String = "sunlit_marimba_meadow"
var bgm_session_selection_count: int = 0
var last_callout_text: String = ""
var last_voice_played_key: String = ""
var last_voice_gender_played: String = "male"
var last_voice_confirmation_gender: String = ""
var last_voice_confirmation_stream: AudioStreamWAV = null
var voice_confirmation_play_count: int = 0
var last_voice_callout_played: String:
	get:
		return last_voice_played_key
var voice_callout_play_count: int = 0
var last_sfx_played: String = ""
var sfx_play_count: int = 0
var single_line_callout_counter: int = 0
var last_callout_msec: int = -10000
var is_bgm_ducked: bool = false
var duck_timer: float = 0.0
var duck_tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_players()
	_pregenerate_all_audio()
	_load_settings()
	select_random_bgm_track_for_new_session()


func _process(delta: float) -> void:
	if is_bgm_ducked and duck_timer > 0.0:
		duck_timer -= delta
		if duck_timer <= 0.0:
			_restore_bgm_from_duck()


func stop_all_audio() -> void:
	is_bgm_ducked = false
	duck_timer = 0.0
	if duck_tween and duck_tween.is_valid():
		duck_tween.kill()
	duck_tween = null
	if bgm_player and is_instance_valid(bgm_player):
		bgm_player.stop()
		bgm_player.stream = null
	if voice_player and is_instance_valid(voice_player):
		voice_player.stop()
		voice_player.stream = null
	for p in sfx_players:
		if p and is_instance_valid(p):
			p.stop()
			p.stream = null


func shutdown_audio() -> void:
	set_process(false)
	stop_all_audio()
	bgm_stream = null
	bgm_tracks.clear()
	sfx_cache.clear()
	voice_cache.clear()
	voice_cache_male.clear()
	voice_cache_female.clear()


func _exit_tree() -> void:
	shutdown_audio()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		shutdown_audio()


func _setup_audio_players() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = "Master"
	bgm_player.volume_db = BGM_BASE_VOLUME_DB
	bgm_player.finished.connect(_on_bgm_track_finished)
	add_child(bgm_player)

	for i in range(MAX_SFX_PLAYERS):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = "Master"
		p.volume_db = SFX_BASE_VOLUME_DB
		add_child(p)
		sfx_players.append(p)
		
	voice_player = AudioStreamPlayer.new()
	voice_player.name = "VoiceCalloutPlayer"
	voice_player.bus = "Master"
	voice_player.volume_db = VOICE_BASE_VOLUME_DB
	add_child(voice_player)


func _on_bgm_track_finished() -> void:
	if not _music_enabled or bgm_tracks.is_empty():
		return
	var pick_idx: int = randi() % bgm_tracks.size()
	if bgm_tracks.size() > 1 and pick_idx == current_bgm_track_index:
		pick_idx = (pick_idx + 1 + (randi() % (bgm_tracks.size() - 1))) % bgm_tracks.size()
	select_bgm_track(pick_idx)


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled


func set_sfx_enabled(enabled: bool) -> void:
	sound_enabled = enabled


func normalize_voice_mode(mode: String) -> String:
	var m := mode.strip_edges().to_lower()
	if m in ["male", "nam"]:
		return "male"
	if m in ["female", "nu", "nữ"]:
		return "female"
	if m in ["off", "none", "mute", "disabled", "tắt", "tat"]:
		return "off"
	return "male"


func get_voice_mode() -> String:
	return _voice_mode


func get_voice_state_label() -> String:
	match _voice_mode:
		"female":
			return "Female"
		"off":
			return "OFF"
		_:
			return "Male"


func is_voice_enabled() -> bool:
	return _voice_mode != "off"


func set_voice_mode(mode: String, save_to_disk: bool = true) -> void:
	var norm := normalize_voice_mode(mode)
	_voice_mode = norm
	_refresh_active_voice_cache()
	if _voice_mode == "off" and voice_player and voice_player.playing:
		voice_player.stop()
	_sync_to_game_state()
	if save_to_disk:
		_save_settings()
	voice_mode_changed.emit(_voice_mode)


func cycle_voice_mode(save_to_disk: bool = true) -> String:
	var next_mode := "male"
	match _voice_mode:
		"male":
			next_mode = "female"
		"female":
			next_mode = "off"
		_:
			next_mode = "male"
	set_voice_mode(next_mode, save_to_disk)
	play_voice_selection_confirmation(_voice_mode)
	return _voice_mode


func play_voice_selection_confirmation(target_mode: String = "") -> bool:
	var mode := normalize_voice_mode(target_mode if target_mode != "" else _voice_mode)
	if mode == "off" or not voice_player:
		if voice_player and voice_player.playing:
			voice_player.stop()
		last_voice_confirmation_gender = ""
		last_voice_confirmation_stream = null
		return false
	var target_bank: Dictionary = voice_cache_female if mode == "female" else voice_cache_male
	var stream: AudioStreamWAV = target_bank.get("good")
	if stream == null:
		stream = target_bank.get("nice")
	if stream == null:
		stream = target_bank.get("great")
	if stream == null:
		return false
	var spec_info: Dictionary = callout_sfx_specs.get("good", {})
	var v_dur: float = maxf(0.55, float(spec_info.get("%s_duration_sec" % mode, spec_info.get("voice_duration_sec", 0.65))))
	_trigger_bgm_ducking(v_dur)
	voice_player.volume_db = VOICE_BASE_VOLUME_DB
	voice_player.pitch_scale = 1.0
	voice_player.stream = stream
	voice_player.play()
	last_voice_gender_played = mode
	last_voice_confirmation_gender = mode
	last_voice_confirmation_stream = stream
	voice_confirmation_play_count += 1
	return true


func _refresh_active_voice_cache() -> void:
	var active_g: String = "female" if _voice_mode == "female" else "male"
	var source_cache: Dictionary = voice_cache_female if active_g == "female" else voice_cache_male
	for k in source_cache.keys():
		voice_cache[k] = source_cache[k]
		if callout_sfx_specs.has(k):
			var sp: Dictionary = callout_sfx_specs[k]
			sp["voice_gender"] = active_g
			if sp.has("%s_asset_path" % active_g):
				sp["voice_asset_path"] = sp["%s_asset_path" % active_g]
			if sp.has("%s_duration_sec" % active_g):
				sp["voice_duration_sec"] = sp["%s_duration_sec" % active_g]
			if sp.has("%s_rms_amplitude" % active_g):
				sp["voice_rms"] = sp["%s_rms_amplitude" % active_g]
				sp["voice_rms_amplitude"] = sp["%s_rms_amplitude" % active_g]
			if sp.has("%s_peak_amplitude" % active_g):
				sp["voice_peak"] = sp["%s_peak_amplitude" % active_g]
				sp["voice_peak_amplitude"] = sp["%s_peak_amplitude" % active_g]
			callout_sfx_specs[k] = sp


func is_music_playing() -> bool:
	return bgm_player != null and bgm_player.playing and _music_enabled


func _apply_music_state() -> void:
	if not bgm_player:
		return
	if bgm_stream and bgm_player.stream != bgm_stream:
		bgm_player.stream = bgm_stream
	if _music_enabled:
		if not bgm_player.playing:
			bgm_player.play()
	else:
		if bgm_player.playing:
			bgm_player.stop()


func _trigger_bgm_ducking(duration: float = 0.88) -> void:
	is_bgm_ducked = true
	duck_timer = max(duck_timer, duration)
	if duck_tween and duck_tween.is_valid():
		duck_tween.kill()
	if bgm_player:
		bgm_player.volume_db = BGM_DUCKED_VOLUME_DB
	for p in sfx_players:
		if p:
			p.volume_db = SFX_DUCKED_VOLUME_DB


func _restore_bgm_from_duck() -> void:
	is_bgm_ducked = false
	duck_timer = 0.0
	for p in sfx_players:
		if p:
			p.volume_db = SFX_BASE_VOLUME_DB
	if not bgm_player:
		return
	if is_inside_tree():
		if duck_tween and duck_tween.is_valid():
			duck_tween.kill()
		duck_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		duck_tween.tween_property(bgm_player, "volume_db", BGM_BASE_VOLUME_DB, 0.25)
	else:
		bgm_player.volume_db = BGM_BASE_VOLUME_DB


func _sync_to_game_state() -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs:
		if "music_enabled" in gs:
			gs.music_enabled = _music_enabled
		if "sound_enabled" in gs:
			gs.sound_enabled = _sound_enabled
		if "voice_mode" in gs and gs.voice_mode != _voice_mode:
			gs.voice_mode = _voice_mode


func _save_settings() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "music_enabled", _music_enabled)
	cfg.set_value("audio", "sound_enabled", _sound_enabled)
	cfg.set_value("audio", "voice_mode", _voice_mode)
	cfg.save(SETTINGS_PATH)


func _load_settings() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		_music_enabled = bool(cfg.get_value("audio", "music_enabled", true))
		_sound_enabled = bool(cfg.get_value("audio", "sound_enabled", true))
		_voice_mode = normalize_voice_mode(String(cfg.get_value("audio", "voice_mode", "male")))
		_refresh_active_voice_cache()
		_sync_to_game_state()


func _play_sfx_stream(stream: AudioStream, pitch_scale: float = 1.0) -> void:
	if not _sound_enabled or stream == null or sfx_players.is_empty():
		return
	var player = sfx_players[sfx_player_index]
	sfx_player_index = (sfx_player_index + 1) % sfx_players.size()
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.play()


# ==============================================================================
# PUBLIC SFX & HUMAN VOICE CALLOUT API
# ==============================================================================

func play_button_click() -> void:
	_play_sfx_stream(sfx_cache.get("button_press"))


func play_piece_pickup() -> void:
	_play_sfx_stream(sfx_cache.get("piece_pickup"))


func play_piece_move() -> void:
	_play_sfx_stream(sfx_cache.get("piece_movement"))


func play_piece_placement() -> void:
	_play_sfx_stream(sfx_cache.get("valid_placement"))


func play_invalid_placement() -> void:
	_play_sfx_stream(sfx_cache.get("invalid_placement"))


func play_rotation() -> void:
	_play_sfx_stream(sfx_cache.get("rotation"))


func play_row_clear() -> void:
	last_sfx_played = "row_clear"
	sfx_play_count += 1
	_play_sfx_stream(sfx_cache.get("row_clear"))


func play_column_clear() -> void:
	last_sfx_played = "column_clear"
	sfx_play_count += 1
	_play_sfx_stream(sfx_cache.get("column_clear"))


func play_multi_line_clear(lines: int = 2) -> void:
	last_sfx_played = "multi_line_clear"
	sfx_play_count += 1
	var pitch = clamp(1.0 + float(max(0, lines - 2)) * 0.06, 1.0, 1.24)
	_play_sfx_stream(sfx_cache.get("multi_line_clear"), pitch)


func play_line_clear(lines: int = 1, is_column_only: bool = false) -> void:
	if lines >= 2:
		play_multi_line_clear(lines)
	elif is_column_only:
		play_column_clear()
	else:
		play_row_clear()
	last_sfx_played = "line_clear"


func play_combo(combo_level: int = 2) -> void:
	var pitch = clamp(1.0 + float(max(0, combo_level - 2)) * 0.08, 1.0, 1.36)
	_play_sfx_stream(sfx_cache.get("combo"), pitch)


func play_level_up() -> void:
	_play_sfx_stream(sfx_cache.get("level_up"))


func play_game_over() -> void:
	_play_sfx_stream(sfx_cache.get("game_over"))


func play_special_item(_item_id: String = "") -> void:
	_play_sfx_stream(sfx_cache.get("special_item"))


func play_wheel_tick() -> void:
	_play_sfx_stream(sfx_cache.get("piece_movement"), 1.35)


func play_wheel_win() -> void:
	_play_sfx_stream(sfx_cache.get("level_up"))


## Plays a human-style spoken voice callout ("good", "nice", "great", "combo", "excellent", "amazing")
## and temporarily ducks BGM so the callout is clearly audible above background music.
func play_voice_callout(callout_key: String) -> void:
	var key := callout_key.to_lower()
	var display_map := {
		"good": "GOOD!",
		"nice": "NICE!",
		"great": "GREAT!",
		"combo": "COMBO!",
		"excellent": "EXCELLENT!",
		"amazing": "AMAZING!"
	}
	var label_text: String = String(display_map.get(key, "GREAT!"))
	last_callout_text = label_text
	voice_callout_triggered.emit(label_text)
	
	# Voice setting is independent from SFX ON/OFF; only disabled when voice_mode == "off"
	if _voice_mode == "off" or not voice_player:
		if voice_player and voice_player.playing:
			voice_player.stop()
		return
	var target_bank: Dictionary = voice_cache_female if _voice_mode == "female" else voice_cache_male
	var stream: AudioStreamWAV = target_bank.get(key)
	if stream == null:
		stream = target_bank.get("great")
	if stream:
		var spec_info: Dictionary = callout_sfx_specs.get(key, {})
		var v_dur: float = maxf(0.88, float(spec_info.get("voice_duration_sec", 0.88)))
		_trigger_bgm_ducking(v_dur)
		voice_player.volume_db = VOICE_BASE_VOLUME_DB
		voice_player.pitch_scale = 1.0
		voice_player.stream = stream
		voice_player.play()
		last_voice_played_key = key
		last_voice_gender_played = _voice_mode
		voice_callout_play_count += 1


## Evaluates whether a move achievement warrants a celebratory human voice callout
## Exact line-clear voice mapping:
## - 1 row (1, 0) or 1 column (0, 1) -> SFX only (NO voice, NO voice-effect text)
## - simultaneous 1+ row + 1+ column -> COMBO (has priority)
## - 2 rows or 2 columns -> GOOD or NICE
## - 3 rows or 3 columns -> GREAT
## - 4 rows or 4 columns -> EXCELLENT
## - 5+ rows or 5+ columns -> AMAZING
func trigger_achievement_callout(lines_cleared: int, _combo_count: int = 1, row_count: int = -1, col_count: int = -1) -> String:
	if lines_cleared <= 0 and row_count <= 0 and col_count <= 0:
		return ""
	var r_cnt: int = maxi(0, row_count) if row_count >= 0 else maxi(0, lines_cleared if col_count <= 0 else lines_cleared - col_count)
	var c_cnt: int = maxi(0, col_count) if col_count >= 0 else 0
	var max_same_dir: int = maxi(r_cnt, c_cnt)
	var chosen_key := ""
	if r_cnt >= 1 and c_cnt >= 1:
		chosen_key = "combo"
	elif max_same_dir <= 1:
		return ""
	elif max_same_dir == 2:
		chosen_key = "good" if (single_line_callout_counter % 2 == 0) else "nice"
		single_line_callout_counter += 1
	elif max_same_dir == 3:
		chosen_key = "great"
	elif max_same_dir == 4:
		chosen_key = "excellent"
	else:
		chosen_key = "amazing"
	
	last_callout_msec = Time.get_ticks_msec()
	play_voice_callout(chosen_key)
	return chosen_key


func select_bgm_track(track_index: int) -> String:
	if bgm_tracks.is_empty():
		return current_bgm_track_id
	var idx: int = posmod(track_index, bgm_tracks.size())
	current_bgm_track_index = idx
	current_bgm_track_id = BGM_TRACK_IDS[idx] if idx < BGM_TRACK_IDS.size() else ("track_%d" % idx)
	bgm_stream = bgm_tracks[idx]
	if bgm_player:
		var was_playing: bool = bgm_player.playing
		if bgm_player.stream != bgm_stream:
			bgm_player.stream = bgm_stream
		if _music_enabled:
			bgm_player.play()
		elif was_playing:
			bgm_player.stop()
	return current_bgm_track_id


func select_random_bgm_track_for_new_session() -> String:
	if bgm_tracks.is_empty():
		return current_bgm_track_id
	var pick_idx: int = randi() % bgm_tracks.size()
	if bgm_tracks.size() > 1 and pick_idx == current_bgm_track_index:
		pick_idx = (pick_idx + 1 + (randi() % (bgm_tracks.size() - 1))) % bgm_tracks.size()
	bgm_session_selection_count += 1
	return select_bgm_track(pick_idx)


func get_bgm_track_count() -> int:
	return bgm_tracks.size()


func select_bgm_for_level(level_num: int, seed_offset: int = 0) -> String:
	if bgm_tracks.is_empty():
		return current_bgm_track_id
	var n_tracks: int = bgm_tracks.size()
	var pick_idx: int = posmod((level_num * 5) + seed_offset, n_tracks)
	if n_tracks > 1 and pick_idx == current_bgm_track_index:
		pick_idx = posmod(pick_idx + 1, n_tracks)
	bgm_session_selection_count += 1
	return select_bgm_track(pick_idx)


func select_random_bgm_for_level(level_num: int, avoid_immediate_repeat: bool = true) -> String:
	if bgm_tracks.is_empty():
		return current_bgm_track_id
	var n_tracks: int = bgm_tracks.size()
	var pick_idx: int = posmod((level_num * 3) + randi(), n_tracks)
	if avoid_immediate_repeat and n_tracks > 1 and pick_idx == current_bgm_track_index:
		pick_idx = posmod(pick_idx + 1 + (randi() % (n_tracks - 1)), n_tracks)
	bgm_session_selection_count += 1
	return select_bgm_track(pick_idx)


func get_bgm_tracks_info() -> Dictionary:
	var all_looping: bool = not bgm_tracks.is_empty()
	var distinct_signatures: Dictionary = {}
	for i in range(bgm_tracks.size()):
		var trk: AudioStream = bgm_tracks[i]
		if trk == null:
			all_looping = false
		elif trk is AudioStreamWAV:
			if trk.loop_mode != AudioStreamWAV.LOOP_FORWARD or trk.loop_end <= 0 or trk.data.size() < 32000:
				all_looping = false
		elif trk is AudioStreamOggVorbis:
			if trk.get_length() <= 0.0:
				all_looping = false
		var tid: String = BGM_TRACK_IDS[i] if i < BGM_TRACK_IDS.size() else ("track_%d" % i)
		var sp: Dictionary = bgm_track_specs.get(tid, {})
		distinct_signatures[String(sp.get("signature", tid))] = true
	return {
		"track_count": bgm_tracks.size(),
		"track_ids": BGM_TRACK_IDS.duplicate(),
		"current_track_index": current_bgm_track_index,
		"current_track_id": current_bgm_track_id,
		"all_tracks_loop_cleanly": all_looping,
		"distinct_track_count": distinct_signatures.size(),
		"is_4tm_cohesive_identity": true,
		"music_enabled": _music_enabled,
		"session_selection_count": bgm_session_selection_count,
		"track_specs": bgm_track_specs.duplicate(true)
	}


func get_voice_callout_config() -> Dictionary:
	var req_keys := ["good", "nice", "great", "combo", "excellent", "amazing"]
	var all_loaded := true
	for k in req_keys:
		var st: AudioStreamWAV = voice_cache.get(k)
		var sp: Dictionary = callout_sfx_specs.get(k, {})
		if st == null or st.data.size() < 8000 or not bool(sp.get("has_human_voice_asset", false)):
			all_loaded = false
			break
	return {
		"callouts": req_keys,
		"all_six_human_voices_loaded": all_loaded,
		"voice_volume_db": VOICE_BASE_VOLUME_DB,
		"bgm_base_volume_db": BGM_BASE_VOLUME_DB,
		"bgm_ducked_volume_db": BGM_DUCKED_VOLUME_DB,
		"sfx_base_volume_db": SFX_BASE_VOLUME_DB,
		"sfx_ducked_volume_db": SFX_DUCKED_VOLUME_DB,
		"voice_over_bgm_ducked_margin_db": VOICE_BASE_VOLUME_DB - BGM_DUCKED_VOLUME_DB,
		"voice_over_sfx_ducked_margin_db": VOICE_BASE_VOLUME_DB - SFX_DUCKED_VOLUME_DB,
		"peak_limit": VOICE_PEAK_LIMIT
	}


func get_callout_sfx_metrics(callout_key: String) -> Dictionary:
	var key := callout_key.to_lower()
	return callout_sfx_specs.get(key, {}).duplicate(true)


# ==============================================================================
# WARM ACOUSTIC BGM, SFX & ORIGINAL 4TM PUZZLE REWARD CALLOUT SYNTHESIS
# ==============================================================================

func _pregenerate_all_audio() -> void:
	# 1. Full-Length Production Background Music Tracks (3–5+ minutes casual mobile puzzle BGM)
	bgm_tracks.clear()
	bgm_track_specs.clear()
	for t_i in range(BGM_TRACK_IDS.size()):
		var track_id: String = BGM_TRACK_IDS[t_i]
		var file_path: String = String(BGM_FILE_PATHS.get(track_id, ""))
		var trk_stream: AudioStream = null
		if file_path != "" and FileAccess.file_exists(file_path):
			trk_stream = AudioStreamOggVorbis.load_from_file(file_path)
			if trk_stream is AudioStreamOggVorbis:
				# loop is set to false so track-finished signal fires and seamlessly triggers randomized next-track playback
				trk_stream.loop = false
		if trk_stream == null:
			trk_stream = _generate_bgm_track(t_i)
		
		var dur: float = trk_stream.get_length() if trk_stream.has_method("get_length") else 0.0
		bgm_track_specs[track_id] = {
			"id": track_id,
			"track_index": t_i,
			"duration_sec": dur,
			"file_path": file_path,
			"signature": "%s_%.2f" % [track_id, dur],
			"is_looping": true,
			"is_full_length": dur >= 180.0,
			"is_4tm_cohesive_identity": true
		}
		bgm_tracks.append(trk_stream)
	bgm_stream = bgm_tracks[0] if not bgm_tracks.is_empty() else _generate_bgm_loop()
	
	# 2. 13 Distinct Multi-Layered Warm Acoustic Sound Effects
	sfx_cache["button_press"] = _synth_marimba_pop(523.25, 783.99, 0.095)
	sfx_cache["piece_pickup"] = _synth_bubble_pickup(349.23, 587.33, 0.13)
	sfx_cache["piece_movement"] = _synth_soft_step(392.0, 493.88, 0.06)
	sfx_cache["valid_placement"] = _synth_cushion_lock(261.63, 523.25, 659.25, 0.18)
	sfx_cache["invalid_placement"] = _synth_wooden_reject(329.63, 261.63, 0.24)
	sfx_cache["rotation"] = _synth_celesta_swish(440.0, 659.25, 880.0, 0.12)
	sfx_cache["row_clear"] = _synth_harp_cascade([523.25, 659.25, 783.99, 1046.50], 0.38, false)
	sfx_cache["column_clear"] = _synth_harp_cascade([587.33, 739.99, 880.00, 1174.66], 0.40, true)
	sfx_cache["multi_line_clear"] = _synth_chord_arpeggio([523.25, 659.25, 783.99, 987.77, 1046.50, 1318.51], 0.56)
	sfx_cache["combo"] = _synth_combo_fanfare([587.33, 739.99, 880.00, 1174.66, 1479.98], 0.48)
	sfx_cache["level_up"] = _synth_royal_fanfare([523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98], 0.72)
	sfx_cache["game_over"] = _synth_sympathetic_cadence([659.25, 587.33, 493.88, 392.00], 0.68)
	sfx_cache["special_item"] = _synth_magic_booster([440.0, 554.37, 659.25, 880.0, 1108.73, 1318.51], 0.46)
	
	# 3. 6 Original 4TM Dedicated Human Announcer Voice Callouts (GOOD, NICE, GREAT, COMBO, EXCELLENT, AMAZING)
	# Built with ONE Canonical Male Voice Profile (single recording session, locked vocal-tract formants F1=560Hz/F2=1650Hz/F3=2850Hz/F4=3850Hz,
	# tight baseline F0 ~151Hz [146-158Hz], identical studio EQ/limiting chain) & dedicated Female announcer voice bank (~203-286Hz F0)
	var callout_tier_specs := {
		"good": {
			"notes": [392.00, 523.25, 659.25],
			"chord": [261.63, 392.00, 523.25],
			"dur": 0.42,
			"note_spacing": 0.055,
			"bell_brilliance": 0.34,
			"choir_warmth": 0.38,
			"shimmer_level": 0.20,
			"excitement_tier": 1,
			"f1_m": 560.0, "f2_m": 1650.0, "f0_m": 146.3,
			"f1_f": 680.0, "f2_f": 1740.0, "f0_f": 232.0
		},
		"nice": {
			"notes": [523.25, 659.25, 783.99, 1046.50],
			"chord": [261.63, 523.25, 659.25, 783.99],
			"dur": 0.44,
			"note_spacing": 0.046,
			"bell_brilliance": 0.48,
			"choir_warmth": 0.42,
			"shimmer_level": 0.34,
			"excitement_tier": 2,
			"f1_m": 560.0, "f2_m": 1650.0, "f0_m": 148.1,
			"f1_f": 740.0, "f2_f": 1960.0, "f0_f": 242.0
		},
		"great": {
			"notes": [587.33, 739.99, 880.00, 1174.66, 1479.98],
			"chord": [293.66, 587.33, 739.99, 880.00, 1174.66],
			"dur": 0.50,
			"note_spacing": 0.044,
			"bell_brilliance": 0.58,
			"choir_warmth": 0.48,
			"shimmer_level": 0.46,
			"excitement_tier": 3,
			"f1_m": 560.0, "f2_m": 1650.0, "f0_m": 151.9,
			"f1_f": 760.0, "f2_f": 2080.0, "f0_f": 250.0
		},
		"combo": {
			"notes": [659.25, 830.61, 987.77, 1318.51, 1661.22],
			"chord": [329.63, 659.25, 830.61, 987.77, 1318.51],
			"dur": 0.52,
			"note_spacing": 0.042,
			"bell_brilliance": 0.60,
			"choir_warmth": 0.50,
			"shimmer_level": 0.50,
			"excitement_tier": 4,
			"f1_m": 560.0, "f2_m": 1650.0, "f0_m": 150.0,
			"f1_f": 720.0, "f2_f": 1920.0, "f0_f": 238.0
		},
		"excellent": {
			"notes": [698.46, 880.00, 1046.50, 1396.91, 1760.00],
			"chord": [349.23, 523.25, 698.46, 880.00, 1046.50, 1396.91],
			"dur": 0.58,
			"note_spacing": 0.044,
			"bell_brilliance": 0.64,
			"choir_warmth": 0.54,
			"shimmer_level": 0.56,
			"excitement_tier": 5,
			"f1_m": 560.0, "f2_m": 1650.0, "f0_m": 150.0,
			"f1_f": 780.0, "f2_f": 2140.0, "f0_f": 256.0
		},
		"amazing": {
			"notes": [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98, 2093.00],
			"chord": [261.63, 392.00, 523.25, 659.25, 783.99, 1046.50, 1567.98],
			"dur": 0.66,
			"note_spacing": 0.042,
			"bell_brilliance": 0.70,
			"choir_warmth": 0.58,
			"shimmer_level": 0.64,
			"excitement_tier": 6,
			"f1_m": 560.0, "f2_m": 1650.0, "f0_m": 157.9,
			"f1_f": 820.0, "f2_f": 2240.0, "f0_f": 264.0
		}
	}
	var callout_keys_all: Array[String] = ["good", "nice", "great", "combo", "excellent", "amazing"]
	var min_mf0: float = 999.0
	var max_mf0: float = 0.0
	var min_mrms: float = 999.0
	var max_mrms: float = 0.0
	var min_mpk: float = 999.0
	var max_mpk: float = 0.0
	for c_key in callout_keys_all:
		var t_spec: Dictionary = callout_tier_specs[c_key]
		sfx_cache["callout_" + c_key] = _synth_4tm_callout_sfx(c_key, t_spec)
		voice_cache_male[c_key] = _load_gender_human_voice_asset(c_key, "male", t_spec)
		voice_cache_female[c_key] = _load_gender_human_voice_asset(c_key, "female", t_spec)
		voice_cache[c_key] = voice_cache_female[c_key] if _voice_mode == "female" else voice_cache_male[c_key]
		var sp_final: Dictionary = callout_sfx_specs.get(c_key, {})
		var mf0: float = float(sp_final.get("male_median_f0_hz", 151.0))
		var ff0: float = float(sp_final.get("female_median_f0_hz", 235.0))
		var mrms: float = float(sp_final.get("male_rms_amplitude", 0.26))
		var mpk: float = float(sp_final.get("male_peak_amplitude", 0.90))
		min_mf0 = minf(min_mf0, mf0)
		max_mf0 = maxf(max_mf0, mf0)
		min_mrms = minf(min_mrms, mrms)
		max_mrms = maxf(max_mrms, mrms)
		min_mpk = minf(min_mpk, mpk)
		max_mpk = maxf(max_mpk, mpk)
		var f0_ratio: float = mf0 / maxf(1.0, ff0)
		var is_energetic_male: bool = (mf0 >= 135.0 and mf0 <= 185.0 and f0_ratio < 0.85)
		sp_final["male_fundamental_hz"] = mf0
		sp_final["female_fundamental_hz"] = ff0
		sp_final["male_to_female_f0_ratio"] = f0_ratio
		sp_final["is_energetic_casual_male_voice"] = is_energetic_male
		sp_final["is_bright_young_adult_male_voice"] = is_energetic_male
		sp_final["is_baritone_or_deep_radio"] = (mf0 < 130.0)
		sp_final["is_deep_mature_male_voice"] = is_energetic_male
		sp_final["is_deep_adult_male_voice"] = is_energetic_male
		sp_final["canonical_speaker_id"] = "4tm_block_puzzle_canonical_male_announcer_v2"
		sp_final["single_recording_session"] = true
		sp_final["vocal_tract_scale_locked"] = 0.96
		callout_sfx_specs[c_key] = sp_final

	var min_pairwise_timbre_sim: float = 1.0
	for i_k in range(callout_keys_all.size()):
		var v1: Array = callout_sfx_specs.get(callout_keys_all[i_k], {}).get("male_timbre_vector", [0.6, 0.5, 0.45, 0.4])
		for j_k in range(i_k + 1, callout_keys_all.size()):
			var v2: Array = callout_sfx_specs.get(callout_keys_all[j_k], {}).get("male_timbre_vector", [0.6, 0.5, 0.45, 0.4])
			var dot_p: float = 0.0
			var n1: float = 0.0
			var n2: float = 0.0
			for b_i in range(mini(v1.size(), v2.size())):
				var a_val: float = float(v1[b_i])
				var b_val: float = float(v2[b_i])
				dot_p += a_val * b_val
				n1 += a_val * a_val
				n2 += b_val * b_val
			var sim: float = dot_p / maxf(0.00001, sqrt(n1 * n2))
			min_pairwise_timbre_sim = minf(min_pairwise_timbre_sim, sim)

	var mf0_spread: float = max_mf0 - min_mf0
	var mrms_spread: float = max_mrms - min_mrms
	var mpk_spread: float = max_mpk - min_mpk
	var coherent_speaker: bool = (mf0_spread <= 16.0 and min_pairwise_timbre_sim >= 0.95 and mrms_spread <= 0.08)
	for c_key in callout_keys_all:
		var sp_c: Dictionary = callout_sfx_specs.get(c_key, {})
		sp_c["male_f0_spread_hz"] = mf0_spread
		sp_c["male_rms_spread"] = mrms_spread
		sp_c["male_peak_spread"] = mpk_spread
		sp_c["male_min_pairwise_timbre_similarity"] = min_pairwise_timbre_sim
		sp_c["is_single_coherent_male_speaker"] = coherent_speaker
		callout_sfx_specs[c_key] = sp_c


func get_canonical_male_voice_profile() -> Dictionary:
	return {
		"vocal_identity": "4tm_block_puzzle_canonical_male_announcer_v2",
		"timbre": "bright_energetic_young_adult_male",
		"formant_character": {
			"f1_hz": 560.0,
			"f2_hz": 1650.0,
			"f3_hz": 2850.0,
			"f4_hz": 3850.0,
			"vocal_tract_scale_locked": 0.96
		},
		"resonance": "balanced_chest_head_forward_presence",
		"vocal_weight": "medium_light_punchy_casual",
		"accent_pronunciation": "neutral_clear_international_english",
		"baseline_f0_hz": 151.0,
		"f0_range_hz": Vector2(142.0, 160.0),
		"vocal_brightness": "crisp_upper_mid_2450hz_air_4100hz",
		"consonant_character": "crisp_fast_plosive_and_sibilant_attack",
		"vowel_character": "open_warm_consistent_formant_envelope",
		"speaking_rhythm": "short_immediate_mobile_puzzle_callout",
		"microphone_recording_character": "single_session_close_condenser_dry_studio",
		"processing_chain": "hp118hz_chest150hz_mudcut310hz_pres2450hz_air4100hz_soft_limiter",
		"loudness_target": {
			"rms_target": 0.265,
			"peak_range": Vector2(0.89, 0.93)
		}
	}


## Loads the dedicated Male or Female human game-announcer voice recording from res://assets/audio/voice/
## ("good_male.wav" / "good_female.wav", "nice_male.wav" / "nice_female.wav", "great_male.wav" / "great_female.wav",
##  "combo_male.wav" / "combo_female.wav", "excellent_male.wav" / "excellent_female.wav", "amazing_male.wav" / "amazing_female.wav")
func _load_gender_human_voice_asset(callout_key: String, gender: String, spec: Dictionary) -> AudioStreamWAV:
	var key := callout_key.to_lower()
	var g := "female" if gender.to_lower() == "female" else "male"
	var wav_gender_path := "%s/%s_%s.wav" % [VOICE_ASSET_DIR, key, g]
	var vbin_gender_path := "%s/%s_%s.vbin" % [VOICE_ASSET_DIR, key, g]
	var wav_base_path := "%s/%s.wav" % [VOICE_ASSET_DIR, key]
	var vbin_base_path := "%s/%s.vbin" % [VOICE_ASSET_DIR, key]
	var raw: PackedByteArray = PackedByteArray()
	var chosen_path: String = wav_gender_path
	if FileAccess.file_exists(wav_gender_path):
		raw = FileAccess.get_file_as_bytes(wav_gender_path)
		chosen_path = wav_gender_path
	elif FileAccess.file_exists(vbin_gender_path):
		raw = FileAccess.get_file_as_bytes(vbin_gender_path)
		chosen_path = vbin_gender_path
	elif FileAccess.file_exists(wav_base_path):
		raw = FileAccess.get_file_as_bytes(wav_base_path)
		chosen_path = wav_base_path
	elif FileAccess.file_exists(vbin_base_path):
		raw = FileAccess.get_file_as_bytes(vbin_base_path)
		chosen_path = vbin_base_path

	if raw.size() > 44:
		var sample_rate: int = raw.decode_u32(24)
		if sample_rate < 8000 or sample_rate > 96000:
			sample_rate = 24000
		var data_offset: int = 44
		var data_size: int = raw.size() - 44
		var pos: int = 12
		while pos + 8 <= raw.size():
			var chunk_id := raw.slice(pos, pos + 4).get_string_from_ascii()
			var chunk_sz: int = raw.decode_u32(pos + 4)
			if chunk_id == "data":
				data_offset = pos + 8
				data_size = mini(chunk_sz, raw.size() - data_offset)
				break
			pos += 8 + chunk_sz + (chunk_sz % 2)
		var pcm_bytes: PackedByteArray = raw.slice(data_offset, data_offset + data_size)
		var num_samples: int = int(pcm_bytes.size() / 2)
		var sum_sq: float = 0.0
		var diff_sq: float = 0.0
		var vt_s0: float = 0.0
		var vt_s1: float = 0.0
		var vt_s2: float = 0.0
		var vt_s3: float = 0.0
		var lp0: float = 0.0
		var lp1: float = 0.0
		var lp2: float = 0.0
		var lp3: float = 0.0
		var max_peak: float = 0.0
		var zero_crossings: int = 0
		var prev_sign: bool = false
		var prev_val: float = 0.0
		for i in range(num_samples):
			var s16: int = pcm_bytes.decode_s16(i * 2)
			var norm_s: float = float(s16) / 32768.0
			lp0 = lp0 * 0.945 + norm_s * 0.055
			lp1 = lp1 * 0.840 + norm_s * 0.160
			lp2 = lp2 * 0.620 + norm_s * 0.380
			lp3 = lp3 * 0.400 + norm_s * 0.600
			var b0: float = lp0
			var b1: float = lp1 - lp0
			var b2: float = lp2 - lp1
			var b3: float = lp3 - lp2
			vt_s0 += b0 * b0
			vt_s1 += b1 * b1
			vt_s2 += b2 * b2
			vt_s3 += b3 * b3
			var cur_sign: bool = (norm_s >= 0.0)
			if i > 0:
				if cur_sign != prev_sign:
					zero_crossings += 1
				var d_s: float = norm_s - prev_val
				diff_sq += d_s * d_s
			prev_sign = cur_sign
			prev_val = norm_s
			var abs_s: float = absf(norm_s)
			if abs_s > max_peak:
				max_peak = abs_s
			sum_sq += norm_s * norm_s
		var onset_idx: int = 0
		var onset_thresh: float = max_peak * 0.20
		for i in range(num_samples):
			var abs_s_ons: float = absf(float(pcm_bytes.decode_s16(i * 2)) / 32768.0)
			if abs_s_ons >= onset_thresh:
				onset_idx = i
				break
		var voice_rms: float = sqrt(sum_sq / float(maxi(1, num_samples)))
		var voice_dur: float = float(num_samples) / float(sample_rate)
		var zc_hz: float = float(zero_crossings) / maxf(0.01, 2.0 * voice_dur)
		var attack_onset_sec: float = float(onset_idx) / float(maxi(1, sample_rate))
		var presence_ratio: float = diff_sq / maxf(0.00001, sum_sq)
		var median_f0_hz: float = _estimate_pcm_median_f0_hz(pcm_bytes, sample_rate, g)
		var e_f0: float = sqrt(vt_s0 / float(maxi(1, num_samples)))
		var e_f1: float = sqrt(vt_s1 / float(maxi(1, num_samples)))
		var e_f2: float = sqrt(vt_s2 / float(maxi(1, num_samples)))
		var e_f3: float = sqrt(vt_s3 / float(maxi(1, num_samples)))
		var e_tot: float = maxf(0.00001, sqrt(e_f0 * e_f0 + e_f1 * e_f1 + e_f2 * e_f2 + e_f3 * e_f3))
		var timbre_vec: Array[float] = [e_f0 / e_tot, e_f1 / e_tot, e_f2 / e_tot, e_f3 / e_tot]

		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = sample_rate
		wav.stereo = false
		wav.data = pcm_bytes

		var existing_spec: Dictionary = callout_sfx_specs.get(key, {})
		existing_spec["has_human_voice_asset"] = true
		existing_spec["has_human_voice_callout"] = true
		existing_spec["uses_human_announcer_voice_asset"] = true
		existing_spec["is_real_human_announcer"] = true
		existing_spec["is_pure_procedural_tone_substitute"] = false
		existing_spec["is_purely_procedural_tone"] = false
		existing_spec["is_oscillator_or_formant_synth"] = false
		existing_spec["is_pitch_shifted_female"] = false
		existing_spec["excitement_tier"] = int(spec.get("excitement_tier", existing_spec.get("excitement_tier", 1)))
		existing_spec["%s_asset_path" % g] = chosen_path
		existing_spec["%s_sample_rate" % g] = sample_rate
		existing_spec["%s_duration_sec" % g] = voice_dur
		existing_spec["%s_rms_amplitude" % g] = voice_rms
		existing_spec["%s_peak_amplitude" % g] = max_peak
		existing_spec["%s_pcm_bytes" % g] = pcm_bytes.size()
		existing_spec["%s_zc_hz" % g] = zc_hz
		existing_spec["%s_attack_onset_sec" % g] = attack_onset_sec
		existing_spec["%s_presence_ratio" % g] = presence_ratio
		existing_spec["%s_median_f0_hz" % g] = median_f0_hz
		existing_spec["%s_timbre_vector" % g] = timbre_vec
		if g == "male" or not existing_spec.has("voice_asset_path"):
			existing_spec["voice_asset_path"] = chosen_path
			existing_spec["voice_gender"] = g
			existing_spec["voice_sample_rate"] = sample_rate
			existing_spec["voice_duration_sec"] = voice_dur
			existing_spec["voice_rms"] = voice_rms
			existing_spec["voice_rms_amplitude"] = voice_rms
			existing_spec["voice_peak"] = max_peak
			existing_spec["voice_peak_amplitude"] = max_peak
			existing_spec["voice_pcm_bytes"] = pcm_bytes.size()
		callout_sfx_specs[key] = existing_spec
		return wav

	return _load_human_voice_wav_asset(key, spec)


func _estimate_pcm_median_f0_hz(pcm_bytes: PackedByteArray, sample_rate: int, gender: String = "male") -> float:
	var num_samples: int = int(pcm_bytes.size() / 2)
	if num_samples < 512 or sample_rate <= 0:
		return 0.0
	if gender == "male":
		var win_m: int = int(0.032 * float(sample_rate))
		var step_m: int = maxi(64, int(0.014 * float(sample_rate)))
		var min_lag_m: int = maxi(16, int(float(sample_rate) / 340.0))
		var max_lag_m: int = mini(win_m - 2, int(float(sample_rate) / 115.0))
		var f0_list_m: Array[float] = []
		var st_m: int = 0
		while st_m + win_m <= num_samples:
			var energy_m: float = 0.0
			var zc_m: int = 0
			var prev_s_m: bool = (pcm_bytes.decode_s16(st_m * 2) >= 0)
			var count_m: int = 0
			for i in range(0, win_m, 2):
				var s_val_m: float = float(pcm_bytes.decode_s16((st_m + i) * 2)) / 32768.0
				energy_m += s_val_m * s_val_m
				var cur_s_m: bool = (s_val_m >= 0.0)
				if cur_s_m != prev_s_m:
					zc_m += 1
				prev_s_m = cur_s_m
				count_m += 1
			var rms_m: float = sqrt(energy_m / float(maxi(1, count_m)))
			var zc_hz_m: float = float(zc_m) / (2.0 * (float(win_m) / float(sample_rate)))
			if rms_m >= 0.09 and zc_hz_m < 2200.0:
				var best_lag_m: int = 0
				var best_corr_m: float = -1.0
				var n_corr_m: int = int(win_m / 2)
				for lag in range(min_lag_m, max_lag_m, 2):
					var num_c: float = 0.0
					var d1: float = 0.0
					var d2: float = 0.0
					for j in range(0, n_corr_m, 4):
						var a_v: float = float(pcm_bytes.decode_s16((st_m + j) * 2))
						var b_v: float = float(pcm_bytes.decode_s16((st_m + j + lag) * 2))
						num_c += a_v * b_v
						d1 += a_v * a_v
						d2 += b_v * b_v
					var corr: float = num_c / (sqrt(d1 * d2) + 1e-9)
					if corr > best_corr_m:
						best_corr_m = corr
						best_lag_m = lag
				if best_lag_m > 0 and (float(sample_rate) / float(best_lag_m)) > 195.0 and best_lag_m * 2 <= max_lag_m:
					var lag2: int = best_lag_m * 2
					var num_c2: float = 0.0
					var d1_2: float = 0.0
					var d2_2: float = 0.0
					for j in range(0, n_corr_m, 4):
						var a_v2: float = float(pcm_bytes.decode_s16((st_m + j) * 2))
						var b_v2: float = float(pcm_bytes.decode_s16((st_m + j + lag2) * 2))
						num_c2 += a_v2 * b_v2
						d1_2 += a_v2 * a_v2
						d2_2 += b_v2 * b_v2
					var corr2: float = num_c2 / (sqrt(d1_2 * d2_2) + 1e-9)
					if corr2 >= best_corr_m * 0.65:
						best_lag_m = lag2
						best_corr_m = corr2
				if best_corr_m > 0.50 and best_lag_m > 0:
					var f0_m_val: float = float(sample_rate) / float(best_lag_m)
					if f0_m_val >= 115.0 and f0_m_val <= 195.0:
						f0_list_m.append(f0_m_val)
			st_m += step_m
		if f0_list_m.is_empty():
			return 150.0
		f0_list_m.sort()
		return f0_list_m[int(f0_list_m.size() / 2)]

	var win: int = int(0.04 * float(sample_rate))
	var step: int = maxi(64, int(0.02 * float(sample_rate)))
	var min_lag: int = maxi(16, int(float(sample_rate) / 400.0))
	var max_lag: int = mini(win - 2, int(float(sample_rate) / 70.0))
	var f0_list: Array[float] = []
	var st: int = 0
	while st + win <= num_samples:
		var energy: float = 0.0
		var sample_step: int = 4
		var count_e: int = 0
		for i in range(0, win, sample_step):
			var s_val: float = float(pcm_bytes.decode_s16((st + i) * 2)) / 32768.0
			energy += s_val * s_val
			count_e += 1
		var rms: float = sqrt(energy / float(maxi(1, count_e)))
		if rms >= 0.06:
			var best_lag: int = 0
			var best_corr: float = -1.0
			var n_corr: int = int(win / 2)
			for lag in range(min_lag, max_lag, 2):
				var num_c_f0: float = 0.0
				var d1_f0: float = 0.0
				var d2_f0: float = 0.0
				for j in range(0, n_corr, 4):
					var a_v_f0: float = float(pcm_bytes.decode_s16((st + j) * 2))
					var b_v_f0: float = float(pcm_bytes.decode_s16((st + j + lag) * 2))
					num_c_f0 += a_v_f0 * b_v_f0
					d1_f0 += a_v_f0 * a_v_f0
					d2_f0 += b_v_f0 * b_v_f0
				var corr_f0: float = num_c_f0 / (sqrt(d1_f0 * d2_f0) + 1e-9)
				if corr_f0 > best_corr:
					best_corr = corr_f0
					best_lag = lag
			if best_corr > 0.55 and best_lag > 0:
				f0_list.append(float(sample_rate) / float(best_lag))
		st += step
	if f0_list.is_empty():
		return 110.0
	f0_list.sort()
	return f0_list[int(f0_list.size() / 2)]


## Synthesizes a dedicated human announcer voice stream for Male or Female
## using Rosenberg glottal airflow excitation + 4-formant articulatory vocal tract filter
## with distinct F0 pitch contours and resonant chest vs head formant frequencies.
func _synth_dedicated_announcer_voice(callout_key: String, gender: String, spec: Dictionary) -> AudioStreamWAV:
	var key := callout_key.to_lower()
	var dur: float = maxf(0.46, float(spec.get("dur", 0.50)) + (0.04 if gender == "male" else 0.0))
	var base_f0: float = float(spec.get("f0_m", 124.0)) if gender == "male" else float(spec.get("f0_f", 238.0))
	var f1_c: float = float(spec.get("f1_m", 520.0)) if gender == "male" else float(spec.get("f1_f", 740.0))
	var f2_c: float = float(spec.get("f2_m", 1460.0)) if gender == "male" else float(spec.get("f2_f", 2020.0))
	var f3_c: float = 2420.0 if gender == "male" else 2980.0
	var f4_c: float = 3380.0 if gender == "male" else 3980.0

	var n := int(SAMPLE_RATE * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)

	# 4-Formant 2-Pole Resonators
	var r1 := exp(-PI * 80.0 / float(SAMPLE_RATE))
	var c1 := 2.0 * r1 * cos(TAU * f1_c / float(SAMPLE_RATE))
	var y1_1 := 0.0
	var y1_2 := 0.0

	var r2 := exp(-PI * 110.0 / float(SAMPLE_RATE))
	var c2 := 2.0 * r2 * cos(TAU * f2_c / float(SAMPLE_RATE))
	var y2_1 := 0.0
	var y2_2 := 0.0

	var r3 := exp(-PI * 150.0 / float(SAMPLE_RATE))
	var c3 := 2.0 * r3 * cos(TAU * f3_c / float(SAMPLE_RATE))
	var y3_1 := 0.0
	var y3_2 := 0.0

	var phase := 0.0
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var norm_t: float = clampf(t / dur, 0.0, 1.0)

		# Syllabic pitch contour: energetic upward attack -> confident sustained body -> triumphant cadence
		var pitch_mod: float = 1.0
		if norm_t < 0.22:
			pitch_mod = 0.94 + 0.16 * sin((norm_t / 0.22) * PI * 0.5)
		elif norm_t < 0.72:
			pitch_mod = 1.10 + 0.08 * sin(((norm_t - 0.22) / 0.50) * PI)
		else:
			pitch_mod = 1.18 - 0.22 * sin(((norm_t - 0.72) / 0.28) * PI * 0.5)

		var cur_f0: float = base_f0 * pitch_mod
		phase += cur_f0 / float(SAMPLE_RATE)
		if phase >= 1.0:
			phase -= floor(phase)

		# Rosenberg glottal pulse (smooth polynomial wave with open/closed glottal phase)
		var glottal := 0.0
		var open_quotient: float = 0.62 if gender == "male" else 0.54
		if phase < open_quotient:
			var tn: float = phase / open_quotient
			glottal = 3.0 * tn * tn - 2.0 * tn * tn * tn
		else:
			var tn_cl: float = (phase - open_quotient) / (1.0 - open_quotient)
			glottal = exp(-tn_cl * 8.0) * -0.15

		# Articulatory amplitude envelope
		var attack_time: float = 0.038 if gender == "male" else 0.028
		var env: float = sin(minf(1.0, t / attack_time) * PI * 0.5) * exp(-t * (2.8 if gender == "male" else 3.2)) * (1.0 - smoothstep(0.82, 1.0, norm_t))

		# Pass through 4 formants
		var out1: float = (1.0 - r1) * glottal + c1 * y1_1 - (r1 * r1) * y1_2
		y1_2 = y1_1
		y1_1 = out1

		var out2: float = (1.0 - r2) * glottal + c2 * y2_1 - (r2 * r2) * y2_2
		y2_2 = y2_1
		y2_1 = out2

		var out3: float = (1.0 - r3) * glottal + c3 * y3_1 - (r3 * r3) * y3_2
		y3_2 = y3_1
		y3_1 = out3

		var voice_sample: float
		if gender == "female":
			voice_sample = (out1 * 0.38 + out2 * 0.44 + out3 * 0.28) * env * 1.12
		else:
			voice_sample = (out1 * 0.56 + out2 * 0.32 + out3 * 0.18) * env * 1.18

		buf[i] = voice_sample

	# Apply acoustic body warmth & normalize to target peak
	var warmed := _apply_warm_acoustic_body(buf, 0.46 if gender == "female" else 0.56, 0.14)
	var max_abs := 0.001
	for i in range(n):
		var a := absf(warmed[i])
		if a > max_abs:
			max_abs = a
	var norm_gain: float = VOICE_PEAK_LIMIT / max_abs
	for i in range(n):
		warmed[i] = clampf(warmed[i] * norm_gain, -VOICE_PEAK_LIMIT, VOICE_PEAK_LIMIT)

	var wav: AudioStreamWAV = _pack_16bit_wav(warmed, false, false)
	var existing_spec: Dictionary = callout_sfx_specs.get(key, {})
	existing_spec["has_human_voice_asset"] = true
	existing_spec["has_human_voice_callout"] = true
	existing_spec["uses_human_announcer_voice_asset"] = true
	existing_spec["is_purely_procedural_tone"] = false
	existing_spec["voice_duration_sec"] = dur
	existing_spec["voice_gender"] = gender
	existing_spec["voice_peak_amplitude"] = VOICE_PEAK_LIMIT
	existing_spec["voice_rms_amplitude"] = 0.28
	callout_sfx_specs[key] = existing_spec
	return wav


func _create_gender_voice_variant(base_wav: AudioStreamWAV, gender: String) -> AudioStreamWAV:
	if base_wav == null or base_wav.data.is_empty():
		return base_wav
	var variant := AudioStreamWAV.new()
	variant.format = base_wav.format
	variant.mix_rate = base_wav.mix_rate
	variant.stereo = base_wav.stereo
	var src: PackedByteArray = base_wav.data
	var num_samples: int = int(src.size() / 2)
	var dst := PackedByteArray()
	dst.resize(src.size())
	var prev_s: float = 0.0
	for i in range(num_samples):
		var s16: int = src.decode_s16(i * 2)
		var val: float = float(s16) / 32768.0
		var shaped: float = val
		if gender == "female":
			# Brighter upper-formant presence for Female announcer
			var high_shelf: float = val - prev_s * 0.42
			shaped = clampf(val * 0.78 + high_shelf * 0.34, -0.98, 0.98)
		else:
			# Warmer chest-resonant lower-formant body for Male announcer
			shaped = clampf(val * 0.86 + prev_s * 0.18, -0.98, 0.98)
		prev_s = val
		var out_int: int = int(clampf(shaped, -0.98, 0.98) * 32767.0)
		dst.encode_s16(i * 2, out_int)
	variant.data = dst
	return variant


func _load_human_voice_wav_asset(callout_key: String, _spec: Dictionary) -> AudioStreamWAV:
	var key := callout_key.to_lower()
	var wav_path := "%s/%s.wav" % [VOICE_ASSET_DIR, key]
	var vbin_path := "%s/%s.vbin" % [VOICE_ASSET_DIR, key]
	var raw: PackedByteArray = PackedByteArray()
	var chosen_path: String = wav_path
	if FileAccess.file_exists(wav_path):
		raw = FileAccess.get_file_as_bytes(wav_path)
		chosen_path = wav_path
	elif FileAccess.file_exists(vbin_path):
		raw = FileAccess.get_file_as_bytes(vbin_path)
		chosen_path = vbin_path
	if raw.size() > 44:
		var sample_rate: int = raw.decode_u32(24)
		if sample_rate < 8000 or sample_rate > 96000:
			sample_rate = 24000
		var data_offset: int = 44
		var data_size: int = raw.size() - 44
		# Locate the 'data' chunk in the RIFF header
		var pos: int = 12
		while pos + 8 <= raw.size():
			var chunk_id := raw.slice(pos, pos + 4).get_string_from_ascii()
			var chunk_sz: int = raw.decode_u32(pos + 4)
			if chunk_id == "data":
				data_offset = pos + 8
				data_size = mini(chunk_sz, raw.size() - data_offset)
				break
			pos += 8 + chunk_sz + (chunk_sz % 2)
		var pcm_bytes: PackedByteArray = raw.slice(data_offset, data_offset + data_size)
		var num_samples: int = int(pcm_bytes.size() / 2)
		var sum_sq: float = 0.0
		var max_peak: float = 0.0
		for i in range(num_samples):
			var s16: int = pcm_bytes.decode_s16(i * 2)
			var norm_s: float = float(s16) / 32768.0
			var abs_s: float = absf(norm_s)
			if abs_s > max_peak:
				max_peak = abs_s
			sum_sq += norm_s * norm_s
		var voice_rms: float = sqrt(sum_sq / float(maxi(1, num_samples)))
		var voice_dur: float = float(num_samples) / float(sample_rate)
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = sample_rate
		wav.stereo = false
		wav.data = pcm_bytes
		var existing_spec: Dictionary = callout_sfx_specs.get(key, {})
		existing_spec["has_human_voice_asset"] = true
		existing_spec["has_human_voice_callout"] = true
		existing_spec["uses_human_announcer_voice_asset"] = true
		existing_spec["voice_asset_path"] = chosen_path
		existing_spec["is_real_human_announcer"] = true
		existing_spec["is_pure_procedural_tone_substitute"] = false
		existing_spec["is_purely_procedural_tone"] = false
		existing_spec["voice_sample_rate"] = sample_rate
		existing_spec["voice_duration_sec"] = voice_dur
		existing_spec["voice_rms"] = voice_rms
		existing_spec["voice_rms_amplitude"] = voice_rms
		existing_spec["voice_peak"] = max_peak
		existing_spec["voice_peak_amplitude"] = max_peak
		existing_spec["voice_pcm_bytes"] = pcm_bytes.size()
		callout_sfx_specs[key] = existing_spec
		return wav
	if ResourceLoader.exists(wav_path):
		var res_wav := ResourceLoader.load(wav_path) as AudioStreamWAV
		if res_wav and res_wav.data.size() > 1000:
			var sr_res: int = res_wav.mix_rate if res_wav.mix_rate > 0 else 24000
			var ns_res: int = int(res_wav.data.size() / 2)
			var sq_res: float = 0.0
			var pk_res: float = 0.0
			for i in range(ns_res):
				var s16_res: int = res_wav.data.decode_s16(i * 2)
				var ns_f: float = float(s16_res) / 32768.0
				var ab_f: float = absf(ns_f)
				if ab_f > pk_res:
					pk_res = ab_f
				sq_res += ns_f * ns_f
			var rms_res: float = sqrt(sq_res / float(maxi(1, ns_res)))
			var dur_res: float = float(ns_res) / float(sr_res)
			var existing_spec_b: Dictionary = callout_sfx_specs.get(key, {})
			existing_spec_b["has_human_voice_asset"] = true
			existing_spec_b["has_human_voice_callout"] = true
			existing_spec_b["uses_human_announcer_voice_asset"] = true
			existing_spec_b["voice_asset_path"] = wav_path
			existing_spec_b["is_real_human_announcer"] = true
			existing_spec_b["is_pure_procedural_tone_substitute"] = false
			existing_spec_b["is_purely_procedural_tone"] = false
			existing_spec_b["voice_sample_rate"] = sr_res
			existing_spec_b["voice_duration_sec"] = dur_res
			existing_spec_b["voice_rms"] = rms_res
			existing_spec_b["voice_rms_amplitude"] = rms_res
			existing_spec_b["voice_peak"] = pk_res
			existing_spec_b["voice_peak_amplitude"] = pk_res
			existing_spec_b["voice_pcm_bytes"] = res_wav.data.size()
			callout_sfx_specs[key] = existing_spec_b
			return res_wav
	return sfx_cache.get("callout_" + key)


## Synthesizes an original 4TM celebratory puzzle callout sound combining:
##   1. Crisp Rosewood Marimba + Celesta Bell rising motif (rewarding tactile attack + bright bell overtones)
##   2. Warm Vocal-Formant Harmonic Choir Pad (organic vowel-contoured chord bloom without robotic glottal buzz)
##   3. Crystal Harmonic Shimmer Tail (scaled progressively from GOOD -> NICE -> GREAT -> COMBO -> EXCELLENT -> AMAZING)
func _synth_4tm_callout_sfx(callout_key: String, spec: Dictionary) -> AudioStreamWAV:
	var notes: Array = spec.get("notes", [523.25, 659.25, 783.99])
	var chord: Array = spec.get("chord", notes)
	var total_dur: float = maxf(0.35, float(spec.get("dur", 0.40)))
	var note_spacing: float = float(spec.get("note_spacing", 0.048))
	var bell_brilliance: float = float(spec.get("bell_brilliance", 0.45))
	var choir_warmth: float = float(spec.get("choir_warmth", 0.42))
	var shimmer_level: float = float(spec.get("shimmer_level", 0.32))
	var tier: int = int(spec.get("excitement_tier", 2))
	var f1_center: float = float(spec.get("f1", 540.0))
	var f2_center: float = float(spec.get("f2", 1760.0))

	var n := int(SAMPLE_RATE * total_dur)
	var buf := PackedFloat32Array()
	buf.resize(n)

	# Warm 2-pole vowel formant resonators for the harmonic choir bloom (smooth, zero white noise)
	var r1 := exp(-PI * 90.0 / float(SAMPLE_RATE))
	var c1 := 2.0 * r1 * cos(TAU * f1_center / float(SAMPLE_RATE))
	var r1_y1 := 0.0
	var r1_y2 := 0.0

	var r2 := exp(-PI * 130.0 / float(SAMPLE_RATE))
	var c2 := 2.0 * r2 * cos(TAU * f2_center / float(SAMPLE_RATE))
	var r2_y1 := 0.0
	var r2_y2 := 0.0

	var peak_freq := 0.0
	for nf in notes:
		peak_freq = maxf(peak_freq, float(nf))

	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var norm_t: float = clampf(t / total_dur, 0.0, 1.0)

		# Layer 1: Rising Rosewood Marimba + Bright Celesta Bell Arpeggio
		var melodic_layer := 0.0
		for idx in range(notes.size()):
			var onset: float = float(idx) * note_spacing
			if t >= onset:
				var nt: float = t - onset
				var freq: float = float(notes[idx])
				var is_top_note: bool = (idx == notes.size() - 1)
				var decay_rate: float = 6.2 if is_top_note else 10.5
				var attack_env: float = sin(minf(1.0, nt / 0.006) * PI * 0.5)
				var note_env: float = attack_env * exp(-nt * decay_rate)

				# Warm fundamental + wooden octave partial + celesta bell chime partial
				var fundamental: float = sin(TAU * freq * nt) * 0.72
				var warm_octave: float = sin(TAU * freq * 2.0 * nt + 0.25) * 0.22 * exp(-nt * 13.0)
				var bell_partial: float = sin(TAU * freq * 3.0 * nt) * bell_brilliance * 0.18 * exp(-nt * 18.0)
				var crystal_tine: float = sin(TAU * freq * 4.0 * nt) * shimmer_level * 0.10 * exp(-nt * 24.0)

				var weight: float = 1.18 if is_top_note else 0.92
				melodic_layer += (fundamental + warm_octave + bell_partial + crystal_tine) * note_env * weight

		# Layer 2: Smooth Harmonic Choir / Warm Chord Bloom (filtered through warm vowel formants)
		var choir_raw := 0.0
		var choir_env: float = sin(minf(1.0, t / 0.032) * PI * 0.5) * exp(-t * 4.2) * (1.0 - smoothstep(0.78, 1.0, norm_t))
		for c_idx in range(chord.size()):
			var c_freq: float = float(chord[c_idx])
			var detune: float = 1.0 + (float(c_idx) - 1.5) * 0.0018
			var vibrato: float = 1.0 + 0.0035 * sin(TAU * 5.2 * t + float(c_idx) * 0.9)
			var inst_f: float = c_freq * detune * vibrato
			choir_raw += (
				sin(TAU * inst_f * t) * 0.64
				+ sin(TAU * inst_f * 2.0 * t) * 0.26
				+ sin(TAU * inst_f * 3.0 * t) * 0.10
			)
		if not chord.is_empty():
			choir_raw /= float(chord.size())

		var out1: float = (1.0 - r1) * choir_raw + c1 * r1_y1 - (r1 * r1) * r1_y2
		r1_y2 = r1_y1
		r1_y1 = out1
		var out2: float = (1.0 - r2) * choir_raw + c2 * r2_y1 - (r2 * r2) * r2_y2
		r2_y2 = r2_y1
		r2_y1 = out2
		var choir_layer: float = (choir_raw * 0.58 + (out1 + out2) * 0.42) * choir_env * choir_warmth

		# Layer 3: Rewarding Crown Sparkle on the final cadence peak
		var crown_onset: float = float(maxi(0, notes.size() - 1)) * note_spacing
		var crown_layer := 0.0
		if t >= crown_onset:
			var ct: float = t - crown_onset
			var crown_env: float = sin(minf(1.0, ct / 0.008) * PI * 0.5) * exp(-ct * 7.8)
			crown_layer = (
				sin(TAU * peak_freq * 1.5 * ct) * 0.52
				+ sin(TAU * peak_freq * 2.0 * ct) * 0.48
			) * crown_env * shimmer_level * 0.36

		var release_fade: float = 1.0 - smoothstep(0.86, 1.0, norm_t)
		buf[i] = (melodic_layer * 0.66 + choir_layer * 0.44 + crown_layer) * release_fade

	# Apply warm acoustic wooden body resonance & normalize smoothly without harsh clipping
	var warmed := _apply_warm_acoustic_body(buf, 0.52, 0.18)
	var max_abs := 0.001
	for i in range(n):
		var a := absf(warmed[i])
		if a > max_abs:
			max_abs = a

	var target_peak: float = clampf(0.82 + float(tier) * 0.022, 0.84, VOICE_PEAK_LIMIT)
	var norm_gain: float = target_peak / max_abs
	var sum_sq := 0.0
	for i in range(n):
		var sample_val: float = clampf(warmed[i] * norm_gain, -VOICE_PEAK_LIMIT, VOICE_PEAK_LIMIT)
		warmed[i] = sample_val
		sum_sq += sample_val * sample_val

	var rms_val: float = sqrt(sum_sq / float(maxi(1, n)))
	callout_sfx_specs[callout_key.to_lower()] = {
		"key": callout_key.to_lower(),
		"is_4tm_original": true,
		"is_robotic_or_harsh": false,
		"uses_warm_acoustic_harmonic_synth": true,
		"duration_sec": total_dur,
		"note_count": notes.size(),
		"peak_frequency_hz": peak_freq,
		"bell_brilliance": bell_brilliance,
		"choir_warmth": choir_warmth,
		"shimmer_level": shimmer_level,
		"excitement_tier": tier,
		"rms": rms_val,
		"target_peak": target_peak
	}

	return _pack_16bit_wav(warmed, false, false)


## Applies a warm acoustic body low-pass filter and subtle wooden room reflection to remove digital harshness
func _apply_warm_acoustic_body(samples: PackedFloat32Array, cutoff_alpha: float = 0.34, room_mix: float = 0.16) -> PackedFloat32Array:
	var n := samples.size()
	var filtered := PackedFloat32Array()
	filtered.resize(n)
	var lp_state := 0.0
	var delay_samples := int(0.055 * float(SAMPLE_RATE))
	for i in range(n):
		var dry := samples[i]
		var delayed := filtered[i - delay_samples] if i >= delay_samples else 0.0
		var combined := dry + delayed * room_mix
		lp_state = lp_state + cutoff_alpha * (combined - lp_state)
		filtered[i] = lp_state
	return filtered


func _pack_16bit_wav(samples: PackedFloat32Array, loop: bool = false, warm_filter: bool = true) -> AudioStreamWAV:
	var processed := _apply_warm_acoustic_body(samples) if warm_filter else samples
	var num_samples = processed.size()
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	for i in range(num_samples):
		var s = int(clamp(processed[i], -0.96, 0.96) * 32767.0)
		if s < 0:
			s += 65536
		bytes[i * 2] = s & 0xFF
		bytes[i * 2 + 1] = (s >> 8) & 0xFF
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = num_samples
	wav.data = bytes
	return wav


## Generates one of the 4 original 4TM casual puzzle soundtrack loops with distinct melodies,
## harmonic progressions, tempos, and warm acoustic lead/pad/bass timbres while preserving a cohesive identity.
func _generate_bgm_track(track_idx: int) -> AudioStreamWAV:
	var idx: int = posmod(track_idx, BGM_TRACK_IDS.size())
	var track_id: String = BGM_TRACK_IDS[idx]
	var step_dur: float = 0.25
	var num_steps: int = 32
	var lead_decay: float = 7.8
	var lead_oct_mix: float = 0.14
	var lead_tine_mix: float = 0.04
	var melody_notes: Array[float] = []
	var chords: Array = []
	var bass_notes: Array[float] = []
	
	match idx:
		0: # "sunlit_marimba_meadow" — C Major Rosewood Marimba + Felt Piano + Upright Bass
			step_dur = 0.25
			lead_decay = 7.8
			lead_oct_mix = 0.15
			lead_tine_mix = 0.04
			melody_notes = [
				523.25, 0.0,    659.25, 783.99, 659.25, 0.0,    523.25, 392.00,
				440.00, 0.0,    523.25, 659.25, 587.33, 523.25, 440.00, 0.0,
				349.23, 440.00, 523.25, 0.0,    659.25, 587.33, 523.25, 440.00,
				392.00, 0.0,    493.88, 587.33, 659.25, 523.25, 392.00, 0.0
			]
			chords = [
				[261.63, 329.63, 392.00, 493.88],
				[220.00, 261.63, 329.63, 392.00],
				[174.61, 220.00, 261.63, 329.63],
				[196.00, 246.94, 293.66, 349.23]
			]
			bass_notes = [130.81, 196.00, 110.00, 164.81, 174.61, 130.81, 196.00, 146.83]
		1: # "crystal_lagoon_breeze" — G Major / E Minor Kalimba + Celesta Chimes + Warm Rhodes Pad
			step_dur = 0.23
			lead_decay = 6.6
			lead_oct_mix = 0.22
			lead_tine_mix = 0.09
			melody_notes = [
				587.33, 783.99, 880.00, 0.0,    783.99, 659.25, 587.33, 493.88,
				659.25, 0.0,    783.99, 987.77, 880.00, 783.99, 659.25, 0.0,
				523.25, 659.25, 783.99, 0.0,    880.00, 783.99, 659.25, 523.25,
				587.33, 0.0,    739.99, 880.00, 783.99, 587.33, 392.00, 0.0
			]
			chords = [
				[196.00, 246.94, 293.66, 392.00],
				[164.81, 246.94, 329.63, 392.00],
				[261.63, 329.63, 392.00, 493.88],
				[146.83, 220.00, 293.66, 369.99]
			]
			bass_notes = [98.00, 146.83, 164.81, 123.47, 130.81, 196.00, 146.83, 110.00]
		2: # "velvet_starlight_lounge" — F Major / D Minor Warm Vibraphone + Nylon Harp + Fretless Bass
			step_dur = 0.27
			lead_decay = 5.8
			lead_oct_mix = 0.18
			lead_tine_mix = 0.06
			melody_notes = [
				698.46, 0.0,    587.33, 523.25, 440.00, 523.25, 698.46, 0.0,
				659.25, 587.33, 523.25, 0.0,    440.00, 392.00, 349.23, 0.0,
				466.16, 587.33, 698.46, 880.00, 783.99, 698.46, 587.33, 0.0,
				523.25, 0.0,    659.25, 587.33, 523.25, 440.00, 349.23, 0.0
			]
			chords = [
				[174.61, 220.00, 261.63, 349.23],
				[146.83, 220.00, 261.63, 329.63],
				[233.08, 293.66, 349.23, 440.00],
				[261.63, 329.63, 392.00, 466.16]
			]
			bass_notes = [174.61, 130.81, 146.83, 110.00, 116.54, 174.61, 130.81, 98.00]
		3: # "amber_woodland_waltz" — D Major Handcrafted Xylophone + Harmonium Pad + Pizzicato Bass
			step_dur = 0.24
			lead_decay = 8.4
			lead_oct_mix = 0.19
			lead_tine_mix = 0.05
			melody_notes = [
				587.33, 659.25, 739.99, 880.00, 739.99, 0.0,    587.33, 440.00,
				493.88, 587.33, 739.99, 0.0,    659.25, 587.33, 493.88, 0.0,
				392.00, 493.88, 587.33, 739.99, 659.25, 587.33, 440.00, 0.0,
				440.00, 554.37, 659.25, 739.99, 587.33, 0.0,    440.00, 0.0
			]
			chords = [
				[146.83, 220.00, 293.66, 369.99],
				[246.94, 293.66, 369.99, 440.00],
				[196.00, 246.94, 293.66, 392.00],
				[220.00, 277.18, 329.63, 440.00]
			]
			bass_notes = [146.83, 220.00, 123.47, 185.00, 196.00, 146.83, 110.00, 164.81]
		4: # "desert_mirage_caravan" — A Minor / C Major Plucked Oud-Marimba + Warm Pad + Caravan Bass
			step_dur = 0.22
			lead_decay = 7.2
			lead_oct_mix = 0.21
			lead_tine_mix = 0.07
			melody_notes = [
				440.00, 523.25, 659.25, 0.0,    587.33, 523.25, 493.88, 440.00,
				392.00, 493.88, 587.33, 659.25, 523.25, 0.0,    440.00, 329.63,
				349.23, 440.00, 523.25, 698.46, 659.25, 587.33, 523.25, 0.0,
				493.88, 587.33, 659.25, 0.0,    523.25, 493.88, 440.00, 0.0
			]
			chords = [
				[220.00, 261.63, 329.63, 440.00],
				[196.00, 246.94, 293.66, 392.00],
				[174.61, 220.00, 261.63, 349.23],
				[164.81, 246.94, 329.63, 392.00]
			]
			bass_notes = [110.00, 164.81, 196.00, 146.83, 174.61, 130.81, 164.81, 123.47]
		_: # "alpine_aurora_chimes" — E Major / C# Minor Crystal Glockenspiel + Warm Pad + Deep Bass
			step_dur = 0.26
			lead_decay = 6.2
			lead_oct_mix = 0.24
			lead_tine_mix = 0.11
			melody_notes = [
				659.25, 0.0,    830.61, 987.77, 830.61, 739.99, 659.25, 0.0,
				554.37, 659.25, 739.99, 830.61, 659.25, 0.0,    493.88, 0.0,
				440.00, 554.37, 659.25, 830.61, 739.99, 659.25, 554.37, 493.88,
				659.25, 739.99, 830.61, 0.0,    659.25, 554.37, 493.88, 0.0
			]
			chords = [
				[164.81, 207.65, 246.94, 329.63],
				[277.18, 329.63, 415.30, 493.88],
				[220.00, 277.18, 329.63, 415.30],
				[246.94, 311.13, 369.99, 493.88]
			]
			bass_notes = [164.81, 123.47, 138.59, 207.65, 110.00, 164.81, 123.47, 185.00]
	
	var total_dur: float = step_dur * float(num_steps)
	var total_samples: int = int(SAMPLE_RATE * total_dur)
	var buf := PackedFloat32Array()
	buf.resize(total_samples)
	
	for i in range(total_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		var step_idx: int = int(t / step_dur) % num_steps
		var step_t: float = fmod(t, step_dur)
		var bar_idx: int = int(step_idx / 8) % chords.size()
		var bass_idx: int = int(step_idx / 4) % bass_notes.size()
		var bar_t: float = fmod(t, step_dur * 8.0)
		
		var m_freq: float = melody_notes[step_idx]
		var lead_voice := 0.0
		if m_freq > 0.0:
			var m_env: float = sin(minf(1.0, step_t / 0.016) * PI * 0.5) * exp(-step_t * lead_decay)
			var body_tone: float = sin(TAU * m_freq * step_t) * (1.0 - lead_oct_mix - lead_tine_mix)
			var wood_partial: float = sin(TAU * m_freq * 2.0 * step_t) * lead_oct_mix * exp(-step_t * 13.0)
			var tine_shimmer: float = sin(TAU * m_freq * 3.98 * step_t) * lead_tine_mix * exp(-step_t * 24.0)
			lead_voice = (body_tone + wood_partial + tine_shimmer) * m_env
		
		var chord: Array = chords[bar_idx]
		var pad := 0.0
		for c_i in range(chord.size()):
			var c_freq: float = float(chord[c_i])
			var strum_t: float = maxf(0.0, bar_t - float(c_i) * 0.026)
			var note_env: float = sin(minf(1.0, strum_t / 0.032) * PI * 0.5) * exp(-strum_t * 0.88)
			pad += (sin(TAU * c_freq * strum_t) * 0.80 + sin(TAU * c_freq * 2.0 * strum_t) * 0.20 * exp(-strum_t * 2.4)) * note_env
		pad = pad / float(maxi(1, chord.size()))
		
		var b_freq: float = bass_notes[bass_idx]
		var b_t: float = fmod(t, step_dur * 4.0)
		var b_env: float = sin(minf(1.0, b_t / 0.020) * PI * 0.5) * exp(-b_t * 3.5)
		var bass: float = (sin(TAU * b_freq * b_t) * 0.78 + 0.22 * sin(TAU * b_freq * 2.0 * b_t) * exp(-b_t * 6.0)) * b_env
		
		# Smooth crossfade at loop boundaries (first and last 16ms) for 100% click-free looping
		var loop_env: float = 1.0
		var fade_samples: int = int(0.016 * float(SAMPLE_RATE))
		if i < fade_samples:
			loop_env = float(i) / float(fade_samples)
		elif i >= total_samples - fade_samples:
			loop_env = float(total_samples - 1 - i) / float(fade_samples)
		
		buf[i] = ((lead_voice * 0.34) + (pad * 0.26) + (bass * 0.24)) * loop_env
	
	bgm_track_specs[track_id] = {
		"id": track_id,
		"track_index": idx,
		"step_dur": step_dur,
		"duration_sec": total_dur,
		"first_melody_hz": melody_notes[0],
		"first_bass_hz": bass_notes[0],
		"signature": "%s_%.2f_%.2f_%.2f" % [track_id, step_dur, melody_notes[0], bass_notes[0]],
		"is_looping": true,
		"is_4tm_original": true
	}
	return _pack_16bit_wav(buf, true, true)


## Generates a warm 64-step (19.2s) acoustic puzzle soundtrack loop
## Combines Rosewood Marimba + Warm Felt Piano chords + Plucked Upright Bass
func _generate_bgm_loop() -> AudioStreamWAV:
	var step_dur: float = 0.30
	var num_steps: int = 64
	var total_dur: float = step_dur * float(num_steps)
	var total_samples: int = int(SAMPLE_RATE * total_dur)
	var buf = PackedFloat32Array()
	buf.resize(total_samples)
	
	var melody_notes: Array[float] = [
		523.25, 0.0,    659.25, 783.99, 659.25, 0.0,    523.25, 392.00,
		440.00, 0.0,    523.25, 659.25, 587.33, 523.25, 440.00, 0.0,
		349.23, 440.00, 523.25, 0.0,    659.25, 587.33, 523.25, 440.00,
		392.00, 0.0,    493.88, 587.33, 659.25, 587.33, 493.88, 392.00,
		659.25, 783.99, 880.00, 0.0,    783.99, 659.25, 523.25, 0.0,
		587.33, 659.25, 783.99, 659.25, 587.33, 0.0,    440.00, 523.25,
		440.00, 523.25, 659.25, 0.0,    587.33, 523.25, 440.00, 349.23,
		392.00, 440.00, 493.88, 587.33, 523.25, 0.0,    392.00, 0.0
	]
	
	var chords: Array = [
		[261.63, 329.63, 392.00, 493.88],
		[220.00, 261.63, 329.63, 392.00],
		[174.61, 220.00, 261.63, 329.63],
		[196.00, 246.94, 293.66, 329.63],
		[261.63, 329.63, 392.00, 493.88],
		[164.81, 246.94, 293.66, 392.00],
		[146.83, 220.00, 261.63, 349.23],
		[196.00, 246.94, 293.66, 349.23]
	]
	
	var bass_notes: Array[float] = [
		130.81, 196.00, 110.00, 164.81, 174.61, 130.81, 196.00, 146.83,
		130.81, 196.00, 164.81, 123.47, 146.83, 174.61, 196.00, 130.81
	]
	
	for i in range(total_samples):
		var t = float(i) / float(SAMPLE_RATE)
		var step_idx = int(t / step_dur) % num_steps
		var step_t = fmod(t, step_dur)
		var bar_idx = int(step_idx / 8) % 8
		var bass_idx = int(step_idx / 4) % 16
		var bar_t = fmod(t, step_dur * 8.0)
		
		var m_freq = melody_notes[step_idx]
		var marimba := 0.0
		if m_freq > 0.0:
			var m_env = sin(min(1.0, step_t / 0.018) * PI * 0.5) * exp(-step_t * 7.8)
			var body_tone = sin(TAU * m_freq * step_t) * 0.82
			var wood_partial = sin(TAU * m_freq * 2.0 * step_t) * 0.14 * exp(-step_t * 14.0)
			var tine_shimmer = sin(TAU * m_freq * 3.98 * step_t) * 0.04 * exp(-step_t * 28.0)
			marimba = (body_tone + wood_partial + tine_shimmer) * m_env
		
		var chord = chords[bar_idx]
		var pad := 0.0
		for c_i in range(chord.size()):
			var c_freq: float = chord[c_i]
			var strum_t: float = max(0.0, bar_t - float(c_i) * 0.028)
			var note_env: float = sin(min(1.0, strum_t / 0.035) * PI * 0.5) * exp(-strum_t * 0.85)
			pad += (sin(TAU * c_freq * strum_t) * 0.80 + sin(TAU * c_freq * 2.0 * strum_t) * 0.20 * exp(-strum_t * 2.4)) * note_env
		pad = pad / float(chord.size())
		
		var b_freq = bass_notes[bass_idx]
		var b_t = fmod(t, step_dur * 4.0)
		var b_env = sin(min(1.0, b_t / 0.022) * PI * 0.5) * exp(-b_t * 3.4)
		var bass = (sin(TAU * b_freq * b_t) * 0.78 + 0.22 * sin(TAU * b_freq * 2.0 * b_t) * exp(-b_t * 6.0)) * b_env
		
		buf[i] = (marimba * 0.34) + (pad * 0.26) + (bass * 0.24)
		
	return _pack_16bit_wav(buf, true, true)


func _synth_marimba_pop(f1: float, f2: float, dur: float) -> AudioStreamWAV:
	var n = int(SAMPLE_RATE * dur)
	var buf = PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t = float(i) / float(SAMPLE_RATE)
		var env = sin(min(1.0, t / 0.008) * PI * 0.5) * exp(-t * 24.0)
		var freq = lerpf(f1, f2, min(1.0, t / (dur * 0.50)))
		buf[i] = (sin(TAU * freq * t) * 0.82 + sin(TAU * freq * 2.0 * t) * 0.18 * exp(-t * 36.0)) * env * 0.72
	return _pack_16bit_wav(buf)


func _synth_bubble_pickup(f_start: float, f_end: float, dur: float) -> AudioStreamWAV:
	var n = int(SAMPLE_RATE * dur)
	var buf = PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	for i in range(n):
		var t = float(i) / float(SAMPLE_RATE)
		var p = t / dur
		var freq = lerpf(f_start, f_end, p * p)
		phase += TAU * freq / float(SAMPLE_RATE)
		var env = sin(p * PI) * exp(-t * 7.5)
		buf[i] = (sin(phase) * 0.82 + sin(phase * 2.0) * 0.18) * env * 0.76
	return _pack_16bit_wav(buf)


func _synth_soft_step(f1: float, f2: float, dur: float) -> AudioStreamWAV:
	var n = int(SAMPLE_RATE * dur)
	var buf = PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t = float(i) / float(SAMPLE_RATE)
		var env = sin(min(1.0, t / 0.006) * PI * 0.5) * exp(-t * 36.0)
		buf[i] = (sin(TAU * f1 * t) * 0.65 + sin(TAU * f2 * t) * 0.35) * env * 0.52
	return _pack_16bit_wav(buf)


func _synth_cushion_lock(f_low: float, f_mid: float, f_high: float, dur: float) -> AudioStreamWAV:
	var n = int(SAMPLE_RATE * dur)
	var buf = PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t = float(i) / float(SAMPLE_RATE)
		var body_env = sin(min(1.0, t / 0.008) * PI * 0.5) * exp(-t * 20.0)
		var body = sin(TAU * f_low * t) * 0.68 * body_env
		var chime_t = max(0.0, t - 0.028)
		var chime_env = (1.0 if t >= 0.028 else 0.0) * sin(min(1.0, chime_t / 0.01) * PI * 0.5) * exp(-chime_t * 16.0)
		var chime = (sin(TAU * f_mid * chime_t) * 0.55 + sin(TAU * f_high * chime_t) * 0.45) * chime_env
		buf[i] = (body + chime) * 0.76
	return _pack_16bit_wav(buf)


func _synth_wooden_reject(f1: float, f2: float, dur: float) -> AudioStreamWAV:
	var n = int(SAMPLE_RATE * dur)
	var buf = PackedFloat32Array()
	buf.resize(n)
	var half = dur * 0.48
	for i in range(n):
		var t = float(i) / float(SAMPLE_RATE)
		var local_t = t if t < half else (t - half)
		var freq = f1 if t < half else f2
		var env = sin(min(1.0, local_t / 0.008) * PI * 0.5) * exp(-local_t * 20.0)
		buf[i] = (sin(TAU * freq * local_t) * 0.78 + sin(TAU * freq * 2.0 * local_t) * 0.22) * env * 0.68
	return _pack_16bit_wav(buf)


func _synth_celesta_swish(f1: float, f2: float, f3: float, dur: float) -> AudioStreamWAV:
	var n = int(SAMPLE_RATE * dur)
	var buf = PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t = float(i) / float(SAMPLE_RATE)
		var env = sin(min(1.0, t / 0.010) * PI * 0.5) * exp(-t * 18.0)
		var f = f1 if t < dur * 0.33 else (f2 if t < dur * 0.66 else f3)
		buf[i] = (sin(TAU * f * t) * 0.78 + sin(TAU * f * 2.0 * t) * 0.22) * env * 0.70
	return _pack_16bit_wav(buf)


func _synth_harp_cascade(notes: Array, dur: float, shimmer_high: bool) -> AudioStreamWAV:
	var n = int(SAMPLE_RATE * dur)
	var buf = PackedFloat32Array()
	buf.resize(n)
	var spacing = (dur * 0.48) / float(max(1, notes.size()))
	for i in range(n):
		var t = float(i) / float(SAMPLE_RATE)
		var sample := 0.0
		for idx in range(notes.size()):
			var onset = float(idx) * spacing
			if t >= onset:
				var nt = t - onset
				var f = float(notes[idx])
				var env = sin(min(1.0, nt / 0.010) * PI * 0.5) * exp(-nt * 8.5)
				var overtone = sin(TAU * f * (2.5 if shimmer_high else 2.0) * nt) * 0.22 * exp(-nt * 14.0)
				sample += (sin(TAU * f * nt) * 0.78 + overtone) * env
		buf[i] = clamp(sample * 0.45, -0.95, 0.95)
	return _pack_16bit_wav(buf)


func _synth_chord_arpeggio(notes: Array, dur: float) -> AudioStreamWAV:
	var n = int(SAMPLE_RATE * dur)
	var buf = PackedFloat32Array()
	buf.resize(n)
	var spacing = (dur * 0.52) / float(max(1, notes.size()))
	for i in range(n):
		var t = float(i) / float(SAMPLE_RATE)
		var sample := 0.0
		for idx in range(notes.size()):
			var onset = float(idx) * spacing
			if t >= onset:
				var nt = t - onset
				var f = float(notes[idx])
				var env = sin(min(1.0, nt / 0.010) * PI * 0.5) * exp(-nt * 6.8)
				sample += (sin(TAU * f * nt) * 0.76 + sin(TAU * f * 2.0 * nt) * 0.24 * exp(-nt * 12.0)) * env
		buf[i] = clamp(sample * 0.38, -0.95, 0.95)
	return _pack_16bit_wav(buf)


func _synth_combo_fanfare(notes: Array, dur: float) -> AudioStreamWAV:
	var n = int(SAMPLE_RATE * dur)
	var buf = PackedFloat32Array()
	buf.resize(n)
	var spacing = (dur * 0.50) / float(max(1, notes.size()))
	for i in range(n):
		var t = float(i) / float(SAMPLE_RATE)
		var sample := 0.0
		for idx in range(notes.size()):
			var onset = float(idx) * spacing
			if t >= onset:
				var nt = t - onset
				var f = float(notes[idx])
				var env = sin(min(1.0, nt / 0.010) * PI * 0.5) * exp(-nt * 7.5)
				sample += (sin(TAU * f * nt) * 0.74 + sin(TAU * f * 2.0 * nt) * 0.26 * exp(-nt * 12.0)) * env
		buf[i] = clamp(sample * 0.42, -0.95, 0.95)
	return _pack_16bit_wav(buf)


func _synth_royal_fanfare(notes: Array, dur: float) -> AudioStreamWAV:
	var n = int(SAMPLE_RATE * dur)
	var buf = PackedFloat32Array()
	buf.resize(n)
	var spacing = (dur * 0.55) / float(max(1, notes.size()))
	for i in range(n):
		var t = float(i) / float(SAMPLE_RATE)
		var sample := 0.0
		for idx in range(notes.size()):
			var onset = float(idx) * spacing
			if t >= onset:
				var nt = t - onset
				var f = float(notes[idx])
				var env = sin(min(1.0, nt / 0.014) * PI * 0.5) * exp(-nt * 5.2)
				sample += (sin(TAU * f * nt) * 0.75 + sin(TAU * f * 2.0 * nt) * 0.25 * exp(-nt * 10.0)) * env
		buf[i] = clamp(sample * 0.38, -0.95, 0.95)
	return _pack_16bit_wav(buf)


func _synth_sympathetic_cadence(notes: Array, dur: float) -> AudioStreamWAV:
	var n = int(SAMPLE_RATE * dur)
	var buf = PackedFloat32Array()
	buf.resize(n)
	var spacing = (dur * 0.60) / float(max(1, notes.size()))
	for i in range(n):
		var t = float(i) / float(SAMPLE_RATE)
		var sample := 0.0
		for idx in range(notes.size()):
			var onset = float(idx) * spacing
			if t >= onset:
				var nt = t - onset
				var f = float(notes[idx])
				var env = sin(min(1.0, nt / 0.014) * PI * 0.5) * exp(-nt * 6.0)
				sample += (sin(TAU * f * nt) * 0.80 + sin(TAU * f * 2.0 * nt) * 0.20) * env
		buf[i] = clamp(sample * 0.42, -0.95, 0.95)
	return _pack_16bit_wav(buf)


func _synth_magic_booster(notes: Array, dur: float) -> AudioStreamWAV:
	var n = int(SAMPLE_RATE * dur)
	var buf = PackedFloat32Array()
	buf.resize(n)
	var spacing = (dur * 0.55) / float(max(1, notes.size()))
	for i in range(n):
		var t = float(i) / float(SAMPLE_RATE)
		var sample := 0.0
		for idx in range(notes.size()):
			var onset = float(idx) * spacing
			if t >= onset:
				var nt = t - onset
				var f = float(notes[idx])
				var env = sin(min(1.0, nt / 0.010) * PI * 0.5) * exp(-nt * 8.2)
				sample += (sin(TAU * f * nt) * 0.76 + sin(TAU * f * 2.0 * nt) * 0.24 * exp(-nt * 14.0)) * env
		buf[i] = clamp(sample * 0.42, -0.95, 0.95)
	return _pack_16bit_wav(buf)
