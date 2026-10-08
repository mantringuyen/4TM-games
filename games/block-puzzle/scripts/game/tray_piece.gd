class_name TrayPiece
extends Control

## TrayPiece — Draggable 3D rounded crystal/gem 4-cell tetromino sitting in the Drag & Drop tray.
## Enforces a strict 3-state machine:
##   1. IN_TRAY
##   2. DRAGGING
##   3. PLACED
## Captures original slot/position/scale/identity snapshot on drag start and guarantees
## full restoration on any invalid drop, out-of-bounds release, or focus/mouse/UI interruption.

signal drag_started(piece: Control)
signal drag_moved(piece: Control, global_pos: Vector2)
signal drag_ended(piece: Control, global_pos: Vector2)
signal drag_cancelled(piece: Control, reason: String)
signal piece_rotated(piece: Control)
signal selected_for_change(piece: Control)

enum PieceState {
	IN_TRAY = 0,
	DRAGGING = 1,
	PLACED = 2
}

const PolyominoLib = preload("res://scripts/core/polyomino_library.gd")

var cell_size: float = 54.8
var cell_gap: float = 4.0
const PREVIEW_SCALE: float = 0.56
const DRAG_SCALE: float = 1.0

var TOUCH_Y_OFFSET: float:
	get:
		return cell_size * 3.0

var shape_data: Dictionary = {}
var cells: Array = []
var _canonical_cells: Array = []
var color: Color = Color.WHITE
var color_id: int = 1
var material_id: String = ""
var slot_index: int = 0
var piece_id: String = ""
var change_select_mode: bool = false

const POINTER_ID_NONE: int = -999
const POINTER_ID_MOUSE: int = -1

var piece_state: int = PieceState.IN_TRAY
var home_position: Vector2 = Vector2.ZERO
var original_scale_vec: Vector2 = Vector2(PREVIEW_SCALE, PREVIEW_SCALE)
var current_scale: float = PREVIEW_SCALE
var drag_touch_index: int = -1
var drag_pointer_id: int:
	get:
		return drag_touch_index if piece_state == PieceState.DRAGGING else POINTER_ID_NONE
	set(val):
		drag_touch_index = val
var rotate_button_pointer_id: int = POINTER_ID_NONE
var rotate_button_consumed: bool = false
var free_tap_pointer_id: int = POINTER_ID_NONE
var rotate_pointer_id: int:
	get:
		if rotate_button_pointer_id != POINTER_ID_NONE:
			return rotate_button_pointer_id
		return free_tap_pointer_id
	set(val):
		rotate_button_pointer_id = val
		if val == POINTER_ID_NONE:
			rotate_button_consumed = false
			free_tap_pointer_id = POINTER_ID_NONE
var last_rotation_source: String = ""
var active_pointer_pos: Vector2 = Vector2.ZERO
var press_start_pos: Vector2 = Vector2.ZERO
var press_start_time: float = 0.0
var _started_with_hardware_mouse: bool = false
var _pointer_left_viewport_during_drag: bool = false
var drag_start_snapshot: Dictionary = {}
var rotation_steps: int = 0
var _last_rotate_frame: int = -1
var _ignore_next_rotate_mouse_release: bool = false
var is_snapped_to_board_preview: bool = false

var is_dragging: bool:
	get:
		return piece_state == PieceState.DRAGGING
	set(val):
		if val:
			piece_state = PieceState.DRAGGING
		elif piece_state == PieceState.DRAGGING:
			piece_state = PieceState.IN_TRAY

var is_consumed: bool:
	get:
		return piece_state == PieceState.PLACED
	set(val):
		if val:
			piece_state = PieceState.PLACED
		elif piece_state == PieceState.PLACED:
			piece_state = PieceState.IN_TRAY

var is_placed: bool:
	get:
		return piece_state == PieceState.PLACED

var tween: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(140, 140)
	mouse_filter = Control.MOUSE_FILTER_PASS
	pivot_offset = Vector2.ZERO


func get_state_name() -> String:
	match piece_state:
		PieceState.IN_TRAY:
			return "IN_TRAY"
		PieceState.DRAGGING:
			return "DRAGGING"
		PieceState.PLACED:
			return "PLACED"
	return "IN_TRAY"


func set_board_cell_metrics(new_cell_size: float, new_cell_gap: float) -> void:
	if new_cell_size > 10.0:
		cell_size = new_cell_size
	if new_cell_gap >= 0.0:
		cell_gap = new_cell_gap
	_update_dimensions()
	queue_redraw()


func setup_piece(data: Dictionary, slot_idx: int) -> void:
	var gs = get_node_or_null("/root/GameState")
	var cur_lvl: int = gs.active_level if (gs and "active_level" in gs) else 1
	shape_data = PolyominoLib.stamp_piece_material(data.duplicate(true), cur_lvl)
	cells = shape_data.get("cells", []).duplicate(true)
	_canonical_cells = cells.duplicate(true)
	color = shape_data.get("color", Color.WHITE)
	color_id = int(shape_data.get("color_id", 1))
	material_id = String(shape_data.get("material_id", ""))
	piece_id = String(shape_data.get("id", "tetromino"))
	slot_index = slot_idx
	piece_state = PieceState.IN_TRAY
	rotation_steps = 0
	drag_touch_index = -1
	rotate_button_pointer_id = POINTER_ID_NONE
	rotate_button_consumed = false
	free_tap_pointer_id = POINTER_ID_NONE
	last_rotation_source = ""
	_started_with_hardware_mouse = false
	_pointer_left_viewport_during_drag = false
	is_snapped_to_board_preview = false
	current_scale = PREVIEW_SCALE
	original_scale_vec = Vector2(PREVIEW_SCALE, PREVIEW_SCALE)
	pivot_offset = Vector2.ZERO
	scale = original_scale_vec
	visible = true
	modulate = Color(1, 1, 1, 1)
	_update_dimensions()
	_capture_drag_snapshot()
	queue_redraw()


func _capture_drag_snapshot() -> void:
	if cells.is_empty() and not _canonical_cells.is_empty():
		cells = _canonical_cells.duplicate(true)
	drag_start_snapshot = {
		"slot_index": slot_index,
		"home_position": home_position,
		"original_scale": Vector2(PREVIEW_SCALE, PREVIEW_SCALE),
		"piece_id": piece_id,
		"shape_data": shape_data.duplicate(true),
		"cells": cells.duplicate(true) if cells.size() == 4 else _canonical_cells.duplicate(true),
		"rotation_steps": rotation_steps,
		"color": color,
		"color_id": color_id,
		"material_id": material_id,
		"state": piece_state
	}


func rotate_dragged_piece(source: String = "rotate_button") -> bool:
	if piece_state != PieceState.DRAGGING or cells.is_empty():
		return false
	var rotated: Array = PolyominoLib.rotate_90_cw(cells)
	if rotated.size() != 4:
		return false
	cells = rotated
	shape_data["cells"] = cells.duplicate(true)
	rotation_steps = (rotation_steps + 1) % 4
	last_rotation_source = source
	_update_dimensions()
	_update_drag_position(active_pointer_pos)
	visible = true
	modulate.a = 1.0
	queue_redraw()
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_rotation"):
		audio_mgr.play_rotation()
	piece_rotated.emit(self)
	drag_moved.emit(self, active_pointer_pos)
	return true


func _is_point_on_drag_rotate_button(global_pt: Vector2) -> bool:
	var p_tray := get_parent()
	if p_tray and p_tray.has_method("is_point_on_rotate_button"):
		return p_tray.is_point_on_rotate_button(global_pt)
	return false


func is_point_on_interactive_ui_control(global_pt: Vector2) -> bool:
	if _is_point_on_drag_rotate_button(global_pt):
		return false
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return false
	return _find_interactive_ui_control_at(get_tree().root, global_pt) != null


func _find_interactive_ui_control_at(node: Node, global_pt: Vector2) -> Control:
	if node == null or not is_instance_valid(node) or node.is_queued_for_deletion():
		return null
	if node is CanvasItem and not (node as CanvasItem).is_visible_in_tree():
		return null
	var p_tray := get_parent()
	if node == self or node == p_tray:
		return null
	var child_count: int = node.get_child_count()
	for idx in range(child_count - 1, -1, -1):
		var child: Node = node.get_child(idx)
		var hit_child: Control = _find_interactive_ui_control_at(child, global_pt)
		if hit_child != null:
			return hit_child
	if node is BaseButton:
		var btn := node as BaseButton
		if btn.mouse_filter != Control.MOUSE_FILTER_IGNORE and not btn.disabled:
			if btn.get_global_rect().has_point(global_pt):
				return btn
	return null


func get_grid_dimensions() -> Vector2i:
	return PolyominoLib.get_dimensions(cells)


func get_shape_pixel_size() -> Vector2:
	var dims = get_dimensions_cells()
	var w = dims.x * cell_size + (dims.x - 1) * cell_gap
	var h = dims.y * cell_size + (dims.y - 1) * cell_gap
	return Vector2(w, h)


func get_dimensions_cells() -> Vector2i:
	if cells.is_empty():
		return Vector2i.ONE
	var max_x: int = 0
	var max_y: int = 0
	for c in cells:
		if c.x > max_x: max_x = c.x
		if c.y > max_y: max_y = c.y
	return Vector2i(max_x + 1, max_y + 1)


func _update_dimensions() -> void:
	var shape_sz = get_shape_pixel_size()
	custom_minimum_size = shape_sz
	size = shape_sz
	pivot_offset = Vector2.ZERO


func get_visual_center_offset() -> Vector2:
	return (get_shape_pixel_size() * current_scale) * 0.5


func get_visual_center_global() -> Vector2:
	return global_position + get_visual_center_offset()


func get_visual_rect_global() -> Rect2:
	return Rect2(global_position, get_shape_pixel_size() * current_scale)


func get_board_target_world_pos() -> Vector2:
	return get_visual_center_global()


func _resolve_gui_event_global_pos(event: InputEvent) -> Vector2:
	if event is InputEventMouse:
		# In Godot 4, _gui_input receives mouse events transformed into Control-local coordinates.
		# Convert local event.position back to global canvas coordinates.
		return get_global_transform_with_canvas() * event.position
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		return get_global_transform_with_canvas() * event.position
	if is_inside_tree() and get_viewport():
		return get_viewport().get_mouse_position()
	return get_visual_center_global()


func _process(_delta: float) -> void:
	if piece_state == PieceState.DRAGGING:
		# Enforce visibility invariant while dragging (event-driven pointer/touch capture handles release)
		if not visible or modulate.a < 0.99:
			visible = true
			modulate.a = 1.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_MOUSE_EXIT or what == NOTIFICATION_FOCUS_EXIT or what == NOTIFICATION_DRAG_END:
		if piece_state == PieceState.DRAGGING:
			cancel_drag("notification_%d" % what)
	elif what == NOTIFICATION_VISIBILITY_CHANGED:
		# Never allow an unplaced piece to become invisible
		if piece_state != PieceState.PLACED and not is_queued_for_deletion() and not visible:
			visible = true


func _gui_input(event: InputEvent) -> void:
	if piece_state == PieceState.PLACED or shape_data.is_empty() or cells.is_empty():
		return
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var global_pt: Vector2 = _resolve_gui_event_global_pos(event)
			if event.pressed and change_select_mode:
				if piece_state == PieceState.DRAGGING:
					cancel_drag("change_block_select")
				selected_for_change.emit(self)
				accept_event()
				return
			if event.pressed and piece_state == PieceState.IN_TRAY:
				press_start_pos = global_pt
				press_start_time = Time.get_ticks_msec() / 1000.0
				_started_with_hardware_mouse = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
				_start_drag(global_pt, -1)
				accept_event()
			elif not event.pressed and piece_state == PieceState.DRAGGING and drag_touch_index == -1:
				_end_drag(global_pt)
				accept_event()
	
	elif event is InputEventScreenTouch:
		var touch_pt: Vector2 = _resolve_gui_event_global_pos(event)
		if event.pressed and change_select_mode:
			if piece_state == PieceState.DRAGGING:
				cancel_drag("change_block_select")
			selected_for_change.emit(self)
			accept_event()
			return
		if event.pressed and piece_state == PieceState.IN_TRAY:
			press_start_pos = touch_pt
			press_start_time = Time.get_ticks_msec() / 1000.0
			_started_with_hardware_mouse = false
			_start_drag(touch_pt, event.index)
			accept_event()
		elif not event.pressed and piece_state == PieceState.DRAGGING and drag_touch_index == event.index:
			_end_drag(touch_pt)
			accept_event()


func _input(event: InputEvent) -> void:
	if piece_state != PieceState.DRAGGING:
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_R, KEY_UP, KEY_W]:
			rotate_dragged_piece("keyboard")
			if is_inside_tree() and get_viewport():
				get_viewport().set_input_as_handled()
			return
	
	# 1. Mouse-owned drag gesture (drag_pointer_id == -1 / drag_touch_index == -1)
	if drag_touch_index == POINTER_ID_MOUSE:
		if event is InputEventMouseMotion:
			if event.device == InputEvent.DEVICE_ID_EMULATION:
				if is_inside_tree() and get_viewport():
					get_viewport().set_input_as_handled()
				return
			# Accept pointer movement from anywhere on the gameplay screen; moving across ROTATE never rotates
			_move_drag(event.global_position)
			if is_inside_tree() and get_viewport():
				get_viewport().set_input_as_handled()
			return
		elif event is InputEventMouseButton:
			if event.device == InputEvent.DEVICE_ID_EMULATION:
				if is_inside_tree() and get_viewport():
					get_viewport().set_input_as_handled()
				return
			if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				rotate_dragged_piece("right_click")
				if is_inside_tree() and get_viewport():
					get_viewport().set_input_as_handled()
				return
			elif event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					# Priority 1: Is it inside ROTATE button? -> ROTATE button owns the event, perform 1 rotation, mark rotate_button_consumed = true
					if _is_point_on_drag_rotate_button(event.global_position):
						rotate_button_pointer_id = POINTER_ID_MOUSE
						rotate_button_consumed = true
						free_tap_pointer_id = POINTER_ID_NONE
						_ignore_next_rotate_mouse_release = true
						rotate_dragged_piece("rotate_button")
						if is_inside_tree() and get_viewport():
							get_viewport().set_input_as_handled()
						return
					# Priority 2: Is it another interactive UI control? -> UI owns event, no global rotation
					if is_point_on_interactive_ui_control(event.global_position):
						_ignore_next_rotate_mouse_release = true
						return
					# Priority 3: Mouse click/hold on non-UI gameplay space repositions the active dragged piece
					_move_drag(event.global_position)
					if is_inside_tree() and get_viewport():
						get_viewport().set_input_as_handled()
					return
				else:
					if rotate_button_pointer_id == POINTER_ID_MOUSE or _ignore_next_rotate_mouse_release:
						rotate_button_pointer_id = POINTER_ID_NONE
						rotate_button_consumed = false
						_ignore_next_rotate_mouse_release = false
						if is_point_on_interactive_ui_control(event.global_position):
							return
						if is_inside_tree() and get_viewport():
							get_viewport().set_input_as_handled()
						return
					# Releasing the mouse button anywhere on screen resolves placement or restores to tray slot
					if is_inside_tree() and get_viewport():
						get_viewport().set_input_as_handled()
					_end_drag(event.global_position)
					return
		elif event is InputEventScreenDrag:
			# Secondary touch drag during a mouse-owned drag must never steal drag ownership or move the piece
			if is_inside_tree() and get_viewport():
				get_viewport().set_input_as_handled()
			return
		elif event is InputEventScreenTouch:
			# Secondary touch during a mouse-owned drag: check ROTATE -> UI -> Free secondary tap rotation
			if event.device != InputEvent.DEVICE_ID_EMULATION:
				if event.pressed:
					# Step 1: Is it inside ROTATE button?
					if _is_point_on_drag_rotate_button(event.position):
						rotate_button_pointer_id = event.index
						rotate_button_consumed = true
						rotate_dragged_piece("rotate_button")
						if is_inside_tree() and get_viewport():
							get_viewport().set_input_as_handled()
						return
					# Step 2: Is it another interactive UI control?
					if is_point_on_interactive_ui_control(event.position):
						return
					# Step 3: Free secondary tap on non-UI gameplay space -> exactly ONE 90° global rotation
					if event.index > 0:
						free_tap_pointer_id = event.index
						rotate_dragged_piece("global_tap")
				else:
					if event.index == rotate_button_pointer_id:
						rotate_button_pointer_id = POINTER_ID_NONE
						rotate_button_consumed = false
						if is_inside_tree() and get_viewport():
							get_viewport().set_input_as_handled()
						return
					if event.index == free_tap_pointer_id:
						free_tap_pointer_id = POINTER_ID_NONE
						if is_inside_tree() and get_viewport():
							get_viewport().set_input_as_handled()
						return
					if is_point_on_interactive_ui_control(event.position):
						return
			if is_inside_tree() and get_viewport():
				get_viewport().set_input_as_handled()
			return
	# 2. Touch-owned drag gesture (drag_pointer_id >= 0 / drag_touch_index >= 0)
	else:
		if event is InputEventScreenDrag:
			if event.index == drag_touch_index:
				# Category 1: Drag pointer (Pointer A) moves the piece; crossing/sweeping over ROTATE must NEVER rotate
				_move_drag(event.position)
				if is_inside_tree() and get_viewport():
					get_viewport().set_input_as_handled()
			else:
				# Category 2 & 3: Secondary pointers must NEVER steal drag ownership or move the piece
				if is_inside_tree() and get_viewport():
					get_viewport().set_input_as_handled()
			return
		elif event is InputEventScreenTouch:
			if event.index == drag_touch_index:
				# Category 1: Drag pointer (Pointer A)
				if event.pressed:
					# Priority 1: Single-finger tap on ROTATE button while dragging
					if _is_point_on_drag_rotate_button(event.position):
						rotate_button_pointer_id = event.index
						rotate_button_consumed = true
						rotate_dragged_piece("rotate_button")
						if is_inside_tree() and get_viewport():
							get_viewport().set_input_as_handled()
						return
					# Priority 2: Independent UI controls retain priority
					if is_point_on_interactive_ui_control(event.position):
						return
					# Priority 3: Pointer A tapping/holding on gameplay screen moves the active dragged piece there
					_move_drag(event.position)
					if is_inside_tree() and get_viewport():
						get_viewport().set_input_as_handled()
					return
				# Releasing Pointer A (drag_pointer_id) resolves the drop (valid placement or tray restoration)
				if rotate_button_pointer_id == event.index:
					rotate_button_pointer_id = POINTER_ID_NONE
					rotate_button_consumed = false
				if is_inside_tree() and get_viewport():
					get_viewport().set_input_as_handled()
				_end_drag(event.position)
				return
			else:
				# Secondary pointer (Pointer B, event.index != drag_touch_index):
				if event.pressed:
					# Priority 1: Is it inside ROTATE button?
					# YES -> ROTATE button owns the event, perform exactly ONE rotation, mark rotate_button_consumed = true, global tap-to-rotate MUST NOT run
					if _is_point_on_drag_rotate_button(event.position):
						rotate_button_pointer_id = event.index
						rotate_button_consumed = true
						if free_tap_pointer_id == event.index:
							free_tap_pointer_id = POINTER_ID_NONE
						rotate_dragged_piece("rotate_button")
						if is_inside_tree() and get_viewport():
							get_viewport().set_input_as_handled()
						return
					# Priority 2: Is it another interactive UI control?
					# YES -> UI owns event, no global rotation
					if is_point_on_interactive_ui_control(event.position):
						return
					if is_Set_to_cancel_on_secondary_touch(event.position):
						cancel_drag("secondary_touch_interruption")
						return
					# Priority 3: Free secondary tap pointer on non-UI gameplay space -> perform exactly ONE 90° global rotation
					if event.index == rotate_button_pointer_id and rotate_button_consumed:
						if is_inside_tree() and get_viewport():
							get_viewport().set_input_as_handled()
						return
					free_tap_pointer_id = event.index
					rotate_dragged_piece("global_tap")
					if is_inside_tree() and get_viewport():
						get_viewport().set_input_as_handled()
					return
				else:
					# Release of secondary pointer (Pointer B):
					# If it was the ROTATE-button pointer -> clear state, never invoke global tap-to-rotate, never affect Pointer A's drag
					if event.index == rotate_button_pointer_id:
						rotate_button_pointer_id = POINTER_ID_NONE
						rotate_button_consumed = false
						if is_inside_tree() and get_viewport():
							get_viewport().set_input_as_handled()
						return
					# If it was the Free secondary tap pointer -> clear state, never affect Pointer A's drag
					if event.index == free_tap_pointer_id:
						free_tap_pointer_id = POINTER_ID_NONE
						if is_inside_tree() and get_viewport():
							get_viewport().set_input_as_handled()
						return
					if is_point_on_interactive_ui_control(event.position):
						return
					if is_inside_tree() and get_viewport():
						get_viewport().set_input_as_handled()
					return
		elif event is InputEventMouseMotion or event is InputEventMouseButton:
			# During a touch-owned drag, allow non-emulated clicks on ROTATE or independent UI buttons,
			# and consume emulated mouse events so they never interfere with the touch drag or double-trigger ROTATE.
			if event.device != InputEvent.DEVICE_ID_EMULATION and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					if _is_point_on_drag_rotate_button(event.global_position):
						rotate_button_pointer_id = POINTER_ID_MOUSE
						rotate_button_consumed = true
						rotate_dragged_piece("rotate_button")
						if is_inside_tree() and get_viewport():
							get_viewport().set_input_as_handled()
						return
					if is_point_on_interactive_ui_control(event.global_position):
						return
				else:
					if rotate_button_pointer_id == POINTER_ID_MOUSE:
						rotate_button_pointer_id = POINTER_ID_NONE
						rotate_button_consumed = false
						if is_inside_tree() and get_viewport():
							get_viewport().set_input_as_handled()
						return
					if is_point_on_interactive_ui_control(event.global_position):
						return
			if is_inside_tree() and get_viewport():
				get_viewport().set_input_as_handled()
			return


func is_Set_to_cancel_on_secondary_touch(_pos: Vector2) -> bool:
	return false


func _start_drag(pointer_pos: Vector2, touch_idx: int = -1) -> void:
	if piece_state == PieceState.PLACED:
		return
	if tween and tween.is_valid():
		tween.kill()
	
	# Capture authoritative source-of-truth snapshot BEFORE mutating transform
	if home_position == Vector2.ZERO and position != Vector2.ZERO and piece_state == PieceState.IN_TRAY:
		home_position = position
	_capture_drag_snapshot()
	
	piece_state = PieceState.DRAGGING
	drag_touch_index = touch_idx
	rotate_button_pointer_id = POINTER_ID_NONE
	rotate_button_consumed = false
	free_tap_pointer_id = POINTER_ID_NONE
	last_rotation_source = ""
	active_pointer_pos = pointer_pos
	_pointer_left_viewport_during_drag = false
	_ignore_next_rotate_mouse_release = false
	is_snapped_to_board_preview = false
	
	move_to_front()
	z_index = 100
	
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		audio_mgr.play_piece_pickup()
	
	current_scale = DRAG_SCALE
	pivot_offset = Vector2.ZERO
	scale = Vector2(current_scale, current_scale)
	visible = true
	modulate = Color(1, 1, 1, 1)
	_update_drag_position(pointer_pos)
	drag_started.emit(self)


func _move_drag(pointer_pos: Vector2) -> void:
	if piece_state != PieceState.DRAGGING:
		return
	active_pointer_pos = pointer_pos
	if is_inside_tree() and get_viewport():
		var vp_rect := get_viewport_rect()
		if vp_rect.size.x > 0 and vp_rect.size.y > 0 and not vp_rect.has_point(pointer_pos):
			_pointer_left_viewport_during_drag = true
	visible = true
	modulate.a = 1.0
	_update_drag_position(pointer_pos)
	drag_moved.emit(self, pointer_pos)


func _update_drag_position(pointer_pos: Vector2) -> void:
	var shape_sz = get_shape_pixel_size() * current_scale
	var target_pos = pointer_pos - Vector2(shape_sz.x * 0.5, shape_sz.y * 0.5 + TOUCH_Y_OFFSET)
	global_position = target_pos


func cancel_drag(reason: String = "cancelled") -> void:
	if piece_state == PieceState.PLACED:
		return
	var was_dragging: bool = (piece_state == PieceState.DRAGGING)
	return_to_slot()
	if was_dragging:
		drag_cancelled.emit(self, reason)


func _end_drag(pointer_pos: Vector2) -> void:
	if piece_state != PieceState.DRAGGING:
		return
	
	active_pointer_pos = pointer_pos
	# Always sync visual/global position to the exact release pointer before evaluating drop
	_update_drag_position(pointer_pos)
	drag_touch_index = -1
	rotate_button_pointer_id = POINTER_ID_NONE
	rotate_button_consumed = false
	free_tap_pointer_id = POINTER_ID_NONE
	last_rotation_source = ""
	_started_with_hardware_mouse = false
	_ignore_next_rotate_mouse_release = false
	
	drag_ended.emit(self, pointer_pos)
	
	# CRITICAL GUARANTEE: If the piece was not transitioned to PLACED by a valid board drop,
	# ALWAYS restore it to its original tray slot and assert all IN_TRAY invariants!
	if is_instance_valid(self) and not is_queued_for_deletion() and piece_state != PieceState.PLACED:
		return_to_slot()


func return_to_slot() -> void:
	if piece_state == PieceState.PLACED:
		return
	if tween and tween.is_valid():
		tween.kill()
	
	# Restore from authoritative snapshot if available (including restoring original pre-drag orientation if rotated during drag)
	if not drag_start_snapshot.is_empty():
		slot_index = int(drag_start_snapshot.get("slot_index", slot_index))
		var snap_home: Vector2 = drag_start_snapshot.get("home_position", home_position)
		if snap_home != Vector2.ZERO or home_position == Vector2.ZERO:
			home_position = snap_home
		if drag_start_snapshot.has("cells") and (drag_start_snapshot["cells"] as Array).size() == 4:
			cells = (drag_start_snapshot["cells"] as Array).duplicate(true)
		elif not _canonical_cells.is_empty():
			cells = _canonical_cells.duplicate(true)
		if drag_start_snapshot.has("shape_data"):
			shape_data = (drag_start_snapshot["shape_data"] as Dictionary).duplicate(true)
		shape_data["cells"] = cells.duplicate(true)
		color = drag_start_snapshot.get("color", color)
		color_id = int(drag_start_snapshot.get("color_id", color_id))
		material_id = String(drag_start_snapshot.get("material_id", material_id))
		shape_data["material_id"] = material_id
		shape_data["color"] = color
		rotation_steps = int(drag_start_snapshot.get("rotation_steps", 0))
	elif not _canonical_cells.is_empty():
		cells = _canonical_cells.duplicate(true)
		shape_data["cells"] = cells.duplicate(true)
		rotation_steps = 0
	
	piece_state = PieceState.IN_TRAY
	drag_touch_index = -1
	rotate_button_pointer_id = POINTER_ID_NONE
	rotate_button_consumed = false
	free_tap_pointer_id = POINTER_ID_NONE
	last_rotation_source = ""
	_started_with_hardware_mouse = false
	_pointer_left_viewport_during_drag = false
	_ignore_next_rotate_mouse_release = false
	is_snapped_to_board_preview = false
	current_scale = PREVIEW_SCALE
	pivot_offset = Vector2.ZERO
	scale = Vector2(PREVIEW_SCALE, PREVIEW_SCALE)
	position = home_position
	z_index = 0
	mouse_filter = Control.MOUSE_FILTER_PASS
	visible = true
	modulate = Color(1.16, 1.16, 1.16, 1.0) if change_select_mode else Color(1, 1, 1, 1)
	_update_dimensions()
	_assert_restored_invariants()
	queue_redraw()


func _assert_restored_invariants() -> bool:
	assert(visible == true, "Restored TrayPiece must be visible!")
	assert(piece_state == PieceState.IN_TRAY, "Restored TrayPiece state must be IN_TRAY!")
	assert(slot_index >= 0 and slot_index < 3, "Restored TrayPiece must have valid tray slot_index (0..2)!")
	assert(is_instance_valid(self) and not is_queued_for_deletion(), "Restored TrayPiece must still exist!")
	assert(cells.size() == 4, "Restored TrayPiece must preserve its 4-cell tetromino shape!")
	return (
		visible == true
		and piece_state == PieceState.IN_TRAY
		and slot_index >= 0 and slot_index < 3
		and is_instance_valid(self) and not is_queued_for_deletion()
		and cells.size() == 4
	)


func verify_in_tray_invariants() -> bool:
	return _assert_restored_invariants()


func set_snapped_to_board_preview(snapped: bool) -> void:
	if is_snapped_to_board_preview != snapped:
		is_snapped_to_board_preview = snapped
		queue_redraw()


func is_rendering_floating_duplicate() -> bool:
	return piece_state == PieceState.DRAGGING and is_snapped_to_board_preview and false


func on_placement_confirmed() -> void:
	piece_state = PieceState.PLACED
	drag_touch_index = -1
	rotate_button_pointer_id = POINTER_ID_NONE
	rotate_button_consumed = false
	free_tap_pointer_id = POINTER_ID_NONE
	last_rotation_source = ""
	_started_with_hardware_mouse = false
	is_snapped_to_board_preview = false
	if tween and tween.is_valid():
		tween.kill()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	modulate.a = 0.0
	queue_free()


func _draw() -> void:
	if cells.is_empty() or (piece_state == PieceState.DRAGGING and is_snapped_to_board_preview):
		return
	
	var gs = get_node_or_null("/root/GameState")
	var cur_lvl: int = gs.active_level if (gs and "active_level" in gs) else 1
	var mat_id: String = material_id if not material_id.is_empty() else String(shape_data.get("material_id", ""))
	if mat_id.is_empty():
		mat_id = PolyominoLib.get_material_id_for_block(color_id, cur_lvl)
	
	for c in cells:
		var cell_pos = Vector2(c.x * (cell_size + cell_gap), c.y * (cell_size + cell_gap))
		var rect = Rect2(cell_pos, Vector2(cell_size, cell_size))
		PolyominoLib.draw_material_block_cell(self, rect, color_id, mat_id, cur_lvl)
