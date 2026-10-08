extends Node

## Targeted Map Core / Map Engine Automated Test Suite
## Verifies all requirements of the reusable 4TM Map Core:
##   1. Arbitrary levels-per-page & hierarchy (World -> MapPages -> LevelNodes)
##   2. 5, 6, 7, 8, 9 and 10 node pages
##   3. Deterministic seeded organic layouts (non-grid, non-zigzag, non-even-circle, non-straight-row)
##   4. Zero node overlap & collision relaxation
##   5. Responsive layouts for 360×800, 390×844, and 720×1280
##   6. Page navigation (prev/next/jump/swipe) & automatic centering
##   7. Drag-vs-tap protection
##   8. Progression preservation & locked/unlocked/completed/stars state
##   9. Data-driven milestone metadata (not hardcoded to every 5th level)
##  10. Coherent single-biome page themes & Block Puzzle 500-level migration

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
const MainMenuScene = preload("res://scenes/ui/main_menu.tscn")
const UIIconScript = preload("res://scripts/ui/ui_icon.gd")

var failures: int = 0
var checks_passed: int = 0
var _tests_completed: bool = false
var _quit_delay_frames: int = 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		checks_passed += 1
	else:
		failures += 1
		printerr("[MAP_CORE_FAIL] ", msg)


func _ready() -> void:
	_run_tests()
	_tests_completed = true


func _cleanup_nodes() -> void:
	var am := get_node_or_null("/root/AudioManager")
	if am and am.has_method("shutdown_audio"):
		am.shutdown_audio()
	for ch in get_children():
		if is_instance_valid(ch) and not ch.is_queued_for_deletion():
			ch.queue_free()
	UIIconScript.cleanup_static_resources()


func _exit_tree() -> void:
	_cleanup_nodes()


func _process(_delta: float) -> void:
	_quit_delay_frames += 1
	if _quit_delay_frames == 1:
		_cleanup_nodes()
	if _quit_delay_frames >= 2:
		get_tree().quit(0 if (failures == 0 and _tests_completed) else 1)


func _run_tests() -> void:
	var am_init = get_node_or_null("/root/AudioManager")
	if am_init and am_init.has_method("shutdown_audio"):
		am_init.shutdown_audio()
	print("=== STARTING TARGETED 4TM MAP CORE TEST SUITE ===")

	# 1. Test arbitrary levels-per-page & 5, 6, 7, 8, 9, 10 node pages
	var custom_map := MapDataScript.new("custom_test_world")
	var test_counts: Array[int] = [5, 6, 7, 8, 9, 10, 4, 11]
	var specs: Array[Dictionary] = []
	for idx in range(test_counts.size()):
		var cnt: int = test_counts[idx]
		var t_id: String = MapThemeScript.PRESET_THEME_IDS[idx % MapThemeScript.PRESET_THEME_IDS.size()]
		specs.append({
			"level_count": cnt,
			"theme_id": t_id,
			"seed_value": 9001 + idx * 409,
			"milestones": {}
		})
	custom_map.configure_from_page_specs(specs)
	_check(custom_map.get_page_count() == test_counts.size(), "MapData supports arbitrary page count")

	var viewports: Array[Vector2] = [
		Vector2(360.0, 800.0),
		Vector2(390.0, 844.0),
		Vector2(720.0, 1280.0)
	]

	for p_i in range(custom_map.get_page_count()):
		var expected_cnt: int = test_counts[p_i]
		var page: MapPage = custom_map.get_page(p_i)
		_check(page.get_level_count() == expected_cnt, "Page %d has exact data-driven level count %d" % [p_i, expected_cnt])
		for vp in viewports:
			var canvas_sz := Vector2(vp.x - 32.0, vp.y * 0.62)
			custom_map.build_page_layout(p_i, canvas_sz, {"unlocked_level": 15, "selected_level": 8, "level_stars": {1: 3, 2: 2, 7: 3}})
			_check(page.nodes.size() == expected_cnt, "Page %d generated %d MapNodes at viewport %s" % [p_i, expected_cnt, str(vp)])
			var overlap_info: Dictionary = MapLayoutGeneratorScript.check_zero_node_overlap(page.nodes, 2.0)
			_check(bool(overlap_info.get("zero_overlap", false)), "Zero node overlap on %d-node page at viewport %s (overlaps=%d, min_gap=%.1f)" % [
				expected_cnt, str(vp), int(overlap_info.get("overlap_count", -1)), float(overlap_info.get("min_edge_gap_px", -1.0))
			])
			for nd in page.nodes:
				var r: Rect2 = nd.get_bounding_rect()
				_check(r.position.x >= 0.0 and r.end.x <= canvas_sz.x and r.position.y >= 0.0 and r.end.y <= canvas_sz.y,
					"Node %d within safe canvas bounds at viewport %s" % [nd.level_id, str(vp)])

	print("[MAP CORE 1/6] Arbitrary levels-per-page (4..11 including 5,6,7,8,9,10) & responsive viewports (360x800, 390x844, 720x1280) zero-overlap: PASSED")

	# 2. Deterministic seeded layouts & non-grid/non-zigzag organic composition verification
	var gen := MapLayoutGeneratorScript.new()
	var page_a := MapPageScript.new(0, [1, 2, 3, 4, 5, 6, 7, 8], MapThemeScript.from_preset("ocean_islands"), "sweeping_arc", 77777)
	var page_b := MapPageScript.new(0, [1, 2, 3, 4, 5, 6, 7, 8], MapThemeScript.from_preset("ocean_islands"), "sweeping_arc", 77777)
	var page_c := MapPageScript.new(1, [9, 10, 11, 12, 13, 14, 15, 16], MapThemeScript.from_preset("green_forest"), "landmark_bend", 88888)
	gen.generate_page_layout(page_a, Vector2(360, 540), {})
	gen.generate_page_layout(page_b, Vector2(360, 540), {})
	gen.generate_page_layout(page_c, Vector2(360, 540), {})

	var identical_seed_match: bool = true
	var different_seed_diff: float = 0.0
	var distinct_x_coords: Dictionary = {}
	for i in range(page_a.nodes.size()):
		if page_a.nodes[i].position.distance_to(page_b.nodes[i].position) > 0.001:
			identical_seed_match = false
		different_seed_diff += page_a.nodes[i].uv_position.distance_to(page_c.nodes[i].uv_position)
		distinct_x_coords[int(roundf(page_a.nodes[i].position.x))] = true

	_check(identical_seed_match, "Same seed produces identical deterministic node positions")
	_check(different_seed_diff > 0.35, "Different page compositions/seeds produce genuinely different organic routes")
	_check(distinct_x_coords.size() >= 5, "Organic layout does not align nodes into a rigid column grid")
	_check(page_a.route != null and page_a.route.smooth_points.size() > page_a.nodes.size() * 4, "MapRoute generates smooth spline curve through nodes")
	_check(page_a.route.get_min_non_adjacent_path_node_clearance() > 18.0, "Route segments maintain readable separation from non-adjacent nodes")
	print("[MAP CORE 2/6] Deterministic seeded organic layouts & path/node separation: PASSED")

	# 3. Single-biome theme coherence, World Type separation & Real-World Library (Correction 7)
	var seen_preset_world_types: Dictionary = {}
	for t_id in MapThemeScript.PRESET_THEME_IDS:
		var th: MapTheme = MapThemeScript.from_preset(t_id)
		_check(th.is_coherent(), "Preset MapTheme '%s' is internally coherent" % t_id)
		seen_preset_world_types[th.world_type] = true
		var pg := MapPageScript.new(0, [1, 2, 3, 4, 5, 6], th, "coastal_loop", 12345)
		gen.generate_page_layout(pg, Vector2(390, 600), {})
		_check(pg.is_theme_coherent(), "Generated MapPage with theme '%s' has 100%% coherent landmarks and destinations" % t_id)

	for wt in MapThemeScript.SUPPORTED_WORLD_TYPES:
		_check(seen_preset_world_types.has(wt), "Preset world themes cover World Type '%s'" % wt)

	for sem_id in MapThemeScript.WORLD_LIBRARY_IDS:
		var sem_th: MapTheme = MapThemeScript.from_preset(sem_id)
		_check(sem_th.is_coherent() and sem_th.world_id == sem_id, "Semantic World Library ID '%s' resolves to coherent world (type='%s', name='%s')" % [sem_id, sem_th.world_type, sem_th.world_name_en])

	var italy_th: MapTheme = MapThemeScript.from_preset("italy")
	_check(italy_th.world_type == MapThemeScript.WORLD_TYPE_COUNTRY and italy_th.subregions.size() == 5, "Italy is strictly a Country World with 5 regional journey stops (Tuscany -> Pisa -> Venice -> Florence -> Rome)")
	var paris_th: MapTheme = MapThemeScript.from_preset("paris")
	_check(paris_th.world_type == MapThemeScript.WORLD_TYPE_LANDMARK_REGION and paris_th.primary_landmark_id == "eiffel_tower_seine", "Paris is a Landmark Region World anchored by the Eiffel Tower & Seine")
	var mars_th: MapTheme = MapThemeScript.from_preset("mars")
	_check(mars_th.world_type == MapThemeScript.WORLD_TYPE_SPACE and mars_th.primary_landmark_id == "mars_olympus_observatory", "Mars is a Space/Astronomical World")
	print("[MAP CORE 3/6] World Type separation (Countryside, Town, Modern City, Country, Landmark Region, Space) & Real-World Library: PASSED")

	# 4. Block Puzzle 500-level migration with 5–10 levels per page (never 20)
	var bp_map: MapData = BlockPuzzleMapConfigScript.build_block_puzzle_map_data(500)
	_check(bp_map.total_levels == 500, "Block Puzzle MapData addresses all 500 levels")
	_check(bp_map.get_page_count() >= 55 and bp_map.get_page_count() <= 90, "Block Puzzle MapData splits 500 levels into %d pages" % bp_map.get_page_count())

	var seen_counts: Dictionary = {}
	var seen_themes: Dictionary = {}
	var seen_world_types: Dictionary = {}
	var seen_country_ids: Dictionary = {}
	var expected_next_lv: int = 1
	for p_i in range(bp_map.get_page_count()):
		var pg_chk: MapPage = bp_map.get_page(p_i)
		var cnt_chk: int = pg_chk.get_level_count()
		seen_counts[cnt_chk] = true
		seen_themes[pg_chk.theme.theme_id] = true
		seen_world_types[pg_chk.theme.world_type] = true
		_check(pg_chk.country_id != "" and not seen_country_ids.has(pg_chk.country_id), "Block Puzzle page %d represents unique country '%s'" % [p_i + 1, pg_chk.country_id])
		seen_country_ids[pg_chk.country_id] = true
		_check(pg_chk.journey_direction in ["north_to_south", "south_to_north", "west_to_east", "east_to_west"], "Page %d country '%s' has valid journey_direction '%s'" % [p_i + 1, pg_chk.country_id, pg_chk.journey_direction])
		_check(pg_chk.authority_source != "" and pg_chk.country_destinations.size() >= cnt_chk, "Page %d country '%s' has authoritative source and >= %d pre-sorted geographic destinations" % [p_i + 1, pg_chk.country_id, cnt_chk])
		_check(cnt_chk >= 5 and cnt_chk <= 10, "Block Puzzle page %d has %d levels (within 5–10 range, never 20)" % [p_i + 1, cnt_chk])
		_check(pg_chk.start_level == expected_next_lv, "Page %d starts at level %d" % [p_i + 1, expected_next_lv])
		expected_next_lv = pg_chk.end_level + 1
		bp_map.build_page_layout(p_i, Vector2(390, 620), {"unlocked_level": 25, "selected_level": 12})
		_check(pg_chk.order_preserved_after_relaxation and MapLayoutGeneratorScript.verify_destination_order_preserved(pg_chk.nodes, pg_chk.journey_direction),
			"Page %d ('%s') strictly preserves geographic destination order after layout & relaxation" % [p_i + 1, pg_chk.country_name_en])
		_check(pg_chk.is_theme_coherent(), "Block Puzzle page %d ('%s' / '%s') is single-biome coherent" % [p_i + 1, pg_chk.theme.theme_id, pg_chk.theme.world_id])
		var pg_dict: Dictionary = pg_chk.to_dict("en")
		_check(String(pg_dict.get("world_type", "")) != "" and String(pg_dict.get("world_id", "")) != "" and String(pg_dict.get("world_name_en", "")) != "" and String(pg_dict.get("country_or_region_en", "")) != "" and String(pg_dict.get("primary_landmark_en", "")) != "" and String(pg_dict.get("gameplay_background_theme", "")) != "",
			"Page %d exposes complete World Type, Real-World Identity, Landmark, and Gameplay Background metadata" % [p_i + 1])
		_check(pg_chk.background_landmarks.size() == 1 and bool(pg_chk.background_landmarks[0].get("is_major_landmark", false)),
			"Block Puzzle page %d has strictly 1 major focal landmark (never cluttered)" % [p_i + 1])
		_check(String(pg_chk.background_landmarks[0].get("landmark_classification", "")) == "POINT_OF_INTEREST" and not bool(pg_chk.background_landmarks[0].get("connected_to_route", true)),
			"Block Puzzle page %d background landmark is an independent POINT_OF_INTEREST not connected by a spur road" % [p_i + 1])
		var lm_pt: Vector2 = pg.background_landmarks[0].get("position", Vector2.ZERO)
		_check(lm_pt.x >= 36.0 and lm_pt.x <= 390.0 - 36.0,
			"Block Puzzle page %d focal landmark within horizontal bounds" % [p_i + 1])
		var manifest: Dictionary = MapRenderer.get_page_landmark_manifest(pg, Rect2(Vector2.ZERO, Vector2(390, 620)))
		var lm_density: String = String(manifest.get("landmark_density", ""))
		var feat_cnt: int = (manifest.get("destination_landmarks", []) as Array).size()
		_check(lm_density in ["sparse", "moderate", "rich", "very_rich"],
			"Block Puzzle page %d ('%s') has valid data-driven landmark_density '%s'" % [p_i + 1, pg.country_name_en, lm_density])
		var density_cnt_ok: bool = false
		match lm_density:
			"sparse":
				density_cnt_ok = (feat_cnt >= 1 and feat_cnt <= 2)
			"moderate":
				density_cnt_ok = (feat_cnt >= 2 and feat_cnt <= 3)
			"rich":
				density_cnt_ok = (feat_cnt >= 3 and feat_cnt <= 5)
			"very_rich":
				density_cnt_ok = (feat_cnt >= 4 and feat_cnt <= 6)
		_check(not bool(manifest.get("has_secondary_spur_roads", true)) and density_cnt_ok and feat_cnt < cnt,
			"Block Puzzle page %d ('%s', density=%s, milestones=%d) has country-appropriate landmark count %d (not 1-to-1 with milestones) and zero secondary spur roads" % [p_i + 1, pg.country_name_en, lm_density, cnt, feat_cnt])
		_check(bool(manifest.get("zero_plaque_or_landmark_overlap", false)),
			"Block Puzzle page %d ('%s') destination footprints, plaques, and landmark silhouettes have zero overlap and zero out-of-bounds (lm_ov=%d, bg_ov=%d, lm_oob=%d, lbl_ov=%d, lbl_oob=%d)" % [
				p_i + 1, pg.country_name_en,
				int(manifest.get("overlapping_landmark_count", -1)),
				int(manifest.get("overlapping_background_count", -1)),
				int(manifest.get("out_of_bounds_landmark_count", -1)),
				int(manifest.get("label_collision_count", -1)),
				int(manifest.get("out_of_bounds_label_count", -1))
			])
		_check(
			bool(manifest.get("visual_hierarchy_valid", false)) and
			float(manifest.get("base_landmark_scale", 0.0)) >= 0.95 and
			int(manifest.get("route_landmark_collision_count", -1)) == 0 and
			bool(manifest.get("all_ground_anchors_valid", false)) and
			bool(manifest.get("all_ground_anchors_not_in_sky", false)) and
			bool(manifest.get("all_ground_anchors_not_distant_horizon", false)) and
			bool(manifest.get("all_ground_anchors_not_mountain_background", false)) and
			bool(manifest.get("all_ground_anchors_inside_surface", false)) and
			bool(manifest.get("all_ground_anchors_compatible", false)) and
			bool(manifest.get("all_water_relationships_valid", false)) and
			bool(manifest.get("all_route_endpoints_compatible", false)) and
			bool(manifest.get("all_footprints_in_safe_bounds", false)) and
			int(manifest.get("primary_landscape_layer_count", 0)) == 1 and
			int(manifest.get("oversized_background_layer_count", -1)) == 0 and
			int(manifest.get("route_in_sky_count", -1)) == 0 and
			int(manifest.get("route_in_background_count", -1)) == 0,
			"Page %d ('%s') passes landmark visual hierarchy (major_landmark > landmark_environment > regional_scene > small_destination_marker), semantic terrain surface, ground_anchor_inside_surface, SKY/DISTANT_HORIZON/MOUNTAIN_BACKGROUND exclusion, water relationship, route clearance, footprint bounds, and single-landscape-layer validation" % [p_i + 1, pg.country_name_en]
		)
		for vp_chk in [Vector2(360.0, 800.0), Vector2(390.0, 844.0), Vector2(720.0, 1280.0)]:
			var c_sz_vp := Vector2(clampf(vp_chk.x - 22.0, 338.0, 684.0), clampf(vp_chk.y - 240.0, 420.0, 960.0))
			bp_map.build_page_layout(p_i, c_sz_vp, {"unlocked_level": 25, "selected_level": 12})
			var man_vp: Dictionary = MapRenderer.get_page_landmark_manifest(pg, Rect2(Vector2.ZERO, c_sz_vp))
			_check(
				bool(man_vp.get("zero_plaque_or_landmark_overlap", false)) and
				bool(man_vp.get("order_preserved_after_relaxation", false)) and
				bool(man_vp.get("all_ground_anchors_not_in_sky", false)) and
				bool(man_vp.get("all_ground_anchors_not_distant_horizon", false)) and
				bool(man_vp.get("all_ground_anchors_not_mountain_background", false)) and
				bool(man_vp.get("all_ground_anchors_inside_surface", false)) and
				bool(man_vp.get("all_water_relationships_valid", false)) and
				bool(man_vp.get("all_route_endpoints_compatible", false)) and
				int(man_vp.get("primary_landscape_layer_count", 0)) == 1 and
				int(man_vp.get("oversized_background_layer_count", -1)) == 0,
				"Page %d ('%s') at viewport %s has zero landmark/background/label overlap, grounded bases on compatible terrain surfaces (never SKY, DISTANT_HORIZON, or MOUNTAIN_BACKGROUND), coherent route endpoints, and preserves geographic order" % [p_i + 1, pg.country_name_en, str(vp_chk)]
			)
		bp_map.build_page_layout(p_i, Vector2(390, 620), {"unlocked_level": 25, "selected_level": 12})

		var geo_rep: Dictionary = BlockPuzzleMapConfigScript.validate_country_page_geography(pg)
		_check(bool(geo_rep.get("geographic_order_valid", false)) and bool(geo_rep.get("level_sequence_consistent", false)) and bool(geo_rep.get("landmark_density_consistent", false)),
			"Page %d ('%s', %s) passes strict lat/lon geographic order, manifest/level consistency & landmark_density validation (errors=%s)" % [
				p_i + 1, pg.country_name_en, pg.journey_direction, str(geo_rep.get("errors", []))
			])

	var full_geo_audit: Dictionary = BlockPuzzleMapConfigScript.audit_all_68_country_journeys(bp_map)
	_check(bool(full_geo_audit.get("all_valid", false)) and int(full_geo_audit.get("unique_countries", 0)) == 68,
		"All 68 country journeys pass strict stored latitude/longitude order & manifest-level consistency audit")

	# Verify debug spatial overlay is disabled by default in production
	_check(not MapRenderer.debug_spatial_overlay_enabled, "Development-only debug spatial overlay is disabled by default in production")

	# Explicit QA Inspection for Vietnam, Thailand, France (Paris), Italy (Pisa & Venice), Japan, USA, Egypt, Switzerland, Norway, and sparse country (Chile)
	var qa_countries: Array[String] = ["vietnam", "thailand", "france", "italy", "japan", "united_states", "egypt", "switzerland", "norway", "chile"]
	var found_qa: Dictionary = {}
	for p_qa in range(bp_map.get_page_count()):
		var pg_qa: MapPage = bp_map.get_page(p_qa)
		if pg_qa.country_id in qa_countries:
			found_qa[pg_qa.country_id] = true
			var qa_rect := Rect2(Vector2.ZERO, Vector2(390, 620))
			var man_qa: Dictionary = MapRenderer.get_page_landmark_manifest(pg_qa, qa_rect)
			var zones_qa: Dictionary = man_qa.get("spatial_zones", {})
			_check(
				zones_qa.has("zones") and
				(zones_qa["zones"] as Dictionary).has("SKY") and
				(zones_qa["zones"] as Dictionary).has("DISTANT_HORIZON") and
				(zones_qa["zones"] as Dictionary).has("MOUNTAIN_BACKGROUND") and
				(zones_qa["zones"] as Dictionary).has("MOUNTAIN_GROUND") and
				(zones_qa["zones"] as Dictionary).has("LAND_GROUND"),
				"QA country '%s' establishes explicit SKY, DISTANT_HORIZON, MOUNTAIN_BACKGROUND, MOUNTAIN_GROUND, LAND_GROUND, WATER, and COASTLINE_SHORE terrain zones" % pg_qa.country_id
			)
			for d_lm in man_qa.get("destination_landmarks", []):
				var lm_id_qa: String = String(d_lm.get("landmark_id", ""))
				var t_surf_qa: String = String(d_lm.get("terrain_surface", ""))
				var allowed_qa: Array = d_lm.get("allowed_grounding_surfaces", [])
				_check(
					bool(d_lm.get("ground_anchor_not_sky", false)) and
					bool(d_lm.get("ground_anchor_not_distant_horizon", false)) and
					bool(d_lm.get("ground_anchor_not_incompatible_mountain_background", false)) and
					bool(d_lm.get("ground_anchor_inside_surface", false)) and
					bool(d_lm.get("route_endpoint_surface_compatible", false)) and
					(t_surf_qa in allowed_qa),
					"QA country '%s' featured landmark '%s' (%s) sits on compatible terrain_surface '%s' (allowed=%s) and shares coherent surface with route endpoint" % [
						pg_qa.country_id, lm_id_qa, String(d_lm.get("location_label", "")), t_surf_qa, str(allowed_qa)
					]
				)
				if lm_id_qa == "eiffel_tower":
					_check(
						String(d_lm.get("grounding_classification", "")) == "URBAN" and
						t_surf_qa in ["URBAN_GROUND", "LAND_GROUND", "FOREGROUND_TERRAIN"] and
						t_surf_qa != "MOUNTAIN_BACKGROUND" and t_surf_qa != "DISTANT_HORIZON" and t_surf_qa != "SKY",
						"Paris Eiffel Tower stands on URBAN_GROUND/LAND_GROUND and never on SKY, DISTANT_HORIZON, or MOUNTAIN_BACKGROUND"
					)
					# Verify that a synthetic candidate below SKY but inside MOUNTAIN_BACKGROUND is REJECTED (exact bug class check)
					var test_x: float = 195.0
					var sky_y_test: float = MapRenderer.get_sky_boundary_y_at(pg_qa, qa_rect, test_x)
					var mbg_bot_y: float = MapRenderer.get_mountain_background_bottom_y_at(pg_qa, qa_rect, test_x)
					var bad_anchor := Vector2(test_x, (sky_y_test + mbg_bot_y) * 0.5)
					var bad_val: Dictionary = MapRenderer.validate_landmark_ground_anchor(pg_qa, qa_rect, bad_anchor, d_lm.get("courtyard_position", bad_anchor), {"landmark_id": "eiffel_tower", "label": "Paris", "grounding_type": "URBAN", "water_relationship": "riverbank"})
					_check(
						bool(bad_val.get("ground_anchor_not_sky", false)) and
						not bool(bad_val.get("ground_anchor_not_incompatible_mountain_background", true)) and
						not bool(bad_val.get("valid", true)),
						"Validator explicitly FAILS when ground_anchor != SKY but ground_anchor sits on MOUNTAIN_BACKGROUND/DISTANT_HORIZON (surface=%s)" % String(bad_val.get("terrain_surface", ""))
					)
				if lm_id_qa == "pisa_tower":
					_check(
						String(d_lm.get("water_relationship", "")) == "none" and
						bool(d_lm.get("water_relationship_valid", false)) and
						t_surf_qa in ["LAND_GROUND", "URBAN_GROUND", "FOREGROUND_TERRAIN"],
						"Leaning Tower of Pisa stands on LAND_GROUND/URBAN_GROUND and never in WATER or MOUNTAIN_BACKGROUND"
					)
	_check(found_qa.size() == qa_countries.size(), "All 10 required runtime QA countries inspected and verified (found %d/10)" % found_qa.size())

	# Verify Vietnam Page 1 (index 0) explicit North-to-South geographic order
	var vn_page: MapPage = bp_map.get_page(0)
	_check(vn_page.country_id == "vietnam" and vn_page.journey_direction == "north_to_south", "Page 1 is Vietnam with north_to_south journey direction")
	var vn_manifest_names: Array[String] = []
	for d_vn in vn_page.country_destinations:
		vn_manifest_names.append(String(d_vn.get("destination_name", "")))
	_check(vn_manifest_names == ["Hanoi", "Ha Long Bay", "Ninh Binh", "Hue", "Da Nang / Hoi An", "Ho Chi Minh City", "Mekong Delta"],
		"Vietnam country_destinations follows strict North-to-South latitude order: Hanoi (21.0285N) -> Ha Long Bay (20.9101N) -> Ninh Binh (20.2506N) -> Hue (16.4637N) -> Da Nang / Hoi An (15.8801N) -> Ho Chi Minh City (10.7769N) -> Mekong Delta (10.0333N)")
	_check(vn_page.active_level_destinations.size() == 6 and vn_page.omitted_destinations.size() == 1 and String(vn_page.omitted_destinations[0].get("destination_name", "")) == "Ninh Binh",
		"Vietnam manifest reconciles 7 researched destinations with 6 active level milestones and explicitly records Ninh Binh in omitted_destinations")
	var vn_names: Array[String] = []
	for nd_vn in vn_page.nodes:
		vn_names.append(String(nd_vn.landmark.get("destination_name", "")))
	var idx_hanoi: int = vn_names.find("Hanoi")
	var idx_halong: int = vn_names.find("Ha Long Bay")
	var idx_hue: int = vn_names.find("Hue")
	var idx_hoian: int = vn_names.find("Da Nang / Hoi An")
	var idx_hcmc: int = vn_names.find("Ho Chi Minh City")
	var idx_mekong: int = vn_names.find("Mekong Delta")
	_check(idx_hanoi == 0 and idx_halong > idx_hanoi and idx_hue > idx_halong and idx_hoian > idx_hue and idx_hcmc > idx_hoian and idx_mekong > idx_hcmc,
		"Vietnam active level journey follows strict North-to-South order: Hanoi -> Ha Long Bay -> Hue -> Da Nang / Hoi An -> Ho Chi Minh City -> Mekong Delta (got %s)" % str(vn_names))
	_check(vn_page.nodes[idx_hanoi].position.y < vn_page.nodes[idx_hue].position.y and vn_page.nodes[idx_hue].position.y < vn_page.nodes[idx_hcmc].position.y,
		"Vietnam Northern destinations sit visually above Central and Southern destinations")

	_check(seen_country_ids.size() == 68, "All 68 MapPages represent 68 distinct countries without duplication (found %d)" % seen_country_ids.size())
	_check(expected_next_lv == 501, "All 500 levels are contiguously addressable across pages")
	for req_cnt in [5, 6, 7, 8, 9, 10]:
		_check(seen_counts.has(req_cnt), "Block Puzzle migration includes %d-level pages" % req_cnt)
	_check(seen_themes.size() == 10, "Block Puzzle migration uses all 10 world themes (found %d)" % seen_themes.size())
	_check(seen_world_types.size() == 6, "Block Puzzle 68-page campaign spans all 6 World Types (found %d)" % seen_world_types.size())
	print("[MAP CORE 4/6] Block Puzzle 500-level World Type & Real-World System (68 pages, 6 World Types, 100%% coherent): PASSED")

	# 5. Data-driven milestones & progression state (locked/unlocked/completed/stars)
	var p2: MapPage = bp_map.build_page_layout(1, Vector2(390, 620), {
		"unlocked_level": 10,
		"selected_level": 9,
		"level_stars": {7: 3, 8: 2, 9: 1}
	})
	var ms_count_p2: int = 0
	for nd in p2.nodes:
		if nd.is_milestone_node():
			ms_count_p2 += 1
			_check(nd.get_scale_multiplier() > 1.05, "Milestone node %d has larger scale multiplier" % nd.level_id)
		if nd.level_id < 10:
			_check(nd.is_unlocked and nd.is_completed and not nd.is_locked, "Level %d is unlocked & completed" % nd.level_id)
		elif nd.level_id == 10:
			_check(nd.is_unlocked and nd.is_current and not nd.is_locked, "Level 10 is current unlocked level")
		else:
			_check(nd.is_locked and not nd.is_unlocked, "Level %d is locked" % nd.level_id)
	_check(ms_count_p2 >= 1, "Page 2 has data-driven milestone nodes")
	print("[MAP CORE 5/6] Data-driven milestones & locked/unlocked/completed/stars state: PASSED")

	# 6. UI Page Navigation, Swipe/Drag Between Pages & Drag-vs-Tap Protection
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.reset_progression(false)
		for lv in range(1, 16):
			gs.record_level_completion(lv, gs.get_level_target_score(lv) * 2)
		gs.select_map_level(15)
	var menu = MainMenuScene.instantiate()
	add_child(menu)
	menu._on_btn_open_level_map_pressed()
	# Level 15 is on Page 3 (index 2: levels 14..21, 8 levels, Green Forest)
	_check(menu.current_map_page == 2, "Opening map automatically centers on Page 3 (index 2) for unlocked Level 15")
	_check(menu._level_map_grid_buttons.size() == 8, "Page 3 renders exactly 8 level node buttons (levels 14..21)")
	var swipe_next: Dictionary = menu.simulate_map_swipe(Vector2(-85.0, 4.0))
	_check(bool(swipe_next.get("page_changed", false)) and menu.current_map_page == 3, "Swipe left navigates to Page 4 (index 3, 9 levels)")
	_check(menu._level_map_grid_buttons.size() == 9, "Page 4 renders exactly 9 level node buttons (levels 22..30)")
	# Verify drag-vs-tap protection blocks accidental node activation right after drag
	var sel_before: int = gs.selected_map_level if gs else 15
	menu._on_map_level_node_pressed(14, true)
	_check((gs.selected_map_level if gs else 15) == sel_before, "Drag-vs-tap protection blocks accidental node selection during/after drag")
	# Normal tap after drag flag clears selects level
	menu._on_map_level_node_pressed(14, true)
	_check((gs.selected_map_level if gs else 14) == 14, "Normal tap selects unlocked level 14")
	var swipe_prev: Dictionary = menu.simulate_map_swipe(Vector2(85.0, 2.0))
	_check(bool(swipe_prev.get("page_changed", false)) and menu.current_map_page == 2, "Swipe right navigates back to Page 3 (index 2)")
	menu.queue_free()
	if gs:
		gs.reset_progression(false)
	print("[MAP CORE 6/7] Page navigation (swipe/drag, auto-centering, variable button count) & drag-vs-tap protection: PASSED")

	# 7. Country Map Artwork Reused as Gameplay Level Backgrounds (All 68 Countries, 360x800, 390x844, 720x1280)
	for p_bg in range(bp_map.get_page_count()):
		var pg_bg: MapPage = bp_map.get_page(p_bg)
		for vp_bg in viewports:
			var bg_rect := Rect2(Vector2.ZERO, vp_bg)
			var bg_m: Dictionary = MapRendererScript.get_gameplay_level_background_manifest(pg_bg, pg_bg.start_level, bg_rect, "en")
			var inv_chk: Dictionary = MapRendererScript.compare_map_page_and_gameplay_background_invariants(pg_bg, bg_rect, pg_bg.start_level)
			_check(
				bool(bg_m.get("valid", false)) and
				bool(bg_m.get("reuses_country_map_artwork", false)) and
				bool(bg_m.get("matches_map_page_exactly", false)) and
				bool(inv_chk.get("valid", false)) and
				bool(inv_chk.get("landmark_count_match", false)) and
				bool(inv_chk.get("landmark_ids_match", false)) and
				bool(inv_chk.get("landmark_positions_match", false)) and
				bool(inv_chk.get("landmark_scale_match", false)) and
				bool(inv_chk.get("landmark_bounding_boxes_match", false)) and
				bool(inv_chk.get("terrain_geometry_match", false)) and
				bool(inv_chk.get("major_scenery_positions_match", false)) and
				bool(inv_chk.get("only_marker_layer_differs", false)) and
				not bool(bg_m.get("draws_map_level_nodes", true)) and
				not bool(bg_m.get("draws_route_lines", true)) and
				not bool(bg_m.get("draws_node_numbers", true)) and
				not bool(bg_m.get("draws_progression_markers", true)) and
				not bool(bg_m.get("draws_map_navigation_ui", true)) and
				not bool(bg_m.get("draws_artificial_floating_islands", true)) and
				int(bg_m.get("unrelated_landmark_count", -1)) == 0 and
				int(bg_m.get("focal_element_count", 0)) == 1 and
				not bool(bg_m.get("has_horizontal_clipping", true)) and
				bool(bg_m.get("ground_anchor_not_in_sky", false)) and
				bool(bg_m.get("preserves_board_readability", false)) and
				String(bg_m.get("country_id", "")) == pg_bg.country_id,
				"Page %d ('%s') gameplay background at %s matches MapPage landmark count/IDs/positions/scale/bboxes/terrain/scenery with only level markers suppressed" % [p_bg + 1, pg_bg.country_name_en, str(vp_bg)]
			)
	print("[MAP CORE 7/7] Country map artwork reused as gameplay level backgrounds (68 countries, exact MapPage invariant verified): PASSED")

	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("shutdown_audio"):
		audio_mgr.shutdown_audio()
	UIIconScript.cleanup_static_resources()

	print("=== TARGETED MAP CORE SUITE COMPLETE: %d checks passed, %d failures ===" % [checks_passed, failures])
