class_name MapRoute
extends RefCounted

const MapNode = preload("res://scripts/map_core/map_node.gd")

## MapRoute — Reusable Organic Adventure Route Data Model for 4TM Map Core
## Connects the MapNodes of a MapPage along a smooth, non-grid, non-zigzag curve
## with theme-matched path styling and scenic landmark spurs.

var page_id: String = "page_1"
var composition_type: String = "curved_arc"
var path_style: String = "sea_stepping_stones"
var waypoints: Array[Vector2] = []
var uv_waypoints: Array[Vector2] = []
var elevations: Array[float] = []
var smooth_points: PackedVector2Array = PackedVector2Array()
var unlocked_smooth_points: PackedVector2Array = PackedVector2Array()
var segments: Array[Dictionary] = []
var scenic_spurs: Array[Dictionary] = []


static func sample_catmull_rom_spline(pts: Array[Vector2], subdivisions: int = 12) -> PackedVector2Array:
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


func rebuild_from_nodes(nodes: Array, p_path_style: String, subdivisions: int = 12) -> void:
	path_style = p_path_style
	waypoints.clear()
	uv_waypoints.clear()
	elevations.clear()
	segments.clear()

	var min_wp_x: float = 99999.0
	var max_wp_x: float = -99999.0
	var min_wp_y: float = 99999.0
	var max_wp_y: float = -99999.0
	var highest_unlocked_local: int = 0
	for i in range(nodes.size()):
		var nd = nodes[i]
		waypoints.append(nd.position)
		uv_waypoints.append(nd.uv_position)
		elevations.append(nd.elevation)
		min_wp_x = minf(min_wp_x, nd.position.x - nd.node_size.x * 0.45)
		max_wp_x = maxf(max_wp_x, nd.position.x + nd.node_size.x * 0.45)
		min_wp_y = minf(min_wp_y, nd.position.y - nd.node_size.y * 0.45)
		max_wp_y = maxf(max_wp_y, nd.position.y + nd.node_size.y * 0.45)
		if nd.is_unlocked:
			highest_unlocked_local = i

	var raw_smooth: PackedVector2Array = sample_catmull_rom_spline(waypoints, subdivisions)
	smooth_points = PackedVector2Array()
	for pt in raw_smooth:
		smooth_points.append(Vector2(
			clampf(pt.x, maxf(14.0, min_wp_x), max_wp_x),
			clampf(pt.y, maxf(14.0, min_wp_y), max_wp_y)
		))

	unlocked_smooth_points = PackedVector2Array()
	if highest_unlocked_local > 0:
		var u_pts: Array[Vector2] = []
		for i in range(highest_unlocked_local + 1):
			u_pts.append(waypoints[i])
		var raw_u_smooth: PackedVector2Array = sample_catmull_rom_spline(u_pts, subdivisions)
		for pt_u in raw_u_smooth:
			unlocked_smooth_points.append(Vector2(
				clampf(pt_u.x, maxf(14.0, min_wp_x), max_wp_x),
				clampf(pt_u.y, maxf(14.0, min_wp_y), max_wp_y)
			))

	for i in range(nodes.size() - 1):
		var n_a = nodes[i]
		var n_b = nodes[i + 1]
		var seg_style: String = String(n_a.route_connection.get("segment_style", path_style))
		var mid_pt: Vector2 = n_a.position.lerp(n_b.position, 0.5)
		segments.append({
			"segment_index": i,
			"from_level_id": n_a.level_id,
			"to_level_id": n_b.level_id,
			"from_pos": n_a.position,
			"to_pos": n_b.position,
			"mid_pos": mid_pt,
			"from_uv": n_a.uv_position,
			"to_uv": n_b.uv_position,
			"from_elevation": n_a.elevation,
			"to_elevation": n_b.elevation,
			"segment_style": seg_style,
			"length_px": n_a.position.distance_to(n_b.position),
			"unlocked": n_a.is_unlocked and n_b.is_unlocked
		})


func get_min_non_adjacent_path_node_clearance() -> float:
	if waypoints.size() <= 2:
		return 999.0
	var min_dist: float = 999.0
	for seg_i in range(waypoints.size() - 1):
		var a: Vector2 = waypoints[seg_i]
		var b: Vector2 = waypoints[seg_i + 1]
		for node_i in range(waypoints.size()):
			if node_i == seg_i or node_i == seg_i + 1:
				continue
			var p: Vector2 = waypoints[node_i]
			var close_pt: Vector2 = Geometry2D.get_closest_point_to_segment(p, a, b)
			min_dist = minf(min_dist, p.distance_to(close_pt))
	return min_dist


func to_dict() -> Dictionary:
	return {
		"page_id": page_id,
		"composition_type": composition_type,
		"path_style": path_style,
		"waypoint_count": waypoints.size(),
		"smooth_point_count": smooth_points.size(),
		"segments": segments.duplicate(true),
		"scenic_spurs": scenic_spurs.duplicate(true),
		"min_non_adjacent_clearance_px": get_min_non_adjacent_path_node_clearance()
	}
