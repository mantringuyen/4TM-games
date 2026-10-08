
extends Node

func _ready() -> void:
	var audio_mgr = AudioManagerDef.new()
	add_child(audio_mgr)
	
	# 1. Check track count
	var track_count = audio_mgr.get_bgm_track_count()
	print("BGM Track Count: ", track_count)
	if track_count < 3:
		printerr("FAIL: Expected at least 3 BGM tracks, got ", track_count)
		get_tree().quit(1)
		return
		
	# 2. Check each track duration
	var bgm_info = audio_mgr.get_bgm_tracks_info()
	var specs = bgm_info.get("track_specs", {})
	for tid in AudioManagerDef.BGM_TRACK_IDS:
		var sp = specs.get(tid, {})
		var dur = float(sp.get("duration_sec", 0.0))
		var is_full = dur >= 180.0
		print("Track %s: %.2fs (%dm %.1fs) [Full Length: %s]" % [tid, dur, int(dur / 60), fmod(dur, 60.0), is_full])
		if dur < 180.0:
			printerr("FAIL: Track ", tid, " duration ", dur, "s is less than 3 minutes!")
			get_tree().quit(1)
			return

	# 3. Test random track selection on new session
	var counts = {}
	for _i in range(100):
		var tid = audio_mgr.select_random_bgm_track_for_new_session()
		counts[tid] = counts.get(tid, 0) + 1
	print("Session random distribution across 100 picks: ", counts)
	if counts.size() < 3:
		printerr("FAIL: Random track selection across sessions did not distribute well: ", counts)
		get_tree().quit(1)
		return

	# 4. Test automatic next-track playback & no immediate repeat
	var prev_idx = audio_mgr.current_bgm_track_index
	var immediate_repeat_count = 0
	for _i in range(50):
		audio_mgr._on_bgm_track_finished()
		var cur_idx = audio_mgr.current_bgm_track_index
		if cur_idx == prev_idx:
			immediate_repeat_count += 1
		prev_idx = cur_idx
	print("Immediate repeats in 50 track-finished transitions: ", immediate_repeat_count)
	if immediate_repeat_count > 0:
		printerr("FAIL: Track immediately repeated on finish!")
		get_tree().quit(1)
		return

	# 5. Test Music OFF / ON behavior
	audio_mgr.music_enabled = false
	if audio_mgr.is_music_playing():
		printerr("FAIL: Music still playing when music_enabled = false")
		get_tree().quit(1)
		return
	if audio_mgr.bgm_player.playing:
		printerr("FAIL: bgm_player is playing when music OFF")
		get_tree().quit(1)
		return

	audio_mgr.music_enabled = true
	if not audio_mgr.is_music_playing():
		printerr("FAIL: Music not playing when music_enabled = true")
		get_tree().quit(1)
		return

	print("ALL BGM SYSTEM VERIFICATION CHECKS PASSED PERFECTLY!")
	audio_mgr.shutdown_audio()
	audio_mgr.queue_free()
	get_tree().quit(0)
