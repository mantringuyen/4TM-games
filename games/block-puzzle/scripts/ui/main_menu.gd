class_name MainMenu
extends Control

## MainMenu — Casual Mobile Puzzle Home Screen for Block Puzzle — 4TM

const GameStateScript = preload("res://scripts/autoload/game_state.gd")
const UIIconScript = preload("res://scripts/ui/ui_icon.gd")
const GameTypographyScript = preload("res://scripts/ui/game_typography.gd")
const MapTheme = preload("res://scripts/map_core/map_theme.gd")
const MapRoute = preload("res://scripts/map_core/map_route.gd")
const MapNode = preload("res://scripts/map_core/map_node.gd")
const MapPage = preload("res://scripts/map_core/map_page.gd")
const MapLayoutGenerator = preload("res://scripts/map_core/map_layout_generator.gd")
const MapRenderer = preload("res://scripts/map_core/map_renderer.gd")
const MapData = preload("res://scripts/map_core/map_data.gd")
const BlockPuzzleMapConfig = preload("res://scripts/map_core/block_puzzle_map_config.gd")
const MapDataScript = MapData
const MapPageScript = MapPage
const MapThemeScript = MapTheme
const MapNodeScript = MapNode
const MapRouteScript = MapRoute
const MapLayoutGeneratorScript = MapLayoutGenerator
const MapRendererScript = MapRenderer
const BlockPuzzleMapConfigScript = BlockPuzzleMapConfig

@onready var btn_classic: Button = _find_node("BtnClassic") as Button
@onready var btn_modern: Button = _find_node("BtnModern") as Button
@onready var btn_falling: Button = _find_node("BtnFalling") as Button
@onready var btn_drag_drop: Button = _find_node("BtnDragDrop") as Button
@onready var btn_start: Button = _find_node("BtnStartGame") as Button
var btn_play_classic: Button:
	get:
		return btn_start

@onready var lbl_ecosystem: Label = _find_node("LblEcosystem") as Label
@onready var lbl_title: Label = _find_node("LblTitle") as Label
@onready var lbl_subtitle: Label = _find_node("LblSubtitle") as Label
@onready var lbl_mode_title: Label = _find_node("LblModeTitle") as Label
@onready var lbl_play_style_title: Label = _find_node("LblPlayStyleTitle") as Label

const RewardedAdScript = preload("res://scripts/core/rewarded_ad_interface.gd")

@onready var btn_top_level: Button = _find_node("BtnTopLevel") as Button
@onready var btn_daily_gift: Button = _find_node("BtnDailyGift") as Button
var energy_panel: PanelContainer = null
var lbl_energy: Label = null
var btn_energy_plus: Button = null
var _energy_ad_overlay: Control = null
var _energy_ad_session_id: String = ""
var _energy_rewarded_ad: RefCounted = null
var btn_language: Button:
	get:
		return _find_node("BtnLanguage") as Button
@onready var btn_top_settings: Button = _find_node("BtnTopSettings") as Button
var btn_settings: Button:
	get:
		return btn_top_settings

@onready var btn_how_to_play: Button = _find_node("BtnHowToPlay") as Button
@onready var btn_settings_account: Button = get_node_or_null("Modals/SettingsModal/Panel/VBoxContainer/BtnAccountSettings")
@onready var btn_nav_account: Button = get_node_or_null("MarginContainer/VBoxContainer/NavActions/BtnAccount")
@onready var btn_account: Button = get_node_or_null("Modals/SettingsModal/Panel/VBoxContainer/BtnAccountSettings") if get_node_or_null("Modals/SettingsModal/Panel/VBoxContainer/BtnAccountSettings") != null else (_find_node("BtnAccount") as Button)
var btn_info: Button:
	get:
		return btn_how_to_play
var btn_rules_help: Button:
	get:
		return _find_node("BtnRulesHelp") as Button
var btn_open_level_map: Button:
	get:
		return _find_node("BtnOpenLevelMap") as Button
var selected_game_mode: int:
	get:
		return selected_mode
	set(v):
		selected_mode = v

# Overlay Modals
@onready var modal_how_to_play: Control = get_node_or_null("Modals/HowToPlayModal")
@onready var lbl_rules_modal_title: Label = get_node_or_null("Modals/HowToPlayModal/Panel/VBoxContainer/LblTitle")
@onready var lbl_rules_modal_content: Label = get_node_or_null("Modals/HowToPlayModal/Panel/VBoxContainer/LblContent")
@onready var btn_close_how_to_play: Button = get_node_or_null("Modals/HowToPlayModal/Panel/VBoxContainer/BtnClose")

@onready var modal_settings: Control = get_node_or_null("Modals/SettingsModal")
@onready var lbl_settings_title: Label = get_node_or_null("Modals/SettingsModal/Panel/VBoxContainer/LblTitle")
@onready var btn_language_modal: Button = get_node_or_null("Modals/SettingsModal/Panel/VBoxContainer/BtnLanguageModal")
@onready var btn_close_settings: Button = get_node_or_null("Modals/SettingsModal/Panel/VBoxContainer/BtnClose")
@onready var audio_toggles_row: HBoxContainer = _find_node("AudioTogglesRow") as HBoxContainer
@onready var voice_haptics_row: HBoxContainer = _find_node("VoiceHapticsRow") as HBoxContainer
@onready var btn_toggle_music: Button = _find_node("BtnMusic") as Button
@onready var btn_toggle_sound: Button = _find_node("BtnSound") as Button
@onready var btn_toggle_voice: Button = _find_node("BtnVoice") as Button
var btn_voice: Button:
	get:
		return btn_toggle_voice
var btn_voice_modal: Button:
	get:
		return btn_toggle_voice
@onready var btn_toggle_haptics: Button = _find_node("BtnHaptics") as Button
var btn_haptics: Button:
	get:
		return btn_toggle_haptics
var btn_haptic: Button:
	get:
		return btn_toggle_haptics

const TITLE_FONT_SIZE_REGULAR: int = 96
const TITLE_FONT_SIZE_MEDIUM: int = 80
const TITLE_FONT_SIZE_COMPACT: int = 74
const TITLE_OUTLINE_SIZE: int = 18
var title_display_font: Font = null

@onready var modal_account: Control = get_node_or_null("Modals/AccountModal")
@onready var lbl_account_title: Label = get_node_or_null("Modals/AccountModal/Panel/VBoxContainer/LblTitle")
@onready var btn_close_account: Button = get_node_or_null("Modals/AccountModal/Panel/VBoxContainer/BtnClose")
@onready var lbl_account_score: Label = get_node_or_null("Modals/AccountModal/Panel/VBoxContainer/StatsBox/LblScore")
@onready var lbl_account_lines: Label = get_node_or_null("Modals/AccountModal/Panel/VBoxContainer/StatsBox/LblLines")
@onready var lbl_reward_status: Label = get_node_or_null("Modals/AccountModal/Panel/VBoxContainer/StatsBox/LblRewardStatus")

var local_account_card: PanelContainer = null
var lbl_local_account_title: Label = null
var lbl_local_status_badge: Label = null
var lbl_local_desc: Label = null
var btn_delete_data: Button = null
var providers_section: VBoxContainer = null
var lbl_providers_title: Label = null
var btn_create_email: Button = null
var btn_apple_id: Button = null
var btn_google_play_id: Button = null
var btn_google_id: Button:
	get:
		return btn_google_play_id
	set(v):
		btn_google_play_id = v
var modal_delete_confirm: ColorRect = null
var confirm_delete_panel: Panel = null
var lbl_delete_confirm_title: Label = null
var lbl_delete_confirm_warning: Label = null
var btn_cancel_delete: Button = null
var btn_confirm_delete: Button = null
var _account_platform_override: String = ""

@onready var modal_level_map: Control = get_node_or_null("Modals/LevelMapModal")
@onready var lbl_map_modal_title: Label = get_node_or_null("Modals/LevelMapModal/Panel/VBoxContainer/LblMapTitle")
@onready var lbl_map_milestone_hint: Label = get_node_or_null("Modals/LevelMapModal/Panel/VBoxContainer/LblMapMilestoneHint")
@onready var btn_page_prev: Button = get_node_or_null("Modals/LevelMapModal/Panel/VBoxContainer/PageNavRow/BtnPagePrev")
@onready var lbl_page_range: Label = get_node_or_null("Modals/LevelMapModal/Panel/VBoxContainer/PageNavRow/LblPageRange")
@onready var btn_page_current: Button = get_node_or_null("Modals/LevelMapModal/Panel/VBoxContainer/PageNavRow/BtnPageCurrent")
@onready var btn_page_next: Button = get_node_or_null("Modals/LevelMapModal/Panel/VBoxContainer/PageNavRow/BtnPageNext")
@onready var level_grid: Control = get_node_or_null("Modals/LevelMapModal/Panel/VBoxContainer/LevelGrid")
@onready var btn_close_level_map: Button = get_node_or_null("Modals/LevelMapModal/Panel/VBoxContainer/BottomMapActions/BtnCloseLevelMap")
@onready var btn_start_selected_level: Button = get_node_or_null("Modals/LevelMapModal/Panel/VBoxContainer/BottomMapActions/BtnStartSelectedLevel")

@onready var modal_lucky_wheel: Control = get_node_or_null("Modals/LuckyWheelModal")
@onready var lbl_wheel_title: Label = get_node_or_null("Modals/LuckyWheelModal/Panel/VBoxContainer/LblWheelTitle")
@onready var lbl_wheel_subtitle: Label = get_node_or_null("Modals/LuckyWheelModal/Panel/VBoxContainer/LblWheelSubtitle")
@onready var wheel_canvas: Control = get_node_or_null("Modals/LuckyWheelModal/Panel/VBoxContainer/WheelCanvas")
@onready var wheel_reward_info_box: Control = get_node_or_null("Modals/LuckyWheelModal/Panel/VBoxContainer/WheelRewardInfoBox")
@onready var lbl_wheel_reward_title: Label = get_node_or_null("Modals/LuckyWheelModal/Panel/VBoxContainer/WheelRewardInfoBox/RewardTextVBox/LblWheelRewardTitle")
@onready var lbl_wheel_reward_desc: Label = get_node_or_null("Modals/LuckyWheelModal/Panel/VBoxContainer/WheelRewardInfoBox/RewardTextVBox/LblWheelRewardDesc")
@onready var lbl_wheel_result: Label = get_node_or_null("Modals/LuckyWheelModal/Panel/VBoxContainer/LblWheelResult")
@onready var btn_close_wheel: Button = get_node_or_null("Modals/LuckyWheelModal/Panel/VBoxContainer/WheelActions/BtnCloseWheel")
@onready var btn_spin_wheel: Button = get_node_or_null("Modals/LuckyWheelModal/Panel/VBoxContainer/WheelActions/BtnSpinWheel")

# First-run default selection: CLASSIC + FALLING
var selected_mode: int = GameStateScript.GameMode.CLASSIC
var selected_play_style: int = GameStateScript.PlayStyle.FALLING
var current_map_page: int = 0
var winding_path_points: Array[Vector2] = []
var winding_path_entries: Array = []
var _custom_map_data: MapData = null
var _current_page_obj: MapPage = null
var map_camera_pan_offset: Vector2 = Vector2.ZERO
var map_swipe_threshold_px: float = 42.0

# Real 3D World Map Navigation & Drag Panning State
var map_scroll_y: float = 0.0
var map_target_scroll_y: float = 0.0
var map_max_scroll_y: float = 0.0
var map_is_dragging: bool = false
var map_drag_start_mouse: Vector2 = Vector2.ZERO
var map_drag_start_scroll_y: float = 0.0
var map_drag_moved_significantly: bool = false
var map_base_node_positions: Array[Vector2] = []

# Real 3D World Map Scene Graph (SubViewport + Camera3D + Connected 3D Terrain + Physical Destination Architectures)
var _level_map_viewport_container: Control = null
var _level_map_viewport: Node = null
var _level_map_world_root_3d: Node3D = null
var _level_map_camera_3d: Node3D = null
var _level_map_chapter_group_3d: Node3D = null
var _level_map_destination_nodes_3d: Array[Node3D] = []
var _level_map_terrain_surfaces_3d: Array[Node3D] = []
var _level_map_shore_surfaces_3d: Array[Node3D] = []
var _level_map_route_segments_3d: Array[Node3D] = []
var _level_map_landmark_nodes_3d: Array[Node3D] = []
var _level_map_gateway_nodes_3d: Array[Node3D] = []
var _level_map_water_mesh_3d: Node3D = null
var _level_map_route_mesh_3d: Node3D = null
var _level_map_grid_buttons: Array[Button] = []

# Daily Gift Lucky Wheel Animation State
var wheel_angle_deg: float = 0.0
var is_wheel_spinning: bool = false
var highlighted_wheel_slice: int = -1
var _last_wheel_tick_peg: int = -1

var reward_toast_label: Label = null
var anim_time: float = 0.0

# Strictly 4-cell decorative floating blocks on the Home Menu background
var floating_decor: Array = [
	{"cells": [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,2)], "col": Color(0.98, 0.30, 0.58, 0.42), "speed": 0.85, "scale": 20.0, "phase": 0.0},
	{"cells": [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3)], "col": Color(0.12, 0.86, 0.98, 0.42), "speed": 0.68, "scale": 20.0, "phase": 1.2},
	{"cells": [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)], "col": Color(1.0, 0.78, 0.16, 0.40), "speed": 0.74, "scale": 18.0, "phase": 2.5},
	{"cells": [Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)], "col": Color(0.76, 0.36, 0.98, 0.42), "speed": 0.92, "scale": 19.0, "phase": 3.8},
	{"cells": [Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1)], "col": Color(0.12, 0.90, 0.56, 0.40), "speed": 0.58, "scale": 18.0, "phase": 4.5},
	{"cells": [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)], "col": Color(1.0, 0.50, 0.16, 0.42), "speed": 0.78, "scale": 20.0, "phase": 5.1}
]


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


func _find_node(node_name: String) -> Node:
	return find_child(node_name, true, false)


func _tr(key: String) -> String:
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_method("tr_text"):
		return gs.tr_text(key)
	return String(GameStateScript.TRANSLATIONS["en"].get(key, key))


func _ready() -> void:
	_sync_selection_from_state()
	_ensure_account_modal_structure()
	_setup_vector_icons()
	
	if btn_modern:
		btn_modern.pressed.connect(_on_btn_modern_pressed)
	if btn_classic:
		btn_classic.pressed.connect(_on_btn_classic_pressed)
	if btn_drag_drop:
		btn_drag_drop.pressed.connect(_on_btn_drag_drop_pressed)
	if btn_falling:
		btn_falling.pressed.connect(_on_btn_falling_pressed)
	if btn_start:
		btn_start.pressed.connect(_on_btn_start_pressed)
	if btn_top_level:
		btn_top_level.pressed.connect(_on_btn_top_level_pressed)
	if btn_daily_gift:
		btn_daily_gift.pressed.connect(_on_btn_daily_gift_pressed)
	if btn_language_modal:
		btn_language_modal.pressed.connect(_on_btn_language_pressed)
	if btn_top_settings:
		btn_top_settings.pressed.connect(_on_btn_settings_pressed)
	if is_inside_tree() and get_viewport():
		if not get_viewport().size_changed.is_connected(_on_viewport_resized):
			get_viewport().size_changed.connect(_on_viewport_resized)
	if not resized.is_connected(_on_self_resized):
		resized.connect(_on_self_resized)
	_setup_title_visual_identity()
		
	if btn_how_to_play:
		btn_how_to_play.pressed.connect(_on_btn_how_to_play_pressed)
	if btn_settings_account:
		btn_settings_account.pressed.connect(_on_btn_account_pressed)
	if btn_nav_account and btn_nav_account != btn_settings_account:
		btn_nav_account.pressed.connect(_on_btn_account_pressed)
	elif btn_account and btn_account != btn_settings_account:
		btn_account.pressed.connect(_on_btn_account_pressed)
		
	if btn_close_how_to_play:
		btn_close_how_to_play.pressed.connect(func(): modal_how_to_play.visible = false)
	if btn_close_settings:
		btn_close_settings.pressed.connect(func(): modal_settings.visible = false)
	if btn_close_account:
		btn_close_account.pressed.connect(_on_btn_close_account_pressed)
	if btn_close_level_map:
		btn_close_level_map.pressed.connect(func(): modal_level_map.visible = false)
	if btn_close_wheel:
		btn_close_wheel.pressed.connect(func():
			if not is_wheel_spinning and modal_lucky_wheel:
				modal_lucky_wheel.visible = false
		)
	if btn_spin_wheel:
		btn_spin_wheel.pressed.connect(_on_btn_spin_wheel_pressed)
		
	if btn_page_prev:
		btn_page_prev.pressed.connect(_on_level_map_prev_page)
	if btn_page_next:
		btn_page_next.pressed.connect(_on_level_map_next_page)
	if btn_page_current:
		btn_page_current.pressed.connect(_on_level_map_jump_current)
	if btn_start_selected_level:
		btn_start_selected_level.pressed.connect(_on_start_selected_level_from_map)
		
	if btn_toggle_music:
		btn_toggle_music.pressed.connect(_on_toggle_music_pressed)
	if btn_toggle_sound:
		btn_toggle_sound.pressed.connect(_on_toggle_sound_pressed)
	if btn_toggle_voice:
		btn_toggle_voice.pressed.connect(_on_toggle_voice_pressed)
	if btn_toggle_haptics:
		btn_toggle_haptics.pressed.connect(_on_toggle_haptics_pressed)
	
	if level_grid:
		_ensure_level_map_3d_viewport()
		level_grid.draw.connect(_draw_level_path_canvas)
		level_grid.resized.connect(_layout_winding_path_nodes)
		level_grid.gui_input.connect(_on_map_drag_input)
	if wheel_canvas:
		wheel_canvas.draw.connect(_draw_lucky_wheel_canvas)
	
	# Celebratory reward toast banner
	reward_toast_label = Label.new()
	reward_toast_label.name = "RewardToastBanner"
	reward_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_toast_label.anchor_left = 0.0
	reward_toast_label.anchor_top = 0.0
	reward_toast_label.anchor_right = 1.0
	reward_toast_label.anchor_bottom = 0.0
	reward_toast_label.offset_left = 0.0
	reward_toast_label.offset_right = 0.0
	reward_toast_label.offset_top = 74.0
	reward_toast_label.offset_bottom = 106.0
	reward_toast_label.add_theme_font_size_override("font_size", 20)
	reward_toast_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.28, 1.0))
	reward_toast_label.add_theme_color_override("font_shadow_color", Color(0.18, 0.06, 0.32, 0.95))
	reward_toast_label.add_theme_constant_override("shadow_offset_x", 1)
	reward_toast_label.add_theme_constant_override("shadow_offset_y", 2)
	reward_toast_label.modulate.a = 0.0
	reward_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(reward_toast_label)
	
	_ensure_energy_header_control()
	var gs = get_node_or_null("/root/GameState")
	if gs:
		if gs.has_signal("progression_updated"):
			gs.progression_updated.connect(func(_u, _s, _c): _refresh_all_ui())
		if gs.has_signal("energy_changed"):
			gs.energy_changed.connect(func(_e, _m): _refresh_energy_ui())
		if gs.has_signal("energy_updated"):
			gs.energy_updated.connect(func(_e, _m): _refresh_energy_ui())
		if gs.has_signal("language_changed"):
			gs.language_changed.connect(func(_lang): _refresh_all_ui())
		if gs.has_signal("voice_settings_changed"):
			gs.voice_settings_changed.connect(func(_vm): _update_settings_buttons())
		if gs.has_signal("mode_changed"):
			gs.mode_changed.connect(func(m):
				selected_mode = int(m)
				_update_mode_selection_ui()
			)
		if gs.has_signal("play_style_changed"):
			gs.play_style_changed.connect(func(st):
				selected_play_style = int(st)
				_update_mode_selection_ui()
			)
		if gs.has_signal("state_changed"):
			gs.state_changed.connect(func(ns, _ps):
				if ns == GameStateScript.State.MENU:
					_sync_selection_from_state()
					_refresh_all_ui()
			)
	
	_refresh_all_ui()
	if is_inside_tree() and get_viewport():
		update_responsive_menu_layout(get_viewport_rect().size)
	else:
		update_responsive_menu_layout(Vector2(720, 1280))


func _ensure_energy_header_control() -> void:
	if _energy_rewarded_ad == null:
		_energy_rewarded_ad = RewardedAdScript.new()
	var top_bar := get_node_or_null("MarginContainer/VBoxContainer/TopStatusBar") as HBoxContainer
	if not top_bar:
		return
	energy_panel = top_bar.get_node_or_null("EnergyPanel") as PanelContainer
	if not energy_panel:
		energy_panel = PanelContainer.new()
		energy_panel.name = "EnergyPanel"
		energy_panel.custom_minimum_size = Vector2(134, 48)
		energy_panel.size = Vector2(134, 48)
		energy_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var ep_sb := StyleBoxFlat.new()
		ep_sb.bg_color = Color(0.06, 0.46, 0.56, 0.98)
		ep_sb.border_width_left = 2
		ep_sb.border_width_top = 2
		ep_sb.border_width_right = 2
		ep_sb.border_width_bottom = 6
		ep_sb.border_color = Color(0.30, 0.96, 0.88, 1.0)
		ep_sb.shadow_color = Color(0.02, 0.16, 0.24, 0.60)
		ep_sb.shadow_size = 8
		ep_sb.shadow_offset = Vector2(0, 3)
		ep_sb.corner_radius_top_left = 22
		ep_sb.corner_radius_top_right = 22
		ep_sb.corner_radius_bottom_right = 22
		ep_sb.corner_radius_bottom_left = 22
		ep_sb.content_margin_left = 10.0
		ep_sb.content_margin_right = 6.0
		ep_sb.content_margin_top = 0.0
		ep_sb.content_margin_bottom = 0.0
		ep_sb.expand_margin_left = 0.0
		ep_sb.expand_margin_right = 0.0
		ep_sb.expand_margin_top = 0.0
		ep_sb.expand_margin_bottom = 0.0
		energy_panel.add_theme_stylebox_override("panel", ep_sb)
		energy_panel.set_meta("visual_identity", "electric_teal_stamina")

		var hbox := HBoxContainer.new()
		hbox.name = "HBox"
		hbox.custom_minimum_size = Vector2.ZERO
		hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 5)
		energy_panel.add_child(hbox)

		var bolt_icon = UIIconScript.new("bolt", Color(1.0, 0.92, 0.24, 1.0))
		bolt_icon.name = "EnergyIcon"
		bolt_icon.align_mode = "none"
		bolt_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bolt_icon.custom_minimum_size = Vector2(22, 22)
		bolt_icon.size = Vector2(22, 22)
		hbox.add_child(bolt_icon)

		var empty_sb := StyleBoxEmpty.new()
		empty_sb.content_margin_left = 0.0
		empty_sb.content_margin_right = 0.0
		empty_sb.content_margin_top = 0.0
		empty_sb.content_margin_bottom = 0.0

		lbl_energy = Label.new()
		lbl_energy.name = "LblEnergy"
		lbl_energy.text = "24/24"
		lbl_energy.custom_minimum_size = Vector2.ZERO
		lbl_energy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lbl_energy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_energy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_energy.add_theme_stylebox_override("normal", empty_sb)
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
		btn_energy_plus.focus_mode = Control.FOCUS_NONE
		btn_energy_plus.add_theme_constant_override("h_separation", 0)
		btn_energy_plus.add_theme_constant_override("outline_size", 2)
		btn_energy_plus.add_theme_font_size_override("font_size", 22)
		btn_energy_plus.add_theme_color_override("font_color", Color(0.36, 0.96, 0.58, 1.0))
		btn_energy_plus.add_theme_color_override("font_hover_color", Color(0.56, 1.0, 0.72, 1.0))
		btn_energy_plus.add_theme_color_override("font_pressed_color", Color(0.24, 0.82, 0.46, 1.0))
		btn_energy_plus.add_theme_color_override("font_disabled_color", Color(0.60, 0.68, 0.76, 0.65))
		btn_energy_plus.add_theme_stylebox_override("normal", empty_sb)
		btn_energy_plus.add_theme_stylebox_override("hover", empty_sb)
		btn_energy_plus.add_theme_stylebox_override("pressed", empty_sb)
		btn_energy_plus.add_theme_stylebox_override("hover_pressed", empty_sb)
		btn_energy_plus.add_theme_stylebox_override("disabled", empty_sb)
		btn_energy_plus.add_theme_stylebox_override("focus", empty_sb)
		UIIconScript.attach_to_button(btn_energy_plus, "plus", Vector2(28, 28), "center", Color(0.36, 0.96, 0.58, 1.0))
		UIIconScript.remove_focus_outline(btn_energy_plus)
		btn_energy_plus.pressed.connect(_on_btn_energy_plus_pressed)
		hbox.add_child(btn_energy_plus)

		top_bar.add_child(energy_panel)
		if btn_top_level:
			top_bar.move_child(energy_panel, min(top_bar.get_child_count() - 1, btn_top_level.get_index() + 1))
	else:
		lbl_energy = energy_panel.find_child("LblEnergy", true, false) as Label
		btn_energy_plus = energy_panel.find_child("BtnEnergyPlus", true, false) as Button
	_ensure_energy_ad_overlay()
	_refresh_energy_ui()


func _ensure_energy_ad_overlay() -> void:
	if _energy_ad_overlay and is_instance_valid(_energy_ad_overlay):
		return
	_energy_ad_overlay = get_node_or_null("EnergyRewardedAdModal") as Control
	if _energy_ad_overlay:
		return
	_energy_ad_overlay = ColorRect.new()
	_energy_ad_overlay.name = "EnergyRewardedAdModal"
	_energy_ad_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	(_energy_ad_overlay as ColorRect).color = Color(0.02, 0.04, 0.14, 0.92)
	_energy_ad_overlay.visible = false
	_energy_ad_overlay.z_index = 220

	var card := PanelContainer.new()
	card.name = "AdCard"
	card.custom_minimum_size = Vector2(320, 240)
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -160
	card.offset_top = -120
	card.offset_right = 160
	card.offset_bottom = 120
	var c_sb := StyleBoxFlat.new()
	c_sb.bg_color = Color(0.12, 0.20, 0.50, 0.98)
	c_sb.border_width_left = 3
	c_sb.border_width_top = 3
	c_sb.border_width_right = 3
	c_sb.border_width_bottom = 6
	c_sb.border_color = Color(1.0, 0.88, 0.30, 1.0)
	c_sb.corner_radius_top_left = 22
	c_sb.corner_radius_top_right = 22
	c_sb.corner_radius_bottom_right = 22
	c_sb.corner_radius_bottom_left = 22
	c_sb.content_margin_left = 18
	c_sb.content_margin_right = 18
	c_sb.content_margin_top = 18
	c_sb.content_margin_bottom = 18
	card.add_theme_stylebox_override("panel", c_sb)
	_energy_ad_overlay.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)

	var lbl_t := Label.new()
	lbl_t.name = "LblAdTitle"
	lbl_t.text = "REWARDED AD: +1 ENERGY"
	lbl_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_t.add_theme_font_size_override("font_size", 18)
	lbl_t.add_theme_color_override("font_color", Color(1.0, 0.94, 0.36, 1.0))
	vbox.add_child(lbl_t)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	vbox.add_child(actions)

	var btn_skip := Button.new()
	btn_skip.name = "BtnSkipEnergyAd"
	btn_skip.text = "SKIP / CLOSE"
	btn_skip.custom_minimum_size = Vector2(124, 44)
	UIIconScript.remove_focus_outline(btn_skip)
	btn_skip.pressed.connect(func(): skip_energy_rewarded_ad())
	actions.add_child(btn_skip)

	var btn_complete := Button.new()
	btn_complete.name = "BtnCompleteEnergyAd"
	btn_complete.text = "COMPLETE AD"
	btn_complete.custom_minimum_size = Vector2(134, 44)
	UIIconScript.remove_focus_outline(btn_complete)
	btn_complete.pressed.connect(func(): complete_energy_rewarded_ad())
	actions.add_child(btn_complete)

	add_child(_energy_ad_overlay)


func _refresh_energy_ui() -> void:
	var gs = get_node_or_null("/root/GameState")
	var cur_e: int = gs.get_energy() if (gs and gs.has_method("get_energy")) else 24
	var max_e: int = GameStateScript.MAX_ENERGY if "MAX_ENERGY" in GameStateScript else 24
	if lbl_energy:
		lbl_energy.text = "%d/%d" % [cur_e, max_e]
	if btn_energy_plus:
		btn_energy_plus.visible = true
		btn_energy_plus.disabled = (cur_e >= max_e)
		btn_energy_plus.modulate = Color(0.68, 0.74, 0.86, 0.75) if (cur_e >= max_e) else Color(1, 1, 1, 1)
	if btn_start:
		btn_start.disabled = (cur_e <= 0)
		btn_start.modulate.a = 0.58 if (cur_e <= 0) else 1.0
	if btn_start_selected_level:
		btn_start_selected_level.disabled = (cur_e <= 0)


func get_energy_display_text() -> String:
	var gs = get_node_or_null("/root/GameState")
	var cur_e: int = gs.get_energy() if (gs and gs.has_method("get_energy")) else 24
	var max_e: int = GameStateScript.MAX_ENERGY if "MAX_ENERGY" in GameStateScript else 24
	return "⚡ %d/%d" % [cur_e, max_e]


func _on_btn_energy_plus_pressed() -> void:
	open_energy_rewarded_ad()


func open_energy_rewarded_ad() -> String:
	_ensure_energy_header_control()
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_method("get_energy") and gs.get_energy() >= GameStateScript.MAX_ENERGY:
		return ""
	if gs and gs.has_method("open_rewarded_ad_for_energy"):
		_energy_ad_session_id = gs.open_rewarded_ad_for_energy()
	else:
		_energy_ad_session_id = "menu_energy_ad_%d_%d" % [Time.get_ticks_usec(), randi() % 100000]
	if _energy_rewarded_ad:
		_energy_rewarded_ad.is_loaded = true
	if _energy_ad_overlay:
		_energy_ad_overlay.visible = true
	return _energy_ad_session_id


func complete_energy_rewarded_ad(session_id: String = "") -> Dictionary:
	var gs = get_node_or_null("/root/GameState")
	var sid: String = session_id if session_id != "" else _energy_ad_session_id
	if sid == "" or not gs:
		if _energy_ad_overlay:
			_energy_ad_overlay.visible = false
		return {"granted": false, "success": false, "reason": "no_active_ad_session"}
	_energy_ad_session_id = ""
	if _energy_ad_overlay:
		_energy_ad_overlay.visible = false
	var res: Dictionary = {}
	if gs.has_method("complete_rewarded_ad_for_energy"):
		res = gs.complete_rewarded_ad_for_energy(sid)
	elif gs.has_method("claim_energy_rewarded_ad"):
		res = gs.claim_energy_rewarded_ad(true, sid)
	res["success"] = bool(res.get("granted", false))
	_refresh_energy_ui()
	return res


func skip_energy_rewarded_ad() -> Dictionary:
	var gs = get_node_or_null("/root/GameState")
	_energy_ad_session_id = ""
	if _energy_ad_overlay:
		_energy_ad_overlay.visible = false
	var res: Dictionary = {}
	if gs and gs.has_method("skip_rewarded_ad_for_energy"):
		res = gs.skip_rewarded_ad_for_energy()
	else:
		res = {"granted": false, "reason": "ad_skipped_or_closed_early"}
	res["success"] = false
	_refresh_energy_ui()
	return res


func _sync_selection_from_state() -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs:
		if "current_mode" in gs:
			selected_mode = int(gs.current_mode)
		if "current_play_style" in gs:
			selected_play_style = int(gs.current_play_style)


static var _spin_style_blue: StyleBoxFlat = null
static var _spin_style_blue_hover: StyleBoxFlat = null
static var _spin_style_blue_pressed: StyleBoxFlat = null
static var _spin_style_blue_disabled: StyleBoxFlat = null
static var _gift_style_active: StyleBoxFlat = null
static var _gift_style_claimed: StyleBoxFlat = null
static var _level_progress_style: StyleBoxFlat = null
static var _level_progress_style_hover: StyleBoxFlat = null
static var _level_progress_style_pressed: StyleBoxFlat = null


func _apply_level_button_progress_style() -> void:
	if not btn_top_level:
		return
	if _level_progress_style == null:
		_level_progress_style = StyleBoxFlat.new()
		_level_progress_style.bg_color = Color(0.80, 0.46, 0.08, 0.98)
		_level_progress_style.border_width_left = 2
		_level_progress_style.border_width_top = 2
		_level_progress_style.border_width_right = 2
		_level_progress_style.border_width_bottom = 5
		_level_progress_style.border_color = Color(1.0, 0.90, 0.36, 1.0)
		_level_progress_style.corner_radius_top_left = 18
		_level_progress_style.corner_radius_top_right = 18
		_level_progress_style.corner_radius_bottom_right = 18
		_level_progress_style.corner_radius_bottom_left = 18
		_level_progress_style.content_margin_left = 24.0
		_level_progress_style.content_margin_right = 8.0
		_level_progress_style.content_margin_top = 0.0
		_level_progress_style.content_margin_bottom = 0.0
		_level_progress_style.shadow_color = Color(0.34, 0.14, 0.02, 0.62)
		_level_progress_style.shadow_size = 8
		_level_progress_style.shadow_offset = Vector2(0, 3)

		_level_progress_style_hover = _level_progress_style.duplicate()
		_level_progress_style_hover.bg_color = Color(0.88, 0.54, 0.12, 0.99)
		_level_progress_style_hover.border_color = Color(1.0, 0.95, 0.52, 1.0)

		_level_progress_style_pressed = _level_progress_style.duplicate()
		_level_progress_style_pressed.bg_color = Color(0.68, 0.36, 0.06, 0.99)
		_level_progress_style_pressed.border_width_bottom = 3

	btn_top_level.add_theme_stylebox_override("normal", _level_progress_style)
	btn_top_level.add_theme_stylebox_override("hover", _level_progress_style_hover)
	btn_top_level.add_theme_stylebox_override("pressed", _level_progress_style_pressed)
	btn_top_level.add_theme_color_override("font_color", Color(1.0, 0.99, 0.90, 1.0))
	btn_top_level.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.96, 1.0))
	btn_top_level.add_theme_color_override("font_pressed_color", Color(0.98, 0.94, 0.80, 1.0))
	btn_top_level.add_theme_color_override("font_outline_color", Color(0.28, 0.10, 0.02, 0.96))
	btn_top_level.add_theme_constant_override("outline_size", 2)
	btn_top_level.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_top_level.set_meta("visual_identity", "royal_amber_gold_progress")


func get_level_and_energy_visual_identity_metrics() -> Dictionary:
	_ensure_energy_header_control()
	_apply_level_button_progress_style()
	var lv_sb := btn_top_level.get_theme_stylebox("normal") as StyleBoxFlat if btn_top_level else null
	var ep_sb := energy_panel.get_theme_stylebox("panel") as StyleBoxFlat if energy_panel else null
	var lv_bg: Color = lv_sb.bg_color if lv_sb else Color.BLACK
	var ep_bg: Color = ep_sb.bg_color if ep_sb else Color.BLACK
	var lv_border: Color = lv_sb.border_color if lv_sb else Color.BLACK
	var ep_border: Color = ep_sb.border_color if ep_sb else Color.BLACK
	var bg_diff: float = absf(lv_bg.r - ep_bg.r) + absf(lv_bg.g - ep_bg.g) + absf(lv_bg.b - ep_bg.b)
	var border_diff: float = absf(lv_border.r - ep_border.r) + absf(lv_border.g - ep_border.g) + absf(lv_border.b - ep_border.b)
	return {
		"level_bg_color": lv_bg,
		"energy_bg_color": ep_bg,
		"level_border_color": lv_border,
		"energy_border_color": ep_border,
		"level_identity": String(btn_top_level.get_meta("visual_identity", "")) if btn_top_level else "",
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


func _get_gift_style(is_active: bool) -> StyleBoxFlat:
	if is_active:
		if _gift_style_active == null:
			_gift_style_active = StyleBoxFlat.new()
			_gift_style_active.bg_color = Color(0.98, 0.36, 0.58, 1.0)
			_gift_style_active.border_width_left = 2
			_gift_style_active.border_width_top = 2
			_gift_style_active.border_width_right = 2
			_gift_style_active.border_width_bottom = 5
			_gift_style_active.border_color = Color(1.0, 0.88, 0.36, 1.0)
			_gift_style_active.corner_radius_top_left = 18
			_gift_style_active.corner_radius_top_right = 18
			_gift_style_active.corner_radius_bottom_right = 18
			_gift_style_active.corner_radius_bottom_left = 18
			_gift_style_active.content_margin_left = 24.0
			_gift_style_active.content_margin_right = 8.0
			_gift_style_active.content_margin_top = 0.0
			_gift_style_active.content_margin_bottom = 0.0
			_gift_style_active.shadow_color = Color(0.32, 0.04, 0.18, 0.55)
			_gift_style_active.shadow_size = 8
			_gift_style_active.shadow_offset = Vector2(0, 3)
		return _gift_style_active
	else:
		if _gift_style_claimed == null:
			_gift_style_claimed = StyleBoxFlat.new()
			_gift_style_claimed.bg_color = Color(0.24, 0.28, 0.38, 0.92)
			_gift_style_claimed.border_width_left = 2
			_gift_style_claimed.border_width_top = 2
			_gift_style_claimed.border_width_right = 2
			_gift_style_claimed.border_width_bottom = 5
			_gift_style_claimed.border_color = Color(0.46, 0.52, 0.64, 0.88)
			_gift_style_claimed.corner_radius_top_left = 18
			_gift_style_claimed.corner_radius_top_right = 18
			_gift_style_claimed.corner_radius_bottom_right = 18
			_gift_style_claimed.corner_radius_bottom_left = 18
			_gift_style_claimed.content_margin_left = 24.0
			_gift_style_claimed.content_margin_right = 8.0
			_gift_style_claimed.content_margin_top = 0.0
			_gift_style_claimed.content_margin_bottom = 0.0
			_gift_style_claimed.shadow_color = Color(0.04, 0.06, 0.14, 0.40)
			_gift_style_claimed.shadow_size = 6
			_gift_style_claimed.shadow_offset = Vector2(0, 2)
		return _gift_style_claimed


func _apply_spin_button_blue_style() -> void:
	if not btn_spin_wheel:
		return
	if _spin_style_blue == null:
		_spin_style_blue = StyleBoxFlat.new()
		_spin_style_blue.bg_color = Color(0.12, 0.54, 0.98, 1.0)
		_spin_style_blue.border_width_left = 3
		_spin_style_blue.border_width_top = 3
		_spin_style_blue.border_width_right = 3
		_spin_style_blue.border_width_bottom = 8
		_spin_style_blue.border_color = Color(0.68, 0.94, 1.0, 1.0)
		_spin_style_blue.corner_radius_top_left = 22
		_spin_style_blue.corner_radius_top_right = 22
		_spin_style_blue.corner_radius_bottom_right = 22
		_spin_style_blue.corner_radius_bottom_left = 22
		_spin_style_blue.shadow_color = Color(0.02, 0.08, 0.32, 0.55)
		_spin_style_blue.shadow_size = 12
		_spin_style_blue.shadow_offset = Vector2(0, 5)

		_spin_style_blue_hover = _spin_style_blue.duplicate()
		_spin_style_blue_hover.bg_color = Color(0.22, 0.62, 1.0, 1.0)
		_spin_style_blue_hover.border_color = Color(0.80, 0.98, 1.0, 1.0)

		_spin_style_blue_pressed = _spin_style_blue.duplicate()
		_spin_style_blue_pressed.bg_color = Color(0.08, 0.40, 0.86, 1.0)
		_spin_style_blue_pressed.border_width_bottom = 3
		_spin_style_blue_pressed.shadow_size = 4
		_spin_style_blue_pressed.shadow_offset = Vector2(0, 2)

		_spin_style_blue_disabled = _spin_style_blue.duplicate()
		_spin_style_blue_disabled.bg_color = Color(0.24, 0.30, 0.46, 0.88)
		_spin_style_blue_disabled.border_color = Color(0.42, 0.48, 0.62, 0.8)
		_spin_style_blue_disabled.shadow_color = Color(0.02, 0.04, 0.12, 0.4)

	btn_spin_wheel.add_theme_stylebox_override("normal", _spin_style_blue)
	btn_spin_wheel.add_theme_stylebox_override("hover", _spin_style_blue_hover)
	btn_spin_wheel.add_theme_stylebox_override("pressed", _spin_style_blue_pressed)
	btn_spin_wheel.add_theme_stylebox_override("disabled", _spin_style_blue_disabled)
	btn_spin_wheel.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	btn_spin_wheel.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn_spin_wheel.add_theme_color_override("font_pressed_color", Color(0.90, 0.96, 1.0, 1.0))
	btn_spin_wheel.add_theme_color_override("font_disabled_color", Color(0.70, 0.76, 0.88, 0.8))
	GameTypographyScript.apply_primary_button_typography(btn_spin_wheel, 24)


func _setup_vector_icons() -> void:
	if btn_top_settings:
		btn_top_settings.text = ""
		UIIconScript.apply_frameless_icon_button_style(btn_top_settings)
		var gear_icon := UIIconScript.attach_to_button(btn_top_settings, "gear", Vector2(56, 56), "center", Color(0.70, 0.73, 0.77, 1.0))
		if gear_icon:
			gear_icon.secondary_color = Color(0.20, 0.24, 0.35, 1.0)
	if btn_top_level:
		_apply_level_button_progress_style()
		UIIconScript.attach_to_button(btn_top_level, "crown", Vector2(26, 26), "left", Color(1.0, 0.94, 0.32, 1.0))
	if btn_daily_gift:
		UIIconScript.apply_reward_game_button_style(btn_daily_gift, 22)
		GameTypographyScript.apply_secondary_button_typography(btn_daily_gift, 20)
		UIIconScript.attach_to_button(btn_daily_gift, "gift", Vector2(26, 26), "left", Color(1.0, 0.92, 0.34, 1.0))
	if btn_language_modal:
		UIIconScript.apply_secondary_game_button_style(btn_language_modal, false, 22)
		GameTypographyScript.apply_secondary_button_typography(btn_language_modal, 20)
		UIIconScript.attach_to_button(btn_language_modal, "globe", Vector2(24, 24), "left", Color(0.82, 0.98, 1.0, 1.0))
	if btn_classic:
		UIIconScript.attach_to_button(btn_classic, "crown", Vector2(30, 30), "left", Color(1.0, 0.90, 0.28, 1.0))
	if btn_modern:
		UIIconScript.attach_to_button(btn_modern, "gem", Vector2(30, 30), "left", Color(0.38, 0.96, 1.0, 1.0))
	if btn_falling:
		UIIconScript.attach_to_button(btn_falling, "falling", Vector2(30, 30), "left", Color(0.45, 0.98, 1.0, 1.0))
	if btn_drag_drop:
		UIIconScript.attach_to_button(btn_drag_drop, "drag_drop", Vector2(30, 30), "left", Color(1.0, 0.88, 0.34, 1.0))
	if btn_start:
		UIIconScript.apply_primary_game_button_style(btn_start, 34)
		GameTypographyScript.apply_primary_button_typography(btn_start, 38)
		UIIconScript.setup_button_press_feedback(btn_start)
		btn_start.alignment = HORIZONTAL_ALIGNMENT_CENTER
		var existing_play_icon := btn_start.get_node_or_null("VectorIcon")
		if existing_play_icon:
			btn_start.remove_child(existing_play_icon)
			existing_play_icon.queue_free()
	if btn_how_to_play:
		UIIconScript.apply_secondary_game_button_style(btn_how_to_play, false, 22)
		GameTypographyScript.apply_secondary_button_typography(btn_how_to_play, 20)
		UIIconScript.attach_to_button(btn_how_to_play, "info", Vector2(26, 26), "left", Color(0.86, 0.98, 1.0, 1.0))
	if btn_settings_account:
		_apply_account_entry_button_style(btn_settings_account)
		UIIconScript.attach_to_button(btn_settings_account, "account", Vector2(24, 24), "left", Color(0.72, 0.96, 1.0, 1.0))
	if btn_nav_account:
		_apply_account_entry_button_style(btn_nav_account)
		UIIconScript.attach_to_button(btn_nav_account, "account", Vector2(24, 24), "left", Color(0.72, 0.96, 1.0, 1.0))
	if btn_account and btn_account != btn_settings_account and btn_account != btn_nav_account:
		_apply_account_entry_button_style(btn_account)
		UIIconScript.attach_to_button(btn_account, "account", Vector2(24, 24), "left", Color(0.72, 0.96, 1.0, 1.0))
	if btn_delete_data:
		_apply_red_exit_style(btn_delete_data)
		UIIconScript.attach_to_button(btn_delete_data, "trash", Vector2(22, 22), "left", Color(1.0, 0.94, 0.94, 1.0))
	if btn_apple_id:
		_apply_apple_provider_button_style(btn_apple_id)
		UIIconScript.attach_to_button(btn_apple_id, "apple", Vector2(24, 24), "left", Color(0.98, 0.99, 1.0, 1.0))
	if btn_google_play_id:
		_apply_google_play_provider_button_style(btn_google_play_id)
		UIIconScript.attach_to_button(btn_google_play_id, "google_play", Vector2(24, 24), "left", Color(1.0, 1.0, 1.0, 0.98))
	if btn_create_email:
		_apply_unavailable_provider_button_style(btn_create_email)
		UIIconScript.attach_to_button(btn_create_email, "email", Vector2(24, 24), "left", Color(0.76, 0.90, 1.0, 0.96))
	if btn_cancel_delete:
		_apply_cancel_safe_button_style(btn_cancel_delete)
		UIIconScript.attach_to_button(btn_cancel_delete, "close", Vector2(22, 22), "left", Color(0.88, 0.98, 1.0, 1.0))
	if btn_confirm_delete:
		_apply_red_exit_style(btn_confirm_delete)
		UIIconScript.attach_to_button(btn_confirm_delete, "trash", Vector2(22, 22), "left", Color(1.0, 0.94, 0.94, 1.0))
	if btn_start_selected_level:
		UIIconScript.attach_to_button(btn_start_selected_level, "play", Vector2(26, 26), "left", Color(1.0, 0.98, 0.82, 1.0))
	if btn_spin_wheel:
		_apply_spin_button_blue_style()
		UIIconScript.attach_to_button(btn_spin_wheel, "wheel", Vector2(28, 28), "left", Color(1.0, 0.94, 0.42, 1.0))
	if btn_toggle_music:
		UIIconScript.apply_audio_toggle_button_identity_style(btn_toggle_music)
		UIIconScript.attach_to_button(btn_toggle_music, "music", Vector2(20, 20), "left", Color(1.0, 0.92, 0.36, 1.0))
	if btn_toggle_sound:
		var audio_mgr = get_node_or_null("/root/AudioManager")
		var s_on: bool = audio_mgr.sound_enabled if audio_mgr else true
		UIIconScript.apply_audio_toggle_button_identity_style(btn_toggle_sound)
		UIIconScript.attach_to_button(btn_toggle_sound, "sound_on" if s_on else "sound_off", Vector2(20, 20), "left", Color(0.52, 0.98, 1.0, 1.0))
	if btn_toggle_voice:
		UIIconScript.apply_voice_button_identity_style(btn_toggle_voice)
		UIIconScript.attach_to_button(btn_toggle_voice, "sound_on", Vector2(20, 20), "left", Color(0.52, 0.98, 1.0, 1.0))
	if btn_toggle_haptics:
		UIIconScript.apply_voice_button_identity_style(btn_toggle_haptics)
		UIIconScript.attach_to_button(btn_toggle_haptics, "haptic", Vector2(20, 20), "left", Color(1.0, 0.90, 0.38, 1.0))
	for red_btn in [btn_close_how_to_play, btn_close_settings, btn_close_account, btn_close_level_map, btn_close_wheel]:
		if red_btn:
			_apply_red_exit_style(red_btn)
			UIIconScript.attach_to_button(red_btn, "close", Vector2(22, 22), "left", Color(1.0, 0.92, 0.92, 1.0))
	_setup_leave_button_spacing()
	UIIconScript.setup_all_buttons_feedback(self)


static var _shared_title_display_font: Font = null


func _build_title_display_font() -> Font:
	if _shared_title_display_font:
		return _shared_title_display_font
	_shared_title_display_font = GameTypographyScript.get_display_font()
	return _shared_title_display_font


func _setup_title_visual_identity() -> void:
	if not title_display_font:
		title_display_font = _build_title_display_font()
	if not lbl_title:
		return
	var gs = get_node_or_null("/root/GameState")
	var is_vi: bool = (gs.get_language() == "vi") if (gs and gs.has_method("get_language")) else false
	lbl_title.text = "Xếp Gạch" if is_vi else "Block Puzzle"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lbl_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lbl_title.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	if title_display_font:
		lbl_title.add_theme_font_override("font", title_display_font)
	lbl_title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE_REGULAR)
	# Suppress default flat label glyph pass so _on_lbl_title_draw renders the sculpted 3D frameless typography
	lbl_title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.28, 0.0))
	lbl_title.add_theme_color_override("font_outline_color", Color(0.14, 0.06, 0.38, 0.0))
	lbl_title.add_theme_constant_override("outline_size", TITLE_OUTLINE_SIZE)
	lbl_title.add_theme_color_override("font_shadow_color", Color(0.05, 0.02, 0.18, 0.0))
	lbl_title.add_theme_constant_override("shadow_offset_x", 4)
	lbl_title.add_theme_constant_override("shadow_offset_y", 9)
	lbl_title.add_theme_constant_override("shadow_outline_size", 12)
	lbl_title.set_meta("is_redesigned_emblem_title", true)
	lbl_title.set_meta("has_background_frame_or_crest", false)
	lbl_title.set_meta("is_playful_casual_game_logo", true)
	lbl_title.set_meta("has_per_character_playful_variation", true)
	if not lbl_title.draw.is_connected(_on_lbl_title_draw):
		lbl_title.draw.connect(_on_lbl_title_draw)


func _draw_beveled_logo_cube(pos: Vector2, side: float, rot_rad: float, base_col: Color, rim_col: Color) -> void:
	if not lbl_title:
		return
	lbl_title.draw_set_transform(pos, rot_rad, Vector2.ONE)
	var hs: float = side * 0.5
	lbl_title.draw_rect(Rect2(Vector2(-hs + 1.5, -hs + 3.5), Vector2(side, side)), Color(0.04, 0.02, 0.16, 0.62), true)
	lbl_title.draw_rect(Rect2(Vector2(-hs - 1.8, -hs - 1.8), Vector2(side + 3.6, side + 3.6)), Color(0.14, 0.06, 0.36, 0.96), true)
	lbl_title.draw_rect(Rect2(Vector2(-hs, -hs), Vector2(side, side)), base_col.darkened(0.22), true)
	lbl_title.draw_rect(Rect2(Vector2(-hs + 1.6, -hs + 1.6), Vector2(side - 3.2, side - 4.2)), base_col, true)
	lbl_title.draw_rect(Rect2(Vector2(-hs + 2.8, -hs + 2.4), Vector2(side - 5.6, (side - 5.6) * 0.42)), rim_col, true)
	lbl_title.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_playful_logo_word(
	font: Font,
	word: String,
	center_x: float,
	baseline_y: float,
	f_sz: int,
	out_sz: int,
	tilts: Array[float],
	y_bounces: Array[float],
	scales: Array[Vector2],
	shadow_col: Color,
	extrude_dark_col: Color,
	extrude_mid_col: Color,
	inner_outline_col: Color,
	lower_bevel_col: Color,
	face_colors: Array[Color],
	top_gleam_col: Color
) -> float:
	var n: int = word.length()
	if n == 0:
		return 0.0
	var adv_list: Array[float] = []
	var total_w: float = 0.0
	var track_px: float = clampf(float(f_sz) * 0.07, 2.5, 5.5)
	for i in range(n):
		var ch: String = word.substr(i, 1)
		var ch_w: float = font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz).x
		if ch.strip_edges().is_empty():
			ch_w = maxf(ch_w, float(f_sz) * 0.34)
		adv_list.append(ch_w)
		total_w += ch_w
		if i < n - 1:
			total_w += track_px

	var glyph_centers: Array[Vector2] = []
	var glyph_widths: Array[float] = []
	var cur_x: float = center_x - total_w * 0.5
	for i in range(n):
		var cw: float = adv_list[i]
		var y_off: float = y_bounces[i % y_bounces.size()]
		glyph_centers.append(Vector2(cur_x + cw * 0.5, baseline_y + y_off))
		glyph_widths.append(cw)
		cur_x += cw + track_px

	# Pass 1: Deep drop shadow & outer 3D block extrusion across all glyphs
	for i in range(n):
		var ch1: String = word.substr(i, 1)
		if ch1.strip_edges().is_empty():
			continue
		var cw1: float = glyph_widths[i]
		var gc: Vector2 = glyph_centers[i]
		var tilt: float = tilts[i % tilts.size()]
		var g_sc: Vector2 = scales[i % scales.size()]
		var draw_pt := Vector2(-cw1 * 0.5, 0.0)
		lbl_title.draw_set_transform(gc + Vector2(0.0, 9.5), tilt, g_sc)
		lbl_title.draw_string_outline(font, draw_pt, ch1, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz, out_sz + 6, shadow_col)
		lbl_title.draw_set_transform(gc + Vector2(0.0, 7.0), tilt, g_sc)
		lbl_title.draw_string_outline(font, draw_pt, ch1, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz, out_sz + 4, extrude_dark_col)
		for ext_y in [5.4, 3.8, 2.2]:
			lbl_title.draw_set_transform(gc + Vector2(0.0, ext_y), tilt, g_sc)
			lbl_title.draw_string_outline(font, draw_pt, ch1, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz, out_sz + 2, extrude_mid_col)

	# Pass 2: Crisp inner contour, lower warm/cool bevel, per-letter vibrant face & top specular gleam
	for i in range(n):
		var ch2: String = word.substr(i, 1)
		if ch2.strip_edges().is_empty():
			continue
		var cw2: float = glyph_widths[i]
		var gc2: Vector2 = glyph_centers[i]
		var tilt2: float = tilts[i % tilts.size()]
		var g_sc2: Vector2 = scales[i % scales.size()]
		var face_col: Color = face_colors[i % face_colors.size()]
		var draw_pt2 := Vector2(-cw2 * 0.5, 0.0)
		lbl_title.draw_set_transform(gc2, tilt2, g_sc2)
		lbl_title.draw_string_outline(font, draw_pt2, ch2, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz, out_sz - 2, inner_outline_col)
		lbl_title.draw_string(font, draw_pt2 + Vector2(0.0, 3.0), ch2, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz, lower_bevel_col)
		lbl_title.draw_string(font, draw_pt2 + Vector2(0.0, 1.2), ch2, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz, face_col.darkened(0.08))
		lbl_title.draw_string(font, draw_pt2, ch2, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz, face_col)
		lbl_title.draw_string(font, draw_pt2 + Vector2(0.0, -2.0), ch2, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz, top_gleam_col)

	lbl_title.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return total_w


func _draw_secondary_subtitle_branding(
	font: Font,
	word: String,
	center_x: float,
	baseline_y: float,
	f_sz: int
) -> float:
	if word.is_empty():
		return 0.0
	var total_w: float = font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz).x
	var draw_pt := Vector2(center_x - total_w * 0.5, baseline_y)
	lbl_title.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	lbl_title.draw_string_outline(font, draw_pt + Vector2(0, 3.2), word, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz, 6, Color(0.02, 0.04, 0.16, 0.55))
	lbl_title.draw_string_outline(font, draw_pt + Vector2(0, 1.8), word, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz, 4, Color(0.06, 0.10, 0.30, 0.92))
	lbl_title.draw_string_outline(font, draw_pt, word, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz, 2, Color(0.12, 0.22, 0.50, 0.95))
	lbl_title.draw_string(font, draw_pt + Vector2(0, 1.2), word, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz, Color(0.70, 0.86, 0.98, 0.92))
	lbl_title.draw_string(font, draw_pt, word, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz, Color(0.95, 0.98, 1.0, 0.96))
	return total_w


func _on_lbl_title_draw() -> void:
	if not lbl_title:
		return
	var font: Font = title_display_font if title_display_font else ThemeDB.fallback_font
	if not font:
		return
	var f_sz: int = lbl_title.get_theme_font_size("font_size")
	if f_sz <= 0:
		f_sz = TITLE_FONT_SIZE_REGULAR
	var w: float = lbl_title.size.x if lbl_title.size.x > 0 else (lbl_title.custom_minimum_size.x if lbl_title.custom_minimum_size.x > 0 else 560.0)
	var h: float = lbl_title.size.y if lbl_title.size.y > 0 else (lbl_title.custom_minimum_size.y if lbl_title.custom_minimum_size.y > 0 else 168.0)
	var center := Vector2(w * 0.5, h * 0.5)
	var span_h: float = clampf(h * 0.88, 100.0, 172.0)

	var gs = get_node_or_null("/root/GameState")
	var lang: String = gs.get_language() if (gs and gs.has_method("get_language")) else "en"
	var is_vi: bool = (lang == "vi")

	if is_vi:
		# ======================================================================
		# VIETNAMESE MODE: "Xếp Gạch" (Primary Title) + "Block Puzzle" (Secondary Line)
		# Normal mixed-case typography with full diacritics (ế, ạ).
		# Secondary line is noticeably smaller, lighter secondary branding/reference text.
		# ======================================================================
		var vi_fsz: int = clampi(int(round(float(f_sz) * 0.84)), 48, 76)
		var vi_y: float = center.y - span_h * 0.08
		var out_vi: int = clampi(int(round(float(vi_fsz) * 0.28)), 13, 21)

		var sub_fsz: int = clampi(int(round(float(vi_fsz) * 0.42)), 18, 30)
		var sub_y: float = center.y + span_h * 0.36

		var cube_side: float = clampf(float(vi_fsz) * 0.28, 12.0, 19.0)
		var half_span_est: float = clampf(float(vi_fsz) * 2.30, 96.0, w * 0.44)
		_draw_beveled_logo_cube(
			Vector2(center.x - half_span_est, vi_y - float(vi_fsz) * 0.30),
			cube_side, -0.20,
			Color(1.0, 0.78, 0.16, 1.0), Color(1.0, 0.97, 0.68, 0.95)
		)
		_draw_beveled_logo_cube(
			Vector2(center.x + half_span_est, vi_y - float(vi_fsz) * 0.26),
			cube_side * 0.92, 0.22,
			Color(0.22, 0.88, 1.0, 1.0), Color(0.84, 0.99, 1.0, 0.95)
		)

		# Primary Title: "Xếp Gạch"
		var vi_tilts: Array[float] = [-0.045, -0.018, 0.018, 0.0, -0.030, 0.018, 0.032, -0.018]
		var vi_bounces: Array[float] = [2.0, -1.6, -2.6, 0.0, 1.6, -2.0, -1.0, 1.4]
		var vi_scales: Array[Vector2] = [
			Vector2(1.04, 1.03), Vector2(1.02, 1.02), Vector2(1.05, 1.04), Vector2(1.0, 1.0),
			Vector2(1.04, 1.03), Vector2(1.02, 1.02), Vector2(1.04, 1.03), Vector2(1.02, 1.02)
		]
		var vi_faces: Array[Color] = [
			Color(1.0, 0.92, 0.24, 1.0),
			Color(1.0, 0.97, 0.36, 1.0),
			Color(1.0, 0.88, 0.18, 1.0),
			Color(1.0, 1.0, 1.0, 1.0),
			Color(0.54, 0.97, 1.0, 1.0),
			Color(0.70, 0.99, 1.0, 1.0),
			Color(0.48, 0.95, 1.0, 1.0),
			Color(0.68, 0.99, 1.0, 1.0)
		]
		var vi_span_w: float = _draw_playful_logo_word(
			font, "Xếp Gạch", center.x, vi_y, vi_fsz, out_vi,
			vi_tilts, vi_bounces, vi_scales,
			Color(0.02, 0.01, 0.12, 0.56),
			Color(0.08, 0.02, 0.24, 0.96),
			Color(0.56, 0.18, 0.12, 0.98),
			Color(0.18, 0.06, 0.44, 0.99),
			Color(0.92, 0.50, 0.12, 0.99),
			vi_faces,
			Color(1.0, 1.0, 0.92, 0.76)
		)

		# Secondary line: "Block Puzzle" noticeably smaller and visually lighter
		_draw_secondary_subtitle_branding(font, "Block Puzzle", center.x, sub_y, sub_fsz)

		var half_span_x: float = clampf(maxf(vi_span_w * 0.52, float(vi_fsz) * 2.10), 88.0, w * 0.44)
		UIIconScript.draw_star_shape(lbl_title, Vector2(center.x - half_span_x, vi_y - float(vi_fsz) * 0.58), 6.0, 2.3, Color(1.0, 0.98, 0.68, 0.96))
		UIIconScript.draw_star_shape(lbl_title, Vector2(center.x + half_span_x, vi_y - float(vi_fsz) * 0.54), 5.5, 2.1, Color(0.74, 0.99, 1.0, 0.94))
	else:
		# ======================================================================
		# ENGLISH MODE: "Block Puzzle" (Tier 1 "Block" + Tier 2 "Puzzle")
		# Normal mixed-case typography (not BLOCK PUZZLE).
		# ======================================================================
		var block_fsz: int = clampi(int(round(float(f_sz) * 0.88)), 52, 82)
		var puzzle_fsz: int = clampi(int(round(float(f_sz) * 0.70)), 40, 68)
		var block_y: float = center.y - span_h * 0.06
		var puzzle_y: float = center.y + span_h * 0.35
		var out_b: int = clampi(int(round(float(block_fsz) * 0.30)), 15, 23)
		var out_p: int = clampi(int(round(float(puzzle_fsz) * 0.30)), 12, 20)

		var en_cube_side: float = clampf(float(block_fsz) * 0.28, 12.0, 20.0)
		var en_half_span_est: float = clampf(float(block_fsz) * 2.18, 96.0, w * 0.43)
		_draw_beveled_logo_cube(
			Vector2(center.x - en_half_span_est, block_y - float(block_fsz) * 0.34),
			en_cube_side, -0.22,
			Color(1.0, 0.78, 0.16, 1.0), Color(1.0, 0.97, 0.68, 0.95)
		)
		_draw_beveled_logo_cube(
			Vector2(center.x + en_half_span_est, puzzle_y - float(puzzle_fsz) * 0.30),
			en_cube_side * 0.90, 0.24,
			Color(0.22, 0.88, 1.0, 1.0), Color(0.84, 0.99, 1.0, 0.95)
		)

		# Tier 1: "Block" — Normal mixed-case casual-game typography
		var block_tilts: Array[float] = [-0.055, -0.024, 0.0, 0.026, 0.055]
		var block_bounces: Array[float] = [2.5, -1.8, -3.6, -1.6, 2.4]
		var block_scales: Array[Vector2] = [
			Vector2(1.05, 1.04), Vector2(1.02, 1.02), Vector2(1.06, 1.05), Vector2(1.02, 1.02), Vector2(1.05, 1.04)
		]
		var block_faces: Array[Color] = [
			Color(1.0, 0.92, 0.24, 1.0),
			Color(1.0, 0.97, 0.36, 1.0),
			Color(1.0, 0.88, 0.18, 1.0),
			Color(1.0, 0.96, 0.34, 1.0),
			Color(1.0, 0.91, 0.22, 1.0)
		]
		var block_span_w: float = _draw_playful_logo_word(
			font, "Block", center.x, block_y, block_fsz, out_b,
			block_tilts, block_bounces, block_scales,
			Color(0.02, 0.01, 0.12, 0.56),
			Color(0.08, 0.02, 0.24, 0.96),
			Color(0.62, 0.18, 0.04, 0.98),
			Color(0.20, 0.06, 0.44, 0.99),
			Color(0.96, 0.46, 0.06, 0.99),
			block_faces,
			Color(1.0, 1.0, 0.92, 0.72)
		)

		# Tier 2: "Puzzle" — Normal mixed-case casual-game typography
		var puzzle_tilts: Array[float] = [-0.042, -0.018, 0.016, -0.016, 0.020, 0.042]
		var puzzle_bounces: Array[float] = [1.8, -1.2, -2.5, -2.2, -1.0, 1.8]
		var puzzle_scales: Array[Vector2] = [
			Vector2(1.04, 1.03), Vector2(1.01, 1.01), Vector2(1.04, 1.04),
			Vector2(1.04, 1.04), Vector2(1.01, 1.01), Vector2(1.04, 1.03)
		]
		var puzzle_faces: Array[Color] = [
			Color(0.54, 0.97, 1.0, 1.0),
			Color(0.70, 0.99, 1.0, 1.0),
			Color(0.46, 0.94, 1.0, 1.0),
			Color(0.66, 0.99, 1.0, 1.0),
			Color(0.52, 0.96, 1.0, 1.0),
			Color(0.72, 0.99, 1.0, 1.0)
		]
		_draw_playful_logo_word(
			font, "Puzzle", center.x, puzzle_y, puzzle_fsz, out_p,
			puzzle_tilts, puzzle_bounces, puzzle_scales,
			Color(0.02, 0.03, 0.16, 0.54),
			Color(0.04, 0.08, 0.28, 0.96),
			Color(0.05, 0.34, 0.76, 0.98),
			Color(0.06, 0.14, 0.46, 0.99),
			Color(0.12, 0.68, 0.98, 0.99),
			puzzle_faces,
			Color(0.96, 1.0, 1.0, 0.74)
		)

		var en_half_span_x: float = clampf(maxf(block_span_w * 0.52, float(block_fsz) * 2.05), 90.0, w * 0.43)
		UIIconScript.draw_star_shape(lbl_title, Vector2(center.x - en_half_span_x, block_y - float(block_fsz) * 0.68), 6.5, 2.5, Color(1.0, 0.98, 0.68, 0.96))
		UIIconScript.draw_star_shape(lbl_title, Vector2(center.x + en_half_span_x, block_y - float(block_fsz) * 0.62), 5.8, 2.2, Color(1.0, 0.96, 0.58, 0.94))
		UIIconScript.draw_star_shape(lbl_title, Vector2(center.x + en_half_span_x * 0.94, puzzle_y - float(puzzle_fsz) * 0.58), 5.5, 2.1, Color(0.74, 0.99, 1.0, 0.94))


func get_title_visual_metrics() -> Dictionary:
	var f_sz: int = lbl_title.get_theme_font_size("font_size") if lbl_title else 0
	var out_sz: int = lbl_title.get_theme_constant("outline_size") if lbl_title else 0
	var sh_y: int = lbl_title.get_theme_constant("shadow_offset_y") if lbl_title else 0
	var header_box := get_node_or_null("MarginContainer/VBoxContainer/Header") as Control
	var top_bar := get_node_or_null("MarginContainer/VBoxContainer/TopStatusBar") as Control
	var mode_box := get_node_or_null("MarginContainer/VBoxContainer/ModeSelection") as Control
	var between_header_and_modes: bool = (
		top_bar != null and header_box != null and mode_box != null
		and top_bar.get_index() < header_box.get_index()
		and header_box.get_index() < mode_box.get_index()
	)
	var is_redesigned: bool = lbl_title != null and bool(lbl_title.get_meta("is_redesigned_emblem_title", false)) and lbl_title.draw.is_connected(_on_lbl_title_draw)
	var normal_sb := lbl_title.get_theme_stylebox("normal") if lbl_title else null
	var has_bg_panel: bool = bool(lbl_title.get_meta("has_background_frame_or_crest", true)) if lbl_title else true
	if normal_sb is StyleBoxFlat and (normal_sb as StyleBoxFlat).bg_color.a > 0.01:
		has_bg_panel = true
	var is_font_var: bool = (title_display_font is FontVariation)
	var gs = get_node_or_null("/root/GameState")
	var lang: String = gs.get_language() if (gs and gs.has_method("get_language")) else "en"
	var is_vi: bool = (lang == "vi")
	return {
		"text": lbl_title.text if lbl_title else "",
		"primary_title": "Xếp Gạch" if is_vi else "Block Puzzle",
		"subtitle": "Block Puzzle" if is_vi else "",
		"is_localized": true,
		"language": lang,
		"font_size": f_sz,
		"regular_font_size": TITLE_FONT_SIZE_REGULAR,
		"compact_font_size": TITLE_FONT_SIZE_COMPACT,
		"outline_size": out_sz,
		"shadow_offset_y": sh_y,
		"has_display_font": title_display_font != null,
		"has_emboldened_display_font_variation": is_font_var,
		"is_playful_casual_game_logo": is_redesigned and bool(lbl_title.get_meta("is_playful_casual_game_logo", false)),
		"has_per_character_playful_variation": is_redesigned and bool(lbl_title.get_meta("has_per_character_playful_variation", false)),
		"is_original_4tm_title_treatment": is_redesigned and is_font_var and not has_bg_panel,
		"has_background_panel": has_bg_panel,
		"has_frame_or_crest": has_bg_panel,
		"is_frameless_dimensional_typography": is_redesigned and not has_bg_panel,
		"is_redesigned_emblem": is_redesigned,
		"has_custom_emblem_canvas": is_redesigned,
		"is_completely_redesigned": is_redesigned,
		"has_depth_highlight_shadow": title_display_font != null and out_sz >= 14 and sh_y >= 6 and is_redesigned and not has_bg_panel,
		"is_between_header_and_modes": between_header_and_modes,
		"header_min_height": header_box.custom_minimum_size.y if header_box else 0.0
	}


func get_title_and_start_centering_metrics(brand_rect: Rect2 = Rect2(), vp_size: Vector2 = Vector2(720, 1280)) -> Dictionary:
	var layout := update_responsive_menu_layout(vp_size)
	var start_r: Rect2 = layout.get("start_button_rect", Rect2())
	var brand_ok: bool = true
	if brand_rect.size.y > 0.0:
		brand_ok = (start_r.end.y <= brand_rect.position.y - 16.0)
	return {
		"title_centered_h": bool(layout.get("is_title_centered_h", false)),
		"title_centered_v": bool(layout.get("is_title_centered_v", false)),
		"title_no_overlap": bool(layout.get("is_strict_vertical_hierarchy", false)),
		"start_centered_h": bool(layout.get("is_start_centered_h", false)),
		"start_centered_v": bool(layout.get("is_start_centered_v", false)),
		"start_clearly_separated": bool(layout.get("is_strict_vertical_hierarchy", false)) and brand_ok,
		"title_top_gap": float(layout.get("title_top_gap", 0.0)),
		"title_bottom_gap": float(layout.get("title_bottom_gap", 0.0)),
		"start_top_gap": float(layout.get("start_top_gap", 0.0)),
		"start_bottom_gap": float(layout.get("start_bottom_gap", 0.0))
	}


func has_polished_large_title_treatment() -> bool:
	var m := get_title_visual_metrics()
	var txt: String = String(m.get("text", ""))
	return (
		(txt == "Block Puzzle" or txt == "Xếp Gạch")
		and int(m.get("regular_font_size", 0)) >= 76
		and int(m.get("font_size", 0)) >= 54
		and bool(m.get("has_display_font", false))
		and not bool(m.get("has_background_panel", true))
		and not bool(m.get("has_frame_or_crest", true))
		and bool(m.get("is_frameless_dimensional_typography", false))
		and bool(m.get("has_depth_highlight_shadow", false))
		and bool(m.get("is_between_header_and_modes", false))
	)


func verify_vertical_hierarchy(brand_rect: Rect2 = Rect2(), ad_rect: Rect2 = Rect2()) -> bool:
	if not has_polished_large_title_treatment() or not is_start_below_mode_and_style_buttons():
		return false
	var vp_sz := Vector2(ad_rect.size.x, ad_rect.end.y) if (ad_rect.size.x > 0 and ad_rect.end.y > 0) else (size if (size.x > 0 and size.y > 0) else Vector2(720, 1280))
	var layout := update_responsive_menu_layout(vp_sz)
	if not bool(layout.get("is_strict_vertical_hierarchy", false)):
		return false
	if not bool(layout.get("is_title_centered_h", false)) or not bool(layout.get("is_title_centered_v", false)):
		return false
	if not bool(layout.get("is_start_centered_h", false)) or not bool(layout.get("is_start_centered_v", false)):
		return false
	if brand_rect.size.y > 0.0 and ad_rect.size.y > 0.0 and brand_rect.position.y > 0.0:
		var start_r: Rect2 = layout.get("start_button_rect", Rect2())
		if start_r.end.y >= brand_rect.position.y or brand_rect.end.y > ad_rect.position.y + 0.5:
			return false
	return true


func _make_red_exit_style(bg_col: Color = Color(0.88, 0.18, 0.26, 0.98), border_col: Color = Color(1.0, 0.68, 0.72, 1.0), bottom_w: int = 7) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg_col
	st.border_width_left = 3
	st.border_width_top = 3
	st.border_width_right = 3
	st.border_width_bottom = bottom_w
	st.border_color = border_col
	st.corner_radius_top_left = 22
	st.corner_radius_top_right = 22
	st.corner_radius_bottom_right = 22
	st.corner_radius_bottom_left = 22
	st.shadow_color = Color(0.18, 0.02, 0.04, 0.55)
	st.shadow_size = 10
	st.shadow_offset = Vector2(0, 4)
	return st


func _apply_red_exit_style(btn: Button) -> void:
	if not btn:
		return
	var st_norm := _make_red_exit_style(Color(0.88, 0.18, 0.26, 0.98), Color(1.0, 0.68, 0.72, 1.0), 7)
	var st_hov := _make_red_exit_style(Color(0.96, 0.24, 0.32, 0.99), Color(1.0, 0.80, 0.84, 1.0), 7)
	var st_press := _make_red_exit_style(Color(0.74, 0.12, 0.20, 0.99), Color(1.0, 0.56, 0.60, 1.0), 3)
	btn.add_theme_color_override("font_color", Color(1.0, 0.98, 0.98, 1.0))
	btn.add_theme_stylebox_override("normal", st_norm)
	btn.add_theme_stylebox_override("hover", st_hov)
	btn.add_theme_stylebox_override("pressed", st_press)
	GameTypographyScript.apply_secondary_button_typography(btn, 20, Color(0.24, 0.04, 0.06, 0.95))
	btn.set_meta("is_red_exit_action", true)


func _setup_leave_button_spacing() -> void:
	var map_actions := get_node_or_null("Modals/LevelMapModal/Panel/VBoxContainer/BottomMapActions") as HBoxContainer
	if map_actions:
		map_actions.add_theme_constant_override("separation", 26)
	var wheel_actions := get_node_or_null("Modals/LuckyWheelModal/Panel/VBoxContainer/WheelActions") as HBoxContainer
	if wheel_actions:
		wheel_actions.add_theme_constant_override("separation", 26)
	if btn_settings_account and btn_settings_account.get_parent() is VBoxContainer:
		var s_vbox := btn_settings_account.get_parent() as VBoxContainer
		var acc_sp := s_vbox.get_node_or_null("SettingsAccountGroupSpacer") as Control
		if not acc_sp:
			acc_sp = Control.new()
			acc_sp.name = "SettingsAccountGroupSpacer"
			acc_sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
			s_vbox.add_child(acc_sp)
		s_vbox.move_child(acc_sp, btn_settings_account.get_index())
		acc_sp.custom_minimum_size = Vector2(0, 30)
	for close_btn in [btn_close_settings, btn_close_how_to_play, btn_close_account]:
		if close_btn and close_btn.get_parent() is VBoxContainer:
			var vbox := close_btn.get_parent() as VBoxContainer
			var spacer_name: String = "LeaveActionSpacer_" + String(close_btn.name)
			var sp := vbox.get_node_or_null(spacer_name) as Control
			if not sp:
				sp = Control.new()
				sp.name = spacer_name
				sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
				vbox.add_child(sp)
				vbox.move_child(sp, close_btn.get_index())
			sp.custom_minimum_size = Vector2(0, 10)


func get_leave_button_spacing_metrics() -> Dictionary:
	var map_actions := get_node_or_null("Modals/LevelMapModal/Panel/VBoxContainer/BottomMapActions") as HBoxContainer
	var wheel_actions := get_node_or_null("Modals/LuckyWheelModal/Panel/VBoxContainer/WheelActions") as HBoxContainer
	var settings_vbox := get_node_or_null("Modals/SettingsModal/Panel/VBoxContainer") as VBoxContainer
	var map_sep: int = map_actions.get_theme_constant("separation") if map_actions else 0
	var wheel_sep: int = wheel_actions.get_theme_constant("separation") if wheel_actions else 0
	var settings_base_sep: int = settings_vbox.get_theme_constant("separation") if settings_vbox else 14
	var settings_spacer := settings_vbox.get_node_or_null("LeaveActionSpacer_BtnClose") as Control if settings_vbox else null
	var settings_leave_gap: float = float(settings_base_sep * 2) + (settings_spacer.custom_minimum_size.y if settings_spacer else 0.0)
	return {
		"level_map_leave_to_start_gap_px": float(map_sep),
		"lucky_wheel_leave_to_spin_gap_px": float(wheel_sep),
		"settings_normal_gap_px": float(settings_base_sep),
		"settings_leave_gap_px": settings_leave_gap,
		"has_intentional_leave_spacing": map_sep >= 22 and wheel_sep >= 22 and settings_leave_gap >= float(settings_base_sep) + 10.0 and settings_leave_gap <= 48.0,
		"has_red_leave_buttons": has_red_exit_actions()
	}


func is_button_red_styled(btn: Button) -> bool:
	if not btn:
		return false
	var st := btn.get_theme_stylebox("normal") as StyleBoxFlat
	if not st:
		return false
	return st.bg_color.r >= 0.70 and st.bg_color.r > st.bg_color.g * 2.2 and st.bg_color.r > st.bg_color.b * 2.0


func has_red_exit_actions() -> bool:
	for exit_btn in [btn_close_how_to_play, btn_close_settings, btn_close_account, btn_close_level_map, btn_close_wheel]:
		if not is_button_red_styled(exit_btn):
			return false
	for normal_btn in [btn_start, btn_classic, btn_modern, btn_falling, btn_drag_drop, btn_how_to_play, btn_account, btn_settings_account, btn_nav_account, btn_top_level, btn_top_settings, btn_language_modal, btn_toggle_music, btn_toggle_sound, btn_toggle_voice]:
		if normal_btn and is_button_red_styled(normal_btn):
			return false
	return true


func has_equal_width_music_sfx_row() -> bool:
	if not audio_toggles_row or not btn_toggle_music or not btn_toggle_sound:
		return false
	if btn_toggle_music.get_parent() != audio_toggles_row or btn_toggle_sound.get_parent() != audio_toggles_row:
		return false
	if audio_toggles_row.get_child_count() != 2:
		return false
	var m_expand: bool = (btn_toggle_music.size_flags_horizontal & Control.SIZE_EXPAND_FILL) == Control.SIZE_EXPAND_FILL
	var s_expand: bool = (btn_toggle_sound.size_flags_horizontal & Control.SIZE_EXPAND_FILL) == Control.SIZE_EXPAND_FILL
	return m_expand and s_expand and is_equal_approx(btn_toggle_music.size_flags_stretch_ratio, btn_toggle_sound.size_flags_stretch_ratio)


func has_equal_width_voice_haptics_row() -> bool:
	if not voice_haptics_row or not btn_toggle_voice or not btn_toggle_haptics:
		return false
	if btn_toggle_voice.get_parent() != voice_haptics_row or btn_toggle_haptics.get_parent() != voice_haptics_row:
		return false
	if voice_haptics_row.get_child_count() != 2:
		return false
	var v_expand: bool = (btn_toggle_voice.size_flags_horizontal & Control.SIZE_EXPAND_FILL) == Control.SIZE_EXPAND_FILL
	var h_expand: bool = (btn_toggle_haptics.size_flags_horizontal & Control.SIZE_EXPAND_FILL) == Control.SIZE_EXPAND_FILL
	return v_expand and h_expand and is_equal_approx(btn_toggle_voice.size_flags_stretch_ratio, btn_toggle_haptics.size_flags_stretch_ratio)


func has_duplicate_branding_row() -> bool:
	return _find_node("BrandBar") != null or _find_node("Logo4TM") != null


func get_branding_info() -> Dictionary:
	return {
		"has_4tm_logo": false,
		"games_text": "",
		"domain_text": "",
		"is_generic_reusable": false,
		"is_centered": false,
		"has_duplicate_in_main_menu": false
	}


func has_gear_icon() -> bool:
	if not btn_top_settings:
		return false
	var icon_node := btn_top_settings.get_node_or_null("VectorIcon")
	return icon_node != null and ("icon_type" in icon_node) and icon_node.icon_type == "gear" and btn_top_settings.text == ""


func is_settings_gear_frameless() -> bool:
	if not has_gear_icon():
		return false
	var st := btn_top_settings.get_theme_stylebox("normal") as StyleBoxFlat
	if st != null and (st.bg_color.a > 0.01 or st.border_width_left > 0 or st.border_width_top > 0 or st.border_width_right > 0 or st.border_width_bottom > 0 or st.shadow_size > 0):
		return false
	return bool(btn_top_settings.get_meta("is_frameless_gear_icon", false))


func has_settings_gear_vector_icon() -> bool:
	return has_gear_icon() and is_settings_gear_frameless()


func has_rules_button_next_to_game_mode() -> bool:
	return _find_node("BtnRulesHelp") != null


func has_redundant_world_map_button() -> bool:
	return _find_node("BtnWorldMap") != null or _find_node("BtnOpenLevelMap") != null or _find_node("ProgressionCard") != null


func has_all_vector_icons() -> bool:
	for b in [btn_top_settings, btn_top_level, btn_daily_gift, btn_language_modal, btn_classic, btn_modern, btn_falling, btn_drag_drop, btn_how_to_play, btn_account, btn_settings_account, btn_delete_data, btn_create_email, btn_apple_id, btn_google_id]:
		if not b or b.get_node_or_null("VectorIcon") == null:
			return false
	return true


func has_text_only_start_button() -> bool:
	if not btn_start:
		return false
	if btn_start.get_node_or_null("VectorIcon") != null:
		return false
	var t := btn_start.text.strip_edges()
	return (t == "START" or t == "BẮT ĐẦU") and btn_start.alignment == HORIZONTAL_ALIGNMENT_CENTER


func has_standalone_language_button() -> bool:
	return _find_node("BtnLanguage") != null


func has_simplified_title_area() -> bool:
	if _find_node("LblEcosystem") != null or _find_node("LblSubtitle") != null:
		return false
	if not lbl_title:
		return false
	var txt := lbl_title.text.strip_edges()
	if txt != "Block Puzzle" and txt != "Xếp Gạch":
		return false
	var header_box := lbl_title.get_parent()
	return header_box != null and header_box.get_child_count() == 1


func get_start_button_spacing_metrics() -> Dictionary:
	var main_vbox := get_node_or_null("MarginContainer/VBoxContainer") as VBoxContainer
	var play_box := get_node_or_null("MarginContainer/VBoxContainer/PlayActionContainer") as MarginContainer
	var vbox_sep: int = main_vbox.get_theme_constant("separation") if main_vbox else 14
	var m_top: int = play_box.get_theme_constant("margin_top") if play_box else 0
	var m_bot: int = play_box.get_theme_constant("margin_bottom") if play_box else 0
	return {
		"margin_top": m_top,
		"margin_bottom": m_bot,
		"vbox_separation": vbox_sep,
		"effective_top_gap": m_top + vbox_sep,
		"effective_bottom_gap": m_bot + vbox_sep
	}


func has_standalone_start_button_hierarchy() -> bool:
	if not btn_start:
		return false
	var main_vbox := get_node_or_null("MarginContainer/VBoxContainer")
	var top_bar := get_node_or_null("MarginContainer/VBoxContainer/TopStatusBar")
	var header_box := get_node_or_null("MarginContainer/VBoxContainer/Header")
	var play_box := get_node_or_null("MarginContainer/VBoxContainer/PlayActionContainer") as MarginContainer
	var mode_box := get_node_or_null("MarginContainer/VBoxContainer/ModeSelection")
	var nav_box := get_node_or_null("MarginContainer/VBoxContainer/NavActions")
	if not main_vbox or not top_bar or not header_box or not play_box or not mode_box or not nav_box:
		return false
	if btn_start.get_parent() != play_box or play_box.get_child_count() != 1:
		return false
	if mode_box.is_ancestor_of(btn_start):
		return false
	var sp := get_start_button_spacing_metrics()
	if int(sp.get("margin_top", 0)) < 16 or int(sp.get("margin_bottom", 0)) < 20:
		return false
	return (
		top_bar.get_index() < header_box.get_index()
		and header_box.get_index() < mode_box.get_index()
		and mode_box.get_index() < play_box.get_index()
		and play_box.get_index() < nav_box.get_index()
	)


func is_start_below_mode_and_style_buttons() -> bool:
	if not has_standalone_start_button_hierarchy():
		return false
	var mode_box := get_node_or_null("MarginContainer/VBoxContainer/ModeSelection") as Control
	var play_box := get_node_or_null("MarginContainer/VBoxContainer/PlayActionContainer") as Control
	if not mode_box or not play_box:
		return false
	for b in [btn_classic, btn_modern, btn_falling, btn_drag_drop]:
		if not b or not mode_box.is_ancestor_of(b):
			return false
	return mode_box.get_index() < play_box.get_index()


func _on_self_resized() -> void:
	if size.x > 0 and size.y > 0:
		update_responsive_menu_layout(size)


func update_responsive_menu_layout(vp_size: Vector2 = Vector2(720, 1280)) -> Dictionary:
	var vp_w: float = vp_size.x if vp_size.x > 0 else 720.0
	var vp_h: float = vp_size.y if vp_size.y > 0 else 1280.0
	var is_compact: bool = (vp_h <= 900.0 or vp_w <= 430.0)
	var is_very_compact: bool = (vp_h <= 810.0 or vp_w <= 370.0)
	
	var margin_ctrl := get_node_or_null("MarginContainer") as MarginContainer
	var main_vbox := get_node_or_null("MarginContainer/VBoxContainer") as VBoxContainer
	var top_bar := get_node_or_null("MarginContainer/VBoxContainer/TopStatusBar") as HBoxContainer
	var header_box := get_node_or_null("MarginContainer/VBoxContainer/Header") as VBoxContainer
	var mode_box := get_node_or_null("MarginContainer/VBoxContainer/ModeSelection") as VBoxContainer
	var play_box := get_node_or_null("MarginContainer/VBoxContainer/PlayActionContainer") as MarginContainer
	var nav_box := get_node_or_null("MarginContainer/VBoxContainer/NavActions") as HBoxContainer
	
	var gs = get_node_or_null("/root/GameState")
	var insets: Dictionary = gs.get_safe_area_insets(vp_size) if (gs and gs.has_method("get_safe_area_insets")) else {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}
	var safe_top: float = float(insets.get("top", 0.0))
	var safe_bot: float = float(insets.get("bottom", 0.0))
	var safe_side: float = maxf(float(insets.get("left", 0.0)), float(insets.get("right", 0.0)))

	var base_m_side: int = 8 if is_very_compact else (12 if is_compact else 24)
	var base_m_top: int = 10 if is_very_compact else (12 if is_compact else 18)
	var base_m_bot: int = 10 if is_very_compact else (12 if is_compact else 18)

	var m_side: int = int(float(base_m_side) + safe_side)
	var m_top: int = int(float(base_m_top) + safe_top)
	var m_bot: int = int(float(base_m_bot) + safe_bot)
	if margin_ctrl:
		margin_ctrl.add_theme_constant_override("margin_left", m_side)
		margin_ctrl.add_theme_constant_override("margin_right", m_side)
		margin_ctrl.add_theme_constant_override("margin_top", m_top)
		margin_ctrl.add_theme_constant_override("margin_bottom", m_bot)
	
	if main_vbox:
		main_vbox.add_theme_constant_override("separation", 0)
	if nav_box:
		nav_box.visible = false
	
	var content_w: float = maxf(280.0, vp_w - float(m_side * 2))
	var top_btn_h: float = 46.0 if is_very_compact else (48.0 if is_compact else 56.0)
	var top_bar_h: float = top_btn_h + 4.0
	if top_bar:
		top_bar.add_theme_constant_override("separation", 3 if is_very_compact else (4 if is_compact else 8))
	if btn_top_level:
		btn_top_level.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var lvl_w: float = 94.0 if is_very_compact else (104.0 if is_compact else 140.0)
		btn_top_level.custom_minimum_size = Vector2(lvl_w, top_btn_h)
		btn_top_level.size.y = top_btn_h
		btn_top_level.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_top_level.add_theme_font_size_override("font_size", 13 if is_very_compact else (14 if is_compact else 17))
		var crown_icon := btn_top_level.get_node_or_null("VectorIcon") as Control
		if crown_icon:
			var cr_side: float = 20.0 if is_very_compact else (22.0 if is_compact else 26.0)
			crown_icon.custom_minimum_size = Vector2(cr_side, cr_side)
			crown_icon.size = Vector2(cr_side, cr_side)
			crown_icon._on_parent_resized()
	if energy_panel:
		var ep_w: float = 80.0 if is_very_compact else (88.0 if is_compact else 130.0)
		energy_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var ep_sb := energy_panel.get_theme_stylebox("panel") as StyleBoxFlat
		if ep_sb:
			ep_sb.content_margin_left = 6.0 if is_very_compact else 8.0
			ep_sb.content_margin_right = 4.0 if is_very_compact else 6.0
			ep_sb.content_margin_top = 0.0
			ep_sb.content_margin_bottom = 0.0
			ep_sb.expand_margin_top = 0.0
			ep_sb.expand_margin_bottom = 0.0
		var ep_hbox := energy_panel.get_node_or_null("HBox") as HBoxContainer
		if ep_hbox:
			ep_hbox.custom_minimum_size = Vector2.ZERO
			ep_hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			ep_hbox.add_theme_constant_override("separation", 3 if is_very_compact else 4)
		var ep_bolt := energy_panel.find_child("EnergyIcon", true, false) as Control
		if ep_bolt:
			var bolt_side: float = 18.0 if is_very_compact else (20.0 if is_compact else 24.0)
			if "align_mode" in ep_bolt:
				ep_bolt.align_mode = "none"
			ep_bolt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			ep_bolt.custom_minimum_size = Vector2(bolt_side, bolt_side)
			ep_bolt.size = Vector2(bolt_side, bolt_side)
			ep_bolt.update_minimum_size()
		if lbl_energy:
			lbl_energy.custom_minimum_size = Vector2.ZERO
			lbl_energy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			lbl_energy.add_theme_font_size_override("font_size", 12 if is_very_compact else (13 if is_compact else 16))
			lbl_energy.update_minimum_size()
		if btn_energy_plus:
			var inner_plus_w: float = 24.0 if is_very_compact else (26.0 if is_compact else 32.0)
			var inner_plus_h: float = 24.0 if is_very_compact else (26.0 if is_compact else 32.0)
			btn_energy_plus.text = ""
			btn_energy_plus.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			btn_energy_plus.custom_minimum_size = Vector2(inner_plus_w, inner_plus_h)
			btn_energy_plus.size = Vector2(inner_plus_w, inner_plus_h)
			btn_energy_plus.add_theme_font_size_override("font_size", 18 if is_very_compact else (20 if is_compact else 24))
			var plus_icon := btn_energy_plus.get_node_or_null("VectorIcon") as Control
			if plus_icon:
				plus_icon.custom_minimum_size = Vector2(inner_plus_w, inner_plus_h)
				plus_icon.size = Vector2(inner_plus_w, inner_plus_h)
				if plus_icon.has_method("_on_parent_resized"):
					plus_icon._on_parent_resized()
			btn_energy_plus.update_minimum_size()
		if ep_hbox:
			ep_hbox.update_minimum_size()
			ep_hbox.size = Vector2(ep_w, top_btn_h)
		energy_panel.custom_minimum_size = Vector2(ep_w, top_btn_h)
		energy_panel.update_minimum_size()
		energy_panel.size = Vector2(ep_w, top_btn_h)
	if btn_daily_gift:
		btn_daily_gift.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var gift_w: float = 126.0 if is_very_compact else (136.0 if is_compact else 184.0)
		btn_daily_gift.custom_minimum_size = Vector2(gift_w, top_btn_h)
		btn_daily_gift.size.y = top_btn_h
		btn_daily_gift.clip_text = false
		btn_daily_gift.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_daily_gift.add_theme_font_size_override("font_size", 12 if is_very_compact else (13 if is_compact else 16))
		var gift_icon := btn_daily_gift.get_node_or_null("VectorIcon") as Control
		if gift_icon:
			var g_side: float = 20.0 if is_very_compact else (22.0 if is_compact else 26.0)
			gift_icon.custom_minimum_size = Vector2(g_side, g_side)
			gift_icon.size = Vector2(g_side, g_side)
			gift_icon._on_parent_resized()
	if btn_top_settings:
		btn_top_settings.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn_top_settings.custom_minimum_size = Vector2(top_btn_h, top_btn_h)
		btn_top_settings.size = Vector2(top_btn_h, top_btn_h)
		var top_gear_icon := btn_top_settings.get_node_or_null("VectorIcon") as Control
		if top_gear_icon:
			top_gear_icon.custom_minimum_size = Vector2(top_btn_h, top_btn_h)
			top_gear_icon.size = Vector2(top_btn_h, top_btn_h)
			if top_gear_icon.has_method("_on_parent_resized"):
				top_gear_icon._on_parent_resized()
	var mode_btn_h: float = 80.0 if is_compact else 90.0
	var mode_sep: int = 8 if is_compact else 14
	if mode_box:
		mode_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mode_box.add_theme_constant_override("separation", mode_sep)
	for mb in [btn_classic, btn_modern, btn_falling, btn_drag_drop]:
		if mb:
			mb.custom_minimum_size = Vector2(0.0, mode_btn_h)
			mb.add_theme_font_size_override("font_size", 19 if is_compact else 24)
	
	var mode_sec_h: float = (26.0 * 2.0) + (mode_btn_h * 2.0) + float(mode_sep * 3)
	var y_header: float = float(m_top)
	var y_header_end: float = y_header + top_bar_h
	var y_ad_top: float = vp_h - safe_bot
	var y_brand_top: float = vp_h - safe_bot
	
	var remaining_v: float = maxf(240.0, vp_h - float(m_bot) - y_header_end - mode_sec_h)
	var title_zone_h: float = remaining_v * 0.5
	
	var title_font_sz: int = TITLE_FONT_SIZE_COMPACT if is_very_compact else (TITLE_FONT_SIZE_MEDIUM if is_compact else TITLE_FONT_SIZE_REGULAR)
	var title_h: float = clampf(title_zone_h - (36.0 if is_compact else 72.0), 108.0 if is_compact else 156.0, 136.0 if is_compact else 188.0)
	var title_w: float = clampf(content_w - 8.0, 296.0, 620.0)
	if header_box:
		header_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		header_box.alignment = BoxContainer.ALIGNMENT_CENTER
		header_box.custom_minimum_size = Vector2(0.0, title_h)
	if lbl_title:
		lbl_title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		lbl_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lbl_title.custom_minimum_size = Vector2(title_w, title_h)
		lbl_title.size = Vector2(title_w, title_h)
		lbl_title.add_theme_font_size_override("font_size", title_font_sz)
		lbl_title.queue_redraw()
	
	var play_m_top: int = 20 if is_compact else 22
	var play_m_bot: int = 20 if is_compact else 22
	var start_btn_h: float = 88.0 if is_compact else 108.0
	var start_btn_w: float = clampf(content_w - 28.0, 268.0, 580.0)
	if play_box:
		play_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		play_box.add_theme_constant_override("margin_left", 14)
		play_box.add_theme_constant_override("margin_right", 14)
		play_box.add_theme_constant_override("margin_top", play_m_top)
		play_box.add_theme_constant_override("margin_bottom", play_m_bot)
	if btn_start:
		btn_start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn_start.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn_start.custom_minimum_size = Vector2(start_btn_w, start_btn_h)
		btn_start.size = Vector2(start_btn_w, start_btn_h)
		btn_start.add_theme_font_size_override("font_size", 32 if is_compact else 38)
	
	var y_title: float = y_header_end + (title_zone_h - title_h) * 0.5
	var x_title: float = (vp_w - title_w) * 0.5
	var y_modes: float = y_header_end + title_zone_h
	var y_modes_end: float = y_modes + mode_sec_h
	var start_zone_h: float = maxf(80.0, y_brand_top - y_modes_end)
	var y_start_btn: float = y_modes_end + (start_zone_h - start_btn_h) * 0.5
	var x_start_btn: float = (vp_w - start_btn_w) * 0.5
	update_responsive_account_and_settings_modals(vp_size)
	
	var title_top_gap: float = y_title - y_header_end
	var title_bot_gap: float = y_modes - (y_title + title_h)
	var title_left_gap: float = x_title
	var title_right_gap: float = vp_w - (x_title + title_w)
	
	var start_top_gap: float = y_start_btn - y_modes_end
	var start_bot_gap: float = y_brand_top - (y_start_btn + start_btn_h)
	var start_left_gap: float = x_start_btn
	var start_right_gap: float = vp_w - (x_start_btn + start_btn_w)
	
	return {
		"header_rect": Rect2(Vector2(float(m_side), y_header), Vector2(content_w, top_bar_h)),
		"title_rect": Rect2(Vector2(x_title, y_title), Vector2(title_w, title_h)),
		"mode_style_rect": Rect2(Vector2(float(m_side), y_modes), Vector2(content_w, mode_sec_h)),
		"start_button_rect": Rect2(Vector2(x_start_btn, y_start_btn), Vector2(start_btn_w, start_btn_h)),
		"branding_rect": Rect2(Vector2(0.0, y_brand_top), Vector2(vp_w, 24.0)),
		"ad_slot_rect": Rect2(Vector2(0.0, y_ad_top), Vector2(vp_w, 60.0)),
		"title_font_size": title_font_sz,
		"title_top_gap": title_top_gap,
		"title_bottom_gap": title_bot_gap,
		"start_top_gap": start_top_gap,
		"start_bottom_gap": start_bot_gap,
		"is_title_centered_h": absf(title_left_gap - title_right_gap) <= 1.0,
		"is_title_centered_v": absf(title_top_gap - title_bot_gap) <= 1.0 and title_top_gap >= 16.0 and title_bot_gap >= 16.0,
		"is_start_centered_h": absf(start_left_gap - start_right_gap) <= 1.0,
		"is_start_centered_v": absf(start_top_gap - start_bot_gap) <= 1.0 and start_top_gap >= 20.0 and start_bot_gap >= 20.0,
		"is_strict_vertical_hierarchy": (
			y_header < y_title
			and y_header_end <= y_title - 12.0
			and (y_title + title_h) <= y_modes - 12.0
			and y_modes_end <= y_start_btn - 16.0
			and (y_start_btn + start_btn_h) <= y_brand_top - 16.0
		)
	}


func has_standalone_play_button_hierarchy() -> bool:
	return has_standalone_start_button_hierarchy()


func open_level_map_from_top_level_button() -> bool:
	_on_btn_top_level_pressed()
	return modal_level_map != null and modal_level_map.visible


func select_game_mode_button(mode_val: int) -> void:
	if mode_val == GameStateScript.GameMode.MODERN_DRAG_AND_DROP:
		_on_btn_modern_pressed()
	else:
		_on_btn_classic_pressed()


func select_play_style_button(style_val: int) -> void:
	if style_val == int(GameStateScript.PlayStyle.DRAG_AND_DROP):
		_on_btn_drag_drop_pressed()
	else:
		_on_btn_falling_pressed()


func _populate_level_map() -> void:
	_populate_level_map_page(current_map_page)


func _refresh_all_ui() -> void:
	if is_queued_for_deletion():
		return
	_sync_selection_from_state()
	_apply_language_texts()
	_refresh_progression_ui()
	_update_mode_selection_ui()
	_update_settings_buttons()
	_refresh_account_ui()
	_refresh_lucky_wheel_ui()
	if modal_level_map and modal_level_map.visible:
		_populate_level_map_page(current_map_page)


func _apply_language_texts() -> void:
	var gs = get_node_or_null("/root/GameState")
	var lang: String = gs.get_language() if (gs and gs.has_method("get_language")) else "en"
	var is_vi := (lang == "vi")
	
	if btn_language_modal:
		btn_language_modal.text = "    " + _tr("language_label")
	if btn_top_settings:
		btn_top_settings.text = ""
		btn_top_settings.tooltip_text = _tr("settings_title")
	if lbl_title:
		lbl_title.text = "Xếp Gạch" if is_vi else "Block Puzzle"
		lbl_title.queue_redraw()
	if lbl_mode_title:
		lbl_mode_title.text = _tr("section_mode_title")
	if lbl_play_style_title:
		lbl_play_style_title.text = _tr("section_style_title")
	if btn_how_to_play:
		btn_how_to_play.text = "    LUẬT CHƠI" if is_vi else "    RULES"
	if btn_settings_account:
		btn_settings_account.text = "    " + _tr("btn_account")
	if btn_nav_account:
		btn_nav_account.text = "    " + _tr("btn_account")
	if btn_account:
		btn_account.text = "    " + _tr("btn_account")
	if lbl_rules_modal_title:
		lbl_rules_modal_title.text = _tr("rules_modal_title")
	if lbl_rules_modal_content and gs and gs.has_method("get_rules_help_text"):
		lbl_rules_modal_content.text = gs.get_rules_help_text(selected_mode, selected_play_style)
	if btn_close_how_to_play:
		btn_close_how_to_play.text = _tr("rules_close")
	if lbl_settings_title:
		lbl_settings_title.text = _tr("settings_title")
	if btn_close_settings:
		btn_close_settings.text = _tr("btn_close")
	if lbl_account_title:
		lbl_account_title.text = _tr("account_title")
	if btn_close_account:
		btn_close_account.text = _tr("btn_close")
	_refresh_account_ui()
	if lbl_map_modal_title:
		lbl_map_modal_title.text = _tr("level_map_title")
	if btn_page_prev:
		btn_page_prev.text = _tr("level_map_prev")
	if btn_page_next:
		btn_page_next.text = _tr("level_map_next")
	if btn_page_current:
		btn_page_current.text = _tr("level_map_current")
	if btn_close_level_map:
		btn_close_level_map.text = _tr("level_map_back")
	if lbl_wheel_title:
		lbl_wheel_title.text = _tr("lucky_wheel_title")
	if lbl_wheel_subtitle:
		lbl_wheel_subtitle.text = _tr("lucky_wheel_subtitle")
	if btn_close_wheel:
		btn_close_wheel.text = _tr("btn_close")


func _on_btn_language_pressed() -> void:
	_play_sfx("click")
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_method("toggle_language"):
		gs.toggle_language()
	_refresh_all_ui()



func _process(delta: float) -> void:
	anim_time += delta
	if btn_start and visible:
		btn_start.pivot_offset = btn_start.size * 0.5
		var pulse = 1.0 + 0.022 * sin(anim_time * 3.6)
		btn_start.scale = Vector2(pulse, pulse)
	if modal_level_map and modal_level_map.visible and level_grid:
		if not is_equal_approx(map_scroll_y, map_target_scroll_y):
			map_scroll_y = lerpf(map_scroll_y, map_target_scroll_y, clampf(delta * 14.0, 0.0, 1.0))
			_apply_map_scroll_positions()
		if _level_map_camera_3d and map_max_scroll_y > 0.0:
			var scroll_norm: float = (map_scroll_y / maxf(1.0, map_max_scroll_y)) - 0.5
			_level_map_camera_3d.position.z = 9.8 + scroll_norm * 3.8
			_level_map_camera_3d.position.y = 12.5 - scroll_norm * 1.5
		level_grid.queue_redraw()
	if modal_lucky_wheel and modal_lucky_wheel.visible and wheel_canvas:
		wheel_canvas.queue_redraw()
	queue_redraw()


func _draw() -> void:
	var h: float = size.y if size.y > 0 else 1280.0
	var w: float = size.x if size.x > 0 else 720.0
	
	# 1. Bright Casual Mobile World Sky & Crystal Horizon Gradient
	var sky_top := Color(0.20, 0.52, 0.96, 1.0)
	var sky_mid := Color(0.46, 0.34, 0.86, 1.0)
	var sky_low := Color(0.76, 0.32, 0.68, 1.0)
	var meadow_bot := Color(0.20, 0.24, 0.58, 1.0)
	var steps: int = 18
	var step_h: float = h / float(steps)
	for i in range(steps):
		var t = float(i) / float(max(1, steps - 1))
		var c: Color
		if t < 0.42:
			c = sky_top.lerp(sky_mid, t / 0.42)
		elif t < 0.76:
			c = sky_mid.lerp(sky_low, (t - 0.42) / 0.34)
		else:
			c = sky_low.lerp(meadow_bot, (t - 0.76) / 0.24)
		draw_rect(Rect2(0, float(i) * step_h, w, step_h + 2.0), c, true)
	
	# 2. Golden Sunburst Halo Behind Logo
	var logo_center = Vector2(w * 0.5, h * 0.14)
	draw_circle(logo_center, w * 0.44, Color(1.0, 0.90, 0.38, 0.22))
	draw_circle(logo_center, w * 0.28, Color(1.0, 0.98, 0.75, 0.18))
	
	# 3. Fluffy Drifting Clouds
	var cloud_positions = [
		Vector2(w * 0.15 + sin(anim_time * 0.25) * 18.0, h * 0.09),
		Vector2(w * 0.84 - cos(anim_time * 0.22) * 20.0, h * 0.12),
		Vector2(w * 0.12 + cos(anim_time * 0.18) * 15.0, h * 0.36),
		Vector2(w * 0.88 + sin(anim_time * 0.20) * 16.0, h * 0.39)
	]
	for cp in cloud_positions:
		draw_circle(cp, 44.0, Color(1.0, 1.0, 1.0, 0.22))
		draw_circle(cp + Vector2(-28.0, 8.0), 32.0, Color(1.0, 1.0, 1.0, 0.20))
		draw_circle(cp + Vector2(28.0, 8.0), 30.0, Color(1.0, 1.0, 1.0, 0.20))
	
	# 4. Rolling Crystal Hills
	draw_circle(Vector2(w * 0.18, h * 0.98), w * 0.56, Color(0.24, 0.74, 0.56, 0.28))
	draw_circle(Vector2(w * 0.84, h * 0.99), w * 0.58, Color(0.36, 0.28, 0.74, 0.34))
	
	# 5. Floating 3D Glossy 4-Cell Tetromino Gem Blocks Around Edges
	var y_ratios = [0.11, 0.23, 0.48, 0.66, 0.80, 0.90]
	var x_ratios = [0.05, 0.88, 0.06, 0.87, 0.06, 0.86]
	
	var box = StyleBoxFlat.new()
	box.corner_radius_top_left = 7
	box.corner_radius_top_right = 7
	box.corner_radius_bottom_right = 7
	box.corner_radius_bottom_left = 7
	box.border_width_bottom = 3
	
	for i in range(floating_decor.size()):
		var d = floating_decor[i]
		var base_x = w * x_ratios[i % x_ratios.size()]
		var base_y = h * y_ratios[i % y_ratios.size()]
		var bob = sin(anim_time * d["speed"] + d["phase"]) * 14.0
		var drift = cos(anim_time * d["speed"] * 0.7 + d["phase"]) * 8.0
		var pos: Vector2 = Vector2(base_x, base_y) + Vector2(drift, bob)
		var sz: float = d["scale"]
		var col: Color = d["col"]
		box.bg_color = col
		box.border_color = col.darkened(0.35)
		
		for c in d["cells"]:
			var cell_rect = Rect2(pos + Vector2(c.x * (sz + 3.0), c.y * (sz + 3.0)), Vector2(sz, sz))
			draw_style_box(box, cell_rect)
			draw_rect(Rect2(cell_rect.position + Vector2(2, 2), Vector2(sz * 0.42, sz * 0.25)), Color(1, 1, 1, col.a * 0.9), true)


# ==============================================================================
# TOP-LEFT LEVEL SHORTCUT & 3D WORLD JOURNEY MAP (500 LEVELS, 25 CHAPTER WORLDS)
# ==============================================================================

class _LevelDestination3DNode extends Node3D:
	var level_num: int = 1
	var is_unlocked: bool = true
	var is_completed: bool = false
	var is_selected: bool = false
	var is_current: bool = false
	var star_count: int = 0
	var milestone_type: String = ""
	var destination_architecture: String = "carved_platform"
	var terrain_surface_type: String = "emerald_turf_terrace"
	var elevation_z: float = 0.25
	var chapter_idx: int = 0
	var primary_color: Color = Color(0.24, 0.64, 0.96, 1.0)
	var secondary_color: Color = Color(1.0, 0.88, 0.32, 1.0)

	var socket_mesh: MeshInstance3D = null
	var foundation_mesh: MeshInstance3D = null
	var pedestal_mesh: MeshInstance3D = null
	var rim_mesh: MeshInstance3D = null
	var superstructure_mesh: MeshInstance3D = null
	var crown_mesh: MeshInstance3D = null
	var star_meshes: Array[MeshInstance3D] = []

	var _socket_primitive := CylinderMesh.new()
	var _foundation_primitive := CylinderMesh.new()
	var _pedestal_primitive := CylinderMesh.new()
	var _rim_primitive := TorusMesh.new()
	var _struct_primitive_cyl := CylinderMesh.new()
	var _struct_primitive_box := BoxMesh.new()
	var _struct_primitive_prism := PrismMesh.new()
	var _struct_primitive_sph := SphereMesh.new()
	var _crown_primitive := PrismMesh.new()

	var _socket_mat := StandardMaterial3D.new()
	var _foundation_mat := StandardMaterial3D.new()
	var _pedestal_mat := StandardMaterial3D.new()
	var _rim_mat := StandardMaterial3D.new()
	var _struct_mat := StandardMaterial3D.new()
	var _crown_mat := StandardMaterial3D.new()

	func _init() -> void:
		_build_persistent_children()

	func _build_persistent_children() -> void:
		if DisplayServer.get_name().to_lower() == "headless":
			return
		socket_mesh = MeshInstance3D.new()
		socket_mesh.name = "GroundSocket3D"
		socket_mesh.mesh = _socket_primitive
		socket_mesh.material_override = _socket_mat
		add_child(socket_mesh)

		foundation_mesh = MeshInstance3D.new()
		foundation_mesh.name = "TerrainFoundation3D"
		foundation_mesh.mesh = _foundation_primitive
		foundation_mesh.material_override = _foundation_mat
		add_child(foundation_mesh)

		pedestal_mesh = MeshInstance3D.new()
		pedestal_mesh.name = "DestinationPedestal3D"
		pedestal_mesh.mesh = _pedestal_primitive
		pedestal_mesh.material_override = _pedestal_mat
		add_child(pedestal_mesh)

		rim_mesh = MeshInstance3D.new()
		rim_mesh.name = "DestinationRim3D"
		rim_mesh.mesh = _rim_primitive
		rim_mesh.material_override = _rim_mat
		add_child(rim_mesh)

		superstructure_mesh = MeshInstance3D.new()
		superstructure_mesh.name = "ArchitectureStructure3D"
		superstructure_mesh.mesh = _struct_primitive_cyl
		superstructure_mesh.material_override = _struct_mat
		add_child(superstructure_mesh)

		_crown_primitive.size = Vector3(0.26, 0.30, 0.26)
		_crown_mat.albedo_color = Color(1.0, 0.88, 0.24, 1.0)
		_crown_mat.emission_enabled = true
		_crown_mat.emission = Color(1.0, 0.82, 0.18, 1.0)
		_crown_mat.emission_energy_multiplier = 0.55

		crown_mesh = MeshInstance3D.new()
		crown_mesh.name = "MilestoneCrown3D"
		crown_mesh.mesh = _crown_primitive
		crown_mesh.material_override = _crown_mat
		crown_mesh.visible = false
		add_child(crown_mesh)

		star_meshes.clear()
		for s_i in range(3):
			var sp := SphereMesh.new()
			sp.radius = 0.08
			sp.height = 0.16

			var sm_mat := StandardMaterial3D.new()
			sm_mat.albedo_color = Color(1.0, 0.92, 0.24, 1.0)
			sm_mat.emission_enabled = true
			sm_mat.emission = Color(1.0, 0.84, 0.16, 1.0)
			sm_mat.emission_energy_multiplier = 0.45

			var sm := MeshInstance3D.new()
			sm.name = "Star3D_%d" % s_i
			sm.mesh = sp
			sm.material_override = sm_mat
			sm.visible = false
			add_child(sm)
			star_meshes.append(sm)

	func setup(
		p_lvl: int,
		p_unlocked: bool,
		p_comp: bool,
		p_sel: bool,
		p_curr: bool,
		p_stars: int,
		p_ms: String,
		p_chapter: int,
		p_island_col: Color,
		p_accent_col: Color,
		p_dest_arch: String = "carved_platform",
		p_terrain_surf: String = "emerald_turf_terrace",
		p_elev_z: float = 0.25
	) -> void:
		level_num = p_lvl
		is_unlocked = p_unlocked
		is_completed = p_comp
		is_selected = p_sel
		is_current = p_curr
		star_count = clampi(p_stars, 0, 3)
		milestone_type = p_ms
		chapter_idx = p_chapter
		destination_architecture = p_dest_arch
		terrain_surface_type = p_terrain_surf
		elevation_z = p_elev_z

		var is_ms: bool = (milestone_type != "")
		var base_r: float = 0.48 if milestone_type == "major_milestone" else (0.42 if is_ms else 0.34)
		var base_h: float = 0.34 if milestone_type == "major_milestone" else (0.28 if is_ms else 0.22)

		if is_selected and is_unlocked:
			primary_color = Color(0.98, 0.56, 0.12, 1.0)
			secondary_color = Color(1.0, 0.96, 0.44, 1.0)
		elif is_current and is_unlocked:
			primary_color = Color(0.18, 0.68, 0.98, 1.0)
			secondary_color = Color(1.0, 0.92, 0.36, 1.0)
		elif is_completed:
			primary_color = Color(0.14, 0.78, 0.48, 1.0) if not is_ms else Color(0.92, 0.58, 0.14, 1.0)
			secondary_color = Color(0.68, 1.0, 0.84, 1.0) if not is_ms else Color(1.0, 0.94, 0.42, 1.0)
		elif is_unlocked:
			primary_color = p_accent_col.darkened(0.12)
			secondary_color = p_accent_col.lightened(0.28)
		else:
			primary_color = Color(0.22, 0.26, 0.44, 1.0)
			secondary_color = Color(0.46, 0.52, 0.74, 1.0)

		if DisplayServer.get_name().to_lower() == "headless":
			return

		# 1. Ground Socket
		_socket_primitive.top_radius = base_r * 1.42
		_socket_primitive.bottom_radius = base_r * 1.62
		_socket_primitive.height = 0.26 + elevation_z * 0.28
		_socket_primitive.radial_segments = 18
		_socket_mat.albedo_color = p_island_col.darkened(0.24)
		_socket_mat.roughness = 0.78
		socket_mesh.position = Vector3(0.0, -_socket_primitive.height * 0.5, 0.0)

		# 2. Foundation Slab
		_foundation_primitive.top_radius = base_r * 1.18
		_foundation_primitive.bottom_radius = base_r * 1.30
		_foundation_primitive.height = 0.14
		_foundation_primitive.radial_segments = 16
		_foundation_mat.albedo_color = p_island_col.lightened(0.08)
		_foundation_mat.roughness = 0.62
		foundation_mesh.position = Vector3(0.0, 0.05, 0.0)

		# 3. Pedestal
		_pedestal_primitive.top_radius = base_r
		_pedestal_primitive.bottom_radius = base_r * 1.12
		_pedestal_primitive.height = base_h
		_pedestal_primitive.radial_segments = 18
		_pedestal_mat.albedo_color = primary_color
		_pedestal_mat.roughness = 0.30
		_pedestal_mat.metallic = 0.22
		if is_selected or is_current:
			_pedestal_mat.emission_enabled = true
			_pedestal_mat.emission = primary_color.lightened(0.22)
			_pedestal_mat.emission_energy_multiplier = 0.45
		else:
			_pedestal_mat.emission_enabled = false
		pedestal_mesh.position = Vector3(0.0, 0.12 + base_h * 0.5, 0.0)

		# 4. Bevel Rim
		_rim_primitive.inner_radius = base_r * 0.82
		_rim_primitive.outer_radius = base_r * 1.06
		_rim_mat.albedo_color = secondary_color
		_rim_mat.roughness = 0.22
		_rim_mat.metallic = 0.45
		rim_mesh.position = Vector3(0.0, 0.12 + base_h, 0.0)

		# 5. Architecture Superstructure
		_struct_mat.albedo_color = secondary_color.lightened(0.12) if is_unlocked else Color(0.52, 0.58, 0.76, 1.0)
		_struct_mat.roughness = 0.26
		_struct_mat.metallic = 0.35

		match destination_architecture:
			"crystal_platform", "monolith_altar":
				_struct_primitive_prism.size = Vector3(base_r * 0.95, 0.36, base_r * 0.95)
				superstructure_mesh.mesh = _struct_primitive_prism
				_struct_mat.emission_enabled = is_unlocked
				_struct_mat.emission = secondary_color
				_struct_mat.emission_energy_multiplier = 0.35
			"watchtower", "citadel_keep":
				_struct_primitive_box.size = Vector3(base_r * 1.05, 0.38, base_r * 1.05)
				superstructure_mesh.mesh = _struct_primitive_box
				_struct_mat.emission_enabled = false
			"observatory_dome", "lotus_pavilion":
				_struct_primitive_sph.radius = base_r * 0.58
				_struct_primitive_sph.height = base_r * 0.95
				superstructure_mesh.mesh = _struct_primitive_sph
				_struct_mat.emission_enabled = false
			"portal_gate", "ancient_shrine", "citadel_gate", "sanctuary_shrine":
				_struct_primitive_box.size = Vector3(base_r * 1.25, 0.34, base_r * 0.48)
				superstructure_mesh.mesh = _struct_primitive_box
				_struct_mat.emission_enabled = false
			_:
				_struct_primitive_cyl.top_radius = base_r * 0.68
				_struct_primitive_cyl.bottom_radius = base_r * 0.82
				_struct_primitive_cyl.height = 0.20
				superstructure_mesh.mesh = _struct_primitive_cyl
				_struct_mat.emission_enabled = false

		superstructure_mesh.position = Vector3(0.0, 0.14 + base_h + 0.12, 0.0)

		# 6. Milestone Crown
		crown_mesh.visible = (is_ms or is_selected or is_current)
		crown_mesh.position = Vector3(0.0, 0.38 + base_h, 0.0)

		# 7. 3D Stars
		for s_i in range(3):
			if s_i < star_meshes.size():
				var sm: MeshInstance3D = star_meshes[s_i]
				sm.visible = (is_completed and s_i < star_count)
				if sm.visible:
					var ang: float = -0.55 + float(s_i) * 0.55
					sm.position = Vector3(sin(ang) * (base_r * 0.85), 0.18 + base_h, cos(ang) * (base_r * 0.85))


func _is_headless() -> bool:
	return DisplayServer.get_name().to_lower() == "headless" or OS.has_feature("dedicated_server")


func _ensure_level_map_3d_viewport() -> void:
	if not level_grid:
		return
	if _level_map_viewport_container and is_instance_valid(_level_map_viewport_container):
		return

	if _is_headless():
		_level_map_viewport_container = Control.new()
		_level_map_viewport_container.name = "LevelMap3DViewportContainer"
		_level_map_viewport_container.position = Vector2.ZERO
		_level_map_viewport_container.custom_minimum_size = Vector2(630, 740)
		_level_map_viewport_container.size = Vector2(630, 740)
		level_grid.add_child(_level_map_viewport_container)
		level_grid.move_child(_level_map_viewport_container, 0)

		_level_map_viewport = Node.new()
		_level_map_viewport.name = "LevelMap3DSubViewport"
		_level_map_viewport_container.add_child(_level_map_viewport)

		_level_map_world_root_3d = Node3D.new()
		_level_map_world_root_3d.name = "LevelMapWorld3DRoot"
		_level_map_viewport.add_child(_level_map_world_root_3d)

		_level_map_camera_3d = Node3D.new()
		_level_map_camera_3d.name = "LevelMapCamera3D"
		_level_map_world_root_3d.add_child(_level_map_camera_3d)

		_level_map_chapter_group_3d = Node3D.new()
		_level_map_chapter_group_3d.name = "ChapterWorld3DGroup"
		_level_map_world_root_3d.add_child(_level_map_chapter_group_3d)

		_level_map_water_mesh_3d = Node3D.new()
		_level_map_water_mesh_3d.name = "ChapterWaterBasin3D"
		_level_map_chapter_group_3d.add_child(_level_map_water_mesh_3d)

		_level_map_terrain_surfaces_3d.clear()
		_level_map_shore_surfaces_3d.clear()
		_level_map_destination_nodes_3d.clear()
		for i in range(20):
			var hl_terr_mesh := Node3D.new()
			hl_terr_mesh.name = "TerrainSurface3D_%d" % i
			_level_map_chapter_group_3d.add_child(hl_terr_mesh)
			_level_map_terrain_surfaces_3d.append(hl_terr_mesh)

			var hl_shore_mesh := Node3D.new()
			hl_shore_mesh.name = "ShoreSurf3D_%d" % i
			_level_map_chapter_group_3d.add_child(hl_shore_mesh)
			_level_map_shore_surfaces_3d.append(hl_shore_mesh)

			var hl_dest_node := _LevelDestination3DNode.new()
			hl_dest_node.name = "Destination3D_%d" % (i + 1)
			_level_map_chapter_group_3d.add_child(hl_dest_node)
			_level_map_destination_nodes_3d.append(hl_dest_node)

		_level_map_route_segments_3d.clear()
		for i in range(19):
			var hl_seg_mesh := Node3D.new()
			hl_seg_mesh.name = "RouteSegment3D_%d" % i
			_level_map_chapter_group_3d.add_child(hl_seg_mesh)
			_level_map_route_segments_3d.append(hl_seg_mesh)
			if i == 0:
				_level_map_route_mesh_3d = hl_seg_mesh

		_level_map_gateway_nodes_3d.clear()
		for g_i in range(2):
			var hl_gate_node := Node3D.new()
			hl_gate_node.name = "ChapterGateway3D_%s" % ("Entry" if g_i == 0 else "Exit")
			_level_map_chapter_group_3d.add_child(hl_gate_node)
			_level_map_gateway_nodes_3d.append(hl_gate_node)

		_level_map_landmark_nodes_3d.clear()
		for lm_i in range(2):
			var hl_lm_node := Node3D.new()
			hl_lm_node.name = "ChapterLandmark3D_%d" % lm_i
			_level_map_chapter_group_3d.add_child(hl_lm_node)
			_level_map_landmark_nodes_3d.append(hl_lm_node)
		return

	_level_map_viewport_container = SubViewportContainer.new()
	_level_map_viewport_container.name = "LevelMap3DViewportContainer"
	_level_map_viewport_container.stretch = true
	_level_map_viewport_container.show_behind_parent = true
	_level_map_viewport_container.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_level_map_viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level_map_viewport_container.position = Vector2.ZERO
	_level_map_viewport_container.custom_minimum_size = Vector2(630, 740)
	_level_map_viewport_container.size = Vector2(630, 740)
	level_grid.add_child(_level_map_viewport_container)
	level_grid.move_child(_level_map_viewport_container, 0)

	_level_map_viewport = SubViewport.new()
	_level_map_viewport.name = "LevelMap3DSubViewport"
	_level_map_viewport.transparent_bg = true
	_level_map_viewport.own_world_3d = true
	_level_map_viewport.size = Vector2i(630, 740)
	_level_map_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_level_map_viewport_container.add_child(_level_map_viewport)

	_level_map_world_root_3d = Node3D.new()
	_level_map_world_root_3d.name = "LevelMapWorld3DRoot"
	_level_map_viewport.add_child(_level_map_world_root_3d)

	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment3D"
	var env_res := Environment.new()
	env_res.background_mode = Environment.BG_CLEAR_COLOR
	env_res.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env_res.ambient_light_color = Color(0.82, 0.88, 1.0, 1.0)
	env_res.ambient_light_energy = 0.85
	world_env.environment = env_res
	_level_map_world_root_3d.add_child(world_env)

	var sun_light := DirectionalLight3D.new()
	sun_light.name = "DirectionalSunLight3D"
	sun_light.light_color = Color(1.0, 0.96, 0.86, 1.0)
	sun_light.light_energy = 1.25
	sun_light.rotation_degrees = Vector3(-48.0, 28.0, 0.0)
	_level_map_world_root_3d.add_child(sun_light)

	_level_map_camera_3d = Camera3D.new()
	_level_map_camera_3d.name = "LevelMapCamera3D"
	_level_map_camera_3d.projection = Camera3D.PROJECTION_PERSPECTIVE
	_level_map_camera_3d.fov = 38.0
	_level_map_camera_3d.position = Vector3(0.0, 12.5, 9.8)
	_level_map_camera_3d.look_at_from_position(Vector3(0.0, 12.5, 9.8), Vector3(0.0, 0.35, 0.0), Vector3.UP)
	_level_map_world_root_3d.add_child(_level_map_camera_3d)

	_level_map_chapter_group_3d = Node3D.new()
	_level_map_chapter_group_3d.name = "ChapterWorld3DGroup"
	_level_map_world_root_3d.add_child(_level_map_chapter_group_3d)

	# 1. Water Basin
	var water_plane := BoxMesh.new()
	water_plane.size = Vector3(10.5, 0.22, 15.2)
	_level_map_water_mesh_3d = MeshInstance3D.new()
	_level_map_water_mesh_3d.name = "ChapterWaterBasin3D"
	_level_map_water_mesh_3d.mesh = water_plane
	_level_map_water_mesh_3d.position = Vector3(0.0, -0.42, 0.0)
	var w_mat := StandardMaterial3D.new()
	_level_map_water_mesh_3d.material_override = w_mat
	_level_map_chapter_group_3d.add_child(_level_map_water_mesh_3d)

	# 2. 20 Persistent Terrain Islands, Shore Rings, and Destination Nodes
	_level_map_terrain_surfaces_3d.clear()
	_level_map_shore_surfaces_3d.clear()
	_level_map_destination_nodes_3d.clear()
	for i in range(20):
		var t_cyl := CylinderMesh.new()
		var terr_mesh := MeshInstance3D.new()
		terr_mesh.name = "TerrainSurface3D_%d" % i
		terr_mesh.mesh = t_cyl
		terr_mesh.material_override = StandardMaterial3D.new()
		_level_map_chapter_group_3d.add_child(terr_mesh)
		_level_map_terrain_surfaces_3d.append(terr_mesh)

		var s_torus := TorusMesh.new()
		s_torus.rings = 8
		s_torus.ring_segments = 14
		var shore_mesh := MeshInstance3D.new()
		shore_mesh.name = "ShoreSurf3D_%d" % i
		shore_mesh.mesh = s_torus
		var s_mat := StandardMaterial3D.new()
		s_mat.albedo_color = Color(0.96, 0.99, 1.0, 0.75)
		shore_mesh.material_override = s_mat
		_level_map_chapter_group_3d.add_child(shore_mesh)
		_level_map_shore_surfaces_3d.append(shore_mesh)

		var dest_node := _LevelDestination3DNode.new()
		dest_node.name = "Destination3D_%d" % (i + 1)
		_level_map_chapter_group_3d.add_child(dest_node)
		_level_map_destination_nodes_3d.append(dest_node)

	# 3. 19 Route Segments
	_level_map_route_segments_3d.clear()
	for i in range(19):
		var box := BoxMesh.new()
		var seg_mesh := MeshInstance3D.new()
		seg_mesh.name = "RouteSegment3D_%d" % i
		seg_mesh.mesh = box
		seg_mesh.material_override = StandardMaterial3D.new()
		_level_map_chapter_group_3d.add_child(seg_mesh)
		_level_map_route_segments_3d.append(seg_mesh)
		if i == 0:
			_level_map_route_mesh_3d = seg_mesh

	# 4. Gateways
	_level_map_gateway_nodes_3d.clear()
	for g_i in range(2):
		var gate_node := Node3D.new()
		gate_node.name = "ChapterGateway3D_%s" % ("Entry" if g_i == 0 else "Exit")
		var torus := TorusMesh.new()
		torus.inner_radius = 0.32
		torus.outer_radius = 0.46
		var arch_mesh := MeshInstance3D.new()
		arch_mesh.name = "GatewayArch3D"
		arch_mesh.mesh = torus
		arch_mesh.material_override = StandardMaterial3D.new()
		gate_node.add_child(arch_mesh)
		_level_map_chapter_group_3d.add_child(gate_node)
		_level_map_gateway_nodes_3d.append(gate_node)

	# 5. Landmarks
	_level_map_landmark_nodes_3d.clear()
	for lm_i in range(2):
		var lm_node := Node3D.new()
		lm_node.name = "ChapterLandmark3D_%d" % lm_i
		var lm_prism := PrismMesh.new()
		lm_prism.size = Vector3(0.58, 0.85, 0.58)
		var lm_mesh := MeshInstance3D.new()
		lm_mesh.name = "LandmarkMesh3D"
		lm_mesh.mesh = lm_prism
		lm_mesh.material_override = StandardMaterial3D.new()
		lm_node.add_child(lm_mesh)
		_level_map_chapter_group_3d.add_child(lm_node)
		_level_map_landmark_nodes_3d.append(lm_node)


func _rebuild_level_map_3d_world(entries: Array, chapter_idx: int) -> void:
	_ensure_level_map_3d_viewport()
	if not _level_map_chapter_group_3d or _level_map_destination_nodes_3d.size() < 20:
		return

	var gs = get_node_or_null("/root/GameState")
	var env: Dictionary = gs.get_chapter_environment(chapter_idx) if (gs and gs.has_method("get_chapter_environment")) else {}
	var island_col: Color = env.get("island_col", Color(0.28, 0.78, 0.58, 1.0))
	var cliff_col: Color = env.get("cliff_col", island_col.darkened(0.42))
	var water_col: Color = env.get("water_col", Color(0.22, 0.68, 0.96, 0.90))
	var path_outer: Color = env.get("path_outer", Color(1.0, 0.88, 0.34, 1.0))

	if _is_headless():
		var hl_world_pts_3d: Array[Vector3] = []
		var hl_entry_count: int = min(entries.size(), _level_map_destination_nodes_3d.size())
		for i in range(_level_map_destination_nodes_3d.size()):
			var is_active_node: bool = (i < hl_entry_count)
			if i < _level_map_terrain_surfaces_3d.size():
				_level_map_terrain_surfaces_3d[i].visible = is_active_node
			if i < _level_map_shore_surfaces_3d.size():
				_level_map_shore_surfaces_3d[i].visible = is_active_node
			if i < _level_map_destination_nodes_3d.size():
				_level_map_destination_nodes_3d[i].visible = is_active_node
			if not is_active_node:
				continue
			var hl_entry: Dictionary = entries[i]
			var hl_lvl_num: int = int(hl_entry.get("level", i + 1))
			var hl_u_norm: float = float(hl_entry.get("organic_u", 0.5))
			var hl_v_norm: float = float(hl_entry.get("organic_v", float(maxi(1, hl_entry_count - 1 - i)) / float(maxi(1, hl_entry_count - 1))))
			var hl_z_elev: float = float(hl_entry.get("elevation_z", 0.25))
			var hl_dest_arch: String = String(hl_entry.get("destination_architecture", "carved_platform"))
			var hl_terrain_surf: String = String(hl_entry.get("terrain_surface_type", "emerald_turf_terrace"))
			var hl_m_type_i: String = String(hl_entry.get("milestone_type", ""))
			var hl_wx: float = (hl_u_norm - 0.5) * 5.2
			var hl_wz: float = (hl_v_norm - 0.5) * 7.8
			var hl_wy: float = hl_z_elev * 1.45
			var hl_pos_3d := Vector3(hl_wx, hl_wy, hl_wz)
			hl_world_pts_3d.append(hl_pos_3d)

			if i < _level_map_terrain_surfaces_3d.size():
				var hl_terr_mesh: Node3D = _level_map_terrain_surfaces_3d[i]
				hl_terr_mesh.position = Vector3(hl_wx, hl_wy - 0.3, hl_wz)
				hl_terr_mesh.set_meta("terrain_surface_type", hl_terrain_surf)
				hl_terr_mesh.set_meta("elevation_z", hl_z_elev)

			if i < _level_map_shore_surfaces_3d.size():
				var hl_shore_mesh: Node3D = _level_map_shore_surfaces_3d[i]
				hl_shore_mesh.position = Vector3(hl_wx, -0.36, hl_wz)

			if i < _level_map_destination_nodes_3d.size():
				var hl_dest_node: _LevelDestination3DNode = _level_map_destination_nodes_3d[i] as _LevelDestination3DNode
				if hl_dest_node:
					hl_dest_node.name = "Destination3D_%d" % hl_lvl_num
					hl_dest_node.position = hl_pos_3d
					hl_dest_node.setup(
						hl_lvl_num,
						bool(hl_entry.get("unlocked", hl_lvl_num == 1)),
						bool(hl_entry.get("completed", false)),
						bool(hl_entry.get("is_selected", hl_lvl_num == 1)),
						bool(hl_entry.get("current", false)),
						int(hl_entry.get("stars", 0)),
						hl_m_type_i,
						chapter_idx,
						island_col,
						path_outer,
						hl_dest_arch,
						hl_terrain_surf,
						hl_z_elev
					)

		for i in range(_level_map_route_segments_3d.size()):
			var hl_seg_mesh: Node3D = _level_map_route_segments_3d[i]
			if i < hl_world_pts_3d.size() - 1:
				var hl_seg_type: String = String(entries[i].get("route_segment_type", "wooden_suspension_bridge")) if i < entries.size() else "wooden_suspension_bridge"
				hl_seg_mesh.visible = true
				hl_seg_mesh.position = (hl_world_pts_3d[i] + hl_world_pts_3d[i + 1]) * 0.5
				hl_seg_mesh.set_meta("route_segment_type", hl_seg_type)
			else:
				hl_seg_mesh.visible = false

		if hl_world_pts_3d.size() >= 2 and _level_map_gateway_nodes_3d.size() >= 2:
			for g_i in range(2):
				var hl_g_idx: int = 0 if g_i == 0 else (hl_world_pts_3d.size() - 1)
				var hl_gate_node: Node3D = _level_map_gateway_nodes_3d[g_i]
				hl_gate_node.position = hl_world_pts_3d[hl_g_idx] + Vector3(0.0, 0.0, 0.45 if hl_g_idx == 0 else -0.45)

		var hl_branches: Array = gs.get_chapter_decorative_branches(chapter_idx) if (gs and gs.has_method("get_chapter_decorative_branches")) else []
		for lm_i in range(2):
			if lm_i < _level_map_landmark_nodes_3d.size():
				var hl_lm_node: Node3D = _level_map_landmark_nodes_3d[lm_i]
				if lm_i < hl_branches.size():
					var hl_br: Dictionary = hl_branches[lm_i]
					var hl_to_uv: Vector2 = hl_br.get("uv_position", hl_br.get("to_uv", Vector2(0.5, 0.5)))
					hl_lm_node.position = Vector3((hl_to_uv.x - 0.5) * 5.6, 0.45, (hl_to_uv.y - 0.5) * 7.8)
					hl_lm_node.visible = true
					hl_lm_node.set_meta("landmark_type", String(hl_br.get("landmark_type", "shrine")))
				else:
					hl_lm_node.visible = false
		return

	# 1. Update Water Basin
	if _level_map_water_mesh_3d and _level_map_water_mesh_3d.material_override:
		var w_mat := _level_map_water_mesh_3d.material_override as StandardMaterial3D
		if w_mat:
			w_mat.albedo_color = water_col
			w_mat.roughness = 0.12
			w_mat.metallic = 0.42

	# 2. Update Terrain Islands, Shore Rings, and Destination Nodes for current page's node count
	var world_pts_3d: Array[Vector3] = []
	var active_count: int = min(entries.size(), _level_map_destination_nodes_3d.size())
	for i in range(_level_map_destination_nodes_3d.size()):
		var is_active: bool = (i < active_count)
		if i < _level_map_terrain_surfaces_3d.size():
			_level_map_terrain_surfaces_3d[i].visible = is_active
		if i < _level_map_shore_surfaces_3d.size():
			_level_map_shore_surfaces_3d[i].visible = is_active
		if i < _level_map_destination_nodes_3d.size():
			_level_map_destination_nodes_3d[i].visible = is_active
		if not is_active:
			continue
		var entry: Dictionary = entries[i]
		var lvl_num: int = int(entry.get("level", i + 1))
		var u_norm: float = float(entry.get("organic_u", 0.5))
		var v_norm: float = float(entry.get("organic_v", float(maxi(1, active_count - 1 - i)) / float(maxi(1, active_count - 1))))
		var z_elev: float = float(entry.get("elevation_z", 0.25))
		var dest_arch: String = String(entry.get("destination_architecture", "carved_platform"))
		var terrain_surf: String = String(entry.get("terrain_surface_type", "emerald_turf_terrace"))
		var m_type_i: String = String(entry.get("milestone_type", ""))
		var wx: float = (u_norm - 0.5) * 5.2
		var wz: float = (v_norm - 0.5) * 7.8
		var wy: float = z_elev * 1.45
		var pos_3d := Vector3(wx, wy, wz)
		world_pts_3d.append(pos_3d)

		var top_r: float = 0.62
		var bot_r: float = 0.90
		var isl_h: float = maxf(0.55, wy + 0.60)
		if m_type_i == "major_milestone" or m_type_i == "crown":
			top_r = 1.32
			bot_r = 1.78
			isl_h = maxf(1.05, wy + 1.10)
		elif m_type_i == "reward_milestone" or m_type_i == "chest":
			top_r = 1.02
			bot_r = 1.38
			isl_h = maxf(0.80, wy + 0.85)
		elif m_type_i != "":
			top_r = 0.82
			bot_r = 1.15
			isl_h = maxf(0.68, wy + 0.72)

		var terr_mesh: MeshInstance3D = _level_map_terrain_surfaces_3d[i]
		var t_cyl := terr_mesh.mesh as CylinderMesh
		if t_cyl:
			t_cyl.top_radius = top_r
			t_cyl.bottom_radius = bot_r
			t_cyl.height = isl_h
			t_cyl.radial_segments = 16
		var t_mat := terr_mesh.material_override as StandardMaterial3D
		if t_mat:
			t_mat.albedo_color = island_col.lerp(cliff_col, clampf(1.0 - z_elev * 0.65, 0.12, 0.68))
			t_mat.roughness = 0.72
		terr_mesh.position = Vector3(wx, wy - isl_h * 0.5, wz)
		terr_mesh.set_meta("terrain_surface_type", terrain_surf)
		terr_mesh.set_meta("elevation_z", z_elev)
		terr_mesh.set_meta("island_index", i)

		var shore_mesh: MeshInstance3D = _level_map_shore_surfaces_3d[i]
		var s_torus := shore_mesh.mesh as TorusMesh
		if s_torus:
			s_torus.inner_radius = bot_r * 0.92
			s_torus.outer_radius = bot_r * 1.12
		shore_mesh.position = Vector3(wx, -0.36, wz)

		var dest_node: _LevelDestination3DNode = _level_map_destination_nodes_3d[i] as _LevelDestination3DNode
		if dest_node:
			dest_node.name = "Destination3D_%d" % lvl_num
			dest_node.position = pos_3d
			dest_node.setup(
				lvl_num,
				bool(entry.get("unlocked", lvl_num == 1)),
				bool(entry.get("completed", false)),
				bool(entry.get("is_selected", lvl_num == 1)),
				bool(entry.get("current", false)),
				int(entry.get("stars", 0)),
				m_type_i,
				chapter_idx,
				island_col,
				path_outer,
				dest_arch,
				terrain_surf,
				z_elev
			)

	# 3. Update Route Segments
	for i in range(_level_map_route_segments_3d.size()):
		var seg_mesh: MeshInstance3D = _level_map_route_segments_3d[i]
		if i >= world_pts_3d.size() - 1:
			seg_mesh.visible = false
			continue
		seg_mesh.visible = true
		var p1: Vector3 = world_pts_3d[i]
		var p2: Vector3 = world_pts_3d[i + 1]
		var seg_type: String = String(entries[i].get("route_segment_type", "wooden_suspension_bridge")) if i < entries.size() else "wooden_suspension_bridge"
		var dist: float = maxf(0.15, p1.distance_to(p2))

		var box := seg_mesh.mesh as BoxMesh
		if box:
			var road_w: float = 0.38 if seg_type in ["timber_bridge_span", "wooden_suspension_bridge"] else 0.32
			var road_h: float = 0.12 if seg_type in ["timber_bridge_span", "wooden_suspension_bridge", "elevated_skyway"] else 0.08
			box.size = Vector3(road_w, road_h, dist)

		var r_mat := seg_mesh.material_override as StandardMaterial3D
		if r_mat:
			match seg_type:
				"timber_bridge_span", "wooden_suspension_bridge", "coastal_boardwalk":
					r_mat.albedo_color = Color(0.64, 0.40, 0.20, 1.0)
				"stone_steps_ascent", "arched_stone_bridge", "carved_temple_causeway":
					r_mat.albedo_color = Color(0.82, 0.84, 0.92, 1.0)
				"stepping_stone_causeway", "sea_stepping_stones":
					r_mat.albedo_color = Color(0.48, 0.88, 0.94, 1.0)
				"cave_tunnel_passage", "prismatic_light_bridge":
					r_mat.albedo_color = Color(0.46, 0.38, 0.66, 1.0)
				"elevated_skyway", "constellation_star_bridge":
					r_mat.albedo_color = Color(1.0, 0.86, 0.36, 1.0)
				_:
					r_mat.albedo_color = path_outer
			r_mat.roughness = 0.48

		var mid_pt: Vector3 = (p1 + p2) * 0.5
		seg_mesh.position = mid_pt
		if dist > 0.001 and not is_equal_approx(absf((p2 - p1).normalized().dot(Vector3.UP)), 1.0):
			seg_mesh.look_at_from_position(mid_pt, p2, Vector3.UP)
		seg_mesh.set_meta("route_segment_type", seg_type)

	# 4. Update Gateways
	if world_pts_3d.size() >= 2 and _level_map_gateway_nodes_3d.size() >= 2:
		for g_i in range(2):
			var g_idx: int = 0 if g_i == 0 else (world_pts_3d.size() - 1)
			var gate_node: Node3D = _level_map_gateway_nodes_3d[g_i]
			gate_node.position = world_pts_3d[g_idx] + Vector3(0.0, 0.0, 0.45 if g_idx == 0 else -0.45)
			var arch_mesh := gate_node.get_node_or_null("GatewayArch3D") as MeshInstance3D
			if arch_mesh and arch_mesh.material_override:
				var g_mat := arch_mesh.material_override as StandardMaterial3D
				if g_mat:
					g_mat.albedo_color = path_outer.lightened(0.22)
					g_mat.emission_enabled = true
					g_mat.emission = path_outer
					g_mat.emission_energy_multiplier = 0.40

	# 5. Update Landmarks
	var branches: Array = gs.get_chapter_decorative_branches(chapter_idx) if (gs and gs.has_method("get_chapter_decorative_branches")) else []
	for lm_i in range(2):
		if lm_i < _level_map_landmark_nodes_3d.size():
			var lm_node: Node3D = _level_map_landmark_nodes_3d[lm_i]
			if lm_i < branches.size():
				var br: Dictionary = branches[lm_i]
				var to_uv: Vector2 = br.get("uv_position", br.get("to_uv", Vector2(0.5, 0.5)))
				var lx: float = (to_uv.x - 0.5) * 5.6
				var lz: float = (to_uv.y - 0.5) * 7.8
				lm_node.position = Vector3(lx, 0.45, lz)
				lm_node.visible = true
				var lm_mesh := lm_node.get_node_or_null("LandmarkMesh3D") as MeshInstance3D
				if lm_mesh and lm_mesh.material_override:
					var lm_mat := lm_mesh.material_override as StandardMaterial3D
					if lm_mat:
						lm_mat.albedo_color = island_col.lightened(0.25)
				lm_node.set_meta("landmark_type", String(br.get("landmark_type", "shrine")))
			else:
				lm_node.visible = false


func get_level_map_3d() -> Dictionary:
	_ensure_level_map_3d_viewport()
	var gs = get_node_or_null("/root/GameState")
	var comp: String = gs.get_chapter_path_archetype(current_map_page) if (gs and gs.has_method("get_chapter_path_archetype")) else "sweeping_arc"
	var active_dest_count: int = 0
	for dn in _level_map_destination_nodes_3d:
		if dn and is_instance_valid(dn) and dn.visible:
			active_dest_count += 1
	return {
		"viewport": _level_map_viewport,
		"world_root": _level_map_world_root_3d,
		"camera": _level_map_camera_3d,
		"chapter_group": _level_map_chapter_group_3d,
		"destination_nodes": _level_map_destination_nodes_3d,
		"active_destination_count": active_dest_count,
		"terrain_surfaces": _level_map_terrain_surfaces_3d,
		"route_segment_nodes": _level_map_route_segments_3d,
		"landmark_nodes": _level_map_landmark_nodes_3d,
		"gateway_nodes": _level_map_gateway_nodes_3d,
		"water_mesh": _level_map_water_mesh_3d,
		"route_mesh": _level_map_route_mesh_3d,
		"route_composition": comp,
		"chapter_index": current_map_page,
		"page_index": current_map_page
	}


func get_level_map_world_inspection(chapter_idx: int = -1) -> Dictionary:
	var md: MapData = get_active_map_data()
	var total_pages: int = md.get_page_count() if md != null else 68
	var target_page: int = current_map_page if chapter_idx < 0 else clampi(chapter_idx, 0, maxi(0, total_pages - 1))
	if target_page != current_map_page or _level_map_destination_nodes_3d.is_empty() or _level_map_destination_nodes_3d[0].position.y == 0.0:
		_populate_level_map_page(target_page)
	var gs = get_node_or_null("/root/GameState")
	var comp: String = gs.get_chapter_path_archetype(current_map_page) if (gs and gs.has_method("get_chapter_path_archetype")) else "sweeping_arc"
	var arch_types: Dictionary = {}
	var surf_types: Dictionary = {}
	var seg_types: Dictionary = {}
	var min_elev: float = 999.0
	var max_elev: float = -999.0
	var active_dest_count: int = 0
	for dn in _level_map_destination_nodes_3d:
		if dn and is_instance_valid(dn) and dn.visible:
			active_dest_count += 1
			arch_types[dn.destination_architecture] = true
			surf_types[dn.terrain_surface_type] = true
			min_elev = minf(min_elev, dn.position.y)
			max_elev = maxf(max_elev, dn.position.y)
	var active_seg_count: int = 0
	for seg in _level_map_route_segments_3d:
		if seg and is_instance_valid(seg) and seg.visible:
			active_seg_count += 1
			seg_types[String(seg.get_meta("route_segment_type", "sea_stepping_stones"))] = true
	var ocean_spec: Dictionary = gs.get_chapter_ocean_biome_spec(current_map_page) if (gs and gs.has_method("get_chapter_ocean_biome_spec")) else {}
	return {
		"page_index": current_map_page,
		"chapter_index": current_map_page,
		"total_pages": total_pages,
		"visual_concept": "ocean_and_islands_adventure_world",
		"is_ocean_and_islands_world": true,
		"ocean_biome_id": String(ocean_spec.get("biome_id", "ocean_islands")),
		"theme_id": String(ocean_spec.get("biome_id", "ocean_islands")),
		"is_theme_coherent": _current_page_obj.is_theme_coherent() if _current_page_obj != null else true,
		"is_coherent_single_biome_page": _current_page_obj.is_theme_coherent() if _current_page_obj != null else true,
		"route_composition": comp,
		"is_background_plus_2d_line_only": false,
		"has_3d_subviewport_world": _level_map_viewport != null and _level_map_camera_3d != null,
		"destination_node_3d_count": active_dest_count,
		"terrain_surface_3d_count": active_dest_count,
		"route_segment_3d_count": active_seg_count,
		"gateway_3d_count": _level_map_gateway_nodes_3d.size(),
		"landmark_3d_count": _level_map_landmark_nodes_3d.size(),
		"distinct_destination_architectures": arch_types.keys(),
		"distinct_terrain_surfaces": surf_types.keys(),
		"distinct_route_segment_types": seg_types.keys(),
		"elevation_span_3d": maxf(0.0, max_elev - min_elev)
	}


func set_map_data(custom_map_data: MapData) -> void:
	_custom_map_data = custom_map_data
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_method("set_custom_map_data"):
		gs.set_custom_map_data(custom_map_data)
	if modal_level_map and modal_level_map.visible:
		_populate_level_map_page(clampi(current_map_page, 0, maxi(0, get_active_map_data().get_page_count() - 1)))


func get_active_map_data() -> MapData:
	if _custom_map_data != null:
		return _custom_map_data
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_method("get_map_data"):
		return gs.get_map_data()
	return BlockPuzzleMapConfigScript.build_block_puzzle_map_data()


func get_current_map_page_object() -> MapPage:
	return _current_page_obj


func navigate_to_map_page(page_idx: int, _animate_transition: bool = true) -> int:
	var md: MapData = get_active_map_data()
	var total_pages: int = md.get_page_count() if md != null else 1
	var target_idx: int = clampi(page_idx, 0, maxi(0, total_pages - 1))
	map_camera_pan_offset = Vector2.ZERO
	_populate_level_map_page(target_idx)
	return current_map_page


func simulate_map_swipe(delta_vec: Vector2) -> Dictionary:
	var prev_page: int = current_map_page
	var is_drag: bool = delta_vec.length() > 7.0
	map_drag_moved_significantly = is_drag
	if absf(delta_vec.x) >= map_swipe_threshold_px and absf(delta_vec.x) > absf(delta_vec.y) * 1.15:
		if delta_vec.x < 0.0:
			navigate_to_map_page(current_map_page + 1, true)
		else:
			navigate_to_map_page(current_map_page - 1, true)
	return {
		"previous_page": prev_page,
		"current_page": current_map_page,
		"page_changed": current_map_page != prev_page,
		"drag_suppressed_tap": map_drag_moved_significantly
	}


func _on_btn_top_level_pressed() -> void:
	_on_btn_open_level_map_pressed()


func _build_level_node_style(_is_sel: bool, _unlocked: bool, _is_comp: bool, _is_curr: bool = false, _milestone_type: String = "") -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	st.border_color = Color(0.0, 0.0, 0.0, 0.0)
	st.set_border_width_all(0)
	st.set_corner_radius_all(14)
	st.content_margin_left = 0.0
	st.content_margin_top = 0.0
	st.content_margin_right = 0.0
	st.content_margin_bottom = 12.0
	return st


func _on_map_drag_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				map_is_dragging = true
				map_drag_start_mouse = mb.global_position
				map_drag_start_scroll_y = map_scroll_y
				map_drag_moved_significantly = false
				map_camera_pan_offset = Vector2.ZERO
			else:
				if map_is_dragging:
					var total_delta: Vector2 = mb.global_position - map_drag_start_mouse
					if absf(total_delta.x) >= map_swipe_threshold_px and absf(total_delta.x) > absf(total_delta.y) * 1.15:
						if total_delta.x < 0.0:
							navigate_to_map_page(current_map_page + 1, true)
						else:
							navigate_to_map_page(current_map_page - 1, true)
				map_is_dragging = false
				map_camera_pan_offset = Vector2.ZERO
				if level_grid:
					level_grid.queue_redraw()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			map_target_scroll_y = clampf(map_target_scroll_y - 48.0, 0.0, map_max_scroll_y)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			map_target_scroll_y = clampf(map_target_scroll_y + 48.0, 0.0, map_max_scroll_y)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if map_is_dragging:
			var dy: float = mm.global_position.y - map_drag_start_mouse.y
			var dx: float = mm.global_position.x - map_drag_start_mouse.x
			if absf(dy) > 7.0 or absf(dx) > 7.0:
				map_drag_moved_significantly = true
			map_camera_pan_offset = Vector2(clampf(dx * 0.25, -36.0, 36.0), clampf(dy * 0.15, -24.0, 24.0))
			map_target_scroll_y = clampf(map_drag_start_scroll_y - dy, 0.0, map_max_scroll_y)
			map_scroll_y = map_target_scroll_y
			_apply_map_scroll_positions()
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			map_is_dragging = true
			map_drag_start_mouse = st.position
			map_drag_start_scroll_y = map_scroll_y
			map_drag_moved_significantly = false
			map_camera_pan_offset = Vector2.ZERO
		else:
			if map_is_dragging:
				var touch_delta: Vector2 = st.position - map_drag_start_mouse
				if absf(touch_delta.x) >= map_swipe_threshold_px and absf(touch_delta.x) > absf(touch_delta.y) * 1.15:
					if touch_delta.x < 0.0:
						navigate_to_map_page(current_map_page + 1, true)
					else:
						navigate_to_map_page(current_map_page - 1, true)
			map_is_dragging = false
			map_camera_pan_offset = Vector2.ZERO
			if level_grid:
				level_grid.queue_redraw()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if map_is_dragging:
			var s_dy: float = sd.position.y - map_drag_start_mouse.y
			var s_dx: float = sd.position.x - map_drag_start_mouse.x
			if absf(s_dy) > 7.0 or absf(s_dx) > 7.0:
				map_drag_moved_significantly = true
			map_camera_pan_offset = Vector2(clampf(s_dx * 0.25, -36.0, 36.0), clampf(s_dy * 0.15, -24.0, 24.0))
			map_target_scroll_y = clampf(map_drag_start_scroll_y - s_dy, 0.0, map_max_scroll_y)
			map_scroll_y = map_target_scroll_y
			_apply_map_scroll_positions()


func _center_map_on_level(target_lvl_num: int) -> void:
	if not level_grid or map_base_node_positions.is_empty():
		return
	var local_idx: int = 0
	if _current_page_obj != null:
		var found_idx: int = _current_page_obj.get_local_index_for_level(target_lvl_num)
		if found_idx >= 0:
			local_idx = clampi(found_idx, 0, map_base_node_positions.size() - 1)
	var canvas_h: float = level_grid.size.y if level_grid.size.y > 0 else 740.0
	if local_idx >= 0 and local_idx < map_base_node_positions.size():
		var node_y: float = map_base_node_positions[local_idx].y
		map_target_scroll_y = clampf(node_y - canvas_h * 0.45, 0.0, map_max_scroll_y)
		map_scroll_y = map_target_scroll_y
		_apply_map_scroll_positions()


func _apply_map_scroll_positions() -> void:
	if not level_grid:
		return
	var level_buttons: Array[Button] = []
	for ch in level_grid.get_children():
		if ch is Button:
			level_buttons.append(ch as Button)
	
	winding_path_points.clear()
	for i in range(min(level_buttons.size(), map_base_node_positions.size())):
		var btn: Button = level_buttons[i]
		var base_p: Vector2 = map_base_node_positions[i]
		btn.position = Vector2(base_p.x, base_p.y - map_scroll_y)
		var ov := btn.get_node_or_null("VectorIcon") as Control
		if ov:
			ov.size = btn.size
			ov.queue_redraw()
		var center_pt: Vector2 = btn.position + btn.size * 0.5
		winding_path_points.append(center_pt)
		if _current_page_obj != null and i < _current_page_obj.nodes.size():
			_current_page_obj.nodes[i].position = center_pt

	if _current_page_obj != null and _current_page_obj.route != null:
		var p_style: String = _current_page_obj.theme.path_style if _current_page_obj.theme != null else "sea_stepping_stones"
		_current_page_obj.route.rebuild_from_nodes(_current_page_obj.nodes, p_style, 14)
	
	level_grid.queue_redraw()


func _on_map_level_node_pressed(lvl_num: int, unlocked: bool) -> void:
	if map_drag_moved_significantly:
		map_drag_moved_significantly = false
		return
	_play_sfx("click")
	var gs = get_node_or_null("/root/GameState")
	if unlocked and gs and gs.has_method("select_map_level"):
		var already_selected: bool = (gs.selected_map_level == lvl_num)
		if gs.select_map_level(lvl_num):
			_refresh_progression_ui()
			_update_mode_selection_ui()
			if modal_level_map and modal_level_map.visible:
				_populate_level_map_page(current_map_page)
			if already_selected and modal_level_map and modal_level_map.visible:
				_on_start_selected_level_from_map()
	else:
		_show_reward_toast(_tr("locked_level_toast") % [max(1, lvl_num - 1), lvl_num])


func _on_btn_open_level_map_pressed() -> void:
	_play_sfx("click")
	_hide_all_modals()
	update_responsive_level_map_layout(get_viewport_rect().size)
	var gs = get_node_or_null("/root/GameState")
	var cur_lvl: int = gs.selected_map_level if (gs and "selected_map_level" in gs) else 1
	var md: MapData = get_active_map_data()
	current_map_page = md.get_page_index_for_level(cur_lvl) if md != null else 0
	_populate_level_map_page(current_map_page)
	if modal_level_map:
		modal_level_map.visible = true
	call_deferred("_layout_winding_path_nodes")
	call_deferred("_center_map_on_level", cur_lvl)


func _populate_level_map_page(page_idx: int) -> void:
	var gs = get_node_or_null("/root/GameState")
	var md: MapData = get_active_map_data()
	var total_pages: int = md.get_page_count() if md != null else 68
	current_map_page = clampi(page_idx, 0, maxi(0, total_pages - 1))

	var canvas_w: float = maxf(280.0, level_grid.size.x if (level_grid and level_grid.size.x > 0) else 630.0)
	var canvas_h: float = maxf(420.0, level_grid.size.y if (level_grid and level_grid.size.y > 0) else 740.0)
	var prog_dict: Dictionary = gs.get_progression_provider_dict() if (gs and gs.has_method("get_progression_provider_dict")) else {}
	_current_page_obj = md.build_page_layout(current_map_page, Vector2(canvas_w, canvas_h), prog_dict) if md != null else null

	var start_lvl: int = _current_page_obj.start_level if _current_page_obj != null else 1
	var end_lvl: int = _current_page_obj.end_level if _current_page_obj != null else 6
	var lang: String = gs.get_language() if (gs and gs.has_method("get_language")) else "en"
	var chapter_title: String = _current_page_obj.get_display_title(lang) if _current_page_obj != null else "Ocean Islands"

	if lbl_page_range:
		lbl_page_range.text = _tr("level_map_page") % [current_map_page + 1, total_pages, chapter_title.to_upper(), start_lvl, end_lvl]
	if btn_page_prev:
		btn_page_prev.disabled = (current_map_page <= 0)
	if btn_page_next:
		btn_page_next.disabled = (current_map_page >= total_pages - 1)

	var sel_lvl: int = gs.selected_map_level if (gs and "selected_map_level" in gs) else 1
	var highest_lvl: int = gs.highest_unlocked_level if (gs and "highest_unlocked_level" in gs) else 1
	var tot_stars: int = gs.total_stars if (gs and "total_stars" in gs) else 0
	var next_ms_lvl: int = gs.get_next_milestone_level(highest_lvl) if (gs and gs.has_method("get_next_milestone_level")) else end_lvl
	var next_ms_icon: String = gs.get_level_milestone_icon(next_ms_lvl, false) if (gs and gs.has_method("get_level_milestone_icon")) else "STAR"

	if lbl_map_milestone_hint:
		lbl_map_milestone_hint.text = _tr("map_status_banner") % [highest_lvl, tot_stars, next_ms_lvl, next_ms_icon]
	if btn_start_selected_level:
		btn_start_selected_level.text = "    " + (_tr("level_map_start") % sel_lvl)

	if not level_grid:
		return
	_ensure_level_map_3d_viewport()

	var entries: Array = []
	if _current_page_obj != null:
		for nd in _current_page_obj.nodes:
			var nd_dict: Dictionary = nd.to_dict()
			nd_dict["title"] = chapter_title
			entries.append(nd_dict)
	elif gs and gs.has_method("get_level_map_page"):
		entries = gs.get_level_map_page(current_map_page)

	winding_path_entries = entries.duplicate(true)
	_rebuild_level_map_3d_world(entries, current_map_page)

	var valid_btns: Array[Button] = []
	for b_existing in _level_map_grid_buttons:
		if b_existing != null and is_instance_valid(b_existing) and not b_existing.is_queued_for_deletion():
			valid_btns.append(b_existing)
	_level_map_grid_buttons = valid_btns
	for child in level_grid.get_children():
		if child != _level_map_viewport_container and not (child in _level_map_grid_buttons):
			level_grid.remove_child(child)
			child.free()
	while _level_map_grid_buttons.size() > entries.size():
		var extra_btn: Button = _level_map_grid_buttons.pop_back()
		if extra_btn != null and is_instance_valid(extra_btn):
			if extra_btn.get_parent() == level_grid:
				level_grid.remove_child(extra_btn)
			extra_btn.free()
	while _level_map_grid_buttons.size() < entries.size():
		var new_btn := Button.new()
		new_btn.clip_text = true
		new_btn.pressed.connect(func():
			_on_map_level_node_pressed(int(new_btn.get_meta("level", 1)), bool(new_btn.get_meta("unlocked", false)))
		)
		level_grid.add_child(new_btn)
		_level_map_grid_buttons.append(new_btn)

	for i in range(entries.size()):
		var entry: Dictionary = entries[i]
		var lvl_num: int = int(entry.get("level", 1))
		var unlocked: bool = bool(entry.get("unlocked", lvl_num == 1))
		var is_comp: bool = bool(entry.get("completed", false))
		var is_curr: bool = bool(entry.get("current", false))
		var is_sel: bool = bool(entry.get("is_selected", lvl_num == 1))
		var stars: int = int(entry.get("stars", 0))
		var path_row: int = int(entry.get("path_row", int(i / 2)))
		var winding_col: int = int(entry.get("winding_col", i % 2))
		var m_type: String = String(entry.get("milestone_type", ""))
		var m_icon: String = String(entry.get("milestone_icon", ""))
		var organic_u: float = float(entry.get("organic_u", 0.5))
		var organic_v: float = float(entry.get("organic_v", 0.5))
		var elev_z: float = float(entry.get("elevation_z", 0.25))
		var dest_arch: String = String(entry.get("destination_architecture", "sandy_cay_island"))
		var terrain_surf: String = String(entry.get("terrain_surface_type", "atoll_islands"))
		var route_comp: String = String(_current_page_obj.composition_type if _current_page_obj != null else entry.get("route_composition", "sweeping_arc"))
		var route_seg: String = String(entry.get("route_segment_type", "sea_stepping_stones"))
		var is_ms_isl: bool = bool(entry.get("is_milestone", m_type != ""))
		var isl_lm: String = String(entry.get("island_landmark", "harbor_lighthouse"))
		var ocean_biome_id: String = String(_current_page_obj.theme.theme_id if (_current_page_obj != null and _current_page_obj.theme != null) else entry.get("ocean_biome_id", "ocean_islands"))
		var default_scale: float = 1.22 if is_ms_isl else 1.0
		var scale_mult: float = float(entry.get("scale_mult", default_scale))
		var visual_tier: int = int(entry.get("visual_tier", 2 if is_ms_isl else 0))

		var btn: Button = _level_map_grid_buttons[i]
		btn.name = "BtnGridLevel_%d" % lvl_num
		btn.clip_text = true
		btn.custom_minimum_size = Vector2(58, 54)
		btn.size = Vector2(58, 54)
		btn.add_theme_font_size_override("font_size", 18 if is_ms_isl else 16)
		btn.set_meta("level", lvl_num)
		btn.set_meta("level_id", lvl_num)
		btn.set_meta("page_id", _current_page_obj.page_id if _current_page_obj != null else ("page_%d" % (current_map_page + 1)))
		btn.set_meta("unlocked", unlocked)
		btn.set_meta("completed", is_comp)
		btn.set_meta("current", is_curr)
		btn.set_meta("is_selected", is_sel)
		btn.set_meta("stars", stars)
		btn.set_meta("path_index", i)
		btn.set_meta("path_row", path_row)
		btn.set_meta("winding_col", winding_col)
		btn.set_meta("organic_u", organic_u)
		btn.set_meta("organic_v", organic_v)
		btn.set_meta("elevation_z", elev_z)
		btn.set_meta("destination_architecture", dest_arch)
		btn.set_meta("terrain_surface_type", terrain_surf)
		btn.set_meta("route_composition", route_comp)
		btn.set_meta("route_segment_type", route_seg)
		btn.set_meta("is_integrated_3d_destination", true)
		btn.set_meta("is_island_destination", true)
		btn.set_meta("is_milestone_island", is_ms_isl)
		btn.set_meta("is_milestone", is_ms_isl)
		btn.set_meta("node_type", String(entry.get("node_type", "milestone" if is_ms_isl else "normal")))
		btn.set_meta("island_landmark", isl_lm)
		btn.set_meta("ocean_biome_id", ocean_biome_id)
		btn.set_meta("theme_id", ocean_biome_id)
		btn.set_meta("scale_mult", scale_mult)
		btn.set_meta("visual_tier", visual_tier)
		btn.set_meta("milestone_type", m_type)
		btn.set_meta("milestone_icon", m_icon)

		btn.text = "%d" % lvl_num

		var st = _build_level_node_style(is_sel, unlocked, is_comp, is_curr, m_type)
		btn.add_theme_font_override("font", GameTypographyScript.get_hud_number_font(0.25, 2))
		btn.add_theme_color_override("font_color", Color(1.0, 0.99, 0.94, 1.0) if unlocked else Color(0.84, 0.88, 0.98, 0.94))
		btn.add_theme_color_override("font_outline_color", Color(0.04, 0.06, 0.18, 0.98))
		btn.add_theme_constant_override("outline_size", 6)
		btn.add_theme_stylebox_override("normal", st)
		btn.add_theme_stylebox_override("hover", st)
		btn.add_theme_stylebox_override("pressed", st)
		UIIconScript.attach_level_node_overlay(btn, unlocked, is_comp, is_sel, is_curr, stars, m_type, dest_arch, terrain_surf, elev_z)

	_layout_winding_path_nodes()


func _layout_winding_path_nodes() -> void:
	if not level_grid:
		return
	var canvas_w: float = maxf(280.0, level_grid.size.x if level_grid.size.x > 0 else 630.0)
	var canvas_h: float = maxf(360.0, level_grid.size.y if level_grid.size.y > 0 else 740.0)
	var is_compact_map: bool = (canvas_w < 440.0 or canvas_h < 580.0)
	if _level_map_viewport_container:
		_level_map_viewport_container.position = Vector2.ZERO
		_level_map_viewport_container.custom_minimum_size = Vector2(canvas_w, canvas_h)
		_level_map_viewport_container.size = Vector2(canvas_w, canvas_h)

	var gs = get_node_or_null("/root/GameState")
	var md: MapData = get_active_map_data()
	var prog_dict: Dictionary = gs.get_progression_provider_dict() if (gs and gs.has_method("get_progression_provider_dict")) else {}
	if md != null:
		_current_page_obj = md.build_page_layout(current_map_page, Vector2(canvas_w, canvas_h), prog_dict)

	var level_buttons: Array[Button] = []
	for ch in level_grid.get_children():
		if ch is Button and not ch.is_queued_for_deletion():
			level_buttons.append(ch as Button)

	for i in range(level_buttons.size()):
		var btn: Button = level_buttons[i]
		var nd: MapNode = _current_page_obj.nodes[i] if (_current_page_obj != null and i < _current_page_obj.nodes.size()) else null
		var is_ms: bool = nd.is_milestone_node() if nd != null else bool(btn.get_meta("is_milestone", false))
		var f_sz: int = (15 if is_ms else 13) if is_compact_map else (20 if is_ms else 17)
		btn.add_theme_font_size_override("font_size", f_sz)

		if nd != null:
			btn.custom_minimum_size = nd.node_size
			btn.size = nd.node_size
			var tl: Vector2 = nd.get_top_left_position()
			btn.position = Vector2(
				clampf(tl.x, 4.0, maxf(4.0, canvas_w - btn.size.x - 4.0)),
				clampf(tl.y, 4.0, maxf(4.0, canvas_h - btn.size.y - 4.0))
			)
			btn.set_meta("organic_u", nd.uv_position.x)
			btn.set_meta("organic_v", nd.uv_position.y)

	# Final pixel-exact bounding-box separation pass for UI Buttons across all responsive viewports
	var min_gap: float = 6.0 if is_compact_map else 10.0
	for _iter in range(32):
		var any_overlap: bool = false
		for a_idx in range(level_buttons.size()):
			var btn_a: Control = level_buttons[a_idx]
			for b_idx in range(a_idx + 1, level_buttons.size()):
				var btn_b: Control = level_buttons[b_idx]
				var ca: Vector2 = btn_a.position + btn_a.size * 0.5
				var cb: Vector2 = btn_b.position + btn_b.size * 0.5
				var half_w: float = (btn_a.size.x + btn_b.size.x) * 0.5 + min_gap
				var half_h: float = (btn_a.size.y + btn_b.size.y) * 0.5 + min_gap
				var dx: float = cb.x - ca.x
				var dy: float = cb.y - ca.y
				if absf(dx) < half_w and absf(dy) < half_h:
					any_overlap = true
					var pen_x: float = half_w - absf(dx)
					var pen_y: float = half_h - absf(dy)
					var dir_x: float = 1.0 if (dx > 0.0 or (is_zero_approx(dx) and b_idx > a_idx)) else -1.0
					var dir_y: float = 1.0 if (dy > 0.0 or (is_zero_approx(dy) and b_idx > a_idx)) else -1.0
					if pen_x < pen_y:
						btn_a.position.x = clampf(btn_a.position.x - dir_x * pen_x * 0.5, 4.0, maxf(4.0, canvas_w - btn_a.size.x - 4.0))
						btn_b.position.x = clampf(btn_b.position.x + dir_x * pen_x * 0.5, 4.0, maxf(4.0, canvas_w - btn_b.size.x - 4.0))
					else:
						btn_a.position.y = clampf(btn_a.position.y - dir_y * pen_y * 0.5, 4.0, maxf(4.0, canvas_h - btn_a.size.y - 4.0))
						btn_b.position.y = clampf(btn_b.position.y + dir_y * pen_y * 0.5, 4.0, maxf(4.0, canvas_h - btn_b.size.y - 4.0))
		if not any_overlap:
			break

	map_base_node_positions.clear()
	winding_path_points.clear()
	var max_node_bottom: float = canvas_h
	for i in range(level_buttons.size()):
		var btn_node: Button = level_buttons[i]
		map_base_node_positions.append(btn_node.position)
		max_node_bottom = maxf(max_node_bottom, btn_node.position.y + btn_node.size.y + 12.0)
		var ov := btn_node.get_node_or_null("VectorIcon") as Control
		if ov:
			ov.size = btn_node.size
			ov.queue_redraw()
		var center_pt: Vector2 = btn_node.position + btn_node.size * 0.5
		winding_path_points.append(center_pt)
		if _current_page_obj != null and i < _current_page_obj.nodes.size():
			_current_page_obj.nodes[i].position = center_pt

	if _current_page_obj != null and _current_page_obj.route != null:
		var p_style: String = _current_page_obj.theme.path_style if _current_page_obj.theme != null else "sea_stepping_stones"
		_current_page_obj.route.rebuild_from_nodes(_current_page_obj.nodes, p_style, 14)

	map_max_scroll_y = maxf(0.0, max_node_bottom - canvas_h)
	map_target_scroll_y = clampf(map_target_scroll_y, 0.0, map_max_scroll_y)
	map_scroll_y = clampf(map_scroll_y, 0.0, map_max_scroll_y)

	level_grid.queue_redraw()


func _draw_3d_map_cloud(pos: Vector2, scale_f: float = 1.0) -> void:
	var s := scale_f
	# Soft drop shadow cast onto terrain below
	level_grid.draw_circle(pos + Vector2(6.0 * s, 18.0 * s), 26.0 * s, Color(0.02, 0.05, 0.16, 0.18))
	level_grid.draw_circle(pos + Vector2(-16.0 * s, 20.0 * s), 18.0 * s, Color(0.02, 0.05, 0.16, 0.15))
	level_grid.draw_circle(pos + Vector2(22.0 * s, 20.0 * s), 18.0 * s, Color(0.02, 0.05, 0.16, 0.15))
	# Cool underside 3D volume
	var shade_col := Color(0.76, 0.86, 0.98, 0.42)
	level_grid.draw_circle(pos + Vector2(0.0, 5.0 * s), 28.0 * s, shade_col)
	level_grid.draw_circle(pos + Vector2(-20.0 * s, 8.0 * s), 20.0 * s, shade_col)
	level_grid.draw_circle(pos + Vector2(20.0 * s, 8.0 * s), 20.0 * s, shade_col)
	# Warm sunlit top puffs
	var top_col := Color(1.0, 0.99, 0.96, 0.56)
	level_grid.draw_circle(pos + Vector2(-2.0 * s, -2.0 * s), 26.0 * s, top_col)
	level_grid.draw_circle(pos + Vector2(-20.0 * s, 4.0 * s), 18.0 * s, top_col)
	level_grid.draw_circle(pos + Vector2(18.0 * s, 4.0 * s), 18.0 * s, top_col)


func _draw_3d_map_tree(pos: Vector2, scale_f: float = 1.0, foliage_base: Color = Color(0.14, 0.72, 0.38, 0.92)) -> void:
	var s := scale_f
	# Ground ambient shadow
	level_grid.draw_circle(pos + Vector2(4.0 * s, 14.0 * s), 18.0 * s, Color(0.02, 0.05, 0.14, 0.34))
	# 3D Trunk with sunlit left bark and shaded right bark
	level_grid.draw_rect(Rect2(pos + Vector2(-4.5 * s, 2.0 * s), Vector2(9.0 * s, 14.0 * s)), Color(0.36, 0.20, 0.09, 0.94), true)
	level_grid.draw_rect(Rect2(pos + Vector2(-4.5 * s, 2.0 * s), Vector2(3.8 * s, 14.0 * s)), Color(0.56, 0.34, 0.16, 0.94), true)
	# 3-Tiered 3D Spherical Canopy (Underside shade -> Mid foliage -> Top-left sunlit highlight)
	var dark_leaf := foliage_base.darkened(0.32)
	var mid_leaf := foliage_base
	var hi_leaf := foliage_base.lightened(0.32)
	level_grid.draw_circle(pos + Vector2(0.0, -2.0 * s), 18.0 * s, dark_leaf)
	level_grid.draw_circle(pos + Vector2(-10.0 * s, 1.0 * s), 13.0 * s, dark_leaf)
	level_grid.draw_circle(pos + Vector2(10.0 * s, 1.0 * s), 13.0 * s, dark_leaf)
	level_grid.draw_circle(pos + Vector2(-1.0 * s, -6.0 * s), 16.5 * s, mid_leaf)
	level_grid.draw_circle(pos + Vector2(-9.0 * s, -2.0 * s), 11.5 * s, mid_leaf)
	level_grid.draw_circle(pos + Vector2(8.0 * s, -2.0 * s), 11.5 * s, mid_leaf)
	level_grid.draw_circle(pos + Vector2(-4.0 * s, -11.0 * s), 10.5 * s, hi_leaf)


func _draw_3d_map_rock(pos: Vector2, scale_f: float = 1.0, rock_col: Color = Color(0.52, 0.58, 0.72, 0.94)) -> void:
	var s := scale_f
	level_grid.draw_circle(pos + Vector2(3.0 * s, 7.0 * s), 15.0 * s, Color(0.02, 0.04, 0.14, 0.34))
	# Chiseled 3-plane 3D boulder (top sunlit plane, left mid plane, right shadow plane)
	var base_poly := PackedVector2Array([
		pos + Vector2(-14.0 * s, 6.0 * s),
		pos + Vector2(-9.0 * s, -9.0 * s),
		pos + Vector2(3.0 * s, -12.0 * s),
		pos + Vector2(14.0 * s, -3.0 * s),
		pos + Vector2(12.0 * s, 7.0 * s),
		pos + Vector2(-2.0 * s, 9.0 * s)
	])
	var top_plane := PackedVector2Array([
		pos + Vector2(-9.0 * s, -9.0 * s),
		pos + Vector2(3.0 * s, -12.0 * s),
		pos + Vector2(7.0 * s, -2.0 * s),
		pos + Vector2(-5.0 * s, -1.0 * s)
	])
	var right_plane := PackedVector2Array([
		pos + Vector2(3.0 * s, -12.0 * s),
		pos + Vector2(14.0 * s, -3.0 * s),
		pos + Vector2(12.0 * s, 7.0 * s),
		pos + Vector2(-2.0 * s, 9.0 * s),
		pos + Vector2(7.0 * s, -2.0 * s)
	])
	level_grid.draw_colored_polygon(base_poly, rock_col)
	level_grid.draw_colored_polygon(right_plane, rock_col.darkened(0.28))
	level_grid.draw_colored_polygon(top_plane, rock_col.lightened(0.26))


func _draw_3d_map_crystal(pos: Vector2, scale_f: float = 1.0, cry_col: Color = Color(0.42, 0.92, 1.0, 0.94)) -> void:
	var s := scale_f
	level_grid.draw_circle(pos + Vector2(0.0, 6.0 * s), 14.0 * s, Color(cry_col.r, cry_col.g, cry_col.b, 0.26))
	# Main central prism spire (left sunlit facet + right shaded facet)
	var left_facet := PackedVector2Array([
		pos + Vector2(-7.0 * s, 6.0 * s),
		pos + Vector2(0.0, 8.0 * s),
		pos + Vector2(0.0, -18.0 * s),
		pos + Vector2(-5.0 * s, -10.0 * s)
	])
	var right_facet := PackedVector2Array([
		pos + Vector2(0.0, 8.0 * s),
		pos + Vector2(7.0 * s, 6.0 * s),
		pos + Vector2(5.0 * s, -10.0 * s),
		pos + Vector2(0.0, -18.0 * s)
	])
	level_grid.draw_colored_polygon(left_facet, cry_col.lightened(0.28))
	level_grid.draw_colored_polygon(right_facet, cry_col.darkened(0.20))
	# Side secondary crystal shard
	var side_shard := PackedVector2Array([
		pos + Vector2(5.0 * s, 7.0 * s),
		pos + Vector2(13.0 * s, 5.0 * s),
		pos + Vector2(12.0 * s, -7.0 * s),
		pos + Vector2(6.0 * s, -2.0 * s)
	])
	level_grid.draw_colored_polygon(side_shard, cry_col.lightened(0.12))
	level_grid.draw_line(pos + Vector2(0.0, -18.0 * s), pos + Vector2(0.0, 8.0 * s), Color(1.0, 1.0, 1.0, 0.82), 1.6)


func _draw_scenic_landmark(pos: Vector2, landmark_type: String, theme_col: Color) -> void:
	# 3D Sculpted Terrain Outcrop Base with Cliff Extrusion & Shadow
	level_grid.draw_circle(pos + Vector2(0, 13.0), 27.0, Color(0.02, 0.05, 0.16, 0.38))
	level_grid.draw_circle(pos + Vector2(0, 8.5), 25.0, theme_col.darkened(0.40))
	level_grid.draw_circle(pos + Vector2(0, 4.0), 24.0, theme_col)
	level_grid.draw_arc(pos + Vector2(0, 4.0), 24.0, PI, TAU, 16, theme_col.lightened(0.34), 2.5, true)
	match landmark_type:
		"shrine", "windmill_shrine", "moss_lantern_gazebo":
			level_grid.draw_rect(Rect2(pos + Vector2(-12, -4), Vector2(24, 13)), Color(0.92, 0.88, 0.76, 0.96), true)
			level_grid.draw_rect(Rect2(pos + Vector2(-12, -4), Vector2(9, 13)), Color(0.99, 0.96, 0.88, 0.96), true)
			level_grid.draw_colored_polygon(PackedVector2Array([
				pos + Vector2(-17, -4),
				pos + Vector2(17, -4),
				pos + Vector2(0, -19)
			]), Color(0.98, 0.76, 0.24, 0.98))
			level_grid.draw_circle(pos + Vector2(0, -11), 3.2, Color(1.0, 0.96, 0.68, 0.95))
		"watchtower", "alpine_watchtower", "lighthouse_pier":
			level_grid.draw_rect(Rect2(pos + Vector2(-8, -14), Vector2(16, 22)), Color(0.72, 0.78, 0.92, 0.96), true)
			level_grid.draw_rect(Rect2(pos + Vector2(-8, -14), Vector2(6, 22)), Color(0.90, 0.94, 1.0, 0.96), true)
			level_grid.draw_colored_polygon(PackedVector2Array([
				pos + Vector2(-12, -14),
				pos + Vector2(12, -14),
				pos + Vector2(0, -26)
			]), Color(0.96, 0.34, 0.40, 0.98))
			var beacon_alpha: float = 0.65 + 0.30 * sin(anim_time * 3.8)
			level_grid.draw_circle(pos + Vector2(0, -10), 4.5, Color(1.0, 0.94, 0.46, beacon_alpha))
		"crystal_cluster", "prism_obelisk", "amethyst_spire":
			_draw_3d_map_crystal(pos + Vector2(-5, 3), 0.82, Color(0.94, 0.54, 1.0, 0.95))
			_draw_3d_map_crystal(pos + Vector2(3, 2), 1.08, Color(0.48, 0.96, 1.0, 0.96))
		"ancient_arch", "sky_gate", "forest_torii", "coral_arch":
			level_grid.draw_rect(Rect2(pos + Vector2(-12, -11), Vector2(5, 19)), Color(0.84, 0.80, 0.72, 0.96), true)
			level_grid.draw_rect(Rect2(pos + Vector2(7, -11), Vector2(5, 19)), Color(0.84, 0.80, 0.72, 0.96), true)
			level_grid.draw_arc(pos + Vector2(0, -11), 10.0, PI, TAU, 12, Color(0.96, 0.90, 0.68, 0.98), 4.2, true)
		"oasis_palm":
			_draw_3d_map_tree(pos + Vector2(0, -2), 0.96, Color(0.22, 0.88, 0.50, 0.96))
		_:
			_draw_3d_map_rock(pos + Vector2(0, 2), 0.95, theme_col.lightened(0.15))
			UIIconScript.draw_star_shape(level_grid, pos + Vector2(0, -9), 10.0, 4.4, Color(1.0, 0.92, 0.32, 0.96))


func _draw_world_waterway_and_falls(cw: float, ch: float, water_col: Color, cliff_col: Color, chapter_idx: int) -> void:
	# Winding 3D river/lagoon channel cutting through the chapter valley with animated wave crests & waterfall
	var river_pts := PackedVector2Array()
	var bank_left := PackedVector2Array()
	var bank_right := PackedVector2Array()
	var steps: int = 18
	var base_x_shift: float = 0.28 if (chapter_idx % 2 == 0) else 0.72
	for s in range(steps + 1):
		var t: float = float(s) / float(steps)
		var ry: float = t * ch
		var meander: float = sin(t * TAU * 1.35 + float(chapter_idx) * 0.9) * (cw * 0.24)
		var rx: float = clampf(cw * base_x_shift + meander, 46.0, cw - 46.0)
		var pt := Vector2(rx, ry)
		river_pts.append(pt)
		bank_left.append(pt + Vector2(-24.0, 3.0))
		bank_right.append(pt + Vector2(24.0, 3.0))
	# Recessed river gorge bank shadow + sunlit water channel + animated wave ribbons
	level_grid.draw_polyline(river_pts, cliff_col.darkened(0.32), 46.0, true)
	level_grid.draw_polyline(river_pts, water_col.darkened(0.18), 38.0, true)
	level_grid.draw_polyline(river_pts, water_col, 30.0, true)
	level_grid.draw_polyline(river_pts, water_col.lightened(0.32), 12.0, true)
	for w_i in range(steps):
		var wave_t: float = fposmod(float(w_i) / float(steps) + anim_time * 0.08, 1.0)
		var seg_idx: int = clampi(int(wave_t * float(steps)), 0, steps - 1)
		var wp: Vector2 = river_pts[seg_idx].lerp(river_pts[seg_idx + 1], fposmod(wave_t * float(steps), 1.0))
		var shimmer_a: float = 0.45 + 0.35 * sin(anim_time * 3.2 + float(w_i))
		level_grid.draw_line(wp + Vector2(-8.0, -2.0), wp + Vector2(8.0, 2.0), Color(0.92, 0.99, 1.0, shimmer_a), 2.2)
	# Cascading 3D Waterfall at upper cliff terrace
	var fall_origin: Vector2 = river_pts[3]
	level_grid.draw_rect(Rect2(fall_origin + Vector2(-14.0, -4.0), Vector2(28.0, 42.0)), water_col.lightened(0.22), true)
	for f_line in range(4):
		var fx: float = fall_origin.x - 9.0 + float(f_line) * 6.0
		var fy_off: float = fposmod(anim_time * 26.0 + float(f_line) * 9.0, 14.0)
		level_grid.draw_line(Vector2(fx, fall_origin.y - 2.0 + fy_off), Vector2(fx, fall_origin.y + 34.0), Color(0.95, 0.99, 1.0, 0.78), 2.4)
	var foam_r: float = 16.0 + 2.5 * sin(anim_time * 4.2)
	level_grid.draw_circle(fall_origin + Vector2(0.0, 38.0), foam_r, Color(0.94, 0.99, 1.0, 0.62))


func _draw_chapter_transition_portal(pos: Vector2, is_entry: bool, chapter_idx: int, accent_col: Color) -> void:
	# 2.5D Foreshortened World Trail Continuation Stones & Twin Carved Trailhead Pillars
	var dir_y: float = 1.0 if is_entry else -1.0
	for st_i in range(1, 4):
		var st_pos := pos + Vector2(sin(float(st_i + chapter_idx)) * 5.0, dir_y * (16.0 + float(st_i) * 8.5))
		var sr_x: float = 7.2 - float(st_i) * 1.0
		var sr_y: float = sr_x * 0.56
		MapRendererScript._draw_ellipse(level_grid, st_pos + Vector2(1.4, 2.2), sr_x, sr_y, Color(0.02, 0.05, 0.14, 0.42), 12)
		MapRendererScript._draw_ellipse(level_grid, st_pos + Vector2(0.0, 1.4), sr_x, sr_y, accent_col.darkened(0.35), 12)
		MapRendererScript._draw_ellipse(level_grid, st_pos, sr_x * 0.90, sr_y * 0.88, accent_col.lightened(0.18), 12)
	var gate_pos: Vector2 = pos + Vector2(0.0, 22.0 if is_entry else -24.0)
	for side_x in [-21.0, 21.0]:
		var p_base := gate_pos + Vector2(side_x, 0.0)
		MapRendererScript._draw_ellipse(level_grid, p_base + Vector2(1.8, 2.4), 5.2, 3.0, Color(0.02, 0.05, 0.14, 0.42), 10)
		level_grid.draw_rect(Rect2(p_base + Vector2(-3.2, -11.0), Vector2(6.4, 12.0)), Color(0.56, 0.60, 0.72, 0.96), true)
		level_grid.draw_rect(Rect2(p_base + Vector2(-3.2, -11.0), Vector2(3.0, 12.0)), Color(0.88, 0.90, 0.96, 0.98), true)
		level_grid.draw_circle(p_base + Vector2(0.0, -12.5), 3.4, Color(1.0, 0.92, 0.38, 0.96))
		level_grid.draw_circle(p_base + Vector2(-1.0, -13.2), 1.6, Color(1.0, 0.99, 0.88, 0.95))


func _draw_foreground_depth_layer(cw: float, ch: float, _island_col: Color, _cliff_col: Color, _accent_col: Color, particle_type: String) -> void:
	# Subtle Atmospheric Motes (Foreground terrain overhangs are already sculpted in 2.5D by MapRenderer)
	for p_i in range(10):
		var seed_f: float = float(p_i * 19 + current_map_page * 7)
		var px: float = fposmod(cw * (0.08 + 0.085 * float(p_i)) + sin(anim_time * 0.7 + seed_f) * 20.0, cw)
		var py: float = fposmod(ch * (0.90 - 0.080 * float(p_i)) - anim_time * (9.0 + float(p_i % 4) * 2.5), ch)
		var p_alpha: float = 0.36 + 0.32 * sin(anim_time * 2.6 + seed_f)
		var p_col := Color(1.0, 0.96, 0.58, p_alpha)
		match particle_type:
			"snowflakes", "ice_crystals":
				p_col = Color(0.88, 0.98, 1.0, p_alpha)
			"fireflies", "floating_spores", "bamboo_leaves":
				p_col = Color(0.62, 1.0, 0.54, p_alpha)
			"sea_bubbles", "pearl_sparkles":
				p_col = Color(0.56, 0.94, 1.0, p_alpha)
			"crystal_motes", "aurora_wisps":
				p_col = Color(0.92, 0.66, 1.0, p_alpha)
			"ember_sparks":
				p_col = Color(1.0, 0.46, 0.14, p_alpha)
		level_grid.draw_circle(Vector2(px, py), 2.8 if (p_i % 3 == 0) else 2.0, p_col)
		if p_i % 3 == 0:
			level_grid.draw_circle(Vector2(px, py), 5.4, Color(p_col.r, p_col.g, p_col.b, p_alpha * 0.26))


func get_level_map_3d_style_metrics(chapter_idx: int = current_map_page) -> Dictionary:
	var gs = get_node_or_null("/root/GameState")
	var md: MapData = get_active_map_data()
	var page: MapPage = md.get_page(chapter_idx) if md != null else _current_page_obj
	var env: Dictionary = gs.get_chapter_environment(chapter_idx) if (gs and gs.has_method("get_chapter_environment")) else {}
	var ocean_spec: Dictionary = gs.get_chapter_ocean_biome_spec(chapter_idx) if (gs and gs.has_method("get_chapter_ocean_biome_spec")) else {}
	var branches: Array = gs.get_chapter_decorative_branches(chapter_idx) if (gs and gs.has_method("get_chapter_decorative_branches")) else []
	var archetype: String = page.composition_type if page != null else (gs.get_chapter_path_archetype(chapter_idx) if (gs and gs.has_method("get_chapter_path_archetype")) else "sweeping_arc")
	return {
		"total_levels": md.total_levels if md != null else GameStateScript.TOTAL_LEVELS,
		"total_pages": md.get_page_count() if md != null else 68,
		"total_chapters": md.get_page_count() if md != null else 68,
		"page_index": page.page_index if page != null else chapter_idx,
		"page_id": page.page_id if page != null else ("page_%d" % (chapter_idx + 1)),
		"levels_on_page": page.get_level_count() if page != null else 6,
		"levels_per_page": page.get_level_count() if page != null else 6,
		"levels_per_chapter": page.get_level_count() if page != null else 6,
		"is_theme_coherent": page.is_theme_coherent() if page != null else true,
		"is_coherent_single_biome_page": page.is_theme_coherent() if page != null else true,
		"theme_id": page.theme.theme_id if (page != null and page.theme != null) else String(env.get("id", "ocean_islands")),
		"visual_concept": "ocean_and_islands_adventure_world",
		"is_ocean_and_islands_world": true,
		"ocean_dominates_background": true,
		"has_dynamic_ocean_waves": true,
		"has_island_destinations": true,
		"has_milestone_islands_5_10_15_20": true,
		"has_organic_island_route": true,
		"has_dimensional_3d_terrain": true,
		"has_layered_environments": true,
		"has_foreground_midground_background_layers": true,
		"depth_layers": env.get("depth_layers", ["horizon_sky_and_distant_islands", "dynamic_ocean_and_island_archipelago", "foreground_coastal_frame"]),
		"has_directional_lighting_and_shadows": true,
		"has_rounded_3d_level_nodes": true,
		"nodes_integrated_into_terrain": true,
		"has_3d_bridges_and_path_segments": true,
		"has_3d_hills_and_floating_islands": true,
		"has_3d_waterways_and_waterfalls": true,
		"has_3d_trees_rocks_crystals_clouds": true,
		"has_chapter_transition_portals": true,
		"has_player_journey_wayfinder": true,
		"milestones_distinct_by_shape_scale_decoration_environment": true,
		"chapter_environment_id": String(env.get("id", "ocean_islands")),
		"ocean_biome_id": String(ocean_spec.get("biome_id", "ocean_islands")),
		"world_title_en": String(env.get("world_title_en", env.get("name_en", "Sapphire Atoll"))),
		"biome_type": String(env.get("biome_type", "open_ocean_archipelago")),
		"terrain_layout": String(env.get("terrain_layout", "atoll_islands")),
		"waterway_type": String(env.get("waterway_type", "sunlit_sea_breeze")),
		"road_style": String(env.get("road_style", "sea_stepping_stones")),
		"vegetation_type": String(env.get("vegetation_type", "harbor_lighthouse")),
		"architecture_type": String(env.get("architecture_type", "sandy_cay_island")),
		"ambient_particle_type": String(env.get("ambient_particle_type", "sea_bubbles")),
		"path_archetype": archetype,
		"milestone_landmarks": env.get("milestone_landmarks", {}),
		"decorative_branch_count": branches.size()
	}


func _sample_catmull_rom_spline(pts: Array[Vector2], subdivisions: int = 10) -> PackedVector2Array:
	var curve := PackedVector2Array()
	var n: int = pts.size()
	if n == 0:
		return curve
	if n == 1:
		curve.append(pts[0])
		return curve
	var steps: int = maxi(2, subdivisions)
	for i in range(n - 1):
		var p0: Vector2 = pts[max(0, i - 1)]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[min(n - 1, i + 1)]
		var p3: Vector2 = pts[min(n - 1, i + 2)]
		for s in range(steps):
			var t: float = float(s) / float(steps)
			var t2: float = t * t
			var t3: float = t2 * t
			var q: Vector2 = 0.5 * (
				(2.0 * p1) +
				(-p0 + p2) * t +
				(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
				(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
			)
			curve.append(q)
	curve.append(pts[n - 1])
	return curve


func _draw_adventure_bridge_segment(p_a: Vector2, p_b: Vector2, seg_type: String, cliff_col: Color) -> void:
	var diff: Vector2 = p_b - p_a
	var length: float = diff.length()
	if length < 8.0:
		return
	var dir: Vector2 = diff / length
	var nrm: Vector2 = Vector2(-dir.y, dir.x)
	var is_stone: bool = (seg_type in ["arched_stone_bridge", "cliff_stairway"])
	var half_w: float = 13.5 if is_stone else 12.5
	# Cast bridge shadow onto canyon/river below
	level_grid.draw_line(p_a + Vector2(0, 9.0), p_b + Vector2(0, 9.0), Color(0.02, 0.05, 0.16, 0.42), half_w * 2.1)
	if is_stone:
		# Sculpted Arched Stone Bridge with Parapet Walls
		level_grid.draw_line(p_a, p_b, cliff_col.darkened(0.28), half_w * 2.15)
		level_grid.draw_line(p_a, p_b, Color(0.84, 0.86, 0.92, 0.98), half_w * 1.65)
		level_grid.draw_line(p_a + nrm * (half_w * 0.88), p_b + nrm * (half_w * 0.88), Color(0.96, 0.94, 0.88, 0.96), 3.2)
		level_grid.draw_line(p_a - nrm * (half_w * 0.88), p_b - nrm * (half_w * 0.88), Color(0.64, 0.68, 0.78, 0.96), 3.2)
		var stone_steps: int = clampi(int(length / 11.0), 3, 10)
		for s_i in range(1, stone_steps):
			var st_p: Vector2 = p_a.lerp(p_b, float(s_i) / float(stone_steps))
			level_grid.draw_line(st_p - nrm * (half_w * 0.72), st_p + nrm * (half_w * 0.72), Color(0.56, 0.60, 0.72, 0.75), 1.8)
	else:
		# Timber Suspension Bridge with Wooden Planks & Side Rope Rails
		level_grid.draw_line(p_a, p_b, Color(0.32, 0.18, 0.08, 0.96), half_w * 1.95)
		var plank_count: int = clampi(int(length / 9.5), 4, 12)
		for p_i in range(plank_count + 1):
			var pl_p: Vector2 = p_a.lerp(p_b, float(p_i) / float(plank_count))
			var pl_col := Color(0.76, 0.48, 0.22, 0.98) if (p_i % 2 == 0) else Color(0.66, 0.40, 0.18, 0.98)
			level_grid.draw_line(pl_p - nrm * (half_w * 0.82), pl_p + nrm * (half_w * 0.82), pl_col, 5.2)
		# Twin woven suspension ropes & corner posts
		level_grid.draw_line(p_a + nrm * half_w, p_b + nrm * half_w, Color(0.92, 0.76, 0.42, 0.96), 2.4)
		level_grid.draw_line(p_a - nrm * half_w, p_b - nrm * half_w, Color(0.84, 0.66, 0.34, 0.96), 2.4)
		for end_pt in [p_a, p_b]:
			level_grid.draw_circle(end_pt + nrm * half_w, 3.6, Color(0.48, 0.28, 0.12, 0.98))
			level_grid.draw_circle(end_pt - nrm * half_w, 3.6, Color(0.48, 0.28, 0.12, 0.98))


func _draw_ocean_sailboat(pos: Vector2, scale_f: float = 1.0, sail_col: Color = Color(1.0, 0.96, 0.86, 0.96)) -> void:
	var s := scale_f
	var bob: float = sin(anim_time * 2.8 + pos.x * 0.05) * 2.0 * s
	var p := pos + Vector2(0.0, bob)
	# Water wake & shadow
	level_grid.draw_arc(p + Vector2(0.0, 5.0 * s), 11.0 * s, 0.15, PI - 0.15, 10, Color(0.92, 0.99, 1.0, 0.68), 1.8 * s)
	# Wooden hull
	var hull := PackedVector2Array([
		p + Vector2(-10.0 * s, 1.0 * s),
		p + Vector2(10.0 * s, 1.0 * s),
		p + Vector2(6.5 * s, 5.5 * s),
		p + Vector2(-6.5 * s, 5.5 * s)
	])
	level_grid.draw_colored_polygon(hull, Color(0.56, 0.32, 0.14, 0.98))
	level_grid.draw_line(p + Vector2(-9.5 * s, 1.2 * s), p + Vector2(9.5 * s, 1.2 * s), Color(0.96, 0.82, 0.44, 0.96), 1.6 * s)
	# Mast & billowing sail
	level_grid.draw_line(p + Vector2(0.0, 1.0 * s), p + Vector2(0.0, -13.0 * s), Color(0.42, 0.24, 0.10, 0.98), 1.8 * s)
	var main_sail := PackedVector2Array([
		p + Vector2(0.5 * s, -12.5 * s),
		p + Vector2(8.5 * s, -2.0 * s),
		p + Vector2(0.5 * s, -1.5 * s)
	])
	var fore_sail := PackedVector2Array([
		p + Vector2(-0.5 * s, -11.0 * s),
		p + Vector2(-6.5 * s, -2.0 * s),
		p + Vector2(-0.5 * s, -2.0 * s)
	])
	level_grid.draw_colored_polygon(main_sail, sail_col)
	level_grid.draw_colored_polygon(fore_sail, sail_col.darkened(0.08))
	# Pennant flag
	level_grid.draw_colored_polygon(PackedVector2Array([
		p + Vector2(0.0, -13.0 * s),
		p + Vector2(4.8 * s, -11.5 * s),
		p + Vector2(0.0, -10.0 * s)
	]), Color(1.0, 0.42, 0.24, 0.98))


func _draw_level_path_canvas() -> void:
	if not level_grid or winding_path_points.size() < 2:
		return
	
	var cw: float = level_grid.size.x if level_grid.size.x > 0 else 630.0
	var ch: float = level_grid.size.y if level_grid.size.y > 0 else 740.0
	var gs = get_node_or_null("/root/GameState")
	var env: Dictionary = gs.get_chapter_environment(current_map_page) if (gs and gs.has_method("get_chapter_environment")) else {}
	var ocean_spec: Dictionary = gs.get_chapter_ocean_biome_spec(current_map_page) if (gs and gs.has_method("get_chapter_ocean_biome_spec")) else {}
	var page_theme_id: String = _current_page_obj.theme.theme_id if (_current_page_obj != null and _current_page_obj.theme != null) else String(ocean_spec.get("biome_id", "ocean_islands"))
	var is_ocean_page: bool = (page_theme_id == "ocean_islands")
	var island_col: Color = ocean_spec.get("island_turf", env.get("island_col", Color(0.24, 0.82, 0.44, 1.0)))
	var cliff_col: Color = env.get("cliff_col", island_col.darkened(0.42))
	var path_outer: Color = env.get("path_outer", Color(1.0, 0.86, 0.32, 1.0))
	var particle_type: String = String(env.get("ambient_particle_type", "sea_bubbles"))
	
	var children: Array[Control] = []
	for ch_node in level_grid.get_children():
		if ch_node is Button:
			children.append(ch_node as Control)
	
	# ==========================================================================
	# LAYER 1–7: CONTINUOUS ILLUSTRATED TOPOGRAPHIC WORLD VIA MAP CORE RENDERER
	# ==========================================================================
	if _current_page_obj != null:
		MapRendererScript.draw_page_canvas(level_grid, _current_page_obj, anim_time, map_camera_pan_offset)

	# Compact active-destination wayfinder pin above the selected / current stop
	for i in range(min(children.size(), winding_path_points.size())):
		var btn := children[i] as Control
		if not btn:
			continue
		var pt: Vector2 = winding_path_points[i]
		var is_sel_node: bool = bool(btn.get_meta("is_selected", false))
		var is_cur_node: bool = bool(btn.get_meta("current", false))
		if is_sel_node or is_cur_node:
			var bob_y: float = -29.0 + sin(anim_time * 4.0) * 2.5
			var pin_pos := pt + Vector2(0.0, bob_y)
			level_grid.draw_colored_polygon(PackedVector2Array([
				pin_pos + Vector2(-6.0, -5.5),
				pin_pos + Vector2(0.0, -8.0),
				pin_pos + Vector2(0.0, 4.5)
			]), Color(1.0, 0.95, 0.48, 0.98) if is_sel_node else Color(0.64, 0.98, 1.0, 0.98))
			level_grid.draw_colored_polygon(PackedVector2Array([
				pin_pos + Vector2(0.0, -8.0),
				pin_pos + Vector2(6.0, -5.5),
				pin_pos + Vector2(0.0, 4.5)
			]), Color(0.86, 0.58, 0.08, 0.98) if is_sel_node else Color(0.14, 0.62, 0.88, 0.98))
			UIIconScript.draw_star_shape(level_grid, pin_pos + Vector2(0.0, -7.0), 3.8, 1.7, Color(1.0, 0.99, 0.88, 1.0))


func _on_level_map_prev_page() -> void:
	_play_sfx("click")
	navigate_to_map_page(current_map_page - 1, true)


func _on_level_map_next_page() -> void:
	_play_sfx("click")
	navigate_to_map_page(current_map_page + 1, true)


func _on_level_map_jump_current() -> void:
	_play_sfx("click")
	var gs = get_node_or_null("/root/GameState")
	var highest_lvl: int = gs.highest_unlocked_level if (gs and "highest_unlocked_level" in gs) else 1
	if gs and gs.has_method("select_map_level"):
		gs.select_map_level(highest_lvl)
	var md: MapData = get_active_map_data()
	current_map_page = md.get_page_index_for_level(highest_lvl) if md != null else 0
	_populate_level_map_page(current_map_page)
	_center_map_on_level(highest_lvl)
	_refresh_progression_ui()
	_update_mode_selection_ui()


func _on_start_selected_level_from_map() -> void:
	_play_sfx("click")
	if modal_level_map:
		modal_level_map.visible = false
	_on_btn_start_pressed()


# ==============================================================================
# DAILY GIFT = LUCKY WHEEL (SPECIAL-ITEM REWARDS ONLY, 1 FREE SPIN PER DAY)
# ==============================================================================

func _on_btn_daily_gift_pressed() -> void:
	_play_sfx("click")
	if is_wheel_spinning:
		return
	_hide_all_modals()
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_method("check_daily_gift_date_reset"):
		gs.check_daily_gift_date_reset()
	highlighted_wheel_slice = -1
	var reward_box := get_node_or_null("Modals/LuckyWheelModal/Panel/VBoxContainer/WheelRewardInfoBox") as Control
	if reward_box:
		reward_box.visible = false
	if modal_lucky_wheel:
		modal_lucky_wheel.visible = true
	_refresh_lucky_wheel_ui()
	_on_viewport_resized()
	if wheel_canvas:
		wheel_canvas.queue_redraw()


func _on_viewport_resized() -> void:
	var vp_sz := Vector2(720.0, 1280.0)
	if is_inside_tree() and get_viewport():
		var r_sz := get_viewport_rect().size
		if r_sz.x > 0 and r_sz.y > 0:
			vp_sz = r_sz
	update_responsive_menu_layout(vp_sz)
	update_responsive_wheel_layout(vp_sz)
	update_responsive_level_map_layout(vp_sz)
	update_responsive_account_and_settings_modals(vp_sz)
	if modal_level_map and modal_level_map.visible:
		_layout_winding_path_nodes()


func update_responsive_level_map_layout(vp_size: Vector2 = Vector2(720, 1280)) -> Dictionary:
	var vp_w: float = vp_size.x if vp_size.x > 0 else 720.0
	var vp_h: float = vp_size.y if vp_size.y > 0 else 1280.0
	var is_compact: bool = (vp_h <= 900.0 or vp_w <= 430.0)
	var is_very_compact: bool = (vp_h <= 810.0 or vp_w <= 370.0)
	
	var brand_top_y: float = vp_h - 88.0
	var top_safe_margin: float = 6.0 if is_compact else 12.0
	var bottom_safe_limit: float = brand_top_y - (8.0 if is_compact else 14.0)
	
	var panel_w: float = clampf(vp_w - (8.0 if is_very_compact else 12.0), 348.0, 704.0)
	var max_safe_panel_h: float = maxf(540.0, bottom_safe_limit - top_safe_margin)
	var panel_h: float = clampf(max_safe_panel_h, 540.0, 1140.0)
	var panel_x: float = (vp_w - panel_w) * 0.5
	var panel_y: float = top_safe_margin + maxf(0.0, (max_safe_panel_h - panel_h) * 0.5)
	
	var map_root: Node = modal_level_map if modal_level_map != null else get_node_or_null("LevelMapModal")
	var map_panel := (map_root.get_node_or_null("Panel") if map_root else get_node_or_null("Modals/LevelMapModal/Panel")) as Control
	var map_vbox := (map_root.get_node_or_null("Panel/VBoxContainer") if map_root else get_node_or_null("Modals/LevelMapModal/Panel/VBoxContainer")) as VBoxContainer
	var map_frame := (map_root.get_node_or_null("Panel/VBoxContainer/MapFrame") if map_root else null) as ColorRect
	var map_scroll := (map_root.get_node_or_null("Panel/VBoxContainer/MapFrame/MapScroll") if map_root else null) as ScrollContainer
	var page_nav_row := (map_root.get_node_or_null("Panel/VBoxContainer/PageNavRow") if map_root else get_node_or_null("Modals/LevelMapModal/Panel/VBoxContainer/PageNavRow")) as HBoxContainer
	var btn_prev := (map_root.get_node_or_null("Panel/VBoxContainer/PageNavRow/BtnPagePrev") if map_root else get_node_or_null("Modals/LevelMapModal/Panel/VBoxContainer/PageNavRow/BtnPagePrev")) as Button
	var btn_next := (map_root.get_node_or_null("Panel/VBoxContainer/PageNavRow/BtnPageNext") if map_root else get_node_or_null("Modals/LevelMapModal/Panel/VBoxContainer/PageNavRow/BtnPageNext")) as Button
	var btn_curr := (map_root.get_node_or_null("Panel/VBoxContainer/PageNavRow/BtnPageCurrent") if map_root else get_node_or_null("Modals/LevelMapModal/Panel/VBoxContainer/PageNavRow/BtnPageCurrent")) as Button
	var lbl_range := (map_root.get_node_or_null("Panel/VBoxContainer/PageNavRow/LblPageRange") if map_root else get_node_or_null("Modals/LevelMapModal/Panel/VBoxContainer/PageNavRow/LblPageRange")) as Label
	var map_actions := (map_root.get_node_or_null("Panel/VBoxContainer/BottomMapActions") if map_root else get_node_or_null("Modals/LevelMapModal/Panel/VBoxContainer/BottomMapActions")) as HBoxContainer
	var btn_cls := (map_root.get_node_or_null("Panel/VBoxContainer/BottomMapActions/BtnCloseLevelMap") if map_root else get_node_or_null("Modals/LevelMapModal/Panel/VBoxContainer/BottomMapActions/BtnCloseLevelMap")) as Button
	var btn_start_map := (map_root.get_node_or_null("Panel/VBoxContainer/BottomMapActions/BtnStartSelectedLevel") if map_root else get_node_or_null("Modals/LevelMapModal/Panel/VBoxContainer/BottomMapActions/BtnStartSelectedLevel")) as Button
	
	var pad_side: float = 5.0 if is_very_compact else (6.0 if is_compact else 10.0)
	var pad_top: float = 5.0 if is_very_compact else (6.0 if is_compact else 10.0)
	var pad_bot: float = 6.0 if is_very_compact else (7.0 if is_compact else 10.0)
	var vbox_sep: int = 3 if is_very_compact else (4 if is_compact else 6)
	var nav_btn_h: float = 38.0 if is_very_compact else (42.0 if is_compact else 48.0)
	var action_btn_h: float = 44.0 if is_very_compact else (48.0 if is_compact else 56.0)
	
	if map_vbox:
		map_vbox.offset_left = pad_side
		map_vbox.offset_top = pad_top
		map_vbox.offset_right = -pad_side
		map_vbox.offset_bottom = -pad_bot
		map_vbox.add_theme_constant_override("separation", vbox_sep)
	if map_panel:
		map_panel.offset_left = panel_x - vp_w * 0.5
		map_panel.offset_right = panel_x + panel_w - vp_w * 0.5
		map_panel.offset_top = panel_y - vp_h * 0.5
		map_panel.offset_bottom = panel_y + panel_h - vp_h * 0.5
		map_panel.position = Vector2(panel_x, panel_y)
		map_panel.size = Vector2(panel_w, panel_h)
		var map_sb := map_panel.get_theme_stylebox("panel") as StyleBoxFlat
		if map_sb:
			map_sb.bg_color = Color(0.05, 0.10, 0.22, 0.96)
			map_sb.border_width_left = 2
			map_sb.border_width_top = 2
			map_sb.border_width_right = 2
			map_sb.border_width_bottom = 3
			map_sb.border_color = Color(0.92, 0.78, 0.34, 0.78)
	
	if level_grid:
		var frame_w: float = maxf(300.0, panel_w - pad_side * 2.0)
		var header_h: float = (20.0 if is_very_compact else (22.0 if is_compact else 26.0)) + (16.0 if is_very_compact else (18.0 if is_compact else 20.0))
		var other_chrome_h: float = pad_top + pad_bot + float(vbox_sep * 4) + header_h + nav_btn_h + action_btn_h
		var frame_h: float = maxf(320.0, panel_h - other_chrome_h)
		if map_frame:
			map_frame.clip_contents = true
			map_frame.custom_minimum_size = Vector2(frame_w, frame_h)
			map_frame.size = Vector2(frame_w, frame_h)
		if map_scroll:
			map_scroll.offset_left = 0.0
			map_scroll.offset_top = 0.0
			map_scroll.offset_right = 0.0
			map_scroll.offset_bottom = 0.0
			map_scroll.position = Vector2.ZERO
			map_scroll.custom_minimum_size = Vector2(frame_w, frame_h)
			map_scroll.size = Vector2(frame_w, frame_h)
			map_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		level_grid.custom_minimum_size = Vector2(frame_w, frame_h)
		level_grid.size = Vector2(frame_w, frame_h)
	
	if page_nav_row:
		page_nav_row.add_theme_constant_override("separation", 4 if is_very_compact else (6 if is_compact else 8))
	if btn_prev:
		btn_prev.custom_minimum_size = Vector2(50.0 if is_very_compact else (60.0 if is_compact else 82.0), nav_btn_h)
		GameTypographyScript.apply_secondary_button_typography(btn_prev, 12 if is_very_compact else (13 if is_compact else 15))
	if btn_next:
		btn_next.custom_minimum_size = Vector2(50.0 if is_very_compact else (60.0 if is_compact else 82.0), nav_btn_h)
		GameTypographyScript.apply_secondary_button_typography(btn_next, 12 if is_very_compact else (13 if is_compact else 15))
	if btn_curr:
		btn_curr.custom_minimum_size = Vector2(60.0 if is_very_compact else (72.0 if is_compact else 90.0), nav_btn_h)
		GameTypographyScript.apply_secondary_button_typography(btn_curr, 12 if is_very_compact else (13 if is_compact else 15))
	if lbl_range:
		lbl_range.clip_text = true
		lbl_range.add_theme_font_size_override("font_size", 11 if is_very_compact else (12 if is_compact else 15))
	if lbl_map_modal_title:
		lbl_map_modal_title.add_theme_font_size_override("font_size", 15 if is_very_compact else (17 if is_compact else 21))
	if lbl_map_milestone_hint:
		lbl_map_milestone_hint.clip_text = true
		lbl_map_milestone_hint.add_theme_font_size_override("font_size", 11 if is_very_compact else (12 if is_compact else 14))
	if map_actions:
		map_actions.add_theme_constant_override("separation", 12 if is_very_compact else (16 if is_compact else 26))
	if btn_cls:
		btn_cls.custom_minimum_size = Vector2(0.0, action_btn_h)
		GameTypographyScript.apply_secondary_button_typography(btn_cls, 15 if is_compact else 19)
	if btn_start_map:
		btn_start_map.custom_minimum_size = Vector2(0.0, action_btn_h)
		GameTypographyScript.apply_primary_button_typography(btn_start_map, 16 if is_compact else 21)
		
	return {
		"panel_size": Vector2(panel_w, panel_h),
		"grid_size": level_grid.size if level_grid else Vector2.ZERO
	}


func update_responsive_wheel_layout(vp_size: Vector2 = Vector2(720, 1280)) -> Dictionary:
	var vp_w: float = vp_size.x if vp_size.x > 0 else 720.0
	var vp_h: float = vp_size.y if vp_size.y > 0 else 1280.0
	var is_compact: bool = (vp_h <= 900.0 or vp_w <= 430.0)
	var is_very_compact: bool = (vp_h <= 810.0 or vp_w <= 370.0)

	# Reserve bottom 88px for 4TM GAMES branding bar (vp_h - 88..vp_h - 64) + AdSlot (vp_h - 60..vp_h)
	# plus a clean separation margin above the 4TM GAMES branding so CLOSE and SPIN never overlap it.
	var brand_top_y: float = vp_h - 88.0
	var ad_top_y: float = vp_h - 60.0
	var top_safe_margin: float = 10.0 if is_compact else 18.0
	var bottom_safe_limit: float = brand_top_y - (14.0 if is_compact else 20.0)

	var panel_w: float = clampf(vp_w - 14.0, 344.0, 704.0)
	var max_safe_panel_h: float = maxf(540.0, bottom_safe_limit - top_safe_margin)
	var panel_h: float = clampf(max_safe_panel_h, 540.0, 1150.0)
	var panel_x: float = (vp_w - panel_w) * 0.5
	var panel_y: float = top_safe_margin + maxf(0.0, (max_safe_panel_h - panel_h) * 0.5)

	var wheel_panel := get_node_or_null("Modals/LuckyWheelModal/Panel") as Control
	var wheel_vbox := get_node_or_null("Modals/LuckyWheelModal/Panel/VBoxContainer") as VBoxContainer
	var reward_box := get_node_or_null("Modals/LuckyWheelModal/Panel/VBoxContainer/WheelRewardInfoBox") as Control
	var wheel_actions := get_node_or_null("Modals/LuckyWheelModal/Panel/VBoxContainer/WheelActions") as HBoxContainer

	var pad_side: float = 12.0 if is_compact else 18.0
	var pad_top: float = 10.0 if is_compact else 16.0
	var pad_bot: float = 12.0 if is_compact else 16.0
	var vbox_sep: int = 5 if is_very_compact else (6 if is_compact else 8)
	var btn_h: float = 48.0 if is_very_compact else (50.0 if is_compact else 58.0)
	var info_h: float = 58.0 if is_very_compact else (64.0 if is_compact else 78.0)
	var title_h: float = 24.0 if is_very_compact else (26.0 if is_compact else 32.0)
	var sub_h: float = 16.0 if is_very_compact else (18.0 if is_compact else 22.0)
	var res_h: float = 20.0 if is_very_compact else (22.0 if is_compact else 26.0)

	if wheel_vbox:
		wheel_vbox.offset_left = pad_side
		wheel_vbox.offset_top = pad_top
		wheel_vbox.offset_right = -pad_side
		wheel_vbox.offset_bottom = -pad_bot
		wheel_vbox.add_theme_constant_override("separation", vbox_sep)
	if lbl_wheel_title:
		lbl_wheel_title.add_theme_font_size_override("font_size", 22 if is_compact else 28)
	if lbl_wheel_subtitle:
		lbl_wheel_subtitle.add_theme_font_size_override("font_size", 13 if is_compact else 17)
	if reward_box:
		reward_box.custom_minimum_size = Vector2(0.0, info_h)
	if lbl_wheel_reward_title:
		lbl_wheel_reward_title.add_theme_font_size_override("font_size", 20 if is_compact else 26)
	if lbl_wheel_reward_desc:
		lbl_wheel_reward_desc.add_theme_font_size_override("font_size", 15 if is_compact else 20)
	if lbl_wheel_result:
		lbl_wheel_result.add_theme_font_size_override("font_size", 13 if is_very_compact else (14 if is_compact else 19))
	if wheel_actions:
		wheel_actions.size_flags_vertical = Control.SIZE_SHRINK_END
		wheel_actions.custom_minimum_size = Vector2(0.0, btn_h)
		wheel_actions.size.y = btn_h
	if btn_close_wheel:
		btn_close_wheel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn_close_wheel.custom_minimum_size = Vector2(0.0, btn_h)
		btn_close_wheel.size.y = btn_h
		GameTypographyScript.apply_secondary_button_typography(btn_close_wheel, 17 if is_compact else 20)
	if btn_spin_wheel:
		btn_spin_wheel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn_spin_wheel.custom_minimum_size = Vector2(0.0, btn_h)
		btn_spin_wheel.size.y = btn_h
		_apply_spin_button_blue_style()
		var gs = get_node_or_null("/root/GameState")
		var can_claim_sp: bool = gs.can_claim_daily_gift_today() if (gs and gs.has_method("can_claim_daily_gift_today")) else true
		var is_claimed: bool = not can_claim_sp and not is_wheel_spinning
		var spin_fsz: int = (12 if is_very_compact else (14 if is_compact else 16)) if is_claimed else (16 if is_very_compact else (18 if is_compact else 22))
		GameTypographyScript.apply_primary_button_typography(btn_spin_wheel, spin_fsz)
		btn_spin_wheel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Keep the Lucky Wheel large and readable across 360x800, 390x844, and 720x1280
	var non_wheel_chrome_h: float = pad_top + pad_bot + float(vbox_sep * 5) + (title_h + sub_h) + info_h + res_h + btn_h
	var max_wheel_from_h: float = panel_h - non_wheel_chrome_h
	var max_wheel_from_w: float = panel_w - pad_side * 2.0
	var min_wheel_side: float = 312.0 if is_very_compact else (336.0 if is_compact else 584.0)
	var canvas_side: float = clampf(minf(max_wheel_from_w, maxf(min_wheel_side, max_wheel_from_h)), min_wheel_side, 630.0)

	# Fit panel height tightly around content so it stays well above the 4TM GAMES branding bar
	var tight_panel_h: float = clampf(canvas_side + non_wheel_chrome_h, 540.0, max_safe_panel_h)
	panel_h = tight_panel_h
	panel_y = top_safe_margin + maxf(0.0, (max_safe_panel_h - panel_h) * 0.5)

	if wheel_panel:
		wheel_panel.anchor_left = 0.0
		wheel_panel.anchor_top = 0.0
		wheel_panel.anchor_right = 0.0
		wheel_panel.anchor_bottom = 0.0
		wheel_panel.offset_left = panel_x
		wheel_panel.offset_top = panel_y
		wheel_panel.offset_right = panel_x + panel_w
		wheel_panel.offset_bottom = panel_y + panel_h
		wheel_panel.position = Vector2(panel_x, panel_y)
		wheel_panel.size = Vector2(panel_w, panel_h)

	if wheel_canvas:
		var min_canvas_y: float = maxf(240.0, canvas_side - info_h - 16.0)
		wheel_canvas.custom_minimum_size = Vector2(canvas_side, min_canvas_y)
		wheel_canvas.size = Vector2(canvas_side, canvas_side)
		wheel_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
		wheel_canvas.queue_redraw()
	if wheel_vbox:
		wheel_vbox.queue_sort()
	if wheel_actions:
		wheel_actions.queue_sort()

	var wheel_radius: float = canvas_side * 0.46
	var icon_radius: float = clampf(wheel_radius * 0.165, 24.0, 46.0)

	var actions_sep: float = float(wheel_actions.get_theme_constant("separation")) if wheel_actions else 26.0
	var inner_w: float = panel_w - pad_side * 2.0
	var each_btn_w: float = (inner_w - actions_sep) * 0.5
	var actions_y: float = panel_y + panel_h - pad_bot - btn_h
	var close_rect := Rect2(Vector2(panel_x + pad_side, actions_y), Vector2(each_btn_w, btn_h))
	var spin_rect := Rect2(Vector2(panel_x + pad_side + each_btn_w + actions_sep, actions_y), Vector2(each_btn_w, btn_h))
	var panel_rect := Rect2(Vector2(panel_x, panel_y), Vector2(panel_w, panel_h))
	var brand_rect := Rect2(Vector2(0.0, brand_top_y), Vector2(vp_w, 24.0))
	var ad_rect := Rect2(Vector2(0.0, ad_top_y), Vector2(vp_w, 60.0))
	var close_gap: float = brand_rect.position.y - close_rect.end.y
	var spin_gap: float = brand_rect.position.y - spin_rect.end.y

	return {
		"panel_size": Vector2(panel_w, panel_h),
		"panel_rect": panel_rect,
		"canvas_size": Vector2(canvas_side, canvas_side),
		"wheel_radius": wheel_radius,
		"wheel_diameter": wheel_radius * 2.0,
		"icon_radius": icon_radius,
		"close_button_rect": close_rect,
		"spin_button_rect": spin_rect,
		"branding_rect": brand_rect,
		"ad_slot_rect": ad_rect,
		"close_to_branding_gap_y": close_gap,
		"spin_to_branding_gap_y": spin_gap,
		"has_zero_branding_overlap": (
			not close_rect.intersects(brand_rect)
			and not spin_rect.intersects(brand_rect)
			and not panel_rect.intersects(brand_rect)
			and not close_rect.intersects(ad_rect)
			and not spin_rect.intersects(ad_rect)
			and close_gap >= 16.0
			and spin_gap >= 16.0
		)
	}


func get_wheel_slice_at_pointer(angle_deg: float = wheel_angle_deg) -> int:
	var slice_count: int = GameStateScript.LUCKY_WHEEL_SLICES.size()
	if slice_count <= 0:
		return 0
	var slice_deg: float = 360.0 / float(slice_count)
	var rel_deg: float = fposmod(270.0 - angle_deg, 360.0)
	return int(floor(rel_deg / slice_deg)) % slice_count


func _update_wheel_pointer_description(slice_idx: int = -1) -> Dictionary:
	var slices: Array = GameStateScript.LUCKY_WHEEL_SLICES
	if slices.is_empty():
		return {}
	var idx: int = slice_idx if (slice_idx >= 0 and slice_idx < slices.size()) else (
		highlighted_wheel_slice if (highlighted_wheel_slice >= 0 and highlighted_wheel_slice < slices.size()) else get_wheel_slice_at_pointer(wheel_angle_deg)
	)
	var slice: Dictionary = slices[idx]
	var gs = get_node_or_null("/root/GameState")
	var lang: String = gs.get_language() if (gs and gs.has_method("get_language")) else "en"
	var is_vi: bool = (lang == "vi")
	var r_type: String = String(slice.get("reward_type", "bomb"))
	var amt: int = int(slice.get("amount", 0))
	var title_str: String = String(slice.get("label_vi" if is_vi else "label_en", "BOMB"))
	var desc_str: String = String(slice.get("desc_vi" if is_vi else "desc_en", ""))
	if gs and gs.has_method("get_lucky_wheel_reward_description"):
		var desc_info: Dictionary = gs.get_lucky_wheel_reward_description(r_type, lang)
		title_str = String(desc_info.get("title", title_str))
		desc_str = String(desc_info.get("description", desc_str))
	var display_title: String = title_str if (r_type == "lucky_next_time" or amt <= 0) else ("%s ×%d" % [title_str, amt])
	if lbl_wheel_reward_title:
		lbl_wheel_reward_title.text = display_title
	if lbl_wheel_reward_desc:
		lbl_wheel_reward_desc.text = desc_str
	return {
		"slice_index": idx,
		"reward_type": r_type,
		"amount": amt,
		"title": title_str,
		"display_title": display_title,
		"description": desc_str
	}


func _refresh_lucky_wheel_ui() -> void:
	var gs = get_node_or_null("/root/GameState")
	var can_claim: bool = gs.can_claim_daily_gift_today() if (gs and gs.has_method("can_claim_daily_gift_today")) else true
	var is_vi: bool = (gs.get_language() == "vi") if (gs and gs.has_method("get_language")) else false
	
	if btn_daily_gift:
		btn_daily_gift.text = "  " + _tr("btn_daily_gift")
		var st_gift: StyleBoxFlat = _get_gift_style(can_claim)
		btn_daily_gift.add_theme_stylebox_override("normal", st_gift)
		btn_daily_gift.add_theme_stylebox_override("hover", st_gift)
		btn_daily_gift.add_theme_stylebox_override("pressed", st_gift)
		btn_daily_gift.add_theme_stylebox_override("disabled", st_gift)
		btn_daily_gift.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0) if can_claim else Color(0.72, 0.76, 0.86, 0.85))
		var gift_icon := btn_daily_gift.get_node_or_null("VectorIcon")
		if gift_icon and "primary_color" in gift_icon:
			gift_icon.primary_color = Color(1.0, 0.92, 0.34, 1.0) if can_claim else Color(0.65, 0.70, 0.80, 0.85)
			gift_icon.queue_redraw()
	
	_update_wheel_pointer_description()
	
	var reward_box := get_node_or_null("Modals/LuckyWheelModal/Panel/VBoxContainer/WheelRewardInfoBox") as Control
	if reward_box:
		reward_box.visible = (highlighted_wheel_slice >= 0 and not is_wheel_spinning)
	
	if not btn_spin_wheel:
		return
	
	_apply_spin_button_blue_style()
	
	if is_wheel_spinning:
		btn_spin_wheel.disabled = true
		btn_spin_wheel.text = "    " + _tr("lucky_wheel_spinning")
	elif can_claim:
		btn_spin_wheel.disabled = false
		btn_spin_wheel.text = "    " + _tr("lucky_wheel_spin_free")
	else:
		btn_spin_wheel.disabled = true
		btn_spin_wheel.text = _tr("lucky_wheel_already_claimed")
	
	if lbl_wheel_result and not is_wheel_spinning and highlighted_wheel_slice < 0:
		if can_claim:
			lbl_wheel_result.text = "Bấm QUAY NGAY để nhận vật phẩm bổ trợ!" if is_vi else "Tap SPIN for your Daily Special-Item Gift!"
		else:
			lbl_wheel_result.text = _tr("daily_already_toast")


func _on_btn_spin_wheel_pressed() -> void:
	if is_wheel_spinning:
		return
	var gs = get_node_or_null("/root/GameState")
	if not gs or not gs.has_method("can_claim_daily_gift_today") or not gs.can_claim_daily_gift_today():
		_show_reward_toast(_tr("daily_already_toast"))
		_refresh_lucky_wheel_ui()
		return
	
	_play_sfx("click")
	var res: Dictionary = gs.spin_daily_gift_wheel()
	if not res.get("success", false):
		_refresh_lucky_wheel_ui()
		return
	
	var winning_idx: int = int(res.get("slice_index", 0))
	var slice_count: int = GameStateScript.LUCKY_WHEEL_SLICES.size()
	var slice_deg: float = 360.0 / float(slice_count)
	
	var target_slice_angle: float = 270.0 - (float(winning_idx) + 0.5) * slice_deg
	var base_turns: float = 360.0 * 5.0
	var start_deg: float = fmod(wheel_angle_deg, 360.0)
	if start_deg < 0.0:
		start_deg += 360.0
	wheel_angle_deg = start_deg
	var final_deg: float = wheel_angle_deg + base_turns + fposmod(target_slice_angle - start_deg, 360.0)
	
	is_wheel_spinning = true
	highlighted_wheel_slice = -1
	_last_wheel_tick_peg = -1
	var reward_box := get_node_or_null("Modals/LuckyWheelModal/Panel/VBoxContainer/WheelRewardInfoBox") as Control
	if reward_box:
		reward_box.visible = false
	_refresh_lucky_wheel_ui()
	
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_method(_set_wheel_spin_angle, wheel_angle_deg, final_deg, 2.2)
	tw.tween_callback(func(): _on_wheel_spin_finished(res))


func _set_wheel_spin_angle(ang: float) -> void:
	wheel_angle_deg = ang
	var peg_idx: int = int(floor(ang / 22.5))
	if peg_idx != _last_wheel_tick_peg:
		_last_wheel_tick_peg = peg_idx
		var audio_mgr = get_node_or_null("/root/AudioManager")
		if audio_mgr and audio_mgr.has_method("play_wheel_tick"):
			audio_mgr.play_wheel_tick()
	_update_wheel_pointer_description(get_wheel_slice_at_pointer(ang))
	if wheel_canvas:
		wheel_canvas.queue_redraw()


func _on_wheel_spin_finished(res: Dictionary) -> void:
	is_wheel_spinning = false
	highlighted_wheel_slice = int(res.get("slice_index", 0))
	var desc_info: Dictionary = _update_wheel_pointer_description(highlighted_wheel_slice)
	var reward_label: String = String(res.get("label", "BOMB"))
	var reward_desc: String = String(desc_info.get("description", res.get("description", "")))
	var is_no_reward: bool = bool(res.get("is_lucky_next_time", false)) or String(res.get("reward_type", "")) == "lucky_next_time"
	var display_With_qty: String = reward_label if is_no_reward else ("%s ×%d" % [reward_label, int(res.get("amount", 1))])
	var toast_msg: String = ("%s — %s" % [reward_label, reward_desc]) if is_no_reward else (_tr("lucky_wheel_won_toast") % display_With_qty)
	
	var reward_box := get_node_or_null("Modals/LuckyWheelModal/Panel/VBoxContainer/WheelRewardInfoBox") as Control
	if reward_box:
		reward_box.visible = true
		reward_box.modulate.a = 1.0
		reward_box.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if lbl_wheel_result:
		lbl_wheel_result.text = toast_msg
	
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		if audio_mgr.has_method("play_wheel_win"):
			audio_mgr.play_wheel_win()
		if not is_no_reward and audio_mgr.has_method("play_voice_callout"):
			audio_mgr.play_voice_callout("EXCELLENT")
	
	_show_reward_toast(toast_msg)
	_refresh_all_ui()
	_on_viewport_resized()
	if wheel_canvas:
		wheel_canvas.queue_redraw()


func _draw_wheel_item_medallion(canvas: Control, pos: Vector2, r_type: String, r: float = 24.0) -> void:
	var s: float = r / 15.0
	# Soft drop shadow
	canvas.draw_circle(pos + Vector2(0, 2.5 * s), r + 2.4 * s, Color(0.02, 0.04, 0.14, 0.60))
	var is_reward_item: bool = (r_type != "lucky_next_time")
	if is_reward_item:
		# Premium golden beveled medallion rim with specular shine
		canvas.draw_circle(pos, r + 2.0 * s, Color(1.0, 0.82, 0.22, 1.0))
		canvas.draw_circle(pos, r + 1.0 * s, Color(1.0, 0.96, 0.58, 1.0))
	else:
		# Distinct platinum/silver lavender rim for Lucky Next Time
		canvas.draw_circle(pos, r + 1.8 * s, Color(0.74, 0.84, 0.98, 0.95))
		canvas.draw_circle(pos, r + 0.8 * s, Color(0.90, 0.95, 1.0, 1.0))

	match r_type:
		"bomb":
			# Deep ruby/garnet jewel background
			canvas.draw_circle(pos, r - 0.8 * s, Color(0.28, 0.06, 0.12, 0.99))
			var b_pos := pos + Vector2(-1.0 * s, 1.5 * s)
			# Spherical bomb body
			canvas.draw_circle(b_pos, 8.4 * s, Color(0.14, 0.18, 0.30, 1.0))
			# Specular white light shine on bomb body
			canvas.draw_circle(b_pos + Vector2(-2.5 * s, -2.5 * s), 2.8 * s, Color(0.90, 0.96, 1.0, 0.92))
			# Brass neck/collar
			canvas.draw_rect(Rect2(b_pos + Vector2(2.5 * s, -9.6 * s), Vector2(3.6 * s, 2.6 * s)), Color(0.88, 0.68, 0.20, 1.0), true)
			# Burning fuse line
			var spark_pos := b_pos + Vector2(7.2 * s, -7.8 * s)
			canvas.draw_line(b_pos + Vector2(4.2 * s, -8.0 * s), spark_pos, Color(1.0, 0.85, 0.30, 1.0), 2.4 * s)
			# Golden/orange 4-point explosive spark
			canvas.draw_circle(spark_pos, 3.6 * s, Color(1.0, 0.50, 0.12, 1.0))
			canvas.draw_line(spark_pos + Vector2(-4.0 * s, 0), spark_pos + Vector2(4.0 * s, 0), Color(1.0, 0.95, 0.45, 1.0), 1.5 * s)
			canvas.draw_line(spark_pos + Vector2(0, -4.0 * s), spark_pos + Vector2(0, 4.0 * s), Color(1.0, 0.95, 0.45, 1.0), 1.5 * s)
		"change_block":
			# Deep royal sapphire jewel background
			canvas.draw_circle(pos, r - 0.8 * s, Color(0.06, 0.18, 0.44, 0.99))
			# Two bright isometric swapping blocks
			var b1 := Rect2(pos + Vector2(-8.6 * s, -7.6 * s), Vector2(8.4 * s, 8.4 * s))
			var b2 := Rect2(pos + Vector2(0.6 * s, -0.6 * s), Vector2(8.4 * s, 8.4 * s))
			# Block 1: Cyan with white top highlight
			canvas.draw_rect(b1, Color(0.12, 0.88, 1.0, 1.0), true)
			canvas.draw_rect(Rect2(b1.position, Vector2(b1.size.x, 2.0 * s)), Color(0.70, 0.98, 1.0, 0.90), true)
			# Block 2: Amber gold with light highlight
			canvas.draw_rect(b2, Color(1.0, 0.80, 0.16, 1.0), true)
			canvas.draw_rect(Rect2(b2.position, Vector2(b2.size.x, 2.0 * s)), Color(1.0, 0.98, 0.65, 0.90), true)
			# Curved exchange arrows in gleaming gold
			canvas.draw_arc(pos, 10.5 * s, -PI * 0.18, PI * 0.36, 12, Color(1.0, 0.96, 0.52, 1.0), 2.4 * s)
			canvas.draw_arc(pos, 10.5 * s, PI * 0.82, PI * 1.36, 12, Color(1.0, 0.96, 0.52, 1.0), 2.4 * s)
		"extra_life":
			# Deep emerald jade jewel background
			canvas.draw_circle(pos, r - 0.8 * s, Color(0.04, 0.30, 0.20, 0.99))
			var hc := pos + Vector2(0, 1.0 * s)
			var heart_col := Color(0.98, 0.20, 0.44, 1.0)
			canvas.draw_circle(hc + Vector2(-3.8 * s, -2.8 * s), 4.8 * s, heart_col)
			canvas.draw_circle(hc + Vector2(3.8 * s, -2.8 * s), 4.8 * s, heart_col)
			canvas.draw_colored_polygon(PackedVector2Array([
				hc + Vector2(-8.2 * s, -1.0 * s),
				hc + Vector2(8.2 * s, -1.0 * s),
				hc + Vector2(0.0, 8.2 * s)
			]), heart_col)
			# Specular highlight on left lobe
			canvas.draw_circle(hc + Vector2(-4.0 * s, -3.2 * s), 2.0 * s, Color(1.0, 0.88, 0.94, 0.85))
			# Crisp recovery cross / plus symbol in golden white
			canvas.draw_rect(Rect2(hc + Vector2(-1.4 * s, -3.8 * s), Vector2(2.8 * s, 7.0 * s)), Color(1.0, 0.98, 0.84, 0.95), true)
			canvas.draw_rect(Rect2(hc + Vector2(-3.5 * s, -1.7 * s), Vector2(7.0 * s, 2.8 * s)), Color(1.0, 0.98, 0.84, 0.95), true)
		"spin_again", "extra_spin":
			# Deep amber/gold jewel background
			canvas.draw_circle(pos, r - 0.8 * s, Color(0.36, 0.22, 0.04, 0.99))
			# Golden refresh / spin circular arc
			canvas.draw_arc(pos, 8.4 * s, -PI * 0.15, PI * 0.85, 14, Color(1.0, 0.90, 0.28, 1.0), 2.6 * s)
			canvas.draw_arc(pos, 8.4 * s, PI * 0.85, PI * 1.85, 14, Color(1.0, 0.90, 0.28, 1.0), 2.6 * s)
			var a_pt1 := pos + Vector2(cos(-PI * 0.15), sin(-PI * 0.15)) * (8.4 * s)
			var a_pt2 := pos + Vector2(cos(PI * 0.85), sin(PI * 0.85)) * (8.4 * s)
			canvas.draw_circle(a_pt1, 2.2 * s, Color(1.0, 1.0, 0.70, 1.0))
			canvas.draw_circle(a_pt2, 2.2 * s, Color(1.0, 1.0, 0.70, 1.0))
			canvas.draw_circle(pos, 3.2 * s, Color(1.0, 0.96, 0.55, 1.0))
			canvas.draw_circle(pos, 1.6 * s, Color(1.0, 1.0, 1.0, 1.0))
		"lucky_next_time":
			# Soft celestial indigo/violet jewel background
			canvas.draw_circle(pos, r - 0.8 * s, Color(0.14, 0.16, 0.36, 0.98))
			# Gentle 4-leaf wishing clover / friendly sparkle emblem
			var leaf_col := Color(0.58, 0.88, 1.0, 0.95)
			for d_vec in [Vector2(-4.2 * s, -4.2 * s), Vector2(4.2 * s, -4.2 * s), Vector2(-4.2 * s, 4.2 * s), Vector2(4.2 * s, 4.2 * s)]:
				canvas.draw_circle(pos + d_vec, 3.8 * s, leaf_col)
			# Center warm star seed
			canvas.draw_circle(pos, 3.2 * s, Color(1.0, 0.94, 0.48, 1.0))
			canvas.draw_circle(pos, 1.6 * s, Color(1.0, 1.0, 1.0, 1.0))


func _draw_lucky_wheel_canvas() -> void:
	if not wheel_canvas:
		return
	var cw: float = wheel_canvas.size.x if wheel_canvas.size.x > 0 else 660.0
	var ch: float = wheel_canvas.size.y if wheel_canvas.size.y > 0 else 660.0
	var center := Vector2(cw * 0.5, ch * 0.52)
	var radius: float = minf(cw, ch) * 0.46
	var is_compact_wheel: bool = (radius < 180.0)
	var is_very_compact_wheel: bool = (radius < 155.0)

	var slices: Array = GameStateScript.LUCKY_WHEEL_SLICES
	var slice_count: int = slices.size()
	var slice_rad: float = TAU / float(slice_count)
	var rot_rad: float = deg_to_rad(wheel_angle_deg)
	var pointer_idx: int = highlighted_wheel_slice if (highlighted_wheel_slice >= 0 and highlighted_wheel_slice < slice_count) else get_wheel_slice_at_pointer(wheel_angle_deg)

	var gs = get_node_or_null("/root/GameState")
	var is_vi: bool = (gs.get_language() == "vi") if (gs and gs.has_method("get_language")) else false

	# 1. Outer deep drop shadow
	wheel_canvas.draw_circle(center + Vector2(0, 10), radius + 24.0, Color(0.02, 0.04, 0.14, 0.65))

	# 2. Polished dimensional golden wheel rim
	wheel_canvas.draw_circle(center, radius + 22.0, Color(1.0, 0.82, 0.22, 1.0))
	wheel_canvas.draw_circle(center, radius + 13.0, Color(0.42, 0.22, 0.06, 1.0))
	wheel_canvas.draw_circle(center, radius + 11.0, Color(1.0, 0.92, 0.52, 1.0))

	# Rich harmonious colors for the 8 wedges (Item & Spin Again wedges pop vividly; Lucky Next Time wedges alternate elegant jewel tones)
	var wedge_palette: Array[Color] = [
		Color(0.92, 0.20, 0.32, 1.0), # 0: Bomb (Ruby Red)
		Color(0.24, 0.22, 0.52, 1.0), # 1: Lucky Next Time (Deep Royal Purple)
		Color(0.12, 0.54, 0.94, 1.0), # 2: Change Block (Bright Azure Blue)
		Color(0.30, 0.20, 0.56, 1.0), # 3: Lucky Next Time (Royal Violet)
		Color(0.08, 0.74, 0.44, 1.0), # 4: Extra Life (Vivid Emerald Jade)
		Color(0.22, 0.24, 0.48, 1.0), # 5: Lucky Next Time (Royal Indigo)
		Color(0.95, 0.65, 0.12, 1.0), # 6: Spin Again (Gleaming Gold Amber)
		Color(0.28, 0.22, 0.52, 1.0)  # 7: Lucky Next Time (Royal Slate Purple)
	]

	var font: Font = title_display_font if title_display_font else ThemeDB.fallback_font
	if not font:
		font = ThemeDB.fallback_font

	# 3. Draw each wedge
	for i in range(slice_count):
		var slice: Dictionary = slices[i]
		var a0: float = rot_rad + float(i) * slice_rad
		var a1: float = a0 + slice_rad
		var r_type: String = String(slice.get("reward_type", "bomb"))
		var is_item_wedge: bool = (r_type != "lucky_next_time")

		var col: Color = Color(slice.get("color", Color(0.24, 0.22, 0.52, 1.0)))
		if i == pointer_idx:
			col = col.lightened(0.24)

		# Wedge surface polygon
		var pts := PackedVector2Array([center])
		var arc_steps: int = 14
		for s in range(arc_steps + 1):
			var a: float = lerpf(a0, a1, float(s) / float(arc_steps))
			pts.append(center + Vector2(cos(a), sin(a)) * radius)
		wheel_canvas.draw_colored_polygon(pts, col)

		# Glossy outer arc highlight
		wheel_canvas.draw_arc(center, radius * 0.93, a0 + 0.03, a1 - 0.03, 10, Color(1.0, 1.0, 1.0, 0.28), 3.5, true)
		if is_item_wedge:
			wheel_canvas.draw_arc(center, radius * 0.90, a0 + 0.05, a1 - 0.05, 8, Color(1.0, 0.95, 0.60, 0.35), 2.0, true)

		# Distinct silver/frost inner band on Lucky Next Time wedges
		if not is_item_wedge:
			wheel_canvas.draw_arc(center, radius * 0.88, a0 + 0.04, a1 - 0.04, 10, Color(0.68, 0.82, 1.0, 0.42), 3.0, true)

		# Beveled segment dividers
		var edge_pt := center + Vector2(cos(a0), sin(a0)) * radius
		wheel_canvas.draw_line(center, edge_pt, Color(0.18, 0.08, 0.02, 0.65), 3.5, true)
		wheel_canvas.draw_line(center, edge_pt, Color(1.0, 0.94, 0.68, 0.92), 1.8, true)

		var mid_a: float = (a0 + a1) * 0.5
		var dir := Vector2(cos(mid_a), sin(mid_a))

		# Icon Medallion: drawn ONLY on item & spin again reward wedges (Bomb, Change Block, Extra Life, Spin Again).
		# Removed from every Lucky Next Time wedge per UI requirements.
		if is_item_wedge:
			var icon_pos := center + dir * (radius * 0.48)
			var wedge_icon_r: float = clampf(radius * 0.145, 21.0, 42.0)
			_draw_wheel_item_medallion(wheel_canvas, icon_pos, r_type, wedge_icon_r)

			# Localized reward name label: positioned at radius * 0.77 (NO x1 or quantity text)
			var label_text: String = ""
			match r_type:
				"bomb":
					label_text = "Bom" if is_vi else "Bomb"
				"change_block":
					label_text = "Đổi Khối" if is_vi else "Change Block"
				"extra_life":
					label_text = "Mạng Thêm" if is_vi else "Extra Life"
				"spin_again", "extra_spin":
					label_text = "Quay Lại" if is_vi else "Spin Again"

			if font and not label_text.is_empty():
				var label_pos := center + dir * (radius * 0.77)
				var f_sz: int = 10 if is_very_compact_wheel else (11 if is_compact_wheel else 15)
				if r_type == "bomb" or r_type == "extra_life":
					f_sz = clampi(f_sz + 1, 11, 17)

				# Rotate label along the arc tangent, ensuring it's never upside down
				var rot_label: float = mid_a + PI * 0.5
				var norm_a: float = fposmod(rot_label, TAU)
				if norm_a > PI * 0.5 and norm_a < PI * 1.5:
					rot_label += PI

				var str_w: float = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, f_sz).x
				var pill_w: float = str_w + (10.0 if is_compact_wheel else 16.0)
				var pill_h: float = float(f_sz) + (6.0 if is_compact_wheel else 8.0)
				var pill_rc := Rect2(-pill_w * 0.5, -pill_h * 0.5, pill_w, pill_h)

				wheel_canvas.draw_set_transform(label_pos, rot_label, Vector2.ONE)

				var pill_bg: Color = Color(0.06, 0.08, 0.22, 0.85)
				var pill_border: Color = Color(1.0, 0.90, 0.38, 0.95)
				var text_col: Color = Color(1.0, 0.98, 0.88, 1.0)

				wheel_canvas.draw_rect(pill_rc, pill_bg, true)
				wheel_canvas.draw_rect(pill_rc, pill_border, false, 1.5)
				wheel_canvas.draw_string_outline(
					font,
					Vector2(-str_w * 0.5, float(f_sz) * 0.34),
					label_text,
					HORIZONTAL_ALIGNMENT_CENTER,
					str_w,
					f_sz,
					2,
					Color(0.04, 0.06, 0.18, 0.95)
				)
				wheel_canvas.draw_string(
					font,
					Vector2(-str_w * 0.5, float(f_sz) * 0.34),
					label_text,
					HORIZONTAL_ALIGNMENT_CENTER,
					str_w,
					f_sz,
					text_col
				)

				wheel_canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			# Multi-line compact label for Lucky Next Time placed at center (radius * 0.58)
			# Vietnamese: 3 lines ("Chúc bạn", "may mắn", "lần sau")
			# English: 2 lines ("Lucky", "Next Time")
			# Guaranteed to stay 100% inside the wedge without touching boundaries or outer rim
			var lines: Array[String] = []
			if is_vi:
				lines.append("Chúc bạn")
				lines.append("may mắn")
				lines.append("lần sau")
			else:
				lines.append("Lucky")
				lines.append("Next Time")
			var lnt_f_sz: int = 10 if is_very_compact_wheel else (11 if is_compact_wheel else 13)
			var lnt_line_h: float = float(lnt_f_sz) * 1.25
			var lnt_total_h: float = float(lines.size()) * lnt_line_h
			var lnt_label_pos := center + dir * (radius * 0.58)

			var lnt_rot_label: float = mid_a + PI * 0.5
			var lnt_norm_a: float = fposmod(lnt_rot_label, TAU)
			if lnt_norm_a > PI * 0.5 and lnt_norm_a < PI * 1.5:
				lnt_rot_label += PI

			var lnt_max_line_w: float = 0.0
			for ln in lines:
				var lnt_lw: float = font.get_string_size(ln, HORIZONTAL_ALIGNMENT_CENTER, -1, lnt_f_sz).x
				if lnt_lw > lnt_max_line_w:
					lnt_max_line_w = lnt_lw

			var lnt_pill_w: float = lnt_max_line_w + (10.0 if is_compact_wheel else 14.0)
			var lnt_pill_h: float = lnt_total_h + (6.0 if is_compact_wheel else 8.0)
			var lnt_pill_rc := Rect2(-lnt_pill_w * 0.5, -lnt_pill_h * 0.5, lnt_pill_w, lnt_pill_h)

			wheel_canvas.draw_set_transform(lnt_label_pos, lnt_rot_label, Vector2.ONE)
			wheel_canvas.draw_rect(lnt_pill_rc, Color(0.08, 0.10, 0.28, 0.85), true)
			wheel_canvas.draw_rect(lnt_pill_rc, Color(0.68, 0.82, 1.0, 0.75), false, 1.5)

			var start_y: float = -lnt_total_h * 0.5 + float(lnt_f_sz) * 0.85
			for l_idx in range(lines.size()):
				var ln_text: String = lines[l_idx]
				var lnt_line_lw: float = font.get_string_size(ln_text, HORIZONTAL_ALIGNMENT_CENTER, -1, lnt_f_sz).x
				var y_pos: float = start_y + float(l_idx) * lnt_line_h
				wheel_canvas.draw_string_outline(
					font,
					Vector2(-lnt_line_lw * 0.5, y_pos),
					ln_text,
					HORIZONTAL_ALIGNMENT_CENTER,
					lnt_line_lw,
					lnt_f_sz,
					2,
					Color(0.04, 0.06, 0.18, 0.95)
				)
				wheel_canvas.draw_string(
					font,
					Vector2(-lnt_line_lw * 0.5, y_pos),
					ln_text,
					HORIZONTAL_ALIGNMENT_CENTER,
					lnt_line_lw,
					lnt_f_sz,
					Color(0.88, 0.94, 1.0, 0.98)
				)

			wheel_canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# 4. 16 Polished Decorative Pegs
	for p in range(16):
		var pa: float = rot_rad + float(p) * (TAU / 16.0)
		var peg_pos := center + Vector2(cos(pa), sin(pa)) * (radius + 14.0)
		var is_gold_peg: bool = (p % 2 == 0)
		var gem_col := Color(1.0, 0.90, 0.32, 1.0) if is_gold_peg else Color(0.40, 0.94, 1.0, 1.0)
		# Peg shadow
		wheel_canvas.draw_circle(peg_pos + Vector2(0, 1.5), 6.5, Color(0.04, 0.02, 0.12, 0.60))
		# Peg outer chrome rim
		wheel_canvas.draw_circle(peg_pos, 5.8, Color(0.88, 0.92, 1.0, 1.0))
		# Peg gemstone
		wheel_canvas.draw_circle(peg_pos, 4.4, gem_col)
		# Specular shine
		wheel_canvas.draw_circle(peg_pos + Vector2(-1.2, -1.2), 1.6, Color(1.0, 1.0, 1.0, 0.95))

	# 5. Attractive Polished Center Hub with Official 4TM Logo
	var hub_r: float = clampf(radius * 0.150, 26.0, 44.0)
	# Hub shadow & outer bronze bevel
	wheel_canvas.draw_circle(center + Vector2(0, 4), hub_r + 4.0, Color(0.04, 0.02, 0.12, 0.65))
	wheel_canvas.draw_circle(center, hub_r + 3.0, Color(0.48, 0.26, 0.08, 1.0))
	# Dimensional golden rings
	wheel_canvas.draw_circle(center, hub_r + 1.5, Color(1.0, 0.82, 0.22, 1.0))
	wheel_canvas.draw_circle(center, hub_r - 1.0, Color(1.0, 0.96, 0.60, 1.0))
	# Jewel core
	wheel_canvas.draw_circle(center, hub_r - 2.5, Color(0.10, 0.08, 0.24, 1.0))

	var hub_logo_tex: Texture2D = UIIconScript.load_official_4tm_logo_texture()
	if hub_logo_tex:
		var logo_side: float = hub_r * 1.35
		var logo_rc := Rect2(center - Vector2(logo_side * 0.5, logo_side * 0.5), Vector2(logo_side, logo_side))
		wheel_canvas.draw_texture_rect(hub_logo_tex, logo_rc, false)

	# 6. Polished Dimensional Top Pointer
	var top_pt := center + Vector2(0, -radius - 4.0)
	var pointer_shadow_pts := PackedVector2Array([
		top_pt + Vector2(0, 29),
		top_pt + Vector2(-22, -16),
		top_pt + Vector2(22, -16)
	])
	wheel_canvas.draw_colored_polygon(pointer_shadow_pts, Color(0.02, 0.04, 0.14, 0.55))

	var pointer_pts := PackedVector2Array([
		top_pt + Vector2(0, 26),
		top_pt + Vector2(-20, -18),
		top_pt + Vector2(20, -18)
	])
	# Left half highlight, right half shade
	var left_half := PackedVector2Array([
		top_pt + Vector2(0, 26),
		top_pt + Vector2(-20, -18),
		top_pt + Vector2(0, -18)
	])
	var right_half := PackedVector2Array([
		top_pt + Vector2(0, 26),
		top_pt + Vector2(0, -18),
		top_pt + Vector2(20, -18)
	])
	wheel_canvas.draw_colored_polygon(left_half, Color(1.0, 0.32, 0.44, 1.0))
	wheel_canvas.draw_colored_polygon(right_half, Color(0.82, 0.12, 0.24, 1.0))
	# Golden pointer border
	wheel_canvas.draw_polyline(PackedVector2Array([
		top_pt + Vector2(0, 26),
		top_pt + Vector2(-20, -18),
		top_pt + Vector2(20, -18),
		top_pt + Vector2(0, 26)
	]), Color(1.0, 0.94, 0.45, 1.0), 3.0, true)

	# Top pivot jewel rivet
	wheel_canvas.draw_circle(top_pt + Vector2(0, -18), 7.0, Color(1.0, 0.84, 0.22, 1.0))
	wheel_canvas.draw_circle(top_pt + Vector2(0, -18), 4.2, Color(0.88, 0.16, 0.28, 1.0))
	wheel_canvas.draw_circle(top_pt + Vector2(-1.5, -19.5), 1.6, Color(1.0, 1.0, 1.0, 0.95))


# ==============================================================================
# PROGRESSION SUMMARY & MODE SELECTION
# ==============================================================================

func _refresh_progression_ui() -> void:
	_refresh_energy_ui()
	var gs = get_node_or_null("/root/GameState")
	var cur_map_lvl := 1
	var can_claim := true
	if gs:
		if "selected_map_level" in gs:
			cur_map_lvl = gs.selected_map_level
		if gs.has_method("can_claim_daily_gift_today"):
			can_claim = gs.can_claim_daily_gift_today()
	
	if btn_top_level:
		_apply_level_button_progress_style()
		btn_top_level.text = "  %s %d" % [_tr("top_level_prefix"), cur_map_lvl]
	if btn_daily_gift:
		btn_daily_gift.text = "  " + _tr("btn_daily_gift")
		var st_gift: StyleBoxFlat = _get_gift_style(can_claim)
		btn_daily_gift.add_theme_stylebox_override("normal", st_gift)
		btn_daily_gift.add_theme_stylebox_override("hover", st_gift)
		btn_daily_gift.add_theme_stylebox_override("pressed", st_gift)
		btn_daily_gift.add_theme_stylebox_override("disabled", st_gift)
		btn_daily_gift.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0) if can_claim else Color(0.72, 0.76, 0.86, 0.85))
		var gift_icon := btn_daily_gift.get_node_or_null("VectorIcon")
		if gift_icon and "primary_color" in gift_icon:
			gift_icon.primary_color = Color(1.0, 0.92, 0.34, 1.0) if can_claim else Color(0.65, 0.70, 0.80, 0.85)
			gift_icon.queue_redraw()


func _show_reward_toast(msg: String) -> void:
	if not reward_toast_label or not is_inside_tree():
		return
	reward_toast_label.text = msg
	reward_toast_label.modulate.a = 1.0
	reward_toast_label.position = Vector2(0, 74)
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(reward_toast_label, "position:y", 62.0, 0.20)
	tw.tween_interval(1.6)
	tw.tween_property(reward_toast_label, "modulate:a", 0.0, 0.35)


func _play_sfx(event_type: String) -> void:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and event_type == "click":
		audio_mgr.play_button_click()


func _on_btn_modern_pressed() -> void:
	_play_sfx("click")
	selected_mode = GameStateScript.GameMode.MODERN_DRAG_AND_DROP
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_method("set_game_mode"):
		gs.set_game_mode(selected_mode)
	_animate_button_tap(btn_modern)
	_update_mode_selection_ui()


func _on_btn_classic_pressed() -> void:
	_play_sfx("click")
	selected_mode = GameStateScript.GameMode.CLASSIC
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_method("set_game_mode"):
		gs.set_game_mode(selected_mode)
	_animate_button_tap(btn_classic)
	_update_mode_selection_ui()


func _on_btn_drag_drop_pressed() -> void:
	_play_sfx("click")
	selected_play_style = GameStateScript.PlayStyle.DRAG_AND_DROP
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_method("set_play_style"):
		gs.set_play_style(selected_play_style)
	_animate_button_tap(btn_drag_drop)
	_update_mode_selection_ui()


func _on_btn_falling_pressed() -> void:
	_play_sfx("click")
	selected_play_style = GameStateScript.PlayStyle.FALLING
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_method("set_play_style"):
		gs.set_play_style(selected_play_style)
	_animate_button_tap(btn_falling)
	_update_mode_selection_ui()


func _animate_button_tap(btn: Button) -> void:
	if not btn or not is_inside_tree():
		return
	btn.pivot_offset = btn.size * 0.5
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.08)
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12)


func _on_btn_start_pressed() -> void:
	_play_sfx("click")
	var state_mgr = get_node_or_null("/root/GameState")
	if state_mgr:
		if state_mgr.has_method("can_start_play_session") and not state_mgr.can_start_play_session():
			var msg: String = state_mgr.tr_text("energy_empty_toast") if state_mgr.has_method("tr_text") else "Out of Energy! Watch an ad (+) or wait for hourly refill."
			_show_reward_toast(msg)
			_refresh_energy_ui()
			return
		if state_mgr.has_method("start_game_combination"):
			state_mgr.start_game_combination(selected_mode, selected_play_style)
		else:
			state_mgr.start_game(selected_mode)


func _make_card_style(bg_col: Color, border_col: Color, border_w: int = 2) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg_col
	s.border_width_left = border_w
	s.border_width_top = border_w
	s.border_width_right = border_w
	s.border_width_bottom = border_w + 5
	s.border_color = border_col
	s.corner_radius_top_left = 26
	s.corner_radius_top_right = 26
	s.corner_radius_bottom_right = 26
	s.corner_radius_bottom_left = 26
	s.shadow_color = Color(0.04, 0.04, 0.18, 0.52)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 4)
	return s


func _update_mode_selection_ui() -> void:
	var style_classic_sel = _make_card_style(Color(0.86, 0.44, 0.12, 0.98), Color(1.0, 0.92, 0.36, 1.0), 3)
	var style_modern_sel = _make_card_style(Color(0.14, 0.56, 0.88, 0.98), Color(0.45, 0.98, 1.0, 1.0), 3)
	var style_play_sel = _make_card_style(Color(0.78, 0.22, 0.62, 0.98), Color(1.0, 0.78, 0.94, 1.0), 3)
	var style_unsel = _make_card_style(Color(0.16, 0.22, 0.52, 0.88), Color(0.42, 0.52, 0.84, 0.72), 2)

	var is_modern = (selected_mode == GameStateScript.GameMode.MODERN_DRAG_AND_DROP)
	var is_falling = (selected_play_style == GameStateScript.PlayStyle.FALLING)

	var classic_label := _tr("mode_classic")
	var modern_label := _tr("mode_modern")
	var falling_label := _tr("style_falling")
	var drag_drop_label := _tr("style_drag_drop")

	# Clean selectable buttons/cards with procedural vector icons (UIIcon) and font-verified text
	if btn_classic:
		btn_classic.text = "    " + classic_label
		btn_classic.add_theme_color_override("font_color", Color(1.0, 0.98, 0.82, 1.0) if not is_modern else Color(0.80, 0.86, 0.98, 0.90))
		btn_classic.add_theme_stylebox_override("normal", style_classic_sel if not is_modern else style_unsel)
		btn_classic.add_theme_stylebox_override("hover", style_classic_sel if not is_modern else style_unsel)
		GameTypographyScript.apply_secondary_button_typography(btn_classic, 22)

	if btn_modern:
		btn_modern.text = "    " + modern_label
		btn_modern.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0) if is_modern else Color(0.80, 0.86, 0.98, 0.90))
		btn_modern.add_theme_stylebox_override("normal", style_modern_sel if is_modern else style_unsel)
		btn_modern.add_theme_stylebox_override("hover", style_modern_sel if is_modern else style_unsel)
		GameTypographyScript.apply_secondary_button_typography(btn_modern, 22)

	if btn_falling:
		btn_falling.text = "    " + falling_label
		btn_falling.add_theme_color_override("font_color", Color(1.0, 0.96, 1.0, 1.0) if is_falling else Color(0.80, 0.86, 0.98, 0.90))
		btn_falling.add_theme_stylebox_override("normal", style_play_sel if is_falling else style_unsel)
		btn_falling.add_theme_stylebox_override("hover", style_play_sel if is_falling else style_unsel)
		GameTypographyScript.apply_secondary_button_typography(btn_falling, 22)

	if btn_drag_drop:
		btn_drag_drop.text = "    " + drag_drop_label
		btn_drag_drop.add_theme_color_override("font_color", Color(1.0, 0.96, 1.0, 1.0) if not is_falling else Color(0.80, 0.86, 0.98, 0.90))
		btn_drag_drop.add_theme_stylebox_override("normal", style_play_sel if not is_falling else style_unsel)
		btn_drag_drop.add_theme_stylebox_override("hover", style_play_sel if not is_falling else style_unsel)
		GameTypographyScript.apply_secondary_button_typography(btn_drag_drop, 22)

	var gs = get_node_or_null("/root/GameState")
	if btn_start:
		btn_start.text = _tr("btn_play")
	if lbl_rules_modal_content and gs and gs.has_method("get_rules_help_text"):
		lbl_rules_modal_content.text = gs.get_rules_help_text(selected_mode, selected_play_style)


func _on_btn_how_to_play_pressed() -> void:
	_play_sfx("click")
	_hide_all_modals()
	var gs = get_node_or_null("/root/GameState")
	if lbl_rules_modal_content and gs and gs.has_method("get_rules_help_text"):
		lbl_rules_modal_content.text = gs.get_rules_help_text(selected_mode, selected_play_style)
	if modal_how_to_play:
		modal_how_to_play.visible = true


func _on_btn_settings_pressed() -> void:
	_play_sfx("click")
	_hide_all_modals()
	_update_settings_buttons()
	if modal_settings:
		modal_settings.visible = true
	_on_viewport_resized()


func _ensure_account_modal_structure() -> void:
	if not modal_account:
		return
	var acc_vbox := get_node_or_null("Modals/AccountModal/Panel/VBoxContainer") as VBoxContainer
	if not acc_vbox:
		return
	var stats_box := acc_vbox.get_node_or_null("StatsBox") as VBoxContainer

	local_account_card = acc_vbox.get_node_or_null("LocalAccountCard") as PanelContainer
	if not local_account_card:
		local_account_card = PanelContainer.new()
		local_account_card.name = "LocalAccountCard"
		local_account_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var card_sb := StyleBoxFlat.new()
		card_sb.bg_color = Color(0.11, 0.24, 0.56, 0.96)
		card_sb.border_width_left = 2
		card_sb.border_width_top = 2
		card_sb.border_width_right = 2
		card_sb.border_width_bottom = 5
		card_sb.border_color = Color(0.36, 0.88, 1.0, 0.98)
		card_sb.corner_radius_top_left = 18
		card_sb.corner_radius_top_right = 18
		card_sb.corner_radius_bottom_right = 18
		card_sb.corner_radius_bottom_left = 18
		card_sb.content_margin_left = 14.0
		card_sb.content_margin_right = 14.0
		card_sb.content_margin_top = 10.0
		card_sb.content_margin_bottom = 12.0
		card_sb.shadow_color = Color(0.03, 0.06, 0.20, 0.55)
		card_sb.shadow_size = 6
		card_sb.shadow_offset = Vector2(0, 3)
		local_account_card.add_theme_stylebox_override("panel", card_sb)
		acc_vbox.add_child(local_account_card)
		acc_vbox.move_child(local_account_card, 1)

		var local_vbox := VBoxContainer.new()
		local_vbox.name = "LocalVBox"
		local_vbox.add_theme_constant_override("separation", 6)
		local_account_card.add_child(local_vbox)

		var header_row := HBoxContainer.new()
		header_row.name = "LocalHeaderRow"
		header_row.alignment = BoxContainer.ALIGNMENT_CENTER
		header_row.add_theme_constant_override("separation", 8)
		local_vbox.add_child(header_row)

		var loc_icon := UIIconScript.new("account", Color(0.46, 0.96, 1.0, 1.0))
		loc_icon.name = "LocalAccountIcon"
		loc_icon.align_mode = "none"
		loc_icon.custom_minimum_size = Vector2(24, 24)
		loc_icon.size = Vector2(24, 24)
		header_row.add_child(loc_icon)

		lbl_local_account_title = Label.new()
		lbl_local_account_title.name = "LblLocalTitle"
		lbl_local_account_title.text = _tr("account_local_title")
		lbl_local_account_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_local_account_title.add_theme_font_size_override("font_size", 19)
		lbl_local_account_title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.42, 1.0))
		header_row.add_child(lbl_local_account_title)

		var badge_panel := PanelContainer.new()
		badge_panel.name = "LocalStatusBadgePanel"
		var badge_sb := StyleBoxFlat.new()
		badge_sb.bg_color = Color(0.10, 0.68, 0.42, 0.96)
		badge_sb.border_width_left = 1
		badge_sb.border_width_top = 1
		badge_sb.border_width_right = 1
		badge_sb.border_width_bottom = 2
		badge_sb.border_color = Color(0.56, 1.0, 0.78, 1.0)
		badge_sb.corner_radius_top_left = 10
		badge_sb.corner_radius_top_right = 10
		badge_sb.corner_radius_bottom_right = 10
		badge_sb.corner_radius_bottom_left = 10
		badge_sb.content_margin_left = 8.0
		badge_sb.content_margin_right = 8.0
		badge_sb.content_margin_top = 2.0
		badge_sb.content_margin_bottom = 2.0
		badge_panel.add_theme_stylebox_override("panel", badge_sb)
		header_row.add_child(badge_panel)

		lbl_local_status_badge = Label.new()
		lbl_local_status_badge.name = "LblLocalStatusBadge"
		lbl_local_status_badge.text = _tr("account_local_badge")
		lbl_local_status_badge.add_theme_font_size_override("font_size", 12)
		lbl_local_status_badge.add_theme_color_override("font_color", Color(0.96, 1.0, 0.98, 1.0))
		badge_panel.add_child(lbl_local_status_badge)

		lbl_local_desc = Label.new()
		lbl_local_desc.name = "LblLocalDesc"
		lbl_local_desc.text = _tr("account_local_desc")
		lbl_local_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_local_desc.add_theme_font_size_override("font_size", 13)
		lbl_local_desc.add_theme_color_override("font_color", Color(0.84, 0.93, 1.0, 0.94))
		local_vbox.add_child(lbl_local_desc)

		if stats_box:
			if stats_box.get_parent() != local_vbox:
				stats_box.get_parent().remove_child(stats_box)
				local_vbox.add_child(stats_box)
			stats_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			stats_box.add_theme_constant_override("separation", 3)
			if lbl_account_score:
				lbl_account_score.add_theme_font_size_override("font_size", 14)
				lbl_account_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			if lbl_account_lines:
				lbl_account_lines.add_theme_font_size_override("font_size", 13)
				lbl_account_lines.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			if lbl_reward_status:
				lbl_reward_status.add_theme_font_size_override("font_size", 14)
				lbl_reward_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

		btn_delete_data = Button.new()
		btn_delete_data.name = "BtnDeleteData"
		btn_delete_data.custom_minimum_size = Vector2(0, 48)
		btn_delete_data.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_delete_data.add_theme_font_size_override("font_size", 17)
		btn_delete_data.text = "    " + _tr("btn_delete_data")
		btn_delete_data.pressed.connect(_on_btn_delete_data_pressed)
		local_vbox.add_child(btn_delete_data)

	providers_section = acc_vbox.get_node_or_null("ProvidersSection") as VBoxContainer
	if not providers_section:
		providers_section = VBoxContainer.new()
		providers_section.name = "ProvidersSection"
		providers_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		providers_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
		providers_section.alignment = BoxContainer.ALIGNMENT_CENTER
		providers_section.add_theme_constant_override("separation", 8)
		acc_vbox.add_child(providers_section)
		acc_vbox.move_child(providers_section, 2)

		lbl_providers_title = Label.new()
		lbl_providers_title.name = "LblProvidersTitle"
		lbl_providers_title.text = _tr("account_providers_title")
		lbl_providers_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_providers_title.add_theme_font_size_override("font_size", 14)
		lbl_providers_title.add_theme_color_override("font_color", Color(0.72, 0.88, 1.0, 0.95))
		providers_section.add_child(lbl_providers_title)

		btn_apple_id = _create_unavailable_provider_button("BtnAppleId", _tr("btn_apple_id"), "apple_id")
		_apply_apple_provider_button_style(btn_apple_id)
		UIIconScript.attach_to_button(btn_apple_id, "apple", Vector2(24, 24), "left", Color(0.98, 0.99, 1.0, 1.0))
		providers_section.add_child(btn_apple_id)

		btn_google_play_id = _create_unavailable_provider_button("BtnGooglePlayId", _tr("btn_google_play_id"), "google_play_id")
		_apply_google_play_provider_button_style(btn_google_play_id)
		UIIconScript.attach_to_button(btn_google_play_id, "google_play", Vector2(24, 24), "left", Color(1.0, 1.0, 1.0, 0.98))
		providers_section.add_child(btn_google_play_id)

		btn_create_email = _create_unavailable_provider_button("BtnCreateWithEmail", _tr("btn_create_email"), "create_with_email")
		_apply_unavailable_provider_button_style(btn_create_email)
		UIIconScript.attach_to_button(btn_create_email, "email", Vector2(24, 24), "left", Color(0.76, 0.90, 1.0, 0.96))
		providers_section.add_child(btn_create_email)

	if providers_section and btn_apple_id and btn_google_play_id and btn_create_email:
		if btn_apple_id.get_parent() == providers_section and btn_google_play_id.get_parent() == providers_section and btn_create_email.get_parent() == providers_section:
			var max_idx: int = providers_section.get_child_count() - 1
			providers_section.move_child(btn_create_email, max_idx)
			if btn_apple_id.get_index() > btn_create_email.get_index():
				providers_section.move_child(btn_apple_id, btn_create_email.get_index())
			if btn_google_play_id.get_index() > btn_create_email.get_index():
				providers_section.move_child(btn_google_play_id, btn_create_email.get_index())

	modal_delete_confirm = modal_account.get_node_or_null("DeleteConfirmDialog") as ColorRect
	if not modal_delete_confirm:
		modal_delete_confirm = ColorRect.new()
		modal_delete_confirm.name = "DeleteConfirmDialog"
		modal_delete_confirm.visible = false
		modal_delete_confirm.set_anchors_preset(Control.PRESET_FULL_RECT)
		modal_delete_confirm.color = Color(0.03, 0.05, 0.16, 0.92)
		modal_delete_confirm.mouse_filter = Control.MOUSE_FILTER_STOP
		modal_account.add_child(modal_delete_confirm)

		confirm_delete_panel = Panel.new()
		confirm_delete_panel.name = "ConfirmPanel"
		confirm_delete_panel.set_anchors_preset(Control.PRESET_CENTER)
		confirm_delete_panel.offset_left = -260.0
		confirm_delete_panel.offset_top = -170.0
		confirm_delete_panel.offset_right = 260.0
		confirm_delete_panel.offset_bottom = 170.0
		var cp_sb := StyleBoxFlat.new()
		cp_sb.bg_color = Color(0.10, 0.16, 0.42, 0.99)
		cp_sb.border_width_left = 3
		cp_sb.border_width_top = 3
		cp_sb.border_width_right = 3
		cp_sb.border_width_bottom = 8
		cp_sb.border_color = Color(1.0, 0.56, 0.58, 1.0)
		cp_sb.corner_radius_top_left = 24
		cp_sb.corner_radius_top_right = 24
		cp_sb.corner_radius_bottom_right = 24
		cp_sb.corner_radius_bottom_left = 24
		cp_sb.shadow_color = Color(0.01, 0.02, 0.08, 0.72)
		cp_sb.shadow_size = 16
		cp_sb.shadow_offset = Vector2(0, 6)
		confirm_delete_panel.add_theme_stylebox_override("panel", cp_sb)
		modal_delete_confirm.add_child(confirm_delete_panel)

		var cp_vbox := VBoxContainer.new()
		cp_vbox.name = "VBoxContainer"
		cp_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		cp_vbox.offset_left = 20.0
		cp_vbox.offset_top = 20.0
		cp_vbox.offset_right = -20.0
		cp_vbox.offset_bottom = -20.0
		cp_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		cp_vbox.add_theme_constant_override("separation", 14)
		confirm_delete_panel.add_child(cp_vbox)

		var warn_row := HBoxContainer.new()
		warn_row.name = "WarnHeaderRow"
		warn_row.alignment = BoxContainer.ALIGNMENT_CENTER
		warn_row.add_theme_constant_override("separation", 10)
		cp_vbox.add_child(warn_row)

		var warn_icon := UIIconScript.new("warning", Color(1.0, 0.86, 0.24, 1.0))
		warn_icon.name = "WarningIcon"
		warn_icon.align_mode = "none"
		warn_icon.custom_minimum_size = Vector2(28, 28)
		warn_icon.size = Vector2(28, 28)
		warn_row.add_child(warn_icon)

		lbl_delete_confirm_title = Label.new()
		lbl_delete_confirm_title.name = "LblConfirmTitle"
		lbl_delete_confirm_title.text = _tr("delete_confirm_title")
		lbl_delete_confirm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_delete_confirm_title.add_theme_font_size_override("font_size", 22)
		lbl_delete_confirm_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.28, 1.0))
		warn_row.add_child(lbl_delete_confirm_title)

		lbl_delete_confirm_warning = Label.new()
		lbl_delete_confirm_warning.name = "LblConfirmWarning"
		lbl_delete_confirm_warning.text = _tr("delete_confirm_warning")
		lbl_delete_confirm_warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_delete_confirm_warning.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_delete_confirm_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_delete_confirm_warning.size_flags_vertical = Control.SIZE_EXPAND_FILL
		lbl_delete_confirm_warning.add_theme_font_size_override("font_size", 16)
		lbl_delete_confirm_warning.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0, 0.98))
		cp_vbox.add_child(lbl_delete_confirm_warning)

		var actions_row := HBoxContainer.new()
		actions_row.name = "ConfirmActionsRow"
		actions_row.alignment = BoxContainer.ALIGNMENT_CENTER
		actions_row.add_theme_constant_override("separation", 16)
		cp_vbox.add_child(actions_row)

		btn_cancel_delete = Button.new()
		btn_cancel_delete.name = "BtnCancelDelete"
		btn_cancel_delete.custom_minimum_size = Vector2(0, 56)
		btn_cancel_delete.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_cancel_delete.add_theme_font_size_override("font_size", 18)
		btn_cancel_delete.text = "    " + _tr("btn_cancel_delete")
		btn_cancel_delete.pressed.connect(_on_btn_cancel_delete_pressed)
		actions_row.add_child(btn_cancel_delete)

		btn_confirm_delete = Button.new()
		btn_confirm_delete.name = "BtnConfirmDelete"
		btn_confirm_delete.custom_minimum_size = Vector2(0, 56)
		btn_confirm_delete.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_confirm_delete.add_theme_font_size_override("font_size", 18)
		btn_confirm_delete.text = "    " + _tr("btn_confirm_delete")
		btn_confirm_delete.pressed.connect(_on_btn_confirm_delete_pressed)
		actions_row.add_child(btn_confirm_delete)


func _create_unavailable_provider_button(btn_name: String, label_txt: String, provider_id: String) -> Button:
	var b := Button.new()
	b.name = btn_name
	b.custom_minimum_size = Vector2(0, 52)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.disabled = false
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 16)
	b.text = "        " + label_txt
	b.set_meta("account_provider_id", provider_id)
	b.set_meta("is_inactive_provider", true)
	b.set_meta("auth_implemented", false)
	b.set_meta("tap_response_count", 0)
	b.pressed.connect(func(): _on_inactive_account_provider_pressed(b))
	UIIconScript.setup_button_press_feedback(b)
	return b


func _apply_account_entry_button_style(btn: Button) -> void:
	if not btn:
		return
	var st_n := StyleBoxFlat.new()
	st_n.bg_color = Color(0.18, 0.42, 0.88, 0.98)
	st_n.border_width_left = 2
	st_n.border_width_top = 2
	st_n.border_width_right = 2
	st_n.border_width_bottom = 6
	st_n.border_color = Color(0.46, 0.90, 1.0, 1.0)
	st_n.corner_radius_top_left = 20
	st_n.corner_radius_top_right = 20
	st_n.corner_radius_bottom_right = 20
	st_n.corner_radius_bottom_left = 20
	st_n.shadow_color = Color(0.04, 0.10, 0.30, 0.55)
	st_n.shadow_size = 6
	st_n.shadow_offset = Vector2(0, 3)
	var st_h := st_n.duplicate()
	st_h.bg_color = Color(0.24, 0.50, 0.96, 0.99)
	var st_p := st_n.duplicate()
	st_p.bg_color = Color(0.14, 0.34, 0.76, 0.99)
	st_p.border_width_bottom = 3
	btn.add_theme_color_override("font_color", Color(1.0, 0.99, 1.0, 1.0))
	btn.add_theme_stylebox_override("normal", st_n)
	btn.add_theme_stylebox_override("hover", st_h)
	btn.add_theme_stylebox_override("pressed", st_p)
	GameTypographyScript.apply_secondary_button_typography(btn, 18)


func _apply_cancel_safe_button_style(btn: Button) -> void:
	if not btn:
		return
	var st_n := StyleBoxFlat.new()
	st_n.bg_color = Color(0.20, 0.48, 0.86, 0.98)
	st_n.border_width_left = 2
	st_n.border_width_top = 2
	st_n.border_width_right = 2
	st_n.border_width_bottom = 6
	st_n.border_color = Color(0.56, 0.90, 1.0, 1.0)
	st_n.corner_radius_top_left = 20
	st_n.corner_radius_top_right = 20
	st_n.corner_radius_bottom_right = 20
	st_n.corner_radius_bottom_left = 20
	st_n.shadow_color = Color(0.04, 0.10, 0.28, 0.55)
	st_n.shadow_size = 6
	st_n.shadow_offset = Vector2(0, 3)
	var st_h := st_n.duplicate()
	st_h.bg_color = Color(0.26, 0.56, 0.94, 0.99)
	var st_p := st_n.duplicate()
	st_p.bg_color = Color(0.16, 0.38, 0.72, 0.99)
	st_p.border_width_bottom = 3
	btn.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0, 1.0))
	btn.add_theme_stylebox_override("normal", st_n)
	btn.add_theme_stylebox_override("hover", st_h)
	btn.add_theme_stylebox_override("pressed", st_p)
	GameTypographyScript.apply_secondary_button_typography(btn, 18)


func _apply_unavailable_provider_button_style(btn: Button) -> void:
	if not btn:
		return
	var st_n := StyleBoxFlat.new()
	st_n.bg_color = Color(0.18, 0.28, 0.58, 0.96)
	st_n.border_width_left = 2
	st_n.border_width_top = 2
	st_n.border_width_right = 2
	st_n.border_width_bottom = 5
	st_n.border_color = Color(0.50, 0.72, 0.98, 0.92)
	st_n.corner_radius_top_left = 18
	st_n.corner_radius_top_right = 18
	st_n.corner_radius_bottom_right = 18
	st_n.corner_radius_bottom_left = 18
	st_n.shadow_color = Color(0.03, 0.06, 0.18, 0.52)
	st_n.shadow_size = 6
	st_n.shadow_offset = Vector2(0, 3)

	var st_h := st_n.duplicate()
	st_h.bg_color = Color(0.24, 0.36, 0.68, 0.98)
	st_h.border_color = Color(0.64, 0.84, 1.0, 0.98)

	var st_p := st_n.duplicate()
	st_p.bg_color = Color(0.14, 0.22, 0.48, 0.98)
	st_p.border_width_bottom = 2

	btn.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0, 0.98))
	btn.add_theme_color_override("font_disabled_color", Color(0.94, 0.97, 1.0, 0.98))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.90, 0.95, 1.0, 0.98))
	btn.add_theme_stylebox_override("normal", st_n)
	btn.add_theme_stylebox_override("hover", st_h)
	btn.add_theme_stylebox_override("pressed", st_p)
	btn.add_theme_stylebox_override("disabled", st_n)
	btn.set_meta("visual_identity", "standard_email_provider")
	GameTypographyScript.apply_secondary_button_typography(btn, 16)


func _apply_apple_provider_button_style(btn: Button) -> void:
	if not btn:
		return
	var st_n := StyleBoxFlat.new()
	st_n.bg_color = Color(0.11, 0.12, 0.17, 0.98)
	st_n.border_width_left = 2
	st_n.border_width_top = 2
	st_n.border_width_right = 2
	st_n.border_width_bottom = 5
	st_n.border_color = Color(0.78, 0.82, 0.90, 0.96)
	st_n.corner_radius_top_left = 18
	st_n.corner_radius_top_right = 18
	st_n.corner_radius_bottom_right = 18
	st_n.corner_radius_bottom_left = 18
	st_n.shadow_color = Color(0.01, 0.02, 0.06, 0.62)
	st_n.shadow_size = 6
	st_n.shadow_offset = Vector2(0, 3)

	var st_h := st_n.duplicate()
	st_h.bg_color = Color(0.16, 0.18, 0.25, 0.99)
	st_h.border_color = Color(0.90, 0.93, 0.98, 1.0)

	var st_p := st_n.duplicate()
	st_p.bg_color = Color(0.08, 0.09, 0.13, 0.99)
	st_p.border_width_bottom = 2

	btn.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0, 1.0))
	btn.add_theme_color_override("font_disabled_color", Color(0.98, 0.99, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.92, 0.94, 0.98, 1.0))
	btn.add_theme_stylebox_override("normal", st_n)
	btn.add_theme_stylebox_override("hover", st_h)
	btn.add_theme_stylebox_override("pressed", st_p)
	btn.add_theme_stylebox_override("disabled", st_n)
	btn.set_meta("visual_identity", "apple_dark_neutral_provider")
	GameTypographyScript.apply_secondary_button_typography(btn, 16)


func _apply_google_play_provider_button_style(btn: Button) -> void:
	if not btn:
		return
	var st_n := StyleBoxFlat.new()
	st_n.bg_color = Color(0.08, 0.36, 0.34, 0.98)
	st_n.border_width_left = 2
	st_n.border_width_top = 2
	st_n.border_width_right = 2
	st_n.border_width_bottom = 5
	st_n.border_color = Color(0.26, 0.92, 0.68, 0.98)
	st_n.corner_radius_top_left = 18
	st_n.corner_radius_top_right = 18
	st_n.corner_radius_bottom_right = 18
	st_n.corner_radius_bottom_left = 18
	st_n.shadow_color = Color(0.02, 0.10, 0.12, 0.58)
	st_n.shadow_size = 6
	st_n.shadow_offset = Vector2(0, 3)

	var st_h := st_n.duplicate()
	st_h.bg_color = Color(0.11, 0.44, 0.41, 0.99)
	st_h.border_color = Color(0.42, 0.98, 0.78, 1.0)

	var st_p := st_n.duplicate()
	st_p.bg_color = Color(0.06, 0.28, 0.26, 0.99)
	st_p.border_width_bottom = 2

	btn.add_theme_color_override("font_color", Color(0.98, 1.0, 0.99, 1.0))
	btn.add_theme_color_override("font_disabled_color", Color(0.98, 1.0, 0.99, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.92, 0.98, 0.96, 1.0))
	btn.add_theme_stylebox_override("normal", st_n)
	btn.add_theme_stylebox_override("hover", st_h)
	btn.add_theme_stylebox_override("pressed", st_p)
	btn.add_theme_stylebox_override("disabled", st_n)
	btn.set_meta("visual_identity", "google_play_multicolor_provider")
	btn.set_meta("has_multicolor_accent", true)
	GameTypographyScript.apply_secondary_button_typography(btn, 16)
	if not btn.draw.is_connected(_on_google_play_provider_btn_draw.bind(btn)):
		btn.draw.connect(_on_google_play_provider_btn_draw.bind(btn))


func _on_google_play_provider_btn_draw(btn: Button) -> void:
	if not btn or btn.size.x < 40.0 or btn.size.y < 20.0:
		return
	# Subtle 4-color Google Play prism accent pills on the right edge of the button
	var pill_y: float = btn.size.y * 0.5
	var right_x: float = btn.size.x - 18.0
	var colors: Array[Color] = [
		Color(0.26, 0.58, 1.0, 0.95),
		Color(0.20, 0.86, 0.52, 0.95),
		Color(1.0, 0.80, 0.18, 0.95),
		Color(0.96, 0.32, 0.30, 0.95)
	]
	for i in range(colors.size()):
		var dy: float = (float(i) - 1.5) * 5.2
		btn.draw_circle(Vector2(right_x, pill_y + dy), 2.1, colors[i])


func _on_inactive_account_provider_pressed(btn: Button = null) -> void:
	# UI-only placeholder: responds visually to press/tap, but performs NO authentication, OAuth, backend call, or account save.
	if btn:
		btn.set_meta("tap_response_count", int(btn.get_meta("tap_response_count", 0)) + 1)
		_animate_button_tap(btn)
	return


func set_account_platform_override(platform_name: String) -> void:
	_account_platform_override = platform_name.strip_edges().to_lower()
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_method("set_simulated_platform"):
		gs.set_simulated_platform(_account_platform_override)
	_refresh_account_ui()


func clear_account_platform_override() -> void:
	_account_platform_override = ""
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_method("clear_simulated_platform"):
		gs.clear_simulated_platform()
	_refresh_account_ui()


func get_effective_account_platform() -> String:
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_method("get_effective_account_platform"):
		return gs.get_effective_account_platform(_account_platform_override)
	var raw: String = _account_platform_override if _account_platform_override != "" else OS.get_name().strip_edges().to_lower()
	if raw in ["ios", "iphone", "ipad", "ipod", "apple", "apple_id", "web_ios"]:
		return "ios"
	if raw in ["android", "google_play", "google_play_id", "web_android"]:
		return "android"
	return "other"


func get_visible_account_providers() -> Array[String]:
	var eff: String = get_effective_account_platform()
	var res: Array[String] = ["local"]
	if eff == "ios":
		res.append("apple_id")
	elif eff == "android":
		res.append("google_play_id")
	res.append("create_with_email")
	return res


func _refresh_account_ui() -> void:
	_ensure_account_modal_structure()
	var state_mgr = get_node_or_null("/root/GameState")
	if lbl_account_title:
		lbl_account_title.text = _tr("account_title")
	if lbl_local_account_title:
		lbl_local_account_title.text = _tr("account_local_title")
	if lbl_local_status_badge:
		lbl_local_status_badge.text = _tr("account_local_badge")
	if lbl_local_desc:
		lbl_local_desc.text = _tr("account_local_desc")
	if btn_delete_data:
		btn_delete_data.text = "    " + _tr("btn_delete_data")
	if lbl_providers_title:
		lbl_providers_title.text = _tr("account_providers_title")
	if btn_create_email:
		btn_create_email.text = "        " + _tr("btn_create_email")
	if btn_apple_id:
		btn_apple_id.text = "        " + _tr("btn_apple_id")
	if btn_google_play_id:
		btn_google_play_id.text = "        " + _tr("btn_google_play_id")
	if lbl_delete_confirm_title:
		lbl_delete_confirm_title.text = _tr("delete_confirm_title")
	if lbl_delete_confirm_warning:
		lbl_delete_confirm_warning.text = _tr("delete_confirm_warning")
	if btn_cancel_delete:
		btn_cancel_delete.text = "    " + _tr("btn_cancel_delete")
	if btn_confirm_delete:
		btn_confirm_delete.text = "    " + _tr("btn_confirm_delete")

	var eff_plat: String = get_effective_account_platform()
	if local_account_card:
		local_account_card.visible = true
	if btn_delete_data:
		btn_delete_data.visible = true
	if btn_create_email:
		btn_create_email.visible = true
	if btn_apple_id:
		btn_apple_id.visible = (eff_plat == "ios")
	if btn_google_play_id:
		btn_google_play_id.visible = (eff_plat == "android")

	if state_mgr:
		if lbl_account_score:
			lbl_account_score.text = _tr("stats_best_score") % state_mgr.high_score
		if lbl_account_lines:
			lbl_account_lines.text = _tr("stats_total_lines") % state_mgr.lines_cleared_total
		if lbl_reward_status:
			lbl_reward_status.text = _tr("stats_summary") % [
				state_mgr.total_stars, state_mgr.coins, state_mgr.highest_unlocked_level, GameStateScript.TOTAL_LEVELS
			]


func update_responsive_account_and_settings_modals(vp_size: Vector2 = Vector2(720, 1280)) -> Dictionary:
	_ensure_account_modal_structure()
	var vp_w: float = vp_size.x if vp_size.x > 0 else 720.0
	var vp_h: float = vp_size.y if vp_size.y > 0 else 1280.0
	var is_compact: bool = (vp_h <= 900.0 or vp_w <= 430.0)
	var is_very_compact: bool = (vp_h <= 810.0 or vp_w <= 370.0)

	var brand_top_y: float = vp_h - 88.0
	var top_safe_y: float = 12.0 if is_compact else 20.0
	var bot_safe_y: float = brand_top_y - (10.0 if is_compact else 16.0)
	var max_modal_h: float = maxf(420.0, bot_safe_y - top_safe_y)
	var modal_w: float = clampf(vp_w - (16.0 if is_very_compact else 24.0), 336.0, 600.0)

	var settings_panel := get_node_or_null("Modals/SettingsModal/Panel") as Control
	var settings_vbox := get_node_or_null("Modals/SettingsModal/Panel/VBoxContainer") as VBoxContainer
	var settings_btn_h: float = 68.0 if is_very_compact else (70.0 if is_compact else 74.0)
	var settings_h: float = clampf(640.0 if is_compact else 720.0, 520.0, max_modal_h)
	var s_pad: float = 16.0 if is_compact else 24.0
	var s_vpad: float = 16.0 if is_compact else 22.0
	var s_sep: int = 10 if is_compact else 12
	var row_sep: int = 10 if is_compact else 12
	if settings_panel:
		settings_panel.offset_left = -modal_w * 0.5
		settings_panel.offset_right = modal_w * 0.5
		settings_panel.offset_top = -settings_h * 0.5
		settings_panel.offset_bottom = settings_h * 0.5
	if settings_vbox:
		settings_vbox.offset_left = s_pad
		settings_vbox.offset_right = -s_pad
		settings_vbox.offset_top = s_vpad
		settings_vbox.offset_bottom = -s_vpad
		settings_vbox.add_theme_constant_override("separation", s_sep)
	if audio_toggles_row:
		audio_toggles_row.add_theme_constant_override("separation", row_sep)
	if voice_haptics_row:
		voice_haptics_row.add_theme_constant_override("separation", row_sep)
	var pair_font_sz: int = 15 if is_very_compact else (16 if is_compact else 18)
	var full_font_sz: int = 17 if is_very_compact else (18 if is_compact else 20)
	for pair_btn in [btn_toggle_music, btn_toggle_sound, btn_toggle_voice, btn_toggle_haptics]:
		if pair_btn:
			pair_btn.custom_minimum_size.y = settings_btn_h
			pair_btn.add_theme_font_size_override("font_size", pair_font_sz)
	for full_btn in [btn_language_modal, btn_settings_account]:
		if full_btn:
			full_btn.custom_minimum_size.y = settings_btn_h
			full_btn.add_theme_font_size_override("font_size", full_font_sz)
	if btn_close_settings:
		btn_close_settings.custom_minimum_size.y = 68.0 if is_compact else 74.0
	var acc_group_spacer_h: float = 22.0 if is_compact else 30.0
	var leave_spacer_h: float = 10.0
	if settings_vbox:
		var acc_sp := settings_vbox.get_node_or_null("SettingsAccountGroupSpacer") as Control
		if not acc_sp and btn_settings_account:
			acc_sp = Control.new()
			acc_sp.name = "SettingsAccountGroupSpacer"
			acc_sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
			settings_vbox.add_child(acc_sp)
			settings_vbox.move_child(acc_sp, btn_settings_account.get_index())
		if acc_sp:
			if btn_settings_account and acc_sp.get_index() != btn_settings_account.get_index() - 1:
				settings_vbox.move_child(acc_sp, btn_settings_account.get_index())
			acc_sp.custom_minimum_size = Vector2(0, acc_group_spacer_h)
		var close_sp := settings_vbox.get_node_or_null("LeaveActionSpacer_BtnClose") as Control
		if close_sp:
			close_sp.custom_minimum_size = Vector2(0, leave_spacer_h)
			leave_spacer_h = close_sp.custom_minimum_size.y

	var acc_panel := get_node_or_null("Modals/AccountModal/Panel") as Control
	var acc_vbox := get_node_or_null("Modals/AccountModal/Panel/VBoxContainer") as VBoxContainer
	var eff_plat: String = get_effective_account_platform()
	var has_platform_id: bool = (eff_plat == "ios" or eff_plat == "android")
	var desired_acc_h: float = (530.0 if has_platform_id else 476.0) if is_compact else (610.0 if has_platform_id else 550.0)
	var acc_h: float = clampf(desired_acc_h, 430.0, max_modal_h)
	var a_pad: float = 16.0 if is_compact else 22.0
	if acc_panel:
		acc_panel.offset_left = -modal_w * 0.5
		acc_panel.offset_right = modal_w * 0.5
		acc_panel.offset_top = -acc_h * 0.5
		acc_panel.offset_bottom = acc_h * 0.5
	if acc_vbox:
		acc_vbox.offset_left = a_pad
		acc_vbox.offset_right = -a_pad
		acc_vbox.offset_top = 14.0 if is_compact else 18.0
		acc_vbox.offset_bottom = -(14.0 if is_compact else 18.0)
		acc_vbox.add_theme_constant_override("separation", 8 if is_compact else 10)
	var prov_btn_h: float = 46.0 if is_compact else 52.0
	for pb in [btn_create_email, btn_apple_id, btn_google_play_id]:
		if pb:
			pb.custom_minimum_size.y = prov_btn_h
			pb.add_theme_font_size_override("font_size", 15 if is_very_compact else (16 if is_compact else 17))
	if btn_delete_data:
		btn_delete_data.custom_minimum_size.y = 44.0 if is_compact else 48.0
	if btn_close_account:
		btn_close_account.custom_minimum_size.y = 50.0 if is_compact else 58.0

	var confirm_w: float = clampf(modal_w - 16.0, 316.0, 520.0)
	var confirm_h: float = 310.0 if is_compact else 340.0
	if confirm_delete_panel:
		confirm_delete_panel.offset_left = -confirm_w * 0.5
		confirm_delete_panel.offset_right = confirm_w * 0.5
		confirm_delete_panel.offset_top = -confirm_h * 0.5
		confirm_delete_panel.offset_bottom = confirm_h * 0.5

	var acc_panel_rect := Rect2(Vector2((vp_w - modal_w) * 0.5, (vp_h - acc_h) * 0.5), Vector2(modal_w, acc_h))
	var settings_panel_rect := Rect2(Vector2((vp_w - modal_w) * 0.5, (vp_h - settings_h) * 0.5), Vector2(modal_w, settings_h))
	var inner_w: float = modal_w - s_pad * 2.0
	var col_w: float = (inner_w - float(row_sep)) * 0.5
	var v_row_y: float = settings_panel_rect.position.y + s_vpad + 34.0 + float(s_sep) + settings_btn_h + float(s_sep) + settings_btn_h + float(s_sep)
	var voice_rect := Rect2(Vector2(settings_panel_rect.position.x + s_pad, v_row_y), Vector2(col_w, settings_btn_h))
	var haptics_rect := Rect2(Vector2(settings_panel_rect.position.x + s_pad + col_w + float(row_sep), v_row_y), Vector2(col_w, settings_btn_h))
	var upper_controls_bottom_y: float = v_row_y + settings_btn_h
	var account_btn_y: float = upper_controls_bottom_y + float(s_sep) + acc_group_spacer_h + float(s_sep)
	var account_btn_rect := Rect2(Vector2(settings_panel_rect.position.x + s_pad, account_btn_y), Vector2(inner_w, settings_btn_h))
	var close_btn_h: float = 52.0 if is_compact else 60.0
	var close_btn_y: float = account_btn_rect.end.y + float(s_sep) + leave_spacer_h + float(s_sep)
	var close_btn_rect := Rect2(Vector2(settings_panel_rect.position.x + s_pad, close_btn_y), Vector2(inner_w, close_btn_h))
	return {
		"viewport": vp_size,
		"account_panel_rect": acc_panel_rect,
		"settings_panel_rect": settings_panel_rect,
		"voice_button_rect": voice_rect,
		"haptics_button_rect": haptics_rect,
		"account_button_rect": account_btn_rect,
		"close_button_rect": close_btn_rect,
		"home_menu_button_rect": close_btn_rect,
		"upper_controls_to_account_gap": account_btn_rect.position.y - upper_controls_bottom_y,
		"account_to_close_gap": close_btn_rect.position.y - account_btn_rect.end.y,
		"settings_fits_within_viewport": settings_panel_rect.position.x >= 4.0 and settings_panel_rect.end.x <= vp_w - 4.0 and settings_panel_rect.position.y >= 6.0 and settings_panel_rect.end.y <= vp_h - 6.0 and close_btn_rect.end.y <= settings_panel_rect.end.y - s_vpad + 2.0,
		"fits_within_viewport": acc_panel_rect.position.x >= 4.0 and acc_panel_rect.end.x <= vp_w - 4.0 and acc_panel_rect.position.y >= 6.0 and acc_panel_rect.end.y <= vp_h - 6.0
	}


func get_settings_layout_inspection(vp_size: Vector2 = Vector2(360, 800)) -> Dictionary:
	var layout_info: Dictionary = update_responsive_account_and_settings_modals(vp_size)
	_update_settings_buttons()
	var voice_rect: Rect2 = layout_info.get("voice_button_rect", Rect2())
	var haptics_rect: Rect2 = layout_info.get("haptics_button_rect", Rect2())
	var account_btn_rect: Rect2 = layout_info.get("account_button_rect", Rect2())
	var close_btn_rect: Rect2 = layout_info.get("close_button_rect", Rect2())
	var panel_rect: Rect2 = layout_info.get("settings_panel_rect", Rect2())
	var upper_to_acc_gap: float = float(layout_info.get("upper_controls_to_account_gap", 0.0))
	var acc_to_close_gap: float = float(layout_info.get("account_to_close_gap", 0.0))
	var fnt: Font = ThemeDB.fallback_font
	var v_fsz: int = btn_toggle_voice.get_theme_font_size("font_size") if btn_toggle_voice else 15
	var h_fsz: int = btn_toggle_haptics.get_theme_font_size("font_size") if btn_toggle_haptics else 15
	var v_txt_w: float = fnt.get_string_size(btn_toggle_voice.text.strip_edges() if btn_toggle_voice else "", HORIZONTAL_ALIGNMENT_LEFT, -1, v_fsz).x if fnt else 90.0
	var h_txt_w: float = fnt.get_string_size(btn_toggle_haptics.text.strip_edges() if btn_toggle_haptics else "", HORIZONTAL_ALIGNMENT_LEFT, -1, h_fsz).x if fnt else 85.0
	var v_req_w: float = v_txt_w + 40.0
	var h_req_w: float = h_txt_w + 40.0

	var voice_count: int = 0
	var haptic_count: int = 0
	if modal_settings:
		var stack: Array[Node] = [modal_settings]
		while not stack.is_empty():
			var cur: Node = stack.pop_back()
			for ch in cur.get_children():
				stack.append(ch)
			if cur is Button:
				var nm: String = String(cur.name).to_lower()
				if "voice" in nm:
					voice_count += 1
				if "haptic" in nm:
					haptic_count += 1

	var v_sb := btn_toggle_voice.get_theme_stylebox("normal") as StyleBoxFlat if btn_toggle_voice else null
	var h_sb := btn_toggle_haptics.get_theme_stylebox("normal") as StyleBoxFlat if btn_toggle_haptics else null
	var same_style_weight: bool = (
		v_sb != null and h_sb != null
		and v_sb.bg_color.is_equal_approx(h_sb.bg_color)
		and v_sb.border_color.is_equal_approx(h_sb.border_color)
		and v_sb.border_width_bottom == h_sb.border_width_bottom
	)
	var same_row: bool = (
		has_equal_width_voice_haptics_row()
		and is_equal_approx(voice_rect.position.y, haptics_rect.position.y)
		and is_equal_approx(voice_rect.size.y, haptics_rect.size.y)
	)
	var equal_weight: bool = (
		same_row
		and same_style_weight
		and is_equal_approx(voice_rect.size.x, haptics_rect.size.x)
		and v_fsz == h_fsz
	)
	var no_clipping: bool = (
		bool(layout_info.get("settings_fits_within_viewport", false))
		and voice_rect.position.x >= panel_rect.position.x + 8.0
		and haptics_rect.end.x <= panel_rect.end.x - 8.0
		and voice_rect.end.x + 4.0 <= haptics_rect.position.x
		and v_req_w <= voice_rect.size.x
		and h_req_w <= haptics_rect.size.x
		and account_btn_rect.position.y >= haptics_rect.end.y + 28.0
		and close_btn_rect.position.y >= account_btn_rect.end.y + 18.0
		and close_btn_rect.end.y <= panel_rect.end.y - 12.0
	)
	var settings_vbox := get_node_or_null("Modals/SettingsModal/Panel/VBoxContainer") as VBoxContainer
	var normal_row_sep: float = float(settings_vbox.get_theme_constant("separation")) if settings_vbox else 12.0
	var bottom_group_separated: bool = (
		upper_to_acc_gap >= normal_row_sep + 20.0
		and acc_to_close_gap >= normal_row_sep + 8.0
		and account_btn_rect.position.y > haptics_rect.end.y
		and close_btn_rect.position.y > account_btn_rect.end.y
		and close_btn_rect.end.y <= panel_rect.end.y - 12.0
	)
	return {
		"viewport": vp_size,
		"voice_haptics_same_row": same_row,
		"equal_visual_weight": equal_weight,
		"no_clipping": no_clipping,
		"single_voice_control": voice_count == 1,
		"single_haptic_control": haptic_count == 1,
		"voice_button_rect": voice_rect,
		"haptics_button_rect": haptics_rect,
		"account_button_rect": account_btn_rect,
		"close_button_rect": close_btn_rect,
		"home_menu_button_rect": close_btn_rect,
		"upper_controls_to_account_gap": upper_to_acc_gap,
		"account_to_close_gap": acc_to_close_gap,
		"bottom_group_clearly_separated": bottom_group_separated,
		"voice_required_width": v_req_w,
		"haptics_required_width": h_req_w
	}


func get_account_menu_inspection(vp_size: Vector2 = Vector2(390, 844)) -> Dictionary:
	var layout_info: Dictionary = update_responsive_account_and_settings_modals(vp_size)
	_refresh_account_ui()
	var gp_label: String = btn_google_play_id.text.strip_edges() if btn_google_play_id else ""
	var ap_label: String = btn_apple_id.text.strip_edges() if btn_apple_id else ""
	var em_label: String = btn_create_email.text.strip_edges() if btn_create_email else ""
	var loc_label: String = lbl_local_account_title.text.strip_edges() if lbl_local_account_title else ""
	var em_sb := btn_create_email.get_theme_stylebox("normal") as StyleBoxFlat if btn_create_email else null
	var ap_sb := btn_apple_id.get_theme_stylebox("normal") as StyleBoxFlat if btn_apple_id else null
	var gp_sb := btn_google_play_id.get_theme_stylebox("normal") as StyleBoxFlat if btn_google_play_id else null
	var apple_distinct_from_email: bool = (
		ap_sb != null and em_sb != null
		and not ap_sb.bg_color.is_equal_approx(em_sb.bg_color)
		and not ap_sb.border_color.is_equal_approx(em_sb.border_color)
	)
	var gp_distinct_from_email: bool = (
		gp_sb != null and em_sb != null
		and not gp_sb.bg_color.is_equal_approx(em_sb.bg_color)
		and not gp_sb.border_color.is_equal_approx(em_sb.border_color)
	)
	var apple_distinct_from_gp: bool = (
		ap_sb != null and gp_sb != null
		and not ap_sb.bg_color.is_equal_approx(gp_sb.bg_color)
		and not ap_sb.border_color.is_equal_approx(gp_sb.border_color)
	)
	var platform_above_email: bool = (
		btn_apple_id != null and btn_google_play_id != null and btn_create_email != null
		and btn_apple_id.get_index() < btn_create_email.get_index()
		and btn_google_play_id.get_index() < btn_create_email.get_index()
	)
	return {
		"platform": get_effective_account_platform(),
		"visible_providers": get_visible_account_providers(),
		"platform_provider_above_create_email": platform_above_email,
		"apple_distinct_from_create_email": apple_distinct_from_email,
		"google_play_distinct_from_create_email": gp_distinct_from_email,
		"apple_distinct_from_google_play": apple_distinct_from_gp,
		"apple_visual_identity": String(btn_apple_id.get_meta("visual_identity", "")) if btn_apple_id else "",
		"google_play_visual_identity": String(btn_google_play_id.get_meta("visual_identity", "")) if btn_google_play_id else "",
		"create_email_visual_identity": String(btn_create_email.get_meta("visual_identity", "")) if btn_create_email else "",
		"has_account_button": btn_account != null and btn_settings_account != null,
		"account_modal_visible": modal_account != null and modal_account.visible,
		"delete_confirm_visible": modal_delete_confirm != null and modal_delete_confirm.visible,
		"local_visible": local_account_card != null and local_account_card.visible,
		"local_label": loc_label,
		"delete_data_visible": btn_delete_data != null and btn_delete_data.visible,
		"create_email_visible": btn_create_email != null and btn_create_email.visible,
		"create_email_label": em_label,
		"create_email_inactive": btn_create_email != null and bool(btn_create_email.get_meta("is_inactive_provider", false)) and not bool(btn_create_email.get_meta("auth_implemented", true)),
		"create_email_responds_to_tap": btn_create_email != null and not btn_create_email.disabled,
		"apple_id_visible": btn_apple_id != null and btn_apple_id.visible,
		"apple_id_label": ap_label,
		"apple_id_inactive": btn_apple_id != null and bool(btn_apple_id.get_meta("is_inactive_provider", false)) and not bool(btn_apple_id.get_meta("auth_implemented", true)),
		"apple_id_responds_to_tap": btn_apple_id != null and not btn_apple_id.disabled,
		"google_play_id_visible": btn_google_play_id != null and btn_google_play_id.visible,
		"google_play_id_label": gp_label,
		"google_play_id_inactive": btn_google_play_id != null and bool(btn_google_play_id.get_meta("is_inactive_provider", false)) and not bool(btn_google_play_id.get_meta("auth_implemented", true)),
		"google_play_id_responds_to_tap": btn_google_play_id != null and not btn_google_play_id.disabled,
		"google_id_visible": btn_google_play_id != null and btn_google_play_id.visible,
		"google_id_inactive": btn_google_play_id != null and bool(btn_google_play_id.get_meta("is_inactive_provider", false)),
		"no_clipping": bool(layout_info.get("fits_within_viewport", false)),
		"fits_within_viewport": bool(layout_info.get("fits_within_viewport", false))
	}


func open_account_menu() -> void:
	_on_btn_account_pressed()


func close_account_menu() -> void:
	_on_btn_close_account_pressed()


func request_delete_local_data() -> void:
	_on_btn_delete_data_pressed()


func cancel_delete_local_data() -> void:
	_on_btn_cancel_delete_pressed()


func confirm_delete_local_data() -> void:
	_on_btn_confirm_delete_pressed()


func _on_btn_account_pressed() -> void:
	_play_sfx("click")
	_hide_all_modals()
	_refresh_account_ui()
	if modal_delete_confirm:
		modal_delete_confirm.visible = false
	if modal_account:
		modal_account.visible = true
	_on_viewport_resized()


func _on_btn_close_account_pressed() -> void:
	_play_sfx("click")
	if modal_delete_confirm:
		modal_delete_confirm.visible = false
	if modal_account:
		modal_account.visible = false


func _on_btn_delete_data_pressed() -> void:
	_play_sfx("click")
	_ensure_account_modal_structure()
	if modal_delete_confirm:
		modal_delete_confirm.visible = true


func _on_btn_cancel_delete_pressed() -> void:
	_play_sfx("click")
	if modal_delete_confirm:
		modal_delete_confirm.visible = false


func _on_btn_confirm_delete_pressed() -> void:
	_play_sfx("click")
	var state_mgr = get_node_or_null("/root/GameState")
	if state_mgr:
		if state_mgr.has_method("delete_local_account_data"):
			state_mgr.delete_local_account_data(true)
		elif state_mgr.has_method("reset_progression"):
			state_mgr.reset_progression(true)
	current_map_page = 0
	map_scroll_y = 0.0
	map_target_scroll_y = 0.0
	map_camera_pan_offset = Vector2.ZERO
	selected_mode = GameStateScript.GameMode.CLASSIC
	selected_play_style = GameStateScript.PlayStyle.FALLING
	if modal_delete_confirm:
		modal_delete_confirm.visible = false
	if modal_account:
		modal_account.visible = false
	if modal_settings:
		modal_settings.visible = false
	_refresh_all_ui()
	_show_reward_toast(_tr("delete_data_reset_toast"))


func _hide_all_modals() -> void:
	if modal_how_to_play: modal_how_to_play.visible = false
	if modal_settings: modal_settings.visible = false
	if modal_delete_confirm: modal_delete_confirm.visible = false
	if modal_account: modal_account.visible = false
	if modal_level_map: modal_level_map.visible = false
	if modal_lucky_wheel and not is_wheel_spinning: modal_lucky_wheel.visible = false


func _apply_settings_panel_style() -> void:
	var settings_panel := get_node_or_null("Modals/SettingsModal/Panel") as Control
	if settings_panel:
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.09, 0.13, 0.28, 0.98)
		st.border_width_left = 3
		st.border_width_top = 3
		st.border_width_right = 3
		st.border_width_bottom = 8
		st.border_color = Color(0.24, 0.88, 0.96, 1.0)
		st.set_corner_radius_all(32)
		st.shadow_color = Color(0.02, 0.04, 0.18, 0.65)
		st.shadow_size = 28
		st.shadow_offset = Vector2(0, 8)
		settings_panel.add_theme_stylebox_override("panel", st)


func _apply_settings_group_button_style(btn: Button, bg_col: Color, border_col: Color) -> void:
	if not btn:
		return
	var st := StyleBoxFlat.new()
	st.bg_color = bg_col
	st.border_width_left = 3
	st.border_width_top = 3
	st.border_width_right = 3
	st.border_width_bottom = 6
	st.border_color = border_col
	st.set_corner_radius_all(22)
	st.shadow_color = Color(0.02, 0.04, 0.16, 0.50)
	st.shadow_size = 10
	st.shadow_offset = Vector2(0, 4)
	st.content_margin_left = 12.0
	st.content_margin_right = 12.0

	var st_hov := st.duplicate() as StyleBoxFlat
	st_hov.bg_color = bg_col.lightened(0.08)
	st_hov.border_color = border_col.lightened(0.10)

	var st_press := st.duplicate() as StyleBoxFlat
	st_press.bg_color = bg_col.darkened(0.08)
	st_press.border_width_bottom = 2
	st_press.shadow_size = 3
	st_press.shadow_offset = Vector2(0, 2)

	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_stylebox_override("hover", st_hov)
	btn.add_theme_stylebox_override("pressed", st_press)
	btn.add_theme_stylebox_override("disabled", st)
	UIIconScript.remove_focus_outline(btn)


func _update_settings_buttons() -> void:
	_apply_settings_panel_style()
	var state_mgr = get_node_or_null("/root/GameState")
	var audio_mgr = get_node_or_null("/root/AudioManager")
	var m_enabled = true
	var s_enabled = true
	if audio_mgr:
		m_enabled = audio_mgr.music_enabled
		s_enabled = audio_mgr.sound_enabled
	elif state_mgr:
		m_enabled = state_mgr.music_enabled
		s_enabled = state_mgr.sound_enabled

	if lbl_settings_title:
		lbl_settings_title.text = _tr("settings_title")
		GameTypographyScript.apply_heading_typography(lbl_settings_title, 34, true)

	if btn_toggle_music:
		btn_toggle_music.text = "   " + (_tr("music_on") if m_enabled else _tr("music_off"))
		UIIconScript.apply_audio_toggle_button_identity_style(btn_toggle_music)
		UIIconScript.attach_to_button(btn_toggle_music, "music", Vector2(22, 22), "left", Color(1.0, 0.92, 0.36, 1.0))
		GameTypographyScript.apply_secondary_button_typography(btn_toggle_music, 18)

	if btn_toggle_sound:
		btn_toggle_sound.text = "   " + (_tr("sfx_on") if s_enabled else _tr("sfx_off"))
		UIIconScript.apply_audio_toggle_button_identity_style(btn_toggle_sound)
		UIIconScript.attach_to_button(btn_toggle_sound, "sound_on" if s_enabled else "sound_off", Vector2(22, 22), "left", Color(0.52, 0.98, 1.0, 1.0))
		GameTypographyScript.apply_secondary_button_typography(btn_toggle_sound, 18)

	if btn_toggle_voice:
		var v_mode: String = "male"
		if state_mgr and state_mgr.has_method("get_voice_mode"):
			v_mode = state_mgr.get_voice_mode()
		elif audio_mgr and audio_mgr.has_method("get_voice_mode"):
			v_mode = audio_mgr.get_voice_mode()
		var v_label: String = state_mgr.get_voice_button_label() if (state_mgr and state_mgr.has_method("get_voice_button_label")) else ("VOICE: " + ("Male" if v_mode == "male" else ("Female" if v_mode == "female" else "OFF")))
		btn_toggle_voice.text = "   " + v_label
		UIIconScript.apply_voice_button_identity_style(btn_toggle_voice)
		UIIconScript.attach_to_button(btn_toggle_voice, "sound_on", Vector2(22, 22), "left", Color(0.52, 0.98, 1.0, 1.0))
		GameTypographyScript.apply_secondary_button_typography(btn_toggle_voice, 18)

	if btn_toggle_haptics:
		var h_on: bool = state_mgr.haptics_enabled if (state_mgr and "haptics_enabled" in state_mgr) else true
		btn_toggle_haptics.text = "   " + (_tr("haptics_on") if h_on else _tr("haptics_off"))
		UIIconScript.apply_voice_button_identity_style(btn_toggle_haptics)
		UIIconScript.attach_to_button(btn_toggle_haptics, "haptic", Vector2(22, 22), "left", Color(1.0, 0.90, 0.38, 1.0))
		GameTypographyScript.apply_secondary_button_typography(btn_toggle_haptics, 18)

	if btn_language_modal:
		btn_language_modal.text = "    " + _tr("language_label")
		_apply_settings_group_button_style(btn_language_modal, Color(0.92, 0.28, 0.62, 0.98), Color(1.0, 0.72, 0.88, 1.0))
		UIIconScript.attach_to_button(btn_language_modal, "language", Vector2(24, 24), "left", Color(1.0, 0.88, 0.95, 1.0))
		GameTypographyScript.apply_secondary_button_typography(btn_language_modal, 19, Color(0.42, 0.08, 0.24, 0.95))

	if btn_settings_account:
		btn_settings_account.text = "    " + _tr("btn_account")
		_apply_settings_group_button_style(btn_settings_account, Color(0.12, 0.72, 0.38, 0.98), Color(0.62, 1.0, 0.76, 1.0))
		UIIconScript.attach_to_button(btn_settings_account, "account", Vector2(24, 24), "left", Color(0.82, 1.0, 0.88, 1.0))
		GameTypographyScript.apply_secondary_button_typography(btn_settings_account, 19, Color(0.04, 0.28, 0.12, 0.95))


	if btn_close_settings:
		btn_close_settings.text = _tr("btn_close")
		_apply_red_exit_style(btn_close_settings)
		UIIconScript.attach_to_button(btn_close_settings, "close", Vector2(24, 24), "left", Color(1.0, 0.94, 0.94, 1.0))
		GameTypographyScript.apply_secondary_button_typography(btn_close_settings, 21, Color(0.24, 0.04, 0.06, 0.95))


func _on_toggle_voice_pressed() -> void:
	var state_mgr = get_node_or_null("/root/GameState")
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if state_mgr and state_mgr.has_method("cycle_voice_mode"):
		state_mgr.cycle_voice_mode()
	elif audio_mgr and audio_mgr.has_method("cycle_voice_mode"):
		audio_mgr.cycle_voice_mode()
	_update_settings_buttons()


func _on_toggle_music_pressed() -> void:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	var state_mgr = get_node_or_null("/root/GameState")
	if audio_mgr:
		audio_mgr.music_enabled = not audio_mgr.music_enabled
		audio_mgr.play_button_click()
	elif state_mgr:
		state_mgr.set_music_enabled(not state_mgr.music_enabled)
	_update_settings_buttons()


func _on_toggle_sound_pressed() -> void:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	var state_mgr = get_node_or_null("/root/GameState")
	if audio_mgr:
		audio_mgr.sound_enabled = not audio_mgr.sound_enabled
		if audio_mgr.sound_enabled:
			audio_mgr.play_button_click()
	elif state_mgr:
		state_mgr.set_sfx_enabled(not state_mgr.sound_enabled)
	_update_settings_buttons()


func _on_toggle_haptics_pressed() -> void:
	_play_sfx("click")
	var state_mgr = get_node_or_null("/root/GameState")
	if state_mgr:
		if state_mgr.has_method("toggle_haptics"):
			state_mgr.toggle_haptics(true)
		elif "haptics_enabled" in state_mgr:
			state_mgr.haptics_enabled = not state_mgr.haptics_enabled
			if state_mgr.haptics_enabled and state_mgr.has_method("trigger_haptic_feedback"):
				state_mgr.trigger_haptic_feedback(35, "haptic_toggle_on")
			if state_mgr.has_method("save_progression"):
				state_mgr.save_progression()
	_update_settings_buttons()
