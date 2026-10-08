class_name MapNode
extends RefCounted

## MapNode — Reusable Level Destination Data Model for 4TM Map Core
## Stores data-driven metadata for a single level destination on a MapPage:
##   - level_id, page_id, page_index, local_index
##   - position (canvas px), uv_position (0..1), elevation (0..1)
##   - node_type ("normal", "milestone", "page_entry", "page_finale")
##   - milestone dictionary (data-driven milestone type, icon, scale_mult, halo_radius, visual_tier)
##   - locked / unlocked / completed / current / selected state
##   - stars, target_score
##   - landmark & route_connection metadata

var level_id: int = 1
var page_id: String = "page_1"
var page_index: int = 0
var local_index: int = 0

var position: Vector2 = Vector2.ZERO
var uv_position: Vector2 = Vector2(0.5, 0.5)
var elevation: float = 0.25
var radius: float = 28.0
var node_size: Vector2 = Vector2(58.0, 54.0)

var node_type: String = "normal"
var milestone: Dictionary = {
	"is_milestone": false,
	"milestone_type": "",
	"milestone_icon": "",
	"scale_mult": 1.0,
	"halo_radius": 0.0,
	"visual_tier": 0
}

var state: String = "locked"
var is_locked: bool = true
var is_unlocked: bool = false
var is_completed: bool = false
var is_current: bool = false
var is_selected: bool = false
var stars: int = 0
var target_score: int = 500

var landmark: Dictionary = {
	"landmark_type": "sandy_cay_island",
	"destination_style": "sandy_cay_island",
	"destination_place_type": "scenic_viewpoint",
	"terrain_surface": "atoll_islands",
	"world_type": "landmark_region",
	"world_id": "ha_long_bay",
	"subregion_id": "bai_chay_harbor",
	"subregion_name_en": "Bai Chay Harbor",
	"subregion_name_vi": "Cảng Bãi Cháy",
	"gameplay_background": "halong_harbor_coast",
	"scale": 1.0
}

var route_connection: Dictionary = {
	"from_level_id": 1,
	"to_level_id": 2,
	"segment_style": "sea_stepping_stones",
	"control_points": [],
	"has_scenic_spur": false,
	"spur_target_uv": Vector2.ZERO,
	"spur_landmark": ""
}


func get_bounding_rect() -> Rect2:
	return Rect2(position - node_size * 0.5, node_size)


func get_top_left_position() -> Vector2:
	return position - node_size * 0.5


func is_milestone_node() -> bool:
	return bool(milestone.get("is_milestone", false)) or String(milestone.get("milestone_type", "")) != ""


func get_milestone_type() -> String:
	return String(milestone.get("milestone_type", ""))


func get_scale_multiplier() -> float:
	return float(milestone.get("scale_mult", 1.0))


func to_dict() -> Dictionary:
	var m_type: String = get_milestone_type()
	var m_icon: String = String(milestone.get("milestone_icon", ""))
	var is_ms: bool = is_milestone_node()
	return {
		"level": level_id,
		"level_id": level_id,
		"page_id": page_id,
		"page_index": page_index,
		"local_index": local_index,
		"position": position,
		"uv_position": uv_position,
		"organic_u": uv_position.x,
		"organic_v": uv_position.y,
		"elevation_z": elevation,
		"radius": radius,
		"node_size": node_size,
		"node_type": node_type,
		"milestone": milestone.duplicate(true),
		"is_milestone": is_ms,
		"milestone_type": m_type,
		"milestone_icon": m_icon,
		"scale_mult": get_scale_multiplier(),
		"visual_tier": int(milestone.get("visual_tier", 0)),
		"state": state,
		"locked": is_locked,
		"unlocked": is_unlocked,
		"completed": is_completed,
		"current": is_current,
		"is_selected": is_selected,
		"stars": stars,
		"target_score": target_score,
		"landmark": landmark.duplicate(true),
		"world_type": String(landmark.get("world_type", "landmark_region")),
		"world_id": String(landmark.get("world_id", "ha_long_bay")),
		"destination_place_type": String(landmark.get("destination_place_type", "scenic_viewpoint")),
		"subregion_id": String(landmark.get("subregion_id", "coastal_bay")),
		"subregion_name_en": String(landmark.get("subregion_name_en", "")),
		"subregion_name_vi": String(landmark.get("subregion_name_vi", "")),
		"gameplay_background": String(landmark.get("gameplay_background", "halong_karst_bay")),
		"destination_architecture": String(landmark.get("destination_style", "carved_platform")),
		"terrain_surface_type": String(landmark.get("terrain_surface", "emerald_turf_terrace")),
		"island_landmark": String(landmark.get("landmark_type", "shrine")),
		"is_milestone_island": is_ms,
		"route_connection": route_connection.duplicate(true),
		"route_segment_type": String(route_connection.get("segment_style", "carved_terrain_road")),
		"route_segment_to_next": String(route_connection.get("segment_style", "carved_terrain_road"))
	}
