class_name InputManagerDef
extends Node

## InputManager — Unified pointer and gesture controller for Block Puzzle — 4TM
## Provides mouse, touch, drag and swipe abstraction across Web, Mobile (Android/iOS) and Desktop.

signal pointer_pressed(position: Vector2, is_touch: bool)
signal pointer_released(position: Vector2, is_touch: bool)
signal pointer_moved(position: Vector2, delta: Vector2)
signal drag_started(start_position: Vector2)
signal drag_updated(current_position: Vector2, total_offset: Vector2)
signal drag_ended(end_position: Vector2)
signal swipe_detected(direction: Vector2)

const DRAG_THRESHOLD: float = 8.0
const SWIPE_THRESHOLD: float = 40.0

var is_pointer_down: bool = false
var is_dragging: bool = false
var pointer_down_position: Vector2 = Vector2.ZERO
var pointer_current_position: Vector2 = Vector2.ZERO
var pointer_down_time: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				_on_pointer_press(mouse_event.position, false)
			else:
				_on_pointer_release(mouse_event.position, false)
				
	elif event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		_on_pointer_move(motion_event.position, motion_event.relative)
		
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_on_pointer_press(touch_event.position, true)
		else:
			_on_pointer_release(touch_event.position, true)
			
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		_on_pointer_move(drag_event.position, drag_event.relative)


func _on_pointer_press(pos: Vector2, is_touch: bool) -> void:
	is_pointer_down = true
	is_dragging = false
	pointer_down_position = pos
	pointer_current_position = pos
	pointer_down_time = Time.get_ticks_msec() / 1000.0
	
	pointer_pressed.emit(pos, is_touch)


func _on_pointer_move(pos: Vector2, delta: Vector2) -> void:
	pointer_current_position = pos
	pointer_moved.emit(pos, delta)
	
	if is_pointer_down:
		var offset := pos - pointer_down_position
		if not is_dragging and offset.length() > DRAG_THRESHOLD:
			is_dragging = true
			drag_started.emit(pointer_down_position)
		
		if is_dragging:
			drag_updated.emit(pos, offset)


func _on_pointer_release(pos: Vector2, is_touch: bool) -> void:
	if not is_pointer_down:
		return
	
	var offset := pos - pointer_down_position
	var elapsed_time := (Time.get_ticks_msec() / 1000.0) - pointer_down_time
	
	if is_dragging:
		drag_ended.emit(pos)
		is_dragging = false
	elif offset.length() > SWIPE_THRESHOLD and elapsed_time < 0.4:
		# Rapid swipe gesture
		var direction := offset.normalized()
		swipe_detected.emit(direction)
	
	is_pointer_down = false
	pointer_released.emit(pos, is_touch)
