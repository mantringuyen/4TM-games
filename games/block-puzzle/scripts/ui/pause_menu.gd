class_name PauseMenu
extends Control

## PauseMenu — Overlay menu when game is paused, including independent Music & SFX toggles and single-language EN/VI labels.

const UIIconScript = preload("res://scripts/ui/ui_icon.gd")
const GameTypographyScript = preload("res://scripts/ui/game_typography.gd")

@onready var lbl_title: Label = find_child("LblTitle", true, false) as Label
@onready var panel_container: PanelContainer = find_child("Panel", true, false) as PanelContainer
@onready var audio_toggles_row: HBoxContainer = find_child("AudioTogglesRow", true, false) as HBoxContainer
@onready var voice_haptics_row: HBoxContainer = find_child("VoiceHapticsRow", true, false) as HBoxContainer
@onready var btn_music: Button = find_child("BtnMusic", true, false) as Button
@onready var btn_sound: Button = find_child("BtnSound", true, false) as Button
@onready var btn_voice: Button = find_child("BtnVoice", true, false) as Button
@onready var btn_haptics: Button = find_child("BtnHaptics", true, false) as Button
@onready var btn_restart: Button = find_child("BtnRestart", true, false) as Button
@onready var btn_resume: Button = find_child("BtnResume", true, false) as Button
@onready var btn_menu: Button = find_child("BtnMenu", true, false) as Button


func _get_game_state() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/GameState")
	var main_loop := Engine.get_main_loop() as SceneTree
	if main_loop and main_loop.root:
		return main_loop.root.get_node_or_null("GameState")
	return null


func _get_audio_manager() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/AudioManager")
	var main_loop := Engine.get_main_loop() as SceneTree
	if main_loop and main_loop.root:
		return main_loop.root.get_node_or_null("AudioManager")
	return null


func _ready() -> void:
	if lbl_title:
		GameTypographyScript.apply_heading_typography(lbl_title, 34)
	if btn_music:
		UIIconScript.apply_audio_toggle_button_identity_style(btn_music)
		GameTypographyScript.apply_secondary_button_typography(btn_music, 17)
		UIIconScript.attach_to_button(btn_music, "music", Vector2(24, 24), "left", Color(1.0, 0.92, 0.36, 1.0))
		btn_music.pressed.connect(_on_btn_music_pressed)
	if btn_sound:
		UIIconScript.apply_audio_toggle_button_identity_style(btn_sound)
		GameTypographyScript.apply_secondary_button_typography(btn_sound, 17)
		UIIconScript.attach_to_button(btn_sound, "sound_on", Vector2(24, 24), "left", Color(0.52, 0.98, 1.0, 1.0))
		btn_sound.pressed.connect(_on_btn_sound_pressed)
	if btn_voice:
		UIIconScript.apply_voice_button_identity_style(btn_voice)
		GameTypographyScript.apply_secondary_button_typography(btn_voice, 17)
		UIIconScript.attach_to_button(btn_voice, "sound_on", Vector2(22, 22), "left", Color(0.52, 0.98, 1.0, 1.0))
		btn_voice.pressed.connect(_on_btn_voice_pressed)
	if btn_haptics:
		UIIconScript.apply_voice_button_identity_style(btn_haptics)
		GameTypographyScript.apply_secondary_button_typography(btn_haptics, 17)
		UIIconScript.attach_to_button(btn_haptics, "haptic", Vector2(22, 22), "left", Color(1.0, 0.90, 0.38, 1.0))
		btn_haptics.pressed.connect(_on_btn_haptics_pressed)
	if btn_restart:
		_apply_action_button_style(btn_restart, Color(0.16, 0.54, 0.96, 1.0), Color(0.70, 0.94, 1.0, 1.0))
		GameTypographyScript.apply_secondary_button_typography(btn_restart, 22)
		UIIconScript.attach_to_button(btn_restart, "restart", Vector2(26, 26), "left")
		btn_restart.pressed.connect(_on_btn_restart_pressed)
	if btn_resume:
		_apply_action_button_style(btn_resume, Color(0.10, 0.84, 0.44, 1.0), Color(0.74, 1.0, 0.58, 1.0))
		GameTypographyScript.apply_primary_button_typography(btn_resume, 26)
		UIIconScript.attach_to_button(btn_resume, "play", Vector2(28, 28), "left")
		btn_resume.pressed.connect(_on_btn_resume_pressed)
	if btn_menu:
		_apply_red_exit_style(btn_menu)
		GameTypographyScript.apply_secondary_button_typography(btn_menu, 22, Color(0.24, 0.04, 0.06, 0.95))
		UIIconScript.attach_to_button(btn_menu, "close", Vector2(24, 24), "left", Color(1.0, 0.94, 0.94, 1.0))
		btn_menu.pressed.connect(_on_btn_menu_pressed)
	_setup_leave_button_spacing()
	update_responsive_layout()
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_signal("language_changed"):
		gs.language_changed.connect(func(_l): _refresh_audio_labels())
	if gs and gs.has_signal("voice_settings_changed"):
		gs.voice_settings_changed.connect(func(_v): _refresh_audio_labels())
	visibility_changed.connect(_refresh_audio_labels)
	_refresh_audio_labels()
	UIIconScript.setup_all_buttons_feedback(self)


func _on_resized() -> void:
	update_responsive_layout(get_viewport_rect().size)


func update_responsive_layout(vp_size: Vector2 = Vector2.ZERO) -> void:
	if vp_size.is_zero_approx():
		if is_inside_tree():
			vp_size = get_viewport_rect().size
		else:
			vp_size = Vector2(720, 1280)
	var vp_w: float = vp_size.x if vp_size.x > 0 else 720.0
	var vp_h: float = vp_size.y if vp_size.y > 0 else 1280.0
	var is_compact: bool = (vp_h <= 880.0 or vp_w <= 420.0)
	var is_very_compact: bool = (vp_h <= 810.0 or vp_w <= 370.0)

	var target_w: float = clampf(vp_w - (16.0 if is_very_compact else 28.0), 330.0, 600.0)
	var target_h: float = clampf(vp_h - (70.0 if is_very_compact else 110.0), 520.0, 720.0)
	if panel_container:
		panel_container.offset_left = -target_w * 0.5
		panel_container.offset_right = target_w * 0.5
		panel_container.offset_top = -target_h * 0.5
		panel_container.offset_bottom = target_h * 0.5

	var resume_h: float = 72.0 if is_very_compact else (74.0 if is_compact else 76.0)
	var restart_h: float = 68.0 if is_very_compact else (70.0 if is_compact else 72.0)
	var menu_h: float = 68.0 if is_very_compact else (70.0 if is_compact else 72.0)
	var toggle_h: float = 64.0 if is_very_compact else (66.0 if is_compact else 68.0)

	if btn_resume:
		btn_resume.custom_minimum_size.y = resume_h
		GameTypographyScript.apply_primary_button_typography(btn_resume, 24 if is_compact else 26)
	if btn_restart:
		btn_restart.custom_minimum_size.y = restart_h
		GameTypographyScript.apply_secondary_button_typography(btn_restart, 20 if is_compact else 22)
	if btn_menu:
		btn_menu.custom_minimum_size.y = menu_h
		GameTypographyScript.apply_secondary_button_typography(btn_menu, 20 if is_compact else 22, Color(0.24, 0.04, 0.06, 0.95))
	for b in [btn_music, btn_sound, btn_voice, btn_haptics]:
		if b:
			b.custom_minimum_size.y = toggle_h
			GameTypographyScript.apply_secondary_button_typography(b, 16 if is_very_compact else 17)


func _apply_action_button_style(btn: Button, bg_col: Color, border_col: Color) -> void:
	if not btn:
		return
	var st := StyleBoxFlat.new()
	st.bg_color = bg_col
	st.border_width_left = 3
	st.border_width_top = 3
	st.border_width_right = 3
	st.border_width_bottom = 8
	st.border_color = border_col
	st.set_corner_radius_all(24)
	st.shadow_color = Color(0.02, 0.04, 0.16, 0.60)
	st.shadow_size = 14
	st.shadow_offset = Vector2(0, 5)
	var st_hov := st.duplicate()
	st_hov.bg_color = bg_col.lightened(0.10)
	st_hov.border_color = border_col.lightened(0.12)
	var st_press := st.duplicate()
	st_press.bg_color = bg_col.darkened(0.08)
	st_press.border_width_bottom = 3
	st_press.shadow_size = 4
	st_press.shadow_offset = Vector2(0, 2)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_stylebox_override("hover", st_hov)
	btn.add_theme_stylebox_override("pressed", st_press)
	UIIconScript.remove_focus_outline(btn)


func _setup_leave_button_spacing() -> void:
	if btn_restart and btn_resume and btn_restart.get_parent() == btn_resume.get_parent():
		var action_parent := btn_restart.get_parent()
		if btn_restart.get_index() > btn_resume.get_index():
			action_parent.move_child(btn_restart, btn_resume.get_index())


func has_restart_before_resume_order() -> bool:
	if not btn_restart or not btn_resume:
		return false
	if btn_restart.get_parent() != btn_resume.get_parent():
		return false
	return btn_restart.get_index() < btn_resume.get_index()


func has_restart_before_resume() -> bool:
	return has_restart_before_resume_order()


func get_leave_button_spacing_metrics() -> Dictionary:
	var vbox := btn_menu.get_parent() as VBoxContainer if btn_menu else null
	var base_sep: int = vbox.get_theme_constant("separation") if vbox else 12
	return {
		"normal_gap_px": float(base_sep),
		"leave_gap_px": float(base_sep),
		"has_intentional_leave_spacing": true,
		"has_red_leave_button": has_red_exit_button()
	}


func _apply_red_exit_style(btn: Button) -> void:
	if not btn:
		return
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.88, 0.18, 0.26, 0.98)
	st.border_width_left = 3
	st.border_width_top = 3
	st.border_width_right = 3
	st.border_width_bottom = 7
	st.border_color = Color(1.0, 0.68, 0.72, 1.0)
	st.set_corner_radius_all(22)
	st.shadow_color = Color(0.18, 0.02, 0.04, 0.55)
	st.shadow_size = 12
	st.shadow_offset = Vector2(0, 5)
	var st_hov := st.duplicate()
	st_hov.bg_color = Color(0.96, 0.24, 0.32, 0.99)
	st_hov.border_color = Color(1.0, 0.78, 0.82, 1.0)
	var st_press := st.duplicate()
	st_press.bg_color = Color(0.74, 0.12, 0.20, 0.99)
	st_press.border_width_bottom = 3
	st_press.shadow_size = 4
	st_press.shadow_offset = Vector2(0, 2)
	btn.add_theme_color_override("font_color", Color(1.0, 0.98, 0.98, 1.0))
	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_stylebox_override("hover", st_hov)
	btn.add_theme_stylebox_override("pressed", st_press)
	btn.set_meta("is_red_exit_action", true)


func has_equal_width_voice_haptics_row() -> bool:
	if not voice_haptics_row or not btn_voice or not btn_haptics:
		return false
	if btn_voice.get_parent() != voice_haptics_row or btn_haptics.get_parent() != voice_haptics_row:
		return false
	var v_expand: bool = (btn_voice.size_flags_horizontal & Control.SIZE_EXPAND_FILL) == Control.SIZE_EXPAND_FILL
	var h_expand: bool = (btn_haptics.size_flags_horizontal & Control.SIZE_EXPAND_FILL) == Control.SIZE_EXPAND_FILL
	return v_expand and h_expand


func has_equal_width_music_sfx_row() -> bool:
	if not audio_toggles_row or not btn_music or not btn_sound:
		return false
	if btn_music.get_parent() != audio_toggles_row or btn_sound.get_parent() != audio_toggles_row:
		return false
	var m_expand: bool = (btn_music.size_flags_horizontal & Control.SIZE_EXPAND_FILL) == Control.SIZE_EXPAND_FILL
	var s_expand: bool = (btn_sound.size_flags_horizontal & Control.SIZE_EXPAND_FILL) == Control.SIZE_EXPAND_FILL
	return m_expand and s_expand


func has_balanced_action_button_spacing() -> bool:
	if not btn_restart or not btn_resume or not btn_menu:
		return false
	return (
		btn_restart.get_parent() == btn_resume.get_parent()
		and btn_resume.get_parent() == btn_menu.get_parent()
		and btn_restart.get_index() < btn_resume.get_index()
		and btn_resume.get_index() < btn_menu.get_index()
	)


func _is_button_red(btn: Button) -> bool:
	if not btn:
		return false
	var st := btn.get_theme_stylebox("normal") as StyleBoxFlat
	if not st:
		return false
	return st.bg_color.r >= 0.70 and st.bg_color.r > st.bg_color.g * 2.2 and st.bg_color.r > st.bg_color.b * 2.0


func has_red_exit_button() -> bool:
	if not _is_button_red(btn_menu):
		return false
	for normal_b in [btn_resume, btn_restart, btn_music, btn_sound]:
		if _is_button_red(normal_b):
			return false
	return true


func _refresh_audio_labels() -> void:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	var gs = get_node_or_null("/root/GameState")
	var m_on = audio_mgr.music_enabled if audio_mgr else true
	var s_on = audio_mgr.sound_enabled if audio_mgr else true
	if lbl_title and gs:
		lbl_title.text = gs.tr_text("pause_title")
	if btn_music:
		btn_music.text = (gs.tr_text("music_on") if m_on else gs.tr_text("music_off")) if gs else ("MUSIC: ON" if m_on else "MUSIC: OFF")
		UIIconScript.apply_audio_toggle_button_identity_style(btn_music)
		UIIconScript.attach_to_button(btn_music, "music", Vector2(26, 26), "left", Color(1.0, 0.92, 0.36, 1.0))
	if btn_sound:
		btn_sound.text = (gs.tr_text("sfx_on") if s_on else gs.tr_text("sfx_off")) if gs else ("SOUND SFX: ON" if s_on else "SOUND SFX: OFF")
		UIIconScript.apply_audio_toggle_button_identity_style(btn_sound)
		UIIconScript.attach_to_button(btn_sound, "sound_on" if s_on else "sound_off", Vector2(26, 26), "left", Color(0.52, 0.98, 1.0, 1.0))
	if btn_voice:
		var v_mode: String = gs.get_voice_mode() if gs else (audio_mgr.get_voice_mode() if audio_mgr else "male")
		btn_voice.text = gs.get_voice_button_label() if gs else ("VOICE: " + (audio_mgr.get_voice_state_label() if audio_mgr else "Male"))
		UIIconScript.apply_voice_button_identity_style(btn_voice)
		UIIconScript.attach_to_button(btn_voice, "sound_on", Vector2(20, 20), "left", Color(0.52, 0.98, 1.0, 1.0))
	if btn_haptics:
		var h_on: bool = gs.haptics_enabled if (gs and "haptics_enabled" in gs) else true
		btn_haptics.text = (gs.tr_text("haptics_on") if h_on else gs.tr_text("haptics_off")) if gs else ("HAPTICS: ON" if h_on else "HAPTICS: OFF")
		UIIconScript.apply_voice_button_identity_style(btn_haptics)
		UIIconScript.attach_to_button(btn_haptics, "haptic", Vector2(20, 20), "left", Color(1.0, 0.90, 0.38, 1.0))
	if btn_resume and gs:
		btn_resume.text = gs.tr_text("btn_resume")
	if btn_restart and gs:
		btn_restart.text = gs.tr_text("btn_restart")
	if btn_menu and gs:
		btn_menu.text = gs.tr_text("btn_home")


func _on_btn_music_pressed() -> void:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		audio_mgr.music_enabled = not audio_mgr.music_enabled
		audio_mgr.play_button_click()
	_refresh_audio_labels()


func _on_btn_sound_pressed() -> void:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		audio_mgr.sound_enabled = not audio_mgr.sound_enabled
		if audio_mgr.sound_enabled:
			audio_mgr.play_button_click()
	_refresh_audio_labels()


func _on_btn_voice_pressed() -> void:
	var gs = get_node_or_null("/root/GameState")
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if gs and gs.has_method("cycle_voice_mode"):
		gs.cycle_voice_mode()
	elif audio_mgr and audio_mgr.has_method("cycle_voice_mode"):
		audio_mgr.cycle_voice_mode()
	_refresh_audio_labels()


func _on_btn_haptics_pressed() -> void:
	var gs = get_node_or_null("/root/GameState")
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if gs and "haptics_enabled" in gs:
		gs.haptics_enabled = not gs.haptics_enabled
	if audio_mgr:
		audio_mgr.play_button_click()
	_refresh_audio_labels()


func _on_btn_resume_pressed() -> void:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		audio_mgr.play_button_click()
	var state_mgr = get_node_or_null("/root/GameState")
	if state_mgr:
		state_mgr.pause_game(false)


func _on_btn_restart_pressed() -> void:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		audio_mgr.play_button_click()
	var state_mgr = get_node_or_null("/root/GameState")
	if state_mgr:
		state_mgr.pause_game(false)
		if state_mgr.has_method("start_game_combination"):
			state_mgr.start_game_combination(state_mgr.current_mode, state_mgr.current_play_style)
		else:
			state_mgr.start_game(state_mgr.current_mode)


func _on_btn_menu_pressed() -> void:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		audio_mgr.play_button_click()
	var state_mgr = get_node_or_null("/root/GameState")
	if state_mgr:
		state_mgr.return_to_menu()
