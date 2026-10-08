class_name UIIcon
extends Control

const GameTypographyScript = preload("res://scripts/ui/game_typography.gd")

## UIIcon — Procedural Vector Icon & Badge Renderer for Block Puzzle — 4TM
## Eliminates dependency on missing system emoji/symbol fonts (which otherwise render
## hexadecimal Unicode code-point boxes such as "2699" for U+2699 ⚙ in Godot's fallback font).
## Renders crisp vector icons directly via CanvasItem drawing primitives.

var icon_type: String = "gear"
var primary_color: Color = Color(1.0, 0.94, 0.42, 1.0)
var secondary_color: Color = Color(0.18, 0.28, 0.62, 1.0)
var star_count: int = 0
var is_unlocked: bool = true
var is_completed: bool = false
var is_selected: bool = false
var is_current: bool = false
var milestone_type: String = ""
var destination_architecture: String = "carved_platform"
var terrain_surface_type: String = "emerald_turf_terrace"
var elevation_z: float = 0.25
var align_mode: String = "left"


func _init(p_type: String = "gear", p_color: Color = Color(1.0, 0.94, 0.42, 1.0)) -> void:
	icon_type = p_type
	primary_color = p_color
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(28, 28)
	size = Vector2(28, 28)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var parent_ctrl: Control = get_parent() as Control
	if parent_ctrl and not parent_ctrl.resized.is_connected(_on_parent_resized):
		parent_ctrl.resized.connect(_on_parent_resized)
	_on_parent_resized()


func _on_parent_resized() -> void:
	var parent_ctrl: Control = get_parent() as Control
	if not parent_ctrl:
		return
	if align_mode == "center":
		position = (parent_ctrl.size - size) * 0.5
	elif align_mode == "left":
		var left_margin: float = 7.0 if parent_ctrl.size.x < 150.0 else 12.0
		position = Vector2(left_margin, (parent_ctrl.size.y - size.y) * 0.5)
	elif align_mode == "right":
		var right_margin: float = 7.0 if parent_ctrl.size.x < 150.0 else 12.0
		position = Vector2(parent_ctrl.size.x - size.x - right_margin, (parent_ctrl.size.y - size.y) * 0.5)
	elif align_mode == "full":
		position = Vector2.ZERO
		size = parent_ctrl.size
	queue_redraw()


const OFFICIAL_4TM_LOGO_PATH: String = "res://assets/branding/4tm_logo.svg"
static var _cached_4tm_logo_tex: Texture2D = null
static var _empty_focus_style: StyleBoxEmpty = null


static func get_empty_focus_stylebox() -> StyleBoxEmpty:
	if not _empty_focus_style:
		_empty_focus_style = StyleBoxEmpty.new()
		if ThemeDB.get_default_theme():
			ThemeDB.get_default_theme().set_stylebox("focus", "Button", _empty_focus_style)
		if ThemeDB.get_project_theme():
			ThemeDB.get_project_theme().set_stylebox("focus", "Button", _empty_focus_style)
	return _empty_focus_style


static func cleanup_static_resources() -> void:
	_cached_4tm_logo_tex = null
	_empty_focus_style = null


static func apply_frameless_icon_button_style(btn: Button) -> void:
	if not btn:
		return
	var empty_sb := StyleBoxEmpty.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.set_meta("is_frameless_icon_button", true)
	btn.set_meta("is_frameless_gear_icon", true)
	btn.add_theme_stylebox_override("normal", empty_sb)
	btn.add_theme_stylebox_override("hover", empty_sb)
	btn.add_theme_stylebox_override("pressed", empty_sb)
	btn.add_theme_stylebox_override("hover_pressed", empty_sb)
	btn.add_theme_stylebox_override("disabled", empty_sb)
	btn.add_theme_stylebox_override("focus", get_empty_focus_stylebox())


static func is_button_frameless(btn: Button) -> bool:
	if not btn:
		return false
	for state_name in ["normal", "hover", "pressed"]:
		var sb: StyleBox = btn.get_theme_stylebox(state_name)
		if sb is StyleBoxEmpty:
			continue
		if sb is StyleBoxFlat:
			var sbf := sb as StyleBoxFlat
			if sbf.bg_color.a > 0.01 or sbf.border_width_left > 0 or sbf.border_width_top > 0 or sbf.border_width_right > 0 or sbf.border_width_bottom > 0 or sbf.shadow_size > 0:
				return false
	return true


static func apply_audio_toggle_button_identity_style(btn: Button) -> void:
	if not btn:
		return
	btn.disabled = false
	btn.toggle_mode = false
	btn.focus_mode = Control.FOCUS_NONE
	btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
	btn.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	var base_st := StyleBoxFlat.new()
	base_st.bg_color = Color(0.88, 0.62, 0.08, 0.98)
	base_st.border_width_left = 2
	base_st.border_width_top = 2
	base_st.border_width_right = 2
	base_st.border_width_bottom = 6
	base_st.border_color = Color(1.0, 0.92, 0.48, 1.0)
	base_st.corner_radius_top_left = 20
	base_st.corner_radius_top_right = 20
	base_st.corner_radius_bottom_right = 20
	base_st.corner_radius_bottom_left = 20
	base_st.shadow_color = Color(0.02, 0.06, 0.22, 0.50)
	base_st.shadow_size = 8
	base_st.shadow_offset = Vector2(0, 3)
	
	btn.add_theme_stylebox_override("normal", base_st)
	btn.add_theme_stylebox_override("hover", base_st)
	btn.add_theme_stylebox_override("pressed", base_st)
	btn.add_theme_stylebox_override("hover_pressed", base_st)
	btn.add_theme_stylebox_override("disabled", base_st)
	remove_focus_outline(btn)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_disabled_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_font_override("font", GameTypographyScript.get_display_font(0.18, 1))


static func apply_voice_button_identity_style(btn: Button) -> void:
	if not btn:
		return
	btn.disabled = false
	btn.toggle_mode = false
	btn.focus_mode = Control.FOCUS_NONE
	btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
	btn.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	var base_st := StyleBoxFlat.new()
	base_st.bg_color = Color(0.08, 0.58, 0.68, 0.98)
	base_st.border_width_left = 2
	base_st.border_width_top = 2
	base_st.border_width_right = 2
	base_st.border_width_bottom = 6
	base_st.border_color = Color(0.58, 0.95, 1.0, 1.0)
	base_st.corner_radius_top_left = 20
	base_st.corner_radius_top_right = 20
	base_st.corner_radius_bottom_right = 20
	base_st.corner_radius_bottom_left = 20
	base_st.shadow_color = Color(0.02, 0.14, 0.22, 0.50)
	base_st.shadow_size = 8
	base_st.shadow_offset = Vector2(0, 3)
	
	btn.add_theme_stylebox_override("normal", base_st)
	btn.add_theme_stylebox_override("hover", base_st)
	btn.add_theme_stylebox_override("pressed", base_st)
	btn.add_theme_stylebox_override("hover_pressed", base_st)
	btn.add_theme_stylebox_override("disabled", base_st)
	remove_focus_outline(btn)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_disabled_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_font_override("font", GameTypographyScript.get_display_font(0.18, 1))


static func apply_game_button_style(
	btn: Button,
	bg_col: Color,
	highlight_col: Color,
	extrusion_depth: int = 8,
	corner_r: int = 24,
	shadow_sz: int = 12,
	shadow_off: Vector2 = Vector2(0, 5)
) -> void:
	if not btn:
		return
	var st := StyleBoxFlat.new()
	st.bg_color = bg_col
	st.border_width_left = 3
	st.border_width_top = 4
	st.border_width_right = 3
	st.border_width_bottom = extrusion_depth
	st.border_color = highlight_col
	st.set_corner_radius_all(corner_r)
	st.shadow_color = Color(0.02, 0.04, 0.16, 0.60)
	st.shadow_size = shadow_sz
	st.shadow_offset = shadow_off
	st.content_margin_left = 14.0
	st.content_margin_right = 14.0
	st.content_margin_top = 6.0
	st.content_margin_bottom = 6.0 + float(extrusion_depth) * 0.35

	var st_hov := st.duplicate() as StyleBoxFlat
	st_hov.bg_color = bg_col.lightened(0.10)
	st_hov.border_color = highlight_col.lightened(0.12)
	st_hov.shadow_size = shadow_sz + 2
	st_hov.shadow_offset = shadow_off + Vector2(0, 1)

	var st_press := st.duplicate() as StyleBoxFlat
	st_press.bg_color = bg_col.darkened(0.08)
	st_press.border_width_bottom = maxi(2, extrusion_depth / 3)
	st_press.shadow_size = maxi(2, shadow_sz / 2)
	st_press.shadow_offset = Vector2(0, 2)
	st_press.content_margin_top = 6.0 + float(extrusion_depth) * 0.45
	st_press.content_margin_bottom = 6.0

	var st_dis := st.duplicate() as StyleBoxFlat
	st_dis.bg_color = Color(0.24, 0.30, 0.44, 0.85)
	st_dis.border_color = Color(0.40, 0.46, 0.58, 0.80)
	st_dis.shadow_color = Color(0.01, 0.02, 0.08, 0.30)
	st_dis.shadow_size = 4
	st_dis.shadow_offset = Vector2(0, 2)

	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_stylebox_override("hover", st_hov)
	btn.add_theme_stylebox_override("pressed", st_press)
	btn.add_theme_stylebox_override("disabled", st_dis)
	btn.add_theme_stylebox_override("focus", get_empty_focus_stylebox())
	btn.add_theme_font_override("font", GameTypographyScript.get_display_font(0.20, 1))
	remove_focus_outline(btn)


static func apply_primary_game_button_style(btn: Button, corner_r: int = 34) -> void:
	apply_game_button_style(
		btn,
		Color(0.12, 0.84, 0.44, 1.0),
		Color(0.74, 1.0, 0.58, 1.0),
		12,
		corner_r,
		18,
		Vector2(0, 8)
	)


static func apply_secondary_game_button_style(btn: Button, is_selected: bool = false, corner_r: int = 22) -> void:
	if is_selected:
		apply_game_button_style(
			btn,
			Color(0.12, 0.58, 0.98, 1.0),
			Color(0.70, 0.96, 1.0, 1.0),
			8,
			corner_r,
			12,
			Vector2(0, 5)
		)
	else:
		apply_game_button_style(
			btn,
			Color(0.24, 0.46, 0.88, 1.0),
			Color(0.68, 0.88, 1.0, 1.0),
			7,
			corner_r,
			10,
			Vector2(0, 4)
		)


static func apply_reward_game_button_style(btn: Button, corner_r: int = 22) -> void:
	apply_game_button_style(
		btn,
		Color(0.96, 0.28, 0.56, 1.0),
		Color(1.0, 0.90, 0.40, 1.0),
		8,
		corner_r,
		12,
		Vector2(0, 5)
	)


static func apply_danger_game_button_style(btn: Button, corner_r: int = 20) -> void:
	apply_game_button_style(
		btn,
		Color(0.86, 0.20, 0.26, 1.0),
		Color(1.0, 0.62, 0.66, 1.0),
		7,
		corner_r,
		10,
		Vector2(0, 4)
	)


static func remove_focus_outline(ctrl: Control) -> void:
	if not ctrl:
		return
	var empty_sb := get_empty_focus_stylebox()
	ctrl.focus_mode = Control.FOCUS_NONE
	ctrl.add_theme_stylebox_override("focus", empty_sb)


static func remove_all_focus_outlines(root: Node) -> void:
	if not root:
		return
	get_empty_focus_stylebox()
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		for ch in cur.get_children():
			stack.append(ch)
		if cur is BaseButton or (cur is Control and (cur as Control).focus_mode != Control.FOCUS_NONE):
			remove_focus_outline(cur as Control)


static func has_focus_outline(ctrl: Control) -> bool:
	if not ctrl:
		return false
	if ctrl.focus_mode != Control.FOCUS_NONE:
		return true
	var focus_sb: StyleBox = ctrl.get_theme_stylebox("focus")
	if focus_sb is StyleBoxEmpty:
		return false
	return focus_sb != null


static func verify_no_focus_outlines_in_tree(root: Node) -> bool:
	if not root:
		return true
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		for ch in cur.get_children():
			stack.append(ch)
		if cur is BaseButton:
			if has_focus_outline(cur as Control):
				return false
	return true


static func load_official_4tm_logo_texture() -> Texture2D:
	if _cached_4tm_logo_tex != null:
		return _cached_4tm_logo_tex
	if FileAccess.file_exists(OFFICIAL_4TM_LOGO_PATH):
		var svg_str := FileAccess.get_file_as_string(OFFICIAL_4TM_LOGO_PATH)
		if not svg_str.is_empty():
			var img := Image.new()
			if img.load_svg_from_string(svg_str, 4.0) == OK and img.get_width() > 0:
				_cached_4tm_logo_tex = ImageTexture.create_from_image(img)
				return _cached_4tm_logo_tex
	if ResourceLoader.exists(OFFICIAL_4TM_LOGO_PATH):
		var loaded := ResourceLoader.load(OFFICIAL_4TM_LOGO_PATH) as Texture2D
		if loaded:
			_cached_4tm_logo_tex = loaded
			return _cached_4tm_logo_tex
	return null


static func setup_button_press_feedback(btn: Button, is_persistent_toggle: bool = false) -> void:
	if not btn or btn.has_meta("_press_feedback_initialized"):
		return
	btn.set_meta("_press_feedback_initialized", true)
	btn.set_meta("is_persistent_toggle", is_persistent_toggle)
	remove_focus_outline(btn)
	
	var is_audio_bright_btn: bool = btn.name in ["BtnMusic", "BtnSound", "BtnVoice", "BtnHaptics"]
	if is_audio_bright_btn:
		if btn.name in ["BtnMusic", "BtnSound"]:
			apply_audio_toggle_button_identity_style(btn)
		else:
			apply_voice_button_identity_style(btn)
	elif not is_persistent_toggle:
		var norm_sb: StyleBox = btn.get_theme_stylebox("normal")
		if norm_sb and not (norm_sb is StyleBoxEmpty):
			var dup_sb := norm_sb.duplicate()
			if not btn.has_theme_stylebox_override("hover"):
				btn.add_theme_stylebox_override("hover", dup_sb)
			if not btn.has_theme_stylebox_override("pressed"):
				btn.add_theme_stylebox_override("pressed", dup_sb)
			if not btn.has_theme_stylebox_override("disabled"):
				btn.add_theme_stylebox_override("disabled", dup_sb)
	remove_focus_outline(btn)
	
	btn.button_down.connect(func():
		if btn and btn.is_inside_tree():
			btn.pivot_offset = btn.size * 0.5
			var tw_down := btn.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw_down.tween_property(btn, "scale", Vector2(0.94, 0.94), 0.06)
	)
	var on_release := func():
		if btn and btn.is_inside_tree():
			btn.pivot_offset = btn.size * 0.5
			var tw_up := btn.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw_up.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12)
			btn.release_focus()
			if is_audio_bright_btn:
				if btn.name in ["BtnMusic", "BtnSound"]:
					apply_audio_toggle_button_identity_style(btn)
				else:
					apply_voice_button_identity_style(btn)
			elif not is_persistent_toggle:
				btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
				btn.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	btn.button_up.connect(on_release)
	btn.pressed.connect(on_release)
	btn.mouse_exited.connect(on_release)
	btn.focus_exited.connect(on_release)


static func setup_all_buttons_feedback(root: Node) -> void:
	if not root:
		return
	remove_all_focus_outlines(root)
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		for ch in cur.get_children():
			stack.append(ch)
		if cur is Button:
			var btn := cur as Button
			var is_toggle: bool = (
				btn.toggle_mode
				or btn.name in ["BtnClassic", "BtnModern", "BtnFalling", "BtnDragDrop", "BtnBomb"]
				or btn.get_meta("is_persistent_toggle", false)
			)
			setup_button_press_feedback(btn, is_toggle)


static func attach_to_button(btn: Button, p_type: String, icon_sz: Vector2 = Vector2(28, 28), p_align: String = "left", p_col: Color = Color(1.0, 0.94, 0.42, 1.0)) -> Control:
	if not btn:
		return null
	remove_focus_outline(btn)
	var is_toggle: bool = (
		btn.toggle_mode
		or btn.name in ["BtnClassic", "BtnModern", "BtnFalling", "BtnDragDrop", "BtnBomb"]
		or btn.get_meta("is_persistent_toggle", false)
	)
	setup_button_press_feedback(btn, is_toggle)
	var existing: Control = btn.get_node_or_null("VectorIcon") as Control
	if not existing:
		var script_res := (load("res://scripts/ui/ui_icon.gd") as GDScript)
		if script_res:
			existing = script_res.new(p_type, p_col)
			existing.name = "VectorIcon"
			btn.add_child(existing)
	existing.icon_type = p_type
	existing.primary_color = p_col
	if p_type == "gear":
		existing.set_meta("is_frameless_gear_icon", true)
		existing.set_meta("is_dark_contrast_gear", p_col.get_luminance() < 0.42)
	existing.align_mode = p_align
	existing.custom_minimum_size = icon_sz
	existing.size = icon_sz
	existing._on_parent_resized()
	existing.queue_redraw()
	return existing


static func setup_4tm_games_branding(brand_bar: HBoxContainer) -> Dictionary:
	if not brand_bar:
		return {}
	brand_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	brand_bar.add_theme_constant_override("separation", 8)
	var existing_logo := brand_bar.get_node_or_null("Logo4TM")
	var logo_tex_rect: TextureRect = null
	if existing_logo and not (existing_logo is TextureRect):
		brand_bar.remove_child(existing_logo)
		existing_logo.queue_free()
	else:
		logo_tex_rect = existing_logo as TextureRect
	if not logo_tex_rect:
		logo_tex_rect = TextureRect.new()
		logo_tex_rect.name = "Logo4TM"
		brand_bar.add_child(logo_tex_rect)
		brand_bar.move_child(logo_tex_rect, 0)
	for ch in logo_tex_rect.get_children():
		logo_tex_rect.remove_child(ch)
		ch.queue_free()
	logo_tex_rect.custom_minimum_size = Vector2(22, 22)
	logo_tex_rect.size = Vector2(22, 22)
	logo_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_tex_rect.texture = load_official_4tm_logo_texture()
	logo_tex_rect.set_meta("asset_path", OFFICIAL_4TM_LOGO_PATH)
	logo_tex_rect.set_meta("uses_official_asset", true)

	var lbl_games := brand_bar.get_node_or_null("LblBrandGames") as Label
	if not lbl_games:
		lbl_games = Label.new()
		lbl_games.name = "LblBrandGames"
		brand_bar.add_child(lbl_games)
	lbl_games.text = "GAMES"
	lbl_games.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_games.add_theme_font_size_override("font_size", 14)
	lbl_games.add_theme_color_override("font_color", Color(1.0, 0.92, 0.36, 0.98))
	var lbl_sep := brand_bar.get_node_or_null("LblBrandSep") as Label
	if not lbl_sep:
		lbl_sep = Label.new()
		lbl_sep.name = "LblBrandSep"
		brand_bar.add_child(lbl_sep)
	lbl_sep.text = "•"
	lbl_sep.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_sep.add_theme_font_size_override("font_size", 14)
	lbl_sep.add_theme_color_override("font_color", Color(0.72, 0.86, 1.0, 0.78))
	var lbl_domain := brand_bar.get_node_or_null("LblVersion") as Label
	if not lbl_domain:
		lbl_domain = brand_bar.get_node_or_null("LblBrandDomain") as Label
	if not lbl_domain:
		lbl_domain = Label.new()
		lbl_domain.name = "LblVersion"
		brand_bar.add_child(lbl_domain)
	lbl_domain.text = "games.4tm.io.vn"
	lbl_domain.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_domain.add_theme_font_size_override("font_size", 14)
	lbl_domain.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0, 0.95))
	return {
		"logo": logo_tex_rect,
		"games_label": lbl_games,
		"domain_label": lbl_domain
	}


static func attach_level_node_overlay(
	btn: Button,
	p_unlocked: bool,
	p_completed: bool,
	p_selected: bool,
	p_current: bool,
	p_stars: int,
	p_milestone: String,
	p_dest_arch: String = "carved_platform",
	p_terrain_surface: String = "emerald_turf_terrace",
	p_elevation_z: float = 0.25
) -> Control:
	if not btn:
		return null
	remove_focus_outline(btn)
	setup_button_press_feedback(btn, false)
	var existing: Control = btn.get_node_or_null("VectorIcon") as Control
	if not existing:
		var script_res := (load("res://scripts/ui/ui_icon.gd") as GDScript)
		if script_res:
			existing = script_res.new("level_node_overlay")
			existing.name = "VectorIcon"
			btn.add_child(existing)
	existing.icon_type = "level_node_overlay"
	existing.align_mode = "full"
	existing.is_unlocked = p_unlocked
	existing.is_completed = p_completed
	existing.is_selected = p_selected
	existing.is_current = p_current
	existing.star_count = clampi(p_stars, 0, 3)
	existing.milestone_type = p_milestone
	existing.destination_architecture = p_dest_arch
	existing.terrain_surface_type = p_terrain_surface
	existing.elevation_z = p_elevation_z
	existing.show_behind_parent = true
	existing._on_parent_resized()
	existing.queue_redraw()
	return existing


func set_stars(earned: int, _total: int = 3) -> void:
	star_count = clampi(earned, 0, 3)
	queue_redraw()


static func has_unsupported_font_chars(text: String) -> bool:
	if text.find("2699") != -1:
		return true
	var font: Font = ThemeDB.fallback_font
	if not font:
		return false
	for i in range(text.length()):
		var code: int = text.unicode_at(i)
		if code == 10 or code == 13 or code == 9 or code == 32:
			continue
		if not font.has_char(code):
			return true
	return false


static func draw_star_shape(canvas: CanvasItem, center: Vector2, outer_r: float, inner_r: float, fill_col: Color, border_col: Color = Color(0, 0, 0, 0), border_w: float = 1.5) -> void:
	var pts := PackedVector2Array()
	for i in range(10):
		var angle: float = -PI * 0.5 + float(i) * (PI / 5.0)
		var r: float = outer_r if (i % 2 == 0) else inner_r
		pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	canvas.draw_colored_polygon(pts, fill_col)
	if border_col.a > 0.01:
		var closed := pts.duplicate()
		closed.append(pts[0])
		canvas.draw_polyline(closed, border_col, border_w, true)


static func draw_gear_shape(canvas: CanvasItem, center: Vector2, radius: float, gear_col: Color, hole_col: Color) -> void:
	var rim_col: Color = gear_col.darkened(0.42)
	rim_col.a = gear_col.a
	var hi_col: Color = gear_col.lightened(0.26)
	hi_col.a = gear_col.a
	var knob_fill: Color = Color(0.94, 0.97, 1.0, gear_col.a) if gear_col.get_luminance() >= 0.45 else hole_col

	# Clean 3-row horizontal vector Settings sliders with sculpted pill tracks and tactile circular knobs
	var span_w: float = radius * 1.68
	var span_h: float = radius * 1.48
	var track_h: float = clampf(radius * 0.22, 3.6, 6.4)
	var knob_r: float = clampf(radius * 0.26, 4.6, 7.6)
	var row_offsets := [-span_h * 0.42, 0.0, span_h * 0.42]
	var knob_u := [0.68, 0.30, 0.62]

	for i in range(3):
		var y: float = center.y + float(row_offsets[i])
		var left_x: float = center.x - span_w * 0.5
		var right_x: float = center.x + span_w * 0.5
		var p_left := Vector2(left_x, y)
		var p_right := Vector2(right_x, y)

		# Subtle drop shadow for crisp separation on frameless header background
		canvas.draw_line(p_left + Vector2(0, 1.8), p_right + Vector2(0, 1.8), Color(0.02, 0.04, 0.14, 0.42), track_h + 2.6, true)
		canvas.draw_circle(p_left + Vector2(0, 1.8), (track_h + 2.6) * 0.5, Color(0.02, 0.04, 0.14, 0.42))
		canvas.draw_circle(p_right + Vector2(0, 1.8), (track_h + 2.6) * 0.5, Color(0.02, 0.04, 0.14, 0.42))

		# Outer dark rim
		canvas.draw_line(p_left, p_right, rim_col, track_h + 2.2, true)
		canvas.draw_circle(p_left, (track_h + 2.2) * 0.5, rim_col)
		canvas.draw_circle(p_right, (track_h + 2.2) * 0.5, rim_col)

		# Main metallic/light-gray slider bar
		canvas.draw_line(p_left, p_right, gear_col, track_h, true)
		canvas.draw_circle(p_left, track_h * 0.5, gear_col)
		canvas.draw_circle(p_right, track_h * 0.5, gear_col)

		# Active left portion highlight
		var kx: float = lerpf(left_x + knob_r * 0.6, right_x - knob_r * 0.6, float(knob_u[i]))
		var k_pos := Vector2(kx, y)
		canvas.draw_line(p_left, k_pos, hi_col, track_h * 0.72, true)

		# Slider knob shadow + rim + fill + center specularity
		canvas.draw_circle(k_pos + Vector2(0, 1.8), knob_r + 1.4, Color(0.02, 0.04, 0.14, 0.45))
		canvas.draw_circle(k_pos, knob_r + 1.4, rim_col)
		canvas.draw_circle(k_pos, knob_r, knob_fill)
		canvas.draw_circle(k_pos, knob_r * 0.42, rim_col)


static func draw_crown_shape(canvas: CanvasItem, center: Vector2, radius: float, col: Color) -> void:
	var w: float = radius * 1.75
	var h: float = radius * 1.30
	var left: float = center.x - w * 0.5
	var right: float = center.x + w * 0.5
	var bot: float = center.y + h * 0.48
	var top: float = center.y - h * 0.52
	var pts := PackedVector2Array([
		Vector2(left + w * 0.08, bot),
		Vector2(right - w * 0.08, bot),
		Vector2(right, top + h * 0.12),
		Vector2(center.x + w * 0.22, center.y + h * 0.05),
		Vector2(center.x, top - h * 0.06),
		Vector2(center.x - w * 0.22, center.y + h * 0.05),
		Vector2(left, top + h * 0.12)
	])
	canvas.draw_colored_polygon(pts, col)
	canvas.draw_circle(Vector2(left, top + h * 0.10), 2.6, Color(1.0, 0.98, 0.78, 1.0))
	canvas.draw_circle(Vector2(center.x, top - h * 0.08), 3.0, Color(0.32, 0.96, 1.0, 1.0))
	canvas.draw_circle(Vector2(right, top + h * 0.10), 2.6, Color(1.0, 0.98, 0.78, 1.0))


static func draw_gift_shape(canvas: CanvasItem, center: Vector2, radius: float) -> void:
	var sz: float = radius * 1.55
	var box_rect := Rect2(center - Vector2(sz * 0.5, sz * 0.38), Vector2(sz, sz * 0.82))
	var lid_rect := Rect2(center - Vector2(sz * 0.56, sz * 0.52), Vector2(sz * 1.12, sz * 0.24))
	canvas.draw_rect(box_rect, Color(0.96, 0.24, 0.48, 1.0), true)
	canvas.draw_rect(lid_rect, Color(1.0, 0.36, 0.60, 1.0), true)
	var rib_col := Color(1.0, 0.90, 0.28, 1.0)
	canvas.draw_rect(Rect2(center.x - sz * 0.12, lid_rect.position.y, sz * 0.24, box_rect.size.y + sz * 0.14), rib_col, true)
	canvas.draw_rect(Rect2(box_rect.position.x, center.y - sz * 0.04, box_rect.size.x, sz * 0.20), rib_col, true)
	canvas.draw_arc(center + Vector2(-sz * 0.20, -sz * 0.58), sz * 0.18, 0.0, TAU, 12, rib_col, 2.5, true)
	canvas.draw_arc(center + Vector2(sz * 0.20, -sz * 0.58), sz * 0.18, 0.0, TAU, 12, rib_col, 2.5, true)


static func draw_lock_shape(canvas: CanvasItem, center: Vector2, radius: float, unlocked_state: bool = false) -> void:
	var w: float = radius * 1.35
	var h: float = radius * 1.08
	var shackle_col := Color(0.82, 0.88, 0.98, 0.95)
	var body_col := Color(1.0, 0.80, 0.22, 0.98) if unlocked_state else Color(0.62, 0.70, 0.88, 0.95)
	var shackle_center := center + Vector2(w * 0.22 if unlocked_state else 0.0, -h * 0.34)
	canvas.draw_arc(shackle_center, w * 0.34, PI, TAU, 14, shackle_col, 2.8, true)
	var body_rect := Rect2(center - Vector2(w * 0.5, h * 0.28), Vector2(w, h * 0.88))
	canvas.draw_rect(body_rect, body_col, true)
	canvas.draw_circle(center + Vector2(0, h * 0.12), 2.4, Color(0.14, 0.18, 0.36, 0.95))


static func draw_trophy_shape(canvas: CanvasItem, center: Vector2, radius: float) -> void:
	var gold := Color(1.0, 0.84, 0.20, 1.0)
	var r: float = radius * 0.85
	canvas.draw_arc(center + Vector2(-r * 0.55, -r * 0.22), r * 0.36, PI * 0.5, PI * 1.5, 10, gold, 2.2, true)
	canvas.draw_arc(center + Vector2(r * 0.55, -r * 0.22), r * 0.36, -PI * 0.5, PI * 0.5, 10, gold, 2.2, true)
	var cup := PackedVector2Array([
		center + Vector2(-r * 0.65, -r * 0.68),
		center + Vector2(r * 0.65, -r * 0.68),
		center + Vector2(r * 0.42, r * 0.18),
		center + Vector2(-r * 0.42, r * 0.18)
	])
	canvas.draw_colored_polygon(cup, gold)
	canvas.draw_rect(Rect2(center + Vector2(-r * 0.16, r * 0.16), Vector2(r * 0.32, r * 0.42)), gold, true)
	canvas.draw_rect(Rect2(center + Vector2(-r * 0.52, r * 0.54), Vector2(r * 1.04, r * 0.24)), gold.darkened(0.15), true)


func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.44
	
	match icon_type:
		"gear":
			draw_gear_shape(self, c, r, primary_color, secondary_color)
		"crown":
			draw_crown_shape(self, c, r, primary_color)
		"gift":
			draw_gift_shape(self, c, r)
		"globe":
			draw_circle(c, r, Color(0.14, 0.48, 0.88, 0.95))
			draw_arc(c, r, 0.0, TAU, 24, primary_color, 2.2, true)
			draw_line(c - Vector2(r, 0), c + Vector2(r, 0), primary_color, 1.8, true)
			draw_line(c - Vector2(0, r), c + Vector2(0, r), primary_color, 1.8, true)
			draw_arc(c, r * 0.58, 0.0, TAU, 20, primary_color, 1.6, true)
		"gem":
			var pts := PackedVector2Array([
				c + Vector2(-r * 0.55, -r * 0.68),
				c + Vector2(r * 0.55, -r * 0.68),
				c + Vector2(r * 0.92, -r * 0.15),
				c + Vector2(0.0, r * 0.88),
				c + Vector2(-r * 0.92, -r * 0.15)
			])
			draw_colored_polygon(pts, Color(0.28, 0.92, 1.0, 1.0))
			var inner := PackedVector2Array([
				c + Vector2(-r * 0.32, -r * 0.45),
				c + Vector2(r * 0.32, -r * 0.45),
				c + Vector2(0.0, r * 0.52)
			])
			draw_colored_polygon(inner, Color(0.78, 0.98, 1.0, 0.88))
		"falling":
			var bsz: float = r * 0.44
			var top_y: float = c.y - r * 0.78
			for dx in [-1, 0, 1]:
				draw_rect(Rect2(Vector2(c.x + float(dx) * (bsz + 1.5) - bsz * 0.5, top_y), Vector2(bsz, bsz)), primary_color, true)
			draw_rect(Rect2(Vector2(c.x - bsz * 0.5, top_y + bsz + 1.5), Vector2(bsz, bsz)), primary_color, true)
			var arr := PackedVector2Array([
				c + Vector2(-r * 0.48, r * 0.30),
				c + Vector2(r * 0.48, r * 0.30),
				c + Vector2(0.0, r * 0.88)
			])
			draw_colored_polygon(arr, Color(1.0, 0.92, 0.32, 1.0))
		"drag_drop":
			var cell_s: float = r * 0.68
			var gap: float = 2.5
			var start := c - Vector2(cell_s + gap * 0.5, cell_s + gap * 0.5)
			var cols := [
				Color(0.24, 0.92, 1.0, 1.0),
				Color(1.0, 0.82, 0.22, 1.0),
				Color(0.98, 0.36, 0.62, 1.0),
				Color(0.22, 0.92, 0.56, 1.0)
			]
			var idx := 0
			for gy in range(2):
				for gx in range(2):
					var rp := start + Vector2(float(gx) * (cell_s + gap), float(gy) * (cell_s + gap))
					draw_rect(Rect2(rp, Vector2(cell_s, cell_s)), cols[idx], true)
					idx += 1
		"play":
			var tri := PackedVector2Array([
				c + Vector2(-r * 0.52, -r * 0.78),
				c + Vector2(r * 0.78, 0.0),
				c + Vector2(-r * 0.52, r * 0.78)
			])
			draw_colored_polygon(tri, primary_color)
		"info":
			draw_circle(c, r, Color(0.14, 0.56, 0.96, 1.0))
			draw_arc(c, r, 0.0, TAU, 24, primary_color, 2.4, true)
			draw_circle(c + Vector2(0, -r * 0.42), r * 0.16, Color(1, 1, 1, 1))
			draw_rect(Rect2(c + Vector2(-r * 0.14, -r * 0.10), Vector2(r * 0.28, r * 0.68)), Color(1, 1, 1, 1), true)
		"trophy":
			draw_trophy_shape(self, c, r)
		"lock":
			draw_lock_shape(self, c, r, false)
		"unlock":
			draw_lock_shape(self, c, r, true)
		"star_filled":
			var star_c := c + Vector2(0, r * 0.09)
			draw_star_shape(self, star_c, r, r * 0.44, Color(1.0, 0.88, 0.18, 1.0), Color(0.52, 0.28, 0.02, 0.90), 1.5)
		"star_empty":
			draw_star_shape(self, c, r, r * 0.44, Color(0.14, 0.18, 0.42, 0.75), Color(0.55, 0.68, 0.96, 0.75), 1.5)
		"stars_row":
			var sr: float = minf(size.y * 0.40, size.x / 7.2)
			var spacing: float = sr * 2.35
			for s_i in range(3):
				var sc := Vector2(c.x + float(s_i - 1) * spacing, c.y)
				var earned: bool = (s_i < star_count)
				var f_col := Color(1.0, 0.88, 0.18, 1.0) if earned else Color(0.14, 0.18, 0.42, 0.80)
				var b_col := Color(1.0, 0.98, 0.65, 0.95) if earned else Color(0.48, 0.60, 0.88, 0.70)
				draw_star_shape(self, sc, sr, sr * 0.44, f_col, b_col, 1.6)
		"level_node_overlay":
			_draw_level_node_overlay()
		"wheel":
			var seg_cols := [
				Color(0.96, 0.28, 0.46, 1.0),
				Color(0.20, 0.66, 0.98, 1.0),
				Color(0.18, 0.86, 0.54, 1.0),
				Color(1.0, 0.76, 0.18, 1.0)
			]
			for s_i in range(8):
				var a0: float = float(s_i) * (TAU / 8.0)
				var a1: float = a0 + (TAU / 8.0)
				var w_pts := PackedVector2Array([c, c + Vector2(cos(a0), sin(a0)) * r, c + Vector2(cos(a1), sin(a1)) * r])
				draw_colored_polygon(w_pts, seg_cols[s_i % seg_cols.size()])
			draw_arc(c, r, 0.0, TAU, 24, Color(1.0, 0.94, 0.42, 1.0), 2.2, true)
			draw_circle(c, r * 0.28, Color(1.0, 0.94, 0.42, 1.0))
		"music", "music_off":
			draw_circle(c + Vector2(-r * 0.35, r * 0.35), r * 0.30, primary_color)
			draw_circle(c + Vector2(r * 0.35, r * 0.20), r * 0.30, primary_color)
			draw_line(c + Vector2(-r * 0.10, r * 0.35), c + Vector2(-r * 0.10, -r * 0.55), primary_color, 2.4, true)
			draw_line(c + Vector2(r * 0.60, r * 0.20), c + Vector2(r * 0.60, -r * 0.70), primary_color, 2.4, true)
			draw_line(c + Vector2(-r * 0.10, -r * 0.55), c + Vector2(r * 0.60, -r * 0.70), primary_color, 3.2, true)
			if icon_type == "music_off":
				draw_line(c + Vector2(-r * 0.65, -r * 0.62), c + Vector2(r * 0.72, r * 0.68), Color(1.0, 0.36, 0.42, 1.0), 2.6, true)
		"sound_on", "sound_off":
			var spk := PackedVector2Array([
				c + Vector2(-r * 0.65, -r * 0.28),
				c + Vector2(-r * 0.25, -r * 0.28),
				c + Vector2(r * 0.20, -r * 0.68),
				c + Vector2(r * 0.20, r * 0.68),
				c + Vector2(-r * 0.25, r * 0.28),
				c + Vector2(-r * 0.65, r * 0.28)
			])
			draw_colored_polygon(spk, primary_color)
			if icon_type == "sound_on":
				draw_arc(c + Vector2(r * 0.20, 0), r * 0.45, -PI * 0.35, PI * 0.35, 10, primary_color, 2.2, true)
			else:
				draw_line(c + Vector2(r * 0.32, -r * 0.35), c + Vector2(r * 0.78, r * 0.35), Color(1.0, 0.36, 0.42, 1.0), 2.6, true)
				draw_line(c + Vector2(r * 0.78, -r * 0.35), c + Vector2(r * 0.32, r * 0.35), Color(1.0, 0.36, 0.42, 1.0), 2.6, true)
		"restart", "turn":
			draw_arc(c, r * 0.68, -PI * 0.75, PI * 0.65, 20, primary_color, 2.8, true)
			var tip: Vector2 = c + Vector2(cos(-PI * 0.75), sin(-PI * 0.75)) * (r * 0.68)
			var arr_t := PackedVector2Array([tip + Vector2(-4, -5), tip + Vector2(6, -2), tip + Vector2(-2, 6)])
			draw_colored_polygon(arr_t, primary_color)
		"home":
			var roof := PackedVector2Array([c + Vector2(-r * 0.78, 0.0), c + Vector2(0.0, -r * 0.78), c + Vector2(r * 0.78, 0.0)])
			draw_colored_polygon(roof, primary_color)
			draw_rect(Rect2(c + Vector2(-r * 0.52, 0.0), Vector2(r * 1.04, r * 0.72)), primary_color, true)
		"left":
			var l_pts := PackedVector2Array([c + Vector2(r * 0.48, -r * 0.68), c + Vector2(-r * 0.58, 0.0), c + Vector2(r * 0.48, r * 0.68)])
			draw_colored_polygon(l_pts, primary_color)
		"right":
			var r_pts := PackedVector2Array([c + Vector2(-r * 0.48, -r * 0.68), c + Vector2(r * 0.58, 0.0), c + Vector2(-r * 0.48, r * 0.68)])
			draw_colored_polygon(r_pts, primary_color)
		"down":
			var d_pts := PackedVector2Array([c + Vector2(-r * 0.68, -r * 0.42), c + Vector2(r * 0.68, -r * 0.42), c + Vector2(0.0, r * 0.62)])
			draw_colored_polygon(d_pts, primary_color)
		"bolt", "energy", "lightning":
			var b_pts := PackedVector2Array([
				c + Vector2(r * 0.15, -r * 0.82),
				c + Vector2(-r * 0.52, r * 0.05),
				c + Vector2(r * 0.02, r * 0.05),
				c + Vector2(-r * 0.18, r * 0.82),
				c + Vector2(r * 0.52, -r * 0.08),
				c + Vector2(-r * 0.02, -r * 0.08)
			])
			draw_colored_polygon(b_pts, Color(1.0, 0.92, 0.24, 1.0))
		"plus", "add":
			var arm: float = r * 0.62
			var thick: float = maxf(3.2, r * 0.34)
			var out_thick: float = thick + 2.4
			var out_col := Color(0.04, 0.22, 0.14, 0.95)
			draw_line(c - Vector2(arm, 0.0), c + Vector2(arm, 0.0), out_col, out_thick, true)
			draw_line(c - Vector2(0.0, arm), c + Vector2(0.0, arm), out_col, out_thick, true)
			draw_line(c - Vector2(arm, 0.0), c + Vector2(arm, 0.0), primary_color, thick, true)
			draw_line(c - Vector2(0.0, arm), c + Vector2(0.0, arm), primary_color, thick, true)
		"extra_life":
			var hc := c + Vector2(0, r * 0.08)
			var hcol := Color(0.98, 0.24, 0.48, 1.0)
			draw_circle(hc + Vector2(-r * 0.34, -r * 0.24), r * 0.40, hcol)
			draw_circle(hc + Vector2(r * 0.34, -r * 0.24), r * 0.40, hcol)
			draw_colored_polygon(PackedVector2Array([hc + Vector2(-r * 0.72, -r * 0.08), hc + Vector2(r * 0.72, -r * 0.08), hc + Vector2(0.0, r * 0.72)]), hcol)
		"close", "cancel", "exit":
			draw_circle(c, r * 0.88, Color(0.62, 0.08, 0.14, 0.85))
			draw_arc(c, r * 0.88, 0.0, TAU, 20, primary_color, 2.0, true)
			var d_len: float = r * 0.42
			draw_line(c + Vector2(-d_len, -d_len), c + Vector2(d_len, d_len), Color(1.0, 0.96, 0.96, 1.0), 3.0, true)
			draw_line(c + Vector2(d_len, -d_len), c + Vector2(-d_len, d_len), Color(1.0, 0.96, 0.96, 1.0), 3.0, true)
		"4tm_logo":
			var tex := load_official_4tm_logo_texture()
			if tex:
				var badge_rect := Rect2(Vector2.ZERO, Vector2(maxf(20.0, size.x), maxf(20.0, size.y)))
				draw_texture_rect(tex, badge_rect, false)
		"account", "user", "local_account":
			draw_circle(c, r * 0.92, Color(0.12, 0.36, 0.78, 0.92))
			draw_arc(c, r * 0.92, 0.0, TAU, 24, primary_color, 2.0, true)
			draw_circle(c + Vector2(0.0, -r * 0.24), r * 0.32, Color(0.98, 0.98, 1.0, 0.98))
			var sh_pts := PackedVector2Array()
			for i in range(13):
				var ang: float = PI + float(i) * (PI / 12.0)
				sh_pts.append(c + Vector2(0.0, r * 0.66) + Vector2(cos(ang) * r * 0.56, sin(ang) * r * 0.48))
			draw_colored_polygon(sh_pts, Color(0.98, 0.98, 1.0, 0.98))
		"trash", "delete":
			var bin_w: float = r * 1.12
			var bin_h: float = r * 1.14
			var lid_w: float = r * 1.34
			var top_y_bin: float = c.y - r * 0.34
			var bot_y_bin: float = c.y + r * 0.78
			var bin_pts := PackedVector2Array([
				Vector2(c.x - bin_w * 0.50, top_y_bin),
				Vector2(c.x + bin_w * 0.50, top_y_bin),
				Vector2(c.x + bin_w * 0.40, bot_y_bin),
				Vector2(c.x - bin_w * 0.40, bot_y_bin)
			])
			draw_colored_polygon(bin_pts, primary_color)
			draw_rect(Rect2(Vector2(c.x - lid_w * 0.5, top_y_bin - r * 0.24), Vector2(lid_w, r * 0.20)), primary_color, true)
			draw_arc(Vector2(c.x, top_y_bin - r * 0.24), r * 0.24, PI, TAU, 10, primary_color, 2.2, true)
			var flute_col := Color(0.42, 0.06, 0.12, 0.88)
			for fx in [-0.20, 0.0, 0.20]:
				draw_line(
					Vector2(c.x + bin_w * float(fx), top_y_bin + r * 0.16),
					Vector2(c.x + bin_w * float(fx) * 0.85, bot_y_bin - r * 0.14),
					flute_col, 1.8, true
				)
		"email", "mail":
			var ew: float = r * 1.56
			var eh: float = r * 1.12
			var er := Rect2(c - Vector2(ew * 0.5, eh * 0.5), Vector2(ew, eh))
			draw_rect(er, Color(0.16, 0.34, 0.68, 0.95), true)
			draw_rect(er, primary_color, false, 2.2)
			var flap := PackedVector2Array([
				er.position + Vector2(1.5, 1.5),
				c + Vector2(0.0, eh * 0.12),
				Vector2(er.end.x - 1.5, er.position.y + 1.5)
			])
			draw_polyline(flap, primary_color, 2.2, true)
		"apple", "apple_id":
			var apple_col := primary_color
			draw_circle(c + Vector2(-r * 0.24, r * 0.06), r * 0.48, apple_col)
			draw_circle(c + Vector2(r * 0.24, r * 0.06), r * 0.48, apple_col)
			var lower_pts := PackedVector2Array([
				c + Vector2(-r * 0.68, r * 0.16),
				c + Vector2(r * 0.68, r * 0.16),
				c + Vector2(r * 0.34, r * 0.74),
				c + Vector2(0.0, r * 0.64),
				c + Vector2(-r * 0.34, r * 0.74)
			])
			draw_colored_polygon(lower_pts, apple_col)
			var leaf_pts := PackedVector2Array([
				c + Vector2(0.0, -r * 0.38),
				c + Vector2(r * 0.10, -r * 0.78),
				c + Vector2(r * 0.40, -r * 0.82),
				c + Vector2(r * 0.28, -r * 0.46)
			])
			draw_colored_polygon(leaf_pts, apple_col.lightened(0.15))
		"google_play", "google_play_id", "google", "google_id":
			var p_top := c + Vector2(-r * 0.62, -r * 0.78)
			var p_bot := c + Vector2(-r * 0.62, r * 0.78)
			var p_nose := c + Vector2(r * 0.78, 0.0)
			var p_mid := c + Vector2(-r * 0.04, 0.0)
			var p_upper := p_top.lerp(p_nose, 0.66)
			var p_lower := p_bot.lerp(p_nose, 0.66)
			draw_colored_polygon(PackedVector2Array([p_top, p_bot, p_mid]), Color(0.18, 0.74, 0.98, 1.0))
			draw_colored_polygon(PackedVector2Array([p_top, p_upper, p_mid]), Color(0.16, 0.88, 0.52, 1.0))
			draw_colored_polygon(PackedVector2Array([p_bot, p_mid, p_lower]), Color(0.96, 0.28, 0.34, 1.0))
			draw_colored_polygon(PackedVector2Array([p_mid, p_upper, p_nose, p_lower]), Color(1.0, 0.80, 0.16, 1.0))
			draw_polyline(PackedVector2Array([p_top, p_nose, p_bot, p_top]), Color(1.0, 1.0, 1.0, 0.88), 1.5, true)
		"haptic", "haptics":
			var ph_w: float = r * 0.86
			var ph_h: float = r * 1.38
			var ph_r := Rect2(c - Vector2(ph_w * 0.5, ph_h * 0.5), Vector2(ph_w, ph_h))
			draw_rect(ph_r, Color(0.14, 0.28, 0.62, 0.95), true)
			draw_rect(ph_r, primary_color, false, 2.0)
			draw_circle(Vector2(c.x, ph_r.end.y - r * 0.18), r * 0.09, primary_color)
			draw_arc(c + Vector2(-ph_w * 0.62, 0.0), r * 0.42, PI * 0.72, PI * 1.28, 8, primary_color, 1.9, true)
			draw_arc(c + Vector2(ph_w * 0.62, 0.0), r * 0.42, -PI * 0.28, PI * 0.28, 8, primary_color, 1.9, true)
		"warning", "alert":
			var tri_w := PackedVector2Array([
				c + Vector2(0.0, -r * 0.84),
				c + Vector2(r * 0.88, r * 0.74),
				c + Vector2(-r * 0.88, r * 0.74)
			])
			draw_colored_polygon(tri_w, Color(1.0, 0.78, 0.16, 1.0))
			var closed_w := tri_w.duplicate()
			closed_w.append(tri_w[0])
			draw_polyline(closed_w, Color(1.0, 0.94, 0.56, 1.0), 2.0, true)
			draw_rect(Rect2(c + Vector2(-r * 0.10, -r * 0.30), Vector2(r * 0.20, r * 0.52)), Color(0.18, 0.10, 0.04, 0.98), true)
			draw_circle(c + Vector2(0.0, r * 0.44), r * 0.11, Color(0.18, 0.10, 0.04, 0.98))


func _draw_level_node_overlay() -> void:
	var w: float = size.x if size.x > 10.0 else 52.0
	var h: float = size.y if size.y > 10.0 else 48.0
	var center := Vector2(w * 0.5, h * 0.5)
	var is_ms: bool = (milestone_type != "" and milestone_type != "normal")

	# Dimensional World Destination Marker (Sits directly inside the Landmark Destination Plaza)
	var pad_c := Vector2(center.x, h * 0.44)
	var rx: float = w * (0.38 if is_ms else 0.33)
	var ry: float = rx * 0.82
	var lip_h: float = 3.8 if is_ms else 3.0

	# 1. State Palette (Current/Selected > Completed > Unlocked > Locked)
	var disc_col := Color(0.16, 0.58, 0.92, 1.0)
	var rim_col := Color(0.98, 0.92, 0.76, 1.0)
	var lip_col := Color(0.46, 0.36, 0.24, 1.0)

	if is_ms:
		disc_col = Color(0.88, 0.22, 0.30, 1.0) if (milestone_type == "major_milestone" or milestone_type == "crown") else Color(0.62, 0.26, 0.88, 1.0)
		rim_col = Color(1.0, 0.88, 0.28, 1.0)
		lip_col = Color(0.58, 0.34, 0.08, 1.0)

	if is_selected and is_unlocked:
		disc_col = Color(0.98, 0.44, 0.10, 1.0)
		rim_col = Color(1.0, 0.96, 0.46, 1.0)
		lip_col = Color(0.64, 0.30, 0.06, 1.0)
	elif is_current and is_unlocked:
		disc_col = Color(0.10, 0.72, 0.98, 1.0) if not is_ms else Color(0.96, 0.30, 0.18, 1.0)
		rim_col = Color(1.0, 0.94, 0.40, 1.0)
		lip_col = Color(0.58, 0.38, 0.10, 1.0)
	elif is_completed:
		disc_col = Color(0.18, 0.74, 0.40, 1.0) if not is_ms else Color(0.92, 0.52, 0.14, 1.0)
		rim_col = Color(0.98, 0.90, 0.42, 1.0)
		lip_col = Color(0.44, 0.34, 0.14, 1.0)
	elif not is_unlocked:
		disc_col = Color(0.32, 0.37, 0.46, 1.0) if not is_ms else Color(0.40, 0.34, 0.50, 1.0)
		rim_col = Color(0.70, 0.74, 0.82, 1.0)
		lip_col = Color(0.22, 0.26, 0.34, 1.0)

	# 2. Subtle Ground Contact Shadow directly on the Landmark Courtyard (no floating island platform!)
	var sh_pts := PackedVector2Array()
	for i in range(20):
		var a_sh: float = float(i) * (TAU / 20.0)
		sh_pts.append(Vector2(pad_c.x + 1.2 + cos(a_sh) * (rx * 1.08), pad_c.y + lip_h + 2.2 + sin(a_sh) * (ry * 1.08)))
	draw_colored_polygon(sh_pts, Color(0.03, 0.06, 0.14, 0.34))

	# 3. Animated Destination Beacon Ring for Current / Selected / Milestone
	if (is_current or is_selected) and is_unlocked:
		var pulse_t: float = float(Time.get_ticks_msec()) * 0.0042
		var pulse_s: float = 1.0 + 0.05 * sin(pulse_t)
		var halo_pts := PackedVector2Array()
		for i in range(24):
			var a_halo: float = float(i) * (TAU / 24.0)
			halo_pts.append(Vector2(
				pad_c.x + cos(a_halo) * rx * 1.32 * pulse_s,
				pad_c.y + 1.0 + sin(a_halo) * ry * 1.32 * pulse_s
			))
		draw_colored_polygon(halo_pts, Color(1.0, 0.94, 0.36, 0.28))
		draw_polyline(halo_pts, Color(1.0, 0.97, 0.52, 0.96), 2.4, true)
	elif is_ms:
		var ms_halo := PackedVector2Array()
		for i in range(24):
			var a_ms: float = float(i) * (TAU / 24.0)
			ms_halo.append(Vector2(pad_c.x + cos(a_ms) * rx * 1.24, pad_c.y + 1.0 + sin(a_ms) * ry * 1.24))
		draw_polyline(ms_halo, Color(1.0, 0.88, 0.32, 0.72 if is_unlocked else 0.38), 2.0, true)

	# 4. Sculpted 3D Destination Medallion (Octagonal Fortress Badge for Milestones, Shield Disc for Normal)
	var segs: int = 8 if is_ms else 22
	var lip_pts := PackedVector2Array()
	var outer_pts := PackedVector2Array()
	var inner_pts := PackedVector2Array()
	var core_pts := PackedVector2Array()
	for i in range(segs):
		var a_med: float = float(i) * (TAU / float(segs)) + (PI * 0.125 if is_ms else 0.0)
		var ca: float = cos(a_med)
		var sa: float = sin(a_med)
		lip_pts.append(Vector2(pad_c.x + ca * rx, pad_c.y + lip_h + sa * ry))
		outer_pts.append(Vector2(pad_c.x + ca * rx, pad_c.y + sa * ry))
		inner_pts.append(Vector2(pad_c.x + ca * (rx - 3.2), pad_c.y + sa * (ry - 2.6)))
		core_pts.append(Vector2(pad_c.x + ca * (rx - 5.2), pad_c.y - 0.8 + sa * (ry - 4.2)))

	draw_colored_polygon(lip_pts, lip_col)
	draw_colored_polygon(outer_pts, rim_col)
	var closed_outer := outer_pts.duplicate()
	closed_outer.append(outer_pts[0])
	draw_polyline(closed_outer, lip_col.darkened(0.35), 1.6, true)
	draw_colored_polygon(inner_pts, disc_col.darkened(0.14))
	draw_colored_polygon(core_pts, disc_col.lightened(0.08))

	# Top-left specular highlight arc inside the destination badge
	var hi_arc := PackedVector2Array()
	for i in range(9):
		var a_hi: float = PI * 0.95 + float(i) * (PI * 0.70 / 8.0)
		hi_arc.append(Vector2(pad_c.x + cos(a_hi) * (rx * 0.72), pad_c.y + sin(a_hi) * (ry * 0.70)))
	draw_polyline(hi_arc, Color(1.0, 1.0, 0.96, 0.46 if is_unlocked else 0.20), 1.8, true)

	# 5. Milestone / Current Destination Crest at Top Rim
	var crest_pos := Vector2(center.x, maxf(5.5, pad_c.y - ry - 2.6))
	if is_ms:
		if milestone_type == "reward_milestone" or milestone_type == "chest":
			draw_gift_shape(self, crest_pos, 7.4)
		else:
			draw_crown_shape(self, crest_pos, 8.2, Color(1.0, 0.90, 0.24, 1.0))
	elif (is_selected or is_current) and is_unlocked:
		draw_crown_shape(self, crest_pos, 6.8, Color(1.0, 0.94, 0.36, 1.0))

	# 6. Stars Row or Padlock on Lower Plinth
	var ledge_y: float = minf(h - 5.5, pad_c.y + ry + lip_h + 2.2)
	if is_unlocked:
		var sr: float = clampf(w * 0.084, 5.0, 7.0)
		var spacing: float = sr * 2.12
		for s_i in range(3):
			var arch_dy: float = 1.2 if s_i == 1 else -0.3
			var sc := Vector2(center.x + float(s_i - 1) * spacing, ledge_y + arch_dy)
			var earned: bool = (s_i < star_count)
			draw_circle(sc + Vector2(0.6, 1.0), sr * 0.76, Color(0.02, 0.05, 0.12, 0.42))
			var f_col := Color(1.0, 0.90, 0.18, 1.0) if earned else Color(0.18, 0.24, 0.36, 0.90)
			var b_col := Color(0.46, 0.24, 0.02, 0.98) if earned else Color(0.52, 0.60, 0.74, 0.78)
			draw_star_shape(self, sc, sr, sr * 0.45, f_col, b_col, 1.3)
	else:
		var lock_p := Vector2(center.x, ledge_y - 0.5)
		draw_circle(lock_p + Vector2(0.8, 1.2), 6.8, Color(0.02, 0.05, 0.12, 0.42))
		draw_circle(lock_p, 6.5, Color(0.22, 0.27, 0.38, 0.96))
		draw_lock_shape(self, lock_p, 5.6, false)

