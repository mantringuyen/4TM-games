extends Node2D

## GameModeBase — Base class for all Block Puzzle — 4TM gameplay variants.
## Separates GameMode rules (Classic vs Modern) from PlayStyle mechanism (Falling vs Drag & Drop).

const GameStateScript = preload("res://scripts/autoload/game_state.gd")

@export var mode_type: int = 1 # GameStateScript.GameMode.MODERN_DRAG_AND_DROP
var rule_mode: int = GameStateScript.GameMode.MODERN_DRAG_AND_DROP
var play_style: int = GameStateScript.PlayStyle.DRAG_AND_DROP
var is_active: bool = false


func _ready() -> void:
	_setup_input_listeners()


## Configures both dimensions (GameMode rules + PlayStyle input mechanism)
func configure_combination(p_rule_mode: int, p_play_style: int) -> void:
	mode_type = p_rule_mode
	rule_mode = p_rule_mode
	play_style = p_play_style


## Returns true if vertical column clearing is allowed:
## - All Drag & Drop play styles (Classic + Drag & Drop, Modern + Drag & Drop) support row AND column clear.
## - Modern + Falling supports row AND column clear.
## - Classic + Falling is row-clear only.
func allows_column_clear() -> bool:
	if play_style == GameStateScript.PlayStyle.DRAG_AND_DROP:
		return true
	return rule_mode == GameStateScript.GameMode.MODERN_DRAG_AND_DROP


## Returns true if special items / boosters are enabled (Modern = true, Classic = false)
func has_special_items() -> bool:
	return rule_mode == GameStateScript.GameMode.MODERN_DRAG_AND_DROP


## Returns true if blocks above cleared rows fall downward via gravity (Falling = true, Drag & Drop = false)
func uses_gravity() -> bool:
	return play_style == GameStateScript.PlayStyle.FALLING


func initialize_mode() -> void:
	_on_mode_initialized()


func start_mode() -> void:
	is_active = true
	_on_mode_started()


func pause_mode(is_paused: bool) -> void:
	_on_mode_paused(is_paused)


func end_mode() -> void:
	is_active = false
	_on_mode_ended()


func reset_mode() -> void:
	_on_mode_reset()


func _setup_input_listeners() -> void:
	var input_mgr = get_node_or_null("/root/InputManager")
	if input_mgr:
		input_mgr.pointer_pressed.connect(_on_pointer_press)
		input_mgr.pointer_released.connect(_on_pointer_release)
		input_mgr.drag_updated.connect(_on_drag_update)
		input_mgr.swipe_detected.connect(_on_swipe)


# Virtual hooks for subclasses
func _on_mode_initialized() -> void:
	pass


func _on_mode_started() -> void:
	pass


func _on_mode_paused(_is_paused: bool) -> void:
	pass


func _on_mode_ended() -> void:
	pass


func _on_mode_reset() -> void:
	pass


func _on_pointer_press(_pos: Vector2, _is_touch: bool) -> void:
	pass


func _on_pointer_release(_pos: Vector2, _is_touch: bool) -> void:
	pass


func _on_drag_update(_pos: Vector2, _offset: Vector2) -> void:
	pass


func _on_swipe(_direction: Vector2) -> void:
	pass
