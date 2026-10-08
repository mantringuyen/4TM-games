class_name PieceTray
extends Control

## PieceTray — 3-piece Drag & Drop spawn dock for Block Puzzle — 4TM
## Always spawns 3 available 3-or-4-cell pieces at the start of each round,
## automatically generates 3 new pieces when all 3 are placed,
## guarantees tray piece recovery when any drag is cancelled or released outside the board,
## and supports selecting a piece to replace when Modern CHANGE BLOCK is active.

signal piece_drag_started(piece: Control)
signal piece_drag_moved(piece: Control, global_pos: Vector2)
signal piece_drag_ended(piece: Control, global_pos: Vector2)
signal piece_drag_cancelled(piece: Control, reason: String)
signal piece_rotated(piece: Control)
signal piece_selected_for_change(slot_idx: int, piece: Control)
signal tray_replenished()

const TRAY_PIECE_SCENE = preload("res://scenes/game/tray_piece.tscn")
const Board = preload("res://scripts/game/board.gd")
const PolyominoLib = preload("res://scripts/core/polyomino_library.gd")
const UIIconScript = preload("res://scripts/ui/ui_icon.gd")
const GameTypographyScript = preload("res://scripts/ui/game_typography.gd")
const SLOT_COUNT: int = 3

var SLOT_CENTERS: Array[Vector2] = [
	Vector2(115, 72),
	Vector2(340, 72),
	Vector2(565, 72)
]

var slots: Array = []
var active_pieces: Array = [null, null, null]
var active_dragging_piece: Control = null
var btn_drag_rotate: Button = null
var round_number: int = 0
var change_block_selection_active: bool = false
var board_cell_size: float = 54.8
var board_cell_gap: float = 4.0
var board_to_tray_gap: float = 68.0


func _ready() -> void:
	_ensure_slots()
	_ensure_rotate_control()
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_signal("language_changed"):
		if not gs.language_changed.is_connected(_on_language_changed):
			gs.language_changed.connect(_on_language_changed)
	queue_redraw()


func _on_language_changed(_lang: String) -> void:
	_refresh_rotate_button_text()


func _ensure_rotate_control() -> void:
	if btn_drag_rotate and is_instance_valid(btn_drag_rotate):
		return
	btn_drag_rotate = get_node_or_null("BtnDragRotate") as Button
	if not btn_drag_rotate:
		btn_drag_rotate = Button.new()
		btn_drag_rotate.name = "BtnDragRotate"
		add_child(btn_drag_rotate)
	btn_drag_rotate.custom_minimum_size = Vector2(184, 52)
	btn_drag_rotate.size = Vector2(184, 52)
	btn_drag_rotate.z_index = 95
	btn_drag_rotate.focus_mode = Control.FOCUS_NONE
	btn_drag_rotate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_drag_rotate.add_theme_font_override("font", GameTypographyScript.get_hud_number_font(0.20, 1))
	btn_drag_rotate.add_theme_font_size_override("font_size", 18)
	btn_drag_rotate.add_theme_color_override("font_color", Color(1.0, 0.98, 0.88, 1.0))
	btn_drag_rotate.add_theme_color_override("font_shadow_color", Color(0.08, 0.02, 0.18, 0.85))
	btn_drag_rotate.add_theme_constant_override("shadow_offset_x", 1)
	btn_drag_rotate.add_theme_constant_override("shadow_offset_y", 2)

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.42, 0.16, 0.64, 0.98)
	st.border_width_left = 2
	st.border_width_top = 2
	st.border_width_right = 2
	st.border_width_bottom = 5
	st.border_color = Color(1.0, 0.88, 0.28, 1.0)
	st.corner_radius_top_left = 20
	st.corner_radius_top_right = 20
	st.corner_radius_bottom_right = 20
	st.corner_radius_bottom_left = 20
	st.content_margin_left = 8.0
	st.content_margin_right = 8.0
	st.content_margin_top = 4.0
	st.content_margin_bottom = 6.0
	st.shadow_color = Color(0.04, 0.02, 0.14, 0.55)
	st.shadow_size = 8
	st.shadow_offset = Vector2(0, 3)

	var st_hov := st.duplicate()
	st_hov.bg_color = Color(0.50, 0.22, 0.74, 0.99)
	var st_press := st.duplicate()
	st_press.bg_color = Color(0.34, 0.12, 0.52, 0.99)
	st_press.border_width_bottom = 2

	btn_drag_rotate.add_theme_stylebox_override("normal", st)
	btn_drag_rotate.add_theme_stylebox_override("hover", st_hov)
	btn_drag_rotate.add_theme_stylebox_override("pressed", st_press)
	UIIconScript.attach_to_button(btn_drag_rotate, "turn", Vector2(22, 22), "left", Color(1.0, 0.92, 0.34, 1.0))
	if not btn_drag_rotate.pressed.is_connected(_on_btn_drag_rotate_pressed):
		btn_drag_rotate.pressed.connect(_on_btn_drag_rotate_pressed)
	_refresh_rotate_button_text()
	_layout_rotate_control()
	btn_drag_rotate.visible = (get_active_dragging_piece() != null)


func _refresh_rotate_button_text() -> void:
	if not btn_drag_rotate:
		return
	var gs = get_node_or_null("/root/GameState")
	var is_vi: bool = (gs.get_language() == "vi") if (gs and gs.has_method("get_language")) else false
	btn_drag_rotate.text = "   XOAY 90°" if is_vi else "   ROTATE"


func set_board_to_tray_gap(gap_px: float) -> void:
	board_to_tray_gap = maxf(gap_px, 48.0)
	_layout_rotate_control()


func _layout_rotate_control() -> void:
	if not btn_drag_rotate:
		return
	var tray_w: float = size.x if size.x > 60.0 else (custom_minimum_size.x if custom_minimum_size.x > 60.0 else 680.0)
	var tray_h: float = size.y if size.y > 40.0 else (custom_minimum_size.y if custom_minimum_size.y > 40.0 else 120.0)
	var eff_gap: float = maxf(board_to_tray_gap, 48.0)
	var btn_w: float = clampf(tray_w * 0.34, 144.0, 206.0)
	var max_btn_h: float = maxf(38.0, eff_gap - 12.0)
	var btn_h: float = minf(clampf(tray_h * 0.44, 42.0, 50.0), max_btn_h)
	btn_drag_rotate.add_theme_font_size_override("font_size", 16 if tray_w <= 400.0 else 18)
	btn_drag_rotate.custom_minimum_size = Vector2(btn_w, btn_h)
	btn_drag_rotate.size = Vector2(btn_w, btn_h)
	var actual_sz: Vector2 = btn_drag_rotate.size
	btn_drag_rotate.position = Vector2((tray_w - actual_sz.x) * 0.5, -eff_gap * 0.5 - actual_sz.y * 0.5)


func get_rotate_button_rect_in_parent() -> Rect2:
	_ensure_rotate_control()
	_layout_rotate_control()
	if not btn_drag_rotate:
		return Rect2()
	return Rect2(position + btn_drag_rotate.position, btn_drag_rotate.size)


func get_drag_rotate_button() -> Button:
	_ensure_rotate_control()
	return btn_drag_rotate


func is_point_on_rotate_button(global_pt: Vector2) -> bool:
	if not btn_drag_rotate or not btn_drag_rotate.visible:
		return false
	var rect := Rect2(btn_drag_rotate.global_position, btn_drag_rotate.size)
	return rect.grow(6.0).has_point(global_pt)


func get_active_dragging_piece() -> Control:
	if active_dragging_piece != null and is_instance_valid(active_dragging_piece) and not active_dragging_piece.is_queued_for_deletion() and active_dragging_piece.is_dragging:
		return active_dragging_piece
	for p in active_pieces:
		if p != null and is_instance_valid(p) and not p.is_queued_for_deletion() and p.is_dragging:
			active_dragging_piece = p
			return p
	return null


func rotate_active_dragged_piece() -> bool:
	var dragging_p: Control = get_active_dragging_piece()
	if not dragging_p or not dragging_p.has_method("rotate_dragged_piece"):
		return false
	return dragging_p.rotate_dragged_piece()


func _on_btn_drag_rotate_pressed() -> void:
	rotate_active_dragged_piece()


func _draw() -> void:
	# Draw 3 light translucent glass pedestals for the 3 tray slots so the level environment shows through
	var pod_style = StyleBoxFlat.new()
	pod_style.bg_color = Color(0.14, 0.22, 0.52, 0.42) if change_block_selection_active else Color(0.06, 0.10, 0.22, 0.18)
	pod_style.border_width_left = 1
	pod_style.border_width_top = 1
	pod_style.border_width_right = 1
	pod_style.border_width_bottom = 2
	pod_style.border_color = Color(1.0, 0.88, 0.28, 0.92) if change_block_selection_active else Color(0.78, 0.90, 1.0, 0.30)
	pod_style.corner_radius_top_left = 16
	pod_style.corner_radius_top_right = 16
	pod_style.corner_radius_bottom_right = 16
	pod_style.corner_radius_bottom_left = 16
	
	var slot_w = (size.x if size.x > 60.0 else 680.0) / float(SLOT_COUNT)
	var pod_w = min(slot_w - 18.0, 198.0)
	var pod_h = min((size.y if size.y > 40.0 else 144.0) - 18.0, 124.0)
	for i in range(SLOT_COUNT):
		var c = SLOT_CENTERS[i]
		var rect = Rect2(c - Vector2(pod_w * 0.5, pod_h * 0.5), Vector2(pod_w, pod_h))
		draw_style_box(pod_style, rect)
		draw_circle(c, 3.0, Color(1.0, 0.94, 0.68, 0.16))


func _ensure_slots() -> void:
	if slots.is_empty():
		var s0 = get_node_or_null("Slot0")
		var s1 = get_node_or_null("Slot1")
		var s2 = get_node_or_null("Slot2")
		if s0 and s1 and s2:
			slots = [s0, s1, s2]
		else:
			slots = [
				{"position": SLOT_CENTERS[0]},
				{"position": SLOT_CENTERS[1]},
				{"position": SLOT_CENTERS[2]}
			]


func set_board_cell_metrics(new_cell_size: float, new_cell_gap: float) -> void:
	if new_cell_size > 10.0:
		board_cell_size = new_cell_size
	if new_cell_gap >= 0.0:
		board_cell_gap = new_cell_gap
	for i in range(SLOT_COUNT):
		var p = active_pieces[i]
		if p != null and is_instance_valid(p) and not p.is_queued_for_deletion():
			if p.has_method("set_board_cell_metrics"):
				p.set_board_cell_metrics(board_cell_size, board_cell_gap)
	update_responsive_layout(size.x if size.x > 60.0 else 680.0)


func set_change_block_highlight(active: bool) -> void:
	if active:
		cancel_all_active_drags("change_block_activated")
	change_block_selection_active = active
	for piece in active_pieces:
		if piece != null and is_instance_valid(piece) and not piece.is_queued_for_deletion():
			if "change_select_mode" in piece:
				piece.change_select_mode = active
			piece.modulate = Color(1.25, 1.25, 0.78, 1.0) if active else Color(1, 1, 1, 1)
	queue_redraw()


func _pick_valid_replacement_shape(old_id: String, cur_lvl: int, board_ref: Node2D = null) -> Dictionary:
	var candidates: Array[String] = []
	for raw_key in PolyominoLib.ACTIVE_SHAPE_KEYS:
		var key := String(raw_key)
		if key == old_id:
			continue
		var sdata: Dictionary = PolyominoLib.SHAPES.get(key, {})
		var scells: Array = sdata.get("cells", [])
		if not PolyominoLib.is_valid_active_piece_size(scells.size()):
			continue
		if board_ref != null and board_ref.has_method("has_any_valid_placement"):
			if not board_ref.has_any_valid_placement(scells):
				continue
		candidates.append(key)
	if candidates.is_empty():
		return {}
	var chosen_key: String = candidates[randi() % candidates.size()]
	return PolyominoLib.stamp_piece_material(PolyominoLib.get_shape(chosen_key), cur_lvl)


func find_eligible_slot_for_change(board_ref: Node2D = null) -> int:
	var gs = get_node_or_null("/root/GameState")
	var cur_lvl: int = gs.active_level if (gs and "active_level" in gs) else 1
	var first_valid_slot: int = -1
	for i in range(SLOT_COUNT):
		var p = active_pieces[i]
		if p == null or not is_instance_valid(p) or p.is_queued_for_deletion() or p.cells.is_empty():
			continue
		var old_id: String = String(p.shape_data.get("id", ""))
		var test_rep: Dictionary = _pick_valid_replacement_shape(old_id, cur_lvl, board_ref)
		if test_rep.is_empty():
			continue
		if first_valid_slot == -1:
			first_valid_slot = i
		if board_ref != null and board_ref.has_method("has_any_valid_placement"):
			if not board_ref.has_any_valid_placement(p.cells):
				return i
	return first_valid_slot


func replace_piece_in_slot(slot_idx: int = -1, board_ref: Node2D = null) -> bool:
	var target_slot: int = slot_idx if slot_idx >= 0 else find_eligible_slot_for_change(board_ref)
	if target_slot < 0 or target_slot >= SLOT_COUNT:
		return false
	var existing = active_pieces[target_slot]
	if existing == null or not is_instance_valid(existing) or existing.is_queued_for_deletion() or existing.cells.is_empty():
		return false
	
	var gs = get_node_or_null("/root/GameState")
	var cur_lvl: int = gs.active_level if (gs and "active_level" in gs) else 1
	var old_id: String = String(existing.shape_data.get("id", ""))
	var new_shape: Dictionary = _pick_valid_replacement_shape(old_id, cur_lvl, board_ref)
	if new_shape.is_empty() or new_shape.get("cells", []).size() != 4 or String(new_shape.get("id", "")) == old_id:
		return false
	
	existing.setup_piece(new_shape, target_slot)
	if existing.has_method("set_board_cell_metrics"):
		existing.set_board_cell_metrics(board_cell_size, board_cell_gap)
	restore_piece_to_slot(existing)
	set_change_block_highlight(false)
	queue_redraw()
	return true


func get_tray_piece_node_count() -> int:
	var count: int = 0
	for ch in get_children():
		if ch != null and is_instance_valid(ch) and not ch.is_queued_for_deletion() and ch != btn_drag_rotate:
			if "slot_index" in ch or ch.has_method("setup_piece"):
				count += 1
	return count


func replace_all_pieces(board_ref: Node2D = null) -> bool:
	_ensure_slots()
	cancel_all_active_drags("change_block_replace_all")
	if get_remaining_piece_count() <= 0:
		return false
	
	var gs = get_node_or_null("/root/GameState")
	var cur_lvl: int = gs.active_level if (gs and "active_level" in gs) else 1
	
	var all_four_cell_keys: Array[String] = []
	var placeable_keys: Array[String] = []
	for raw_key in PolyominoLib.ACTIVE_SHAPE_KEYS:
		var key := String(raw_key)
		var sdata: Dictionary = PolyominoLib.SHAPES.get(key, {})
		var scells: Array = sdata.get("cells", [])
		if not PolyominoLib.is_valid_active_piece_size(scells.size()):
			continue
		all_four_cell_keys.append(key)
		if board_ref == null or not board_ref.has_method("has_any_valid_placement") or board_ref.has_any_valid_placement(scells):
			placeable_keys.append(key)
	
	if all_four_cell_keys.is_empty() or (board_ref != null and placeable_keys.is_empty()):
		return false
	
	var old_ids: Array[String] = []
	for i in range(SLOT_COUNT):
		var p = active_pieces[i]
		if p != null and is_instance_valid(p) and not p.is_queued_for_deletion() and not p.cells.is_empty():
			old_ids.append(String(p.shape_data.get("id", "")))
		else:
			old_ids.append("")
	
	var chosen_keys: Array[String] = []
	var new_shapes: Array[Dictionary] = []
	for i in range(SLOT_COUNT):
		var old_id: String = old_ids[i]
		var pool: Array[String] = []
		# 1. Prefer placeable 4-cell shapes different from old_id, old_ids, and already-chosen keys
		for k in placeable_keys:
			if k != old_id and not (k in chosen_keys) and not (k in old_ids):
				pool.append(k)
		# 2. Fallback: placeable 4-cell shapes different from old_id and already-chosen keys
		if pool.is_empty():
			for k in placeable_keys:
				if k != old_id and not (k in chosen_keys):
					pool.append(k)
		# 3. Fallback: any placeable 4-cell shape different from old_id
		if pool.is_empty():
			for k in placeable_keys:
				if k != old_id:
					pool.append(k)
		# 4. Fallback (when old_id was the sole placeable shape on a nearly-full board): any 4-cell shape different from old_id
		if pool.is_empty():
			for k in all_four_cell_keys:
				if k != old_id and not (k in chosen_keys):
					pool.append(k)
		if pool.is_empty():
			for k in all_four_cell_keys:
				if k != old_id:
					pool.append(k)
		if pool.is_empty():
			return false
		var picked_key: String = pool[randi() % pool.size()]
		chosen_keys.append(picked_key)
		var stamped: Dictionary = PolyominoLib.stamp_piece_material(PolyominoLib.get_shape(picked_key), cur_lvl)
		if stamped.is_empty() or stamped.get("cells", []).size() != 4:
			return false
		new_shapes.append(stamped)
	
	# Clean up any stray TrayPiece child nodes not tracked in active_pieces
	for ch in get_children():
		if ch != null and is_instance_valid(ch) and not ch.is_queued_for_deletion() and ch != btn_drag_rotate:
			if ("slot_index" in ch or ch.has_method("setup_piece")) and not (ch in active_pieces):
				remove_child(ch)
				ch.queue_free()
	
	for i in range(SLOT_COUNT):
		var existing = active_pieces[i]
		if existing != null and is_instance_valid(existing) and not existing.is_queued_for_deletion():
			existing.setup_piece(new_shapes[i], i)
			if existing.has_method("set_board_cell_metrics"):
				existing.set_board_cell_metrics(board_cell_size, board_cell_gap)
			restore_piece_to_slot(existing)
		else:
			_spawn_piece_in_slot(i, new_shapes[i])
	
	set_change_block_highlight(false)
	queue_redraw()
	return true


func _gui_input(event: InputEvent) -> void:
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if get_active_dragging_piece() != null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var global_pt: Vector2 = get_global_transform_with_canvas() * event.position
		if is_point_on_rotate_button(global_pt):
			return
		var slot_idx: int = _resolve_slot_index_for_local_point(event.position)
		if slot_idx >= 0 and slot_idx < SLOT_COUNT:
			var p = active_pieces[slot_idx]
			if p != null and is_instance_valid(p) and not p.is_queued_for_deletion() and not p.is_dragging:
				p._started_with_hardware_mouse = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
				p._start_drag(global_pt, -1)
				accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		var st_global_pt: Vector2 = get_global_transform_with_canvas() * event.position
		if is_point_on_rotate_button(st_global_pt):
			return
		var st_slot_idx: int = _resolve_slot_index_for_local_point(event.position)
		if st_slot_idx >= 0 and st_slot_idx < SLOT_COUNT:
			var st_p = active_pieces[st_slot_idx]
			if st_p != null and is_instance_valid(st_p) and not st_p.is_queued_for_deletion() and not st_p.is_dragging:
				st_p._started_with_hardware_mouse = false
				st_p._start_drag(st_global_pt, event.index)
				accept_event()


func _resolve_slot_index_for_local_point(local_pt: Vector2) -> int:
	var tray_w: float = size.x if size.x > 60.0 else 680.0
	var tray_h: float = size.y if size.y > 40.0 else 144.0
	if local_pt.x < 0.0 or local_pt.x > tray_w or local_pt.y < 0.0 or local_pt.y > tray_h:
		return -1
	var slot_w: float = tray_w / float(SLOT_COUNT)
	return clampi(int(floor(local_pt.x / maxf(1.0, slot_w))), 0, SLOT_COUNT - 1)


func reset_round_counter() -> void:
	round_number = 0


func spawn_new_round() -> void:
	_ensure_slots()
	clear_all_pieces()
	round_number += 1
	
	var gs = get_node_or_null("/root/GameState")
	var cur_lvl: int = gs.active_level if (gs and "active_level" in gs) else 1
	var shapes = PolyominoLib.get_random_tray_set(SLOT_COUNT, cur_lvl, round_number)
	for i in range(SLOT_COUNT):
		_spawn_piece_in_slot(i, shapes[i])
	
	queue_redraw()
	tray_replenished.emit()


func get_active_piece_ids() -> Array[String]:
	var ids: Array[String] = []
	for i in range(SLOT_COUNT):
		var p = active_pieces[i] if i < active_pieces.size() else null
		if p != null and is_instance_valid(p) and not p.is_queued_for_deletion():
			ids.append(String(p.shape_data.get("id", "")))
		else:
			ids.append("")
	return ids


func generate_fresh_valid_tray_for_recovery(board: Board = null, exclude_ids: Array = []) -> Array[String]:
	_ensure_slots()
	var prev_ids: Array[String] = get_active_piece_ids()
	for ex in exclude_ids:
		var ex_str := String(ex)
		if ex_str != "" and not (ex_str in prev_ids):
			prev_ids.append(ex_str)
	clear_all_pieces()
	round_number += 1
	
	var gs = get_node_or_null("/root/GameState")
	var cur_lvl: int = gs.active_level if (gs and "active_level" in gs) else 1
	
	var all_ids: Array = PolyominoLib.SHAPES.keys()
	var valid_ids: Array[String] = []
	for raw_id in all_ids:
		var sid := String(raw_id)
		var sdata: Dictionary = PolyominoLib.get_shape(sid)
		if board == null or board.has_any_valid_placement(sdata.get("cells", [])):
			valid_ids.append(sid)
	if valid_ids.is_empty():
		for raw_id in all_ids:
			valid_ids.append(String(raw_id))
	
	var chosen_ids: Array[String] = []
	for i in range(SLOT_COUNT):
		var shape_data: Dictionary = {}
		var candidates: Array = PolyominoLib.get_random_tray_set(SLOT_COUNT, cur_lvl, round_number + i + 3)
		for cand in candidates:
			var cid := String(cand.get("id", ""))
			var fits: bool = (board == null) or board.has_any_valid_placement(cand.get("cells", []))
			if fits and not (cid in prev_ids) and not (cid in chosen_ids):
				shape_data = cand
				break
		if shape_data.is_empty():
			for vid in valid_ids:
				if not (vid in prev_ids) and not (vid in chosen_ids):
					shape_data = PolyominoLib.get_shape(vid)
					break
		if shape_data.is_empty():
			for vid in valid_ids:
				if not (vid in chosen_ids):
					shape_data = PolyominoLib.get_shape(vid)
					break
		if shape_data.is_empty():
			shape_data = PolyominoLib.get_shape(valid_ids[i % valid_ids.size()])
		chosen_ids.append(String(shape_data.get("id", "")))
		_spawn_piece_in_slot(i, shape_data)
	
	set_change_block_highlight(false)
	queue_redraw()
	tray_replenished.emit()
	return chosen_ids


func _compute_slot_home_position(slot_idx: int, piece: Control) -> Vector2:
	var clamped_idx: int = clampi(slot_idx, 0, SLOT_COUNT - 1)
	var slot_center: Vector2 = SLOT_CENTERS[clamped_idx]
	var shape_sz: Vector2 = piece.get_shape_pixel_size() * piece.PREVIEW_SCALE
	return slot_center - (shape_sz * 0.5)


func _spawn_piece_in_slot(slot_idx: int, shape_data: Dictionary) -> void:
	if slot_idx < 0 or slot_idx >= SLOT_COUNT:
		return
	
	var piece_instance: Control = TRAY_PIECE_SCENE.instantiate()
	add_child(piece_instance)
	
	piece_instance.setup_piece(shape_data, slot_idx)
	if piece_instance.has_method("set_board_cell_metrics"):
		piece_instance.set_board_cell_metrics(board_cell_size, board_cell_gap)
	if "change_select_mode" in piece_instance:
		piece_instance.change_select_mode = change_block_selection_active
	
	var target_pos: Vector2 = _compute_slot_home_position(slot_idx, piece_instance)
	piece_instance.home_position = target_pos
	piece_instance.position = target_pos
	piece_instance.mouse_filter = Control.MOUSE_FILTER_PASS
	piece_instance.visible = true
	piece_instance.modulate = Color(1, 1, 1, 1)
	if piece_instance.has_method("_capture_drag_snapshot"):
		piece_instance._capture_drag_snapshot()
	
	piece_instance.drag_started.connect(_on_piece_drag_started)
	piece_instance.drag_moved.connect(_on_piece_drag_moved)
	piece_instance.drag_ended.connect(_on_piece_drag_ended)
	if piece_instance.has_signal("drag_cancelled"):
		piece_instance.drag_cancelled.connect(_on_piece_drag_cancelled)
	if piece_instance.has_signal("piece_rotated"):
		piece_instance.piece_rotated.connect(_on_piece_rotated)
	if piece_instance.has_signal("selected_for_change"):
		piece_instance.selected_for_change.connect(func(p): piece_selected_for_change.emit(slot_idx, p))
	
	active_pieces[slot_idx] = piece_instance


func cancel_all_active_drags(reason: String = "interrupted") -> void:
	for i in range(SLOT_COUNT):
		var p = active_pieces[i]
		if p != null and is_instance_valid(p) and not p.is_queued_for_deletion():
			if "is_dragging" in p and p.is_dragging:
				if p.has_method("cancel_drag"):
					p.cancel_drag(reason)
				else:
					restore_piece_to_slot(p)


## Guaranteed recovery helper: ensures an unconsumed piece is back in its exact original slot, visible, and interactive.
func restore_piece_to_slot(piece: Control) -> void:
	if piece == null or not is_instance_valid(piece) or piece.is_queued_for_deletion():
		return
	if "is_consumed" in piece and piece.is_consumed:
		return
	var slot_idx: int = clampi(int(piece.slot_index) if "slot_index" in piece else 0, 0, SLOT_COUNT - 1)
	# Ensure no duplicate references in other slots
	for i in range(SLOT_COUNT):
		if i != slot_idx and active_pieces[i] == piece:
			active_pieces[i] = null
	active_pieces[slot_idx] = piece
	if piece.get_parent() != self:
		if piece.get_parent():
			piece.get_parent().remove_child(piece)
		add_child(piece)
	var target_pos: Vector2 = _compute_slot_home_position(slot_idx, piece)
	piece.home_position = target_pos
	piece.return_to_slot()
	# Recompute home_position after return_to_slot restores original unrotated cells
	target_pos = _compute_slot_home_position(slot_idx, piece)
	piece.home_position = target_pos
	piece.position = target_pos
	if piece.has_method("_capture_drag_snapshot"):
		piece._capture_drag_snapshot()
	if active_dragging_piece == piece:
		active_dragging_piece = null
	if btn_drag_rotate and get_active_dragging_piece() == null:
		btn_drag_rotate.visible = false
	for other in active_pieces:
		if other != null and is_instance_valid(other) and not other.is_queued_for_deletion():
			other.mouse_filter = Control.MOUSE_FILTER_PASS
			other.visible = true
			other.modulate.a = 1.0


func consume_piece(piece: Control) -> void:
	for i in range(SLOT_COUNT):
		if active_pieces[i] == piece:
			active_pieces[i] = null
	if active_dragging_piece == piece:
		active_dragging_piece = null
	if btn_drag_rotate and get_active_dragging_piece() == null:
		btn_drag_rotate.visible = false
	
	if piece != null and is_instance_valid(piece):
		piece.on_placement_confirmed()
	
	for other in active_pieces:
		if other != null and is_instance_valid(other) and not other.is_queued_for_deletion():
			other.mouse_filter = Control.MOUSE_FILTER_PASS
			other.visible = true
	
	if is_tray_empty():
		spawn_new_round()


func update_responsive_layout(tray_width: float = 680.0) -> void:
	_ensure_slots()
	var effective_w: float = tray_width if tray_width > 60.0 else 680.0
	var slot_w: float = effective_w / float(SLOT_COUNT)
	var center_y: float = custom_minimum_size.y * 0.5 if custom_minimum_size.y > 0 else 72.0
	for i in range(SLOT_COUNT):
		var center_x: float = slot_w * (float(i) + 0.5)
		var new_center := Vector2(center_x, center_y)
		
		SLOT_CENTERS[i] = new_center
		if i < slots.size() and slots[i] != null:
			var s = slots[i]
			if s is Node2D:
				s.position = new_center
			elif s is Dictionary:
				s["position"] = new_center
			
		var piece = active_pieces[i]
		if piece != null and is_instance_valid(piece) and not piece.is_queued_for_deletion():
			var target_pos: Vector2 = _compute_slot_home_position(i, piece)
			piece.home_position = target_pos
			if "drag_start_snapshot" in piece and piece.drag_start_snapshot is Dictionary:
				piece.drag_start_snapshot["home_position"] = target_pos
			if not piece.is_dragging:
				piece.position = target_pos
	_ensure_rotate_control()
	_layout_rotate_control()
	queue_redraw()


func is_tray_empty() -> bool:
	for piece in active_pieces:
		if piece != null and is_instance_valid(piece) and not piece.is_queued_for_deletion():
			return false
	return true


func get_remaining_piece_count() -> int:
	var count: int = 0
	for piece in active_pieces:
		if piece != null and is_instance_valid(piece) and not piece.is_queued_for_deletion():
			count += 1
	return count


func clear_all_pieces() -> void:
	for i in range(SLOT_COUNT):
		if active_pieces[i] != null and is_instance_valid(active_pieces[i]):
			active_pieces[i].queue_free()
		active_pieces[i] = null


func _on_piece_drag_started(piece: Control) -> void:
	active_dragging_piece = piece
	for other in active_pieces:
		if other != null and is_instance_valid(other) and other != piece:
			other.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_rotate_control()
	_layout_rotate_control()
	if btn_drag_rotate:
		btn_drag_rotate.visible = true
		btn_drag_rotate.move_to_front()
	piece_drag_started.emit(piece)


func _on_piece_rotated(piece: Control) -> void:
	piece_rotated.emit(piece)


func _on_piece_drag_moved(piece: Control, global_pos: Vector2) -> void:
	piece_drag_moved.emit(piece, global_pos)


func _on_piece_drag_ended(piece: Control, global_pos: Vector2) -> void:
	if active_dragging_piece == piece:
		active_dragging_piece = null
	if btn_drag_rotate and get_active_dragging_piece() == null:
		btn_drag_rotate.visible = false
	for other in active_pieces:
		if other != null and is_instance_valid(other) and not other.is_queued_for_deletion():
			other.mouse_filter = Control.MOUSE_FILTER_PASS
			other.visible = true
			other.modulate.a = 1.0
	piece_drag_ended.emit(piece, global_pos)


func _on_piece_drag_cancelled(piece: Control, reason: String) -> void:
	if active_dragging_piece == piece:
		active_dragging_piece = null
	if btn_drag_rotate and get_active_dragging_piece() == null:
		btn_drag_rotate.visible = false
	restore_piece_to_slot(piece)
	for other in active_pieces:
		if other != null and is_instance_valid(other) and not other.is_queued_for_deletion():
			other.mouse_filter = Control.MOUSE_FILTER_PASS
			other.visible = true
			other.modulate.a = 1.0
	piece_drag_cancelled.emit(piece, reason)
