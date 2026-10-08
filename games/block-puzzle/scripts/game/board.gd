class_name Board
extends Node2D

## Board — 12x10 Grid Game Board (12 Rows × 10 Columns) for Block Puzzle — 4TM
## Features:
##   1. Bright dimensional 3D rounded puzzle cabinet (Royal Gold-Amber vs Crystal Lagoon-Magenta).
##   2. Checkerboard-tinted recessed rounded sockets for crisp 12x10 readability.
##   3. Dimensional 4TM crystal/jewel blocks with distinct inner gem facets.
##   4. Interactive 3x3 BOMB target highlight reticle & target-confirmed detonation.
##   5. Celebratory starburst confetti particles & flash burst when lines or bombs clear.

signal piece_placed(shape: Array, origin: Vector2i, color_id: int)
signal board_cleared()
signal cell_state_changed(coords: Vector2i, new_value: int)
signal bomb_target_clicked(grid_coords: Vector2i)

const PolyominoLib = preload("res://scripts/core/polyomino_library.gd")
const GameTypographyScript = preload("res://scripts/ui/game_typography.gd")

# Board Dimensions (Falling: 10 Columns × 12 Rows; Drag & Drop: 8 Columns × 10 Rows)
const DEFAULT_GRID_ROWS: int = 12
const DEFAULT_GRID_COLS: int = 10
const FALLING_GRID_ROWS: int = 12
const FALLING_GRID_COLS: int = 10
const DRAG_DROP_GRID_ROWS: int = 10
const DRAG_DROP_GRID_COLS: int = 8

var GRID_ROWS: int = DEFAULT_GRID_ROWS
var GRID_COLS: int = DEFAULT_GRID_COLS
var GRID_WIDTH: int = DEFAULT_GRID_COLS
var GRID_HEIGHT: int = DEFAULT_GRID_ROWS
const GRID_SIZE: int = 10

# Layout & Rendering Metrics (Defaulted for 720px portrait viewport: 10 cols × 12 rows, margin ≈ 1 cell each side)
var CELL_SIZE: float = 54.8
var CELL_GAP: float = 4.0
var PADDING: float = 8.0
const CELL_CORNER_RADIUS: float = 10.0

var is_modern_visual_theme: bool = true

# 4TM Visual Palette — Original 4TM Crystal & Gem Theme
const COLOR_GHOST_VALID: Color = Color(0.22, 0.96, 1.0, 0.68)
const COLOR_GHOST_INVALID: Color = Color(1.0, 0.28, 0.48, 0.65)

const COLOR_MAP: Dictionary = {
	1: PolyominoLib.COLOR_CYAN,         # Cyan
	2: PolyominoLib.COLOR_BLUE,         # Blue
	3: PolyominoLib.COLOR_GREEN,        # Green
	4: PolyominoLib.COLOR_YELLOW,       # Yellow
	5: PolyominoLib.COLOR_ORANGE,       # Orange
	6: PolyominoLib.COLOR_PURPLE,       # Purple
	7: PolyominoLib.COLOR_RED,          # Red
	8: PolyominoLib.COLOR_MAGENTA_PINK, # Magenta/Pink
}

# Pure Board Data Model: 12x10 2D Array [row_y][col_x] (12 rows, 10 columns)
# 0 = Empty cell, >0 = Occupied with color_id
var grid_data: Array = []
var grid_materials: Array = []
var grid_special_items: Array = []

# Ghost Preview State
var preview_active: bool = false
var preview_shape: Array = []
var preview_origin: Vector2i = Vector2i.ZERO
var preview_is_valid: bool = false
var preview_color: Color = COLOR_GHOST_VALID
var preview_color_id: int = -1
var preview_material_id: String = ""

# Bomb Target Selection State (Modern Mode Bomb Booster)
var bomb_target_active: bool = false
var bomb_target_center: Vector2i = Vector2i(4, 5)

# Translucent Glass Board Surface Constants (Environment visible with crisp cell readability)
const BOARD_SURFACE_ALPHA: float = 0.055
const BOARD_CABINET_ALPHA: float = 0.06
const EMPTY_CELL_ALPHA_EVEN: float = 0.04
const EMPTY_CELL_ALPHA_ODD: float = 0.05
const EMPTY_CELL_BORDER_ALPHA: float = 0.45
var custom_level_grid_tint: Color = Color(0.0, 0.0, 0.0, 0.0)

# Line Clear Visual Feedback & Celebratory Particles State
const BURST_PARTICLES_PER_CELL: int = 6
const BURST_PARTICLE_MIN_RADIUS: float = 7.5
const BURST_PARTICLE_MAX_RADIUS: float = 15.0
const BOARD_CALLOUT_FONT_SIZE: int = 56
const BOARD_CALLOUT_PEAK_SCALE: float = 1.52
const BOARD_CALLOUT_OUTLINE_SIZE: int = 16
const BOARD_CALLOUT_HAS_BACKGROUND: bool = false
var flash_cells: Array = []
var flash_alpha: float = 0.0
var flash_tween: Tween
var burst_particles: Array = []
var impact_rings: Array = []
var clear_light_beams: Array = []
var floating_callout_text: String = ""
var floating_callout_pos: Vector2 = Vector2.ZERO
var floating_callout_scale: float = 1.0
var floating_callout_alpha: float = 0.0
var floating_callout_tween: Tween = null
var callout_display_font: Font = null
var callout_display_count: int = 0
var last_displayed_callout: String = ""
static var _shared_callout_display_font: Font = null

var callout_spawn_count: int:
	get:
		return callout_display_count

var last_callout_spawned: String:
	get:
		return last_displayed_callout

var floating_texts: Array:
	get:
		if floating_callout_alpha > 0.0 and floating_callout_text != "":
			return [{"text": floating_callout_text, "pos": floating_callout_pos, "alpha": floating_callout_alpha}]
		return []


func apply_level_environment_tint(env: Dictionary) -> void:
	var b_col: Color = env.get("board_border_col", env.get("accent", Color(0.76, 0.94, 1.0, 1.0)))
	custom_level_grid_tint = Color(b_col.r, b_col.g, b_col.b, 1.0)
	queue_redraw()


func has_callout_display_font_treatment() -> bool:
	if not callout_display_font:
		callout_display_font = _build_callout_display_font()
	return callout_display_font != null and not BOARD_CALLOUT_HAS_BACKGROUND and BOARD_CALLOUT_FONT_SIZE >= 48 and BOARD_CALLOUT_OUTLINE_SIZE >= 12


func _build_callout_display_font() -> Font:
	if _shared_callout_display_font:
		return _shared_callout_display_font
	_shared_callout_display_font = GameTypographyScript.get_callout_font()
	return _shared_callout_display_font


func _get_callout_tier_palette(raw_text: String) -> Dictionary:
	var upper := raw_text.to_upper()
	if "AMAZING" in upper:
		return {
			"fill": Color(1.0, 0.96, 0.24, 1.0),
			"rim": Color(0.98, 0.36, 0.68, 0.98),
			"outline": Color(0.26, 0.04, 0.38, 0.99),
			"shadow": Color(0.12, 0.01, 0.20, 0.92),
			"highlight": Color(1.0, 0.99, 0.86, 0.60)
		}
	elif "EXCELLENT" in upper:
		return {
			"fill": Color(1.0, 0.64, 0.98, 1.0),
			"rim": Color(0.86, 0.22, 0.78, 0.98),
			"outline": Color(0.24, 0.04, 0.36, 0.99),
			"shadow": Color(0.11, 0.02, 0.18, 0.92),
			"highlight": Color(1.0, 0.96, 1.0, 0.58)
		}
	elif "COMBO" in upper:
		return {
			"fill": Color(1.0, 0.88, 0.18, 1.0),
			"rim": Color(1.0, 0.44, 0.08, 0.98),
			"outline": Color(0.28, 0.06, 0.02, 0.99),
			"shadow": Color(0.14, 0.03, 0.01, 0.92),
			"highlight": Color(1.0, 0.99, 0.82, 0.58)
		}
	elif "GREAT" in upper:
		return {
			"fill": Color(0.32, 0.96, 1.0, 1.0),
			"rim": Color(0.12, 0.58, 0.98, 0.98),
			"outline": Color(0.04, 0.12, 0.38, 0.99),
			"shadow": Color(0.02, 0.06, 0.22, 0.92),
			"highlight": Color(0.92, 1.0, 1.0, 0.60)
		}
	elif "NICE" in upper:
		return {
			"fill": Color(0.42, 1.0, 0.66, 1.0),
			"rim": Color(0.08, 0.76, 0.46, 0.98),
			"outline": Color(0.03, 0.22, 0.12, 0.99),
			"shadow": Color(0.01, 0.11, 0.06, 0.92),
			"highlight": Color(0.92, 1.0, 0.96, 0.58)
		}
	return {
		"fill": Color(1.0, 0.94, 0.28, 1.0),
		"rim": Color(0.96, 0.54, 0.10, 0.98),
		"outline": Color(0.06, 0.10, 0.34, 0.99),
		"shadow": Color(0.03, 0.05, 0.20, 0.92),
		"highlight": Color(1.0, 0.99, 0.84, 0.58)
	}


func get_board_surface_style_metrics() -> Dictionary:
	var comp_alpha: float = 1.0 - ((1.0 - BOARD_CABINET_ALPHA) * (1.0 - BOARD_SURFACE_ALPHA) * (1.0 - EMPTY_CELL_ALPHA_ODD))
	return {
		"is_translucent": BOARD_SURFACE_ALPHA <= 0.12 and EMPTY_CELL_ALPHA_EVEN <= 0.10 and comp_alpha <= 0.22,
		"is_ultra_transparent": BOARD_SURFACE_ALPHA <= 0.10 and EMPTY_CELL_ALPHA_EVEN <= 0.08 and comp_alpha <= 0.20,
		"is_ultra_transparent_glass": BOARD_SURFACE_ALPHA <= 0.06 and EMPTY_CELL_ALPHA_EVEN <= 0.05 and comp_alpha <= 0.20,
		"board_surface_alpha": BOARD_SURFACE_ALPHA,
		"board_cabinet_alpha": BOARD_CABINET_ALPHA,
		"cabinet_alpha": BOARD_CABINET_ALPHA,
		"empty_cell_alpha_even": EMPTY_CELL_ALPHA_EVEN,
		"empty_cell_alpha_odd": EMPTY_CELL_ALPHA_ODD,
		"empty_cell_border_alpha": EMPTY_CELL_BORDER_ALPHA,
		"composite_empty_cell_opacity": comp_alpha,
		"environment_visibility_ratio": 1.0 - comp_alpha,
		"has_dark_opaque_panel": false,
		"uses_subtle_cell_borders": EMPTY_CELL_BORDER_ALPHA >= 0.30 and EMPTY_CELL_BORDER_ALPHA <= 0.55,
		"burst_particles_per_cell": BURST_PARTICLES_PER_CELL,
		"burst_particle_max_radius": BURST_PARTICLE_MAX_RADIUS,
		"board_callout_font_size": BOARD_CALLOUT_FONT_SIZE,
		"board_callout_peak_scale": BOARD_CALLOUT_PEAK_SCALE,
		"board_callout_outline_size": BOARD_CALLOUT_OUTLINE_SIZE
	}


func _init() -> void:
	_init_grid_data()


func configure_grid_dimensions(cols: int = DEFAULT_GRID_COLS, rows: int = DEFAULT_GRID_ROWS) -> void:
	GRID_COLS = maxi(1, cols)
	GRID_WIDTH = GRID_COLS
	GRID_ROWS = maxi(1, rows)
	GRID_HEIGHT = GRID_ROWS
	bomb_target_center = Vector2i(
		clampi(GRID_WIDTH / 2 - 1, 0, GRID_WIDTH - 1),
		clampi(GRID_HEIGHT / 2, 0, GRID_HEIGHT - 1)
	)
	_init_grid_data()
	queue_redraw()


func _ready() -> void:
	callout_display_font = _build_callout_display_font()
	var gs = get_node_or_null("/root/GameState")
	if gs and "current_mode" in gs:
		is_modern_visual_theme = (gs.current_mode == 1)
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_signal("voice_callout_triggered"):
		if not audio_mgr.voice_callout_triggered.is_connected(_on_board_voice_callout):
			audio_mgr.voice_callout_triggered.connect(_on_board_voice_callout)
	queue_redraw()


func _process(delta: float) -> void:
	var needs_redraw := false
	if not burst_particles.is_empty():
		var any_alive := false
		for p in burst_particles:
			p["age"] += delta
			if p["age"] < p["life"]:
				p["pos"] += p["vel"] * delta
				p["vel"].y += 320.0 * delta
				any_alive = true
		if not any_alive:
			burst_particles.clear()
		needs_redraw = true
	if not impact_rings.is_empty():
		var any_ring := false
		for ring in impact_rings:
			ring["age"] += delta
			if ring["age"] < ring["life"]:
				ring["radius"] = lerpf(float(ring["start_r"]), float(ring["end_r"]), float(ring["age"]) / float(ring["life"]))
				any_ring = true
		if not any_ring:
			impact_rings.clear()
		needs_redraw = true
	if not clear_light_beams.is_empty():
		var any_beam := false
		for beam in clear_light_beams:
			beam["age"] += delta
			if beam["age"] < beam["life"]:
				any_beam = true
		if not any_beam:
			clear_light_beams.clear()
		needs_redraw = true
	if floating_callout_alpha > 0.0:
		needs_redraw = true
	if needs_redraw:
		queue_redraw()


func _on_board_voice_callout(callout_text: String) -> void:
	trigger_board_callout_popup(callout_text)


func trigger_board_callout_popup(callout_text: String, custom_pos: Vector2 = Vector2(-1, -1)) -> void:
	if not callout_display_font:
		callout_display_font = _build_callout_display_font()
	var clean_txt := callout_text.strip_edges().to_upper()
	if clean_txt != "" and not clean_txt.ends_with("!"):
		clean_txt += "!"
	var b_sz := get_board_pixel_size()
	floating_callout_text = clean_txt
	last_displayed_callout = clean_txt
	callout_display_count += 1
	floating_callout_pos = custom_pos if (custom_pos.x >= 0.0 and custom_pos.y >= 0.0) else Vector2(b_sz.x * 0.5, b_sz.y * 0.38)
	floating_callout_scale = 0.48
	floating_callout_alpha = 1.0
	
	# Spawn celebratory callout particle burst & dual shockwave rings around callout center
	var palette = COLOR_MAP.values()
	for i in range(18):
		var angle: float = (TAU / 18.0) * float(i) + randf_range(-0.12, 0.12)
		var spd: float = randf_range(120.0, 310.0)
		var p_col: Color = palette[i % palette.size()]
		burst_particles.append({
			"pos": floating_callout_pos,
			"vel": Vector2(cos(angle) * spd, sin(angle) * spd - 90.0),
			"col": p_col.lightened(0.32),
			"r": randf_range(BURST_PARTICLE_MIN_RADIUS, BURST_PARTICLE_MAX_RADIUS),
			"age": 0.0,
			"life": randf_range(0.46, 0.74)
		})
	impact_rings.append({
		"pos": floating_callout_pos,
		"start_r": CELL_SIZE * 0.40,
		"end_r": CELL_SIZE * 4.2,
		"radius": CELL_SIZE * 0.40,
		"age": 0.0,
		"life": 0.44,
		"col": Color(1.0, 0.94, 0.36, 0.92)
	})
	impact_rings.append({
		"pos": floating_callout_pos,
		"start_r": CELL_SIZE * 0.25,
		"end_r": CELL_SIZE * 3.1,
		"radius": CELL_SIZE * 0.25,
		"age": 0.0,
		"life": 0.36,
		"col": Color(0.32, 0.98, 1.0, 0.88)
	})
	
	if floating_callout_tween and floating_callout_tween.is_valid():
		floating_callout_tween.kill()
	if is_inside_tree():
		floating_callout_tween = create_tween()
		floating_callout_tween.tween_property(self, "floating_callout_scale", BOARD_CALLOUT_PEAK_SCALE, 0.17).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		floating_callout_tween.parallel().tween_property(self, "floating_callout_pos:y", floating_callout_pos.y - 32.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		floating_callout_tween.tween_property(self, "floating_callout_scale", 1.18, 0.11)
		floating_callout_tween.tween_interval(0.46)
		floating_callout_tween.tween_property(self, "floating_callout_alpha", 0.0, 0.28)
	queue_redraw()


## Sets whether the board renders with the Modern (Crystal-Neon) or Classic (Royal Gold) theme
func set_visual_mode(is_modern: bool) -> void:
	is_modern_visual_theme = is_modern
	queue_redraw()


## Recalculates board metrics responsively for the 10-column × 12-row grid.
## Target visual relationship on portrait screens:
##   margin (≈ 1 cell) | 10 board columns | margin (≈ 1 cell)
##   Total width span = 12 cell-equivalents -> board occupies 10/12 (83.33%) of available_width.
func update_responsive_layout(available_width: float = 720.0, custom_board_width: float = 0.0, max_available_height: float = 0.0) -> Vector2:
	var width_ratio: float = float(GRID_WIDTH) / float(GRID_WIDTH + 2) # 10.0 / 12.0 = 0.833333
	var target_board_width: float = custom_board_width if custom_board_width > 0.0 else (available_width * width_ratio)
	
	# Ensure square cells fit within max_available_height if constrained vertically
	if max_available_height > 0.0:
		var aspect_h_over_w: float = float(GRID_HEIGHT) / float(GRID_WIDTH) # 1.20
		var max_w_from_h: float = max_available_height / aspect_h_over_w
		if max_w_from_h < target_board_width:
			target_board_width = max(200.0, max_w_from_h)
	
	var scale_factor: float = target_board_width / 600.0
	PADDING = 8.0 * scale_factor
	CELL_GAP = 4.0 * scale_factor
	CELL_SIZE = (target_board_width - (PADDING * 2.0) - (CELL_GAP * float(GRID_WIDTH - 1))) / float(GRID_WIDTH)
	queue_redraw()
	return get_board_pixel_size()


## Returns the single-side (left or right) horizontal margin when centered in viewport_width
func get_horizontal_margin_for_viewport(viewport_width: float = 720.0) -> float:
	return max(0.0, (viewport_width - get_board_pixel_size().x) * 0.5)


## Returns the ratio of single-side horizontal margin to one cell width (target ≈ 1.0)
func get_margin_to_cell_ratio(viewport_width: float = 720.0) -> float:
	if CELL_SIZE <= 0.0:
		return 1.0
	return get_horizontal_margin_for_viewport(viewport_width) / CELL_SIZE


## Initializes the pure 12x10 logical data matrix (12 rows, 10 columns) with zeros
func _init_grid_data() -> void:
	grid_data.clear()
	grid_materials.clear()
	grid_special_items.clear()
	for y in range(GRID_HEIGHT):
		var row: Array = []
		var mat_row: Array = []
		var sp_row: Array = []
		for x in range(GRID_WIDTH):
			row.append(0)
			mat_row.append("")
			sp_row.append("")
		grid_data.append(row)
		grid_materials.append(mat_row)
		grid_special_items.append(sp_row)


# ==============================================================================
# BOARD LOGIC API (12 ROWS × 10 COLUMNS)
# ==============================================================================

static func normalize_special_item_type(item_type: String) -> String:
	var norm: String = item_type.strip_edges().to_lower()
	match norm:
		"bomb":
			return "bomb"
		"change_block", "change":
			return "change_block"
		"extra_life", "heart", "life":
			return "extra_life"
		"locked", "locked_cell", "lock":
			return "locked"
		"rainbow", "seven_color", "7_color", "7-color":
			return "rainbow"
		_:
			return ""


func is_special_milestone_level_for_board(level_num: int = -1) -> bool:
	var gs = get_node_or_null("/root/GameState")
	var eff_lvl: int = level_num if level_num >= 1 else (int(gs.active_level) if (gs and "active_level" in gs) else 1)
	if gs and gs.has_method("is_special_milestone_level"):
		return bool(gs.is_special_milestone_level(eff_lvl))
	return PolyominoLib.is_special_milestone_level(eff_lvl)


func clear_special_items() -> void:
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			grid_special_items[y][x] = ""
	queue_redraw()


func set_cell_special_item(coords: Vector2i, item_type: String, ensure_occupied_color_id: int = 0, level_num: int = -1) -> bool:
	if not is_valid_cell(coords):
		return false
	var norm: String = normalize_special_item_type(item_type)
	if norm == "":
		grid_special_items[coords.y][coords.x] = ""
		queue_redraw()
		return true
	var gs = get_node_or_null("/root/GameState")
	var eff_lvl: int = level_num if level_num >= 1 else (int(gs.active_level) if (gs and "active_level" in gs) else 1)
	if gs and gs.has_method("has_special_items") and not gs.has_special_items(gs.current_mode):
		return false
	if not is_special_milestone_level_for_board(eff_lvl):
		return false
	if grid_data[coords.y][coords.x] == 0:
		var cid: int = ensure_occupied_color_id if ensure_occupied_color_id > 0 else (9 if norm == "rainbow" else (((coords.x + coords.y) % 8) + 1))
		grid_data[coords.y][coords.x] = cid
		grid_materials[coords.y][coords.x] = "rainbow" if norm == "rainbow" else PolyominoLib.get_material_id_for_block(cid, eff_lvl)
	elif norm == "rainbow":
		grid_data[coords.y][coords.x] = 9
		grid_materials[coords.y][coords.x] = "rainbow"
	grid_special_items[coords.y][coords.x] = norm
	queue_redraw()
	return true


func get_cell_special_item(coords: Vector2i) -> String:
	if not is_valid_cell(coords) or grid_data[coords.y][coords.x] == 0:
		return ""
	var sp: String = String(grid_special_items[coords.y][coords.x])
	if sp != "":
		return sp
	if int(grid_data[coords.y][coords.x]) == 9 or String(grid_materials[coords.y][coords.x]) in ["rainbow", "seven_color"]:
		return "rainbow"
	return ""


func has_cell_special_item(coords: Vector2i) -> bool:
	return get_cell_special_item(coords) != ""


func is_cell_locked(coords: Vector2i) -> bool:
	return get_cell_special_item(coords) == "locked"


func get_active_special_item_cells() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var coords := Vector2i(x, y)
			var sp: String = get_cell_special_item(coords)
			if sp != "":
				result.append({
					"coords": coords,
					"item_type": sp,
					"color_id": int(grid_data[y][x]),
					"material_id": String(grid_materials[y][x]),
					"cell_rect": Rect2(grid_to_local(coords), Vector2(CELL_SIZE, CELL_SIZE))
				})
	return result


func get_special_item_count_on_board(item_type: String = "") -> int:
	var norm_filter: String = normalize_special_item_type(item_type) if item_type != "" else ""
	var cnt: int = 0
	for entry in get_active_special_item_cells():
		if norm_filter == "" or String(entry.get("item_type", "")) == norm_filter:
			cnt += 1
	return cnt


func spawn_milestone_special_items(level_num: int = -1, allow_special: bool = true) -> Array[Dictionary]:
	var gs = get_node_or_null("/root/GameState")
	var eff_lvl: int = level_num if level_num >= 1 else (int(gs.active_level) if (gs and "active_level" in gs) else 1)
	if not allow_special or not is_special_milestone_level_for_board(eff_lvl):
		clear_special_items()
		return []
	if gs and gs.has_method("can_level_have_special_board_items") and not gs.can_level_have_special_board_items(eff_lvl, gs.current_mode):
		clear_special_items()
		return []
	var specs: Array = []
	if gs and gs.has_method("get_milestone_special_board_item_specs"):
		specs = gs.get_milestone_special_board_item_specs(eff_lvl, gs.current_mode)
	else:
		var boosters: Array[String] = ["bomb", "change_block", "extra_life"]
		var chosen_booster: String = boosters[posmod(eff_lvl, boosters.size())]
		specs = [
			{"coords": Vector2i(2, 9), "item_type": chosen_booster, "color_id": ((eff_lvl) % 8) + 1},
			{"coords": Vector2i(5, 10), "item_type": "rainbow", "color_id": 9},
			{"coords": Vector2i(7, 9), "item_type": "locked", "color_id": ((eff_lvl + 3) % 8) + 1}
		]
	for s in specs:
		var c_pos: Vector2i = s.get("coords", Vector2i(2, 9))
		if GRID_HEIGHT != 12:
			c_pos.y = clampi(GRID_HEIGHT - (12 - c_pos.y), 0, GRID_HEIGHT - 1)
		if GRID_WIDTH != 10:
			c_pos.x = clampi(int(round(float(c_pos.x) * float(GRID_WIDTH - 1) / 9.0)), 0, GRID_WIDTH - 1)
		var i_type: String = String(s.get("item_type", "bomb"))
		var c_id: int = int(s.get("color_id", 1))
		set_cell_special_item(c_pos, i_type, c_id, eff_lvl)
	queue_redraw()
	return get_active_special_item_cells()


func try_spawn_milestone_special_item_in_occupied_cell(item_type: String = "", level_num: int = -1, allow_special: bool = true) -> Dictionary:
	var gs = get_node_or_null("/root/GameState")
	var eff_lvl: int = level_num if level_num >= 1 else (int(gs.active_level) if (gs and "active_level" in gs) else 1)
	if not allow_special or not is_special_milestone_level_for_board(eff_lvl):
		return {"spawned": false, "reason": "not_special_milestone_level"}
	if gs and gs.has_method("can_level_have_special_board_items") and not gs.can_level_have_special_board_items(eff_lvl, gs.current_mode):
		return {"spawned": false, "reason": "mode_or_level_disallows_special_items"}
	var candidates: Array[Vector2i] = []
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var p := Vector2i(x, y)
			if grid_data[y][x] != 0 and get_cell_special_item(p) == "":
				candidates.append(p)
	if candidates.is_empty():
		return {"spawned": false, "reason": "no_available_occupied_cell"}
	var boosters: Array[String] = ["bomb", "change_block", "extra_life"]
	var chosen_type: String = normalize_special_item_type(item_type)
	if chosen_type == "":
		chosen_type = boosters[posmod(eff_lvl + candidates.size(), boosters.size())]
	var target_coord: Vector2i = candidates[posmod(eff_lvl * 3 + candidates.size(), candidates.size())]
	var ok: bool = set_cell_special_item(target_coord, chosen_type, int(grid_data[target_coord.y][target_coord.x]), eff_lvl)
	return {
		"spawned": ok,
		"coords": target_coord,
		"item_type": chosen_type
	}


func is_valid_cell(coords: Vector2i) -> bool:
	return coords.x >= 0 and coords.x < GRID_WIDTH and coords.y >= 0 and coords.y < GRID_HEIGHT


func is_cell_empty(coords: Vector2i) -> bool:
	if not is_valid_cell(coords):
		return false
	return grid_data[coords.y][coords.x] == 0


func can_place_piece(shape_cells: Array, origin: Vector2i) -> bool:
	if shape_cells.is_empty():
		return false
	
	for cell in shape_cells:
		var target: Vector2i = origin + cell
		if not is_valid_cell(target):
			return false
		if not is_cell_empty(target):
			return false
	
	return true


func has_any_valid_placement(shape_cells: Array) -> bool:
	if shape_cells.is_empty():
		return false
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if can_place_piece(shape_cells, Vector2i(x, y)):
				return true
	return false


func place_piece(shape_cells: Array, origin: Vector2i, color_id: int = 1, material_id: String = "", piece_special_items: Dictionary = {}) -> bool:
	if not can_place_piece(shape_cells, origin):
		return false
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_method("record_placement_checkpoint") and "current_state" in gs and int(gs.current_state) == 1:
		gs.record_placement_checkpoint(self)
	var cur_lvl: int = gs.active_level if (gs and "active_level" in gs) else 1
	var resolved_mat: String = material_id if not material_id.is_empty() else (
		preview_material_id if (preview_active and not preview_material_id.is_empty() and preview_color_id == color_id) else PolyominoLib.get_material_id_for_block(color_id, cur_lvl)
	)
	var can_have_special: bool = is_special_milestone_level_for_board(cur_lvl) and (gs == null or not gs.has_method("has_special_items") or gs.has_special_items(gs.current_mode))
	
	for cell in shape_cells:
		var target: Vector2i = origin + cell
		grid_data[target.y][target.x] = color_id
		grid_materials[target.y][target.x] = resolved_mat
		var cell_sp: String = ""
		if can_have_special:
			if piece_special_items.has(cell):
				cell_sp = normalize_special_item_type(String(piece_special_items[cell]))
			elif color_id == 9 or resolved_mat in ["rainbow", "seven_color"]:
				cell_sp = "rainbow"
		grid_special_items[target.y][target.x] = cell_sp
		cell_state_changed.emit(target, color_id)
	
	queue_redraw()
	piece_placed.emit(shape_cells, origin, color_id)
	return true


func clear_board() -> void:
	if grid_data.size() != GRID_HEIGHT or (grid_data.size() > 0 and grid_data[0].size() != GRID_WIDTH):
		_init_grid_data()
	else:
		for y in range(GRID_HEIGHT):
			for x in range(GRID_WIDTH):
				grid_data[y][x] = 0
				grid_materials[y][x] = ""
				grid_special_items[y][x] = ""
	
	flash_cells.clear()
	clear_light_beams.clear()
	impact_rings.clear()
	burst_particles.clear()
	if floating_callout_tween and floating_callout_tween.is_valid():
		floating_callout_tween.kill()
	floating_callout_text = ""
	floating_callout_alpha = 0.0
	bomb_target_active = false
	clear_preview()
	queue_redraw()
	board_cleared.emit()


func get_cell(coords: Vector2i) -> int:
	if not is_valid_cell(coords):
		return -1
	return grid_data[coords.y][coords.x]


func get_cell_material_id(coords: Vector2i) -> String:
	if not is_valid_cell(coords) or grid_data[coords.y][coords.x] == 0:
		return ""
	var stored_mat: String = String(grid_materials[coords.y][coords.x])
	if not stored_mat.is_empty():
		return stored_mat
	var gs = get_node_or_null("/root/GameState")
	var cur_lvl: int = gs.active_level if (gs and "active_level" in gs) else 1
	return PolyominoLib.get_material_id_for_block(int(grid_data[coords.y][coords.x]), cur_lvl)


func get_preview_material_id() -> String:
	if not preview_active:
		return ""
	return preview_material_id


func get_board_state() -> Array:
	return grid_data.duplicate(true)


func get_occupied_cell_count() -> int:
	var count: int = 0
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if grid_data[y][x] != 0:
				count += 1
	return count


func get_completed_rows() -> Array:
	var rows: Array = []
	for y in range(GRID_HEIGHT):
		var full: bool = true
		for x in range(GRID_WIDTH):
			if grid_data[y][x] == 0:
				full = false
				break
		if full:
			rows.append(y)
	return rows


func get_completed_columns() -> Array:
	var cols: Array = []
	for x in range(GRID_WIDTH):
		var full: bool = true
		for y in range(GRID_HEIGHT):
			if grid_data[y][x] == 0:
				full = false
				break
		if full:
			cols.append(x)
	return cols


## Detects completed lines (rows of 10 cells, columns of 12 cells) and clears them from grid_data.
func check_and_clear_lines(is_modern: bool = true, apply_gravity_override: Variant = null) -> Dictionary:
	var cleared_rows = get_completed_rows()
	var cleared_cols = get_completed_columns() if is_modern else []
	
	var cells_to_clear: Dictionary = {}
	
	for r in cleared_rows:
		for x in range(GRID_WIDTH):
			cells_to_clear[Vector2i(x, r)] = true
			
	for c in cleared_cols:
		for y in range(GRID_HEIGHT):
			cells_to_clear[Vector2i(c, y)] = true
			
	var unique_cells_count: int = 0
	var has_rainbow_cleared: bool = false
	var collected_special_items: Array[String] = []
	var unlocked_cells: Array[Vector2i] = []
	var actually_cleared_coords: Array = []
	
	for coord in cells_to_clear.keys():
		var c_val: int = int(grid_data[coord.y][coord.x])
		var c_mat: String = String(grid_materials[coord.y][coord.x])
		var c_sp: String = String(grid_special_items[coord.y][coord.x])
		if c_sp == "locked":
			# Locked cell unlocks into a normal playable block cell on first line clear
			grid_special_items[coord.y][coord.x] = ""
			unlocked_cells.append(coord)
			cell_state_changed.emit(coord, c_val)
			continue
		if c_val == 9 or c_mat in ["rainbow", "seven_color"] or c_sp == "rainbow":
			has_rainbow_cleared = true
		if c_sp in ["bomb", "change_block", "extra_life"]:
			collected_special_items.append(c_sp)
		grid_data[coord.y][coord.x] = 0
		grid_materials[coord.y][coord.x] = ""
		grid_special_items[coord.y][coord.x] = ""
		unique_cells_count += 1
		actually_cleared_coords.append(coord)
		cell_state_changed.emit(coord, 0)
		
	if unique_cells_count > 0 or not unlocked_cells.is_empty():
		_spawn_clear_light_beams(cleared_rows, cleared_cols)
		_trigger_clear_flash(actually_cleared_coords if not actually_cleared_coords.is_empty() else unlocked_cells)
		queue_redraw()
		
	var total_lines = cleared_rows.size() + cleared_cols.size()
	
	var should_apply_gravity: bool = (not is_modern) if apply_gravity_override == null else bool(apply_gravity_override)
	if should_apply_gravity and cleared_rows.size() > 0:
		apply_classic_gravity()
		queue_redraw()
		
	return {
		"lines_cleared": total_lines,
		"row_count": cleared_rows.size(),
		"col_count": cleared_cols.size(),
		"cleared_rows": cleared_rows,
		"cleared_cols": cleared_cols,
		"unique_cells_cleared": unique_cells_count,
		"has_rainbow": has_rainbow_cleared,
		"collected_special_items": collected_special_items,
		"unlocked_cells": unlocked_cells,
		"gravity_applied": should_apply_gravity and cleared_rows.size() > 0
	}


## Compacts remaining blocks downward for each of the 10 columns across all 12 rows (Falling gravity).
func apply_classic_gravity() -> void:
	for x in range(GRID_WIDTH):
		var column_blocks: Array = []
		var column_mats: Array = []
		var column_specials: Array = []
		for y in range(GRID_HEIGHT - 1, -1, -1):
			if grid_data[y][x] != 0:
				column_blocks.append(grid_data[y][x])
				column_mats.append(grid_materials[y][x])
				column_specials.append(grid_special_items[y][x])
				grid_data[y][x] = 0
				grid_materials[y][x] = ""
				grid_special_items[y][x] = ""
		
		var target_y = GRID_HEIGHT - 1
		for idx_b in range(column_blocks.size()):
			var block_val = column_blocks[idx_b]
			grid_data[target_y][x] = block_val
			grid_materials[target_y][x] = column_mats[idx_b]
			grid_special_items[target_y][x] = column_specials[idx_b]
			cell_state_changed.emit(Vector2i(x, target_y), block_val)
			target_y -= 1
		
		while target_y >= 0:
			grid_data[target_y][x] = 0
			grid_materials[target_y][x] = ""
			grid_special_items[target_y][x] = ""
			cell_state_changed.emit(Vector2i(x, target_y), 0)
			target_y -= 1


# ==============================================================================
# MODERN SPECIAL ITEM BOARD OPERATIONS (BOMB TARGETING & EXTRA LIFE RESCUE)
# ==============================================================================

func set_bomb_target_highlight(center: Vector2i, active: bool = true) -> bool:
	if active and not is_valid_cell(center):
		return false
	bomb_target_active = active
	if active:
		bomb_target_center = center
	queue_redraw()
	return true


func clear_bomb_target_highlight() -> void:
	bomb_target_active = false
	queue_redraw()


func is_bomb_target_highlighted() -> bool:
	return bomb_target_active


func get_bomb_target_center() -> Vector2i:
	return bomb_target_center


func get_bomb_target_cells(center: Vector2i = bomb_target_center) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if not is_valid_cell(center):
		return cells
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var p := Vector2i(center.x + dx, center.y + dy)
			if is_valid_cell(p):
				cells.append(p)
	return cells


func detonate_bomb_at(target_center: Vector2i) -> Dictionary:
	if not is_valid_cell(target_center):
		return {"executed": false, "cleared_count": 0, "target": target_center}
	
	var target_area: Array[Vector2i] = get_bomb_target_cells(target_center)
	var cleared_coords: Array = []
	var collected_items: Array[String] = []
	for p in target_area:
		if grid_data[p.y][p.x] != 0:
			var sp_id: String = String(grid_special_items[p.y][p.x])
			if sp_id in ["bomb", "change_block", "extra_life"]:
				collected_items.append(sp_id)
			grid_data[p.y][p.x] = 0
			grid_materials[p.y][p.x] = ""
			grid_special_items[p.y][p.x] = ""
			cell_state_changed.emit(p, 0)
			cleared_coords.append(p)
	
	bomb_target_active = false
	_trigger_clear_flash(target_area)
	queue_redraw()
	return {
		"executed": true,
		"cleared_count": cleared_coords.size(),
		"target": target_center,
		"affected_cells": target_area.size(),
		"collected_special_items": collected_items
	}


func restore_checkpoint_state(saved_grid: Array, saved_materials: Array = [], saved_special_items: Array = []) -> void:
	if saved_grid.size() != GRID_HEIGHT:
		return
	for y in range(GRID_HEIGHT):
		var row = saved_grid[y]
		if row is Array and row.size() == GRID_WIDTH:
			for x in range(GRID_WIDTH):
				grid_data[y][x] = int(row[x])
		if y < saved_materials.size() and saved_materials[y] is Array and saved_materials[y].size() == GRID_WIDTH:
			for x in range(GRID_WIDTH):
				grid_materials[y][x] = String(saved_materials[y][x])
		if y < saved_special_items.size() and saved_special_items[y] is Array and saved_special_items[y].size() == GRID_WIDTH:
			for x in range(GRID_WIDTH):
				grid_special_items[y][x] = String(saved_special_items[y][x]) if grid_data[y][x] != 0 else ""
		else:
			for x in range(GRID_WIDTH):
				if grid_data[y][x] == 0:
					grid_special_items[y][x] = ""
	flash_cells.clear()
	bomb_target_active = false
	clear_preview()
	queue_redraw()


func apply_extra_life_rescue() -> int:
	var row_counts: Array = []
	for y in range(GRID_HEIGHT):
		var cnt: int = 0
		for x in range(GRID_WIDTH):
			if grid_data[y][x] != 0:
				cnt += 1
		if cnt > 0:
			row_counts.append({"row": y, "count": cnt})
	
	row_counts.sort_custom(func(a, b): return a["count"] > b["count"])
	var cleared_coords: Array = []
	var rows_to_clear: int = min(5, row_counts.size())
	for i in range(rows_to_clear):
		var ry: int = int(row_counts[i]["row"])
		for x in range(GRID_WIDTH):
			if grid_data[ry][x] != 0:
				grid_data[ry][x] = 0
				grid_materials[ry][x] = ""
				grid_special_items[ry][x] = ""
				cell_state_changed.emit(Vector2i(x, ry), 0)
				cleared_coords.append(Vector2i(x, ry))
	
	if not cleared_coords.is_empty():
		_trigger_clear_flash(cleared_coords)
		queue_redraw()
	return cleared_coords.size()


func _trigger_clear_flash(coords: Array) -> void:
	flash_cells = coords.duplicate()
	flash_alpha = 1.0
	_spawn_celebration_particles(coords)
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	
	flash_tween = create_tween()
	flash_tween.tween_method(func(val: float):
		flash_alpha = val
		queue_redraw()
	, 1.0, 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flash_tween.tween_callback(func():
		flash_cells.clear()
		queue_redraw()
	)


func _spawn_clear_light_beams(rows: Array, cols: Array) -> void:
	var b_sz := get_board_pixel_size()
	for r in rows:
		var row_y: float = grid_to_local(Vector2i(0, int(r))).y
		clear_light_beams.append({
			"rect": Rect2(Vector2(PADDING * 0.5, row_y - 4.0), Vector2(b_sz.x - PADDING, CELL_SIZE + 8.0)),
			"age": 0.0,
			"life": 0.24,
			"col": Color(0.42, 0.98, 1.0, 0.85) if is_modern_visual_theme else Color(1.0, 0.92, 0.36, 0.85)
		})
	for c in cols:
		var col_x: float = grid_to_local(Vector2i(int(c), 0)).x
		clear_light_beams.append({
			"rect": Rect2(Vector2(col_x - 4.0, PADDING * 0.5), Vector2(CELL_SIZE + 8.0, b_sz.y - PADDING)),
			"age": 0.0,
			"life": 0.24,
			"col": Color(1.0, 0.56, 0.94, 0.85)
		})


func _spawn_celebration_particles(coords: Array) -> void:
	var palette = COLOR_MAP.values()
	var sum_pos := Vector2.ZERO
	var valid_cnt := 0
	for coord in coords:
		if not is_valid_cell(coord):
			continue
		var center = grid_to_local_center(coord)
		sum_pos += center
		valid_cnt += 1
		for i in range(BURST_PARTICLES_PER_CELL):
			var angle = randf() * TAU
			var spd = randf_range(110.0, 295.0)
			var p_col: Color = palette[randi() % palette.size()]
			burst_particles.append({
				"pos": center,
				"vel": Vector2(cos(angle) * spd, sin(angle) * spd - 95.0),
				"col": p_col.lightened(0.30),
				"r": randf_range(BURST_PARTICLE_MIN_RADIUS, BURST_PARTICLE_MAX_RADIUS),
				"age": 0.0,
				"life": randf_range(0.24, 0.42)
			})
	if valid_cnt > 0:
		var burst_center: Vector2 = sum_pos / float(valid_cnt)
		# Primary & secondary expanding ripple shockwaves
		impact_rings.append({
			"pos": burst_center,
			"start_r": CELL_SIZE * 0.45,
			"end_r": CELL_SIZE * 4.5,
			"radius": CELL_SIZE * 0.45,
			"age": 0.0,
			"life": 0.24,
			"col": Color(1.0, 0.94, 0.38, 0.94)
		})
		impact_rings.append({
			"pos": burst_center,
			"start_r": CELL_SIZE * 0.25,
			"end_r": CELL_SIZE * 3.2,
			"radius": CELL_SIZE * 0.25,
			"age": 0.0,
			"life": 0.20,
			"col": Color(0.36, 0.98, 1.0, 0.88)
		})


# ==============================================================================
# COORDINATE CONVERSIONS
# ==============================================================================

func get_board_pixel_size() -> Vector2:
	var total_w = (GRID_WIDTH * CELL_SIZE) + ((GRID_WIDTH - 1) * CELL_GAP) + (PADDING * 2.0)
	var total_h = (GRID_HEIGHT * CELL_SIZE) + ((GRID_HEIGHT - 1) * CELL_GAP) + (PADDING * 2.0)
	return Vector2(total_w, total_h)


func grid_to_local(coords: Vector2i) -> Vector2:
	var px = PADDING + (coords.x * (CELL_SIZE + CELL_GAP))
	var py = PADDING + (coords.y * (CELL_SIZE + CELL_GAP))
	return Vector2(px, py)


func grid_to_local_center(coords: Vector2i) -> Vector2:
	return grid_to_local(coords) + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)


func local_to_grid(local_pos: Vector2) -> Vector2i:
	var adjusted = local_pos - Vector2(PADDING, PADDING)
	var step = CELL_SIZE + CELL_GAP
	var gx = int(round(adjusted.x / step))
	var gy = int(round(adjusted.y / step))
	return Vector2i(gx, gy)


func local_point_to_cell(local_pos: Vector2) -> Vector2i:
	var adjusted = local_pos - Vector2(PADDING, PADDING)
	var step = CELL_SIZE + CELL_GAP
	var gx = int(floor(adjusted.x / step))
	var gy = int(floor(adjusted.y / step))
	return Vector2i(gx, gy)


func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local_pos = to_local(world_pos)
	return local_to_grid(local_pos)


func grid_to_world(coords: Vector2i) -> Vector2:
	return to_global(grid_to_local(coords))


func get_shape_board_pixel_size(shape_cells: Array) -> Vector2:
	var dims: Vector2i = PolyominoLib.get_dimensions(shape_cells)
	if dims.x <= 0 or dims.y <= 0:
		return Vector2(CELL_SIZE, CELL_SIZE)
	var w: float = (float(dims.x) * CELL_SIZE) + (float(max(0, dims.x - 1)) * CELL_GAP)
	var h: float = (float(dims.y) * CELL_SIZE) + (float(max(0, dims.y - 1)) * CELL_GAP)
	return Vector2(w, h)


func grid_to_local_shape_center(origin: Vector2i, shape_cells: Array) -> Vector2:
	return grid_to_local(origin) + (get_shape_board_pixel_size(shape_cells) * 0.5)


func grid_to_world_shape_center(origin: Vector2i, shape_cells: Array) -> Vector2:
	return to_global(grid_to_local_shape_center(origin, shape_cells))


func resolve_piece_origin_from_visual_center(visual_center_world: Vector2, shape_cells: Array) -> Vector2i:
	var local_center: Vector2 = to_local(visual_center_world)
	var shape_px: Vector2 = get_shape_board_pixel_size(shape_cells)
	var implied_local_origin: Vector2 = local_center - (shape_px * 0.5)
	return local_to_grid(implied_local_origin)


# ==============================================================================
# GHOST PREVIEW & ROUNDED 3D CRYSTAL/GEM RENDERING
# ==============================================================================

func set_preview(shape_cells: Array, origin: Vector2i, is_valid: bool, tint_color: Color = Color.WHITE, p_color_id: int = -1, p_material_id: String = "") -> void:
	var gs = get_node_or_null("/root/GameState")
	var cur_lvl: int = gs.active_level if (gs and "active_level" in gs) else 1
	var resolved_cid: int = 1
	if p_color_id >= 1:
		resolved_cid = p_color_id
	else:
		for cid in COLOR_MAP.keys():
			if COLOR_MAP[cid].is_equal_approx(Color(tint_color.r, tint_color.g, tint_color.b, 1.0)):
				resolved_cid = int(cid)
				break
	var resolved_mat: String = p_material_id if not p_material_id.is_empty() else PolyominoLib.get_material_id_for_block(resolved_cid, cur_lvl)
	var changed: bool = (
		not preview_active
		or preview_origin != origin
		or preview_is_valid != is_valid
		or preview_color_id != resolved_cid
		or preview_material_id != resolved_mat
		or preview_shape != shape_cells
	)
	preview_active = true
	if preview_shape != shape_cells:
		preview_shape = shape_cells.duplicate(true)
	preview_origin = origin
	preview_is_valid = is_valid
	preview_color_id = resolved_cid
	preview_material_id = resolved_mat
	if changed:
		var mat_spec: Dictionary = PolyominoLib.get_material_spec(preview_material_id, preview_color_id, cur_lvl)
		var mat_base_col: Color = mat_spec.get("base_color", tint_color)
		if is_valid:
			if tint_color.a >= 0.9:
				preview_color = Color(mat_base_col.r, mat_base_col.g, mat_base_col.b, 1.0)
			else:
				preview_color = Color(mat_base_col.r, mat_base_col.g, mat_base_col.b, 0.68)
		else:
			preview_color = COLOR_GHOST_INVALID
		queue_redraw()


func clear_preview() -> void:
	if preview_active or not preview_shape.is_empty():
		preview_active = false
		preview_shape = []
		preview_material_id = ""
		queue_redraw()


func _draw() -> void:
	var board_size = get_board_pixel_size()
	var bg_rect = Rect2(Vector2.ZERO, board_size)
	var gs = get_node_or_null("/root/GameState")
	var cur_lvl: int = gs.active_level if (gs and "active_level" in gs) else 1
	
	# 1. Ultra-Transparent Glass Perimeter Rim (Level environment shines directly through empty cells)
	var lvl_accent := Color(0.62, 0.94, 1.0, 1.0) if is_modern_visual_theme else Color(1.0, 0.90, 0.52, 1.0)
	if custom_level_grid_tint.a > 0.1:
		lvl_accent = custom_level_grid_tint
	elif gs and gs.has_method("get_level_visual_theme"):
		var l_theme: Dictionary = gs.get_level_visual_theme(cur_lvl)
		lvl_accent = l_theme.get("grid_tint", lvl_accent)

	var outer_cabinet = StyleBoxFlat.new()
	outer_cabinet.bg_color = Color(0.04, 0.08, 0.18, BOARD_CABINET_ALPHA)
	outer_cabinet.border_width_left = 2
	outer_cabinet.border_width_top = 2
	outer_cabinet.border_width_right = 2
	outer_cabinet.border_width_bottom = 3
	outer_cabinet.border_color = Color(lvl_accent.r, lvl_accent.g, lvl_accent.b, 0.68)
	outer_cabinet.corner_radius_top_left = 18
	outer_cabinet.corner_radius_top_right = 18
	outer_cabinet.corner_radius_bottom_right = 18
	outer_cabinet.corner_radius_bottom_left = 18
	outer_cabinet.shadow_color = Color(0.02, 0.04, 0.14, 0.18)
	outer_cabinet.shadow_size = 6
	outer_cabinet.shadow_offset = Vector2(0, 2)
	draw_style_box(outer_cabinet, bg_rect.grow(1.5))

	# Outer dark glass contour rim so cabinet edge is sharp against bright skies
	var outer_contour = StyleBoxFlat.new()
	outer_contour.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	outer_contour.border_width_left = 1
	outer_contour.border_width_top = 1
	outer_contour.border_width_right = 1
	outer_contour.border_width_bottom = 1
	outer_contour.border_color = Color(0.02, 0.05, 0.14, EMPTY_CELL_BORDER_ALPHA)
	outer_contour.corner_radius_top_left = 19
	outer_contour.corner_radius_top_right = 19
	outer_contour.corner_radius_bottom_right = 19
	outer_contour.corner_radius_bottom_left = 19
	draw_style_box(outer_contour, bg_rect.grow(2.5))
	
	# Translucent luminous glass boundary
	var inner_well = StyleBoxFlat.new()
	inner_well.bg_color = Color(0.02, 0.05, 0.14, BOARD_SURFACE_ALPHA)
	inner_well.border_width_left = 1
	inner_well.border_width_top = 1
	inner_well.border_width_right = 1
	inner_well.border_width_bottom = 1
	inner_well.border_color = Color(0.94, 0.98, 1.0, EMPTY_CELL_BORDER_ALPHA)
	inner_well.corner_radius_top_left = 15
	inner_well.corner_radius_top_right = 15
	inner_well.corner_radius_bottom_right = 15
	inner_well.corner_radius_bottom_left = 15
	draw_style_box(inner_well, bg_rect)
	
	var cell_rad = int(clamp(CELL_SIZE * 0.18, 4.0, 9.0))
	var inner_rad = maxi(3, cell_rad - 1)
	var empty_socket_even = StyleBoxFlat.new()
	empty_socket_even.bg_color = Color(0.03, 0.07, 0.18, EMPTY_CELL_ALPHA_EVEN)
	empty_socket_even.border_width_left = 1
	empty_socket_even.border_width_top = 1
	empty_socket_even.border_width_right = 1
	empty_socket_even.border_width_bottom = 1
	empty_socket_even.border_color = Color(0.02, 0.06, 0.16, EMPTY_CELL_BORDER_ALPHA)
	empty_socket_even.corner_radius_top_left = cell_rad
	empty_socket_even.corner_radius_top_right = cell_rad
	empty_socket_even.corner_radius_bottom_right = cell_rad
	empty_socket_even.corner_radius_bottom_left = cell_rad

	var empty_socket_odd = empty_socket_even.duplicate()
	empty_socket_odd.bg_color = Color(0.02, 0.05, 0.14, EMPTY_CELL_ALPHA_ODD)

	var empty_socket_glass_rim = StyleBoxFlat.new()
	empty_socket_glass_rim.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	empty_socket_glass_rim.border_width_left = 1
	empty_socket_glass_rim.border_width_top = 1
	empty_socket_glass_rim.border_width_right = 1
	empty_socket_glass_rim.border_width_bottom = 1
	var rim_tint: Color = lvl_accent.lightened(0.42)
	empty_socket_glass_rim.border_color = Color(rim_tint.r, rim_tint.g, rim_tint.b, EMPTY_CELL_BORDER_ALPHA)
	empty_socket_glass_rim.corner_radius_top_left = inner_rad
	empty_socket_glass_rim.corner_radius_top_right = inner_rad
	empty_socket_glass_rim.corner_radius_bottom_right = inner_rad
	empty_socket_glass_rim.corner_radius_bottom_left = inner_rad
	
	# 2. Draw 12x10 Crisp Glass Cell Outlines and High-Contrast Occupied 4TM Material Blocks
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var cell_coords = Vector2i(x, y)
			var cell_pos = grid_to_local(cell_coords)
			var cell_rect = Rect2(cell_pos, Vector2(CELL_SIZE, CELL_SIZE))
			var cell_val = grid_data[y][x]
			
			if cell_val == 0:
				var sock = empty_socket_even if ((x + y) % 2 == 0) else empty_socket_odd
				draw_style_box(sock, cell_rect)
				draw_style_box(empty_socket_glass_rim, cell_rect.grow(-1.0))
			else:
				var block_color = COLOR_MAP.get(cell_val, COLOR_MAP[1])
				var cell_mat_id: String = String(grid_materials[y][x])
				var cell_sp_id: String = get_cell_special_item(cell_coords)
				_draw_block_cell(cell_rect, block_color, cell_val, cur_lvl, cell_mat_id, cell_sp_id)
	
	# 3. Draw Ghost Placement Preview / Active Falling Piece
	if preview_active and not preview_shape.is_empty():
		var ghost_box = StyleBoxFlat.new()
		ghost_box.bg_color = preview_color
		ghost_box.border_width_left = 2
		ghost_box.border_width_top = 2
		ghost_box.border_width_right = 2
		ghost_box.border_width_bottom = 3
		ghost_box.border_color = Color(preview_color.r, preview_color.g, preview_color.b, 0.98).lightened(0.35)
		ghost_box.corner_radius_top_left = cell_rad
		ghost_box.corner_radius_top_right = cell_rad
		ghost_box.corner_radius_bottom_right = cell_rad
		ghost_box.corner_radius_bottom_left = cell_rad

		var active_color_id: int = preview_color_id if preview_color_id >= 1 else 1
		var active_mat_id: String = preview_material_id if not preview_material_id.is_empty() else PolyominoLib.get_material_id_for_block(active_color_id, cur_lvl)

		for offset in preview_shape:
			var target_coord = preview_origin + offset
			if is_valid_cell(target_coord):
				var p_cell_pos = grid_to_local(target_coord)
				var p_cell_rect = Rect2(p_cell_pos, Vector2(CELL_SIZE, CELL_SIZE))
				
				if preview_is_valid:
					_draw_block_cell(p_cell_rect, preview_color, active_color_id, cur_lvl, active_mat_id)
				else:
					draw_style_box(ghost_box, p_cell_rect)
					var inner_pip = Rect2(p_cell_pos + Vector2(4, 3), Vector2(p_cell_rect.size.x * 0.36, p_cell_rect.size.y * 0.20))
					draw_rect(inner_pip, Color(1, 1, 1, 0.54), true)
	
	# 4. Draw Interactive 3x3 Bomb Target Reticle Highlight
	if bomb_target_active and is_valid_cell(bomb_target_center):
		var bomb_reticle = StyleBoxFlat.new()
		bomb_reticle.bg_color = Color(1.0, 0.28, 0.36, 0.42)
		bomb_reticle.border_width_left = 3
		bomb_reticle.border_width_top = 3
		bomb_reticle.border_width_right = 3
		bomb_reticle.border_width_bottom = 3
		bomb_reticle.border_color = Color(1.0, 0.92, 0.28, 0.98)
		bomb_reticle.corner_radius_top_left = cell_rad
		bomb_reticle.corner_radius_top_right = cell_rad
		bomb_reticle.corner_radius_bottom_right = cell_rad
		bomb_reticle.corner_radius_bottom_left = cell_rad
		for b_cell in get_bomb_target_cells(bomb_target_center):
			var c_pos = grid_to_local(b_cell)
			var c_rect = Rect2(c_pos, Vector2(CELL_SIZE, CELL_SIZE))
			draw_style_box(bomb_reticle, c_rect.grow(2.0))
	
	# 5. Draw Full-Line Clear Light Beams & Cell Flash Burst
	for beam in clear_light_beams:
		if beam["age"] < beam["life"]:
			var b_ratio: float = 1.0 - (float(beam["age"]) / float(beam["life"]))
			var b_col: Color = beam["col"]
			b_col.a = b_ratio * 0.78
			var b_rect: Rect2 = beam["rect"]
			draw_rect(b_rect.grow(6.0 * b_ratio), b_col, true)
			draw_rect(b_rect, Color(1.0, 1.0, 1.0, b_ratio * 0.85), true)

	if flash_alpha > 0.0 and not flash_cells.is_empty():
		var burst_box = StyleBoxFlat.new()
		burst_box.bg_color = Color(1.0, 0.94, 0.42, flash_alpha * 0.96)
		burst_box.border_width_left = 2
		burst_box.border_width_top = 2
		burst_box.border_width_right = 2
		burst_box.border_width_bottom = 2
		burst_box.border_color = Color(1.0, 1.0, 1.0, flash_alpha)
		burst_box.corner_radius_top_left = cell_rad + 2
		burst_box.corner_radius_top_right = cell_rad + 2
		burst_box.corner_radius_bottom_right = cell_rad + 2
		burst_box.corner_radius_bottom_left = cell_rad + 2
		for coord in flash_cells:
			if is_valid_cell(coord):
				var f_cell_pos = grid_to_local(coord)
				var f_cell_rect = Rect2(f_cell_pos, Vector2(CELL_SIZE, CELL_SIZE))
				draw_style_box(burst_box, f_cell_rect.grow(4.5 * flash_alpha))
				draw_circle(f_cell_rect.position + f_cell_rect.size * 0.5, (CELL_SIZE * 0.40) * flash_alpha, Color(1, 1, 1, flash_alpha))
	
	# 6. Draw Celebratory Impact Ripple Rings & Starburst Confetti Particles
	for ring in impact_rings:
		if ring["age"] < ring["life"]:
			var r_ratio: float = 1.0 - (float(ring["age"]) / float(ring["life"]))
			var r_col: Color = ring["col"]
			r_col.a = r_ratio * 0.90
			draw_arc(ring["pos"], float(ring["radius"]), 0.0, TAU, 40, r_col, maxf(3.0, 11.0 * r_ratio), true)

	for p in burst_particles:
		if p["age"] < p["life"]:
			var ratio = 1.0 - (float(p["age"]) / float(p["life"]))
			var p_col: Color = p["col"]
			p_col.a = ratio
			var pr: float = float(p["r"]) * ratio
			draw_circle(p["pos"], pr, p_col)
			draw_circle(p["pos"], pr * 0.54, Color(1, 1, 1, ratio))

	# 7. Draw Floating Board Callout Text Burst (Pure Game-Style Display Typography — NO Background Panel/Circle)
	if floating_callout_alpha > 0.01 and floating_callout_text != "":
		var font: Font = callout_display_font if callout_display_font else ThemeDB.fallback_font
		if font:
			var pal: Dictionary = _get_callout_tier_palette(floating_callout_text)
			var f_sz: int = clampi(int(round(float(BOARD_CALLOUT_FONT_SIZE) * floating_callout_scale)), 32, 84)
			var box_w: float = board_size.x * 0.94
			var draw_pt := Vector2((board_size.x - box_w) * 0.5, clampf(floating_callout_pos.y, 56.0, board_size.y - 56.0))
			var shadow_pt := draw_pt + Vector2(4.0, 7.0)
			var sh_col: Color = pal.get("shadow", Color(0.02, 0.03, 0.14, 0.92))
			sh_col.a *= floating_callout_alpha
			var out_col: Color = pal.get("outline", Color(0.06, 0.08, 0.28, 0.99))
			out_col.a *= floating_callout_alpha
			var rim_col: Color = pal.get("rim", Color(0.98, 0.56, 0.12, 0.98))
			rim_col.a *= floating_callout_alpha
			var fill_col: Color = pal.get("fill", Color(1.0, 0.96, 0.34, 1.0))
			fill_col.a *= floating_callout_alpha
			var hi_col: Color = pal.get("highlight", Color(1.0, 0.99, 0.86, 0.58))
			hi_col.a *= floating_callout_alpha
			# Layer 1: Deep arcade drop shadow outline (no background circle or panel!)
			draw_string_outline(
				font,
				shadow_pt,
				floating_callout_text,
				HORIZONTAL_ALIGNMENT_CENTER,
				box_w,
				f_sz,
				BOARD_CALLOUT_OUTLINE_SIZE + 4,
				sh_col
			)
			# Layer 2: Crisp dark outer contour stroke for maximum board contrast
			draw_string_outline(
				font,
				draw_pt,
				floating_callout_text,
				HORIZONTAL_ALIGNMENT_CENTER,
				box_w,
				f_sz,
				BOARD_CALLOUT_OUTLINE_SIZE,
				out_col
			)
			# Layer 3: Vibrant tier inner rim stroke for game-style display depth
			draw_string_outline(
				font,
				draw_pt + Vector2(0.0, 2.0),
				floating_callout_text,
				HORIZONTAL_ALIGNMENT_CENTER,
				box_w,
				f_sz,
				6,
				rim_col
			)
			# Layer 4: Radiant tier-colored display face
			draw_string(
				font,
				draw_pt,
				floating_callout_text,
				HORIZONTAL_ALIGNMENT_CENTER,
				box_w,
				f_sz,
				fill_col
			)
			# Layer 5: Specular top highlight for casual-game typography polish
			draw_string(
				font,
				draw_pt + Vector2(0.0, -2.0),
				floating_callout_text,
				HORIZONTAL_ALIGNMENT_CENTER,
				box_w,
				f_sz,
				hi_col
			)


## Draws an occupied block cell using the procedural 4TM materials and any active cell special item
func _draw_block_cell(cell_rect: Rect2, _base_color: Color, color_id: int = 1, level_num: int = 1, material_id: String = "", special_item_type: String = "") -> void:
	PolyominoLib.draw_material_block_cell(self, cell_rect, color_id, material_id, level_num, special_item_type)
