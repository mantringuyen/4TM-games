extends Node

## Main — Root scene orchestrator for Block Puzzle — 4TM
## Toggles UI screens based on GameState transitions with smooth mobile game transitions,
## and renders a dedicated per-level background environment layer behind the transparent 12x10 board.

const GameStateScript = preload("res://scripts/autoload/game_state.gd")
const UIIconScript = preload("res://scripts/ui/ui_icon.gd")
const MapRendererScript = preload("res://scripts/map_core/map_renderer.gd")

@onready var main_menu: Control = $UI/MainMenu
@onready var hud: Control = $UI/HUD
@onready var pause_menu: Control = $UI/PauseMenu
@onready var game_over_modal: Control = $UI/GameOverModal
@onready var game_world: Node2D = $GameWorld

var level_backdrop_layer: CanvasLayer = null
var level_backdrop_canvas: Control = null
var active_backdrop_theme: Dictionary = {}
var active_backdrop_manifest: Dictionary = {}
var backdrop_anim_time: float = 0.0


func _ready() -> void:
	_setup_level_backdrop_layer()
	UIIconScript.remove_all_focus_outlines(self)
	if is_inside_tree() and get_viewport():
		if not get_viewport().size_changed.is_connected(_refresh_active_level_backdrop):
			get_viewport().size_changed.connect(_refresh_active_level_backdrop)
	var state_mgr = get_node_or_null("/root/GameState")
	if state_mgr:
		state_mgr.state_changed.connect(_on_game_state_changed)
		if state_mgr.has_signal("game_started"):
			state_mgr.game_started.connect(func(_m): _refresh_active_level_backdrop())
		if state_mgr.has_signal("level_updated"):
			state_mgr.level_updated.connect(func(_l, _c): _refresh_active_level_backdrop())
		_refresh_active_level_backdrop()
		_update_ui_state(state_mgr.current_state, state_mgr.current_state)
	else:
		_update_ui_state(GameStateScript.State.MENU, GameStateScript.State.MENU)


func _process(delta: float) -> void:
	if level_backdrop_canvas and level_backdrop_canvas.visible:
		backdrop_anim_time += delta


func _setup_level_backdrop_layer() -> void:
	if level_backdrop_layer:
		return
	level_backdrop_layer = CanvasLayer.new()
	level_backdrop_layer.name = "LevelBackdropLayer"
	level_backdrop_layer.layer = -5
	add_child(level_backdrop_layer)
	level_backdrop_canvas = Control.new()
	level_backdrop_canvas.name = "LevelBackdropCanvas"
	level_backdrop_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	level_backdrop_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_backdrop_canvas.draw.connect(_draw_level_backdrop_canvas)
	level_backdrop_layer.add_child(level_backdrop_canvas)


func _get_effective_backdrop_viewport_size() -> Vector2:
	var vp_sz: Vector2 = level_backdrop_canvas.size if level_backdrop_canvas else Vector2.ZERO
	if vp_sz.x <= 10.0 or vp_sz.y <= 10.0:
		vp_sz = get_viewport().get_visible_rect().size if get_viewport() else Vector2(720.0, 1280.0)
	return Vector2(maxf(320.0, vp_sz.x), maxf(480.0, vp_sz.y))


func _refresh_active_level_backdrop(override_viewport_size: Vector2 = Vector2.ZERO) -> void:
	var gs = get_node_or_null("/root/GameState")
	var cur_lvl: int = gs.active_level if (gs and "active_level" in gs) else 1
	var eff_vp: Vector2 = override_viewport_size if (override_viewport_size.x > 10.0 and override_viewport_size.y > 10.0) else _get_effective_backdrop_viewport_size()
	if gs and gs.has_method("get_level_visual_theme"):
		active_backdrop_theme = gs.get_level_visual_theme(cur_lvl)
	else:
		active_backdrop_theme = {
			"level": cur_lvl,
			"theme_id": "ocean_islands_lv%d" % cur_lvl,
			"biome_id": "ocean_islands",
			"sky_top": Color(0.08, 0.36, 0.78, 1.0),
			"sky_mid": Color(0.14, 0.58, 0.90, 1.0),
			"sky_bot": Color(0.24, 0.80, 0.96, 1.0),
			"terrain_primary": Color(0.20, 0.76, 0.48, 1.0),
			"terrain_secondary": Color(0.16, 0.42, 0.68, 1.0),
			"accent_col": Color(0.42, 0.96, 1.0, 1.0),
			"grid_tint": Color(0.56, 0.94, 1.0, 1.0),
			"material_palette_id": "ocean_aquatic"
		}
	if gs and gs.has_method("get_level_gameplay_background_manifest"):
		active_backdrop_manifest = gs.get_level_gameplay_background_manifest(cur_lvl, eff_vp)
	else:
		active_backdrop_manifest = {}
	if game_world and game_world.has_method("get_active_mode"):
		var m_node = game_world.get_active_mode()
		if m_node and m_node.has_method("get_board"):
			var b_node = m_node.get_board()
			if b_node and b_node.has_method("apply_level_environment_tint"):
				b_node.apply_level_environment_tint(active_backdrop_theme)
	if level_backdrop_canvas:
		level_backdrop_canvas.queue_redraw()


func get_active_level_backdrop_state(override_viewport_size: Vector2 = Vector2.ZERO) -> Dictionary:
	_refresh_active_level_backdrop(override_viewport_size)
	var audio_mgr = get_node_or_null("/root/AudioManager")
	var out: Dictionary = active_backdrop_manifest.duplicate(true)
	out["visible"] = level_backdrop_canvas != null and level_backdrop_canvas.visible
	out["level"] = int(active_backdrop_theme.get("level", 1))
	out["active_level"] = int(active_backdrop_theme.get("level", 1))
	out["canonical_background_id"] = String(active_backdrop_theme.get("canonical_background_id", out.get("canonical_background_id", "")))
	out["background_id"] = String(active_backdrop_theme.get("background_id", out.get("background_id", "")))
	out["theme_id"] = String(active_backdrop_theme.get("theme_id", ""))
	out["biome_id"] = String(active_backdrop_theme.get("biome_id", ""))
	out["material_palette_id"] = String(active_backdrop_theme.get("material_palette_id", ""))
	out["bgm_track_id"] = String(audio_mgr.current_bgm_track_id) if audio_mgr else ""
	return out


func get_active_level_backdrop_info(override_viewport_size: Vector2 = Vector2.ZERO) -> Dictionary:
	return get_active_level_backdrop_state(override_viewport_size)


func _draw_level_backdrop_canvas() -> void:
	if not level_backdrop_canvas:
		return
	var eff_vp: Vector2 = _get_effective_backdrop_viewport_size()
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_method("get_map_data"):
		var cur_lvl: int = int(active_backdrop_theme.get("level", gs.active_level if "active_level" in gs else 1))
		var page = gs.get_map_data().get_page_for_level(cur_lvl)
		var lang: String = gs.get_language() if gs.has_method("get_language") else "en"
		if page != null:
			active_backdrop_manifest = MapRendererScript.draw_gameplay_level_background(
				level_backdrop_canvas,
				page,
				cur_lvl,
				Rect2(Vector2.ZERO, eff_vp),
				backdrop_anim_time,
				lang
			)
			return

	var w: float = eff_vp.x
	var h: float = eff_vp.y
	var sky_top: Color = active_backdrop_theme.get("sky_top", Color(0.08, 0.36, 0.78, 1.0))
	var sky_mid: Color = active_backdrop_theme.get("sky_mid", Color(0.14, 0.58, 0.90, 1.0))
	var sky_bot: Color = active_backdrop_theme.get("sky_bot", Color(0.24, 0.80, 0.96, 1.0))
	var bands: int = 16
	for i in range(bands):
		var t0: float = float(i) / float(bands)
		var t1: float = float(i + 1) / float(bands)
		var c_band: Color = sky_top.lerp(sky_mid, t0 * 2.0) if t0 < 0.5 else sky_mid.lerp(sky_bot, (t0 - 0.5) * 2.0)
		level_backdrop_canvas.draw_rect(Rect2(0.0, h * t0, w, h * (t1 - t0) + 2.0), c_band, true)


func _on_game_state_changed(new_state: int, prev_state: int) -> void:
	_update_ui_state(new_state, prev_state)


func _update_ui_state(state: int, prev_state: int = -1) -> void:
	var in_gameplay: bool = (state == GameStateScript.State.PLAYING or state == GameStateScript.State.PAUSED or state == GameStateScript.State.GAME_OVER)
	if level_backdrop_canvas:
		level_backdrop_canvas.visible = in_gameplay
		if in_gameplay:
			_refresh_active_level_backdrop()
	if main_menu:
		var show_menu = (state == GameStateScript.State.MENU)
		main_menu.visible = show_menu
		if show_menu and prev_state != GameStateScript.State.MENU and is_inside_tree():
			main_menu.modulate.a = 0.0
			var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(main_menu, "modulate:a", 1.0, 0.22)
	if hud:
		var show_hud = (state == GameStateScript.State.PLAYING or state == GameStateScript.State.PAUSED)
		hud.visible = show_hud
		if show_hud and prev_state == GameStateScript.State.MENU and is_inside_tree():
			hud.modulate.a = 0.0
			var tw_h = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw_h.tween_property(hud, "modulate:a", 1.0, 0.22)
	if pause_menu:
		pause_menu.visible = (state == GameStateScript.State.PAUSED)
	if game_over_modal:
		game_over_modal.visible = (state == GameStateScript.State.GAME_OVER)
