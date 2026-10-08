class_name GameOverModal
extends Control

## GameOverModal — Celebratory Level Complete & Game Over Summary Card for Block Puzzle — 4TM.
## Displays single-language UI (EN or VI).

const UIIconScript = preload("res://scripts/ui/ui_icon.gd")
const GameStateScript = preload("res://scripts/autoload/game_state.gd")
const RewardedAdScript = preload("res://scripts/core/rewarded_ad_interface.gd")
const GameTypographyScript = preload("res://scripts/ui/game_typography.gd")

@onready var lbl_title: Label = _find_node_by_name("LblGameOver") as Label
@onready var lbl_final_score_title: Label = _find_node_by_name("LblFinalScoreTitle") as Label
@onready var lbl_final_score: Label = _find_node_by_name("LblFinalScore") as Label
@onready var lbl_high_score: Label = _find_node_by_name("LblHighScore") as Label
@onready var lbl_stars: Label = _find_node_by_name("LblStars") as Label
@onready var lbl_unlock_status: Label = _find_node_by_name("LblUnlockStatus") as Label
@onready var lbl_reward_coins: Label = _find_node_by_name("LblRewardCoins") as Label
@onready var btn_extra_life: Button = _find_node_by_name("BtnExtraLife") as Button
@onready var btn_watch_ad: Button = _find_node_by_name("BtnWatchAd") as Button
@onready var btn_next_level: Button = _find_node_by_name("BtnNextLevel") as Button
@onready var btn_retry: Button = _find_node_by_name("BtnRetry") as Button
@onready var btn_menu: Button = _find_node_by_name("BtnMenu") as Button
var btn_main_menu: Button:
	get:
		return btn_menu
@onready var panel_container: PanelContainer = get_node_or_null("Panel")

var last_was_level_complete: bool = false
var last_next_level: int = 2
var last_final_score: int = 0
var last_final_level: int = 1
var last_stats: Dictionary = {}
var _recovery_in_progress: bool = false
var _rewarded_ad: RefCounted = null


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


func _find_node_by_name(node_name: String) -> Control:
	return find_child(node_name, true, false) as Control


func _ready() -> void:
	_ensure_nodes()
	_rewarded_ad = RewardedAdScript.new()
	if btn_extra_life:
		GameTypographyScript.apply_secondary_button_typography(btn_extra_life, 22)
		UIIconScript.attach_to_button(btn_extra_life, "extra_life", Vector2(28, 28), "left")
		if not btn_extra_life.pressed.is_connected(_on_btn_extra_life_pressed):
			btn_extra_life.pressed.connect(_on_btn_extra_life_pressed)
	if btn_watch_ad:
		GameTypographyScript.apply_secondary_button_typography(btn_watch_ad, 22)
		UIIconScript.attach_to_button(btn_watch_ad, "play", Vector2(26, 26), "left")
		if not btn_watch_ad.pressed.is_connected(_on_btn_watch_ad_pressed):
			btn_watch_ad.pressed.connect(_on_btn_watch_ad_pressed)
	if btn_next_level:
		GameTypographyScript.apply_primary_button_typography(btn_next_level, 24)
		UIIconScript.attach_to_button(btn_next_level, "play", Vector2(26, 26), "left")
		if not btn_next_level.pressed.is_connected(_on_btn_next_level_pressed):
			btn_next_level.pressed.connect(_on_btn_next_level_pressed)
	if btn_retry:
		GameTypographyScript.apply_secondary_button_typography(btn_retry, 22)
		UIIconScript.attach_to_button(btn_retry, "restart", Vector2(26, 26), "left")
		if not btn_retry.pressed.is_connected(_on_btn_retry_pressed):
			btn_retry.pressed.connect(_on_btn_retry_pressed)
	if btn_menu:
		_apply_red_exit_style(btn_menu)
		UIIconScript.attach_to_button(btn_menu, "close", Vector2(24, 24), "left", Color(1.0, 0.94, 0.94, 1.0))
		if not btn_menu.pressed.is_connected(_on_btn_menu_pressed):
			btn_menu.pressed.connect(_on_btn_menu_pressed)
	_setup_leave_button_spacing()
	
	var state_mgr = get_node_or_null("/root/GameState")
	if state_mgr:
		state_mgr.game_over_triggered.connect(_on_game_over)
		if state_mgr.has_signal("language_changed"):
			state_mgr.language_changed.connect(func(_l): _render_modal_state())
		if state_mgr.has_signal("special_item_inventory_changed"):
			state_mgr.special_item_inventory_changed.connect(func(_inv): _render_modal_state())
	UIIconScript.setup_all_buttons_feedback(self)


func _setup_leave_button_spacing() -> void:
	if btn_menu and btn_menu.get_parent() is VBoxContainer:
		var vbox := btn_menu.get_parent() as VBoxContainer
		var sp := vbox.get_node_or_null("LeaveActionSpacer_BtnMenu") as Control
		if not sp:
			sp = Control.new()
			sp.name = "LeaveActionSpacer_BtnMenu"
			sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(sp)
			vbox.move_child(sp, btn_menu.get_index())
		sp.custom_minimum_size = Vector2(0, 10)


func get_leave_button_spacing_metrics() -> Dictionary:
	_ensure_nodes()
	var vbox := btn_menu.get_parent() as VBoxContainer if btn_menu else null
	var base_sep: int = vbox.get_theme_constant("separation") if vbox else 12
	var sp := vbox.get_node_or_null("LeaveActionSpacer_BtnMenu") as Control if vbox else null
	var leave_gap: float = float(base_sep * 2) + (sp.custom_minimum_size.y if sp else 0.0)
	return {
		"normal_gap_px": float(base_sep),
		"leave_gap_px": leave_gap,
		"has_intentional_leave_spacing": leave_gap >= float(base_sep) + 10.0 and leave_gap <= 48.0,
		"has_red_leave_button": has_red_exit_button()
	}


func _apply_red_exit_style(btn: Button) -> void:
	if not btn:
		return
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.86, 0.16, 0.24, 0.98)
	st.border_width_left = 2
	st.border_width_top = 2
	st.border_width_right = 2
	st.border_width_bottom = 6
	st.border_color = Color(1.0, 0.62, 0.66, 1.0)
	st.corner_radius_top_left = 20
	st.corner_radius_top_right = 20
	st.corner_radius_bottom_right = 20
	st.corner_radius_bottom_left = 20
	var st_hov := st.duplicate()
	st_hov.bg_color = Color(0.94, 0.22, 0.30, 0.99)
	var st_press := st.duplicate()
	st_press.bg_color = Color(0.72, 0.10, 0.18, 0.99)
	st_press.border_width_bottom = 3
	btn.add_theme_color_override("font_color", Color(1.0, 0.98, 0.98, 1.0))
	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_stylebox_override("hover", st_hov)
	btn.add_theme_stylebox_override("pressed", st_press)
	btn.set_meta("is_red_exit_action", true)


func _is_button_red(btn: Button) -> bool:
	if not btn:
		return false
	var st := btn.get_theme_stylebox("normal") as StyleBoxFlat
	if not st:
		return false
	return st.bg_color.r >= 0.70 and st.bg_color.r > st.bg_color.g * 2.2 and st.bg_color.r > st.bg_color.b * 2.0


func has_red_exit_button() -> bool:
	_ensure_nodes()
	if not _is_button_red(btn_menu):
		return false
	for normal_b in [btn_retry, btn_next_level, btn_extra_life, btn_watch_ad]:
		if normal_b and _is_button_red(normal_b):
			return false
	return true


func _ensure_nodes() -> void:
	if not lbl_title: lbl_title = _find_node_by_name("LblGameOver") as Label
	if not lbl_final_score_title: lbl_final_score_title = _find_node_by_name("LblFinalScoreTitle") as Label
	if not lbl_final_score: lbl_final_score = _find_node_by_name("LblFinalScore") as Label
	if not lbl_high_score: lbl_high_score = _find_node_by_name("LblHighScore") as Label
	if not lbl_stars: lbl_stars = _find_node_by_name("LblStars") as Label
	if not lbl_unlock_status: lbl_unlock_status = _find_node_by_name("LblUnlockStatus") as Label
	if not lbl_reward_coins: lbl_reward_coins = _find_node_by_name("LblRewardCoins") as Label
	if not btn_extra_life: btn_extra_life = _find_node_by_name("BtnExtraLife") as Button
	if not btn_watch_ad:
		btn_watch_ad = _find_node_by_name("BtnWatchAd") as Button
		if not btn_watch_ad and btn_extra_life and btn_extra_life.get_parent():
			btn_watch_ad = Button.new()
			btn_watch_ad.name = "BtnWatchAd"
			btn_watch_ad.custom_minimum_size = Vector2(0, 62)
			btn_watch_ad.text = "WATCH AD"
			btn_extra_life.get_parent().add_child(btn_watch_ad)
			btn_extra_life.get_parent().move_child(btn_watch_ad, btn_extra_life.get_index() + 1)
	if not btn_next_level: btn_next_level = _find_node_by_name("BtnNextLevel") as Button
	if not btn_retry: btn_retry = _find_node_by_name("BtnRetry") as Button
	if not btn_menu: btn_menu = _find_node_by_name("BtnMenu") as Button


func _on_game_over(final_score: int, final_level: int, stats: Dictionary) -> void:
	_recovery_in_progress = false
	last_final_score = final_score
	last_final_level = final_level
	last_stats = stats.duplicate()
	_render_modal_state()
	
	if panel_container and is_inside_tree():
		panel_container.scale = Vector2(0.8, 0.8)
		panel_container.pivot_offset = panel_container.size * 0.5
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(panel_container, "scale", Vector2(1.0, 1.0), 0.3)


func _render_modal_state() -> void:
	_ensure_nodes()
	var state_mgr = get_node_or_null("/root/GameState")
	var is_complete: bool = bool(last_stats.get("level_complete", false))
	last_was_level_complete = is_complete
	last_next_level = int(last_stats.get("next_level", last_final_level + 1))
	
	if lbl_title:
		if is_complete:
			var fmt_c = state_mgr.tr_text("modal_level_complete") if state_mgr else "LEVEL %d COMPLETE!"
			lbl_title.text = fmt_c % last_final_level
		else:
			var fmt_o = state_mgr.tr_text("modal_game_over") if state_mgr else "LEVEL %d ENDED"
			lbl_title.text = fmt_o % last_final_level
	
	if lbl_final_score_title and state_mgr:
		lbl_final_score_title.text = state_mgr.tr_text("modal_final_score")
	if lbl_final_score:
		lbl_final_score.text = str(last_final_score)
	if lbl_high_score and state_mgr:
		lbl_high_score.text = state_mgr.tr_text("modal_best_score") % state_mgr.high_score
	
	var stars_earned: int = int(last_stats.get("stars", 0))
	if lbl_stars:
		if state_mgr and state_mgr.has_method("format_stars_string"):
			lbl_stars.text = state_mgr.format_stars_string(stars_earned)
		else:
			lbl_stars.text = "%d/3 STARS" % stars_earned
	
	if lbl_unlock_status:
		if is_complete:
			lbl_unlock_status.visible = true
			var fmt_u = state_mgr.tr_text("modal_unlocked_next") if state_mgr else "LEVEL %d UNLOCKED!"
			lbl_unlock_status.text = fmt_u % last_next_level
		else:
			var target_pts = state_mgr.get_level_target_score(last_final_level) if (state_mgr and state_mgr.has_method("get_level_target_score")) else 500
			lbl_unlock_status.visible = true
			var fmt_t = state_mgr.tr_text("modal_target_needed") if state_mgr else "Target Needed: %d Pts"
			lbl_unlock_status.text = fmt_t % target_pts
	
	var coins_earned: int = int(last_stats.get("coins_earned", 0))
	if lbl_reward_coins:
		var fmt_r = state_mgr.tr_text("modal_reward_coins") if state_mgr else "REWARD: +%d COINS"
		lbl_reward_coins.text = fmt_r % coins_earned
	
	if is_complete:
		# Level Complete modal state
		if btn_extra_life:
			btn_extra_life.visible = false
		if btn_watch_ad:
			btn_watch_ad.visible = false
		if btn_next_level:
			btn_next_level.visible = true
			var fmt_nl = state_mgr.tr_text("btn_next_level") if state_mgr else "NEXT LEVEL (%d)"
			btn_next_level.text = fmt_nl % last_next_level
		if btn_retry:
			btn_retry.visible = true
			btn_retry.text = state_mgr.tr_text("btn_play_again") if state_mgr else "PLAY AGAIN"
		if btn_menu:
			btn_menu.visible = true
			btn_menu.text = state_mgr.tr_text("btn_main_menu") if state_mgr else "MAIN MENU"
	else:
		# Genuine Game Over: show strictly 1. USE EXTRA LIFE, 2. WATCH AD, 3. MAIN MENU
		var el_count: int = 0
		if state_mgr:
			if state_mgr.has_method("get_special_item_count"):
				el_count = state_mgr.get_special_item_count("extra_life")
			elif "special_item_inventory" in state_mgr:
				el_count = int(state_mgr.special_item_inventory.get("extra_life", 0))
		var can_use_el: bool = (el_count > 0) and (not state_mgr or not state_mgr.has_method("can_use_extra_life_now") or state_mgr.can_use_extra_life_now())
		if btn_extra_life:
			btn_extra_life.visible = true
			btn_extra_life.disabled = not can_use_el
			btn_extra_life.modulate.a = 0.52 if (not can_use_el) else 1.0
			btn_extra_life.text = state_mgr.tr_text("btn_use_extra_life") if state_mgr else "USE EXTRA LIFE"
		if btn_watch_ad:
			btn_watch_ad.visible = true
			btn_watch_ad.disabled = false
			btn_watch_ad.text = state_mgr.tr_text("btn_watch_ad") if state_mgr else "WATCH AD"
		if btn_next_level:
			btn_next_level.visible = false
		if btn_retry:
			btn_retry.visible = false
		if btn_menu:
			btn_menu.visible = true
			btn_menu.text = state_mgr.tr_text("btn_main_menu") if state_mgr else "MAIN MENU"


func get_visible_gameover_choices() -> Array[String]:
	_ensure_nodes()
	var choices: Array[String] = []
	for b in [btn_extra_life, btn_watch_ad, btn_next_level, btn_retry, btn_menu]:
		if b and b.visible:
			choices.append(b.text.strip_edges())
	return choices


func _find_active_gameplay_mode() -> Node:
	if not is_inside_tree():
		return null
	var game_world = get_tree().root.find_child("GameWorld", true, false)
	if game_world and game_world.has_method("get_active_mode"):
		var m = game_world.get_active_mode()
		if m:
			return m
	var stack: Array[Node] = [get_tree().root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		for ch in cur.get_children():
			stack.append(ch)
		if cur != self and cur.has_method("confirm_extra_life") and "board" in cur and cur.board != null:
			return cur
	return null


func _on_btn_extra_life_pressed() -> bool:
	if _recovery_in_progress or last_was_level_complete:
		return false
	var state_mgr = get_node_or_null("/root/GameState")
	if not state_mgr or state_mgr.current_state != GameStateScript.State.GAME_OVER:
		return false
	if state_mgr.has_method("can_use_extra_life_now") and not state_mgr.can_use_extra_life_now():
		return false
	_recovery_in_progress = true
	var recovered := false
	var game_world = get_tree().root.find_child("GameWorld", true, false) if is_inside_tree() else null
	if game_world and game_world.has_method("use_special_item") and game_world.get_active_mode() != null:
		recovered = game_world.use_special_item("extra_life")
	else:
		var active_mode = _find_active_gameplay_mode()
		if active_mode and active_mode.has_method("confirm_extra_life"):
			recovered = active_mode.confirm_extra_life()
		elif state_mgr.consume_special_item("extra_life"):
			if "placement_checkpoints" in state_mgr and state_mgr.placement_checkpoints.size() > 0:
				state_mgr.rewind_extra_life_checkpoint(null)
			state_mgr.revive_from_extra_life()
			recovered = true
	if recovered:
		visible = false
		_render_modal_state()
	_recovery_in_progress = false
	return recovered


func _on_btn_watch_ad_pressed() -> bool:
	if _recovery_in_progress or last_was_level_complete:
		return false
	var state_mgr = get_node_or_null("/root/GameState")
	if not state_mgr or state_mgr.current_state != GameStateScript.State.GAME_OVER:
		return false
	_recovery_in_progress = true
	if _rewarded_ad:
		_rewarded_ad.is_loaded = true
		_rewarded_ad.show_rewarded_ad("revive")
	var active_mode = _find_active_gameplay_mode()
	if active_mode and active_mode.has_method("apply_watch_ad_rescue"):
		active_mode.apply_watch_ad_rescue()
	else:
		if active_mode and "board" in active_mode and active_mode.board and active_mode.board.has_method("apply_extra_life_rescue"):
			active_mode.board.apply_extra_life_rescue()
		if state_mgr.has_method("revive_from_watch_ad"):
			state_mgr.revive_from_watch_ad()
		elif state_mgr.has_method("revive_from_extra_life"):
			state_mgr.revive_from_extra_life()
	visible = false
	_recovery_in_progress = false
	return true


func _on_btn_next_level_pressed() -> void:
	var state_mgr = get_node_or_null("/root/GameState")
	if state_mgr:
		if state_mgr.has_method("start_next_level"):
			state_mgr.start_next_level()
		elif state_mgr.has_method("start_level"):
			state_mgr.start_level(last_next_level, state_mgr.current_mode, int(state_mgr.current_play_style))


func _on_btn_retry_pressed() -> void:
	var state_mgr = get_node_or_null("/root/GameState")
	if state_mgr:
		if state_mgr.has_method("start_game_combination"):
			state_mgr.start_game_combination(state_mgr.current_mode, state_mgr.current_play_style, state_mgr.active_level)
		else:
			state_mgr.start_game(state_mgr.current_mode)


func _on_btn_menu_pressed() -> void:
	# MAIN MENU never consumes Extra Life
	var state_mgr = get_node_or_null("/root/GameState")
	if state_mgr:
		state_mgr.return_to_menu()
