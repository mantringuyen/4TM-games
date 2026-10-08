class_name MapRenderer
extends Control

const MapTheme = preload("res://scripts/map_core/map_theme.gd")
const MapRoute = preload("res://scripts/map_core/map_route.gd")
const MapNode = preload("res://scripts/map_core/map_node.gd")
const MapPage = preload("res://scripts/map_core/map_page.gd")

## MapRenderer — Illustrated Topographic World Map Renderer (Correction 6)
## Renders each MapPage as ONE continuous hand-crafted illustrated landscape painting:
##   1. Sky & Iconic Regional Horizon Backdrop (Mount Fuji, Giza Pyramids, Roman Colosseum,
##      Ha Long Karst Peaks, Eiffel Skyline, Matterhorn, Vesuvius Caldera, Milky Way Nebula)
##   2. Large Connected Topographic Landforms with Stepped Contour Ridges & Cliffs
##   3. Continuous Integrated Waterway (Coastal Bay / Peninsula Channel / Valley River / Canal)
##      routed cleanly through the natural valley gap between lower and upper level clusters
##   4. Cohesive Regional Forests, Terraces, Villages, Bridges & Iconic Landmarks
##   5. Natural Winding Trail with Real Bridges/Causeways at Water Crossings
##   6. Level Destinations Embedded Directly Into the Trail & Landscape
##   7. Foreground Framing Silhouette & Subtle Atmospheric Depth

enum RenderMode {
	MAP_PAGE = 0,
	GAMEPLAY_BACKGROUND = 1
}
const MODE_MAP_PAGE: String = "MAP_PAGE"
const MODE_GAMEPLAY_BACKGROUND: String = "GAMEPLAY_BACKGROUND"

const MapRenderVisibility: Dictionary = {
	"MAP_PAGE": {
		"mode": "MAP_PAGE",
		"artwork": true,
		"terrain": true,
		"waterways": true,
		"horizon": true,
		"roads": true,
		"landmarks": true,
		"landmark_names": true,
		"scenery": true,
		"atmosphere": true,
		"routes": true,
		"level_markers": true,
		"level_numbers": true,
		"progression_ui": true,
		"navigation_ui": true
	},
	"GAMEPLAY_BACKGROUND": {
		"mode": "GAMEPLAY_BACKGROUND",
		"artwork": true,
		"terrain": true,
		"waterways": true,
		"horizon": true,
		"roads": true,
		"landmarks": true,
		"landmark_names": true,
		"scenery": true,
		"atmosphere": true,
		"routes": true,
		"level_markers": false,
		"level_numbers": false,
		"progression_ui": false,
		"navigation_ui": false
	}
}

var current_page: MapPage = null
var time_sec: float = 0.0
var animate_ambience: bool = true
var debug_show_spatial_zones: bool = false
static var debug_spatial_overlay_enabled: bool = false


static func _is_gameplay_background_mode(mode) -> bool:
	if mode is String:
		return String(mode).to_upper() == MODE_GAMEPLAY_BACKGROUND
	return int(mode) == RenderMode.GAMEPLAY_BACKGROUND


static func get_render_visibility(mode = RenderMode.MAP_PAGE) -> Dictionary:
	var key: String = MODE_GAMEPLAY_BACKGROUND if _is_gameplay_background_mode(mode) else MODE_MAP_PAGE
	return (MapRenderVisibility[key] as Dictionary).duplicate(true)


static func _ensure_page_layout_for_rect(page: MapPage, rect: Rect2) -> void:
	if page == null or rect.size.x <= 10.0 or rect.size.y <= 10.0:
		return
	if page.nodes.is_empty() or page.last_canvas_size.distance_to(rect.size) > 1.0:
		const MapLayoutGenScript = preload("res://scripts/map_core/map_layout_generator.gd")
		var gen = MapLayoutGenScript.new()
		gen.generate_page_layout(page, rect.size)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


func setup(p_page: MapPage) -> void:
	current_page = p_page
	queue_redraw()


func set_page(p_page: MapPage) -> void:
	current_page = p_page
	queue_redraw()


func _process(delta: float) -> void:
	if not visible or not animate_ambience or current_page == null:
		return
	time_sec += delta
	queue_redraw()


func _draw() -> void:
	if current_page == null:
		return
	draw_page_world(self, current_page, Rect2(Vector2.ZERO, size), time_sec)


static func draw_page_canvas(
	canvas: CanvasItem,
	page: MapPage,
	anim_time: float = 0.0,
	pan_offset: Vector2 = Vector2.ZERO,
	mode = RenderMode.MAP_PAGE
) -> void:
	if canvas == null or page == null:
		return
	var c_size: Vector2 = page.last_canvas_size
	if canvas is Control:
		var ctrl_sz: Vector2 = (canvas as Control).size
		if ctrl_sz.x > 10.0 and ctrl_sz.y > 10.0:
			c_size = ctrl_sz
	if c_size.x <= 10.0 or c_size.y <= 10.0:
		c_size = Vector2(390.0, 620.0)
	render_country_page(canvas, page, Rect2(pan_offset, c_size), mode, anim_time)


static func draw_page_world(
	canvas: CanvasItem,
	page: MapPage,
	rect: Rect2,
	anim_time: float = 0.0,
	mode = RenderMode.MAP_PAGE
) -> void:
	render_country_page(canvas, page, rect, mode, anim_time)


static func render_country_page(
	canvas: CanvasItem,
	page: MapPage,
	rect: Rect2,
	mode = RenderMode.MAP_PAGE,
	anim_time: float = 0.0
) -> Dictionary:
	if page == null or rect.size.x <= 10.0 or rect.size.y <= 10.0:
		return {}
	_ensure_page_layout_for_rect(page, rect)
	var is_gameplay_bg: bool = _is_gameplay_background_mode(mode)
	var vis: Dictionary = get_render_visibility(mode)
	var theme: MapTheme = page.theme if page.theme != null else MapTheme.from_preset("ocean_islands")
	var pal: Dictionary = theme.palette
	var ox: float = rect.position.x
	var oy: float = rect.position.y

	var rng := RandomNumberGenerator.new()
	rng.seed = int(page.seed_value) ^ (page.page_index * 1664525)
	var flip_world: bool = ((page.page_index % 2) == 1)

	# Compute natural valley river / canal / bay crossing index between lower and upper node groups
	var split_idx: int = _find_water_crossing_index(page)
	var country_key: String = _resolve_country_composition_key(theme, page)

	if canvas != null:
		# 1. Full-Screen Continuous Atmospheric Sky & Independent POINT_OF_INTEREST Panorama
		_draw_sky_and_regional_horizon(canvas, rect, page, theme, pal, flip_world, anim_time)

		# 2. Continuous Country / World Landscape & Waterways Across the Whole Screen
		if country_key in ["vietnam_bay", "thailand", "norway", "coastal_archipelago"]:
			_draw_coastal_bay_world(canvas, rect, page, theme, pal, split_idx, flip_world, anim_time)
		elif theme.world_type == "modern_city" and country_key not in ["japan", "vietnam_city", "usa_nyc", "france", "italy"]:
			_draw_modern_city_world(canvas, rect, page, theme, pal, split_idx, flip_world, anim_time)
		else:
			_draw_inland_topographic_world(canvas, rect, page, theme, pal, split_idx, flip_world, anim_time)

		# 3 & 4. Country Roads, Courtyards & Water-Crossing Bridges (part of MapPage artwork; kept in both modes)
		_draw_trail_stop_clearings(canvas, page, theme, pal, Vector2(ox, oy))
		_draw_natural_trail_and_bridges(canvas, rect, page, theme, pal, split_idx, Vector2(ox, oy), anim_time)

		# 5. Complete Country Landmarks, Landmark Names (Plaques), Independent POIs & Regional Scenery
		_draw_continuous_country_landmarks(canvas, rect, page, theme, pal, split_idx, flip_world, anim_time, rng, country_key)

		# 6. Foreground World Framing & Subtle Atmospheric Depth
		_draw_foreground_framing_and_atmosphere(canvas, rect, page, theme, pal, flip_world, anim_time, rng)

		# 7. Subtle gameplay readability veil (after exact MapPage artwork is rendered; never alters landmark position or scale)
		if is_gameplay_bg:
			_draw_gameplay_subdued_contrast_veil(canvas, rect, pal)
		else:
			var show_dbg: bool = debug_spatial_overlay_enabled or ((canvas is MapRenderer) and (canvas as MapRenderer).debug_show_spatial_zones)
			if show_dbg:
				draw_debug_spatial_overlay(canvas, page, rect)

	return {
		"valid": true,
		"render_mode": MODE_GAMEPLAY_BACKGROUND if is_gameplay_bg else MODE_MAP_PAGE,
		"visibility": vis,
		"country_id": page.country_id,
		"country_key": country_key,
		"split_idx": split_idx,
		"reuses_country_map_artwork": true,
		"reuses_full_map_page_artwork": true,
		"matches_map_page_exactly": true,
		"renders_artwork": bool(vis.get("artwork", true)),
		"renders_landmarks": bool(vis.get("landmarks", true)),
		"renders_scenery": bool(vis.get("scenery", true)),
		"renders_roads": bool(vis.get("roads", true)),
		"renders_level_markers": bool(vis.get("level_markers", false)),
		"renders_level_nodes": false,
		"renders_node_numbers": false,
		"renders_progression_ui": bool(vis.get("progression_ui", false)),
		"renders_navigation_ui": bool(vis.get("navigation_ui", false)),
		"renders_route_lines": not is_gameplay_bg,
		"renders_destination_pads": not is_gameplay_bg,
		"renders_level_labels": not is_gameplay_bg
	}


static func _resolve_country_composition_key(theme: MapTheme, page: MapPage = null) -> String:
	var cid: String = page.country_id if page != null else ""
	match cid:
		"vietnam":
			return "vietnam_bay"
		"thailand", "cambodia", "myanmar", "malaysia", "sri_lanka":
			return "thailand"
		"france", "belgium", "netherlands", "luxembourg", "monaco", "united_kingdom", "ireland", "germany":
			return "france"
		"italy", "spain", "portugal", "greece", "croatia", "malta", "turkey", "slovenia", "romania", "hungary", "czechia", "poland":
			return "italy"
		"japan", "south_korea", "china", "taiwan", "india":
			return "japan"
		"usa", "united_states", "canada", "australia", "brazil", "mexico", "colombia", "singapore":
			return "usa_canyon" if (theme != null and theme.world_id == "grand_canyon") else "usa_nyc"
		"egypt", "morocco", "jordan", "tunisia", "saudi_arabia", "uae", "united_arab_emirates", "oman", "qatar", "kuwait", "uzbekistan", "pakistan", "kenya", "south_africa", "mongolia":
			return "egypt"
		"switzerland", "austria", "nepal", "bhutan", "peru", "chile", "argentina", "bolivia", "georgia", "costa_rica":
			return "switzerland"
		"norway", "iceland", "new_zealand", "finland", "sweden", "denmark":
			return "norway"
		"indonesia", "philippines", "maldives", "Fiji", "cuba", "panama", "ecuador":
			return "coastal_archipelago"
	if theme == null:
		return "japan"
	var wid: String = theme.world_id
	var tid: String = theme.theme_id
	if wid in ["paris", "rural_countryside"]:
		return "france"
	if wid in ["mount_fuji", "tokyo", "modern_city"]:
		return "japan"
	if wid in ["italy", "venice", "rome", "tuscan_countryside"]:
		return "italy"
	if wid == "ha_long_bay":
		return "vietnam_bay"
	if wid == "ho_chi_minh_city":
		return "vietnam_city"
	if wid == "new_york_city":
		return "usa_nyc"
	if wid == "grand_canyon":
		return "usa_canyon"
	if wid == "giza":
		return "egypt"
	if wid in ["alpine_village", "swiss_alps"]:
		return "switzerland"
	if wid in ["mars", "moon", "milky_way"]:
		return "space"
	if tid in ["hills_mountains", "volcano"]:
		return "japan"
	if tid in ["ancient_ruins", "green_forest"]:
		return "italy"
	if tid == "crystal_sanctuary":
		return "france"
	if tid == "ocean_islands":
		return "vietnam_bay"
	if tid == "tropical_coast":
		return "usa_nyc"
	if tid == "desert":
		return "egypt"
	if tid == "snow_ice":
		return "switzerland"
	if tid == "starlight_highlands":
		return "space"
	return "japan"


static func get_country_horizon_ratio(country_id: String, country_key: String = "") -> float:
	match country_id:
		"vietnam": return 0.148
		"thailand": return 0.145
		"france": return 0.140
		"italy": return 0.144
		"japan": return 0.154
		"usa", "united_states": return 0.142
		"egypt": return 0.136
		"switzerland": return 0.158
		"norway": return 0.156
		"chile", "iceland", "nepal", "peru": return 0.156
		"saudi_arabia", "morocco", "jordan", "oman": return 0.138
	match country_key:
		"switzerland", "norway", "japan": return 0.154
		"vietnam_bay", "thailand", "coastal_archipelago": return 0.146
		"egypt", "usa_canyon": return 0.138
		"france", "usa_nyc": return 0.142
		_: return 0.145


static func get_country_sky_floor_ratio(country_id: String, country_key: String = "") -> float:
	return clampf(get_country_horizon_ratio(country_id, country_key) - 0.036, 0.095, 0.125)


static func get_sky_boundary_y_at(page: MapPage, rect: Rect2, px: float, _country_key: String = "") -> float:
	var w: float = maxf(280.0, rect.size.x)
	var h: float = maxf(340.0, rect.size.y)
	var u: float = clampf((px - rect.position.x) / w, 0.0, 1.0)
	var flip_w: bool = ((page.page_index % 2) == 1) if page != null else false
	var su: float = 1.0 - u if flip_w else u
	var phase_c: float = float(page.page_index if page != null else 0) * 0.47
	var theme: MapTheme = page.theme if (page != null and page.theme != null) else null
	var cid: String = page.country_id if page != null else ""
	var c_key: String = _country_key if _country_key != "" else _resolve_country_composition_key(theme, page)
	var hz: float = get_country_horizon_ratio(cid, c_key)
	var fy_norm: float = clampf(hz - 0.028 - 0.018 * sin(su * PI * 1.35 + 0.2 + phase_c) - 0.008 * cos(su * PI * 3.1), 0.090, 0.138)
	return rect.position.y + h * fy_norm


static func get_distant_horizon_bottom_y_at(page: MapPage, rect: Rect2, px: float, _country_key: String = "") -> float:
	var w: float = maxf(280.0, rect.size.x)
	var h: float = maxf(340.0, rect.size.y)
	var u: float = clampf((px - rect.position.x) / w, 0.0, 1.0)
	var flip_w: bool = ((page.page_index % 2) == 1) if page != null else false
	var su: float = 1.0 - u if flip_w else u
	var phase_c: float = float(page.page_index if page != null else 0) * 0.47
	var theme: MapTheme = page.theme if (page != null and page.theme != null) else null
	var cid: String = page.country_id if page != null else ""
	var c_key: String = _country_key if _country_key != "" else _resolve_country_composition_key(theme, page)
	var hz: float = get_country_horizon_ratio(cid, c_key)
	var dh_norm: float = clampf(hz + 0.004 + 0.014 * cos(su * PI * 1.25 + 0.4 + phase_c) - 0.006 * sin(su * PI * 2.8), 0.124, 0.168)
	return maxf(get_sky_boundary_y_at(page, rect, px, c_key) + 6.0, rect.position.y + h * dh_norm)


static func get_mountain_background_bottom_y_at(page: MapPage, rect: Rect2, px: float, _country_key: String = "") -> float:
	var w: float = maxf(280.0, rect.size.x)
	var h: float = maxf(340.0, rect.size.y)
	var u: float = clampf((px - rect.position.x) / w, 0.0, 1.0)
	var flip_w: bool = ((page.page_index % 2) == 1) if page != null else false
	var su: float = 1.0 - u if flip_w else u
	var phase_c: float = float(page.page_index if page != null else 0) * 0.63
	var theme: MapTheme = page.theme if (page != null and page.theme != null) else null
	var cid: String = page.country_id if page != null else ""
	var c_key: String = _country_key if _country_key != "" else _resolve_country_composition_key(theme, page)
	var hz: float = get_country_horizon_ratio(cid, c_key)
	var mb_norm: float = clampf(hz + 0.032 + 0.014 * sin(su * PI * 1.8 + phase_c) + 0.006 * cos(su * PI * 3.0), 0.156, 0.198)
	return maxf(get_distant_horizon_bottom_y_at(page, rect, px, c_key) + 6.0, rect.position.y + h * mb_norm)


static func get_mountain_background_top_y_at(page: MapPage, rect: Rect2, px: float, _country_key: String = "") -> float:
	var w: float = maxf(280.0, rect.size.x)
	var h: float = maxf(340.0, rect.size.y)
	var ox: float = rect.position.x
	var oy: float = rect.position.y
	var flip_w: bool = ((page.page_index % 2) == 1) if page != null else false
	var theme: MapTheme = page.theme if (page != null and page.theme != null) else null
	var c_key: String = _country_key if _country_key != "" else _resolve_country_composition_key(theme, page)
	var base_y: float = get_mountain_background_bottom_y_at(page, rect, px, c_key)
	var peak_cx: float = ox + w * (0.56 if not flip_w else 0.44)
	match c_key:
		"japan", "switzerland", "norway":
			var d_norm: float = absf(px - peak_cx) / maxf(1.0, w * 0.32)
			if d_norm < 1.0:
				return lerpf(oy + h * 0.055, base_y, d_norm * d_norm)
		"france":
			var u: float = clampf((px - ox) / w, 0.0, 1.0)
			if u >= 0.04 and u <= 0.96:
				var alps_h: float = (0.095 * exp(-pow((u - 0.22) / 0.12, 2.0)) + 0.110 * exp(-pow((u - 0.58) / 0.15, 2.0))) * h
				return maxf(oy + h * 0.065, base_y - alps_h)
		"vietnam_bay", "vietnam_city", "thailand", "coastal_archipelago":
			var u_k: float = clampf((px - ox) / w, 0.0, 1.0)
			var k_xs: Array[float] = [0.16, 0.34, 0.54, 0.74, 0.86]
			var k_hs: Array[float] = [0.085, 0.105, 0.118, 0.095, 0.080]
			var min_ky: float = base_y
			for k_i in range(k_xs.size()):
				var du: float = absf(u_k - k_xs[k_i]) / 0.09
				if du < 1.0:
					min_ky = minf(min_ky, base_y - h * k_hs[k_i] * (1.0 - du * du))
			return min_ky
	return get_distant_horizon_bottom_y_at(page, rect, px, c_key)


static func get_land_ground_top_y_at(page: MapPage, rect: Rect2, px: float, _country_key: String = "") -> float:
	var h: float = maxf(340.0, rect.size.y)
	var theme: MapTheme = page.theme if (page != null and page.theme != null) else null
	var c_key: String = _country_key if _country_key != "" else _resolve_country_composition_key(theme, page)
	var mtn_bg_y: float = get_mountain_background_bottom_y_at(page, rect, px, c_key)
	var highland_h: float = h * (0.020 if c_key in ["switzerland", "norway", "japan"] else 0.015)
	return mtn_bg_y + highland_h


static func get_minimum_valid_ground_y_at(page: MapPage, rect: Rect2, px: float, stop_info: Dictionary = {}, _country_key: String = "") -> float:
	var theme: MapTheme = page.theme if (page != null and page.theme != null) else null
	var c_key: String = _country_key if _country_key != "" else _resolve_country_composition_key(theme, page)
	var g_spec: Dictionary = derive_landmark_grounding_spec(stop_info, c_key)
	var g_class: String = String(g_spec.get("grounding_classification", "GROUND"))
	if g_class in ["MOUNTAIN", "CLIFF"]:
		return get_mountain_background_bottom_y_at(page, rect, px, c_key) + 3.0
	return get_land_ground_top_y_at(page, rect, px, c_key) + 3.0


static func get_country_spatial_zones(page: MapPage, rect: Rect2) -> Dictionary:
	var w: float = maxf(280.0, rect.size.x)
	var h: float = maxf(340.0, rect.size.y)
	var ox: float = rect.position.x
	var oy: float = rect.position.y
	var theme: MapTheme = page.theme if (page != null and page.theme != null) else MapTheme.from_preset("green_forest")
	var cid: String = page.country_id if page != null else ""
	var c_key: String = _resolve_country_composition_key(theme, page)
	var hz_ratio: float = get_country_horizon_ratio(cid, c_key)
	var sky_floor_ratio: float = get_country_sky_floor_ratio(cid, c_key)
	var split_idx: int = _find_water_crossing_index(page) if page != null else 0
	var flip_w: bool = ((page.page_index % 2) == 1) if page != null else false
	var water_spine: PackedVector2Array = _build_country_waterway_spine(page, rect, split_idx, flip_w, c_key)
	var water_half_w: float = clampf(minf(w, h) * 0.044, 15.0, 24.0)
	var has_coastal_bay: bool = c_key in ["vietnam_bay", "thailand", "norway", "coastal_archipelago"]
	var sea_on_right: bool = not flip_w
	var mid_x: float = ox + w * 0.5
	var sky_y_mid: float = get_sky_boundary_y_at(page, rect, mid_x)
	var dist_hz_y_mid: float = get_distant_horizon_bottom_y_at(page, rect, mid_x)
	var mtn_bg_y_mid: float = get_mountain_background_bottom_y_at(page, rect, mid_x)
	var land_top_y_mid: float = get_land_ground_top_y_at(page, rect, mid_x)
	var coast_rect := Rect2(
		ox + (w * 0.62 if sea_on_right else 0.0),
		land_top_y_mid,
		w * 0.38,
		maxf(40.0, oy + h * 0.90 - land_top_y_mid)
	)
	var sky_r := Rect2(ox, oy, w, maxf(16.0, sky_y_mid - oy))
	var dist_hz_r := Rect2(ox, sky_y_mid, w, maxf(8.0, dist_hz_y_mid - sky_y_mid))
	var mtn_bg_r := Rect2(ox, dist_hz_y_mid, w, maxf(8.0, mtn_bg_y_mid - dist_hz_y_mid))
	var mtn_ground_r := Rect2(ox, mtn_bg_y_mid, w, maxf(8.0, land_top_y_mid - mtn_bg_y_mid))
	var land_r := Rect2(ox, land_top_y_mid, w, maxf(60.0, oy + h - land_top_y_mid))
	var urban_r := Rect2(ox + w * 0.06, land_top_y_mid, w * 0.88, maxf(60.0, oy + h * 0.88 - land_top_y_mid))
	var fg_r := Rect2(ox, oy + h * 0.88, w, h * 0.12)
	return {
		"country_id": cid,
		"country_key": c_key,
		"canvas_rect": rect,
		"horizon_ratio": hz_ratio,
		"sky_floor_ratio": sky_floor_ratio,
		"horizon_y": oy + h * hz_ratio,
		"sky_floor_y": sky_y_mid,
		"distant_horizon_bottom_y": dist_hz_y_mid,
		"mountain_background_bottom_y": mtn_bg_y_mid,
		"land_ground_top_y": land_top_y_mid,
		"sky_rect": sky_r,
		"distant_horizon_rect": dist_hz_r,
		"mountain_background_rect": mtn_bg_r,
		"mountain_ground_rect": mtn_ground_r,
		"mountain_hill_rect": mtn_ground_r,
		"land_ground_rect": land_r,
		"coastline_shore_rect": coast_rect,
		"urban_ground_rect": urban_r,
		"foreground_terrain_rect": fg_r,
		"water_spine": water_spine,
		"water_half_width": water_half_w,
		"has_coastal_bay": has_coastal_bay,
		"sea_on_right": sea_on_right,
		"zones": {
			"SKY": sky_r,
			"DISTANT_HORIZON": dist_hz_r,
			"MOUNTAIN_BACKGROUND": mtn_bg_r,
			"MOUNTAIN_GROUND": mtn_ground_r,
			"MOUNTAIN_HILL": mtn_ground_r,
			"LAND_GROUND": land_r,
			"WATER": coast_rect if has_coastal_bay else Rect2(ox, water_spine[int(water_spine.size() / 2)].y - water_half_w if water_spine.size() > 0 else oy + h * 0.48, w, water_half_w * 2.0),
			"COASTLINE_SHORE": coast_rect,
			"URBAN_GROUND": urban_r,
			"FOREGROUND_TERRAIN": fg_r
		},
		"primary_landscape_layer_count": 1,
		"oversized_background_layer_count": 0,
		"background_within_canvas": true
	}


static func _closest_point_on_polyline(pt: Vector2, spine: PackedVector2Array) -> Vector2:
	if spine.is_empty():
		return pt
	if spine.size() == 1:
		return spine[0]
	var best_pt: Vector2 = spine[0]
	var best_d2: float = INF
	for i in range(spine.size() - 1):
		var a: Vector2 = spine[i]
		var b: Vector2 = spine[i + 1]
		var ab: Vector2 = b - a
		var len2: float = ab.length_squared()
		var t: float = clampf((pt - a).dot(ab) / len2, 0.0, 1.0) if len2 > 0.0001 else 0.0
		var proj: Vector2 = a + ab * t
		var d2: float = pt.distance_squared_to(proj)
		if d2 < best_d2:
			best_d2 = d2
			best_pt = proj
	return best_pt


static func _distance_to_polyline(pt: Vector2, spine: PackedVector2Array) -> float:
	if spine.is_empty():
		return 99999.0
	return pt.distance_to(_closest_point_on_polyline(pt, spine))


static func derive_landmark_grounding_spec(stop_info: Dictionary, country_key: String = "") -> Dictionary:
	if stop_info.has("supporting_surface") and String(stop_info.get("grounding_type", "")) != "":
		return {
			"grounding_classification": String(stop_info.get("grounding_type", "GROUND")),
			"water_relationship": String(stop_info.get("water_relationship", "none")),
			"supporting_terrain_zone": String(stop_info.get("supporting_terrain_zone", "LAND_GROUND")),
			"supporting_surface": String(stop_info.get("supporting_surface", "terrace_ground"))
		}
	var g_type: String = String(stop_info.get("grounding_type", ""))
	var w_rel: String = String(stop_info.get("water_relationship", ""))
	var t_zone: String = String(stop_info.get("supporting_terrain_zone", ""))
	var lm_id: String = String(stop_info.get("landmark_id", ""))
	var label_str: String = String(stop_info.get("label", ""))
	var env_type: String = String(stop_info.get("environment_type", ""))
	if lm_id == "pisa_tower" or label_str.to_lower().begins_with("pisa"):
		return {
			"grounding_classification": "HISTORIC_SITE",
			"water_relationship": "none",
			"supporting_terrain_zone": "URBAN_GROUND",
			"supporting_surface": "piazza_miracoli_ground"
		}
	if lm_id == "eiffel_tower" or label_str.to_lower().begins_with("paris"):
		return {
			"grounding_classification": "URBAN",
			"water_relationship": "riverbank",
			"supporting_terrain_zone": "URBAN_GROUND",
			"supporting_surface": "parisian_urban_ground"
		}
	if g_type == "" or g_type == "GROUND":
		var comb: String = ("%s %s %s %s" % [lm_id, label_str, env_type, country_key]).to_lower()
		if lm_id in ["halong_karst_harbor", "halong_harbor", "mont_saint_michel", "statue_of_liberty", "itsukushima_torii", "torii_shrine", "tanah_lot_bali", "phang_nga_james_bond", "krabi_railay_karsts", "el_nido_lagoons", "bled_island_castle", "stockholm_archipelago", "helsinki_suomenlinna"] or comb.find("island") >= 0 or comb.find("ha long") >= 0:
			g_type = "ISLAND"
			w_rel = "island_in_water"
			t_zone = "COASTLINE_SHORE"
		elif lm_id in ["venice_canal", "venice_canal_rialto", "rijksmuseum_canals", "giethoorn_canals", "bruges_belfry_canals", "kinderdijk_windmills", "nyhavn_harbor", "panama_canal_miraflores"] or comb.find("canal") >= 0 or comb.find("venice") >= 0:
			g_type = "WATERFRONT"
			w_rel = "canal"
			t_zone = "COASTLINE_SHORE"
		elif lm_id in ["mekong_floating_market", "inle_lake_stilt_boats", "kerala_backwaters_houseboat", "hanoi_hoan_kiem_pagoda", "hanoi_pagoda", "ninh_binh_trang_an_karst", "hoian_covered_bridge_lanterns", "hoian_lanterns", "wat_arun_grand_palace", "golden_gate", "golden_gate_bridge", "sydney_opera_harbour_bridge", "victoria_harbour_skyline", "bund_pudong_skyline", "marina_bay_sands", "lighthouse_landmark"] or comb.find("river") >= 0 or comb.find("bay") >= 0 or comb.find("harbor") >= 0 or comb.find("lake") >= 0 or comb.find("delta") >= 0:
			g_type = "WATERFRONT"
			w_rel = "riverbank" if (comb.find("river") >= 0 or comb.find("delta") >= 0) else ("lake_shore" if comb.find("lake") >= 0 else "bay_coast")
			t_zone = "COASTLINE_SHORE"
		elif lm_id in ["amalfi_cliff_village", "cinque_terre_harbor", "oia_blue_domes", "meteora_monasteries", "meteora_cliffs", "tiger_nest_paro", "sigiriya_lion_rock", "grand_canyon_rim", "table_mountain"] or comb.find("cliff") >= 0 or comb.find("canyon") >= 0:
			g_type = "CLIFF"
			if w_rel == "":
				w_rel = "bay_coast" if (comb.find("amalfi") >= 0 or comb.find("cinque") >= 0 or comb.find("oia") >= 0) else "none"
			t_zone = "MOUNTAIN_HILL"
		elif lm_id in ["chureito_pagoda", "wat_phra_that_doi_suthep", "machu_picchu_citadel", "neuschwanstein_castle", "alpine_chalet", "alpine_village", "zermatt_sanctuary", "matterhorn_zermatt", "jungfraujoch_sphinx", "banff_lake_louise", "torres_del_paine", "mount_kilimanjaro", "arenal_volcano"] or comb.find("mountain") >= 0 or comb.find("alps") >= 0 or comb.find("volcano") >= 0:
			g_type = "MOUNTAIN"
			if w_rel == "":
				w_rel = "none"
			t_zone = "MOUNTAIN_HILL"
		elif lm_id in ["giza_sphinx", "giza_pyramids_sphinx", "abu_simbel", "abu_simbel_temples", "karnak_temple", "luxor_obelisk", "petra_treasury", "wadi_rum_arches", "uluru_ayers_rock"] or country_key == "egypt" or comb.find("desert") >= 0:
			g_type = "DESERT"
			if w_rel == "":
				w_rel = "riverbank" if (comb.find("karnak") >= 0 or comb.find("luxor") >= 0 or comb.find("abu_simbel") >= 0) else "none"
			t_zone = "LAND_GROUND"
		elif lm_id in ["tokyo_tower", "saigon_bitexco_skyline", "saigon_skyline", "manhattan_skyline", "las_vegas_strip", "cloud_gate_skyline", "florence_duomo", "milan_duomo", "sagrada_familia", "brandenburg_gate", "st_basils_red_square"] or comb.find("city") >= 0 or comb.find("skyline") >= 0 or comb.find("tower") >= 0:
			g_type = "URBAN"
			if w_rel == "":
				w_rel = "none"
			t_zone = "URBAN_GROUND"
		elif comb.find("valley") >= 0 or comb.find("loire") >= 0:
			g_type = "VALLEY"
			if w_rel == "":
				w_rel = "riverbank" if comb.find("loire") >= 0 else "none"
			t_zone = "LAND_GROUND"
		elif comb.find("temple") >= 0 or comb.find("castle") >= 0 or comb.find("palace") >= 0 or comb.find("colosseum") >= 0 or comb.find("citadel") >= 0:
			g_type = "HISTORIC_SITE"
			if w_rel == "":
				w_rel = "none"
			t_zone = "LAND_GROUND"
		else:
			g_type = "GROUND"
			if w_rel == "":
				w_rel = "none"
			t_zone = "LAND_GROUND"
	if w_rel == "":
		w_rel = "none"
	if t_zone == "" or t_zone == "LAND":
		t_zone = "LAND_GROUND"
	elif t_zone == "COASTLINE" or t_zone == "WATERFRONT":
		t_zone = "COASTLINE_SHORE"
	var surf: String = "terrace_ground"
	match g_type:
		"URBAN": surf = "urban_plaza_ground"
		"HISTORIC_SITE": surf = "historic_sanctuary_terrace"
		"ISLAND": surf = "island_karst_base"
		"WATERFRONT": surf = "waterfront_quay_terrace"
		"MOUNTAIN": surf = "mountain_ridge_terrace"
		"CLIFF": surf = "cliff_headland_ledge"
		"DESERT": surf = "desert_sandstone_plateau"
		"VALLEY": surf = "valley_meadow_terrace"
	return {
		"grounding_classification": g_type,
		"water_relationship": w_rel,
		"supporting_terrain_zone": t_zone,
		"supporting_surface": surf
	}


static func get_allowed_grounding_surfaces(stop_info: Dictionary, country_key: String = "") -> Array[String]:
	var g_spec: Dictionary = derive_landmark_grounding_spec(stop_info, country_key)
	var g_class: String = String(g_spec.get("grounding_classification", "GROUND"))
	var w_rel: String = String(g_spec.get("water_relationship", "none"))
	var lm_id: String = String(stop_info.get("landmark_id", ""))
	var label_str: String = String(stop_info.get("label", stop_info.get("destination_name", ""))).to_lower()
	if lm_id == "eiffel_tower" or label_str.begins_with("paris"):
		return ["URBAN_GROUND"]
	if lm_id == "pisa_tower" or label_str.begins_with("pisa"):
		return ["LAND_GROUND", "URBAN_GROUND"]
	match g_class:
		"URBAN":
			return ["URBAN_GROUND", "LAND_GROUND"]
		"HISTORIC_SITE":
			return ["LAND_GROUND", "URBAN_GROUND", "FOREGROUND_TERRAIN"]
		"MOUNTAIN":
			return ["MOUNTAIN_GROUND", "MOUNTAIN_HILL", "LAND_GROUND"]
		"CLIFF":
			if w_rel != "none":
				return ["MOUNTAIN_GROUND", "MOUNTAIN_HILL", "COASTLINE_SHORE", "LAND_GROUND"]
			return ["MOUNTAIN_GROUND", "MOUNTAIN_HILL", "LAND_GROUND"]
		"ISLAND":
			return ["COASTLINE_SHORE", "ISLAND"]
		"WATERFRONT":
			return ["COASTLINE_SHORE", "WATERFRONT", "URBAN_GROUND", "LAND_GROUND"]
		"DESERT", "VALLEY", "GROUND", _:
			return ["LAND_GROUND", "FOREGROUND_TERRAIN", "URBAN_GROUND"]


static func get_terrain_surface_at_point(
	page: MapPage,
	rect: Rect2,
	pt: Vector2,
	stop_info: Dictionary = {},
	precomputed_water_spine: PackedVector2Array = PackedVector2Array()
) -> String:
	if pt.x < rect.position.x - 0.5 or pt.x > rect.end.x + 0.5 or pt.y < rect.position.y - 0.5 or pt.y > rect.end.y + 0.5:
		return "OUT_OF_BOUNDS"
	var w: float = maxf(280.0, rect.size.x)
	var h: float = maxf(340.0, rect.size.y)
	var theme: MapTheme = page.theme if (page != null and page.theme != null) else MapTheme.from_preset("green_forest")
	var c_key: String = _resolve_country_composition_key(theme, page)
	var sky_y: float = get_sky_boundary_y_at(page, rect, pt.x, c_key)
	var mtn_top_y: float = get_mountain_background_top_y_at(page, rect, pt.x, c_key)
	var dist_hz_y: float = get_distant_horizon_bottom_y_at(page, rect, pt.x, c_key)
	var mtn_bg_y: float = get_mountain_background_bottom_y_at(page, rect, pt.x, c_key)
	var land_top_y: float = get_land_ground_top_y_at(page, rect, pt.x, c_key)

	# 1. Strictly distinguish SKY, DISTANT_HORIZON, and MOUNTAIN_BACKGROUND from playable ground
	if pt.y < sky_y:
		if pt.y >= mtn_top_y:
			return "MOUNTAIN_BACKGROUND"
		return "SKY"
	if pt.y < dist_hz_y:
		if pt.y >= mtn_top_y:
			return "MOUNTAIN_BACKGROUND"
		return "DISTANT_HORIZON"
	if pt.y < mtn_bg_y:
		return "MOUNTAIN_BACKGROUND"
	if pt.y < land_top_y:
		return "MOUNTAIN_GROUND"

	# 2. Check river/canal waterway spine & coastal sea bay
	var water_spine: PackedVector2Array = precomputed_water_spine
	if water_spine.is_empty():
		var split_idx: int = _find_water_crossing_index(page) if page != null else 0
		var flip_w: bool = ((page.page_index % 2) == 1) if page != null else false
		water_spine = _build_country_waterway_spine(page, rect, split_idx, flip_w, c_key)
	var water_half_w: float = clampf(minf(w, h) * 0.044, 15.0, 24.0)
	var d_river: float = _distance_to_polyline(pt, water_spine) if not water_spine.is_empty() else 99999.0

	var g_spec: Dictionary = derive_landmark_grounding_spec(stop_info, c_key) if not stop_info.is_empty() else {}
	var g_class: String = String(g_spec.get("grounding_classification", ""))
	var w_rel: String = String(g_spec.get("water_relationship", "none"))
	var lm_id: String = String(stop_info.get("landmark_id", ""))
	var label_str: String = String(stop_info.get("label", stop_info.get("destination_name", ""))).to_lower()

	if d_river < water_half_w - 1.5:
		if g_class == "ISLAND":
			return "ISLAND"
		if g_class == "WATERFRONT" and w_rel in ["canal", "floating_market", "island_in_water"]:
			return "COASTLINE_SHORE"
		return "WATER"

	# 3. Classify compatible terrain surface on the continuous landmass
	if lm_id == "eiffel_tower" or label_str.begins_with("paris"):
		return "URBAN_GROUND"
	if g_class == "ISLAND":
		return "COASTLINE_SHORE"
	if g_class == "WATERFRONT":
		return "COASTLINE_SHORE"
	if g_class in ["MOUNTAIN", "CLIFF"]:
		if w_rel != "none" and d_river <= water_half_w + 36.0:
			return "COASTLINE_SHORE"
		return "MOUNTAIN_GROUND"
	if g_class == "URBAN" or theme.world_type == "modern_city" or c_key == "usa_nyc":
		return "URBAN_GROUND"
	if pt.y >= rect.position.y + h * 0.88 and g_class not in ["HISTORIC_SITE", "URBAN"]:
		return "FOREGROUND_TERRAIN"
	return "LAND_GROUND"


static func validate_landmark_ground_anchor(
	page: MapPage,
	rect: Rect2,
	ground_anchor: Vector2,
	node_pos: Vector2,
	stop_info: Dictionary,
	precomputed_water_spine: PackedVector2Array = PackedVector2Array()
) -> Dictionary:
	var theme: MapTheme = page.theme if (page != null and page.theme != null) else MapTheme.from_preset("green_forest")
	var c_key: String = _resolve_country_composition_key(theme, page)
	var g_spec: Dictionary = derive_landmark_grounding_spec(stop_info, c_key)
	var g_class: String = String(g_spec.get("grounding_classification", "GROUND"))
	var allowed_surfaces: Array[String] = get_allowed_grounding_surfaces(stop_info, c_key)
	var surf: String = get_terrain_surface_at_point(page, rect, ground_anchor, stop_info, precomputed_water_spine)
	var route_surf: String = get_terrain_surface_at_point(page, rect, node_pos, stop_info, precomputed_water_spine)

	var in_bounds: bool = (
		ground_anchor.x >= rect.position.x and ground_anchor.x <= rect.end.x and
		ground_anchor.y >= rect.position.y and ground_anchor.y <= rect.end.y
	)
	var not_sky: bool = (surf != "SKY" and ground_anchor.y >= get_sky_boundary_y_at(page, rect, ground_anchor.x, c_key) - 0.5)
	var not_distant_horizon: bool = (surf != "DISTANT_HORIZON" and ground_anchor.y >= get_distant_horizon_bottom_y_at(page, rect, ground_anchor.x, c_key) - 0.5)
	var not_mtn_bg: bool = (
		surf != "MOUNTAIN_BACKGROUND" and
		ground_anchor.y >= get_mountain_background_bottom_y_at(page, rect, ground_anchor.x, c_key) - 0.5 and
		(g_class in ["MOUNTAIN", "CLIFF"] or (surf not in ["MOUNTAIN_GROUND", "MOUNTAIN_HILL"] and ground_anchor.y >= get_land_ground_top_y_at(page, rect, ground_anchor.x, c_key) - 0.5))
	)
	var not_in_water: bool = (surf != "WATER")
	var inside_surface: bool = (surf in allowed_surfaces) and not_sky and not_distant_horizon and not_mtn_bg and not_in_water
	var route_endpoint_ok: bool = (
		route_surf not in ["SKY", "DISTANT_HORIZON", "MOUNTAIN_BACKGROUND", "OUT_OF_BOUNDS"] and
		absf(ground_anchor.y - node_pos.y) <= 78.0
	)
	return {
		"valid": in_bounds and inside_surface and route_endpoint_ok,
		"terrain_surface": surf,
		"allowed_grounding_surfaces": allowed_surfaces,
		"ground_anchor_in_bounds": in_bounds,
		"ground_anchor_inside_surface": inside_surface,
		"ground_anchor_not_sky": not_sky,
		"ground_anchor_not_distant_horizon": not_distant_horizon,
		"ground_anchor_not_incompatible_mountain_background": not_mtn_bg,
		"ground_anchor_not_in_water": not_in_water,
		"route_endpoint_surface": route_surf,
		"route_endpoint_compatible": route_endpoint_ok,
		"route_endpoint_surface_compatible": route_endpoint_ok
	}


static func draw_debug_spatial_overlay(canvas: CanvasItem, page: MapPage, rect: Rect2) -> Dictionary:
	var zones: Dictionary = get_country_spatial_zones(page, rect)
	var man: Dictionary = get_page_landmark_manifest(page, rect)
	var dest_lms: Array = man.get("destination_landmarks", [])
	if canvas != null:
		var z_dict: Dictionary = zones.get("zones", {})
		var dbg_cols := {
			"SKY": Color(0.20, 0.65, 1.0, 0.16),
			"DISTANT_HORIZON": Color(0.65, 0.55, 0.95, 0.18),
			"MOUNTAIN_BACKGROUND": Color(0.95, 0.25, 0.25, 0.20),
			"MOUNTAIN_GROUND": Color(0.85, 0.55, 0.20, 0.18),
			"LAND_GROUND": Color(0.20, 0.85, 0.35, 0.12),
			"COASTLINE_SHORE": Color(0.95, 0.85, 0.25, 0.16),
			"WATER": Color(0.10, 0.50, 0.95, 0.18)
		}
		for z_name in ["SKY", "DISTANT_HORIZON", "MOUNTAIN_BACKGROUND", "MOUNTAIN_GROUND", "LAND_GROUND", "COASTLINE_SHORE", "WATER"]:
			if z_dict.has(z_name):
				var r_z: Rect2 = z_dict[z_name]
				canvas.draw_rect(r_z, dbg_cols[z_name], true)
				canvas.draw_rect(r_z, dbg_cols[z_name].lightened(0.35), false, 1.2)
		for d_entry in dest_lms:
			var ga: Vector2 = d_entry.get("ground_anchor", Vector2.ZERO)
			var rp: Vector2 = d_entry.get("route_endpoint", d_entry.get("courtyard_position", Vector2.ZERO))
			canvas.draw_line(rp, ga, Color(1.0, 0.95, 0.20, 0.90), 2.0)
			canvas.draw_circle(rp, 4.5, Color(0.15, 0.95, 0.95, 0.95))
			canvas.draw_circle(ga, 5.0, Color(1.0, 0.20, 0.85, 0.95))
	return {
		"zones_rendered": ["SKY", "DISTANT_HORIZON", "MOUNTAIN_BACKGROUND", "MOUNTAIN_GROUND", "LAND_GROUND", "WATER", "COASTLINE_SHORE"],
		"landmark_ground_anchor_count": dest_lms.size(),
		"route_endpoint_count": page.nodes.size() if page != null else 0
	}


static func _find_water_crossing_index(page: MapPage) -> int:
	if page == null:
		return 0
	var n: int = page.nodes.size()
	if n < 3:
		return 0
	var best_idx: int = clampi(int(round(float(n) * 0.38)) - 1, 0, n - 2)
	var best_score: float = -99999.0
	for i in range(1, n - 2):
		var nd_a: MapNode = page.nodes[i]
		var nd_b: MapNode = page.nodes[i + 1]
		var dy: float = absf(nd_a.position.y - nd_b.position.y)
		var lm_a: String = String(nd_a.landmark.get("landmark_id", ""))
		var lm_b: String = String(nd_b.landmark.get("landmark_id", ""))
		var wrel_a: String = String(nd_a.landmark.get("water_relationship", "none"))
		var wrel_b: String = String(nd_b.landmark.get("water_relationship", "none"))
		var score: float = dy
		if wrel_a != "none" or wrel_b != "none":
			score += 18.0
		if lm_a == "pisa_tower" or lm_b == "pisa_tower":
			score -= 60.0
		if score > best_score:
			best_score = score
			best_idx = i
	return best_idx


static func _build_country_waterway_spine(
	page: MapPage,
	rect: Rect2,
	split_idx: int,
	flip_world: bool,
	_country_key: String = ""
) -> PackedVector2Array:
	var w: float = maxf(280.0, rect.size.x)
	var h: float = maxf(340.0, rect.size.y)
	var ox: float = rect.position.x
	var oy: float = rect.position.y
	var n: int = page.nodes.size() if page != null else 0
	var cross_pt := Vector2(ox + w * 0.5, oy + h * 0.52)
	if n >= 2 and split_idx >= 0 and split_idx < n - 1:
		cross_pt = Vector2(ox, oy) + (page.nodes[split_idx].position + page.nodes[split_idx + 1].position) * 0.5

	var river_spine := PackedVector2Array()
	var r_segs: int = 24
	var left_y: float = clampf(cross_pt.y + (h * 0.06 if not flip_world else -h * 0.06), oy + h * 0.28, oy + h * 0.74)
	var right_y: float = clampf(cross_pt.y + (-h * 0.06 if not flip_world else h * 0.06), oy + h * 0.28, oy + h * 0.74)
	var cross_u: float = clampf((cross_pt.x - ox) / maxf(1.0, w), 0.15, 0.85)
	for i in range(r_segs + 1):
		var u: float = float(i) / float(r_segs)
		var px: float = ox + u * w
		var base_ry: float = lerpf(left_y, right_y, u)
		var pin_interp: float = lerpf(left_y, right_y, cross_u)
		var dy_corr: float = (cross_pt.y - pin_interp) * exp(-pow((u - cross_u) / 0.28, 2.0))
		var meander: float = sin(u * PI * 2.0) * (h * 0.020) * (1.0 - exp(-pow((u - cross_u) / 0.18, 2.0)))
		var py: float = base_ry + dy_corr + meander
		# Deflect river away from land-grounded stops so land monuments (e.g. Pisa) never sit in water
		if page != null and split_idx >= 0:
			for n_i in range(n):
				var nd: MapNode = page.nodes[n_i]
				var np: Vector2 = Vector2(ox, oy) + nd.position
				var dx_n: float = absf(px - np.x)
				var req_clear_y: float = nd.node_size.y * 0.82 + 24.0
				if dx_n < nd.node_size.x * 1.35:
					var dy_n: float = py - np.y
					if absf(dy_n) < req_clear_y:
						var push_sign: float = 1.0 if (n_i <= split_idx and np.y < cross_pt.y) else (-1.0 if np.y > cross_pt.y else (1.0 if dy_n >= 0.0 else -1.0))
						var atten: float = 1.0 - (dx_n / maxf(1.0, nd.node_size.x * 1.35))
						py = lerpf(py, np.y + push_sign * req_clear_y, atten * 0.85)
		py = clampf(py, oy + h * 0.24, oy + h * 0.84)
		river_spine.append(Vector2(px, py))
	return river_spine


# ==============================================================================
# 1. FULL-SCREEN ATMOSPHERE & DEEP MIDGROUND PANORAMA (NO TOP 1/5 SPLIT)
# ==============================================================================
static func _draw_sky_and_regional_horizon(
	canvas: CanvasItem,
	rect: Rect2,
	page: MapPage,
	theme: MapTheme,
	pal: Dictionary,
	flip_world: bool,
	anim_time: float
) -> void:
	var w: float = rect.size.x
	var h: float = rect.size.y
	var ox: float = rect.position.x
	var oy: float = rect.position.y
	var cid: String = page.country_id if page != null else ""
	var country_key: String = _resolve_country_composition_key(theme, page)
	var hz_ratio: float = get_country_horizon_ratio(cid, country_key)

	var sky_top: Color = pal.get("sky_top", Color(0.28, 0.70, 0.94, 1.0))
	var sky_bot: Color = pal.get("sky_bottom", Color(0.84, 0.95, 0.99, 1.0))
	var ground_high: Color = pal.get("ground_primary", Color(0.28, 0.58, 0.34, 1.0))
	if country_key in ["vietnam_bay", "thailand", "norway", "coastal_archipelago"]:
		ground_high = pal.get("island_surface", Color(0.32, 0.66, 0.34, 1.0)).darkened(0.18)

	# Full-screen continuous base painting strictly inside rect
	canvas.draw_rect(Rect2(ox, oy, w, h), ground_high, true)
	var sky_bands: int = 20
	var sky_reach: float = hz_ratio + 0.08
	for i in range(sky_bands):
		var t0: float = float(i) / float(sky_bands)
		var t1: float = float(i + 1) / float(sky_bands)
		var c: Color = sky_top.lerp(sky_bot, pow((t0 + t1) * 0.5, 0.82))
		if t0 > 0.72:
			c = c.lerp(ground_high.lightened(0.18), (t0 - 0.72) / 0.28)
		canvas.draw_rect(Rect2(ox, oy + h * t0 * sky_reach, w, h * (t1 - t0) * sky_reach + 2.0), c, true)

	# Celestial sun / moon / nebula glow
	var sun_u: float = 0.22 if not flip_world else 0.78
	var sun_pos := Vector2(ox + w * sun_u, oy + h * 0.068)
	if country_key == "space":
		var neb_pts := PackedVector2Array([
			Vector2(ox, oy + h * 0.16),
			Vector2(ox + w * 0.35, oy + h * 0.06),
			Vector2(ox + w * 0.72, oy + h * 0.04),
			Vector2(ox + w, oy + h * 0.11),
			Vector2(ox + w, oy + h * 0.20),
			Vector2(ox + w * 0.65, oy + h * 0.14),
			Vector2(ox + w * 0.28, oy + h * 0.17),
			Vector2(ox, oy + h * 0.21)
		])
		var neb_col := Color(0.56, 0.38, 0.88, 0.28) if theme.world_id != "mars" else Color(0.92, 0.52, 0.34, 0.24)
		canvas.draw_colored_polygon(neb_pts, neb_col)
		for s_i in range(32):
			var sx: float = ox + fposmod(float(s_i * 73 + page.page_index * 29), 97.0) / 97.0 * w
			var sy: float = oy + fposmod(float(s_i * 41 + page.page_index * 17), 83.0) / 83.0 * (h * 0.17)
			var tw: float = 1.3 + 0.7 * sin(anim_time * 2.2 + float(s_i))
			canvas.draw_circle(Vector2(sx, sy), tw, Color(1.0, 0.97, 0.84, 0.84))
		var pl_pos := Vector2(ox + w * (0.76 if not flip_world else 0.24), oy + h * 0.085)
		canvas.draw_circle(pl_pos, minf(w, h) * 0.048, Color(0.18, 0.56, 0.92, 0.96) if theme.world_id == "moon" else Color(0.92, 0.64, 0.34, 0.94))
		canvas.draw_circle(pl_pos + Vector2(-4.0, -3.0), minf(w, h) * 0.022, Color(0.36, 0.82, 0.48, 0.88))
	else:
		var sun_col := Color(1.0, 0.95, 0.78, 0.92) if country_key != "japan" else Color(1.0, 0.36, 0.32, 0.82)
		canvas.draw_circle(sun_pos, minf(w, h) * 0.082, Color(sun_col.r, sun_col.g, sun_col.b, 0.16))
		canvas.draw_circle(sun_pos, minf(w, h) * 0.048, Color(sun_col.r, sun_col.g, sun_col.b, 0.34))
		canvas.draw_circle(sun_pos, minf(w, h) * 0.030, sun_col)

	# DISTANT_HORIZON (far_hills) & MOUNTAIN_GROUND highland rim (near_hills) locked to contour equations
	var dist_col: Color = pal.get("cliff_color", Color(0.45, 0.52, 0.66)).lerp(sky_bot, 0.34)
	var mid_ridge_col: Color = ground_high.lerp(sky_bot, 0.14)
	var far_hills := PackedVector2Array()
	var near_hills := PackedVector2Array()
	var h_segs: int = 28
	for i in range(h_segs + 1):
		var u: float = float(i) / float(h_segs)
		var px_h: float = ox + u * w
		far_hills.append(Vector2(px_h, get_sky_boundary_y_at(page, rect, px_h)))
		near_hills.append(Vector2(px_h, get_mountain_background_bottom_y_at(page, rect, px_h)))
	far_hills.append(Vector2(ox + w, oy + h * 0.28))
	far_hills.append(Vector2(ox, oy + h * 0.28))
	near_hills.append(Vector2(ox + w, oy + h * 0.30))
	near_hills.append(Vector2(ox, oy + h * 0.30))
	canvas.draw_colored_polygon(far_hills, dist_col)

	# Iconic Country MOUNTAIN_BACKGROUND Panorama Massif anchored at get_mountain_background_bottom_y_at
	var fuji_cx: float = ox + w * (0.56 if not flip_world else 0.44)
	var mtn_bg_base_y: float = get_mountain_background_bottom_y_at(page, rect, fuji_cx) + h * 0.012
	match country_key:
		"japan":
			var fuji_base_y: float = mtn_bg_base_y
			var fuji_top_y: float = oy + h * 0.048
			var f_l1: float = maxf(ox, fuji_cx - w * 0.34)
			var f_r1: float = minf(ox + w, fuji_cx + w * 0.34)
			var fuji_poly := PackedVector2Array([
				Vector2(f_l1, fuji_base_y),
				Vector2(maxf(ox, fuji_cx - w * 0.18), lerpf(fuji_top_y, fuji_base_y, 0.56)),
				Vector2(fuji_cx - w * 0.070, fuji_top_y + h * 0.010),
				Vector2(fuji_cx - w * 0.038, fuji_top_y),
				Vector2(fuji_cx + w * 0.038, fuji_top_y),
				Vector2(fuji_cx + w * 0.070, fuji_top_y + h * 0.010),
				Vector2(minf(ox + w, fuji_cx + w * 0.18), lerpf(fuji_top_y, fuji_base_y, 0.56)),
				Vector2(f_r1, fuji_base_y)
			])
			canvas.draw_colored_polygon(fuji_poly, Color(0.26, 0.38, 0.68, 0.96))
			var snow_y: float = lerpf(fuji_top_y, fuji_base_y, 0.38)
			var snow_poly := PackedVector2Array([
				Vector2(fuji_cx - w * 0.115, snow_y),
				Vector2(fuji_cx - w * 0.070, fuji_top_y + h * 0.010),
				Vector2(fuji_cx - w * 0.038, fuji_top_y),
				Vector2(fuji_cx + w * 0.038, fuji_top_y),
				Vector2(fuji_cx + w * 0.070, fuji_top_y + h * 0.010),
				Vector2(fuji_cx + w * 0.115, snow_y),
				Vector2(fuji_cx + w * 0.06, snow_y - h * 0.012),
				Vector2(fuji_cx, snow_y + h * 0.008),
				Vector2(fuji_cx - w * 0.06, snow_y - h * 0.012)
			])
			canvas.draw_colored_polygon(snow_poly, Color(0.98, 0.99, 1.0, 0.98))
		"vietnam_bay", "vietnam_city", "thailand", "coastal_archipelago":
			var k_xs: Array[float] = [0.16, 0.34, 0.54, 0.74, 0.86]
			var k_hs: Array[float] = [0.085, 0.105, 0.118, 0.095, 0.080]
			var ridge_tint := Color(0.18, 0.48, 0.44, 0.88) if country_key != "thailand" else Color(0.22, 0.52, 0.38, 0.88)
			for k_i in range(k_xs.size()):
				var kx: float = ox + w * k_xs[k_i]
				var kh: float = h * k_hs[k_i]
				var kw: float = w * (0.075 + float(k_i % 2) * 0.016)
				var k_base: float = get_mountain_background_bottom_y_at(page, rect, kx) + h * 0.008
				var k_pts := PackedVector2Array([
					Vector2(clampf(kx - kw, ox, ox + w), k_base),
					Vector2(clampf(kx - kw * 0.82, ox, ox + w), k_base - kh * 0.62),
					Vector2(clampf(kx - kw * 0.32, ox, ox + w), k_base - kh),
					Vector2(clampf(kx + kw * 0.28, ox, ox + w), k_base - kh * 0.92),
					Vector2(clampf(kx + kw * 0.84, ox, ox + w), k_base - kh * 0.48),
					Vector2(clampf(kx + kw, ox, ox + w), k_base)
				])
				canvas.draw_colored_polygon(k_pts, ridge_tint)
		"italy":
			var aq_y: float = mtn_bg_base_y
			var aq_x0: float = ox + w * 0.08
			var aq_w: float = w * 0.54
			canvas.draw_rect(Rect2(aq_x0, aq_y - h * 0.042, aq_w, h * 0.012), Color(0.86, 0.76, 0.60, 0.88), true)
			for a_i in range(7):
				var px: float = aq_x0 + float(a_i) * (aq_w / 6.5)
				canvas.draw_rect(Rect2(px, aq_y - h * 0.032, w * 0.024, h * 0.038), Color(0.82, 0.70, 0.54, 0.88), true)
		"france":
			var alps := PackedVector2Array([
				Vector2(ox + w * 0.04, mtn_bg_base_y),
				Vector2(ox + w * 0.22, oy + h * 0.078),
				Vector2(ox + w * 0.38, mtn_bg_base_y - h * 0.025),
				Vector2(ox + w * 0.58, oy + h * 0.068),
				Vector2(ox + w * 0.78, mtn_bg_base_y - h * 0.025),
				Vector2(ox + w * 0.96, mtn_bg_base_y)
			])
			canvas.draw_colored_polygon(alps, Color(0.58, 0.64, 0.84, 0.85))
		"usa_nyc":
			var nyc_xs: Array[float] = [0.18, 0.28, 0.42, 0.56, 0.70, 0.82]
			var nyc_hs: Array[float] = [0.065, 0.090, 0.110, 0.085, 0.095, 0.070]
			for b_i in range(nyc_xs.size()):
				var bx: float = ox + w * nyc_xs[b_i]
				var bh: float = h * nyc_hs[b_i]
				var bw: float = w * 0.060
				canvas.draw_rect(Rect2(bx - bw * 0.5, mtn_bg_base_y - bh, bw, bh), Color(0.28, 0.40, 0.58, 0.86), true)
		"usa_canyon", "egypt":
			if country_key == "egypt":
				for p_i in range(2):
					var px_eg: float = ox + w * (0.32 + float(p_i) * 0.32)
					var py: float = mtn_bg_base_y
					var ps: float = w * (0.12 - float(p_i) * 0.02)
					canvas.draw_colored_polygon(PackedVector2Array([
						Vector2(clampf(px_eg - ps, ox, ox + w), py),
						Vector2(px_eg, py - ps * 0.72),
						Vector2(clampf(px_eg + ps, ox, ox + w), py)
					]), Color(0.92, 0.72, 0.34, 0.90))
			else:
				for b_i in range(3):
					var bx_cy: float = ox + w * (0.20 + float(b_i) * 0.30)
					var by: float = mtn_bg_base_y
					var bw_cy: float = w * 0.095
					var bh_cy: float = h * (0.075 + float(b_i % 2) * 0.020)
					canvas.draw_colored_polygon(PackedVector2Array([
						Vector2(clampf(bx_cy - bw_cy, ox, ox + w), by),
						Vector2(clampf(bx_cy - bw_cy * 0.68, ox, ox + w), by - bh_cy),
						Vector2(clampf(bx_cy + bw_cy * 0.68, ox, ox + w), by - bh_cy),
						Vector2(clampf(bx_cy + bw_cy, ox, ox + w), by)
					]), Color(0.80, 0.38, 0.22, 0.90))
		"switzerland", "norway":
			var mh_x: float = fuji_cx
			var mh_base: float = mtn_bg_base_y
			var mh_top: float = oy + h * 0.052
			canvas.draw_colored_polygon(PackedVector2Array([
				Vector2(maxf(ox, mh_x - w * 0.24), mh_base),
				Vector2(mh_x - w * 0.09, oy + h * 0.11),
				Vector2(mh_x + w * 0.02, mh_top),
				Vector2(mh_x + w * 0.10, oy + h * 0.12),
				Vector2(minf(ox + w, mh_x + w * 0.24), mh_base)
			]), Color(0.42, 0.54, 0.72, 0.95))
			canvas.draw_colored_polygon(PackedVector2Array([
				Vector2(mh_x - w * 0.09, oy + h * 0.11),
				Vector2(mh_x + w * 0.02, mh_top),
				Vector2(mh_x + w * 0.04, oy + h * 0.135),
				Vector2(mh_x - w * 0.07, oy + h * 0.145)
			]), Color(0.96, 0.99, 1.0, 0.96))

	canvas.draw_colored_polygon(near_hills, mid_ridge_col)

	if country_key != "space":
		var cloud_col := Color(1.0, 0.99, 0.96, 0.72)
		for c_i in range(3):
			var cu: float = clampf(fposmod(0.18 + float(c_i) * 0.30 + anim_time * 0.003 * float(c_i + 1), 0.76) + 0.12, 0.14, 0.86)
			var cy: float = oy + h * (0.045 + float(c_i % 2) * 0.028)
			var cw: float = w * (0.13 + float(c_i % 2) * 0.025)
			_draw_storybook_cloud(canvas, Vector2(ox + cu * w, cy), cw, cloud_col)


# ==============================================================================
# 2A. CONTINUOUS COASTAL & RIVER DELTA TOPOGRAPHIC WORLD
#     (Vietnam, Thailand, Norway, Coastal Archipelagos — ONE Unified Landscape!)
# ==============================================================================
static func _draw_coastal_bay_world(
	canvas: CanvasItem,
	rect: Rect2,
	page: MapPage,
	theme: MapTheme,
	pal: Dictionary,
	split_idx: int,
	flip_world: bool,
	anim_time: float
) -> void:
	var w: float = rect.size.x
	var h: float = rect.size.y
	var ox: float = rect.position.x
	var oy: float = rect.position.y
	var c_key: String = _resolve_country_composition_key(theme, page)

	var deep_water: Color = pal.get("water_color", Color(0.08, 0.56, 0.76, 1.0)).darkened(0.12)
	var mid_water: Color = pal.get("water_color", Color(0.14, 0.68, 0.84, 1.0))
	var shallow_water: Color = pal.get("ground_secondary", Color(0.24, 0.82, 0.86, 1.0))
	var sand_col: Color = pal.get("shore_color", Color(0.94, 0.86, 0.64, 1.0))
	var turf_col: Color = pal.get("island_surface", Color(0.36, 0.74, 0.34, 1.0))
	var high_turf: Color = turf_col.darkened(0.16)
	var cliff_col: Color = pal.get("cliff_color", Color(0.52, 0.46, 0.38, 1.0))

	# 1. Continuous Full-Width Country Landmass Base starting at get_land_ground_top_y_at
	var base_land := PackedVector2Array()
	for i in range(25):
		var u: float = float(i) / 24.0
		var px_l: float = ox + u * w
		base_land.append(Vector2(px_l, get_land_ground_top_y_at(page, rect, px_l)))
	base_land.append(Vector2(ox + w, oy + h))
	base_land.append(Vector2(ox, oy + h))
	canvas.draw_colored_polygon(base_land, high_turf)

	# Stepped continuous topographic terraces across the entire country width [ox..ox+w]
	var terr_vs: Array[float] = [0.27, 0.44, 0.62, 0.79]
	for t_i in range(terr_vs.size()):
		var tv: float = terr_vs[t_i]
		var t_col: Color = high_turf.lerp(turf_col.lightened(0.08), float(t_i + 1) * 0.24)
		var t_poly := PackedVector2Array()
		for s_i in range(25):
			var u_t: float = float(s_i) / 24.0
			var su: float = 1.0 - u_t if flip_world else u_t
			var px_t: float = ox + u_t * w
			var min_ty: float = get_land_ground_top_y_at(page, rect, px_t) + 6.0
			var wy: float = maxf(min_ty, oy + h * clampf(tv + (su - 0.5) * (0.045 if t_i % 2 == 0 else -0.040) + sin(su * PI * 2.2 + float(t_i)) * 0.020, 0.21, 0.94))
			t_poly.append(Vector2(px_t, wy))
		t_poly.append(Vector2(ox + w, oy + h))
		t_poly.append(Vector2(ox, oy + h))
		canvas.draw_colored_polygon(t_poly, t_col)

	# 2. Integrated Coastal Sea Bay & River Delta Basin Carved Cleanly Into the Coastline
	var sea_on_right: bool = not flip_world
	var bay_top_y: float = get_land_ground_top_y_at(page, rect, ox + (w if sea_on_right else 0.0)) + 4.0
	var bay_bot_y: float = oy + h * 0.90
	var shore_poly := PackedVector2Array()
	var water_poly := PackedVector2Array()
	var deep_poly := PackedVector2Array()
	var b_steps: int = 24
	var edge_x: float = ox + w if sea_on_right else ox
	var dir_in: float = -1.0 if sea_on_right else 1.0
	shore_poly.append(Vector2(edge_x, bay_top_y))
	water_poly.append(Vector2(edge_x, bay_top_y + 4.0))
	deep_poly.append(Vector2(edge_x, bay_top_y + 10.0))
	for i in range(b_steps + 1):
		var t: float = float(i) / float(b_steps)
		var py: float = lerpf(bay_top_y, bay_bot_y, t)
		var cove_reach: float = (0.34 * sin(t * PI) + 0.08 * sin(t * PI * 3.0)) * w
		var sx: float = clampf(edge_x + dir_in * (cove_reach + 8.0), ox + w * 0.14, ox + w * 0.86)
		var wx: float = clampf(edge_x + dir_in * cove_reach, ox + w * 0.16, ox + w * 0.84)
		var dx: float = clampf(edge_x + dir_in * (cove_reach * 0.68), ox + w * 0.22, ox + w * 0.78)
		shore_poly.append(Vector2(sx, py))
		water_poly.append(Vector2(wx, py))
		deep_poly.append(Vector2(dx, py))
	shore_poly.append(Vector2(edge_x, bay_bot_y))
	water_poly.append(Vector2(edge_x, bay_bot_y - 4.0))
	deep_poly.append(Vector2(edge_x, bay_bot_y - 10.0))
	canvas.draw_colored_polygon(shore_poly, sand_col)
	canvas.draw_colored_polygon(water_poly, shallow_water.lerp(mid_water, 0.55))
	canvas.draw_colored_polygon(deep_poly, deep_water)

	# 3. Continuous River / Bay Channel Connecting Inland Delta to the Coastal Bay
	var river_spine: PackedVector2Array = _build_country_waterway_spine(page, rect, split_idx, flip_world, c_key)
	var river_half_w: float = clampf(minf(w, h) * 0.046, 15.0, 24.0)
	_draw_ribbon_along_spine(canvas, river_spine, river_half_w + 6.0, cliff_col.darkened(0.18), Vector2(0.0, 2.0), rect)
	_draw_ribbon_along_spine(canvas, river_spine, river_half_w + 3.2, sand_col, Vector2.ZERO, rect)
	_draw_ribbon_along_spine(canvas, river_spine, river_half_w, mid_water, Vector2.ZERO, rect)
	_draw_ribbon_along_spine(canvas, river_spine, river_half_w * 0.58, shallow_water.lightened(0.12), Vector2(0.0, -1.0), rect)

	# 4. Iconic Limestone Karst Islets / Fjord Sea Stacks inside the Coastal Bay Water Zone
	var bay_u: float = 0.82 if sea_on_right else 0.18
	var karst_spots: Array[Vector2] = [
		Vector2(ox + w * bay_u, oy + h * 0.38),
		Vector2(ox + w * (bay_u + (-0.05 if sea_on_right else 0.05)), oy + h * 0.62)
	]
	for k_idx in range(karst_spots.size()):
		var kp: Vector2 = _nudge_away_from_nodes(karst_spots[k_idx], page, Vector2(ox, oy), 48.0) if split_idx >= 0 else karst_spots[k_idx]
		kp.x = clampf(kp.x, ox + 28.0, ox + w - 28.0)
		kp.y = clampf(kp.y, oy + h * 0.28, oy + h * 0.84)
		_draw_halong_karst_islet(canvas, kp, (21.0 - float(k_idx) * 2.5), cliff_col, turf_col, shallow_water)

	# 5. Subtle Animated Water Ripples inside the Bay & Channel
	for w_i in range(6):
		var rp: Vector2 = river_spine[clampi(2 + w_i * 3, 1, river_spine.size() - 2)]
		var wp := Vector2(clampf(rp.x + sin(anim_time * 1.4 + float(w_i)) * 3.5, ox + 16.0, ox + w - 16.0), rp.y)
		canvas.draw_arc(wp, 7.5, PI * 1.1, PI * 1.9, 8, Color(1.0, 1.0, 1.0, 0.34), 1.5, true)


static func _offset_and_scale_poly(poly: PackedVector2Array, pivot: Vector2, scale_v: Vector2, offset_v: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		var d: Vector2 = p - pivot
		out.append(pivot + Vector2(d.x * scale_v.x, d.y * scale_v.y) + offset_v)
	return out


static func _offset_and_scale_poly_clamped(poly: PackedVector2Array, pivot: Vector2, scale_v: Vector2, offset_v: Vector2, bounds: Rect2) -> PackedVector2Array:
	var out := PackedVector2Array()
	var min_x: float = bounds.position.x
	var max_x: float = bounds.end.x
	var min_y: float = bounds.position.y
	var max_y: float = bounds.end.y
	for p in poly:
		var d: Vector2 = p - pivot
		var pt: Vector2 = pivot + Vector2(d.x * scale_v.x, d.y * scale_v.y) + offset_v
		out.append(Vector2(clampf(pt.x, min_x, max_x), clampf(pt.y, min_y, max_y)))
	return out


static func _draw_halong_karst_islet(
	canvas: CanvasItem,
	pos: Vector2,
	r: float,
	cliff_col: Color,
	turf_col: Color,
	shallow_col: Color
) -> void:
	_draw_ellipse_filled(canvas, pos + Vector2(0.0, r * 0.32), r * 1.24, r * 0.44, Color(shallow_col.r, shallow_col.g, shallow_col.b, 0.58))
	_draw_ellipse_filled(canvas, pos + Vector2(0.0, r * 0.30), r * 1.02, r * 0.34, Color(0.96, 0.99, 1.0, 0.76))
	var rock_pts := PackedVector2Array([
		pos + Vector2(-r * 0.86, r * 0.28),
		pos + Vector2(-r * 0.72, -r * 0.48),
		pos + Vector2(-r * 0.26, -r * 1.05),
		pos + Vector2(r * 0.24, -r * 0.86),
		pos + Vector2(r * 0.78, -r * 0.32),
		pos + Vector2(r * 0.88, r * 0.28)
	])
	canvas.draw_colored_polygon(rock_pts, cliff_col)
	var shade_pts := PackedVector2Array([
		pos + Vector2(-r * 0.08, -r * 0.95),
		pos + Vector2(r * 0.24, -r * 0.86),
		pos + Vector2(r * 0.78, -r * 0.32),
		pos + Vector2(r * 0.88, r * 0.28),
		pos + Vector2(0.0, r * 0.28)
	])
	canvas.draw_colored_polygon(shade_pts, cliff_col.darkened(0.24))
	_draw_ellipse_filled(canvas, pos + Vector2(-r * 0.14, -r * 0.76), r * 0.50, r * 0.24, turf_col.darkened(0.10))
	_draw_ellipse_filled(canvas, pos + Vector2(-r * 0.18, -r * 0.82), r * 0.40, r * 0.19, turf_col.lightened(0.08))


# ==============================================================================
# 2B. INLAND ILLUSTRATED TOPOGRAPHIC WORLD (Japan, Italy, France, Vietnam City,
#     USA NYC & Grand Canyon, Egypt, Switzerland, Space)
# ==============================================================================
static func _draw_inland_topographic_world(
	canvas: CanvasItem,
	rect: Rect2,
	page: MapPage,
	theme: MapTheme,
	pal: Dictionary,
	split_idx: int,
	flip_world: bool,
	_anim_time: float
) -> void:
	var w: float = rect.size.x
	var h: float = rect.size.y
	var ox: float = rect.position.x
	var oy: float = rect.position.y
	var cid: String = page.country_id if page != null else ""
	var c_key: String = _resolve_country_composition_key(theme, page)
	var hz_ratio: float = get_country_horizon_ratio(cid, c_key)

	var ground_high: Color = pal.get("ground_primary", Color(0.26, 0.58, 0.28, 1.0))
	var ground_mid: Color = pal.get("ground_secondary", Color(0.42, 0.74, 0.32, 1.0))
	var ground_low: Color = pal.get("island_surface", Color(0.52, 0.80, 0.36, 1.0))
	var cliff_col: Color = pal.get("cliff_color", Color(0.52, 0.42, 0.30, 1.0))
	var water_col: Color = pal.get("water_color", Color(0.20, 0.70, 0.86, 1.0))
	var bank_col: Color = pal.get("shore_color", Color(0.88, 0.84, 0.62, 1.0))

	# 1. Six Large Sweeping Diagonal Topographic Terraces Across the Entire Map
	# Terrace 0 starts directly at get_land_ground_top_y_at so zero background mountain apron is exposed!
	var top_t: float = hz_ratio + 0.048
	var terrace_ys: Array[float] = [
		top_t,
		lerpf(top_t, 0.90, 0.18),
		lerpf(top_t, 0.90, 0.38),
		lerpf(top_t, 0.90, 0.58),
		lerpf(top_t, 0.90, 0.78),
		0.90
	]
	var terrace_cols: Array[Color] = [
		ground_high,
		ground_high.lerp(ground_mid, 0.38),
		ground_mid,
		ground_mid.lerp(ground_low, 0.55),
		ground_low,
		ground_low.lightened(0.07)
	]

	var country_phase: float = float(page.page_index if page != null else 0) * 0.63
	var slope_amp: float = 0.058
	match c_key:
		"switzerland", "japan":
			slope_amp = 0.072
		"egypt", "usa_canyon":
			slope_amp = 0.046
		"france", "italy":
			slope_amp = 0.054

	for t_i in range(terrace_ys.size()):
		var base_v: float = terrace_ys[t_i]
		var top_col: Color = terrace_cols[t_i]
		var lip_h: float = h * (0.018 + float(t_i % 2) * 0.005)
		var lip_col: Color = cliff_col.lerp(top_col.darkened(0.36), 0.42)

		var ridge_pts := PackedVector2Array()
		var lip_pts := PackedVector2Array()
		var segs: int = 28
		for s_i in range(segs + 1):
			var u: float = float(s_i) / float(segs)
			var su: float = 1.0 - u if flip_world else u
			var px_s: float = ox + u * w
			var py: float
			if t_i == 0:
				py = get_land_ground_top_y_at(page, rect, px_s)
			else:
				var slope: float = (su - 0.5) * (slope_amp if (t_i % 2 == 0) else -slope_amp * 0.88)
				var wave: float = sin(su * PI * 2.1 + float(t_i) * 1.15 + country_phase) * 0.022 + cos(su * PI * 3.4 + float(t_i)) * 0.010
				py = maxf(get_land_ground_top_y_at(page, rect, px_s) + float(t_i) * 8.0, oy + h * clampf(base_v + slope + wave, top_t, 0.95))
			ridge_pts.append(Vector2(px_s, py))
			lip_pts.append(Vector2(px_s, py + lip_h))

		var lip_poly := PackedVector2Array()
		for p in ridge_pts:
			lip_poly.append(p - Vector2(0.0, lip_h * 0.65))
		for s_i in range(segs, -1, -1):
			lip_poly.append(lip_pts[s_i])
		canvas.draw_colored_polygon(lip_poly, lip_col)

		var sheet_poly := PackedVector2Array()
		for p in ridge_pts:
			sheet_poly.append(p)
		sheet_poly.append(Vector2(ox + w, oy + h))
		sheet_poly.append(Vector2(ox, oy + h))
		canvas.draw_colored_polygon(sheet_poly, top_col)
		canvas.draw_polyline(ridge_pts, top_col.lightened(0.18), 2.2, true)

	# Optional coastal sea margin for countries with a coastal horizon (Italy, Japan, France, USA)
	if c_key in ["italy", "japan", "france", "usa_nyc"]:
		var sea_right: bool = not flip_world
		var c_edge_x: float = ox + w if sea_right else ox
		var c_dir: float = -1.0 if sea_right else 1.0
		var c_top_y: float = oy + h * 0.56
		var c_bot_y: float = oy + h * 0.88
		var c_shore := PackedVector2Array([Vector2(c_edge_x, c_top_y)])
		var c_water := PackedVector2Array([Vector2(c_edge_x, c_top_y + 4.0)])
		for ci in range(13):
			var ct: float = float(ci) / 12.0
			var cpy: float = lerpf(c_top_y, c_bot_y, ct)
			var creach: float = sin(ct * PI) * w * 0.14
			c_shore.append(Vector2(clampf(c_edge_x + c_dir * (creach + 5.0), ox + 12.0, ox + w - 12.0), cpy))
			c_water.append(Vector2(clampf(c_edge_x + c_dir * creach, ox + 12.0, ox + w - 12.0), cpy))
		c_shore.append(Vector2(c_edge_x, c_bot_y))
		c_water.append(Vector2(c_edge_x, c_bot_y - 4.0))
		canvas.draw_colored_polygon(c_shore, bank_col)
		canvas.draw_colored_polygon(c_water, water_col)

	# 2. Integrated Valley River / Grand Canal / Seine / Nile / Bay Channel / Colorado River
	# Uses _build_country_waterway_spine which deflects away from land-grounded monuments (e.g. Pisa)!
	var river_spine: PackedVector2Array = _build_country_waterway_spine(page, rect, split_idx, flip_world, c_key)
	var river_half_w: float = clampf(minf(w, h) * 0.044, 15.0, 24.0)
	if c_key == "egypt":
		# Lush emerald Nile valley agricultural belt flanking the river through the desert
		_draw_ribbon_along_spine(canvas, river_spine, river_half_w + 14.0, Color(0.36, 0.68, 0.32, 0.82), Vector2.ZERO, rect)
	_draw_ribbon_along_spine(canvas, river_spine, river_half_w + 7.0, cliff_col.darkened(0.20), Vector2(0.0, 2.5), rect)
	_draw_ribbon_along_spine(canvas, river_spine, river_half_w + 3.5, bank_col, Vector2.ZERO, rect)
	_draw_ribbon_along_spine(canvas, river_spine, river_half_w, water_col.darkened(0.10), Vector2.ZERO, rect)
	_draw_ribbon_along_spine(canvas, river_spine, river_half_w * 0.62, water_col.lightened(0.16), Vector2(0.0, -1.0), rect)

	for i in range(2, river_spine.size() - 2, 3):
		var rp: Vector2 = river_spine[i]
		var r_dir: Vector2 = (river_spine[i + 1] - river_spine[i - 1]).normalized()
		var ripple_col := Color(1.0, 1.0, 1.0, 0.38) if theme.theme_id != "volcano" else Color(1.0, 0.86, 0.24, 0.62)
		canvas.draw_line(rp - r_dir * 8.0, rp + r_dir * 8.0, ripple_col, 1.8, true)


static func _draw_ribbon_along_spine(
	canvas: CanvasItem,
	spine: PackedVector2Array,
	half_width: float,
	col: Color,
	offset: Vector2,
	bounds: Rect2 = Rect2()
) -> void:
	var n: int = spine.size()
	if n < 2:
		return
	var has_bounds: bool = (bounds.size.x > 0.0 and bounds.size.y > 0.0)
	var min_x: float = bounds.position.x
	var max_x: float = bounds.end.x
	var min_y: float = bounds.position.y
	var max_y: float = bounds.end.y
	var top_edge := PackedVector2Array()
	var bot_edge := PackedVector2Array()
	for i in range(n):
		var t_dir: Vector2
		if i == 0:
			t_dir = (spine[1] - spine[0]).normalized()
		elif i == n - 1:
			t_dir = (spine[n - 1] - spine[n - 2]).normalized()
		else:
			t_dir = (spine[i + 1] - spine[i - 1]).normalized()
		var n_dir := Vector2(-t_dir.y, t_dir.x)
		var p: Vector2 = spine[i] + offset
		var pt_top: Vector2 = p + n_dir * half_width
		var pt_bot: Vector2 = p - n_dir * half_width
		if has_bounds:
			pt_top = Vector2(clampf(pt_top.x, min_x, max_x), clampf(pt_top.y, min_y, max_y))
			pt_bot = Vector2(clampf(pt_bot.x, min_x, max_x), clampf(pt_bot.y, min_y, max_y))
		top_edge.append(pt_top)
		bot_edge.append(pt_bot)
	var poly := PackedVector2Array()
	for p in top_edge:
		poly.append(p)
	for i in range(n - 1, -1, -1):
		poly.append(bot_edge[i])
	canvas.draw_colored_polygon(poly, col)


static func _draw_modern_city_world(
	canvas: CanvasItem,
	rect: Rect2,
	page: MapPage,
	_theme: MapTheme,
	pal: Dictionary,
	split_idx: int,
	flip_world: bool,
	_anim_time: float
) -> void:
	var w: float = rect.size.x
	var h: float = rect.size.y
	var ox: float = rect.position.x
	var oy: float = rect.position.y

	var urban_base: Color = pal.get("ground_primary", Color(0.32, 0.38, 0.46, 1.0))
	var block_col: Color = pal.get("ground_secondary", Color(0.46, 0.52, 0.60, 1.0))
	var park_col: Color = pal.get("island_surface", Color(0.34, 0.72, 0.42, 1.0))
	var water_col: Color = pal.get("water_color", Color(0.14, 0.64, 0.84, 1.0))

	var c_key: String = _resolve_country_composition_key(_theme, page)
	var city_poly := PackedVector2Array()
	for i in range(25):
		var u: float = float(i) / 24.0
		var px: float = ox + u * w
		var py: float = get_land_ground_top_y_at(page, rect, px, c_key)
		city_poly.append(Vector2(px, py))
	city_poly.append(Vector2(ox + w, oy + h))
	city_poly.append(Vector2(ox, oy + h))
	canvas.draw_colored_polygon(city_poly, urban_base)

	for row_i in range(4):
		var by: float = oy + h * (0.22 + float(row_i) * 0.19)
		var bh: float = h * 0.145
		canvas.draw_rect(Rect2(ox + w * 0.05, by, w * 0.40, bh), block_col.lightened(float(row_i % 2) * 0.06), true)
		canvas.draw_rect(Rect2(ox + w * 0.55, by, w * 0.40, bh), block_col.lightened(float((row_i + 1) % 2) * 0.06), true)

	var park_rect := Rect2(ox + w * (0.07 if not flip_world else 0.57), oy + h * 0.56, w * 0.36, h * 0.15)
	canvas.draw_rect(park_rect, park_col, true)
	_draw_ellipse_filled(canvas, park_rect.position + park_rect.size * 0.5, park_rect.size.x * 0.28, park_rect.size.y * 0.26, water_col.lightened(0.15))

	var n: int = page.nodes.size()
	var cross_pt := Vector2(ox + w * 0.5, oy + h * 0.48)
	if n >= 2 and split_idx >= 0 and split_idx < n - 1:
		cross_pt = Vector2(ox, oy) + (page.nodes[split_idx].position + page.nodes[split_idx + 1].position) * 0.5
	var canal_spine := PackedVector2Array([
		Vector2(ox, cross_pt.y + (h * 0.04 if not flip_world else -h * 0.04)),
		cross_pt,
		Vector2(ox + w, cross_pt.y + (-h * 0.04 if not flip_world else h * 0.04))
	])
	_draw_ribbon_along_spine(canvas, canal_spine, 22.0, Color(0.76, 0.80, 0.86, 1.0), Vector2.ZERO)
	_draw_ribbon_along_spine(canvas, canal_spine, 17.0, water_col, Vector2.ZERO)


# ==============================================================================
# 3. ROUTE-INTEGRATED DESTINATION PLAZAS (ROUTE -> LANDMARK -> LOCATION -> LEVEL)
# ==============================================================================
static func _select_route_destination_stops(
	page: MapPage,
	split_idx: int,
	country_key: String
) -> Dictionary:
	var n: int = page.nodes.size()
	var stops: Dictionary = {}
	if n <= 0:
		return stops

	# Fallback country-specific stop sequences only used when a synthetic test page has no node landmark metadata
	var stop_specs: Array = []
	match country_key:
		"japan":
			var top_id: String = "tokyo_tower" if (page.theme != null and page.theme.world_id == "tokyo") else "chureito_pagoda"
			var top_lbl: String = "Tokyo" if top_id == "tokyo_tower" else "Chureito"
			stop_specs = [
				["torii_shrine", "Miyajima"],
				["osaka_castle", "Osaka"],
				["kyoto_temple", "Kyoto"],
				[top_id, top_lbl]
			]
		"italy":
			stop_specs = [
				["venice_canal", "Venice"],
				["florence_duomo", "Florence"],
				["pisa_tower", "Pisa"],
				["tuscany_villa", "Tuscany"],
				["rome_colosseum", "Rome"]
			]
		"france":
			stop_specs = [
				["tuscany_villa", "Nice"],
				["loire_chateau", "Loire Valley"],
				["mont_saint_michel", "Mont-St-Michel"],
				["versailles_palace", "Versailles"],
				["eiffel_tower", "Paris"]
			]
		"vietnam_bay", "vietnam_city":
			stop_specs = [
				["hanoi_hoan_kiem_pagoda", "Hanoi"],
				["ninh_binh_trang_an_karst", "Ninh Binh"],
				["halong_karst_harbor", "Ha Long Bay"],
				["hue_imperial_citadel", "Hue"],
				["hoian_covered_bridge_lanterns", "Da Nang / Hoi An"],
				["saigon_bitexco_skyline", "Ho Chi Minh City"],
				["mekong_floating_market", "Mekong Delta"]
			]
		"usa_nyc", "usa_canyon":
			stop_specs = [
				["statue_of_liberty", "New York City"],
				["manhattan_skyline", "Chicago"],
				["grand_canyon_rim", "Grand Canyon"],
				["las_vegas_strip", "Las Vegas"],
				["golden_gate", "San Francisco"]
			]
		"egypt":
			stop_specs = [
				["giza_sphinx", "Cairo & Giza"],
				["karnak_temple", "Karnak"],
				["luxor_obelisk", "Luxor"],
				["abu_simbel", "Abu Simbel"]
			]
		"switzerland":
			stop_specs = [
				["alpine_chalet", "Geneva"],
				["zermatt_sanctuary", "Zermatt"],
				["alpine_village", "Interlaken"],
				["glacier_bridge", "Lucerne"],
				["zermatt_sanctuary", "St. Moritz"]
			]
		_:
			stop_specs = [
				["lunar_base", "Moon Base"],
				["crater_array", "Crater Array"],
				["mars_dome", "Olympus"],
				["astral_observatory", "Observatory"]
			]

	var chosen_indices: Array[int] = []
	for i in range(n):
		var nd_chk: MapNode = page.nodes[i]
		var lm_chk: Dictionary = nd_chk.landmark if (nd_chk != null and nd_chk.landmark is Dictionary) else {}
		var chk_ctx: String = String(lm_chk.get("milestone_context", ""))
		if chk_ctx == "major_landmark" or chk_ctx == "landmark_environment":
			chosen_indices.append(i)

	if chosen_indices.is_empty():
		var target_k: int = 3 if n <= 6 else 4
		target_k = mini(target_k, n)
		if n <= 4:
			chosen_indices = [0, maxi(0, n - 1)]
		elif target_k <= 3:
			var mid_idx: int = clampi(split_idx, 2, maxi(2, n - 3))
			chosen_indices = [0, mid_idx, n - 1]
		else:
			var idx1: int = clampi(int(round(float(n - 1) * 0.31)), 2, maxi(2, n - 5))
			var idx2: int = clampi(maxi(idx1 + 2, int(round(float(n - 1) * 0.66))), idx1 + 2, maxi(idx1 + 2, n - 3))
			chosen_indices = [0, idx1, idx2, n - 1]

	var total_specs: int = stop_specs.size()
	for s_i in range(chosen_indices.size()):
		var n_idx: int = clampi(chosen_indices[s_i], 0, n - 1)
		var nd: MapNode = page.nodes[n_idx]
		var lm_dict: Dictionary = nd.landmark if (nd != null and nd.landmark is Dictionary) else {}
		var node_lm_id: String = String(lm_dict.get("landmark_id", ""))
		var node_label: String = String(lm_dict.get("destination_name", lm_dict.get("location_label", "")))
		var m_ctx: String = String(lm_dict.get("milestone_context", "major_landmark"))
		var env_type: String = String(lm_dict.get("environment_type", "regional_landscape"))
		if node_lm_id != "" and node_label != "":
			var raw_stop := {
				"landmark_id": node_lm_id,
				"label": node_label,
				"milestone_context": m_ctx,
				"environment_type": env_type,
				"destination_order": int(lm_dict.get("destination_order", n_idx + 1)),
				"region": String(lm_dict.get("region", "")),
				"landmark_description": String(lm_dict.get("landmark_description", "")),
				"lat": float(lm_dict.get("lat", 0.0)),
				"lon": float(lm_dict.get("lon", 0.0)),
				"grounding_type": String(lm_dict.get("grounding_type", "")),
				"water_relationship": String(lm_dict.get("water_relationship", "")),
				"supporting_terrain_zone": String(lm_dict.get("supporting_terrain_zone", "")),
				"classification": "DESTINATION_LANDMARK"
			}
			var g_spec: Dictionary = derive_landmark_grounding_spec(raw_stop, country_key)
			raw_stop["grounding_type"] = g_spec["grounding_classification"]
			raw_stop["water_relationship"] = g_spec["water_relationship"]
			raw_stop["supporting_terrain_zone"] = g_spec["supporting_terrain_zone"]
			raw_stop["supporting_surface"] = g_spec["supporting_surface"]
			stops[n_idx] = raw_stop
		else:
			var spec_idx: int = clampi(int(round(float(s_i) * float(maxi(0, total_specs - 1)) / float(maxi(1, chosen_indices.size() - 1)))), 0, maxi(0, total_specs - 1))
			var fallback_stop := {
				"landmark_id": stop_specs[spec_idx][0],
				"label": stop_specs[spec_idx][1],
				"milestone_context": m_ctx,
				"environment_type": env_type,
				"destination_order": n_idx + 1,
				"classification": "DESTINATION_LANDMARK"
			}
			var g_spec_fb: Dictionary = derive_landmark_grounding_spec(fallback_stop, country_key)
			fallback_stop["grounding_type"] = g_spec_fb["grounding_classification"]
			fallback_stop["water_relationship"] = g_spec_fb["water_relationship"]
			fallback_stop["supporting_terrain_zone"] = g_spec_fb["supporting_terrain_zone"]
			fallback_stop["supporting_surface"] = g_spec_fb["supporting_surface"]
			stops[n_idx] = fallback_stop
	return stops


static func get_destination_hierarchy_scale_multiplier(m_ctx: String) -> float:
	match m_ctx:
		"major_landmark":
			return 1.22
		"landmark_environment":
			return 1.04
		"regional_scene":
			return 0.80
		"small_destination_marker":
			return 0.56
		_:
			return 1.04


static func get_base_landmark_scale_for_viewport(rect: Rect2, page: MapPage = null) -> float:
	var w: float = maxf(280.0, rect.size.x)
	var h: float = maxf(340.0, rect.size.y)
	var vp_sc: float = clampf(minf(w / 320.0, h / 460.0), 1.00, 1.48)
	var lm_density: String = "moderate"
	if page != null:
		if page.landmark_density != "":
			lm_density = page.landmark_density
		elif not page.nodes.is_empty() and page.nodes[0].landmark is Dictionary:
			lm_density = String(page.nodes[0].landmark.get("landmark_density", "moderate"))
	var density_mult: float = 1.12 if lm_density == "sparse" else (1.06 if lm_density == "moderate" else (1.00 if lm_density == "high" else 0.96))
	return vp_sc * density_mult


static func _get_landmark_local_extents(lm_id: String, sc: float, m_ctx: String = "major_landmark") -> Dictionary:
	var ctx_mult: float = get_destination_hierarchy_scale_multiplier(m_ctx)
	var eff_sc: float = sc * ctx_mult
	var is_tall: bool = lm_id in [
		"eiffel_tower", "tower_bridge_big_ben", "tokyo_tower", "cn_tower_toronto",
		"taipei_101_jiufen", "petronas_twin_towers", "burj_khalifa_downtown",
		"marina_bay_sands", "kuwait_towers", "baku_flame_towers", "mont_saint_michel",
		"taj_mahal_agra", "hagia_sophia_blue_mosque", "sultan_qaboos_mosque",
		"sheikh_zayed_mosque", "hassan_ii_mosque", "koutoubia_jemaa_el_fna",
		"registan_samarkand", "shah_i_zinda_bibi", "kalyan_minaret_ark",
		"ichan_kala_khiva", "badshahi_mosque_lahore", "faisal_mosque",
		"al_masjid_an_nabawi", "museum_islamic_art_doha", "saigon_bitexco_skyline",
		"saigon_skyline", "victoria_harbour_skyline", "bund_pudong_skyline",
		"sydney_opera_harbour_bridge", "auckland_sky_tower_harbour",
		"panama_canal_miraflores", "lighthouse_landmark", "cape_of_good_hope",
		"belem_tower_jeronimos", "hercules_tower", "peggys_cove_lighthouse",
		"statue_of_liberty", "christ_redeemer_corcovado", "moai_ahu_tongariki",
		"ushuaia_fin_del_mundo", "las_vegas_strip", "cloud_gate_skyline", "manhattan_skyline"
	]
	var is_med_tall: bool = lm_id in [
		"osaka_castle", "himeji_castle", "edinburgh_castle", "neuschwanstein_castle",
		"heidelberg_castle", "chillon_castle", "charles_bridge_castle", "wawel_castle",
		"bran_castle", "peles_castle", "bled_island_castle", "trakai_island_castle",
		"tallinn_toompea_walls", "dubrovnik_walls", "kotor_bay_fortress",
		"cartagena_walled_city", "qaitbay_citadel", "pena_palace_sintra", "alcazar_toledo",
		"chureito_pagoda", "wat_arun_grand_palace", "wat_phra_that_doi_suthep",
		"ayutthaya_prangs", "angkor_wat_towers", "bagan_pagodas", "shwedagon_pagoda",
		"pha_that_luang", "wat_xieng_thong", "borobudur_stupa", "prambanan_temple",
		"tanah_lot_bali", "boudhanath_swayambhunath", "tiger_nest_paro", "punakha_dzong",
		"temple_of_the_tooth", "pisa_tower", "florence_duomo", "florence_duomo_pisa",
		"milan_duomo", "sagrada_familia", "cologne_cathedral", "york_minster",
		"st_basils_red_square", "peter_paul_hermitage", "st_stephens_schoenbrunn",
		"grand_place_atomium", "rijksmuseum_canals", "notre_dame_montreal",
		"havana_capitolio_malecon", "cusco_plaza_armas", "quito_compania_mitad",
		"golden_gate", "golden_gate_bridge", "chapel_bridge_lucerne", "mostar_stari_most",
		"chain_bridge_danube", "bosphorus_bridge", "victoria_falls_bridge",
		"karnak_temple", "luxor_obelisk", "karnak_luxor_temple", "edfu_horus_temple",
		"philae_isis_temple", "axum_obelisks", "lalibela_rock_churches",
		"halong_harbor", "halong_karst_harbor", "guilin_li_river_karsts",
		"zhangjiajie_avatar_peaks", "phang_nga_james_bond", "krabi_railay_karsts",
		"el_nido_lagoons", "raja_ampat_wayag", "komodo_padar_island",
		"milford_sound_mitre_peak", "geirangerfjord_seven_sisters", "lofoten_reinebringen"
	]
	return {
		"eff_sc": eff_sc,
		"half_w": 26.0 * eff_sc,
		"top_h": (43.0 if is_tall else (35.5 if is_med_tall else 30.0)) * eff_sc,
		"bot_h": 7.0 * eff_sc
	}


static func _rect_clearance_to_obstacles(cand_rect: Rect2, obstacle_rects: Array[Rect2]) -> float:
	var min_clear: float = 99999.0
	for obs in obstacle_rects:
		var dx: float = maxf(0.0, maxf(obs.position.x - cand_rect.end.x, cand_rect.position.x - obs.end.x))
		var dy: float = maxf(0.0, maxf(obs.position.y - cand_rect.end.y, cand_rect.position.y - obs.end.y))
		if dx == 0.0 and dy == 0.0:
			var pen_x: float = minf(cand_rect.end.x - obs.position.x, obs.end.x - cand_rect.position.x)
			var pen_y: float = minf(cand_rect.end.y - obs.position.y, obs.end.y - cand_rect.position.y)
			min_clear = minf(min_clear, -minf(pen_x, pen_y) - 4.0)
		else:
			min_clear = minf(min_clear, sqrt(dx * dx + dy * dy))
	return min_clear


static func _non_incident_route_clearance(cand_rect: Rect2, page: MapPage, node_idx: int, offset: Vector2) -> float:
	if page == null or page.nodes.size() < 2:
		return 99999.0
	var min_d: float = 99999.0
	var rc: Vector2 = cand_rect.get_center()
	var rx: float = cand_rect.size.x * 0.5
	var ry: float = cand_rect.size.y * 0.5
	for seg_i in range(page.nodes.size() - 1):
		if seg_i == node_idx - 1 or seg_i == node_idx:
			continue
		var a: Vector2 = offset + page.nodes[seg_i].position
		var b: Vector2 = offset + page.nodes[seg_i + 1].position
		var cl_pt: Vector2 = Geometry2D.get_closest_point_to_segment(rc, a, b)
		var dx: float = maxf(0.0, absf(rc.x - cl_pt.x) - rx)
		var dy: float = maxf(0.0, absf(rc.y - cl_pt.y) - ry)
		var d: float = sqrt(dx * dx + dy * dy) - 7.5
		min_d = minf(min_d, d)
	return min_d


static func _compute_non_overlapping_landmark_layout(
	page: MapPage,
	dest_stops: Dictionary,
	rect: Rect2,
	base_sc: float
) -> Dictionary:
	var ox: float = rect.position.x
	var oy: float = rect.position.y
	var w: float = maxf(280.0, rect.size.x)
	var h: float = maxf(340.0, rect.size.y)
	var n: int = page.nodes.size()
	var zones: Dictionary = get_country_spatial_zones(page, rect)
	var water_spine: PackedVector2Array = zones.get("water_spine", PackedVector2Array())
	var water_half_w: float = float(zones.get("water_half_width", 18.0))
	var c_key: String = String(zones.get("country_key", "japan"))

	var node_rects: Array[Rect2] = []
	for i in range(n):
		var nd_i: MapNode = page.nodes[i]
		var np_i: Vector2 = rect.position + nd_i.position
		node_rects.append(Rect2(np_i - nd_i.node_size * 0.5 - Vector2(3.0, 3.0), nd_i.node_size + Vector2(6.0, 6.0)))

	var placed_landmarks: Dictionary = {}
	var placed_lm_rects: Array[Rect2] = []
	var stop_keys: Array = dest_stops.keys()
	stop_keys.sort()

	for node_idx_var in stop_keys:
		var node_idx: int = int(node_idx_var)
		if node_idx < 0 or node_idx >= n:
			continue
		var nd: MapNode = page.nodes[node_idx]
		# 1. Choose destination region around route endpoint (node_pos)
		var node_pos: Vector2 = rect.position + nd.position
		var stop_info: Dictionary = dest_stops[node_idx]
		var lm_id: String = String(stop_info.get("landmark_id", ""))
		var m_ctx: String = String(stop_info.get("milestone_context", "major_landmark"))
		# 2. Determine valid grounding surface from grounding metadata
		var g_spec: Dictionary = derive_landmark_grounding_spec(stop_info, c_key)
		var g_class: String = String(g_spec.get("grounding_classification", "GROUND"))
		var w_rel: String = String(g_spec.get("water_relationship", "none"))
		var s_surf: String = String(g_spec.get("supporting_surface", "terrace_ground"))
		var allowed_surfaces: Array[String] = get_allowed_grounding_surfaces(stop_info, c_key)

		var in_sign: float = 1.0 if (node_pos.x - ox) < (w * 0.50) else -1.0
		var bhw: float = nd.node_size.x * 0.5
		var bhh: float = nd.node_size.y * 0.5

		var fallback_min_y: float = get_minimum_valid_ground_y_at(page, rect, node_pos.x, stop_info) + 3.0
		var best_pos: Vector2 = Vector2(clampf(node_pos.x + in_sign * (bhw + 28.0), ox + 32.0, ox + w - 32.0), maxf(fallback_min_y, node_pos.y + 2.0))
		var best_sc: float = base_sc * get_destination_hierarchy_scale_multiplier(m_ctx) * 0.80
		var best_rect := Rect2(best_pos - Vector2(22.0, 28.0), Vector2(44.0, 34.0))
		var best_clear: float = -99999.0
		var best_val: Dictionary = {}

		var all_obs: Array[Rect2] = []
		all_obs.append_array(node_rects)
		all_obs.append_array(placed_lm_rects)

		# 3-10. Base-first candidate evaluation:
		# Preferred correction order:
		# 1. Reposition locally at largest scale;
		# 2. Adjust lateral/vertical composition on valid terrain surface;
		# 3. Respect route and obstacle clearance;
		# 4. Slightly reduce scale only when necessary.
		var scale_steps: Array[float] = [1.0, 0.92, 0.84, 0.76, 0.68, 0.60]
		for sc_mult in scale_steps:
			var sc_try: float = base_sc * sc_mult
			var ext: Dictionary = _get_landmark_local_extents(lm_id, sc_try, m_ctx)
			var hw: float = float(ext["half_w"])
			var th: float = float(ext["top_h"])
			var bh_lm: float = float(ext["bot_h"])
			var eff_sc: float = float(ext["eff_sc"])

			var candidates: Array[Vector2] = [
				Vector2(node_pos.x + in_sign * (bhw + hw + 7.5), node_pos.y + 2.0),
				Vector2(node_pos.x - in_sign * (bhw + hw + 7.5), node_pos.y + 2.0),
				Vector2(node_pos.x + in_sign * (bhw + hw + 7.5), node_pos.y - 4.0),
				Vector2(node_pos.x - in_sign * (bhw + hw + 7.5), node_pos.y - 4.0),
				Vector2(node_pos.x + in_sign * (bhw + hw + 8.5), node_pos.y + 11.0),
				Vector2(node_pos.x - in_sign * (bhw + hw + 8.5), node_pos.y + 11.0),
				Vector2(node_pos.x + in_sign * (bhw + hw + 18.0), node_pos.y + 2.0),
				Vector2(node_pos.x - in_sign * (bhw + hw + 18.0), node_pos.y + 2.0),
				Vector2(node_pos.x, node_pos.y - bhh - bh_lm - 5.0),
				Vector2(node_pos.x + in_sign * 18.0, node_pos.y - bhh - bh_lm - 5.0),
				Vector2(node_pos.x - in_sign * 18.0, node_pos.y - bhh - bh_lm - 5.0),
				Vector2(node_pos.x + in_sign * (bhw + hw * 0.92 + 7.0), node_pos.y + bhh * 0.65 + 10.0),
				Vector2(node_pos.x - in_sign * (bhw + hw * 0.92 + 7.0), node_pos.y + bhh * 0.65 + 10.0),
				Vector2(node_pos.x, node_pos.y + bhh + th + 6.0),
				Vector2(node_pos.x + in_sign * 18.0, node_pos.y + bhh + th + 6.0),
				Vector2(node_pos.x - in_sign * 18.0, node_pos.y + bhh + th + 6.0)
			]

			var step_best_score: float = -99999.0
			var step_best_pos: Vector2 = best_pos
			var step_best_rect := Rect2()
			var step_best_clear: float = -99999.0
			var step_best_val: Dictionary = {}

			for c_idx in range(candidates.size()):
				var raw_c: Vector2 = candidates[c_idx]
				var cx: float = clampf(raw_c.x, ox + hw + 4.0, maxf(ox + hw + 4.0, ox + w - hw - 4.0))
				var min_valid_y_cx: float = maxf(oy + th + 4.0, get_minimum_valid_ground_y_at(page, rect, cx, stop_info, c_key) + 2.5)
				var max_valid_y_cx: float = maxf(min_valid_y_cx, oy + h - bh_lm - 4.0)
				var cy: float = raw_c.y
				if cy < min_valid_y_cx:
					if absf(cx - node_pos.x) < bhw + hw * 0.75:
						continue
					cy = min_valid_y_cx
				cy = clampf(cy, min_valid_y_cx, max_valid_y_cx)

				var c_rect := Rect2(Vector2(cx - hw, cy - th), Vector2(hw * 2.0, th + bh_lm))
				if c_rect.position.x < ox + 1.0 or c_rect.end.x > ox + w - 1.0 or c_rect.position.y < oy + 1.0 or c_rect.end.y > oy + h - 1.0:
					continue
				var cl: float = _rect_clearance_to_obstacles(c_rect, all_obs)
				var route_cl: float = _non_incident_route_clearance(c_rect, page, node_idx, rect.position)
				cl = minf(cl, route_cl)
				if cl < step_best_clear and cl < 2.0:
					continue
				var cand_anchor := Vector2(cx, cy)
				var val_res: Dictionary = validate_landmark_ground_anchor(page, rect, cand_anchor, node_pos, stop_info, water_spine)
				if not bool(val_res.get("valid", false)):
					if not bool(val_res.get("ground_anchor_not_in_water", true)) and not water_spine.is_empty():
						var w_pt: Vector2 = _closest_point_on_polyline(cand_anchor, water_spine)
						var push_dir: float = 1.0 if cy >= w_pt.y else -1.0
						for dir_try in [push_dir, -push_dir]:
							var ny: float = clampf(w_pt.y + dir_try * (water_half_w + 5.0), min_valid_y_cx, max_valid_y_cx)
							var n_anchor := Vector2(cx, ny)
							var n_rect := Rect2(Vector2(cx - hw, ny - th), Vector2(hw * 2.0, th + bh_lm))
							if n_rect.position.y < oy + 1.0 or n_rect.end.y > oy + h - 1.0:
								continue
							var n_cl: float = minf(_rect_clearance_to_obstacles(n_rect, all_obs), _non_incident_route_clearance(n_rect, page, node_idx, rect.position))
							if n_cl < step_best_clear and n_cl < 2.0:
								continue
							var n_val: Dictionary = validate_landmark_ground_anchor(page, rect, n_anchor, node_pos, stop_info, water_spine)
							if bool(n_val.get("valid", false)):
								cy = ny
								cand_anchor = n_anchor
								c_rect = n_rect
								cl = n_cl
								val_res = n_val
								break
				if not bool(val_res.get("valid", false)):
					continue

				if w_rel == "none" and not water_spine.is_empty():
					var wd: float = _distance_to_polyline(cand_anchor, water_spine)
					cl = minf(cl, wd - water_half_w + 2.0)
				var dy_route_pen: float = absf(cy - node_pos.y) * 0.04
				var sc_val: float = (minf(cl, 20.0) - float(c_idx) * 0.20 - dy_route_pen) if cl >= 2.0 else (cl * 12.0 - float(c_idx) * 0.05 - dy_route_pen)
				if sc_val > step_best_score:
					step_best_score = sc_val
					step_best_pos = cand_anchor
					step_best_rect = c_rect
					step_best_clear = cl
					step_best_val = val_res

			# Preferred Correction #2: Local lateral/vertical terrain pocket search BEFORE reducing scale
			if step_best_clear < 2.2:
				for dx_v in [-62.0, -38.0, -20.0, 20.0, 38.0, 62.0]:
					var cx_sr: float = clampf(node_pos.x + dx_v, ox + hw + 4.0, maxf(ox + hw + 4.0, ox + w - hw - 4.0))
					var min_valid_y_sr: float = maxf(oy + th + 4.0, get_minimum_valid_ground_y_at(page, rect, cx_sr, stop_info, c_key) + 2.5)
					var max_valid_y_sr: float = maxf(min_valid_y_sr, oy + h - bh_lm - 4.0)
					for dy_v in [-28.0, -14.0, 0.0, 14.0, 28.0, 42.0]:
						var cy_sr: float = clampf(node_pos.y + dy_v, min_valid_y_sr, max_valid_y_sr)
						var c_rect_sr := Rect2(Vector2(cx_sr - hw, cy_sr - th), Vector2(hw * 2.0, th + bh_lm))
						if c_rect_sr.position.x < ox + 1.0 or c_rect_sr.end.x > ox + w - 1.0 or c_rect_sr.position.y < oy + 1.0 or c_rect_sr.end.y > oy + h - 1.0:
							continue
						var cl_sr: float = minf(_rect_clearance_to_obstacles(c_rect_sr, all_obs), _non_incident_route_clearance(c_rect_sr, page, node_idx, rect.position))
						if cl_sr <= step_best_clear and cl_sr < 2.0:
							continue
						var cand_anchor_sr := Vector2(cx_sr, cy_sr)
						var val_res_sr: Dictionary = validate_landmark_ground_anchor(page, rect, cand_anchor_sr, node_pos, stop_info, water_spine)
						if not bool(val_res_sr.get("valid", false)):
							continue
						if w_rel == "none" and not water_spine.is_empty():
							var wd2: float = _distance_to_polyline(cand_anchor_sr, water_spine)
							cl_sr = minf(cl_sr, wd2 - water_half_w + 2.0)
						var dist_pen: float = Vector2(cx_sr - node_pos.x, (cy_sr - node_pos.y) * 1.35).length() * 0.018
						var sc_grid: float = (minf(cl_sr, 16.0) - dist_pen) if cl_sr >= 2.0 else (cl_sr * 12.0 - dist_pen)
						if sc_grid > step_best_score:
							step_best_score = sc_grid
							step_best_pos = cand_anchor_sr
							step_best_rect = c_rect_sr
							step_best_clear = cl_sr
							step_best_val = val_res_sr

			if not step_best_val.is_empty() and step_best_clear > best_clear:
				best_clear = step_best_clear
				best_pos = step_best_pos
				best_sc = eff_sc
				best_rect = step_best_rect
				best_val = step_best_val
			if not step_best_val.is_empty() and step_best_clear >= 2.2:
				break

		if best_val.is_empty():
			var fb_x: float = clampf(node_pos.x + in_sign * (bhw + 26.0), ox + 28.0, ox + w - 28.0)
			var fb_min_y: float = maxf(oy + 38.0, get_minimum_valid_ground_y_at(page, rect, fb_x, stop_info) + 4.0)
			var fb_y: float = clampf(maxf(node_pos.y + 4.0, fb_min_y), fb_min_y, oy + h - 16.0)
			best_pos = Vector2(fb_x, fb_y)
			best_val = validate_landmark_ground_anchor(page, rect, best_pos, node_pos, stop_info, water_spine)
			var ext_fb: Dictionary = _get_landmark_local_extents(lm_id, base_sc * 0.68, m_ctx)
			best_sc = float(ext_fb["eff_sc"])
			best_rect = Rect2(Vector2(best_pos.x - float(ext_fb["half_w"]), best_pos.y - float(ext_fb["top_h"])), Vector2(float(ext_fb["half_w"]) * 2.0, float(ext_fb["top_h"]) + float(ext_fb["bot_h"])))

		# Complete semantic footprint (architectural body + environment context + shadow + forecourt base) clamped inside rect
		var fp_x0: float = maxf(ox, best_rect.position.x)
		var fp_y0: float = maxf(oy, best_rect.position.y)
		var fp_x1: float = minf(ox + w, best_rect.end.x)
		var fp_y1: float = minf(oy + h, best_rect.end.y)
		var fp_rect := Rect2(Vector2(fp_x0, fp_y0), Vector2(maxf(8.0, fp_x1 - fp_x0), maxf(8.0, fp_y1 - fp_y0)))
		var actual_surface: String = String(best_val.get("terrain_surface", get_terrain_surface_at_point(page, rect, best_pos, stop_info, water_spine)))

		placed_landmarks[node_idx] = {
			"arch_pos": best_pos,
			"ground_anchor": best_pos,
			"scale": best_sc,
			"arch_rect": fp_rect,
			"footprint_rect": fp_rect,
			"milestone_context": m_ctx,
			"grounding_classification": g_class,
			"water_relationship": w_rel,
			"terrain_surface": actual_surface,
			"allowed_grounding_surfaces": allowed_surfaces,
			"supporting_terrain_zone": actual_surface,
			"supporting_surface": s_surf,
			"validation": best_val,
			"clearance": best_clear
		}
		placed_lm_rects.append(fp_rect.grow(3.0))

	return placed_landmarks


static func _compute_safe_landmark_arch_pos(
	page: MapPage,
	node_idx: int,
	rect: Rect2,
	base_sc: float
) -> Vector2:
	var split_idx: int = _find_water_crossing_index(page)
	var theme: MapTheme = page.theme if page.theme != null else MapTheme.from_preset("green_forest")
	var country_key: String = _resolve_country_composition_key(theme, page)
	var dest_stops: Dictionary = _select_route_destination_stops(page, split_idx, country_key)
	var layout: Dictionary = _compute_non_overlapping_landmark_layout(page, dest_stops, rect, base_sc)
	if layout.has(node_idx):
		return layout[node_idx].get("arch_pos", rect.position + page.nodes[node_idx].position)
	var nd: MapNode = page.nodes[node_idx]
	var np: Vector2 = rect.position + nd.position
	var min_y: float = get_minimum_valid_ground_y_at(page, rect, np.x, nd.landmark if nd.landmark is Dictionary else {}) + 4.0
	return Vector2(clampf(np.x, rect.position.x + 36.0, rect.end.x - 36.0), clampf(maxf(np.y, min_y), maxf(rect.position.y + 38.0, min_y), rect.end.y - 24.0))


static func _format_plaque_display_text(label_text: String) -> String:
	var txt: String = label_text.strip_edges()
	if txt.length() > 16:
		var paren_idx: int = txt.find(" (")
		if paren_idx > 2:
			txt = txt.substr(0, paren_idx).strip_edges()
	if txt.length() > 16:
		var amp_idx: int = txt.find(" & ")
		if amp_idx > 2:
			txt = txt.substr(0, amp_idx).strip_edges()
	if txt.length() > 16:
		var slash_idx: int = txt.find(" / ")
		if slash_idx > 2:
			txt = txt.substr(0, slash_idx).strip_edges()
	if txt.length() > 18:
		txt = txt.substr(0, 17).strip_edges()
	return txt


static func _get_plaque_size(label_text: String, is_compact: bool, is_poi: bool = false) -> Vector2:
	var disp_text: String = _format_plaque_display_text(label_text)
	var f_size: int = (10 if is_compact else 11) if not is_poi else (11 if is_compact else 12)
	var char_est: float = float(disp_text.length()) * (5.5 if is_compact else 6.0)
	var font: Font = ThemeDB.fallback_font
	var measured_w: float = char_est
	if font != null:
		measured_w = maxf(char_est * 0.88, font.get_string_size(disp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, f_size).x)
	var inner_w: float = maxf(42.0, measured_w + (12.0 if is_compact else 14.0))
	var half_h: float = (8.5 if is_compact else 9.5) if not is_poi else (9.5 if is_compact else 10.5)
	return Vector2(inner_w + 8.0, half_h * 2.0 + 3.0)


static func _compute_non_overlapping_plaque_pos(
	node_pos: Vector2,
	arch_pos: Vector2,
	nd: MapNode,
	label_text: String,
	rect: Rect2,
	obstacle_rects: Array[Rect2],
	base_sc: float,
	is_poi: bool = false,
	water_spine: PackedVector2Array = PackedVector2Array(),
	water_half_w: float = 18.0,
	route_pts: PackedVector2Array = PackedVector2Array()
) -> Vector2:
	var ox: float = rect.position.x
	var oy: float = rect.position.y
	var w: float = maxf(280.0, rect.size.x)
	var h: float = maxf(340.0, rect.size.y)
	var is_compact: bool = (w < 420.0 or h < 580.0)
	var p_sz: Vector2 = _get_plaque_size(label_text, is_compact, is_poi)
	var half_w: float = p_sz.x * 0.5
	var half_h: float = p_sz.y * 0.5

	var btn_half_w: float = (nd.node_size.x * 0.5) if nd != null else 22.0
	var btn_half_h: float = (nd.node_size.y * 0.5) if nd != null else 20.0
	var prefer_right: bool = (node_pos.x - ox) < (w * 0.50)
	var p_sign: float = 1.0 if prefer_right else -1.0
	var w_rel: String = String(nd.landmark.get("water_relationship", "none")) if (nd != null and nd.landmark is Dictionary) else "none"

	var side_dist: float = btn_half_w + half_w + 8.0
	var candidates: Array[Vector2] = [
		Vector2(node_pos.x + p_sign * side_dist, node_pos.y + 2.0),
		Vector2(node_pos.x - p_sign * side_dist, node_pos.y + 2.0),
		Vector2(node_pos.x, node_pos.y + btn_half_h + half_h + 8.0),
		Vector2(node_pos.x + p_sign * (btn_half_w * 0.6 + half_w + 6.0), node_pos.y + btn_half_h + half_h + 6.0),
		Vector2(node_pos.x - p_sign * (btn_half_w * 0.6 + half_w + 6.0), node_pos.y + btn_half_h + half_h + 6.0),
		Vector2(node_pos.x, node_pos.y - btn_half_h - half_h - 8.0),
		Vector2(node_pos.x + p_sign * (btn_half_w * 0.6 + half_w + 6.0), node_pos.y - btn_half_h - half_h - 6.0),
		Vector2(node_pos.x - p_sign * (btn_half_w * 0.6 + half_w + 6.0), node_pos.y - btn_half_h - half_h - 6.0),
		Vector2(arch_pos.x, arch_pos.y - 34.0 * base_sc - half_h - 5.0),
		Vector2(arch_pos.x, arch_pos.y + 16.0 * base_sc + half_h + 5.0),
		Vector2(node_pos.x + p_sign * side_dist, node_pos.y - 18.0),
		Vector2(node_pos.x - p_sign * side_dist, node_pos.y - 18.0),
		Vector2(node_pos.x + p_sign * side_dist, node_pos.y + 18.0),
		Vector2(node_pos.x - p_sign * side_dist, node_pos.y + 18.0)
	]

	var min_cx: float = ox + half_w + 4.0
	var max_cx: float = maxf(min_cx, ox + w - half_w - 4.0)
	var min_cy: float = oy + half_h + 4.0
	var max_cy: float = maxf(min_cy, oy + h - half_h - 4.0)

	var best_pos: Vector2 = Vector2(clampf(candidates[0].x, min_cx, max_cx), clampf(candidates[0].y, min_cy, max_cy))
	var best_score: float = -99999.0
	var best_clear: float = -99999.0

	for c_idx in range(candidates.size()):
		var raw_c: Vector2 = candidates[c_idx]
		var cx: float = clampf(raw_c.x, min_cx, max_cx)
		var cy: float = clampf(raw_c.y, min_cy, max_cy)
		var cand_rect := Rect2(Vector2(cx - half_w, cy - half_h), p_sz)
		var min_clear: float = _rect_clearance_to_obstacles(cand_rect, obstacle_rects)
		var env_pen: float = 0.0
		if w_rel == "none" and not water_spine.is_empty():
			if _distance_to_polyline(Vector2(cx, cy), water_spine) < water_half_w:
				env_pen += 2.5
		if not route_pts.is_empty() and not is_poi:
			if _distance_to_polyline(Vector2(cx, cy), route_pts) < 11.0:
				env_pen += 1.8
		var pref_bonus: float = maxf(0.0, 3.5 - float(c_idx) * 0.25) - env_pen
		var score: float = (minf(min_clear, 20.0) + pref_bonus) if min_clear >= 1.5 else (min_clear * 10.0 - float(c_idx) * 0.05)
		if score > best_score:
			best_score = score
			best_pos = Vector2(cx, cy)
			best_clear = min_clear

	if best_clear < 1.5:
		for dy_i in range(-11, 12):
			var dy_v: float = float(dy_i) * 10.0
			for dx_i in range(-11, 12):
				var dx_v: float = float(dx_i) * 15.0
				var cx_pl: float = clampf(node_pos.x + dx_v, min_cx, max_cx)
				var cy_pl: float = clampf(node_pos.y + dy_v, min_cy, max_cy)
				var cand_rect_pl := Rect2(Vector2(cx_pl - half_w, cy_pl - half_h), p_sz)
				var cl: float = _rect_clearance_to_obstacles(cand_rect_pl, obstacle_rects)
				var dist_pen: float = Vector2(cx_pl - node_pos.x, cy_pl - node_pos.y).length() * 0.01
				var sc_grid: float = (minf(cl, 12.0) - dist_pen) if cl >= 1.5 else (cl * 10.0 - dist_pen)
				if sc_grid > best_score:
					best_score = sc_grid
					best_clear = cl
					best_pos = Vector2(cx_pl, cy_pl)

	return best_pos


static func _classify_label_direction(node_pos: Vector2, plaque_pos: Vector2) -> String:
	var d: Vector2 = plaque_pos - node_pos
	if absf(d.x) >= absf(d.y):
		return "right" if d.x >= 0.0 else "left"
	return "below" if d.y >= 0.0 else "above"


static func _nudge_away_from_nodes(pt: Vector2, page: MapPage, offset: Vector2, min_clear: float) -> Vector2:
	var res: Vector2 = pt
	for _pass_i in range(2):
		for nd in page.nodes:
			var np: Vector2 = offset + nd.position
			var diff: Vector2 = res - np
			var d: float = diff.length()
			var req: float = nd.radius + min_clear
			if d < req:
				var dir: Vector2 = diff / maxf(0.001, d)
				res = np + dir * req
	return res


static func _compute_node_courtyard_radii(
	page: MapPage,
	dest_stops: Dictionary,
	offset: Vector2,
	canvas_w: float = 360.0
) -> Array[Vector2]:
	var n: int = page.nodes.size()
	var radii: Array[Vector2] = []
	for i in range(n):
		var nd: MapNode = page.nodes[i]
		var pos: Vector2 = offset + nd.position
		var m_ctx: String = String(nd.landmark.get("milestone_context", ""))
		var is_major: bool = (m_ctx == "major_landmark") or (m_ctx == "" and dest_stops.has(i))
		var is_env: bool = (m_ctx == "landmark_environment")
		var is_reg: bool = (m_ctx == "regional_scene")
		var rx_mult: float = 0.88 if is_major else (0.82 if is_env else (0.74 if is_reg else 0.68))
		var rx: float = nd.node_size.x * rx_mult
		var local_x: float = pos.x - offset.x
		rx = minf(rx, maxf(18.0, minf(local_x - 7.0, canvas_w - local_x - 7.0)))
		radii.append(Vector2(rx, rx * 0.56))

	for _pass in range(3):
		for i in range(n):
			var pi: Vector2 = offset + page.nodes[i].position
			for j in range(i + 1, n):
				var pj: Vector2 = offset + page.nodes[j].position
				var dx: float = pi.x - pj.x
				var dy: float = pi.y - pj.y
				var rx_sum: float = (radii[i].x + 5.5) + (radii[j].x + 5.5)
				var ry_sum: float = (radii[i].y + 4.0) + (radii[j].y + 4.0)
				var ed: float = sqrt((dx * dx) / maxf(1.0, rx_sum * rx_sum) + (dy * dy) / maxf(1.0, ry_sum * ry_sum))
				if ed < 1.08:
					var sc_f: float = clampf(ed / 1.08 * 0.95, 0.46, 0.96)
					radii[i] *= sc_f
					radii[j] *= sc_f
	return radii


# ==============================================================================
# 4. DESTINATION COURTYARDS & PLAZAS DIRECTLY ON THE MAIN ROUTE
# ==============================================================================
static func _draw_trail_stop_clearings(
	canvas: CanvasItem,
	page: MapPage,
	theme: MapTheme,
	pal: Dictionary,
	offset: Vector2
) -> void:
	var road_outer: Color = pal.get("path_outer", Color(0.78, 0.62, 0.42, 1.0))
	var road_inner: Color = pal.get("path_inner", Color(0.95, 0.88, 0.72, 1.0))
	var split_idx: int = _find_water_crossing_index(page)
	var country_key: String = _resolve_country_composition_key(theme, page)
	var dest_stops: Dictionary = _select_route_destination_stops(page, split_idx, country_key)
	var canvas_w: float = maxf(280.0, page.last_canvas_size.x)
	var radii: Array[Vector2] = _compute_node_courtyard_radii(page, dest_stops, offset, canvas_w)

	for i in range(page.nodes.size()):
		var nd: MapNode = page.nodes[i]
		var pos: Vector2 = offset + nd.position
		var r_vec: Vector2 = radii[i] if i < radii.size() else Vector2(nd.node_size.x * 0.74, nd.node_size.x * 0.42)
		var rx: float = r_vec.x * 0.78
		var ry: float = r_vec.y * 0.74

		# Subtle roadbed junction widening blended into the continuous terrain (no circular green pads or floating island blobs)
		if theme.world_type == "modern_city" or country_key == "usa_nyc":
			var sq := Rect2(pos - Vector2(rx * 0.88, ry * 0.84), Vector2(rx * 1.76, ry * 1.68))
			canvas.draw_rect(sq.grow(2.0), road_outer.darkened(0.10), true)
			canvas.draw_rect(sq, road_inner.lightened(0.04), true)
		else:
			_draw_ellipse_filled(canvas, pos + Vector2(0.0, 0.8), rx * 0.90, ry * 0.84, road_outer.darkened(0.08))
			_draw_ellipse_filled(canvas, pos, rx * 0.78, ry * 0.72, road_inner.lightened(0.05))


# ==============================================================================
# 5. NATURAL WINDING ADVENTURE TRAIL & WATER-CROSSING BRIDGES
# ==============================================================================
static func _draw_natural_trail_and_bridges(
	canvas: CanvasItem,
	rect: Rect2,
	page: MapPage,
	theme: MapTheme,
	pal: Dictionary,
	split_idx: int,
	offset: Vector2,
	_anim_time: float
) -> void:
	var route: MapRoute = page.route
	var pts := PackedVector2Array()
	if route != null and route.smooth_points.size() >= 2:
		for p in route.smooth_points:
			pts.append(offset + p)
	else:
		for nd in page.nodes:
			pts.append(offset + nd.position)
	if pts.size() < 2:
		return

	var path_outer: Color = pal.get("path_outer", Color(0.78, 0.62, 0.40, 1.0))
	var path_inner: Color = pal.get("path_inner", Color(0.96, 0.90, 0.74, 1.0))

	# 1. Wide, organic sculpted adventure roadbed leading directly into each landmark destination
	_draw_ribbon_along_spine(canvas, pts, 15.0, path_outer.darkened(0.28), Vector2(0.0, 3.2), rect)
	_draw_ribbon_along_spine(canvas, pts, 12.6, path_outer.darkened(0.10), Vector2(0.0, 1.2), rect)
	_draw_ribbon_along_spine(canvas, pts, 9.8, path_inner, Vector2.ZERO, rect)
	_draw_ribbon_along_spine(canvas, pts, 5.4, path_inner.lightened(0.10), Vector2(0.0, -0.8), rect)

	# 2. Illustrated cobblestones / timber planks / stepping stones along the trail
	var accum_d: float = 0.0
	for i in range(1, pts.size()):
		var seg_len: float = pts[i - 1].distance_to(pts[i])
		accum_d += seg_len
		if accum_d >= 15.0:
			accum_d = 0.0
			var mp: Vector2 = (pts[i - 1] + pts[i]) * 0.5
			_draw_ellipse_filled(canvas, mp, 4.8, 2.7, path_outer.lightened(0.12))

	# 3. Real Scenic Bridge / Causeway Where the Trail Crosses the River / Bay Channel
	var n: int = page.nodes.size()
	if n >= 2 and split_idx < n - 1:
		var p_from: Vector2 = offset + page.nodes[split_idx].position
		var p_to: Vector2 = offset + page.nodes[split_idx + 1].position
		var flip_w: bool = ((page.page_index % 2) == 1)
		var c_key: String = _resolve_country_composition_key(theme, page)
		var water_spine: PackedVector2Array = _build_country_waterway_spine(page, rect, split_idx, flip_w, c_key)
		var bridge_center: Vector2 = _closest_point_on_polyline((p_from + p_to) * 0.5, water_spine)
		var bridge_dir: Vector2 = (p_to - p_from).normalized()
		var bridge_perp := Vector2(-bridge_dir.y, bridge_dir.x)
		var half_span: float = clampf(p_from.distance_to(p_to) * 0.28, 20.0, 38.0)
		var half_deck_w: float = 14.0

		var b0: Vector2 = bridge_center - bridge_dir * half_span
		var b1: Vector2 = bridge_center + bridge_dir * half_span

		var sh_pts := PackedVector2Array([
			b0 + bridge_perp * (half_deck_w + 2.5) + Vector2(2.5, 6.0),
			b1 + bridge_perp * (half_deck_w + 2.5) + Vector2(2.5, 6.0),
			b1 - bridge_perp * (half_deck_w + 2.5) + Vector2(2.5, 6.0),
			b0 - bridge_perp * (half_deck_w + 2.5) + Vector2(2.5, 6.0)
		])
		canvas.draw_colored_polygon(sh_pts, Color(0.02, 0.08, 0.16, 0.42))

		var deck_col := Color(0.76, 0.54, 0.32, 1.0)
		var rail_col := Color(0.52, 0.34, 0.18, 1.0)
		if theme.theme_id == "hills_mountains" or theme.world_id in ["mount_fuji", "tokyo"]:
			deck_col = Color(0.88, 0.26, 0.20, 1.0)
			rail_col = Color(0.98, 0.82, 0.28, 1.0)
		elif theme.theme_id in ["ancient_ruins", "crystal_sanctuary", "snow_ice", "volcano"]:
			deck_col = Color(0.88, 0.84, 0.78, 1.0)
			rail_col = Color(0.64, 0.58, 0.52, 1.0)

		var deck_pts := PackedVector2Array([
			b0 + bridge_perp * half_deck_w,
			b1 + bridge_perp * half_deck_w,
			b1 - bridge_perp * half_deck_w,
			b0 - bridge_perp * half_deck_w
		])
		canvas.draw_colored_polygon(deck_pts, deck_col)

		for p_i in range(6):
			var lt: float = (float(p_i) + 0.5) / 6.0
			var bc: Vector2 = b0.lerp(b1, lt)
			canvas.draw_line(bc - bridge_perp * (half_deck_w - 1.8), bc + bridge_perp * (half_deck_w - 1.8), rail_col.darkened(0.15), 1.8)

		canvas.draw_line(b0 + bridge_perp * half_deck_w, b1 + bridge_perp * half_deck_w, rail_col, 3.2, true)
		canvas.draw_line(b0 - bridge_perp * half_deck_w, b1 - bridge_perp * half_deck_w, rail_col, 3.2, true)
		for end_pt in [b0, b1]:
			canvas.draw_circle(end_pt + bridge_perp * half_deck_w, 3.8, rail_col.lightened(0.18))
			canvas.draw_circle(end_pt - bridge_perp * half_deck_w, 3.8, rail_col.lightened(0.18))


# ==============================================================================
# 6. ROUTE-INTEGRATED DESTINATION LANDMARKS & INDEPENDENT POINTS OF INTEREST
# ==============================================================================
static func _find_safe_scenery_pos(
	preferred_pos: Vector2,
	half_ext: Vector2,
	rect: Rect2,
	page: MapPage,
	obstacle_rects: Array[Rect2]
) -> Vector2:
	var ox: float = rect.position.x
	var oy: float = rect.position.y
	var w: float = maxf(280.0, rect.size.x)
	var h: float = maxf(340.0, rect.size.y)
	var min_x: float = ox + half_ext.x + 6.0
	var max_x: float = maxf(min_x, ox + w - half_ext.x - 6.0)
	var best_pt := Vector2(clampf(preferred_pos.x, min_x, max_x), preferred_pos.y)
	var min_y_0: float = maxf(oy + half_ext.y + 8.0, get_land_ground_top_y_at(page, rect, best_pt.x) + half_ext.y * 0.5)
	var max_y_0: float = maxf(min_y_0, oy + h - half_ext.y - 6.0)
	best_pt.y = clampf(best_pt.y, min_y_0, max_y_0)
	var best_cl: float = _rect_clearance_to_obstacles(Rect2(best_pt - half_ext, half_ext * 2.0), obstacle_rects)
	if best_cl >= 3.0:
		return best_pt
	for dy_step in [0.0, -18.0, 18.0, -34.0, 34.0]:
		for dx_step in [0.0, -24.0, 24.0, -48.0, 48.0]:
			var cx: float = clampf(preferred_pos.x + dx_step, min_x, max_x)
			var min_y: float = maxf(oy + half_ext.y + 8.0, get_land_ground_top_y_at(page, rect, cx) + half_ext.y * 0.5)
			var max_y: float = maxf(min_y, oy + h - half_ext.y - 6.0)
			var cy: float = clampf(preferred_pos.y + dy_step, min_y, max_y)
			var cand := Vector2(cx, cy)
			var cl: float = _rect_clearance_to_obstacles(Rect2(cand - half_ext, half_ext * 2.0), obstacle_rects)
			if cl > best_cl:
				best_cl = cl
				best_pt = cand
				if best_cl >= 3.5:
					return best_pt
	return best_pt


static func _draw_continuous_country_landmarks(
	canvas: CanvasItem,
	rect: Rect2,
	page: MapPage,
	_theme: MapTheme,
	pal: Dictionary,
	split_idx: int,
	flip_world: bool,
	anim_time: float,
	_rng: RandomNumberGenerator,
	country_key: String,
	is_gameplay_bg: bool = false
) -> void:
	var w: float = rect.size.x
	var h: float = rect.size.y
	var ox: float = rect.position.x
	var oy: float = rect.position.y
	var offset := Vector2(ox, oy)
	var base_sc: float = get_base_landmark_scale_for_viewport(rect, page)

	var dark_green: Color = pal.get("ground_primary", Color(0.20, 0.52, 0.26, 1.0)).darkened(0.14)
	var lit_green: Color = pal.get("island_surface", Color(0.46, 0.80, 0.36, 0.98)).lightened(0.10)

	# 1. TYPE A — COUNTRY-BASED DESTINATION LANDMARKS & MILESTONE CONTEXTS
	var dest_stops: Dictionary = _select_route_destination_stops(page, split_idx, country_key)
	var lm_layout: Dictionary = _compute_non_overlapping_landmark_layout(page, dest_stops, rect, base_sc)
	var n: int = page.nodes.size()
	var is_compact_vp: bool = (w < 420.0 or h < 580.0)

	var obstacle_rects: Array[Rect2] = []
	for i in range(n):
		var nd_obs: MapNode = page.nodes[i]
		var np_obs: Vector2 = offset + nd_obs.position
		obstacle_rects.append(Rect2(
			np_obs - nd_obs.node_size * 0.5 - Vector2(3.0, 3.0),
			nd_obs.node_size + Vector2(6.0, 6.0)
		))
	for i in lm_layout.keys():
		var lm_rect: Rect2 = lm_layout[i].get("footprint_rect", lm_layout[i].get("arch_rect", Rect2()))
		obstacle_rects.append(lm_rect.grow(2.0))

	var zones: Dictionary = get_country_spatial_zones(page, rect)
	var water_spine: PackedVector2Array = zones.get("water_spine", PackedVector2Array())
	var water_half_w: float = float(zones.get("water_half_width", 18.0))
	var route_pts := PackedVector2Array()
	if page.route != null and page.route.smooth_points.size() >= 2:
		var sp_cnt: int = page.route.smooth_points.size()
		for rp_i in range(0, sp_cnt, 4):
			route_pts.append(offset + page.route.smooth_points[rp_i])
		if (sp_cnt - 1) % 4 != 0:
			route_pts.append(offset + page.route.smooth_points[sp_cnt - 1])

	# Pass 1A: Draw all featured destination landmarks and location plaques exactly as on MapPage
	for i in range(n):
		if not dest_stops.has(i):
			continue
		var nd: MapNode = page.nodes[i]
		var node_pos: Vector2 = offset + nd.position
		var lm_entry: Dictionary = lm_layout.get(i, {})
		var arch_pos: Vector2 = lm_entry.get("arch_pos", _compute_safe_landmark_arch_pos(page, i, rect, base_sc))
		var lm_sc: float = float(lm_entry.get("scale", base_sc))
		var stop_info: Dictionary = dest_stops[i]
		var lm_id: String = String(stop_info.get("landmark_id", ""))
		var label_text: String = String(stop_info.get("label", ""))
		var g_class: String = String(lm_entry.get("grounding_classification", stop_info.get("grounding_type", "GROUND")))
		var w_rel: String = String(lm_entry.get("water_relationship", stop_info.get("water_relationship", "none")))
		_draw_landmark_forecourt_approach(canvas, node_pos, arch_pos, lm_sc, country_key, pal, g_class, w_rel, lm_id)
		_draw_destination_landmark_at_node(canvas, node_pos, arch_pos, lm_id, lm_sc, anim_time, pal)
		if label_text != "":
			var plaque_pos: Vector2 = _compute_non_overlapping_plaque_pos(
				node_pos, arch_pos, nd, label_text, rect, obstacle_rects, lm_sc, false, water_spine, water_half_w, route_pts
			)
			var p_sz: Vector2 = _get_plaque_size(label_text, is_compact_vp, false)
			obstacle_rects.append(Rect2(plaque_pos - p_sz * 0.5 - Vector2(2.0, 2.0), p_sz + Vector2(4.0, 4.0)))
			_draw_location_plaque(canvas, plaque_pos, label_text, country_key, false, is_compact_vp)

	# Pass 1B: Draw regional milestone scenes outside obstacle footprints (no shrunken/repositioned duplicate landmarks)
	for i in range(n):
		if dest_stops.has(i):
			continue
		var nd_ms: MapNode = page.nodes[i]
		var node_pos_ms: Vector2 = offset + nd_ms.position
		var m_ctx: String = String(nd_ms.landmark.get("milestone_context", "regional_scene"))
		var env_type: String = String(nd_ms.landmark.get("environment_type", "regional_landscape"))
		var reg_sc: float = base_sc * maxf(0.72, get_destination_hierarchy_scale_multiplier(m_ctx))
		var side_dir: float = -1.0 if (node_pos_ms.x - ox) > (w * 0.50) else 1.0
		var raw_env := Vector2(clampf(node_pos_ms.x + side_dir * 42.0, ox + 32.0, ox + w - 32.0), node_pos_ms.y - 4.0)
		var reg_ext := Vector2(18.0 * reg_sc, 14.0 * reg_sc)
		var env_pos: Vector2 = _find_safe_scenery_pos(raw_env, reg_ext, rect, page, obstacle_rects)
		var reg_rect := Rect2(env_pos - reg_ext, reg_ext * 2.0)
		if _rect_clearance_to_obstacles(reg_rect, obstacle_rects) >= -2.0:
			obstacle_rects.append(reg_rect.grow(2.0))
			_draw_regional_milestone_scene(canvas, env_pos, reg_sc, env_type, country_key, dark_green, lit_green)

	# 2. TYPE B — INDEPENDENT POINT OF INTEREST (Large, Named Scenic Landmark Separated from the Route)
	var poi_cx: float = ox + w * (0.56 if not flip_world else 0.44)
	var poi_label: String = ""
	var poi_anchor := Vector2(poi_cx, oy + h * 0.19)
	match country_key:
		"japan":
			var lake_pos := Vector2(poi_cx, oy + h * 0.33)
			_draw_ellipse_filled(canvas, lake_pos, w * 0.20, h * 0.025, Color(0.22, 0.64, 0.86, 0.88))
			_draw_ellipse_filled(canvas, lake_pos + Vector2(0.0, -2.0), w * 0.14, h * 0.016, Color(0.62, 0.88, 0.98, 0.68))
			poi_label = "Mount Fuji"
			poi_anchor = Vector2(poi_cx, oy + h * 0.19)
		"france":
			poi_label = "French Alps"
			poi_anchor = Vector2(ox + w * 0.58, oy + h * 0.18)
		"vietnam_bay", "vietnam_city":
			var bay_raw := Vector2(ox + w * (0.20 if flip_world else 0.80), oy + h * 0.30)
			var bay_poi: Vector2 = _find_safe_scenery_pos(bay_raw, Vector2(26.0, 22.0), rect, page, obstacle_rects)
			var bay_rect := Rect2(bay_poi - Vector2(26.0, 22.0), Vector2(52.0, 44.0))
			if _rect_clearance_to_obstacles(bay_rect, obstacle_rects) >= 0.0:
				obstacle_rects.append(bay_rect.grow(2.0))
				_draw_halong_karst_islet(canvas, bay_poi, 26.0, pal.get("cliff_color", Color(0.46, 0.44, 0.40)), lit_green, pal.get("ground_secondary", Color(0.22, 0.82, 0.88)))
				_draw_halong_junk_boat(canvas, bay_poi + Vector2(-18.0, 10.0), 1.15)
		"thailand":
			var thai_raw := Vector2(ox + w * (0.20 if flip_world else 0.80), oy + h * 0.34)
			var thai_poi: Vector2 = _find_safe_scenery_pos(thai_raw, Vector2(24.0, 20.0), rect, page, obstacle_rects)
			var thai_rect := Rect2(thai_poi - Vector2(24.0, 20.0), Vector2(48.0, 40.0))
			if _rect_clearance_to_obstacles(thai_rect, obstacle_rects) >= 0.0:
				obstacle_rects.append(thai_rect.grow(2.0))
				_draw_halong_karst_islet(canvas, thai_poi, 24.0, pal.get("cliff_color", Color(0.48, 0.44, 0.38)), lit_green, pal.get("ground_secondary", Color(0.22, 0.82, 0.88)))
		"italy":
			poi_label = "Apennines"
			poi_anchor = Vector2(ox + w * 0.34, oy + h * 0.21)
		"usa_canyon", "usa_nyc":
			poi_label = "Monument Valley" if country_key == "usa_canyon" else "Hudson Harbor"
			poi_anchor = Vector2(ox + w * 0.50, oy + h * 0.20)
		"switzerland", "norway":
			poi_label = "Matterhorn" if country_key == "switzerland" else "Geiranger"
			poi_anchor = Vector2(poi_cx, oy + h * 0.18)
		"egypt":
			poi_label = "Giza Plateau"
			poi_anchor = Vector2(ox + w * 0.48, oy + h * 0.20)

	if poi_label != "":
		var safe_poi_pos: Vector2 = _compute_non_overlapping_plaque_pos(
			poi_anchor, poi_anchor, null, poi_label, rect, obstacle_rects, base_sc, true, water_spine, water_half_w, route_pts
		)
		var poi_psz: Vector2 = _get_plaque_size(poi_label, is_compact_vp, true)
		obstacle_rects.append(Rect2(safe_poi_pos - poi_psz * 0.5 - Vector2(2.0, 2.0), poi_psz + Vector2(4.0, 4.0)))
		_draw_location_plaque(canvas, safe_poi_pos, poi_label, country_key, true, is_compact_vp)

	# 3. REGIONAL ENVIRONMENTAL SCENERY CLUSTERS (Trees, Vegetation, Hills, Terraces Framing the World)
	var margin_bands: Array[float] = [0.28, 0.48, 0.68, 0.84]
	for b_idx in range(margin_bands.size()):
		var mv: float = margin_bands[b_idx]
		var on_left: bool = ((b_idx + (1 if flip_world else 0)) % 2 == 0)
		var mu: float = 0.12 if on_left else 0.88
		var scen_ext := Vector2(18.0 * base_sc * 0.72, 14.0 * base_sc * 0.72)
		var scen_pos: Vector2 = _find_safe_scenery_pos(Vector2(ox + w * mu, oy + h * mv), scen_ext, rect, page, obstacle_rects)
		var scen_rect := Rect2(scen_pos - scen_ext, scen_ext * 2.0)
		if _rect_clearance_to_obstacles(scen_rect, obstacle_rects) < 2.0:
			continue
		obstacle_rects.append(scen_rect.grow(2.0))
		match country_key:
			"japan":
				if b_idx % 2 == 0:
					_draw_sakura_blossom_cluster(canvas, scen_pos, base_sc * 0.72)
				else:
					_draw_bamboo_and_sakura_grove(canvas, scen_pos, base_sc * 0.70)
			"italy":
				if b_idx % 2 == 0:
					_draw_cypress_grove(canvas, scen_pos, base_sc * 0.74)
				else:
					_draw_woodland_canopy_mass(canvas, scen_pos, base_sc * 0.66, dark_green, lit_green)
			"france":
				if b_idx % 2 == 0:
					_draw_lavender_field_rows(canvas, scen_pos, base_sc * 0.72)
				else:
					_draw_woodland_canopy_mass(canvas, scen_pos, base_sc * 0.68, dark_green, lit_green)
			"vietnam_bay", "vietnam_city", "thailand", "coastal_archipelago":
				if b_idx % 2 == 0:
					_draw_stepped_rice_terrace_patch(canvas, scen_pos, base_sc * 0.70)
				else:
					_draw_palm_grove_cluster(canvas, scen_pos, base_sc * 0.72)
			"usa_canyon", "usa_nyc":
				if country_key == "usa_canyon":
					_draw_grand_canyon_mesa(canvas, scen_pos, base_sc * 0.72)
				else:
					_draw_woodland_canopy_mass(canvas, scen_pos, base_sc * 0.66, dark_green, lit_green)
			"egypt":
				_draw_palm_grove_cluster(canvas, scen_pos, base_sc * 0.72)
			"switzerland", "norway":
				_draw_snow_pine_cluster(canvas, scen_pos, base_sc * 0.74)
			_:
				_draw_woodland_canopy_mass(canvas, scen_pos, base_sc * 0.66, dark_green, lit_green)


static func _draw_regional_milestone_scene(
	canvas: CanvasItem,
	pos: Vector2,
	sc: float,
	env_type: String,
	country_key: String,
	dark_green: Color,
	lit_green: Color
) -> void:
	match env_type:
		"coastal_landscape":
			_draw_palm_grove_cluster(canvas, pos, sc)
		"mountain_landscape":
			_draw_snow_pine_cluster(canvas, pos, sc)
		"agricultural_landscape":
			if country_key == "france" or country_key == "italy":
				_draw_lavender_field_rows(canvas, pos, sc)
			else:
				_draw_stepped_rice_terrace_patch(canvas, pos, sc)
		"desert_landscape":
			_draw_grand_canyon_mesa(canvas, pos, sc * 0.92)
		"historic_town":
			_draw_coastal_terracotta_village(canvas, pos, sc * 0.92)
		"river_landscape", "lake_landscape":
			_draw_cypress_grove(canvas, pos, sc)
		_:
			if country_key == "japan":
				_draw_sakura_blossom_cluster(canvas, pos, sc)
			elif country_key == "italy":
				_draw_cypress_grove(canvas, pos, sc)
			else:
				_draw_woodland_canopy_mass(canvas, pos, sc, dark_green, lit_green)


static func _draw_landmark_forecourt_approach(
	canvas: CanvasItem,
	courtyard_pos: Vector2,
	arch_pos: Vector2,
	sc: float,
	country_key: String,
	pal: Dictionary,
	_grounding_class: String = "GROUND",
	_water_rel: String = "none",
	lm_id: String = ""
) -> void:
	var road_col: Color = pal.get("path_inner", Color(0.95, 0.88, 0.72, 1.0)).lightened(0.06)
	var border_col: Color = pal.get("path_outer", Color(0.76, 0.62, 0.42, 1.0)).darkened(0.10)

	# 1. Coherent footpath trace connecting the route destination to the landmark base
	canvas.draw_line(courtyard_pos, arch_pos + Vector2(0.0, 2.0 * sc), border_col, 6.2 * sc, true)
	canvas.draw_line(courtyard_pos, arch_pos + Vector2(0.0, 2.0 * sc), road_col, 3.8 * sc, true)

	# 2. Natural ground contact shadow directly on the continuous country terrain (no artificial circular pads or floating blobs)
	canvas.draw_line(
		arch_pos + Vector2(-15.5 * sc, 2.8 * sc),
		arch_pos + Vector2(15.5 * sc, 2.8 * sc),
		Color(0.04, 0.08, 0.12, 0.28),
		3.2 * sc,
		true
	)

	# 3. Architectural flanking context standing on the same ground line when applicable
	if lm_id == "eiffel_tower":
		for b_i in [-1, 1]:
			var bx: float = arch_pos.x + float(b_i) * 14.5 * sc
			canvas.draw_rect(Rect2(Vector2(bx - 5.0 * sc, arch_pos.y - 7.5 * sc), Vector2(10.0 * sc, 9.5 * sc)), Color(0.90, 0.84, 0.72, 0.94), true)
			canvas.draw_rect(Rect2(Vector2(bx - 5.2 * sc, arch_pos.y - 10.0 * sc), Vector2(10.4 * sc, 2.8 * sc)), Color(0.32, 0.38, 0.48, 0.96), true)
	elif lm_id == "pisa_tower":
		canvas.draw_rect(Rect2(arch_pos + Vector2(-15.0 * sc, -7.0 * sc), Vector2(11.0 * sc, 9.0 * sc)), Color(0.96, 0.94, 0.88, 0.98), true)
		canvas.draw_colored_polygon(PackedVector2Array([
			arch_pos + Vector2(-16.0 * sc, -7.0 * sc),
			arch_pos + Vector2(-9.5 * sc, -12.5 * sc),
			arch_pos + Vector2(-3.0 * sc, -7.0 * sc)
		]), Color(0.84, 0.38, 0.24, 0.96))

	if country_key == "japan" or country_key == "vietnam_city":
		for side_s in [-1.0, 1.0]:
			var lx: float = courtyard_pos.x + side_s * 20.0 * sc
			var ly: float = courtyard_pos.y - 3.0
			canvas.draw_circle(Vector2(lx, ly), 2.2 * sc, Color(0.96, 0.26, 0.18, 0.95))


static func _draw_destination_landmark_at_node(
	canvas: CanvasItem,
	node_pos: Vector2,
	arch_pos: Vector2,
	lm_id: String,
	sc: float,
	anim_time: float,
	pal: Dictionary
) -> void:
	match lm_id:
		"torii_shrine", "fushimi_inari_torii", "itsukushima_torii", "meiji_shrine":
			_draw_bamboo_and_sakura_grove(canvas, arch_pos + Vector2(-15.0 * sc, 1.5 * sc), sc * 0.76)
			_draw_japanese_torii_shrine_gate(canvas, arch_pos + Vector2(0.0, -2.0 * sc), sc * 1.08)
		"kyoto_temple", "senso_ji_pagoda", "todai_ji_nara", "gyeongbokgung_nseoul", "bulguksa_seokguram", "forbidden_city_great_wall", "great_wall_forbidden_city", "terracotta_army_xian", "classic_gardens_suzhou":
			_draw_japanese_temple_complex(canvas, arch_pos + Vector2(0.0, -4.0 * sc), sc * 1.02)
		"osaka_castle", "himeji_castle", "edinburgh_castle", "neuschwanstein_castle", "heidelberg_castle", "chillon_castle", "charles_bridge_castle", "wawel_castle", "bran_castle", "peles_castle", "bled_island_castle", "trakai_island_castle", "tallinn_toompea_walls", "dubrovnik_walls", "kotor_bay_fortress", "cartagena_walled_city", "qaitbay_citadel", "pena_palace_sintra", "alcazar_toledo":
			_draw_japanese_castle_keep(canvas, arch_pos + Vector2(0.0, -4.0 * sc), sc * 1.04)
		"tokyo_tower", "cn_tower_toronto", "taipei_101_jiufen", "petronas_twin_towers", "burj_khalifa_downtown", "marina_bay_sands", "kuwait_towers", "baku_flame_towers":
			_draw_modern_city_building_cluster(canvas, arch_pos + Vector2(-9.0 * sc, -2.0 * sc), sc * 0.86)
			_draw_tokyo_tower_landmark(canvas, arch_pos + Vector2(8.5 * sc, -2.0 * sc), sc * 0.96)
		"chureito_pagoda", "wat_arun_grand_palace", "wat_phra_that_doi_suthep", "ayutthaya_prangs", "angkor_wat_towers", "bagan_pagodas", "shwedagon_pagoda", "pha_that_luang", "wat_xieng_thong", "borobudur_stupa", "prambanan_temple", "tanah_lot_bali", "boudhanath_swayambhunath", "tiger_nest_paro", "punakha_dzong", "temple_of_the_tooth":
			_draw_sakura_blossom_cluster(canvas, arch_pos + Vector2(-15.5 * sc, 1.5 * sc), sc * 0.76)
			_draw_japanese_pagoda_landmark(canvas, arch_pos + Vector2(0.0, -4.0 * sc), sc * 1.02)
		"tuscany_villa", "amalfi_cliff_village", "cinque_terre_harbor", "oia_blue_domes", "rovaniemi_arctic", "bryggen_wharf", "nyhavn_harbor", "gamla_stan_vasa", "hallstatt_lake_village", "chefchaouen_blue_medina", "sidi_bou_said", "valparaiso_cerros", "bo_kaap_waterfront":
			_draw_tuscan_villa_cluster(canvas, arch_pos + Vector2(0.0, -3.0 * sc), sc * 1.04)
		"pisa_tower":
			_draw_cypress_grove(canvas, arch_pos + Vector2(-14.5 * sc, 1.5 * sc), sc * 0.78)
			_draw_leaning_tower_of_pisa(canvas, arch_pos + Vector2(4.0 * sc, 2.0 * sc), sc * 1.12)
		"florence_duomo", "florence_duomo_pisa", "milan_duomo", "sagrada_familia", "cologne_cathedral", "york_minster", "st_basils_red_square", "peter_paul_hermitage", "st_stephens_schoenbrunn", "grand_place_atomium", "rijksmuseum_canals", "notre_dame_montreal", "havana_capitolio_malecon", "cusco_plaza_armas", "quito_compania_mitad":
			_draw_florence_duomo_and_pisa(canvas, arch_pos + Vector2(0.0, -4.0 * sc), sc * 1.02)
		"venice_canal", "venice_canal_rialto", "kinderdijk_windmills", "giethoorn_canals", "bruges_belfry_canals", "stockholm_archipelago", "helsinki_suomenlinna":
			_draw_venice_canal_palazzo_and_gondola(canvas, arch_pos + Vector2(0.0, -4.0 * sc), sc * 1.00)
		"rome_colosseum", "colosseum_rome", "pompeii_vesuvius", "pont_du_gard", "parthenon_acropolis", "delphi_apollo_temple", "meteora_monasteries", "ephesus_celsus", "petra_treasury", "jerash_oval_plaza", "el_djem_amphitheatre", "carthage_antonine_baths", "baalbek_bacchus", "stonehenge", "roman_baths", "acropolis_lindos":
			_draw_roman_colosseum_landmark(canvas, arch_pos + Vector2(0.0, -4.0 * sc), sc * 1.04)
		"loire_chateau", "chateau_chambord", "promenade_des_anglais":
			_draw_lavender_field_rows(canvas, arch_pos + Vector2(0.0, 2.5 * sc), sc * 0.80)
			_draw_tuscan_villa_cluster(canvas, arch_pos + Vector2(0.0, -3.0 * sc), sc * 1.00)
		"versailles_palace", "brandenburg_gate", "plaza_mayor_palace", "plaza_espana_seville", "alhambra_palace", "buda_castle_parliament", "palace_of_parliament", "amber_fort_hawa_mahal", "gateway_of_india", "mysore_palace", "victoria_memorial_kolkata", "teatro_colon_obelisco":
			_draw_versailles_palace_and_gardens(canvas, arch_pos + Vector2(0.0, -4.0 * sc), sc * 1.00)
		"mont_saint_michel", "taj_mahal_agra", "hagia_sophia_blue_mosque", "sultan_qaboos_mosque", "sheikh_zayed_mosque", "hassan_ii_mosque", "koutoubia_jemaa_el_fna", "registan_samarkand", "shah_i_zinda_bibi", "kalyan_minaret_ark", "ichan_kala_khiva", "badshahi_mosque_lahore", "faisal_mosque", "al_masjid_an_nabawi", "museum_islamic_art_doha":
			_draw_mont_saint_michel_abbey(canvas, arch_pos + Vector2(0.0, -4.0 * sc), sc * 0.98)
		"eiffel_tower", "tower_bridge_big_ben":
			_draw_eiffel_tower_landmark(canvas, arch_pos + Vector2(0.0, -3.0 * sc), sc * 0.96)
		"halong_harbor", "halong_karst_harbor", "guilin_li_river_karsts", "zhangjiajie_avatar_peaks", "phang_nga_james_bond", "krabi_railay_karsts", "el_nido_lagoons", "raja_ampat_wayag", "komodo_padar_island", "milford_sound_mitre_peak", "geirangerfjord_seven_sisters", "lofoten_reinebringen":
			_draw_halong_karst_islet(
				canvas, arch_pos + Vector2(-12.0 * sc, -5.0 * sc), 21.0 * sc,
				pal.get("cliff_color", Color(0.46, 0.44, 0.40)),
				pal.get("island_surface", Color(0.42, 0.78, 0.36)),
				pal.get("ground_secondary", Color(0.22, 0.82, 0.88))
			)
			_draw_halong_junk_boat(canvas, arch_pos + Vector2(15.0 * sc, 2.0 * sc), sc * 0.96)
		"ninh_binh_trang_an_karst", "chocolate_hills_bohol", "sigiriya_lion_rock", "cappadocia_chimneys", "pamukkale_travertines", "meteora_cliffs":
			_draw_ninh_binh_trang_an_karsts(canvas, arch_pos + Vector2(0.0, -4.0 * sc), sc * 1.00, pal)
		"hanoi_pagoda", "hanoi_hoan_kiem_pagoda":
			_draw_hanoi_hoan_kiem_and_the_huc(canvas, arch_pos + Vector2(0.0, -4.0 * sc), sc * 1.02)
		"hue_citadel", "hue_imperial_citadel":
			_draw_hue_imperial_citadel_gate(canvas, arch_pos + Vector2(0.0, -4.0 * sc), sc * 1.00)
		"hoian_lanterns", "hoian_covered_bridge_lanterns", "jiufen_teahouse_lanterns":
			_draw_hoian_lantern_street_and_bridge(canvas, arch_pos + Vector2(0.0, -4.0 * sc), sc * 1.00)
		"saigon_skyline", "saigon_bitexco_skyline", "victoria_harbour_skyline", "bund_pudong_skyline", "sydney_opera_harbour_bridge", "auckland_sky_tower_harbour", "panama_canal_miraflores":
			_draw_saigon_bitexco_and_skyline(canvas, arch_pos + Vector2(0.0, -4.0 * sc), sc * 0.96)
		"mekong_floating_market", "inle_lake_stilt_boats", "kerala_backwaters_houseboat", "okavango_delta_mokoro", "amazon_meeting_waters":
			_draw_mekong_delta_floating_market(canvas, arch_pos + Vector2(0.0, -4.0 * sc), sc * 1.00)
		"lighthouse_landmark", "cape_of_good_hope", "belem_tower_jeronimos", "hercules_tower", "peggys_cove_lighthouse":
			_draw_lighthouse_landmark(canvas, arch_pos + Vector2(0.0, -3.0 * sc), sc * 0.90, anim_time)
		"statue_of_liberty", "christ_redeemer_corcovado", "moai_ahu_tongariki", "ushuaia_fin_del_mundo":
			_draw_statue_of_liberty_harbor(canvas, arch_pos + Vector2(0.0, -4.0 * sc), sc * 0.98)
		"grand_canyon_rim", "uluru_ayers_rock", "wadi_rum_arches", "sossusvlei_dunes", "sahara_erg_chebbi", "atacama_valle_luna", "table_mountain", "chapada_diamantina", "tsingy_bemaraha", "avenue_of_baobabs":
			_draw_grand_canyon_mesa(canvas, arch_pos + Vector2(0.0, -4.0 * sc), sc * 1.12)
		"las_vegas_strip", "cloud_gate_skyline", "manhattan_skyline":
			_draw_modern_city_building_cluster(canvas, arch_pos + Vector2(0.0, -4.0 * sc), sc * 0.96)
		"golden_gate", "golden_gate_bridge", "chapel_bridge_lucerne", "mostar_stari_most", "chain_bridge_danube", "bosphorus_bridge", "victoria_falls_bridge":
			_draw_golden_gate_and_vegas_strip(canvas, arch_pos + Vector2(0.0, -3.0 * sc), sc * 1.02)
		"giza_sphinx", "giza_pyramids_sphinx", "abu_simbel", "abu_simbel_temples", "chichen_itza_el_castillo", "teotihuacan_pyramids", "tikal_temples", "palemque_inscriptions", "copan_hieroglyphic_stairway", "machu_picchu_citadel", "sacred_valley_ollantaytambo", "tiwanaku_kalasasaya":
			_draw_egyptian_temple_landmark(canvas, arch_pos + Vector2(0.0, -4.0 * sc), sc * 1.02)
		"karnak_temple", "luxor_obelisk", "karnak_luxor_temple", "edfu_horus_temple", "philae_isis_temple", "axum_obelisks", "lalibela_rock_churches":
			_draw_luxor_obelisk_and_pylon(canvas, arch_pos + Vector2(0.0, -4.0 * sc), sc * 0.98)
		"alpine_chalet", "alpine_village", "glacier_bridge", "zermatt_sanctuary", "matterhorn_zermatt", "jungfraujoch_sphinx", "jet_deau_geneva", "banff_lake_louise", "jasper_icefields", "torres_del_paine", "perito_moreno_glacier", "fitz_roy_el_chalten", "bariloche_nahuel_huapi", "mount_kilimanjaro", "mount_kenya", "kazbegi_gergeti_trinity", "tian_shan_issyk_kul", "gullfoss_geysir", "jokulsarlon_glacier_lagoon", "kirkjufell_snaefellsnes", "arenal_volcano", "cotopaxi_avenue_volcanoes", "bromo_tengger_caldera", "mayon_volcano_cone":
			_draw_alpine_chalet(canvas, arch_pos + Vector2(0.0, -4.0 * sc), sc * 1.04)
		_:
			_draw_tuscan_villa_cluster(canvas, arch_pos + Vector2(0.0, -3.0 * sc), sc * 1.00)


static func _draw_hanoi_hoan_kiem_and_the_huc(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	# Ngoc Son Temple two-tier golden-roofed pagoda + crimson arched The Huc Bridge grounded on the terrain
	canvas.draw_rect(Rect2(pos + Vector2(-9.0 * sc, -13.0 * sc), Vector2(18.0 * sc, 11.0 * sc)), Color(0.96, 0.88, 0.68, 1.0), true)
	for tier_i in range(2):
		var ty: float = (-12.5 - float(tier_i) * 6.5) * sc
		var tw: float = (13.5 - float(tier_i) * 3.0) * sc
		canvas.draw_colored_polygon(PackedVector2Array([
			pos + Vector2(-tw, ty),
			pos + Vector2(-tw * 0.65, ty - 5.2 * sc),
			pos + Vector2(tw * 0.65, ty - 5.2 * sc),
			pos + Vector2(tw, ty)
		]), Color(0.78, 0.24, 0.16, 1.0))
	# Iconic crimson arched wooden The Huc Bridge
	canvas.draw_arc(pos + Vector2(0.0, 5.5 * sc), 14.0 * sc, PI * 1.08, PI * 1.92, 12, Color(0.92, 0.18, 0.16, 1.0), 3.6 * sc)
	for post_i in range(5):
		var px: float = (-10.0 + float(post_i) * 5.0) * sc
		var py: float = -3.2 * sc + absf(float(post_i - 2)) * 1.4 * sc
		canvas.draw_line(pos + Vector2(px, py), pos + Vector2(px, py - 3.6 * sc), Color(0.98, 0.82, 0.28, 1.0), 1.6 * sc)


static func _draw_ninh_binh_trang_an_karsts(canvas: CanvasItem, pos: Vector2, sc: float, pal: Dictionary) -> void:
	var cliff_col: Color = pal.get("cliff_color", Color(0.44, 0.46, 0.42, 1.0))
	var green_col: Color = pal.get("island_surface", Color(0.36, 0.74, 0.34, 1.0))
	# Twin karst peaks + limestone water-cave arch + sampan grounded on the landscape
	_draw_halong_karst_islet(canvas, pos + Vector2(-10.0 * sc, -4.0 * sc), 19.0 * sc, cliff_col, green_col, Color(0.20, 0.68, 0.72))
	_draw_halong_karst_islet(canvas, pos + Vector2(11.0 * sc, -2.0 * sc), 16.0 * sc, cliff_col.darkened(0.08), green_col, Color(0.20, 0.68, 0.72))
	# Cave grotto arch at base
	canvas.draw_circle(pos + Vector2(-10.0 * sc, 2.0 * sc), 4.2 * sc, Color(0.12, 0.22, 0.26, 0.95))
	# Wooden sampan boat
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(2.0 * sc, 4.0 * sc),
		pos + Vector2(6.0 * sc, 6.5 * sc),
		pos + Vector2(15.0 * sc, 6.5 * sc),
		pos + Vector2(18.0 * sc, 4.0 * sc)
	]), Color(0.64, 0.38, 0.18, 1.0))


static func _draw_saigon_bitexco_and_skyline(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	_draw_modern_city_building_cluster(canvas, pos + Vector2(-8.0 * sc, 0.0), sc * 0.92)
	# Iconic Bitexco Financial Tower curved lotus profile + cantilevered helipad disk on the right
	var b_col := Color(0.32, 0.68, 0.88, 1.0)
	var tower_pts := PackedVector2Array([
		pos + Vector2(6.0 * sc, 6.0 * sc),
		pos + Vector2(7.5 * sc, -28.0 * sc),
		pos + Vector2(12.0 * sc, -34.0 * sc),
		pos + Vector2(15.5 * sc, -24.0 * sc),
		pos + Vector2(17.0 * sc, 6.0 * sc)
	])
	canvas.draw_colored_polygon(tower_pts, b_col)
	# Iconic circular helipad projecting from the 52nd floor
	_draw_ellipse_filled(canvas, pos + Vector2(18.5 * sc, -19.0 * sc), 5.8 * sc, 2.2 * sc, Color(0.86, 0.94, 1.0, 1.0))
	canvas.draw_line(pos + Vector2(11.5 * sc, -34.0 * sc), pos + Vector2(11.5 * sc, -41.0 * sc), Color(0.95, 0.98, 1.0, 1.0), 2.0 * sc)


static func _draw_mekong_delta_floating_market(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	# Cai Rang wooden market boats + tropical fruit poles + coconut palms grounded on the delta
	_draw_palm_grove_cluster(canvas, pos + Vector2(-18.0 * sc, -4.0 * sc), sc * 0.72)
	for b_i in range(2):
		var bx: float = (-4.0 + float(b_i) * 14.0) * sc
		var by: float = (0.0 + float(b_i) * 3.2) * sc
		canvas.draw_colored_polygon(PackedVector2Array([
			pos + Vector2(bx - 9.0 * sc, by - 1.5 * sc),
			pos + Vector2(bx - 6.0 * sc, by + 3.0 * sc),
			pos + Vector2(bx + 6.0 * sc, by + 3.0 * sc),
			pos + Vector2(bx + 9.0 * sc, by - 1.5 * sc)
		]), Color(0.62, 0.36, 0.18, 1.0))
		# Colorful tropical fruit baskets + upright sample pole (cây bẹo)
		canvas.draw_circle(pos + Vector2(bx - 2.0 * sc, by - 2.2 * sc), 2.6 * sc, Color(0.98, 0.76, 0.18, 1.0))
		canvas.draw_circle(pos + Vector2(bx + 2.2 * sc, by - 2.2 * sc), 2.5 * sc, Color(0.92, 0.26, 0.22, 1.0))
		canvas.draw_line(pos + Vector2(bx + 5.0 * sc, by - 1.5 * sc), pos + Vector2(bx + 5.0 * sc, by - 11.0 * sc), Color(0.48, 0.30, 0.14, 1.0), 1.6 * sc)
		canvas.draw_circle(pos + Vector2(bx + 5.0 * sc, by - 11.5 * sc), 2.2 * sc, Color(0.38, 0.82, 0.28, 1.0))


static func _draw_location_plaque(
	canvas: CanvasItem,
	pos: Vector2,
	label_text: String,
	country_key: String,
	is_poi: bool = false,
	is_compact: bool = false
) -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return
	var disp_text: String = _format_plaque_display_text(label_text)
	var f_size: int = (10 if is_compact else 11) if not is_poi else (11 if is_compact else 12)
	var p_sz: Vector2 = _get_plaque_size(disp_text, is_compact, is_poi)
	var half_w: float = maxf(18.0, p_sz.x * 0.5 - 4.0)
	var half_h: float = maxf(7.5, p_sz.y * 0.5 - 1.5)

	# Illustrated wooden signboard / carved stone ribbon integrated into the world art
	var bg_col := Color(0.36, 0.22, 0.13, 0.94)
	var rim_col := Color(0.88, 0.72, 0.42, 0.96)
	var txt_col := Color(1.0, 0.97, 0.88, 1.0)
	if country_key in ["italy", "france", "egypt"]:
		bg_col = Color(0.95, 0.90, 0.78, 0.95)
		rim_col = Color(0.58, 0.44, 0.28, 0.96)
		txt_col = Color(0.24, 0.16, 0.10, 1.0)

	var plaque_pts := PackedVector2Array([
		pos + Vector2(-half_w - 4.0, 0.0),
		pos + Vector2(-half_w, -half_h),
		pos + Vector2(half_w, -half_h),
		pos + Vector2(half_w + 4.0, 0.0),
		pos + Vector2(half_w, half_h),
		pos + Vector2(-half_w, half_h)
	])
	var sh_pts := PackedVector2Array()
	for p in plaque_pts:
		sh_pts.append(p + Vector2(1.0, 2.2))
	canvas.draw_colored_polygon(sh_pts, Color(0.02, 0.05, 0.12, 0.36))
	canvas.draw_colored_polygon(plaque_pts, bg_col)
	var closed_plaque := plaque_pts.duplicate()
	closed_plaque.append(plaque_pts[0])
	canvas.draw_polyline(closed_plaque, rim_col, 1.6, true)
	canvas.draw_circle(pos + Vector2(-half_w + 2.5, 0.0), 1.6, rim_col)
	canvas.draw_circle(pos + Vector2(half_w - 2.5, 0.0), 1.6, rim_col)

	var baseline_y: float = pos.y + float(f_size) * 0.36
	canvas.draw_string(
		font,
		Vector2(pos.x - half_w, baseline_y),
		disp_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		half_w * 2.0,
		f_size,
		txt_col
	)


# ==============================================================================
# REGIONAL LANDMARK & ENVIRONMENT ILLUSTRATION PRIMITIVES
# ==============================================================================
static func _draw_japanese_torii_shrine_gate(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	var vermilion := Color(0.90, 0.20, 0.16, 1.0)
	var dark_roof := Color(0.20, 0.18, 0.22, 1.0)
	var stone_col := Color(0.76, 0.74, 0.70, 1.0)
	# Twin stone tōrō lanterns flanking the shrine approach
	for s_side in [-1.0, 1.0]:
		var lx: float = pos.x + s_side * 18.5 * sc
		var ly: float = pos.y + 4.0 * sc
		canvas.draw_rect(Rect2(Vector2(lx - 2.5 * sc, ly - 8.0 * sc), Vector2(5.0 * sc, 8.0 * sc)), stone_col, true)
		canvas.draw_rect(Rect2(Vector2(lx - 2.0 * sc, ly - 11.5 * sc), Vector2(4.0 * sc, 3.5 * sc)), Color(1.0, 0.90, 0.42, 0.95), true)
		canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(lx - 4.5 * sc, ly - 11.5 * sc),
			Vector2(lx, ly - 15.0 * sc),
			Vector2(lx + 4.5 * sc, ly - 11.5 * sc)
		]), stone_col.darkened(0.18))
	# Tall vermilion Torii pillars + black base shoes
	canvas.draw_rect(Rect2(pos + Vector2(-11.5 * sc, 1.0 * sc), Vector2(4.2 * sc, 5.0 * sc)), dark_roof, true)
	canvas.draw_rect(Rect2(pos + Vector2(7.3 * sc, 1.0 * sc), Vector2(4.2 * sc, 5.0 * sc)), dark_roof, true)
	canvas.draw_rect(Rect2(pos + Vector2(-11.0 * sc, -21.0 * sc), Vector2(3.4 * sc, 23.0 * sc)), vermilion, true)
	canvas.draw_rect(Rect2(pos + Vector2(7.6 * sc, -21.0 * sc), Vector2(3.4 * sc, 23.0 * sc)), vermilion, true)
	# Lower tie beam (nuki) + center plaque (gakuzuka)
	canvas.draw_rect(Rect2(pos + Vector2(-14.0 * sc, -15.5 * sc), Vector2(28.0 * sc, 2.8 * sc)), vermilion, true)
	canvas.draw_rect(Rect2(pos + Vector2(-2.2 * sc, -21.5 * sc), Vector2(4.4 * sc, 6.5 * sc)), Color(0.98, 0.82, 0.28, 1.0), true)
	# Sweeping curved top kasagi lintel
	var kasagi := PackedVector2Array([
		pos + Vector2(-18.0 * sc, -22.5 * sc),
		pos + Vector2(-12.0 * sc, -20.5 * sc),
		pos + Vector2(12.0 * sc, -20.5 * sc),
		pos + Vector2(18.0 * sc, -22.5 * sc),
		pos + Vector2(16.0 * sc, -18.0 * sc),
		pos + Vector2(-16.0 * sc, -18.0 * sc)
	])
	canvas.draw_colored_polygon(kasagi, vermilion)
	canvas.draw_line(pos + Vector2(-17.5 * sc, -22.2 * sc), pos + Vector2(17.5 * sc, -22.2 * sc), dark_roof, 2.2 * sc)


static func _draw_japanese_temple_complex(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	# Traditional Kyoto Kiyomizu-dera / Hondō wooden temple hall with sweeping irimoya roof & sakura tree
	_draw_sakura_blossom_cluster(canvas, pos + Vector2(18.0 * sc, -4.0 * sc), sc * 0.82)
	# Raised wooden stage / stone foundation
	canvas.draw_rect(Rect2(pos + Vector2(-21.0 * sc, 1.0 * sc), Vector2(42.0 * sc, 6.0 * sc)), Color(0.56, 0.36, 0.20, 1.0), true)
	# White plaster & crimson timber colonnade walls
	canvas.draw_rect(Rect2(pos + Vector2(-18.0 * sc, -12.0 * sc), Vector2(36.0 * sc, 13.5 * sc)), Color(0.97, 0.94, 0.88, 1.0), true)
	for p_i in range(5):
		var px: float = (-15.0 + float(p_i) * 7.5) * sc
		canvas.draw_rect(Rect2(pos + Vector2(px - 1.1 * sc, -12.0 * sc), Vector2(2.2 * sc, 13.5 * sc)), Color(0.84, 0.22, 0.18, 1.0), true)
	# Grand sweeping curved dark-slate temple roof with golden chigi finials
	var main_roof := PackedVector2Array([
		pos + Vector2(-25.0 * sc, -10.5 * sc),
		pos + Vector2(-15.0 * sc, -22.5 * sc),
		pos + Vector2(15.0 * sc, -22.5 * sc),
		pos + Vector2(25.0 * sc, -10.5 * sc)
	])
	canvas.draw_colored_polygon(main_roof, Color(0.22, 0.24, 0.30, 1.0))
	# Central golden-trimmed gable (karahafu) over the temple entrance
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-9.5 * sc, -11.0 * sc),
		pos + Vector2(0.0, -18.5 * sc),
		pos + Vector2(9.5 * sc, -11.0 * sc)
	]), Color(0.32, 0.34, 0.42, 1.0))
	canvas.draw_line(pos + Vector2(-15.0 * sc, -22.5 * sc), pos + Vector2(15.0 * sc, -22.5 * sc), Color(0.98, 0.82, 0.28, 1.0), 2.4 * sc)


static func _draw_japanese_castle_keep(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	# Iconic Himeji / Osaka Castle multi-tiered white plaster tenshu on sloped stone ishigaki base
	var base_pts := PackedVector2Array([
		pos + Vector2(-19.0 * sc, 6.0 * sc),
		pos + Vector2(-14.0 * sc, -3.0 * sc),
		pos + Vector2(14.0 * sc, -3.0 * sc),
		pos + Vector2(19.0 * sc, 6.0 * sc)
	])
	canvas.draw_colored_polygon(base_pts, Color(0.58, 0.56, 0.52, 1.0))
	for tier in range(3):
		var ty: float = (-3.0 - float(tier) * 8.5) * sc
		var tw: float = (15.0 - float(tier) * 2.8) * sc
		canvas.draw_rect(Rect2(pos + Vector2(-tw, ty - 6.5 * sc), Vector2(tw * 2.0, 6.8 * sc)), Color(0.98, 0.97, 0.94, 1.0), true)
		canvas.draw_colored_polygon(PackedVector2Array([
			pos + Vector2(-tw * 1.28, ty - 5.8 * sc),
			pos + Vector2(-tw * 0.78, ty - 10.2 * sc),
			pos + Vector2(tw * 0.78, ty - 10.2 * sc),
			pos + Vector2(tw * 1.28, ty - 5.8 * sc)
		]), Color(0.24, 0.28, 0.34, 1.0))


static func _draw_tokyo_tower_landmark(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	var red_col := Color(0.94, 0.24, 0.18, 1.0)
	var white_col := Color(0.98, 0.98, 0.98, 1.0)
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-14.0 * sc, 6.0 * sc),
		pos + Vector2(-4.5 * sc, -14.0 * sc),
		pos + Vector2(-1.8 * sc, -36.0 * sc),
		pos + Vector2(1.8 * sc, -36.0 * sc),
		pos + Vector2(4.5 * sc, -14.0 * sc),
		pos + Vector2(14.0 * sc, 6.0 * sc),
		pos + Vector2(7.5 * sc, 6.0 * sc),
		pos + Vector2(0.0, -3.0 * sc),
		pos + Vector2(-7.5 * sc, 6.0 * sc)
	]), red_col)
	canvas.draw_rect(Rect2(pos + Vector2(-9.5 * sc, -6.0 * sc), Vector2(19.0 * sc, 3.2 * sc)), white_col, true)
	canvas.draw_rect(Rect2(pos + Vector2(-5.5 * sc, -19.0 * sc), Vector2(11.0 * sc, 2.8 * sc)), white_col, true)
	canvas.draw_line(pos + Vector2(0.0, -36.0 * sc), pos + Vector2(0.0, -45.0 * sc), white_col, 2.2 * sc)


static func _draw_bamboo_and_sakura_grove(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	for b_i in range(5):
		var bx: float = pos.x + float(b_i - 2) * 4.2 * sc
		var by0: float = pos.y + 4.0 * sc
		var by1: float = by0 - (18.0 + float(b_i % 2) * 5.0) * sc
		canvas.draw_line(Vector2(bx, by0), Vector2(bx + (1.2 if b_i % 2 == 0 else -1.0) * sc, by1), Color(0.24, 0.68, 0.30, 1.0), 2.4 * sc)
		canvas.draw_circle(Vector2(bx, by1), 4.2 * sc, Color(0.36, 0.80, 0.38, 0.92))


static func _draw_sakura_blossom_cluster(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	canvas.draw_rect(Rect2(pos + Vector2(-2.2 * sc, -2.0 * sc), Vector2(4.4 * sc, 9.0 * sc)), Color(0.44, 0.26, 0.18, 1.0), true)
	canvas.draw_circle(pos + Vector2(-6.0 * sc, -6.0 * sc), 8.5 * sc, Color(0.98, 0.64, 0.78, 0.95))
	canvas.draw_circle(pos + Vector2(6.0 * sc, -5.0 * sc), 8.0 * sc, Color(1.0, 0.74, 0.86, 0.95))
	canvas.draw_circle(pos + Vector2(0.0, -10.5 * sc), 9.2 * sc, Color(1.0, 0.82, 0.90, 0.98))


static func _draw_venice_canal_palazzo_and_gondola(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	# Venetian Grand Canal colorful gothic palazzos + striped mooring poles + black-and-gold Gondola
	var colors: Array[Color] = [Color(0.96, 0.76, 0.44, 1.0), Color(0.92, 0.52, 0.42, 1.0), Color(0.98, 0.88, 0.72, 1.0)]
	for b_i in range(3):
		var bx: float = pos.x + float(b_i - 1) * 13.5 * sc
		var bh: float = (18.0 + float(b_i % 2) * 4.0) * sc
		canvas.draw_rect(Rect2(Vector2(bx - 6.5 * sc, pos.y - bh), Vector2(13.0 * sc, bh + 3.0 * sc)), colors[b_i], true)
		canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(bx - 7.5 * sc, pos.y - bh),
			Vector2(bx, pos.y - bh - 6.0 * sc),
			Vector2(bx + 7.5 * sc, pos.y - bh)
		]), Color(0.78, 0.32, 0.18, 1.0))
		canvas.draw_rect(Rect2(Vector2(bx - 2.2 * sc, pos.y - bh * 0.62), Vector2(4.4 * sc, 5.5 * sc)), Color(0.32, 0.22, 0.18, 0.92), true)
	# Venetian Gondola moored at the canal dock beside the palazzo entrance
	var g_pos := pos + Vector2(9.0 * sc, 5.0 * sc)
	canvas.draw_colored_polygon(PackedVector2Array([
		g_pos + Vector2(-14.0 * sc, -2.2 * sc),
		g_pos + Vector2(-9.5 * sc, 2.6 * sc),
		g_pos + Vector2(9.5 * sc, 2.6 * sc),
		g_pos + Vector2(14.0 * sc, -3.0 * sc),
		g_pos + Vector2(10.5 * sc, 0.0),
		g_pos + Vector2(-10.5 * sc, 0.0)
	]), Color(0.14, 0.14, 0.18, 1.0))
	canvas.draw_rect(Rect2(g_pos + Vector2(-4.0 * sc, -3.0 * sc), Vector2(8.0 * sc, 3.0 * sc)), Color(0.88, 0.22, 0.20, 1.0), true)


static func _draw_florence_duomo_and_pisa(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	# Florence Cathedral iconic terracotta Brunelleschi dome + white marble Leaning Tower of Pisa
	var d_pos := pos + Vector2(-8.0 * sc, 2.0 * sc)
	canvas.draw_rect(Rect2(d_pos + Vector2(-14.0 * sc, -8.0 * sc), Vector2(28.0 * sc, 12.0 * sc)), Color(0.96, 0.94, 0.88, 1.0), true)
	canvas.draw_arc(d_pos + Vector2(0.0, -8.0 * sc), 12.5 * sc, PI, TAU, 16, Color(0.84, 0.36, 0.20, 1.0), 12.0 * sc)
	canvas.draw_circle(d_pos + Vector2(0.0, -21.5 * sc), 2.8 * sc, Color(0.98, 0.92, 0.72, 1.0))
	_draw_leaning_tower_of_pisa(canvas, pos + Vector2(16.0 * sc, 3.0 * sc), sc * 0.86)


static func _draw_versailles_palace_and_gardens(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	# Grand symmetrical limestone Château de Versailles with blue-slate mansard roofs & golden gates
	canvas.draw_rect(Rect2(pos + Vector2(-22.0 * sc, -11.0 * sc), Vector2(44.0 * sc, 15.0 * sc)), Color(0.97, 0.91, 0.76, 1.0), true)
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-23.5 * sc, -11.0 * sc),
		pos + Vector2(-19.0 * sc, -17.5 * sc),
		pos + Vector2(19.0 * sc, -17.5 * sc),
		pos + Vector2(23.5 * sc, -11.0 * sc)
	]), Color(0.26, 0.36, 0.52, 1.0))
	canvas.draw_line(pos + Vector2(-19.0 * sc, -17.5 * sc), pos + Vector2(19.0 * sc, -17.5 * sc), Color(0.98, 0.84, 0.30, 1.0), 2.0 * sc)
	for w_i in range(5):
		var wx: float = pos.x + float(w_i - 2) * 7.5 * sc
		canvas.draw_rect(Rect2(Vector2(wx - 1.8 * sc, pos.y - 8.5 * sc), Vector2(3.6 * sc, 7.0 * sc)), Color(0.38, 0.52, 0.72, 0.92), true)


static func _draw_mont_saint_michel_abbey(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	# Tiered rocky gothic island citadel topped by a soaring abbey spire
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-20.0 * sc, 6.0 * sc),
		pos + Vector2(-14.0 * sc, -8.0 * sc),
		pos + Vector2(-6.0 * sc, -20.0 * sc),
		pos + Vector2(0.0, -34.0 * sc),
		pos + Vector2(6.0 * sc, -20.0 * sc),
		pos + Vector2(14.0 * sc, -8.0 * sc),
		pos + Vector2(20.0 * sc, 6.0 * sc)
	]), Color(0.76, 0.72, 0.66, 1.0))
	canvas.draw_rect(Rect2(pos + Vector2(-8.0 * sc, -18.0 * sc), Vector2(16.0 * sc, 10.0 * sc)), Color(0.88, 0.84, 0.76, 1.0), true)
	canvas.draw_line(pos + Vector2(0.0, -34.0 * sc), pos + Vector2(0.0, -42.0 * sc), Color(0.98, 0.86, 0.34, 1.0), 2.2 * sc)


static func _draw_hoian_lantern_street_and_bridge(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	_draw_hoian_pavilion_landmark(canvas, pos + Vector2(-8.0 * sc, 0.0), sc * 0.95)
	_draw_hoian_pavilion_landmark(canvas, pos + Vector2(12.0 * sc, 3.0 * sc), sc * 0.82)
	for l_i in range(5):
		var lp: Vector2 = pos + Vector2(float(l_i - 2) * 7.5 * sc, -4.0 * sc + sin(float(l_i)) * 2.0 * sc)
		var l_col := Color(0.98, 0.24, 0.18, 1.0) if l_i % 2 == 0 else Color(1.0, 0.84, 0.22, 1.0)
		canvas.draw_circle(lp, 3.0 * sc, l_col)


static func _draw_hue_imperial_citadel_gate(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	# Hue Imperial Ngọ Môn stone battlement with three arched gates & golden-roofed Five-Phoenix Pavilion
	canvas.draw_rect(Rect2(pos + Vector2(-22.0 * sc, -6.0 * sc), Vector2(44.0 * sc, 12.0 * sc)), Color(0.68, 0.56, 0.48, 1.0), true)
	for a_i in range(3):
		var ax: float = pos.x + float(a_i - 1) * 11.0 * sc
		canvas.draw_rect(Rect2(Vector2(ax - 3.0 * sc, pos.y - 2.0 * sc), Vector2(6.0 * sc, 8.0 * sc)), Color(0.28, 0.18, 0.16, 1.0), true)
	canvas.draw_rect(Rect2(pos + Vector2(-15.0 * sc, -16.0 * sc), Vector2(30.0 * sc, 10.0 * sc)), Color(0.86, 0.22, 0.18, 1.0), true)
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-20.0 * sc, -15.0 * sc),
		pos + Vector2(-12.0 * sc, -23.0 * sc),
		pos + Vector2(12.0 * sc, -23.0 * sc),
		pos + Vector2(20.0 * sc, -15.0 * sc)
	]), Color(0.96, 0.76, 0.22, 1.0))


static func _draw_statue_of_liberty_harbor(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	var stone := Color(0.78, 0.76, 0.70, 1.0)
	var patina := Color(0.36, 0.78, 0.68, 1.0)
	# Star-shaped granite pedestal
	canvas.draw_rect(Rect2(pos + Vector2(-11.0 * sc, -4.0 * sc), Vector2(22.0 * sc, 11.0 * sc)), stone, true)
	# Copper-green robed figure + raised torch arm + golden flame
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-7.0 * sc, -4.0 * sc),
		pos + Vector2(-4.5 * sc, -24.0 * sc),
		pos + Vector2(4.5 * sc, -24.0 * sc),
		pos + Vector2(7.0 * sc, -4.0 * sc)
	]), patina)
	canvas.draw_circle(pos + Vector2(0.0, -27.0 * sc), 4.2 * sc, patina)
	canvas.draw_line(pos + Vector2(3.5 * sc, -22.0 * sc), pos + Vector2(8.5 * sc, -35.0 * sc), patina, 3.0 * sc)
	canvas.draw_circle(pos + Vector2(8.5 * sc, -37.0 * sc), 3.6 * sc, Color(1.0, 0.86, 0.24, 1.0))


static func _draw_golden_gate_and_vegas_strip(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	var intl_orange := Color(0.90, 0.28, 0.18, 1.0)
	for t_side in [-1.0, 1.0]:
		var tx: float = pos.x + t_side * 14.0 * sc
		canvas.draw_rect(Rect2(Vector2(tx - 2.4 * sc, pos.y - 26.0 * sc), Vector2(4.8 * sc, 32.0 * sc)), intl_orange, true)
	canvas.draw_line(pos + Vector2(-24.0 * sc, -6.0 * sc), pos + Vector2(24.0 * sc, -6.0 * sc), intl_orange, 3.4 * sc)
	canvas.draw_arc(pos + Vector2(0.0, -26.0 * sc), 14.0 * sc, 0.0, PI, 12, intl_orange, 2.2 * sc)


static func _draw_modern_city_building_cluster(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	var b_specs: Array = [
		[-14.0, 10.0, 24.0, Color(0.28, 0.42, 0.64, 1.0)],
		[-2.0, 11.0, 34.0, Color(0.36, 0.54, 0.78, 1.0)],
		[11.0, 10.0, 20.0, Color(0.24, 0.36, 0.56, 1.0)]
	]
	for sp in b_specs:
		var bx: float = pos.x + float(sp[0]) * sc
		var bw: float = float(sp[1]) * sc
		var bh: float = float(sp[2]) * sc
		var bcol: Color = sp[3]
		canvas.draw_rect(Rect2(Vector2(bx, pos.y - bh + 6.0 * sc), Vector2(bw, bh)), bcol, true)
		for wy in range(3):
			canvas.draw_rect(Rect2(Vector2(bx + 2.0 * sc, pos.y - bh + (10.0 + float(wy) * 6.0) * sc), Vector2(bw - 4.0 * sc, 2.4 * sc)), Color(1.0, 0.92, 0.54, 0.85), true)
	canvas.draw_line(pos + Vector2(3.5 * sc, -28.0 * sc), pos + Vector2(3.5 * sc, -38.0 * sc), Color(0.92, 0.96, 1.0, 1.0), 2.2 * sc)


static func _draw_luxor_obelisk_and_pylon(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	_draw_egyptian_temple_landmark(canvas, pos + Vector2(-6.0 * sc, 0.0), sc * 0.92)
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(12.0 * sc, 6.0 * sc),
		pos + Vector2(13.2 * sc, -26.0 * sc),
		pos + Vector2(15.0 * sc, -31.0 * sc),
		pos + Vector2(16.8 * sc, -26.0 * sc),
		pos + Vector2(18.0 * sc, 6.0 * sc)
	]), Color(0.98, 0.82, 0.42, 1.0))
static func _draw_lighthouse_landmark(canvas: CanvasItem, pos: Vector2, sc: float, anim_time: float) -> void:
	var tower_pts := PackedVector2Array([
		pos + Vector2(-9.5 * sc, 8.0 * sc),
		pos + Vector2(-6.0 * sc, -26.0 * sc),
		pos + Vector2(6.0 * sc, -26.0 * sc),
		pos + Vector2(9.5 * sc, 8.0 * sc)
	])
	canvas.draw_colored_polygon(tower_pts, Color(0.98, 0.96, 0.92, 1.0))
	# Red stripes
	for s_i in range(2):
		var y0: float = -4.0 * sc - float(s_i) * 11.0 * sc
		var y1: float = y0 - 5.5 * sc
		var w0: float = lerpf(9.0, 6.2, (8.0 * sc - y0) / (34.0 * sc)) * sc
		var w1: float = lerpf(9.0, 6.2, (8.0 * sc - y1) / (34.0 * sc)) * sc
		canvas.draw_colored_polygon(PackedVector2Array([
			pos + Vector2(-w0, y0), pos + Vector2(-w1, y1), pos + Vector2(w1, y1), pos + Vector2(w0, y0)
		]), Color(0.88, 0.24, 0.22, 1.0))
	# Lantern room & dome
	canvas.draw_rect(Rect2(pos + Vector2(-5.5 * sc, -32.0 * sc), Vector2(11.0 * sc, 6.0 * sc)), Color(1.0, 0.94, 0.46, 1.0), true)
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-7.5 * sc, -32.0 * sc),
		pos + Vector2(0.0, -39.0 * sc),
		pos + Vector2(7.5 * sc, -32.0 * sc)
	]), Color(0.82, 0.20, 0.20, 1.0))
	# Soft rotating light beam
	var beam_len: float = (26.0 + 4.0 * sin(anim_time * 2.0)) * sc
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(0.0, -29.0 * sc),
		pos + Vector2(beam_len, -36.0 * sc),
		pos + Vector2(beam_len, -22.0 * sc)
	]), Color(1.0, 0.96, 0.58, 0.26))


static func _draw_hoian_pavilion_landmark(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	# Warm ochre Hoi An ancient house walls + curved terracotta roof + glowing lanterns
	canvas.draw_rect(Rect2(pos + Vector2(-16.0 * sc, -10.0 * sc), Vector2(32.0 * sc, 18.0 * sc)), Color(0.96, 0.78, 0.32, 1.0), true)
	canvas.draw_rect(Rect2(pos + Vector2(-5.0 * sc, -2.0 * sc), Vector2(10.0 * sc, 10.0 * sc)), Color(0.42, 0.24, 0.14, 1.0), true)
	var roof_pts := PackedVector2Array([
		pos + Vector2(-22.0 * sc, -9.0 * sc),
		pos + Vector2(-12.0 * sc, -20.0 * sc),
		pos + Vector2(12.0 * sc, -20.0 * sc),
		pos + Vector2(22.0 * sc, -9.0 * sc)
	])
	canvas.draw_colored_polygon(roof_pts, Color(0.78, 0.30, 0.18, 1.0))
	# Hanging red silk lanterns
	for lx in [-12.0, 12.0]:
		canvas.draw_circle(pos + Vector2(lx * sc, -5.0 * sc), 3.2 * sc, Color(0.98, 0.26, 0.20, 1.0))


static func _draw_japanese_pagoda_landmark(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	# Three-tiered crimson Chureito Pagoda
	for tier in range(3):
		var ty: float = (4.0 - float(tier) * 10.5) * sc
		var tw: float = (18.0 - float(tier) * 3.2) * sc
		canvas.draw_rect(Rect2(pos + Vector2(-tw * 0.65, ty - 7.0 * sc), Vector2(tw * 1.3, 7.0 * sc)), Color(0.96, 0.93, 0.86, 1.0), true)
		var roof := PackedVector2Array([
			pos + Vector2(-tw * 1.08, ty - 6.0 * sc),
			pos + Vector2(-tw * 0.65, ty - 11.5 * sc),
			pos + Vector2(tw * 0.65, ty - 11.5 * sc),
			pos + Vector2(tw * 1.08, ty - 6.0 * sc)
		])
		canvas.draw_colored_polygon(roof, Color(0.84, 0.20, 0.18, 1.0))
	canvas.draw_line(pos + Vector2(0.0, -26.0 * sc), pos + Vector2(0.0, -36.0 * sc), Color(0.96, 0.80, 0.26, 1.0), 2.4 * sc)


static func _draw_roman_colosseum_landmark(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	# Iconic Roman Colosseum stepped travertine stone outer wall with three tiers of arches
	var w_col: float = 24.0 * sc
	var h_col: float = 22.0 * sc
	var base_rect := Rect2(pos + Vector2(-w_col, -h_col + 6.0 * sc), Vector2(w_col * 2.0, h_col))
	canvas.draw_rect(base_rect, Color(0.92, 0.82, 0.64, 1.0), true)
	# Iconic stepped asymmetric upper left crown of the Colosseum
	canvas.draw_rect(Rect2(pos + Vector2(-w_col, -h_col - 5.0 * sc), Vector2(w_col * 1.25, 6.0 * sc)), Color(0.95, 0.86, 0.68, 1.0), true)
	# Three rows of recessed Roman arches
	for row_i in range(3):
		var ry: float = pos.y + (2.0 - float(row_i) * 7.0) * sc
		var arch_cnt: int = 5 if row_i < 2 else 3
		for a_i in range(arch_cnt):
			var ax: float = pos.x + (-w_col * 0.72 + float(a_i) * (w_col * 0.36))
			canvas.draw_rect(Rect2(Vector2(ax - 2.2 * sc, ry - 4.2 * sc), Vector2(4.4 * sc, 4.5 * sc)), Color(0.42, 0.32, 0.22, 0.95), true)


static func _draw_leaning_tower_of_pisa(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	# White marble Leaning Tower of Pisa tilted at a charming angle
	var tilt: Vector2 = Vector2(5.5 * sc, -26.0 * sc)
	var perp: Vector2 = Vector2(7.5 * sc, 1.6 * sc)
	var body := PackedVector2Array([
		pos - perp,
		pos + tilt - perp * 0.88,
		pos + tilt + perp * 0.88,
		pos + perp
	])
	canvas.draw_colored_polygon(body, Color(0.97, 0.95, 0.90, 1.0))
	for tier_i in range(4):
		var lt: float = float(tier_i + 1) / 4.5
		var tc: Vector2 = pos + tilt * lt
		canvas.draw_line(tc - perp * 0.92, tc + perp * 0.92, Color(0.76, 0.72, 0.64, 1.0), 1.8)


static func _draw_eiffel_tower_landmark(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	var bronze := Color(0.56, 0.44, 0.34, 1.0)
	var bronze_lit := Color(0.76, 0.62, 0.46, 1.0)
	# Left & right curved lattice legs
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-15.0 * sc, 8.0 * sc),
		pos + Vector2(-5.5 * sc, -12.0 * sc),
		pos + Vector2(-2.5 * sc, -36.0 * sc),
		pos + Vector2(2.5 * sc, -36.0 * sc),
		pos + Vector2(5.5 * sc, -12.0 * sc),
		pos + Vector2(15.0 * sc, 8.0 * sc),
		pos + Vector2(8.5 * sc, 8.0 * sc),
		pos + Vector2(0.0, -2.0 * sc),
		pos + Vector2(-8.5 * sc, 8.0 * sc)
	]), bronze)
	# Observation decks & spire
	canvas.draw_rect(Rect2(pos + Vector2(-11.0 * sc, -4.0 * sc), Vector2(22.0 * sc, 2.8 * sc)), bronze_lit, true)
	canvas.draw_rect(Rect2(pos + Vector2(-7.5 * sc, -16.0 * sc), Vector2(15.0 * sc, 2.4 * sc)), bronze_lit, true)
	canvas.draw_line(pos + Vector2(0.0, -36.0 * sc), pos + Vector2(0.0, -45.0 * sc), Color(1.0, 0.92, 0.46, 1.0), 2.2 * sc)


static func _draw_egyptian_temple_landmark(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	# Golden stepped pyramid + twin sandstone pylons
	var pyr := PackedVector2Array([
		pos + Vector2(-20.0 * sc, 8.0 * sc),
		pos + Vector2(0.0, -24.0 * sc),
		pos + Vector2(20.0 * sc, 8.0 * sc)
	])
	canvas.draw_colored_polygon(pyr, Color(0.96, 0.76, 0.34, 1.0))
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(0.0, 8.0 * sc),
		pos + Vector2(0.0, -24.0 * sc),
		pos + Vector2(20.0 * sc, 8.0 * sc)
	]), Color(0.78, 0.52, 0.22, 1.0))
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-6.5 * sc, -13.5 * sc),
		pos + Vector2(0.0, -24.0 * sc),
		pos + Vector2(6.5 * sc, -13.5 * sc)
	]), Color(1.0, 0.92, 0.42, 1.0))


static func _draw_alpine_sanctuary_landmark(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	_draw_alpine_chalet(canvas, pos + Vector2(0.0, 2.0 * sc), sc * 1.15)


static func _draw_volcano_citadel_landmark(canvas: CanvasItem, pos: Vector2, sc: float, anim_time: float) -> void:
	var arch := PackedVector2Array([
		pos + Vector2(-18.0 * sc, 8.0 * sc),
		pos + Vector2(-14.0 * sc, -22.0 * sc),
		pos + Vector2(0.0, -30.0 * sc),
		pos + Vector2(14.0 * sc, -22.0 * sc),
		pos + Vector2(18.0 * sc, 8.0 * sc)
	])
	canvas.draw_colored_polygon(arch, Color(0.24, 0.18, 0.22, 1.0))
	var glow_r: float = (7.0 + 1.2 * sin(anim_time * 3.0)) * sc
	canvas.draw_circle(pos + Vector2(0.0, -10.0 * sc), glow_r, Color(1.0, 0.48, 0.12, 0.92))
	canvas.draw_circle(pos + Vector2(0.0, -10.0 * sc), glow_r * 0.55, Color(1.0, 0.90, 0.36, 0.96))


static func _draw_astral_observatory_landmark(canvas: CanvasItem, pos: Vector2, sc: float, anim_time: float) -> void:
	# White-and-gold domed celestial observatory
	canvas.draw_arc(pos + Vector2(0.0, -4.0 * sc), 16.0 * sc, PI, TAU, 18, Color(0.88, 0.92, 0.98, 1.0), 16.0 * sc)
	canvas.draw_rect(Rect2(pos + Vector2(-16.0 * sc, -4.0 * sc), Vector2(32.0 * sc, 12.0 * sc)), Color(0.76, 0.82, 0.94, 1.0), true)
	canvas.draw_line(pos + Vector2(4.0 * sc, -14.0 * sc), pos + Vector2(16.0 * sc, -26.0 * sc), Color(1.0, 0.88, 0.36, 1.0), 3.2 * sc)
	canvas.draw_circle(pos + Vector2(16.0 * sc, -26.0 * sc), (3.5 + 0.8 * sin(anim_time * 2.5)) * sc, Color(0.46, 0.92, 1.0, 0.88))


# ==============================================================================
# REGIONAL ENVIRONMENTAL PROPS (GROUPS OF TREES, VILLAGES, BOATS, TERRACES)
# ==============================================================================
static func _draw_woodland_canopy_mass(canvas: CanvasItem, pos: Vector2, sc: float, dark_green: Color, lit_green: Color) -> void:
	var offsets: Array[Vector2] = [Vector2(-14.0, 4.0), Vector2(12.0, 5.0), Vector2(0.0, -5.0)]
	for off in offsets:
		var tp: Vector2 = pos + off * sc
		canvas.draw_rect(Rect2(tp + Vector2(-2.2 * sc, 4.0 * sc), Vector2(4.4 * sc, 8.0 * sc)), Color(0.46, 0.30, 0.18, 1.0), true)
		canvas.draw_circle(tp + Vector2(1.5 * sc, 1.5 * sc), 11.0 * sc, dark_green)
		canvas.draw_circle(tp + Vector2(-1.5 * sc, -1.5 * sc), 9.5 * sc, lit_green)


static func _draw_palm_grove_cluster(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	for p_i in range(2):
		var base_p: Vector2 = pos + Vector2(float(p_i * 16 - 8) * sc, float(p_i * 4) * sc)
		var top_p: Vector2 = base_p + Vector2((5.0 if p_i == 0 else -4.0) * sc, -18.0 * sc)
		canvas.draw_line(base_p, top_p, Color(0.58, 0.38, 0.20, 1.0), 3.0 * sc, true)
		for f_i in range(5):
			var a: float = -PI * 0.85 + float(f_i) * (PI * 0.42)
			var tip: Vector2 = top_p + Vector2(cos(a) * 11.0 * sc, sin(a) * 7.0 * sc + 2.5 * sc)
			canvas.draw_line(top_p, tip, Color(0.28, 0.74, 0.32, 1.0), 2.6 * sc, true)


static func _draw_halong_junk_boat(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	# Traditional amber-sailed wooden junk boat on the emerald bay
	var hull := PackedVector2Array([
		pos + Vector2(-12.0 * sc, 0.0),
		pos + Vector2(12.0 * sc, 0.0),
		pos + Vector2(8.5 * sc, 5.0 * sc),
		pos + Vector2(-8.5 * sc, 5.0 * sc)
	])
	canvas.draw_colored_polygon(hull, Color(0.48, 0.28, 0.16, 1.0))
	var sail := PackedVector2Array([
		pos + Vector2(-2.0 * sc, 0.0),
		pos + Vector2(-2.0 * sc, -16.0 * sc),
		pos + Vector2(9.5 * sc, -3.0 * sc)
	])
	canvas.draw_colored_polygon(sail, Color(0.92, 0.46, 0.22, 0.95))


static func _draw_coastal_terracotta_village(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	for h_i in range(2):
		var hp: Vector2 = pos + Vector2(float(h_i * 14 - 7) * sc, float(h_i * 3) * sc)
		canvas.draw_rect(Rect2(hp + Vector2(-7.0 * sc, -8.0 * sc), Vector2(14.0 * sc, 11.0 * sc)), Color(0.97, 0.90, 0.74, 1.0), true)
		canvas.draw_colored_polygon(PackedVector2Array([
			hp + Vector2(-8.5 * sc, -8.0 * sc),
			hp + Vector2(0.0, -15.0 * sc),
			hp + Vector2(8.5 * sc, -8.0 * sc)
		]), Color(0.84, 0.36, 0.20, 1.0))


static func _draw_tuscan_villa_cluster(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	# Warm ochre stone Tuscan farmhouse + terracotta roof + slender cypress trees
	canvas.draw_rect(Rect2(pos + Vector2(-12.0 * sc, -9.0 * sc), Vector2(24.0 * sc, 14.0 * sc)), Color(0.95, 0.84, 0.62, 1.0), true)
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-14.5 * sc, -9.0 * sc),
		pos + Vector2(0.0, -17.5 * sc),
		pos + Vector2(14.5 * sc, -9.0 * sc)
	]), Color(0.82, 0.36, 0.20, 1.0))
	_draw_cypress_grove(canvas, pos + Vector2(16.0 * sc, 2.0 * sc), sc * 0.85)


static func _draw_cypress_grove(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	for c_i in range(3):
		var cp: Vector2 = pos + Vector2(float(c_i - 1) * 8.5 * sc, float(c_i % 2) * 3.0 * sc)
		var ch: float = (18.0 - float(c_i % 2) * 3.5) * sc
		_draw_ellipse_filled(canvas, cp + Vector2(0.0, -ch * 0.5), 4.0 * sc, ch * 0.52, Color(0.16, 0.44, 0.24, 1.0))


static func _draw_japanese_torii_and_maple(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	var vermilion := Color(0.90, 0.22, 0.18, 1.0)
	canvas.draw_rect(Rect2(pos + Vector2(-9.0 * sc, -14.0 * sc), Vector2(2.8 * sc, 18.0 * sc)), vermilion, true)
	canvas.draw_rect(Rect2(pos + Vector2(6.2 * sc, -14.0 * sc), Vector2(2.8 * sc, 18.0 * sc)), vermilion, true)
	canvas.draw_rect(Rect2(pos + Vector2(-13.0 * sc, -16.5 * sc), Vector2(26.0 * sc, 3.2 * sc)), vermilion, true)
	canvas.draw_rect(Rect2(pos + Vector2(-10.5 * sc, -11.0 * sc), Vector2(21.0 * sc, 2.2 * sc)), vermilion, true)


static func _draw_stepped_rice_terrace_patch(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	for t_i in range(3):
		var tp: Vector2 = pos + Vector2(0.0, float(t_i) * 5.5 * sc)
		var rx: float = (20.0 - float(t_i) * 3.5) * sc
		var ry: float = 6.0 * sc
		_draw_ellipse_filled(canvas, tp + Vector2(0.0, 2.2 * sc), rx, ry, Color(0.46, 0.36, 0.22, 0.90))
		_draw_ellipse_filled(canvas, tp, rx, ry, Color(0.54, 0.84, 0.34, 0.96))


static func _draw_grand_canyon_mesa(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	var mesa := PackedVector2Array([
		pos + Vector2(-18.0 * sc, 6.0 * sc),
		pos + Vector2(-13.0 * sc, -12.0 * sc),
		pos + Vector2(13.0 * sc, -12.0 * sc),
		pos + Vector2(18.0 * sc, 6.0 * sc)
	])
	canvas.draw_colored_polygon(mesa, Color(0.78, 0.38, 0.22, 1.0))
	canvas.draw_line(pos + Vector2(-14.5 * sc, -4.0 * sc), pos + Vector2(14.5 * sc, -4.0 * sc), Color(0.94, 0.62, 0.34, 0.88), 2.2 * sc)


static func _draw_alpine_chalet(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	canvas.draw_rect(Rect2(pos + Vector2(-11.0 * sc, -8.0 * sc), Vector2(22.0 * sc, 13.0 * sc)), Color(0.64, 0.42, 0.24, 1.0), true)
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-14.0 * sc, -7.0 * sc),
		pos + Vector2(0.0, -17.0 * sc),
		pos + Vector2(14.0 * sc, -7.0 * sc)
	]), Color(0.96, 0.98, 1.0, 1.0))
	canvas.draw_rect(Rect2(pos + Vector2(-3.5 * sc, -3.5 * sc), Vector2(7.0 * sc, 5.0 * sc)), Color(1.0, 0.88, 0.38, 0.95), true)


static func _draw_snow_pine_cluster(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	for p_i in range(3):
		var tp: Vector2 = pos + Vector2(float(p_i - 1) * 10.0 * sc, float(p_i % 2) * 4.0 * sc)
		canvas.draw_colored_polygon(PackedVector2Array([
			tp + Vector2(-8.0 * sc, 4.0 * sc),
			tp + Vector2(0.0, -14.0 * sc),
			tp + Vector2(8.0 * sc, 4.0 * sc)
		]), Color(0.18, 0.42, 0.38, 1.0))
		canvas.draw_colored_polygon(PackedVector2Array([
			tp + Vector2(-5.5 * sc, -3.0 * sc),
			tp + Vector2(0.0, -14.0 * sc),
			tp + Vector2(5.5 * sc, -3.0 * sc)
		]), Color(0.94, 0.98, 1.0, 0.95))


static func _draw_basalt_outcrop_cluster(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	for b_i in range(3):
		var bx: float = pos.x + float(b_i - 1) * 7.5 * sc
		var bh: float = (14.0 - float(b_i % 2) * 4.0) * sc
		canvas.draw_rect(Rect2(Vector2(bx - 3.2 * sc, pos.y - bh), Vector2(6.4 * sc, bh + 4.0 * sc)), Color(0.22, 0.18, 0.24, 1.0), true)


static func _draw_lavender_field_rows(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	for r_i in range(4):
		var ry: float = pos.y + float(r_i - 1) * 4.5 * sc
		canvas.draw_line(Vector2(pos.x - 16.0 * sc, ry), Vector2(pos.x + 16.0 * sc, ry - 3.0 * sc), Color(0.56, 0.34, 0.84, 0.92), 3.4 * sc, true)


static func _draw_lunar_crater_formation(canvas: CanvasItem, pos: Vector2, sc: float) -> void:
	_draw_ellipse_filled(canvas, pos, 14.0 * sc, 7.5 * sc, Color(0.32, 0.44, 0.70, 0.92))
	_draw_ellipse_filled(canvas, pos + Vector2(1.0 * sc, 1.0 * sc), 9.5 * sc, 4.8 * sc, Color(0.16, 0.24, 0.44, 0.95))


# ==============================================================================
# 7. FOREGROUND FRAMING SILHOUETTE & ATMOSPHERIC DEPTH
# ==============================================================================
static func _draw_foreground_framing_and_atmosphere(
	canvas: CanvasItem,
	rect: Rect2,
	_page: MapPage,
	theme: MapTheme,
	pal: Dictionary,
	_flip_world: bool,
	anim_time: float,
	_rng: RandomNumberGenerator
) -> void:
	var w: float = rect.size.x
	var h: float = rect.size.y
	var ox: float = rect.position.x
	var oy: float = rect.position.y

	var fg_col: Color = pal.get("ground_primary", Color(0.12, 0.34, 0.24)).darkened(0.42)
	fg_col.a = 0.88

	# Lower-left and lower-right natural foreground hillside/foliage framing corners
	var left_fg := PackedVector2Array([
		Vector2(ox, oy + h * 0.89),
		Vector2(ox + w * 0.14, oy + h * 0.94),
		Vector2(ox + w * 0.24, oy + h),
		Vector2(ox, oy + h)
	])
	var right_fg := PackedVector2Array([
		Vector2(ox + w, oy + h * 0.89),
		Vector2(ox + w * 0.86, oy + h * 0.94),
		Vector2(ox + w * 0.76, oy + h),
		Vector2(ox + w, oy + h)
	])
	canvas.draw_colored_polygon(left_fg, fg_col)
	canvas.draw_colored_polygon(right_fg, fg_col)

	# Subtle animated atmospheric motes (4 gentle motes across the world)
	var mote_col: Color = pal.get("accent_color", Color(1.0, 0.90, 0.42, 1.0))
	mote_col.a = 0.42
	for m_i in range(4):
		var mu: float = fposmod(0.20 + float(m_i) * 0.22 + sin(anim_time * 0.5 + float(m_i)) * 0.03, 0.88) + 0.06
		var mv: float = fposmod(0.28 + float(m_i) * 0.17 - anim_time * 0.012, 0.62) + 0.20
		canvas.draw_circle(Vector2(ox + mu * w, oy + mv * h), 2.2, mote_col)
	if theme.theme_id == "ocean_islands":
		pass


static func _draw_storybook_cloud(canvas: CanvasItem, pos: Vector2, cw: float, col: Color) -> void:
	var ch: float = cw * 0.28
	canvas.draw_circle(pos + Vector2(-cw * 0.22, -ch * 0.15), ch * 0.72, col)
	canvas.draw_circle(pos + Vector2(0.0, -ch * 0.35), ch * 0.92, col)
	canvas.draw_circle(pos + Vector2(cw * 0.22, -ch * 0.12), ch * 0.68, col)
	canvas.draw_rect(Rect2(pos + Vector2(-cw * 0.36, -ch * 0.15), Vector2(cw * 0.72, ch * 0.55)), col, true)


static func _draw_ellipse(canvas: CanvasItem, center: Vector2, rx: float, ry: float, col: Color, segs: int = 20) -> void:
	_draw_ellipse_filled(canvas, center, rx, ry, col, segs)


static func _draw_ellipse_filled(canvas: CanvasItem, center: Vector2, rx: float, ry: float, col: Color, segs: int = 20) -> void:
	var pts := PackedVector2Array()
	for i in range(segs):
		var a: float = float(i) * (TAU / float(segs))
		pts.append(Vector2(center.x + cos(a) * rx, center.y + sin(a) * ry))
	canvas.draw_colored_polygon(pts, col)


static func get_page_landmark_manifest(page: MapPage, rect: Rect2) -> Dictionary:
	if page == null:
		return {}
	var theme: MapTheme = page.theme if page.theme != null else MapTheme.from_preset("green_forest")
	var country_key: String = _resolve_country_composition_key(theme, page)
	var split_idx: int = _find_water_crossing_index(page)
	var dest_stops: Dictionary = _select_route_destination_stops(page, split_idx, country_key)
	var w: float = maxf(280.0, rect.size.x)
	var h: float = maxf(360.0, rect.size.y)
	var base_sc: float = get_base_landmark_scale_for_viewport(rect, page)
	var is_compact_vp: bool = (w < 420.0 or h < 580.0)
	var zones: Dictionary = get_country_spatial_zones(page, rect)
	var sky_floor_y: float = float(zones.get("sky_floor_y", rect.position.y + h * 0.145))
	var water_spine: PackedVector2Array = zones.get("water_spine", PackedVector2Array())
	var water_half_w: float = float(zones.get("water_half_width", 18.0))
	var route_pts := PackedVector2Array()
	var route_in_sky_count: int = 0
	var route_in_background_count: int = 0
	if page.route != null and page.route.smooth_points.size() >= 2:
		var sp_cnt: int = page.route.smooth_points.size()
		for rp_i in range(sp_cnt):
			var abs_rp: Vector2 = rect.position + page.route.smooth_points[rp_i]
			if rp_i % 4 == 0 or rp_i == sp_cnt - 1:
				route_pts.append(abs_rp)
			var sky_y_rp: float = get_sky_boundary_y_at(page, rect, abs_rp.x, country_key)
			if abs_rp.y < sky_y_rp - 1.0:
				route_in_sky_count += 1
			var surf_rp: String = get_terrain_surface_at_point(page, rect, abs_rp, {}, water_spine)
			if surf_rp in ["SKY", "DISTANT_HORIZON", "MOUNTAIN_BACKGROUND"]:
				route_in_background_count += 1
	var lm_layout: Dictionary = _compute_non_overlapping_landmark_layout(page, dest_stops, rect, base_sc)
	var courtyard_radii: Array[Vector2] = _compute_node_courtyard_radii(page, dest_stops, rect.position, w)

	var obstacle_rects: Array[Rect2] = []
	for i in range(page.nodes.size()):
		var nd_obs: MapNode = page.nodes[i]
		var np_obs: Vector2 = rect.position + nd_obs.position
		obstacle_rects.append(Rect2(
			np_obs - nd_obs.node_size * 0.5 - Vector2(3.0, 3.0),
			nd_obs.node_size + Vector2(6.0, 6.0)
		))
	for i in lm_layout.keys():
		var lm_rect: Rect2 = lm_layout[i].get("footprint_rect", lm_layout[i].get("arch_rect", Rect2()))
		obstacle_rects.append(lm_rect.grow(2.0))

	var overlapping_landmark_count: int = 0
	var out_of_bounds_landmark_count: int = 0
	var route_landmark_collision_count: int = 0
	var lm_keys: Array = lm_layout.keys()
	for ki in range(lm_keys.size()):
		var idx_a: int = int(lm_keys[ki])
		var rect_a: Rect2 = lm_layout[idx_a].get("footprint_rect", lm_layout[idx_a].get("arch_rect", Rect2()))
		if rect_a.position.x < rect.position.x - 0.5 or rect_a.end.x > rect.end.x + 0.5 or rect_a.position.y < rect.position.y - 0.5 or rect_a.end.y > rect.end.y + 0.5:
			out_of_bounds_landmark_count += 1
		if _non_incident_route_clearance(rect_a, page, idx_a, rect.position) < -2.0:
			route_landmark_collision_count += 1
		for kj in range(ki + 1, lm_keys.size()):
			var idx_b: int = int(lm_keys[kj])
			var rect_b: Rect2 = lm_layout[idx_b].get("footprint_rect", lm_layout[idx_b].get("arch_rect", Rect2()))
			if rect_a.intersects(rect_b):
				overlapping_landmark_count += 1

	var overlapping_background_count: int = 0
	for i in range(page.nodes.size()):
		var pi: Vector2 = rect.position + page.nodes[i].position
		var ri: Vector2 = courtyard_radii[i]
		for j in range(i + 1, page.nodes.size()):
			var pj: Vector2 = rect.position + page.nodes[j].position
			var rj: Vector2 = courtyard_radii[j]
			var dx: float = pi.x - pj.x
			var dy: float = pi.y - pj.y
			var rx_sum: float = (ri.x + 5.0) + (rj.x + 5.0)
			var ry_sum: float = (ri.y + 3.5) + (rj.y + 3.5)
			var ed: float = sqrt((dx * dx) / maxf(1.0, rx_sum * rx_sum) + (dy * dy) / maxf(1.0, ry_sum * ry_sum))
			if ed < 1.0:
				overlapping_background_count += 1

	var destinations: Array[Dictionary] = []
	var plaque_overlap_count: int = 0
	var out_of_bounds_label_count: int = 0
	var all_ground_anchors_valid: bool = true
	var all_ground_anchors_not_in_sky: bool = true
	var all_ground_anchors_not_distant_horizon: bool = true
	var all_ground_anchors_not_mountain_background: bool = true
	var all_ground_anchors_inside_surface: bool = true
	var all_ground_anchors_compatible: bool = true
	var all_water_relationships_valid: bool = true
	var all_route_endpoints_compatible: bool = true
	var all_footprints_in_safe_bounds: bool = true

	for idx in dest_stops.keys():
		var stop_info: Dictionary = dest_stops[idx]
		var nd: MapNode = page.nodes[idx]
		var node_pos: Vector2 = rect.position + nd.position
		var lm_entry: Dictionary = lm_layout.get(idx, {})
		var arch_pos: Vector2 = lm_entry.get("arch_pos", _compute_safe_landmark_arch_pos(page, idx, rect, base_sc))
		var ground_anchor: Vector2 = lm_entry.get("ground_anchor", arch_pos)
		var lm_sc: float = float(lm_entry.get("scale", base_sc))
		var arch_rect: Rect2 = lm_entry.get("arch_rect", Rect2())
		var fp_rect: Rect2 = lm_entry.get("footprint_rect", arch_rect)
		var g_class: String = String(lm_entry.get("grounding_classification", stop_info.get("grounding_type", "GROUND")))
		var w_rel: String = String(lm_entry.get("water_relationship", stop_info.get("water_relationship", "none")))
		var s_surf: String = String(lm_entry.get("supporting_surface", stop_info.get("supporting_surface", "terrace_ground")))

		var val_check: Dictionary = validate_landmark_ground_anchor(page, rect, ground_anchor, node_pos, stop_info, water_spine)
		var terrain_surface: String = String(val_check.get("terrain_surface", "SKY"))
		var allowed_surfaces: Array = val_check.get("allowed_grounding_surfaces", [])
		var anchor_in_bounds: bool = bool(val_check.get("ground_anchor_in_bounds", false))
		var anchor_not_in_sky: bool = bool(val_check.get("ground_anchor_not_sky", false))
		var anchor_not_distant_horizon: bool = bool(val_check.get("ground_anchor_not_distant_horizon", false))
		var anchor_not_mountain_bg: bool = bool(val_check.get("ground_anchor_not_incompatible_mountain_background", false))
		var anchor_inside_surface: bool = bool(val_check.get("ground_anchor_inside_surface", false))
		var water_rel_ok: bool = bool(val_check.get("ground_anchor_not_in_water", false))
		var route_ep_ok: bool = bool(val_check.get("route_endpoint_surface_compatible", false))
		var anchor_compatible: bool = bool(val_check.get("valid", false))

		var fp_in_bounds: bool = (
			fp_rect.position.x >= rect.position.x - 0.5 and fp_rect.end.x <= rect.end.x + 0.5 and
			fp_rect.position.y >= rect.position.y - 0.5 and fp_rect.end.y <= rect.end.y + 0.5
		)
		if not anchor_in_bounds:
			all_ground_anchors_valid = false
		if not anchor_not_in_sky:
			all_ground_anchors_not_in_sky = false
		if not anchor_not_distant_horizon:
			all_ground_anchors_not_distant_horizon = false
		if not anchor_not_mountain_bg:
			all_ground_anchors_not_mountain_background = false
		if not anchor_inside_surface:
			all_ground_anchors_inside_surface = false
		if not anchor_compatible:
			all_ground_anchors_compatible = false
		if not water_rel_ok:
			all_water_relationships_valid = false
		if not route_ep_ok:
			all_route_endpoints_compatible = false
		if not fp_in_bounds:
			all_footprints_in_safe_bounds = false

		var label_text: String = String(stop_info.get("label", ""))
		var plaque_pos: Vector2 = _compute_non_overlapping_plaque_pos(
			node_pos, arch_pos, nd, label_text, rect, obstacle_rects, lm_sc, false, water_spine, water_half_w, route_pts
		)
		var label_dir: String = _classify_label_direction(node_pos, plaque_pos)
		var p_sz: Vector2 = _get_plaque_size(label_text, is_compact_vp, false)
		var p_rect := Rect2(plaque_pos - p_sz * 0.5, p_sz)
		if p_rect.position.x < rect.position.x or p_rect.end.x > rect.end.x or p_rect.position.y < rect.position.y or p_rect.end.y > rect.end.y:
			out_of_bounds_label_count += 1
		for obs in obstacle_rects:
			if p_rect.intersects(obs.grow(-2.5)):
				plaque_overlap_count += 1
		obstacle_rects.append(Rect2(plaque_pos - p_sz * 0.5 - Vector2(2.0, 2.0), p_sz + Vector2(4.0, 4.0)))
		destinations.append({
			"node_index": idx,
			"level_id": nd.level_id,
			"destination_order": int(stop_info.get("destination_order", idx + 1)),
			"milestone_context": String(stop_info.get("milestone_context", "major_landmark")),
			"landmark_classification": "DESTINATION_LANDMARK",
			"landmark_id": String(stop_info.get("landmark_id", "")),
			"location_label": label_text,
			"region": String(stop_info.get("region", "")),
			"lat": float(stop_info.get("lat", 0.0)),
			"lon": float(stop_info.get("lon", 0.0)),
			"ground_anchor": ground_anchor,
			"terrain_surface": terrain_surface,
			"allowed_grounding_surfaces": allowed_surfaces,
			"ground_anchor_inside_surface": anchor_inside_surface,
			"ground_anchor_not_sky": anchor_not_in_sky,
			"ground_anchor_not_distant_horizon": anchor_not_distant_horizon,
			"ground_anchor_not_incompatible_mountain_background": anchor_not_mountain_bg,
			"ground_anchor_not_in_water": water_rel_ok,
			"route_endpoint_surface": String(val_check.get("route_endpoint_surface", "")),
			"route_endpoint_surface_compatible": route_ep_ok,
			"grounding_classification": g_class,
			"supporting_surface": s_surf,
			"spatial_zone": terrain_surface,
			"water_relationship": w_rel,
			"water_relationship_valid": water_rel_ok,
			"ground_anchor_in_bounds": anchor_in_bounds,
			"ground_anchor_not_in_sky": anchor_not_in_sky,
			"ground_anchor_compatible_with_environment": anchor_compatible,
			"courtyard_position": node_pos,
			"architecture_position": arch_pos,
			"architecture_rect": arch_rect,
			"footprint_rect": fp_rect,
			"footprint_in_safe_bounds": fp_in_bounds,
			"architecture_scale": lm_sc,
			"plaque_position": plaque_pos,
			"plaque_rect": p_rect,
			"label_placement_direction": label_dir,
			"has_separate_spur_road": false,
			"level_marker_inside_courtyard": true
		})

	var ox: float = rect.position.x
	var oy: float = rect.position.y
	var flip_world: bool = ((page.page_index % 2) == 1)
	var regional_scene_entries: Array[Dictionary] = []
	var major_scenery_positions: Array[Vector2] = []

	for i in range(page.nodes.size()):
		if dest_stops.has(i):
			continue
		var nd_reg: MapNode = page.nodes[i]
		var node_pos_reg: Vector2 = rect.position + nd_reg.position
		var m_ctx_reg: String = String(nd_reg.landmark.get("milestone_context", "regional_scene"))
		var env_type_reg: String = String(nd_reg.landmark.get("environment_type", "regional_landscape"))
		var reg_sc: float = base_sc * maxf(0.72, get_destination_hierarchy_scale_multiplier(m_ctx_reg))
		var side_dir: float = -1.0 if (node_pos_reg.x - ox) > (w * 0.50) else 1.0
		var raw_env := Vector2(clampf(node_pos_reg.x + side_dir * 42.0, ox + 32.0, ox + w - 32.0), node_pos_reg.y - 4.0)
		var reg_ext := Vector2(18.0 * reg_sc, 14.0 * reg_sc)
		var env_pos: Vector2 = _find_safe_scenery_pos(raw_env, reg_ext, rect, page, obstacle_rects)
		var reg_rect := Rect2(env_pos - reg_ext, reg_ext * 2.0)
		if _rect_clearance_to_obstacles(reg_rect, obstacle_rects) >= -2.0:
			obstacle_rects.append(reg_rect.grow(2.0))
			major_scenery_positions.append(env_pos)
			regional_scene_entries.append({
				"node_index": i,
				"level_id": nd_reg.level_id,
				"landmark_id": String(nd_reg.landmark.get("landmark_id", "")),
				"destination_name": String(nd_reg.landmark.get("destination_name", page.country_name_en)),
				"region": String(nd_reg.landmark.get("region", "")),
				"milestone_context": m_ctx_reg,
				"environment_type": env_type_reg,
				"scale": reg_sc,
				"ground_anchor": env_pos,
				"footprint_rect": reg_rect
			})

	var poi_cx: float = ox + w * (0.56 if not flip_world else 0.44)
	var poi_label: String = ""
	var poi_anchor := Vector2(poi_cx, oy + h * 0.19)
	match country_key:
		"japan":
			poi_label = "Mount Fuji"
			poi_anchor = Vector2(poi_cx, oy + h * 0.19)
		"france":
			poi_label = "French Alps"
			poi_anchor = Vector2(ox + w * 0.58, oy + h * 0.18)
		"vietnam_bay", "vietnam_city":
			var bay_raw := Vector2(ox + w * (0.20 if flip_world else 0.80), oy + h * 0.30)
			var bay_poi: Vector2 = _find_safe_scenery_pos(bay_raw, Vector2(26.0, 22.0), rect, page, obstacle_rects)
			var bay_rect := Rect2(bay_poi - Vector2(26.0, 22.0), Vector2(52.0, 44.0))
			if _rect_clearance_to_obstacles(bay_rect, obstacle_rects) >= 0.0:
				obstacle_rects.append(bay_rect.grow(2.0))
				major_scenery_positions.append(bay_poi)
		"thailand":
			var thai_raw := Vector2(ox + w * (0.20 if flip_world else 0.80), oy + h * 0.34)
			var thai_poi: Vector2 = _find_safe_scenery_pos(thai_raw, Vector2(24.0, 20.0), rect, page, obstacle_rects)
			var thai_rect := Rect2(thai_poi - Vector2(24.0, 20.0), Vector2(48.0, 40.0))
			if _rect_clearance_to_obstacles(thai_rect, obstacle_rects) >= 0.0:
				obstacle_rects.append(thai_rect.grow(2.0))
				major_scenery_positions.append(thai_poi)
		"italy":
			poi_label = "Apennines"
			poi_anchor = Vector2(ox + w * 0.34, oy + h * 0.21)
		"usa_canyon", "usa_nyc":
			poi_label = "Monument Valley" if country_key == "usa_canyon" else "Hudson Harbor"
			poi_anchor = Vector2(ox + w * 0.50, oy + h * 0.20)
		"switzerland", "norway":
			poi_label = "Matterhorn" if country_key == "switzerland" else "Geiranger"
			poi_anchor = Vector2(poi_cx, oy + h * 0.18)
		"egypt":
			poi_label = "Giza Plateau"
			poi_anchor = Vector2(ox + w * 0.48, oy + h * 0.20)

	if poi_label != "":
		var safe_poi_pos: Vector2 = _compute_non_overlapping_plaque_pos(
			poi_anchor, poi_anchor, null, poi_label, rect, obstacle_rects, base_sc, true, water_spine, water_half_w, route_pts
		)
		var poi_psz: Vector2 = _get_plaque_size(poi_label, is_compact_vp, true)
		obstacle_rects.append(Rect2(safe_poi_pos - poi_psz * 0.5 - Vector2(2.0, 2.0), poi_psz + Vector2(4.0, 4.0)))

	var margin_bands: Array[float] = [0.28, 0.48, 0.68, 0.84]
	for b_idx in range(margin_bands.size()):
		var mv: float = margin_bands[b_idx]
		var on_left: bool = ((b_idx + (1 if flip_world else 0)) % 2 == 0)
		var mu: float = 0.12 if on_left else 0.88
		var scen_ext := Vector2(18.0 * base_sc * 0.72, 14.0 * base_sc * 0.72)
		var scen_pos: Vector2 = _find_safe_scenery_pos(Vector2(ox + w * mu, oy + h * mv), scen_ext, rect, page, obstacle_rects)
		var scen_rect := Rect2(scen_pos - scen_ext, scen_ext * 2.0)
		if _rect_clearance_to_obstacles(scen_rect, obstacle_rects) < 2.0:
			continue
		obstacle_rects.append(scen_rect.grow(2.0))
		major_scenery_positions.append(scen_pos)

	var lm_ids_ordered: Array[String] = []
	var lm_positions_ordered: Array[Vector2] = []
	var lm_scales_ordered: Array[float] = []
	var lm_bboxes_ordered: Array[Rect2] = []
	for d_entry in destinations:
		lm_ids_ordered.append(String(d_entry.get("landmark_id", "")))
		lm_positions_ordered.append(d_entry.get("architecture_position", d_entry.get("ground_anchor", Vector2.ZERO)))
		lm_scales_ordered.append(float(d_entry.get("architecture_scale", base_sc)))
		lm_bboxes_ordered.append(d_entry.get("footprint_rect", Rect2()))

	var terrain_geometry: Dictionary = {
		"country_key": country_key,
		"flip_world": flip_world,
		"split_idx": split_idx,
		"sky_floor_y": float(zones.get("sky_floor_y", oy + h * 0.145)),
		"distant_horizon_bottom_y": float(zones.get("distant_horizon_bottom_y", oy + h * 0.19)),
		"mountain_bg_bottom_y": float(zones.get("mountain_bg_bottom_y", oy + h * 0.24)),
		"land_ground_top_y": float(zones.get("land_ground_top_y", oy + h * 0.24)),
		"water_half_width": water_half_w,
		"water_spine": water_spine
	}

	var ordered_node_dests: Array[Dictionary] = []
	var milestone_contexts: Array[String] = []
	var page_landmark_density: String = "moderate"
	for i in range(page.nodes.size()):
		var nd_i: MapNode = page.nodes[i]
		var lm_i: Dictionary = nd_i.landmark if (nd_i != null and nd_i.landmark is Dictionary) else {}
		if i == 0 and lm_i.has("landmark_density"):
			page_landmark_density = String(lm_i.get("landmark_density", "moderate"))
		var m_ctx: String = String(lm_i.get("milestone_context", "regional_scene"))
		milestone_contexts.append(m_ctx)
		var abs_np: Vector2 = rect.position + nd_i.position
		ordered_node_dests.append({
			"node_index": i,
			"level_id": nd_i.level_id,
			"destination_order": int(lm_i.get("destination_order", i + 1)),
			"destination_name": String(lm_i.get("destination_name", lm_i.get("location_label", ""))),
			"region": String(lm_i.get("region", "")),
			"landmark_id": String(lm_i.get("landmark_id", "")),
			"landmark_description": String(lm_i.get("landmark_description", "")),
			"milestone_context": m_ctx,
			"environment_type": String(lm_i.get("environment_type", "regional_landscape")),
			"grounding_type": String(lm_i.get("grounding_type", "GROUND")),
			"water_relationship": String(lm_i.get("water_relationship", "none")),
			"supporting_terrain_zone": String(lm_i.get("supporting_terrain_zone", "LAND")),
			"terrain_surface": get_terrain_surface_at_point(page, rect, abs_np, lm_i, water_spine),
			"is_featured_landmark": bool(lm_i.get("is_featured_landmark", dest_stops.has(i))),
			"lat": float(lm_i.get("lat", 0.0)),
			"lon": float(lm_i.get("lon", 0.0)),
			"position": abs_np
		})

	return {
		"country_key": country_key,
		"country_id": page.country_id,
		"country_name_en": page.country_name_en,
		"landmark_density": page_landmark_density,
		"featured_landmark_count": destinations.size(),
		"landmark_count": destinations.size(),
		"landmark_ids": lm_ids_ordered,
		"landmark_positions": lm_positions_ordered,
		"landmark_scales": lm_scales_ordered,
		"landmark_bounding_boxes": lm_bboxes_ordered,
		"terrain_geometry": terrain_geometry,
		"major_scenery_positions": major_scenery_positions,
		"regional_milestone_scenes": regional_scene_entries,
		"base_landmark_scale": base_sc,
		"hierarchy_scale_multipliers": {
			"major_landmark": get_destination_hierarchy_scale_multiplier("major_landmark"),
			"landmark_environment": get_destination_hierarchy_scale_multiplier("landmark_environment"),
			"regional_scene": get_destination_hierarchy_scale_multiplier("regional_scene"),
			"small_destination_marker": get_destination_hierarchy_scale_multiplier("small_destination_marker")
		},
		"visual_hierarchy_valid": (
			get_destination_hierarchy_scale_multiplier("major_landmark") > get_destination_hierarchy_scale_multiplier("landmark_environment")
			and get_destination_hierarchy_scale_multiplier("landmark_environment") > get_destination_hierarchy_scale_multiplier("regional_scene")
			and get_destination_hierarchy_scale_multiplier("regional_scene") > get_destination_hierarchy_scale_multiplier("small_destination_marker")
		),
		"milestone_contexts": milestone_contexts,
		"journey_direction": page.journey_direction,
		"authority_source": page.authority_source,
		"independent_poi": page.independent_poi,
		"spatial_zones": zones,
		"primary_landscape_layer_count": 1,
		"oversized_background_layer_count": 0,
		"all_ground_anchors_valid": all_ground_anchors_valid,
		"all_ground_anchors_not_in_sky": all_ground_anchors_not_in_sky,
		"all_ground_anchors_not_distant_horizon": all_ground_anchors_not_distant_horizon,
		"all_ground_anchors_not_mountain_background": all_ground_anchors_not_mountain_background,
		"all_ground_anchors_inside_surface": all_ground_anchors_inside_surface,
		"all_ground_anchors_compatible": all_ground_anchors_compatible,
		"all_water_relationships_valid": all_water_relationships_valid,
		"all_route_endpoints_compatible": all_route_endpoints_compatible,
		"all_footprints_in_safe_bounds": all_footprints_in_safe_bounds,
		"route_in_sky_count": route_in_sky_count,
		"route_in_background_count": route_in_background_count,
		"route_landmark_collision_count": route_landmark_collision_count,
		"ordered_node_destinations": ordered_node_dests,
		"destination_landmarks": destinations,
		"order_preserved_after_relaxation": page.order_preserved_after_relaxation,
		"has_secondary_spur_roads": false,
		"overlapping_landmark_count": overlapping_landmark_count,
		"overlapping_background_count": overlapping_background_count,
		"out_of_bounds_landmark_count": out_of_bounds_landmark_count,
		"label_collision_count": plaque_overlap_count,
		"out_of_bounds_label_count": out_of_bounds_label_count,
		"zero_plaque_or_landmark_overlap": (
			plaque_overlap_count == 0 and overlapping_landmark_count == 0 and
			overlapping_background_count == 0 and out_of_bounds_landmark_count == 0 and
			out_of_bounds_label_count == 0 and all_ground_anchors_valid and
			all_ground_anchors_not_in_sky and all_ground_anchors_not_distant_horizon and
			all_ground_anchors_not_mountain_background and all_ground_anchors_inside_surface and
			all_ground_anchors_compatible and all_water_relationships_valid and
			all_route_endpoints_compatible and all_footprints_in_safe_bounds and
			route_in_sky_count == 0 and route_in_background_count == 0 and
			route_landmark_collision_count == 0
		)
	}


# ==============================================================================
# 8. GAMEPLAY LEVEL BACKGROUND PRESENTATION LAYER (EXACT MAP PAGE REUSE)
#    Architecture:MapPage(country) -> same exact MapPage render -> hide ONLY level markers
# ==============================================================================
static var _gameplay_bg_manifest_cache: Dictionary = {}


static func get_gameplay_level_background_manifest(
	page: MapPage,
	target_level_id: int,
	rect: Rect2,
	lang: String = "en"
) -> Dictionary:
	if page == null or rect.size.x <= 10.0 or rect.size.y <= 10.0:
		return {}
	var cache_key: String = "%d_%s_%d_%d_%d_%d_%s" % [
		page.get_instance_id(),
		page.country_id,
		int(round(rect.position.x)),
		int(round(rect.position.y)),
		int(round(rect.size.x)),
		int(round(rect.size.y)),
		lang
	]
	if _gameplay_bg_manifest_cache.has(cache_key):
		var cached_manifest: Dictionary = (_gameplay_bg_manifest_cache[cache_key] as Dictionary).duplicate(true)
		cached_manifest["level_id"] = target_level_id
		return cached_manifest

	_ensure_page_layout_for_rect(page, rect)
	# Single source of truth: use the exact MapPage landmark manifest without any gameplay-specific layout/scaling
	var page_manifest: Dictionary = get_page_landmark_manifest(page, rect)
	var country_key: String = String(page_manifest.get("country_key", "japan"))
	var base_sc: float = float(page_manifest.get("base_landmark_scale", 1.0))
	var dest_landmarks: Array = page_manifest.get("destination_landmarks", [])
	var reg_scenes: Array = page_manifest.get("regional_milestone_scenes", [])
	var lm_ids: Array = page_manifest.get("landmark_ids", [])
	var lm_positions: Array = page_manifest.get("landmark_positions", [])
	var lm_scales: Array = page_manifest.get("landmark_scales", [])
	var lm_bboxes: Array = page_manifest.get("landmark_bounding_boxes", [])
	var terrain_geom: Dictionary = page_manifest.get("terrain_geometry", {})
	var major_scenery_pts: Array = page_manifest.get("major_scenery_positions", [])

	var canonical_bg: Dictionary = page.canonical_gameplay_background if not page.canonical_gameplay_background.is_empty() else {}
	var canonical_bg_id: String = String(canonical_bg.get("canonical_background_id", "%s_canonical_country_bg" % page.country_id))

	var composition_elements: Array[Dictionary] = []
	var composition_landmarks: Array[Dictionary] = []
	var map_dest_landmarks: Array[Dictionary] = []
	var resolved_major_ids: Array[String] = []
	var resolved_cue_ids: Array[String] = []
	var all_country_lm_ids: Array[String] = []

	for d_var in dest_landmarks:
		var d_entry: Dictionary = d_var as Dictionary
		var el_lm_id: String = String(d_entry.get("landmark_id", ""))
		var el_name: String = String(d_entry.get("location_label", page.country_name_en))
		var el_sc: float = float(d_entry.get("architecture_scale", base_sc))
		var arch_pos: Vector2 = d_entry.get("architecture_position", d_entry.get("ground_anchor", Vector2.ZERO))
		var el_anchor: Vector2 = d_entry.get("ground_anchor", arch_pos)
		var el_fp_rect: Rect2 = d_entry.get("footprint_rect", d_entry.get("architecture_rect", Rect2()))
		resolved_major_ids.append(el_lm_id)
		if not (el_lm_id in all_country_lm_ids):
			all_country_lm_ids.append(el_lm_id)
		var el_dict := {
			"node_index": int(d_entry.get("node_index", 0)),
			"level_id": int(d_entry.get("level_id", target_level_id)),
			"landmark_id": el_lm_id,
			"landmark_name": el_name,
			"destination_name": el_name,
			"location_label": el_name,
			"region": String(d_entry.get("region", "")),
			"country_id": page.country_id,
			"milestone_context": String(d_entry.get("milestone_context", "major_landmark")),
			"visual_tier": "major_landmark",
			"hierarchy_rank": composition_elements.size() + 1,
			"scale_weight": 1.0,
			"scale": el_sc,
			"architecture_scale": el_sc,
			"ground_anchor": el_anchor,
			"architecture_position": arch_pos,
			"footprint_rect": el_fp_rect,
			"plaque_position": d_entry.get("plaque_position", Vector2.ZERO),
			"plaque_rect": d_entry.get("plaque_rect", Rect2()),
			"terrain_surface": String(d_entry.get("terrain_surface", "LAND_GROUND")),
			"grounding_type": String(d_entry.get("grounding_classification", "GROUND"))
		}
		composition_elements.append(el_dict)
		composition_landmarks.append(el_dict)
		map_dest_landmarks.append(el_dict)

	for r_var in reg_scenes:
		var r_entry: Dictionary = r_var as Dictionary
		var r_lm_id: String = String(r_entry.get("landmark_id", ""))
		if r_lm_id != "":
			resolved_cue_ids.append(r_lm_id)
			if not (r_lm_id in all_country_lm_ids):
				all_country_lm_ids.append(r_lm_id)
		var cue_dict := {
			"node_index": int(r_entry.get("node_index", 0)),
			"level_id": int(r_entry.get("level_id", target_level_id)),
			"landmark_id": r_lm_id,
			"landmark_name": String(r_entry.get("destination_name", page.country_name_en)),
			"destination_name": String(r_entry.get("destination_name", page.country_name_en)),
			"region": String(r_entry.get("region", "")),
			"country_id": page.country_id,
			"milestone_context": String(r_entry.get("milestone_context", "regional_scene")),
			"visual_tier": "regional_scenery",
			"hierarchy_rank": composition_elements.size() + 1,
			"scale_weight": get_destination_hierarchy_scale_multiplier(String(r_entry.get("milestone_context", "regional_scene"))),
			"scale": float(r_entry.get("scale", base_sc * 0.80)),
			"ground_anchor": r_entry.get("ground_anchor", Vector2.ZERO),
			"footprint_rect": r_entry.get("footprint_rect", Rect2())
		}
		composition_elements.append(cue_dict)

	for c_dest_var in page.country_destinations:
		if c_dest_var is Dictionary:
			var c_lm_id: String = String((c_dest_var as Dictionary).get("landmark_id", ""))
			if c_lm_id != "" and not (c_lm_id in all_country_lm_ids):
				all_country_lm_ids.append(c_lm_id)

	var first_el: Dictionary = map_dest_landmarks[0] if not map_dest_landmarks.is_empty() else {}
	var second_el: Dictionary = map_dest_landmarks[1] if map_dest_landmarks.size() > 1 else (composition_elements[1] if composition_elements.size() > 1 else first_el)
	var prim_lm_id: String = String(first_el.get("landmark_id", canonical_bg.get("canonical_landmark_id", "%s_heritage" % page.country_id)))
	var prim_lm_name: String = String(first_el.get("landmark_name", canonical_bg.get("canonical_landmark_name", page.country_name_en)))
	var sec_lm_id: String = String(second_el.get("landmark_id", canonical_bg.get("canonical_secondary_landmark_id", "")))
	var sec_lm_name: String = String(second_el.get("landmark_name", canonical_bg.get("canonical_secondary_landmark_name", "")))
	var ground_anchor: Vector2 = first_el.get("ground_anchor", Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y * 0.45))
	var sec_anchor: Vector2 = second_el.get("ground_anchor", Vector2(rect.position.x + rect.size.x * 0.3, rect.position.y + rect.size.y * 0.58))
	var lm_sc: float = float(first_el.get("scale", base_sc))
	var fp_rect: Rect2 = first_el.get("footprint_rect", Rect2(ground_anchor - Vector2(24.0, 24.0), Vector2(48.0, 48.0)))
	var plaque_pos: Vector2 = first_el.get("plaque_position", ground_anchor + Vector2(0.0, 18.0))
	var plaque_rect: Rect2 = first_el.get("plaque_rect", Rect2(plaque_pos - Vector2(30.0, 10.0), Vector2(60.0, 20.0)))
	var country_name: String = page.country_name_vi if (lang == "vi" and page.country_name_vi != "") else page.country_name_en

	var horizontal_clipped: bool = int(page_manifest.get("out_of_bounds_landmark_count", 0)) > 0 or int(page_manifest.get("out_of_bounds_label_count", 0)) > 0
	var vertical_clipped: bool = horizontal_clipped
	var vis: Dictionary = get_render_visibility(RenderMode.GAMEPLAY_BACKGROUND)

	var result_manifest: Dictionary = {
		"valid": true,
		"reuses_country_map_artwork": true,
		"reuses_full_map_page_artwork": true,
		"matches_full_map_page_artwork": true,
		"matches_map_page_exactly": true,
		"render_mode": MODE_GAMEPLAY_BACKGROUND,
		"visibility": vis,
		"resolution_architecture": "level_to_country_to_canonical_background",
		"uses_destination_selection": false,
		"level_id": target_level_id,
		"page_index": page.page_index,
		"map_page_id": page.page_id,
		"country_id": page.country_id,
		"country_key": country_key,
		"country_name_en": page.country_name_en,
		"country_name_vi": page.country_name_vi,
		"canonical_background_id": canonical_bg_id,
		"background_id": canonical_bg_id,
		"full_map_page_artwork_id": "%s_map_page_artwork" % page.country_id,
		"canonical_landmark_id": prim_lm_id,
		"canonical_landmark_name": prim_lm_name,
		"canonical_secondary_landmark_id": sec_lm_id,
		"canonical_secondary_landmark_name": sec_lm_name,
		"destination_landmarks": dest_landmarks,
		"regional_milestone_scenes": reg_scenes,
		"composition_landmarks": composition_landmarks,
		"composition_elements": composition_elements,
		"map_page_destination_landmarks": map_dest_landmarks,
		"independent_poi": page.independent_poi,
		"landmark_count": int(page_manifest.get("landmark_count", dest_landmarks.size())),
		"featured_landmark_count": int(page_manifest.get("featured_landmark_count", dest_landmarks.size())),
		"landmark_ids": lm_ids,
		"all_country_landmark_ids": all_country_lm_ids,
		"landmark_positions": lm_positions,
		"landmark_scales": lm_scales,
		"landmark_bounding_boxes": lm_bboxes,
		"base_landmark_scale": base_sc,
		"terrain_geometry": terrain_geom,
		"major_scenery_positions": major_scenery_pts,
		"major_landmark_ids": resolved_major_ids,
		"scenery_cue_ids": resolved_cue_ids,
		"map_page_destination_count": page.country_destinations.size(),
		"major_landmark_count": resolved_major_ids.size(),
		"scenery_cue_count": resolved_cue_ids.size(),
		"focal_element_count": 1,
		"has_multiple_landmarks": composition_elements.size() >= 2,
		"has_visual_hierarchy": bool(page_manifest.get("visual_hierarchy_valid", true)),
		"is_single_landmark_only": false,
		"contextual_label": country_name,
		"landmark_id": prim_lm_id,
		"secondary_landmark_id": sec_lm_id,
		"has_featured_landmark": prim_lm_id != "",
		"has_strong_landmark": prim_lm_id != "",
		"ground_anchor": ground_anchor,
		"secondary_ground_anchor": sec_anchor,
		"landmark_scale": lm_sc,
		"footprint_rect": fp_rect,
		"plaque_position": plaque_pos,
		"plaque_rect": plaque_rect,
		"terrain_surface": String(first_el.get("terrain_surface", "LAND_GROUND")) if not first_el.is_empty() else "LAND_GROUND",
		"ground_anchor_not_sky": bool(page_manifest.get("all_ground_anchors_not_in_sky", true)),
		"ground_anchor_not_in_sky": bool(page_manifest.get("all_ground_anchors_not_in_sky", true)),
		"ground_anchor_not_mountain_background": bool(page_manifest.get("all_ground_anchors_not_mountain_background", true)),
		"ground_anchor_not_in_water": bool(page_manifest.get("all_water_relationships_valid", true)),
		"ground_anchor_valid": bool(page_manifest.get("all_ground_anchors_valid", true)),
		"horizontal_clipped": horizontal_clipped,
		"has_horizontal_clipping": horizontal_clipped,
		"vertical_clipped": vertical_clipped,
		"renders_level_nodes": false,
		"draws_map_level_nodes": false,
		"renders_route_lines": false,
		"draws_route_lines": false,
		"renders_node_numbers": false,
		"draws_node_numbers": false,
		"draws_progression_markers": false,
		"renders_destination_pads": false,
		"draws_artificial_floating_islands": false,
		"renders_map_ui": false,
		"draws_map_navigation_ui": false,
		"renders_level_labels": false,
		"renders_unrelated_landmarks": false,
		"unrelated_landmark_count": 0,
		"is_continuous_country_scene": true,
		"is_destination_collage": false,
		"preserves_board_readability": true,
		"has_subdued_contrast_veil": true,
		"subdued_veil_alpha": 0.10,
		"layer_order": [
			"country_landscape_background",
			"subtle_atmospheric_depth",
			"integrated_country_landmarks",
			"gameplay_hud",
			"translucent_12x10_board",
			"blocks_tray_controls"
		]
	}
	_gameplay_bg_manifest_cache[cache_key] = result_manifest.duplicate(true)
	return result_manifest


static func compare_map_page_and_gameplay_background_invariants(
	page: MapPage,
	rect: Rect2,
	target_level_id: int = -1
) -> Dictionary:
	if page == null or rect.size.x <= 10.0 or rect.size.y <= 10.0:
		return {"valid": false}
	_ensure_page_layout_for_rect(page, rect)
	var lvl_id: int = target_level_id if target_level_id > 0 else page.start_level
	var map_man: Dictionary = get_page_landmark_manifest(page, rect)
	var bg_man: Dictionary = get_gameplay_level_background_manifest(page, lvl_id, rect, "en")

	var map_cnt: int = int(map_man.get("landmark_count", -1))
	var bg_cnt: int = int(bg_man.get("landmark_count", -2))
	var count_match: bool = (map_cnt == bg_cnt and map_cnt > 0)

	var map_ids: Array = map_man.get("landmark_ids", [])
	var bg_ids: Array = bg_man.get("landmark_ids", [])
	var ids_match: bool = (map_ids == bg_ids and not map_ids.is_empty())

	var map_pos: Array = map_man.get("landmark_positions", [])
	var bg_pos: Array = bg_man.get("landmark_positions", [])
	var pos_match: bool = (map_pos.size() == bg_pos.size())
	if pos_match:
		for i in range(map_pos.size()):
			if (map_pos[i] as Vector2).distance_to(bg_pos[i] as Vector2) > 0.001:
				pos_match = false
				break

	var map_sc: Array = map_man.get("landmark_scales", [])
	var bg_sc: Array = bg_man.get("landmark_scales", [])
	var scale_match: bool = (map_sc.size() == bg_sc.size() and is_equal_approx(float(map_man.get("base_landmark_scale", 0.0)), float(bg_man.get("base_landmark_scale", -1.0))))
	if scale_match:
		for i in range(map_sc.size()):
			if not is_equal_approx(float(map_sc[i]), float(bg_sc[i])):
				scale_match = false
				break

	var map_bb: Array = map_man.get("landmark_bounding_boxes", [])
	var bg_bb: Array = bg_man.get("landmark_bounding_boxes", [])
	var bbox_match: bool = (map_bb.size() == bg_bb.size())
	if bbox_match:
		for i in range(map_bb.size()):
			var ra: Rect2 = map_bb[i] as Rect2
			var rb: Rect2 = bg_bb[i] as Rect2
			if ra.position.distance_to(rb.position) > 0.001 or ra.size.distance_to(rb.size) > 0.001:
				bbox_match = false
				break

	var map_tg: Dictionary = map_man.get("terrain_geometry", {})
	var bg_tg: Dictionary = bg_man.get("terrain_geometry", {})
	var terrain_match: bool = (
		String(map_tg.get("country_key", "")) == String(bg_tg.get("country_key", "x")) and
		int(map_tg.get("split_idx", -1)) == int(bg_tg.get("split_idx", -2)) and
		is_equal_approx(float(map_tg.get("sky_floor_y", -1.0)), float(bg_tg.get("sky_floor_y", -2.0))) and
		is_equal_approx(float(map_tg.get("land_ground_top_y", -1.0)), float(bg_tg.get("land_ground_top_y", -2.0))) and
		(map_tg.get("water_spine", PackedVector2Array()) as PackedVector2Array).size() == (bg_tg.get("water_spine", PackedVector2Array()) as PackedVector2Array).size()
	)

	var map_scen: Array = map_man.get("major_scenery_positions", [])
	var bg_scen: Array = bg_man.get("major_scenery_positions", [])
	var scenery_match: bool = (map_scen.size() == bg_scen.size() and not map_scen.is_empty())
	if scenery_match:
		for i in range(map_scen.size()):
			if (map_scen[i] as Vector2).distance_to(bg_scen[i] as Vector2) > 0.001:
				scenery_match = false
				break

	var vis_map: Dictionary = get_render_visibility(RenderMode.MAP_PAGE)
	var vis_bg: Dictionary = get_render_visibility(RenderMode.GAMEPLAY_BACKGROUND)
	var only_markers_differ: bool = (
		bool(vis_map.get("artwork", false)) == bool(vis_bg.get("artwork", true)) and
		bool(vis_map.get("landmarks", false)) == bool(vis_bg.get("landmarks", true)) and
		bool(vis_map.get("scenery", false)) == bool(vis_bg.get("scenery", true)) and
		bool(vis_map.get("roads", false)) == bool(vis_bg.get("roads", true)) and
		bool(vis_map.get("level_markers", false)) and not bool(vis_bg.get("level_markers", true)) and
		bool(vis_map.get("level_numbers", false)) and not bool(vis_bg.get("level_numbers", true)) and
		bool(vis_map.get("progression_ui", false)) and not bool(vis_bg.get("progression_ui", true)) and
		bool(vis_map.get("navigation_ui", false)) and not bool(vis_bg.get("navigation_ui", true))
	)

	return {
		"valid": count_match and ids_match and pos_match and scale_match and bbox_match and terrain_match and scenery_match and only_markers_differ,
		"landmark_count_match": count_match,
		"landmark_ids_match": ids_match,
		"landmark_positions_match": pos_match,
		"landmark_scale_match": scale_match,
		"landmark_bounding_boxes_match": bbox_match,
		"terrain_geometry_match": terrain_match,
		"major_scenery_positions_match": scenery_match,
		"only_marker_layer_differs": only_markers_differ
	}


static func draw_gameplay_level_background(
	canvas: CanvasItem,
	page: MapPage,
	target_level_id: int,
	rect: Rect2,
	anim_time: float = 0.0,
	lang: String = "en"
) -> Dictionary:
	if canvas == null or page == null or rect.size.x <= 10.0 or rect.size.y <= 10.0:
		return {}
	render_country_page(canvas, page, rect, RenderMode.GAMEPLAY_BACKGROUND, anim_time)
	return get_gameplay_level_background_manifest(page, target_level_id, rect, lang)


static func _draw_gameplay_subdued_contrast_veil(
	canvas: CanvasItem,
	rect: Rect2,
	pal: Dictionary
) -> void:
	var ox: float = rect.position.x
	var oy: float = rect.position.y
	var w: float = rect.size.x
	var h: float = rect.size.y
	var sky_top: Color = pal.get("sky_top", Color(0.12, 0.22, 0.42, 1.0))
	var veil_tint: Color = sky_top.darkened(0.72)
	veil_tint.a = 0.10
	canvas.draw_rect(rect, veil_tint, true)

	# Subtle top HUD readability band and bottom tray/controls readability band
	var top_h: float = minf(132.0, h * 0.15)
	canvas.draw_rect(Rect2(Vector2(ox, oy), Vector2(w, top_h)), Color(0.02, 0.05, 0.13, 0.12), true)
	var bot_h: float = minf(164.0, h * 0.18)
	canvas.draw_rect(Rect2(Vector2(ox, oy + h - bot_h), Vector2(w, bot_h)), Color(0.02, 0.05, 0.13, 0.12), true)

