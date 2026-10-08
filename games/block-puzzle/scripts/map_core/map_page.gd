class_name MapPage
extends RefCounted

const MapTheme = preload("res://scripts/map_core/map_theme.gd")
const MapRoute = preload("res://scripts/map_core/map_route.gd")
const MapNode = preload("res://scripts/map_core/map_node.gd")

## MapPage — Self-Contained Visual World in the 4TM Map Core Hierarchy
## Hierarchy: World (MapData) -> Map Pages (MapPage) -> Level Nodes (MapNode)
## Each MapPage has:
##   - Arbitrary data-driven level count (e.g. 5–10 levels, or any custom count)
##   - Strictly ONE coherent MapTheme / biome (never mixes unrelated biomes)
##   - Deterministic seeded organic layout composition
##   - Data-driven milestone definitions (not hardcoded to every 5th level)
##   - Matching landmarks, terrain, route style, and atmosphere

var page_id: String = "page_1"
var page_index: int = 0
var page_number: int = 1
var title_en: String = ""
var title_vi: String = ""
var subtitle_en: String = ""
var subtitle_vi: String = ""

var start_level: int = 1
var end_level: int = 6
var level_ids: Array[int] = []

var theme: MapTheme = null
var composition_type: String = "sweeping_arc"
var seed_value: int = 10101

## Geographic Country Journey Manifest (1 Page = 1 Country, pre-ordered along journey_direction)
var country_id: String = ""
var country_name_en: String = ""
var country_name_vi: String = ""
var journey_direction: String = "north_to_south"
var authority_source: String = ""
var landmark_density: String = "moderate"
var country_destinations: Array[Dictionary] = []
var active_level_destinations: Array[Dictionary] = []
var omitted_destinations: Array[Dictionary] = []
var independent_poi: Dictionary = {}
var canonical_gameplay_background: Dictionary = {}
var order_preserved_after_relaxation: bool = true

## Data-driven milestone specifications keyed by level_id (int)
var milestone_specs: Dictionary = {}

## Generated layout nodes and organic route for the current viewport size
var nodes: Array = []
var route: MapRoute = null
var background_landmarks: Array[Dictionary] = []
var last_canvas_size: Vector2 = Vector2.ZERO


func _init(p_page_index: int = 0, p_level_ids: Array[int] = [], p_theme: MapTheme = null, p_composition: String = "sweeping_arc", p_seed: int = 0) -> void:
	page_index = maxi(0, p_page_index)
	page_number = page_index + 1
	page_id = "page_%d" % page_number
	theme = p_theme if p_theme != null else MapTheme.from_preset("ocean_islands")
	composition_type = p_composition
	seed_value = p_seed if p_seed != 0 else (1337 + page_number * 7919)
	set_levels(p_level_ids)


func set_levels(p_level_ids: Array[int]) -> void:
	level_ids.clear()
	for lv in p_level_ids:
		level_ids.append(int(lv))
	if level_ids.is_empty():
		start_level = 1
		end_level = 1
	else:
		start_level = level_ids[0]
		end_level = level_ids[level_ids.size() - 1]


func get_level_count() -> int:
	return level_ids.size()


func contains_level(level_id: int) -> bool:
	return level_ids.has(level_id)


func get_local_index_for_level(level_id: int) -> int:
	return level_ids.find(level_id)


func get_node_for_level(level_id: int) -> MapNode:
	for nd in nodes:
		if nd.level_id == level_id:
			return nd
	return null


func set_milestone_spec(level_id: int, spec: Dictionary) -> void:
	milestone_specs[level_id] = spec.duplicate(true)


func get_milestone_spec(level_id: int) -> Dictionary:
	if milestone_specs.has(level_id):
		return milestone_specs[level_id].duplicate(true)
	return {
		"is_milestone": false,
		"milestone_type": "",
		"milestone_icon": "",
		"scale_mult": 1.0,
		"halo_radius": 0.0,
		"visual_tier": 0
	}


func get_display_title(lang: String = "en") -> String:
	var base_name: String = ""
	if lang == "vi":
		base_name = title_vi if title_vi != "" else (theme.name_vi if theme != null else "Vùng Đất %d" % page_number)
	else:
		base_name = title_en if title_en != "" else (theme.name_en if theme != null else "World %d" % page_number)
	return base_name


func get_display_subtitle(lang: String = "en") -> String:
	if lang == "vi":
		if subtitle_vi != "":
			return subtitle_vi
		return "Màn %d – %d (%d màn)" % [start_level, end_level, get_level_count()]
	if subtitle_en != "":
		return subtitle_en
	return "Levels %d – %d (%d levels)" % [start_level, end_level, get_level_count()]


func is_theme_coherent() -> bool:
	if theme == null or not theme.is_coherent():
		return false
	for lm in background_landmarks:
		if String(lm.get("theme_id", theme.theme_id)) != theme.theme_id:
			return false
		var lm_type: String = String(lm.get("landmark_type", ""))
		if lm_type != "" and not theme.landmark_types.has(lm_type):
			return false
	for nd in nodes:
		var dest_style: String = String(nd.landmark.get("destination_style", ""))
		if dest_style != "" and not theme.destination_styles.has(dest_style):
			return false
	return true


func get_page_progress_summary() -> Dictionary:
	var completed_count: int = 0
	var unlocked_count: int = 0
	var earned_stars: int = 0
	var max_stars: int = get_level_count() * 3
	for nd in nodes:
		if nd.is_completed:
			completed_count += 1
		if nd.is_unlocked:
			unlocked_count += 1
		earned_stars += int(nd.stars)
	return {
		"page_id": page_id,
		"page_index": page_index,
		"page_number": page_number,
		"level_count": get_level_count(),
		"start_level": start_level,
		"end_level": end_level,
		"completed_count": completed_count,
		"unlocked_count": unlocked_count,
		"earned_stars": earned_stars,
		"max_stars": max_stars,
		"is_page_unlocked": unlocked_count > 0,
		"is_page_completed": get_level_count() > 0 and completed_count >= get_level_count()
	}


func to_dict(lang: String = "en") -> Dictionary:
	var node_dicts: Array[Dictionary] = []
	for nd in nodes:
		node_dicts.append(nd.to_dict())
	var theme_dict: Dictionary = theme.to_dict() if theme != null else {}
	var summary: Dictionary = get_page_progress_summary()
	return {
		"page_id": page_id,
		"page_index": page_index,
		"page_number": page_number,
		"chapter": page_number,
		"name": get_display_title(lang),
		"name_en": get_display_title("en"),
		"name_vi": get_display_title("vi"),
		"subtitle": get_display_subtitle(lang),
		"start_level": start_level,
		"end_level": end_level,
		"level_count": get_level_count(),
		"level_ids": level_ids.duplicate(),
		"composition_type": composition_type,
		"seed_value": seed_value,
		"theme": theme_dict,
		"theme_id": theme.theme_id if theme != null else "",
		"world_type": theme.world_type if theme != null else "landmark_region",
		"world_id": theme.world_id if theme != null else "ha_long_bay",
		"country_id": country_id if country_id != "" else (theme.world_id if theme != null else "vietnam"),
		"country_name_en": country_name_en if country_name_en != "" else (theme.country_or_region_en if theme != null else "Vietnam"),
		"country_name_vi": country_name_vi if country_name_vi != "" else (theme.country_or_region_vi if theme != null else "Việt Nam"),
		"journey_direction": journey_direction,
		"authority_source": authority_source,
		"landmark_density": landmark_density,
		"country_destinations": country_destinations.duplicate(true),
		"active_level_destinations": active_level_destinations.duplicate(true),
		"omitted_destinations": omitted_destinations.duplicate(true),
		"independent_poi": independent_poi.duplicate(true),
		"order_preserved_after_relaxation": order_preserved_after_relaxation,
		"world_name_en": theme.world_name_en if theme != null else "",
		"world_name_vi": theme.world_name_vi if theme != null else "",
		"country_or_region_en": theme.country_or_region_en if theme != null else "",
		"country_or_region_vi": theme.country_or_region_vi if theme != null else "",
		"primary_landmark_en": theme.primary_landmark_en if theme != null else "",
		"primary_landmark_vi": theme.primary_landmark_vi if theme != null else "",
		"gameplay_background_theme": theme.gameplay_background_theme if theme != null else "",
		"region_id": theme.region_id if theme != null else "",
		"region_name_en": theme.region_name_en if theme != null else "",
		"region_name_vi": theme.region_name_vi if theme != null else "",
		"subregions": theme.subregions.duplicate() if theme != null else [],
		"subregion_names_en": theme.subregion_names_en.duplicate() if theme != null else [],
		"subregion_names_vi": theme.subregion_names_vi.duplicate() if theme != null else [],
		"gameplay_backgrounds": theme.gameplay_backgrounds.duplicate() if theme != null else [],
		"dominant_environment": theme.dominant_environment if theme != null else "",
		"terrain_style": theme.terrain_style if theme != null else "",
		"path_style": theme.path_style if theme != null else "",
		"atmosphere_style": theme.atmosphere_style if theme != null else "",
		"particle_style": theme.particle_style if theme != null else "",
		"palette": theme.palette.duplicate(true) if theme != null else {},
		"sky_top": theme.palette.get("sky_top", Color(0.08, 0.42, 0.86)) if theme != null else Color(0.08, 0.42, 0.86),
		"sky_bottom": theme.palette.get("sky_bottom", Color(0.36, 0.78, 0.98)) if theme != null else Color(0.36, 0.78, 0.98),
		"ground_primary": theme.palette.get("ground_primary", Color(0.05, 0.44, 0.78)) if theme != null else Color(0.05, 0.44, 0.78),
		"ground_secondary": theme.palette.get("ground_secondary", Color(0.16, 0.78, 0.92)) if theme != null else Color(0.16, 0.78, 0.92),
		"water_color": theme.palette.get("water_color", Color(0.08, 0.56, 0.88)) if theme != null else Color(0.08, 0.56, 0.88),
		"path_outer": theme.palette.get("path_outer", Color(1.0, 0.86, 0.32)) if theme != null else Color(1.0, 0.86, 0.32),
		"path_inner": theme.palette.get("path_inner", Color(1.0, 0.96, 0.78)) if theme != null else Color(1.0, 0.96, 0.78),
		"accent_color": theme.palette.get("accent_color", Color(0.26, 0.94, 1.0)) if theme != null else Color(0.26, 0.94, 1.0),
		"landmark": theme.landmark_types[0] if (theme != null and not theme.landmark_types.is_empty()) else "shrine",
		"landmarks": background_landmarks.duplicate(true),
		"nodes": node_dicts,
		"route": route.to_dict() if route != null else {},
		"is_theme_coherent": is_theme_coherent(),
		"progress": summary
	}
