extends Control

## HUD — Playful Casual Mobile Puzzle Gameplay Header for Block Puzzle — 4TM
## Displays single-language UI (EN or VI):
##   - Level Badge & Mode + PlayStyle ribbon
##   - Live 3-Star Milestone Indicator (★ ★ ★) & Target Goal progress
##   - Score with pop animation & floating +Points toast
##   - SpecialItemsBar ONLY in Modern Game Mode (hidden in Classic Game Mode)

const GameStateScript = preload("res://scripts/autoload/game_state.gd")
const UIIconScript = preload("res://scripts/ui/ui_icon.gd")
const GameTypographyScript = preload("res://scripts/ui/game_typography.gd")

@onready var lbl_score: Label = _find_lbl_score()
@onready var lbl_score_title: Label = get_node_or_null("MarginContainer/VBoxContainer/HeaderRow/ScorePanel/Margin/ScoreBox/LblScoreTitle")
@onready var lbl_level: Label = _find_lbl_level()
@onready var lbl_level_title: Label = get_node_or_null("MarginContainer/VBoxContainer/HeaderRow/LevelPanel/Margin/LevelBox/LblLevelTitle")
@onready var lbl_star_meter: Label = get_node_or_null("MarginContainer/VBoxContainer/HeaderRow/LevelPanel/Margin/LevelBox/LblStarMeter")
@onready var lbl_goal_progress: Label = get_node_or_null("MarginContainer/VBoxContainer/HeaderRow/ScorePanel/Margin/ScoreBox/LblGoalProgress")
@onready var level_panel: PanelContainer = get_node_or_null("MarginContainer/VBoxContainer/HeaderRow/LevelPanel")
@onready var btn_settings: Button = get_node_or_null("MarginContainer/VBoxContainer/HeaderRow/SettingsBox/BtnSettings")
@onready var btn_pause: Button = get_node_or_null("MarginContainer/VBoxContainer/HeaderRow/SettingsBox/BtnSettings")
@onready var special_items_bar: Control = get_node_or_null("MarginContainer/VBoxContainer/SpecialItemsBar")

var energy_panel: PanelContainer = null
var energy_icon: Control = null
var lbl_energy: Label = null
var btn_energy_plus: Button = null
var energy_ad_modal: Control = null
var _active_energy_ad_session_id: String = ""

const CALLOUT_FONT_SIZE: int = 54
const COMBO_FONT_SIZE: int = 44
const POINTS_POPUP_FONT_SIZE: int = 30
const CALLOUT_PEAK_SCALE: float = 1.50
const COMBO_PEAK_SCALE: float = 1.40
const CALLOUT_OUTLINE_SIZE: int = 14
const COMBO_OUTLINE_SIZE: int = 12

var combo_banner: Label = null
var callout_banner: Label = null
var points_popup: Label = null
var callout_display_font: Font = null


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


func _build_callout_display_font() -> Font:
	var sys_font := SystemFont.new()
	sys_font.font_names = PackedStringArray(["Impact", "Arial Black", "Montserrat", "Trebuchet MS", "Sans-Serif"])
	sys_font.font_weight = 900
	sys_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	if ThemeDB.fallback_font:
		sys_font.fallbacks = [ThemeDB.fallback_font]
	return sys_font


func _get_callout_tier_palette(raw_text: String) -> Dictionary:
	var upper := raw_text.to_upper()
	if "AMAZING" in upper:
		return {
			"fill": Color(1.0, 0.94, 0.24, 1.0),
			"outline": Color(0.28, 0.04, 0.36, 0.99),
			"shadow": Color(0.14, 0.02, 0.22, 0.96)
		}
	elif "EXCELLENT" in upper:
		return {
			"fill": Color(1.0, 0.64, 0.96, 1.0),
			"outline": Color(0.24, 0.04, 0.34, 0.99),
			"shadow": Color(0.12, 0.02, 0.20, 0.96)
		}
	elif "COMBO" in upper:
		return {
			"fill": Color(1.0, 0.88, 0.20, 1.0),
			"outline": Color(0.26, 0.08, 0.02, 0.99),
			"shadow": Color(0.16, 0.04, 0.01, 0.96)
		}
	elif "GREAT" in upper:
		return {
			"fill": Color(0.36, 0.98, 1.0, 1.0),
			"outline": Color(0.04, 0.12, 0.34, 0.99),
			"shadow": Color(0.02, 0.06, 0.22, 0.96)
		}
	elif "NICE" in upper:
		return {
			"fill": Color(0.46, 1.0, 0.66, 1.0),
			"outline": Color(0.04, 0.22, 0.12, 0.99),
			"shadow": Color(0.02, 0.12, 0.06, 0.96)
		}
	return {
		"fill": Color(1.0, 0.92, 0.34, 1.0),
		"outline": Color(0.08, 0.14, 0.36, 0.99),
		"shadow": Color(0.04, 0.08, 0.24, 0.96)
	}


func _find_lbl_score() -> Label:
	var l = get_node_or_null("MarginContainer/VBoxContainer/HeaderRow/ScorePanel/Margin/ScoreBox/LblScore")
	if not l:
		l = get_node_or_null("MarginContainer/VBoxContainer/HeaderRow/ScoreBox/LblScore")
	return l


func _find_lbl_level() -> Label:
	var l = get_node_or_null("MarginContainer/VBoxContainer/HeaderRow/LevelPanel/Margin/LevelBox/LblLevel")
	if not l:
		l = get_node_or_null("MarginContainer/VBoxContainer/HeaderRow/LevelBox/LblLevel")
	return l


func _ready() -> void:
	if not lbl_score:
		lbl_score = _find_lbl_score()
	if not lbl_level:
		lbl_level = _find_lbl_level()
	if not special_items_bar:
		special_items_bar = get_node_or_null("MarginContainer/VBoxContainer/SpecialItemsBar")
	_ensure_energy_header_control()
		
	if btn_settings:
		btn_settings.text = ""
		UIIconScript.apply_frameless_icon_button_style(btn_settings)
		btn_settings.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn_settings.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn_settings.custom_minimum_size = Vector2(66, 56)
		btn_settings.size = Vector2(66, 56)
		var gear_ctrl := UIIconScript.attach_to_button(btn_settings, "gear", Vector2(52, 52), "center", Color(0.70, 0.73, 0.77, 1.0))
		if gear_ctrl:
			gear_ctrl.secondary_color = Color(0.20, 0.24, 0.35, 1.0)
		btn_settings.pressed.connect(_on_btn_settings_pressed)
	if is_inside_tree() and get_viewport():
		if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
			get_viewport().size_changed.connect(_on_viewport_size_changed)
		update_responsive_layout(get_viewport_rect().size)
	else:
		update_responsive_layout(Vector2(720, 1280))
	
	callout_display_font = _build_callout_display_font()
	combo_banner = null
	callout_banner = null

	points_popup = Label.new()
	points_popup.name = "PointsPopup"
	points_popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	points_popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	points_popup.anchor_left = 0.0
	points_popup.anchor_top = 0.0
	points_popup.anchor_right = 1.0
	points_popup.anchor_bottom = 0.0
	points_popup.offset_left = 0.0
	points_popup.offset_right = 0.0
	points_popup.custom_minimum_size = Vector2(720, 44)
	points_popup.offset_top = 96
	points_popup.offset_bottom = 140
	points_popup.pivot_offset = Vector2(360, 22)
	points_popup.add_theme_font_size_override("font_size", POINTS_POPUP_FONT_SIZE)
	points_popup.add_theme_color_override("font_color", Color(0.45, 1.0, 0.68, 1.0))
	points_popup.add_theme_color_override("font_outline_color", Color(0.02, 0.18, 0.08, 0.98))
	points_popup.add_theme_constant_override("outline_size", 6)
	points_popup.add_theme_color_override("font_shadow_color", Color(0.02, 0.22, 0.10, 0.95))
	points_popup.add_theme_constant_override("shadow_offset_x", 2)
	points_popup.add_theme_constant_override("shadow_offset_y", 3)
	points_popup.modulate.a = 0.0
	points_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(points_popup)
	
	var state_mgr = _get_game_state()
	if state_mgr:
		state_mgr.score_updated.connect(_on_score_updated)
		state_mgr.level_updated.connect(_on_level_updated)
		if state_mgr.has_signal("game_started"):
			state_mgr.game_started.connect(_on_game_started)
		if state_mgr.has_signal("mode_changed"):
			state_mgr.mode_changed.connect(_on_mode_changed)
		if state_mgr.has_signal("language_changed"):
			state_mgr.language_changed.connect(_on_language_changed)
		if state_mgr.has_signal("level_completed"):
			state_mgr.level_completed.connect(_on_level_completed)
		if state_mgr.has_signal("special_item_discovered"):
			state_mgr.special_item_discovered.connect(_on_special_item_discovered)
		if state_mgr.has_signal("energy_changed"):
			state_mgr.energy_changed.connect(func(_c, _m): update_energy_display())
		_refresh_language()
		_on_score_updated(state_mgr.score, 0)
		_on_level_updated(state_mgr.level, 0)
		_update_mode_presentation(state_mgr.current_mode)
		update_energy_display()
	
	_apply_level_panel_progress_style()
	_apply_score_panel_progress_style()
	
	if special_items_bar and special_items_bar.has_signal("item_clicked"):
		special_items_bar.item_clicked.connect(_on_special_item_clicked)
	UIIconScript.setup_all_buttons_feedback(self)


func _exit_tree() -> void:
	var state_mgr = _get_game_state()
	if state_mgr:
		if state_mgr.score_updated.is_connected(_on_score_updated):
			state_mgr.score_updated.disconnect(_on_score_updated)
		if state_mgr.level_updated.is_connected(_on_level_updated):
			state_mgr.level_updated.disconnect(_on_level_updated)
		if state_mgr.has_signal("game_started") and state_mgr.game_started.is_connected(_on_game_started):
			state_mgr.game_started.disconnect(_on_game_started)
		if state_mgr.has_signal("mode_changed") and state_mgr.mode_changed.is_connected(_on_mode_changed):
			state_mgr.mode_changed.disconnect(_on_mode_changed)
		if state_mgr.has_signal("language_changed") and state_mgr.language_changed.is_connected(_on_language_changed):
			state_mgr.language_changed.disconnect(_on_language_changed)
		if state_mgr.has_signal("level_completed") and state_mgr.level_completed.is_connected(_on_level_completed):
			state_mgr.level_completed.disconnect(_on_level_completed)
		if state_mgr.has_signal("special_item_discovered") and state_mgr.special_item_discovered.is_connected(_on_special_item_discovered):
			state_mgr.special_item_discovered.disconnect(_on_special_item_discovered)


func _apply_level_panel_progress_style() -> void:
	if not level_panel:
		level_panel = get_node_or_null("MarginContainer/VBoxContainer/HeaderRow/LevelPanel") as PanelContainer
	if not level_panel:
		return
	var empty_sb := StyleBoxEmpty.new()
	level_panel.add_theme_stylebox_override("panel", empty_sb)
	level_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	level_panel.set_meta("visual_identity", "royal_amber_gold_progress")
	if lbl_level_title:
		lbl_level_title.visible = false
	if lbl_level:
		lbl_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		GameTypographyScript.apply_hud_level_typography(lbl_level, 38)
	_ensure_level_crown_icon()


func _ensure_level_crown_icon() -> void:
	if not level_panel:
		return
	level_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	level_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var margin_box := level_panel.get_node_or_null("Margin") as MarginContainer
	if not margin_box:
		return
	var level_box := margin_box.get_node_or_null("LevelBox") as VBoxContainer
	if not level_box:
		return
	level_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	level_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var hbox := level_box.get_node_or_null("LevelHBox") as HBoxContainer
	if not hbox:
		hbox = HBoxContainer.new()
		hbox.name = "LevelHBox"
		hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
		hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_theme_constant_override("separation", 16)
		level_box.add_child(hbox)
	else:
		hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
		hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_theme_constant_override("separation", 16)
	
	if lbl_level and lbl_level.get_parent() != hbox:
		lbl_level.get_parent().remove_child(lbl_level)
		hbox.add_child(lbl_level)
	if lbl_level:
		lbl_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl_level.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_level.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var existing_crown := hbox.get_node_or_null("LevelCrownIcon") as Control
	if not existing_crown:
		if UIIconScript:
			existing_crown = UIIconScript.new("crown", Color(1.0, 0.92, 0.32, 1.0))
			existing_crown.name = "LevelCrownIcon"
			existing_crown.align_mode = "none"
			existing_crown.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			existing_crown.custom_minimum_size = Vector2(58, 58)
			existing_crown.size = Vector2(58, 58)
			hbox.add_child(existing_crown)
			hbox.move_child(existing_crown, 0)
	else:
		existing_crown.align_mode = "none"
		existing_crown.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		existing_crown.custom_minimum_size = Vector2(58, 58)
		existing_crown.size = Vector2(58, 58)
		hbox.move_child(existing_crown, 0)


func _apply_score_panel_progress_style() -> void:
	var score_panel = get_node_or_null("MarginContainer/VBoxContainer/HeaderRow/ScorePanel") as PanelContainer
	if not score_panel:
		return
	var empty_sb := StyleBoxEmpty.new()
	score_panel.add_theme_stylebox_override("panel", empty_sb)
	score_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	if lbl_score_title:
		lbl_score_title.visible = false
	if lbl_score:
		lbl_score.visible = false
	if lbl_goal_progress:
		lbl_goal_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_goal_progress.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_goal_progress.size_flags_horizontal = Control.SIZE_SHRINK_END
		lbl_goal_progress.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		GameTypographyScript.apply_hud_score_typography(lbl_goal_progress, 36)
	_ensure_score_star_icon()


func _ensure_score_star_icon() -> void:
	var score_panel = get_node_or_null("MarginContainer/VBoxContainer/HeaderRow/ScorePanel") as PanelContainer
	if not score_panel:
		return
	score_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var margin_box := score_panel.get_node_or_null("Margin") as MarginContainer
	if not margin_box:
		return
	var score_box := margin_box.get_node_or_null("ScoreBox") as VBoxContainer
	if not score_box:
		return
	score_box.alignment = BoxContainer.ALIGNMENT_END
	score_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Remove any duplicate star icons
	var dup_icon1 := score_panel.get_node_or_null("ScoreStarIcon")
	if dup_icon1:
		score_panel.remove_child(dup_icon1)
		dup_icon1.queue_free()
	if lbl_goal_progress:
		var dup_icon2 := lbl_goal_progress.get_node_or_null("ScoreStarIcon")
		if dup_icon2:
			lbl_goal_progress.remove_child(dup_icon2)
			dup_icon2.queue_free()

	var hbox := score_box.get_node_or_null("ScoreHBox") as HBoxContainer
	if not hbox:
		hbox = HBoxContainer.new()
		hbox.name = "ScoreHBox"
		hbox.alignment = BoxContainer.ALIGNMENT_END
		hbox.add_theme_constant_override("separation", 12)
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		score_box.add_child(hbox)
	else:
		hbox.alignment = BoxContainer.ALIGNMENT_END
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_theme_constant_override("separation", 12)
	
	if lbl_goal_progress and lbl_goal_progress.get_parent() != hbox:
		lbl_goal_progress.get_parent().remove_child(lbl_goal_progress)
		hbox.add_child(lbl_goal_progress)
	if lbl_goal_progress:
		lbl_goal_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_goal_progress.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_goal_progress.size_flags_horizontal = Control.SIZE_SHRINK_END
		lbl_goal_progress.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var existing_star := hbox.get_node_or_null("ScoreStarIcon") as Control
	if not existing_star:
		if UIIconScript:
			existing_star = UIIconScript.new("star_filled", Color(1.0, 0.88, 0.18, 1.0))
			existing_star.name = "ScoreStarIcon"
			existing_star.align_mode = "none"
			existing_star.size_flags_horizontal = Control.SIZE_SHRINK_END
			existing_star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			existing_star.custom_minimum_size = Vector2(54, 54)
			existing_star.size = Vector2(54, 54)
			hbox.add_child(existing_star)
			hbox.move_child(existing_star, 0)
	else:
		existing_star.align_mode = "none"
		existing_star.size_flags_horizontal = Control.SIZE_SHRINK_END
		existing_star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		existing_star.custom_minimum_size = Vector2(54, 54)
		existing_star.size = Vector2(54, 54)
		hbox.move_child(existing_star, 0)


func get_level_and_energy_visual_identity_metrics() -> Dictionary:
	_ensure_energy_header_control()
	_apply_level_panel_progress_style()
	var lv_sb := level_panel.get_theme_stylebox("panel") if level_panel else null
	var ep_sb := energy_panel.get_theme_stylebox("panel") as StyleBoxFlat if energy_panel else null
	var lv_bg: Color = lv_sb.bg_color if (lv_sb is StyleBoxFlat) else Color(0.98, 0.72, 0.12, 1.0)
	var ep_bg: Color = ep_sb.bg_color if ep_sb else Color.BLACK
	var lv_border: Color = lv_sb.border_color if (lv_sb is StyleBoxFlat) else Color(1.0, 0.88, 0.28, 1.0)
	var ep_border: Color = ep_sb.border_color if ep_sb else Color.BLACK
	var bg_diff: float = absf(lv_bg.r - ep_bg.r) + absf(lv_bg.g - ep_bg.g) + absf(lv_bg.b - ep_bg.b)
	var border_diff: float = absf(lv_border.r - ep_border.r) + absf(lv_border.g - ep_border.g) + absf(lv_border.b - ep_border.b)
	return {
		"level_bg_color": lv_bg,
		"energy_bg_color": ep_bg,
		"level_border_color": lv_border,
		"energy_border_color": ep_border,
		"level_identity": String(level_panel.get_meta("visual_identity", "")) if level_panel else "",
		"energy_identity": String(energy_panel.get_meta("visual_identity", "")) if energy_panel else "",
		"bg_color_manhattan_distance": bg_diff,
		"border_color_manhattan_distance": border_diff,
		"are_clearly_distinct": (
			lv_sb != null and ep_sb != null
			and bg_diff >= 0.85
			and border_diff >= 0.50
			and lv_bg.r > lv_bg.b * 2.5
			and ep_bg.b > ep_bg.r * 2.5
		)
	}


func _ensure_energy_header_control() -> void:
	_apply_level_panel_progress_style()
	var header_row := get_node_or_null("MarginContainer/VBoxContainer/HeaderRow") as HBoxContainer
	if not header_row:
		return
	energy_panel = header_row.get_node_or_null("EnergyPanel") as PanelContainer
	if not energy_panel:
		energy_panel = PanelContainer.new()
		energy_panel.name = "EnergyPanel"
		energy_panel.custom_minimum_size = Vector2(102, 48)
		energy_panel.size = Vector2(102, 48)
		energy_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		energy_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var st_ep := StyleBoxFlat.new()
		st_ep.bg_color = Color(0.06, 0.46, 0.56, 0.98)
		st_ep.border_width_left = 2
		st_ep.border_width_top = 2
		st_ep.border_width_right = 2
		st_ep.border_width_bottom = 5
		st_ep.border_color = Color(0.30, 0.96, 0.88, 1.0)
		st_ep.shadow_color = Color(0.02, 0.16, 0.24, 0.60)
		st_ep.shadow_size = 7
		st_ep.shadow_offset = Vector2(0, 3)
		st_ep.set_corner_radius_all(18)
		st_ep.content_margin_left = 7.0
		st_ep.content_margin_right = 7.0
		st_ep.content_margin_top = 0.0
		st_ep.content_margin_bottom = 0.0
		st_ep.expand_margin_left = 0.0
		st_ep.expand_margin_right = 0.0
		st_ep.expand_margin_top = 0.0
		st_ep.expand_margin_bottom = 0.0
		energy_panel.add_theme_stylebox_override("panel", st_ep)
		energy_panel.set_meta("visual_identity", "electric_teal_stamina")
		header_row.add_child(energy_panel)
		var lvl_idx: int = level_panel.get_index() if level_panel else 0
		header_row.move_child(energy_panel, min(lvl_idx + 1, header_row.get_child_count() - 1))

		var hbox := HBoxContainer.new()
		hbox.name = "EnergyHBox"
		hbox.custom_minimum_size = Vector2.ZERO
		hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 5)
		energy_panel.add_child(hbox)

		energy_icon = UIIconScript.new("bolt")
		energy_icon.name = "EnergyBoltIcon"
		energy_icon.align_mode = "none"
		energy_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		energy_icon.custom_minimum_size = Vector2(22, 22)
		energy_icon.size = Vector2(22, 22)
		energy_icon.primary_color = Color(1.0, 0.94, 0.26, 1.0)
		hbox.add_child(energy_icon)

		var st_plus := StyleBoxEmpty.new()
		st_plus.content_margin_left = 0.0
		st_plus.content_margin_right = 0.0
		st_plus.content_margin_top = 0.0
		st_plus.content_margin_bottom = 0.0

		lbl_energy = Label.new()
		lbl_energy.name = "LblEnergy"
		lbl_energy.text = "24/24"
		lbl_energy.custom_minimum_size = Vector2.ZERO
		lbl_energy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lbl_energy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_energy.add_theme_stylebox_override("normal", st_plus)
		lbl_energy.add_theme_font_size_override("font_size", 15)
		lbl_energy.add_theme_color_override("font_color", Color(0.92, 1.0, 0.99, 1.0))
		lbl_energy.add_theme_color_override("font_outline_color", Color(0.02, 0.18, 0.24, 0.96))
		lbl_energy.add_theme_constant_override("outline_size", 2)
		hbox.add_child(lbl_energy)

		btn_energy_plus = Button.new()
		btn_energy_plus.name = "BtnEnergyPlus"
		btn_energy_plus.text = ""
		btn_energy_plus.flat = true
		btn_energy_plus.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn_energy_plus.custom_minimum_size = Vector2(28, 28)
		btn_energy_plus.size = Vector2(28, 28)
		btn_energy_plus.add_theme_constant_override("h_separation", 0)
		btn_energy_plus.add_theme_font_size_override("font_size", 22)
		btn_energy_plus.add_theme_color_override("font_color", Color(0.38, 1.0, 0.58, 1.0))
		btn_energy_plus.add_theme_color_override("font_hover_color", Color(0.56, 1.0, 0.72, 1.0))
		btn_energy_plus.add_theme_color_override("font_pressed_color", Color(0.24, 0.90, 0.46, 1.0))
		btn_energy_plus.add_theme_color_override("font_disabled_color", Color(0.62, 0.74, 0.86, 0.78))
		btn_energy_plus.add_theme_color_override("font_outline_color", Color(0.04, 0.22, 0.14, 0.96))
		btn_energy_plus.add_theme_constant_override("outline_size", 2)
		btn_energy_plus.add_theme_stylebox_override("normal", st_plus)
		btn_energy_plus.add_theme_stylebox_override("hover", st_plus)
		btn_energy_plus.add_theme_stylebox_override("pressed", st_plus)
		btn_energy_plus.add_theme_stylebox_override("hover_pressed", st_plus)
		btn_energy_plus.add_theme_stylebox_override("disabled", st_plus)
		btn_energy_plus.add_theme_stylebox_override("focus", st_plus)
		btn_energy_plus.set_meta("has_separate_background_frame", false)
		btn_energy_plus.set_meta("is_integrated_energy_plus", true)
		UIIconScript.attach_to_button(btn_energy_plus, "plus", Vector2(28, 28), "center", Color(0.38, 1.0, 0.58, 1.0))
		UIIconScript.remove_focus_outline(btn_energy_plus)
		UIIconScript.setup_button_press_feedback(btn_energy_plus)
		btn_energy_plus.pressed.connect(_on_btn_energy_plus_pressed)
		hbox.add_child(btn_energy_plus)
		energy_panel.set_meta("is_unified_energy_control", true)

	if not energy_ad_modal:
		energy_ad_modal = Control.new()
		energy_ad_modal.name = "EnergyFullscreenAdModal"
		energy_ad_modal.top_level = true
		energy_ad_modal.visible = false
		energy_ad_modal.anchor_right = 1.0
		energy_ad_modal.anchor_bottom = 1.0
		energy_ad_modal.custom_minimum_size = Vector2(720, 1280)
		energy_ad_modal.z_index = 120
		add_child(energy_ad_modal)

		var bg := ColorRect.new()
		bg.name = "AdBackdrop"
		bg.anchor_right = 1.0
		bg.anchor_bottom = 1.0
		bg.color = Color(0.04, 0.06, 0.16, 0.96)
		energy_ad_modal.add_child(bg)

		var vbox := VBoxContainer.new()
		vbox.name = "AdContentVBox"
		vbox.anchor_left = 0.1
		vbox.anchor_right = 0.9
		vbox.anchor_top = 0.25
		vbox.anchor_bottom = 0.75
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 18)
		energy_ad_modal.add_child(vbox)

		var lbl_ad_title := Label.new()
		lbl_ad_title.name = "LblAdTitle"
		lbl_ad_title.text = "REWARDED ADVERTISEMENT"
		lbl_ad_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_ad_title.add_theme_font_size_override("font_size", 26)
		lbl_ad_title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.34, 1.0))
		vbox.add_child(lbl_ad_title)

		var lbl_ad_desc := Label.new()
		lbl_ad_desc.name = "LblAdDesc"
		lbl_ad_desc.text = "Watch full-screen ad to earn +1 Energy"
		lbl_ad_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_ad_desc.add_theme_font_size_override("font_size", 18)
		vbox.add_child(lbl_ad_desc)

		var btn_complete := Button.new()
		btn_complete.name = "BtnCompleteAd"
		btn_complete.text = "COMPLETE AD (+1 ENERGY)"
		btn_complete.custom_minimum_size = Vector2(240, 56)
		UIIconScript.remove_focus_outline(btn_complete)
		UIIconScript.setup_button_press_feedback(btn_complete)
		btn_complete.pressed.connect(func(): complete_energy_rewarded_ad(_active_energy_ad_session_id))
		vbox.add_child(btn_complete)

		var btn_skip := Button.new()
		btn_skip.name = "BtnSkipAd"
		btn_skip.text = "SKIP / CLOSE"
		btn_skip.custom_minimum_size = Vector2(240, 50)
		UIIconScript.remove_focus_outline(btn_skip)
		UIIconScript.setup_button_press_feedback(btn_skip)
		btn_skip.pressed.connect(func(): skip_energy_rewarded_ad())
		vbox.add_child(btn_skip)


func update_energy_display() -> void:
	_ensure_energy_header_control()
	var state_mgr = _get_game_state()
	var cur_e: int = state_mgr.get_energy() if (state_mgr and state_mgr.has_method("get_energy")) else 24
	var max_e: int = state_mgr.get_max_energy() if (state_mgr and state_mgr.has_method("get_max_energy")) else 24
	if lbl_energy:
		lbl_energy.text = "%d/%d" % [cur_e, max_e]
	if btn_energy_plus:
		btn_energy_plus.disabled = (cur_e >= max_e)


func _on_btn_energy_plus_pressed() -> void:
	open_energy_rewarded_ad()


func open_energy_rewarded_ad() -> String:
	_ensure_energy_header_control()
	var state_mgr = _get_game_state()
	if not state_mgr or not state_mgr.has_method("open_rewarded_ad_for_energy"):
		return ""
	var sid: String = state_mgr.open_rewarded_ad_for_energy()
	_active_energy_ad_session_id = sid
	if energy_ad_modal:
		energy_ad_modal.visible = true
	return sid


func complete_energy_rewarded_ad(session_id: String = "") -> Dictionary:
	var state_mgr = _get_game_state()
	var sid: String = session_id if session_id != "" else _active_energy_ad_session_id
	var res: Dictionary = {"granted": false, "amount": 0}
	if state_mgr and state_mgr.has_method("complete_rewarded_ad_for_energy"):
		res = state_mgr.complete_rewarded_ad_for_energy(sid)
	if energy_ad_modal:
		energy_ad_modal.visible = false
	update_energy_display()
	return res


func skip_energy_rewarded_ad() -> Dictionary:
	var state_mgr = _get_game_state()
	var res: Dictionary = {"granted": false, "amount": 0}
	if state_mgr and state_mgr.has_method("skip_rewarded_ad_for_energy"):
		res = state_mgr.skip_rewarded_ad_for_energy()
	if energy_ad_modal:
		energy_ad_modal.visible = false
	update_energy_display()
	return res


func watch_energy_rewarded_ad(ad_completed: bool = true) -> Dictionary:
	var sid := open_energy_rewarded_ad()
	if ad_completed:
		return complete_energy_rewarded_ad(sid)
	return skip_energy_rewarded_ad()


func _on_language_changed(_lang: String) -> void:
	_refresh_language()


func _refresh_language() -> void:
	var state_mgr = _get_game_state()
	if not state_mgr:
		return
	if lbl_score_title and state_mgr.has_method("tr_text"):
		lbl_score_title.text = state_mgr.tr_text("hud_score_title")
	_on_level_updated(state_mgr.level, 0)
	_update_mode_presentation(state_mgr.current_mode)
	_update_stars_and_goal()


func _on_game_started(mode: int) -> void:
	if special_items_bar and special_items_bar.has_method("reset_inventory"):
		special_items_bar.reset_inventory()
	_refresh_language()
	_update_mode_presentation(mode)
	_update_stars_and_goal()


func _on_mode_changed(mode: int) -> void:
	_update_mode_presentation(mode)


func _update_mode_presentation(mode: int) -> void:
	if not special_items_bar:
		special_items_bar = get_node_or_null("MarginContainer/VBoxContainer/SpecialItemsBar")
	var state_mgr = _get_game_state()
	var is_modern = (mode == GameStateScript.GameMode.MODERN_DRAG_AND_DROP)
	if state_mgr and state_mgr.has_method("has_special_items"):
		is_modern = state_mgr.has_special_items(mode)
	
	if special_items_bar:
		special_items_bar.visible = is_modern
	
	if lbl_level_title:
		if state_mgr and state_mgr.has_method("get_combination_name"):
			lbl_level_title.text = state_mgr.get_combination_name().to_upper()
		else:
			lbl_level_title.text = "MODERN" if is_modern else "CLASSIC"
		lbl_level_title.add_theme_color_override(
			"font_color",
			Color(0.45, 0.98, 1.0, 1.0) if is_modern else Color(1.0, 0.88, 0.32, 1.0)
		)


func is_special_items_visible() -> bool:
	if not special_items_bar:
		special_items_bar = get_node_or_null("MarginContainer/VBoxContainer/SpecialItemsBar")
	return special_items_bar != null and special_items_bar.visible


func _update_stars_and_goal() -> void:
	var state_mgr = _get_game_state()
	if not state_mgr:
		return
	if lbl_star_meter:
		lbl_star_meter.visible = false
		lbl_star_meter.text = ""
	if lbl_goal_progress:
		_ensure_score_star_icon()
		var cur_lvl = state_mgr.active_level if "active_level" in state_mgr else state_mgr.level
		var target_pts = state_mgr.get_level_target_score(cur_lvl) if state_mgr.has_method("get_level_target_score") else (cur_lvl * 500)
		var fmt = state_mgr.tr_text("hud_goal") if state_mgr.has_method("tr_text") else "%s / %s"
		lbl_goal_progress.text = fmt % [_format_score(state_mgr.score), _format_score(target_pts)]


func _on_score_updated(new_score: int, added: int) -> void:
	if lbl_score:
		lbl_score.text = _format_score(new_score)
		if added > 0 and is_inside_tree():
			lbl_score.pivot_offset = lbl_score.size * 0.5
			var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(lbl_score, "scale", Vector2(1.22, 1.22), 0.09)
			tw.tween_property(lbl_score, "scale", Vector2(1.0, 1.0), 0.14)
	if added > 0 and points_popup and is_inside_tree():
		points_popup.text = "+%d PTS" % added
		points_popup.pivot_offset = points_popup.size * 0.5
		points_popup.position = Vector2(0, 98)
		points_popup.scale = Vector2(0.82, 0.82)
		points_popup.modulate.a = 1.0
		var tw_p = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_p.tween_property(points_popup, "scale", Vector2(1.26, 1.26), 0.16)
		tw_p.tween_property(points_popup, "position:y", 68.0, 0.45)
		tw_p.tween_property(points_popup, "modulate:a", 0.0, 0.50)
	_update_stars_and_goal()


func _on_level_updated(new_level: int, _lines: int) -> void:
	if lbl_level:
		var state_mgr = _get_game_state()
		var disp_lvl = state_mgr.active_level if (state_mgr and "active_level" in state_mgr) else new_level
		var fmt = state_mgr.tr_text("hud_level") if (state_mgr and state_mgr.has_method("tr_text")) else "LV %d"
		lbl_level.text = fmt % disp_lvl
	_update_stars_and_goal()


func _on_special_item_discovered(item_id: String, _new_qty: int) -> void:
	if not callout_banner or not is_inside_tree():
		return
	var state_mgr = _get_game_state()
	var item_label := "BOMB +1"
	match item_id:
		"bomb": item_label = (state_mgr.tr_text("item_bomb") if state_mgr else "BOMB") + " +1"
		"change_block": item_label = (state_mgr.tr_text("item_change_block") if state_mgr else "CHANGE BLOCK") + " +1"
		"extra_life": item_label = (state_mgr.tr_text("item_extra_life") if state_mgr else "EXTRA LIFE") + " +1"
	var fmt = state_mgr.tr_text("bonus_item_banner") if state_mgr else "BONUS ITEM: %s!"
	callout_banner.text = fmt % item_label
	callout_banner.position = Vector2(0, 178)
	callout_banner.scale = Vector2(0.75, 0.75)
	callout_banner.modulate.a = 1.0
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(callout_banner, "scale", Vector2(1.15, 1.15), 0.20)
	tw.tween_property(callout_banner, "position", Vector2(0, 158), 0.20)
	var tw2 = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw2.tween_interval(0.85)
	tw2.tween_property(callout_banner, "modulate:a", 0.0, 0.32)


func _on_level_completed(completed_lvl: int, _stars: int, reward_coins: int) -> void:
	if not callout_banner or not is_inside_tree():
		return
	var state_mgr = _get_game_state()
	var fmt = state_mgr.tr_text("level_complete_banner") if state_mgr else "LEVEL %d COMPLETE! +%d COINS!"
	callout_banner.text = fmt % [completed_lvl, reward_coins]
	callout_banner.position = Vector2(0, 180)
	callout_banner.scale = Vector2(0.75, 0.75)
	callout_banner.modulate.a = 1.0
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(callout_banner, "scale", Vector2(1.18, 1.18), 0.22)
	tw.tween_property(callout_banner, "position", Vector2(0, 160), 0.22)
	var tw2 = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw2.tween_interval(0.95)
	tw2.tween_property(callout_banner, "modulate:a", 0.0, 0.35)


func _on_combo_updated(_combo: int) -> void:
	# Gameplay callouts are displayed exclusively by the single main gameplay Board callout system
	pass


func _on_voice_callout(_callout_text: String) -> void:
	# Gameplay callouts are displayed exclusively by the single main gameplay Board callout system
	pass


func has_duplicate_next_piece_callout() -> bool:
	if get_node_or_null("VoiceCalloutBanner") != null or get_node_or_null("ComboBanner") != null:
		return true
	if callout_banner != null or combo_banner != null:
		return true
	var audio_mgr = _get_audio_manager()
	if audio_mgr and audio_mgr.has_signal("voice_callout_triggered"):
		if audio_mgr.voice_callout_triggered.is_connected(_on_voice_callout):
			return true
	var state_mgr = _get_game_state()
	if state_mgr and state_mgr.has_signal("combo_updated"):
		if state_mgr.combo_updated.is_connected(_on_combo_updated):
			return true
	return false


func has_callout_background_panel() -> bool:
	for b_lbl in [callout_banner, combo_banner]:
		if not b_lbl:
			continue
		if b_lbl.get_child_count() > 0:
			return true
		var sb: StyleBox = b_lbl.get_theme_stylebox("normal")
		if sb != null and not (sb is StyleBoxEmpty):
			return true
	return false


func get_callout_visual_metrics() -> Dictionary:
	return {
		"callout_font_size": CALLOUT_FONT_SIZE,
		"combo_font_size": COMBO_FONT_SIZE,
		"points_popup_font_size": POINTS_POPUP_FONT_SIZE,
		"callout_peak_scale": CALLOUT_PEAK_SCALE,
		"combo_peak_scale": COMBO_PEAK_SCALE,
		"callout_outline_size": CALLOUT_OUTLINE_SIZE,
		"combo_outline_size": COMBO_OUTLINE_SIZE,
		"has_background_panel": has_callout_background_panel(),
		"has_display_font_treatment": callout_display_font != null
	}


func _format_score(val: int) -> String:
	if val < 1000:
		return str(val)
	
	var s = str(val)
	var res = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			res = "," + res
		res = s[i] + res
		count += 1
	return res


func _on_btn_settings_pressed() -> void:
	var audio_mgr = _get_audio_manager()
	if audio_mgr:
		audio_mgr.play_button_click()
	var state_mgr = _get_game_state()
	if state_mgr:
		state_mgr.pause_game(true)


func _on_viewport_size_changed() -> void:
	if is_inside_tree() and get_viewport():
		update_responsive_layout(get_viewport_rect().size)


func update_responsive_layout(vp_size: Vector2 = Vector2(720, 1280)) -> void:
	var vp_w: float = vp_size.x if vp_size.x > 0 else 720.0
	var is_compact: bool = (vp_w <= 430.0 or (vp_size.y > 0 and vp_size.y <= 900.0))
	var is_ultra_narrow: bool = (vp_w <= 370.0 or (vp_size.y > 0 and vp_size.y <= 810.0))
	var header_ctrl_h: float = 44.0 if is_ultra_narrow else (48.0 if is_compact else 56.0)
	var gs = _get_game_state()
	var insets: Dictionary = gs.get_safe_area_insets(vp_size) if (gs and gs.has_method("get_safe_area_insets")) else {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}
	var safe_top: float = float(insets.get("top", 0.0))
	var safe_left: float = float(insets.get("left", 0.0))
	var safe_right: float = float(insets.get("right", 0.0))
	var base_m_top: int = 6 if is_ultra_narrow else (8 if is_compact else 12)
	var base_m_side: int = 6 if is_ultra_narrow else (10 if is_compact else 18)
	var margin_ctrl := get_node_or_null("MarginContainer") as MarginContainer
	if margin_ctrl:
		margin_ctrl.add_theme_constant_override("margin_left", int(base_m_side + safe_left))
		margin_ctrl.add_theme_constant_override("margin_right", int(base_m_side + safe_right))
		margin_ctrl.add_theme_constant_override("margin_top", int(float(base_m_top) + safe_top))
		margin_ctrl.add_theme_constant_override("margin_bottom", 4 if is_compact else 6)
	var total_header_h: float = float(base_m_top) + safe_top + header_ctrl_h + (4.0 if is_compact else 6.0)
	custom_minimum_size.y = maxf(custom_minimum_size.y, total_header_h)
	size.y = maxf(size.y, total_header_h)
	if margin_ctrl:
		margin_ctrl.custom_minimum_size.y = maxf(margin_ctrl.custom_minimum_size.y, total_header_h)
		margin_ctrl.size.y = maxf(margin_ctrl.size.y, total_header_h)
	var score_panel_node := get_node_or_null("MarginContainer/VBoxContainer/HeaderRow/ScorePanel") as PanelContainer
	if level_panel:
		level_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		level_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		level_panel.custom_minimum_size = Vector2(78.0 if is_ultra_narrow else (92.0 if is_compact else 126.0), header_ctrl_h)
		level_panel.size.y = header_ctrl_h
		var lvl_m := level_panel.get_node_or_null("Margin") as MarginContainer
		if lvl_m:
			lvl_m.add_theme_constant_override("margin_right", 8 if is_ultra_narrow else (12 if is_compact else 18))
		var lvl_box := level_panel.get_node_or_null("Margin/LevelBox") as VBoxContainer
		if lvl_box:
			lvl_box.alignment = BoxContainer.ALIGNMENT_BEGIN
			lvl_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var lvl_hbox := level_panel.get_node_or_null("Margin/LevelBox/LevelHBox") as HBoxContainer
		if lvl_hbox:
			lvl_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
			lvl_hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			lvl_hbox.add_theme_constant_override("separation", 8 if is_ultra_narrow else (12 if is_compact else 16))
	var crown_icon := find_child("LevelCrownIcon", true, false) as Control
	if crown_icon:
		var crown_sz := Vector2(36, 36) if is_ultra_narrow else (Vector2(42, 42) if is_compact else Vector2(56, 56))
		crown_icon.align_mode = "none"
		crown_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		crown_icon.custom_minimum_size = crown_sz
		crown_icon.size = crown_sz
		crown_icon.update_minimum_size()
		crown_icon.queue_redraw()
	if lbl_level:
		var lvl_f_sz: int = 26 if is_ultra_narrow else (30 if is_compact else 38)
		GameTypographyScript.apply_hud_level_typography(lbl_level, lvl_f_sz)
		lbl_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl_level.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_level.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if score_panel_node:
		score_panel_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		score_panel_node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		score_panel_node.custom_minimum_size = Vector2(86.0 if is_ultra_narrow else (98.0 if is_compact else 170.0), header_ctrl_h)
		score_panel_node.size.y = header_ctrl_h
		var sc_box := score_panel_node.get_node_or_null("Margin/ScoreBox") as VBoxContainer
		if sc_box:
			sc_box.alignment = BoxContainer.ALIGNMENT_END
			sc_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sc_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var sc_hbox := score_panel_node.get_node_or_null("Margin/ScoreBox/ScoreHBox") as HBoxContainer
		if sc_hbox:
			sc_hbox.alignment = BoxContainer.ALIGNMENT_END
			sc_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sc_hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			sc_hbox.add_theme_constant_override("separation", 6 if is_ultra_narrow else (8 if is_compact else 12))
	var star_icon := find_child("ScoreStarIcon", true, false) as Control
	if star_icon:
		var star_sz := Vector2(36, 36) if is_ultra_narrow else (Vector2(42, 42) if is_compact else Vector2(54, 54))
		star_icon.align_mode = "none"
		star_icon.size_flags_horizontal = Control.SIZE_SHRINK_END
		star_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		star_icon.custom_minimum_size = star_sz
		star_icon.size = star_sz
		star_icon.update_minimum_size()
		star_icon.queue_redraw()
	if lbl_goal_progress:
		var sc_f_sz: int = 22 if is_ultra_narrow else (26 if is_compact else 34)
		GameTypographyScript.apply_hud_score_typography(lbl_goal_progress, sc_f_sz)
		lbl_goal_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_goal_progress.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_goal_progress.size_flags_horizontal = Control.SIZE_SHRINK_END
		lbl_goal_progress.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if energy_icon:
		var bolt_sz := Vector2(18, 18) if is_ultra_narrow else (Vector2(20, 20) if is_compact else Vector2(24, 24))
		if "align_mode" in energy_icon:
			energy_icon.align_mode = "none"
		energy_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		energy_icon.custom_minimum_size = bolt_sz
		energy_icon.size = bolt_sz
		energy_icon.update_minimum_size()
		energy_icon.queue_redraw()
	if lbl_energy:
		lbl_energy.custom_minimum_size = Vector2.ZERO
		lbl_energy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		GameTypographyScript.apply_energy_typography(lbl_energy, 13 if is_ultra_narrow else (14 if is_compact else 16))
		lbl_energy.update_minimum_size()
	if btn_energy_plus:
		var plus_sz := Vector2(26, 26) if is_ultra_narrow else (Vector2(28, 28) if is_compact else Vector2(32, 32))
		btn_energy_plus.text = ""
		btn_energy_plus.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn_energy_plus.custom_minimum_size = plus_sz
		btn_energy_plus.size = plus_sz
		btn_energy_plus.add_theme_font_size_override("font_size", 20 if is_ultra_narrow else (22 if is_compact else 24))
		var plus_icon := btn_energy_plus.get_node_or_null("VectorIcon") as Control
		if plus_icon:
			plus_icon.custom_minimum_size = plus_sz
			plus_icon.size = plus_sz
			if plus_icon.has_method("_on_parent_resized"):
				plus_icon._on_parent_resized()
		btn_energy_plus.update_minimum_size()
	if energy_panel:
		var ep_sz := Vector2(82.0, header_ctrl_h) if is_ultra_narrow else (Vector2(90.0, header_ctrl_h) if is_compact else Vector2(128.0, header_ctrl_h))
		energy_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var ep_hbox := energy_panel.get_node_or_null("EnergyHBox") as HBoxContainer
		if ep_hbox:
			ep_hbox.custom_minimum_size = Vector2.ZERO
			ep_hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			ep_hbox.update_minimum_size()
			ep_hbox.size = ep_sz
		energy_panel.custom_minimum_size = ep_sz
		energy_panel.update_minimum_size()
		energy_panel.size = ep_sz
	var settings_box := get_node_or_null("MarginContainer/VBoxContainer/HeaderRow/SettingsBox") as Control
	if settings_box:
		settings_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if btn_settings:
		var target_btn_sz := Vector2(50.0, 42.0) if is_ultra_narrow else (Vector2(56.0, 46.0) if is_compact else Vector2(66.0, 54.0))
		UIIconScript.apply_frameless_icon_button_style(btn_settings)
		btn_settings.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn_settings.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn_settings.custom_minimum_size = target_btn_sz
		btn_settings.size = target_btn_sz
		var icon_side: float = target_btn_sz.y - 4.0
		var icon_sz := Vector2(icon_side, icon_side)
		var gear_ctrl := UIIconScript.attach_to_button(btn_settings, "gear", icon_sz, "center", Color(0.70, 0.73, 0.77, 1.0))
		if gear_ctrl:
			gear_ctrl.secondary_color = Color(0.20, 0.24, 0.35, 1.0)
			gear_ctrl._on_parent_resized()


func update_responsive_hud_layout(vp_size: Vector2 = Vector2(720, 1280)) -> void:
	update_responsive_layout(vp_size)


func has_gear_icon() -> bool:
	if not btn_settings:
		return false
	var ic := btn_settings.get_node_or_null("VectorIcon") as Control
	return ic != null and ("icon_type" in ic) and ic.icon_type == "gear"


func is_settings_gear_frameless() -> bool:
	if not btn_settings or not has_gear_icon():
		return false
	return UIIconScript.is_button_frameless(btn_settings)


func has_star_rating_in_hud() -> bool:
	if lbl_star_meter and lbl_star_meter.visible:
		return true
	var star_icon := find_child("HudStarsIcon", true, false) as Control
	if star_icon and star_icon.visible:
		return true
	return false


func get_hud_hierarchy_metrics() -> Dictionary:
	var header_row := get_node_or_null("MarginContainer/VBoxContainer/HeaderRow") as HBoxContainer
	var score_panel := get_node_or_null("MarginContainer/VBoxContainer/HeaderRow/ScorePanel") as PanelContainer
	var h_px: float = 52.0
	if header_row and header_row.size.y > 0.0:
		h_px = minf(68.0, header_row.size.y)
	return {
		"has_level_element": level_panel != null and lbl_level != null and lbl_level.visible,
		"has_score_element": score_panel != null and ((lbl_score != null and lbl_score.visible) or (lbl_goal_progress != null and lbl_goal_progress.visible)),
		"has_energy_element": energy_panel != null and lbl_energy != null and energy_panel.visible,
		"has_settings_gear": btn_settings != null and has_gear_icon(),
		"is_settings_gear_frameless": is_settings_gear_frameless(),
		"is_settings_frameless_gear": is_settings_gear_frameless(),
		"has_balanced_4_item_header": level_panel != null and score_panel != null and energy_panel != null and btn_settings != null and not has_star_rating_in_hud(),
		"uses_stars_as_primary_hud_element": has_star_rating_in_hud(),
		"has_star_rating_in_hud": has_star_rating_in_hud(),
		"is_compact_and_balanced": not has_star_rating_in_hud() and h_px <= 68.0,
		"header_height_px": h_px
	}


func get_header_layout_metrics() -> Dictionary:
	return get_hud_hierarchy_metrics()


func has_well_proportioned_settings_button() -> bool:
	if not btn_settings:
		return false
	var sz: Vector2 = btn_settings.size if (btn_settings.size.x > 0 and btn_settings.size.y > 0) else btn_settings.custom_minimum_size
	var icon_node := btn_settings.get_node_or_null("VectorIcon") as Control
	if not icon_node or not ("icon_type" in icon_node) or icon_node.icon_type != "gear":
		return false
	var aspect: float = sz.x / maxf(1.0, sz.y)
	return sz.x >= 54.0 and sz.y >= 44.0 and sz.x > sz.y and aspect >= 1.08 and aspect <= 1.55 and icon_node.size.y >= sz.y - 8.0 and btn_settings.text == ""


func has_proper_settings_button_proportions() -> bool:
	return has_well_proportioned_settings_button()



func _on_special_item_clicked(item_id: String) -> void:
	var state_mgr = _get_game_state()
	if item_id == "extra_life":
		if not state_mgr or state_mgr.current_state != GameStateScript.State.GAME_OVER:
			return
		if state_mgr.has_method("can_use_extra_life_now") and not state_mgr.can_use_extra_life_now():
			return
	if state_mgr and state_mgr.has_method("has_special_items") and not state_mgr.has_special_items():
		return
	if not special_items_bar:
		return
	var current_count: int = int(special_items_bar.inventory.get(item_id, 0))
	if current_count <= 0:
		return
	var game_world = get_tree().root.find_child("GameWorld", true, false)
	if game_world and game_world.has_method("use_special_item"):
		var consumed_immediately: bool = game_world.use_special_item(item_id)
		var active_mode = game_world.get_active_mode() if game_world.has_method("get_active_mode") else null
		if active_mode and "pending_special_item" in active_mode:
			special_items_bar.set_item_selected(active_mode.pending_special_item, active_mode.pending_special_item != "")
			if not active_mode.special_item_Pending_changed.is_connected(_on_mode_pending_item_changed):
				active_mode.special_item_Pending_changed.connect(_on_mode_pending_item_changed)
			if not active_mode.special_item_consumed.is_connected(_on_mode_item_consumed):
				active_mode.special_item_consumed.connect(_on_mode_item_consumed)
		if consumed_immediately:
			if special_items_bar.has_method("animate_activation"):
				special_items_bar.animate_activation(item_id)


func _on_mode_pending_item_changed(pending_id: String) -> void:
	if special_items_bar and special_items_bar.has_method("set_item_selected"):
		if pending_id == "":
			special_items_bar.set_item_selected("", false)
		else:
			special_items_bar.set_item_selected(pending_id, true)


func _on_mode_item_consumed(item_id: String) -> void:
	if special_items_bar:
		special_items_bar.set_item_selected("", false)
		if special_items_bar.has_method("animate_activation"):
			special_items_bar.animate_activation(item_id)
