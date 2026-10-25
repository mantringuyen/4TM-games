extends Node2D

## GameWorld — Manages active gameplay combination (GameMode x PlayStyle), board container, boosters,
## and renders a bright, colorful 4TM mobile puzzle world backdrop behind the 12x10 board.

const GameStateScript = preload("res://scripts/autoload/game_state.gd")
const ClassicModeScript = preload("res://scripts/core/classic_mode.gd")
const ModernModeScript = preload("res://scripts/core/modern_mode.gd")
const GameModeBaseScript = preload("res://scripts/core/game_mode.gd")

@onready var mode_container: Node2D = $ModeContainer
var active_mode_node: Node2D = null
var anim_time: float = 0.0
var is_modern_world: bool = true

var world_clouds: Array = [
	{"x": 0.16, "y": 0.11, "r": 58.0, "speed": 0.16, "phase": 0.0},
	{"x": 0.78, "y": 0.15, "r": 64.0, "speed": 0.12, "phase": 1.8},
	{"x": 0.45, "y": 0.24, "r": 48.0, "speed": 0.20, "phase": 3.4}
]

var world_sparkles: Array = [
	{"x": 0.10, "y": 0.28, "r": 6.0, "phase": 0.2, "col": Color(1.0, 0.92, 0.35, 0.85)},
	{"x": 0.90, "y": 0.32, "r": 7.0, "phase": 1.1, "col": Color(0.35, 0.96, 1.0, 0.85)},
	{"x": 0.12, "y": 0.56, "r": 5.5, "phase": 2.4, "col": Color(1.0, 0.55, 0.85, 0.85)},
	{"x": 0.88, "y": 0.62, "r": 6.5, "phase": 3.7, "col": Color(0.45, 1.0, 0.72, 0.85)},
	{"x": 0.18, "y": 0.82, "r": 6.0, "phase": 4.5, "col": Color(1.0, 0.85, 0.25, 0.85)},
	{"x": 0.84, "y": 0.84, "r": 5.5, "phase": 5.3, "col": Color(0.55, 0.88, 1.0, 0.85)}
]

var _pending_teardown_id: int = 0
var _pending_teardown_nodes: Array[Node] = []


func _exit_tree() -> void:
	var state_mgr = _get_game_state()
	if state_mgr:
		if state_mgr.game_started.is_connected(_on_game_started):
			state_mgr.game_started.disconnect(_on_game_started)
		if state_mgr.state_changed.is_connected(_on_state_changed):
			state_mgr.state_changed.disconnect(_on_state_changed)
	_ensure_main_loop_teardown_polling()


func _ready() -> void:
	var state_mgr = _get_game_state()
	if state_mgr:
		if not state_mgr.game_started.is_connected(_on_game_started):
			state_mgr.game_started.connect(_on_game_started)
		if not state_mgr.state_changed.is_connected(_on_state_changed):
			state_mgr.state_changed.connect(_on_state_changed)
		is_modern_world = (state_mgr.current_mode == GameStateScript.GameMode.MODERN_DRAG_AND_DROP)
	queue_redraw()


func _process(delta: float) -> void:
	anim_time += delta


func _draw() -> void:
	var vp_size = get_viewport_rect().size if is_inside_tree() and get_viewport() else Vector2(720.0, 1280.0)
	var w = vp_size.x if vp_size.x > 0 else 720.0
	var h = vp_size.y if vp_size.y > 0 else 1280.0

	for sp in world_sparkles:
		var pulse = 0.55 + 0.45 * sin(anim_time * 2.4 + float(sp["phase"]))
		var pos = Vector2(w * float(sp["x"]), h * float(sp["y"]))
		var sr = float(sp["r"]) * pulse
		var scol: Color = sp["col"]
		scol.a *= pulse * 0.55
		var star_pts = PackedVector2Array([
			pos + Vector2(0, -sr * 1.5),
			pos + Vector2(sr * 0.42, -sr * 0.42),
			pos + Vector2(sr * 1.5, 0),
			pos + Vector2(sr * 0.42, sr * 0.42),
			pos + Vector2(0, sr * 1.5),
			pos + Vector2(-sr * 0.42, sr * 0.42),
			pos + Vector2(-sr * 1.5, 0),
			pos + Vector2(-sr * 0.42, -sr * 0.42)
		])
		draw_colored_polygon(star_pts, scol)


func _on_game_started(mode: int) -> void:
	var start_ms: int = Time.get_ticks_msec()
	var state_mgr = _get_game_state()
	var style: int = GameStateScript.PlayStyle.FALLING if mode == GameStateScript.GameMode.CLASSIC else GameStateScript.PlayStyle.DRAG_AND_DROP
	if state_mgr and "current_play_style" in state_mgr:
		style = state_mgr.current_play_style
	
	var sess_num: int = state_mgr.session_start_counter if (state_mgr and "session_start_counter" in state_mgr) else 0
	print("[%d] [LIFECYCLE] GameWorld: _on_game_started STARTED (session #%d, mode=%d, style=%d)" % [start_ms, sess_num, mode, style])
	
	_clear_active_mode()
	is_modern_world = (mode == GameStateScript.GameMode.MODERN_DRAG_AND_DROP)
	queue_redraw()
	
	match style:
		GameStateScript.PlayStyle.FALLING:
			active_mode_node = ClassicModeScript.new()
		GameStateScript.PlayStyle.DRAG_AND_DROP, _:
			active_mode_node = ModernModeScript.new()
	
	if active_mode_node and mode_container:
		if active_mode_node.has_method("configure_combination"):
			active_mode_node.configure_combination(mode, style)
		mode_container.add_child(active_mode_node)
		if active_mode_node.has_method("initialize_mode"):
			active_mode_node.initialize_mode()
		if active_mode_node.has_method("start_mode"):
			active_mode_node.start_mode()
	print("[%d] [LIFECYCLE] GameWorld: _on_game_started COMPLETED (took=%dms)" % [Time.get_ticks_msec(), Time.get_ticks_msec() - start_ms])


func use_special_item(item_id: String) -> bool:
	if item_id == "extra_life":
		var state_mgr = _get_game_state()
		if not state_mgr or state_mgr.current_state != GameStateScript.State.GAME_OVER:
			return false
		if state_mgr.has_method("can_use_extra_life_now") and not state_mgr.can_use_extra_life_now():
			return false
	if active_mode_node and active_mode_node.has_method("apply_special_item"):
		return active_mode_node.apply_special_item(item_id)
	return false


func get_active_mode() -> Node2D:
	return active_mode_node


func _on_state_changed(new_state: int, _prev_state: int) -> void:
	if new_state == GameStateScript.State.MENU:
		_clear_active_mode()
	elif new_state == GameStateScript.State.PAUSED and active_mode_node:
		if active_mode_node.has_method("pause_mode"):
			active_mode_node.pause_mode(true)
	elif new_state == GameStateScript.State.PLAYING and active_mode_node:
		if active_mode_node.has_method("pause_mode"):
			active_mode_node.pause_mode(false)


func _ensure_main_loop_teardown_polling() -> void:
	if _pending_teardown_id <= 0:
		return
	var main_loop := Engine.get_main_loop() as SceneTree
	if main_loop and not main_loop.process_frame.is_connected(_on_poll_teardown_frame):
		main_loop.process_frame.connect(_on_poll_teardown_frame)


func _stop_teardown_polling() -> void:
	if is_inside_tree() and get_tree() and get_tree().process_frame.is_connected(_on_poll_teardown_frame):
		get_tree().process_frame.disconnect(_on_poll_teardown_frame)
	var main_loop := Engine.get_main_loop() as SceneTree
	if main_loop and main_loop.process_frame.is_connected(_on_poll_teardown_frame):
		main_loop.process_frame.disconnect(_on_poll_teardown_frame)
	_pending_teardown_id = 0
	_pending_teardown_nodes.clear()


func _clear_active_mode() -> void:
	var start_ms: int = Time.get_ticks_msec()
	var state_mgr = _get_game_state()
	var active_teardown_id: int = 0
	if state_mgr and "is_teardown_pending" in state_mgr and state_mgr.is_teardown_pending:
		active_teardown_id = int(state_mgr.teardown_session_id)
	
	_stop_teardown_polling()

	var nodes_to_watch: Array[Node] = []
	if active_mode_node and is_instance_valid(active_mode_node):
		if not (active_mode_node in nodes_to_watch):
			nodes_to_watch.append(active_mode_node)
		if active_mode_node.has_method("end_mode"):
			active_mode_node.end_mode()
		active_mode_node.process_mode = Node.PROCESS_MODE_DISABLED
		if active_mode_node.get_parent():
			active_mode_node.get_parent().remove_child(active_mode_node)
		active_mode_node.queue_free()
		active_mode_node = null

	if mode_container:
		for child in mode_container.get_children():
			if is_instance_valid(child):
				if not (child in nodes_to_watch):
					nodes_to_watch.append(child)
				if child.has_method("end_mode"):
					child.end_mode()
				child.process_mode = Node.PROCESS_MODE_DISABLED
				if child.get_parent():
					child.get_parent().remove_child(child)
				child.queue_free()

	if active_teardown_id > 0:
		var still_valid: Array[Node] = []
		for n in nodes_to_watch:
			if is_instance_valid(n):
				still_valid.append(n)
		
		if not still_valid.is_empty():
			_pending_teardown_id = active_teardown_id
			_pending_teardown_nodes = still_valid
			_ensure_main_loop_teardown_polling()
		else:
			_complete_teardown_for_id(active_teardown_id)


func _on_poll_teardown_frame() -> void:
	if _pending_teardown_id <= 0:
		_stop_teardown_polling()
		return
	var all_freed: bool = true
	for n in _pending_teardown_nodes:
		if is_instance_valid(n):
			all_freed = false
			break
	if all_freed:
		var tid: int = _pending_teardown_id
		_stop_teardown_polling()
		_complete_teardown_for_id(tid)


func _complete_teardown_for_id(teardown_id: int) -> void:
	if teardown_id <= 0:
		return
	var state_mgr = _get_game_state()
	if state_mgr:
		if state_mgr.has_method("complete_session_teardown"):
			state_mgr.complete_session_teardown(teardown_id)
		elif "teardown_session_id" in state_mgr:
			if state_mgr.teardown_session_id == teardown_id:
				state_mgr.is_teardown_pending = false
				print("[%d] [LIFECYCLE] GameWorld: Teardown #%d GENUINELY COMPLETED (teardown_pending=false)" % [Time.get_ticks_msec(), teardown_id])


func _get_game_state() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/GameState")
	var main_loop := Engine.get_main_loop() as SceneTree
	if main_loop and main_loop.root:
		return main_loop.root.get_node_or_null("GameState")
	return null
