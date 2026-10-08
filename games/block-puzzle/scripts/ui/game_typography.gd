class_name GameTypography
extends RefCounted

## GameTypography — Centralized Casual Mobile Game Typography System for Block Puzzle — 4TM
## Implements a multi-role typography system with distinctive visual personalities and dedicated font assets:
##   - GAME_DISPLAY: Fredoka (Playful rounded display font for title, START CTA, mode names, major headers)
##   - GAME_HUD_NUMBER: Titan One (Distinctive heavy rounded game display numerals for LV, Score, Energy)
##   - GAME_UI: Nunito (Friendly rounded casual game UI font with 100% full Vietnamese coverage)
##   - GAME_SMALL: Nunito (Compact, clear UI typography for sub-labels and footers)
##   - GAME_CALLOUT: Luckiest Guy (Extremely expressive heavy display font for score callouts: GOOD, GREAT, COMBO, etc.)

enum Role {
	GAME_DISPLAY,
	GAME_HUD_NUMBER,
	GAME_UI,
	GAME_SMALL,
	GAME_CALLOUT
}

static var _shared_font_cache: Dictionary = {}
static var _display_base_font: Font = null
static var _hud_number_base_font: Font = null
static var _ui_base_font: Font = null
static var _callout_base_font: Font = null


static func _get_base_display_font() -> Font:
	if _display_base_font != null:
		return _display_base_font
	if ResourceLoader.exists("res://assets/fonts/game_display_bold.ttf"):
		_display_base_font = ResourceLoader.load("res://assets/fonts/game_display_bold.ttf") as Font
	elif ResourceLoader.exists("res://assets/fonts/game_hud_numbers.ttf"):
		_display_base_font = ResourceLoader.load("res://assets/fonts/game_hud_numbers.ttf") as Font
	if _display_base_font == null:
		_display_base_font = _get_base_ui_font()
	return _display_base_font


static func set_custom_display_font(font_path: String) -> void:
	if ResourceLoader.exists(font_path):
		_display_base_font = ResourceLoader.load(font_path) as Font
		_shared_font_cache.clear()



static func _get_base_hud_number_font() -> Font:
	if _hud_number_base_font != null:
		return _hud_number_base_font
	if ResourceLoader.exists("res://assets/fonts/game_hud_numbers.ttf"):
		_hud_number_base_font = ResourceLoader.load("res://assets/fonts/game_hud_numbers.ttf") as Font
	elif ResourceLoader.exists("res://assets/fonts/game_display_bold.ttf"):
		_hud_number_base_font = ResourceLoader.load("res://assets/fonts/game_display_bold.ttf") as Font
	if _hud_number_base_font == null:
		_hud_number_base_font = _get_base_display_font()
	return _hud_number_base_font


static func _get_base_ui_font() -> Font:
	if _ui_base_font != null:
		return _ui_base_font
	if ResourceLoader.exists("res://assets/fonts/game_ui_font.ttf"):
		_ui_base_font = ResourceLoader.load("res://assets/fonts/game_ui_font.ttf") as Font
	elif ResourceLoader.exists("res://assets/fonts/game_font_bold.ttf"):
		_ui_base_font = ResourceLoader.load("res://assets/fonts/game_font_bold.ttf") as Font
	if _ui_base_font == null:
		var sys_font := SystemFont.new()
		sys_font.font_names = PackedStringArray([
			"Be Vietnam Pro", "Nunito", "Quicksand", "Comfortaa",
			"Arial Rounded MT Bold", "Montserrat", "Segoe UI", "Trebuchet MS", "Arial", "Sans-Serif"
		])
		sys_font.font_weight = 700
		sys_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
		if ThemeDB.fallback_font:
			sys_font.fallbacks = [ThemeDB.fallback_font]
		_ui_base_font = sys_font
	return _ui_base_font


static func _get_base_callout_font() -> Font:
	if _callout_base_font != null:
		return _callout_base_font
	if ResourceLoader.exists("res://assets/fonts/game_callout.ttf"):
		_callout_base_font = ResourceLoader.load("res://assets/fonts/game_callout.ttf") as Font
	elif ResourceLoader.exists("res://assets/fonts/game_display_bold.ttf"):
		_callout_base_font = ResourceLoader.load("res://assets/fonts/game_display_bold.ttf") as Font
	if _callout_base_font == null:
		_callout_base_font = _get_base_display_font()
	return _callout_base_font


static func get_role_font(p_role: int, p_embolden: float = -1.0, p_spacing: int = -1) -> Font:
	var def_embolden: float = 0.20
	var def_spacing: int = 1
	var base_f: Font = null
	
	match p_role:
		Role.GAME_DISPLAY:
			def_embolden = 0.22
			def_spacing = 2
			base_f = _get_base_display_font()
		Role.GAME_HUD_NUMBER:
			def_embolden = 0.25
			def_spacing = 2
			base_f = _get_base_hud_number_font()
		Role.GAME_UI:
			def_embolden = 0.16
			def_spacing = 1
			base_f = _get_base_ui_font()
		Role.GAME_SMALL:
			def_embolden = 0.10
			def_spacing = 0
			base_f = _get_base_ui_font()
		Role.GAME_CALLOUT:
			def_embolden = 0.28
			def_spacing = 3
			base_f = _get_base_callout_font()
		_:
			base_f = _get_base_display_font()
	
	var emb: float = p_embolden if p_embolden >= 0.0 else def_embolden
	var spc: int = p_spacing if p_spacing >= 0 else def_spacing
	var key: String = "role_%d_%.2f_%d" % [p_role, emb, spc]
	
	if _shared_font_cache.has(key):
		return _shared_font_cache[key]
	
	var f_var := FontVariation.new()
	f_var.base_font = base_f
	f_var.variation_embolden = emb
	f_var.spacing_glyph = spc
	
	# Configure fallback chain for Vietnamese diacritics & missing glyphs
	var fallbacks_array: Array[Font] = []
	var ui_font := _get_base_ui_font()
	if ui_font and base_f != ui_font:
		fallbacks_array.append(ui_font)
	if ThemeDB.fallback_font and base_f != ThemeDB.fallback_font and ui_font != ThemeDB.fallback_font:
		fallbacks_array.append(ThemeDB.fallback_font)
	
	if not fallbacks_array.is_empty():
		f_var.fallbacks = fallbacks_array
		
	_shared_font_cache[key] = f_var
	return f_var


static func get_display_font(p_embolden: float = 0.22, p_spacing: int = 2) -> Font:
	return get_role_font(Role.GAME_DISPLAY, p_embolden, p_spacing)


static func get_hud_number_font(p_embolden: float = 0.25, p_spacing: int = 2) -> Font:
	return get_role_font(Role.GAME_HUD_NUMBER, p_embolden, p_spacing)


static func get_ui_font(p_embolden: float = 0.16, p_spacing: int = 1) -> Font:
	return get_role_font(Role.GAME_UI, p_embolden, p_spacing)


static func get_small_font(p_embolden: float = 0.10, p_spacing: int = 0) -> Font:
	return get_role_font(Role.GAME_SMALL, p_embolden, p_spacing)


static func get_callout_font(p_embolden: float = 0.28, p_spacing: int = 3) -> Font:
	return get_role_font(Role.GAME_CALLOUT, p_embolden, p_spacing)


static func get_game_font(p_embolden: float = 0.22, p_spacing: int = 1) -> Font:
	return get_role_font(Role.GAME_DISPLAY, p_embolden, p_spacing)


static func apply_hud_level_typography(lbl: Label, font_size: int = 38) -> void:
	if not lbl:
		return
	lbl.add_theme_font_override("font", get_hud_number_font(0.25, 2))
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.32, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.04, 0.01, 0.98))
	lbl.add_theme_constant_override("outline_size", maxi(4, int(float(font_size) * 0.16)))
	lbl.add_theme_color_override("font_shadow_color", Color(0.04, 0.02, 0.08, 0.92))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 3)


static func apply_hud_score_typography(lbl: Label, font_size: int = 36) -> void:
	if not lbl:
		return
	lbl.add_theme_font_override("font", get_hud_number_font(0.25, 2))
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.35, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.10, 0.04, 0.01, 0.98))
	lbl.add_theme_constant_override("outline_size", maxi(4, int(float(font_size) * 0.16)))
	lbl.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.12, 0.92))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 3)


static func apply_energy_typography(lbl: Label, font_size: int = 15) -> void:
	if not lbl:
		return
	lbl.add_theme_font_override("font", get_hud_number_font(0.20, 1))
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color(0.92, 1.0, 0.99, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.18, 0.24, 0.96))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.add_theme_color_override("font_shadow_color", Color(0.01, 0.08, 0.12, 0.85))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 2)


static func apply_primary_button_typography(btn: Button, font_size: int = 38) -> void:
	if not btn:
		return
	btn.add_theme_font_override("font", get_display_font(0.24, 1))
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.94, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.92, 0.98, 0.92, 1.0))
	btn.add_theme_color_override("font_outline_color", Color(0.02, 0.28, 0.12, 0.98))
	btn.add_theme_constant_override("outline_size", maxi(4, int(float(font_size) * 0.14)))
	btn.add_theme_color_override("font_shadow_color", Color(0.01, 0.16, 0.06, 0.95))
	btn.add_theme_constant_override("shadow_offset_x", 1)
	btn.add_theme_constant_override("shadow_offset_y", 3)


static func apply_secondary_button_typography(btn: Button, font_size: int = 22, outline_color: Color = Color(0.06, 0.10, 0.28, 0.95)) -> void:
	if not btn:
		return
	btn.add_theme_font_override("font", get_display_font(0.20, 1))
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(0.95, 0.98, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.88, 0.94, 1.0, 1.0))
	btn.add_theme_color_override("font_outline_color", outline_color)
	btn.add_theme_constant_override("outline_size", maxi(3, int(float(font_size) * 0.12)))
	btn.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.14, 0.85))
	btn.add_theme_constant_override("shadow_offset_x", 1)
	btn.add_theme_constant_override("shadow_offset_y", 2)


static func apply_heading_typography(lbl: Label, font_size: int = 26, is_cyan: bool = false) -> void:
	if not lbl:
		return
	lbl.add_theme_font_override("font", get_display_font(0.22, 1))
	lbl.add_theme_font_size_override("font_size", font_size)
	var col := Color(0.42, 0.96, 1.0, 1.0) if is_cyan else Color(1.0, 0.92, 0.38, 1.0)
	var outline := Color(0.04, 0.12, 0.34, 0.98) if is_cyan else Color(0.18, 0.06, 0.02, 0.98)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", outline)
	lbl.add_theme_constant_override("outline_size", maxi(4, int(float(font_size) * 0.18)))
	lbl.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.14, 0.90))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 3)


static func apply_game_title_typography(lbl: Label, font_size: int = 48) -> void:
	if not lbl:
		return
	lbl.add_theme_font_override("font", get_display_font(0.28, 2))
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.94, 0.32, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.04, 0.01, 0.98))
	lbl.add_theme_constant_override("outline_size", maxi(6, int(float(font_size) * 0.18)))
	lbl.add_theme_color_override("font_shadow_color", Color(0.04, 0.02, 0.12, 0.92))
	lbl.add_theme_constant_override("shadow_offset_x", 3)
	lbl.add_theme_constant_override("shadow_offset_y", 5)


static func apply_reward_callout_typography(lbl: Label, font_size: int = 38) -> void:
	if not lbl:
		return
	lbl.add_theme_font_override("font", get_callout_font(0.28, 2))
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.28, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.18, 0.04, 0.02, 0.98))
	lbl.add_theme_constant_override("outline_size", maxi(6, int(float(font_size) * 0.18)))
	lbl.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.10, 0.90))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 4)


static func apply_body_typography(lbl: Label, font_size: int = 16) -> void:
	if not lbl:
		return
	lbl.add_theme_font_override("font", get_ui_font(0.14, 0))
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.04, 0.08, 0.20, 0.95))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.10, 0.70))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 2)


static func apply_small_typography(lbl: Label, font_size: int = 12) -> void:
	if not lbl:
		return
	lbl.add_theme_font_override("font", get_small_font(0.10, 0))
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0, 0.92))
	lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.06, 0.16, 0.90))
	lbl.add_theme_constant_override("outline_size", 2)
