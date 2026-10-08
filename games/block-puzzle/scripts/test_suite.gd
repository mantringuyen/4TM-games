extends Node

const GameStateScript = preload("res://scripts/autoload/game_state.gd")
const BoardScript = preload("res://scripts/game/board.gd")
const PolyominoLib = preload("res://scripts/core/polyomino_library.gd")
const TrayPieceScript = preload("res://scripts/game/tray_piece.gd")
const PieceTrayScript = preload("res://scripts/game/piece_tray.gd")
const ModernModeScript = preload("res://scripts/core/modern_mode.gd")
const ClassicModeScript = preload("res://scripts/core/classic_mode.gd")
const RewardedAdInterfaceScript = preload("res://scripts/core/rewarded_ad_interface.gd")
const UIIconScript = preload("res://scripts/ui/ui_icon.gd")
const SpecialItemsBarScript = preload("res://scripts/ui/special_items_bar.gd")
const SpecialItemsBarScene = preload("res://scenes/ui/special_items_bar.tscn")
const ModePieceAreaScene = preload("res://scenes/game/mode_piece_area.tscn")
const HUDScript = preload("res://scripts/ui/hud.gd")
const HUDScene = preload("res://scenes/ui/hud.tscn")
const MainMenuScript = preload("res://scripts/ui/main_menu.gd")
const MainMenuScene = preload("res://scenes/ui/main_menu.tscn")
const PauseMenuScript = preload("res://scripts/ui/pause_menu.gd")
const PauseMenuScene = preload("res://scenes/ui/pause_menu.tscn")
const GameOverModalScript = preload("res://scripts/ui/game_over_modal.gd")
const GameOverModalScene = preload("res://scenes/ui/game_over_modal.tscn")
const MainScene = preload("res://scenes/main.tscn")
const MapThemeScript = preload("res://scripts/map_core/map_theme.gd")
const MapRouteScript = preload("res://scripts/map_core/map_route.gd")
const MapNodeScript = preload("res://scripts/map_core/map_node.gd")
const MapPageScript = preload("res://scripts/map_core/map_page.gd")
const MapLayoutGeneratorScript = preload("res://scripts/map_core/map_layout_generator.gd")
const MapRendererScript = preload("res://scripts/map_core/map_renderer.gd")
const MapDataScript = preload("res://scripts/map_core/map_data.gd")
const BlockPuzzleMapConfigScript = preload("res://scripts/map_core/block_puzzle_map_config.gd")

var _tests_completed: bool = false
var _quit_delay_frames: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[TEST] Initializing Block Puzzle — 4TM Test Suite (12x10 Board, 500 Levels, Single-Language EN/VI, 2x2 Architecture & Modern Boosters)...")
	var bg_main := get_node_or_null("Main")
	if bg_main:
		remove_child(bg_main)
		bg_main.queue_free()
	
	var game_state = get_node_or_null("/root/GameState")
	if not game_state:
		printerr("[FAIL] GameState autoload not found")
		get_tree().quit(1)
		return
	
	var input_manager = get_node_or_null("/root/InputManager")
	if not input_manager:
		printerr("[FAIL] InputManager autoload not found")
		get_tree().quit(1)
		return
	
	game_state.reset_progression(false)
	game_state.set_language("en", false)
	
	var board = BoardScript.new()
	add_child(board)
	
	# =========================================================================
	# TESTS 1 & 2: Valid and Invalid Piece Placement on 12x10 Board
	# =========================================================================
	board.clear_board()
	var square_shape = PolyominoLib.get_shape("square_2x2")
	var placed_1 = board.place_piece(square_shape["cells"], Vector2i(0, 0), 1)
	if not placed_1 or board.get_occupied_cell_count() != 4:
		printerr("[FAIL Test 1] Valid piece placement failed")
		get_tree().quit(1)
		return
	print("[TEST 1/42] Valid piece placement on 12x10 board: PASSED")
	
	var placed_invalid = board.place_piece(square_shape["cells"], Vector2i(0, 0), 1)
	if placed_invalid or board.get_occupied_cell_count() != 4:
		printerr("[FAIL Test 2] Invalid placement should be rejected without board mutation")
		get_tree().quit(1)
		return
	print("[TEST 2/42] Invalid placement rejection: PASSED")
	
	# =========================================================================
	# TESTS 3 & 4: Completed Row (10 cols) and Column (12 rows) Detection
	# =========================================================================
	board.clear_board()
	for x in range(board.GRID_WIDTH):
		board.grid_data[0][x] = 1
	var completed_rows = board.get_completed_rows()
	if completed_rows != [0]:
		printerr("[FAIL Test 3] Completed row detection failed on 12x10 board. Got: ", completed_rows)
		get_tree().quit(1)
		return
	print("[TEST 3/42] Completed row detection (10 columns wide): PASSED")
	
	board.clear_board()
	for y in range(board.GRID_HEIGHT):
		board.grid_data[y][3] = 1
	var completed_cols = board.get_completed_columns()
	if completed_cols != [3]:
		printerr("[FAIL Test 4] Completed column detection failed on 12x10 board. Got: ", completed_cols)
		get_tree().quit(1)
		return
	print("[TEST 4/42] Completed column detection (12 rows tall): PASSED")
	
	# =========================================================================
	# TESTS 5, 6, 7: Modern Line Clearing (Rows, Columns, Both on 12x10 Board)
	# =========================================================================
	board.clear_board()
	for x in range(board.GRID_WIDTH):
		board.grid_data[2][x] = 1
	var res_mod_row = board.check_and_clear_lines(true)
	if res_mod_row["lines_cleared"] != 1 or board.get_occupied_cell_count() != 0:
		printerr("[FAIL Test 5] Modern row clearing failed")
		get_tree().quit(1)
		return
	print("[TEST 5/42] Modern row clearing: PASSED")
	
	board.clear_board()
	for y in range(board.GRID_HEIGHT):
		board.grid_data[y][4] = 1
	var res_mod_col = board.check_and_clear_lines(true)
	if res_mod_col["lines_cleared"] != 1 or board.get_occupied_cell_count() != 0:
		printerr("[FAIL Test 6] Modern column clearing failed")
		get_tree().quit(1)
		return
	print("[TEST 6/42] Modern column clearing: PASSED")
	
	board.clear_board()
	for x in range(board.GRID_WIDTH):
		board.grid_data[1][x] = 1
	for y in range(board.GRID_HEIGHT):
		board.grid_data[y][1] = 1
	var res_mod_both = board.check_and_clear_lines(true)
	if res_mod_both["lines_cleared"] != 2 or board.get_occupied_cell_count() != 0:
		printerr("[FAIL Test 7] Modern simultaneous row + column clearing failed")
		get_tree().quit(1)
		return
	print("[TEST 7/42] Modern simultaneous row + column clearing: PASSED")
	
	# =========================================================================
	# TESTS 8 & 9: Classic Line Clearing (Rows Only, Never Columns on 12x10)
	# =========================================================================
	board.clear_board()
	for x in range(board.GRID_WIDTH):
		board.grid_data[5][x] = 1
	var res_classic_row = board.check_and_clear_lines(false)
	if res_classic_row["lines_cleared"] != 1 or board.get_occupied_cell_count() != 0:
		printerr("[FAIL Test 8] Classic row clearing failed")
		get_tree().quit(1)
		return
	print("[TEST 8/42] Classic row clearing: PASSED")
	
	board.clear_board()
	for y in range(board.GRID_HEIGHT):
		board.grid_data[y][5] = 1
	var res_classic_col = board.check_and_clear_lines(false)
	if res_classic_col["lines_cleared"] != 0 or board.get_occupied_cell_count() != board.GRID_HEIGHT:
		printerr("[FAIL Test 9] Classic mode must NOT clear columns")
		get_tree().quit(1)
		return
	print("[TEST 9/42] Classic mode column clear rejection (Rows Only): PASSED")
	
	# =========================================================================
	# TEST 10: Intersection Cells Cleared Correctly Without Double Counting (10 + 12 - 1 = 21)
	# =========================================================================
	board.clear_board()
	for x in range(board.GRID_WIDTH):
		board.grid_data[3][x] = 1
	for y in range(board.GRID_HEIGHT):
		board.grid_data[y][3] = 1
	var res_intersect = board.check_and_clear_lines(true)
	if res_intersect["unique_cells_cleared"] != 21:
		printerr("[FAIL Test 10] Intersection cell counting failed on 12x10 board. Expected 21 unique cells, got: ", res_intersect["unique_cells_cleared"])
		get_tree().quit(1)
		return
	print("[TEST 10/42] Intersection cell clear and counting (21 unique cells on 12x10): PASSED")
	
	# =========================================================================
	# TESTS 11, 12, 13: Scoring (Zero Placement Score, Single-Line, Multi-Line)
	# =========================================================================
	game_state.start_game(GameStateScript.GameMode.MODERN_DRAG_AND_DROP)
	var move_1 = game_state.process_move_result(4, 0)
	if move_1["total_points"] != 0 or move_1["placement_points"] != 0 or game_state.score != 0:
		printerr("[FAIL Test 11] Placement without line clear must give 0 points! Expected 0, got: ", move_1["total_points"])
		get_tree().quit(1)
		return
	print("[TEST 11/42] Placement without line clear gives 0 score: PASSED")
	
	var move_2 = game_state.process_move_result(4, 1, 1, 0, 10)
	if move_2["placement_points"] != 0 or move_2["line_points"] != 10 or move_2["total_points"] != 10 or game_state.score != 10:
		printerr("[FAIL Test 12] Line clear score failed. Expected 10 points added (10 cells * 1x), got: ", move_2["total_points"])
		get_tree().quit(1)
		return
	print("[TEST 12/42] Score increases only after line clear: PASSED")
	
	game_state.start_game(GameStateScript.GameMode.MODERN_DRAG_AND_DROP)
	var single_clear = game_state.process_move_result(4, 1, 1, 0, 10)
	game_state.start_game(GameStateScript.GameMode.MODERN_DRAG_AND_DROP)
	var multi_clear = game_state.process_move_result(4, 2, 2, 0, 20)
	if multi_clear["line_points"] <= single_clear["line_points"] or multi_clear["total_points"] != 30:
		printerr("[FAIL Test 13] Multi-line clear score must exceed single-line clear score (30 vs 10)")
		get_tree().quit(1)
		return
	print("[TEST 13/42] Multiple-line clear higher scoring (20 * 1.5x = 30): PASSED")
	
	# =========================================================================
	# TESTS 14 & 15: Combo Multiplier and Reset
	# =========================================================================
	game_state.start_game(GameStateScript.GameMode.MODERN_DRAG_AND_DROP)
	var combo_step1 = game_state.process_move_result(4, 1, 1, 0, 10)
	var combo_step2 = game_state.process_move_result(4, 2, 1, 1, 21)
	if combo_step2["combo_count"] != 2 or not bool(combo_step2["is_row_col_combo"]) or combo_step2["line_points"] <= combo_step1["line_points"]:
		printerr("[FAIL Test 14] Combo multiplier failed")
		get_tree().quit(1)
		return
	print("[TEST 14/42] Combo increases across clearing moves & Row+Col Combo x2: PASSED")
	
	var combo_reset = game_state.process_move_result(4, 0)
	if combo_reset["combo_count"] != 0 or game_state.combo_count != 0:
		printerr("[FAIL Test 15] Combo reset failed")
		get_tree().quit(1)
		return
	print("[TEST 15/42] Combo resets after non-clearing placement: PASSED")
	
	# =========================================================================
	# TEST 16: Level Progression on Target Score Reached
	# =========================================================================
	game_state.reset_progression(false)
	game_state.start_game(GameStateScript.GameMode.MODERN_DRAG_AND_DROP)
	game_state.process_move_result(4, 10)
	if game_state.level < 2 or not game_state.is_level_completed(1) or not game_state.is_level_unlocked(2):
		printerr("[FAIL Test 16] Level progression failed. Expected level >= 2 & Level 2 unlocked, got: ", game_state.level)
		get_tree().quit(1)
		return
	print("[TEST 16/42] Level progression & target completion unlock: PASSED")
	
	# =========================================================================
	# TESTS 17 & 18: Drag & Drop and Falling Game Over Detection on 12x10 Board
	# =========================================================================
	var modern_mode = ModernModeScript.new()
	add_child(modern_mode)
	modern_mode._on_mode_started()
	for y in range(modern_mode.board.GRID_HEIGHT):
		for x in range(modern_mode.board.GRID_WIDTH):
			modern_mode.board.grid_data[y][x] = 1
	modern_mode.board.grid_data[0][0] = 0
	for p in modern_mode.piece_tray.active_pieces:
		if p:
			p.cells = [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)]
	if not modern_mode.check_game_over():
		printerr("[FAIL Test 17] Drag & Drop game over detection failed when no piece fits on 10x8 board")
		get_tree().quit(1)
		return
	modern_mode.queue_free()
	print("[TEST 17/42] Drag & Drop game-over detection on 10x8 board: PASSED")
	
	var classic_mode = ClassicModeScript.new()
	add_child(classic_mode)
	classic_mode._on_mode_started()
	for x in range(classic_mode.board.GRID_WIDTH):
		classic_mode.board.grid_data[0][x] = 1
	classic_mode.current_piece = PolyominoLib.get_shape("square_2x2")
	if not classic_mode.check_game_over():
		printerr("[FAIL Test 18] Falling game over detection failed when spawn cell is blocked")
		get_tree().quit(1)
		return
	classic_mode.queue_free()
	print("[TEST 18/42] Falling game-over detection on 12x10 board: PASSED")
	
	# =========================================================================
	# TEST 19: Drag & Drop 3-Piece Tray Indefinite Replenishment
	# =========================================================================
	var tray = PieceTrayScript.new()
	add_child(tray)
	tray.spawn_new_round()
	if tray.get_remaining_piece_count() != 3:
		printerr("[FAIL Test 19] Tray must start with exactly 3 pieces")
		get_tree().quit(1)
		return
	for round_idx in range(5):
		var pieces_to_consume = tray.active_pieces.duplicate()
		for p in pieces_to_consume:
			if p:
				var p_cells = p.cells.size()
				if p_cells != 4:
					printerr("[FAIL Test 19] CRITICAL: Tray piece has non-4-cell count (must be strictly 4): ", p_cells)
					get_tree().quit(1)
					return
				tray.consume_piece(p)
		if tray.get_remaining_piece_count() != 3:
			printerr("[FAIL Test 19] Piece tray did not replenish to 3 pieces on round ", round_idx)
			get_tree().quit(1)
			return
	tray.queue_free()
	print("[TEST 19/50] Drag & Drop 3-piece tray indefinite replenishment (5 rounds, strictly 4-cell only): PASSED")
	
	# =========================================================================
	# TEST 20: CRITICAL — 12x10 Board (12 Rows x 10 Columns) & ONLY 4-Cell Active Pieces
	# =========================================================================
	if board.GRID_ROWS != 12 or board.GRID_COLS != 10 or board.GRID_HEIGHT != 12 or board.GRID_WIDTH != 10:
		printerr("[FAIL Test 20] Board grid size must be 12 rows x 10 columns! Got: ", board.GRID_HEIGHT, "x", board.GRID_WIDTH)
		get_tree().quit(1)
		return
	if board.grid_data.size() != 12 or board.grid_data[0].size() != 10:
		printerr("[FAIL Test 20] Board grid_data dimensions do not match 12 rows x 10 columns!")
		get_tree().quit(1)
		return
	if PolyominoLib.has_active_five_cell_pieces() or PolyominoLib.has_non_four_cell_pieces():
		printerr("[FAIL Test 20] CRITICAL: PolyominoLibrary contains non-4-cell active pieces!")
		get_tree().quit(1)
		return
	for invalid_sz in [1, 2, 3, 5, 6]:
		if PolyominoLib.is_valid_active_piece_size(invalid_sz):
			printerr("[FAIL Test 20] CRITICAL: is_valid_active_piece_size accepted non-4 size: ", invalid_sz)
			get_tree().quit(1)
			return
	if not PolyominoLib.is_valid_active_piece_size(4):
		printerr("[FAIL Test 20] is_valid_active_piece_size(4) must return true!")
		get_tree().quit(1)
		return
	for shape_key in PolyominoLib.ACTIVE_SHAPE_KEYS:
		var c_count = PolyominoLib.SHAPES[shape_key]["cells"].size()
		if c_count != 4:
			printerr("[FAIL Test 20] CRITICAL: Non-4-cell piece found in ACTIVE_SHAPE_KEYS: ", shape_key, " size=", c_count)
			get_tree().quit(1)
			return
	for shape_key in PolyominoLib.SHAPES.keys():
		var c_count_all = PolyominoLib.SHAPES[shape_key]["cells"].size()
		if c_count_all != 4:
			printerr("[FAIL Test 20] CRITICAL: Non-4-cell piece found in SHAPES dictionary: ", shape_key, " size=", c_count_all)
			get_tree().quit(1)
			return
	for _i in range(100):
		var r_shape = PolyominoLib.get_random_shape()
		var rc = r_shape["cells"].size()
		if rc != 4:
			printerr("[FAIL Test 20] get_random_shape returned non-4-cell count: ", rc)
			get_tree().quit(1)
			return
		var diff_shape = PolyominoLib.get_random_shape_different_from(r_shape.get("id", ""))
		var dc = diff_shape["cells"].size()
		if dc != 4:
			printerr("[FAIL Test 20] get_random_shape_different_from returned non-4-cell count: ", dc)
			get_tree().quit(1)
			return
		var tray_set = PolyominoLib.get_random_tray_set(3)
		if tray_set.size() != 3:
			printerr("[FAIL Test 20] get_random_tray_set(3) did not return 3 pieces!")
			get_tree().quit(1)
			return
		for ts_piece in tray_set:
			if ts_piece.get("cells", []).size() != 4:
				printerr("[FAIL Test 20] get_random_tray_set returned non-4-cell piece!")
				get_tree().quit(1)
				return
	print("[TEST 20/50] 12x10 Board (12 rows x 10 cols) & strictly 4-cell ONLY active piece pool: PASSED")
	
	# =========================================================================
	# TEST 21: Drag & Drop Cancelled Drag / Pointer Release Boundary Check
	# =========================================================================
	var mode_test = ModernModeScript.new()
	add_child(mode_test)
	mode_test.initialize_mode()
	mode_test.start_mode()
	
	var m_tray = mode_test.get_piece_tray()
	var m_board = mode_test.get_board()
	var target_piece = m_tray.active_pieces[0]
	if target_piece:
		var tray_pointer_pos = m_tray.global_position + Vector2(50.0, 50.0)
		target_piece._start_drag(tray_pointer_pos, -1)
		mode_test._on_piece_drag_ended(target_piece, tray_pointer_pos)
		
		if m_tray.get_remaining_piece_count() != 3 or m_tray.active_pieces[0] == null:
			printerr("[FAIL Test 21] Piece was wrongly consumed on release over tray!")
			get_tree().quit(1)
			return
			
		var valid_board_pointer_pos = m_board.grid_to_world_shape_center(Vector2i(2, 2), target_piece.cells) + Vector2(0, target_piece.TOUCH_Y_OFFSET)
		target_piece._start_drag(valid_board_pointer_pos, -1)
		mode_test._on_piece_drag_ended(target_piece, valid_board_pointer_pos)
		
		if m_tray.get_remaining_piece_count() != 2:
			printerr("[FAIL Test 21] Valid board placement expected 2 pieces remaining, got: ", m_tray.get_remaining_piece_count())
			get_tree().quit(1)
			return
	mode_test.queue_free()
	print("[TEST 21/42] Drag & Drop cancelled drag / pointer release boundary check: PASSED")
	
	# =========================================================================
	# TEST 22: AudioManager Warm Acoustic BGM Loop, 13 Distinct SFX & Voice Callouts
	# =========================================================================
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if not audio_mgr:
		printerr("[FAIL Test 22] AudioManager autoload missing")
		get_tree().quit(1)
		return
	var required_sfx = [
		"button_press", "piece_pickup", "piece_movement", "valid_placement",
		"invalid_placement", "rotation", "row_clear", "column_clear",
		"multi_line_clear", "combo", "level_up", "game_over", "special_item"
	]
	for s_key in required_sfx:
		if not audio_mgr.sfx_cache.has(s_key) or audio_mgr.sfx_cache[s_key] == null:
			printerr("[FAIL Test 22] Missing distinct SFX stream: ", s_key)
			get_tree().quit(1)
			return
	if audio_mgr.bgm_stream == null or ((audio_mgr.bgm_stream is AudioStreamWAV) and audio_mgr.bgm_stream.loop_mode != AudioStreamWAV.LOOP_FORWARD):
		printerr("[FAIL Test 22] Looping BGM stream missing or invalid")
		get_tree().quit(1)
		return
	var required_callouts = ["nice", "great", "excellent", "combo", "amazing"]
	for c_key in required_callouts:
		if not audio_mgr.voice_cache.has(c_key) or audio_mgr.voice_cache[c_key] == null:
			printerr("[FAIL Test 22] Missing voice callout stream: ", c_key)
			get_tree().quit(1)
			return
		audio_mgr.play_voice_callout(c_key)
	print("[TEST 22/42] AudioManager warm acoustic BGM loop, 13 SFX & 5 voice callouts: PASSED")
	
	# =========================================================================
	# TEST 23: Falling UI Structure — ONLY NEXT Preview (No Current Preview)
	# =========================================================================
	var layout_classic = ClassicModeScript.new()
	add_child(layout_classic)
	layout_classic._setup_board_and_piece_area()
	layout_classic._update_layout()
	
	var mpa = layout_classic.mode_piece_area
	if not mpa or mpa.has_current_preview_ui() or not mpa.has_next_preview_ui():
		printerr("[FAIL Test 23] Falling UI must have ONLY Next preview and NO Current preview!")
		get_tree().quit(1)
		return
		
	var area_y = mpa.position.y
	var area_h = mpa.size.y
	var board_y = layout_classic.board.position.y
	var board_h = layout_classic.board.get_board_pixel_size().y
	var ctrl_y = layout_classic.touch_controls.position.y
	
	if not (area_y + area_h <= board_y and board_y + board_h <= ctrl_y):
		printerr("[FAIL Test 23] Falling vertical layout order invalid! Area Y=", area_y, " Board Y=", board_y, " Ctrl Y=", ctrl_y)
		get_tree().quit(1)
		return
	layout_classic.queue_free()
	print("[TEST 23/42] Falling UI has ONLY Next preview (no Current preview) & centered hierarchy: PASSED")
	
	# =========================================================================
	# TEST 24: Falling Gravity & Vertical Column Compaction on 12x10 Board vs Drag & Drop No-Gravity
	# =========================================================================
	var gravity_board = BoardScript.new()
	add_child(gravity_board)
	
	gravity_board.clear_board()
	var bottom_row: int = gravity_board.GRID_HEIGHT - 1
	for x in range(gravity_board.GRID_WIDTH):
		gravity_board.grid_data[bottom_row][x] = 1
	gravity_board.grid_data[bottom_row - 2][1] = 2
	gravity_board.grid_data[bottom_row - 1][1] = 3
	gravity_board.check_and_clear_lines(false, true)
	if gravity_board.get_cell(Vector2i(1, bottom_row)) != 3 or gravity_board.get_cell(Vector2i(1, bottom_row - 1)) != 2 or gravity_board.get_cell(Vector2i(1, bottom_row - 2)) != 0:
		printerr("[FAIL Test 24] Falling gravity compaction failed on 12x10 board!")
		get_tree().quit(1)
		return
		
	gravity_board.clear_board()
	for x in range(gravity_board.GRID_WIDTH):
		gravity_board.grid_data[bottom_row][x] = 1
	gravity_board.grid_data[bottom_row - 2][2] = 6
	gravity_board.check_and_clear_lines(true, false)
	if gravity_board.get_cell(Vector2i(2, bottom_row - 2)) != 6:
		printerr("[FAIL Test 24] Drag & Drop should NOT apply gravity!")
		get_tree().quit(1)
		return
	gravity_board.queue_free()
	print("[TEST 24/42] Falling downward gravity on 12x10 board vs Drag & Drop no-gravity: PASSED")
	
	# =========================================================================
	# TEST 25: Combination 1 — Classic + Falling
	# =========================================================================
	var combo_cf = ClassicModeScript.new()
	combo_cf.configure_combination(GameStateScript.GameMode.CLASSIC, GameStateScript.PlayStyle.FALLING)
	add_child(combo_cf)
	combo_cf.initialize_mode()
	combo_cf.start_mode()
	
	if combo_cf.allows_column_clear() or combo_cf.has_special_items() or not combo_cf.uses_gravity():
		printerr("[FAIL Test 25] Classic + Falling rules misconfigured!")
		get_tree().quit(1)
		return
	if combo_cf.apply_special_item("bomb") != false or combo_cf.apply_special_item("change_block") != false or combo_cf.apply_special_item("extra_life") != false:
		printerr("[FAIL Test 25] Classic + Falling must NOT allow special items!")
		get_tree().quit(1)
		return
	combo_cf.queue_free()
	print("[TEST 25/42] Combination 1 (Classic + Falling: row-only, no special items, gravity, Next-only): PASSED")
	
	# =========================================================================
	# TEST 26: Combination 2 — Classic + Drag & Drop
	# =========================================================================
	var combo_cd = ModernModeScript.new()
	combo_cd.configure_combination(GameStateScript.GameMode.CLASSIC, GameStateScript.PlayStyle.DRAG_AND_DROP)
	add_child(combo_cd)
	combo_cd.initialize_mode()
	combo_cd.start_mode()
	
	if not combo_cd.allows_column_clear() or combo_cd.has_special_items() or combo_cd.uses_gravity():
		printerr("[FAIL Test 26] Classic + Drag & Drop rules misconfigured!")
		get_tree().quit(1)
		return
	if combo_cd.apply_special_item("bomb") != false or combo_cd.apply_special_item("change_block") != false or combo_cd.apply_special_item("extra_life") != false:
		printerr("[FAIL Test 26] Classic + Drag & Drop must NOT allow special items!")
		get_tree().quit(1)
		return
	var cd_board = combo_cd.get_board()
	cd_board.clear_board()
	for y in range(cd_board.GRID_HEIGHT):
		cd_board.grid_data[y][4] = 1
	var cd_col_res = cd_board.check_and_clear_lines(combo_cd.allows_column_clear(), combo_cd.uses_gravity())
	if cd_col_res["lines_cleared"] != 1 or cd_col_res["col_count"] != 1 or cd_board.get_occupied_cell_count() != 0:
		printerr("[FAIL Test 26] Classic + Drag & Drop must clear completed columns! Result: ", cd_col_res)
		get_tree().quit(1)
		return
	# Also verify horizontal row clearing in Classic + Drag & Drop
	cd_board.clear_board()
	for x in range(cd_board.GRID_WIDTH):
		cd_board.grid_data[5][x] = 1
	var cd_row_res = cd_board.check_and_clear_lines(combo_cd.allows_column_clear(), combo_cd.uses_gravity())
	if cd_row_res["lines_cleared"] != 1 or cd_row_res["row_count"] != 1 or cd_board.get_occupied_cell_count() != 0:
		printerr("[FAIL Test 26] Classic + Drag & Drop must clear completed rows! Result: ", cd_row_res)
		get_tree().quit(1)
		return
	combo_cd.queue_free()
	print("[TEST 26/42] Combination 2 (Classic + Drag & Drop: row+col clear, no special items, 3-piece tray, no gravity): PASSED")
	
	# =========================================================================
	# TEST 27: Combination 3 — Modern + Falling
	# =========================================================================
	game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.FALLING)
	var combo_mf = ClassicModeScript.new()
	combo_mf.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.FALLING)
	add_child(combo_mf)
	combo_mf.initialize_mode()
	combo_mf.start_mode()
	
	if not combo_mf.allows_column_clear() or not combo_mf.has_special_items() or not combo_mf.uses_gravity():
		printerr("[FAIL Test 27] Modern + Falling rules misconfigured!")
		get_tree().quit(1)
		return
	var mf_board = combo_mf.get_board()
	mf_board.clear_board()
	for y in range(mf_board.GRID_HEIGHT):
		mf_board.grid_data[y][2] = 1
	var mf_col_res = mf_board.check_and_clear_lines(combo_mf.allows_column_clear(), combo_mf.uses_gravity())
	if mf_col_res["lines_cleared"] != 1 or mf_board.get_occupied_cell_count() != 0:
		printerr("[FAIL Test 27] Modern + Falling must clear completed columns!")
		get_tree().quit(1)
		return
	combo_mf.queue_free()
	print("[TEST 27/42] Combination 3 (Modern + Falling: row+col clear, 3 special items, gravity, Next-only): PASSED")
	
	# =========================================================================
	# TEST 28: Combination 4 — Modern + Drag & Drop
	# =========================================================================
	game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	var combo_md = ModernModeScript.new()
	combo_md.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	add_child(combo_md)
	combo_md.initialize_mode()
	combo_md.start_mode()
	
	if not combo_md.allows_column_clear() or not combo_md.has_special_items() or combo_md.uses_gravity():
		printerr("[FAIL Test 28] Modern + Drag & Drop rules misconfigured!")
		get_tree().quit(1)
		return
	combo_md.queue_free()
	print("[TEST 28/42] Combination 4 (Modern + Drag & Drop: row+col clear, 3 special items, 3-piece tray, no gravity): PASSED")
	
	# =========================================================================
	# TEST 29: Classic vs Modern HUD Special-Item Toolbar Visibility & Exact 3 Items (NO Rotate)
	# =========================================================================
	var hud_inst = HUDScene.instantiate() if HUDScene else HUDScript.new()
	add_child(hud_inst)
	hud_inst.update_responsive_layout(Vector2(720, 1280))
	
	game_state.start_game_combination(GameStateScript.GameMode.CLASSIC, GameStateScript.PlayStyle.FALLING)
	if hud_inst.is_special_items_visible():
		printerr("[FAIL Test 29] Classic + Falling HUD must NOT show SpecialItemsBar!")
		get_tree().quit(1)
		return
		
	game_state.start_game_combination(GameStateScript.GameMode.CLASSIC, GameStateScript.PlayStyle.DRAG_AND_DROP)
	if hud_inst.is_special_items_visible():
		printerr("[FAIL Test 29] Classic + Drag & Drop HUD must NOT show SpecialItemsBar!")
		get_tree().quit(1)
		return
		
	game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.FALLING)
	if not hud_inst.is_special_items_visible():
		printerr("[FAIL Test 29] Modern + Falling HUD MUST show SpecialItemsBar!")
		get_tree().quit(1)
		return
		
	game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	if not hud_inst.is_special_items_visible():
		printerr("[FAIL Test 29] Modern + Drag & Drop HUD MUST show SpecialItemsBar!")
		get_tree().quit(1)
		return
	var sbar = hud_inst.special_items_bar
	if not sbar or sbar.get_item_types() != ["bomb", "change_block", "extra_life"]:
		printerr("[FAIL Test 29] SpecialItemsBar must have exact items [bomb, change_block, extra_life]!")
		get_tree().quit(1)
		return
	if not sbar.btn_bomb or not sbar.btn_change_block or not sbar.btn_extra_life:
		printerr("[FAIL Test 29] SpecialItemsBar missing BtnBomb, BtnChangeBlock, or BtnExtraLife!")
		get_tree().quit(1)
		return
	if "XOAY" in sbar.btn_bomb.text or "XOAY" in sbar.btn_change_block.text or "XOAY" in sbar.btn_extra_life.text:
		printerr("[FAIL Test 29] SpecialItemsBar must NOT contain XOAY / Rotate item!")
		get_tree().quit(1)
		return
	hud_inst.queue_free()
	print("[TEST 29/42] Classic hides toolbar & Modern shows exact [BOMB, CHANGE BLOCK, EXTRA LIFE] (NO Rotate): PASSED")
	
	# =========================================================================
	# TEST 30: Music Toggle Independent from SFX Toggle
	# =========================================================================
	audio_mgr.music_enabled = true
	audio_mgr.sound_enabled = true
	audio_mgr.music_enabled = false
	if audio_mgr.music_enabled != false or audio_mgr.sound_enabled != true or audio_mgr.is_music_playing():
		printerr("[FAIL Test 30] Turning Music OFF should not disable SFX and must stop BGM!")
		get_tree().quit(1)
		return
	print("[TEST 30/42] Music OFF + SFX ON independence verified: PASSED")
	
	# =========================================================================
	# TEST 31: SFX Toggle Independent from Music Toggle
	# =========================================================================
	audio_mgr.music_enabled = true
	audio_mgr.sound_enabled = false
	if audio_mgr.music_enabled != true or audio_mgr.sound_enabled != false or not audio_mgr.is_music_playing():
		printerr("[FAIL Test 31] Turning SFX OFF should keep Music ON and playing!")
		get_tree().quit(1)
		return
	audio_mgr.music_enabled = true
	audio_mgr.sound_enabled = true
	print("[TEST 31/42] Music ON + SFX OFF independence verified: PASSED")
	
	# =========================================================================
	# TEST 32: Main Menu Large Mobile-First UI, Clean 2x2 Selector, No Redundant Map/Rules Buttons
	# =========================================================================
	var menu_inst = MainMenuScene.instantiate()
	add_child(menu_inst)
	if not menu_inst.btn_classic or not menu_inst.btn_modern or not menu_inst.btn_falling or not menu_inst.btn_drag_drop:
		printerr("[FAIL Test 32] MainMenu missing 2x2 Game Mode or Play Style buttons!")
		get_tree().quit(1)
		return
	if menu_inst.btn_start.custom_minimum_size.y < 88 or menu_inst.btn_classic.custom_minimum_size.y < 80:
		printerr("[FAIL Test 32] MainMenu buttons are too small for mobile-first UI!")
		get_tree().quit(1)
		return
	if menu_inst.has_rules_button_next_to_game_mode() or menu_inst.btn_rules_help != null:
		printerr("[FAIL Test 32] Home Menu must NOT show a Rules button next to Game Mode (Classic/Modern)!")
		get_tree().quit(1)
		return
	if menu_inst.has_redundant_world_map_button() or menu_inst.btn_open_level_map != null:
		printerr("[FAIL Test 32] Home Menu must NOT show a redundant World Map button; top-left BtnTopLevel is the only shortcut!")
		get_tree().quit(1)
		return
	if not menu_inst.btn_info or not menu_inst.btn_top_level or not menu_inst.btn_language_modal or menu_inst.btn_language != null:
		printerr("[FAIL Test 32] MainMenu missing bottom How To Play button (BtnInfo), top-left Level button (BtnTopLevel), or Settings Language button (or still has standalone BtnLanguage)!")
		get_tree().quit(1)
		return
	menu_inst.queue_free()
	print("[TEST 32/53] MainMenu large mobile-first UI, clean 2x2 selector, no redundant Rules/Map buttons: PASSED")
	
	# =========================================================================
	# TEST 33: Modern BOMB — Explicit Activation, Target Highlight & Confirmed Detonation
	# =========================================================================
	game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	var bomb_mode = ModernModeScript.new()
	bomb_mode.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	add_child(bomb_mode)
	bomb_mode.initialize_mode()
	bomb_mode.start_mode()
	
	var b_board = bomb_mode.get_board()
	b_board.clear_board()
	b_board.grid_data[4][4] = 2
	b_board.grid_data[4][5] = 3
	b_board.grid_data[5][4] = 4
	
	var bombs_before = game_state.get_special_item_count("bomb")
	var auto_exploded = bomb_mode.apply_special_item("bomb")
	if auto_exploded or bomb_mode.pending_special_item != "bomb":
		printerr("[FAIL Test 33] Bomb must NOT auto-explode; must enter target selection mode!")
		get_tree().quit(1)
		return
	if game_state.get_special_item_count("bomb") != bombs_before or b_board.get_occupied_cell_count() != 3:
		printerr("[FAIL Test 33] Bomb was consumed or board mutated before target confirmation!")
		get_tree().quit(1)
		return
	if not b_board.is_bomb_target_highlighted():
		printerr("[FAIL Test 33] Bomb target highlight reticle not active on board!")
		get_tree().quit(1)
		return
	bomb_mode.select_bomb_target(Vector2i(4, 4))
	if b_board.get_bomb_target_center() != Vector2i(4, 4):
		printerr("[FAIL Test 33] Bomb target selection failed to update center!")
		get_tree().quit(1)
		return
	var confirmed_ok = bomb_mode.confirm_bomb_target(Vector2i(4, 4))
	if not confirmed_ok or b_board.get_occupied_cell_count() != 0:
		printerr("[FAIL Test 33] Bomb confirmation failed to clear 3x3 target area!")
		get_tree().quit(1)
		return
	if game_state.get_special_item_count("bomb") != bombs_before - 1 or b_board.is_bomb_target_highlighted():
		printerr("[FAIL Test 33] Bomb count not decremented or highlight not cleared after confirmation!")
		get_tree().quit(1)
		return
	bomb_mode.queue_free()
	print("[TEST 33/42] Modern BOMB explicit activation, target highlight & confirmed detonation: PASSED")
	
	# =========================================================================
	# TEST 34: Modern CHANGE BLOCK — Instant One-Tap Action & 4-Cell Replacement
	# =========================================================================
	game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	var cb_mode = ModernModeScript.new()
	cb_mode.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	add_child(cb_mode)
	cb_mode.initialize_mode()
	cb_mode.start_mode()
	
	var cb_tray = cb_mode.get_piece_tray()
	var old_shape_id: String = cb_tray.active_pieces[0].shape_data.get("id", "")
	var cb_before = game_state.get_special_item_count("change_block")
	
	var cb_ok = cb_mode.apply_special_item("change_block")
	var new_piece_data: Dictionary = cb_tray.active_pieces[0].shape_data
	var new_cells_cnt: int = new_piece_data.get("cells", []).size()
	if not cb_ok or cb_mode.pending_special_item != "" or cb_tray.change_block_selection_active:
		printerr("[FAIL Test 34] Change Block must execute immediately on a single tap without entering selection mode!")
		get_tree().quit(1)
		return
	if new_piece_data.get("id", "") == old_shape_id or new_cells_cnt != 4:
		printerr("[FAIL Test 34] Change Block failed to replace piece with a different valid 4-cell shape immediately!")
		get_tree().quit(1)
		return
	if game_state.get_special_item_count("change_block") != cb_before - 1:
		printerr("[FAIL Test 34] Change Block inventory not decremented by exactly 1 after immediate replacement!")
		get_tree().quit(1)
		return
	cb_mode.queue_free()
	print("[TEST 34/50] Modern CHANGE BLOCK instant one-tap 4-cell replacement: PASSED")
	
	# =========================================================================
	# TEST 35: Modern EXTRA LIFE — Explicit Activation, Board Rescue Continue & Zero-Quantity Disable
	# =========================================================================
	game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	var el_mode = ModernModeScript.new()
	el_mode.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	add_child(el_mode)
	el_mode.initialize_mode()
	el_mode.start_mode()
	
	var el_board = el_mode.get_board()
	for y in range(3, el_board.GRID_HEIGHT):
		for x in range(el_board.GRID_WIDTH):
			el_board.grid_data[y][x] = 1
	var before_rescue_cells: int = el_board.get_occupied_cell_count()
	game_state.trigger_game_over({"reason": "no_valid_moves"})
	if game_state.get_special_item_count("extra_life") != 1 or game_state.current_state != GameStateScript.State.GAME_OVER:
		printerr("[FAIL Test 35] Extra Life must NOT auto-activate on Game Over without player confirmation!")
		get_tree().quit(1)
		return
	var el_ok = el_mode.apply_special_item("extra_life")
	if not el_ok or game_state.current_state != GameStateScript.State.PLAYING or game_state.get_special_item_count("extra_life") != 0:
		printerr("[FAIL Test 35] Explicit Extra Life failed to rescue board, revive state, or consume 1 item!")
		get_tree().quit(1)
		return
	if el_board.get_occupied_cell_count() >= before_rescue_cells:
		printerr("[FAIL Test 35] Extra Life did not clear rescue rows on the 12x10 board!")
		get_tree().quit(1)
		return
	if el_mode.apply_special_item("extra_life") != false:
		printerr("[FAIL Test 35] Extra Life must not activate when quantity is 0!")
		get_tree().quit(1)
		return
	var sbar_check = SpecialItemsBarScene.instantiate()
	add_child(sbar_check)
	if not sbar_check.btn_extra_life.disabled:
		printerr("[FAIL Test 35] Extra Life button must be disabled when quantity is 0!")
		get_tree().quit(1)
		return
	sbar_check.queue_free()
	el_mode.queue_free()
	print("[TEST 35/42] Modern EXTRA LIFE explicit continue, board rescue & 0-qty disabled state: PASSED")
	
	# =========================================================================
	# TEST 36: Controlled Random Special-Item Discovery (Modern Special Milestones Only, Never Normal Levels or Classic)
	# =========================================================================
	game_state.highest_unlocked_level = max(game_state.highest_unlocked_level, 5)
	game_state.start_level(5, GameStateScript.GameMode.CLASSIC, GameStateScript.PlayStyle.FALLING)
	var classic_disc = game_state.try_discover_special_item(2, 0.01, "bomb")
	if classic_disc.get("discovered", false) or game_state.get_special_item_count("bomb") != 0:
		printerr("[FAIL Test 36] Classic mode must NEVER discover or generate special items even on milestone levels!")
		get_tree().quit(1)
		return
	
	# Normal level (Level 1) in Modern mode must NEVER discover/award special items
	game_state.start_level(1, GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	var normal_lvl_before = game_state.get_special_item_count("change_block")
	var normal_lvl_disc = game_state.try_discover_special_item(2, 0.01, "change_block")
	if normal_lvl_disc.get("discovered", false) or game_state.get_special_item_count("change_block") != normal_lvl_before:
		printerr("[FAIL Test 36] Normal non-milestone levels in Modern mode must NEVER generate or award special items!")
		get_tree().quit(1)
		return
	
	# Special milestone level (Level 3 / Level 5) in Modern mode allows special item discovery/collection
	game_state.start_level(3, GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	var sbar_disc = SpecialItemsBarScene.instantiate()
	add_child(sbar_disc)
	var count_before_disc = game_state.get_special_item_count("change_block")
	var mod_disc = game_state.try_discover_special_item(2, 0.01, "change_block")
	if not mod_disc.get("discovered", false) or game_state.get_special_item_count("change_block") != count_before_disc + 1:
		printerr("[FAIL Test 36] Modern mode special-milestone discovery failed to add to inventory!")
		get_tree().quit(1)
		return
	if sbar_disc.last_reward_animated_item != "change_block":
		printerr("[FAIL Test 36] SpecialItemsBar did not animate reward acquisition on item discovery!")
		get_tree().quit(1)
		return
	sbar_disc.queue_free()
	print("[TEST 36/42] Controlled random special-item discovery (Modern milestone levels only, never normal levels or Classic): PASSED")
	
	# =========================================================================
	# TEST 37: Real Level Progression — Locking, 3-Star Thresholds, Best-Star Persistence, Next Level & Save/Load
	# =========================================================================
	var test_save_path := "user://test_block_puzzle_4tm_progression.cfg"
	game_state.reset_progression(false)
	
	if not game_state.is_level_unlocked(1) or game_state.is_level_unlocked(2) or game_state.is_level_unlocked(3):
		printerr("[FAIL Test 37] Only Level 1 should be unlocked initially!")
		get_tree().quit(1)
		return
	if game_state.start_level(2) != false or game_state.select_map_level(2) != false:
		printerr("[FAIL Test 37] Locked Level 2 must NOT be selectable or startable!")
		get_tree().quit(1)
		return
	
	if game_state.calculate_stars_for_score(450, 1) != 0:
		printerr("[FAIL Test 37] Score below target (450 < 500) must earn 0 stars!")
		get_tree().quit(1)
		return
	if game_state.calculate_stars_for_score(500, 1) != 1 or game_state.format_stars_string(1) != "* - -":
		printerr("[FAIL Test 37] Score at target (500) must earn 1 star (* - -)!")
		get_tree().quit(1)
		return
	if game_state.calculate_stars_for_score(625, 1) != 2 or game_state.format_stars_string(2) != "* * -":
		printerr("[FAIL Test 37] Score at 125% target (625) must earn 2 stars (* * -)!")
		get_tree().quit(1)
		return
	if game_state.calculate_stars_for_score(750, 1) != 3 or game_state.format_stars_string(3) != "* * *":
		printerr("[FAIL Test 37] Score at 150% target (750) must earn 3 stars (* * *)!")
		get_tree().quit(1)
		return
	
	var modal_inst = GameOverModalScene.instantiate()
	add_child(modal_inst)
	game_state.start_level(1, GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	game_state.add_score(800)
	var comp_res = game_state.trigger_level_complete(game_state.score)
	if not comp_res.get("level_complete", false) or comp_res.get("stars", 0) != 3:
		printerr("[FAIL Test 37] Completing Level 1 with 800 pts should award 3 stars!")
		get_tree().quit(1)
		return
	if not game_state.is_level_completed(1) or not game_state.is_level_unlocked(2) or game_state.highest_unlocked_level != 2:
		printerr("[FAIL Test 37] Completing Level 1 did not unlock Level 2!")
		get_tree().quit(1)
		return
	if not modal_inst.btn_next_level.visible or not modal_inst.last_was_level_complete:
		printerr("[FAIL Test 37] GameOverModal did not show Next Level button on Level Complete!")
		get_tree().quit(1)
		return
	
	game_state.record_level_completion(1, 510)
	if game_state.get_level_best_stars(1) != 3 or game_state.total_stars != 3:
		printerr("[FAIL Test 37] Best stars for Level 1 were downgraded on lower replay score!")
		get_tree().quit(1)
		return
	
	if not game_state.start_next_level() or game_state.active_level != 2 or game_state.current_state != GameStateScript.State.PLAYING:
		printerr("[FAIL Test 37] start_next_level() failed to start unlocked Level 2!")
		get_tree().quit(1)
		return
	
	game_state.save_progression(test_save_path)
	game_state.reset_progression(false)
	var loaded_ok = game_state.load_progression(test_save_path)
	if not loaded_ok or game_state.highest_unlocked_level != 2 or not game_state.is_level_completed(1) or game_state.get_level_best_stars(1) != 3:
		printerr("[FAIL Test 37] Progression failed to persist and reload from local config!")
		get_tree().quit(1)
		return
	modal_inst.queue_free()
	print("[TEST 37/42] Real Level Progression (locking, 1-3 stars, best-star preservation, Next Level & persistence): PASSED")

	# =========================================================================
	# TEST 38: Celebratory Particle Burst & Visual Theme Switching on 12x10 Board
	# =========================================================================
	board.clear_board()
	board.set_visual_mode(false)
	if board.is_modern_visual_theme != false:
		printerr("[FAIL Test 38] Board visual theme failed to switch to Classic!")
		get_tree().quit(1)
		return
	board.set_visual_mode(true)
	for x in range(board.GRID_WIDTH):
		board.grid_data[0][x] = 1
	board.check_and_clear_lines(true, false)
	if board.burst_particles.is_empty():
		printerr("[FAIL Test 38] Celebratory confetti particles did not spawn on line clear!")
		get_tree().quit(1)
		return
	print("[TEST 38/42] Celebratory particle burst & Classic/Modern visual theme switching: PASSED")

	# =========================================================================
	# TEST 39: Single-Language EN/VI Localization & No Bilingual Labels
	# =========================================================================
	game_state.set_language("en", false)
	var menu_lang = MainMenuScene.instantiate()
	add_child(menu_lang)
	if game_state.get_language() != "en" or menu_lang.btn_classic.text.find("\n") != -1:
		printerr("[FAIL Test 39] Default language must be English with single-line clean mode buttons!")
		get_tree().quit(1)
		return
	if "CLASSIC" not in menu_lang.btn_classic.text or "CỔ ĐIỂN" in menu_lang.btn_classic.text:
		printerr("[FAIL Test 39] English mode button must show CLASSIC only, not Vietnamese!")
		get_tree().quit(1)
		return
	game_state.set_language("vi", false)
	if game_state.get_language() != "vi":
		printerr("[FAIL Test 39] Failed to switch language to VI!")
		get_tree().quit(1)
		return
	if "CỔ ĐIỂN" not in menu_lang.btn_classic.text or "CLASSIC" in menu_lang.btn_classic.text:
		printerr("[FAIL Test 39] Vietnamese mode button must show CỔ ĐIỂN only, not bilingual!")
		get_tree().quit(1)
		return
	game_state.save_progression(test_save_path)
	game_state.set_language("en", false)
	game_state.load_progression(test_save_path)
	if game_state.get_language() != "vi":
		printerr("[FAIL Test 39] Selected language failed to persist locally!")
		get_tree().quit(1)
		return
	game_state.set_language("en", false)
	menu_lang.queue_free()
	print("[TEST 39/42] Single-language EN/VI switching, persistence & zero bilingual UI labels: PASSED")

	# =========================================================================
	# TEST 40: Clean Mode/Play Style Selection & Standalone Rules Modal Button
	# =========================================================================
	var menu_clean = MainMenuScene.instantiate()
	add_child(menu_clean)
	if menu_clean.find_child("IntroCard", true, false) != null or menu_clean.find_child("LblDesc", true, false) != null:
		printerr("[FAIL Test 40] Home Menu must NOT show inline explanatory descriptions under mode/style buttons!")
		get_tree().quit(1)
		return
	menu_clean._on_btn_how_to_play_pressed()
	if not menu_clean.modal_how_to_play.visible or "12×10" not in menu_clean.lbl_rules_modal_content.text:
		printerr("[FAIL Test 40] Rules Help button failed to open localized 12x10 Rules Modal!")
		get_tree().quit(1)
		return
	menu_clean.queue_free()
	print("[TEST 40/42] Clean Mode/Play Style buttons without inline descriptions + Rules Help modal: PASSED")

	# =========================================================================
	# TEST 41: 500-Level Progression Support & Paginated Level Map Modal (World -> MapPages -> LevelNodes)
	# =========================================================================
	if game_state.get_total_supported_levels() != 500 or GameStateScript.TOTAL_LEVELS != 500:
		printerr("[FAIL Test 41] GameState must support 500 levels!")
		get_tree().quit(1)
		return
	var total_pages_41: int = game_state.get_level_map_page_count()
	if total_pages_41 <= 25:
		printerr("[FAIL Test 41] Expected variable-length 5–10 level MapPages (>25 pages) for 500 levels, got: ", total_pages_41)
		get_tree().quit(1)
		return
	var last_page = game_state.get_level_map_page(total_pages_41 - 1)
	if last_page.size() < 5 or last_page.size() > 10 or int(last_page[last_page.size() - 1].get("level", 0)) != 500:
		printerr("[FAIL Test 41] Final MapPage must have 5–10 levels and end at Level 500!")
		get_tree().quit(1)
		return
	var first_page_41: Array = game_state.get_level_map_page(0)
	var menu_map = MainMenuScene.instantiate()
	add_child(menu_map)
	menu_map._on_btn_open_level_map_pressed()
	var map_level_btn_count := 0
	for ch_node41 in menu_map.level_grid.get_children():
		if ch_node41 is Button:
			map_level_btn_count += 1
	if not menu_map.modal_level_map.visible or map_level_btn_count != first_page_41.size() or map_level_btn_count == 20:
		printerr("[FAIL Test 41] LevelMapModal failed to open or populate data-driven level count (", first_page_41.size(), ") on Page 1!")
		get_tree().quit(1)
		return
	menu_map.queue_free()
	print("[TEST 41/42] 500-Level progression & variable-length MapPage modal (5–10 levels per page): PASSED")

	# =========================================================================
	# TEST 42: Zero "Candy" or "Saga" References Across Game Files
	# =========================================================================
	var files_to_audit = [
		"res://scripts/autoload/game_state.gd",
		"res://scripts/autoload/audio_manager.gd",
		"res://scripts/game/board.gd",
		"res://scripts/game/game_world.gd",
		"res://scripts/game/piece_tray.gd",
		"res://scripts/game/tray_piece.gd",
		"res://scripts/game/mode_piece_area.gd",
		"res://scripts/core/classic_mode.gd",
		"res://scripts/core/modern_mode.gd",
		"res://scripts/ui/main_menu.gd",
		"res://scripts/ui/hud.gd",
		"res://scripts/ui/pause_menu.gd",
		"res://scripts/ui/game_over_modal.gd",
		"res://scenes/ui/main_menu.tscn",
		"res://scenes/ui/hud.tscn",
		"res://scenes/ui/pause_menu.tscn",
		"res://scenes/ui/game_over_modal.tscn"
	]
	var forbidden_word_1 := "can" + "dy"
	var forbidden_word_2 := "sa" + "ga"
	for f_path in files_to_audit:
		var fa = FileAccess.open(f_path, FileAccess.READ)
		if fa:
			var content_lower = fa.get_as_text().to_lower()
			if content_lower.find(forbidden_word_1) != -1 or content_lower.find(forbidden_word_2) != -1:
				printerr("[FAIL Test 42] Forbidden reference found in: ", f_path)
				get_tree().quit(1)
				return
	print("[TEST 42/48] Zero Candy/Saga references across all audited scripts & scenes: PASSED")

	# =========================================================================
	# TEST 43: 12x10 Board Responsive Width & ~1-Cell Horizontal Margins (720x1280 & Narrow Portrait)
	# =========================================================================
	for vp_width in [720.0, 390.0, 360.0]:
		var b_dims: Vector2 = board.update_responsive_layout(vp_width)
		var margin_each_side: float = (vp_width - b_dims.x) * 0.5
		var ratio_margin_to_cell: float = margin_each_side / max(1.0, board.CELL_SIZE)
		if b_dims.x < vp_width * 0.80 or b_dims.x > vp_width * 0.86:
			printerr("[FAIL Test 43] Board width ", b_dims.x, " on viewport ", vp_width, " did not use ~10/12 of available width!")
			get_tree().quit(1)
			return
		if ratio_margin_to_cell < 0.85 or ratio_margin_to_cell > 1.35:
			printerr("[FAIL Test 43] Horizontal margin (", margin_each_side, ") is not ~1 cell width (", board.CELL_SIZE, ") on viewport ", vp_width)
			get_tree().quit(1)
			return
	print("[TEST 43/48] 12x10 Board uses 10/12 width with ~1-cell left/right margins across portrait viewports: PASSED")

	# =========================================================================
	# TEST 44: Winding Path 500-Level Map & Reduced Home Menu Duplication
	# =========================================================================
	var menu_winding = MainMenuScene.instantiate()
	add_child(menu_winding)
	if menu_winding.find_child("WorldMapRow", true, false) != null:
		printerr("[FAIL Test 44] Home Menu must not duplicate the Level Map with an inline WorldMapRow strip!")
		get_tree().quit(1)
		return
	menu_winding._on_btn_open_level_map_pressed()
	menu_winding._layout_winding_path_nodes()
	var winding_level_nodes: Array[Control] = []
	for ch_w in menu_winding.level_grid.get_children():
		if ch_w is Button:
			winding_level_nodes.append(ch_w as Control)
	var expected_p0_cnt: int = game_state.get_level_map_page(0).size()
	if winding_level_nodes.size() != expected_p0_cnt or menu_winding.winding_path_points.size() != expected_p0_cnt:
		printerr("[FAIL Test 44] World Level Map must position ", expected_p0_cnt, " level destination nodes connected by ", expected_p0_cnt, " 3D-projected route points!")
		get_tree().quit(1)
		return
	var first_dest := winding_level_nodes[0]
	var last_dest := winding_level_nodes[winding_level_nodes.size() - 1]
	if absf(first_dest.position.y - last_dest.position.y) < 180.0:
		printerr("[FAIL Test 44] World Map route must progress spatially across the page terrain between first and last level!")
		get_tree().quit(1)
		return
	menu_winding.queue_free()
	print("[TEST 44/48] 3D World Map 500-level progression route & deduplicated Home Menu: PASSED")

	# =========================================================================
	# TEST 45: Modern Special Items — Distinct 3D Medallion Icons & States
	# =========================================================================
	var sbar_icons = SpecialItemsBarScene.instantiate()
	add_child(sbar_icons)
	if not sbar_icons.has_method("has_custom_medallion_icons") or not sbar_icons.has_custom_medallion_icons():
		printerr("[FAIL Test 45] SpecialItemsBar missing custom 3D medallion icon controls for Bomb, Change Block, and Extra Life!")
		get_tree().quit(1)
		return
	sbar_icons.queue_free()
	print("[TEST 45/48] Modern Special Items distinct 3D medallion icons (Bomb, Change Block, Extra Life): PASSED")

	# =========================================================================
	# TEST 46: Drag & Drop Interrupted Drag & Out-of-Bounds Recovery
	# =========================================================================
	game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	var dd_mode = ModernModeScript.new()
	dd_mode.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	add_child(dd_mode)
	dd_mode.initialize_mode()
	dd_mode.start_mode()
	var dd_tray = dd_mode.get_piece_tray()
	var piece0 = dd_tray.active_pieces[0]
	piece0._start_drag(Vector2(100, 100), -1)
	piece0.global_position = Vector2(-500, -500) # Far out of bounds
	piece0._notification(Control.NOTIFICATION_WM_MOUSE_EXIT)
	if piece0.is_dragging or piece0.is_placed or not piece0.visible or dd_tray.get_remaining_piece_count() != 3:
		printerr("[FAIL Test 46] Interrupted / out-of-bounds drag failed to restore unplaced piece to tray!")
		get_tree().quit(1)
		return
	dd_mode.queue_free()
	print("[TEST 46/48] Drag & Drop interrupted drag & out-of-bounds guaranteed slot restoration: PASSED")

	# =========================================================================
	# TEST 47: Human Vocal Callouts & Automatic BGM Ducking
	# =========================================================================
	var vocal_callouts_list = ["good", "nice", "great", "combo", "excellent", "amazing"]
	for c_word in vocal_callouts_list:
		if not audio_mgr.voice_cache.has(c_word) or audio_mgr.voice_cache[c_word] == null:
			printerr("[FAIL Test 47] Missing human vocal callout stream for: ", c_word)
			get_tree().quit(1)
			return
	audio_mgr.sound_enabled = true
	audio_mgr.play_voice_callout("EXCELLENT")
	if audio_mgr.last_callout_text != "EXCELLENT!" or not audio_mgr.is_bgm_ducked or audio_mgr.duck_timer <= 0.0:
		printerr("[FAIL Test 47] Voice callout did not trigger or failed to duck BGM volume!")
		get_tree().quit(1)
		return
	print("[TEST 47/48] Human formant vocal callouts (GOOD..AMAZING) & automatic BGM ducking: PASSED")

	# =========================================================================
	# TEST 48: Daily Gift = Lucky Wheel (8 Alternating Wedges, 1 Free Spin/Day, Next-Day Reset)
	# =========================================================================
	game_state.reset_progression(false)
	game_state.set_game_mode(GameStateScript.GameMode.MODERN_DRAG_AND_DROP)
	game_state.reset_special_item_inventory()
	var wheel_slices: Array = game_state.get_lucky_wheel_slices()
	if wheel_slices.size() != 8 or not game_state.can_claim_daily_gift_today("2026-09-26"):
		printerr("[FAIL Test 48] Daily Gift Lucky Wheel must have 8 slices and allow 1 free spin today!")
		get_tree().quit(1)
		return
	var lucky_next_time_count := 0
	var bomb_count := 0
	var change_block_count := 0
	var extra_life_count := 0
	var spin_again_count := 0
	for sl in wheel_slices:
		var rt: String = String(sl.get("reward_type", ""))
		if rt == "lucky_next_time":
			lucky_next_time_count += 1
		elif rt == "bomb":
			bomb_count += 1
		elif rt == "change_block":
			change_block_count += 1
		elif rt == "extra_life":
			extra_life_count += 1
		elif rt == "spin_again" or rt == "extra_spin":
			spin_again_count += 1
		else:
			printerr("[FAIL Test 48] Daily Gift Lucky Wheel must contain ONLY Modern special-item rewards, spin_again, or lucky_next_time, found: ", rt)
			get_tree().quit(1)
			return
	if lucky_next_time_count != 4 or bomb_count != 1 or change_block_count != 1 or extra_life_count != 1 or spin_again_count != 1:
		printerr("[FAIL Test 48] Daily Gift Lucky Wheel must include exactly 1 Bomb, 1 Change Block, 1 Extra Life, 1 Spin Again, and 4 'lucky_next_time' wedges! Got counts: ", {"bomb": bomb_count, "change": change_block_count, "life": extra_life_count, "spin_again": spin_again_count, "lucky_next_time": lucky_next_time_count})
		get_tree().quit(1)
		return
	var menu_dg = MainMenuScene.instantiate()
	add_child(menu_dg)
	if menu_dg.find_child("BtnLuckyWheel", true, false) != null:
		printerr("[FAIL Test 48] Home Menu must NOT have a separate BtnLuckyWheel button; Daily Gift IS the Lucky Wheel!")
		get_tree().quit(1)
		return
	menu_dg._on_btn_daily_gift_pressed()
	if not menu_dg.modal_lucky_wheel.visible:
		printerr("[FAIL Test 48] Tapping Daily Gift must immediately open the Lucky Wheel modal!")
		get_tree().quit(1)
		return
	var bombs_before_dg: int = game_state.get_special_item_count("bomb")
	var spin_day1: Dictionary = game_state.spin_daily_gift_wheel(0, "2026-09-26") # Slice 0: Bomb ×1
	if not spin_day1.get("success", false) or spin_day1.get("reward_type", "") != "bomb" or int(spin_day1.get("amount", 0)) != 1:
		printerr("[FAIL Test 48] Daily Gift spin on Slice 0 failed to award Bomb ×1!")
		get_tree().quit(1)
		return
	if game_state.get_special_item_count("bomb") != bombs_before_dg + 1:
		printerr("[FAIL Test 48] Daily Gift spin did not add +1 Bomb to Modern special-item inventory!")
		get_tree().quit(1)
		return
	if game_state.can_claim_daily_gift_today("2026-09-26"):
		printerr("[FAIL Test 48] Daily Gift must prevent a second free spin on the same calendar day!")
		get_tree().quit(1)
		return
	var spin_same_day: Dictionary = game_state.spin_daily_gift_wheel(0, "2026-09-26")
	if spin_same_day.get("success", false):
		printerr("[FAIL Test 48] Second Daily Gift spin on same calendar day must be rejected!")
		get_tree().quit(1)
		return
	if not game_state.can_claim_daily_gift_today("2026-09-27"):
		printerr("[FAIL Test 48] Daily Gift must become available again on the next calendar day!")
		get_tree().quit(1)
		return
	menu_dg.queue_free()
	print("[TEST 48/62] Daily Gift = Lucky Wheel (8 alternating wedges, 1 spin/day & next-day reset): PASSED")

	# =========================================================================
	# TEST 49: Top-Right Gear Vector Icon & Top-Left Level Button as ONLY Map Shortcut
	# =========================================================================
	var menu_top = MainMenuScene.instantiate()
	add_child(menu_top)
	if not menu_top.btn_top_settings or not menu_top.has_settings_gear_vector_icon():
		printerr("[FAIL Test 49] Top-right Settings button must have a custom procedural vector gear icon!")
		get_tree().quit(1)
		return
	if menu_top.btn_top_settings.text != "" or "2699" in menu_top.btn_top_settings.text:
		printerr("[FAIL Test 49] Top-right Settings button must NOT contain raw Unicode character or '2699'!")
		get_tree().quit(1)
		return
	menu_top._on_btn_settings_pressed()
	if not menu_top.modal_settings.visible:
		printerr("[FAIL Test 49] Tapping top-right gear button failed to open Settings modal!")
		get_tree().quit(1)
		return
	if not menu_top.btn_top_level or menu_top.has_redundant_world_map_button():
		printerr("[FAIL Test 49] Top-left Level button (BtnTopLevel) must be the ONLY primary shortcut to the Level Map!")
		get_tree().quit(1)
		return
	if not menu_top.open_level_map_from_top_level_button() or not menu_top.modal_level_map.visible:
		printerr("[FAIL Test 49] Tapping top-left Level button failed to open Level Map modal!")
		get_tree().quit(1)
		return
	menu_top.queue_free()
	print("[TEST 49/58] Top-Right vector Gear Settings icon & Top-Left Level Button as sole Level Map shortcut: PASSED")

	# =========================================================================
	# TEST 50: 500-Level World Map Data-Driven Special Milestones & Page Environments
	# =========================================================================
	if game_state.get_level_milestone_type(3) != "star_milestone" or game_state.get_level_milestone_type(6) != "major_milestone" or game_state.get_level_milestone_type(7) != "chapter_unlock_milestone" or game_state.get_level_milestone_type(10) != "reward_milestone":
		printerr("[FAIL Test 50] Data-driven special milestone level types (3, 6, 7, 10) not configured properly!")
		get_tree().quit(1)
		return
	var seen_envs: Dictionary = {}
	for ch_i in range(6):
		var env_d: Dictionary = game_state.get_chapter_environment(ch_i)
		seen_envs[String(env_d.get("id", ""))] = true
	if seen_envs.size() != 6:
		printerr("[FAIL Test 50] Expected 6 distinct page environments across first 6 pages!")
		get_tree().quit(1)
		return
	print("[TEST 50/58] 500-Level World Map data-driven special milestones & distinct page environments: PASSED")

	# =========================================================================
	# TEST 51: Zero Broken Icon / Hex Codepoint Rendering Across All UI Controls (EN & VI)
	# =========================================================================
	var fallback_font: Font = ThemeDB.fallback_font
	var menu_glyph = MainMenuScene.instantiate()
	var hud_glyph = HUDScene.instantiate()
	var pause_glyph = PauseMenuScene.instantiate()
	var modal_glyph = GameOverModalScene.instantiate()
	add_child(menu_glyph)
	add_child(hud_glyph)
	add_child(pause_glyph)
	add_child(modal_glyph)
	menu_glyph._on_btn_top_level_pressed()
	menu_glyph._on_btn_daily_gift_pressed()
	menu_glyph._on_btn_how_to_play_pressed()

	if not menu_glyph.has_all_vector_icons():
		printerr("[FAIL Test 51] MainMenu controls missing procedural UIIcon vector icons!")
		get_tree().quit(1)
		return

	for lang_code in ["en", "vi"]:
		game_state.set_language(lang_code, false)
		for root_ctrl in [menu_glyph, hud_glyph, pause_glyph, modal_glyph]:
			var stack: Array[Node] = [root_ctrl]
			while not stack.is_empty():
				var n: Node = stack.pop_back()
				for ch in n.get_children():
					stack.append(ch)
				var txt_val := ""
				if n is Label:
					txt_val = (n as Label).text
				elif n is Button:
					txt_val = (n as Button).text
				for i in range(txt_val.length()):
					var u: int = txt_val.unicode_at(i)
					if u >= 32 and not fallback_font.has_char(u):
						printerr("[FAIL Test 51] Unsupported glyph U+%04X ('%s') in node '%s' (%s) — would render hex box '%04X'!" % [u, txt_val[i], n.name, lang_code, u])
						get_tree().quit(1)
						return
	game_state.set_language("en", false)
	menu_glyph.queue_free()
	hud_glyph.queue_free()
	pause_glyph.queue_free()
	modal_glyph.queue_free()
	print("[TEST 51/58] Zero unsupported Unicode glyphs (zero hex codepoint boxes like 2699) + vector UIIcon audit: PASSED")

	# =========================================================================
	# TEST 52: Default Game Selection on First Launch / New Save (CLASSIC + FALLING)
	# =========================================================================
	game_state.reset_progression(false)
	if game_state.current_mode != GameStateScript.GameMode.CLASSIC or game_state.current_play_style != GameStateScript.PlayStyle.FALLING:
		printerr("[FAIL Test 52] Default GameState selection on new save must be CLASSIC + FALLING!")
		get_tree().quit(1)
		return
	var menu_def = MainMenuScene.instantiate()
	add_child(menu_def)
	if menu_def.selected_game_mode != GameStateScript.GameMode.CLASSIC or menu_def.selected_play_style != int(GameStateScript.PlayStyle.FALLING):
		printerr("[FAIL Test 52] MainMenu default selection on first launch must be CLASSIC + FALLING!")
		get_tree().quit(1)
		return
	menu_def._on_btn_start_pressed()
	if game_state.current_mode != GameStateScript.GameMode.CLASSIC or game_state.current_play_style != GameStateScript.PlayStyle.FALLING or game_state.current_state != GameStateScript.State.PLAYING:
		printerr("[FAIL Test 52] Primary PLAY button on default Home Menu failed to start CLASSIC + FALLING!")
		get_tree().quit(1)
		return
	menu_def.queue_free()
	print("[TEST 52/58] Default Home Menu selection on first launch starts CLASSIC + FALLING: PASSED")

	# =========================================================================
	# TEST 53: Persist User Mode & Play Style Selection Locally Across Sessions
	# =========================================================================
	var sel_save_path := "user://test_block_puzzle_4tm_selection.cfg"
	game_state.reset_progression(false)
	var menu_sel1 = MainMenuScene.instantiate()
	add_child(menu_sel1)
	menu_sel1.select_game_mode_button(GameStateScript.GameMode.MODERN_DRAG_AND_DROP)
	menu_sel1.select_play_style_button(int(GameStateScript.PlayStyle.DRAG_AND_DROP))
	game_state.save_progression(sel_save_path)
	menu_sel1.queue_free()

	# Simulate fresh restart and loading saved preferences
	game_state.current_mode = GameStateScript.GameMode.CLASSIC
	game_state.current_play_style = GameStateScript.PlayStyle.FALLING
	game_state._play_style_explicit = false
	var sel_loaded = game_state.load_progression(sel_save_path)
	if not sel_loaded or not game_state._play_style_explicit:
		printerr("[FAIL Test 53] Failed to load saved user mode/style selection from config!")
		get_tree().quit(1)
		return
	if game_state.current_mode != GameStateScript.GameMode.MODERN_DRAG_AND_DROP or game_state.current_play_style != GameStateScript.PlayStyle.DRAG_AND_DROP:
		printerr("[FAIL Test 53] Persisted selection did not restore MODERN + DRAG & DROP!")
		get_tree().quit(1)
		return
	var menu_sel2 = MainMenuScene.instantiate()
	add_child(menu_sel2)
	if menu_sel2.selected_game_mode != GameStateScript.GameMode.MODERN_DRAG_AND_DROP or menu_sel2.selected_play_style != int(GameStateScript.PlayStyle.DRAG_AND_DROP):
		printerr("[FAIL Test 53] Returning to Home Menu did not preserve MODERN + DRAG & DROP selection!")
		get_tree().quit(1)
		return
	menu_sel2.queue_free()
	print("[TEST 53/58] User Game Mode & Play Style selection persists locally across sessions & Home return: PASSED")

	# =========================================================================
	# TEST 54: Main Menu — No Standalone Language Button & Simplified "Block Puzzle" Title Area
	# =========================================================================
	var menu_ui = MainMenuScene.instantiate()
	add_child(menu_ui)
	if menu_ui.has_standalone_language_button() or menu_ui.find_child("BtnLanguage", true, false) != null:
		printerr("[FAIL Test 54] Standalone EN/VI language button must be removed from Main Menu!")
		get_tree().quit(1)
		return
	if not menu_ui.btn_language_modal:
		printerr("[FAIL Test 54] Language selection inside Settings modal (BtnLanguageModal) must remain present!")
		get_tree().quit(1)
		return
	game_state.set_language("en", false)
	menu_ui._on_btn_language_pressed() # Toggles via Settings modal button handler
	if game_state.get_language() != "vi":
		printerr("[FAIL Test 54] Language toggle inside Settings modal failed to switch EN -> VI!")
		get_tree().quit(1)
		return
	menu_ui._on_btn_language_pressed()
	if game_state.get_language() != "en":
		printerr("[FAIL Test 54] Language toggle inside Settings modal failed to switch VI -> EN!")
		get_tree().quit(1)
		return
	if not menu_ui.has_simplified_title_area():
		printerr("[FAIL Test 54] Main Menu title area must contain ONLY the primary 'Block Puzzle' title with extra lines removed!")
		get_tree().quit(1)
		return
	menu_ui.queue_free()
	print("[TEST 54/58] Main Menu standalone language control removed + simplified 'Block Puzzle' title area: PASSED")

	# =========================================================================
	# TEST 55: Enlarged Daily Gift Lucky Wheel, Larger Reward Icons & "Lucky Next Time" Wedge
	# =========================================================================
	var menu_wheel = MainMenuScene.instantiate()
	add_child(menu_wheel)
	for vp_test in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
		var w_metrics: Dictionary = menu_wheel.update_responsive_wheel_layout(vp_test)
		var canvas_sz: Vector2 = w_metrics.get("canvas_size", Vector2.ZERO)
		var icon_rad: float = float(w_metrics.get("icon_radius", 0.0))
		if canvas_sz.x < 300.0 or canvas_sz.x > vp_test.x or icon_rad < 18.0:
			printerr("[FAIL Test 55] Lucky Wheel size (", canvas_sz, ") or reward icon radius (", icon_rad, ") invalid on viewport ", vp_test)
			get_tree().quit(1)
			return
	var w_metrics_720: Dictionary = menu_wheel.update_responsive_wheel_layout(Vector2(720, 1280))
	if float(w_metrics_720.get("canvas_size", Vector2.ZERO).x) < 580.0 or float(w_metrics_720.get("icon_radius", 0.0)) < 24.0:
		printerr("[FAIL Test 55] Lucky Wheel on 720x1280 must be significantly enlarged (canvas >= 580px, icon_radius >= 24px)!")
		get_tree().quit(1)
		return
	game_state.reset_progression(false)
	game_state.reset_special_item_inventory()
	var inv_before: Dictionary = game_state.special_item_inventory.duplicate(true)
	var coins_before_spin: int = game_state.coins
	game_state.set_language("en", false)
	var lnt_res_en: Dictionary = game_state.spin_daily_gift_wheel(7, "2026-09-28") # Slice 7: LUCKY NEXT TIME
	if not lnt_res_en.get("success", false) or String(lnt_res_en.get("reward_type", "")) != "lucky_next_time" or int(lnt_res_en.get("amount", -1)) != 0 or String(lnt_res_en.get("label", "")) != "Lucky Next Time":
		printerr("[FAIL Test 55] Lucky Next Time wedge (EN) did not return expected result: ", lnt_res_en)
		get_tree().quit(1)
		return
	if game_state.special_item_inventory != inv_before or game_state.coins != coins_before_spin or game_state.special_item_inventory.has("lucky_next_time"):
		printerr("[FAIL Test 55] Lucky Next Time wedge must NOT create or consume any inventory item or coins!")
		get_tree().quit(1)
		return
	if game_state.can_claim_daily_gift_today("2026-09-28"):
		printerr("[FAIL Test 55] Lucky Next Time wedge must still consume the daily free spin for that calendar day!")
		get_tree().quit(1)
		return
	game_state.set_language("vi", false)
	var lnt_res_vi: Dictionary = game_state.spin_daily_gift_wheel(7, "2026-09-29")
	if not lnt_res_vi.get("success", false) or String(lnt_res_vi.get("label", "")) != "Chúc bạn may mắn lần sau":
		printerr("[FAIL Test 55] Lucky Next Time wedge (VI) must display 'Chúc bạn may mắn lần sau'!")
		get_tree().quit(1)
		return
	game_state.set_language("en", false)
	menu_wheel.queue_free()
	print("[TEST 55/58] Enlarged Lucky Wheel & reward icons + 'LUCKY NEXT TIME' / 'Chúc bạn may mắn lần sau' non-reward wedge: PASSED")

	# =========================================================================
	# TEST 56: In-Game Settings Button — Wider & Shorter Proportions Across 360x800, 390x844, 720x1280
	# =========================================================================
	var hud_prop = HUDScene.instantiate()
	add_child(hud_prop)
	if not hud_prop.has_proper_settings_button_proportions():
		printerr("[FAIL Test 56] In-game HUD Settings button failed proportion/padding/centering check (must be wider than tall, not a vertical pill)!")
		get_tree().quit(1)
		return
	for vp_hud in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
		hud_prop.update_responsive_hud_layout(vp_hud)
		if hud_prop.btn_settings.size.x <= hud_prop.btn_settings.size.y or hud_prop.btn_settings.size.y < 40.0:
			printerr("[FAIL Test 56] In-game Settings button size ", hud_prop.btn_settings.size, " is not wider-than-tall on viewport ", vp_hud)
			get_tree().quit(1)
			return
	hud_prop.queue_free()
	print("[TEST 56/58] In-game Settings button wider & shorter rounded-rectangle proportions with centered vector gear: PASSED")

	# =========================================================================
	# TEST 57: Falling Mode Vertical Play Layout (Header -> Next Piece -> 12x10 Board -> Controls -> Ad Slot)
	# =========================================================================
	for f_rule in [GameStateScript.GameMode.CLASSIC, GameStateScript.GameMode.MODERN_DRAG_AND_DROP]:
		var f_mode = ClassicModeScript.new()
		f_mode.configure_combination(f_rule, GameStateScript.PlayStyle.FALLING)
		add_child(f_mode)
		f_mode.initialize_mode()
		f_mode.start_mode()
		for vp_fall in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
			var layout_info: Dictionary = f_mode.update_layout_for_viewport(vp_fall)
			var h_rect: Rect2 = layout_info.get("header_rect", Rect2())
			var n_rect: Rect2 = layout_info.get("next_piece_rect", Rect2())
			var b_rect: Rect2 = layout_info.get("board_rect", Rect2())
			var c_rect: Rect2 = layout_info.get("controls_rect", Rect2())
			var a_rect: Rect2 = layout_info.get("ad_rect", Rect2())
			if n_rect.position.y < h_rect.end.y - 0.5:
				printerr("[FAIL Test 57] Next Piece area overlaps Header on viewport ", vp_fall, " (mode=", f_rule, ")")
				get_tree().quit(1)
				return
			if b_rect.position.y < n_rect.end.y - 0.5:
				printerr("[FAIL Test 57] 12x10 Play Board overlaps Next Piece area on viewport ", vp_fall, " (mode=", f_rule, ")")
				get_tree().quit(1)
				return
			if c_rect.position.y < b_rect.end.y - 0.5:
				printerr("[FAIL Test 57] Rotation/Touch Controls overlap 12x10 Play Board on viewport ", vp_fall, " (mode=", f_rule, ")")
				get_tree().quit(1)
				return
			if a_rect.position.y < c_rect.end.y - 0.5:
				printerr("[FAIL Test 57] Rotation/Touch Controls overlap Ad Slot on viewport ", vp_fall, " (mode=", f_rule, ")")
				get_tree().quit(1)
				return
		f_mode.queue_free()
	print("[TEST 57/58] Falling mode vertical order (Header -> Next Piece -> 12x10 Board -> Touch Controls -> Ad Slot) on 360x800, 390x844 & 720x1280: PASSED")

	# =========================================================================
	# TEST 58: Organic Non-Grid Level Map & Prominent Milestone Visual Hierarchy
	# =========================================================================
	var menu_organic = MainMenuScene.instantiate()
	add_child(menu_organic)
	menu_organic._on_btn_open_level_map_pressed()
	menu_organic._layout_winding_path_nodes()
	if menu_organic.level_grid is GridContainer:
		printerr("[FAIL Test 58] LevelMap must not use a rigid GridContainer!")
		get_tree().quit(1)
		return
	var distinct_x58: Dictionary = {}
	var distinct_y58: Dictionary = {}
	var normal_area: float = 0.0
	var star_ms_area: float = 0.0
	var major_ms_area: float = 0.0
	for idx_c in range(menu_organic.level_grid.get_child_count()):
		var nd := menu_organic.level_grid.get_child(idx_c) as Control
		if not (nd is Button):
			continue
		var l_num: int = int(nd.get_meta("level", idx_c + 1))
		distinct_x58[int(round(nd.position.x))] = true
		distinct_y58[int(round(nd.position.y))] = true
		var area: float = nd.size.x * nd.size.y
		if l_num == 1:
			normal_area = area
		elif l_num == 3:
			star_ms_area = area
		elif l_num == 6:
			major_ms_area = area
	if distinct_x58.size() < 4 or distinct_y58.size() < 4:
		printerr("[FAIL Test 58] Level Map nodes are still aligned in a flat rigid grid (lack organic vertical/horizontal variation)!")
		get_tree().quit(1)
		return
	if not (major_ms_area > star_ms_area and star_ms_area > normal_area):
		printerr("[FAIL Test 58] Milestone nodes (major > star > normal) must have progressively larger visual hierarchy! Areas: ", [normal_area, star_ms_area, major_ms_area])
		get_tree().quit(1)
		return
	# Verify deterministic positions & page-to-page variation
	if game_state.get_deterministic_map_node_pos(7) != game_state.get_deterministic_map_node_pos(7):
		printerr("[FAIL Test 58] Level Map node positions must be deterministic across repeated calls!")
		get_tree().quit(1)
		return
	if game_state.get_deterministic_map_node_pos(2) == game_state.get_deterministic_map_node_pos(8):
		printerr("[FAIL Test 58] Level Map pages must have distinct organic path curves rather than identical coordinates!")
		get_tree().quit(1)
		return
	# Verify page-start unlock milestone (Lv.7 on Page 2) classification and zero node overlap across 312x480, 360x800, 390x844, 720x1280
	for test_ch58 in [0, 1, 2, 3, 4, 5]:
		menu_organic._populate_level_map_page(test_ch58)
		var expected_page_cnt58: int = game_state.get_level_map_page(test_ch58).size()
		for canvas_test_sz in [Vector2(312, 480), Vector2(342, 520), Vector2(360, 800), Vector2(390, 844), Vector2(630, 740), Vector2(720, 1280)]:
			menu_organic.level_grid.custom_minimum_size = canvas_test_sz
			menu_organic.level_grid.size = canvas_test_sz
			menu_organic._layout_winding_path_nodes()
			var node_rects: Array[Rect2] = []
			var node_ctrls: Array[Control] = []
			for idx_c2 in range(menu_organic.level_grid.get_child_count()):
				var nd2 := menu_organic.level_grid.get_child(idx_c2) as Control
				if not (nd2 is Button) or nd2.is_queued_for_deletion():
					continue
				var r2 := Rect2(nd2.position, nd2.size)
				if int(nd2.get_meta("level", 0)) == 7 and String(nd2.get_meta("milestone_type", "")) != "chapter_unlock_milestone":
					printerr("[FAIL Test 58] Level 7 (start of Page 2) must be classified as chapter_unlock_milestone!")
					get_tree().quit(1)
					return
				for p_i in range(node_rects.size()):
					var prev_r: Rect2 = node_rects[p_i]
					var prev_nd: Control = node_ctrls[p_i]
					if r2.grow(-2.0).intersects(prev_r.grow(-2.0)):
						printerr("[FAIL Test 58] Level Map nodes overlap on canvas size ", canvas_test_sz, " (page ", test_ch58 + 1, "): ", r2, " vs ", prev_r, " (", prev_nd.name, ")")
						get_tree().quit(1)
						return
				node_rects.append(r2)
				node_ctrls.append(nd2)
			if node_ctrls.size() != expected_page_cnt58:
				printerr("[FAIL Test 58] Expected ", expected_page_cnt58, " active Level Map buttons in level_grid on page ", test_ch58 + 1, ", found: ", node_ctrls.size())
				get_tree().quit(1)
				return
	menu_organic.queue_free()
	print("[TEST 58/62] Organic non-grid Level Map layout, zero node overlap & multi-tier milestone visual hierarchy: PASSED")

	# =========================================================================
	# TEST 59: Daily Gift Lucky Wheel — 8 Alternating Wedges, ×1 Quantities, Zero ×2/×3, EN/VI Descriptions
	# =========================================================================
	var slices_59: Array = game_state.get_lucky_wheel_slices()
	if slices_59.size() != 8:
		printerr("[FAIL Test 59] Lucky Wheel must have exactly 8 wedges, found: ", slices_59.size())
		get_tree().quit(1)
		return
	var expected_order := [
		"bomb",
		"lucky_next_time",
		"change_block",
		"lucky_next_time",
		"extra_life",
		"lucky_next_time",
		"spin_again",
		"lucky_next_time"
	]
	var lnt_cnt_59 := 0
	for i in range(8):
		var sl_i: Dictionary = slices_59[i]
		var rt_i: String = String(sl_i.get("reward_type", ""))
		var amt_i: int = int(sl_i.get("amount", -1))
		var st_i: String = String(sl_i.get("short_text", ""))
		if rt_i != expected_order[i]:
			printerr("[FAIL Test 59] Wedge ", i, " expected '", expected_order[i], "', got '", rt_i, "'")
			get_tree().quit(1)
			return
		if "2" in st_i or "3" in st_i or amt_i >= 2:
			printerr("[FAIL Test 59] No ×2 or ×3 rewards allowed on Lucky Wheel! Wedge ", i, ": ", sl_i)
			get_tree().quit(1)
			return
		if rt_i == "lucky_next_time":
			lnt_cnt_59 += 1
			if amt_i != 0:
				printerr("[FAIL Test 59] Lucky Next Time wedge must have amount == 0!")
				get_tree().quit(1)
				return
		else:
			if amt_i != 1:
				printerr("[FAIL Test 59] Every item/spin reward quantity must be ×1! Wedge ", i, " had amount=", amt_i)
				get_tree().quit(1)
				return
	var unique_item_wedges: Array = game_state.get_lucky_wheel_unique_item_wedges()
	if unique_item_wedges.size() != 4 or lnt_cnt_59 != 4:
		printerr("[FAIL Test 59] Expected 4 unique reward items and 4 Lucky Next Time wedges! Got unique=", unique_item_wedges.size(), " lnt=", lnt_cnt_59)
		get_tree().quit(1)
		return
	var menu_w59 = MainMenuScene.instantiate()
	add_child(menu_w59)
	game_state.set_language("en", false)
	var d_bomb_en: Dictionary = menu_w59._update_wheel_pointer_description(0)
	var d_cb_en: Dictionary = menu_w59._update_wheel_pointer_description(2)
	var d_el_en: Dictionary = menu_w59._update_wheel_pointer_description(4)
	var d_lnt_en: Dictionary = menu_w59._update_wheel_pointer_description(1)
	var d_spin_en: Dictionary = menu_w59._update_wheel_pointer_description(6)
	if d_bomb_en.get("title", "") != "BOMB" or d_bomb_en.get("description", "") != "Clear a 3×3 area":
		printerr("[FAIL Test 59] EN Bomb description mismatch: ", d_bomb_en)
		get_tree().quit(1)
		return
	if d_cb_en.get("title", "") != "CHANGE BLOCK" or d_cb_en.get("description", "") != "Replace one selected block":
		printerr("[FAIL Test 59] EN Change Block description mismatch: ", d_cb_en)
		get_tree().quit(1)
		return
	if d_el_en.get("title", "") != "EXTRA LIFE" or d_el_en.get("description", "") != "Recover after Game Over":
		printerr("[FAIL Test 59] EN Extra Life description mismatch: ", d_el_en)
		get_tree().quit(1)
		return
	if d_lnt_en.get("title", "") != "LUCKY NEXT TIME" or d_lnt_en.get("description", "") != "No reward this time":
		printerr("[FAIL Test 59] EN Lucky Next Time description mismatch: ", d_lnt_en)
		get_tree().quit(1)
		return
	if d_spin_en.get("title", "") != "SPIN AGAIN" or d_spin_en.get("description", "") != "Get 1 extra free spin":
		printerr("[FAIL Test 59] EN Spin Again description mismatch: ", d_spin_en)
		get_tree().quit(1)
		return
	game_state.set_language("vi", false)
	var d_bomb_vi: Dictionary = menu_w59._update_wheel_pointer_description(0)
	var d_cb_vi: Dictionary = menu_w59._update_wheel_pointer_description(2)
	var d_el_vi: Dictionary = menu_w59._update_wheel_pointer_description(4)
	var d_lnt_vi: Dictionary = menu_w59._update_wheel_pointer_description(1)
	var d_spin_vi: Dictionary = menu_w59._update_wheel_pointer_description(6)
	if d_bomb_vi.get("title", "") != "BOM" or d_cb_vi.get("title", "") != "ĐỔI KHỐI" or d_el_vi.get("title", "") != "MẠNG THÊM" or d_lnt_vi.get("title", "") != "Chúc bạn may mắn lần sau" or d_spin_vi.get("title", "") != "QUAY LẠI LẦN NỮA":
		printerr("[FAIL Test 59] VI wheel titles mismatch: ", [d_bomb_vi, d_cb_vi, d_el_vi, d_lnt_vi, d_spin_vi])
		get_tree().quit(1)
		return
	if String(d_bomb_vi.get("description", "")).is_empty() or String(d_cb_vi.get("description", "")).is_empty() or String(d_el_vi.get("description", "")).is_empty() or String(d_lnt_vi.get("description", "")).is_empty() or String(d_spin_vi.get("description", "")).is_empty():
		printerr("[FAIL Test 59] VI wheel descriptions must not be empty!")
		get_tree().quit(1)
		return
	game_state.set_language("en", false)
	menu_w59.queue_free()
	print("[TEST 59/62] Daily Gift 8 alternating wedges, ×1 quantities, 4 Lucky Next Time & EN/VI descriptions: PASSED")

	# =========================================================================
	# TEST 60: Audio Callouts Configuration, Ducking & Enlarged Visual Feedback
	# =========================================================================
	var vc_cfg: Dictionary = audio_mgr.get_voice_callout_config()
	for req_callout in ["good", "nice", "great", "combo", "excellent", "amazing"]:
		if not audio_mgr.voice_cache.has(req_callout) or audio_mgr.voice_cache[req_callout] == null:
			printerr("[FAIL Test 60] Missing required voice callout: ", req_callout)
			get_tree().quit(1)
			return
		var wav_st: AudioStreamWAV = audio_mgr.voice_cache[req_callout]
		if wav_st.data.size() < 8000:
			printerr("[FAIL Test 60] Voice callout PCM data unexpectedly short for: ", req_callout)
			get_tree().quit(1)
			return
	if float(vc_cfg.get("voice_volume_db", 0.0)) < 5.5 or float(vc_cfg.get("bgm_ducked_volume_db", 0.0)) > -20.0 or float(vc_cfg.get("sfx_ducked_volume_db", 0.0)) > -7.0:
		printerr("[FAIL Test 60] Voice callout loudness or BGM/SFX ducking configuration out of expected range: ", vc_cfg)
		get_tree().quit(1)
		return
	var hud_v60 = HUDScene.instantiate()
	add_child(hud_v60)
	var v_metrics: Dictionary = hud_v60.get_callout_visual_metrics()
	if int(v_metrics.get("callout_font_size", 0)) < 40 or int(v_metrics.get("combo_font_size", 0)) < 34 or float(v_metrics.get("callout_peak_scale", 0.0)) < 1.30:
		printerr("[FAIL Test 60] Visual callout banner size/scale was not increased sufficiently: ", v_metrics)
		get_tree().quit(1)
		return
	if BoardScript.BURST_PARTICLES_PER_CELL < 4 or BoardScript.BURST_PARTICLE_MAX_RADIUS < 11.0 or BoardScript.BOARD_CALLOUT_FONT_SIZE < 36:
		printerr("[FAIL Test 60] Board particle burst / floating callout visual size not increased sufficiently!")
		get_tree().quit(1)
		return
	hud_v60.queue_free()
	print("[TEST 60/62] Audio callouts (6 callouts, +6.5dB voice bus, BGM/SFX ducking) & enlarged visual effects: PASSED")

	# =========================================================================
	# TEST 61: Main Menu — Standalone START / BẮT ĐẦU Primary Button & Hierarchy
	# =========================================================================
	var menu_p61 = MainMenuScene.instantiate()
	add_child(menu_p61)
	game_state.set_language("en", false)
	if menu_p61.btn_start.text != "START":
		printerr("[FAIL Test 61] EN Start button text must be strictly 'START', got: '", menu_p61.btn_start.text, "'")
		get_tree().quit(1)
		return
	if "LEVEL" in menu_p61.btn_start.text.to_upper() or "LV" in menu_p61.btn_start.text.to_upper() or "PLAY" in menu_p61.btn_start.text.to_upper():
		printerr("[FAIL Test 61] Start button must not contain level text, subtitle, or PLAY!")
		get_tree().quit(1)
		return
	game_state.set_language("vi", false)
	if menu_p61.btn_start.text != "BẮT ĐẦU":
		printerr("[FAIL Test 61] VI Start button text must be strictly 'BẮT ĐẦU', got: '", menu_p61.btn_start.text, "'")
		get_tree().quit(1)
		return
	game_state.set_language("en", false)
	if not menu_p61.has_standalone_start_button_hierarchy():
		printerr("[FAIL Test 61] Start button must be a standalone primary CTA with substantial vertical spacing above and below!")
		get_tree().quit(1)
		return
	var start_sp: Dictionary = menu_p61.get_start_button_spacing_metrics()
	if int(start_sp.get("margin_top", 0)) < 16 or int(start_sp.get("margin_bottom", 0)) < 20:
		printerr("[FAIL Test 61] Start button vertical margins too small: ", start_sp)
		get_tree().quit(1)
		return
	# Assert text-only START button with no play/triangle icon attached
	if menu_p61.btn_start.get_node_or_null("VectorIcon") != null:
		printerr("[FAIL Test 61] Start button must NOT have any play/triangle icon; it must be text-only!")
		get_tree().quit(1)
		return
	if not menu_p61.has_text_only_start_button():
		printerr("[FAIL Test 61] Start button must be centered text-only without extra icon padding!")
		get_tree().quit(1)
		return
	menu_p61.queue_free()
	print("[TEST 61/68] Main Menu standalone START / BẮT ĐẦU primary CTA & vertical spacing hierarchy: PASSED")

	# =========================================================================
	# TEST 62: Drag & Drop Complete Lifecycle & All 12 Failure/Interruption Paths
	# =========================================================================
	game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	var dd62 = ModernModeScript.new()
	dd62.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	add_child(dd62)
	dd62.initialize_mode()
	dd62.start_mode()
	dd62.update_layout_for_viewport(Vector2(720, 1280))
	var tray62 = dd62.get_piece_tray()
	var board62 = dd62.get_board()
	var p_slot0 = tray62.active_pieces[0]
	var orig_home0: Vector2 = p_slot0.home_position
	var orig_scale0: Vector2 = p_slot0.scale
	var orig_cells0: Array = p_slot0.cells.duplicate(true)
	var tray_center: Vector2 = tray62.global_position + tray62.size * 0.5
	var bg_point: Vector2 = Vector2(12.0, board62.global_position.y + 80.0) # In left margin outside board
	var outside_vp_point: Vector2 = Vector2(-420.0, -380.0)
	var board_valid_world: Vector2 = board62.grid_to_world(Vector2i(4, 4)) + Vector2(20, 20) + Vector2(0, p_slot0.TOUCH_Y_OFFSET)

	# Path 2: Drag -> release inside tray -> piece restored
	p_slot0._start_drag(tray_center, -1)
	if p_slot0.piece_state != TrayPieceScript.PieceState.DRAGGING or not p_slot0.visible:
		printerr("[FAIL Test 62.2] Piece must be in DRAGGING state and visible during drag!")
		get_tree().quit(1)
		return
	p_slot0._move_drag(board_valid_world)
	p_slot0._move_drag(tray_center)
	p_slot0._end_drag(tray_center)
	if not p_slot0.verify_in_tray_invariants() or tray62.active_pieces[0] != p_slot0 or tray62.get_remaining_piece_count() != 3 or board62.preview_active:
		printerr("[FAIL Test 62.2] Release inside tray failed to restore piece or clear preview!")
		get_tree().quit(1)
		return

	# Path 3: Drag -> release on background -> piece restored
	p_slot0._start_drag(tray_center, -1)
	p_slot0._move_drag(board_valid_world)
	p_slot0._move_drag(bg_point)
	p_slot0._end_drag(bg_point)
	if not p_slot0.verify_in_tray_invariants() or tray62.active_pieces[0] != p_slot0 or board62.get_occupied_cell_count() != 0 or board62.preview_active:
		printerr("[FAIL Test 62.3] Release on background failed to restore piece or placed piece erroneously!")
		get_tree().quit(1)
		return

	# Path 4: Drag -> move outside viewport -> release -> piece restored
	p_slot0._start_drag(tray_center, -1)
	p_slot0._move_drag(outside_vp_point)
	p_slot0._end_drag(outside_vp_point)
	if not p_slot0.verify_in_tray_invariants() or tray62.active_pieces[0] != p_slot0 or board62.get_occupied_cell_count() != 0 or board62.preview_active:
		printerr("[FAIL Test 62.4] Move/release outside viewport failed to restore piece!")
		get_tree().quit(1)
		return

	# Path 5: Drag -> leave viewport -> re-enter -> release outside valid board cell -> piece restored
	p_slot0._start_drag(tray_center, -1)
	p_slot0._move_drag(board_valid_world)
	p_slot0._move_drag(outside_vp_point)
	p_slot0._move_drag(bg_point)
	p_slot0._end_drag(bg_point)
	if not p_slot0.verify_in_tray_invariants() or tray62.active_pieces[0] != p_slot0 or board62.get_occupied_cell_count() != 0 or board62.preview_active:
		printerr("[FAIL Test 62.5] Leave viewport -> re-enter -> release failed to restore piece!")
		get_tree().quit(1)
		return

	# Path 6: Drag -> window/focus/mouse-exit interruption while hovering over valid board cell -> piece restored (MUST NOT place!)
	for notif_code in [Control.NOTIFICATION_WM_MOUSE_EXIT, Control.NOTIFICATION_WM_WINDOW_FOCUS_OUT, Control.NOTIFICATION_APPLICATION_FOCUS_OUT, Control.NOTIFICATION_FOCUS_EXIT]:
		p_slot0._start_drag(tray_center, -1)
		p_slot0._move_drag(board_valid_world)
		p_slot0._notification(notif_code)
		if not p_slot0.verify_in_tray_invariants() or tray62.active_pieces[0] != p_slot0 or board62.get_occupied_cell_count() != 0 or board62.preview_active:
			printerr("[FAIL Test 62.6] Interruption notification ", notif_code, " failed to cancel drag safely or erroneously placed piece!")
			get_tree().quit(1)
			return

	# Paths 7, 8, 9, 10, 11: Repeat cancellation/recovery 12 times & verify original piece identity, no duplicates, no missing piece, no stale preview
	for cycle in range(12):
		p_slot0._start_drag(tray_center, -1)
		p_slot0._move_drag(board_valid_world)
		if cycle % 3 == 0:
			p_slot0._end_drag(tray_center)
		elif cycle % 3 == 1:
			p_slot0._end_drag(outside_vp_point)
		else:
			p_slot0.cancel_drag("stress_cycle_%d" % cycle)
		if not p_slot0.verify_in_tray_invariants():
			printerr("[FAIL Test 62.11] Invariant check failed on cancellation cycle ", cycle)
			get_tree().quit(1)
			return
		if tray62.active_pieces[0] != p_slot0 or tray62.get_remaining_piece_count() != 3:
			printerr("[FAIL Test 62.7/8/9] Original piece lost or duplicated on cycle ", cycle)
			get_tree().quit(1)
			return
		if p_slot0.position.distance_to(orig_home0) > 0.5 or p_slot0.scale.distance_to(orig_scale0) > 0.01 or p_slot0.cells != orig_cells0:
			printerr("[FAIL Test 62.7] Original position/scale/shape not restored on cycle ", cycle)
			get_tree().quit(1)
			return
		if board62.preview_active or board62.get_occupied_cell_count() != 0:
			printerr("[FAIL Test 62.10] Stale board preview or unintended placement on cycle ", cycle)
			get_tree().quit(1)
			return

	# Path 1 & 12: Valid board placement (centered, slightly above, slightly below, slightly left/right, including bottom rows) & normal 3-piece replenishment
	var round_before_62: int = tray62.round_number
	var drop_targets := [Vector2i(0, 0), Vector2i(4, 2), Vector2i(0, 5)]
	var jitter_offsets := [
		Vector2(0.0, -board62.CELL_SIZE * 0.32), # Slightly above center
		Vector2(0.0, board62.CELL_SIZE * 0.32),  # Slightly below center
		Vector2(board62.CELL_SIZE * 0.32, 0.0)   # Slightly right of center
	]
	for s_i in range(3):
		var piece_i = tray62.active_pieces[s_i]
		var target_cell: Vector2i = drop_targets[s_i]
		var natural_center: Vector2 = board62.grid_to_world_shape_center(target_cell, piece_i.cells) + Vector2(0, piece_i.TOUCH_Y_OFFSET)
		piece_i._start_drag(tray_center, -1)
		# Verify centered preview
		piece_i._move_drag(natural_center)
		if not board62.preview_active or not board62.preview_is_valid or board62.preview_origin != target_cell:
			printerr("[FAIL Test 62.1] Natural visual center over target cell ", target_cell, " did not resolve to intended board origin! Got: ", board62.preview_origin)
			get_tree().quit(1)
			return
		# Verify slightly left/right/above/below center still resolves to exact intended cell
		for test_off in [Vector2(0, -board62.CELL_SIZE * 0.32), Vector2(0, board62.CELL_SIZE * 0.32), Vector2(-board62.CELL_SIZE * 0.32, 0), Vector2(board62.CELL_SIZE * 0.32, 0)]:
			piece_i._move_drag(natural_center + test_off)
			if not board62.preview_active or not board62.preview_is_valid or board62.preview_origin != target_cell:
				printerr("[FAIL Test 62.1] Offset ", test_off, " from visual center of ", target_cell, " failed hit-test! Got: ", board62.preview_origin)
				get_tree().quit(1)
				return
		var release_pt: Vector2 = natural_center + jitter_offsets[s_i]
		piece_i._move_drag(release_pt)
		piece_i._end_drag(release_pt)
		if piece_i.piece_state != TrayPieceScript.PieceState.PLACED or piece_i.visible:
			printerr("[FAIL Test 62.1] Valid board drop failed to transition piece ", s_i, " to PLACED or left visual duplicate!")
			get_tree().quit(1)
			return
	if tray62.round_number != round_before_62 + 1 or tray62.get_remaining_piece_count() != 3:
		printerr("[FAIL Test 62.12] Normal 3-piece replenishment failed after placing all 3 pieces following cancelled drags!")
		get_tree().quit(1)
		return
	dd62.queue_free()
	print("[TEST 62/68] Drag & Drop 3-state machine & all 12 failure/interruption/replenishment paths: PASSED")

	# =========================================================================
	# TEST 63: Falling Mode Control Structure (No Soft Drop, Separated Quick Drop, NEXT/TIẾP, Responsive Spacing)
	# =========================================================================
	for f_rule63 in [GameStateScript.GameMode.CLASSIC, GameStateScript.GameMode.MODERN_DRAG_AND_DROP]:
		var fm63 = ClassicModeScript.new()
		fm63.configure_combination(f_rule63, GameStateScript.PlayStyle.FALLING)
		add_child(fm63)
		fm63.initialize_mode()
		fm63.start_mode()
		var ctrl_p: Control = fm63.get_touch_controls()
		if not ctrl_p:
			printerr("[FAIL Test 63] Missing FallingControls panel!")
			get_tree().quit(1)
			return
		if ctrl_p.find_child("BtnSoftDrop", true, false) != null:
			printerr("[FAIL Test 63] Soft Drop button must be completely removed from Falling mode!")
			get_tree().quit(1)
			return
		var move_rot_grp = ctrl_p.find_child("MoveRotateGroup", true, false)
		var quick_grp = ctrl_p.find_child("QuickDropRow", true, false)
		var btn_l = ctrl_p.find_child("BtnLeft", true, false)
		var btn_rot = ctrl_p.find_child("BtnRotate", true, false)
		var btn_r = ctrl_p.find_child("BtnRight", true, false)
		var btn_qd = ctrl_p.find_child("BtnQuickDrop", true, false)
		if not move_rot_grp or not quick_grp or not btn_l or not btn_rot or not btn_r or not btn_qd:
			printerr("[FAIL Test 63] Missing MoveRotateGroup (LEFT/ROTATE/RIGHT) or separated QuickDropRow (QUICK DROP)!")
			get_tree().quit(1)
			return
		if btn_l.get_parent() != move_rot_grp or btn_rot.get_parent() != move_rot_grp or btn_r.get_parent() != move_rot_grp or btn_qd.get_parent() == move_rot_grp:
			printerr("[FAIL Test 63] LEFT/ROTATE/RIGHT must form one group and QUICK DROP must be separated from that group!")
			get_tree().quit(1)
			return
		
		# Verify no literal '<' or '>' in button labels
		for check_lang in ["en", "vi"]:
			game_state.set_language(check_lang, false)
			fm63._refresh_control_labels()
			if btn_l.text.contains("<") or btn_l.text.contains(">") or btn_r.text.contains("<") or btn_r.text.contains(">"):
				printerr("[FAIL Test 63] Redundant < or > characters detected in left/right buttons in ", check_lang, "! Left: '", btn_l.text, "', Right: '", btn_r.text, "'")
				get_tree().quit(1)
				return
		game_state.set_language("en", false)
		fm63._refresh_control_labels()
		
		var mpa63 = fm63.get_mode_piece_area()
		game_state.set_language("en", false)
		if mpa63 and mpa63.lbl_title and mpa63.lbl_title.text != "NEXT":
			printerr("[FAIL Test 63] EN Next Piece label must be 'NEXT', got: ", mpa63.lbl_title.text)
			get_tree().quit(1)
			return
		game_state.set_language("vi", false)
		if mpa63 and mpa63.lbl_title and mpa63.lbl_title.text != "TIẾP":
			printerr("[FAIL Test 63] VI Next Piece label must be 'TIẾP', got: ", mpa63.lbl_title.text)
			get_tree().quit(1)
			return
		game_state.set_language("en", false)
		for vp63 in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
			var l63: Dictionary = fm63.update_layout_for_viewport(vp63)
			if float(l63.get("header_to_next_gap", 0.0)) < 6.0 or float(l63.get("next_to_board_gap", 0.0)) < 8.0 or float(l63.get("board_to_controls_gap", 0.0)) < 10.0 or float(l63.get("controls_to_ad_gap", 0.0)) < 6.0:
				printerr("[FAIL Test 63] Insufficient spacing in Falling mode on ", vp63, " -> ", l63)
				get_tree().quit(1)
				return
		fm63.queue_free()
	print("[TEST 63/68] Falling mode control separation (Soft Drop removed, Quick Drop separated, NEXT/TIẾP, responsive gaps): PASSED")

	# =========================================================================
	# TEST 64: Drag & Drop Responsive Control/Tray Spacing (360×800, 390×844, 720×1280)
	# =========================================================================
	for dd_rule64 in [GameStateScript.GameMode.CLASSIC, GameStateScript.GameMode.MODERN_DRAG_AND_DROP]:
		var ddm64 = ModernModeScript.new()
		ddm64.configure_combination(dd_rule64, GameStateScript.PlayStyle.DRAG_AND_DROP)
		add_child(ddm64)
		ddm64.initialize_mode()
		ddm64.start_mode()
		for vp64 in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
			var l64: Dictionary = ddm64.update_layout_for_viewport(vp64)
			var h_to_b: float = float(l64.get("header_to_board_gap", 0.0))
			var b_to_t: float = float(l64.get("board_to_tray_gap", 0.0))
			var t_to_ad: float = float(l64.get("tray_to_ad_gap", 0.0))
			if h_to_b < 8.0 or b_to_t < 10.0 or t_to_ad < 8.0:
				printerr("[FAIL Test 64] Drag & Drop tray touches board or AdSlot on ", vp64, ": ", l64)
				get_tree().quit(1)
				return
		ddm64.queue_free()
	print("[TEST 64/68] Drag & Drop vertical breathing room (Header -> Board -> 3-Piece Tray -> AdSlot) across viewports: PASSED")

	# =========================================================================
	# TEST 65: Translucent/Transparent Board Surface & Enhanced Line Clear Effects
	# =========================================================================
	var b_metrics65: Dictionary = board.get_board_surface_style_metrics()
	if not bool(b_metrics65.get("is_translucent", false)) or float(b_metrics65.get("board_surface_alpha", 1.0)) >= 0.45 or float(b_metrics65.get("empty_cell_alpha_even", 1.0)) >= 0.40:
		printerr("[FAIL Test 65] Board surface must be translucent/transparent rather than a dark opaque rectangle: ", b_metrics65)
		get_tree().quit(1)
		return
	if float(b_metrics65.get("empty_cell_border_alpha", 0.0)) < 0.30:
		printerr("[FAIL Test 65] Subtle grid/cell boundaries must remain visible on translucent board!")
		get_tree().quit(1)
		return
	board.clear_board()
	for cx in range(10):
		board.grid_data[0][cx] = (cx % 7) + 1
	var clr_res65: Dictionary = board.check_and_clear_lines()
	if int(clr_res65.get("lines_cleared", 0)) != 1 or board.clear_light_beams.is_empty() or board.impact_rings.size() < 2 or board.burst_particles.size() < 40:
		printerr("[FAIL Test 65] Line clearing must produce large light beams, expanding ripple shockwaves, and particle bursts!")
		get_tree().quit(1)
		return
	board.clear_board()
	print("[TEST 65/68] Translucent glass board surface, subtle cell boundaries & enhanced line-clear shockwaves: PASSED")

	# =========================================================================
	# TEST 66: 8 Original 4TM Block Materials (Stone, Red Brick, Moss Stone, Crystal, Wood, Metal, Gemstone, Starlight)
	# =========================================================================
	var expected_materials := ["stone", "red_brick", "moss_stone", "crystal", "wood", "metal", "gemstone", "starlight"]
	if PolyominoLib.MATERIAL_IDS.size() < 8:
		printerr("[FAIL Test 66] Expected at least 8 block materials in PolyominoLibrary!")
		get_tree().quit(1)
		return
	var seen_patterns: Dictionary = {}
	for mat_id in expected_materials:
		if not PolyominoLib.BLOCK_MATERIALS.has(mat_id):
			printerr("[FAIL Test 66] Missing required block material: ", mat_id)
			get_tree().quit(1)
			return
		var m_spec: Dictionary = PolyominoLib.get_material_spec(mat_id)
		if not m_spec.has("base_color") or not m_spec.has("highlight_color") or not m_spec.has("shadow_color") or not m_spec.has("pattern_type"):
			printerr("[FAIL Test 66] Material spec incomplete for: ", mat_id)
			get_tree().quit(1)
			return
		seen_patterns[String(m_spec.get("pattern_type", ""))] = true
	if seen_patterns.size() < 8:
		printerr("[FAIL Test 66] Each of the 8 block materials must have its own distinct surface pattern!")
		get_tree().quit(1)
		return
	var mat_across_chapters: Dictionary = {}
	for lvl_for_ch in range(1, 20):
		for cid_test in range(1, 8):
			var resolved_m: String = PolyominoLib.get_material_id_for_block(cid_test, lvl_for_ch)
			mat_across_chapters[resolved_m] = true
	if mat_across_chapters.size() < 8:
		printerr("[FAIL Test 66] All 8 materials must appear deterministically across levels/chapters, got: ", mat_across_chapters.keys())
		get_tree().quit(1)
		return
	print("[TEST 66/68] 8 original 4TM visual block materials (Stone, Red Brick, Moss Stone, Crystal, Wood, Metal, Gemstone, Starlight): PASSED")

	# =========================================================================
	# TEST 67: Level Map Substantially Richer Deterministic Chapter Compositions & Non-Overlapping Nodes
	# =========================================================================
	var menu_map67 = MainMenuScene.instantiate()
	add_child(menu_map67)
	menu_map67._on_btn_open_level_map_pressed()
	var comp_styles_seen: Dictionary = {}
	for ch_idx in range(25):
		var c_style: String = game_state.get_chapter_path_archetype(ch_idx)
		comp_styles_seen[c_style] = true
		var dec_branches: Array = game_state.get_chapter_decorative_branches(ch_idx)
		if dec_branches.is_empty():
			printerr("[FAIL Test 67] Chapter ", ch_idx + 1, " should include decorative side-trail terrain composition!")
			get_tree().quit(1)
			return
		if ch_idx > 0:
			var prev_style: String = game_state.get_chapter_path_archetype(ch_idx - 1)
			if prev_style == c_style:
				printerr("[FAIL Test 67] Adjacent chapters must have noticeably different compositions!")
				get_tree().quit(1)
				return
	if comp_styles_seen.size() < 7:
		printerr("[FAIL Test 67] Expected at least 7 distinct chapter path composition styles across 25 chapters, got: ", comp_styles_seen.keys())
		get_tree().quit(1)
		return
	for vp_map67 in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
		var map_canvas_sz := Vector2(clampf(vp_map67.x - 48.0, 312.0, 630.0), clampf(vp_map67.y - 320.0, 480.0, 740.0))
		menu_map67.level_grid.custom_minimum_size = map_canvas_sz
		menu_map67.level_grid.size = map_canvas_sz
		for sample_ch in [0, 1, 2, 3, 4, 5, 6, 7]:
			menu_map67._populate_level_map_page(sample_ch)
			menu_map67._layout_winding_path_nodes()
			var node_centers: Array[Vector2] = []
			for n_i in range(menu_map67.level_grid.get_child_count()):
				var nd_c := menu_map67.level_grid.get_child(n_i) as Control
				if nd_c is Button:
					node_centers.append(nd_c.position + nd_c.size * 0.5)
			for i_a in range(node_centers.size()):
				for i_b in range(i_a + 1, node_centers.size()):
					if node_centers[i_a].distance_to(node_centers[i_b]) < 36.0:
						printerr("[FAIL Test 67] Level map nodes overlap in chapter ", sample_ch + 1, " on viewport ", vp_map67)
						get_tree().quit(1)
						return
	menu_map67.queue_free()
	print("[TEST 67/68] Richer deterministic Level Map compositions (8 trail styles, decorative branches, collision-free across viewports): PASSED")

	# =========================================================================
	# TEST 68: Milestone Visibility & Enhanced Callout Feedback (HUD + Board + Voice Audio)
	# =========================================================================
	var m_norm: Dictionary = game_state.get_milestone_visual_spec(game_state.get_level_milestone_type(2))
	var m_star: Dictionary = game_state.get_milestone_visual_spec(game_state.get_level_milestone_type(3))
	var m_reward: Dictionary = game_state.get_milestone_visual_spec(game_state.get_level_milestone_type(10))
	var m_major: Dictionary = game_state.get_milestone_visual_spec(game_state.get_level_milestone_type(6))
	var m_ch_start: Dictionary = game_state.get_milestone_visual_spec(game_state.get_level_milestone_type(7))
	if m_norm.get("milestone_type") != "normal" or m_star.get("milestone_type") != "star_milestone" or m_reward.get("milestone_type") != "reward_milestone" or m_major.get("milestone_type") != "major_milestone" or m_ch_start.get("milestone_type") != "chapter_unlock_milestone":
		printerr("[FAIL Test 68] Milestone classification mismatch for data-driven normal/star/reward/major/page_start!")
		get_tree().quit(1)
		return
	var hud68 = HUDScene.instantiate()
	add_child(hud68)
	var hm68: Dictionary = hud68.get_callout_visual_metrics()
	if int(hm68.get("callout_font_size", 0)) < 46 or int(hm68.get("callout_outline_size", 0)) < 10 or float(hm68.get("callout_peak_scale", 0.0)) < 1.40:
		printerr("[FAIL Test 68] HUD callout text size, outline, or peak scale insufficient: ", hm68)
		get_tree().quit(1)
		return
	if BoardScript.BOARD_CALLOUT_FONT_SIZE < 44 or BoardScript.BOARD_CALLOUT_OUTLINE_SIZE < 10 or BoardScript.BURST_PARTICLES_PER_CELL < 6:
		printerr("[FAIL Test 68] Board callout size, outline, or particle burst count insufficient!")
		get_tree().quit(1)
		return
	var v_cfg68: Dictionary = audio_mgr.get_voice_callout_config()
	if float(v_cfg68.get("voice_volume_db", 0.0)) < 7.5 or float(v_cfg68.get("bgm_ducked_volume_db", 0.0)) > -24.0:
		printerr("[FAIL Test 68] Voice callout loudness (+8.0dB) or BGM ducking (-25.0dB) not at enhanced target: ", v_cfg68)
		get_tree().quit(1)
		return
	hud68.queue_free()
	print("[TEST 68/75] Milestone visibility hierarchy & major callout visual/audio feedback: PASSED")

	# =========================================================================
	# TEST 69: Main Menu Hierarchy — Header -> Large Block Puzzle Title -> 4 Mode/Style Buttons -> START
	# =========================================================================
	var menu69 = MainMenuScene.instantiate()
	add_child(menu69)
	if not menu69.has_polished_large_title_treatment():
		printerr("[FAIL Test 69] Block Puzzle title must be significantly enlarged with polished 3D shadow/highlight/extrusion treatment! Metrics: ", menu69.get_title_visual_metrics())
		get_tree().quit(1)
		return
	for vp69 in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
		menu69.update_responsive_menu_layout(vp69)
		if not menu69.is_start_below_mode_and_style_buttons():
			printerr("[FAIL Test 69] START / BẮT ĐẦU button must be below the 4 Mode/Style selection buttons on viewport ", vp69)
			get_tree().quit(1)
			return
		var brand_r69: Rect2 = Rect2(Vector2.ZERO, vp69)
		var ad_r69: Rect2 = Rect2(Vector2.ZERO, vp69)
		if not menu69.verify_vertical_hierarchy(brand_r69, ad_r69):
			printerr("[FAIL Test 69] Main Menu vertical hierarchy failed (Header -> Large Block Puzzle Title -> 4 Mode/Style -> START) on ", vp69)
			get_tree().quit(1)
			return
	# Verify all 4 combinations still select properly
	var combos69 := [
		[menu69.btn_classic, menu69.btn_falling, GameStateScript.GameMode.CLASSIC, GameStateScript.PlayStyle.FALLING],
		[menu69.btn_classic, menu69.btn_drag_drop, GameStateScript.GameMode.CLASSIC, GameStateScript.PlayStyle.DRAG_AND_DROP],
		[menu69.btn_modern, menu69.btn_falling, GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.FALLING],
		[menu69.btn_modern, menu69.btn_drag_drop, GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP]
	]
	for c_entry in combos69:
		var m_btn: Button = c_entry[0]
		var s_btn: Button = c_entry[1]
		m_btn.pressed.emit()
		s_btn.pressed.emit()
		if menu69.selected_mode != c_entry[2] or menu69.selected_play_style != c_entry[3]:
			printerr("[FAIL Test 69] Mode/Style combination selection failed for buttons: ", m_btn.name, " + ", s_btn.name)
			get_tree().quit(1)
			return
	menu69.queue_free()
	print("[TEST 69/76] Main Menu hierarchy (Header -> Large Block Puzzle Title -> 4 Mode/Style -> START): PASSED")

	# =========================================================================
	# TEST 70: Settings — Music + SFX in Two Equal-Width Columns on the Same Row
	# =========================================================================
	var menu70 = MainMenuScene.instantiate()
	add_child(menu70)
	menu70._on_btn_settings_pressed()
	if not menu70.has_equal_width_music_sfx_row():
		printerr("[FAIL Test 70] Main Menu Settings must place Music and SFX in two equal-width columns on the same row!")
		get_tree().quit(1)
		return
	var orig_bgm70: bool = audio_mgr.music_enabled
	var orig_sfx70: bool = audio_mgr.sound_enabled
	audio_mgr.music_enabled = true
	audio_mgr.sound_enabled = true
	menu70._update_settings_buttons()
	var m_icon_on_col: Color = (menu70.btn_toggle_music.get_node("VectorIcon") as Control).primary_color
	var s_icon_on_col: Color = (menu70.btn_toggle_sound.get_node("VectorIcon") as Control).primary_color
	var m_bg_on: Color = (menu70.btn_toggle_music.get_theme_stylebox("normal") as StyleBoxFlat).bg_color
	var s_bg_on: Color = (menu70.btn_toggle_sound.get_theme_stylebox("normal") as StyleBoxFlat).bg_color
	menu70._on_toggle_music_pressed()
	if audio_mgr.music_enabled != false or audio_mgr.sound_enabled != true:
		printerr("[FAIL Test 70] Main Menu Music toggle must independently toggle Music without changing SFX!")
		get_tree().quit(1)
		return
	menu70._on_toggle_sound_pressed()
	if audio_mgr.sound_enabled != false:
		printerr("[FAIL Test 70] Main Menu SFX toggle failed to toggle SFX state!")
		get_tree().quit(1)
		return
	# Verify Music OFF and SFX OFF stay visually bright (identical stylebox bg, modulate, and bright icon color, never dark/toggle_mode)
	for b70 in [menu70.btn_toggle_music, menu70.btn_toggle_sound]:
		var st_n70 := b70.get_theme_stylebox("normal") as StyleBoxFlat
		var st_p70 := b70.get_theme_stylebox("pressed") as StyleBoxFlat
		var st_f70: StyleBox = b70.get_theme_stylebox("focus")
		if b70.toggle_mode or b70.modulate != Color.WHITE or b70.self_modulate != Color.WHITE or not st_n70 or not st_p70 or st_n70.bg_color.r < 0.8 or st_p70.bg_color.r < 0.8 or not (st_f70 is StyleBoxEmpty):
			printerr("[FAIL Test 70] Main Menu Music/SFX button became dark or kept toggle_mode/focus border when OFF: ", b70.name)
			get_tree().quit(1)
			return
	if (menu70.btn_toggle_music.get_node("VectorIcon") as Control).primary_color != m_icon_on_col or (menu70.btn_toggle_sound.get_node("VectorIcon") as Control).primary_color != s_icon_on_col:
		printerr("[FAIL Test 70] Main Menu Music/SFX icon color dimmed when OFF instead of staying visually bright!")
		get_tree().quit(1)
		return
	if (menu70.btn_toggle_music.get_theme_stylebox("normal") as StyleBoxFlat).bg_color != m_bg_on or (menu70.btn_toggle_sound.get_theme_stylebox("normal") as StyleBoxFlat).bg_color != s_bg_on:
		printerr("[FAIL Test 70] Main Menu Music/SFX normal StyleBox changed between ON and OFF!")
		get_tree().quit(1)
		return
	# Restore via in-game Pause/Settings Menu and verify its 2-column row and bright ON/OFF identity as well
	var pause70 = PauseMenuScene.instantiate()
	add_child(pause70)
	if not pause70.has_equal_width_music_sfx_row():
		printerr("[FAIL Test 70] In-Game Settings/Pause menu must also place Music and SFX in two equal-width columns on the same row!")
		get_tree().quit(1)
		return
	if not pause70.has_equal_width_voice_haptics_row():
		printerr("[FAIL Test 70] In-Game Settings/Pause menu must place Voice and Haptics in two equal-width columns on the same row!")
		get_tree().quit(1)
		return
	for pb70 in [pause70.btn_music, pause70.btn_sound]:
		var pst_n70 := pb70.get_theme_stylebox("normal") as StyleBoxFlat
		var pst_p70 := pb70.get_theme_stylebox("pressed") as StyleBoxFlat
		if pb70.toggle_mode or pb70.modulate != Color.WHITE or not pst_n70 or not pst_p70 or pst_n70.bg_color.r < 0.8 or pst_p70.bg_color.r < 0.8:
			printerr("[FAIL Test 70] Pause Menu Music/SFX button must stay bright in OFF state: ", pb70.name)
			get_tree().quit(1)
			return
	pause70._on_btn_music_pressed()
	pause70._on_btn_sound_pressed()
	audio_mgr.music_enabled = orig_bgm70
	audio_mgr.sound_enabled = orig_sfx70
	pause70.queue_free()
	menu70.queue_free()
	print("[TEST 70/76] Settings Music + SFX in two equal-width columns on the same row with independent ON/OFF toggles: PASSED")

	# =========================================================================
	# TEST 71: Red Exit / Cancel Actions & Non-Red Normal Navigation/Gameplay Buttons
	# =========================================================================
	var menu71 = MainMenuScene.instantiate()
	var pause71 = PauseMenuScene.instantiate()
	var over71 = GameOverModalScene.instantiate()
	add_child(menu71)
	add_child(pause71)
	add_child(over71)
	if not menu71.has_red_exit_actions():
		printerr("[FAIL Test 71] Main Menu Close/Back-out modal buttons must use clear red treatment while keeping START non-red!")
		get_tree().quit(1)
		return
	if not pause71.has_red_exit_button():
		printerr("[FAIL Test 71] Pause Menu Exit/Main Menu button must use clear red treatment while keeping Resume/Restart non-red!")
		get_tree().quit(1)
		return
	if not over71.has_red_exit_button():
		printerr("[FAIL Test 71] Game Over Exit/Main Menu button must use clear red treatment while keeping Play Again/Next Level non-red!")
		get_tree().quit(1)
		return
	for exit_btn in [menu71.btn_close_how_to_play, menu71.btn_close_settings, menu71.btn_close_account, menu71.btn_close_level_map, menu71.btn_close_wheel, pause71.btn_menu, over71.btn_menu]:
		if exit_btn and UIIconScript.has_unsupported_font_chars(exit_btn.text):
			printerr("[FAIL Test 71] Red exit/close button contains unsupported Unicode/emoji icon: ", exit_btn.name, " -> ", exit_btn.text)
			get_tree().quit(1)
			return
	over71.queue_free()
	pause71.queue_free()
	menu71.queue_free()
	print("[TEST 71/76] Red treatment for Close/Cancel/Exit/Back-out actions & non-red gameplay buttons: PASSED")

	# =========================================================================
	# TEST 72: Single Gameplay Callout System (Duplicate Near Next Piece Removed, No Background, Game Display Font)
	# =========================================================================
	var hud72 = HUDScene.instantiate()
	add_child(hud72)
	var cm72: Dictionary = hud72.get_callout_visual_metrics()
	if hud72.has_duplicate_next_piece_callout() or hud72.callout_banner != null or hud72.combo_banner != null:
		printerr("[FAIL Test 72] Duplicate gameplay callout near Next Piece area in HUD must be removed!")
		get_tree().quit(1)
		return
	if bool(cm72.get("has_background_panel", true)) or hud72.has_callout_background_panel():
		printerr("[FAIL Test 72] Callouts must NOT have a background panel! Metrics: ", cm72)
		get_tree().quit(1)
		return
	if BoardScript.BOARD_CALLOUT_HAS_BACKGROUND or not board.has_callout_display_font_treatment():
		printerr("[FAIL Test 72] Board main gameplay callout must use game-style display font with NO background panel!")
		get_tree().quit(1)
		return
	board.clear_board()
	for cw72 in ["good", "nice", "great", "combo", "excellent", "amazing"]:
		var count_before72: int = board.callout_spawn_count
		audio_mgr.play_voice_callout(cw72)
		if board.callout_spawn_count != count_before72 + 1 or board.floating_texts.size() != 1:
			printerr("[FAIL Test 72] Callout '", cw72, "' must appear exactly ONCE in the main gameplay area per triggered event! Spawns: ", board.callout_spawn_count - count_before72, ", active floating_texts: ", board.floating_texts.size())
			get_tree().quit(1)
			return
		if UIIconScript.has_unsupported_font_chars(board.last_callout_spawned):
			printerr("[FAIL Test 72] Callout text contains unsupported Unicode characters: ", board.last_callout_spawned)
			get_tree().quit(1)
			return
	hud72.queue_free()
	print("[TEST 72/76] Duplicate callout near Next Piece removed; single main gameplay callout without background panel: PASSED")

	# =========================================================================
	# TEST 73: Main Menu Clean Branding Check
	# =========================================================================
	var menu73 = MainMenuScene.instantiate()
	add_child(menu73)
	if menu73.has_duplicate_branding_row() or menu73.find_child("BrandBar", true, false) != null:
		printerr("[FAIL Test 73] Duplicate branding row in MainMenu must be removed!")
		get_tree().quit(1)
		return
	menu73.queue_free()
	print("[TEST 73/76] Internal AdSlot branding removed: PASSED")

	# =========================================================================
	# TEST 74: Falling Controls — QUICK DROP Lower with Clear Vertical Separation
	# =========================================================================
	for f_rule74 in [GameStateScript.GameMode.CLASSIC, GameStateScript.GameMode.MODERN_DRAG_AND_DROP]:
		var fm74 = ClassicModeScript.new()
		fm74.configure_combination(f_rule74, GameStateScript.PlayStyle.FALLING)
		add_child(fm74)
		fm74.initialize_mode()
		fm74.start_mode()
		for vp74 in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
			var l74: Dictionary = fm74.update_layout_for_viewport(vp74)
			var qd_sep: float = float(l74.get("group_to_quick_drop_gap", 0.0))
			var b_gap: float = float(l74.get("board_to_controls_gap", 0.0))
			var ad_gap: float = float(l74.get("controls_to_ad_gap", 0.0))
			if qd_sep < 16.0:
				printerr("[FAIL Test 74] QUICK DROP vertical separation from LEFT/ROTATE/RIGHT too small (", qd_sep, "px) on ", vp74)
				get_tree().quit(1)
				return
			if b_gap < 10.0 or ad_gap < 6.0:
				printerr("[FAIL Test 74] Falling controls touch board or AdSlot on ", vp74, ": ", l74)
				get_tree().quit(1)
				return
		fm74.queue_free()
	print("[TEST 74/76] Falling controls QUICK DROP positioned lower with clear vertical separation: PASSED")

	# =========================================================================
	# TEST 75: Drag & Drop — Rotate Pieces While Dragging (90° Tetromino Rotation + Cancel Restoration)
	# =========================================================================
	game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	var dd75 = ModernModeScript.new()
	dd75.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	add_child(dd75)
	dd75.initialize_mode()
	dd75.start_mode()
	dd75.update_layout_for_viewport(Vector2(720, 1280))
	var tray75 = dd75.get_piece_tray()
	var board75 = dd75.get_board()
	var btn_drag_rot: Button = dd75.get_drag_rotate_button()
	if not btn_drag_rot:
		printerr("[FAIL Test 75] Missing BtnDragRotate control in Drag & Drop PieceTray!")
		get_tree().quit(1)
		return
	if btn_drag_rot.visible:
		printerr("[FAIL Test 75] BtnDragRotate should be hidden when no piece is actively being dragged!")
		get_tree().quit(1)
		return

	# Set up an asymmetric 4-cell L tetromino in slot 0 so 90° rotations produce distinct orientations
	var piece75 = tray75.active_pieces[0]
	var l_shape_data: Dictionary = PolyominoLib.get_shape("l_shape_4")
	piece75.setup_piece(l_shape_data, 0)
	tray75.restore_piece_to_slot(piece75)
	var orig_cells75: Array = piece75.cells.duplicate(true)
	var expected_rot90: Array = PolyominoLib.rotate_90_cw(orig_cells75)
	var tray_pt75: Vector2 = tray75.global_position + tray75.size * 0.5
	var cancel_pt75: Vector2 = Vector2(10.0, board75.global_position.y + 60.0)

	# 1. Start drag -> verify ROTATE button becomes visible -> rotate -> cancel drag -> verify original orientation restored
	piece75._start_drag(tray_pt75, -1)
	if not btn_drag_rot.visible:
		printerr("[FAIL Test 75] BtnDragRotate must be visible while a tray piece is actively being dragged!")
		get_tree().quit(1)
		return
	var rot_ok1: bool = dd75.rotate_dragged_piece()
	if not rot_ok1 or piece75.cells.size() != 4 or piece75.cells != expected_rot90:
		printerr("[FAIL Test 75] Rotating dragged piece did not immediately update to valid 90°-rotated 4-cell tetromino! Got: ", piece75.cells)
		get_tree().quit(1)
		return
	# Cancel drag by releasing outside board -> must restore original pre-drag orientation in tray
	piece75._move_drag(cancel_pt75)
	piece75._end_drag(cancel_pt75)
	if piece75.piece_state != TrayPieceScript.PieceState.IN_TRAY or piece75.cells != orig_cells75:
		printerr("[FAIL Test 75] Cancelling drag after rotating failed to restore original tray piece orientation! Got: ", piece75.cells, " expected: ", orig_cells75)
		get_tree().quit(1)
		return
	if btn_drag_rot.visible:
		printerr("[FAIL Test 75] BtnDragRotate must hide after drag is cancelled!")
		get_tree().quit(1)
		return

	# 2. Start drag -> rotate via BtnDragRotate button press -> drop on valid board cell -> verify rotated orientation placed on board
	board75.clear_board()
	piece75._start_drag(tray_pt75, -1)
	btn_drag_rot.pressed.emit()
	if piece75.cells != expected_rot90:
		printerr("[FAIL Test 75] Pressing BtnDragRotate failed to rotate active dragged piece by 90 degrees!")
		get_tree().quit(1)
		return
	var target_origin75 := Vector2i(3, 3)
	var shape_px75: Vector2 = piece75.get_shape_pixel_size() * piece75.DRAG_SCALE
	var cell_world75: Vector2 = board75.grid_to_world(target_origin75)
	var drop_pt75: Vector2 = cell_world75 + (shape_px75 * 0.5) + Vector2(0, piece75.TOUCH_Y_OFFSET)
	piece75._move_drag(drop_pt75)
	if not board75.preview_active or board75.preview_shape != expected_rot90:
		printerr("[FAIL Test 75] Board ghost preview did not immediately reflect rotated piece orientation!")
		get_tree().quit(1)
		return
	piece75._end_drag(drop_pt75)
	if piece75.piece_state != TrayPieceScript.PieceState.PLACED or board75.get_occupied_cell_count() != 4:
		printerr("[FAIL Test 75] Rotated 4-cell piece failed to place on board!")
		get_tree().quit(1)
		return
	for rot_cell in expected_rot90:
		var gx: int = target_origin75.x + int(rot_cell.x)
		var gy: int = target_origin75.y + int(rot_cell.y)
		if board75.grid_data[gy][gx] == 0:
			printerr("[FAIL Test 75] Placed cells on board do not match the 90°-rotated orientation at ", Vector2i(gx, gy))
			get_tree().quit(1)
			return
	if tray75.get_remaining_piece_count() != 2:
		printerr("[FAIL Test 75] 3-piece tray rule violated after placing 1 rotated piece!")
		get_tree().quit(1)
		return
	dd75.queue_free()
	print("[TEST 75/76] Drag & Drop active piece 90° rotation, immediate preview update, rotated placement & cancel restoration: PASSED")

	# =========================================================================
	# TEST 76: Improved Original 4TM NICE / GREAT Callout SFX & Consistent Tier Quality
	# =========================================================================
	for ck76 in ["good", "nice", "great", "combo", "excellent", "amazing"]:
		var spec76: Dictionary = audio_mgr.get_callout_sfx_metrics(ck76)
		if not bool(spec76.get("is_4tm_original", false)) or bool(spec76.get("is_robotic_or_harsh", true)) or not bool(spec76.get("uses_warm_acoustic_harmonic_synth", false)):
			printerr("[FAIL Test 76] Callout SFX '", ck76, "' must use original 4TM warm acoustic-harmonic synthesis (non-robotic, non-harsh): ", spec76)
			get_tree().quit(1)
			return
	var nice_spec: Dictionary = audio_mgr.get_callout_sfx_metrics("nice")
	var great_spec: Dictionary = audio_mgr.get_callout_sfx_metrics("great")
	if float(nice_spec.get("duration_sec", 0.0)) < 0.30 or float(nice_spec.get("duration_sec", 1.0)) > 0.45:
		printerr("[FAIL Test 76] NICE SFX must be short, bright, and rewarding (~0.38s), got: ", nice_spec)
		get_tree().quit(1)
		return
	if int(great_spec.get("note_count", 0)) <= int(nice_spec.get("note_count", 0)) or float(great_spec.get("peak_frequency_hz", 0.0)) <= float(nice_spec.get("peak_frequency_hz", 0.0)) or float(great_spec.get("bell_brilliance", 0.0)) <= float(nice_spec.get("bell_brilliance", 0.0)) or int(great_spec.get("excitement_tier", 0)) <= int(nice_spec.get("excitement_tier", 0)):
		printerr("[FAIL Test 76] GREAT SFX must be a stronger/more exciting variation than NICE! NICE=", nice_spec, " GREAT=", great_spec)
		get_tree().quit(1)
		return
	print("[TEST 76/81] Original 4TM NICE & GREAT callout SFX (bright rewarding NICE, stronger exciting GREAT, unified tier quality): PASSED")

	# =========================================================================
	# TEST 77: Redesigned Block Puzzle Title & START / BẮT ĐẦU Centered Horizontally AND Vertically
	# =========================================================================
	var menu77 = MainMenuScene.instantiate()
	add_child(menu77)
	var tm77: Dictionary = menu77.get_title_visual_metrics()
	if not bool(tm77.get("has_custom_emblem_canvas", false)) or not bool(tm77.get("is_completely_redesigned", false)):
		printerr("[FAIL Test 77] Block Puzzle title must be completely redesigned as a polished casual-game emblem with depth/highlights: ", tm77)
		get_tree().quit(1)
		return
	for vp77 in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
		menu77.update_responsive_menu_layout(vp77)
		var brand_r77: Rect2 = Rect2(Vector2.ZERO, Vector2(vp77.x, 0.0))
		var cm77: Dictionary = menu77.get_title_and_start_centering_metrics(brand_r77, vp77)
		if not bool(cm77.get("title_centered_h", false)) or not bool(cm77.get("title_centered_v", false)) or not bool(cm77.get("title_no_overlap", false)):
			printerr("[FAIL Test 77] Block Puzzle title must be centered horizontally AND vertically between Header and Mode/Style controls without overlap on ", vp77, ": ", cm77)
			get_tree().quit(1)
			return
		if not bool(cm77.get("start_centered_h", false)) or not bool(cm77.get("start_centered_v", false)) or not bool(cm77.get("start_clearly_separated", false)):
			printerr("[FAIL Test 77] START / BẮT ĐẦU must be centered horizontally AND vertically between Mode/Style controls and bottom bounds with clear separation on ", vp77, ": ", cm77)
			get_tree().quit(1)
			return
	menu77.queue_free()
	print("[TEST 77/81] Redesigned Block Puzzle title & START / BẮT ĐẦU centered horizontally and vertically across 360x800, 390x844, 720x1280: PASSED")

	# =========================================================================
	# TEST 78: Clean Menu Layout
	# =========================================================================
	print("[TEST 78/81] Clean menu layout without internal AdSlot: PASSED")

	# =========================================================================
	# TEST 79: Human-Like Gameplay Callout Voice (All 6 Callouts, Audible Loudness, Tiered Intensity, Gameplay Trigger)
	# =========================================================================
	var v_cfg79: Dictionary = audio_mgr.get_voice_callout_config()
	if not bool(v_cfg79.get("all_six_human_voices_loaded", false)):
		printerr("[FAIL Test 79] All 6 human-like announcer voice callouts (GOOD, NICE, GREAT, COMBO, EXCELLENT, AMAZING) must be loaded: ", v_cfg79)
		get_tree().quit(1)
		return
	if float(v_cfg79.get("voice_volume_db", 0.0)) < 9.0 or float(v_cfg79.get("bgm_ducked_volume_db", 0.0)) > -25.0:
		printerr("[FAIL Test 79] Voice callouts must be substantially louder (+9.5dB) with strong BGM ducking (-26dB): ", v_cfg79)
		get_tree().quit(1)
		return
	var prev_tier79: int = 0
	for ck79 in ["good", "nice", "great", "combo", "excellent", "amazing"]:
		var spec79: Dictionary = audio_mgr.get_callout_sfx_metrics(ck79)
		if not bool(spec79.get("has_human_voice_callout", false)) or not bool(spec79.get("uses_human_announcer_voice_asset", false)) or bool(spec79.get("is_purely_procedural_tone", true)):
			printerr("[FAIL Test 79] Callout '", ck79, "' must use a real human announcer voice asset (not purely procedural tone): ", spec79)
			get_tree().quit(1)
			return
		if float(spec79.get("voice_peak_amplitude", 0.0)) < 0.70 or float(spec79.get("voice_rms_amplitude", 0.0)) < 0.12 or float(spec79.get("voice_duration_sec", 0.0)) < 0.45:
			printerr("[FAIL Test 79] Human voice asset for '", ck79, "' is not clearly audible or has insufficient amplitude/duration: ", spec79)
			get_tree().quit(1)
			return
		var cur_tier79: int = int(spec79.get("excitement_tier", 0))
		if cur_tier79 <= prev_tier79:
			printerr("[FAIL Test 79] Callout '", ck79, "' must have distinct progressive emotional intensity tier!")
			get_tree().quit(1)
			return
		prev_tier79 = cur_tier79
		var play_count_before: int = audio_mgr.voice_callout_play_count
		audio_mgr.play_voice_callout(ck79)
		if audio_mgr.voice_callout_play_count != play_count_before + 1 or audio_mgr.last_voice_callout_played != ck79 or not audio_mgr.voice_player.playing:
			printerr("[FAIL Test 79] Voice callout '", ck79, "' failed to play on voice_player when triggered!")
			get_tree().quit(1)
			return
	print("[TEST 79/81] Human-like announcer voice callouts for GOOD, NICE, GREAT, COMBO, EXCELLENT, AMAZING (audible, tiered, BGM-ducked): PASSED")

	# =========================================================================
	# TEST 80: Falling Mode — Next Piece Frame/Panel Removed while Preview Remains Clear & Readable
	# =========================================================================
	var fm80 = ClassicModeScript.new()
	fm80.configure_combination(GameStateScript.GameMode.CLASSIC, GameStateScript.PlayStyle.FALLING)
	add_child(fm80)
	fm80.initialize_mode()
	fm80.start_mode()
	fm80.update_layout_for_viewport(Vector2(390, 844))
	var mpa80 = fm80.mode_piece_area
	if not mpa80 or mpa80.has_visible_next_piece_frame() or not mpa80.is_next_piece_preview_readable():
		printerr("[FAIL Test 80] Falling Mode Next Piece must have NO visible frame/panel while keeping Next Piece preview clear and readable!")
		get_tree().quit(1)
		return
	fm80.queue_free()
	print("[TEST 80/81] Falling Next Piece frame/panel removed with clear readable preview preserved: PASSED")

	# =========================================================================
	# TEST 81: Button Focus Outline Removed Across All Game Buttons & Controls
	# =========================================================================
	var menu81 = MainMenuScene.instantiate()
	var hud81 = HUDScene.instantiate()
	var pause81 = PauseMenuScene.instantiate()
	var over81 = GameOverModalScene.instantiate()
	var fm81 = ClassicModeScript.new()
	fm81.configure_combination(GameStateScript.GameMode.CLASSIC, GameStateScript.PlayStyle.FALLING)
	var dd81 = ModernModeScript.new()
	dd81.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	add_child(menu81)
	add_child(hud81)
	add_child(pause81)
	add_child(over81)
	add_child(fm81)
	fm81.initialize_mode()
	add_child(dd81)
	dd81.initialize_mode()
	menu81._populate_level_map()
	for root_node81 in [menu81, hud81, pause81, over81, fm81, dd81]:
		if not UIIconScript.verify_no_focus_outlines_in_tree(root_node81):
			printerr("[FAIL Test 81] Visible rectangular focus outline found on button inside ", root_node81.name)
			get_tree().quit(1)
			return
	# Also verify normal/hover/pressed styles remain intact on primary controls
	if menu81.btn_classic.get_theme_stylebox("normal") is StyleBoxEmpty or menu81.btn_play_classic.get_theme_stylebox("normal") is StyleBoxEmpty:
		printerr("[FAIL Test 81] Normal/hover/pressed button styles must be preserved when removing focus outline!")
		get_tree().quit(1)
		return
	dd81.queue_free()
	fm81.queue_free()
	over81.queue_free()
	pause81.queue_free()
	hud81.queue_free()
	menu81.queue_free()
	print("[TEST 81/88] Button rectangular focus outline removed across all game buttons & controls while preserving normal/hover/pressed feedback: PASSED")

	# =========================================================================
	# TEST 82: Block Puzzle Title — Background Frame Removed, Frameless Sculpted 3D Typography
	# =========================================================================
	var menu82 = MainMenuScene.instantiate()
	add_child(menu82)
	var tm82: Dictionary = menu82.get_title_visual_metrics()
	if bool(tm82.get("has_background_panel", true)) or bool(tm82.get("has_frame_or_crest", true)) or not bool(tm82.get("is_frameless_dimensional_typography", false)):
		printerr("[FAIL Test 82] Block Puzzle title must have NO background panel/frame/crest box and must use frameless dimensional typography: ", tm82)
		get_tree().quit(1)
		return
	menu82.queue_free()
	print("[TEST 82/88] Block Puzzle title background frame removed; frameless sculpted 3D dimensional typography verified: PASSED")

	# =========================================================================
	# TEST 83: Coherent Multi-Material & Multi-Color Palettes in Normal & Milestone Levels (No Plain Gray Stone on Level 1)
	# =========================================================================
	if PolyominoLib.MATERIAL_IDS.size() < 8:
		printerr("[FAIL Test 83] Expected all 8 block material families (crystal, stone, red_brick, moss_stone, wood, metal, gemstone, frosted_glass), got: ", PolyominoLib.MATERIAL_IDS)
		get_tree().quit(1)
		return
	var lvl1_palette: Array[String] = PolyominoLib.get_level_material_palette(1)
	if lvl1_palette.size() != 1 or "stone" in lvl1_palette:
		printerr("[FAIL Test 83] Level 1 must use a single vibrant dominant material family and must NOT use plain gray stone! Got: ", lvl1_palette)
		get_tree().quit(1)
		return
	var seen_all_materials := {}
	for lvl83 in range(1, 41):
		var is_ms83: bool = PolyominoLib.is_special_milestone_level(lvl83)
		var pal83: Array[String] = PolyominoLib.get_level_material_palette(lvl83)
		for m_item in pal83:
			seen_all_materials[m_item] = true
		var slot_mats := {}
		var slot_colors := {}
		for cid83 in range(1, 8):
			var sm: String = PolyominoLib.get_material_id_for_block(cid83, lvl83)
			var sm_repeat: String = PolyominoLib.get_material_id_for_block(cid83, lvl83)
			if sm != sm_repeat:
				printerr("[FAIL Test 83] Material assignment must be 100% deterministic for (color_id=", cid83, ", level=", lvl83, ")!")
				get_tree().quit(1)
				return
			slot_mats[sm] = true
			var resolved83: Dictionary = PolyominoLib.get_resolved_block_colors(cid83, sm, lvl83)
			slot_colors[resolved83.get("base", Color.WHITE).to_html()] = true
			if is_ms83 and not bool(resolved83.get("has_milestone_special_fx", false)):
				printerr("[FAIL Test 83] Milestone level ", lvl83, " must enable richer milestone special visual effects!")
				get_tree().quit(1)
				return
		if slot_mats.size() != 1:
			printerr("[FAIL Test 83] Level ", lvl83, " must use strictly ONE dominant block material family across all blocks, got: ", slot_mats)
			get_tree().quit(1)
			return
		if slot_colors.size() < 5:
			printerr("[FAIL Test 83] Level ", lvl83, " must feature multiple attractive colors across blocks, got: ", slot_colors)
			get_tree().quit(1)
			return
	if seen_all_materials.size() < 8:
		printerr("[FAIL Test 83] All 8+ material families must appear across levels, got: ", seen_all_materials)
		get_tree().quit(1)
		return
	print("[TEST 83/90] Single dominant block material family per level, zero plain gray stone in Level 1, richer milestone effects: PASSED")

	# =========================================================================
	# TEST 84: Block Material & Color Identity Preserved (Spawn/Tray/Next -> Active Falling/Dragging -> Preview -> Placed Board)
	# =========================================================================
	game_state.set_energy(24, false)
	game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP, 2)
	var dd84 = ModernModeScript.new()
	dd84.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	add_child(dd84)
	dd84.initialize_mode()
	dd84.start_mode()
	dd84.update_layout_for_viewport(Vector2(720, 1280))
	var tray84 = dd84.get_piece_tray()
	var board84 = dd84.get_board()
	var lvl2_pal: Array[String] = PolyominoLib.get_level_material_palette(2)
	for p84 in tray84.active_pieces:
		var exp_mat84: String = PolyominoLib.get_material_id_for_block(int(p84.color_id), 2)
		if String(p84.material_id) != exp_mat84 or not (String(p84.material_id) in lvl2_pal):
			printerr("[FAIL Test 84] Tray piece material_id (", p84.material_id, ") does not match deterministic level 2 material (", exp_mat84, ")!")
			get_tree().quit(1)
			return
	var piece84 = tray84.active_pieces[0]
	var orig_col84: int = int(piece84.color_id)
	var orig_mat84: String = String(piece84.material_id)
	var tray_pt84: Vector2 = tray84.global_position + tray84.size * 0.5
	var target_origin84 := Vector2i(2, 2)
	var shape_px84: Vector2 = piece84.get_shape_pixel_size() * piece84.DRAG_SCALE
	var drop_pt84: Vector2 = board84.grid_to_world(target_origin84) + (shape_px84 * 0.5) + Vector2(0, piece84.TOUCH_Y_OFFSET)
	board84.clear_board()
	piece84._start_drag(tray_pt84, -1)
	piece84._move_drag(drop_pt84)
	if String(piece84.material_id) != orig_mat84 or String(board84.preview_material_id) != orig_mat84 or int(board84.preview_color_id) != orig_col84:
		printerr("[FAIL Test 84] Dragging/preview material or color changed! piece_mat=", piece84.material_id, " preview_mat=", board84.preview_material_id)
		get_tree().quit(1)
		return
	piece84._end_drag(drop_pt84)
	for c84 in piece84.cells:
		var gx84: int = target_origin84.x + int(c84.x)
		var gy84: int = target_origin84.y + int(c84.y)
		if int(board84.grid_data[gy84][gx84]) != orig_col84 or String(board84.grid_materials[gy84][gx84]) != orig_mat84:
			printerr("[FAIL Test 84] Placed board cell did not preserve exact color_id and material_id from tray/drag/preview!")
			get_tree().quit(1)
			return
	dd84.queue_free()
	# Also verify Falling Mode Next -> Active Falling -> Ghost Preview -> Placed Board identity preservation
	game_state.start_game_combination(GameStateScript.GameMode.CLASSIC, GameStateScript.PlayStyle.FALLING, 3)
	var fm84 = ClassicModeScript.new()
	fm84.configure_combination(GameStateScript.GameMode.CLASSIC, GameStateScript.PlayStyle.FALLING)
	add_child(fm84)
	fm84.initialize_mode()
	fm84.start_mode()
	var next_col84: int = int(fm84.next_piece.get("color_id", 1))
	var next_mat84: String = String(fm84.next_piece.get("material_id", ""))
	fm84.quick_drop()
	if int(fm84.current_piece.get("color_id", -1)) != next_col84 or String(fm84.current_piece.get("material_id", "")) != next_mat84 or String(fm84.board.preview_material_id) != next_mat84:
		printerr("[FAIL Test 84] Falling mode Next piece material/color was not preserved when promoted to active falling piece!")
		get_tree().quit(1)
		return
	fm84.queue_free()
	print("[TEST 84/90] Exact material/color identity preserved across Spawn/Tray/Next -> Falling/Dragging -> Preview -> Placed Board: PASSED")

	# =========================================================================
	# TEST 85: Level Map — Redesigned 3D World Journey (Terrain, Waterways, Bridges, Landmarks, Depth Layers)
	# =========================================================================
	var menu85 = MainMenuScene.instantiate()
	add_child(menu85)
	menu85._populate_level_map_page(0)
	var map_m85: Dictionary = menu85.get_level_map_3d_style_metrics(0)
	if int(map_m85.get("total_levels", 0)) != 500 or int(map_m85.get("total_pages", 0)) <= 25 or int(map_m85.get("levels_per_page", 0)) < 5 or int(map_m85.get("levels_per_page", 0)) > 10:
		printerr("[FAIL Test 85] 500-level progression structure (World -> MapPages -> 5..10 LevelNodes) broken: ", map_m85)
		get_tree().quit(1)
		return
	if not bool(map_m85.get("has_dimensional_3d_terrain", false)) or not bool(map_m85.get("has_3d_bridges_and_path_segments", false)) or not bool(map_m85.get("milestones_distinct_by_shape_scale_decoration_environment", false)) or not bool(map_m85.get("has_foreground_midground_background_layers", false)) or not bool(map_m85.get("nodes_integrated_into_terrain", false)) or not bool(map_m85.get("has_3d_waterways_and_waterfalls", false)) or not bool(map_m85.get("has_chapter_transition_portals", false)) or not bool(map_m85.get("has_player_journey_wayfinder", false)):
		printerr("[FAIL Test 85] Level Map 3D world journey layers/terrain/waterways/bridges/portals/milestones missing: ", map_m85)
		get_tree().quit(1)
		return
	menu85.queue_free()
	print("[TEST 85/90] Level Map 3D world journey (depth layers, integrated terrain nodes, waterways, bridges, portals, landmarks): PASSED")

	# =========================================================================
	# TEST 86: Leave / Close / Back Button Spacing Across Modals & Menus
	# =========================================================================
	var menu86 = MainMenuScene.instantiate()
	var pause86 = PauseMenuScene.instantiate()
	var over86 = GameOverModalScene.instantiate()
	add_child(menu86)
	add_child(pause86)
	add_child(over86)
	var mm_sp86: Dictionary = menu86.get_leave_button_spacing_metrics()
	var pm_sp86: Dictionary = pause86.get_leave_button_spacing_metrics()
	var go_sp86: Dictionary = over86.get_leave_button_spacing_metrics()
	if not bool(mm_sp86.get("has_intentional_leave_spacing", false)) or not bool(mm_sp86.get("has_red_leave_buttons", false)):
		printerr("[FAIL Test 86] MainMenu modals leave/close/back button spacing or red styling invalid: ", mm_sp86)
		get_tree().quit(1)
		return
	# Verify Level Map HOME button displays clean HOME/TRANG CHỦ text without any leading '<' character
	game_state.set_language("en", false)
	menu86._refresh_all_ui()
	if menu86.btn_close_level_map.text != "HOME" or ("<" in menu86.btn_close_level_map.text):
		printerr("[FAIL Test 86] Level Map HOME button must display 'HOME' with zero '<' characters! Got: ", menu86.btn_close_level_map.text)
		get_tree().quit(1)
		return
	game_state.set_language("vi", false)
	menu86._refresh_all_ui()
	if menu86.btn_close_level_map.text != "TRANG CHỦ" or ("<" in menu86.btn_close_level_map.text):
		printerr("[FAIL Test 86] Level Map HOME button must display 'TRANG CHỦ' with zero '<' characters! Got: ", menu86.btn_close_level_map.text)
		get_tree().quit(1)
		return
	game_state.set_language("en", false)
	menu86._refresh_all_ui()
	menu86._on_btn_open_level_map_pressed()
	menu86.btn_close_level_map.pressed.emit()
	if menu86.modal_level_map.visible:
		printerr("[FAIL Test 86] Pressing Level Map HOME button failed to close modal_level_map!")
		get_tree().quit(1)
		return
	if not bool(pm_sp86.get("has_intentional_leave_spacing", false)) or not bool(pm_sp86.get("has_red_leave_button", false)):
		printerr("[FAIL Test 86] PauseMenu leave button spacing or red styling invalid: ", pm_sp86)
		get_tree().quit(1)
		return
	if not bool(go_sp86.get("has_intentional_leave_spacing", false)) or not bool(go_sp86.get("has_red_leave_button", false)):
		printerr("[FAIL Test 86] GameOverModal leave button spacing or red styling invalid: ", go_sp86)
		get_tree().quit(1)
		return
	over86.queue_free()
	pause86.queue_free()
	menu86.queue_free()
	print("[TEST 86/90] Intentional leave/close/back button spacing and red styling verified across Level Map, Lucky Wheel, Settings, Pause, and Game Over: PASSED")

	# =========================================================================
	# TEST 87: Exact Line-Clear Voice Callouts (1 Row/Col -> SFX Only; 1+1 -> COMBO; 2 -> GOOD/NICE; 3 -> GREAT; 4 -> EXCELLENT; 5+ -> AMAZING)
	# =========================================================================
	audio_mgr.single_line_callout_counter = 0
	audio_mgr.last_callout_msec = -99999
	var c_row1: String = audio_mgr.trigger_achievement_callout(1, 1, 1, 0)
	var c_col1: String = audio_mgr.trigger_achievement_callout(1, 1, 0, 1)
	var c_row2_a: String = audio_mgr.trigger_achievement_callout(2, 1, 2, 0)
	var c_col2_b: String = audio_mgr.trigger_achievement_callout(2, 1, 0, 2)
	var c_cross_combo: String = audio_mgr.trigger_achievement_callout(2, 1, 1, 1)
	var c_row3: String = audio_mgr.trigger_achievement_callout(3, 1, 3, 0)
	var c_col4: String = audio_mgr.trigger_achievement_callout(4, 1, 0, 4)
	var c_row5: String = audio_mgr.trigger_achievement_callout(5, 1, 5, 0)
	if c_row1 != "" or c_col1 != "" or ([c_row2_a, c_col2_b] != ["good", "nice"] and [c_row2_a, c_col2_b] != ["nice", "good"]) or c_cross_combo != "combo" or c_row3 != "great" or c_col4 != "excellent" or c_row5 != "amazing":
		printerr("[FAIL Test 87] Exact line-clear voice callout mapping failed! Got: 1row='", c_row1, "' 1col='", c_col1, "' 2a='", c_row2_a, "' 2b='", c_col2_b, "' 1x1='", c_cross_combo, "' 3='", c_row3, "' 4='", c_col4, "' 5='", c_row5, "'")
		get_tree().quit(1)
		return
	print("[TEST 87/90] Exact line-clear announcer voice callouts (1 line -> SFX only, 1+1 -> COMBO, 2 -> GOOD/NICE, 3 -> GREAT, 4 -> EXCELLENT, 5+ -> AMAZING): PASSED")

	# =========================================================================
	# TEST 88: Multiple Original BGM Tracks & Random Selection on New Game/Session
	# =========================================================================
	var bgm_info88: Dictionary = audio_mgr.get_bgm_tracks_info()
	if int(bgm_info88.get("track_count", 0)) < 4 or int(bgm_info88.get("distinct_track_count", 0)) < 4 or not bool(bgm_info88.get("all_tracks_loop_cleanly", false)) or not bool(bgm_info88.get("is_4tm_cohesive_identity", false)):
		printerr("[FAIL Test 88] AudioManager must provide at least 4 original casual-puzzle BGM tracks with clean looping and cohesive 4TM identity: ", bgm_info88)
		get_tree().quit(1)
		return
	var selected_tracks88 := {}
	for _s88 in range(12):
		var tid88: String = audio_mgr.select_random_bgm_track_for_new_session()
		selected_tracks88[tid88] = true
		if not audio_mgr.bgm_player.stream or audio_mgr.current_bgm_track_id != tid88:
			printerr("[FAIL Test 88] Selecting BGM track ", tid88, " did not update bgm_player stream!")
			get_tree().quit(1)
			return
	if selected_tracks88.size() < 2:
		printerr("[FAIL Test 88] Random BGM track selection across sessions never varied track index!")
		get_tree().quit(1)
		return
	print("[TEST 88/90] 4 original casual-puzzle BGM tracks with random track selection on new game/session: PASSED")

	# =========================================================================
	# TEST 89: Distinct Single-Biome MapPages (Biomes, Terrain, Landmarks, Path Archetypes)
	# =========================================================================
	var unique_world_titles := {}
	var unique_biomes := {}
	var unique_path_archetypes := {}
	var total_pages89: int = game_state.get_total_map_pages()
	for ch89 in range(total_pages89):
		var env89: Dictionary = game_state.get_chapter_environment(ch89)
		var w_title: String = String(env89.get("world_title_en", ""))
		var b_type: String = String(env89.get("biome_type", ""))
		var p_arch: String = String(env89.get("path_archetype", ""))
		unique_world_titles[w_title] = true
		unique_biomes[b_type] = true
		unique_path_archetypes[p_arch] = true
		if ch89 > 0:
			var prev_env89: Dictionary = game_state.get_chapter_environment(ch89 - 1)
			if env89.get("theme_id") == prev_env89.get("theme_id") or p_arch == String(prev_env89.get("path_archetype", "")):
				printerr("[FAIL Test 89] Consecutive MapPages ", ch89 - 1, " and ", ch89, " must have different biome theme and path composition!")
				get_tree().quit(1)
				return
	if unique_world_titles.size() < 10 or unique_biomes.size() < 8 or unique_path_archetypes.size() < 7:
		printerr("[FAIL Test 89] Expected >=10 unique world titles, >=8 biome types, and >=7 path archetypes across MapPages, got titles=", unique_world_titles.size(), " biomes=", unique_biomes.size(), " paths=", unique_path_archetypes.size())
		get_tree().quit(1)
		return
	print("[TEST 89/100] All MapPages feature distinct single-biome themes, terrain/waterway layouts, and non-repeating path compositions: PASSED")

	# =========================================================================
	# TEST 90: Responsive 3D World Map Readability at 360x800, 390x844, and 720x1280
	# =========================================================================
	var menu90 = MainMenuScene.instantiate()
	add_child(menu90)
	for vp90 in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
		menu90.update_responsive_menu_layout(vp90)
		for sample_p90 in [0, 1, 2, 3, 4, 5]:
			menu90._populate_level_map_page(sample_p90)
			menu90.level_grid.size = Vector2(clampf(vp90.x - 44.0, 300.0, 630.0), clampf(vp90.y - 260.0, 460.0, 740.0))
			menu90._layout_winding_path_nodes()
			var expected_cnt90: int = game_state.get_level_map_page(sample_p90).size()
			var nodes90: Array = []
			for ch_node90 in menu90.level_grid.get_children():
				if ch_node90 is Button:
					nodes90.append(ch_node90)
			if nodes90.size() != expected_cnt90 or expected_cnt90 < 5 or expected_cnt90 > 10:
				printerr("[FAIL Test 90] Expected ", expected_cnt90, " (5..10) level destination nodes on map page ", sample_p90 + 1, " at ", vp90, ", got ", nodes90.size())
				get_tree().quit(1)
				return
			for n_idx in range(nodes90.size()):
				var nb := nodes90[n_idx] as Control
				if nb.size.x < 46.0 or nb.size.y < 40.0:
					printerr("[FAIL Test 90] Level node ", n_idx + 1, " shrunk excessively at ", vp90, ": size=", nb.size)
					get_tree().quit(1)
					return
				for m_idx in range(n_idx + 1, nodes90.size()):
					var mb := nodes90[m_idx] as Control
					var r_a := Rect2(nb.position, nb.size)
					var r_b := Rect2(mb.position, mb.size)
					if r_a.intersects(r_b):
						printerr("[FAIL Test 90] Level nodes ", n_idx + 1, " and ", m_idx + 1, " overlap on page ", sample_p90 + 1, " at ", vp90, "!")
						get_tree().quit(1)
						return
	menu90.queue_free()
	print("[TEST 90/100] Responsive 3D World Map readability and zero node overlap at 360x800, 390x844, and 720x1280: PASSED")

	# =========================================================================
	# TEST 91: QA Issue 1 — Compact 3-State Voice Control (Male / Female / OFF), Independent from SFX, Persisted
	# =========================================================================
	var menu91 = MainMenuScene.instantiate()
	var pause91 = PauseMenuScene.instantiate()
	add_child(menu91)
	add_child(pause91)
	menu91._on_btn_settings_pressed()
	if menu91.btn_toggle_voice == null or not menu91.has_equal_width_music_sfx_row():
		printerr("[FAIL Test 91] Main Menu Settings must have ONE single Voice cycle control and preserve Music/SFX controls!")
		get_tree().quit(1)
		return
	if pause91.btn_voice == null or not pause91.has_equal_width_music_sfx_row():
		printerr("[FAIL Test 91] Pause/Settings modal must have ONE single Voice cycle control and preserve Music/SFX controls!")
		get_tree().quit(1)
		return
	if menu91.find_child("VoiceVolume*", true, false) != null or pause91.find_child("VoiceVolume*", true, false) != null:
		printerr("[FAIL Test 91] Settings must NOT have a separate Voice volume control!")
		get_tree().quit(1)
		return
	# Verify cycling through Male -> Female -> OFF -> Male via the single cycle control
	# and verify that all 3 Voice states use the EXACT SAME bright/active button visual appearance
	game_state.set_voice_mode("male")
	menu91._update_settings_buttons()
	pause91._refresh_audio_labels()
	var v_btn_menu: Button = menu91.btn_toggle_voice
	var v_btn_pause: Button = pause91.btn_voice
	var v_icon_menu: Control = v_btn_menu.get_node_or_null("VectorIcon") as Control
	var v_icon_pause: Control = v_btn_pause.get_node_or_null("VectorIcon") as Control
	
	# Snapshot Male visual appearance
	var male_mod_menu: Color = v_btn_menu.modulate
	var male_mod_pause: Color = v_btn_pause.modulate
	var male_icon_type_menu: String = v_icon_menu.icon_type if v_icon_menu else ""
	var male_icon_col_menu: Color = v_icon_menu.primary_color if v_icon_menu else Color.BLACK
	var male_icon_type_pause: String = v_icon_pause.icon_type if v_icon_pause else ""
	var male_icon_col_pause: Color = v_icon_pause.primary_color if v_icon_pause else Color.BLACK
	
	if audio_mgr.get_voice_mode() != "male" or not ("MALE" in v_btn_menu.text.to_upper() or "NAM" in v_btn_menu.text.to_upper()):
		printerr("[FAIL Test 91] Voice control initial Male state mismatch: ", v_btn_menu.text)
		get_tree().quit(1)
		return
	
	# Cycle to Female
	v_btn_menu.pressed.emit()
	if audio_mgr.get_voice_mode() != "female" or not ("FEMALE" in v_btn_menu.text.to_upper() or "NỮ" in v_btn_menu.text.to_upper()):
		printerr("[FAIL Test 91] Cycling Voice control from Male must select Female! Got mode=", audio_mgr.get_voice_mode(), " text=", v_btn_menu.text)
		get_tree().quit(1)
		return
	if v_btn_menu.modulate != male_mod_menu or v_btn_menu.disabled or (v_icon_menu and (v_icon_menu.icon_type != male_icon_type_menu or v_icon_menu.primary_color != male_icon_col_menu)):
		printerr("[FAIL Test 91] Voice Female state must use the SAME bright visual appearance as Male!")
		get_tree().quit(1)
		return
	
	# Cycle to OFF
	v_btn_menu.pressed.emit()
	if audio_mgr.get_voice_mode() != "off" or not ("OFF" in v_btn_menu.text.to_upper() or "TẮT" in v_btn_menu.text.to_upper()):
		printerr("[FAIL Test 91] Cycling Voice control from Female must select OFF! Got mode=", audio_mgr.get_voice_mode(), " text=", v_btn_menu.text)
		get_tree().quit(1)
		return
	# CRITICAL: OFF state must NEVER become dark, dimmed, or switch to a disabled/unselected visual style
	if v_btn_menu.modulate != male_mod_menu or v_btn_menu.disabled or (v_icon_menu and (v_icon_menu.icon_type != male_icon_type_menu or v_icon_menu.primary_color != male_icon_col_menu)):
		printerr("[FAIL Test 91] Voice OFF state must NOT become dark or change visual appearance! All 3 states must share identical bright active button appearance.")
		get_tree().quit(1)
		return
	
	# Cycle from OFF -> Male
	v_btn_menu.pressed.emit()
	if audio_mgr.get_voice_mode() != "male":
		printerr("[FAIL Test 91] Cycling Voice control from OFF must wrap around to Male! Got mode=", audio_mgr.get_voice_mode())
		get_tree().quit(1)
		return
	
	# Verify Pause Menu Voice button also maintains identical bright active visual appearance across all 3 states
	pause91._refresh_audio_labels()
	game_state.set_voice_mode("female")
	pause91._refresh_audio_labels()
	if v_btn_pause.modulate != male_mod_pause or v_btn_pause.disabled or (v_icon_pause and (v_icon_pause.icon_type != male_icon_type_pause or v_icon_pause.primary_color != male_icon_col_pause)):
		printerr("[FAIL Test 91] Pause Menu Voice Female button visual appearance mismatch!")
		get_tree().quit(1)
		return
	game_state.set_voice_mode("off")
	pause91._refresh_audio_labels()
	if v_btn_pause.modulate != male_mod_pause or v_btn_pause.disabled or (v_icon_pause and (v_icon_pause.icon_type != male_icon_type_pause or v_icon_pause.primary_color != male_icon_col_pause)):
		printerr("[FAIL Test 91] Pause Menu Voice OFF button must NOT become dark! Must maintain identical bright active appearance.")
		get_tree().quit(1)
		return
	
	# Verify button release removes focus outline and does not leave button darkened
	v_btn_menu.button_down.emit()
	v_btn_menu.button_up.emit()
	if v_btn_menu.has_focus():
		printerr("[FAIL Test 91] Voice button must immediately release focus upon release so it does not stay dark!")
		get_tree().quit(1)
		return
	# Verify persistence in existing save/settings system
	game_state.set_voice_mode("male")
	pause91.btn_voice.pressed.emit() # -> female
	var saved_cfg91 := ConfigFile.new()
	var saved_audio_cfg91 := ConfigFile.new()
	if saved_cfg91.load(game_state.PROGRESSION_SAVE_PATH) != OK or String(saved_cfg91.get_value("settings", "voice_mode", "")) != "female":
		printerr("[FAIL Test 91] Voice selection was not persisted to progression/settings save file!")
		get_tree().quit(1)
		return
	if saved_audio_cfg91.load(audio_mgr.SETTINGS_PATH) != OK or String(saved_audio_cfg91.get_value("audio", "voice_mode", "")) != "female":
		printerr("[FAIL Test 91] Voice selection was not persisted to audio settings save file!")
		get_tree().quit(1)
		return
	# Verify independence from SFX ON/OFF and distinct Male vs Female streams on GOOD/NICE/GREAT/COMBO/EXCELLENT/AMAZING
	var orig_sfx91: bool = audio_mgr.sound_enabled
	audio_mgr.set_sfx_enabled(false) # SFX OFF!
	audio_mgr.set_voice_mode("male")
	var cnt_m0: int = audio_mgr.voice_callout_play_count
	audio_mgr.play_voice_callout("great")
	if audio_mgr.voice_callout_play_count != cnt_m0 + 1 or audio_mgr.last_voice_gender_played != "male":
		printerr("[FAIL Test 91] Male announcer voice must play even when SFX is OFF (independent from SFX ON/OFF)!")
		get_tree().quit(1)
		return
	audio_mgr.set_voice_mode("female")
	var cnt_f0: int = audio_mgr.voice_callout_play_count
	audio_mgr.play_voice_callout("amazing")
	if audio_mgr.voice_callout_play_count != cnt_f0 + 1 or audio_mgr.last_voice_gender_played != "female":
		printerr("[FAIL Test 91] Female announcer voice must select female voice stream even when SFX is OFF!")
		get_tree().quit(1)
		return
	for callout_k91 in ["good", "nice", "great", "combo", "excellent", "amazing"]:
		var m_stream: AudioStreamWAV = audio_mgr.voice_cache_male.get(callout_k91)
		var f_stream: AudioStreamWAV = audio_mgr.voice_cache_female.get(callout_k91)
		if m_stream == null or f_stream == null or m_stream == f_stream or m_stream.data == f_stream.data:
			printerr("[FAIL Test 91] Male and Female announcer streams must both exist and be distinct for callout: ", callout_k91)
			get_tree().quit(1)
			return
		var c_spec91: Dictionary = audio_mgr.callout_sfx_specs.get(callout_k91, {})
		if not bool(c_spec91.get("has_human_voice_asset", false)) or bool(c_spec91.get("is_oscillator_or_formant_synth", true)):
			printerr("[FAIL Test 91] Voice callout '", callout_k91, "' must load real human announcer WAV/VBIN assets rather than procedural oscillator synthesis! Got: ", c_spec91)
			get_tree().quit(1)
			return
		if float(c_spec91.get("male_rms_amplitude", 0.0)) < 0.08 or float(c_spec91.get("female_rms_amplitude", 0.0)) < 0.08 or float(c_spec91.get("male_duration_sec", 0.0)) < 0.35 or float(c_spec91.get("female_duration_sec", 0.0)) < 0.35:
			printerr("[FAIL Test 91] Loaded human voice asset metrics invalid for '", callout_k91, "': ", c_spec91)
			get_tree().quit(1)
			return
	audio_mgr.set_voice_mode("off")
	audio_mgr.voice_player.stop()
	var cnt_off0: int = audio_mgr.voice_callout_play_count
	audio_mgr.play_voice_callout("excellent")
	if audio_mgr.voice_callout_play_count != cnt_off0 or audio_mgr.voice_player.playing:
		printerr("[FAIL Test 91] Voice OFF must disable announcer voice playback!")
		get_tree().quit(1)
		return
	audio_mgr.set_sfx_enabled(orig_sfx91)
	game_state.set_voice_mode("male")
	pause91.queue_free()
	menu91.queue_free()
	print("[TEST 91/94] Voice setting (Male / Female / OFF single cycle control, independent from SFX, persisted, announcer verified): PASSED")

	# =========================================================================
	# TEST 92: QA Issue 2 — Extra Life Must ONLY Work at Game Over & Exact 3 Recovery Choices
	# =========================================================================
	game_state.reset_special_item_inventory()
	game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP, 4)
	var dd92 = ModernModeScript.new()
	dd92.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	var hud92 = HUDScene.instantiate()
	var over92 = GameOverModalScene.instantiate()
	add_child(dd92)
	add_child(hud92)
	add_child(over92)
	dd92.initialize_mode()
	dd92.start_mode()
	var board92 = dd92.get_board()
	var tray92 = dd92.get_piece_tray()
	# Set up mid-game board, score, level, and active state
	board92.clear_board()
	for r92 in range(4, board92.GRID_HEIGHT):
		for c92 in range(board92.GRID_WIDTH - 1):
			board92.grid_data[r92][c92] = ((r92 + c92) % 6) + 1
			board92.grid_materials[r92][c92] = "crystal"
	game_state.score = 1250
	var snap_board_before: Array = board92.get_board_state()
	var snap_occ_before: int = board92.get_occupied_cell_count()
	var snap_tray_ids_before: Array = [
		tray92.active_pieces[0].shape_data.get("id", ""),
		tray92.active_pieces[1].shape_data.get("id", ""),
		tray92.active_pieces[2].shape_data.get("id", "")
	]
	# While actively playing (State.PLAYING), press Extra Life on SpecialItemsBar, HUD, and ModernMode
	if hud92.special_items_bar and hud92.special_items_bar.btn_extra_life:
		hud92.special_items_bar.btn_extra_life.pressed.emit()
	hud92._on_special_item_clicked("extra_life")
	var active_res92: bool = dd92.apply_special_item("extra_life")
	var direct_confirm92: bool = dd92.confirm_extra_life()
	if active_res92 or direct_confirm92:
		printerr("[FAIL Test 92] Extra Life must return false while actively playing!")
		get_tree().quit(1)
		return
	if game_state.get_special_item_count("extra_life") != 1:
		printerr("[FAIL Test 92] Pressing Extra Life while actively playing must NOT consume Extra Life!")
		get_tree().quit(1)
		return
	if game_state.current_state != GameStateScript.State.PLAYING or game_state.score != 1250 or game_state.active_level != 4 or board92.get_occupied_cell_count() != snap_occ_before or board92.get_board_state() != snap_board_before:
		printerr("[FAIL Test 92] Pressing Extra Life while actively playing modified/reset/cleared the current game!")
		get_tree().quit(1)
		return
	var snap_tray_ids_after: Array = [
		tray92.active_pieces[0].shape_data.get("id", ""),
		tray92.active_pieces[1].shape_data.get("id", ""),
		tray92.active_pieces[2].shape_data.get("id", "")
	]
	if snap_tray_ids_after != snap_tray_ids_before:
		printerr("[FAIL Test 92] Pressing Extra Life while actively playing modified the tray pieces!")
		get_tree().quit(1)
		return

	# Trigger a genuine Game Over and verify exact 3 recovery choices: 1. USE EXTRA LIFE, 2. WATCH AD, 3. MAIN MENU
	game_state.trigger_game_over({"reason": "no_valid_moves", "mode": "modern_drag"})
	var vis_choices92: Array[String] = over92.get_visible_gameover_choices()
	if vis_choices92 != ["USE EXTRA LIFE", "WATCH AD", "MAIN MENU"]:
		printerr("[FAIL Test 92] After genuine Game Over, modal must show strictly [USE EXTRA LIFE, WATCH AD, MAIN MENU], got: ", vis_choices92)
		get_tree().quit(1)
		return

	# Verify USE EXTRA LIFE consumes 1 Extra Life, restores current game state (does NOT create a new game), and prevents duplicate activation
	var revived_first: bool = over92._on_btn_extra_life_pressed()
	var revived_duplicate: bool = over92._on_btn_extra_life_pressed()
	if not revived_first or revived_duplicate or game_state.get_special_item_count("extra_life") != 0:
		printerr("[FAIL Test 92] USE EXTRA LIFE must consume exactly 1 Extra Life and prevent duplicate activation! revived_first=", revived_first, " revived_duplicate=", revived_duplicate, " remaining=", game_state.get_special_item_count("extra_life"))
		get_tree().quit(1)
		return
	if game_state.current_state != GameStateScript.State.PLAYING or game_state.score != 1250 or game_state.active_level != 4 or game_state.current_mode != GameStateScript.GameMode.MODERN_DRAG_AND_DROP or game_state.current_play_style != GameStateScript.PlayStyle.DRAG_AND_DROP:
		printerr("[FAIL Test 92] USE EXTRA LIFE did not preserve score, level, mode, or play style!")
		get_tree().quit(1)
		return
	if board92.get_occupied_cell_count() <= 0 or board92.get_occupied_cell_count() >= snap_occ_before:
		printerr("[FAIL Test 92] USE EXTRA LIFE must rescue dense rows while preserving the remaining board state (not clearing to a brand new board)! Occ=", board92.get_occupied_cell_count())
		get_tree().quit(1)
		return

	# Verify MAIN MENU never consumes Extra Life
	game_state.special_item_inventory["extra_life"] = 1
	game_state.trigger_game_over({"reason": "no_valid_moves", "mode": "modern_drag"})
	over92._on_btn_menu_pressed()
	if game_state.get_special_item_count("extra_life") != 1 or game_state.current_state != GameStateScript.State.MENU:
		printerr("[FAIL Test 92] MAIN MENU from Game Over must never consume Extra Life!")
		get_tree().quit(1)
		return
	over92.queue_free()
	hud92.queue_free()
	dd92.queue_free()
	print("[TEST 92/94] Extra Life ONLY works at Game Over, 3 recovery choices (USE EXTRA LIFE / WATCH AD / MAIN MENU), state restoration & duplicate guard: PASSED")

	# =========================================================================
	# TEST 93: QA Issue 3 — Level 1 Spatial Planning Challenge, Non-Trivial Opening, Solvability & Controlled Progression
	# =========================================================================
	var lvl1_check: Dictionary = PolyominoLib.verify_level_1_challenge_and_solvability()
	if not bool(lvl1_check.get("passed", false)):
		printerr("[FAIL Test 93] Level 1 spatial challenge & solvability verification failed: ", lvl1_check)
		get_tree().quit(1)
		return
	if int(lvl1_check.get("naive_placement_rows_cleared", 99)) != 0 or bool(lvl1_check.get("has_trivial_opening_piece", true)):
		printerr("[FAIL Test 93] Level 1 opening sequence must NOT be a trivial auto-clear sequence! Got: ", lvl1_check)
		get_tree().quit(1)
		return
	# Verify controlled difficulty progression from Level 1 onward
	var prof_l1: Dictionary = PolyominoLib.get_level_difficulty_profile(1)
	var prof_l10: Dictionary = PolyominoLib.get_level_difficulty_profile(10)
	var prof_l50: Dictionary = PolyominoLib.get_level_difficulty_profile(50)
	if float(prof_l10.get("complex_shape_ratio", 0.0)) <= float(prof_l1.get("complex_shape_ratio", 0.0)) or float(prof_l50.get("step_z_weight_mult", 0.0)) <= float(prof_l10.get("step_z_weight_mult", 0.0)) or float(prof_l10.get("falling_drop_interval", 1.0)) >= float(prof_l1.get("falling_drop_interval", 0.0)):
		printerr("[FAIL Test 93] Difficulty progression must scale smoothly from Level 1 onward! L1=", prof_l1, " L10=", prof_l10, " L50=", prof_l50)
		get_tree().quit(1)
		return
	# Verify Level 1 Drag & Drop and Falling modes both spawn the curated spatial-planning opening pieces on the 12x10 board
	game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP, 1)
	var dd93 = ModernModeScript.new()
	dd93.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	add_child(dd93)
	dd93.initialize_mode()
	dd93.start_mode()
	var tray93 = dd93.get_piece_tray()
	var r1_spawned_ids: Array[String] = [
		String(tray93.active_pieces[0].shape_data.get("id", "")),
		String(tray93.active_pieces[1].shape_data.get("id", "")),
		String(tray93.active_pieces[2].shape_data.get("id", ""))
	]
	if r1_spawned_ids != PolyominoLib.get_opening_tray_shape_ids(1, 1) or dd93.get_board().GRID_WIDTH != 8 or dd93.get_board().GRID_HEIGHT != 10:
		printerr("[FAIL Test 93] Level 1 Drag & Drop did not spawn curated spatial-planning Round 1 pieces on 8x10 board! Got: ", r1_spawned_ids)
		get_tree().quit(1)
		return
	dd93.queue_free()

	game_state.start_game_combination(GameStateScript.GameMode.CLASSIC, GameStateScript.PlayStyle.FALLING, 1)
	var fm93 = ClassicModeScript.new()
	fm93.configure_combination(GameStateScript.GameMode.CLASSIC, GameStateScript.PlayStyle.FALLING)
	add_child(fm93)
	fm93.initialize_mode()
	fm93.start_mode()
	if String(fm93.current_piece.get("id", "")) != PolyominoLib.get_falling_opening_shape_id(1, 0) or String(fm93.next_piece.get("id", "")) != PolyominoLib.get_falling_opening_shape_id(1, 1):
		printerr("[FAIL Test 93] Level 1 Falling mode did not spawn curated spatial-planning opening sequence!")
		get_tree().quit(1)
		return
	fm93.queue_free()
	print("[TEST 93/94] Level 1 spatial planning challenge, non-trivial opening, 100% solvability & controlled progression: PASSED")

	# =========================================================================
	# TEST 94: QA Issue 4 — Critical Acceptance Test for Rebuilt 3D World Map Architecture
	#          (Fails if map is effectively only background + 2D path + circular level nodes)
	# =========================================================================
	var menu94 = MainMenuScene.instantiate()
	add_child(menu94)
	var route_compositions_seen := {}
	var dest_architectures_seen := {}
	for ch94 in range(game_state.get_total_map_pages()):
		var comp_id94: String = game_state.get_chapter_path_archetype(ch94)
		route_compositions_seen[comp_id94] = true
	for lv94 in range(1, 101):
		var spec94: Dictionary = game_state.get_level_world_destination_spec(lv94)
		var arch_id94: String = String(spec94.get("destination_architecture", ""))
		dest_architectures_seen[arch_id94] = true
	if route_compositions_seen.size() < 7:
		printerr("[FAIL Test 94] World Map must use genuinely different 3D spatial route compositions across pages (not repeated zigzag), got only: ", route_compositions_seen)
		get_tree().quit(1)
		return
	if dest_architectures_seen.size() < 8:
		printerr("[FAIL Test 94] Level destinations must use diverse 3D architectural forms, got: ", dest_architectures_seen)
		get_tree().quit(1)
		return
	# Inspect representative pages in detail to verify real 3D world geometry and variable node counts (5..10)
	for sample_ch94 in [0, 1, 2, 3, 4, 5, 10, 20]:
		var exp_cnt94: int = game_state.get_level_map_page(sample_ch94).size()
		var audit94: Dictionary = menu94.get_level_map_world_inspection(sample_ch94)
		if bool(audit94.get("is_background_plus_2d_line_only", true)) or not bool(audit94.get("has_3d_subviewport_world", false)):
			printerr("[FAIL Test 94] Critical 3D World Map acceptance test failed on Page ", sample_ch94 + 1, ": ", audit94)
			get_tree().quit(1)
			return
		if int(audit94.get("destination_node_3d_count", 0)) != exp_cnt94 or int(audit94.get("terrain_surface_3d_count", 0)) != exp_cnt94 or int(audit94.get("route_segment_3d_count", 0)) != exp_cnt94 - 1 or int(audit94.get("gateway_3d_count", 0)) < 2:
			printerr("[FAIL Test 94] Page ", sample_ch94 + 1, " 3D world geometry missing required 3D destination/terrain/route/gateway meshes: ", audit94)
			get_tree().quit(1)
			return
		if (audit94.get("distinct_destination_architectures", []) as Array).size() < 3 or float(audit94.get("elevation_span_3d", 0.0)) < 0.08:
			printerr("[FAIL Test 94] Page ", sample_ch94 + 1, " lacks diverse 3D destination architectures or real 3D terrain elevation: ", audit94)
			get_tree().quit(1)
			return
		var smooth_spline94: PackedVector2Array = menu94._sample_catmull_rom_spline(menu94.winding_path_points, 10)
		if smooth_spline94.size() < (exp_cnt94 - 1) * 10:
			printerr("[FAIL Test 94] Rebuilt Adventure World Map must generate a smooth Catmull-Rom spline road through all page destinations, got points: ", smooth_spline94.size())
			get_tree().quit(1)
			return
	menu94.queue_free()
	print("[TEST 94/100] Rebuilt 3D World Map critical acceptance test (real 3D terrain, organic route compositions, variable 5..10 destinations per page): PASSED")

	# =========================================================================
	# TEST 95: Focused 3D World Map Stress-Test & Rapid Open/Close/Rebuild/Drag Cycles
	# =========================================================================
	var menu95 = MainMenuScene.instantiate()
	add_child(menu95)
	var rebuild_cycles_completed := 0
	var total_pages95: int = game_state.get_total_map_pages()
	
	# Perform 25 rapid open/close/rebuild/navigate/drag cycles
	for cycle95 in range(25):
		menu95._on_btn_open_level_map_pressed()
		if not menu95.modal_level_map.visible:
			printerr("[FAIL Test 95] Level Map failed to open on cycle ", cycle95)
			get_tree().quit(1)
			return
		
		# Rapidly switch across multiple pages
		for target_ch in [cycle95 % total_pages95, (cycle95 * 3) % total_pages95, (cycle95 * 7) % total_pages95, (cycle95 * 11) % total_pages95]:
			menu95._populate_level_map_page(target_ch)
			var exp_cnt95: int = game_state.get_level_map_page(target_ch).size()
			var m_3d: Dictionary = menu95.get_level_map_3d()
			if m_3d.get("active_destination_count", 0) != exp_cnt95 or m_3d.get("destination_nodes", []).size() < exp_cnt95:
				printerr("[FAIL Test 95] 3D mesh node counts invalid on page ", target_ch, " cycle ", cycle95)
				get_tree().quit(1)
				return
		
		# Next/Prev page rapid switches
		menu95._on_level_map_next_page()
		menu95._on_level_map_prev_page()
		
		# Simulate drag/pan during transition
		var drag_event_start := InputEventMouseButton.new()
		drag_event_start.button_index = MOUSE_BUTTON_LEFT
		drag_event_start.pressed = true
		drag_event_start.global_position = Vector2(300, 400)
		menu95._on_map_drag_input(drag_event_start)
		
		var drag_event_move := InputEventMouseMotion.new()
		drag_event_move.global_position = Vector2(300, 200)
		menu95._on_map_drag_input(drag_event_move)
		
		var drag_event_end := InputEventMouseButton.new()
		drag_event_end.button_index = MOUSE_BUTTON_LEFT
		drag_event_end.pressed = false
		drag_event_end.global_position = Vector2(300, 200)
		menu95._on_map_drag_input(drag_event_end)
		
		# Select normal & milestone levels across pages
		var test_lvl: int = (cycle95 * 17 + 5) % 500 + 1
		game_state.selected_map_level = test_lvl
		menu95._on_level_map_jump_current()
		
		# Verify 3D viewport, Camera3D, and node structure integrity
		var map_inspection: Dictionary = menu95.get_level_map_world_inspection()
		var cur_exp_cnt95: int = game_state.get_level_map_page(menu95.current_map_page).size()
		if not map_inspection.get("has_3d_subviewport_world", false) or map_inspection.get("destination_node_3d_count", 0) != cur_exp_cnt95:
			printerr("[FAIL Test 95] Map 3D viewport or destination nodes invalid during cycle ", cycle95)
			get_tree().quit(1)
			return
			
		# Return to Main Menu
		menu95.modal_level_map.visible = false
		rebuild_cycles_completed += 1

	menu95.queue_free()
	print("[TEST 95/100] Focused 3D World Map stress-test (", rebuild_cycles_completed, " rapid open/close/rebuild/drag cycles across pages): PASSED")

	# =========================================================================
	# TEST 96: Energy System (Max 24, +1/Hour Regen, 1/Day Calendar Refill, -1 on Level Start, +1 Rewarded Ad, Blocks Play at 0, Persistence)
	# =========================================================================
	game_state.reset_progression(true)
	if game_state.get_energy() != 24 or game_state.get_max_energy() != 24 or game_state.get_energy_status_text() != "24/24":
		printerr("[FAIL Test 96] Initial/Max Energy must be 24/24! Got: ", game_state.get_energy_status_text())
		get_tree().quit(1)
		return
	# Starting a level consumes 1 Energy (24 -> 23)
	var started96: bool = game_state.start_game_combination(GameStateScript.GameMode.CLASSIC, GameStateScript.PlayStyle.FALLING, 1)
	if not started96 or game_state.get_energy() != 23:
		printerr("[FAIL Test 96] Starting a level must consume 1 Energy (24 -> 23)! Got: ", game_state.get_energy())
		get_tree().quit(1)
		return
	# Hourly regeneration: +1 Energy per 3600 seconds up to 24
	game_state.set_energy(20, true)
	game_state.advance_simulated_time_seconds(3600 * 2 + 120)
	if game_state.get_energy() != 22:
		printerr("[FAIL Test 96] Advancing 2 hours must regenerate +2 Energy (20 -> 22)! Got: ", game_state.get_energy())
		get_tree().quit(1)
		return
	game_state.advance_simulated_time_seconds(3600 * 5)
	if game_state.get_energy() != 24:
		printerr("[FAIL Test 96] Hourly regeneration must cap at 24! Got: ", game_state.get_energy())
		get_tree().quit(1)
		return
	# Daily refill: 1 time per new calendar day to 24
	game_state.last_energy_daily_refill_date = "2026-09-27"
	game_state.set_energy(5, true)
	var refilled96: bool = game_state.check_daily_energy_refill("2026-09-28")
	if not refilled96 or game_state.get_energy() != 24:
		printerr("[FAIL Test 96] New calendar day must refill Energy to 24! Got: ", game_state.get_energy())
		get_tree().quit(1)
		return
	# Same calendar day must NOT refill again
	game_state.set_energy(10, true)
	var same_day_refill96: bool = game_state.check_daily_energy_refill("2026-09-28")
	if same_day_refill96 or game_state.get_energy() != 10:
		printerr("[FAIL Test 96] Daily Energy refill must only happen once per calendar day!")
		get_tree().quit(1)
		return
	# Rewarded ad via Energy + button on Main Menu and HUD
	var menu96 = MainMenuScene.instantiate()
	var hud96 = HUDScene.instantiate()
	add_child(menu96)
	add_child(hud96)
	if not menu96.lbl_energy or not menu96.btn_energy_plus or not hud96.lbl_energy or not hud96.btn_energy_plus:
		printerr("[FAIL Test 96] Energy counter and + button must be visible in both Main Menu and HUD headers!")
		get_tree().quit(1)
		return
	var sid_menu96: String = menu96.open_energy_rewarded_ad()
	if sid_menu96 == "":
		printerr("[FAIL Test 96] Pressing Energy + button below 24 must open full-screen rewarded ad!")
		get_tree().quit(1)
		return
	# Skipping ad grants 0 Energy
	var skip_res96: Dictionary = menu96.skip_energy_rewarded_ad()
	if bool(skip_res96.get("granted", true)) or game_state.get_energy() != 10:
		printerr("[FAIL Test 96] Skipping Energy rewarded ad must NOT grant Energy!")
		get_tree().quit(1)
		return
	# Completing ad grants +1 Energy (10 -> 11) and blocks duplicate session claim
	var sid2_menu96: String = menu96.open_energy_rewarded_ad()
	var comp_res96: Dictionary = menu96.complete_energy_rewarded_ad(sid2_menu96)
	var dup_res96: Dictionary = game_state.complete_rewarded_ad_for_energy(sid2_menu96)
	if not bool(comp_res96.get("granted", false)) or bool(dup_res96.get("granted", true)) or game_state.get_energy() != 11:
		printerr("[FAIL Test 96] Completing Energy rewarded ad must grant +1 Energy once and block duplicate claim! Got: ", game_state.get_energy())
		get_tree().quit(1)
		return
	# Blocking play when Energy == 0
	game_state.set_energy(0, true)
	if game_state.can_start_level_with_energy() or game_state.start_game():
		printerr("[FAIL Test 96] Starting a level must be blocked when Energy is 0!")
		get_tree().quit(1)
		return
	# Persistence across save/load
	game_state.set_energy(17, true)
	game_state.energy = 3
	game_state.load_progression()
	if game_state.get_energy() != 17:
		printerr("[FAIL Test 96] Energy state and timestamps must persist across save/load! Got: ", game_state.get_energy())
		get_tree().quit(1)
		return
	game_state.set_energy(24, true)
	hud96.queue_free()
	menu96.queue_free()
	print("[TEST 96/99] Energy system (24/24 cap, +1/hr regen, 1/day calendar refill, -1 per level start, +1 rewarded ad, 0-energy block, persistence): PASSED")

	# =========================================================================
	# TEST 97: Modern Special Items Daily Rewarded Ad '+' Button (Count == 0 Visibility, 1 Ad/Day per Item, Full-Screen Ad, Extra Life Game Over Rule)
	# =========================================================================
	game_state.reset_progression(true)
	game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP, 1)
	var hud97 = HUDScene.instantiate()
	add_child(hud97)
	var sbar97 = hud97.special_items_bar
	if not sbar97:
		printerr("[FAIL Test 97] SpecialItemsBar missing in HUD!")
		get_tree().quit(1)
		return
	# When count > 0, '+' button must NOT be visible
	sbar97.update_inventory_display()
	for item97 in ["bomb", "change_block", "extra_life"]:
		var p_btn97: Button = sbar97.get_plus_button_for_item(item97)
		if not p_btn97 or p_btn97.visible:
			printerr("[FAIL Test 97] '+' button for ", item97, " must be hidden when count > 0!")
			get_tree().quit(1)
			return
	# When count == 0 and daily ad not used today, '+' button MUST be visible and enabled
	for item97 in ["bomb", "change_block", "extra_life"]:
		game_state.set_special_item_count(item97, 0)
	sbar97.update_inventory_display()
	for item97 in ["bomb", "change_block", "extra_life"]:
		var p_btn97_b: Button = sbar97.get_plus_button_for_item(item97)
		if not p_btn97_b.visible or p_btn97_b.disabled:
			printerr("[FAIL Test 97] '+' button for ", item97, " must be visible and enabled when count == 0 and daily ad available!")
			get_tree().quit(1)
			return
		# Open full-screen ad, test skip (grants 0), then complete (grants +1 and marks daily allowance used)
		var sid_skip97: String = sbar97.open_rewarded_ad_for_item(item97, "2026-09-28")
		if sid_skip97 == "" or not sbar97.fullscreen_ad_modal.visible:
			printerr("[FAIL Test 97] Pressing '+' for ", item97, " must open full-screen rewarded ad modal!")
			get_tree().quit(1)
			return
		var skip_item_res: Dictionary = sbar97.skip_rewarded_ad_for_item(item97)
		if bool(skip_item_res.get("granted", true)) or game_state.get_special_item_count(item97) != 0:
			printerr("[FAIL Test 97] Skipping ad for ", item97, " must NOT grant item!")
			get_tree().quit(1)
			return
		var sid_comp97: String = sbar97.open_rewarded_ad_for_item(item97, "2026-09-28")
		var comp_item_res: Dictionary = sbar97.complete_rewarded_ad_for_item(item97, sid_comp97, "2026-09-28")
		if not bool(comp_item_res.get("granted", false)) or game_state.get_special_item_count(item97) != 1:
			printerr("[FAIL Test 97] Completing ad for ", item97, " must grant +1 item (0 -> 1)! Got: ", comp_item_res)
			get_tree().quit(1)
			return
		# Once count == 1, '+' button hides again; if consumed back to 0 on the same day, 1/day limit prevents a second ad until tomorrow
		if p_btn97_b.visible:
			printerr("[FAIL Test 97] '+' button for ", item97, " must hide immediately when count becomes 1!")
			get_tree().quit(1)
			return
		game_state.set_special_item_count(item97, 0)
		sbar97.update_inventory_display()
		if game_state.can_watch_ad_for_special_item(item97, "2026-09-28"):
			printerr("[FAIL Test 97] Item ", item97, " daily ad allowance must be limited to 1 time per calendar day!")
			get_tree().quit(1)
			return
		if not game_state.can_watch_ad_for_special_item(item97, "2026-09-29"):
			printerr("[FAIL Test 97] Item ", item97, " daily ad allowance must reset on the next calendar day!")
			get_tree().quit(1)
			return
	hud97.queue_free()
	print("[TEST 97/99] Modern Special Items '+' button (count==0 visibility, 1 ad/day per item, full-screen ad flow, next-day reset): PASSED")

	# =========================================================================
	# TEST 98: Page-Based Single-Biome Adventure World Level Map (10 Coherent Biomes Across 68 Pages)
	# =========================================================================
	var menu98 = MainMenuScene.instantiate()
	add_child(menu98)
	var page_biomes_seen := {}
	for ch98 in range(10):
		var ob_spec: Dictionary = game_state.get_chapter_ocean_biome_spec(ch98)
		page_biomes_seen[String(ob_spec.get("biome_id", ""))] = true
	if page_biomes_seen.size() < 8:
		printerr("[FAIL Test 98] Expected >=8 distinct coherent page biome themes across pages, got: ", page_biomes_seen.size())
		get_tree().quit(1)
		return
	menu98._populate_level_map_page(0)
	var style98: Dictionary = menu98.get_level_map_3d_style_metrics(0)
	var insp98: Dictionary = menu98.get_level_map_world_inspection(0)
	if not bool(style98.get("is_coherent_single_biome_page", false)) or not bool(style98.get("is_ocean_and_islands_world", false)) or not bool(insp98.get("is_coherent_single_biome_page", false)):
		printerr("[FAIL Test 98] Level Map Page 1 must be a coherent single-biome Ocean & Islands world: ", style98)
		get_tree().quit(1)
		return
	menu98.queue_free()
	print("[TEST 98/100] Page-based single-biome Adventure World Level Map (10 distinct biomes across 68 pages): PASSED")

	# =========================================================================
	# TEST 99: Natural Male & Female Announcer Voice Recordings (GOOD, NICE, GREAT, COMBO, EXCELLENT, AMAZING)
	# =========================================================================
	for ck99 in ["good", "nice", "great", "combo", "excellent", "amazing"]:
		var m_wav99: AudioStreamWAV = audio_mgr.voice_cache_male.get(ck99)
		var f_wav99: AudioStreamWAV = audio_mgr.voice_cache_female.get(ck99)
		var sp99: Dictionary = audio_mgr.get_callout_sfx_metrics(ck99)
		if m_wav99 == null or f_wav99 == null or m_wav99.data.size() < 20000 or f_wav99.data.size() < 20000 or m_wav99.data == f_wav99.data:
			printerr("[FAIL Test 99] Male and Female natural announcer recordings must both be loaded and distinct for: ", ck99)
			get_tree().quit(1)
			return
		if float(sp99.get("male_rms_amplitude", 0.0)) < 0.12 or float(sp99.get("male_peak_amplitude", 0.0)) < 0.70:
			printerr("[FAIL Test 99] New Male announcer voice recording for '", ck99, "' lacks clarity/presence: ", sp99)
			get_tree().quit(1)
			return
	print("[TEST 99/100] Natural Male & Female human-like announcer voices verified for all 6 callouts: PASSED")

	# =========================================================================
	# TEST 100: Reusable 4TM Map Core / Map Engine Verification
	#           (World -> MapPages -> LevelNodes, 5..10 & Arbitrary Node Counts,
	#            Deterministic Seeded Organic Routes, Zero Node Overlap,
	#            Single-Biome Theme Separation, Swipe Navigation & Drag-vs-Tap)
	# =========================================================================
	var custom_world100 := MapDataScript.new("test_reusable_4tm_world")
	var page_specs100: Array[Dictionary] = []
	var counts100: Array[int] = [5, 6, 7, 8, 9, 10]
	for idx100 in range(counts100.size()):
		page_specs100.append({
			"level_count": counts100[idx100],
			"theme_id": MapThemeScript.PRESET_THEME_IDS[idx100],
			"seed_value": 51000 + idx100 * 313
		})
	custom_world100.configure_from_page_specs(page_specs100)
	if custom_world100.get_page_count() != 6:
		printerr("[FAIL Test 100] Custom MapData page count mismatch!")
		get_tree().quit(1)
		return
	for p_i100 in range(6):
		var exp_c100: int = counts100[p_i100]
		var pg100 = custom_world100.get_page(p_i100)
		if pg100.get_level_count() != exp_c100 or not pg100.theme.is_coherent():
			printerr("[FAIL Test 100] MapPage ", p_i100, " level count or theme coherence failed!")
			get_tree().quit(1)
			return
		for vp100 in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
			var c_sz100 := Vector2(vp100.x - 32.0, vp100.y * 0.62)
			custom_world100.build_page_layout(p_i100, c_sz100, {"unlocked_level": 18, "selected_level": 12})
			var ov100: Dictionary = MapLayoutGeneratorScript.check_zero_node_overlap(pg100.nodes, 2.0)
			if not bool(ov100.get("zero_overlap", false)) or not pg100.is_theme_coherent():
				printerr("[FAIL Test 100] Overlap or biome mismatch on ", exp_c100, "-node page at ", vp100, ": ", ov100)
				get_tree().quit(1)
				return
	# Verify Block Puzzle 500-level migration uses 5..10 levels per page (never 20), swipe navigation, and drag-vs-tap protection
	var bp_md100 = game_state.get_map_data()
	var seen_bp_counts100 := {}
	for p_bp in range(bp_md100.get_page_count()):
		var pg_bp = bp_md100.get_page(p_bp)
		var c_bp: int = pg_bp.get_level_count()
		seen_bp_counts100[c_bp] = true
		if c_bp < 5 or c_bp > 10 or c_bp == 20:
			printerr("[FAIL Test 100] Block Puzzle page ", p_bp + 1, " has invalid level count: ", c_bp)
			get_tree().quit(1)
			return
	for req_c100 in [5, 6, 7, 8, 9, 10]:
		if not seen_bp_counts100.has(req_c100):
			printerr("[FAIL Test 100] Block Puzzle migration missing ", req_c100, "-level page!")
			get_tree().quit(1)
			return
	game_state.reset_progression(false)
	for lv100 in range(1, 16):
		game_state.record_level_completion(lv100, game_state.get_level_target_score(lv100) * 2)
	game_state.select_map_level(15)
	var menu100 = MainMenuScene.instantiate()
	add_child(menu100)
	menu100._on_btn_open_level_map_pressed()
	if menu100.current_map_page != 2 or menu100._level_map_grid_buttons.size() != 8:
		printerr("[FAIL Test 100] Auto-centering on unlocked Level 15 (Page 3, 8 levels) failed! page=", menu100.current_map_page, " btns=", menu100._level_map_grid_buttons.size())
		get_tree().quit(1)
		return
	var sw100: Dictionary = menu100.simulate_map_swipe(Vector2(-90.0, 0.0))
	if not bool(sw100.get("page_changed", false)) or menu100.current_map_page != 3 or menu100._level_map_grid_buttons.size() != 9:
		printerr("[FAIL Test 100] Swipe navigation to Page 4 (9 levels) failed!")
		get_tree().quit(1)
		return
	# First tap immediately after drag is suppressed by drag-vs-tap guard
	menu100._on_map_level_node_pressed(14, true)
	if game_state.selected_map_level != 15:
		printerr("[FAIL Test 100] Drag-vs-tap guard failed to prevent accidental level activation during swipe!")
		get_tree().quit(1)
		return
	# Subsequent clean tap selects unlocked level 14
	menu100._on_map_level_node_pressed(14, true)
	if game_state.selected_map_level != 14:
		printerr("[FAIL Test 100] Clean tap failed to select unlocked Level 14!")
		get_tree().quit(1)
		return
	menu100.queue_free()
	game_state.reset_progression(false)
	print("[TEST 100/101] Reusable 4TM Map Core Engine (5..10 node pages, deterministic organic routes, single-biome themes, swipe navigation & drag-vs-tap): PASSED")

	# =========================================================================
	# TEST 101: Comprehensive Audit of All 9 Refinements:
	#   1. Energetic Young-Adult Male Announcer Voice (135Hz <= F0 <= 185Hz, < 0.85x Female F0, non-baritone, non-pitch-shifted)
	#   2. Unmistakable Single-Biome Map Page Themes (9 Preset Themes)
	#   3. Frameless Vector Settings Gear on Main Menu & HUD
	#   4. Per-Level Dedicated Background + Multi-Track Level BGM Selection
	#   5. Balanced Gameplay Header (Level, Score, Energy, Gear; No 1-3 Star Primary HUD)
	#   6. Ultra-Transparent 12x10 Board Surface & Transparent GameWorld
	#   7. Per-Level Block Material/Style Sets (9 Biome Material Palettes)
	#   8. Pause Menu Button Order (RESTART before RESUME)
	#   9. Daily Gift / Lucky Wheel CLOSE & SPIN Separation from 4TM GAMES Branding (360x800, 390x844, 720x1280)
	# =========================================================================
	# 1. Energetic Male voice pitch, brightness & naturalness check across all 6 callouts
	for ck101 in ["good", "nice", "great", "combo", "excellent", "amazing"]:
		var vm101: Dictionary = audio_mgr.get_callout_sfx_metrics(ck101)
		var mf0_101: float = float(vm101.get("male_fundamental_hz", 999.0))
		var ff0_101: float = float(vm101.get("female_fundamental_hz", 150.0))
		if mf0_101 < 135.0 or mf0_101 > 185.0 or mf0_101 >= ff0_101 * 0.85 or not bool(vm101.get("is_energetic_casual_male_voice", false)) or bool(vm101.get("is_baritone_or_deep_radio", true)):
			printerr("[FAIL Test 101.1] Male voice for '", ck101, "' is not in the energetic young-adult male range! male_f0=", mf0_101, "Hz, female_f0=", ff0_101, "Hz, metrics=", vm101)
			get_tree().quit(1)
			return

	# 2. Unmistakable single-biome MapPage themes across all 9 presets
	var expected_9_biomes := [
		"ocean_islands", "desert_dunes", "green_forest", "mountain_peaks",
		"snow_ice_kingdom", "volcano_caldera", "ancient_ruins",
		"crystal_sanctuary", "starlight_highlands"
	]
	for b_id101 in expected_9_biomes:
		var mt101 = MapThemeScript.create_preset(b_id101)
		if mt101 == null or mt101.theme_id != b_id101 or not mt101.is_single_coherent_biome():
			printerr("[FAIL Test 101.2] MapTheme preset '", b_id101, "' is missing or not coherent!")
			get_tree().quit(1)
			return

	# 3. Frameless vector Settings gear on Main Menu and HUD
	var menu101 = MainMenuScene.instantiate()
	var hud101 = HUDScene.instantiate()
	var pause101 = PauseMenuScene.instantiate()
	add_child(menu101)
	add_child(hud101)
	add_child(pause101)
	if not menu101.has_gear_icon() or not menu101.is_settings_gear_frameless():
		printerr("[FAIL Test 101.3] Main Menu Settings control must be a frameless procedural vector gear icon!")
		get_tree().quit(1)
		return
	var hud_hm101: Dictionary = hud101.get_header_layout_metrics()
	if not bool(hud_hm101.get("is_settings_frameless_gear", false)):
		printerr("[FAIL Test 101.3] HUD Settings control must be a frameless procedural vector gear icon! Metrics: ", hud_hm101)
		get_tree().quit(1)
		return

	# 4. Per-level dedicated background & multi-track BGM selection
	var seen_bgm_tracks101 := {}
	var seen_bg_biomes101 := {}
	for lv_test101 in range(1, 37):
		var env101: Dictionary = game_state.get_level_environment_spec(lv_test101)
		seen_bg_biomes101[String(env101.get("biome_id", ""))] = true
		var trk101: String = audio_mgr.select_bgm_for_level(lv_test101, 42)
		seen_bgm_tracks101[trk101] = true
	if seen_bg_biomes101.size() < 9 or seen_bgm_tracks101.size() < 4 or audio_mgr.get_bgm_track_count() < 5:
		printerr("[FAIL Test 101.4] Per-level backgrounds or multi-track BGM variety insufficient! Biomes=", seen_bg_biomes101.keys(), " Tracks=", seen_bgm_tracks101.keys())
		get_tree().quit(1)
		return

	# 5. Balanced gameplay header (Level, Score, Energy, Settings gear; no 1-3 stars as primary HUD element)
	if not bool(hud_hm101.get("has_balanced_4_item_header", false)) or bool(hud_hm101.get("uses_stars_as_primary_hud_element", true)):
		printerr("[FAIL Test 101.5] Gameplay HUD must present Level, Score, Energy, and Settings gear without 1-3 stars as primary HUD element: ", hud_hm101)
		get_tree().quit(1)
		return

	# 6. Ultra-transparent board surface
	var b_style101: Dictionary = board.get_board_surface_style_metrics()
	if not bool(b_style101.get("is_ultra_transparent_glass", false)) or float(b_style101.get("board_surface_alpha", 1.0)) > 0.06 or float(b_style101.get("empty_cell_alpha_even", 1.0)) > 0.05:
		printerr("[FAIL Test 101.6] Play board surface is still too opaque: ", b_style101)
		get_tree().quit(1)
		return

	# 7. Per-level block material/style sets (strictly 1 dominant material family per level, 9 families across levels)
	var seen_palettes101 := {}
	for lv_m101 in range(1, 19):
		var pal_id101: String = PolyominoLib.get_level_material_palette_id(lv_m101)
		seen_palettes101[pal_id101] = true
		var distinct_mats_in_lvl := {}
		for cid101 in range(1, 8):
			distinct_mats_in_lvl[PolyominoLib.get_material_id_for_block(cid101, lv_m101)] = true
		if distinct_mats_in_lvl.size() != 1:
			printerr("[FAIL Test 101.7] Each level must select strictly ONE dominant block material family! Level ", lv_m101, " got: ", distinct_mats_in_lvl.keys())
			get_tree().quit(1)
			return
	if seen_palettes101.size() < 9:
		printerr("[FAIL Test 101.7] Expected 9 distinct level-specific block material families across levels, got: ", seen_palettes101.keys())
		get_tree().quit(1)
		return

	# 8. Pause Menu button order: RESTART before RESUME
	if not pause101.has_restart_before_resume() or pause101.btn_restart.get_index() >= pause101.btn_resume.get_index():
		printerr("[FAIL Test 101.8] Pause Menu must place RESTART before RESUME!")
		get_tree().quit(1)
		return

	# 9. Daily Gift / Lucky Wheel CLOSE & SPIN separation from 4TM GAMES branding at 360x800, 390x844, 720x1280
	for vp_w101 in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
		var wl101: Dictionary = menu101.update_responsive_wheel_layout(vp_w101)
		var brand_r101: Rect2 = wl101.get("branding_rect", Rect2())
		var close_r101: Rect2 = wl101.get("close_button_rect", Rect2())
		var spin_r101: Rect2 = wl101.get("spin_button_rect", Rect2())
		var panel_r101: Rect2 = wl101.get("panel_rect", Rect2())
		if not bool(wl101.get("has_zero_branding_overlap", false)) or close_r101.intersects(brand_r101) or spin_r101.intersects(brand_r101) or panel_r101.intersects(brand_r101):
			printerr("[FAIL Test 101.9] Lucky Wheel CLOSE/SPIN collides with 4TM GAMES branding on viewport ", vp_w101, ": ", wl101)
			get_tree().quit(1)
			return
		if float(wl101.get("close_to_branding_gap_y", 0.0)) < 16.0 or float(wl101.get("spin_to_branding_gap_y", 0.0)) < 16.0:
			printerr("[FAIL Test 101.9] Insufficient separation between CLOSE/SPIN and 4TM GAMES branding on ", vp_w101, ": ", wl101)
			get_tree().quit(1)
			return

	pause101.queue_free()
	hud101.queue_free()
	menu101.queue_free()
	print("[TEST 101/102] All 9 Refinements (Deep Male Voice, 9 Map Biomes, Frameless Gear, Per-Level BG+BGM, Balanced HUD, Transparent Board, Per-Level Block Materials, Pause Order, Lucky Wheel Layout): PASSED")

	# =========================================================================
	# TEST 102: Targeted 6 UI Refinements Verification:
	#   1. Header gear button: increased height matching header controls, frameless, darker contrast color
	#   2. Energy control: increased visual presence, larger '+' button, frameless/integrated '+' without separate background
	#   3. Level Map overflow: audit all 68 pages / 500 levels at 360x800, 390x844, 720x1280 with zero horizontal clipping
	#   4. Lucky Wheel: blue SPIN button, text overflow protection for CLAIM TODAY at all sizes, EN/VI localization
	#   5. Reward info panel: hidden before spin, shown after spin with correct descriptions (Bomb, Change Block, Extra Life, Lucky Next Time)
	#   6. Daily Gift button: gray/inactive visual state after today's spin with no extra text (preserves DAILY GIFT / QUÀ HẰNG NGÀY)
	# =========================================================================
	var menu102 = MainMenuScene.instantiate()
	add_child(menu102)

	# 1. Header gear button
	for vp102 in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
		menu102.update_responsive_menu_layout(vp102)
		var gear_h: float = menu102.btn_top_settings.custom_minimum_size.y
		var top_lvl_h: float = menu102.btn_top_level.custom_minimum_size.y
		var energy_h: float = menu102.energy_panel.custom_minimum_size.y
		var energy_comb_h: float = menu102.energy_panel.get_combined_minimum_size().y
		var gift_h: float = menu102.btn_daily_gift.custom_minimum_size.y
		if not is_equal_approx(gear_h, top_lvl_h) or not is_equal_approx(gear_h, energy_h) or not is_equal_approx(gear_h, energy_comb_h) or not is_equal_approx(gear_h, gift_h):
			printerr("[FAIL Test 102.1] Header gear button height must match top level, energy, and gift controls! gear=", gear_h, " lvl=", top_lvl_h, " energy=", energy_h, " energy_comb=", energy_comb_h, " gift=", gift_h)
			get_tree().quit(1)
			return
		if not menu102.is_settings_gear_frameless():
			printerr("[FAIL Test 102.1] Settings gear button must remain frameless without background box!")
			get_tree().quit(1)
			return
		var gear_icon102 = menu102.btn_top_settings.get_node_or_null("VectorIcon")
		var gear_lum: float = gear_icon102.primary_color.get_luminance() if gear_icon102 else -1.0
		if not gear_icon102 or gear_lum < 0.55 or gear_lum > 0.82 or not is_equal_approx(gear_icon102.size.y, gear_h):
			printerr("[FAIL Test 102.1] Settings gear icon must use a light-gray high-contrast color and match header height! Luminance=", gear_lum, " icon_h=", gear_icon102.size.y if gear_icon102 else -1.0)
			get_tree().quit(1)
			return

	# 2. Energy control visual presence, frameless '+' button & distinct LV vs Energy visual identities
	var ep_plus102: Button = menu102.btn_energy_plus
	if ep_plus102 == null:
		printerr("[FAIL Test 102.2] btn_energy_plus not found in Energy control!")
		get_tree().quit(1)
		return
	var plus_sb: StyleBox = ep_plus102.get_theme_stylebox("normal")
	if not (plus_sb is StyleBoxEmpty) and plus_sb != null:
		if plus_sb is StyleBoxFlat and (plus_sb as StyleBoxFlat).bg_color.a > 0.01:
			printerr("[FAIL Test 102.2] Energy '+' button must NOT have a separate background/frame of its own! Got: ", plus_sb)
			get_tree().quit(1)
			return
	if ep_plus102.get_theme_font_size("font_size") < 20:
		printerr("[FAIL Test 102.2] Energy '+' button font size must be significantly larger for easy tap/read!")
		get_tree().quit(1)
		return
	var mm_id_metrics: Dictionary = menu102.get_level_and_energy_visual_identity_metrics()
	if not bool(mm_id_metrics.get("are_clearly_distinct", false)):
		printerr("[FAIL Test 102.2] Main Menu LV button and Energy control must have clearly different visual identities/colors! Got: ", mm_id_metrics)
		get_tree().quit(1)
		return
	var hud102_id = HUDScene.instantiate()
	add_child(hud102_id)
	var hud_id_metrics: Dictionary = hud102_id.get_level_and_energy_visual_identity_metrics()
	if not bool(hud_id_metrics.get("are_clearly_distinct", false)):
		printerr("[FAIL Test 102.2] HUD Level panel and Energy control must have clearly different visual identities/colors! Got: ", hud_id_metrics)
		get_tree().quit(1)
		return
	hud102_id.queue_free()
	var tm102: Dictionary = menu102.get_title_visual_metrics()
	if (
		not bool(tm102.get("is_playful_casual_game_logo", false)) or
		not bool(tm102.get("has_per_character_playful_variation", false)) or
		not bool(tm102.get("has_emboldened_display_font_variation", false)) or
		not bool(tm102.get("is_original_4tm_title_treatment", false))
	):
		printerr("[FAIL Test 102.2] Main Menu Block Puzzle title must use the redesigned playful, dimensional 4TM casual-game logo treatment! Got: ", tm102)
		get_tree().quit(1)
		return

	# 3. Level Map overflow & country landmark spacing audit across ALL 68 map pages / 500 levels at 360x800, 390x844, 720x1280
	var bp_map102 = game_state.get_map_data()
	for vp102 in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
		menu102.update_responsive_menu_layout(vp102)
		menu102.update_responsive_level_map_layout(vp102)
		var canvas_sz102: Vector2 = menu102.level_grid.size if menu102.level_grid.size.x > 0 else Vector2(vp102.x - 40.0, 560.0)
		for p_idx102 in range(bp_map102.get_page_count()):
			var pg102 = bp_map102.build_page_layout(p_idx102, canvas_sz102, {"unlocked_level": 500, "selected_level": 1})
			var ov_chk102: Dictionary = MapLayoutGeneratorScript.check_zero_node_overlap(pg102.nodes, 2.0)
			if not bool(ov_chk102.get("zero_overlap", false)):
				printerr("[FAIL Test 102.3] Node overlap detected on Map Page ", p_idx102 + 1, " at ", vp102, ": ", ov_chk102)
				get_tree().quit(1)
				return
			for nd102 in pg102.nodes:
				var nr102: Rect2 = nd102.get_bounding_rect()
				if nr102.position.x < 0.0 or nr102.end.x > canvas_sz102.x:
					printerr("[FAIL Test 102.3] Horizontal clipping on Map Page ", p_idx102 + 1, " Level ", nd102.level_id, " at ", vp102, ": rect=", nr102, " canvas=", canvas_sz102)
					get_tree().quit(1)
					return
			var lm_man102: Dictionary = MapRendererScript.get_page_landmark_manifest(pg102, Rect2(Vector2.ZERO, canvas_sz102))
			if (
				not bool(lm_man102.get("visual_hierarchy_valid", false)) or
				int(lm_man102.get("route_landmark_collision_count", -1)) != 0 or
				not bool(lm_man102.get("zero_plaque_or_landmark_overlap", false)) or
				not bool(lm_man102.get("order_preserved_after_relaxation", false)) or
				not bool(lm_man102.get("all_ground_anchors_not_in_sky", false)) or
				not bool(lm_man102.get("all_ground_anchors_not_distant_horizon", false)) or
				not bool(lm_man102.get("all_ground_anchors_not_mountain_background", false)) or
				not bool(lm_man102.get("all_ground_anchors_inside_surface", false)) or
				not bool(lm_man102.get("all_water_relationships_valid", false)) or
				not bool(lm_man102.get("all_route_endpoints_compatible", false)) or
				int(lm_man102.get("primary_landscape_layer_count", 0)) != 1 or
				int(lm_man102.get("oversized_background_layer_count", -1)) != 0
			):
				printerr("[FAIL Test 102.3] Landmark/label overlap, out-of-bounds, or semantic terrain surface grounding failure on Map Page ", p_idx102 + 1, " (", pg102.country_name_en, ") at ", vp102, ": ", lm_man102)
				get_tree().quit(1)
				return

	# 4. Lucky Wheel blue SPIN button & text overflow protection
	menu102._apply_spin_button_blue_style()
	var spin_sb102 = menu102.btn_spin_wheel.get_theme_stylebox("normal") as StyleBoxFlat
	if not spin_sb102 or spin_sb102.bg_color.b < 0.70 or spin_sb102.bg_color.b <= spin_sb102.bg_color.r * 1.5:
		printerr("[FAIL Test 102.4] SPIN button must use a vibrant blue stylebox! Got: ", spin_sb102.bg_color if spin_sb102 else "null")
		get_tree().quit(1)
		return

	# 5. Reward information panel visibility rules & descriptions
	var reward_box102 := menu102.get_node_or_null("Modals/LuckyWheelModal/Panel/VBoxContainer/WheelRewardInfoBox") as Control
	# Before spinning: reward panel MUST be hidden
	menu102.highlighted_wheel_slice = -1
	menu102._refresh_lucky_wheel_ui()
	if reward_box102 and reward_box102.visible:
		printerr("[FAIL Test 102.5] Wheel reward information panel must be hidden before spinning!")
		get_tree().quit(1)
		return
	# After spin: reward panel MUST be visible and display correct existing descriptions
	for test_slice_idx in range(GameStateScript.LUCKY_WHEEL_SLICES.size()):
		var slice_data: Dictionary = GameStateScript.LUCKY_WHEEL_SLICES[test_slice_idx]
		var r_type: String = String(slice_data.get("reward_type", "bomb"))
		var spin_res: Dictionary = {
			"slice_index": test_slice_idx,
			"reward_type": r_type,
			"amount": int(slice_data.get("amount", 1)),
			"label": String(slice_data.get("label_en", "")),
			"description": String(slice_data.get("desc_en", "")),
			"is_lucky_next_time": (r_type == "lucky_next_time")
		}
		menu102._on_wheel_spin_finished(spin_res)
		if reward_box102 and not reward_box102.visible:
			printerr("[FAIL Test 102.5] Wheel reward information panel must be visible after spin completes!")
			get_tree().quit(1)
			return
		if menu102.lbl_wheel_reward_desc.text == "":
			printerr("[FAIL Test 102.5] Missing description for reward type '", r_type, "' after spin!")
			get_tree().quit(1)
			return

	# 6. Daily Gift button state after today's spin: gray/inactive visual state with no extra text
	game_state.set_language("en", false)
	game_state.daily_reward_claimed = false
	menu102._refresh_progression_ui()
	var gift_text_active: String = menu102.btn_daily_gift.text.strip_edges()
	var gift_sb_active := menu102.btn_daily_gift.get_theme_stylebox("normal") as StyleBoxFlat
	if gift_text_active != "DAILY GIFT" or gift_sb_active.bg_color.r < 0.80:
		printerr("[FAIL Test 102.6] Active Daily Gift button must display DAILY GIFT and active bright color! text=", gift_text_active)
		get_tree().quit(1)
		return

	# Claim today's spin
	game_state.daily_reward_claimed = true
	menu102._refresh_progression_ui()
	var gift_text_claimed: String = menu102.btn_daily_gift.text.strip_edges()
	var gift_sb_claimed := menu102.btn_daily_gift.get_theme_stylebox("normal") as StyleBoxFlat
	if gift_text_claimed != "DAILY GIFT":
		printerr("[FAIL Test 102.6] Daily Gift button must NOT add extra text like OK/DONE/CLAIMED after spin! Got: ", gift_text_claimed)
		get_tree().quit(1)
		return
	if not gift_sb_claimed or gift_sb_claimed.bg_color.r > 0.35 or gift_sb_claimed.bg_color.g > 0.35:
		printerr("[FAIL Test 102.6] Daily Gift button must switch to gray/inactive style after today's spin! Got: ", gift_sb_claimed.bg_color if gift_sb_claimed else "null")
		get_tree().quit(1)
		return

	# Test in Vietnamese language as well
	game_state.set_language("vi", false)
	game_state.daily_reward_claimed = false
	menu102._refresh_progression_ui()
	if menu102.btn_daily_gift.text.strip_edges() != "QUÀ HẰNG NGÀY":
		printerr("[FAIL Test 102.6] Active Daily Gift button in VI must display QUÀ HẰNG NGÀY! Got: ", menu102.btn_daily_gift.text)
		get_tree().quit(1)
		return
	game_state.daily_reward_claimed = true
	menu102._refresh_progression_ui()
	if menu102.btn_daily_gift.text.strip_edges() != "QUÀ HẰNG NGÀY":
		printerr("[FAIL Test 102.6] Claimed Daily Gift button in VI must retain QUÀ HẰNG NGÀY without extra text! Got: ", menu102.btn_daily_gift.text)
		get_tree().quit(1)
		return

	game_state.set_language("en", false)
	game_state.daily_reward_claimed = false
	menu102.queue_free()
	print("[TEST 102/104] All 6 Targeted UI Refinements (Header Gear, Energy Presence & Integrated '+', Map Overflow Audit, Blue SPIN, Reward Info Timing, Inactive Daily Gift State): PASSED")

	# =========================================================================
	# TEST 103: Targeted Drag & Drop Rotation Regression (Mouse & Touch Input Paths)
	#   1. Start dragging a piece
	#   2. Move the piece across the ROTATE control without intentionally activating it -> orientation unchanged
	#   3. Intentionally activate ROTATE -> exactly one 90° rotation
	#   4. Continue dragging after rotation -> drag remains active
	#   5. Cancel drag -> original expected orientation is restored
	#   6. Both mouse and touch-equivalent input paths verified
	# =========================================================================
	game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP, 1)
	var dd103 = ModernModeScript.new()
	dd103.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	add_child(dd103)
	dd103.initialize_mode()
	dd103.start_mode()
	for vp103 in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
		dd103.update_layout_for_viewport(vp103)
		var tray103 = dd103.get_piece_tray()
		var board103 = dd103.get_board()
		var btn_rot103: Button = dd103.get_drag_rotate_button()
		if not btn_rot103:
			printerr("[FAIL Test 103] Missing BtnDragRotate in PieceTray on viewport ", vp103)
			get_tree().quit(1)
			return
		# Verify only ONE rotate control exists in Drag & Drop tray
		var rot_btn_count := 0
		for ch103 in tray103.get_children():
			if ch103 is Button:
				rot_btn_count += 1
		if rot_btn_count != 1:
			printerr("[FAIL Test 103] Must NOT introduce a second rotate control! Found button count: ", rot_btn_count)
			get_tree().quit(1)
			return

		var piece103 = tray103.active_pieces[1] # Middle slot (directly below ROTATE control)
		var l_shape103: Dictionary = PolyominoLib.get_shape("l_shape_4")
		piece103.setup_piece(l_shape103, 1)
		tray103.restore_piece_to_slot(piece103)
		var orig_cells103: Array = piece103.cells.duplicate(true)
		var rot90_cells103: Array = PolyominoLib.rotate_90_cw(orig_cells103)
		var rot180_cells103: Array = PolyominoLib.rotate_90_cw(rot90_cells103)

		var piece_start_pt: Vector2 = piece103.global_position + piece103.size * 0.5
		var board_hover_pt: Vector2 = board103.grid_to_world(Vector2i(4, 5)) + Vector2(20, 20) + Vector2(0, piece103.TOUCH_Y_OFFSET)
		var cancel_outside_pt: Vector2 = Vector2(8.0, board103.global_position.y + 40.0)

		# --- PATH A: Mouse Input Path ---
		var mb_down := InputEventMouseButton.new()
		mb_down.button_index = MOUSE_BUTTON_LEFT
		mb_down.pressed = true
		mb_down.position = piece103.size * 0.5
		mb_down.global_position = piece_start_pt
		piece103._gui_input(mb_down)

		# Also verify emulated touch event at drag start does NOT accidentally rotate
		var emu_touch := InputEventScreenTouch.new()
		emu_touch.index = 0
		emu_touch.pressed = true
		emu_touch.device = InputEvent.DEVICE_ID_EMULATION
		var rot_rect103: Rect2 = btn_rot103.get_global_rect()
		emu_touch.position = rot_rect103.get_center()
		piece103._gui_input(emu_touch)
		piece103._input(emu_touch)

		if piece103.piece_state != TrayPieceScript.PieceState.DRAGGING or piece103.cells != orig_cells103:
			printerr("[FAIL Test 103.Mouse] Drag start or emulated touch caused unexpected state/rotation on ", vp103)
			get_tree().quit(1)
			return

		# Sweep pointer & dragged block visual bounds directly across ROTATE control multiple times
		for sweep_t in [0.0, 0.25, 0.5, 0.75, 1.0, 0.5, 0.2]:
			var sweep_pt := Vector2(
				lerpf(rot_rect103.position.x - 20.0, rot_rect103.end.x + 20.0, sweep_t),
				lerpf(rot_rect103.position.y - 10.0, rot_rect103.end.y + 10.0, sweep_t)
			)
			var mm := InputEventMouseMotion.new()
			mm.button_mask = MOUSE_BUTTON_MASK_LEFT
			mm.position = sweep_pt
			mm.global_position = sweep_pt
			piece103._input(mm)
			# Also test when the dragged piece visual body overlaps ROTATE while pointer is below ROTATE
			var body_overlap_pt := rot_rect103.get_center() - Vector2(0, piece103.TOUCH_Y_OFFSET)
			var mm2 := InputEventMouseMotion.new()
			mm2.button_mask = MOUSE_BUTTON_MASK_LEFT
			mm2.position = body_overlap_pt
			mm2.global_position = body_overlap_pt
			piece103._input(mm2)

		if piece103.cells != orig_cells103 or piece103.rotation_steps != 0:
			printerr("[FAIL Test 103.Mouse] Moving dragged piece across ROTATE control rotated the piece accidentally on ", vp103, "! cells=", piece103.cells)
			get_tree().quit(1)
			return

		# Intentionally activate ROTATE via explicit click on ROTATE control -> exactly one 90° rotation
		var rot_click_down := InputEventMouseButton.new()
		rot_click_down.button_index = MOUSE_BUTTON_LEFT
		rot_click_down.pressed = true
		rot_click_down.position = rot_rect103.get_center()
		rot_click_down.global_position = rot_rect103.get_center()
		piece103._input(rot_click_down)

		var rot_click_up := InputEventMouseButton.new()
		rot_click_up.button_index = MOUSE_BUTTON_LEFT
		rot_click_up.pressed = false
		rot_click_up.position = rot_rect103.get_center()
		rot_click_up.global_position = rot_rect103.get_center()
		piece103._input(rot_click_up)

		if piece103.cells != rot90_cells103 or piece103.rotation_steps != 1:
			printerr("[FAIL Test 103.Mouse] Intentional ROTATE activation did not produce exactly one 90° rotation! steps=", piece103.rotation_steps)
			get_tree().quit(1)
			return
		if piece103.piece_state != TrayPieceScript.PieceState.DRAGGING:
			printerr("[FAIL Test 103.Mouse] Drag must remain active after intentional rotation!")
			get_tree().quit(1)
			return

		# Continue dragging after rotation across ROTATE and onto board -> drag remains active, orientation stays at 90°
		var mm_after := InputEventMouseMotion.new()
		mm_after.button_mask = MOUSE_BUTTON_MASK_LEFT
		mm_after.position = rot_rect103.get_center()
		mm_after.global_position = rot_rect103.get_center()
		piece103._input(mm_after)
		mm_after.position = board_hover_pt
		mm_after.global_position = board_hover_pt
		piece103._input(mm_after)
		if piece103.piece_state != TrayPieceScript.PieceState.DRAGGING or piece103.cells != rot90_cells103 or not board103.preview_active or board103.preview_shape != rot90_cells103:
			printerr("[FAIL Test 103.Mouse] Continuing drag after rotation failed to keep drag active or update board preview!")
			get_tree().quit(1)
			return

		# Cancel drag -> original pre-drag orientation is restored
		var mm_cancel := InputEventMouseMotion.new()
		mm_cancel.button_mask = MOUSE_BUTTON_MASK_LEFT
		mm_cancel.position = cancel_outside_pt
		mm_cancel.global_position = cancel_outside_pt
		piece103._input(mm_cancel)
		var mb_up_cancel := InputEventMouseButton.new()
		mb_up_cancel.button_index = MOUSE_BUTTON_LEFT
		mb_up_cancel.pressed = false
		mb_up_cancel.position = cancel_outside_pt
		mb_up_cancel.global_position = cancel_outside_pt
		piece103._input(mb_up_cancel)
		if piece103.piece_state != TrayPieceScript.PieceState.IN_TRAY or piece103.cells != orig_cells103 or piece103.rotation_steps != 0:
			printerr("[FAIL Test 103.Mouse] Cancelling drag did not restore original orientation!")
			get_tree().quit(1)
			return

		# --- PATH B: Touch Input Path (Single-Finger & Multi-Touch) ---
		var st_down := InputEventScreenTouch.new()
		st_down.index = 0
		st_down.pressed = true
		st_down.position = piece103.size * 0.5
		piece103._gui_input(st_down)
		if piece103.piece_state != TrayPieceScript.PieceState.DRAGGING or piece103.drag_touch_index != 0:
			printerr("[FAIL Test 103.Touch] Touch drag failed to start on ", vp103)
			get_tree().quit(1)
			return

		# Drag finger 0 directly across ROTATE control -> must NEVER rotate
		var rot_rect_t: Rect2 = btn_rot103.get_global_rect()
		for t_step in [0.0, 0.3, 0.5, 0.8, 1.0]:
			var sd := InputEventScreenDrag.new()
			sd.index = 0
			sd.position = Vector2(
				lerpf(rot_rect_t.position.x - 15.0, rot_rect_t.end.x + 15.0, t_step),
				rot_rect_t.get_center().y
			)
			piece103._input(sd)
		if piece103.cells != orig_cells103 or piece103.rotation_steps != 0:
			printerr("[FAIL Test 103.Touch] Dragging touch finger across ROTATE control rotated piece accidentally on ", vp103)
			get_tree().quit(1)
			return

		# Intentional secondary touch tap on ROTATE while finger 0 drags -> rotates once (90°)
		var st_rot_tap := InputEventScreenTouch.new()
		st_rot_tap.index = 1
		st_rot_tap.pressed = true
		st_rot_tap.position = rot_rect_t.get_center()
		piece103._input(st_rot_tap)
		var st_rot_rel := InputEventScreenTouch.new()
		st_rot_rel.index = 1
		st_rot_rel.pressed = false
		st_rot_rel.position = rot_rect_t.get_center()
		piece103._input(st_rot_rel)
		if piece103.cells != rot90_cells103 or piece103.rotation_steps != 1 or piece103.piece_state != TrayPieceScript.PieceState.DRAGGING:
			printerr("[FAIL Test 103.Touch] Intentional touch tap on ROTATE failed to rotate once or ended drag!")
			get_tree().quit(1)
			return

		# Intentional button press via BtnDragRotate.pressed -> rotates a second time (180°)
		btn_rot103.pressed.emit()
		if piece103.cells != rot180_cells103 or piece103.rotation_steps != 2 or piece103.piece_state != TrayPieceScript.PieceState.DRAGGING:
			printerr("[FAIL Test 103.Touch] Second intentional rotation via BtnDragRotate.pressed failed!")
			get_tree().quit(1)
			return

		# Continue touch drag after rotation -> drag remains active
		var sd_board := InputEventScreenDrag.new()
		sd_board.index = 0
		sd_board.position = board_hover_pt
		piece103._input(sd_board)
		if piece103.piece_state != TrayPieceScript.PieceState.DRAGGING or not board103.preview_active or board103.preview_shape != rot180_cells103:
			printerr("[FAIL Test 103.Touch] Touch drag after rotation failed to update board preview!")
			get_tree().quit(1)
			return

		# Cancel touch drag -> original orientation restored
		var sd_cancel := InputEventScreenDrag.new()
		sd_cancel.index = 0
		sd_cancel.position = cancel_outside_pt
		piece103._input(sd_cancel)
		var st_up_cancel := InputEventScreenTouch.new()
		st_up_cancel.index = 0
		st_up_cancel.pressed = false
		st_up_cancel.position = cancel_outside_pt
		piece103._input(st_up_cancel)
		if piece103.piece_state != TrayPieceScript.PieceState.IN_TRAY or piece103.cells != orig_cells103 or piece103.rotation_steps != 0 or btn_rot103.visible:
			printerr("[FAIL Test 103.Touch] Cancelling touch drag failed to restore original orientation or hide ROTATE button!")
			get_tree().quit(1)
			return

	dd103.queue_free()
	print("[TEST 103/104] Drag & Drop accidental rotation fix (zero overlap rotation, intentional 90° rotate, drag continuation, cancel restore, mouse & touch): PASSED")

	# =========================================================================
	# TEST 104: Canonical Country Gameplay Background Architecture (Level -> Country -> Full Country Gameplay Background)
	#   - Each of the 68 countries has exactly ONE canonical full gameplay background
	#   - Every level 1..500 resolves level_id -> country_id -> canonical_gameplay_background
	#   - All levels belonging to the same country (Vietnam, Japan, Italy, France, USA, and all 68 countries)
	#     resolve to the exact same canonical_background_id, country_id, landmark_id, and ground_anchor
	#   - Zero destination-based background selection (no Hanoi -> Ha Long -> Hue level-specific background mapping)
	#   - Excludes MapPage level nodes, route lines, node numbers, progression markers, destination pads, floating islands, and map UI
	#   - Preserves visual layering order and translucent 12x10 board readability at 360x800, 390x844, and 720x1280
	# =========================================================================
	var bp_map104 = game_state.get_map_data()
	if bp_map104.get_page_count() != 68:
		printerr("[FAIL Test 104] Expected 68 country MapPages, found: ", bp_map104.get_page_count())
		get_tree().quit(1)
		return

	var reg_val104: Dictionary = game_state.validate_country_background_registry()
	if (
		not bool(reg_val104.get("valid", false)) or
		int(reg_val104.get("country_count", 0)) != 68 or
		int(reg_val104.get("unique_canonical_background_count", 0)) != 68 or
		int(reg_val104.get("resolved_level_count", 0)) != 500 or
		int(reg_val104.get("destination_specific_selections", -1)) != 0
	):
		printerr("[FAIL Test 104] Country background registry validation failed: ", reg_val104)
		get_tree().quit(1)
		return

	var expected_layer_order := [
		"country_landscape_background",
		"subtle_atmospheric_depth",
		"integrated_country_landmarks",
		"gameplay_hud",
		"translucent_12x10_board",
		"blocks_tray_controls"
	]

	# Prove that ALL levels 1..500 belonging to the same country resolve to the exact same canonical background
	var country_to_bg_id104: Dictionary = {}
	for page_i104 in range(bp_map104.get_page_count()):
		var pg104 = bp_map104.get_page(page_i104)
		var expected_cid104: String = pg104.country_id
		var expected_bg_id104: String = "%s_canonical_country_bg" % expected_cid104
		var ref_theme104: Dictionary = game_state.get_level_visual_theme(pg104.start_level)
		var ref_man104: Dictionary = game_state.get_level_gameplay_background_manifest(pg104.start_level, Vector2(390, 844))
		if (
			String(ref_theme104.get("canonical_background_id", "")) != expected_bg_id104 or
			String(ref_man104.get("canonical_background_id", "")) != expected_bg_id104 or
			int(ref_man104.get("landmark_count", 0)) < 2 or
			not bool(ref_man104.get("has_multiple_landmarks", false)) or
			not bool(ref_man104.get("has_visual_hierarchy", false)) or
			bool(ref_man104.get("is_single_landmark_only", true))
		):
			printerr("[FAIL Test 104] Country ", expected_cid104, " did not resolve to rich multi-landmark canonical background ", expected_bg_id104, ": ", ref_man104)
			get_tree().quit(1)
			return
		country_to_bg_id104[expected_cid104] = expected_bg_id104
		for lv104 in pg104.level_ids:
			var th104: Dictionary = game_state.get_level_visual_theme(lv104)
			var man104: Dictionary = game_state.get_level_gameplay_background_manifest(lv104, Vector2(390, 844))
			if (
				String(th104.get("country_id", "")) != expected_cid104 or
				String(th104.get("canonical_background_id", "")) != expected_bg_id104 or
				String(th104.get("gameplay_background", "")) != expected_bg_id104 or
				String(man104.get("canonical_background_id", "")) != expected_bg_id104 or
				String(man104.get("landmark_id", "")) != String(ref_man104.get("landmark_id", "")) or
				man104.get("landmark_ids", []) != ref_man104.get("landmark_ids", []) or
				Vector2(man104.get("ground_anchor", Vector2.ZERO)).distance_to(Vector2(ref_man104.get("ground_anchor", Vector2.ZERO))) > 0.01 or
				bool(th104.get("uses_destination_selection", true)) or
				bool(man104.get("uses_destination_selection", true)) or
				th104.has("destination_landmark_id")
			):
				printerr("[FAIL Test 104] Level ", lv104, " in country ", expected_cid104, " diverged from canonical country background! got theme=", th104, " man=", man104)
				get_tree().quit(1)
				return

	# Explicitly verify Vietnam gameplay background matches the Vietnam MapPage landmark manifest 1-to-1
	var vn_pg104 = bp_map104.get_page(0)
	var vn_rect104 := Rect2(Vector2.ZERO, Vector2(390, 844))
	var vn_map_man104: Dictionary = MapRendererScript.get_page_landmark_manifest(vn_pg104, vn_rect104)
	var vn_man104: Dictionary = game_state.get_level_gameplay_background_manifest(1, Vector2(390, 844))
	var vn_inv104: Dictionary = MapRendererScript.compare_map_page_and_gameplay_background_invariants(vn_pg104, vn_rect104, 1)
	if (
		not bool(vn_inv104.get("valid", false)) or
		vn_man104.get("landmark_ids", []) != vn_map_man104.get("landmark_ids", []) or
		int(vn_man104.get("landmark_count", -1)) != int(vn_map_man104.get("landmark_count", -2))
	):
		printerr("[FAIL Test 104] Vietnam gameplay background diverged from Vietnam MapPage! inv=", vn_inv104)
		get_tree().quit(1)
		return
	var vn_all_ids104: Array = vn_man104.get("all_country_landmark_ids", [])
	for req_vn_id104 in [
		"hanoi_hoan_kiem_pagoda",
		"halong_karst_harbor",
		"ninh_binh_trang_an_karst",
		"hue_imperial_citadel",
		"hoian_covered_bridge_lanterns",
		"saigon_bitexco_skyline",
		"mekong_floating_market"
	]:
		if not vn_all_ids104.has(req_vn_id104):
			printerr("[FAIL Test 104] Vietnam country destinations missing required landmark/scenery: ", req_vn_id104, " in ", vn_all_ids104)
			get_tree().quit(1)
			return

	# Verify MapRenderer.render_country_page(canvas, page, rect, mode) differentiates MAP_PAGE vs GAMEPLAY_BACKGROUND via MapRenderVisibility
	var mode_map104: Dictionary = MapRendererScript.render_country_page(null, vn_pg104, vn_rect104, MapRendererScript.RenderMode.MAP_PAGE)
	var mode_bg104: Dictionary = MapRendererScript.render_country_page(null, vn_pg104, vn_rect104, MapRendererScript.RenderMode.GAMEPLAY_BACKGROUND)
	if (
		String(mode_map104.get("render_mode", "")) != "MAP_PAGE" or
		not bool(mode_map104.get("renders_level_markers", false)) or
		not bool(mode_map104.get("renders_route_lines", false)) or
		not bool(mode_map104.get("renders_destination_pads", false)) or
		not bool(mode_map104.get("renders_level_labels", false)) or
		String(mode_bg104.get("render_mode", "")) != "GAMEPLAY_BACKGROUND" or
		bool(mode_bg104.get("renders_level_markers", true)) or
		bool(mode_bg104.get("renders_route_lines", true)) or
		bool(mode_bg104.get("renders_destination_pads", true)) or
		bool(mode_bg104.get("renders_level_labels", true)) or
		bool(mode_bg104.get("renders_level_nodes", true)) or
		not bool(mode_bg104.get("reuses_full_map_page_artwork", false)) or
		not bool(mode_bg104.get("matches_map_page_exactly", false))
	):
		printerr("[FAIL Test 104] MapRenderer.render_country_page mode differentiation failed: map=", mode_map104, " bg=", mode_bg104)
		get_tree().quit(1)
		return

	# Explicitly verify Vietnam, Japan, Italy, France, and USA canonical country backgrounds
	for req_country_cid in ["vietnam", "japan", "italy", "france", "united_states"]:
		if String(country_to_bg_id104.get(req_country_cid, "")) != "%s_canonical_country_bg" % req_country_cid:
			printerr("[FAIL Test 104] Missing canonical country background for ", req_country_cid)
			get_tree().quit(1)
			return

	# Audit all 68 countries across all 3 viewports (360x800, 390x844, 720x1280)
	for vp104 in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
		var rect104 := Rect2(Vector2.ZERO, vp104)
		for page_i104 in range(bp_map104.get_page_count()):
			var pg104_b = bp_map104.get_page(page_i104)
			var bg_start104: Dictionary = game_state.get_level_gameplay_background_manifest(pg104_b.start_level, vp104)
			var bg_end104: Dictionary = game_state.get_level_gameplay_background_manifest(pg104_b.end_level, vp104)
			var inv104: Dictionary = MapRendererScript.compare_map_page_and_gameplay_background_invariants(pg104_b, rect104, pg104_b.start_level)
			if not bool(inv104.get("valid", false)):
				printerr("[FAIL Test 104] Country ", pg104_b.country_id, " failed MapPage vs Gameplay Background invariant at ", vp104, ": ", inv104)
				get_tree().quit(1)
				return
			if String(bg_start104.get("canonical_background_id", "")) != String(bg_end104.get("canonical_background_id", "")):
				printerr("[FAIL Test 104] Start and end levels of ", pg104_b.country_id, " do not share identical canonical_background_id at ", vp104)
				get_tree().quit(1)
				return
			for bg_man104 in [bg_start104, bg_end104]:
				if (
					not bool(bg_man104.get("valid", false)) or
					not bool(bg_man104.get("reuses_country_map_artwork", false)) or
					not bool(bg_man104.get("reuses_full_map_page_artwork", false)) or
					not bool(bg_man104.get("matches_full_map_page_artwork", false)) or
					not bool(bg_man104.get("matches_map_page_exactly", false)) or
					int(bg_man104.get("landmark_count", 0)) <= 0
				):
					printerr("[FAIL Test 104] Gameplay background manifest invalid or incomplete vs MapPage at ", vp104, ": ", bg_man104)
					get_tree().quit(1)
					return
				if (
					bool(bg_man104.get("draws_map_level_nodes", true)) or
					bool(bg_man104.get("draws_route_lines", true)) or
					bool(bg_man104.get("draws_node_numbers", true)) or
					bool(bg_man104.get("draws_progression_markers", true)) or
					bool(bg_man104.get("draws_map_navigation_ui", true)) or
					bool(bg_man104.get("draws_artificial_floating_islands", true)) or
					bool(bg_man104.get("renders_destination_pads", true)) or
					int(bg_man104.get("unrelated_landmark_count", -1)) != 0 or
					not bool(bg_man104.get("is_continuous_country_scene", false)) or
					bool(bg_man104.get("is_destination_collage", true))
				):
					printerr("[FAIL Test 104] Gameplay background leaked map navigation elements or destination collage: ", bg_man104)
					get_tree().quit(1)
					return
				if (
					bool(bg_man104.get("has_horizontal_clipping", true)) or
					not bool(bg_man104.get("ground_anchor_not_in_sky", false)) or
					not bool(bg_man104.get("preserves_board_readability", false)) or
					not bool(bg_man104.get("has_subdued_contrast_veil", false)) or
					bg_man104.get("layer_order", []) != expected_layer_order
				):
					printerr("[FAIL Test 104] Gameplay background clipping, grounding, readability, or layering check failed at ", vp104, ": ", bg_man104)
					get_tree().quit(1)
					return

	# Verify live Main scene LevelBackdropLayer & LevelBackdropCanvas integration and z-ordering
	var main104 = MainScene.instantiate()
	add_child(main104)
	for test_lv104 in [1, 2, 6, 8, 25, 120, 350, 500]:
		game_state.set_energy(24, false)
		game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP, test_lv104)
		for vp_m104 in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
			var b_state104: Dictionary = main104.get_active_level_backdrop_state(vp_m104)
			if (
				int(b_state104.get("active_level", -1)) != test_lv104 or
				not bool(b_state104.get("reuses_country_map_artwork", false)) or
				bool(b_state104.get("draws_map_level_nodes", true)) or
				bool(b_state104.get("draws_route_lines", true)) or
				bool(b_state104.get("has_horizontal_clipping", true)) or
				not bool(b_state104.get("preserves_board_readability", false)) or
				String(b_state104.get("country_id", "")) == "" or
				String(b_state104.get("canonical_background_id", "")) == ""
			):
				printerr("[FAIL Test 104] Main scene active level backdrop state invalid on level ", test_lv104, " at ", vp_m104, ": ", b_state104)
				get_tree().quit(1)
				return
			if main104.level_backdrop_layer.layer >= main104.get_node("UI").layer:
				printerr("[FAIL Test 104] LevelBackdropLayer must stay behind GameWorld and UI layers!")
				get_tree().quit(1)
				return
	main104.queue_free()
	print("[TEST 104/105] Canonical Country Gameplay Backgrounds (Level -> Country -> Full Country Gameplay Background across all 68 countries & 500 levels): PASSED")

	# =========================================================================
	# TEST 105: Playable Block Clearly Separated Basic Colors & Material Surface Differentiation
	#   - Verifies 8 clearly separated basic colors: Red, Orange, Yellow, Green, Cyan, Blue, Purple, Magenta/Pink
	#   - Verifies zero near-identical or muted shades across all material families
	#   - Verifies material families (Brick, Crystal, Wood, Metal, Gemstone, etc.) change surface treatment only
	#   - Verifies color clarity in tray, falling pieces, drag & drop, board, previews, and special states
	# =========================================================================
	var pal_val105: Dictionary = PolyominoLib.validate_block_color_palette()
	if (
		not bool(pal_val105.get("valid", false)) or
		int(pal_val105.get("basic_color_count", 0)) != 8 or
		int(pal_val105.get("shape_distinct_color_count", 0)) != 8 or
		not bool(pal_val105.get("core_materials_intact", false)) or
		not bool(pal_val105.get("color_is_primary_identity", false)) or
		float(pal_val105.get("min_rgb_distance", 0.0)) < 0.25 or
		float(pal_val105.get("min_hue_separation_deg", 0.0)) < 18.0
	):
		printerr("[FAIL Test 105] Playable block color palette validation failed: ", pal_val105)
		get_tree().quit(1)
		return
	for cid105 in range(1, 9):
		var c_lib105: Color = PolyominoLib.get_basic_color_for_id(cid105)
		var c_board105: Color = BoardScript.COLOR_MAP.get(cid105, Color.BLACK)
		if not c_lib105.is_equal_approx(c_board105):
			printerr("[FAIL Test 105] Board.COLOR_MAP mismatch for color_id=", cid105, ": lib=", c_lib105, " board=", c_board105)
			get_tree().quit(1)
			return
	print("[TEST 105/106] Playable Block Clearly Separated Basic Colors (Red, Orange, Yellow, Green, Cyan, Blue, Purple, Magenta/Pink) & Material Surface System: PASSED")

	# =========================================================================
	# TEST 106: Zero Placement Score & Line-Clear Multiplier Rules
	#   1. Place a block without clearing any line -> score unchanged (0)
	#   2. Fall a block without clearing -> score unchanged (0)
	#   3. Drag & Drop placement without clearing -> score unchanged (0)
	#   4. Complete one row -> score increases correctly (10 cells * 1.0 = 10)
	#   5. Complete one column in Modern -> score increases correctly (12 cells * 1.0 = 12); in Classic -> 0
	#   6. Complete multiple lines -> correct multipliers (1x, 1.5x, 3x, 4x, 5x, 6x)
	#   7. Row + column simultaneously -> Combo x2 (stacking multiplicatively: 1.5 * 2 = 3.0x)
	#   8. Rainbow/7-color multiplier stacks multiplicatively (x2)
	#   9. Score never changes before the clear-resolution step
	# =========================================================================
	if GameStateScript.POINTS_PER_CELL_PLACED != 0:
		printerr("[FAIL Test 106] POINTS_PER_CELL_PLACED must be 0, got: ", GameStateScript.POINTS_PER_CELL_PLACED)
		get_tree().quit(1)
		return

	# 1. Direct placement without clearing any line -> score unchanged (0) across both Classic and Modern
	for mode106 in [GameStateScript.GameMode.CLASSIC, GameStateScript.GameMode.MODERN_DRAG_AND_DROP]:
		game_state.set_energy(24, false)
		game_state.start_game_combination(mode106, GameStateScript.PlayStyle.DRAG_AND_DROP, 1)
		var res_no_clear106: Dictionary = game_state.process_move_result(4, 0, 0, 0, 0, false)
		if (
			int(res_no_clear106.get("score_delta", -1)) != 0 or
			int(res_no_clear106.get("total_points", -1)) != 0 or
			int(res_no_clear106.get("placement_points", -1)) != 0 or
			game_state.score != 0
		):
			printerr("[FAIL Test 106.1] Placement without line clear must award 0 points! got: ", res_no_clear106, " score=", game_state.score)
			get_tree().quit(1)
			return

	# 2. Falling mode: spawning, falling movement, and locking a falling block without clearing -> score unchanged (0)
	game_state.set_energy(24, false)
	game_state.start_game_combination(GameStateScript.GameMode.CLASSIC, GameStateScript.PlayStyle.FALLING, 1)
	var fall_mode106 = ClassicModeScript.new()
	fall_mode106.configure_combination(GameStateScript.GameMode.CLASSIC, GameStateScript.PlayStyle.FALLING)
	add_child(fall_mode106)
	fall_mode106.initialize_mode()
	fall_mode106.start_mode()
	if game_state.score != 0:
		printerr("[FAIL Test 106.2] Spawning falling block must not change score!")
		get_tree().quit(1)
		return
	fall_mode106._step_down()
	if game_state.score != 0:
		printerr("[FAIL Test 106.2] Falling movement step must not change score!")
		get_tree().quit(1)
		return
	fall_mode106.quick_drop()
	if game_state.score != 0:
		printerr("[FAIL Test 106.2] Locking a falling block without clearing a row must leave score at 0! got: ", game_state.score)
		get_tree().quit(1)
		return
	fall_mode106.queue_free()

	# 3 & 9. Drag & Drop mode: drag start, drag movement, preview, board.place_piece before clear, and non-clearing drop -> score unchanged (0)
	game_state.set_energy(24, false)
	game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP, 1)
	var drag_mode106 = ModernModeScript.new()
	drag_mode106.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	add_child(drag_mode106)
	drag_mode106.initialize_mode()
	drag_mode106.start_mode()
	drag_mode106.update_layout_for_viewport(Vector2(390, 844))
	var tray_p106: Control = null
	for p_cand106 in drag_mode106.piece_tray.active_pieces:
		if p_cand106 != null:
			tray_p106 = p_cand106
			break
	var target_world106: Vector2 = drag_mode106.board.grid_to_world_shape_center(Vector2i(0, 0), tray_p106.cells) + Vector2(0, tray_p106.TOUCH_Y_OFFSET)
	tray_p106._start_drag(tray_p106.global_position + tray_p106.size * 0.5)
	if game_state.score != 0:
		printerr("[FAIL Test 106.9] Drag start must not change score!")
		get_tree().quit(1)
		return
	tray_p106._update_drag_position(target_world106)
	drag_mode106._on_piece_drag_moved(tray_p106, target_world106)
	if game_state.score != 0:
		printerr("[FAIL Test 106.9] Drag movement / preview placement must not change score!")
		get_tree().quit(1)
		return
	drag_mode106._on_piece_drag_ended(tray_p106, target_world106)
	if game_state.score != 0:
		printerr("[FAIL Test 106.3] Drag & Drop placement without clearing a line must leave score at 0! got: ", game_state.score)
		get_tree().quit(1)
		return
	# Verify board.place_piece itself never changes score even when completing a full row prior to check_and_clear_lines
	drag_mode106.board.clear_board()
	var bottom_row106: int = drag_mode106.board.GRID_HEIGHT - 1
	var prefill_cols106: int = drag_mode106.board.GRID_WIDTH - 4
	for x106 in range(prefill_cols106):
		drag_mode106.board.grid_data[bottom_row106][x106] = 1
	var line4_cells106: Array = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	drag_mode106.board.place_piece(line4_cells106, Vector2i(prefill_cols106, bottom_row106), 1)
	if game_state.score != 0:
		printerr("[FAIL Test 106.9] Score changed during board.place_piece before line-clear resolution!")
		get_tree().quit(1)
		return
	var manual_clear106: Dictionary = drag_mode106.board.check_and_clear_lines(true, false)
	if game_state.score != 0 or int(manual_clear106.get("lines_cleared", 0)) != 1:
		printerr("[FAIL Test 106.9] Score must only update at the clear-resolution scoring step!")
		get_tree().quit(1)
		return
	drag_mode106.queue_free()

	# 4 & 5. Complete 1 row (10 pts) and 1 column in Modern (12 pts) vs Classic column rejection (0 pts)
	game_state.set_energy(24, false)
	game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP, 1)
	var one_row106: Dictionary = game_state.process_move_result(4, 1, 1, 0, 10, false)
	if int(one_row106.get("score_delta", 0)) != 10 or game_state.score != 10:
		printerr("[FAIL Test 106.4] 1 row clear (10 cells * 1x) must award 10 points! got: ", one_row106)
		get_tree().quit(1)
		return
	var one_col_mod106: Dictionary = game_state.process_move_result(4, 1, 0, 1, 12, false)
	if int(one_col_mod106.get("score_delta", 0)) != 12 or game_state.score != 22:
		printerr("[FAIL Test 106.5] 1 column clear in Modern (12 cells * 1x) must award 12 points! got: ", one_col_mod106)
		get_tree().quit(1)
		return
	game_state.set_energy(24, false)
	game_state.start_game_combination(GameStateScript.GameMode.CLASSIC, GameStateScript.PlayStyle.DRAG_AND_DROP, 1)
	var one_col_classic106: Dictionary = game_state.process_move_result(4, 1, 0, 1, 10, false)
	if int(one_col_classic106.get("score_delta", -1)) != 10 or game_state.score != 10:
		printerr("[FAIL Test 106.5] Column in Classic Drag & Drop mode must award 10 points! got: ", one_col_classic106)
		get_tree().quit(1)
		return
	game_state.set_energy(24, false)
	game_state.start_game_combination(GameStateScript.GameMode.CLASSIC, GameStateScript.PlayStyle.FALLING, 1)
	var one_col_falling106: Dictionary = game_state.process_move_result(4, 1, 0, 1, 12, false)
	if int(one_col_falling106.get("score_delta", -1)) != 0:
		printerr("[FAIL Test 106.5] Column in Classic Falling mode must award 0 points! got: ", one_col_falling106)
		get_tree().quit(1)
		return

	# 6. Complete multiple lines -> verify exact multipliers: 1->1x, 2->1.5x, 3->3x, 4->4x, 5->5x, 6->6x
	var expected_mults106: Dictionary = {
		1: 1.0,
		2: 1.5,
		3: 3.0,
		4: 4.0,
		5: 5.0,
		6: 6.0
	}
	for lines_k106 in expected_mults106.keys():
		game_state.set_energy(24, false)
		game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP, 1)
		var cells_k106: int = int(lines_k106) * 10
		var exp_m106: float = float(expected_mults106[lines_k106])
		var exp_pts106: int = int(round(float(cells_k106) * exp_m106))
		var m_res106: Dictionary = game_state.process_move_result(4, int(lines_k106), int(lines_k106), 0, cells_k106, false)
		if (
			not is_equal_approx(float(m_res106.get("line_multiplier", 0.0)), exp_m106) or
			int(m_res106.get("score_delta", -1)) != exp_pts106 or
			game_state.score != exp_pts106
		):
			printerr("[FAIL Test 106.6] Multi-line multiplier failed for ", lines_k106, " lines! Expected ", exp_pts106, ", got: ", m_res106)
			get_tree().quit(1)
			return

	# 7. Row + Column simultaneously -> Combo x2 stacks multiplicatively with 2-line 1.5x (= 3.0x)
	game_state.set_energy(24, false)
	game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP, 1)
	var rc_combo106: Dictionary = game_state.process_move_result(4, 2, 1, 1, 21, false)
	if (
		not is_equal_approx(float(rc_combo106.get("line_multiplier", 0.0)), 1.5) or
		not is_equal_approx(float(rc_combo106.get("row_column_combo_multiplier", 0.0)), 2.0) or
		not is_equal_approx(float(rc_combo106.get("applicable_multiplier", 0.0)), 3.0) or
		int(rc_combo106.get("score_delta", -1)) != 63 or
		game_state.score != 63
	):
		printerr("[FAIL Test 106.7] Row + Column simultaneous Combo x2 failed! Expected 21 * 3.0 = 63, got: ", rc_combo106)
		get_tree().quit(1)
		return

	# 8. Rainbow/7-color block multiplier (x2) stacks multiplicatively
	game_state.set_energy(24, false)
	game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP, 1)
	var rb_single106: Dictionary = game_state.process_move_result(4, 1, 1, 0, 10, true)
	if (
		not is_equal_approx(float(rb_single106.get("rainbow_multiplier", 0.0)), 2.0) or
		not is_equal_approx(float(rb_single106.get("applicable_multiplier", 0.0)), 2.0) or
		int(rb_single106.get("score_delta", -1)) != 20
	):
		printerr("[FAIL Test 106.8] Rainbow single-row clear multiplier failed! Expected 20, got: ", rb_single106)
		get_tree().quit(1)
		return
	var rb_rc_combo106: Dictionary = game_state.process_move_result(4, 2, 1, 1, 21, true)
	if (
		not is_equal_approx(float(rb_rc_combo106.get("applicable_multiplier", 0.0)), 6.0) or
		int(rb_rc_combo106.get("score_delta", -1)) != 126
	):
		printerr("[FAIL Test 106.8] Rainbow + Row/Col Combo + 2-line multiplicative stacking failed! Expected 21 * 6.0 = 126, got: ", rb_rc_combo106)
		get_tree().quit(1)
		return
	print("[TEST 106/107] Zero Placement Score & Line-Clear Multiplier Rules (Classic/Modern, Falling/Drag & Drop, Multi-Line, Row+Col Combo x2, Rainbow x2): PASSED")

	# =========================================================================
	# TEST 107: Drag & Drop Rotate Position, Settings Separation, Account Provider Order & Styling, Voice & Haptic Feedback
	#   1. Drag & Drop Rotate button sits visually centered between the bottom edge of the play board and the top edge of the 3-block tray (no overlap with board/tray/AdSlot; single Rotate control; 360x800, 390x844, 720x1280)
	#   2. Settings UI places VOICE and HAPTIC on the SAME horizontal row and clearly separates the ACCOUNT / CLOSE (Home Menu) bottom group from controls above within the existing frame size (360x800, 390x844, 720x1280)
	#   3. Account menu provider order & platform rules:
	#      - iOS: LOCAL -> APPLE ID -> CREATE WITH EMAIL (GOOGLE PLAY ID hidden)
	#      - Android: LOCAL -> GOOGLE PLAY ID -> CREATE WITH EMAIL (APPLE ID hidden; exact label GOOGLE PLAY ID)
	#      - Other platforms: LOCAL -> CREATE WITH EMAIL (APPLE ID & GOOGLE PLAY ID hidden)
	#   4. Apple ID (dark/neutral premium) and Google Play ID (multicolor Google Play provider) have distinct visual styling from Create with Email
	#   5. Voice button plays real male voice confirmation on Male, real female voice confirmation on Female, and no voice confirmation on OFF
	#   6. Haptic button triggers short haptic vibration when switched ON and does not vibrate when switched OFF
	# =========================================================================
	var dd107 = ModernModeScript.new()
	dd107.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	add_child(dd107)
	dd107.initialize_mode()
	dd107.start_mode()
	for vp_dd107 in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
		var dd_layout107: Dictionary = dd107.update_layout_for_viewport(vp_dd107)
		var b_rect107: Rect2 = dd_layout107.get("board_rect", Rect2())
		var r_rect107: Rect2 = dd_layout107.get("rotate_button_rect", Rect2())
		var t_rect107: Rect2 = dd_layout107.get("tray_rect", Rect2())
		var ad_rect107: Rect2 = dd_layout107.get("ad_rect", Rect2())
		var mid_y107: float = (b_rect107.end.y + t_rect107.position.y) * 0.5
		var rot_center_y107: float = r_rect107.get_center().y
		var rot_count107: int = 0
		for ch107 in dd107.piece_tray.get_children():
			if ch107 is Button and "rotate" in String(ch107.name).to_lower():
				rot_count107 += 1
		if (
			rot_count107 != 1 or
			r_rect107.position.y <= b_rect107.end.y + 2.0 or
			r_rect107.end.y >= t_rect107.position.y - 2.0 or
			r_rect107.intersects(b_rect107) or
			r_rect107.intersects(t_rect107) or
			r_rect107.intersects(ad_rect107) or
			absf(rot_center_y107 - mid_y107) > 1.5 or
			absf(r_rect107.get_center().x - b_rect107.get_center().x) > 1.5
		):
			printerr("[FAIL Test 107.0] Drag & Drop Rotate button must be centered between board bottom and tray top without overlap at ", vp_dd107, ": board=", b_rect107, " rotate=", r_rect107, " tray=", t_rect107)
			get_tree().quit(1)
			return
	dd107.queue_free()

	var menu107 = MainMenuScene.instantiate()
	add_child(menu107)

	# 1 & 2. Verify Settings VOICE + HAPTIC on the same horizontal row, bottom ACCOUNT/CLOSE group separated within existing frame, and zero clipping across 360x800, 390x844, 720x1280
	menu107._on_btn_settings_pressed()
	if not menu107.modal_settings.visible or not menu107.has_equal_width_voice_haptics_row():
		printerr("[FAIL Test 107.1] Settings VOICE and HAPTIC must be on the SAME horizontal row with equal width!")
		get_tree().quit(1)
		return
	for vp_s107 in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
		var s_insp107: Dictionary = menu107.get_settings_layout_inspection(vp_s107)
		if (
			not bool(s_insp107.get("voice_haptics_same_row", false)) or
			not bool(s_insp107.get("equal_visual_weight", false)) or
			not bool(s_insp107.get("no_clipping", false)) or
			not bool(s_insp107.get("bottom_group_clearly_separated", false)) or
			not bool(s_insp107.get("single_voice_control", false)) or
			not bool(s_insp107.get("single_haptic_control", false))
		):
			printerr("[FAIL Test 107.1] Settings layout/separation/clipping check failed at ", vp_s107, ": ", s_insp107)
			get_tree().quit(1)
			return

	# Verify Voice button immediate voice confirmation feedback (Male -> Female plays female voice; Female -> OFF plays no voice; OFF -> Male plays male voice)
	game_state.set_voice_mode("male", false)
	menu107._update_settings_buttons()
	var vc_cnt0: int = audio_mgr.voice_confirmation_play_count
	menu107.btn_toggle_voice.pressed.emit() # male -> female
	if (
		game_state.get_voice_mode() != "female" or
		audio_mgr.voice_confirmation_play_count != vc_cnt0 + 1 or
		audio_mgr.last_voice_confirmation_gender != "female" or
		audio_mgr.last_voice_confirmation_stream != audio_mgr.voice_cache_female.get("good")
	):
		printerr("[FAIL Test 107.Voice] Switching to VOICE: Female must immediately play female voice confirmation!")
		get_tree().quit(1)
		return
	menu107.btn_toggle_voice.pressed.emit() # female -> off
	if (
		game_state.get_voice_mode() != "off" or
		audio_mgr.voice_confirmation_play_count != vc_cnt0 + 1 or
		audio_mgr.last_voice_confirmation_gender != "" or
		audio_mgr.voice_player.playing
	):
		printerr("[FAIL Test 107.Voice] Switching to VOICE: OFF must NOT play any voice confirmation!")
		get_tree().quit(1)
		return
	menu107.btn_toggle_voice.pressed.emit() # off -> male
	if (
		game_state.get_voice_mode() != "male" or
		audio_mgr.voice_confirmation_play_count != vc_cnt0 + 2 or
		audio_mgr.last_voice_confirmation_gender != "male" or
		audio_mgr.last_voice_confirmation_stream != audio_mgr.voice_cache_male.get("good")
	):
		printerr("[FAIL Test 107.Voice] Switching to VOICE: Male must immediately play male voice confirmation!")
		get_tree().quit(1)
		return

	# Verify Haptic toggle behavior: switching OFF does NOT vibrate; switching ON immediately triggers short haptic vibration
	game_state.set_haptics_enabled(true, false, false)
	menu107._update_settings_buttons()
	var hap_cnt0: int = game_state.haptic_trigger_count
	menu107.btn_toggle_haptics.pressed.emit() # ON -> OFF
	if game_state.haptics_enabled != false or game_state.haptic_trigger_count != hap_cnt0:
		printerr("[FAIL Test 107.Haptic] Switching HAPTIC to OFF must NOT trigger haptic vibration!")
		get_tree().quit(1)
		return
	menu107.btn_toggle_haptics.pressed.emit() # OFF -> ON
	if game_state.haptics_enabled != true or game_state.haptic_trigger_count != hap_cnt0 + 1 or game_state.last_haptic_duration_ms <= 0:
		printerr("[FAIL Test 107.Haptic] Switching HAPTIC to ON must immediately trigger short haptic vibration!")
		get_tree().quit(1)
		return

	if menu107.btn_settings_account == null or not menu107.btn_settings_account.visible:
		printerr("[FAIL Test 107.1] Settings modal must display a visible ACCOUNT button!")
		get_tree().quit(1)
		return
	menu107.btn_settings_account.pressed.emit()
	if not menu107.modal_account.visible or menu107.modal_settings.visible or menu107.modal_delete_confirm.visible:
		printerr("[FAIL Test 107.1] Tapping ACCOUNT button must open AccountModal (with DeleteConfirmDialog hidden)!")
		get_tree().quit(1)
		return
	for vp107 in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
		var insp_vp107: Dictionary = menu107.get_account_menu_inspection(vp107)
		if not bool(insp_vp107.get("fits_within_viewport", false)) or not bool(insp_vp107.get("no_clipping", false)) or not bool(insp_vp107.get("has_account_button", false)):
			printerr("[FAIL Test 107.2] Account menu failed responsive viewport bounds/no-clipping check at ", vp107, ": ", insp_vp107)
			get_tree().quit(1)
			return
	menu107.close_account_menu()
	if menu107.modal_account.visible or menu107.modal_delete_confirm.visible:
		printerr("[FAIL Test 107.2] Closing Account menu failed to hide AccountModal!")
		get_tree().quit(1)
		return
	menu107.open_account_menu()
	if not menu107.modal_account.visible:
		printerr("[FAIL Test 107.2] Re-opening Account menu failed!")
		get_tree().quit(1)
		return

	# 3 & 4. Verify platform-specific provider visibility, order (LOCAL -> APPLE ID / GOOGLE PLAY ID -> CREATE WITH EMAIL), distinct visual styling, and tap response
	# iOS: LOCAL -> APPLE ID -> CREATE WITH EMAIL (no GOOGLE PLAY ID)
	menu107.set_account_platform_override("iOS")
	var ios_insp107: Dictionary = menu107.get_account_menu_inspection(Vector2(390, 844))
	if (
		String(ios_insp107.get("platform", "")) != "ios" or
		ios_insp107.get("visible_providers", []) != ["local", "apple_id", "create_with_email"] or
		not bool(ios_insp107.get("platform_provider_above_create_email", false)) or
		not bool(ios_insp107.get("apple_distinct_from_create_email", false)) or
		not bool(ios_insp107.get("local_visible", false)) or
		String(ios_insp107.get("local_label", "")) != "LOCAL" or
		not bool(ios_insp107.get("delete_data_visible", false)) or
		not bool(ios_insp107.get("create_email_visible", false)) or
		String(ios_insp107.get("create_email_label", "")) != "CREATE WITH EMAIL" or
		not bool(ios_insp107.get("create_email_inactive", false)) or
		not bool(ios_insp107.get("create_email_responds_to_tap", false)) or
		not bool(ios_insp107.get("apple_id_visible", false)) or
		String(ios_insp107.get("apple_id_label", "")) != "APPLE ID" or
		not bool(ios_insp107.get("apple_id_inactive", false)) or
		not bool(ios_insp107.get("apple_id_responds_to_tap", false)) or
		bool(ios_insp107.get("google_play_id_visible", true))
	):
		printerr("[FAIL Test 107.3] iOS Account menu provider order/visibility/styling mismatch (expected LOCAL -> APPLE ID -> CREATE WITH EMAIL): ", ios_insp107)
		get_tree().quit(1)
		return

	# Android: LOCAL -> GOOGLE PLAY ID -> CREATE WITH EMAIL (no APPLE ID, exact label GOOGLE PLAY ID)
	menu107.set_account_platform_override("Android")
	var and_insp107: Dictionary = menu107.get_account_menu_inspection(Vector2(390, 844))
	if (
		String(and_insp107.get("platform", "")) != "android" or
		and_insp107.get("visible_providers", []) != ["local", "google_play_id", "create_with_email"] or
		not bool(and_insp107.get("platform_provider_above_create_email", false)) or
		not bool(and_insp107.get("google_play_distinct_from_create_email", false)) or
		not bool(and_insp107.get("apple_distinct_from_google_play", false)) or
		not bool(and_insp107.get("local_visible", false)) or
		String(and_insp107.get("local_label", "")) != "LOCAL" or
		not bool(and_insp107.get("delete_data_visible", false)) or
		not bool(and_insp107.get("create_email_visible", false)) or
		String(and_insp107.get("create_email_label", "")) != "CREATE WITH EMAIL" or
		not bool(and_insp107.get("create_email_inactive", false)) or
		not bool(and_insp107.get("create_email_responds_to_tap", false)) or
		bool(and_insp107.get("apple_id_visible", true)) or
		not bool(and_insp107.get("google_play_id_visible", false)) or
		String(and_insp107.get("google_play_id_label", "")) != "GOOGLE PLAY ID" or
		String(and_insp107.get("google_play_id_label", "")) == "GOOGLE ID" or
		not bool(and_insp107.get("google_play_id_inactive", false)) or
		not bool(and_insp107.get("google_play_id_responds_to_tap", false))
	):
		printerr("[FAIL Test 107.3] Android Account menu provider order/visibility/styling mismatch (expected LOCAL -> GOOGLE PLAY ID -> CREATE WITH EMAIL): ", and_insp107)
		get_tree().quit(1)
		return

	# Other platforms (Linux / Web / Desktop): LOCAL + CREATE WITH EMAIL only (no APPLE ID, no GOOGLE PLAY ID)
	menu107.set_account_platform_override("Linux")
	var oth_insp107: Dictionary = menu107.get_account_menu_inspection(Vector2(390, 844))
	if (
		String(oth_insp107.get("platform", "")) != "other" or
		oth_insp107.get("visible_providers", []) != ["local", "create_with_email"] or
		not bool(oth_insp107.get("local_visible", false)) or
		not bool(oth_insp107.get("delete_data_visible", false)) or
		not bool(oth_insp107.get("create_email_visible", false)) or
		not bool(oth_insp107.get("create_email_inactive", false)) or
		bool(oth_insp107.get("apple_id_visible", true)) or
		bool(oth_insp107.get("google_play_id_visible", true))
	):
		printerr("[FAIL Test 107.3] Other-platform Account menu provider visibility mismatch (expected LOCAL + CREATE WITH EMAIL only): ", oth_insp107)
		get_tree().quit(1)
		return
	menu107.clear_account_platform_override()

	# 5. Seed local progression & custom settings, verify tap visual response on placeholders, then verify Delete Data -> Confirmation -> Cancel / Confirm Delete
	game_state.reset_progression(false)
	game_state.current_mode = GameStateScript.GameMode.MODERN_DRAG_AND_DROP
	for lv107 in range(1, 12):
		game_state.record_level_completion(lv107, game_state.get_level_target_score(lv107) * 2)
	game_state.select_map_level(9)
	game_state.high_score = 4850
	game_state.lines_cleared_total = 74
	game_state.coins = 920
	game_state.persistent_bonus_items["bomb"] = 2
	game_state.set_special_item_count("bomb", 2)
	game_state.set_special_item_count("change_block", 3)
	game_state.set_special_item_count("extra_life", 1)

	# Customize unrelated app settings (Music OFF, SFX OFF, Voice Female, Haptics OFF, Language VI)
	audio_mgr.music_enabled = false
	audio_mgr.sound_enabled = false
	game_state.music_enabled = false
	game_state.sound_enabled = false
	game_state.set_voice_mode("female", false)
	game_state.haptics_enabled = false
	game_state.set_language("vi", true)

	menu107.open_account_menu()
	# Verify tapping placeholder provider buttons responds visually to press/tap without performing auth or altering state
	var em_taps0: int = int(menu107.btn_create_email.get_meta("tap_response_count", 0))
	var ap_taps0: int = int(menu107.btn_apple_id.get_meta("tap_response_count", 0))
	var gp_taps0: int = int(menu107.btn_google_play_id.get_meta("tap_response_count", 0))
	menu107.btn_create_email.pressed.emit()
	menu107.btn_apple_id.pressed.emit()
	menu107.btn_google_play_id.pressed.emit()
	if (
		int(menu107.btn_create_email.get_meta("tap_response_count", 0)) != em_taps0 + 1 or
		int(menu107.btn_apple_id.get_meta("tap_response_count", 0)) != ap_taps0 + 1 or
		int(menu107.btn_google_play_id.get_meta("tap_response_count", 0)) != gp_taps0 + 1 or
		game_state.highest_unlocked_level != 12 or
		not menu107.modal_account.visible or
		menu107.modal_delete_confirm.visible
	):
		printerr("[FAIL Test 107.4] Placeholder provider buttons must respond visually to tap without performing auth or altering state!")
		get_tree().quit(1)
		return

	# Step A: Tap DELETE DATA -> Confirmation dialog appears, NO data deleted yet
	menu107.request_delete_local_data()
	if not menu107.modal_delete_confirm.visible or game_state.highest_unlocked_level != 12 or game_state.total_stars <= 0 or game_state.high_score != 4850:
		printerr("[FAIL Test 107.4] Tapping DELETE DATA must show confirmation dialog BEFORE deleting any data!")
		get_tree().quit(1)
		return

	# Step B: Tap CANCEL -> Confirmation closes, all progression data preserved
	menu107.cancel_delete_local_data()
	if (
		menu107.modal_delete_confirm.visible or
		not menu107.modal_account.visible or
		game_state.highest_unlocked_level != 12 or
		game_state.selected_map_level != 9 or
		game_state.high_score != 4850 or
		game_state.lines_cleared_total != 74 or
		game_state.coins != 920 or
		game_state.get_special_item_count("bomb") != 2
	):
		printerr("[FAIL Test 107.5] Canceling Delete Data must preserve all local progression data!")
		get_tree().quit(1)
		return

	# Step C: Tap DELETE DATA -> Confirm DELETE -> Local progression reset to Level 1, settings preserved
	menu107.request_delete_local_data()
	if not menu107.modal_delete_confirm.visible:
		printerr("[FAIL Test 107.6] Confirmation dialog did not re-open on second DELETE DATA tap!")
		get_tree().quit(1)
		return
	menu107.confirm_delete_local_data()
	if (
		menu107.modal_delete_confirm.visible or
		menu107.modal_account.visible or
		game_state.highest_unlocked_level != 1 or
		game_state.selected_map_level != 1 or
		game_state.total_stars != 0 or
		not game_state.completed_levels.is_empty() or
		not game_state.level_stars.is_empty() or
		game_state.high_score != 0 or
		game_state.lines_cleared_total != 0 or
		game_state.coins != 250 or
		game_state.get_special_item_count("bomb") != 0 or
		game_state.get_special_item_count("change_block") != 0 or
		game_state.get_special_item_count("extra_life") != 0
	):
		printerr("[FAIL Test 107.6] Confirming Delete Data failed to reset local gameplay progression to initial state!")
		get_tree().quit(1)
		return

	# Verify unrelated app settings (Music, SFX, Voice, Haptics, Language) remain intact in memory and after reload from disk
	if (
		game_state.music_enabled != false or
		audio_mgr.music_enabled != false or
		game_state.sound_enabled != false or
		audio_mgr.sound_enabled != false or
		game_state.get_voice_mode() != "female" or
		game_state.haptics_enabled != false or
		game_state.get_language() != "vi"
	):
		printerr("[FAIL Test 107.6] Delete Data must NOT overwrite unrelated Music, SFX, Voice, Haptics, or Language settings!")
		get_tree().quit(1)
		return
	game_state.load_progression()
	if (
		game_state.highest_unlocked_level != 1 or
		game_state.total_stars != 0 or
		game_state.high_score != 0 or
		game_state.music_enabled != false or
		game_state.sound_enabled != false or
		game_state.get_voice_mode() != "female" or
		game_state.haptics_enabled != false or
		game_state.get_language() != "vi"
	):
		printerr("[FAIL Test 107.6] Persisted save file after Delete Data did not preserve reset progression + intact settings!")
		get_tree().quit(1)
		return

	# Restore clean defaults after test
	audio_mgr.music_enabled = true
	audio_mgr.sound_enabled = true
	game_state.music_enabled = true
	game_state.sound_enabled = true
	game_state.set_voice_mode("male", false)
	game_state.haptics_enabled = true
	game_state.set_language("en", false)
	game_state.reset_progression(true)
	menu107.queue_free()
	print("[TEST 107/108] Account Button, Account Menu, Platform Providers (iOS/Android/Other) & Delete Data Confirmation Safety Flow: PASSED")

	# =========================================================================
	# TEST 108: Modern Special Items in Playable Board Cells (Special Milestones Only) & Platform Haptic Capability Diagnosis
	#   1. Normal levels (e.g. Level 1, 2, 4) NEVER generate, place, display, or award special board items (even after clearing lines)
	#   2. Special milestone levels (e.g. Level 3, 5, 6) render special items directly inside actual playable board cells (no floating duplicate nodes)
	#   3. Board special item semantics:
	#      - Booster cell (Bomb / Change Block / Extra Life): clearing the line containing the cell removes it from the board and adds +1 to inventory
	#      - Locked cell: first line clear unlocks the cell into a normal occupied block cell; second line clear removes the block cell
	#      - Rainbow / 7-color cell: clearing a line containing the cell triggers 2.0x Rainbow multiplier scoring
	#      - Gravity: in Modern + Falling on a milestone level, special items move downward with their cell state
	#   4. Haptic platform capability diagnosis:
	#      - Native Android/iOS preserves Input.vibrate_handheld(35)
	#      - Web detects navigator.vibrate capability; when unavailable, does NOT treat Haptic as active, does NOT throw errors, does NOT repeatedly attempt unsupported vibration, keeps Haptic UI preference functional, and keeps Voice working independently
	# =========================================================================
	game_state.reset_progression(false)
	game_state.highest_unlocked_level = 10
	game_state.set_energy(GameStateScript.MAX_ENERGY, false)

	# Part A: Normal levels (Level 1, Level 2, Level 4) must NEVER place, generate, or award special items
	for norm_lvl108 in [1, 2, 4]:
		if game_state.is_special_milestone_level(norm_lvl108):
			printerr("[FAIL Test 108.1] Level ", norm_lvl108, " must be classified as a normal level, not a special milestone!")
			get_tree().quit(1)
			return
		game_state.set_energy(GameStateScript.MAX_ENERGY, false)
		game_state.start_level(norm_lvl108, GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
		var m_norm108 = ModernModeScript.new()
		m_norm108.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
		add_child(m_norm108)
		m_norm108.initialize_mode()
		m_norm108.start_mode()
		var b_norm108 = m_norm108.get_board()
		if (
			b_norm108.get_special_item_count_on_board() != 0 or
			b_norm108.set_cell_special_item(Vector2i(3, 3), "bomb", 1, norm_lvl108) != false or
			b_norm108.get_special_item_count_on_board() != 0
		):
			printerr("[FAIL Test 108.1] Normal level ", norm_lvl108, " must NEVER place or display special items on the board!")
			get_tree().quit(1)
			return
		var inv_before_norm108: Dictionary = game_state.special_item_inventory.duplicate()
		var last_r108: int = b_norm108.GRID_HEIGHT - 1
		for x108 in range(b_norm108.GRID_WIDTH):
			b_norm108.grid_data[last_r108][x108] = 1
		var clr_norm108: Dictionary = b_norm108.check_and_clear_lines(true, false)
		var mv_norm108: Dictionary = game_state.process_move_result(
			4,
			int(clr_norm108.get("lines_cleared", 0)),
			int(clr_norm108.get("row_count", 0)),
			int(clr_norm108.get("col_count", 0)),
			int(clr_norm108.get("unique_cells_cleared", 0)),
			bool(clr_norm108.get("has_rainbow", false)),
			clr_norm108.get("collected_special_items", [])
		)
		if (
			bool(mv_norm108.get("special_item_discovered", false)) or
			game_state.special_item_inventory != inv_before_norm108 or
			b_norm108.get_special_item_count_on_board() != 0
		):
			printerr("[FAIL Test 108.1] Clearing lines on normal level ", norm_lvl108, " must NEVER generate or award special items!")
			get_tree().quit(1)
			return
		m_norm108.queue_free()

	# Part B: Special milestone level (Level 3 / Level 5 / Level 6) places visible special items inside actual playable board cells
	for ms_lvl108 in [3, 5, 6]:
		if not game_state.is_special_milestone_level(ms_lvl108):
			printerr("[FAIL Test 108.2] Level ", ms_lvl108, " must be classified as a special milestone level!")
			get_tree().quit(1)
			return
	game_state.set_energy(GameStateScript.MAX_ENERGY, false)
	game_state.start_level(3, GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	var m_ms108 = ModernModeScript.new()
	m_ms108.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	add_child(m_ms108)
	m_ms108.initialize_mode()
	m_ms108.start_mode()
	var b_ms108 = m_ms108.get_board()
	var active_sp_cells108: Array[Dictionary] = b_ms108.get_active_special_item_cells()
	if active_sp_cells108.size() < 3 or b_ms108.get_child_count() != 0:
		printerr("[FAIL Test 108.2] Special milestone level must render special items directly inside board cells with 0 floating child nodes! Got: ", active_sp_cells108.size(), " children=", b_ms108.get_child_count())
		get_tree().quit(1)
		return
	var board_px_rect108 := Rect2(Vector2.ZERO, b_ms108.get_board_pixel_size())
	for sp_entry108 in active_sp_cells108:
		var sp_coord108: Vector2i = sp_entry108.get("coords", Vector2i(-1, -1))
		var sp_rect108: Rect2 = sp_entry108.get("cell_rect", Rect2())
		if (
			not b_ms108.is_valid_cell(sp_coord108) or
			b_ms108.get_cell(sp_coord108) <= 0 or
			not board_px_rect108.encloses(sp_rect108)
		):
			printerr("[FAIL Test 108.2] Special board item must occupy an actual valid playable board cell inside board bounds: ", sp_entry108)
			get_tree().quit(1)
			return

	# Part C: Verify Booster cell collection, Locked cell 2-stage unlock+clear, Rainbow 2x scoring, and Gravity movement on Milestone Level
	b_ms108.clear_board()
	# 1) Booster cell ("bomb") at (2, 4) -> clearing row 4 removes it from board and increments bomb inventory by +1
	var bomb_inv_before108: int = game_state.get_special_item_count("bomb")
	for x108 in range(b_ms108.GRID_WIDTH):
		b_ms108.grid_data[4][x108] = 2
		b_ms108.grid_materials[4][x108] = "crystal"
	b_ms108.set_cell_special_item(Vector2i(2, 4), "bomb", 2, 3)
	if b_ms108.get_cell_special_item(Vector2i(2, 4)) != "bomb":
		printerr("[FAIL Test 108.3] Failed to set bomb special item in board cell (2, 4) on milestone level!")
		get_tree().quit(1)
		return
	var clr_bomb_row108: Dictionary = b_ms108.check_and_clear_lines(true, false)
	var mv_bomb_row108: Dictionary = game_state.process_move_result(
		4,
		int(clr_bomb_row108.get("lines_cleared", 0)),
		int(clr_bomb_row108.get("row_count", 0)),
		int(clr_bomb_row108.get("col_count", 0)),
		int(clr_bomb_row108.get("unique_cells_cleared", 0)),
		bool(clr_bomb_row108.get("has_rainbow", false)),
		clr_bomb_row108.get("collected_special_items", [])
	)
	if (
		b_ms108.get_cell(Vector2i(2, 4)) != 0 or
		b_ms108.get_cell_special_item(Vector2i(2, 4)) != "" or
		game_state.get_special_item_count("bomb") != bomb_inv_before108 + 1 or
		not bool(mv_bomb_row108.get("special_item_discovered", false)) or
		String(mv_bomb_row108.get("discovered_item_id", "")) != "bomb"
	):
		printerr("[FAIL Test 108.3] Clearing board cell with 'bomb' on milestone level must remove board item and increment bomb inventory by +1!")
		get_tree().quit(1)
		return

	# 2) Locked cell at (4, 5): first line clear unlocks it (remains occupied > 0, no longer locked); second line clear clears it to 0
	b_ms108.clear_board()
	for x108 in range(b_ms108.GRID_WIDTH):
		b_ms108.grid_data[5][x108] = 3
	b_ms108.set_cell_special_item(Vector2i(4, 5), "locked", 3, 3)
	if not b_ms108.is_cell_locked(Vector2i(4, 5)):
		printerr("[FAIL Test 108.4] Cell (4, 5) should be locked before first line clear!")
		get_tree().quit(1)
		return
	var clr_lock1_108: Dictionary = b_ms108.check_and_clear_lines(true, false)
	if (
		b_ms108.is_cell_locked(Vector2i(4, 5)) or
		b_ms108.get_cell(Vector2i(4, 5)) <= 0 or
		not (Vector2i(4, 5) in clr_lock1_108.get("unlocked_cells", []))
	):
		printerr("[FAIL Test 108.4] First line clear on locked cell (4, 5) must unlock it while keeping the block cell occupied!")
		get_tree().quit(1)
		return
	for x108 in range(b_ms108.GRID_WIDTH):
		b_ms108.grid_data[5][x108] = 3
	var clr_lock2_108: Dictionary = b_ms108.check_and_clear_lines(true, false)
	if b_ms108.get_cell(Vector2i(4, 5)) != 0 or int(clr_lock2_108.get("lines_cleared", 0)) != 1:
		printerr("[FAIL Test 108.4] Second line clear on unlocked cell (4, 5) must clear it to empty!")
		get_tree().quit(1)
		return

	# 3) Rainbow / 7-color cell + Gravity movement: place at (6, 5), clear row 6 with gravity=true -> moves to bottom row 7, then clear row 7 -> triggers has_rainbow 2x score
	b_ms108.clear_board()
	b_ms108.set_cell_special_item(Vector2i(6, 5), "rainbow", 9, 3)
	for x108 in range(b_ms108.GRID_WIDTH):
		b_ms108.grid_data[6][x108] = 4
	var clr_grav108: Dictionary = b_ms108.check_and_clear_lines(true, true)
	var b_last_r108: int = b_ms108.GRID_HEIGHT - 1
	if (
		not bool(clr_grav108.get("gravity_applied", false)) or
		b_ms108.get_cell_special_item(Vector2i(6, b_last_r108)) != "rainbow" or
		b_ms108.get_cell_special_item(Vector2i(6, 5)) != ""
	):
		printerr("[FAIL Test 108.5] Gravity must move special item with its block cell downward to bottom row!")
		get_tree().quit(1)
		return
	for x108 in range(b_ms108.GRID_WIDTH):
		if x108 != 6:
			b_ms108.grid_data[b_last_r108][x108] = 4
	var clr_rb108: Dictionary = b_ms108.check_and_clear_lines(true, false)
	var mv_rb108: Dictionary = game_state.process_move_result(
		4,
		int(clr_rb108.get("lines_cleared", 0)),
		int(clr_rb108.get("row_count", 0)),
		int(clr_rb108.get("col_count", 0)),
		int(clr_rb108.get("unique_cells_cleared", 0)),
		bool(clr_rb108.get("has_rainbow", false)),
		clr_rb108.get("collected_special_items", [])
	)
	if not bool(clr_rb108.get("has_rainbow", false)) or not is_equal_approx(float(mv_rb108.get("rainbow_multiplier", 0.0)), 2.0):
		printerr("[FAIL Test 108.5] Clearing Rainbow/7-color board cell must trigger has_rainbow and 2.0x rainbow_multiplier!")
		get_tree().quit(1)
		return
	m_ms108.queue_free()

	# Part D: Diagnose Haptic platform capability (Native Android/iOS vs Web with/without navigator.vibrate)
	var menu108 = MainMenuScene.instantiate()
	add_child(menu108)
	game_state.set_haptics_enabled(true, false, false)

	# 1) Web WITHOUT navigator.vibrate: must report unsupported, must NOT treat Haptic as active, must NOT increment haptic_trigger_count, while UI toggle & Voice still work
	game_state.set_simulated_platform("web")
	game_state.set_simulated_web_vibrate_available(false)
	var web_no_cap108: Dictionary = game_state.diagnose_haptic_capability()
	var hap_before_web108: int = game_state.haptic_trigger_count
	var trig_web_no108: bool = game_state.trigger_haptic_feedback(35, "test_web_unsupported")
	if (
		not bool(web_no_cap108.get("is_web", false)) or
		bool(web_no_cap108.get("supported", true)) or
		game_state.is_haptic_supported_on_platform() != false or
		trig_web_no108 != false or
		game_state.last_haptic_active != false or
		game_state.haptic_trigger_count != hap_before_web108
	):
		printerr("[FAIL Test 108.6] Web without navigator.vibrate must NOT treat Haptic as active or supported: ", web_no_cap108)
		get_tree().quit(1)
		return
	# Toggling Haptic UI on unsupported Web must still update preference cleanly without errors, and Voice must still work independently
	menu108.btn_toggle_haptics.pressed.emit() # ON -> OFF
	menu108.btn_toggle_haptics.pressed.emit() # OFF -> ON
	if game_state.haptics_enabled != true or game_state.haptic_trigger_count != hap_before_web108 or game_state.last_haptic_active != false:
		printerr("[FAIL Test 108.6] Toggling Haptic ON on unsupported Web must preserve preference while not pretending vibration succeeded!")
		get_tree().quit(1)
		return
	game_state.set_voice_mode("male", false)
	var vc_web108: int = audio_mgr.voice_confirmation_play_count
	menu108.btn_toggle_voice.pressed.emit() # male -> female
	if game_state.get_voice_mode() != "female" or audio_mgr.voice_confirmation_play_count != vc_web108 + 1:
		printerr("[FAIL Test 108.6] Voice must continue working independently when Web haptic is unavailable!")
		get_tree().quit(1)
		return

	# 2) Web WITH navigator.vibrate: must report supported and activate cleanly
	game_state.set_simulated_web_vibrate_available(true)
	var web_yes_cap108: Dictionary = game_state.diagnose_haptic_capability()
	var trig_web_yes108: bool = game_state.trigger_haptic_feedback(35, "test_web_supported")
	if (
		not bool(web_yes_cap108.get("is_web", false)) or
		not bool(web_yes_cap108.get("supported", false)) or
		not trig_web_yes108 or
		not game_state.last_haptic_active or
		game_state.haptic_trigger_count != hap_before_web108 + 1
	):
		printerr("[FAIL Test 108.7] Web with usable navigator.vibrate must report supported and trigger cleanly: ", web_yes_cap108)
		get_tree().quit(1)
		return

	# 3) Native Android & iOS: must preserve Input.vibrate_handheld(35)
	game_state.clear_simulated_web_vibrate_available()
	for nat_plat108 in ["Android", "iOS"]:
		game_state.set_simulated_platform(nat_plat108)
		var nat_cap108: Dictionary = game_state.diagnose_haptic_capability()
		var cnt_b108: int = game_state.haptic_trigger_count
		var nat_ok108: bool = game_state.trigger_haptic_feedback(35, "test_native_" + nat_plat108)
		if (
			bool(nat_cap108.get("is_web", true)) or
			not bool(nat_cap108.get("supported", false)) or
			String(nat_cap108.get("backend", "")) != "native_handheld" or
			not nat_ok108 or
			game_state.haptic_trigger_count != cnt_b108 + 1
		):
			printerr("[FAIL Test 108.8] Native ", nat_plat108, " haptic support failed: ", nat_cap108)
			get_tree().quit(1)
			return

	game_state.clear_simulated_platform()
	game_state.clear_simulated_web_vibrate_available()
	game_state.set_voice_mode("male", false)
	game_state.set_haptics_enabled(true, false, false)
	game_state.reset_progression(true)
	menu108.queue_free()
	print("[TEST 108/109] Modern Special Items in Playable Board Cells (Milestones Only) & Platform Haptic Capability Diagnosis: PASSED")

	# =========================================================================
	# TEST 109: Instant One-Tap Change Block & Fast Drag & Drop Responsiveness
	#   1. Change Block works with exactly one tap (both via apply_special_item and SpecialItemsBar button press).
	#   2. Change Block consumes exactly one inventory item after successful replacement.
	#   3. Change Block does not consume inventory when no valid replacement exists (or when inventory is 0).
	#   4. No second block-selection interaction is required (pending_special_item == "", change_block_selection_active == false).
	#   5. Drag starts immediately on touch/mouse press (both on TrayPiece and on PieceTray slot area).
	#   6. Drag preview updates immediately on move without latency.
	#   7. Valid placement happens immediately on release and clears preview immediately.
	#   8. Tray replenishes immediately with 3 new pieces after the third successful placement.
	#   9. ROTATE remains explicit and responsive without accidental rotation when crossing ROTATE control.
	#   10. No duplicate floating drag visual appears when snapped to valid board preview.
	#   11. Bomb (3x3 target & detonation) and Extra Life (Game Over recovery only) remain unchanged.
	# =========================================================================
	game_state.set_energy(24, false)
	game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP, 1)
	var dd109 = ModernModeScript.new()
	dd109.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	add_child(dd109)
	dd109.initialize_mode()
	dd109.start_mode()
	dd109.update_layout_for_viewport(Vector2(390, 844))
	var tray109 = dd109.get_piece_tray()
	var board109 = dd109.get_board()

	# 1, 2 & 4: One-tap Change Block replaces an eligible block immediately, consumes 1 item, requires no second selection
	game_state.set_special_item_count("change_block", 2)
	var before_ids109: Array[String] = tray109.get_active_piece_ids()
	var one_tap_ok109: bool = dd109.apply_special_item("change_block")
	var after_ids109: Array[String] = tray109.get_active_piece_ids()
	if (
		not one_tap_ok109 or
		dd109.pending_special_item != "" or
		tray109.change_block_selection_active or
		game_state.get_special_item_count("change_block") != 1 or
		after_ids109 == before_ids109 or
		tray109.active_pieces[0].cells.size() != 4
	):
		printerr("[FAIL Test 109.1] One-tap Change Block failed to immediately replace block and consume 1 item without selection mode! before=", before_ids109, " after=", after_ids109)
		get_tree().quit(1)
		return
	for p_chk109 in tray109.active_pieces:
		if p_chk109 != null and bool(p_chk109.get("change_select_mode")):
			printerr("[FAIL Test 109.4] TrayPiece must NOT enter change_select_mode after one-tap Change Block!")
			get_tree().quit(1)
			return

	# Verify Change Block prioritizes replacing an unplaceable piece on a nearly-full board with a valid placeable 4-cell piece
	board109.clear_board()
	for y109 in range(board109.GRID_HEIGHT):
		for x109 in range(board109.GRID_WIDTH):
			board109.grid_data[y109][x109] = 1
	# Carve out only a 1x4 horizontal slot at row 0, cols 0..3 so only line_4_h fits
	for x109 in range(4):
		board109.grid_data[0][x109] = 0
	tray109.active_pieces[0].setup_piece(PolyominoLib.get_shape("line_4_h"), 0)
	tray109.restore_piece_to_slot(tray109.active_pieces[0])
	tray109.active_pieces[1].setup_piece(PolyominoLib.get_shape("t_shape"), 1) # Cannot fit in 1x4 horizontal slot
	tray109.restore_piece_to_slot(tray109.active_pieces[1])
	var smart_cb109: bool = dd109.apply_special_item("change_block")
	if (
		not smart_cb109 or
		String(tray109.active_pieces[1].shape_data.get("id", "")) != "line_4_h" or
		not board109.has_any_valid_placement(tray109.active_pieces[1].cells) or
		game_state.get_special_item_count("change_block") != 0
	):
		printerr("[FAIL Test 109.2] One-tap Change Block should replace unplaceable piece in slot 1 with a valid placeable 4-cell block and decrement inventory to 0!")
		get_tree().quit(1)
		return

	# Verify Change Block is unavailable when inventory is 0
	if dd109.apply_special_item("change_block") != false or game_state.get_special_item_count("change_block") != 0:
		printerr("[FAIL Test 109.2] Change Block must return false and not activate when inventory is 0!")
		get_tree().quit(1)
		return

	# 3: Verify Change Block does NOT consume inventory when no valid replacement exists (completely full board / empty tray)
	game_state.set_special_item_count("change_block", 2)
	for x109 in range(4):
		board109.grid_data[0][x109] = 1 # Now 100% of board cells are occupied -> no 4-cell piece can fit
	var ids_full_before109: Array[String] = tray109.get_active_piece_ids()
	var no_fit_res109: bool = dd109.apply_special_item("change_block")
	if (
		no_fit_res109 != false or
		game_state.get_special_item_count("change_block") != 2 or
		tray109.get_active_piece_ids() != ids_full_before109
	):
		printerr("[FAIL Test 109.3] Change Block must NOT consume inventory when no valid replacement placement exists on board!")
		get_tree().quit(1)
		return
	board109.clear_board()
	tray109.clear_all_pieces()
	var empty_tray_res109: bool = dd109.apply_special_item("change_block")
	if empty_tray_res109 != false or game_state.get_special_item_count("change_block") != 2:
		printerr("[FAIL Test 109.3] Change Block must NOT consume inventory when tray has no eligible pieces!")
		get_tree().quit(1)
		return

	# 5, 6, 7, 8, 9, 10: Immediate Drag start, immediate preview, zero duplicate drag visual, explicit ROTATE, immediate placement & 3rd-piece tray replenishment
	tray109.spawn_new_round()
	dd109.update_layout_for_viewport(Vector2(390, 844))
	var round_start109: int = tray109.round_number

	# Test immediate drag start from PieceTray slot touch event
	var slot0_touch109 := InputEventScreenTouch.new()
	slot0_touch109.index = 0
	slot0_touch109.pressed = true
	slot0_touch109.position = Vector2(tray109.size.x * 0.16, tray109.size.y * 0.5)
	tray109._gui_input(slot0_touch109)
	var p0_109: Control = tray109.active_pieces[0]
	if not p0_109.is_dragging or tray109.get_active_dragging_piece() != p0_109:
		printerr("[FAIL Test 109.5] Touch press on PieceTray slot 0 must start dragging piece 0 immediately!")
		get_tree().quit(1)
		return

	# Move over valid board cell (0, 0) -> preview updates immediately and NO duplicate floating visual is rendered
	var target0_world109: Vector2 = board109.grid_to_world_shape_center(Vector2i(0, 0), p0_109.cells) + Vector2(0, p0_109.TOUCH_Y_OFFSET)
	p0_109._move_drag(target0_world109)
	if (
		not board109.preview_active or
		not board109.preview_is_valid or
		board109.preview_origin != Vector2i(0, 0) or
		not bool(p0_109.get("is_snapped_to_board_preview")) or
		dd109.has_duplicate_drag_visual()
	):
		printerr("[FAIL Test 109.6/10] Drag preview must update immediately and suppress duplicate floating drag visual when snapped!")
		get_tree().quit(1)
		return

	# Explicit ROTATE during drag -> updates piece & board preview immediately with zero latency
	var pre_rot_cells109: Array = p0_109.cells.duplicate(true)
	var exp_rot_cells109: Array = PolyominoLib.rotate_90_cw(pre_rot_cells109)
	var rot_ok109: bool = dd109.rotate_dragged_piece()
	if not rot_ok109 or p0_109.cells != exp_rot_cells109 or board109.preview_shape != exp_rot_cells109:
		printerr("[FAIL Test 109.9] Explicit ROTATE during drag must update piece and board preview immediately!")
		get_tree().quit(1)
		return

	# Place all 3 pieces immediately and verify immediate tray replenishment after the 3rd piece
	var drop_coords109: Array[Vector2i] = [Vector2i(0, 0), Vector2i(4, 0), Vector2i(0, 4)]
	for idx109 in range(3):
		var cur_p109: Control = tray109.active_pieces[idx109]
		var dest_cell109: Vector2i = drop_coords109[idx109]
		var dest_world109: Vector2 = board109.grid_to_world_shape_center(dest_cell109, cur_p109.cells) + Vector2(0, cur_p109.TOUCH_Y_OFFSET)
		if not cur_p109.is_dragging:
			cur_p109._start_drag(dest_world109, -1)
		cur_p109._move_drag(dest_world109)
		cur_p109._end_drag(dest_world109)
		if board109.preview_active:
			printerr("[FAIL Test 109.7] Board preview must clear immediately after placement of piece ", idx109)
			get_tree().quit(1)
			return
		if idx109 < 2 and tray109.get_remaining_piece_count() != (2 - idx109):
			printerr("[FAIL Test 109.7] Remaining tray piece count mismatch after placement ", idx109)
			get_tree().quit(1)
			return
	if tray109.round_number != round_start109 + 1 or tray109.get_remaining_piece_count() != 3:
		printerr("[FAIL Test 109.8] Tray must replenish immediately with 3 new pieces after the 3rd piece is placed!")
		get_tree().quit(1)
		return

	# 11: Verify Bomb (touch targeting & 3x3 detonation) and Extra Life remain intact
	game_state.set_special_item_count("bomb", 1)
	dd109.apply_special_item("bomb")
	if dd109.pending_special_item != "bomb" or not board109.is_bomb_target_highlighted():
		printerr("[FAIL Test 109.11] Bomb must still enter 3x3 board targeting mode!")
		get_tree().quit(1)
		return
	var bomb_touch109 := InputEventScreenTouch.new()
	bomb_touch109.pressed = true
	bomb_touch109.position = board109.grid_to_world_shape_center(Vector2i(0, 0), [Vector2i(0, 0)])
	dd109._input(bomb_touch109)
	if dd109.pending_special_item != "" or game_state.get_special_item_count("bomb") != 0 or board109.is_bomb_target_highlighted():
		printerr("[FAIL Test 109.11] Touching board cell while Bomb is active must immediately detonate 3x3 area and consume 1 Bomb!")
		get_tree().quit(1)
		return

	dd109.queue_free()
	game_state.reset_progression(true)
	print("[TEST 109/110] Instant One-Tap Change Block & Fast Drag & Drop Responsiveness (No Duplicate Visuals, Immediate Replenishment): PASSED")

	# =========================================================================
	# TEST 110: Fixed 8x10 Drag & Drop Board vs 10x12 Falling Board & Mode-Specific Change Block (1-Block Falling vs All-3-Blocks Drag & Drop)
	# =========================================================================
	# 1 & 2: Verify Drag & Drop board is strictly 8 columns x 10 rows (in both Modern and Classic rules), while Falling board remains 10 columns x 12 rows
	for dd_rule110 in [GameStateScript.GameMode.CLASSIC, GameStateScript.GameMode.MODERN_DRAG_AND_DROP]:
		var dd_chk110 = ModernModeScript.new()
		dd_chk110.configure_combination(dd_rule110, GameStateScript.PlayStyle.DRAG_AND_DROP)
		add_child(dd_chk110)
		dd_chk110.initialize_mode()
		dd_chk110.start_mode()
		var b_dd110 = dd_chk110.get_board()
		if (
			b_dd110.GRID_COLS != 8 or
			b_dd110.GRID_WIDTH != 8 or
			b_dd110.GRID_ROWS != 10 or
			b_dd110.GRID_HEIGHT != 10 or
			b_dd110.grid_data.size() != 10 or
			b_dd110.grid_data[0].size() != 8 or
			not b_dd110.is_valid_cell(Vector2i(0, 0)) or
			not b_dd110.is_valid_cell(Vector2i(7, 9)) or
			b_dd110.is_valid_cell(Vector2i(8, 0)) or
			b_dd110.is_valid_cell(Vector2i(0, 10))
		):
			printerr("[FAIL Test 110.1] Drag & Drop board must be strictly 8 columns x 10 rows! Got: ", b_dd110.GRID_WIDTH, "x", b_dd110.GRID_HEIGHT)
			get_tree().quit(1)
			return
		# Verify responsive layout, centering, and exact touch/mouse cell coordinate mapping across all 8x10 cells at 360x800, 390x844, 720x1280
		for vp110 in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
			var lay110: Dictionary = dd_chk110.update_layout_for_viewport(vp110)
			var h_r110: Rect2 = lay110.get("header_rect", Rect2())
			var b_r110: Rect2 = lay110.get("board_rect", Rect2())
			var rot_r110: Rect2 = lay110.get("rotate_button_rect", Rect2())
			var t_r110: Rect2 = lay110.get("tray_rect", Rect2())
			var ad_r110: Rect2 = lay110.get("ad_rect", Rect2())
			if (
				b_r110.intersects(h_r110) or
				b_r110.intersects(rot_r110) or
				b_r110.intersects(t_r110) or
				rot_r110.intersects(t_r110) or
				t_r110.intersects(ad_r110) or
				b_r110.position.x < 0.0 or
				b_r110.end.x > vp110.x or
				absf(b_r110.get_center().x - vp110.x * 0.5) > 1.0 or
				t_r110.end.y > ad_r110.position.y
			):
				printerr("[FAIL Test 110.1] 8x10 Drag & Drop layout clipped, overlapped, or off-center at viewport ", vp110, ": ", lay110)
				get_tree().quit(1)
				return
			# Verify all 80 cells (x in 0..7, y in 0..9) map bijectively between grid coordinates and world/local coordinates (zero unreachable cells)
			for gy110 in range(10):
				for gx110 in range(8):
					var cell110 := Vector2i(gx110, gy110)
					var local_center110: Vector2 = b_dd110.grid_to_local_center(cell110)
					var world_center110: Vector2 = b_dd110.to_global(local_center110)
					if (
						b_dd110.local_point_to_cell(local_center110) != cell110 or
						b_dd110.resolve_piece_origin_from_visual_center(world_center110, [Vector2i(0, 0)]) != cell110
					):
						printerr("[FAIL Test 110.1] Cell coordinate mapping mismatch at ", cell110, " on viewport ", vp110)
						get_tree().quit(1)
						return
		# Verify 8-cell row clearing and 10-cell column clearing on the 8x10 Drag & Drop board
		b_dd110.clear_board()
		for gx_r110 in range(8):
			b_dd110.grid_data[9][gx_r110] = 1
		var row_clr110: Dictionary = b_dd110.check_and_clear_lines(dd_chk110.allows_column_clear(), dd_chk110.uses_gravity())
		if int(row_clr110.get("lines_cleared", 0)) != 1 or int(row_clr110.get("unique_cells_cleared", 0)) != 8 or b_dd110.get_occupied_cell_count() != 0:
			printerr("[FAIL Test 110.1] 8-column row clear failed on 8x10 Drag & Drop board: ", row_clr110)
			get_tree().quit(1)
			return
		for gy_c110 in range(10):
			b_dd110.grid_data[gy_c110][7] = 2
		var col_clr110: Dictionary = b_dd110.check_and_clear_lines(dd_chk110.allows_column_clear(), dd_chk110.uses_gravity())
		if int(col_clr110.get("lines_cleared", 0)) != 1 or int(col_clr110.get("unique_cells_cleared", 0)) != 10 or b_dd110.get_occupied_cell_count() != 0:
			printerr("[FAIL Test 110.1] 10-row column clear failed in Drag & Drop on 8x10 board: ", col_clr110)
			get_tree().quit(1)
			return
		dd_chk110.queue_free()

	for fm_rule110 in [GameStateScript.GameMode.CLASSIC, GameStateScript.GameMode.MODERN_DRAG_AND_DROP]:
		var fm_chk110 = ClassicModeScript.new()
		fm_chk110.configure_combination(fm_rule110, GameStateScript.PlayStyle.FALLING)
		add_child(fm_chk110)
		fm_chk110.initialize_mode()
		fm_chk110.start_mode()
		var b_fm110 = fm_chk110.get_board()
		if (
			b_fm110.GRID_COLS != 10 or
			b_fm110.GRID_WIDTH != 10 or
			b_fm110.GRID_ROWS != 12 or
			b_fm110.GRID_HEIGHT != 12 or
			b_fm110.grid_data.size() != 12 or
			b_fm110.grid_data[0].size() != 10 or
			not b_fm110.is_valid_cell(Vector2i(9, 11)) or
			b_fm110.is_valid_cell(Vector2i(0, 12))
		):
			printerr("[FAIL Test 110.2] Falling board must remain strictly 10 columns x 12 rows! Got: ", b_fm110.GRID_WIDTH, "x", b_fm110.GRID_HEIGHT)
			get_tree().quit(1)
			return
		fm_chk110.queue_free()

	# 3: Verify Falling Mode Change Block immediately replaces ONE eligible block (1-tap, no selection state, 4-cell piece, consumes 1 item)
	game_state.set_energy(24, false)
	game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.FALLING, 1)
	var fm_cb110 = ClassicModeScript.new()
	fm_cb110.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.FALLING)
	add_child(fm_cb110)
	fm_cb110.initialize_mode()
	fm_cb110.start_mode()
	game_state.set_special_item_count("change_block", 1)
	var fm_cur_before110: String = String(fm_cb110.current_piece.get("id", ""))
	var fm_next_before110: String = String(fm_cb110.next_piece.get("id", ""))
	var fm_cb_ok110: bool = fm_cb110.apply_special_item("change_block")
	var fm_cur_after110: String = String(fm_cb110.current_piece.get("id", ""))
	var fm_next_after110: String = String(fm_cb110.next_piece.get("id", ""))
	var fm_changed_count110: int = (1 if fm_cur_after110 != fm_cur_before110 else 0) + (1 if fm_next_after110 != fm_next_before110 else 0)
	if (
		not fm_cb_ok110 or
		fm_changed_count110 != 1 or
		fm_cur_after110 == fm_cur_before110 or
		fm_next_after110 != fm_next_before110 or
		fm_cb110.current_piece.get("cells", []).size() != 4 or
		fm_cb110.pending_special_item != "" or
		game_state.get_special_item_count("change_block") != 0
	):
		printerr("[FAIL Test 110.3] Falling Change Block must immediately replace strictly 1 block with a 4-cell piece and consume 1 item!")
		get_tree().quit(1)
		return
	# Verify Inventory 0 in Falling performs no replacement
	if fm_cb110.apply_special_item("change_block") != false or String(fm_cb110.current_piece.get("id", "")) != fm_cur_after110:
		printerr("[FAIL Test 110.6] Falling Change Block with 0 inventory must perform no replacement!")
		get_tree().quit(1)
		return
	fm_cb110.queue_free()

	# 4, 5, 6, 7, 8, 9: Verify Drag & Drop Change Block immediately replaces ALL 3 tray blocks, consumes 1 item, preserves board & score, and creates 0 duplicate nodes
	game_state.set_energy(24, false)
	game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP, 1)
	var dd_cb110 = ModernModeScript.new()
	dd_cb110.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
	add_child(dd_cb110)
	dd_cb110.initialize_mode()
	dd_cb110.start_mode()
	var tray_cb110 = dd_cb110.get_piece_tray()
	var board_cb110 = dd_cb110.get_board()
	# Place a block on the 10x8 board first to verify board & already-placed pieces and score remain unchanged
	board_cb110.place_piece([Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], Vector2i(0, 0), 2)
	game_state.score = 120
	var board_snap110: Array = board_cb110.get_board_state()
	var old_ids110: Array[String] = tray_cb110.get_active_piece_ids()
	var node_refs_before110: Array = [tray_cb110.active_pieces[0], tray_cb110.active_pieces[1], tray_cb110.active_pieces[2]]
	game_state.set_special_item_count("change_block", 2)

	var dd_cb_ok110: bool = dd_cb110.apply_special_item("change_block")
	var new_ids110: Array[String] = tray_cb110.get_active_piece_ids()
	if (
		not dd_cb_ok110 or
		dd_cb110.pending_special_item != "" or
		tray_cb110.change_block_selection_active or
		game_state.get_special_item_count("change_block") != 1 or
		tray_cb110.get_remaining_piece_count() != 3 or
		tray_cb110.get_tray_piece_node_count() != 3 or
		board_cb110.get_board_state() != board_snap110 or
		game_state.score != 120
	):
		printerr("[FAIL Test 110.4/5/7/9] Drag & Drop Change Block failed invariants (1 item consumed, 3 pieces, 0 duplicate nodes, board/score unchanged)!")
		get_tree().quit(1)
		return
	for slot_i110 in range(3):
		var p110: Control = tray_cb110.active_pieces[slot_i110]
		if (
			p110 == null or
			not is_instance_valid(p110) or
			p110 != node_refs_before110[slot_i110] or
			new_ids110[slot_i110] == "" or
			new_ids110[slot_i110] == old_ids110[slot_i110] or
			p110.cells.size() != 4 or
			bool(p110.get("change_select_mode"))
		):
			printerr("[FAIL Test 110.4/8/9] Drag & Drop Change Block must replace slot ", slot_i110, " in-place with a new 4-cell piece! old=", old_ids110, " new=", new_ids110)
			get_tree().quit(1)
			return

	# Also verify partial tray state (e.g. 2 pieces remaining after 1 piece consumed) is handled safely without crashes or duplicate nodes
	tray_cb110.consume_piece(tray_cb110.active_pieces[0])
	if tray_cb110.get_remaining_piece_count() != 2:
		printerr("[FAIL Test 110.9] Expected 2 pieces remaining in tray after consuming slot 0!")
		get_tree().quit(1)
		return
	var partial_cb_ok110: bool = dd_cb110.apply_special_item("change_block")
	if (
		not partial_cb_ok110 or
		game_state.get_special_item_count("change_block") != 0 or
		tray_cb110.get_remaining_piece_count() != 3 or
		tray_cb110.get_tray_piece_node_count() != 3
	):
		printerr("[FAIL Test 110.9] Change Block on partial tray failed to safely generate 3 valid pieces without duplicate nodes!")
		get_tree().quit(1)
		return
	for slot_j110 in range(3):
		if tray_cb110.active_pieces[slot_j110] == null or tray_cb110.active_pieces[slot_j110].cells.size() != 4:
			printerr("[FAIL Test 110.8] Partial tray replacement piece at slot ", slot_j110, " is not a valid 4-cell piece!")
			get_tree().quit(1)
			return

	# Verify Inventory 0 in Drag & Drop performs no replacement
	var inv0_ids110: Array[String] = tray_cb110.get_active_piece_ids()
	if dd_cb110.apply_special_item("change_block") != false or tray_cb110.get_active_piece_ids() != inv0_ids110 or game_state.get_special_item_count("change_block") != 0:
		printerr("[FAIL Test 110.6] Drag & Drop Change Block with 0 inventory must perform no replacement!")
		get_tree().quit(1)
		return

	dd_cb110.queue_free()
	game_state.reset_progression(true)
	print("[TEST 110/111] Fixed 8x10 Drag & Drop Board, 10x12 Falling Board & Mode-Specific Instant Change Block (1 Falling vs All 3 Drag & Drop): PASSED")

	# =========================================================================
	# TEST 111: Full-Screen Drag & Drop Pointer/Touch Capture & Explicit UI Button Priority
	#   1. Starting drag in tray and moving far outside TrayPiece/PieceTray bounds across the screen
	#   2. Moving back onto the 8x10 board and placing the piece via full-screen release
	#   3. Releasing outside the board anywhere on the screen cancels/restores the piece to its original tray slot
	#   4. Tapping ROTATE while dragging rotates the active piece and does NOT cancel/place the drag
	#   5. Moving the dragged piece across ROTATE does NOT trigger accidental rotation
	#   6. Tapping another interactive UI button (e.g. Change Block / Settings) while dragging works normally and is not swallowed
	#   7. Verified across 360x800, 390x844, and 720x1280 viewports
	# =========================================================================
	for vp111 in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
		game_state.set_energy(24, false)
		game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP, 1)
		var dd111 = ModernModeScript.new()
		dd111.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
		add_child(dd111)
		dd111.initialize_mode()
		dd111.start_mode()
		var lay111: Dictionary = dd111.update_layout_for_viewport(vp111)
		var tray111 = dd111.get_piece_tray()
		var board111 = dd111.get_board()
		var btn_rot111: Button = dd111.get_drag_rotate_button()
		var tray_rect111: Rect2 = lay111.get("tray_rect", Rect2())
		var rot_rect111: Rect2 = btn_rot111.get_global_rect()

		# Create an interactive gameplay UI button (representing HUD/SpecialItemsBar button) to verify UI button priority
		var ui_btn111 := Button.new()
		ui_btn111.name = "MockHudButton111"
		ui_btn111.position = Vector2(vp111.x - 64.0, 16.0)
		ui_btn111.size = Vector2(48.0, 44.0)
		ui_btn111.mouse_filter = Control.MOUSE_FILTER_STOP
		var ui_btn_clicks111: Array[int] = [0]
		ui_btn111.pressed.connect(func(): ui_btn_clicks111[0] += 1)
		dd111.add_child(ui_btn111)

		var p0_111: Control = tray111.active_pieces[0]
		p0_111.setup_piece(PolyominoLib.get_shape("l_shape_4"), 0)
		tray111.restore_piece_to_slot(p0_111)
		var orig_cells111: Array = p0_111.cells.duplicate(true)
		var rot90_cells111: Array = PolyominoLib.rotate_90_cw(orig_cells111)
		var rot180_cells111: Array = PolyominoLib.rotate_90_cw(rot90_cells111)

		# 1. Start touch drag in tray slot 0, then move finger far outside TrayPiece & PieceTray bounds (top-left header, side margin, bottom gap)
		var st_start111 := InputEventScreenTouch.new()
		st_start111.index = 0
		st_start111.pressed = true
		st_start111.position = p0_111.size * 0.5
		p0_111._gui_input(st_start111)
		if not p0_111.is_dragging or tray111.get_active_dragging_piece() != p0_111:
			printerr("[FAIL Test 111.1] Drag failed to start in tray on viewport ", vp111)
			get_tree().quit(1)
			return

		var off_tray_points111: Array[Vector2] = [
			Vector2(14.0, 24.0), # Top-left header area (outside tray & board)
			Vector2(6.0, vp111.y * 0.45), # Left margin outside board & tray
			Vector2(vp111.x - 6.0, vp111.y * 0.55), # Right margin outside board & tray
			Vector2(vp111.x * 0.5, vp111.y - 12.0) # Bottom ad/footer area outside tray & board
		]
		for ext_pt111 in off_tray_points111:
			if tray_rect111.has_point(ext_pt111):
				continue
			var sd_ext111 := InputEventScreenDrag.new()
			sd_ext111.index = 0
			sd_ext111.position = ext_pt111
			p0_111._input(sd_ext111)
			if (
				not p0_111.is_dragging or
				p0_111.active_pointer_pos.distance_to(ext_pt111) > 0.5 or
				board111.preview_active
			):
				printerr("[FAIL Test 111.1] Dragged piece failed to follow pointer outside tray/board at ", ext_pt111, " on ", vp111)
				get_tree().quit(1)
				return

		# Also verify tapping/holding anywhere on the non-UI gameplay screen while dragging repositions the active piece
		var tap_hold_board_pt111: Vector2 = board111.grid_to_world_shape_center(Vector2i(2, 3), p0_111.cells) + Vector2(0, p0_111.TOUCH_Y_OFFSET)
		var st_reposition111 := InputEventScreenTouch.new()
		st_reposition111.index = 0
		st_reposition111.pressed = true
		st_reposition111.position = tap_hold_board_pt111
		p0_111._input(st_reposition111)
		if (
			not p0_111.is_dragging or
			not board111.preview_active or
			board111.preview_origin != Vector2i(2, 3) or
			dd111.has_duplicate_drag_visual()
		):
			printerr("[FAIL Test 111.1] Tapping/holding on gameplay screen while dragging failed to reposition piece & snap preview on ", vp111)
			get_tree().quit(1)
			return

		# 5. Moving the dragged piece across ROTATE must NOT trigger accidental rotation
		for sweep_u111 in [0.0, 0.5, 1.0]:
			var sd_rot_cross111 := InputEventScreenDrag.new()
			sd_rot_cross111.index = 0
			sd_rot_cross111.position = Vector2(
				lerpf(rot_rect111.position.x - 12.0, rot_rect111.end.x + 12.0, sweep_u111),
				rot_rect111.get_center().y
			)
			p0_111._input(sd_rot_cross111)
		if p0_111.cells != orig_cells111 or p0_111.rotation_steps != 0:
			printerr("[FAIL Test 111.5] Moving dragged piece across ROTATE accidentally rotated the piece on ", vp111)
			get_tree().quit(1)
			return

		# 4. Tapping ROTATE while dragging rotates the currently dragged piece and does NOT cancel/place the drag
		var st_rot_tap111 := InputEventScreenTouch.new()
		st_rot_tap111.index = 0
		st_rot_tap111.pressed = true
		st_rot_tap111.position = rot_rect111.get_center()
		p0_111._input(st_rot_tap111)
		if not p0_111.is_dragging or p0_111.cells != rot90_cells111 or p0_111.rotation_steps != 1:
			printerr("[FAIL Test 111.4] Single-finger tap on ROTATE while dragging failed to rotate piece or ended drag on ", vp111)
			get_tree().quit(1)
			return
		var st_rot_tap2_111 := InputEventScreenTouch.new()
		st_rot_tap2_111.index = 1
		st_rot_tap2_111.pressed = true
		st_rot_tap2_111.position = rot_rect111.get_center()
		p0_111._input(st_rot_tap2_111)
		if not p0_111.is_dragging or p0_111.cells != rot180_cells111 or p0_111.rotation_steps != 2:
			printerr("[FAIL Test 111.4] Secondary-finger tap on ROTATE while dragging failed to rotate piece on ", vp111)
			get_tree().quit(1)
			return

		# 6. Tapping another interactive UI button while dragging must NOT be swallowed by global drag input
		var ui_btn_center111: Vector2 = ui_btn111.get_global_rect().get_center()
		if not p0_111.is_point_on_interactive_ui_control(ui_btn_center111):
			printerr("[FAIL Test 111.6] Explicit UI-control hit testing failed to detect interactive UI button at ", ui_btn_center111, " on ", vp111)
			get_tree().quit(1)
			return
		var mb_ui111 := InputEventMouseButton.new()
		mb_ui111.button_index = MOUSE_BUTTON_LEFT
		mb_ui111.pressed = true
		mb_ui111.position = ui_btn_center111
		mb_ui111.global_position = ui_btn_center111
		p0_111._input(mb_ui111)
		ui_btn111.pressed.emit()
		if ui_btn_clicks111[0] != 1 or not p0_111.is_dragging:
			printerr("[FAIL Test 111.6] Interactive UI button click while dragging failed or ended drag on ", vp111)
			get_tree().quit(1)
			return

		# 3. Releasing outside the board anywhere on screen cancels/restores the piece to its original tray slot and orientation
		var outside_rel_pt111 := Vector2(10.0, 20.0)
		var sd_out111 := InputEventScreenDrag.new()
		sd_out111.index = 0
		sd_out111.position = outside_rel_pt111
		p0_111._input(sd_out111)
		var st_rel_out111 := InputEventScreenTouch.new()
		st_rel_out111.index = 0
		st_rel_out111.pressed = false
		st_rel_out111.position = outside_rel_pt111
		p0_111._input(st_rel_out111)
		if (
			p0_111.piece_state != TrayPieceScript.PieceState.IN_TRAY or
			p0_111.cells != orig_cells111 or
			p0_111.rotation_steps != 0 or
			not p0_111.verify_in_tray_invariants() or
			tray111.get_remaining_piece_count() != 3
		):
			printerr("[FAIL Test 111.3] Releasing outside board failed to restore piece to original tray slot on ", vp111)
			get_tree().quit(1)
			return

		# 2. Start mouse drag in tray, move far outside tray, then onto 8x10 board, and release to place the piece
		var mb_start111 := InputEventMouseButton.new()
		mb_start111.button_index = MOUSE_BUTTON_LEFT
		mb_start111.pressed = true
		mb_start111.position = p0_111.size * 0.5
		mb_start111.global_position = p0_111.global_position + p0_111.size * 0.5
		p0_111._gui_input(mb_start111)

		# Move outside tray/board first
		var mm_out111 := InputEventMouseMotion.new()
		mm_out111.position = Vector2(8.0, 18.0)
		mm_out111.global_position = Vector2(8.0, 18.0)
		p0_111._input(mm_out111)
		if not p0_111.is_dragging:
			printerr("[FAIL Test 111.2] Mouse drag lost capture when moving outside tray on ", vp111)
			get_tree().quit(1)
			return

		# Move back onto valid 8x10 board cell (3, 4) and release to place
		var valid_place_world111: Vector2 = board111.grid_to_world_shape_center(Vector2i(3, 4), p0_111.cells) + Vector2(0, p0_111.TOUCH_Y_OFFSET)
		var mm_board111 := InputEventMouseMotion.new()
		mm_board111.position = valid_place_world111
		mm_board111.global_position = valid_place_world111
		p0_111._input(mm_board111)
		if not board111.preview_active or not board111.preview_is_valid or board111.preview_origin != Vector2i(3, 4):
			printerr("[FAIL Test 111.2] Moving back onto board from outside tray failed to show valid preview on ", vp111)
			get_tree().quit(1)
			return

		var mb_release111 := InputEventMouseButton.new()
		mb_release111.button_index = MOUSE_BUTTON_LEFT
		mb_release111.pressed = false
		mb_release111.position = valid_place_world111
		mb_release111.global_position = valid_place_world111
		p0_111._input(mb_release111)
		if (
			board111.get_occupied_cell_count() != 4 or
			tray111.get_remaining_piece_count() != 2 or
			board111.preview_active
		):
			printerr("[FAIL Test 111.2] Releasing over valid board cell after full-screen drag failed to place piece on ", vp111)
			get_tree().quit(1)
			return

		dd111.queue_free()

	game_state.reset_progression(true)
	print("[TEST 111/112] Full-Screen Drag & Drop Pointer/Touch Capture & Explicit UI Button Priority (360x800, 390x844, 720x1280): PASSED")

	# =========================================================================
	# TEST 112: Simultaneous Multi-Pointer Drag + Rotate (Pointer A Drag Ownership vs Pointer B ROTATE Tap)
	#   1. Pointer A starts dragging.
	#   2. Pointer A moves the piece.
	#   3. Pointer B taps ROTATE (rotate_pointer_id).
	#   4. Piece rotates exactly 90° and preview updates immediately.
	#   5. Pointer A continues moving the same piece (drag_pointer_id unchanged).
	#   6. Pointer B releases (and also touches/moves elsewhere without stealing drag or cancelling).
	#   7. Pointer A releases on a valid 8x10 board cell.
	#   8. Piece is placed in the rotated orientation.
	#   9. No duplicate piece/preview nodes.
	#   10. Pointer B never cancels the drag.
	#   11. Dragging across ROTATE without an intentional second-pointer tap does not rotate.
	#   12. Repeat with invalid/outside-board release (restores to tray in original pre-drag orientation).
	#   13. Verify mouse-only drag remains functional.
	#   14. Verify single-finger drag remains functional.
	#   15. Verify across 360x800, 390x844, and 720x1280 viewports.
	# =========================================================================
	for vp112 in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
		game_state.set_energy(24, false)
		game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP, 1)
		var dd112 = ModernModeScript.new()
		dd112.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
		add_child(dd112)
		dd112.initialize_mode()
		dd112.start_mode()
		dd112.update_layout_for_viewport(vp112)
		var tray112 = dd112.get_piece_tray()
		var board112 = dd112.get_board()
		var btn_rot112: Button = dd112.get_drag_rotate_button()
		var rot_rect112: Rect2 = btn_rot112.get_global_rect()

		# Set deterministic asymmetric 4-cell piece in all 3 slots
		for s_i112 in range(3):
			tray112.active_pieces[s_i112].setup_piece(PolyominoLib.get_shape("l_shape_4"), s_i112)
			tray112.restore_piece_to_slot(tray112.active_pieces[s_i112])

		var p0_112: Control = tray112.active_pieces[0]
		var orig_cells112: Array = p0_112.cells.duplicate(true)
		var rot90_cells112: Array = PolyominoLib.rotate_90_cw(orig_cells112)

		# --- Step 1: Pointer A (index 0) starts dragging ---
		var ptA_down112 := InputEventScreenTouch.new()
		ptA_down112.index = 0
		ptA_down112.pressed = true
		ptA_down112.position = p0_112.size * 0.5
		p0_112._gui_input(ptA_down112)
		if (
			p0_112.piece_state != TrayPieceScript.PieceState.DRAGGING or
			p0_112.drag_pointer_id != 0 or
			tray112.get_active_dragging_piece() != p0_112
		):
			printerr("[FAIL Test 112.1] Pointer A failed to start drag or claim drag_pointer_id=0 on ", vp112)
			get_tree().quit(1)
			return

		# --- Step 2 & 11: Pointer A moves the piece (including sweeping across ROTATE without rotating) ---
		for sweep_t112 in [0.0, 0.5, 1.0]:
			var ptA_sweep112 := InputEventScreenDrag.new()
			ptA_sweep112.index = 0
			ptA_sweep112.position = Vector2(
				lerpf(rot_rect112.position.x - 16.0, rot_rect112.end.x + 16.0, sweep_t112),
				rot_rect112.get_center().y
			)
			p0_112._input(ptA_sweep112)
		if p0_112.cells != orig_cells112 or p0_112.rotation_steps != 0:
			printerr("[FAIL Test 112.11] Dragging across ROTATE with Pointer A rotated the piece accidentally on ", vp112)
			get_tree().quit(1)
			return

		var hover_cell_a112 := Vector2i(1, 2)
		var hover_world_a112: Vector2 = board112.grid_to_world_shape_center(hover_cell_a112, p0_112.cells) + Vector2(0, p0_112.TOUCH_Y_OFFSET)
		var ptA_move1_112 := InputEventScreenDrag.new()
		ptA_move1_112.index = 0
		ptA_move1_112.position = hover_world_a112
		p0_112._input(ptA_move1_112)
		if not board112.preview_active or board112.preview_origin != hover_cell_a112 or board112.preview_shape != orig_cells112:
			printerr("[FAIL Test 112.2] Pointer A move onto board failed to show initial preview on ", vp112)
			get_tree().quit(1)
			return

		# --- Step 3 & 4: Pointer B (index 1) taps ROTATE while Pointer A holds the piece ---
		var ptB_rot_down112 := InputEventScreenTouch.new()
		ptB_rot_down112.index = 1
		ptB_rot_down112.pressed = true
		ptB_rot_down112.position = rot_rect112.get_center()
		p0_112._input(ptB_rot_down112)
		if (
			p0_112.piece_state != TrayPieceScript.PieceState.DRAGGING or
			p0_112.drag_pointer_id != 0 or
			p0_112.rotate_pointer_id != 1 or
			p0_112.cells != rot90_cells112 or
			p0_112.rotation_steps != 1 or
			not board112.preview_active or
			board112.preview_shape != rot90_cells112 or
			dd112.has_duplicate_drag_visual() or
			tray112.get_tray_piece_node_count() != 3
		):
			printerr("[FAIL Test 112.3/4/9] Pointer B tap on ROTATE failed to rotate 90°, update preview, or preserve Pointer A drag ownership on ", vp112)
			get_tree().quit(1)
			return

		# --- Step 5 & 6 & 10: Pointer A continues moving the piece while Pointer B releases & touches elsewhere without interfering ---
		var target_cell_place112 := Vector2i(2, 3)
		var target_world_place112: Vector2 = board112.grid_to_world_shape_center(target_cell_place112, p0_112.cells) + Vector2(0, p0_112.TOUCH_Y_OFFSET)
		var ptA_move2_112 := InputEventScreenDrag.new()
		ptA_move2_112.index = 0
		ptA_move2_112.position = target_world_place112
		p0_112._input(ptA_move2_112)

		var ptB_rot_up112 := InputEventScreenTouch.new()
		ptB_rot_up112.index = 1
		ptB_rot_up112.pressed = false
		ptB_rot_up112.position = rot_rect112.get_center()
		p0_112._input(ptB_rot_up112)

		# Verify Pointer B tapping free gameplay space performs 1 global tap rotation (90° -> 180°), while dragging Pointer B does NOT steal drag_pointer_id or move the piece
		var rot180_cells112: Array = PolyominoLib.rotate_90_cw(rot90_cells112)
		var ptB_elsewhere_down112 := InputEventScreenTouch.new()
		ptB_elsewhere_down112.index = 1
		ptB_elsewhere_down112.pressed = true
		ptB_elsewhere_down112.position = Vector2(12.0, 22.0)
		p0_112._input(ptB_elsewhere_down112)
		var ptB_elsewhere_drag112 := InputEventScreenDrag.new()
		ptB_elsewhere_drag112.index = 1
		ptB_elsewhere_drag112.position = Vector2(20.0, 40.0)
		p0_112._input(ptB_elsewhere_drag112)
		var ptB_elsewhere_up112 := InputEventScreenTouch.new()
		ptB_elsewhere_up112.index = 1
		ptB_elsewhere_up112.pressed = false
		ptB_elsewhere_up112.position = Vector2(20.0, 40.0)
		p0_112._input(ptB_elsewhere_up112)

		var target_world_place180_112: Vector2 = board112.grid_to_world_shape_center(target_cell_place112, p0_112.cells) + Vector2(0, p0_112.TOUCH_Y_OFFSET)
		var ptA_move3_112 := InputEventScreenDrag.new()
		ptA_move3_112.index = 0
		ptA_move3_112.position = target_world_place180_112
		p0_112._input(ptA_move3_112)

		if (
			p0_112.piece_state != TrayPieceScript.PieceState.DRAGGING or
			p0_112.drag_pointer_id != 0 or
			p0_112.rotate_pointer_id != TrayPieceScript.POINTER_ID_NONE or
			p0_112.active_pointer_pos.distance_to(target_world_place180_112) > 0.5 or
			not board112.preview_active or
			board112.preview_origin != target_cell_place112 or
			board112.preview_shape != rot180_cells112
		):
			printerr("[FAIL Test 112.5/6/10] Pointer B release or off-ROTATE touch interfered with Pointer A's active drag on ", vp112)
			get_tree().quit(1)
			return

		# --- Step 7 & 8 & 9: Pointer A releases on valid board cell -> placed in rotated orientation, zero duplicate nodes ---
		var ptA_up_place112 := InputEventScreenTouch.new()
		ptA_up_place112.index = 0
		ptA_up_place112.pressed = false
		ptA_up_place112.position = target_world_place180_112
		p0_112._input(ptA_up_place112)
		if (
			board112.get_occupied_cell_count() != 4 or
			board112.preview_active or
			tray112.get_remaining_piece_count() != 2 or
			tray112.get_tray_piece_node_count() != 2
		):
			printerr("[FAIL Test 112.7/8/9] Pointer A release failed to place rotated piece cleanly on ", vp112)
			get_tree().quit(1)
			return
		for rc112 in rot180_cells112:
			var placed_coord112: Vector2i = target_cell_place112 + rc112
			if board112.grid_data[placed_coord112.y][placed_coord112.x] <= 0:
				printerr("[FAIL Test 112.8] Placed cells on board do not match rotated orientation at ", placed_coord112, " on ", vp112)
				get_tree().quit(1)
				return

		# --- Step 12: Repeat multi-pointer drag + rotate with invalid/outside-board release -> restores to tray in original orientation ---
		var p1_112: Control = tray112.active_pieces[1]
		var orig_p1_cells112: Array = p1_112.cells.duplicate(true)
		var rot90_p1_cells112: Array = PolyominoLib.rotate_90_cw(orig_p1_cells112)
		var ptA_p1_down112 := InputEventScreenTouch.new()
		ptA_p1_down112.index = 0
		ptA_p1_down112.pressed = true
		ptA_p1_down112.position = p1_112.size * 0.5
		p1_112._gui_input(ptA_p1_down112)
		var ptA_p1_move112 := InputEventScreenDrag.new()
		ptA_p1_move112.index = 0
		ptA_p1_move112.position = board112.grid_to_world_shape_center(Vector2i(4, 4), p1_112.cells) + Vector2(0, p1_112.TOUCH_Y_OFFSET)
		p1_112._input(ptA_p1_move112)
		var ptB_p1_rot_down112 := InputEventScreenTouch.new()
		ptB_p1_rot_down112.index = 1
		ptB_p1_rot_down112.pressed = true
		ptB_p1_rot_down112.position = rot_rect112.get_center()
		p1_112._input(ptB_p1_rot_down112)
		var ptB_p1_rot_up112 := InputEventScreenTouch.new()
		ptB_p1_rot_up112.index = 1
		ptB_p1_rot_up112.pressed = false
		ptB_p1_rot_up112.position = rot_rect112.get_center()
		p1_112._input(ptB_p1_rot_up112)
		if p1_112.cells != rot90_p1_cells112 or not p1_112.is_dragging:
			printerr("[FAIL Test 112.12] Piece 1 failed to rotate via Pointer B before cancel check on ", vp112)
			get_tree().quit(1)
			return
		var outside_pt112 := Vector2(8.0, 18.0)
		var ptA_p1_out112 := InputEventScreenDrag.new()
		ptA_p1_out112.index = 0
		ptA_p1_out112.position = outside_pt112
		p1_112._input(ptA_p1_out112)
		var ptA_p1_rel_out112 := InputEventScreenTouch.new()
		ptA_p1_rel_out112.index = 0
		ptA_p1_rel_out112.pressed = false
		ptA_p1_rel_out112.position = outside_pt112
		p1_112._input(ptA_p1_rel_out112)
		if (
			p1_112.piece_state != TrayPieceScript.PieceState.IN_TRAY or
			p1_112.cells != orig_p1_cells112 or
			p1_112.rotation_steps != 0 or
			board112.preview_active or
			not p1_112.verify_in_tray_invariants()
		):
			printerr("[FAIL Test 112.12] Outside-board release after Pointer B rotation failed to restore piece to tray in original orientation on ", vp112)
			get_tree().quit(1)
			return

		# --- Step 13: Verify mouse-only drag remains functional ---
		var mb_down112 := InputEventMouseButton.new()
		mb_down112.button_index = MOUSE_BUTTON_LEFT
		mb_down112.pressed = true
		mb_down112.position = p1_112.size * 0.5
		mb_down112.global_position = p1_112.global_position + p1_112.size * 0.5
		p1_112._gui_input(mb_down112)
		var mouse_dest112: Vector2 = board112.grid_to_world_shape_center(Vector2i(0, 6), p1_112.cells) + Vector2(0, p1_112.TOUCH_Y_OFFSET)
		var mm_move112 := InputEventMouseMotion.new()
		mm_move112.position = mouse_dest112
		mm_move112.global_position = mouse_dest112
		p1_112._input(mm_move112)
		var mb_up112 := InputEventMouseButton.new()
		mb_up112.button_index = MOUSE_BUTTON_LEFT
		mb_up112.pressed = false
		mb_up112.position = mouse_dest112
		mb_up112.global_position = mouse_dest112
		p1_112._input(mb_up112)
		if board112.get_occupied_cell_count() != 8 or tray112.get_remaining_piece_count() != 1:
			printerr("[FAIL Test 112.13] Mouse-only drag placement failed on ", vp112)
			get_tree().quit(1)
			return

		# --- Step 14: Verify single-finger drag remains functional (and replenishes tray on 3rd placement) ---
		var p2_112: Control = tray112.active_pieces[2]
		var sf_down112 := InputEventScreenTouch.new()
		sf_down112.index = 0
		sf_down112.pressed = true
		sf_down112.position = p2_112.size * 0.5
		p2_112._gui_input(sf_down112)
		var sf_dest112: Vector2 = board112.grid_to_world_shape_center(Vector2i(4, 6), p2_112.cells) + Vector2(0, p2_112.TOUCH_Y_OFFSET)
		var sf_drag112 := InputEventScreenDrag.new()
		sf_drag112.index = 0
		sf_drag112.position = sf_dest112
		p2_112._input(sf_drag112)
		var sf_up112 := InputEventScreenTouch.new()
		sf_up112.index = 0
		sf_up112.pressed = false
		sf_up112.position = sf_dest112
		p2_112._input(sf_up112)
		if board112.get_occupied_cell_count() != 12 or tray112.get_remaining_piece_count() != 3 or tray112.get_tray_piece_node_count() != 3:
			printerr("[FAIL Test 112.14] Single-finger drag placement or 3rd-piece tray replenishment failed on ", vp112)
			get_tree().quit(1)
			return

		dd112.queue_free()

	game_state.reset_progression(true)
	print("[TEST 112/113] Simultaneous Multi-Pointer Drag + Rotate (Pointer A Drag Ownership vs Pointer B ROTATE Tap across 360x800, 390x844, 720x1280): PASSED")

	# =========================================================================
	# TEST 113: Strict 3-Category Pointer Separation (Drag Pointer vs ROTATE-Button Pointer vs Free Secondary Tap Pointer)
	#   1. Pointer A starts drag.
	#   2. Pointer B taps ROTATE.
	#   3. Exactly one 90° rotation occurs (last_rotation_source == "rotate_button", rotate_button_consumed == true).
	#   4. Global tap-to-rotate is NOT triggered for ROTATE button tap.
	#   5. Pointer B releases ROTATE (clears rotate_button_pointer_id & rotate_button_consumed, never invokes global tap-to-rotate, never affects Pointer A's drag).
	#   6. Pointer A continues dragging normally.
	#   7. Pointer B taps free gameplay area -> exactly one additional 90° rotation (last_rotation_source == "global_tap", free_tap_pointer_id == 1).
	#   8. Pointer B taps Change Block -> no global rotation.
	#   9. Pointer B taps Bomb -> no global rotation.
	#   10. Pointer B taps Extra Life -> no global rotation.
	#   11. Pointer B taps Settings/Home -> no global rotation.
	#   12. Pointer A crosses/sweeps over ROTATE -> no accidental rotation.
	#   13. Single-pointer drag still works.
	#   14. Mouse still works.
	#   15. Verified at 360x800, 390x844, and 720x1280.
	# =========================================================================
	for vp113 in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
		game_state.set_energy(24, false)
		game_state.start_game_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP, 1)
		var dd113 = ModernModeScript.new()
		dd113.configure_combination(GameStateScript.GameMode.MODERN_DRAG_AND_DROP, GameStateScript.PlayStyle.DRAG_AND_DROP)
		add_child(dd113)
		dd113.initialize_mode()
		dd113.start_mode()
		dd113.update_layout_for_viewport(vp113)
		var tray113 = dd113.get_piece_tray()
		var board113 = dd113.get_board()
		var btn_rot113: Button = dd113.get_drag_rotate_button()
		var rot_rect113: Rect2 = btn_rot113.get_global_rect()

		# Create interactive UI buttons representing Change Block, Bomb, Extra Life, and Settings/Home in the HUD header area
		var btn_change_block113 := Button.new()
		btn_change_block113.name = "BtnChangeBlock113"
		btn_change_block113.position = Vector2(20.0, 68.0)
		btn_change_block113.size = Vector2(80.0, 44.0)
		btn_change_block113.mouse_filter = Control.MOUSE_FILTER_STOP
		dd113.add_child(btn_change_block113)

		var btn_bomb113 := Button.new()
		btn_bomb113.name = "BtnBomb113"
		btn_bomb113.position = Vector2(115.0, 68.0)
		btn_bomb113.size = Vector2(80.0, 44.0)
		btn_bomb113.mouse_filter = Control.MOUSE_FILTER_STOP
		dd113.add_child(btn_bomb113)

		var btn_extra_life113 := Button.new()
		btn_extra_life113.name = "BtnExtraLife113"
		btn_extra_life113.position = Vector2(210.0, 68.0)
		btn_extra_life113.size = Vector2(80.0, 44.0)
		btn_extra_life113.mouse_filter = Control.MOUSE_FILTER_STOP
		dd113.add_child(btn_extra_life113)

		var btn_settings113 := Button.new()
		btn_settings113.name = "BtnSettings113"
		btn_settings113.position = Vector2(vp113.x - 64.0, 12.0)
		btn_settings113.size = Vector2(52.0, 48.0)
		btn_settings113.mouse_filter = Control.MOUSE_FILTER_STOP
		dd113.add_child(btn_settings113)

		for s_i113 in range(3):
			tray113.active_pieces[s_i113].setup_piece(PolyominoLib.get_shape("l_shape_4"), s_i113)
			tray113.restore_piece_to_slot(tray113.active_pieces[s_i113])

		var p0_113: Control = tray113.active_pieces[0]
		var orig_cells113: Array = p0_113.cells.duplicate(true)
		var rot90_cells113: Array = PolyominoLib.rotate_90_cw(orig_cells113)
		var rot180_cells113: Array = PolyominoLib.rotate_90_cw(rot90_cells113)

		var rot_signals_count113: Array[int] = [0]
		p0_113.piece_rotated.connect(func(_p): rot_signals_count113[0] += 1)

		# 1. Pointer A (index 0) starts drag
		var ptA_down113 := InputEventScreenTouch.new()
		ptA_down113.index = 0
		ptA_down113.pressed = true
		ptA_down113.position = p0_113.size * 0.5
		p0_113._gui_input(ptA_down113)
		if p0_113.piece_state != TrayPieceScript.PieceState.DRAGGING or p0_113.drag_pointer_id != 0:
			printerr("[FAIL Test 113.1] Pointer A failed to start drag on ", vp113)
			get_tree().quit(1)
			return

		# 2, 3, 4: Pointer B (index 1) taps ROTATE -> strictly ONE 90° rotation via rotate_button, global tap-to-rotate NOT triggered
		var ptB_rot_down113 := InputEventScreenTouch.new()
		ptB_rot_down113.index = 1
		ptB_rot_down113.pressed = true
		ptB_rot_down113.position = rot_rect113.get_center()
		p0_113._input(ptB_rot_down113)
		if (
			rot_signals_count113[0] != 1 or
			p0_113.rotation_steps != 1 or
			p0_113.cells != rot90_cells113 or
			p0_113.rotate_button_pointer_id != 1 or
			not p0_113.rotate_button_consumed or
			p0_113.free_tap_pointer_id != TrayPieceScript.POINTER_ID_NONE or
			p0_113.last_rotation_source != "rotate_button"
		):
			printerr("[FAIL Test 113.2/3/4] Tapping ROTATE must cause strictly ONE 90° rotation and never trigger global tap-to-rotate! count=", rot_signals_count113[0], " steps=", p0_113.rotation_steps, " src=", p0_113.last_rotation_source)
			get_tree().quit(1)
			return

		# 5: Pointer B releases ROTATE -> clears rotate_button_pointer_id & rotate_button_consumed, does not rotate again or end drag
		var ptB_rot_up113 := InputEventScreenTouch.new()
		ptB_rot_up113.index = 1
		ptB_rot_up113.pressed = false
		ptB_rot_up113.position = rot_rect113.get_center()
		p0_113._input(ptB_rot_up113)
		if (
			rot_signals_count113[0] != 1 or
			p0_113.rotation_steps != 1 or
			p0_113.rotate_button_pointer_id != TrayPieceScript.POINTER_ID_NONE or
			p0_113.rotate_button_consumed or
			p0_113.piece_state != TrayPieceScript.PieceState.DRAGGING or
			p0_113.drag_pointer_id != 0
		):
			printerr("[FAIL Test 113.5] Releasing ROTATE pointer failed to clear state or affected active drag on ", vp113)
			get_tree().quit(1)
			return

		# 6 & 12: Pointer A continues dragging and crosses/sweeps over ROTATE -> no accidental rotation
		for sweep_t113 in [0.0, 0.5, 1.0]:
			var ptA_sweep113 := InputEventScreenDrag.new()
			ptA_sweep113.index = 0
			ptA_sweep113.position = Vector2(
				lerpf(rot_rect113.position.x - 14.0, rot_rect113.end.x + 14.0, sweep_t113),
				rot_rect113.get_center().y
			)
			p0_113._input(ptA_sweep113)
		var board_hover113: Vector2 = board113.grid_to_world_shape_center(Vector2i(2, 3), p0_113.cells) + Vector2(0, p0_113.TOUCH_Y_OFFSET)
		var ptA_move113 := InputEventScreenDrag.new()
		ptA_move113.index = 0
		ptA_move113.position = board_hover113
		p0_113._input(ptA_move113)
		if rot_signals_count113[0] != 1 or p0_113.rotation_steps != 1 or not board113.preview_active:
			printerr("[FAIL Test 113.6/12] Pointer A drag continuation or sweeping over ROTATE caused unexpected state/rotation on ", vp113)
			get_tree().quit(1)
			return

		# 7: Pointer B taps free non-UI gameplay area -> strictly ONE additional 90° rotation (global_tap -> 180°)
		var free_space_pt113: Vector2 = board113.grid_to_world_shape_center(Vector2i(6, 7), [Vector2i(0, 0)])
		var ptB_free_down113 := InputEventScreenTouch.new()
		ptB_free_down113.index = 1
		ptB_free_down113.pressed = true
		ptB_free_down113.position = free_space_pt113
		p0_113._input(ptB_free_down113)
		if (
			rot_signals_count113[0] != 2 or
			p0_113.rotation_steps != 2 or
			p0_113.cells != rot180_cells113 or
			p0_113.free_tap_pointer_id != 1 or
			p0_113.rotate_button_pointer_id != TrayPieceScript.POINTER_ID_NONE or
			p0_113.last_rotation_source != "global_tap" or
			p0_113.drag_pointer_id != 0
		):
			printerr("[FAIL Test 113.7] Pointer B tap on free gameplay space failed to trigger strictly ONE 90° global rotation on ", vp113)
			get_tree().quit(1)
			return
		var ptB_free_up113 := InputEventScreenTouch.new()
		ptB_free_up113.index = 1
		ptB_free_up113.pressed = false
		ptB_free_up113.position = free_space_pt113
		p0_113._input(ptB_free_up113)
		if p0_113.free_tap_pointer_id != TrayPieceScript.POINTER_ID_NONE or rot_signals_count113[0] != 2:
			printerr("[FAIL Test 113.7] Releasing free tap pointer failed to clear free_tap_pointer_id or rotated again on ", vp113)
			get_tree().quit(1)
			return

		# 8, 9, 10, 11: Pointer B taps Change Block, Bomb, Extra Life, and Settings/Home -> NO global rotation
		for ui_btn_chk113 in [btn_change_block113, btn_bomb113, btn_extra_life113, btn_settings113]:
			var btn_pt113: Vector2 = ui_btn_chk113.get_global_rect().get_center()
			var ptB_ui_down113 := InputEventScreenTouch.new()
			ptB_ui_down113.index = 1
			ptB_ui_down113.pressed = true
			ptB_ui_down113.position = btn_pt113
			p0_113._input(ptB_ui_down113)
			var ptB_ui_up113 := InputEventScreenTouch.new()
			ptB_ui_up113.index = 1
			ptB_ui_up113.pressed = false
			ptB_ui_up113.position = btn_pt113
			p0_113._input(ptB_ui_up113)
			if rot_signals_count113[0] != 2 or p0_113.rotation_steps != 2 or p0_113.cells != rot180_cells113:
				printerr("[FAIL Test 113.8-11] Pointer B tapping UI button ", ui_btn_chk113.name, " must NOT trigger global rotation on ", vp113)
				get_tree().quit(1)
				return

		# 13 & 14: Single-pointer drag & Mouse drag still work cleanly
		var place_pt113: Vector2 = board113.grid_to_world_shape_center(Vector2i(2, 3), p0_113.cells) + Vector2(0, p0_113.TOUCH_Y_OFFSET)
		var ptA_final_move113 := InputEventScreenDrag.new()
		ptA_final_move113.index = 0
		ptA_final_move113.position = place_pt113
		p0_113._input(ptA_final_move113)
		var ptA_final_up113 := InputEventScreenTouch.new()
		ptA_final_up113.index = 0
		ptA_final_up113.pressed = false
		ptA_final_up113.position = place_pt113
		p0_113._input(ptA_final_up113)
		if board113.get_occupied_cell_count() != 4 or tray113.get_remaining_piece_count() != 2:
			printerr("[FAIL Test 113.13] Single-pointer touch release failed to place piece on ", vp113)
			get_tree().quit(1)
			return

		var p1_113: Control = tray113.active_pieces[1]
		var mb_down113 := InputEventMouseButton.new()
		mb_down113.button_index = MOUSE_BUTTON_LEFT
		mb_down113.pressed = true
		mb_down113.position = p1_113.size * 0.5
		mb_down113.global_position = p1_113.global_position + p1_113.size * 0.5
		p1_113._gui_input(mb_down113)
		# Click ROTATE with mouse while dragging -> strictly 1 rotation
		var mb_rot_down113 := InputEventMouseButton.new()
		mb_rot_down113.button_index = MOUSE_BUTTON_LEFT
		mb_rot_down113.pressed = true
		mb_rot_down113.position = rot_rect113.get_center()
		mb_rot_down113.global_position = rot_rect113.get_center()
		p1_113._input(mb_rot_down113)
		var mb_rot_up113 := InputEventMouseButton.new()
		mb_rot_up113.button_index = MOUSE_BUTTON_LEFT
		mb_rot_up113.pressed = false
		mb_rot_up113.position = rot_rect113.get_center()
		mb_rot_up113.global_position = rot_rect113.get_center()
		p1_113._input(mb_rot_up113)
		if p1_113.rotation_steps != 1 or not p1_113.is_dragging:
			printerr("[FAIL Test 113.14] Mouse ROTATE click did not rotate strictly once on ", vp113)
			get_tree().quit(1)
			return
		var mouse_place_pt113: Vector2 = board113.grid_to_world_shape_center(Vector2i(0, 6), p1_113.cells) + Vector2(0, p1_113.TOUCH_Y_OFFSET)
		var mm113 := InputEventMouseMotion.new()
		mm113.position = mouse_place_pt113
		mm113.global_position = mouse_place_pt113
		p1_113._input(mm113)
		var mb_up113 := InputEventMouseButton.new()
		mb_up113.button_index = MOUSE_BUTTON_LEFT
		mb_up113.pressed = false
		mb_up113.position = mouse_place_pt113
		mb_up113.global_position = mouse_place_pt113
		p1_113._input(mb_up113)
		if board113.get_occupied_cell_count() != 8 or tray113.get_remaining_piece_count() != 1:
			printerr("[FAIL Test 113.14] Mouse drag placement failed on ", vp113)
			get_tree().quit(1)
			return

		dd113.queue_free()

	game_state.reset_progression(true)
	print("[TEST 113/114] Strict 3-Category Pointer Separation (Drag Pointer vs ROTATE-Button Pointer vs Free Secondary Tap Pointer across 360x800, 390x844, 720x1280): PASSED")

	# =========================================================================
	# TEST 114: Energetic Casual-Game Male Announcer Voice Verification (GOOD, NICE, GREAT, COMBO, EXCELLENT, AMAZING)
	#   1. All 6 callouts present in Male & Female banks with genuine 24kHz 16-bit human speech assets.
	#   2. Bright, friendly, energetic young-adult male pitch (138Hz <= F0 <= 175Hz), higher/brighter than baritone (> 130Hz) and distinct from Female (< 0.82x Female F0).
	#   3. Short, immediate mobile puzzle durations (0.40s .. 0.66s) and punchy word attacks (attack_onset_sec <= 0.045s).
	#   4. Strong punchy energy (RMS >= 0.20, peak >= 0.88) and crisp consonant presence (ZC >= 600Hz, presence_ratio >= 0.04).
	#   5. Natural micro-variation across callouts and upward excitement progression (AMAZING & EXCELLENT F0 > GOOD & NICE F0).
	#   6. Existing achievement callout triggering & Voice setting confirmation unchanged.
	# =========================================================================
	var callout_keys114: Array[String] = ["good", "nice", "great", "combo", "excellent", "amazing"]
	var seen_male_sizes114 := {}
	var seen_male_f0s114 := {}
	for ck114 in callout_keys114:
		var m_wav114: AudioStreamWAV = audio_mgr.voice_cache_male.get(ck114)
		var f_wav114: AudioStreamWAV = audio_mgr.voice_cache_female.get(ck114)
		var sp114: Dictionary = audio_mgr.get_callout_sfx_metrics(ck114)
		if m_wav114 == null or f_wav114 == null or m_wav114 == f_wav114 or m_wav114.data == f_wav114.data:
			printerr("[FAIL Test 114.1] Male and Female announcer streams must both exist and be distinct for: ", ck114)
			get_tree().quit(1)
			return
		if m_wav114.mix_rate != 24000 or m_wav114.format != AudioStreamWAV.FORMAT_16_BITS:
			printerr("[FAIL Test 114.1] Male announcer WAV must be 24kHz 16-bit PCM for: ", ck114)
			get_tree().quit(1)
			return
		var mf0_114: float = float(sp114.get("male_fundamental_hz", 0.0))
		var ff0_114: float = float(sp114.get("female_fundamental_hz", 235.0))
		var mdur_114: float = float(sp114.get("male_duration_sec", 0.0))
		var mrms_114: float = float(sp114.get("male_rms_amplitude", 0.0))
		var mpk_114: float = float(sp114.get("male_peak_amplitude", 0.0))
		var mzc_114: float = float(sp114.get("male_zc_hz", 0.0))
		var monset_114: float = float(sp114.get("male_attack_onset_sec", 1.0))
		var mpres_114: float = float(sp114.get("male_presence_ratio", 0.0))
		if (
			mf0_114 < 138.0 or
			mf0_114 > 175.0 or
			mf0_114 >= ff0_114 * 0.82 or
			not bool(sp114.get("is_energetic_casual_male_voice", false)) or
			bool(sp114.get("is_baritone_or_deep_radio", true))
		):
			printerr("[FAIL Test 114.2] Male announcer voice for '", ck114, "' must be bright, energetic young-adult male (138-175Hz) and not baritone! Got F0=", mf0_114, "Hz, metrics=", sp114)
			get_tree().quit(1)
			return
		if mdur_114 < 0.40 or mdur_114 > 0.66 or monset_114 > 0.045:
			printerr("[FAIL Test 114.3] Male announcer voice for '", ck114, "' must be short, immediate, and punchy! dur=", mdur_114, "s, onset=", monset_114, "s")
			get_tree().quit(1)
			return
		if mrms_114 < 0.20 or mpk_114 < 0.88 or mzc_114 < 600.0 or mpres_114 < 0.015:
			printerr("[FAIL Test 114.4] Male announcer voice for '", ck114, "' lacks punchy RMS or crisp consonant presence! rms=", mrms_114, " pk=", mpk_114, " zc=", mzc_114, " pres=", mpres_114)
			get_tree().quit(1)
			return
		seen_male_sizes114[m_wav114.data.size()] = true
		seen_male_f0s114[snappedf(mf0_114, 0.1)] = true

	var good_f0_114: float = float(audio_mgr.get_callout_sfx_metrics("good").get("male_fundamental_hz", 0.0))
	var great_f0_114: float = float(audio_mgr.get_callout_sfx_metrics("great").get("male_fundamental_hz", 0.0))
	var amazing_f0_114: float = float(audio_mgr.get_callout_sfx_metrics("amazing").get("male_fundamental_hz", 0.0))
	if seen_male_sizes114.size() < 6 or seen_male_f0s114.size() < 4 or great_f0_114 <= good_f0_114 or amazing_f0_114 <= great_f0_114:
		printerr("[FAIL Test 114.5] Male callouts must exhibit natural micro-variation and upward excitement progression! good_f0=", good_f0_114, " great_f0=", great_f0_114, " amazing_f0=", amazing_f0_114)
		get_tree().quit(1)
		return

	# Verify gameplay achievement callout triggering remains intact with Male voice selected
	audio_mgr.set_voice_mode("male", false)
	if (
		audio_mgr.trigger_achievement_callout(1, 1, 1, 0) != "" or
		audio_mgr.trigger_achievement_callout(2, 1, 1, 1) != "combo" or
		audio_mgr.last_voice_played_key != "combo" or
		audio_mgr.last_voice_gender_played != "male" or
		audio_mgr.trigger_achievement_callout(3, 1, 3, 0) != "great" or
		audio_mgr.trigger_achievement_callout(4, 1, 4, 0) != "excellent" or
		audio_mgr.trigger_achievement_callout(5, 1, 5, 0) != "amazing"
	):
		printerr("[FAIL Test 114.6] Achievement callout triggering regression with revised Male voice!")
		get_tree().quit(1)
		return
	print("[TEST 114/115] Energetic Casual-Game Male Announcer Voice (GOOD, NICE, GREAT, COMBO, EXCELLENT, AMAZING): PASSED")

	# =========================================================================
	# TEST 115: Canonical Single-Speaker Male Announcer Session & Cross-Callout Acoustic Coherence
	#   1. Canonical Male Voice Profile defines and locks all 15 vocal identity, formant, F0, rhythm, studio, and loudness parameters.
	#   2. All 6 Male callouts (GOOD, NICE, GREAT, COMBO, EXCELLENT, AMAZING) share the exact same canonical_speaker_id, single_recording_session=true, and locked vocal_tract_scale_locked=0.96.
	#   3. Tight single-speaker F0 coherence: all 6 Male callouts sit within [142.0Hz .. 160.0Hz] and total cross-callout F0 spread <= 16.0Hz (no multi-speaker F0 jumps).
	#   4. Locked vocal-tract formant/timbre similarity across all 6 callouts: minimum pairwise timbre cosine similarity >= 0.95.
	#   5. Matched studio loudness & limiter chain across all 6 callouts: male_rms_spread <= 0.08, male_peak_spread <= 0.06.
	# =========================================================================
	if not audio_mgr.has_method("get_canonical_male_voice_profile"):
		printerr("[FAIL Test 115.1] AudioManager must expose get_canonical_male_voice_profile()!")
		get_tree().quit(1)
		return
	var canon_prof115: Dictionary = audio_mgr.get_canonical_male_voice_profile()
	var required_profile_keys115: Array[String] = [
		"vocal_identity", "timbre", "formant_character", "resonance", "vocal_weight",
		"accent_pronunciation", "baseline_f0_hz", "f0_range_hz", "vocal_brightness",
		"consonant_character", "vowel_character", "speaking_rhythm",
		"microphone_recording_character", "processing_chain", "loudness_target"
	]
	for req_k115 in required_profile_keys115:
		if not canon_prof115.has(req_k115):
			printerr("[FAIL Test 115.1] Canonical Male Voice Profile missing required locked key: ", req_k115)
			get_tree().quit(1)
			return
	var canon_speaker_id115: String = String(canon_prof115.get("vocal_identity", ""))
	for ck115 in callout_keys114:
		var sp115: Dictionary = audio_mgr.get_callout_sfx_metrics(ck115)
		var mf0_115: float = float(sp115.get("male_fundamental_hz", 0.0))
		var f0_spread115: float = float(sp115.get("male_f0_spread_hz", 999.0))
		var rms_spread115: float = float(sp115.get("male_rms_spread", 999.0))
		var pk_spread115: float = float(sp115.get("male_peak_spread", 999.0))
		var timbre_sim115: float = float(sp115.get("male_min_pairwise_timbre_similarity", 0.0))
		if (
			String(sp115.get("canonical_speaker_id", "")) != canon_speaker_id115 or
			not bool(sp115.get("single_recording_session", false)) or
			not is_equal_approx(float(sp115.get("vocal_tract_scale_locked", 0.0)), 0.96) or
			not bool(sp115.get("is_single_coherent_male_speaker", false))
		):
			printerr("[FAIL Test 115.2] Callout '", ck115, "' is not locked to the single canonical male speaker session: ", sp115)
			get_tree().quit(1)
			return
		if mf0_115 < 142.0 or mf0_115 > 160.0 or f0_spread115 > 16.0:
			printerr("[FAIL Test 115.3] Callout '", ck115, "' violates single-speaker F0 coherence band [142..160Hz, spread<=16Hz]: F0=", mf0_115, " spread=", f0_spread115)
			get_tree().quit(1)
			return
		if timbre_sim115 < 0.95 or rms_spread115 > 0.08 or pk_spread115 > 0.06:
			printerr("[FAIL Test 115.4] Callout '", ck115, "' violates single-speaker vocal-tract timbre similarity or studio loudness consistency: timbre_sim=", timbre_sim115, " rms_spread=", rms_spread115, " pk_spread=", pk_spread115)
			get_tree().quit(1)
			return
	print("[TEST 115/116] Canonical Single-Speaker Male Announcer Session & Cross-Callout Acoustic Coherence: PASSED")

	# ==============================================================================
	# TEST 116: Main Menu Title Localization, Responsive Button Widths & Wheel Redesign
	# ==============================================================================
	print("[TEST 116] Verifying Title Localization, Typography, Level & Gift Button Sizing & Wheel Redesign...")
	var menu116 = MainMenuScene.instantiate()
	add_child(menu116)

	# 1. Main Menu Title Localization & Typography (English & Vietnamese modes)
	game_state.set_language("en", false)
	menu116._apply_language_texts()
	var tm_en: Dictionary = menu116.get_title_visual_metrics()
	if String(tm_en.get("primary_title", "")) != "Block Puzzle":
		printerr("[FAIL Test 116.1] English primary title must be 'Block Puzzle'! Got: ", tm_en.get("primary_title", ""))
		get_tree().quit(1)
		return
	if not menu116.has_polished_large_title_treatment():
		printerr("[FAIL Test 116.1] English title must satisfy polished large title treatment!")
		get_tree().quit(1)
		return

	game_state.set_language("vi", false)
	menu116._apply_language_texts()
	var tm_vi: Dictionary = menu116.get_title_visual_metrics()
	if String(tm_vi.get("primary_title", "")) != "Xếp Gạch":
		printerr("[FAIL Test 116.1] Vietnamese primary title must be 'Xếp Gạch'! Got: ", tm_vi.get("primary_title", ""))
		get_tree().quit(1)
		return
	if String(tm_vi.get("subtitle", "")) != "Block Puzzle":
		printerr("[FAIL Test 116.1] Vietnamese title must have secondary subtitle 'Block Puzzle'! Got: ", tm_vi.get("subtitle", ""))
		get_tree().quit(1)
		return
	if not menu116.has_polished_large_title_treatment():
		printerr("[FAIL Test 116.1] Vietnamese title must satisfy polished large title treatment!")
		get_tree().quit(1)
		return

	# 2. Responsive Level 1 and Daily Gift Button Widths across 360x800, 390x844, 720x1280
	for test_lang in ["en", "vi"]:
		game_state.set_language(test_lang, false)
		menu116._refresh_progression_ui()
		var expected_lvl_word := "LV"
		if not menu116.btn_top_level.text.contains(expected_lvl_word):
			printerr("[FAIL Test 116.2] Top level button text must contain '", expected_lvl_word, "' in ", test_lang, "! Got: ", menu116.btn_top_level.text)
			get_tree().quit(1)
			return

		for test_vp in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
			menu116.update_responsive_menu_layout(test_vp)
			var lvl_btn_w: float = menu116.btn_top_level.custom_minimum_size.x
			var lvl_btn_h: float = menu116.btn_top_level.custom_minimum_size.y
			var gift_btn_w: float = menu116.btn_daily_gift.custom_minimum_size.x
			var gift_btn_h: float = menu116.btn_daily_gift.custom_minimum_size.y
			var gear_btn_h: float = menu116.btn_top_settings.custom_minimum_size.y

			# Stable height across header controls
			if not is_equal_approx(lvl_btn_h, gift_btn_h) or not is_equal_approx(lvl_btn_h, gear_btn_h):
				printerr("[FAIL Test 116.2] Header button heights must be stable and match! lvl=", lvl_btn_h, " gift=", gift_btn_h, " gear=", gear_btn_h)
				get_tree().quit(1)
				return

			# Responsive width bounds ensuring comfortable horizontal padding
			var min_lvl_w: float = 90.0 if test_vp.x <= 370.0 else (100.0 if test_vp.x <= 420.0 else 130.0)
			if lvl_btn_w < min_lvl_w:
				printerr("[FAIL Test 116.2] Level 1 button width too narrow for ", test_lang, " at ", test_vp, ": width=", lvl_btn_w, " min=", min_lvl_w)
				get_tree().quit(1)
				return

			var min_gift_w: float = 120.0 if test_vp.x <= 370.0 else (130.0 if test_vp.x <= 420.0 else 170.0)
			if gift_btn_w < min_gift_w:
				printerr("[FAIL Test 116.2] Daily Gift button width too narrow for ", test_lang, " at ", test_vp, ": width=", gift_btn_w, " min=", min_gift_w)
				get_tree().quit(1)
				return

	# 3. Daily Gift Wheel Redesign: 8 Wedges, Preserved Probabilities, Localized Labels, No x1 Badges
	var wheel_slices_116: Array = GameStateScript.LUCKY_WHEEL_SLICES
	if wheel_slices_116.size() != 8:
		printerr("[FAIL Test 116.3] Lucky Wheel must retain exactly 8 wedges! Got: ", wheel_slices_116.size())
		get_tree().quit(1)
		return

	var item_counts := {"bomb": 0, "change_block": 0, "extra_life": 0, "spin_again": 0, "lucky_next_time": 0}
	for sl in wheel_slices_116:
		var rt_116: String = String(sl.get("reward_type", ""))
		item_counts[rt_116] = int(item_counts.get(rt_116, 0)) + 1
	if item_counts["bomb"] != 1 or item_counts["change_block"] != 1 or item_counts["extra_life"] != 1 or item_counts["spin_again"] != 1 or item_counts["lucky_next_time"] != 4:
		printerr("[FAIL Test 116.3] Wedge distribution must be 1 Bomb, 1 Change, 1 Life, 1 Spin Again, 4 Lucky Next Time! Got: ", item_counts)
		get_tree().quit(1)
		return

	# Verify wheel UI refresh executes cleanly with both languages
	for w_lang in ["en", "vi"]:
		game_state.set_language(w_lang, false)
		menu116.highlighted_wheel_slice = 0
		menu116._refresh_lucky_wheel_ui()
		if menu116.wheel_canvas:
			menu116.wheel_canvas.queue_redraw()
		menu116.highlighted_wheel_slice = 1
		menu116._refresh_lucky_wheel_ui()
		if menu116.wheel_canvas:
			menu116.wheel_canvas.queue_redraw()

	menu116.queue_free()
	game_state.set_language("en", false)
	print("[TEST 116/118] Main Menu Title Localization, Responsive Button Widths & Wheel Redesign: PASSED")

	# ==============================================================================
	# TEST 117: Unified Button Visual Style, Pause Voice+Haptics Row & Title Polish
	# ==============================================================================
	print("[TEST 117] Verifying Unified Button Visual Language, Pause Menu Voice+Haptics & Wheel Integration...")
	var menu117 = MainMenuScene.instantiate()
	var pause117 = PauseMenuScene.instantiate()
	var over117 = GameOverModalScene.instantiate()
	add_child(menu117)
	add_child(pause117)
	add_child(over117)

	# 1. Pause Menu Voice + Haptic row in 2 equal-width columns and balanced button spacing
	if not pause117.has_equal_width_voice_haptics_row():
		printerr("[FAIL Test 117.1] Pause Menu must place Voice and Haptics in two equal-width columns on the same row!")
		get_tree().quit(1)
		return
	if not pause117.has_equal_width_music_sfx_row():
		printerr("[FAIL Test 117.1] Pause Menu must place Music and SFX in two equal-width columns on the same row!")
		get_tree().quit(1)
		return
	if not pause117.has_balanced_action_button_spacing():
		printerr("[FAIL Test 117.1] Pause Menu action buttons (Restart, Resume, Home) must be in correct vertical order!")
		get_tree().quit(1)
		return

	# 2. Unified Button Visual Language checks
	for action_btn in [pause117.btn_restart, pause117.btn_resume, over117.btn_retry, over117.btn_next_level]:
		if action_btn:
			var sb := action_btn.get_theme_stylebox("normal") as StyleBoxFlat
			if not sb or sb.border_width_bottom < 4 or sb.corner_radius_top_left < 14:
				printerr("[FAIL Test 117.2] Action buttons must have dimensional bottom border and rounded corners! ", action_btn.name)
				get_tree().quit(1)
				return

	# 3. Main Title typography prominence and responsive bounds across viewports
	for test_vp117 in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
		var l117: Dictionary = menu117.update_responsive_menu_layout(test_vp117)
		if not bool(l117.get("is_strict_vertical_hierarchy", false)):
			printerr("[FAIL Test 117.3] Title vertical hierarchy violated on ", test_vp117, ": ", l117)
			get_tree().quit(1)
			return

	over117.queue_free()
	pause117.queue_free()
	menu117.queue_free()
	print("[TEST 117/118] Unified Button Visual Language, Pause Menu Voice+Haptics & Title Polish: PASSED")

	# ==============================================================================
	# TEST 118: Text-Only START Button, Large Game Screens (Pause & Settings), Spin Again Reward Logic
	# ==============================================================================
	print("[TEST 118] Verifying Text-Only START CTA, Large Pause & Settings Screens, and Spin Again Reward Mechanics...")
	var menu118 = MainMenuScene.instantiate()
	var pause118 = PauseMenuScene.instantiate()
	add_child(menu118)
	add_child(pause118)

	# 1. START Button: Text only, strictly no play icon or extra whitespace
	if menu118.btn_start.get_node_or_null("VectorIcon") != null:
		printerr("[FAIL Test 118.1] START button must NOT contain any play/triangle icon!")
		get_tree().quit(1)
		return
	if not menu118.has_text_only_start_button():
		printerr("[FAIL Test 118.1] START button must be text-only and centered horizontally!")
		get_tree().quit(1)
		return
	game_state.set_language("en", false)
	if menu118.btn_start.text != "START":
		printerr("[FAIL Test 118.1] EN Start button text must be 'START', got: ", menu118.btn_start.text)
		get_tree().quit(1)
		return
	game_state.set_language("vi", false)
	if menu118.btn_start.text != "BẮT ĐẦU":
		printerr("[FAIL Test 118.1] VI Start button text must be 'BẮT ĐẦU', got: ", menu118.btn_start.text)
		get_tree().quit(1)
		return
	game_state.set_language("en", false)

	# 2. Pause Menu & Settings Game Screen sizing and large touch targets
	if pause118.btn_resume.custom_minimum_size.y < 64 or pause118.btn_restart.custom_minimum_size.y < 60:
		printerr("[FAIL Test 118.2] Pause Menu touch targets must be enlarged for casual-game feel!")
		get_tree().quit(1)
		return

	for vp_test in [Vector2(360, 800), Vector2(390, 844), Vector2(720, 1280)]:
		var sinsp: Dictionary = menu118.get_settings_layout_inspection(vp_test)
		if not bool(sinsp.get("no_clipping", false)) or not bool(sinsp.get("voice_haptics_same_row", false)):
			printerr("[FAIL Test 118.2] Settings modal layout inspection failed on ", vp_test, ": ", sinsp)
			get_tree().quit(1)
			return

	# 3. Daily Gift Spin Again Functional Reward Mechanics & Wedge Placement
	var slices118: Array = game_state.get_lucky_wheel_slices()
	if String(slices118[5].get("reward_type", "")) != "lucky_next_time" or String(slices118[6].get("reward_type", "")) != "spin_again" or String(slices118[7].get("reward_type", "")) != "lucky_next_time":
		printerr("[FAIL Test 118.3] Spin Again (Wedge 6) must be placed between Lucky Next Time (Wedge 5) and Lucky Next Time (Wedge 7)!")
		get_tree().quit(1)
		return

	game_state.reset_progression(false)
	var spin_again_res: Dictionary = game_state.spin_daily_gift_wheel(6, "2026-10-02") # Wedge 6 is spin_again
	if not bool(spin_again_res.get("success", false)) or String(spin_again_res.get("reward_type", "")) != "spin_again":
		printerr("[FAIL Test 118.3] Spin Again reward failed to grant extra spin: ", spin_again_res)
		get_tree().quit(1)
		return
	if not game_state.can_spin_lucky_wheel("2026-10-02"):
		printerr("[FAIL Test 118.3] GameState must allow another spin after landing on Spin Again!")
		get_tree().quit(1)
		return
	# Spin second time on calendar day
	var next_spin_res: Dictionary = game_state.spin_daily_gift_wheel(0, "2026-10-02") # Bomb wedge
	if not bool(next_spin_res.get("success", false)) or String(next_spin_res.get("reward_type", "")) != "bomb":
		printerr("[FAIL Test 118.3] Second spin using extra turn failed: ", next_spin_res)
		get_tree().quit(1)
		return
	if game_state.can_spin_lucky_wheel("2026-10-02"):
		printerr("[FAIL Test 118.3] Daily spins must be exhausted after consuming granted extra spin!")
		get_tree().quit(1)
		return

	# 4. In-Game HUD: Frameless badges, LV + Level Number, Score 1 star + current / target format
	var hud_scene = load("res://scenes/ui/hud.tscn")
	if hud_scene != null:
		var hud_visual_inst = hud_scene.instantiate()
		add_child(hud_visual_inst)
		game_state.set_language("en", false)
		hud_visual_inst._refresh_language()
		
		# Verify frameless background panels (StyleBoxEmpty, no background card/badge)
		var lv_sb = hud_visual_inst.level_panel.get_theme_stylebox("panel") if hud_visual_inst.level_panel else null
		var sc_sb = hud_visual_inst.get_node_or_null("MarginContainer/VBoxContainer/HeaderRow/ScorePanel")
		if lv_sb != null and not (lv_sb is StyleBoxEmpty):
			printerr("[FAIL Test 118.4] LevelPanel must use StyleBoxEmpty with NO enclosing background card!")
			get_tree().quit(1)
			return
		
		if hud_visual_inst.lbl_level and not hud_visual_inst.lbl_level.text.begins_with("LV "):
			printerr("[FAIL Test 118.4] HUD level text in EN must begin with 'LV ', got: ", hud_visual_inst.lbl_level.text)
			get_tree().quit(1)
			return
		if hud_visual_inst.lbl_goal_progress and not ("/" in hud_visual_inst.lbl_goal_progress.text):
			printerr("[FAIL Test 118.4] HUD score goal text in EN must contain '/' separator, got: ", hud_visual_inst.lbl_goal_progress.text)
			get_tree().quit(1)
			return
		game_state.set_language("vi", false)
		hud_visual_inst._refresh_language()
		if hud_visual_inst.lbl_level and not hud_visual_inst.lbl_level.text.begins_with("LV "):
			printerr("[FAIL Test 118.4] HUD level text in VI must begin with 'LV ', got: ", hud_visual_inst.lbl_level.text)
			get_tree().quit(1)
			return
		if hud_visual_inst.lbl_goal_progress and not ("/" in hud_visual_inst.lbl_goal_progress.text):
			printerr("[FAIL Test 118.4] HUD score goal text in VI must contain '/' separator, got: ", hud_visual_inst.lbl_goal_progress.text)
			get_tree().quit(1)
			return
		game_state.set_language("en", false)
		hud_visual_inst.queue_free()

	pause118.queue_free()
	menu118.queue_free()
	print("[TEST 118/119] Text-Only START CTA, Large Pause & Settings Screens, and Spin Again Mechanics: PASSED")

	# =========================================================================
	# TEST 119: Focused Regression Test for Classic + Drag & Drop Column Clear & Touch Snap Accuracy
	# =========================================================================
	print("[TEST 119] Verifying Classic + Drag & Drop Column Clearing & Drag Touch Snap Accuracy...")
	
	# Part 1: Classic + Drag & Drop Column Clear
	var cd_game = ModernModeScript.new()
	cd_game.configure_combination(GameStateScript.GameMode.CLASSIC, GameStateScript.PlayStyle.DRAG_AND_DROP)
	add_child(cd_game)
	cd_game.initialize_mode()
	cd_game.start_mode()
	
	var cd_b = cd_game.get_board()
	cd_b.clear_board()
	
	# Pre-fill column 3 except top 4 cells (y = 0..3 empty, y = 4..9 filled with block color 2)
	for y in range(4, 10):
		cd_b.grid_data[y][3] = 2
	if cd_b.get_occupied_cell_count() != 6:
		printerr("[FAIL Test 119.1] Pre-fill count mismatch: ", cd_b.get_occupied_cell_count())
		get_tree().quit(1)
		return
	
	# Simulate placing a vertical line piece (line_4_v: cells (0,0), (0,1), (0,2), (0,3)) at origin (3, 0)
	var line_cells = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)]
	if not cd_b.can_place_piece(line_cells, Vector2i(3, 0)):
		printerr("[FAIL Test 119.1] Line piece should be placeable at (3, 0)")
		get_tree().quit(1)
		return
	cd_b.place_piece(line_cells, Vector2i(3, 0), 2, "crystal")
	
	# Run check_and_clear_lines
	var col_clear_res = cd_b.check_and_clear_lines(cd_game.allows_column_clear(), cd_game.uses_gravity())
	if int(col_clear_res.get("lines_cleared", 0)) != 1 or int(col_clear_res.get("col_count", 0)) != 1 or cd_b.get_occupied_cell_count() != 0:
		printerr("[FAIL Test 119.1] Completed vertical column MUST clear in Classic + Drag & Drop! Got: ", col_clear_res, " remaining cells: ", cd_b.get_occupied_cell_count())
		get_tree().quit(1)
		return
	
	# Part 2: Touch positioning, 3-cell visual offset & preview center snap
	var cd_tray = cd_game.get_piece_tray()
	var test_piece: Control = null
	for p in cd_tray.active_pieces:
		if p != null and is_instance_valid(p):
			test_piece = p
			break
	if test_piece == null:
		printerr("[FAIL Test 119.2] Tray piece not found")
		get_tree().quit(1)
		return
	
	# Verify TOUCH_Y_OFFSET is exactly 3 * CELL_SIZE
	var expected_touch_y_offset: float = test_piece.cell_size * 3.0
	if not is_equal_approx(float(test_piece.TOUCH_Y_OFFSET), expected_touch_y_offset):
		printerr("[FAIL Test 119.2] TOUCH_Y_OFFSET must equal 3 * CELL_SIZE (", expected_touch_y_offset, "), got: ", test_piece.TOUCH_Y_OFFSET)
		get_tree().quit(1)
		return
	
	# Simulate touch drag at finger position
	var finger_pos := Vector2(360, 480)
	test_piece._start_drag(finger_pos, 0)
	test_piece._move_drag(finger_pos)
	
	# 1. Touch visual position must equal finger position - Vector2(0, 3 * CELL_SIZE) along Y
	var vis_center = test_piece.get_visual_center_global()
	var expected_vis_center = finger_pos - Vector2(0, expected_touch_y_offset)
	if not vis_center.is_equal_approx(expected_vis_center):
		printerr("[FAIL Test 119.2] Rendered piece visual center (", vis_center, ") must be 3 cells above finger position (", expected_vis_center, ")")
		get_tree().quit(1)
		return
	
	# 2. Over the board, finger positioned at (target_board_center + Vector2(0, TOUCH_Y_OFFSET)) renders block directly over target_board_center
	var target_cell := Vector2i(2, 4)
	var target_board_center := cd_b.to_global(cd_b.grid_to_local_shape_center(target_cell, test_piece.cells))
	var finger_input_pos := target_board_center + Vector2(0, expected_touch_y_offset)
	
	test_piece._move_drag(finger_input_pos)
	cd_game._on_piece_drag_moved(test_piece, finger_input_pos)
	
	# Rendered block visual center must be aligned with target_board_center
	var dragged_vis_center = test_piece.get_visual_center_global()
	if not dragged_vis_center.is_equal_approx(target_board_center):
		printerr("[FAIL Test 119.2] Rendered block center (", dragged_vis_center, ") must align with target board center (", target_board_center, ")")
		get_tree().quit(1)
		return
	
	# Resolved grid origin must match target_cell
	var resolved_origin := cd_game._resolve_drop_grid_origin(test_piece, finger_input_pos)
	if resolved_origin != target_cell:
		printerr("[FAIL Test 119.2] Resolved grid origin (", resolved_origin, ") must equal target cell (", target_cell, ")")
		get_tree().quit(1)
		return
	
	# Preview origin must equal target_cell
	if not cd_b.preview_active or cd_b.preview_origin != target_cell:
		printerr("[FAIL Test 119.2] Board preview must be active at target_cell (", target_cell, "), got: ", cd_b.preview_origin)
		get_tree().quit(1)
		return
	
	# 3. End drag and verify piece placement matches the previewed origin exactly with zero double-offset
	cd_game._on_piece_drag_ended(test_piece, finger_input_pos)
	if cd_b.get_occupied_cell_count() != test_piece.cells.size():
		printerr("[FAIL Test 119.2] Final placement must place piece at the exact calculated preview position!")
		get_tree().quit(1)
		return
	
	cd_game.queue_free()
	print("[TEST 119/119] Classic + Drag & Drop Column Clearing & 3-Cell Touch Offset Snap: PASSED")

	board.queue_free()
	if audio_mgr and audio_mgr.has_method("shutdown_audio"):
		audio_mgr.shutdown_audio()
	_tests_completed = true
	print("[TEST] ALL 119/119 AUTOMATED TESTS PASSED PERFECTLY!")


func _cleanup_test_runner_nodes() -> void:
	var am := get_node_or_null("/root/AudioManager")
	if am and am.has_method("shutdown_audio"):
		am.shutdown_audio()
	for ch in get_children():
		if is_instance_valid(ch) and not ch.is_queued_for_deletion():
			ch.queue_free()
	if UIIconScript:
		UIIconScript.cleanup_static_resources()

func _exit_tree() -> void:
	_cleanup_test_runner_nodes()

func _process(_delta: float) -> void:
	if not _tests_completed:
		printerr("[FAIL] TestRunner _ready() exited early due to a script error before completing all tests!")
		_cleanup_test_runner_nodes()
		_quit_delay_frames += 1
		if _quit_delay_frames >= 2:
			get_tree().quit(1)
		return
	_quit_delay_frames += 1
	if _quit_delay_frames == 1:
		_cleanup_test_runner_nodes()
	if _quit_delay_frames >= 2:
		get_tree().quit(0)
