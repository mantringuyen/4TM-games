class_name ModePieceArea
extends Control

## ModePieceArea — Falling PlayStyle NEXT piece preview display manager.
## Shows ONLY the NEXT piece preview (never Current preview since the falling piece is visible on the board).

const GameStateScript = preload("res://scripts/autoload/game_state.gd")
const PolyominoLib = preload("res://scripts/core/polyomino_library.gd")

@onready var classic_area: Control = get_node_or_null("ClassicPieceArea")
@onready var lbl_title: Label = get_node_or_null("ClassicPieceArea/Center/NextBox/LblTitle")

var current_mode: int = GameStateScript.GameMode.MODERN_DRAG_AND_DROP


class PiecePreviewDrawer extends Control:
	var shape_cells: Array = []
	var shape_color: Color = Color.CYAN
	var shape_color_id: int = 1
	var shape_material_id: String = ""
	var shape_name: String = ""

	func setup_shape(data: Dictionary) -> void:
		shape_cells = data.get("cells", [])
		shape_color = data.get("color", Color.CYAN)
		shape_color_id = int(data.get("color_id", 1))
		shape_material_id = String(data.get("material_id", ""))
		shape_name = data.get("name", "")
		queue_redraw()

	func _draw() -> void:
		if shape_cells.is_empty():
			return

		var panel_sz = size if (size.x > 10.0 and size.y > 10.0) else Vector2(186.0, 70.0)
		var dims = PolyominoLib.get_dimensions(shape_cells)
		
		var gap = 3.0
		var max_cell_w = (panel_sz.x - 18.0 - float(max(0, dims.x - 1)) * gap) / float(max(1, dims.x))
		var max_cell_h = (panel_sz.y - 10.0 - float(max(0, dims.y - 1)) * gap) / float(max(1, dims.y))
		var cell_sz = clamp(min(max_cell_w, max_cell_h), 12.0, 24.0)
			
		var shape_sz = Vector2(dims.x * cell_sz + (dims.x - 1) * gap, dims.y * cell_sz + (dims.y - 1) * gap)
		var origin = (panel_sz - shape_sz) * 0.5
		var gs = get_node_or_null("/root/GameState")
		var cur_lvl: int = gs.active_level if (gs and "active_level" in gs) else 1

		for c in shape_cells:
			var cell_pos = origin + Vector2(c.x * (cell_sz + gap), c.y * (cell_sz + gap))
			var rect = Rect2(cell_pos, Vector2(cell_sz, cell_sz))
			PolyominoLib.draw_material_block_cell(self, rect, shape_color_id, shape_material_id, cur_lvl)


func _ready() -> void:
	_ensure_nodes()
	var state_mgr = get_node_or_null("/root/GameState")
	if state_mgr:
		state_mgr.game_started.connect(_on_game_started)
		if state_mgr.has_signal("language_changed"):
			state_mgr.language_changed.connect(_on_language_changed)
		if state_mgr.current_play_style == GameStateScript.PlayStyle.FALLING:
			if classic_area:
				classic_area.visible = true
		else:
			set_game_mode(state_mgr.current_mode)
	_refresh_language()


func _ensure_nodes() -> void:
	if not classic_area:
		classic_area = get_node_or_null("ClassicPieceArea")
	if not lbl_title:
		lbl_title = get_node_or_null("ClassicPieceArea/Center/NextBox/LblTitle")
	var panel_next := get_node_or_null("ClassicPieceArea/Center/NextBox/PreviewPanel") as Control
	if panel_next:
		panel_next.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		panel_next.self_modulate = Color(1, 1, 1, 0)


func has_visible_frame_or_panel() -> bool:
	_ensure_nodes()
	var panel_next := get_node_or_null("ClassicPieceArea/Center/NextBox/PreviewPanel") as Control
	if not panel_next:
		return false
	var st: StyleBox = panel_next.get_theme_stylebox("panel")
	if st is StyleBoxEmpty:
		return false
	if st is StyleBoxFlat:
		var sf := st as StyleBoxFlat
		if sf.bg_color.a > 0.01 or sf.border_width_left > 0 or sf.border_width_top > 0 or sf.border_width_right > 0 or sf.border_width_bottom > 0 or sf.shadow_size > 0:
			return true
	return false


func has_visible_next_piece_frame() -> bool:
	return has_visible_frame_or_panel()


func is_next_piece_preview_readable() -> bool:
	_ensure_nodes()
	var panel_next := get_node_or_null("ClassicPieceArea/Center/NextBox/PreviewPanel") as Control
	if not classic_area or not classic_area.visible or not panel_next or not panel_next.visible:
		return false
	if not lbl_title or not lbl_title.visible or lbl_title.text.strip_edges().is_empty():
		return false
	var drawer := panel_next.get_node_or_null("PiecePreviewDrawer") as PiecePreviewDrawer
	return drawer != null and drawer.visible and drawer.shape_cells.size() == 4 and panel_next.size.x >= 80.0 and panel_next.size.y >= 32.0


func _on_language_changed(_lang: String) -> void:
	_refresh_language()


func _refresh_language() -> void:
	_ensure_nodes()
	var state_mgr = get_node_or_null("/root/GameState")
	if lbl_title and state_mgr and state_mgr.has_method("tr_text"):
		lbl_title.text = state_mgr.tr_text("next_piece")


func _on_game_started(mode: int) -> void:
	_refresh_language()
	var state_mgr = get_node_or_null("/root/GameState")
	if state_mgr and state_mgr.current_play_style == GameStateScript.PlayStyle.FALLING:
		_ensure_nodes()
		current_mode = mode
		if classic_area:
			classic_area.visible = true
	else:
		set_game_mode(mode)


func set_game_mode(mode: int) -> void:
	_ensure_nodes()
	current_mode = mode
	var state_mgr = get_node_or_null("/root/GameState")
	var is_falling = (mode == GameStateScript.GameMode.CLASSIC)
	if state_mgr and "current_play_style" in state_mgr and state_mgr._play_style_explicit:
		is_falling = (state_mgr.current_play_style == GameStateScript.PlayStyle.FALLING)
	if classic_area:
		classic_area.visible = is_falling


func set_falling_active(active: bool) -> void:
	_ensure_nodes()
	if classic_area:
		classic_area.visible = active


func has_current_preview_ui() -> bool:
	return get_node_or_null("ClassicPieceArea/Center/NextBox/CurrentPreviewPanel") != null or get_node_or_null("ClassicPieceArea/Center/NextBox/LblCurrent") != null


func has_next_preview_ui() -> bool:
	return get_node_or_null("ClassicPieceArea/Center/NextBox/PreviewPanel") != null


func update_responsive_size(area_size: Vector2) -> void:
	_ensure_nodes()
	var w: float = maxf(180.0, area_size.x)
	var h: float = maxf(44.0, area_size.y)
	custom_minimum_size = Vector2(w, h)
	size = Vector2(w, h)
	if classic_area:
		classic_area.custom_minimum_size = Vector2(w, h)
		classic_area.size = Vector2(w, h)
	var center_box := get_node_or_null("ClassicPieceArea/Center") as Control
	if center_box:
		center_box.custom_minimum_size = Vector2(w, h)
		center_box.size = Vector2(w, h)
	var next_box := get_node_or_null("ClassicPieceArea/Center/NextBox") as HBoxContainer
	if next_box:
		next_box.add_theme_constant_override("separation", 10 if w < 360.0 else 16)
	if lbl_title:
		lbl_title.add_theme_font_size_override("font_size", 14 if (w < 360.0 or h < 54.0) else 17)
	var panel_next := get_node_or_null("ClassicPieceArea/Center/NextBox/PreviewPanel") as Control
	if panel_next:
		var panel_w: float = clampf(w * 0.40, 118.0, 192.0)
		var panel_h: float = maxf(38.0, h - 6.0)
		panel_next.custom_minimum_size = Vector2(panel_w, panel_h)
		panel_next.size = Vector2(panel_w, panel_h)
		var drawer := panel_next.get_node_or_null("PiecePreviewDrawer") as PiecePreviewDrawer
		if drawer:
			drawer.custom_minimum_size = panel_next.size
			drawer.size = panel_next.size
			drawer.queue_redraw()



func set_classic_previews(_current_shape_data: Dictionary, next_shape_data: Dictionary) -> void:
	set_classic_next_preview(next_shape_data)


func set_classic_next_preview(next_shape_data: Dictionary) -> void:
	_ensure_nodes()
	if not next_shape_data.is_empty():
		var panel_next = get_node_or_null("ClassicPieceArea/Center/NextBox/PreviewPanel")
		if not panel_next:
			panel_next = get_node_or_null("ClassicPieceArea/HBox/NextBox/PreviewPanel")
		if panel_next:
			_update_preview_panel(panel_next, next_shape_data)


func _update_preview_panel(panel: Control, shape_data: Dictionary) -> void:
	var drawer = panel.get_node_or_null("PiecePreviewDrawer") as PiecePreviewDrawer
	if not drawer:
		drawer = PiecePreviewDrawer.new()
		drawer.name = "PiecePreviewDrawer"
		var init_sz: Vector2 = panel.size if (panel.size.x > 0 and panel.size.y > 0) else (panel.custom_minimum_size if (panel.custom_minimum_size.x > 0 and panel.custom_minimum_size.y > 0) else Vector2(156, 52))
		drawer.custom_minimum_size = init_sz
		drawer.size = init_sz
		panel.add_child(drawer)
	
	drawer.setup_shape(shape_data)
