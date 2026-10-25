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
	var tid_to_complete: int = _pending_teardown_id
	_stop_teardown_polling()
	_clear_active_mode()
	if tid_to_complete > 0:
		_complete_teardown_for_id(tid_to_complete)


func _stop_teardown_polling() -> void:
	if is_inside_tree() and get_tree() and get_tree().process_frame.is_connected(_on_poll_teardown_frame):
		get_tree().process_frame.disconnect(_on_poll_teardown_frame)
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
				if child.get_parent():
					child.get_parent().remove_child(child)
				child.queue_free()

	if active_teardown_id > 0:
		var still_valid: Array[Node] = []
		for n in nodes_to_watch:
			if is_instance_valid(n):
				still_valid.append(n)
		
		if not still_valid.is_empty() and is_inside_tree() and get_tree():
			_pending_teardown_id = active_teardown_id
			_pending_teardown_nodes = still_valid
			if not get_tree().process_frame.is_connected(_on_poll_teardown_frame):
				get_tree().process_frame.connect(_on_poll_teardown_frame)
		else:
			_complete_teardown_for_id(active_teardown_id)


func _on_poll_teardown_frame() -> void:
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


