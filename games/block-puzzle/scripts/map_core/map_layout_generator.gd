class_name MapLayoutGenerator
extends RefCounted

const MapTheme = preload("res://scripts/map_core/map_theme.gd")
const MapRoute = preload("res://scripts/map_core/map_route.gd")
const MapNode = preload("res://scripts/map_core/map_node.gd")
const MapPage = preload("res://scripts/map_core/map_page.gd")
const MapRenderer = preload("res://scripts/map_core/map_renderer.gd")

## MapLayoutGenerator — Deterministic Seeded Organic Route & Node Placement System
## Generates organic adventure routes for any number of nodes per MapPage (e.g. 5–10 or arbitrary).
## Never uses fixed zigzags, regular grids, repeated S-patterns, evenly spaced circles, or straight rows.
## Enforces:
##   - minimum node distance & milestone spacing boost
##   - safe screen margins for responsive viewports (360×800, 390×844, 720×1280, etc.)
##   - collision detection & iterative force-directed relaxation
##   - path/node separation so route curves never cut through unrelated nodes

const COMPOSITION_TYPES: Array[String] = [
	"sweeping_arc",
	"coastal_loop",
	"winding_ascent",
	"landmark_bend",
	"canyon_meander",
	"spiral_cove",
	"scenic_switchback",
	"archipelago_drift"
]

var min_node_distance_ratio: float = 0.165
var min_node_distance_px_floor: float = 72.0
var milestone_spacing_multiplier: float = 1.18
var safe_margin_left_ratio: float = 0.125
var safe_margin_right_ratio: float = 0.125
var safe_margin_top_ratio: float = 0.105
var safe_margin_bottom_ratio: float = 0.085
var relaxation_iterations: int = 48


static func get_composition_for_page(page_index: int, _seed_value: int = 0) -> String:
	var n: int = COMPOSITION_TYPES.size()
	var safe_p: int = maxi(0, page_index)
	var cycle: int = int(safe_p / n)
	var idx: int = (safe_p + cycle * 3) % n
	return COMPOSITION_TYPES[idx]


static func get_landmark_stop_indices(count: int, split_idx: int = -1) -> Array[int]:
	var chosen: Array[int] = []
	if count <= 0:
		return chosen
	if count == 1:
		return [0]
	if count <= 4:
		return [0, count - 1]
	var sp: int = split_idx if split_idx >= 1 else clampi(int(round(float(count) * 0.50)), 2, maxi(2, count - 2))
	if count <= 6:
		# 5 or 6 nodes: 3 well-separated landmark destinations (e.g. [0, 2, 4] or [0, 3, 5], min index gap >= 2)
		var mid_i: int = clampi(sp, 2, count - 3)
		chosen = [0, mid_i, count - 1]
	else:
		# 7..10 nodes: 4 well-separated landmark destinations with min index gap >= 2
		var idx1: int = clampi(int(round(float(count - 1) * 0.31)), 2, count - 5)
		var idx2: int = clampi(maxi(idx1 + 2, int(round(float(count - 1) * 0.66))), idx1 + 2, count - 3)
		chosen = [0, idx1, idx2, count - 1]
	return chosen


static func get_country_featured_stop_indices(nodes: Array) -> Array[int]:
	var chosen: Array[int] = []
	for i in range(nodes.size()):
		var nd: MapNode = nodes[i]
		if nd == null:
			continue
		var m_ctx: String = String(nd.landmark.get("milestone_context", ""))
		if m_ctx == "major_landmark" or m_ctx == "landmark_environment":
			chosen.append(i)
	if chosen.is_empty() and not nodes.is_empty():
		return get_landmark_stop_indices(nodes.size())
	return chosen


static func get_destination_footprint_extents(
	nd: MapNode,
	is_landmark_stop: bool,
	canvas_size: Vector2,
	node_count: int
) -> Dictionary:
	var short_side: float = minf(maxf(280.0, canvas_size.x), maxf(360.0, canvas_size.y))
	var density_sc: float = clampf(8.4 / float(maxi(5, node_count)), 0.78, 1.05)
	var base_sc: float = clampf(minf(canvas_size.x / 340.0, canvas_size.y / 580.0), 0.80, 1.38)
	var m_ctx: String = String(nd.landmark.get("milestone_context", "")) if nd != null else ""
	var lm_density: String = String(nd.landmark.get("landmark_density", "moderate")) if nd != null else "moderate"
	var country_breath_mult: float = 1.08 if lm_density == "sparse" else (1.03 if lm_density == "moderate" else (0.98 if lm_density == "high" else 0.94))
	var is_major_lm: bool = (m_ctx == "major_landmark") or (m_ctx == "" and is_landmark_stop)
	var is_env_lm: bool = (m_ctx == "landmark_environment")
	var is_reg_scene: bool = (m_ctx == "regional_scene")
	var half_btn_w: float = nd.node_size.x * 0.5
	var half_btn_h: float = nd.node_size.y * 0.5
	var court_rx: float = nd.node_size.x * (0.92 if is_major_lm else (0.85 if is_env_lm else (0.74 if is_reg_scene else 0.66))) + 5.0
	var lm_w: float = (40.0 if is_major_lm else (34.0 if is_env_lm else (23.0 if is_reg_scene else 14.0))) * base_sc * country_breath_mult
	# Complete horizontal footprint: marker + courtyard plaza + enlarged landmark width + side plaque reserve
	var half_w: float = maxf(
		maxf(court_rx, lm_w),
		(half_btn_w + (22.0 if is_major_lm else (18.0 if is_env_lm else 12.0))) * density_sc * country_breath_mult
	)
	# Upward footprint: includes enlarged landmark architecture or regional scene rising above courtyard
	var top_ext: float = maxf(
		half_btn_h + (40.0 if is_major_lm else (32.0 if is_env_lm else (19.0 if is_reg_scene else 10.0))) * base_sc * density_sc * country_breath_mult,
		short_side * (0.158 if is_major_lm else (0.142 if is_env_lm else 0.088)) * density_sc
	)
	# Downward footprint: includes courtyard apron, stars, and lower route entry
	var bot_ext: float = maxf(
		court_rx * 0.60 + (11.0 if (is_major_lm or is_env_lm) else 7.0) * density_sc,
		short_side * 0.076 * density_sc
	)
	return {
		"half_w": half_w,
		"top_ext": top_ext,
		"bot_ext": bot_ext
	}


func compute_safe_rect(canvas_size: Vector2, node_radius: float = 28.0) -> Rect2:
	var w: float = maxf(260.0, canvas_size.x)
	var h: float = maxf(320.0, canvas_size.y)
	var left: float = maxf(node_radius + 14.0, w * safe_margin_left_ratio)
	var right: float = maxf(node_radius + 14.0, w * safe_margin_right_ratio)
	var top: float = maxf(node_radius + 36.0, h * maxf(safe_margin_top_ratio, 0.148))
	var bottom: float = maxf(node_radius + 18.0, h * safe_margin_bottom_ratio)
	var usable_w: float = maxf(80.0, w - left - right)
	var usable_h: float = maxf(120.0, h - top - bottom)
	return Rect2(Vector2(left, top), Vector2(usable_w, usable_h))


func compute_node_size_for_viewport(canvas_size: Vector2, level_count: int, is_milestone: bool = false, milestone_scale: float = 1.0) -> Vector2:
	var short_side: float = minf(maxf(260.0, canvas_size.x), maxf(340.0, canvas_size.y))
	var density_scale: float = clampf(8.2 / float(maxi(5, level_count)), 0.72, 1.04)
	var base_w: float = clampf(short_side * 0.136 * density_scale, 42.0, 56.0)
	var base_h: float = clampf(base_w * 0.92, 38.0, 52.0)
	var mult: float = clampf(milestone_scale, 1.0, 1.18) if is_milestone else 1.0
	return Vector2(roundf(base_w * mult), roundf(base_h * mult))


func generate_page_layout(
	page: MapPage,
	canvas_size: Vector2,
	progression_provider: Dictionary = {}
) -> void:
	if page == null:
		return
	var eff_canvas: Vector2 = Vector2(
		maxf(280.0, canvas_size.x),
		maxf(340.0, canvas_size.y)
	)
	page.last_canvas_size = eff_canvas
	var count: int = page.get_level_count()
	page.nodes.clear()
	if count <= 0:
		page.route = MapRoute.new()
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = int(page.seed_value) ^ (page.page_index * 2654435761)

	var theme_obj: MapTheme = page.theme if page.theme != null else MapTheme.from_preset("ocean_islands")
	var j_dir: String = page.journey_direction if page.journey_direction != "" else "north_to_south"
	var c_id: String = page.country_id if page.country_id != "" else theme_obj.world_id
	var c_en: String = page.country_name_en if page.country_name_en != "" else theme_obj.country_or_region_en

	# 1. Resolve pre-ordered geographic destination sequence BEFORE visual layout
	var recon: Dictionary = reconcile_country_destinations_with_levels(page.country_destinations, page.level_ids)
	page.country_destinations = recon.get("country_destinations", [])
	page.active_level_destinations = recon.get("active_level_destinations", [])
	page.omitted_destinations = recon.get("omitted_destinations", [])
	var ordered_dests: Array[Dictionary] = page.active_level_destinations

	# 2. Generate organic UV waypoints in [0..1]x[0..1] progressing along journey_direction
	var raw_uvs: Array[Vector2] = _generate_organic_uvs(count, page.composition_type, rng, j_dir)

	# 3. Compute safe placement rect and convert UV -> pixel space
	var base_node_size: Vector2 = compute_node_size_for_viewport(eff_canvas, count, false, 1.0)
	var safe_rect: Rect2 = compute_safe_rect(eff_canvas, base_node_size.x * 0.55)

	var unlocked_level: int = int(progression_provider.get("unlocked_level", 1))
	var selected_level: int = int(progression_provider.get("selected_level", unlocked_level))
	var level_stars: Dictionary = progression_provider.get("level_stars", {})
	var target_scores: Dictionary = progression_provider.get("target_scores", {})

	var dest_styles: Array[String] = theme_obj.destination_styles
	var lm_types: Array[String] = theme_obj.landmark_types

	for i in range(count):
		var lv_id: int = page.level_ids[i]
		var nd := MapNode.new()
		nd.level_id = lv_id
		nd.page_id = page.page_id
		nd.page_index = page.page_index
		nd.local_index = i

		var m_spec: Dictionary = page.get_milestone_spec(lv_id)
		var is_ms: bool = bool(m_spec.get("is_milestone", false)) or String(m_spec.get("milestone_type", "")) != ""
		var m_scale: float = float(m_spec.get("scale_mult", 1.18 if is_ms else 1.0))
		nd.milestone = m_spec
		if is_ms:
			nd.node_type = "milestone"
		elif i == 0:
			nd.node_type = "page_entry"
		elif i == count - 1:
			nd.node_type = "page_finale"
		else:
			nd.node_type = "normal"

		nd.node_size = compute_node_size_for_viewport(eff_canvas, count, is_ms, m_scale)
		nd.radius = maxf(nd.node_size.x, nd.node_size.y) * 0.5
		nd.uv_position = raw_uvs[i]
		nd.position = Vector2(
			safe_rect.position.x + raw_uvs[i].x * safe_rect.size.x,
			safe_rect.position.y + raw_uvs[i].y * safe_rect.size.y
		)
		var progress_t: float = float(i) / float(maxi(1, count - 1))
		nd.elevation = clampf(0.18 + progress_t * 0.64 + (0.12 if is_ms else 0.0), 0.12, 0.96)

		# Progression state
		var stars_val: int = int(level_stars.get(lv_id, level_stars.get(str(lv_id), 0)))
		nd.stars = clampi(stars_val, 0, 3)
		nd.is_unlocked = lv_id <= unlocked_level
		nd.is_locked = not nd.is_unlocked
		nd.is_completed = nd.stars > 0 or lv_id < unlocked_level
		nd.is_current = (lv_id == unlocked_level)
		nd.is_selected = (lv_id == selected_level)
		if nd.is_current:
			nd.state = "current"
		elif nd.is_completed:
			nd.state = "completed"
		elif nd.is_unlocked:
			nd.state = "unlocked"
		else:
			nd.state = "locked"

		nd.target_score = int(target_scores.get(lv_id, 400 + lv_id * 95))

		# Coherent theme-matched landmark, sub-region & pre-ordered geographic destination metadata
		var style_idx: int = (i + page.page_index) % maxi(1, dest_styles.size())
		if is_ms and dest_styles.size() > 0:
			style_idx = dest_styles.size() - 1
		var dest_style: String = dest_styles[style_idx] if not dest_styles.is_empty() else "sandy_cay_island"
		var lm_type: String = lm_types[i % maxi(1, lm_types.size())] if not lm_types.is_empty() else "harbor_lighthouse"
		var sub_list: Array[String] = theme_obj.subregions
		var sub_en_list: Array[String] = theme_obj.subregion_names_en
		var sub_vi_list: Array[String] = theme_obj.subregion_names_vi
		var bg_list: Array[String] = theme_obj.gameplay_backgrounds
		var zone_idx: int = clampi(int(floor(progress_t * float(maxi(1, sub_list.size())))), 0, maxi(0, sub_list.size() - 1))
		var sub_id: String = sub_list[zone_idx] if not sub_list.is_empty() else "coastal_bay"
		var sub_en: String = sub_en_list[zone_idx % maxi(1, sub_en_list.size())] if not sub_en_list.is_empty() else sub_id
		var sub_vi: String = sub_vi_list[zone_idx % maxi(1, sub_vi_list.size())] if not sub_vi_list.is_empty() else sub_en
		var bg_id: String = bg_list[zone_idx % maxi(1, bg_list.size())] if not bg_list.is_empty() else "halong_karst_bay"

		var geo_dest: Dictionary = ordered_dests[i] if i < ordered_dests.size() else {}
		var dest_name: String = String(geo_dest.get("destination_name", sub_en))
		var dest_region: String = String(geo_dest.get("region", c_en))
		var dest_lm_id: String = String(geo_dest.get("landmark_id", ""))
		var dest_lm_desc: String = String(geo_dest.get("landmark", theme_obj.primary_landmark_en))
		var dest_lat: float = float(geo_dest.get("lat", lerpf(21.0, 10.0, progress_t)))
		var dest_lon: float = float(geo_dest.get("lon", lerpf(105.8, 106.7, progress_t)))
		var dest_order: int = int(geo_dest.get("destination_order", i + 1))
		var dest_m_ctx: String = String(geo_dest.get("milestone_context", "major_landmark" if (i == 0 or i == count - 1) else "regional_scene"))
		var dest_env_type: String = String(geo_dest.get("environment_type", "regional_landscape"))
		var is_feat_lm: bool = (dest_m_ctx == "major_landmark" or dest_m_ctx == "landmark_environment")
		var dest_grounding: String = String(geo_dest.get("grounding_type", "GROUND"))
		var dest_water_rel: String = String(geo_dest.get("water_relationship", "none"))
		var dest_terrain_zone: String = String(geo_dest.get("supporting_terrain_zone", "LAND"))

		var place_type: String = "scenic_viewpoint"
		match theme_obj.world_type:
			"countryside": place_type = "farm_clearing"
			"town": place_type = "town_square"
			"modern_city": place_type = "urban_plaza"
			"country": place_type = "regional_destination"
			"landmark_region": place_type = "scenic_viewpoint"
			"space_astronomical": place_type = "planetary_station"
		nd.landmark = {
			"landmark_type": lm_type,
			"landmark_id": dest_lm_id,
			"landmark_description": dest_lm_desc,
			"landmark_classification": "DESTINATION_LANDMARK",
			"milestone_context": dest_m_ctx,
			"environment_type": dest_env_type,
			"grounding_type": dest_grounding,
			"water_relationship": dest_water_rel,
			"supporting_terrain_zone": dest_terrain_zone,
			"is_featured_landmark": is_feat_lm,
			"landmark_density": page.landmark_density,
			"is_route_destination": true,
			"has_separate_spur_road": false,
			"destination_order": dest_order,
			"route_sequence_index": i,
			"destination_name": dest_name,
			"location_label": dest_name,
			"region": dest_region,
			"lat": dest_lat,
			"lon": dest_lon,
			"country_id": c_id,
			"country_name_en": c_en,
			"journey_direction": j_dir,
			"destination_style": dest_style,
			"destination_place_type": place_type,
			"terrain_surface": theme_obj.terrain_style,
			"world_type": theme_obj.world_type,
			"world_id": theme_obj.world_id,
			"subregion_id": sub_id,
			"subregion_name_en": sub_en,
			"subregion_name_vi": sub_vi,
			"gameplay_background": bg_id,
			"scale": m_scale
		}
		page.nodes.append(nd)

	# 4. Collision detection & force-directed relaxation preserving destination order
	_relax_node_positions(page.nodes, safe_rect, eff_canvas, j_dir, page)
	page.order_preserved_after_relaxation = verify_destination_order_preserved(page.nodes, j_dir)

	# 4. Update normalized UV positions from relaxed pixel positions and populate route connections
	for i in range(count):
		var nd_uv: MapNode = page.nodes[i]
		nd_uv.uv_position = Vector2(
			clampf((nd_uv.position.x - safe_rect.position.x) / maxf(1.0, safe_rect.size.x), 0.0, 1.0),
			clampf((nd_uv.position.y - safe_rect.position.y) / maxf(1.0, safe_rect.size.y), 0.0, 1.0)
		)
		var next_lv: int = page.nodes[i + 1].level_id if (i + 1 < count) else nd_uv.level_id
		nd_uv.route_connection = {
			"from_level_id": nd_uv.level_id,
			"to_level_id": next_lv,
			"segment_style": theme_obj.path_style,
			"has_scenic_spur": false,
			"spur_target_uv": nd_uv.uv_position,
			"spur_landmark": ""
		}

	# 5. Build MapRoute and single major focal landmark strictly matching page.theme
	var route := MapRoute.new()
	route.page_id = page.page_id
	route.composition_type = page.composition_type
	route.rebuild_from_nodes(page.nodes, theme_obj.path_style, 14)
	var eff_rect := Rect2(Vector2.ZERO, eff_canvas)
	for sp_i in range(route.smooth_points.size()):
		var sp: Vector2 = route.smooth_points[sp_i]
		var min_route_y: float = MapRenderer.get_mountain_background_bottom_y_at(page, eff_rect, sp.x) + 2.0
		if sp.y < min_route_y:
			route.smooth_points[sp_i] = Vector2(sp.x, min_route_y)
	page.route = route

	page.background_landmarks = _generate_theme_landmarks(page, safe_rect, rng)
	route.scenic_spurs = []


static func compute_active_destination_indices(m: int, count: int) -> Array[int]:
	var chosen_indices: Array[int] = []
	if m <= 0 or count <= 0:
		return chosen_indices
	if count == 1:
		return [0]
	if m == count:
		for i in range(count):
			chosen_indices.append(i)
		return chosen_indices
	if m == count + 1 and m >= 4:
		var omit_idx: int = clampi(int(floor(float(m - 2) * 0.58)), 1, m - 2)
		for idx in range(m):
			if idx != omit_idx:
				chosen_indices.append(idx)
		return chosen_indices
	if m > count:
		for i in range(count):
			var raw_idx: int = int(round(float(i) * float(m - 1) / float(count - 1)))
			if not chosen_indices.is_empty() and raw_idx <= chosen_indices[chosen_indices.size() - 1]:
				raw_idx = chosen_indices[chosen_indices.size() - 1] + 1
			var max_allowed: int = m - (count - i)
			raw_idx = clampi(raw_idx, 0, max_allowed)
			chosen_indices.append(raw_idx)
		return chosen_indices
	for seq_i in range(count):
		var src_idx: int = clampi(int(floor(float(seq_i) * float(m) / float(count))), 0, m - 1)
		chosen_indices.append(src_idx)
	return chosen_indices


static func reconcile_country_destinations_with_levels(all_dests: Array, level_ids: Array) -> Dictionary:
	var m: int = all_dests.size()
	var count: int = level_ids.size()
	var reconciled_all: Array[Dictionary] = []
	var active_list: Array[Dictionary] = []
	var omitted_list: Array[Dictionary] = []
	if m <= 0 or count <= 0:
		return {
			"country_destinations": reconciled_all,
			"active_level_destinations": active_list,
			"omitted_destinations": omitted_list
		}
	var chosen_indices: Array[int] = compute_active_destination_indices(m, count)
	var chosen_lookup: Dictionary = {}
	for seq_i in range(chosen_indices.size()):
		chosen_lookup[chosen_indices[seq_i]] = seq_i

	if m >= count:
		for idx in range(m):
			var d_copy: Dictionary = (all_dests[idx] as Dictionary).duplicate(true)
			d_copy["researched_order"] = idx + 1
			d_copy["destination_order"] = idx + 1
			if chosen_lookup.has(idx):
				var seq_i: int = int(chosen_lookup[idx])
				var lv_id: int = int(level_ids[seq_i]) if seq_i < level_ids.size() else (seq_i + 1)
				d_copy["included_in_level_sequence"] = true
				d_copy["active_sequence_order"] = seq_i + 1
				d_copy["route_sequence_index"] = seq_i
				d_copy["assigned_level_id"] = lv_id
				d_copy["selection_status"] = "active_level_destination"
				d_copy["omission_reason"] = ""
				var act_copy: Dictionary = d_copy.duplicate(true)
				active_list.append(act_copy)
			else:
				var reason: String = "Explicitly omitted from %d-level active sequence (%d researched country destinations in manifest)." % [count, m]
				d_copy["included_in_level_sequence"] = false
				d_copy["active_sequence_order"] = -1
				d_copy["route_sequence_index"] = -1
				d_copy["assigned_level_id"] = -1
				d_copy["selection_status"] = "omitted_from_level_sequence"
				d_copy["omission_reason"] = reason
				omitted_list.append(d_copy.duplicate(true))
			reconciled_all.append(d_copy)
	else:
		for seq_i in range(count):
			var src_idx: int = chosen_indices[seq_i]
			var lv_id_else: int = int(level_ids[seq_i]) if seq_i < level_ids.size() else (seq_i + 1)
			var d_copy_else: Dictionary = (all_dests[src_idx] as Dictionary).duplicate(true)
			d_copy_else["researched_order"] = src_idx + 1
			d_copy_else["destination_order"] = seq_i + 1
			d_copy_else["included_in_level_sequence"] = true
			d_copy_else["active_sequence_order"] = seq_i + 1
			d_copy_else["route_sequence_index"] = seq_i
			d_copy_else["assigned_level_id"] = lv_id_else
			d_copy_else["selection_status"] = "active_level_destination"
			d_copy_else["omission_reason"] = ""
			reconciled_all.append(d_copy_else)
			active_list.append(d_copy_else.duplicate(true))

	return {
		"country_destinations": reconciled_all,
		"active_level_destinations": active_list,
		"omitted_destinations": omitted_list
	}


static func select_ordered_destinations_for_count(all_dests: Array, count: int) -> Array[Dictionary]:
	var dummy_lvs: Array[int] = []
	for i in range(maxi(0, count)):
		dummy_lvs.append(i + 1)
	var recon: Dictionary = reconcile_country_destinations_with_levels(all_dests, dummy_lvs)
	return recon.get("active_level_destinations", [])


static func verify_destination_order_preserved(nodes: Array, journey_direction: String = "north_to_south") -> bool:
	var n: int = nodes.size()
	if n <= 1:
		return true
	var is_n2s: bool = (journey_direction == "north_to_south")
	for i in range(n - 1):
		var a: MapNode = nodes[i]
		var b: MapNode = nodes[i + 1]
		var ord_a: int = int(a.landmark.get("destination_order", i + 1))
		var ord_b: int = int(b.landmark.get("destination_order", i + 2))
		if ord_a >= ord_b:
			return false
		if is_n2s:
			# North-to-South: northern stop i must sit above (smaller y) southern stop i+1
			if a.position.y >= b.position.y:
				return false
		else:
			if a.position.y <= b.position.y:
				return false
	return true


func _generate_organic_uvs(
	count: int,
	composition: String,
	rng: RandomNumberGenerator,
	journey_direction: String = "south_to_north"
) -> Array[Vector2]:
	var uvs: Array[Vector2] = []
	if count <= 0:
		return uvs
	if count == 1:
		uvs.append(Vector2(0.5, 0.55))
		return uvs

	var mirror_x: bool = rng.randf() > 0.5
	var phase_jitter: float = rng.randf_range(-0.14, 0.14)
	var is_n2s: bool = (journey_direction == "north_to_south")
	var v_start: float = 0.06 if is_n2s else 0.94
	var v_end: float = 0.94 if is_n2s else 0.06

	# Non-uniform terrain-pocket vertical progression along journey_direction:
	var v_coords: Array[float] = []
	var cluster_gap_idx: int = maxi(1, int(round(float(count) * 0.42)))
	var upper_gap_idx: int = maxi(cluster_gap_idx + 1, count - 2)
	var raw_weights: Array[float] = []
	for s_i in range(count - 1):
		var w_step: float = 0.96 + rng.randf_range(-0.08, 0.08)
		if s_i == cluster_gap_idx - 1:
			w_step = 1.26 + rng.randf_range(0.0, 0.12)
		elif s_i == upper_gap_idx - 1:
			w_step = 1.16 + rng.randf_range(0.0, 0.10)
		elif s_i % 2 == 0:
			w_step = 0.86 + rng.randf_range(-0.05, 0.07)
		raw_weights.append(w_step)

	var total_w: float = 0.0
	for w_val in raw_weights:
		total_w += w_val
	var accum_w: float = 0.0
	v_coords.append(v_start)
	for s_i in range(count - 1):
		accum_w += raw_weights[s_i]
		var norm_p: float = accum_w / maxf(0.001, total_w)
		v_coords.append(lerpf(v_start, v_end, norm_p))

	for i in range(count):
		var t: float = float(i) / float(maxi(1, count - 1))
		var v: float = v_coords[i]
		var u: float = 0.5

		# Smooth topographic contour modulation (no alternating i%2 zigzag)
		var contour_drift: float = sin(t * PI * 2.4 + phase_jitter) * 0.045 + cos(t * PI * 1.3 - phase_jitter) * 0.025
		if i == 0 or i == count - 1:
			contour_drift *= 0.35

		match composition:
			"sweeping_arc":
				var arc_theta: float = lerpf(-0.48 * PI, 0.56 * PI, t)
				u = 0.20 + cos(arc_theta) * 0.62 + contour_drift
				v += -sin(t * PI) * 0.022
			"coastal_loop":
				var hook_phase: float = t * 1.48 * PI
				u = 0.48 + sin(hook_phase + 0.28) * (0.38 - 0.04 * t) + contour_drift
				v += sin(t * PI * 2.0) * 0.018
			"winding_ascent":
				var amp: float = lerpf(0.38, 0.28, t)
				u = 0.50 + sin(t * PI * 1.92 + 0.32) * amp + contour_drift
				v += cos(t * PI * 2.2) * 0.018
			"landmark_bend":
				var detour_a: float = exp(-pow((t - 0.30) / 0.20, 2.0)) * -0.37
				var detour_b: float = exp(-pow((t - 0.72) / 0.22, 2.0)) * 0.38
				u = 0.52 + detour_a + detour_b + contour_drift
				v += -sin(t * PI * 1.5) * 0.018
			"canyon_meander":
				u = 0.48 - cos(t * PI * 1.72 + 0.20) * 0.37 + contour_drift
				v += sin(t * PI * 2.0) * 0.018
			"spiral_cove":
				var angle: float = lerpf(0.12 * PI, 1.58 * PI, t)
				var rad_x: float = lerpf(0.39, 0.25, t * 0.65)
				u = 0.50 + cos(angle) * rad_x + contour_drift * 0.8
				v += sin(angle) * 0.022
			"scenic_switchback":
				var plateau: float = smoothstep(0.22, 0.76, t)
				u = lerpf(0.18, 0.82, plateau) + sin(t * PI * 2.2 + 0.35) * 0.16 + contour_drift * 0.8
				v += -sin(t * PI * 1.8) * 0.018
			_:
				u = 0.50 + sin(t * PI * 1.68 + 0.50) * 0.37 - cos(t * PI * 2.5) * 0.06 + contour_drift
				v += sin(t * PI * 1.7) * 0.018

		var jitter_u: float = rng.randf_range(-0.018, 0.018)
		var jitter_v: float = rng.randf_range(-0.010, 0.010)
		if i == 0 or i == count - 1:
			jitter_v *= 0.25
		u = clampf(u + jitter_u, 0.10, 0.90)
		v = clampf(v + jitter_v, 0.05, 0.95)
		if mirror_x:
			u = 1.0 - u
		if journey_direction == "west_to_east":
			u = clampf(lerpf(u, lerpf(0.16, 0.84, t), 0.36), 0.10, 0.90)
		elif journey_direction == "east_to_west":
			u = clampf(lerpf(u, lerpf(0.84, 0.16, t), 0.36), 0.10, 0.90)
		uvs.append(Vector2(u, v))

	# Ensure West-to-East / East-to-West endpoints reflect horizontal geographic direction
	if journey_direction == "west_to_east" and uvs[0].x > uvs[count - 1].x:
		for i in range(count):
			uvs[i].x = 1.0 - uvs[i].x
	elif journey_direction == "east_to_west" and uvs[0].x < uvs[count - 1].x:
		for i in range(count):
			uvs[i].x = 1.0 - uvs[i].x

	# Ensure consecutive stops on higher-density pages have natural lateral curve separation
	for i in range(count - 1):
		var du: float = uvs[i + 1].x - uvs[i].x
		var dv: float = absf(uvs[i].y - uvs[i + 1].y)
		if dv < 0.15 and absf(du) < 0.22:
			var push_dir: float = 1.0 if (uvs[i].x < 0.52) else -1.0
			if absf(du) > 0.02:
				push_dir = 1.0 if du > 0.0 else -1.0
			var needed_u: float = (0.23 - absf(du)) * 0.55
			uvs[i].x = clampf(uvs[i].x - push_dir * needed_u * 0.45, 0.10, 0.90)
			uvs[i + 1].x = clampf(uvs[i + 1].x + push_dir * needed_u * 0.65, 0.10, 0.90)

	return uvs


func _relax_node_positions(
	nodes: Array,
	safe_rect: Rect2,
	canvas_size: Vector2,
	journey_direction: String = "south_to_north",
	page: MapPage = null
) -> void:
	var n: int = nodes.size()
	if n <= 1:
		if n == 1:
			nodes[0].position = safe_rect.position + safe_rect.size * 0.5
		return

	var canvas_rect := Rect2(Vector2.ZERO, canvas_size)
	var is_n2s: bool = (journey_direction == "north_to_south")
	var short_side: float = minf(canvas_size.x, canvas_size.y)
	var density_factor: float = clampf(8.2 / float(maxi(5, n)), 0.74, 1.08)
	var base_min_dist: float = maxf(
		min_node_distance_px_floor * 0.96 * density_factor,
		short_side * min_node_distance_ratio * density_factor
	)

	var lm_indices: Array[int] = get_country_featured_stop_indices(nodes)
	var footprints: Array[Dictionary] = []
	var is_mtn_node: Array[bool] = []
	var c_key_relax: String = MapRenderer._resolve_country_composition_key(page.theme if page != null else null, page)
	for i in range(n):
		var is_lm: bool = (i in lm_indices)
		footprints.append(get_destination_footprint_extents(nodes[i], is_lm, canvas_size, n))
		var g_spec_i: Dictionary = MapRenderer.derive_landmark_grounding_spec(nodes[i].landmark if nodes[i].landmark is Dictionary else {}, c_key_relax)
		var g_class_i: String = String(g_spec_i.get("grounding_classification", "GROUND"))
		is_mtn_node.append(g_class_i in ["MOUNTAIN", "CLIFF"])

	for _iter in range(relaxation_iterations):
		var deltas: Array[Vector2] = []
		deltas.resize(n)
		for i in range(n):
			deltas[i] = Vector2.ZERO

		# 1. Pairwise Complete Destination Footprint + Radial Repulsion
		for i in range(n):
			var nd_a: MapNode = nodes[i]
			var fp_a: Dictionary = footprints[i]
			for j in range(i + 1, n):
				var nd_b: MapNode = nodes[j]
				var fp_b: Dictionary = footprints[j]

				# (a) Radial center-to-center distance floor
				var combined_radii: float = (nd_a.radius + nd_b.radius) * 1.24
				var is_ms_pair: bool = (nd_a.is_milestone_node() or nd_b.is_milestone_node())
				var ms_boost: float = (milestone_spacing_multiplier * 1.06) if is_ms_pair else 0.98
				var req_dist: float = maxf(base_min_dist * ms_boost, combined_radii)
				var diff: Vector2 = nd_a.position - nd_b.position
				var dist: float = diff.length()
				if dist < req_dist:
					var dir: Vector2 = diff / dist if dist > 0.001 else Vector2(cos(float(i + j)), sin(float(i - j))).normalized()
					var push: float = (req_dist - dist) * 0.52
					deltas[i] += dir * push
					deltas[j] -= dir * push

				# (b) Asymmetric Destination Footprint Elliptical Clearance
				var req_fp_w: float = float(fp_a["half_w"]) + float(fp_b["half_w"]) + 8.0 * density_factor
				var req_fp_h: float = (float(fp_b["top_ext"]) + float(fp_a["bot_ext"]) if is_n2s else float(fp_a["top_ext"]) + float(fp_b["bot_ext"])) + 8.0 * density_factor
				var dx_ab: float = nd_b.position.x - nd_a.position.x
				var dy_ab: float = absf(nd_a.position.y - nd_b.position.y)
				var norm_x: float = dx_ab / maxf(1.0, req_fp_w)
				var norm_y: float = dy_ab / maxf(1.0, req_fp_h)
				var ell_d: float = sqrt(norm_x * norm_x + norm_y * norm_y)
				if ell_d < 1.0:
					var overlap_frac: float = 1.0 - ell_d
					var lat_sign: float = 1.0 if dx_ab >= 0.0 else -1.0
					if absf(dx_ab) < 4.0:
						lat_sign = 1.0 if (nd_a.position.x < canvas_size.x * 0.5) else -1.0
					var y_push_dir: float = 1.0 if is_n2s else -1.0
					var push_vec := Vector2(
						lat_sign * req_fp_w * overlap_frac * 0.44,
						y_push_dir * req_fp_h * overlap_frac * 0.30
					)
					deltas[i] -= push_vec
					deltas[j] += push_vec

		# 2. Route segment vs non-adjacent node clearance (prevents paths cutting across other stops)
		for seg_i in range(n - 1):
			var a: Vector2 = nodes[seg_i].position
			var b: Vector2 = nodes[seg_i + 1].position
			for k in range(n):
				if k == seg_i or k == seg_i + 1:
					continue
				var p: Vector2 = nodes[k].position
				var closest: Vector2 = Geometry2D.get_closest_point_to_segment(p, a, b)
				var seg_diff: Vector2 = p - closest
				var seg_dist: float = seg_diff.length()
				var min_seg_clearance: float = nodes[k].radius * 1.44 + 17.0
				if seg_dist < min_seg_clearance:
					var push_dir: Vector2 = seg_diff / seg_dist if seg_dist > 0.001 else Vector2(1.0, 0.0)
					var push_amt: float = (min_seg_clearance - seg_dist) * 0.45
					deltas[k] += push_dir * push_amt

		# 3. Strictly preserve geographic destination progression order (never swap stops)
		for i in range(n - 1):
			var p_cur: Vector2 = nodes[i].position + deltas[i]
			var p_nxt: Vector2 = nodes[i + 1].position + deltas[i + 1]
			var min_v_step: float = safe_rect.size.y / float(maxi(4, n + 1)) * 0.42
			if is_n2s:
				# North-to-South: node i+1 must stay below (larger y) node i
				if p_nxt.y < p_cur.y + min_v_step:
					var adjust_y: float = ((p_cur.y + min_v_step) - p_nxt.y) * 0.42
					deltas[i].y -= adjust_y
					deltas[i + 1].y += adjust_y
			else:
				# South-to-North / West-to-East / East-to-West: node i+1 stays above (smaller y) node i
				if p_nxt.y > p_cur.y - min_v_step:
					var adjust_y_s: float = (p_nxt.y - (p_cur.y - min_v_step)) * 0.42
					deltas[i].y += adjust_y_s
					deltas[i + 1].y -= adjust_y_s

		# 4. Apply deltas and clamp strictly onto valid terrain surface (never SKY, DISTANT_HORIZON, or MOUNTAIN_BACKGROUND)
		for i in range(n):
			var nd: MapNode = nodes[i]
			nd.position += deltas[i]
			var is_ms_node: bool = nd.is_milestone_node()
			var island_rx: float = minf(nd.node_size.x * (0.76 if is_ms_node else 0.66) + 6.0, canvas_size.x * 0.165)
			var min_edge_x: float = maxf(safe_rect.position.x * 0.88, island_rx)
			var pad_y: float = maxf(4.0, nd.node_size.y * 0.12)
			nd.position.x = clampf(
				nd.position.x,
				min_edge_x,
				canvas_size.x - min_edge_x
			)
			var min_surf_y: float = (MapRenderer.get_mountain_background_bottom_y_at(page, canvas_rect, nd.position.x, c_key_relax) if is_mtn_node[i] else MapRenderer.get_land_ground_top_y_at(page, canvas_rect, nd.position.x, c_key_relax)) + 3.0
			if nd.position.y < min_surf_y + 10.0:
				# Slide laterally toward lower terrain contour if upper destination sits near elevated ridge
				var lx_try: float = maxf(min_edge_x, nd.position.x - 22.0)
				var rx_try: float = minf(canvas_size.x - min_edge_x, nd.position.x + 22.0)
				var y_left: float = (MapRenderer.get_mountain_background_bottom_y_at(page, canvas_rect, lx_try, c_key_relax) if is_mtn_node[i] else MapRenderer.get_land_ground_top_y_at(page, canvas_rect, lx_try, c_key_relax)) + 3.0
				var y_right: float = (MapRenderer.get_mountain_background_bottom_y_at(page, canvas_rect, rx_try, c_key_relax) if is_mtn_node[i] else MapRenderer.get_land_ground_top_y_at(page, canvas_rect, rx_try, c_key_relax)) + 3.0
				if y_left + 1.0 < min_surf_y:
					nd.position.x = clampf(nd.position.x - 4.0, min_edge_x, canvas_size.x - min_edge_x)
					min_surf_y = (MapRenderer.get_mountain_background_bottom_y_at(page, canvas_rect, nd.position.x, c_key_relax) if is_mtn_node[i] else MapRenderer.get_land_ground_top_y_at(page, canvas_rect, nd.position.x, c_key_relax)) + 3.0
				elif y_right + 1.0 < min_surf_y:
					nd.position.x = clampf(nd.position.x + 4.0, min_edge_x, canvas_size.x - min_edge_x)
					min_surf_y = (MapRenderer.get_mountain_background_bottom_y_at(page, canvas_rect, nd.position.x, c_key_relax) if is_mtn_node[i] else MapRenderer.get_land_ground_top_y_at(page, canvas_rect, nd.position.x, c_key_relax)) + 3.0
			var eff_top_y: float = maxf(safe_rect.position.y + pad_y, min_surf_y + 6.0)
			nd.position.y = clampf(
				nd.position.y,
				eff_top_y,
				safe_rect.position.y + safe_rect.size.y - pad_y
			)

	# Final exact Destination-Footprint & Bounding-Box separation pass so zero overlap is guaranteed
	var min_box_gap: float = 10.0
	for _sep_iter in range(52):
		var any_overlap: bool = false
		for i in range(n):
			var node_a: MapNode = nodes[i]
			var fp_node_a: Dictionary = footprints[i]
			for j in range(i + 1, n):
				var node_b: MapNode = nodes[j]
				var fp_node_b: Dictionary = footprints[j]
				var half_w: float = maxf(
					(node_a.node_size.x + node_b.node_size.x) * 0.5 + min_box_gap,
					(float(fp_node_a["half_w"]) + float(fp_node_b["half_w"])) * 0.88
				)
				var half_h: float = maxf(
					(node_a.node_size.y + node_b.node_size.y) * 0.5 + min_box_gap,
					((float(fp_node_b["top_ext"]) + float(fp_node_a["bot_ext"])) if is_n2s else (float(fp_node_a["top_ext"]) + float(fp_node_b["bot_ext"]))) * 0.86
				)
				var dx: float = node_b.position.x - node_a.position.x
				var dy: float = node_b.position.y - node_a.position.y
				if absf(dx) < half_w and absf(dy) < half_h:
					any_overlap = true
					var pen_x: float = half_w - absf(dx)
					var pen_y: float = half_h - absf(dy)
					var dir_x: float = 1.0 if (dx > 0.0 or (is_zero_approx(dx) and (j % 2 == 0))) else -1.0
					var dir_y: float = 1.0 if is_n2s else -1.0

					var clamp_ax: float = maxf(node_a.node_size.x * 0.5 + 6.0, minf(node_a.node_size.x * (0.76 if node_a.is_milestone_node() else 0.66) + 6.0, canvas_size.x * 0.165))
					var clamp_bx: float = maxf(node_b.node_size.x * 0.5 + 6.0, minf(node_b.node_size.x * (0.76 if node_b.is_milestone_node() else 0.66) + 6.0, canvas_size.x * 0.165))
					var a_at_wall: bool = (node_a.position.x <= clamp_ax + 3.0 and dir_x > 0.0) or (node_a.position.x >= canvas_size.x - clamp_ax - 3.0 and dir_x < 0.0)
					var b_at_wall: bool = (node_b.position.x <= clamp_bx + 3.0 and dir_x < 0.0) or (node_b.position.x >= canvas_size.x - clamp_bx - 3.0 and dir_x > 0.0)
					var share_a: float = 0.15 if a_at_wall else (0.85 if b_at_wall else 0.52)
					var share_b: float = 0.15 if b_at_wall else (0.85 if a_at_wall else 0.52)

					if pen_x <= pen_y * 1.25:
						node_a.position.x -= dir_x * (pen_x * share_a)
						node_b.position.x += dir_x * (pen_x * share_b)
						node_a.position.y -= dir_y * (pen_y * 0.22)
						node_b.position.y += dir_y * (pen_y * 0.22)
					else:
						node_a.position.y -= dir_y * (pen_y * 0.55)
						node_b.position.y += dir_y * (pen_y * 0.55)
						node_a.position.x -= dir_x * (pen_x * share_a * 0.45)
						node_b.position.x += dir_x * (pen_x * share_b * 0.45)
					for idx_clamp in [i, j]:
						var nd_clamp: MapNode = nodes[idx_clamp]
						var half_sz: Vector2 = nd_clamp.node_size * 0.5
						var isl_pad_x: float = minf(nd_clamp.node_size.x * (0.76 if nd_clamp.is_milestone_node() else 0.66) + 6.0, canvas_size.x * 0.165)
						var clamp_x: float = maxf(half_sz.x + 6.0, isl_pad_x)
						nd_clamp.position.x = clampf(nd_clamp.position.x, clamp_x, canvas_size.x - clamp_x)
						var min_surf_c: float = (MapRenderer.get_mountain_background_bottom_y_at(page, canvas_rect, nd_clamp.position.x, c_key_relax) if is_mtn_node[idx_clamp] else MapRenderer.get_land_ground_top_y_at(page, canvas_rect, nd_clamp.position.x, c_key_relax)) + 3.0
						var min_ground_y: float = maxf(maxf(half_sz.y + 8.0, safe_rect.position.y), min_surf_c + 6.0)
						nd_clamp.position.y = clampf(nd_clamp.position.y, min_ground_y, canvas_size.y - half_sz.y - 12.0)

		# Enforce strict sequence order after each separation pass so relaxation never swaps stops
		var min_seq_gap: float = maxf(6.0, safe_rect.size.y / float(maxi(6, n * 3)))
		for i in range(n - 1):
			var cur_nd: MapNode = nodes[i]
			var nxt_nd: MapNode = nodes[i + 1]
			var cur_surf_y: float = (MapRenderer.get_mountain_background_bottom_y_at(page, canvas_rect, cur_nd.position.x, c_key_relax) if is_mtn_node[i] else MapRenderer.get_land_ground_top_y_at(page, canvas_rect, cur_nd.position.x, c_key_relax)) + 3.0
			var nxt_surf_y: float = (MapRenderer.get_mountain_background_bottom_y_at(page, canvas_rect, nxt_nd.position.x, c_key_relax) if is_mtn_node[i + 1] else MapRenderer.get_land_ground_top_y_at(page, canvas_rect, nxt_nd.position.x, c_key_relax)) + 3.0
			var cur_min_y: float = maxf(maxf(cur_nd.node_size.y * 0.5 + 8.0, safe_rect.position.y), cur_surf_y + 6.0)
			var nxt_min_y: float = maxf(maxf(nxt_nd.node_size.y * 0.5 + 8.0, safe_rect.position.y), nxt_surf_y + 6.0)
			if is_n2s and nxt_nd.position.y < cur_nd.position.y + min_seq_gap:
				var mid_y: float = (cur_nd.position.y + nxt_nd.position.y) * 0.5
				cur_nd.position.y = clampf(mid_y - min_seq_gap * 0.55, cur_min_y, canvas_size.y - cur_nd.node_size.y * 0.5 - 12.0)
				nxt_nd.position.y = clampf(cur_nd.position.y + min_seq_gap, nxt_min_y, canvas_size.y - nxt_nd.node_size.y * 0.5 - 12.0)
			elif (not is_n2s) and nxt_nd.position.y > cur_nd.position.y - min_seq_gap:
				var mid_y_s: float = (cur_nd.position.y + nxt_nd.position.y) * 0.5
				cur_nd.position.y = clampf(mid_y_s + min_seq_gap * 0.55, cur_min_y, canvas_size.y - cur_nd.node_size.y * 0.5 - 12.0)
				nxt_nd.position.y = clampf(cur_nd.position.y - min_seq_gap, nxt_min_y, canvas_size.y - nxt_nd.node_size.y * 0.5 - 12.0)

		if not any_overlap:
			break


func _generate_theme_landmarks(page: MapPage, safe_rect: Rect2, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var landmarks: Array[Dictionary] = []
	var theme_obj: MapTheme = page.theme if page.theme != null else MapTheme.from_preset("ocean_islands")
	var lm_types: Array[String] = theme_obj.landmark_types
	if lm_types.is_empty():
		return landmarks

	var canvas_w: float = maxf(280.0, page.last_canvas_size.x)
	var canvas_h: float = maxf(340.0, page.last_canvas_size.y)

	# ONE MAJOR LANDMARK PER PAGE INTEGRATED INTO AN ASYMMETRIC WORLD PROMONTORY:
	# Compute the average horizontal side of the mid-page nodes and place the Major Landmark
	# on the opposite scenic promontory cliff / destination sanctuary so landmark + terrain + path + stops
	# form one deliberate asymmetric composition.
	var mid_u_sum: float = 0.0
	var mid_cnt: int = 0
	for i in range(page.nodes.size()):
		if i > 0 and i < page.nodes.size() - 1:
			mid_u_sum += page.nodes[i].uv_position.x
			mid_cnt += 1
	var avg_mid_u: float = (mid_u_sum / float(mid_cnt)) if mid_cnt > 0 else 0.5
	var prefer_left_promontory: bool = (avg_mid_u >= 0.50)

	var candidate_uvs: Array[Vector2] = [
		Vector2(0.22 if prefer_left_promontory else 0.78, 0.32),
		Vector2(0.20 if prefer_left_promontory else 0.80, 0.48),
		Vector2(0.24 if prefer_left_promontory else 0.76, 0.24),
		Vector2(0.78 if prefer_left_promontory else 0.22, 0.28),
		Vector2(0.22 if prefer_left_promontory else 0.78, 0.62),
		Vector2(0.50, 0.26)
	]
	var sc: float = clampf(rng.randf_range(1.24, 1.35), 1.22, 1.35)
	var lm_margin: float = 28.0 * sc + 6.0
	var best_px := Vector2(clampf(safe_rect.position.x + (0.22 if prefer_left_promontory else 0.78) * safe_rect.size.x, lm_margin, canvas_w - lm_margin), clampf(safe_rect.position.y + 0.32 * safe_rect.size.y, lm_margin, canvas_h - lm_margin))
	var best_uv := Vector2(0.22 if prefer_left_promontory else 0.78, 0.32)
	var best_clearance: float = -1.0

	for idx in range(candidate_uvs.size()):
		var cand_uv: Vector2 = candidate_uvs[idx]
		cand_uv.x = clampf(cand_uv.x + rng.randf_range(-0.025, 0.025), 0.16, 0.84)
		cand_uv.y = clampf(cand_uv.y + rng.randf_range(-0.025, 0.025), 0.18, 0.78)
		var cand_px: Vector2 = safe_rect.position + Vector2(cand_uv.x * safe_rect.size.x, cand_uv.y * safe_rect.size.y)
		cand_px.x = clampf(cand_px.x, lm_margin, maxf(lm_margin, canvas_w - lm_margin))
		cand_px.y = clampf(cand_px.y, lm_margin, maxf(lm_margin, canvas_h - lm_margin))

		var min_dist: float = 99999.0
		for nd in page.nodes:
			var d_node: float = nd.position.distance_to(cand_px) - nd.radius
			min_dist = minf(min_dist, d_node)
		if page.route != null and page.route.smooth_points.size() >= 2:
			for r_idx in range(0, page.route.smooth_points.size(), 3):
				var d_route: float = page.route.smooth_points[r_idx].distance_to(cand_px)
				min_dist = minf(min_dist, d_route * 0.92)

		# Give strong preference to the asymmetric focal side opposite the mid-valley route bend
		var side_bonus: float = 18.0 if (idx < 3) else 0.0
		if min_dist + side_bonus > best_clearance:
			best_clearance = min_dist + side_bonus
			best_px = cand_px
			best_uv = Vector2(
				clampf((cand_px.x - safe_rect.position.x) / maxf(1.0, safe_rect.size.x), 0.12, 0.88),
				clampf((cand_px.y - safe_rect.position.y) / maxf(1.0, safe_rect.size.y), 0.14, 0.82)
			)

	var lm_type: String = lm_types[page.page_index % lm_types.size()]
	var sec_type: String = lm_types[(page.page_index + 1) % lm_types.size()]
	landmarks.append({
		"theme_id": theme_obj.theme_id,
		"landmark_type": lm_type,
		"secondary_landmark_type": sec_type,
		"landmark_classification": "POINT_OF_INTEREST",
		"is_independent_poi": true,
		"connected_to_route": false,
		"has_separate_spur_road": false,
		"is_major_landmark": true,
		"promontory_side": "left" if best_uv.x < 0.5 else "right",
		"uv_position": best_uv,
		"position": best_px,
		"scale": sc
	})
	return landmarks


static func audit_page_horizontal_bounds(page: MapPage, canvas_size: Vector2) -> Dictionary:
	if page == null:
		return {"no_horizontal_overflow": false, "clipped_count": 1}
	var w: float = maxf(280.0, canvas_size.x)
	var min_x: float = 99999.0
	var max_x: float = -99999.0
	var clipped_items: Array[String] = []
	for nd in page.nodes:
		var r: Rect2 = nd.get_bounding_rect()
		var isl_rx: float = minf(nd.node_size.x * (0.76 if nd.is_milestone_node() else 0.66) + 4.0, w * 0.48)
		var left_edge: float = minf(r.position.x, nd.position.x - isl_rx)
		var right_edge: float = maxf(r.end.x, nd.position.x + isl_rx)
		min_x = minf(min_x, left_edge)
		max_x = maxf(max_x, right_edge)
		if left_edge < -0.5 or right_edge > w + 0.5:
			clipped_items.append("node_%d(%.1f..%.1f)" % [nd.level_id, left_edge, right_edge])
	for lm in page.background_landmarks:
		var pos: Vector2 = lm.get("position", Vector2.ZERO)
		var sc: float = float(lm.get("scale", 1.0))
		var lm_rx: float = 28.0 * sc
		min_x = minf(min_x, pos.x - lm_rx)
		max_x = maxf(max_x, pos.x + lm_rx)
		if pos.x - lm_rx < -0.5 or pos.x + lm_rx > w + 0.5:
			clipped_items.append("landmark_%s(%.1f..%.1f)" % [String(lm.get("landmark_type", "")), pos.x - lm_rx, pos.x + lm_rx])
	if page.route != null:
		var route_half_stroke: float = 11.0
		for pt in page.route.smooth_points:
			min_x = minf(min_x, pt.x - route_half_stroke)
			max_x = maxf(max_x, pt.x + route_half_stroke)
			if pt.x - route_half_stroke < -0.5 or pt.x + route_half_stroke > w + 0.5:
				clipped_items.append("route_pt(%.1f)" % pt.x)
				break
	return {
		"no_horizontal_overflow": clipped_items.is_empty(),
		"clipped_count": clipped_items.size(),
		"clipped_items": clipped_items,
		"min_x": min_x,
		"max_x": max_x,
		"canvas_width": w
	}


static func check_zero_node_overlap(nodes: Array, extra_padding_px: float = 0.0) -> Dictionary:
	var overlap_count: int = 0
	var min_center_dist: float = 99999.0
	var min_edge_gap: float = 99999.0
	var n: int = nodes.size()
	for i in range(n):
		var a: MapNode = nodes[i]
		var rect_a: Rect2 = a.get_bounding_rect().grow(extra_padding_px)
		for j in range(i + 1, n):
			var b: MapNode = nodes[j]
			var rect_b: Rect2 = b.get_bounding_rect().grow(extra_padding_px)
			var c_dist: float = a.position.distance_to(b.position)
			var edge_gap: float = c_dist - (a.radius + b.radius)
			min_center_dist = minf(min_center_dist, c_dist)
			min_edge_gap = minf(min_edge_gap, edge_gap)
			if rect_a.intersects(rect_b):
				overlap_count += 1
	return {
		"zero_overlap": overlap_count == 0,
		"overlap_count": overlap_count,
		"min_center_distance_px": min_center_dist if n > 1 else 0.0,
		"min_edge_gap_px": min_edge_gap if n > 1 else 0.0
	}
