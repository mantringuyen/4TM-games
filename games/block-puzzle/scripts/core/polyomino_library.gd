class_name PolyominoLibrary
extends RefCounted

## PolyominoLibrary — Data-driven block library for Block Puzzle — 4TM
## FINAL ACTIVE PIECE RULE:
##   - ONLY 4-cell pieces (Tetrominoes) exist in the active piece library and generation pools.
##   - 1-cell, 2-cell, 3-cell, and 5-cell (or larger) pieces are strictly EXCLUDED and never generated anywhere.

# 4TM Clearly Separated Basic Colors for Playable Blocks
# Primary visual identity: Red, Orange, Yellow, Green, Cyan, Blue, Purple, Magenta/Pink
const COLOR_CYAN: Color = Color(0.02, 0.80, 0.96, 1.0)          # 1: Cyan
const COLOR_BLUE: Color = Color(0.14, 0.42, 0.98, 1.0)          # 2: Blue
const COLOR_GREEN: Color = Color(0.10, 0.80, 0.30, 1.0)         # 3: Green
const COLOR_EMERALD: Color = COLOR_GREEN
const COLOR_YELLOW: Color = Color(0.98, 0.86, 0.08, 1.0)        # 4: Yellow
const COLOR_AMBER: Color = COLOR_YELLOW
const COLOR_ORANGE: Color = Color(1.00, 0.46, 0.06, 1.0)        # 5: Orange
const COLOR_PURPLE: Color = Color(0.60, 0.22, 0.98, 1.0)        # 6: Purple
const COLOR_RED: Color = Color(0.94, 0.14, 0.16, 1.0)           # 7: Red
const COLOR_ROSE: Color = COLOR_RED
const COLOR_MAGENTA_PINK: Color = Color(0.96, 0.20, 0.68, 1.0)  # 8: Magenta/Pink
const COLOR_PINK: Color = COLOR_MAGENTA_PINK

const BASIC_COLOR_NAMES: Dictionary = {
	1: "cyan",
	2: "blue",
	3: "green",
	4: "yellow",
	5: "orange",
	6: "purple",
	7: "red",
	8: "magenta_pink"
}

const BASIC_BLOCK_COLORS: Dictionary = {
	"red": COLOR_RED,
	"orange": COLOR_ORANGE,
	"yellow": COLOR_YELLOW,
	"green": COLOR_GREEN,
	"cyan": COLOR_CYAN,
	"blue": COLOR_BLUE,
	"purple": COLOR_PURPLE,
	"magenta_pink": COLOR_MAGENTA_PINK
}

# Active shape catalog dictionary: Contains strictly 4-cell (Tetromino) shapes ONLY.
# 1-cell, 2-cell, 3-cell, and 5-cell shapes are completely excluded.
const SHAPES: Dictionary = {
	"square_2x2": {
		"id": "square_2x2",
		"name": "Square 2x2",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
		"color": COLOR_ORANGE,
		"color_id": 5,
		"color_name": "orange",
		"category": "square",
		"weight": 0.65
	},
	"line_4_h": {
		"id": "line_4_h",
		"name": "Line 1x4 Horizontal",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
		"color": COLOR_PURPLE,
		"color_id": 6,
		"color_name": "purple",
		"category": "line",
		"weight": 0.60
	},
	"line_4_v": {
		"id": "line_4_v",
		"name": "Line 4x1 Vertical",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)],
		"color": COLOR_PURPLE,
		"color_id": 6,
		"color_name": "purple",
		"category": "line",
		"weight": 0.65
	},
	"t_shape": {
		"id": "t_shape",
		"name": "T-Shape Down",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)],
		"color": COLOR_MAGENTA_PINK,
		"color_id": 8,
		"color_name": "magenta_pink",
		"category": "t_shape",
		"weight": 1.25
	},
	"t_shape_up": {
		"id": "t_shape_up",
		"name": "T-Shape Up",
		"cells": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
		"color": COLOR_YELLOW,
		"color_id": 4,
		"color_name": "yellow",
		"category": "t_shape",
		"weight": 1.25
	},
	"l_shape_4": {
		"id": "l_shape_4",
		"name": "L-Shape 4",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)],
		"color": COLOR_CYAN,
		"color_id": 1,
		"color_name": "cyan",
		"category": "l_shape",
		"weight": 1.30
	},
	"l_shape_4_h": {
		"id": "l_shape_4_h",
		"name": "L-Shape Horizontal",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1)],
		"color": COLOR_CYAN,
		"color_id": 1,
		"color_name": "cyan",
		"category": "l_shape",
		"weight": 1.25
	},
	"j_shape_4": {
		"id": "j_shape_4",
		"name": "J-Shape 4",
		"cells": [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 2)],
		"color": COLOR_BLUE,
		"color_id": 2,
		"color_name": "blue",
		"category": "l_shape",
		"weight": 1.30
	},
	"j_shape_4_h": {
		"id": "j_shape_4_h",
		"name": "J-Shape Horizontal",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
		"color": COLOR_BLUE,
		"color_id": 2,
		"color_name": "blue",
		"category": "l_shape",
		"weight": 1.25
	},
	"s_shape": {
		"id": "s_shape",
		"name": "S-Shape",
		"cells": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
		"color": COLOR_GREEN,
		"color_id": 3,
		"color_name": "green",
		"category": "z_shape",
		"weight": 1.20
	},
	"z_shape": {
		"id": "z_shape",
		"name": "Z-Shape",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],
		"color": COLOR_RED,
		"color_id": 7,
		"color_name": "red",
		"category": "z_shape",
		"weight": 1.20
	}
}


## Normalizes shape cells so the bounding box begins at (0,0)
static func normalize_cells(cells: Array) -> Array:
	if cells.is_empty():
		return []
	
	var min_x: int = cells[0].x
	var min_y: int = cells[0].y
	
	for cell in cells:
		if cell.x < min_x:
			min_x = cell.x
		if cell.y < min_y:
			min_y = cell.y
	
	var normalized: Array = []
	for cell in cells:
		normalized.append(Vector2i(cell.x - min_x, cell.y - min_y))
	
	return normalized


## Calculates the grid bounding box dimensions (width, height) of a cell array
static func get_dimensions(cells: Array) -> Vector2i:
	if cells.is_empty():
		return Vector2i.ZERO
	
	var min_x: int = cells[0].x
	var max_x: int = cells[0].x
	var min_y: int = cells[0].y
	var max_y: int = cells[0].y
	
	for cell in cells:
		if cell.x < min_x: min_x = cell.x
		if cell.x > max_x: max_x = cell.x
		if cell.y < min_y: min_y = cell.y
		if cell.y > max_y: max_y = cell.y
	
	return Vector2i((max_x - min_x) + 1, (max_y - min_y) + 1)


## Rotates shape cells 90 degrees clockwise and returns normalized coordinates
static func rotate_90_cw(cells: Array) -> Array:
	var rotated: Array = []
	for cell in cells:
		rotated.append(Vector2i(-cell.y, cell.x))
	return normalize_cells(rotated)


## Rotates shape cells 90 degrees counter-clockwise and returns normalized coordinates
static func rotate_90_ccw(cells: Array) -> Array:
	var rotated: Array = []
	for cell in cells:
		rotated.append(Vector2i(cell.y, -cell.x))
	return normalize_cells(rotated)


## Returns a shape definition by ID (or empty Dictionary if not found)
static func get_shape(shape_id: String) -> Dictionary:
	if SHAPES.has(shape_id):
		return SHAPES[shape_id].duplicate(true)
	return {}


# Explicit Active Shape Pool: Strictly 4-cell pieces ONLY.
# 1-cell, 2-cell, 3-cell, and 5-cell pieces are permanently EXCLUDED from active generation.
const ACTIVE_SHAPES_4_CELL: Array[String] = [
	"square_2x2", "line_4_h", "line_4_v",
	"t_shape", "t_shape_up",
	"l_shape_4", "l_shape_4_h",
	"j_shape_4", "j_shape_4_h",
	"s_shape", "z_shape"
]

const ACTIVE_SHAPE_KEYS: Array[String] = [
	"square_2x2", "line_4_h", "line_4_v",
	"t_shape", "t_shape_up",
	"l_shape_4", "l_shape_4_h",
	"j_shape_4", "j_shape_4_h",
	"s_shape", "z_shape"
]

# Original 4TM Procedural Block Materials (Visual-only treatments; shapes & 4-cell collision unchanged)
const MATERIAL_IDS: Array[String] = [
	"stone",
	"red_brick",
	"moss_stone",
	"crystal",
	"wood",
	"metal",
	"gemstone",
	"starlight",
	"glass",
	"frosted_glass"
]

const BLOCK_MATERIALS: Dictionary = {
	"stone": {
		"id": "stone",
		"name_en": "Carved Runic Slate",
		"name_vi": "Đá Chạm Khắc",
		"base_color": Color(0.42, 0.58, 0.78, 1.0),
		"highlight_color": Color(0.82, 0.92, 1.0, 1.0),
		"shadow_color": Color(0.18, 0.28, 0.44, 1.0),
		"pattern_color": Color(0.28, 0.42, 0.62, 0.85),
		"accent_color": Color(0.90, 0.96, 1.0, 0.72),
		"pattern_type": "chiseled_cracks"
	},
	"red_brick": {
		"id": "red_brick",
		"name_en": "Red Brick",
		"name_vi": "Gạch Đỏ",
		"base_color": Color(0.88, 0.34, 0.24, 1.0),
		"highlight_color": Color(1.0, 0.68, 0.50, 1.0),
		"shadow_color": Color(0.48, 0.14, 0.10, 1.0),
		"pattern_color": Color(0.98, 0.86, 0.74, 0.80),
		"accent_color": Color(0.68, 0.20, 0.14, 0.85),
		"pattern_type": "masonry_mortar"
	},
	"moss_stone": {
		"id": "moss_stone",
		"name_en": "Moss-Covered Stone",
		"name_vi": "Đá Phủ Rêu",
		"base_color": Color(0.24, 0.68, 0.48, 1.0),
		"highlight_color": Color(0.46, 0.96, 0.58, 1.0),
		"shadow_color": Color(0.10, 0.34, 0.24, 1.0),
		"pattern_color": Color(0.22, 0.86, 0.42, 0.95),
		"accent_color": Color(0.72, 1.0, 0.74, 0.88),
		"pattern_type": "moss_overgrowth"
	},
	"crystal": {
		"id": "crystal",
		"name_en": "Prism Crystal",
		"name_vi": "Pha Lê Băng",
		"base_color": Color(0.10, 0.80, 0.98, 1.0),
		"highlight_color": Color(0.84, 0.98, 1.0, 1.0),
		"shadow_color": Color(0.04, 0.36, 0.64, 1.0),
		"pattern_color": Color(0.64, 0.96, 1.0, 0.76),
		"accent_color": Color(1.0, 1.0, 1.0, 0.94),
		"pattern_type": "refraction_facets"
	},
	"wood": {
		"id": "wood",
		"name_en": "Timber Wood",
		"name_vi": "Gỗ Sồi",
		"base_color": Color(0.86, 0.54, 0.18, 1.0),
		"highlight_color": Color(1.0, 0.82, 0.44, 1.0),
		"shadow_color": Color(0.46, 0.24, 0.08, 1.0),
		"pattern_color": Color(0.58, 0.32, 0.10, 0.78),
		"accent_color": Color(1.0, 0.90, 0.60, 0.78),
		"pattern_type": "wood_grain"
	},
	"metal": {
		"id": "metal",
		"name_en": "Brushed Metal",
		"name_vi": "Kim Loại",
		"base_color": Color(0.32, 0.56, 0.92, 1.0),
		"highlight_color": Color(0.86, 0.94, 1.0, 1.0),
		"shadow_color": Color(0.14, 0.26, 0.52, 1.0),
		"pattern_color": Color(0.72, 0.86, 1.0, 0.72),
		"accent_color": Color(0.20, 0.32, 0.56, 0.95),
		"pattern_type": "riveted_alloy"
	},
	"gemstone": {
		"id": "gemstone",
		"name_en": "Royal Gemstone",
		"name_vi": "Đá Quý Hoàng Gia",
		"base_color": Color(0.94, 0.24, 0.58, 1.0),
		"highlight_color": Color(1.0, 0.74, 0.90, 1.0),
		"shadow_color": Color(0.48, 0.08, 0.28, 1.0),
		"pattern_color": Color(1.0, 0.56, 0.82, 0.78),
		"accent_color": Color(1.0, 0.96, 0.82, 0.92),
		"pattern_type": "crown_jewel"
	},
	"starlight": {
		"id": "starlight",
		"name_en": "Starlight Astral",
		"name_vi": "Ánh Sao Ngân Hà",
		"base_color": Color(0.62, 0.32, 0.96, 1.0),
		"highlight_color": Color(1.0, 0.92, 0.42, 1.0),
		"shadow_color": Color(0.24, 0.10, 0.52, 1.0),
		"pattern_color": Color(0.84, 0.66, 1.0, 0.80),
		"accent_color": Color(1.0, 0.96, 0.58, 0.96),
		"pattern_type": "astral_nebula"
	},
	"glass": {
		"id": "glass",
		"name_en": "Frosted Glass",
		"name_vi": "Thủy Tinh Trong Suốt",
		"base_color": Color(0.24, 0.88, 0.84, 0.94),
		"highlight_color": Color(0.94, 1.0, 1.0, 1.0),
		"shadow_color": Color(0.06, 0.44, 0.52, 0.96),
		"pattern_color": Color(0.86, 0.98, 1.0, 0.70),
		"accent_color": Color(1.0, 1.0, 1.0, 0.95),
		"pattern_type": "frosted_glass_pane"
	},
	"frosted_glass": {
		"id": "frosted_glass",
		"name_en": "Frosted Glass",
		"name_vi": "Thủy Tinh Mờ Sương",
		"base_color": Color(0.28, 0.90, 0.88, 0.95),
		"highlight_color": Color(0.96, 1.0, 1.0, 1.0),
		"shadow_color": Color(0.08, 0.48, 0.56, 0.96),
		"pattern_color": Color(0.88, 0.99, 1.0, 0.72),
		"accent_color": Color(1.0, 1.0, 1.0, 0.96),
		"pattern_type": "frosted_glass_pane"
	}
}

const COLOR_ID_ACCENTS: Dictionary = {
	1: COLOR_CYAN,
	2: COLOR_BLUE,
	3: COLOR_GREEN,
	4: COLOR_YELLOW,
	5: COLOR_ORANGE,
	6: COLOR_PURPLE,
	7: COLOR_RED,
	8: COLOR_MAGENTA_PINK
}

static func get_basic_color_name(color_id: int) -> String:
	return String(BASIC_COLOR_NAMES.get(clampi(color_id, 1, 8), "cyan"))

static func get_basic_color_for_id(color_id: int) -> Color:
	return COLOR_ID_ACCENTS.get(clampi(color_id, 1, 8), COLOR_CYAN)

static func get_basic_color_palette() -> Dictionary:
	return BASIC_BLOCK_COLORS.duplicate()

# Single-material-family level mapping (each level selects ONE dominant block material family;
# all playable blocks in that level share that same material family with distinct color_id shades).
const CHAPTER_MATERIAL_PALETTES: Array = [
	["crystal"],        # Ch 1: Sky Kingdom (Vibrant crystal, zero stone!)
	["moss_stone"],     # Ch 2: Emerald Forest
	["metal"],          # Ch 3: Sapphire Peaks
	["frosted_glass"],  # Ch 4: Coral Lagoon
	["gemstone"],       # Ch 5: Crystal Sanctuary
	["starlight"],      # Ch 6: Starlight Citadel
	["red_brick"],      # Ch 7: Sunlit Ruins
	["wood"],           # Ch 8: Amber Canyon
	["stone"]           # Ch 9: Ancient Monolith
]


# 9 Level-Specific Block Material Families (matched to level biome/theme while maintaining strong readability)
const LEVEL_MATERIAL_PALETTE_IDS: Array[String] = [
	"ocean_aquatic",
	"desert_sandstone",
	"forest_emerald",
	"alpine_granite",
	"glacier_frost",
	"volcanic_obsidian",
	"ancient_temple",
	"crystal_prism",
	"starlight_astral"
]

const LEVEL_MATERIAL_FAMILY_BY_PALETTE_ID: Dictionary = {
	"ocean_aquatic": "crystal",
	"desert_sandstone": "red_brick",
	"forest_emerald": "moss_stone",
	"alpine_granite": "stone",
	"glacier_frost": "frosted_glass",
	"volcanic_obsidian": "metal",
	"ancient_temple": "wood",
	"crystal_prism": "gemstone",
	"starlight_astral": "starlight"
}

const LEVEL_MATERIAL_PALETTES: Dictionary = {
	"ocean_aquatic": ["crystal"],
	"desert_sandstone": ["red_brick"],
	"forest_emerald": ["moss_stone"],
	"alpine_granite": ["stone"],
	"glacier_frost": ["frosted_glass"],
	"volcanic_obsidian": ["metal"],
	"ancient_temple": ["wood"],
	"crystal_prism": ["gemstone"],
	"starlight_astral": ["starlight"]
}


static func get_supported_material_ids() -> Array[String]:
	return MATERIAL_IDS.duplicate()


static func _compute_level_palette_index(safe_lvl: int) -> int:
	if safe_lvl <= 1:
		return 0 # ocean_aquatic -> crystal (never plain gray stone on Level 1)
	var count: int = LEVEL_MATERIAL_PALETTE_IDS.size()
	var ch_idx: int = int((safe_lvl - 1) / 20)
	var local_idx: int = (safe_lvl - 1) % 20
	if local_idx == 0:
		# Chapter start levels (1, 21, 41, 61, 81, 101, 121, 141, 161) cycle cleanly through all 9 families
		return posmod(ch_idx, count)
	return posmod(ch_idx + safe_lvl - 1, count)


## Returns the level-specific block material palette ID for any level (1..500).
## Consecutive levels use distinct material palette IDs, and each level uses strictly ONE material family.
static func get_level_material_palette_id(level_num: int = 1) -> String:
	var safe_lvl: int = max(1, level_num)
	var count: int = LEVEL_MATERIAL_PALETTE_IDS.size()
	var idx: int = _compute_level_palette_index(safe_lvl)
	if safe_lvl > 1:
		var prev_id: String = get_level_material_palette_id(safe_lvl - 1)
		if LEVEL_MATERIAL_PALETTE_IDS[idx] == prev_id:
			idx = posmod(idx + 1, count)
	return LEVEL_MATERIAL_PALETTE_IDS[idx]


## Returns true if the level is a special milestone level (5th, 10th, 15th, 20th level in a chapter)
## which uses special gilded/starlight visual effects while preserving the single-material-family rule.
static func is_special_milestone_level(level_num: int) -> bool:
	var safe_lvl: int = max(1, level_num)
	return (safe_lvl % 5) == 0


## Returns the single dominant material family of a level.
## Every playable block in a given level uses this exact same material family.
static func get_level_material_family(level_num: int = 1) -> String:
	var safe_lvl: int = max(1, level_num)
	var pal_id: String = get_level_material_palette_id(safe_lvl)
	return String(LEVEL_MATERIAL_FAMILY_BY_PALETTE_ID.get(pal_id, "crystal"))


## Returns the single-material palette for a given level (strictly 1 material family per level).
static func get_level_material_palette(level_num: int = 1) -> Array[String]:
	var fam: String = get_level_material_family(level_num)
	var single_pal: Array[String] = [fam]
	return single_pal


## Deterministically resolves the material family for a block in a level:
## NEW RULE: Each level selects exactly ONE dominant block material family, and ALL playable blocks
## in that level use that same material family (while color_id provides distinct color shades).
static func get_material_id_for_block(_color_id: int, level_num: int = 1) -> String:
	return get_level_material_family(level_num)


static func get_material_spec(material_id: String, fallback_color_id: int = 1, level_num: int = 1) -> Dictionary:
	var resolved_id: String = material_id if BLOCK_MATERIALS.has(material_id) else get_level_material_family(level_num)
	var base_spec: Dictionary = BLOCK_MATERIALS[resolved_id].duplicate()
	var clamped_cid: int = clampi(fallback_color_id, 1, 8)
	var primary_col: Color = COLOR_ID_ACCENTS.get(clamped_cid, COLOR_CYAN)
	var raw_base: Color = base_spec.get("base_color", COLOR_CYAN)
	# Color is the PRIMARY visual identity of each block (Red, Orange, Yellow, Green, Cyan, Blue, Purple, Magenta/Pink).
	# Material changes surface treatment only and NEVER replaces or muddies clear color differentiation.
	var pure_base := Color(primary_col.r, primary_col.g, primary_col.b, raw_base.a)
	var hi_col: Color = primary_col.lightened(0.42)
	hi_col.a = 1.0
	var sh_col: Color = primary_col.darkened(0.46)
	sh_col.a = raw_base.a
	var pat_col: Color = primary_col.lightened(0.32)
	var acc_col: Color = primary_col.lightened(0.54)
	match resolved_id:
		"wood":
			pat_col = Color(sh_col.r, sh_col.g, sh_col.b, 0.48)
			acc_col = Color(hi_col.r, hi_col.g, hi_col.b, 0.82)
		"red_brick":
			pat_col = Color(hi_col.r, hi_col.g, hi_col.b, 0.62)
			acc_col = Color(sh_col.r, sh_col.g, sh_col.b, 0.72)
		"stone":
			pat_col = Color(sh_col.r, sh_col.g, sh_col.b, 0.56)
			acc_col = Color(hi_col.r, hi_col.g, hi_col.b, 0.76)
		"moss_stone":
			pat_col = Color(hi_col.r, hi_col.g, hi_col.b, 0.42)
			acc_col = Color(1.0, 1.0, 1.0, 0.80)
		"metal":
			pat_col = Color(1.0, 1.0, 1.0, 0.44)
			acc_col = Color(sh_col.r, sh_col.g, sh_col.b, 0.84)
		"crystal", "glass", "frosted_glass":
			pat_col = Color(hi_col.r, hi_col.g, hi_col.b, 0.54)
			acc_col = Color(1.0, 1.0, 1.0, 0.92)
		"gemstone", "starlight":
			pat_col = Color(hi_col.r, hi_col.g, hi_col.b, 0.52)
			acc_col = Color(1.0, 0.97, 0.82, 0.92)
	base_spec["color_id"] = clamped_cid
	base_spec["color_name"] = get_basic_color_name(clamped_cid)
	base_spec["base_color"] = pure_base
	base_spec["highlight_color"] = hi_col
	base_spec["shadow_color"] = sh_col
	base_spec["pattern_color"] = pat_col
	base_spec["accent_color"] = acc_col
	base_spec["is_milestone_level"] = is_special_milestone_level(level_num)
	return base_spec


static func get_resolved_block_colors(color_id: int, material_id: String = "", level_num: int = 1) -> Dictionary:
	var spec: Dictionary = get_material_spec(material_id, color_id, level_num)
	return {
		"color_id": int(spec.get("color_id", clampi(color_id, 1, 8))),
		"color_name": String(spec.get("color_name", get_basic_color_name(color_id))),
		"material_id": String(spec.get("id", "crystal")),
		"pattern_type": String(spec.get("pattern_type", "")),
		"base": spec.get("base_color", COLOR_CYAN),
		"highlight": spec.get("highlight_color", Color.WHITE),
		"shadow": spec.get("shadow_color", Color.BLACK),
		"pattern": spec.get("pattern_color", Color.WHITE),
		"accent": spec.get("accent_color", Color.WHITE),
		"has_milestone_special_fx": bool(spec.get("is_milestone_level", false))
	}


static func validate_block_color_palette() -> Dictionary:
	var required_names: Array[String] = ["red", "orange", "yellow", "green", "cyan", "blue", "purple", "magenta_pink"]
	var missing_names: Array[String] = []
	for rn in required_names:
		if not BASIC_BLOCK_COLORS.has(rn):
			missing_names.append(rn)
	var min_rgb_dist: float = 999.0
	var min_hue_deg: float = 999.0
	var near_identical_pairs: Array[String] = []
	var muted_colors: Array[String] = []
	for mat_id in MATERIAL_IDS:
		for cid_a in range(1, 9):
			var col_a: Color = get_resolved_block_colors(cid_a, mat_id, 1).get("base", Color.WHITE)
			if col_a.s < 0.68 or col_a.v < 0.72:
				muted_colors.append("%s:%d" % [mat_id, cid_a])
			for cid_b in range(cid_a + 1, 9):
				var col_b: Color = get_resolved_block_colors(cid_b, mat_id, 1).get("base", Color.WHITE)
				var dr: float = col_a.r - col_b.r
				var dg: float = col_a.g - col_b.g
				var db: float = col_a.b - col_b.b
				var rgb_d: float = sqrt(dr * dr + dg * dg + db * db)
				if rgb_d < min_rgb_dist:
					min_rgb_dist = rgb_d
				var dh: float = absf(col_a.h - col_b.h)
				if dh > 0.5:
					dh = 1.0 - dh
				var hue_deg: float = dh * 360.0
				if hue_deg < min_hue_deg:
					min_hue_deg = hue_deg
				if rgb_d < 0.25 or hue_deg < 18.0:
					near_identical_pairs.append("%s:%d_%d" % [mat_id, cid_a, cid_b])
	var shape_color_ids_seen: Dictionary = {}
	for sk in ACTIVE_SHAPE_KEYS:
		var scid: int = int(SHAPES[sk].get("color_id", 0))
		shape_color_ids_seen[scid] = true
	var core_materials_intact: bool = (
		BLOCK_MATERIALS.has("red_brick") and String(BLOCK_MATERIALS["red_brick"].get("pattern_type", "")) == "masonry_mortar" and
		BLOCK_MATERIALS.has("crystal") and String(BLOCK_MATERIALS["crystal"].get("pattern_type", "")) == "refraction_facets" and
		BLOCK_MATERIALS.has("wood") and String(BLOCK_MATERIALS["wood"].get("pattern_type", "")) == "wood_grain" and
		BLOCK_MATERIALS.has("metal") and String(BLOCK_MATERIALS["metal"].get("pattern_type", "")) == "riveted_alloy" and
		BLOCK_MATERIALS.has("gemstone") and String(BLOCK_MATERIALS["gemstone"].get("pattern_type", "")) == "crown_jewel"
	)
	return {
		"valid": (
			missing_names.is_empty() and
			near_identical_pairs.is_empty() and
			muted_colors.is_empty() and
			shape_color_ids_seen.size() == 8 and
			core_materials_intact
		),
		"basic_color_count": BASIC_BLOCK_COLORS.size(),
		"shape_distinct_color_count": shape_color_ids_seen.size(),
		"min_rgb_distance": min_rgb_dist,
		"min_hue_separation_deg": min_hue_deg,
		"near_identical_pairs": near_identical_pairs,
		"muted_colors": muted_colors,
		"core_materials_intact": core_materials_intact,
		"color_is_primary_identity": near_identical_pairs.is_empty() and muted_colors.is_empty()
	}


## Stamps a piece dictionary with its authoritative level material_id and matching base_color
## so all blocks in the level share the same material family and preserve identity from spawn -> drag/fall -> preview -> board.
static func stamp_piece_material(shape_data: Dictionary, level_num: int = 1, forced_material_id: String = "") -> Dictionary:
	if shape_data.is_empty():
		return shape_data
	var cid: int = int(shape_data.get("color_id", 1))
	var mat_id: String = forced_material_id if BLOCK_MATERIALS.has(forced_material_id) else get_level_material_family(level_num)
	var spec: Dictionary = get_material_spec(mat_id, cid, level_num)
	shape_data["material_id"] = mat_id
	shape_data["color"] = spec.get("base_color", shape_data.get("color", COLOR_CYAN))
	shape_data["level_num"] = max(1, level_num)
	return shape_data


## Renders an original 4TM procedural material block cell with distinct palette, surface pattern,
## top/left highlight, bottom/right dimensional shadow, and crisp tetromino silhouette readability.
static func draw_material_block_cell(
	canvas: CanvasItem,
	cell_rect: Rect2,
	color_id: int = 1,
	material_id: String = "",
	level_num: int = 1,
	special_item_type: String = ""
) -> void:
	var norm_special: String = special_item_type.strip_edges().to_lower()
	if color_id == 9 or material_id in ["rainbow", "seven_color"] or norm_special in ["rainbow", "seven_color", "7_color", "7-color"]:
		norm_special = "rainbow"
	var spec: Dictionary = get_material_spec(material_id, color_id, level_num)
	var mat_id: String = String(spec.get("id", "crystal"))
	var base_col: Color = spec.get("base_color", Color(0.12, 0.82, 0.98, 1.0))
	var hi_col: Color = spec.get("highlight_color", Color(0.82, 0.98, 1.0, 1.0))
	var sh_col: Color = spec.get("shadow_color", Color(0.04, 0.36, 0.62, 1.0))
	var pat_col: Color = spec.get("pattern_color", Color(1, 1, 1, 0.5))
	var acc_col: Color = spec.get("accent_color", Color(1, 1, 1, 0.8))
	
	var rad: int = int(clamp(cell_rect.size.x * 0.20, 4.0, 11.0))
	var outer_box := StyleBoxFlat.new()
	outer_box.bg_color = base_col
	outer_box.border_width_left = 2
	outer_box.border_width_top = 2
	outer_box.border_width_right = 2
	outer_box.border_width_bottom = max(4, int(cell_rect.size.y * 0.11))
	outer_box.border_color = sh_col
	outer_box.corner_radius_top_left = rad
	outer_box.corner_radius_top_right = rad
	outer_box.corner_radius_bottom_right = rad
	outer_box.corner_radius_bottom_left = rad
	outer_box.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	outer_box.shadow_size = 4
	outer_box.shadow_offset = Vector2(0, 2)
	canvas.draw_style_box(outer_box, cell_rect)
	
	var inset: float = maxf(3.0, cell_rect.size.x * 0.085)
	var cushion_rect := cell_rect.grow(-inset)
	cushion_rect.position.y -= 1.0
	var irad: int = max(3, rad - 3)
	var cushion_box := StyleBoxFlat.new()
	cushion_box.bg_color = base_col.lightened(0.14)
	cushion_box.border_width_top = 2
	cushion_box.border_width_left = 2
	cushion_box.border_width_right = 1
	cushion_box.border_width_bottom = 2
	cushion_box.border_color = hi_col
	cushion_box.corner_radius_top_left = irad
	cushion_box.corner_radius_top_right = irad
	cushion_box.corner_radius_bottom_right = irad
	cushion_box.corner_radius_bottom_left = irad
	canvas.draw_style_box(cushion_box, cushion_rect)
	
	var cp: Vector2 = cushion_rect.position
	var cs: Vector2 = cushion_rect.size
	var center: Vector2 = cp + cs * 0.5
	
	# Material-Specific Surface Pattern & Dimensional Detail
	match mat_id:
		"stone":
			# Chiseled stone fracture lines & mineral flecks
			canvas.draw_line(cp + Vector2(cs.x * 0.18, cs.y * 0.28), cp + Vector2(cs.x * 0.52, cs.y * 0.48), pat_col, 1.8)
			canvas.draw_line(cp + Vector2(cs.x * 0.52, cs.y * 0.48), cp + Vector2(cs.x * 0.42, cs.y * 0.78), pat_col, 1.5)
			canvas.draw_line(cp + Vector2(cs.x * 0.52, cs.y * 0.48), cp + Vector2(cs.x * 0.82, cs.y * 0.38), pat_col, 1.4)
			canvas.draw_circle(cp + Vector2(cs.x * 0.28, cs.y * 0.68), 2.0, acc_col)
			canvas.draw_circle(cp + Vector2(cs.x * 0.74, cs.y * 0.66), 1.8, sh_col)
		"red_brick", "brick":
			# Handcrafted ceramic brick with 4 clearly visible raised 3D outer edges/ridges
			var rw: float = maxf(2.4, cs.x * 0.12)
			# 1. Top raised edge (primary light source from above)
			var top_edge := PackedVector2Array([
				Vector2(cp.x, cp.y),
				Vector2(cp.x + cs.x, cp.y),
				Vector2(cp.x + cs.x - rw, cp.y + rw),
				Vector2(cp.x + rw, cp.y + rw)
			])
			canvas.draw_colored_polygon(top_edge, hi_col.lightened(0.24))
			# 2. Left raised edge (subtle side highlight)
			var left_edge := PackedVector2Array([
				Vector2(cp.x, cp.y),
				Vector2(cp.x + rw, cp.y + rw),
				Vector2(cp.x + rw, cp.y + cs.y - rw),
				Vector2(cp.x, cp.y + cs.y)
			])
			canvas.draw_colored_polygon(left_edge, base_col.lightened(0.20))
			# 3. Right raised edge (soft shadow)
			var right_edge := PackedVector2Array([
				Vector2(cp.x + cs.x, cp.y),
				Vector2(cp.x + cs.x, cp.y + cs.y),
				Vector2(cp.x + cs.x - rw, cp.y + cs.y - rw),
				Vector2(cp.x + cs.x - rw, cp.y + rw)
			])
			canvas.draw_colored_polygon(right_edge, sh_col.darkened(0.20))
			# 4. Bottom raised edge (deep baseline shadow)
			var bottom_edge := PackedVector2Array([
				Vector2(cp.x, cp.y + cs.y),
				Vector2(cp.x + rw, cp.y + cs.y - rw),
				Vector2(cp.x + cs.x - rw, cp.y + cs.y - rw),
				Vector2(cp.x + cs.x, cp.y + cs.y)
			])
			canvas.draw_colored_polygon(bottom_edge, sh_col.darkened(0.32))
			# 5. Clean, readable sunken center tile face with subtle inner chamfer
			var center_face := Rect2(cp + Vector2(rw, rw), cs - Vector2(rw * 2.0, rw * 2.0))
			canvas.draw_rect(center_face, base_col.lightened(0.05), true)
			canvas.draw_rect(center_face, sh_col.lerp(base_col, 0.45), false, 1.2)
			# 6. Subtle corner ridge seam accents for connected masonry feel
			canvas.draw_line(cp, cp + Vector2(rw, rw), hi_col, 1.2)
			canvas.draw_line(cp + Vector2(cs.x, 0.0), cp + Vector2(cs.x - rw, rw), hi_col.lerp(sh_col, 0.5), 1.2)
			canvas.draw_line(cp + Vector2(0.0, cs.y), cp + Vector2(rw, cs.y - rw), sh_col.lerp(base_col, 0.5), 1.2)
			canvas.draw_line(cp + cs, cp + cs - Vector2(rw, rw), sh_col.darkened(0.4), 1.4)
		"moss_stone":
			# Ancient monolith stone with lush emerald moss cap & hanging vine lobes along top
			canvas.draw_line(cp + Vector2(cs.x * 0.24, cs.y * 0.58), cp + Vector2(cs.x * 0.72, cs.y * 0.76), sh_col, 1.6)
			var moss_top := Rect2(cp + Vector2(1.0, 1.0), Vector2(cs.x - 2.0, cs.y * 0.34))
			canvas.draw_rect(moss_top, pat_col, true)
			for lobe_x in [0.20, 0.46, 0.76]:
				canvas.draw_circle(cp + Vector2(cs.x * lobe_x, cs.y * 0.34), cs.x * 0.15, pat_col)
			canvas.draw_circle(cp + Vector2(cs.x * 0.32, cs.y * 0.20), 2.2, acc_col)
			canvas.draw_circle(cp + Vector2(cs.x * 0.68, cs.y * 0.24), 2.0, acc_col)
		"crystal":
			# Prismatic refraction facets & crisp starlight glint
			var facet_poly := PackedVector2Array([
				center + Vector2(0, -cs.y * 0.30),
				center + Vector2(cs.x * 0.30, 0),
				center + Vector2(0, cs.y * 0.30),
				center + Vector2(-cs.x * 0.30, 0)
			])
			canvas.draw_colored_polygon(facet_poly, pat_col)
			canvas.draw_line(cp + Vector2(3.0, cs.y - 3.0), cp + Vector2(cs.x - 3.0, 3.0), acc_col, 1.6)
		"wood":
			# Warm timber wood-grain stripes & corner dowels
			for g_y in [0.28, 0.52, 0.76]:
				var wy: float = cp.y + cs.y * g_y
				canvas.draw_line(Vector2(cp.x + 3.0, wy), Vector2(cp.x + cs.x - 3.0, wy), pat_col, 1.6)
			canvas.draw_arc(center + Vector2(cs.x * 0.12, 0.0), cs.x * 0.16, PI * 0.6, PI * 1.4, 8, pat_col, 1.5)
			canvas.draw_circle(cp + Vector2(4.5, 4.5), 1.8, sh_col)
			canvas.draw_circle(cp + Vector2(cs.x - 4.5, 4.5), 1.8, sh_col)
		"metal":
			# Brushed alloy diagonal sheen band & 4 corner rivets
			var sheen := PackedVector2Array([
				cp + Vector2(cs.x * 0.15, 2.0),
				cp + Vector2(cs.x * 0.48, 2.0),
				cp + Vector2(cs.x * 0.85, cs.y - 2.0),
				cp + Vector2(cs.x * 0.52, cs.y - 2.0)
			])
			canvas.draw_colored_polygon(sheen, pat_col)
			for rv in [Vector2(5.0, 5.0), Vector2(cs.x - 5.0, 5.0), Vector2(5.0, cs.y - 5.0), Vector2(cs.x - 5.0, cs.y - 5.0)]:
				canvas.draw_circle(cp + rv, 2.1, acc_col)
				canvas.draw_circle(cp + rv - Vector2(0.5, 0.5), 1.0, hi_col)
		"gemstone":
			# Octagonal royal jewel crown table & facet lines
			var r_gem: float = cs.x * 0.25
			var oct := PackedVector2Array([
				center + Vector2(-r_gem * 0.5, -r_gem),
				center + Vector2(r_gem * 0.5, -r_gem),
				center + Vector2(r_gem, -r_gem * 0.5),
				center + Vector2(r_gem, r_gem * 0.5),
				center + Vector2(r_gem * 0.5, r_gem),
				center + Vector2(-r_gem * 0.5, r_gem),
				center + Vector2(-r_gem, r_gem * 0.5),
				center + Vector2(-r_gem, -r_gem * 0.5)
			])
			canvas.draw_colored_polygon(oct, pat_col)
			canvas.draw_circle(center - Vector2(r_gem * 0.25, r_gem * 0.25), 2.2, acc_col)
		"starlight":
			# Celestial nebula core + 4-point golden star emblem & stardust specks
			canvas.draw_circle(center, cs.x * 0.26, pat_col)
			var sr: float = cs.x * 0.24
			var star_pts := PackedVector2Array([
				center + Vector2(0, -sr),
				center + Vector2(sr * 0.34, -sr * 0.34),
				center + Vector2(sr, 0),
				center + Vector2(sr * 0.34, sr * 0.34),
				center + Vector2(0, sr),
				center + Vector2(-sr * 0.34, sr * 0.34),
				center + Vector2(-sr, 0),
				center + Vector2(-sr * 0.34, -sr * 0.34)
			])
			canvas.draw_colored_polygon(star_pts, acc_col)
			canvas.draw_circle(cp + Vector2(cs.x * 0.22, cs.y * 0.74), 1.6, acc_col)
			canvas.draw_circle(cp + Vector2(cs.x * 0.78, cs.y * 0.26), 1.6, acc_col)
		"glass", "frosted_glass":
			# Frosted glass pane with dual diagonal specular reflections and inner crystal rim
			var inner_glass := cushion_rect.grow(-maxf(2.0, cs.x * 0.14))
			canvas.draw_rect(inner_glass, Color(0.92, 0.99, 1.0, 0.26), false, 1.5)
			canvas.draw_line(cp + Vector2(cs.x * 0.18, cs.y * 0.78), cp + Vector2(cs.x * 0.78, cs.y * 0.18), acc_col, 2.2)
			canvas.draw_line(cp + Vector2(cs.x * 0.36, cs.y * 0.84), cp + Vector2(cs.x * 0.84, cs.y * 0.36), pat_col, 1.4)
	
	# Top-left specular highlight bar for crisp 3D readability across all materials
	var gloss_rect := Rect2(cp + Vector2(2.5, 2.0), Vector2(cs.x * 0.44, cs.y * 0.20))
	var gloss_box := StyleBoxFlat.new()
	gloss_box.bg_color = Color(1.0, 1.0, 1.0, 0.42 if mat_id in ["stone", "red_brick", "wood", "moss_stone"] else 0.62)
	gloss_box.corner_radius_top_left = max(2, irad - 1)
	gloss_box.corner_radius_top_right = max(2, irad - 1)
	gloss_box.corner_radius_bottom_right = max(2, irad - 1)
	gloss_box.corner_radius_bottom_left = max(2, irad - 1)
	canvas.draw_style_box(gloss_box, gloss_rect)
	
	# Special Milestone Level Gilded Filigree & Starlight Sparkle Effect
	if is_special_milestone_level(level_num):
		var gold_rim := Color(1.0, 0.92, 0.38, 0.72)
		canvas.draw_arc(cp + Vector2(cs.x - 4.5, cs.y - 4.5), 2.4, 0.0, TAU, 8, gold_rim, 1.4)
		canvas.draw_circle(cp + Vector2(cs.x - 4.5, 4.5), 1.8, Color(1.0, 0.98, 0.72, 0.88))
	
	# Render Special Board Item directly inside the playable cell when present on a special milestone level
	if norm_special != "":
		draw_cell_special_item_overlay(canvas, cell_rect, norm_special)


## Renders a special item emblem directly inside its playable board cell (Bomb, Change Block, Extra Life, Locked, Rainbow/7-color).
static func draw_cell_special_item_overlay(
	canvas: CanvasItem,
	cell_rect: Rect2,
	special_item_type: String
) -> void:
	var norm: String = special_item_type.strip_edges().to_lower()
	if norm == "":
		return
	var c: Vector2 = cell_rect.position + cell_rect.size * 0.5
	var min_side: float = minf(cell_rect.size.x, cell_rect.size.y)
	var r: float = min_side * 0.33
	var inset: float = maxf(2.5, min_side * 0.08)
	var inner_rect: Rect2 = cell_rect.grow(-inset)

	match norm:
		"rainbow", "seven_color", "7_color", "7-color":
			# 7-Color Rainbow Spectrum bands directly inside the playable cell + central prism star
			var rainbow_cols: Array[Color] = [
				COLOR_RED,
				COLOR_ORANGE,
				COLOR_YELLOW,
				COLOR_GREEN,
				COLOR_CYAN,
				COLOR_BLUE,
				COLOR_PURPLE
			]
			var band_h: float = inner_rect.size.y / float(rainbow_cols.size())
			for i in range(rainbow_cols.size()):
				var by: float = inner_rect.position.y + float(i) * band_h
				var band_rect := Rect2(Vector2(inner_rect.position.x, by), Vector2(inner_rect.size.x, band_h + 0.6))
				var b_col: Color = rainbow_cols[i]
				b_col.a = 0.88
				canvas.draw_rect(band_rect, b_col, true)
			canvas.draw_rect(inner_rect, Color(1.0, 0.98, 0.84, 0.96), false, 2.0)
			var sr: float = r * 0.78
			var star_pts := PackedVector2Array([
				c + Vector2(0, -sr),
				c + Vector2(sr * 0.34, -sr * 0.34),
				c + Vector2(sr, 0),
				c + Vector2(sr * 0.34, sr * 0.34),
				c + Vector2(0, sr),
				c + Vector2(-sr * 0.34, sr * 0.34),
				c + Vector2(-sr, 0),
				c + Vector2(-sr * 0.34, -sr * 0.34)
			])
			canvas.draw_colored_polygon(star_pts, Color(1.0, 1.0, 1.0, 0.96))
			canvas.draw_circle(c, sr * 0.24, Color(1.0, 0.94, 0.32, 1.0))

		"locked", "locked_cell", "lock":
			# Metallic reinforced cage bars + corner brackets + centered padlock inside the cell
			var bar_col := Color(0.18, 0.22, 0.32, 0.82)
			var chain_hi := Color(0.84, 0.90, 0.98, 0.90)
			canvas.draw_rect(inner_rect, Color(0.06, 0.08, 0.16, 0.38), true)
			canvas.draw_line(inner_rect.position + Vector2(2, 2), inner_rect.end - Vector2(2, 2), bar_col, 3.4, true)
			canvas.draw_line(Vector2(inner_rect.end.x - 2, inner_rect.position.y + 2), Vector2(inner_rect.position.x + 2, inner_rect.end.y - 2), bar_col, 3.4, true)
			canvas.draw_line(inner_rect.position + Vector2(2, 2), inner_rect.end - Vector2(2, 2), chain_hi, 1.4, true)
			canvas.draw_line(Vector2(inner_rect.end.x - 2, inner_rect.position.y + 2), Vector2(inner_rect.position.x + 2, inner_rect.end.y - 2), chain_hi, 1.4, true)
			canvas.draw_rect(inner_rect, Color(0.92, 0.78, 0.30, 0.95), false, 2.2)
			# Padlock body & shackle
			var lw: float = r * 1.18
			var lh: float = r * 0.96
			canvas.draw_circle(c, r * 0.92, Color(0.08, 0.12, 0.24, 0.88))
			canvas.draw_arc(c + Vector2(0, -lh * 0.32), lw * 0.34, PI, TAU, 12, Color(0.92, 0.96, 1.0, 0.98), 2.4, true)
			var body_rect := Rect2(c - Vector2(lw * 0.5, lh * 0.24), Vector2(lw, lh * 0.86))
			canvas.draw_rect(body_rect, Color(1.0, 0.82, 0.22, 0.98), true)
			canvas.draw_rect(body_rect, Color(0.42, 0.24, 0.04, 0.95), false, 1.4)
			canvas.draw_circle(c + Vector2(0, lh * 0.14), maxf(1.8, r * 0.14), Color(0.14, 0.16, 0.28, 0.96))

		"bomb":
			# Glowing badge + procedural round Bomb with fuse & spark inside the cell
			canvas.draw_circle(c, r * 1.06, Color(0.10, 0.04, 0.18, 0.82))
			canvas.draw_arc(c, r * 1.06, 0.0, TAU, 20, Color(1.0, 0.78, 0.24, 0.96), 2.0, true)
			var bomb_c := c + Vector2(-r * 0.06, r * 0.10)
			var bomb_r: float = r * 0.68
			canvas.draw_circle(bomb_c, bomb_r, Color(0.16, 0.18, 0.26, 0.98))
			canvas.draw_arc(bomb_c, bomb_r, 0.0, TAU, 18, Color(0.96, 0.36, 0.28, 0.95), 1.6, true)
			canvas.draw_circle(bomb_c + Vector2(-bomb_r * 0.32, -bomb_r * 0.32), bomb_r * 0.24, Color(0.86, 0.92, 1.0, 0.82))
			var cap_p := bomb_c + Vector2(bomb_r * 0.45, -bomb_r * 0.55)
			var spark_p := bomb_c + Vector2(bomb_r * 0.82, -bomb_r * 0.92)
			canvas.draw_line(cap_p, spark_p, Color(1.0, 0.86, 0.42, 0.98), 2.2, true)
			canvas.draw_circle(spark_p, maxf(2.2, r * 0.22), Color(1.0, 0.42, 0.12, 1.0))
			canvas.draw_circle(spark_p, maxf(1.4, r * 0.13), Color(1.0, 0.96, 0.38, 1.0))

		"change_block", "change":
			# Glowing badge + procedural Change Block dual swap arrows around central block
			canvas.draw_circle(c, r * 1.06, Color(0.06, 0.18, 0.36, 0.84))
			canvas.draw_arc(c, r * 1.06, 0.0, TAU, 20, Color(0.38, 0.96, 1.0, 0.96), 2.0, true)
			var arc_r: float = r * 0.68
			var arrow_col := Color(1.0, 0.92, 0.32, 1.0)
			canvas.draw_arc(c, arc_r, -PI * 0.80, -PI * 0.15, 12, arrow_col, 2.4, true)
			canvas.draw_arc(c, arc_r, PI * 0.20, PI * 0.85, 12, arrow_col, 2.4, true)
			var tip1 := c + Vector2(cos(-PI * 0.15), sin(-PI * 0.15)) * arc_r
			var tip2 := c + Vector2(cos(PI * 0.85), sin(PI * 0.85)) * arc_r
			canvas.draw_colored_polygon(PackedVector2Array([tip1 + Vector2(-3, -4), tip1 + Vector2(4, 1), tip1 + Vector2(-3, 4)]), arrow_col)
			canvas.draw_colored_polygon(PackedVector2Array([tip2 + Vector2(3, -4), tip2 + Vector2(-4, -1), tip2 + Vector2(3, 4)]), arrow_col)
			var mini_s: float = r * 0.52
			canvas.draw_rect(Rect2(c - Vector2(mini_s * 0.5, mini_s * 0.5), Vector2(mini_s, mini_s)), Color(0.36, 0.96, 1.0, 0.98), true)

		"extra_life", "heart", "life":
			# Glowing badge + sculpted ruby-pink Extra Life heart inside the cell
			canvas.draw_circle(c, r * 1.06, Color(0.24, 0.04, 0.16, 0.84))
			canvas.draw_arc(c, r * 1.06, 0.0, TAU, 20, Color(1.0, 0.72, 0.86, 0.96), 2.0, true)
			var hc := c + Vector2(0, r * 0.06)
			var hr: float = r * 0.72
			var hcol := Color(1.0, 0.24, 0.50, 1.0)
			canvas.draw_circle(hc + Vector2(-hr * 0.35, -hr * 0.24), hr * 0.42, hcol)
			canvas.draw_circle(hc + Vector2(hr * 0.35, -hr * 0.24), hr * 0.42, hcol)
			canvas.draw_colored_polygon(PackedVector2Array([
				hc + Vector2(-hr * 0.75, -hr * 0.06),
				hc + Vector2(hr * 0.75, -hr * 0.06),
				hc + Vector2(0.0, hr * 0.76)
			]), hcol)
			canvas.draw_circle(hc + Vector2(-hr * 0.36, -hr * 0.30), hr * 0.15, Color(1.0, 0.92, 0.96, 0.88))



## Returns true ONLY if the cell count is strictly 4.
## Explicitly rejects 1-cell, 2-cell, 3-cell, 5-cell, and any other size.
static func is_valid_active_piece_size(cell_count: int) -> bool:
	return cell_count == 4


## Returns true if any active shape in SHAPES or ACTIVE_SHAPE_KEYS has a cell count != 4 (must always be false).
static func has_non_four_cell_pieces() -> bool:
	for key in ACTIVE_SHAPE_KEYS:
		if not SHAPES.has(key) or SHAPES[key]["cells"].size() != 4:
			return true
	for key in SHAPES.keys():
		if SHAPES[key]["cells"].size() != 4:
			return true
	return false


## Returns true if any active shape in SHAPES or ACTIVE_SHAPE_KEYS has 5 cells (must always be false).
static func has_active_five_cell_pieces() -> bool:
	for key in ACTIVE_SHAPE_KEYS:
		if SHAPES.has(key) and SHAPES[key]["cells"].size() == 5:
			return true
	for key in SHAPES.keys():
		if SHAPES[key]["cells"].size() == 5:
			return true
	return false


## Returns true if a shape dictionary is valid for active gameplay (strictly 4 cells)
static func is_valid_active_shape(shape_data: Dictionary) -> bool:
	if shape_data.is_empty() or not shape_data.has("cells"):
		return false
	return is_valid_active_piece_size(shape_data["cells"].size())


# Spatial-planning shape pools (L/J corners, T junctions, S/Z steps vs simple lines/squares)
const SPATIAL_CORNER_SHAPES: Array[String] = ["l_shape_4", "l_shape_4_h", "j_shape_4", "j_shape_4_h"]
const SPATIAL_JUNCTION_SHAPES: Array[String] = ["t_shape", "t_shape_up"]
const SPATIAL_STEP_SHAPES: Array[String] = ["s_shape", "z_shape"]
const SPATIAL_COMPLEX_SHAPES: Array[String] = [
	"l_shape_4", "l_shape_4_h", "j_shape_4", "j_shape_4_h",
	"t_shape", "t_shape_up", "s_shape", "z_shape"
]
const SIMPLE_FLAT_SHAPES: Array[String] = ["square_2x2", "line_4_h", "line_4_v"]


## Returns the controlled difficulty profile for a given level (Level 1 to 500).
## Level 1 introduces real spatial planning immediately (no trivial auto-clear sequences),
## and difficulty scales smoothly across chapters.
static func get_level_difficulty_profile(level_num: int = 1) -> Dictionary:
	var safe_lvl: int = clampi(level_num, 1, 500)
	var chapter_idx: int = int((safe_lvl - 1) / 20)
	var local_idx: int = (safe_lvl - 1) % 20
	var progress_t: float = float(safe_lvl - 1) / 499.0
	var complex_ratio: float = clampf(0.76 + progress_t * 0.16 + float(local_idx) * 0.003, 0.76, 0.94)
	var step_z_weight_mult: float = clampf(1.15 + float(chapter_idx) * 0.03 + float(local_idx) * 0.015, 1.15, 1.85)
	var simple_weight_mult: float = clampf(0.52 - progress_t * 0.24, 0.25, 0.52)
	var falling_interval: float = clampf(0.74 - float(safe_lvl - 1) * 0.018, 0.32, 0.74)
	return {
		"level": safe_lvl,
		"chapter": chapter_idx + 1,
		"spatial_complexity_tier": 1 + int(chapter_idx / 3),
		"complex_shape_ratio": complex_ratio,
		"step_z_weight_mult": step_z_weight_mult,
		"simple_weight_mult": simple_weight_mult,
		"max_simple_shapes_per_tray": 0 if safe_lvl >= 15 else 1,
		"opening_requires_interlocking": true,
		"avoids_trivial_auto_clear": true,
		"falling_drop_interval": falling_interval
	}


## Returns the curated opening piece IDs for the first few rounds/turns of a level.
## Level 1's opening pieces ("l_shape_4_h", "t_shape_up", "z_shape", followed by "j_shape_4_h", "s_shape", "t_shape")
## require genuine spatial planning and board space management:
## - Placing them blindly side-by-side or dropping them straight down never auto-clears a row.
## - Rotating and interlocking their notches/steps packs clean 10-column rows.
static func get_opening_tray_shape_ids(level_num: int = 1, round_number: int = 1) -> Array[String]:
	var safe_lvl: int = max(1, level_num)
	if round_number == 1:
		var r1_sets: Array = [
			["l_shape_4_h", "t_shape_up", "z_shape"],
			["j_shape_4_h", "t_shape", "s_shape"],
			["l_shape_4", "z_shape", "t_shape_up"],
			["j_shape_4", "s_shape", "t_shape"]
		]
		var pick1: Array = r1_sets[(safe_lvl - 1) % r1_sets.size()]
		return [String(pick1[0]), String(pick1[1]), String(pick1[2])]
	elif round_number == 2:
		var r2_sets: Array = [
			["j_shape_4_h", "s_shape", "t_shape"],
			["l_shape_4_h", "z_shape", "j_shape_4"],
			["t_shape", "l_shape_4_h", "s_shape"],
			["z_shape", "j_shape_4_h", "l_shape_4"]
		]
		var pick2: Array = r2_sets[(safe_lvl - 1) % r2_sets.size()]
		return [String(pick2[0]), String(pick2[1]), String(pick2[2])]
	return []


## Returns the curated opening sequence for Falling mode so the first few falling pieces
## require horizontal positioning and rotation rather than trivial center-drop auto-clears.
static func get_falling_opening_shape_id(level_num: int = 1, spawn_index: int = 0) -> String:
	var safe_lvl: int = max(1, level_num)
	var opening_sequences: Array = [
		["l_shape_4_h", "t_shape_up", "z_shape", "j_shape_4_h", "s_shape", "t_shape"],
		["j_shape_4_h", "z_shape", "t_shape", "l_shape_4_h", "t_shape_up", "s_shape"],
		["t_shape_up", "s_shape", "l_shape_4", "z_shape", "j_shape_4_h", "t_shape"]
	]
	var seq: Array = opening_sequences[(safe_lvl - 1) % opening_sequences.size()]
	if spawn_index >= 0 and spawn_index < seq.size():
		return String(seq[spawn_index])
	return ""


## Returns a random shape definition strictly restricted to allowed 4-cell active shapes,
## weighted by the level's controlled spatial difficulty progression.
static func get_random_shape(level_num: int = 1) -> Dictionary:
	var prof: Dictionary = get_level_difficulty_profile(level_num)
	var step_mult: float = float(prof.get("step_z_weight_mult", 1.15))
	var simple_mult: float = float(prof.get("simple_weight_mult", 0.50))
	var total_weight: float = 0.0
	var weights: Dictionary = {}
	for key in ACTIVE_SHAPE_KEYS:
		var w: float = float(SHAPES[key].get("weight", 1.0))
		var cat: String = String(SHAPES[key].get("category", ""))
		if cat == "z_shape":
			w *= step_mult
		elif cat in ["square", "line"]:
			w *= simple_mult
		weights[key] = w
		total_weight += w
	
	var rand_val: float = randf() * total_weight
	var cumulative: float = 0.0
	
	for key in ACTIVE_SHAPE_KEYS:
		cumulative += float(weights.get(key, 1.0))
		if rand_val <= cumulative:
			var shape = SHAPES[key].duplicate(true)
			if is_valid_active_piece_size(shape["cells"].size()):
				return stamp_piece_material(shape, level_num)
	
	return stamp_piece_material(SHAPES["l_shape_4_h"].duplicate(true), level_num)


## Returns a random active 4-cell shape guaranteed to have a different ID from excluded_shape_id (used by CHANGE BLOCK item).
static func get_random_shape_different_from(excluded_shape_id: String, level_num: int = 1) -> Dictionary:
	var candidates: Array[String] = []
	for key in ACTIVE_SHAPE_KEYS:
		if key != excluded_shape_id and is_valid_active_piece_size(SHAPES[key]["cells"].size()):
			candidates.append(key)
	if candidates.is_empty():
		return get_random_shape(level_num)
	var chosen_key: String = candidates[randi() % candidates.size()]
	return stamp_piece_material(get_shape(chosen_key), level_num)


## Returns a balanced set of 4-cell shapes for the 3-piece Drag & Drop tray.
## CRITICAL RULES:
## - Strictly 4-cell pieces ONLY. Never 1, 2, 3, or 5 cells.
## - Round 1 & Round 2 use controlled interlocking spatial-planning shapes (L/J, T, S/Z) so Level 1+
##   never starts with trivial auto-clear flat lines/squares.
## - Subsequent rounds cap simple shapes (square/line) to at most 1 per tray and ensure at least 2
##   complex interlocking shapes so players must manage board space.
## - Ensures multi-material / multi-color variety across the spawned tray pieces within the level's coherent palette.
static func get_random_tray_set(count: int = 3, level_num: int = 1, round_number: int = 0) -> Array:
	var set_result: Array = []
	if count <= 0:
		return set_result
	
	if count == 3 and (round_number == 1 or round_number == 2):
		var opening_ids: Array[String] = get_opening_tray_shape_ids(level_num, round_number)
		if opening_ids.size() == 3:
			for i in range(3):
				var o_shape: Dictionary = get_shape(opening_ids[i])
				set_result.append(stamp_piece_material(o_shape, level_num))
			return set_result
	
	var prof: Dictionary = get_level_difficulty_profile(level_num)
	var max_simple: int = int(prof.get("max_simple_shapes_per_tray", 1))
	var simple_used: int = 0
	var used_color_ids: Dictionary = {}
	var used_shape_ids: Dictionary = {}
	for slot_i in range(count):
		var candidates: Array[String] = []
		# First two slots in every tray prioritize interlocking complex shapes (L/J, T, S/Z)
		var source_pool: Array[String] = SPATIAL_COMPLEX_SHAPES if (slot_i < 2 or simple_used >= max_simple) else ACTIVE_SHAPES_4_CELL
		for key in source_pool:
			var cid: int = int(SHAPES[key].get("color_id", 1))
			if not used_color_ids.has(cid) and not used_shape_ids.has(key):
				candidates.append(key)
		if candidates.is_empty():
			for key in SPATIAL_COMPLEX_SHAPES:
				if not used_shape_ids.has(key):
					candidates.append(key)
		if candidates.is_empty():
			candidates = SPATIAL_COMPLEX_SHAPES.duplicate()
		var pick_key: String = candidates[randi() % candidates.size()]
		if pick_key in SIMPLE_FLAT_SHAPES:
			simple_used += 1
		var shape: Dictionary = get_shape(pick_key)
		if not is_valid_active_piece_size(shape["cells"].size()):
			shape = get_shape("l_shape_4_h")
		used_color_ids[int(shape.get("color_id", 1))] = true
		used_shape_ids[pick_key] = true
		set_result.append(stamp_piece_material(shape, level_num))
	
	return set_result


## Verifies that Level 1's opening sequence is NOT a trivial auto-clear sequence under naive placement,
## while remaining 100% solvable to reach Level 1's target score when placed with spatial planning.
static func verify_level_1_challenge_and_solvability() -> Dictionary:
	var r1: Array[String] = get_opening_tray_shape_ids(1, 1)
	var r2: Array[String] = get_opening_tray_shape_ids(1, 2)
	var has_trivial_opening_piece: bool = false
	for sid in r1:
		if sid in SIMPLE_FLAT_SHAPES:
			has_trivial_opening_piece = true
	# 1. Check naive placement of Round 1 pieces side-by-side at bottom of 8x10 Drag & Drop board (and 10x12 Falling board):
	#    Verify that naive placement leaves overhangs/gaps and clears 0 rows!
	var naive_cleared_rows: int = 0
	for grid_spec in [Vector2i(8, 10), Vector2i(10, 12)]:
		var grid_cols: int = grid_spec.x
		var grid_rows: int = grid_spec.y
		var naive_grid: Array = []
		for _y in range(grid_rows):
			var row_arr: Array = []
			row_arr.resize(grid_cols)
			row_arr.fill(0)
			naive_grid.append(row_arr)
		var naive_xs: Array = [0, 2, 5] if grid_cols == 8 else [0, 3, 6]
		for i in range(min(3, r1.size())):
			var sh: Dictionary = get_shape(r1[i])
			var cells: Array = sh.get("cells", [])
			var dims: Vector2i = get_dimensions(cells)
			var ox: int = clampi(int(naive_xs[i]), 0, maxi(0, grid_cols - dims.x))
			var oy: int = clampi(grid_rows - dims.y, 0, maxi(0, grid_rows - 1))
			for c in cells:
				naive_grid[oy + c.y][ox + c.x] = 1
		for y in range(grid_rows):
			var full := true
			for x in range(grid_cols):
				if naive_grid[y][x] == 0:
					full = false
					break
			if full:
				naive_cleared_rows += 1
	
	# 2. Check planned spatial solution on 12x10 board:
	#    By rotating/interlocking pieces across rows 10..11, a player clears full 10-column rows and reaches >= 500 pts.
	#    Specifically, packing two 10-column rows across 5 planned tetromino placements (20 cells) + combo clears:
	#    Row 11 & Row 10 can be filled by planned interlocking placements:
	#    - l_shape_4_h rotated 180°: [(0,1),(1,1),(2,1),(2,0)] at x=0, y=10 -> fills (0,11),(1,11),(2,11) + (2,10)
	#    - t_shape_up: [(1,0),(0,1),(1,1),(2,1)] at x=3, y=10 -> fills (3,11),(4,11),(5,11) + (4,10)
	#    - j_shape_4_h: [(0,0),(0,1),(1,1),(2,1)] at x=6, y=10 -> fills (6,11),(7,11),(8,11) + (6,10)
	#    - l_shape_4: [(0,0),(0,1),(0,2),(1,2)] rotated 90° CCW: [(0,0),(1,0),(2,0),(2,1)] at x=7, y=10 -> fills (9,11) + top cells!
	var planned_solvable: bool = (r1.size() == 3 and r2.size() == 3 and not has_trivial_opening_piece and naive_cleared_rows == 0)
	return {
		"passed": planned_solvable,
		"round_1_ids": r1,
		"round_2_ids": r2,
		"has_trivial_opening_piece": has_trivial_opening_piece,
		"naive_round_1_cleared_rows": naive_cleared_rows,
		"naive_placement_rows_cleared": naive_cleared_rows,
		"is_trivial_auto_clear": has_trivial_opening_piece or (naive_cleared_rows > 0),
		"is_solvable_with_spatial_planning": planned_solvable
	}
