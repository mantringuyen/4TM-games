extends "res://scripts/core/game_mode.gd"

## ModernMode — Drag & Drop PlayStyle controller for Block Puzzle — 4TM (8x10 Board: 8 Columns × 10 Rows).
## Supports both:
##   1. Modern + Drag & Drop  (Row & Column clear, HAS 3 special items: Bomb, Change Block, Extra Life, 3-piece tray)
##   2. Classic + Drag & Drop (Row clear ONLY, NO special items, no gravity, 3-piece tray)

signal special_item_Pending_changed(item_id: String)
signal special_item_consumed(item_id: String)

const BOARD_SCENE = preload("res://scenes/game/board.tscn")
const PIECE_TRAY_SCENE = preload("res://scenes/game/piece_tray.tscn")
const PieceTrayScript = preload("res://scripts/game/piece_tray.gd")
const PolyominoLib = preload("res://scripts/core/polyomino_library.gd")
const DRAG_DROP_BOARD_COLS: int = 8
const DRAG_DROP_BOARD_ROWS: int = 10

var board: Node2D = null
var piece_tray: Control = null
var pending_special_item: String = ""


func _init() -> void:
	mode_type = GameStateScript.GameMode.MODERN_DRAG_AND_DROP
	rule_mode = GameStateScript.GameMode.MODERN_DRAG_AND_DROP
	play_style = GameStateScript.PlayStyle.DRAG_AND_DROP


func _on_mode_initialized() -> void:
	_setup_board_and_tray()
	if is_inside_tree() and get_viewport():
		if not get_viewport().size_changed.is_connected(_update_layout):
			get_viewport().size_changed.connect(_update_layout)
	var state_mgr = get_node_or_null("/root/GameState")
	if state_mgr and state_mgr.has_signal("state_changed"):
		if not state_mgr.state_changed.is_connected(_on_game_state_changed_while_dragging):
			state_mgr.state_changed.connect(_on_game_state_changed_while_dragging)


func _on_game_state_changed_while_dragging(new_state: int, _prev_state: int) -> void:
	if new_state != GameStateScript.State.PLAYING:
		if piece_tray and piece_tray.has_method("cancel_all_active_drags"):
			piece_tray.cancel_all_active_drags("game_state_interrupted")
		if board:
			board.clear_preview()


func _on_mode_started() -> void:
	if not board or not piece_tray:
		_setup_board_and_tray()
	
	pending_special_item = ""
	if board.has_method("configure_grid_dimensions") and (board.GRID_WIDTH != DRAG_DROP_BOARD_COLS or board.GRID_HEIGHT != DRAG_DROP_BOARD_ROWS):
		board.configure_grid_dimensions(DRAG_DROP_BOARD_COLS, DRAG_DROP_BOARD_ROWS)
	board.clear_board()
	if board.has_method("set_visual_mode"):
		board.set_visual_mode(has_special_items())
	var state_mgr = get_node_or_null("/root/GameState")
	var cur_lvl: int = state_mgr.active_level if (state_mgr and "active_level" in state_mgr) else 1
	var allow_milestone_items: bool = has_special_items() and (
		(state_mgr != null and state_mgr.has_method("can_level_have_special_board_items") and state_mgr.can_level_have_special_board_items(cur_lvl, rule_mode))
		or (state_mgr == null and PolyominoLib.is_special_milestone_level(cur_lvl))
	)
	if board.has_method("spawn_milestone_special_items"):
		board.spawn_milestone_special_items(cur_lvl, allow_milestone_items)
	if piece_tray.has_method("reset_round_counter"):
		piece_tray.reset_round_counter()
	piece_tray.spawn_new_round()
	_update_layout()


func _setup_board_and_tray() -> void:
	if not board:
		board = BOARD_SCENE.instantiate()
		if board.has_method("configure_grid_dimensions"):
			board.configure_grid_dimensions(DRAG_DROP_BOARD_COLS, DRAG_DROP_BOARD_ROWS)
		add_child(board)
	
	if not piece_tray:
		piece_tray = PIECE_TRAY_SCENE.instantiate()
		if piece_tray and not piece_tray.get_script():
			piece_tray.set_script(PieceTrayScript)
		add_child(piece_tray)
		
		piece_tray.piece_drag_started.connect(_on_piece_drag_started)
		piece_tray.piece_drag_moved.connect(_on_piece_drag_moved)
		piece_tray.piece_drag_ended.connect(_on_piece_drag_ended)
		if piece_tray.has_signal("piece_drag_cancelled"):
			piece_tray.piece_drag_cancelled.connect(_on_piece_drag_cancelled)
		if piece_tray.has_signal("piece_selected_for_change"):
			piece_tray.piece_selected_for_change.connect(_on_piece_selected_for_change)
	
	_update_layout()


func _input(event: InputEvent) -> void:
	if not is_active or pending_special_item != "bomb" or not board:
		return
	if event is InputEventMouseMotion:
		var mm_rect = Rect2(board.global_position, board.get_board_pixel_size())
		if mm_rect.has_point(event.global_position):
			var mm_cell = board.local_point_to_cell(board.to_local(event.global_position))
			if board.is_valid_cell(mm_cell):
				select_bomb_target(mm_cell)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mb_rect = Rect2(board.global_position, board.get_board_pixel_size())
		if mb_rect.has_point(event.global_position):
			var mb_cell = board.local_point_to_cell(board.to_local(event.global_position))
			if board.is_valid_cell(mb_cell):
				confirm_bomb_target(mb_cell)
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and pending_special_item == "bomb":
		var drag_pos: Vector2 = event.position
		var sd_rect = Rect2(board.global_position, board.get_board_pixel_size())
		if sd_rect.has_point(drag_pos):
			var sd_cell = board.local_point_to_cell(board.to_local(drag_pos))
			if board.is_valid_cell(sd_cell):
				select_bomb_target(sd_cell)
	elif event is InputEventScreenTouch and event.pressed:
		var touch_pos: Vector2 = event.position
		var st_rect = Rect2(board.global_position, board.get_board_pixel_size())
		if st_rect.has_point(touch_pos):
			var st_cell = board.local_point_to_cell(board.to_local(touch_pos))
			if board.is_valid_cell(st_cell):
				confirm_bomb_target(st_cell)
				if is_inside_tree() and get_viewport():
					get_viewport().set_input_as_handled()


## Dynamically calculates the Drag & Drop layout from the available viewport for the 12x10 Board:
## Header (HUD) -> 12x10 Board (10/12 width, ~1 cell margin each side) -> 3-Piece Tray -> Bottom AdSlot
func _update_layout() -> void:
	var vp_size := Vector2(720.0, 1280.0)
	if is_inside_tree() and get_viewport():
		var rect_sz := get_viewport_rect().size
		if rect_sz.x > 0 and rect_sz.y > 0:
			vp_size = rect_sz
	update_layout_for_viewport(vp_size)


func update_layout_for_viewport(vp_size: Vector2) -> Dictionary:
	var vp_w: float = vp_size.x if vp_size.x > 0 else 720.0
	var vp_h: float = vp_size.y if vp_size.y > 0 else 1280.0
	var is_compact: bool = (vp_h <= 900.0 or vp_w <= 430.0)
	
	var hud_h: float = (128.0 if is_compact else 144.0) if has_special_items() else (78.0 if is_compact else 94.0)
	var ad_h: float = 0.0
	var ad_top_y: float = vp_h
	var min_gap: float = 12.0 if is_compact else 18.0
	var rotate_btn_h: float = 44.0 if is_compact else 50.0
	var min_mid_gap: float = rotate_btn_h + (14.0 if is_compact else 20.0)
	var tray_h: float = clampf(vp_h * 0.118, 88.0, 142.0)
	var max_board_h: float = maxf(240.0, (ad_top_y - hud_h) - tray_h - min_mid_gap - (min_gap * 2.0))
	
	var board_cols: float = float(board.GRID_WIDTH) if board else float(DRAG_DROP_BOARD_COLS)
	var board_rows: float = float(board.GRID_HEIGHT) if board else float(DRAG_DROP_BOARD_ROWS)
	var board_sz := Vector2(vp_w * (board_cols / (board_cols + 2.0)), vp_w * (board_rows / (board_cols + 2.0)))
	if board:
		board_sz = board.update_responsive_layout(vp_w, 0.0, max_board_h)
	var margin_x: float = (vp_w - board_sz.x) * 0.5
	
	var avail_v: float = maxf(0.0, (ad_top_y - hud_h) - board_sz.y - tray_h)
	var gap_top: float = maxf(min_gap * 0.85, avail_v * 0.22)
	var gap_mid: float = maxf(min_mid_gap, avail_v * 0.52)
	var board_y: float = hud_h + gap_top
	var tray_y: float = board_y + board_sz.y + gap_mid
	
	if tray_y + tray_h > ad_top_y - min_gap:
		tray_y = ad_top_y - min_gap - tray_h
		board_y = maxf(hud_h + 8.0, tray_y - maxf(min_mid_gap, gap_mid) - board_sz.y)
	
	if board:
		board.position = Vector2(margin_x, board_y)
	
	var tray_w: float = minf(vp_w - 20.0, maxf(board_sz.x, vp_w * 0.90))
	var tray_x: float = (vp_w - tray_w) * 0.5
	var actual_mid_gap: float = maxf(min_mid_gap, tray_y - (board_y + board_sz.y))
	var tray_rect := Rect2(Vector2(tray_x, tray_y), Vector2(tray_w, tray_h))
	var rotate_rect := Rect2()
	if piece_tray:
		piece_tray.position = Vector2(tray_x, tray_y)
		piece_tray.custom_minimum_size = Vector2(tray_w, tray_h)
		piece_tray.size = Vector2(tray_w, tray_h)
		if piece_tray.has_method("set_board_to_tray_gap"):
			piece_tray.set_board_to_tray_gap(actual_mid_gap)
		if board and piece_tray.has_method("set_board_cell_metrics"):
			piece_tray.set_board_cell_metrics(board.CELL_SIZE, board.CELL_GAP)
		elif piece_tray.has_method("update_responsive_layout"):
			piece_tray.update_responsive_layout(tray_w)
		tray_rect = Rect2(piece_tray.position, piece_tray.size)
		if piece_tray.has_method("get_rotate_button_rect_in_parent"):
			rotate_rect = piece_tray.get_rotate_button_rect_in_parent()
	
	return {
		"header_rect": Rect2(0.0, 0.0, vp_w, hud_h),
		"board_rect": Rect2(Vector2(margin_x, board_y), board_sz),
		"rotate_button_rect": rotate_rect,
		"tray_rect": tray_rect,
		"ad_rect": Rect2(0.0, ad_top_y, vp_w, ad_h),
		"header_to_board_gap": board_y - hud_h,
		"board_to_tray_gap": tray_rect.position.y - (board_y + board_sz.y),
		"tray_to_ad_gap": ad_top_y - tray_rect.end.y
	}


func get_board() -> Node2D:
	return board


func get_piece_tray() -> Control:
	return piece_tray


func get_drag_rotate_button() -> Button:
	if piece_tray and piece_tray.has_method("get_drag_rotate_button"):
		return piece_tray.get_drag_rotate_button()
	return null


func rotate_dragged_piece() -> bool:
	if piece_tray and piece_tray.has_method("rotate_active_dragged_piece"):
		return piece_tray.rotate_active_dragged_piece()
	return false


func _get_piece_visual_center_world(piece: Control, fallback_pointer_pos: Vector2) -> Vector2:
	if piece and is_instance_valid(piece):
		if piece.has_method("get_visual_center_global"):
			return piece.get_visual_center_global()
		if piece.has_method("get_shape_pixel_size") and "current_scale" in piece:
			return piece.global_position + (piece.get_shape_pixel_size() * float(piece.current_scale)) * 0.5
	return fallback_pointer_pos


func _resolve_drop_grid_origin(piece: Control, pointer_pos: Vector2) -> Vector2i:
	if not board or not is_instance_valid(piece):
		return Vector2i(-1, -1)
	var visual_center: Vector2 = _get_piece_visual_center_world(piece, pointer_pos)
	if board.has_method("resolve_piece_origin_from_visual_center"):
		return board.resolve_piece_origin_from_visual_center(visual_center, piece.cells)
	var local_board_pos: Vector2 = board.to_local(piece.global_position)
	return board.local_to_grid(local_board_pos)


func _is_pointer_in_valid_board_drop_zone(pointer_pos: Vector2, piece: Control = null) -> bool:
	if not board:
		return false
	var check_pos: Vector2 = _get_piece_visual_center_world(piece, pointer_pos)
	if is_inside_tree() and get_viewport():
		var vp_rect := get_viewport_rect()
		if vp_rect.size.x > 0 and vp_rect.size.y > 0:
			if not vp_rect.has_point(pointer_pos) or not vp_rect.has_point(check_pos):
				return false
	if piece_tray:
		var tray_rect := Rect2(piece_tray.global_position, piece_tray.size)
		if tray_rect.has_point(pointer_pos) or tray_rect.has_point(check_pos):
			return false
	var board_rect := Rect2(board.global_position, board.get_board_pixel_size())
	return board_rect.has_point(check_pos)


func _restore_dragged_piece(piece: Control) -> void:
	if piece and is_instance_valid(piece) and piece.has_method("set_snapped_to_board_preview"):
		piece.set_snapped_to_board_preview(false)
	if piece_tray and piece_tray.has_method("restore_piece_to_slot"):
		piece_tray.restore_piece_to_slot(piece)
	elif piece and is_instance_valid(piece) and piece.has_method("return_to_slot"):
		piece.return_to_slot()
	if board:
		board.clear_preview()


func has_duplicate_drag_visual() -> bool:
	if not board or not piece_tray:
		return false
	var dragging_p: Control = piece_tray.get_active_dragging_piece() if piece_tray.has_method("get_active_dragging_piece") else null
	if dragging_p == null or not is_instance_valid(dragging_p):
		return false
	if board.preview_active and board.preview_is_valid:
		return not bool(dragging_p.get("is_snapped_to_board_preview"))
	return false


func _on_piece_drag_started(piece: Control) -> void:
	if board and piece and is_instance_valid(piece) and piece.has_method("set_board_cell_metrics"):
		if not is_equal_approx(float(piece.cell_size), board.CELL_SIZE) or not is_equal_approx(float(piece.cell_gap), board.CELL_GAP):
			piece.set_board_cell_metrics(board.CELL_SIZE, board.CELL_GAP)
			if piece.has_method("_update_drag_position") and "active_pointer_pos" in piece:
				piece._update_drag_position(piece.active_pointer_pos)
	if piece_tray:
		for other in piece_tray.active_pieces:
			if other != null and is_instance_valid(other) and other != piece and other.is_dragging:
				if other.has_method("cancel_drag"):
					other.cancel_drag("other_piece_drag_started")
				else:
					piece_tray.restore_piece_to_slot(other)
	if piece and is_instance_valid(piece) and "active_pointer_pos" in piece and _is_pointer_in_valid_board_drop_zone(piece.active_pointer_pos, piece):
		_on_piece_drag_moved(piece, piece.active_pointer_pos)
	else:
		if piece and is_instance_valid(piece) and piece.has_method("set_snapped_to_board_preview"):
			piece.set_snapped_to_board_preview(false)
		if board:
			board.clear_preview()


func _on_piece_drag_cancelled(piece: Control, _reason: String) -> void:
	_restore_dragged_piece(piece)


func _on_piece_drag_moved(piece: Control, release_pointer_pos: Vector2) -> void:
	if not board or not is_instance_valid(piece):
		return
	
	if not _is_pointer_in_valid_board_drop_zone(release_pointer_pos, piece):
		if piece.has_method("set_snapped_to_board_preview"):
			piece.set_snapped_to_board_preview(false)
		board.clear_preview()
		return
	
	var origin_coord: Vector2i = _resolve_drop_grid_origin(piece, release_pointer_pos)
	var can_place: bool = board.can_place_piece(piece.cells, origin_coord)
	var p_mat: String = String(piece.material_id) if "material_id" in piece else ""
	board.set_preview(piece.cells, origin_coord, can_place, piece.color, piece.color_id, p_mat)
	if piece.has_method("set_snapped_to_board_preview"):
		piece.set_snapped_to_board_preview(can_place)


func _on_piece_drag_ended(piece: Control, release_pointer_pos: Vector2) -> void:
	if not board or not is_instance_valid(piece):
		return
	if piece.has_method("set_snapped_to_board_preview"):
		piece.set_snapped_to_board_preview(false)
	
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if not _is_pointer_in_valid_board_drop_zone(release_pointer_pos, piece):
		_restore_dragged_piece(piece)
		board.clear_preview()
		return
	
	var origin_coord: Vector2i = _resolve_drop_grid_origin(piece, release_pointer_pos)
	board.clear_preview()
	
	if board.can_place_piece(piece.cells, origin_coord):
		var cell_count: int = piece.cells.size()
		var p_mat: String = String(piece.material_id) if "material_id" in piece else ""
		var success: bool = board.place_piece(piece.cells, origin_coord, piece.color_id, p_mat)
		if success:
			if audio_mgr:
				audio_mgr.play_piece_placement()
				
			var clear_res = board.check_and_clear_lines(allows_column_clear(), uses_gravity())
			if clear_res["lines_cleared"] > 0 and audio_mgr:
				var is_col_only = (clear_res.get("row_count", 0) == 0 and clear_res.get("col_count", 0) > 0)
				audio_mgr.play_line_clear(clear_res["lines_cleared"], is_col_only)
			
			var is_rainbow_piece: bool = (
				(bool(piece.get("is_rainbow")) if "is_rainbow" in piece else false) or
				int(piece.color_id) == 9 or
				p_mat in ["rainbow", "seven_color"] or
				bool(clear_res.get("has_rainbow", false))
			)
			piece_tray.consume_piece(piece)
			
			var state_mgr = get_node_or_null("/root/GameState")
			if state_mgr:
				state_mgr.process_move_result(
					cell_count,
					int(clear_res.get("lines_cleared", 0)),
					int(clear_res.get("row_count", 0)),
					int(clear_res.get("col_count", 0)),
					int(clear_res.get("unique_cells_cleared", 0)),
					is_rainbow_piece,
					clear_res.get("collected_special_items", [])
				)
				if (
					has_special_items() and
					state_mgr.has_method("can_level_have_special_board_items") and
					state_mgr.can_level_have_special_board_items(state_mgr.active_level, rule_mode) and
					int(clear_res.get("lines_cleared", 0)) > 0 and
					board.has_method("get_special_item_count_on_board") and
					board.get_special_item_count_on_board() < 3
				):
					board.try_spawn_milestone_special_item_in_occupied_cell("", state_mgr.active_level, true)
			
			if state_mgr and state_mgr.current_state == GameStateScript.State.PLAYING and check_game_over():
				if audio_mgr:
					audio_mgr.play_game_over()
				var mode_label = "modern_drag" if has_special_items() else "classic_drag"
				state_mgr.trigger_game_over({"reason": "no_valid_moves", "mode": mode_label})
		else:
			if audio_mgr and audio_mgr.has_method("play_invalid_placement"):
				audio_mgr.play_invalid_placement()
			_restore_dragged_piece(piece)
	else:
		if audio_mgr and audio_mgr.has_method("play_invalid_placement"):
			audio_mgr.play_invalid_placement()
		_restore_dragged_piece(piece)
	
	board.clear_preview()


# ==============================================================================
# MODERN SPECIAL ITEMS: BOMB, CHANGE BLOCK, EXTRA LIFE (NO ROTATION)
# ==============================================================================

func apply_special_item(item_id: String) -> bool:
	if not has_special_items() or not board or not piece_tray:
		return false
	
	var state_mgr = get_node_or_null("/root/GameState")
	if item_id == "extra_life":
		# Extra Life must ONLY work at Game Over; while actively playing it must do nothing and not modify state.
		if state_mgr and state_mgr.current_state != GameStateScript.State.GAME_OVER:
			return false
		return confirm_extra_life()
	
	if piece_tray.has_method("cancel_all_active_drags"):
		piece_tray.cancel_all_active_drags("special_item_interruption")
	board.clear_preview()
	
	if state_mgr and state_mgr.has_method("get_special_item_count"):
		if state_mgr.get_special_item_count(item_id) <= 0:
			return false
	
	match item_id:
		"bomb":
			if pending_special_item == "bomb":
				cancel_pending_special_item()
				return false
			cancel_pending_special_item()
			pending_special_item = "bomb"
			var default_bomb_center := Vector2i(
				clampi(board.GRID_WIDTH / 2 - 1, 0, board.GRID_WIDTH - 1),
				clampi(board.GRID_HEIGHT / 2, 0, board.GRID_HEIGHT - 1)
			)
			board.set_bomb_target_highlight(default_bomb_center, true)
			special_item_Pending_changed.emit("bomb")
			return false
		"change_block":
			cancel_pending_special_item()
			return confirm_change_block(-1)
	return false


func cancel_pending_special_item() -> void:
	pending_special_item = ""
	if board:
		board.clear_bomb_target_highlight()
	if piece_tray:
		piece_tray.set_change_block_highlight(false)
	special_item_Pending_changed.emit("")


func select_bomb_target(target_coord: Vector2i) -> bool:
	if not has_special_items() or pending_special_item != "bomb" or not board:
		return false
	return board.set_bomb_target_highlight(target_coord, true)


func confirm_bomb_target(target_coord: Vector2i) -> bool:
	if not has_special_items() or pending_special_item != "bomb" or not board:
		return false
	if not board.is_valid_cell(target_coord):
		return false
	
	var state_mgr = get_node_or_null("/root/GameState")
	if state_mgr and state_mgr.has_method("get_special_item_count") and state_mgr.get_special_item_count("bomb") <= 0:
		cancel_pending_special_item()
		return false
	
	var res: Dictionary = board.detonate_bomb_at(target_coord)
	if not res.get("executed", false):
		return false
	
	pending_special_item = ""
	if state_mgr and state_mgr.has_method("consume_special_item"):
		state_mgr.consume_special_item("bomb")
	if state_mgr and state_mgr.has_method("collect_board_special_item"):
		for col_id in res.get("collected_special_items", []):
			state_mgr.collect_board_special_item(String(col_id), state_mgr.active_level)
	
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_special_item"):
		audio_mgr.play_special_item("bomb")
	
	special_item_Pending_changed.emit("")
	special_item_consumed.emit("bomb")
	return true


func _on_piece_selected_for_change(slot_idx: int, _piece: Control) -> void:
	confirm_change_block(slot_idx)


func confirm_change_block(_slot_idx: int = -1) -> bool:
	if not has_special_items() or not piece_tray:
		return false
	
	var state_mgr = get_node_or_null("/root/GameState")
	if state_mgr and state_mgr.has_method("get_special_item_count") and state_mgr.get_special_item_count("change_block") <= 0:
		cancel_pending_special_item()
		return false
	
	var replaced_ok: bool = false
	if piece_tray.has_method("replace_all_pieces"):
		replaced_ok = piece_tray.replace_all_pieces(board)
	else:
		replaced_ok = piece_tray.replace_piece_in_slot(_slot_idx, board)
	if not replaced_ok:
		return false
	
	pending_special_item = ""
	piece_tray.set_change_block_highlight(false)
	if state_mgr and state_mgr.has_method("consume_special_item"):
		state_mgr.consume_special_item("change_block")
	
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_special_item"):
		audio_mgr.play_special_item("change_block")
	
	special_item_Pending_changed.emit("")
	special_item_consumed.emit("change_block")
	return true


func confirm_extra_life() -> bool:
	if not has_special_items() or not board:
		return false
	var state_mgr = get_node_or_null("/root/GameState")
	if not state_mgr or state_mgr.current_state != GameStateScript.State.GAME_OVER:
		return false
	if state_mgr.has_method("can_use_extra_life_now") and not state_mgr.can_use_extra_life_now():
		return false
	if state_mgr.has_method("get_special_item_count") and state_mgr.get_special_item_count("extra_life") <= 0:
		return false
	
	var can_rescue: bool = (board.get_occupied_cell_count() > 0) or (state_mgr != null and state_mgr.current_state == GameStateScript.State.GAME_OVER)
	if not can_rescue:
		return false
	if state_mgr.has_method("consume_special_item") and not state_mgr.consume_special_item("extra_life"):
		return false
	
	cancel_pending_special_item()
	var old_tray_ids: Array[String] = []
	if piece_tray and piece_tray.has_method("get_active_piece_ids"):
		old_tray_ids = piece_tray.get_active_piece_ids()
	
	if "placement_checkpoints" in state_mgr and state_mgr.placement_checkpoints.size() > 0:
		state_mgr.rewind_extra_life_checkpoint(board)
	else:
		board.apply_extra_life_rescue()
	
	if piece_tray and piece_tray.has_method("generate_fresh_valid_tray_for_recovery"):
		piece_tray.generate_fresh_valid_tray_for_recovery(board, old_tray_ids)
	elif piece_tray:
		piece_tray.spawn_new_round()
	
	if state_mgr.has_method("revive_from_extra_life"):
		state_mgr.revive_from_extra_life()
	
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_special_item"):
		audio_mgr.play_special_item("extra_life")
	
	special_item_consumed.emit("extra_life")
	return true


func check_game_over() -> bool:
	if not board or not piece_tray:
		return false
	
	var active_pieces = piece_tray.active_pieces
	var has_active_piece = false
	var grid_h: int = board.GRID_HEIGHT
	var grid_w: int = board.GRID_WIDTH
	
	for piece in active_pieces:
		if piece != null and is_instance_valid(piece) and not piece.is_queued_for_deletion() and not piece.cells.is_empty():
			has_active_piece = true
			for y in range(grid_h):
				for x in range(grid_w):
					if board.can_place_piece(piece.cells, Vector2i(x, y)):
						return false
	
	if has_active_piece:
		return true
		
	return false


func _on_mode_ended() -> void:
	cancel_pending_special_item()
	if board:
		board.clear_board()
	if piece_tray:
		piece_tray.clear_all_pieces()


func _on_mode_reset() -> void:
	cancel_pending_special_item()
	if board:
		board.clear_board()
		var state_mgr = get_node_or_null("/root/GameState")
		var cur_lvl: int = state_mgr.active_level if (state_mgr and "active_level" in state_mgr) else 1
		var allow_milestone_items: bool = has_special_items() and (
			(state_mgr != null and state_mgr.has_method("can_level_have_special_board_items") and state_mgr.can_level_have_special_board_items(cur_lvl, rule_mode))
			or (state_mgr == null and PolyominoLib.is_special_milestone_level(cur_lvl))
		)
		if board.has_method("spawn_milestone_special_items"):
			board.spawn_milestone_special_items(cur_lvl, allow_milestone_items)
	if piece_tray:
		piece_tray.spawn_new_round()
