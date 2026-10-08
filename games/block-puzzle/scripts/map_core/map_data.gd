class_name MapData
extends RefCounted

const MapTheme = preload("res://scripts/map_core/map_theme.gd")
const MapRoute = preload("res://scripts/map_core/map_route.gd")
const MapNode = preload("res://scripts/map_core/map_node.gd")
const MapPage = preload("res://scripts/map_core/map_page.gd")
const MapLayoutGenerator = preload("res://scripts/map_core/map_layout_generator.gd")

## MapData — Reusable World Container for the 4TM Map Core Engine
## Hierarchy: World (MapData) -> Map Pages (MapPage) -> Level Nodes (MapNode)
## Supports any number of pages and any number of levels per page (e.g. 5–10 levels/page).

var world_id: String = "world_main"
var world_title_en: String = "Adventure World"
var world_title_vi: String = "Thế Giới Phiêu Lưu"
var pages: Array[MapPage] = []
var level_to_page_index: Dictionary = {}
var total_levels: int = 0
var layout_generator: MapLayoutGenerator = null


func _init(p_world_id: String = "world_main") -> void:
	world_id = p_world_id
	layout_generator = MapLayoutGenerator.new()


func clear() -> void:
	pages.clear()
	level_to_page_index.clear()
	total_levels = 0


func add_page(page: MapPage) -> void:
	if page == null:
		return
	page.page_index = pages.size()
	page.page_number = page.page_index + 1
	if page.page_id == "" or page.page_id.begins_with("page_"):
		page.page_id = "page_%d" % page.page_number
	pages.append(page)
	for lv_id in page.level_ids:
		level_to_page_index[int(lv_id)] = page.page_index
		if int(lv_id) > total_levels:
			total_levels = int(lv_id)


func configure_from_page_specs(page_specs: Array) -> void:
	clear()
	var next_level_id: int = 1
	for idx in range(page_specs.size()):
		var spec: Dictionary = page_specs[idx]
		var explicit_levels: Array[int] = []
		if spec.has("level_ids") and spec["level_ids"] is Array and not spec["level_ids"].is_empty():
			for lv in spec["level_ids"]:
				explicit_levels.append(int(lv))
			next_level_id = explicit_levels[explicit_levels.size() - 1] + 1
		else:
			var count: int = maxi(1, int(spec.get("level_count", 6)))
			for _k in range(count):
				explicit_levels.append(next_level_id)
				next_level_id += 1

		var theme_obj: MapTheme = null
		if spec.get("theme") is MapTheme:
			theme_obj = spec["theme"]
		elif spec.get("theme") is Dictionary:
			theme_obj = MapTheme.from_dict(spec["theme"])
		else:
			var theme_id: String = String(spec.get("theme_id", MapTheme.PRESET_THEME_IDS[idx % MapTheme.PRESET_THEME_IDS.size()]))
			theme_obj = MapTheme.from_preset(theme_id)

		var seed_val: int = int(spec.get("seed_value", 1337 + (idx + 1) * 7919))
		var comp_type: String = String(spec.get("composition_type", MapLayoutGenerator.get_composition_for_page(idx, seed_val)))

		var page := MapPage.new(idx, explicit_levels, theme_obj, comp_type, seed_val)
		page.title_en = String(spec.get("title_en", theme_obj.name_en))
		page.title_vi = String(spec.get("title_vi", theme_obj.name_vi))
		page.subtitle_en = String(spec.get("subtitle_en", ""))
		page.subtitle_vi = String(spec.get("subtitle_vi", ""))
		page.country_id = String(spec.get("country_id", ""))
		page.country_name_en = String(spec.get("country_name_en", ""))
		page.country_name_vi = String(spec.get("country_name_vi", ""))
		page.journey_direction = String(spec.get("journey_direction", "north_to_south"))
		page.authority_source = String(spec.get("authority_source", ""))
		page.landmark_density = String(spec.get("landmark_density", "moderate"))
		if spec.get("country_destinations") is Array:
			page.country_destinations.clear()
			for d_item in spec["country_destinations"]:
				if d_item is Dictionary:
					page.country_destinations.append(d_item.duplicate(true))
		if spec.get("active_level_destinations") is Array:
			page.active_level_destinations.clear()
			for a_item in spec["active_level_destinations"]:
				if a_item is Dictionary:
					page.active_level_destinations.append(a_item.duplicate(true))
		if spec.get("omitted_destinations") is Array:
			page.omitted_destinations.clear()
			for o_item in spec["omitted_destinations"]:
				if o_item is Dictionary:
					page.omitted_destinations.append(o_item.duplicate(true))
		if spec.get("independent_poi") is Dictionary:
			page.independent_poi = (spec["independent_poi"] as Dictionary).duplicate(true)
		if spec.get("canonical_gameplay_background") is Dictionary:
			page.canonical_gameplay_background = (spec["canonical_gameplay_background"] as Dictionary).duplicate(true)

		# Populate data-driven milestone definitions
		if spec.has("milestones") and spec["milestones"] is Dictionary:
			var m_dict: Dictionary = spec["milestones"]
			for key in m_dict.keys():
				var lv_key: int = int(key)
				if m_dict[key] is Dictionary:
					page.set_milestone_spec(lv_key, m_dict[key])

		add_page(page)


func get_page_count() -> int:
	return pages.size()


func get_page(page_index: int) -> MapPage:
	if pages.is_empty():
		return null
	var clamped: int = clampi(page_index, 0, pages.size() - 1)
	return pages[clamped]


func get_page_by_number(page_number: int) -> MapPage:
	return get_page(page_number - 1)


func get_page_index_for_level(level_id: int) -> int:
	var clamped_lv: int = clampi(level_id, 1, maxi(1, total_levels))
	if level_to_page_index.has(clamped_lv):
		return int(level_to_page_index[clamped_lv])
	for i in range(pages.size()):
		if pages[i].contains_level(clamped_lv):
			return i
	return 0


func get_page_number_for_level(level_id: int) -> int:
	return get_page_index_for_level(level_id) + 1


func get_page_for_level(level_id: int) -> MapPage:
	return get_page(get_page_index_for_level(level_id))


func build_page_layout(page_index: int, canvas_size: Vector2, progression_provider: Dictionary = {}) -> MapPage:
	var page: MapPage = get_page(page_index)
	if page == null:
		return null
	layout_generator.generate_page_layout(page, canvas_size, progression_provider)
	return page


func get_node_for_level(level_id: int, canvas_size: Vector2 = Vector2(390, 620), progression_provider: Dictionary = {}) -> MapNode:
	var p_idx: int = get_page_index_for_level(level_id)
	var page: MapPage = get_page(p_idx)
	if page == null:
		return null
	if page.nodes.is_empty() or page.last_canvas_size.distance_to(canvas_size) > 1.0:
		layout_generator.generate_page_layout(page, canvas_size, progression_provider)
	return page.get_node_for_level(level_id)


func to_summary_dict() -> Dictionary:
	var page_counts: Array[int] = []
	var theme_ids: Array[String] = []
	for p in pages:
		page_counts.append(p.get_level_count())
		theme_ids.append(p.theme.theme_id if p.theme != null else "")
	return {
		"world_id": world_id,
		"page_count": pages.size(),
		"total_levels": total_levels,
		"page_level_counts": page_counts,
		"page_theme_ids": theme_ids
	}
