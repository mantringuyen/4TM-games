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


func _ready() -> void:
	var state_mgr = get_node_or_null("/root/GameState")
	if state_mgr:
		state_mgr.game_started.connect(_on_game_started)
		state_mgr.state_changed.connect(_on_state_changed)
		is_modern_world = (state_mgr.current_mode == GameStateScript.GameMode.MODERN_DRAG_AND_DROP)
	queue_redraw()


func _process(delta: float) -> void:
	anim_time += delta


func _draw() -> void:
	var vp_size = get_viewport_rect().size if is_inside_tree() and get_viewport() else Vector2(720.0, 1280.0)
	var w = vp_size.x if vp_size.x > 0 else 720.0
	var h = vp_size.y if vp_size.y > 0 else 1280.0

	# Keep GameWorld canvas transparent so Main's per-level LevelBackdropLayer remains
	# 100% visible behind and through the transparent 12x10 play board.
	# Only draw subtle ambient margin sparkles for depth.
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
	_clear_active_mode()
	is_modern_world = (mode == GameStateScript.GameMode.MODERN_DRAG_AND_DROP)
	queue_redraw()
	
	var state_mgr = get_node_or_null("/root/GameState")
	var style: int = GameStateScript.PlayStyle.FALLING if mode == GameStateScript.GameMode.CLASSIC else GameStateScript.PlayStyle.DRAG_AND_DROP
	if state_mgr and "current_play_style" in state_mgr:
		style = state_mgr.current_play_style
	
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


func use_special_item(item_id: String) -> bool:
	if item_id == "extra_life":
		var state_mgr = get_node_or_null("/root/GameState")
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


func _clear_active_mode() -> void:
	if active_mode_node:
		if active_mode_node.has_method("end_mode"):
			active_mode_node.end_mode()
		active_mode_node.queue_free()
		active_mode_node = null
