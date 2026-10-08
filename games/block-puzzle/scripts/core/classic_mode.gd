extends "res://scripts/core/game_mode.gd"

## ClassicMode — Falling PlayStyle controller for Block Puzzle — 4TM (12x10 Board).
## Supports both:
##   1. Classic + Falling (Row clear only, NO special items, downward gravity, ONLY Next preview)
##   2. Modern + Falling  (Row & Column clear, HAS 3 special items: Bomb, Change Block, Extra Life, downward gravity, ONLY Next preview)

signal special_item_Pending_changed(item_id: String)
signal special_item_consumed(item_id: String)

const BOARD_SCENE = preload("res://scenes/game/board.tscn")
const MODE_PIECE_AREA_SCENE = preload("res://scenes/game/mode_piece_area.tscn")
const PolyominoLib = preload("res://scripts/core/polyomino_library.gd")
const UIIconScript = preload("res://scripts/ui/ui_icon.gd")
const GameTypographyScript = preload("res://scripts/ui/game_typography.gd")

var board: Node2D = null
var mode_piece_area: Control = null
var touch_controls: Control = null
var pending_special_item: String = ""

var btn_left: Button = null
var btn_rotate: Button = null
var btn_right: Button = null
var btn_down: Button = null
var btn_drop: Button = null

# Falling piece state
var current_piece: Dictionary = {}
var next_piece: Dictionary = {}
var current_pos: Vector2i = Vector2i.ZERO
var drop_timer: float = 0.0
var drop_interval: float = 0.74
var is_falling: bool = false
var spawn_count: int = 0

var touch_start_pos: Vector2 = Vector2.ZERO
var touch_last_pos: Vector2 = Vector2.ZERO
var touch_start_time: float = 0.0
var touch_accumulated: Vector2 = Vector2.ZERO
var is_touch_active: bool = false
const TOUCH_STEP_X: float = 34.0
const TOUCH_STEP_Y: float = 38.0
const QUICK_DROP_SEPARATION_COMPACT: float = 18.0
const QUICK_DROP_SEPARATION_REGULAR: float = 24.0


func _init() -> void:
	mode_type = GameStateScript.GameMode.CLASSIC
	rule_mode = GameStateScript.GameMode.CLASSIC
	play_style = GameStateScript.PlayStyle.FALLING


func _on_mode_initialized() -> void:
	_setup_board_and_piece_area()
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_signal("language_changed"):
		if not gs.language_changed.is_connected(_on_language_changed):
			gs.language_changed.connect(_on_language_changed)
	if is_inside_tree() and get_viewport():
		if not get_viewport().size_changed.is_connected(_update_layout):
			get_viewport().size_changed.connect(_update_layout)


func _on_language_changed(_lang: String) -> void:
	_refresh_control_labels()


func _on_mode_started() -> void:
	if not board or not mode_piece_area:
		_setup_board_and_piece_area()
	
	pending_special_item = ""
	if board.has_method("configure_grid_dimensions") and (board.GRID_WIDTH != 10 or board.GRID_HEIGHT != 12):
		board.configure_grid_dimensions(10, 12)
	board.clear_board()
	if board.has_method("set_visual_mode"):
		board.set_visual_mode(has_special_items())
	if mode_piece_area:
		if mode_piece_area.has_method("set_falling_active"):
			mode_piece_area.set_falling_active(true)
		elif mode_piece_area.has_method("set_game_mode"):
			mode_piece_area.set_game_mode(GameStateScript.GameMode.CLASSIC)
		
	var gs = get_node_or_null("/root/GameState")
	var cur_lvl: int = gs.active_level if (gs and "active_level" in gs) else 1
	var allow_milestone_items: bool = has_special_items() and (
		(gs != null and gs.has_method("can_level_have_special_board_items") and gs.can_level_have_special_board_items(cur_lvl, rule_mode))
		or (gs == null and PolyominoLib.is_special_milestone_level(cur_lvl))
	)
	if board.has_method("spawn_milestone_special_items"):
		board.spawn_milestone_special_items(cur_lvl, allow_milestone_items)
	spawn_count = 0
	var prof: Dictionary = PolyominoLib.get_level_difficulty_profile(cur_lvl)
	drop_interval = float(prof.get("falling_drop_interval", 0.74))
	current_piece = _pick_next_falling_piece(cur_lvl)
	next_piece = _pick_next_falling_piece(cur_lvl)
	
	_refresh_control_labels()
	_update_previews()
	_spawn_current_piece()
	_update_layout()


func _pick_next_falling_piece(cur_lvl: int) -> Dictionary:
	var opening_id: String = PolyominoLib.get_falling_opening_shape_id(cur_lvl, spawn_count)
	spawn_count += 1
	if not opening_id.is_empty():
		var pal: Array[String] = PolyominoLib.get_level_material_palette(cur_lvl)
		var forced_mat: String = pal[(spawn_count - 1) % pal.size()] if not pal.is_empty() else ""
		return PolyominoLib.stamp_piece_material(PolyominoLib.get_shape(opening_id), cur_lvl, forced_mat)
	return PolyominoLib.get_random_shape(cur_lvl)


func _process(delta: float) -> void:
	if not is_active or not is_falling:
		return
		
	var state_mgr = get_node_or_null("/root/GameState")
	if state_mgr and state_mgr.current_state != GameStateScript.State.PLAYING:
		return
		
	drop_timer += delta
	if drop_timer >= drop_interval:
		drop_timer = 0.0
		_step_down()


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	var state_mgr = get_node_or_null("/root/GameState")
	if state_mgr and state_mgr.current_state != GameStateScript.State.PLAYING:
		return
	
	if pending_special_item == "bomb" and board:
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
					return
		elif event is InputEventScreenTouch and event.pressed:
			var st_rect = Rect2(board.global_position, board.get_board_pixel_size())
			if st_rect.has_point(event.position):
				var st_cell = board.local_point_to_cell(board.to_local(event.position))
				if board.is_valid_cell(st_cell):
					confirm_bomb_target(st_cell)
					return
	
	if not is_falling:
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT, KEY_A:
				move_left()
			KEY_RIGHT, KEY_D:
				move_right()
			KEY_DOWN, KEY_S:
				_step_down()
			KEY_UP, KEY_W, KEY_R:
				rotate_piece()
			KEY_SPACE:
				quick_drop()
		return

	if event is InputEventScreenTouch:
		var touch_ev = event as InputEventScreenTouch
		if touch_ev.pressed:
			is_touch_active = true
			touch_start_pos = touch_ev.position
			touch_last_pos = touch_ev.position
			touch_accumulated = Vector2.ZERO
			touch_start_time = Time.get_ticks_msec() / 1000.0
		else:
			if is_touch_active:
				is_touch_active = false
				var dist = (touch_ev.position - touch_start_pos).length()
				var elapsed = (Time.get_ticks_msec() / 1000.0) - touch_start_time
				if dist < 22.0 and elapsed < 0.35:
					rotate_piece()
					
	elif event is InputEventScreenDrag and is_touch_active:
		var drag_ev = event as InputEventScreenDrag
		var delta = drag_ev.position - touch_last_pos
		touch_last_pos = drag_ev.position
		touch_accumulated += delta
		
		while touch_accumulated.x <= -TOUCH_STEP_X:
			move_left()
			touch_accumulated.x += TOUCH_STEP_X
		while touch_accumulated.x >= TOUCH_STEP_X:
			move_right()
			touch_accumulated.x -= TOUCH_STEP_X
			
		while touch_accumulated.y >= TOUCH_STEP_Y:
			_step_down()
			touch_accumulated.y -= TOUCH_STEP_Y


func _on_swipe(direction: Vector2) -> void:
	if not is_active or not is_falling:
		return
	if direction.x < -0.5:
		move_left()
	elif direction.x > 0.5:
		move_right()
	elif direction.y > 0.5:
		quick_drop()
	elif direction.y < -0.5:
		rotate_piece()


func _spawn_current_piece() -> void:
	var shape_cells = current_piece.get("cells", [])
	if shape_cells.is_empty():
		return
		
	var dims = PolyominoLib.get_dimensions(shape_cells)
	var grid_w: int = board.GRID_WIDTH if board else 10
	var spawn_x = int((grid_w - dims.x) / 2)
	var spawn_y = 0
	current_pos = Vector2i(spawn_x, spawn_y)
	
	if not board.can_place_piece(shape_cells, current_pos):
		is_falling = false
		var audio_mgr = get_node_or_null("/root/AudioManager")
		if audio_mgr:
			audio_mgr.play_game_over()
		var state_mgr = get_node_or_null("/root/GameState")
		if state_mgr:
			var mode_label = "modern_falling" if has_special_items() else "classic_falling"
			state_mgr.trigger_game_over({"reason": "cannot_place_spawn", "mode": mode_label})
		return
		
	is_falling = true
	drop_timer = 0.0
	var gs = get_node_or_null("/root/GameState")
	var cur_lvl: int = gs.active_level if (gs and "active_level" in gs) else 1
	PolyominoLib.stamp_piece_material(current_piece, cur_lvl)
	board.set_preview(
		shape_cells,
		current_pos,
		true,
		current_piece.get("color", Color.CYAN),
		int(current_piece.get("color_id", 1)),
		String(current_piece.get("material_id", ""))
	)


func _step_down() -> void:
	if not is_falling or current_piece.is_empty():
		return
		
	var target_pos = current_pos + Vector2i(0, 1)
	var shape_cells = current_piece["cells"]
	
	if board.can_place_piece(shape_cells, target_pos):
		current_pos = target_pos
		board.set_preview(
			shape_cells,
			current_pos,
			true,
			current_piece.get("color", Color.CYAN),
			int(current_piece.get("color_id", 1)),
			String(current_piece.get("material_id", ""))
		)
	else:
		is_falling = false
		board.place_piece(
			shape_cells,
			current_pos,
			int(current_piece.get("color_id", 1)),
			String(current_piece.get("material_id", ""))
		)
		board.clear_preview()
		_on_piece_locked()


func _on_piece_locked() -> void:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		audio_mgr.play_piece_placement()
		
	var cell_count = current_piece.get("cells", []).size()
	var is_rainbow_piece: bool = (
		bool(current_piece.get("is_rainbow", false)) or
		int(current_piece.get("color_id", 0)) == 9 or
		String(current_piece.get("material_id", "")) in ["rainbow", "seven_color"]
	)
	var state_mgr = get_node_or_null("/root/GameState")
	
	var pass_count := 0
	while pass_count < 20:
		pass_count += 1
		var clear_res = board.check_and_clear_lines(allows_column_clear(), uses_gravity())
		var lines_cleared = int(clear_res.get("lines_cleared", 0))
		var pass_is_rainbow = is_rainbow_piece or bool(clear_res.get("has_rainbow", false))
		
		if lines_cleared > 0:
			if audio_mgr:
				var is_col_only = (clear_res.get("row_count", 0) == 0 and clear_res.get("col_count", 0) > 0)
				audio_mgr.play_line_clear(lines_cleared, is_col_only)
			
			if state_mgr:
				state_mgr.process_move_result(
					cell_count if pass_count == 1 else 0,
					lines_cleared,
					int(clear_res.get("row_count", 0)),
					int(clear_res.get("col_count", 0)),
					int(clear_res.get("unique_cells_cleared", 0)),
					pass_is_rainbow,
					clear_res.get("collected_special_items", [])
				)
				if (
					has_special_items() and
					state_mgr.has_method("can_level_have_special_board_items") and
					state_mgr.can_level_have_special_board_items(state_mgr.active_level, rule_mode) and
					board.has_method("get_special_item_count_on_board") and
					board.get_special_item_count_on_board() < 3
				):
					board.try_spawn_milestone_special_item_in_occupied_cell("", state_mgr.active_level, true)
				drop_interval = clamp(0.82 - float(state_mgr.level - 1) * 0.04, 0.32, 0.82)
				if state_mgr.current_state != GameStateScript.State.PLAYING:
					return
		else:
			if pass_count == 1 and state_mgr:
				state_mgr.process_move_result(
					cell_count,
					0, 0, 0, 0,
					pass_is_rainbow,
					[]
				)
				drop_interval = clamp(0.82 - float(state_mgr.level - 1) * 0.04, 0.32, 0.82)
				if state_mgr.current_state != GameStateScript.State.PLAYING:
					return
			break

	var cur_lvl: int = state_mgr.active_level if (state_mgr and "active_level" in state_mgr) else 1
	current_piece = next_piece
	next_piece = _pick_next_falling_piece(cur_lvl)
	_update_previews()
	_spawn_current_piece()


func move_left() -> void:
	if not is_falling or current_piece.is_empty():
		return
	var target = current_pos + Vector2i(-1, 0)
	if board.can_place_piece(current_piece["cells"], target):
		current_pos = target
		var audio_mgr = get_node_or_null("/root/AudioManager")
		if audio_mgr and audio_mgr.has_method("play_piece_move"):
			audio_mgr.play_piece_move()
		board.set_preview(
			current_piece["cells"],
			current_pos,
			true,
			current_piece.get("color", Color.CYAN),
			int(current_piece.get("color_id", 1)),
			String(current_piece.get("material_id", ""))
		)


func move_right() -> void:
	if not is_falling or current_piece.is_empty():
		return
	var target = current_pos + Vector2i(1, 0)
	if board.can_place_piece(current_piece["cells"], target):
		current_pos = target
		var audio_mgr = get_node_or_null("/root/AudioManager")
		if audio_mgr and audio_mgr.has_method("play_piece_move"):
			audio_mgr.play_piece_move()
		board.set_preview(
			current_piece["cells"],
			current_pos,
			true,
			current_piece.get("color", Color.CYAN),
			int(current_piece.get("color_id", 1)),
			String(current_piece.get("material_id", ""))
		)


func rotate_piece() -> void:
	if not is_falling or current_piece.is_empty():
		return
	var rotated = PolyominoLib.rotate_90_cw(current_piece["cells"])
	var dims = PolyominoLib.get_dimensions(rotated)
	var target = current_pos
	var grid_w: int = board.GRID_WIDTH if board else 10
	
	if target.x + dims.x > grid_w:
		target.x = grid_w - dims.x
	if target.x < 0:
		target.x = 0
	
	var rotated_ok := false
	if board.can_place_piece(rotated, target):
		current_pos = target
		current_piece["cells"] = rotated
		rotated_ok = true
	elif target.x > 0 and board.can_place_piece(rotated, target + Vector2i(-1, 0)):
		current_pos = target + Vector2i(-1, 0)
		current_piece["cells"] = rotated
		rotated_ok = true
	elif target.x + dims.x < grid_w and board.can_place_piece(rotated, target + Vector2i(1, 0)):
		current_pos = target + Vector2i(1, 0)
		current_piece["cells"] = rotated
		rotated_ok = true
		
	if rotated_ok:
		var audio_mgr = get_node_or_null("/root/AudioManager")
		if audio_mgr:
			audio_mgr.play_rotation()
		board.set_preview(
			current_piece["cells"],
			current_pos,
			true,
			current_piece.get("color", Color.CYAN),
			int(current_piece.get("color_id", 1)),
			String(current_piece.get("material_id", ""))
		)


func quick_drop() -> void:
	if not is_falling or current_piece.is_empty():
		return
	var shape_cells = current_piece["cells"]
	var drop_pos = current_pos
	while board.can_place_piece(shape_cells, drop_pos + Vector2i(0, 1)):
		drop_pos += Vector2i(0, 1)
	current_pos = drop_pos
	_step_down()


# ==============================================================================
# MODERN SPECIAL ITEMS IN FALLING MODE: BOMB, CHANGE BLOCK, EXTRA LIFE
# ==============================================================================

func apply_special_item(item_id: String) -> bool:
	if not has_special_items() or not board:
		return false
	var state_mgr = get_node_or_null("/root/GameState")
	if item_id == "extra_life":
		if state_mgr and state_mgr.current_state != GameStateScript.State.GAME_OVER:
			return false
		return confirm_extra_life()
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
			board.set_bomb_target_highlight(Vector2i(4, 5), true)
			special_item_Pending_changed.emit("bomb")
			return false
		"change_block":
			cancel_pending_special_item()
			return confirm_change_block(0)
	return false


func cancel_pending_special_item() -> void:
	pending_special_item = ""
	if board:
		board.clear_bomb_target_highlight()
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
	if uses_gravity():
		board.apply_classic_gravity()
		board.queue_redraw()
	
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


func confirm_change_block(target_slot: int = 0) -> bool:
	if not has_special_items():
		return false
	var state_mgr = get_node_or_null("/root/GameState")
	if state_mgr and state_mgr.has_method("get_special_item_count") and state_mgr.get_special_item_count("change_block") <= 0:
		cancel_pending_special_item()
		return false
	
	var cur_lvl: int = state_mgr.active_level if (state_mgr and "active_level" in state_mgr) else 1
	if target_slot == 0:
		if current_piece.is_empty():
			return false
		var old_id: String = String(current_piece.get("id", ""))
		var candidates: Array[String] = []
		for raw_k in PolyominoLib.ACTIVE_SHAPE_KEYS:
			var k := String(raw_k)
			if k == old_id:
				continue
			var scells: Array = PolyominoLib.SHAPES[k].get("cells", [])
			if not PolyominoLib.is_valid_active_piece_size(scells.size()):
				continue
			if is_falling and board and not board.can_place_piece(scells, current_pos):
				continue
			candidates.append(k)
		if candidates.is_empty():
			return false
		var chosen_k: String = candidates[randi() % candidates.size()]
		current_piece = PolyominoLib.stamp_piece_material(PolyominoLib.get_shape(chosen_k), cur_lvl)
		if is_falling and board:
			board.set_preview(
				current_piece["cells"],
				current_pos,
				board.can_place_piece(current_piece["cells"], current_pos),
				current_piece.get("color", Color.CYAN),
				int(current_piece.get("color_id", 1)),
				String(current_piece.get("material_id", ""))
			)
	elif target_slot == 1:
		if next_piece.is_empty():
			return false
		var old_next_id: String = String(next_piece.get("id", ""))
		var new_next: Dictionary = PolyominoLib.get_random_shape_different_from(old_next_id, cur_lvl)
		if new_next.is_empty() or String(new_next.get("id", "")) == old_next_id:
			return false
		next_piece = new_next
		_update_previews()
	else:
		return false
	
	pending_special_item = ""
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
	var old_cur_id: String = String(current_piece.get("id", ""))
	var old_next_id: String = String(next_piece.get("id", ""))
	if "placement_checkpoints" in state_mgr and state_mgr.placement_checkpoints.size() > 0:
		state_mgr.rewind_extra_life_checkpoint(board)
	else:
		board.apply_extra_life_rescue()
		if uses_gravity():
			board.apply_classic_gravity()
			board.queue_redraw()
	
	var cur_lvl: int = state_mgr.active_level if (state_mgr and "active_level" in state_mgr) else 1
	current_piece = PolyominoLib.get_random_shape_different_from(old_cur_id, cur_lvl)
	next_piece = PolyominoLib.get_random_shape_different_from(old_next_id, cur_lvl)
	_update_previews()
	
	if state_mgr.has_method("revive_from_extra_life"):
		state_mgr.revive_from_extra_life()
	if not is_falling:
		_spawn_current_piece()
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_special_item"):
		audio_mgr.play_special_item("extra_life")
	special_item_consumed.emit("extra_life")
	return true


func check_game_over() -> bool:
	if current_piece.is_empty():
		return false
	var shape_cells = current_piece.get("cells", [])
	var dims = PolyominoLib.get_dimensions(shape_cells)
	var grid_w: int = board.GRID_WIDTH if board else 10
	var spawn_pos = Vector2i(int((grid_w - dims.x) / 2), 0)
	return not board.can_place_piece(shape_cells, spawn_pos)


func _update_previews() -> void:
	if mode_piece_area and mode_piece_area.has_method("set_classic_next_preview"):
		mode_piece_area.set_classic_next_preview(next_piece)


func _setup_board_and_piece_area() -> void:
	if not mode_piece_area:
		mode_piece_area = MODE_PIECE_AREA_SCENE.instantiate()
		add_child(mode_piece_area)
	
	if not board:
		board = BOARD_SCENE.instantiate()
		if board.has_method("configure_grid_dimensions"):
			board.configure_grid_dimensions(10, 12)
		add_child(board)
	
	if not touch_controls:
		_setup_touch_controls(0, 500)
	
	_update_layout()


func _update_layout() -> void:
	var vp_size := Vector2(720.0, 1280.0)
	if is_inside_tree() and get_viewport():
		var rect_sz := get_viewport_rect().size
		if rect_sz.x > 0 and rect_sz.y > 0:
			vp_size = rect_sz
	update_layout_for_viewport(vp_size)


## Strictly organizes the Falling mode vertical play layout:
##   1. HEADER (HUD + SpecialItemsBar in Modern mode)
##   2. NEXT PIECE AREA (ModePieceArea: NEXT / TIẾP label + centered preview)
##   3. 12×10 PLAY BOARD (Board)
##   4. CONTROL AREA (Group 1: LEFT / ROTATE / RIGHT; separated centered Group 2: QUICK DROP; NO Soft Drop)
##   5. AD SLOT (bottom 60px banner reservation)
## Guarantees comfortable non-touching spacing at 360×800, 390×844, and 720×1280 in both Classic and Modern modes.
func update_layout_for_viewport(vp_size: Vector2) -> Dictionary:
	var vp_w: float = vp_size.x if vp_size.x > 0 else 720.0
	var vp_h: float = vp_size.y if vp_size.y > 0 else 1280.0
	var is_compact: bool = (vp_w <= 430.0 or vp_h <= 900.0)
	
	# 1. Header bottom boundary (accounts for SpecialItemsBar when in Modern + Falling)
	var hud_h: float = (138.0 if is_compact else 156.0) if has_special_items() else (84.0 if is_compact else 98.0)
	# 5. Bottom AdSlot reservation
	var ad_h: float = 0.0
	var ad_top_y: float = vp_h
	
	var gap: float = 10.0 if is_compact else 16.0
	# 2. Dedicated Next Piece Area between Header and Play Board
	var piece_area_h: float = clampf(vp_h * 0.068, 50.0, 72.0)
	# 4. Dedicated Control Area (Left/Rotate/Right group + separated centered Quick Drop moved lower)
	var ctrl_h: float = clampf(vp_h * 0.132, 102.0, 140.0)
	
	var avail_v: float = maxf(260.0, ad_top_y - hud_h)
	var max_board_h: float = avail_v - piece_area_h - ctrl_h - (gap * 4.0)
	
	var board_sz := Vector2(vp_w * (10.0 / 12.0), vp_w)
	if board:
		board_sz = board.update_responsive_layout(vp_w, 0.0, max_board_h)
	var margin_x: float = (vp_w - board_sz.x) * 0.5
	var content_w: float = maxf(board_sz.x, minf(vp_w - 24.0, vp_w * (10.0 / 12.0)))
	var content_x: float = (vp_w - content_w) * 0.5
	
	var cluster_h: float = piece_area_h + gap + board_sz.y + gap + ctrl_h
	var free_v: float = maxf(0.0, avail_v - cluster_h)
	var extra_gap: float = free_v / 4.0
	var step_gap: float = maxf(gap, gap + extra_gap * 0.45)
	
	var piece_area_y: float = hud_h + maxf(gap, free_v * 0.22)
	var board_y: float = piece_area_y + piece_area_h + step_gap
	var ctrl_y: float = board_y + board_sz.y + step_gap
	
	var max_ctrl_y: float = ad_top_y - ctrl_h - gap
	if ctrl_y > max_ctrl_y:
		ctrl_y = max_ctrl_y
		board_y = ctrl_y - gap - board_sz.y
		piece_area_y = maxf(hud_h + 8.0, board_y - gap - piece_area_h)
	
	if mode_piece_area:
		if mode_piece_area.has_method("set_falling_active"):
			mode_piece_area.set_falling_active(true)
		if mode_piece_area.has_method("update_responsive_size"):
			mode_piece_area.update_responsive_size(Vector2(content_w, piece_area_h))
		else:
			mode_piece_area.custom_minimum_size = Vector2(content_w, piece_area_h)
			mode_piece_area.size = Vector2(content_w, piece_area_h)
		mode_piece_area.position = Vector2(content_x, piece_area_y)
	
	if board:
		board.position = Vector2(margin_x, board_y)
	
	var group_sep: float = QUICK_DROP_SEPARATION_COMPACT if is_compact else QUICK_DROP_SEPARATION_REGULAR
	var row1_h: float = floor((ctrl_h - group_sep) * 0.51)
	var row2_h: float = maxf(36.0, ctrl_h - group_sep - row1_h)
	var qd_w: float = round(content_w * 0.68)
	var qd_x: float = content_x + (content_w - qd_w) * 0.5
	
	if touch_controls:
		touch_controls.position = Vector2(content_x, ctrl_y)
		touch_controls.custom_minimum_size = Vector2(content_w, ctrl_h)
		touch_controls.size = Vector2(content_w, ctrl_h)
		_resize_touch_control_rows(content_w, ctrl_h, is_compact)
	
	var header_rect := Rect2(Vector2(0.0, 0.0), Vector2(vp_w, hud_h))
	var next_piece_rect := Rect2(Vector2(content_x, piece_area_y), Vector2(content_w, piece_area_h))
	var board_rect := Rect2(Vector2(margin_x, board_y), board_sz)
	var controls_rect := Rect2(Vector2(content_x, ctrl_y), Vector2(content_w, ctrl_h))
	var ad_rect := Rect2(Vector2(0.0, ad_top_y), Vector2(vp_w, ad_h))
	var lrr_rect := Rect2(Vector2(content_x, ctrl_y), Vector2(content_w, row1_h))
	var qd_rect := Rect2(Vector2(qd_x, ctrl_y + row1_h + group_sep), Vector2(qd_w, row2_h))
	
	return {
		"header_rect": header_rect,
		"next_piece_rect": next_piece_rect,
		"board_rect": board_rect,
		"controls_rect": controls_rect,
		"ad_rect": ad_rect,
		"left_rotate_right_rect": lrr_rect,
		"quick_drop_rect": qd_rect,
		"header_bottom": hud_h,
		"next_piece_top": piece_area_y,
		"next_piece_bottom": piece_area_y + piece_area_h,
		"board_top": board_y,
		"board_bottom": board_y + board_sz.y,
		"controls_top": ctrl_y,
		"controls_bottom": ctrl_y + ctrl_h,
		"ad_slot_top": ad_top_y,
		"header_to_next_gap": piece_area_y - hud_h,
		"next_to_board_gap": board_y - (piece_area_y + piece_area_h),
		"board_to_controls_gap": ctrl_y - (board_y + board_sz.y),
		"controls_to_ad_gap": ad_top_y - (ctrl_y + ctrl_h),
		"group_to_quick_drop_gap": group_sep,
		"has_soft_drop": has_soft_drop_button(),
		"viewport_height": vp_h
	}


func has_soft_drop_button() -> bool:
	if btn_down != null:
		return true
	if touch_controls and touch_controls.find_child("BtnSoftDrop", true, false) != null:
		return true
	return false


func _resize_touch_control_rows(ctrl_w: float, ctrl_h: float, is_compact: bool) -> void:
	if not touch_controls or touch_controls.get_child_count() == 0:
		return
	var vbox := touch_controls.get_child(0) as VBoxContainer
	if not vbox:
		return
	var sep: float = QUICK_DROP_SEPARATION_COMPACT if is_compact else QUICK_DROP_SEPARATION_REGULAR
	vbox.add_theme_constant_override("separation", int(sep))
	vbox.position = Vector2.ZERO
	vbox.custom_minimum_size = Vector2(ctrl_w, ctrl_h)
	vbox.size = Vector2(ctrl_w, ctrl_h)
	var row1_h: float = floor((ctrl_h - sep) * 0.51)
	var row2_h: float = maxf(36.0, ctrl_h - sep - row1_h)
	var qd_w: float = round(ctrl_w * 0.68)
	if vbox.get_child_count() >= 2:
		var r1 := vbox.get_child(0) as HBoxContainer
		var r2 := vbox.get_child(1) as HBoxContainer
		if r1:
			r1.custom_minimum_size = Vector2(ctrl_w, row1_h)
			r1.size = Vector2(ctrl_w, row1_h)
			r1.position = Vector2.ZERO
		if r2:
			r2.custom_minimum_size = Vector2(ctrl_w, row2_h)
			r2.size = Vector2(ctrl_w, row2_h)
			r2.position = Vector2(0.0, row1_h + sep)
	if btn_drop:
		btn_drop.custom_minimum_size = Vector2(qd_w, row2_h)
		btn_drop.size = Vector2(qd_w, row2_h)
		btn_drop.position = Vector2((ctrl_w - qd_w) * 0.5, 0.0)
	var f_sz: int = 13 if is_compact else 17
	var icon_sz := Vector2(18, 18) if is_compact else Vector2(22, 22)
	for b in [btn_left, btn_rotate, btn_right, btn_drop]:
		if b:
			b.add_theme_font_size_override("font_size", f_sz)
			var vi := b.get_node_or_null("VectorIcon") as Control
			if vi:
				vi.custom_minimum_size = icon_sz
				vi.size = icon_sz
				if vi.has_method("_on_parent_resized"):
					vi._on_parent_resized()


func _setup_touch_controls(margin_x: float, width: float) -> void:
	btn_down = null
	touch_controls = Control.new()
	touch_controls.name = "ClassicTouchControls"
	touch_controls.position = Vector2(margin_x, 795)
	touch_controls.size = Vector2(width, 124)
	
	var vbox = VBoxContainer.new()
	vbox.name = "ControlsVBox"
	vbox.position = Vector2.ZERO
	vbox.custom_minimum_size = Vector2(width, 124)
	vbox.size = Vector2(width, 124)
	vbox.add_theme_constant_override("separation", int(QUICK_DROP_SEPARATION_REGULAR))
	touch_controls.add_child(vbox)
	
	# Group 1: LEFT / ROTATE / RIGHT
	var row1 = HBoxContainer.new()
	row1.name = "MoveRotateGroup"
	row1.custom_minimum_size = Vector2(0, 56)
	row1.add_theme_constant_override("separation", 12)
	row1.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(row1)
	
	btn_left = _create_control_button("   LEFT", Color(0.16, 0.20, 0.46, 0.94), Color(0.24, 0.90, 1.0, 0.95))
	btn_left.name = "BtnLeft"
	UIIconScript.attach_to_button(btn_left, "left", Vector2(22, 22), "left")
	btn_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_left.pressed.connect(move_left)
	row1.add_child(btn_left)
	
	btn_rotate = _create_control_button("   ROTATE", Color(0.38, 0.16, 0.56, 0.94), Color(1.0, 0.84, 0.24, 0.98))
	btn_rotate.name = "BtnRotate"
	UIIconScript.attach_to_button(btn_rotate, "turn", Vector2(22, 22), "left")
	btn_rotate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_rotate.pressed.connect(rotate_piece)
	row1.add_child(btn_rotate)
	
	btn_right = _create_control_button("RIGHT   ", Color(0.16, 0.20, 0.46, 0.94), Color(0.24, 0.90, 1.0, 0.95))
	btn_right.name = "BtnRight"
	UIIconScript.attach_to_button(btn_right, "right", Vector2(22, 22), "right")
	btn_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_right.pressed.connect(move_right)
	row1.add_child(btn_right)
	
	# Group 2: Centered & Visually Separated QUICK DROP (Soft Drop completely removed)
	var row2 = HBoxContainer.new()
	row2.name = "QuickDropRow"
	row2.custom_minimum_size = Vector2(0, 50)
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(row2)
	
	btn_drop = _create_control_button("   QUICK DROP", Color(0.08, 0.56, 0.36, 0.96), Color(0.28, 0.98, 0.64, 0.98))
	btn_drop.name = "BtnQuickDrop"
	UIIconScript.attach_to_button(btn_drop, "bolt", Vector2(22, 22), "left")
	btn_drop.custom_minimum_size = Vector2(round(width * 0.68), 50)
	btn_drop.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_drop.pressed.connect(quick_drop)
	row2.add_child(btn_drop)
	
	add_child(touch_controls)
	_refresh_control_labels()


func _refresh_control_labels() -> void:
	var gs = get_node_or_null("/root/GameState")
	if not gs or not gs.has_method("tr_text"):
		return
	if btn_left: btn_left.text = "   " + gs.tr_text("ctrl_left")
	if btn_rotate: btn_rotate.text = "   " + gs.tr_text("ctrl_turn")
	if btn_right: btn_right.text = gs.tr_text("ctrl_right") + "   "
	if btn_drop: btn_drop.text = "   " + gs.tr_text("ctrl_hard_drop")


func _create_control_button(text: String, bg_col: Color, border_col: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.add_theme_font_override("font", GameTypographyScript.get_hud_number_font(0.20, 1))
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.68))
	btn.add_theme_constant_override("shadow_offset_x", 1)
	btn.add_theme_constant_override("shadow_offset_y", 2)
	
	var style = StyleBoxFlat.new()
	style.bg_color = bg_col
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 5
	style.border_color = border_col
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	
	var style_pressed = style.duplicate()
	style_pressed.bg_color = bg_col.lightened(0.22)
	style_pressed.border_width_bottom = 2
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	UIIconScript.remove_focus_outline(btn)
	return btn


func get_board() -> Node2D:
	return board


func get_mode_piece_area() -> Control:
	return mode_piece_area


func get_touch_controls() -> Control:
	return touch_controls


func _on_mode_ended() -> void:
	cancel_pending_special_item()
	is_falling = false
	if board:
		board.clear_board()


func _on_mode_reset() -> void:
	cancel_pending_special_item()
	is_falling = false
	if board:
		board.clear_board()
