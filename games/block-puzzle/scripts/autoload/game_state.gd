class_name GameStateManager
extends Node

## GameStateManager — Central game state, localization, Modern special-item inventory, Daily Gift Lucky Wheel & 500-level progression manager
## Manages:
##   1. 2 × 2 Architecture:
##      - Game Mode: Classic (row clear only, NO special items) vs Modern (row + col clear, 3 special items)
##      - Play Style: Falling (falling piece + Next preview only + gravity) vs Drag & Drop (3-piece tray + no gravity)
##   2. Active Piece Rule:
##      - Strictly 4-cell pieces ONLY on the 12×10 board.
##   3. Single-Language Localization System:
##      - Default language: "en" (English). Switchable to "vi" (natural Vietnamese).
##      - Never displays bilingual text simultaneously; persisted locally.
##   4. Modern Special Items (ONLY in Modern Mode):
##      - "bomb"         (BOMB)
##      - "change_block" (CHANGE BLOCK)
##      - "extra_life"   (EXTRA LIFE)
##   5. Daily Gift = Lucky Wheel:
##      - 1 free spin per calendar day (persisted via last_daily_gift_date & daily_reward_claimed).
##      - Grants ONLY Modern special items (Bomb, Change Block, Extra Life) in quantities of 1–3.
##   6. Real 500-Level Progression, Milestones & Chapter Environments:
##      - 500 levels across 25 chapters with special milestones (⭐ Star, 🎁 Reward, 🏆 Major, 🔒 Chapter Unlock)
##        and 6 atmospheric chapter environments.

enum GameMode {
	CLASSIC,                ## Classic Game Mode: horizontal row clearing only, NO special items/boosters
	MODERN_DRAG_AND_DROP    ## Modern Game Mode: row + column clearing, HAS special items/boosters (aliased as MODERN)
}

const MODERN: int = GameMode.MODERN_DRAG_AND_DROP

enum PlayStyle {
	FALLING,                ## Falling Play Style: pieces fall from top, ONLY Next preview shown, gravity on row clear
	DRAG_AND_DROP           ## Drag & Drop Play Style: 3-piece tray, replenish 3 pieces when empty, no gravity
}

enum State {
	MENU,                   ## In main menu / level map / mode & play style selection
	PLAYING,                ## Active gameplay session
	PAUSED,                 ## Game paused with overlay
	GAME_OVER               ## Session completed (either Level Complete or Out of Moves)
}

signal state_changed(new_state: State, previous_state: State)
signal mode_changed(new_mode: GameMode)
signal play_style_changed(new_style: PlayStyle)
signal language_changed(new_lang: String)
signal game_started(mode: GameMode)
signal combination_started(mode: GameMode, style: PlayStyle)
signal game_paused(is_paused: bool)
signal game_over_triggered(final_score: int, final_level: int, stats: Dictionary)
signal score_updated(new_score: int, points_added: int)
signal level_updated(new_level: int, lines_cleared: int)
signal combo_updated(combo_count: int)
signal audio_settings_changed(music_on: bool, sfx_on: bool)
signal voice_settings_changed(voice_mode: String)
signal progression_updated(unlocked_level: int, total_stars: int, coins: int)
signal level_completed(completed_level: int, stars_earned: int, reward_coins: int)
signal reward_claimed(reward_data: Dictionary)
signal special_item_discovered(item_id: String, new_quantity: int)
signal special_item_inventory_changed(inventory: Dictionary)
signal lucky_wheel_spun(result: Dictionary)
signal energy_changed(current_energy: int, max_energy: int)
signal rewarded_ad_completed(reward_type: String, amount: int)

const PROGRESSION_SAVE_PATH: String = "user://block_puzzle_4tm_progression.cfg"
const TOTAL_LEVELS: int = 500
const LEVELS_PER_PAGE: int = 8
const MAX_ENERGY: int = 24
const ENERGY_REGEN_INTERVAL_SEC: int = 3600
const RewardedAdScript = preload("res://scripts/core/rewarded_ad_interface.gd")
const MapTheme = preload("res://scripts/map_core/map_theme.gd")
const MapRoute = preload("res://scripts/map_core/map_route.gd")
const MapNode = preload("res://scripts/map_core/map_node.gd")
const MapPage = preload("res://scripts/map_core/map_page.gd")
const MapLayoutGenerator = preload("res://scripts/map_core/map_layout_generator.gd")
const MapData = preload("res://scripts/map_core/map_data.gd")
const BlockPuzzleMapConfig = preload("res://scripts/map_core/block_puzzle_map_config.gd")
const BlockPuzzleMapConfigScript = BlockPuzzleMapConfig

var map_data: MapData = null

# Exact 3 Modern Special Items (NO Rotate item)
const MODERN_ITEM_TYPES: Array[String] = ["bomb", "change_block", "extra_life"]
const DEFAULT_MODERN_INVENTORY: Dictionary = {
	"bomb": 2,
	"change_block": 2,
	"extra_life": 1
}

# 8-Slice Daily Gift Lucky Wheel Configuration — Exact Interleaved 8-Wedge Sequence:
#   0. Bomb ×1
#   1. Lucky Next Time (Text-Only)
#   2. Change Block ×1
#   3. Lucky Next Time (Text-Only)
#   4. Extra Life ×1
#   5. Lucky Next Time (Text-Only)
#   6. Spin Again ×1 (Positioned Between Lucky Next Time 5 and 7)
#   7. Lucky Next Time (Text-Only)
const LUCKY_WHEEL_SLICES: Array = [
	{"index": 0, "reward_type": "bomb",            "amount": 1, "icon": "bomb",            "label_en": "BOMB",            "label_vi": "BOM",                      "desc_en": "Clear a 3×3 area",           "desc_vi": "Xóa vùng 3×3 trên bảng",          "short_text": "×1", "color": Color(0.92, 0.20, 0.32, 1.0)},
	{"index": 1, "reward_type": "lucky_next_time", "amount": 0, "icon": "lucky_next_time", "label_en": "Lucky Next Time", "label_vi": "Chúc bạn may mắn lần sau", "desc_en": "No reward this time",        "desc_vi": "Chúc bạn may mắn lần sau",        "short_text": "—",  "color": Color(0.24, 0.22, 0.52, 1.0)},
	{"index": 2, "reward_type": "change_block",    "amount": 1, "icon": "change_block",    "label_en": "CHANGE BLOCK",    "label_vi": "ĐỔI KHỐI",                 "desc_en": "Replace one selected block", "desc_vi": "Đổi một khối đang chọn",          "short_text": "×1", "color": Color(0.12, 0.54, 0.94, 1.0)},
	{"index": 3, "reward_type": "lucky_next_time", "amount": 0, "icon": "lucky_next_time", "label_en": "Lucky Next Time", "label_vi": "Chúc bạn may mắn lần sau", "desc_en": "No reward this time",        "desc_vi": "Chúc bạn may mắn lần sau",        "short_text": "—",  "color": Color(0.30, 0.20, 0.56, 1.0)},
	{"index": 4, "reward_type": "extra_life",      "amount": 1, "icon": "extra_life",      "label_en": "EXTRA LIFE",      "label_vi": "MẠNG THÊM",                "desc_en": "Recover after Game Over",    "desc_vi": "Hồi phục sau khi thua",           "short_text": "×1", "color": Color(0.08, 0.74, 0.44, 1.0)},
	{"index": 5, "reward_type": "lucky_next_time", "amount": 0, "icon": "lucky_next_time", "label_en": "Lucky Next Time", "label_vi": "Chúc bạn may mắn lần sau", "desc_en": "No reward this time",        "desc_vi": "Chúc bạn may mắn lần sau",        "short_text": "—",  "color": Color(0.22, 0.24, 0.48, 1.0)},
	{"index": 6, "reward_type": "spin_again",      "amount": 1, "icon": "spin_again",      "label_en": "SPIN AGAIN",      "label_vi": "QUAY LẠI LẦN NỮA",         "desc_en": "Get 1 extra free spin",      "desc_vi": "Nhận thêm 1 lượt quay miễn phí",  "short_text": "+1", "color": Color(0.95, 0.65, 0.12, 1.0)},
	{"index": 7, "reward_type": "lucky_next_time", "amount": 0, "icon": "lucky_next_time", "label_en": "Lucky Next Time", "label_vi": "Chúc bạn may mắn lần sau", "desc_en": "No reward this time",        "desc_vi": "Chúc bạn may mắn lần sau",        "short_text": "—",  "color": Color(0.28, 0.22, 0.52, 1.0)}
]

# 12 Distinct World Biome Archetypes for the 25-Chapter 500-Level World Journey
const CHAPTER_ENVIRONMENTS: Array[Dictionary] = [
	{
		"id": "sky_clouds",
		"name_en": "Sky Kingdom",
		"name_vi": "Vương Quốc Mây Trời",
		"biome_type": "sky_archipelago",
		"terrain_layout": "floating_citadel_islands",
		"waterway_type": "cloud_cascade_river",
		"road_style": "golden_cobblestone",
		"vegetation_type": "sky_blossom_pines",
		"architecture_type": "sky_citadel",
		"ambient_particle_type": "golden_motes",
		"bg_top": Color(0.14, 0.48, 0.94, 0.98),
		"bg_bot": Color(0.38, 0.76, 0.98, 0.96),
		"island_col": Color(0.28, 0.78, 0.52, 0.92),
		"cliff_col": Color(0.36, 0.44, 0.64, 0.96),
		"water_col": Color(0.22, 0.78, 0.98, 0.84),
		"path_outer": Color(0.96, 0.78, 0.28, 0.95),
		"path_inner": Color(1.0, 0.96, 0.76, 0.98)
	},
	{
		"id": "emerald_forest",
		"name_en": "Emerald Forest",
		"name_vi": "Rừng Ngọc Bích",
		"biome_type": "ancient_woodland_valley",
		"terrain_layout": "river_valley_terraces",
		"waterway_type": "meandering_brook",
		"road_style": "mossy_flagstone_trail",
		"vegetation_type": "giant_emerald_oaks",
		"architecture_type": "woodland_shrine",
		"ambient_particle_type": "forest_fireflies",
		"bg_top": Color(0.06, 0.34, 0.24, 0.98),
		"bg_bot": Color(0.18, 0.58, 0.36, 0.96),
		"island_col": Color(0.22, 0.70, 0.36, 0.92),
		"cliff_col": Color(0.34, 0.28, 0.22, 0.96),
		"water_col": Color(0.12, 0.76, 0.74, 0.86),
		"path_outer": Color(0.84, 0.64, 0.24, 0.95),
		"path_inner": Color(0.96, 0.90, 0.64, 0.98)
	},
	{
		"id": "sapphire_mountain",
		"name_en": "Sapphire Peaks",
		"name_vi": "Đỉnh Núi Lam Ngọc",
		"biome_type": "alpine_glacier_ridge",
		"terrain_layout": "stepped_cliff_switchbacks",
		"waterway_type": "alpine_waterfall_gorge",
		"road_style": "carved_mountain_stairs",
		"vegetation_type": "snowy_alpine_firs",
		"architecture_type": "alpine_watchtower",
		"ambient_particle_type": "snow_sparkles",
		"bg_top": Color(0.12, 0.22, 0.56, 0.98),
		"bg_bot": Color(0.30, 0.52, 0.86, 0.96),
		"island_col": Color(0.46, 0.66, 0.92, 0.92),
		"cliff_col": Color(0.24, 0.34, 0.56, 0.96),
		"water_col": Color(0.36, 0.86, 1.0, 0.86),
		"path_outer": Color(0.64, 0.90, 1.0, 0.95),
		"path_inner": Color(0.94, 0.98, 1.0, 0.98)
	},
	{
		"id": "coral_ocean",
		"name_en": "Ocean Lagoon",
		"name_vi": "Vịnh Đại Dương",
		"biome_type": "tropical_coral_atoll",
		"terrain_layout": "island_hopping_lagoon",
		"waterway_type": "turquoise_sea_channels",
		"road_style": "sandy_boardwalk_bridge",
		"vegetation_type": "tropical_palms_corals",
		"architecture_type": "harbor_lighthouse",
		"ambient_particle_type": "sea_foam_bubbles",
		"bg_top": Color(0.04, 0.42, 0.68, 0.98),
		"bg_bot": Color(0.10, 0.74, 0.84, 0.96),
		"island_col": Color(0.96, 0.84, 0.50, 0.92),
		"cliff_col": Color(0.68, 0.48, 0.28, 0.96),
		"water_col": Color(0.06, 0.66, 0.86, 0.88),
		"path_outer": Color(0.96, 0.72, 0.28, 0.95),
		"path_inner": Color(1.0, 0.96, 0.82, 0.98)
	},
	{
		"id": "crystal_landscape",
		"name_en": "Crystal Sanctuary",
		"name_vi": "Thánh Địa Pha Lê",
		"biome_type": "subterranean_crystal_cavern",
		"terrain_layout": "cavern_crystal_ledges",
		"waterway_type": "bioluminescent_stream",
		"road_style": "prismatic_quartz_causeway",
		"vegetation_type": "crystal_spires_fungi",
		"architecture_type": "crystal_monolith_gate",
		"ambient_particle_type": "prism_Runes",
		"bg_top": Color(0.28, 0.10, 0.52, 0.98),
		"bg_bot": Color(0.52, 0.22, 0.78, 0.96),
		"island_col": Color(0.68, 0.36, 0.92, 0.92),
		"cliff_col": Color(0.32, 0.14, 0.52, 0.96),
		"water_col": Color(0.28, 0.92, 0.98, 0.84),
		"path_outer": Color(0.98, 0.68, 0.96, 0.95),
		"path_inner": Color(0.76, 0.98, 1.0, 0.98)
	},
	{
		"id": "starlight_night",
		"name_en": "Starlight Night",
		"name_vi": "Đêm Ánh Sao",
		"biome_type": "celestial_observatory_peaks",
		"terrain_layout": "starlight_sanctuary_terraces",
		"waterway_type": "astral_nebula_river",
		"road_style": "starlight_marble_road",
		"vegetation_type": "luminous_willow_trees",
		"architecture_type": "astral_observatory",
		"ambient_particle_type": "stardust_sparks",
		"bg_top": Color(0.05, 0.08, 0.26, 0.98),
		"bg_bot": Color(0.16, 0.20, 0.52, 0.96),
		"island_col": Color(0.26, 0.38, 0.76, 0.92),
		"cliff_col": Color(0.14, 0.18, 0.42, 0.96),
		"water_col": Color(0.38, 0.52, 0.96, 0.84),
		"path_outer": Color(1.0, 0.88, 0.30, 0.95),
		"path_inner": Color(0.84, 0.94, 1.0, 0.98)
	},
	{
		"id": "amber_canyon",
		"name_en": "Amber Canyon",
		"name_vi": "Hẻm Núi Hổ Phách",
		"biome_type": "red_rock_canyon_mesa",
		"terrain_layout": "canyon_mesa_bridges",
		"waterway_type": "canyon_rapids_river",
		"road_style": "timber_trestle_switchback",
		"vegetation_type": "desert_agave_pines",
		"architecture_type": "canyon_fortress_arch",
		"ambient_particle_type": "warm_sun_motes",
		"bg_top": Color(0.58, 0.24, 0.14, 0.98),
		"bg_bot": Color(0.88, 0.48, 0.22, 0.96),
		"island_col": Color(0.84, 0.44, 0.22, 0.92),
		"cliff_col": Color(0.48, 0.20, 0.10, 0.96),
		"water_col": Color(0.16, 0.72, 0.78, 0.84),
		"path_outer": Color(0.98, 0.82, 0.42, 0.95),
		"path_inner": Color(1.0, 0.94, 0.76, 0.98)
	},
	{
		"id": "sunlit_ruins",
		"name_en": "Sunlit Temple Ruins",
		"name_vi": "Thánh Điện Cổ Đại",
		"biome_type": "ancient_temple_valley",
		"terrain_layout": "sunken_courtyard_terraces",
		"waterway_type": "sacred_aqueduct_canal",
		"road_style": "chiseled_temple_causeway",
		"vegetation_type": "overgrown_banyan_vines",
		"architecture_type": "stepped_pyramid_temple",
		"ambient_particle_type": "golden_pollen",
		"bg_top": Color(0.18, 0.44, 0.42, 0.98),
		"bg_bot": Color(0.42, 0.72, 0.54, 0.96),
		"island_col": Color(0.56, 0.74, 0.42, 0.92),
		"cliff_col": Color(0.42, 0.46, 0.34, 0.96),
		"water_col": Color(0.20, 0.82, 0.72, 0.85),
		"path_outer": Color(0.92, 0.78, 0.38, 0.95),
		"path_inner": Color(0.98, 0.94, 0.78, 0.98)
	},
	{
		"id": "misty_bamboo_highlands",
		"name_en": "Jade Highland Falls",
		"name_vi": "Cao Nguyên Ngọc Bích",
		"biome_type": "jade_karst_waterfalls",
		"terrain_layout": "terraced_jade_valleys",
		"waterway_type": "twin_jade_waterfalls",
		"road_style": "arched_stone_bridges",
		"vegetation_type": "jade_bamboo_blossoms",
		"architecture_type": "pagoda_sanctuary",
		"ambient_particle_type": "blossom_petals",
		"bg_top": Color(0.10, 0.42, 0.48, 0.98),
		"bg_bot": Color(0.28, 0.74, 0.68, 0.96),
		"island_col": Color(0.26, 0.76, 0.54, 0.92),
		"cliff_col": Color(0.22, 0.42, 0.44, 0.96),
		"water_col": Color(0.32, 0.92, 0.86, 0.86),
		"path_outer": Color(0.94, 0.84, 0.48, 0.95),
		"path_inner": Color(0.98, 0.96, 0.84, 0.98)
	},
	{
		"id": "crimson_autumn_woods",
		"name_en": "Maple Crown Valley",
		"name_vi": "Thung Lũng Lá Phong",
		"biome_type": "autumn_maple_highlands",
		"terrain_layout": "winding_creek_hills",
		"waterway_type": "amber_mirror_creek",
		"road_style": "cobblestone_woodland_road",
		"vegetation_type": "crimson_golden_maples",
		"architecture_type": "windmill_watchtower",
		"ambient_particle_type": "autumn_leaves",
		"bg_top": Color(0.46, 0.18, 0.32, 0.98),
		"bg_bot": Color(0.84, 0.44, 0.28, 0.96),
		"island_col": Color(0.78, 0.48, 0.24, 0.92),
		"cliff_col": Color(0.42, 0.24, 0.20, 0.96),
		"water_col": Color(0.24, 0.68, 0.88, 0.85),
		"path_outer": Color(0.98, 0.80, 0.36, 0.95),
		"path_inner": Color(1.0, 0.94, 0.78, 0.98)
	},
	{
		"id": "glacial_aurora_fjord",
		"name_en": "Aurora Fjord",
		"name_vi": "Vịnh Băng Cực Quang",
		"biome_type": "arctic_aurora_fjord",
		"terrain_layout": "ice_shelf_peninsulas",
		"waterway_type": "glacial_fjord_sound",
		"road_style": "frost_crystal_causeway",
		"vegetation_type": "frosted_boreal_spruces",
		"architecture_type": "ice_crown_citadel",
		"ambient_particle_type": "aurora_sparks",
		"bg_top": Color(0.06, 0.26, 0.46, 0.98),
		"bg_bot": Color(0.18, 0.66, 0.76, 0.96),
		"island_col": Color(0.58, 0.84, 0.96, 0.92),
		"cliff_col": Color(0.24, 0.46, 0.68, 0.96),
		"water_col": Color(0.12, 0.56, 0.82, 0.88),
		"path_outer": Color(0.52, 0.98, 0.88, 0.95),
		"path_inner": Color(0.92, 1.0, 0.98, 0.98)
	},
	{
		"id": "golden_horizon_citadel",
		"name_en": "Solar Crown Sanctuary",
		"name_vi": "Thánh Điện Thái Dương",
		"biome_type": "radiant_celestial_capital",
		"terrain_layout": "grand_acropolis_plateaus",
		"waterway_type": "golden_fountain_cascades",
		"road_style": "royal_gilded_avenue",
		"vegetation_type": "sunburst_laurel_trees",
		"architecture_type": "grand_solar_palace",
		"ambient_particle_type": "solar_sparkles",
		"bg_top": Color(0.36, 0.20, 0.62, 0.98),
		"bg_bot": Color(0.86, 0.52, 0.26, 0.96),
		"island_col": Color(0.42, 0.76, 0.56, 0.92),
		"cliff_col": Color(0.46, 0.36, 0.58, 0.96),
		"water_col": Color(0.32, 0.84, 0.96, 0.86),
		"path_outer": Color(1.0, 0.86, 0.28, 0.96),
		"path_inner": Color(1.0, 0.98, 0.82, 0.99)
	}
]

var current_state: State = State.MENU
# First-run default selection: CLASSIC + FALLING
var current_mode: GameMode = GameMode.CLASSIC
var current_play_style: PlayStyle = PlayStyle.FALLING
var _play_style_explicit: bool = false
var current_language: String = "en"

var score: int = 0
var high_score: int = 0
var level: int = 1
var active_level: int = 1
var lines_cleared_total: int = 0
var combo_count: int = 0
var session_stats: Dictionary = {}
var level_completed_in_session: bool = false

# Modern Special-Item Inventory & Discovery Configuration
var special_item_inventory: Dictionary = {
	"bomb": 2,
	"change_block": 2,
	"extra_life": 1
}
var persistent_bonus_items: Dictionary = {
	"bomb": 0,
	"change_block": 0,
	"extra_life": 0
}
var special_item_discovery_chance: float = 0.25
var moves_since_last_discovery: int = 0

# Real Level Progression & Daily Gift State (Persisted Locally, Levels 1..500)
var highest_unlocked_level: int = 1
var selected_map_level: int = 1
var newly_unlocked_level: int = 0
var last_completed_level: int = 0
var completed_levels: Dictionary = {}
var level_stars: Dictionary = {}
var total_stars: int = 0
var coins: int = 250
var daily_reward_claimed: bool = false
var last_daily_gift_date: String = ""
var lucky_wheel_free_spins: int = 1
var lucky_wheel_total_spins: int = 0
var last_lucky_wheel_result: Dictionary = {}
var last_reward_coins: int = 0
var last_session_stars: int = 0

# Energy System State (Max 24, +1/hr regen, 1/day calendar refill, -1 per level start)
var energy: int = MAX_ENERGY
var max_energy: int = MAX_ENERGY
var current_energy: int:
	get:
		return energy
	set(v):
		set_energy(v, false)
var last_energy_regen_timestamp: int = 0
var last_energy_daily_refill_date: String = ""
var _simulated_unix_time: int = -1
var _claimed_ad_sessions: Dictionary = {}
var rewarded_ad_controller: RefCounted = null

# Special Item Daily Rewarded-Ad Allowances (1 ad/day per item, independent from Daily Gift)
var last_special_item_ad_dates: Dictionary = {
	"bomb": "",
	"change_block": "",
	"extra_life": ""
}

# Extra Life 3-Placement Rewind Checkpoints & Session Recovery Guard
var placement_checkpoints: Array[Dictionary] = []
var extra_life_used_in_session: bool = false
var extra_life_recovery_count_in_session: int = 0
var last_extra_life_rewound_placements: int = 0

const LEVEL_TARGETS: Dictionary = {
	1: 500,
	2: 800,
	3: 1200,
	4: 1700,
	5: 2300
}

const CHAPTER_THEMES_EN: Array[String] = [
	"Sky Kingdom",
	"Emerald Forest",
	"Sapphire Peaks",
	"Ocean Lagoon",
	"Crystal Sanctuary",
	"Starlight Night",
	"Cloud Archipelago",
	"Ancient Grove",
	"Glacier Ridge",
	"Coral Atoll",
	"Prism Cavern",
	"Aurora Horizon",
	"Sunstone Mesa",
	"Whispering Bamboo",
	"Cobalt Fjord",
	"Amber Oasis",
	"Lunar Observatory",
	"Misty Cascades",
	"Jade Terraces",
	"Obsidian Basalt",
	"Pearl Shoals",
	"Aether Geode",
	"Gilded Canopy",
	"Frostfire Pass",
	"Solar Crown Citadel"
]

const CHAPTER_THEMES_VI: Array[String] = [
	"Vương Quốc Mây Trời",
	"Rừng Ngọc Bích",
	"Đỉnh Núi Lam Ngọc",
	"Vịnh Đại Dương",
	"Thánh Địa Pha Lê",
	"Đêm Ánh Sao",
	"Quần Đảo Tầng Mây",
	"Rừng Cổ Thụ",
	"Đỉnh Băng Giá",
	"Đảo San Hô",
	"Hang Lăng Kính",
	"Chân Trời Cực Quang",
	"Cao Nguyên Đá Nắng",
	"Rừng Trúc Thì Thầm",
	"Vịnh Hẹp Lam Bảo",
	"Ốc Đảo Hổ Phách",
	"Đài Quan Sát Ánh Trăng",
	"Thác Sương Mờ",
	"Ruộng Bậc Thang Ngọc",
	"Vách Đá Huyền Vũ",
	"Bãi Ngọc Trai",
	"Động Tinh Thể Aether",
	"Vòm Rừng Hoàng Kim",
	"Đèo Băng Hỏa",
	"Thánh Điện Thái Dương"
]

const TRANSLATIONS: Dictionary = {
	"en": {
		"app_subtitle": "ORIGINAL 4TM PUZZLE EDITION",
		"top_level_prefix": "LV",
		"top_stars_suffix": "STARS",
		"top_coins_suffix": "COINS",
		"btn_daily_gift": "DAILY GIFT",
		"btn_daily_claimed": "DAILY GIFT",
		"daily_claimed_toast": "Daily Gift Claimed: %s!",
		"daily_already_toast": "Come back tomorrow for your next free Daily Gift spin!",
		"lucky_wheel_title": "DAILY GIFT",
		"lucky_wheel_subtitle": "One Free Spin Daily — Win Modern Special Items!",
		"lucky_wheel_spin_free": "SPIN",
		"lucky_wheel_already_claimed": "CLAIMED TODAY — COME BACK TOMORROW",
		"lucky_wheel_spinning": "SPINNING...",
		"lucky_wheel_won_toast": "DAILY GIFT REWARD: %s!",
		"section_mode_title": "GAME MODE",
		"section_style_title": "PLAY STYLE",
		"mode_classic": "CLASSIC",
		"mode_modern": "MODERN",
		"style_falling": "FALLING",
		"style_drag_drop": "DRAG & DROP",
		"btn_start": "START",
		"btn_play": "START",
		"btn_play_level": "PLAY LEVEL %d",
		"btn_level_map": "WORLD MAP (1–500)",
		"btn_nav_levels": "LEVELS",
		"btn_nav_audio": "SETTINGS",
		"btn_nav_stats": "ACCOUNT",
		"level_banner_title": "LEVEL %d • %s",
		"level_banner_target": "Target: %d Pts   •   Best: %s",
		"locked_level_toast": "Complete Level %d first to unlock Level %d!",
		"rules_modal_title": "GAME RULES & GUIDE",
		"rules_close": "GOT IT",
		"level_map_title": "WORLD PROGRESSION MAP",
		"level_map_page": "CH. %d/%d • %s (LV. %d–%d)",
		"level_map_prev": "< PREV",
		"level_map_next": "NEXT >",
		"level_map_current": "CURRENT",
		"level_map_start": "PLAY LEVEL %d",
		"level_map_back": "HOME",
		"level_card_locked": "LOCKED",
		"level_card_prefix": "LV. %d",
		"map_status_banner": "You: Lv.%d   •   %d Stars   •   Next Milestone: Lv.%d (%s)",
		"settings_title": "SETTINGS",
		"music_on": "MUSIC: ON",
		"music_off": "MUSIC: OFF",
		"sfx_on": "SOUND SFX: ON",
		"sfx_off": "SOUND SFX: OFF",
		"voice_male": "VOICE: Male",
		"voice_female": "VOICE: Female",
		"voice_off": "VOICE: OFF",
		"haptics_on": "HAPTIC: ON",
		"haptics_off": "HAPTIC: OFF",
		"language_label": "LANGUAGE: EN",
		"btn_close": "CLOSE",
		"stats_title": "PLAYER RECORDS",
		"stats_best_score": "HIGH SCORE: %d",
		"stats_total_lines": "LINES CLEARED: %d",
		"stats_summary": "Stars: %d   •   Coins: %d   •   Unlocked: %d/%d",
		"hud_level": "LV %d",
		"hud_score_title": "SCORE",
		"hud_goal": "%s / %s",
		"next_piece": "NEXT",
		"item_bomb": "BOMB",
		"item_change_block": "CHANGE BLOCK",
		"item_extra_life": "EXTRA LIFE",
		"ctrl_left": "LEFT",
		"ctrl_turn": "TURN",
		"ctrl_right": "RIGHT",
		"ctrl_soft_drop": "SOFT DROP",
		"ctrl_hard_drop": "QUICK DROP",
		"pause_title": "GAME PAUSED",
		"btn_resume": "RESUME GAME",
		"btn_restart": "RESTART LEVEL",
		"btn_home": "HOME MENU",
		"modal_level_complete": "LEVEL %d COMPLETE!",
		"modal_game_over": "LEVEL %d ENDED",
		"modal_unlocked_next": "LEVEL %d UNLOCKED!",
		"modal_target_needed": "Target Needed: %d Pts",
		"modal_final_score": "FINAL SCORE",
		"modal_best_score": "BEST SCORE: %d",
		"modal_reward_coins": "REWARD: +%d COINS",
		"btn_use_extra_life": "USE EXTRA LIFE",
		"btn_watch_ad": "WATCH AD",
		"btn_main_menu": "MAIN MENU",
		"btn_next_level": "NEXT LEVEL (%d)",
		"btn_play_again": "PLAY AGAIN",
		"bonus_item_banner": "BONUS ITEM: %s!",
		"level_complete_banner": "LEVEL %d COMPLETE! +%d COINS!",
		"energy_empty_toast": "Out of Energy! Watch an ad (+) or wait for hourly refill.",
		"btn_account": "ACCOUNT",
		"account_title": "ACCOUNT",
		"account_local_title": "LOCAL",
		"account_local_badge": "ACTIVE",
		"account_local_desc": "Current local game account on this device.",
		"btn_delete_data": "DELETE DATA",
		"account_providers_title": "LINK / CREATE ACCOUNT",
		"btn_create_email": "CREATE WITH EMAIL",
		"btn_apple_id": "APPLE ID",
		"btn_google_play_id": "GOOGLE PLAY ID",
		"btn_google_id": "GOOGLE PLAY ID",
		"account_provider_unavailable": "UNAVAILABLE",
		"delete_confirm_title": "DELETE LOCAL DATA?",
		"delete_confirm_warning": "Warning: Local game progress (levels, stars, coins, high score, and bonus items) will be permanently reset to Level 1.",
		"btn_cancel_delete": "CANCEL",
		"btn_confirm_delete": "DELETE",
		"delete_data_reset_toast": "Local game data has been reset to Level 1."
	},
	"vi": {
		"app_subtitle": "PHIÊN BẢN XẾP KHỐI 4TM",
		"top_level_prefix": "LV",
		"top_stars_suffix": "SAO",
		"top_coins_suffix": "XU",
		"btn_daily_gift": "QUÀ HẰNG NGÀY",
		"btn_daily_claimed": "QUÀ HẰNG NGÀY",
		"daily_claimed_toast": "Đã Nhận Quà Hằng Ngày: %s!",
		"daily_already_toast": "Bạn đã quay Quà Hằng Ngày hôm nay. Hãy quay lại vào ngày mai!",
		"lucky_wheel_title": "QUÀ HẰNG NGÀY",
		"lucky_wheel_subtitle": "Mỗi Ngày 1 Lượt Quay Miễn Phí — Nhận Vật Phẩm Hiện Đại!",
		"lucky_wheel_spin_free": "QUAY NGAY",
		"lucky_wheel_already_claimed": "ĐÃ NHẬN HÔM NAY — QUAY LẠI NGÀY MAI",
		"lucky_wheel_spinning": "ĐANG QUAY...",
		"lucky_wheel_won_toast": "QUÀ HẰNG NGÀY: %s!",
		"section_mode_title": "CHẾ ĐỘ CHƠI",
		"section_style_title": "KIỂU ĐIỀU KHIỂN",
		"mode_classic": "CỔ ĐIỂN",
		"mode_modern": "HIỆN ĐẠI",
		"style_falling": "KHỐI RƠI",
		"style_drag_drop": "KÉO THẢ",
		"btn_start": "BẮT ĐẦU",
		"btn_play": "BẮT ĐẦU",
		"btn_play_level": "CHƠI MÀN %d",
		"btn_level_map": "BẢN ĐỒ HÀNH TRÌNH (1–500)",
		"btn_nav_levels": "BẢN ĐỒ",
		"btn_nav_audio": "CÀI ĐẶT",
		"btn_nav_stats": "TÀI KHOẢN",
		"level_banner_title": "MÀN %d • %s",
		"level_banner_target": "Mục tiêu: %d Điểm   •   Kỷ lục: %s",
		"locked_level_toast": "Hãy hoàn thành Màn %d để mở khóa Màn %d!",
		"rules_modal_title": "LUẬT CHƠI & HƯỚNG DẪN",
		"rules_close": "ĐÃ HIỂU",
		"level_map_title": "BẢN ĐỒ HÀNH TRÌNH",
		"level_map_page": "CHƯƠNG %d/%d • %s (MÀN %d–%d)",
		"level_map_prev": "< TRƯỚC",
		"level_map_next": "TIẾP >",
		"level_map_current": "HIỆN TẠI",
		"level_map_start": "CHƠI MÀN %d",
		"level_map_back": "TRANG CHỦ",
		"level_card_locked": "ĐÃ KHÓA",
		"level_card_prefix": "MÀN %d",
		"map_status_banner": "Hiện tại: Màn %d   •   %d Sao   •   Cột mốc tiếp: Màn %d (%s)",
		"settings_title": "CÀI ĐẶT",
		"music_on": "NHẠC NỀN: BẬT",
		"music_off": "NHẠC NỀN: TẮT",
		"sfx_on": "ÂM THANH: BẬT",
		"sfx_off": "ÂM THANH: TẮT",
		"voice_male": "GIỌNG: Nam",
		"voice_female": "GIỌNG: Nữ",
		"voice_off": "GIỌNG: TẮT",
		"haptics_on": "RUNG: BẬT",
		"haptics_off": "RUNG: TẮT",
		"language_label": "NGÔN NGỮ: VI",
		"btn_close": "ĐÓNG",
		"stats_title": "THÀNH TÍCH NGƯỜI CHƠI",
		"stats_best_score": "ĐIỂM CAO NHẤT: %d",
		"stats_total_lines": "TỔNG HÀNG ĐÃ XÓA: %d",
		"stats_summary": "Sao: %d   •   Xu: %d   •   Đã mở: %d/%d",
		"hud_level": "LV %d",
		"hud_score_title": "ĐIỂM SỐ",
		"hud_goal": "%s / %s",
		"next_piece": "TIẾP",
		"item_bomb": "BOM",
		"item_change_block": "ĐỔI KHỐI",
		"item_extra_life": "MẠNG THÊM",
		"ctrl_left": "TRÁI",
		"ctrl_turn": "XOAY",
		"ctrl_right": "PHẢI",
		"ctrl_soft_drop": "RƠI NHẸ",
		"ctrl_hard_drop": "THẢ NHANH",
		"pause_title": "TẠM DỪNG",
		"btn_resume": "TIẾP TỤC CHƠI",
		"btn_restart": "CHƠI LẠI MÀN NÀY",
		"btn_home": "MÀN HÌNH CHÍNH",
		"modal_level_complete": "HOÀN THÀNH MÀN %d!",
		"modal_game_over": "KẾT THÚC MÀN %d",
		"modal_unlocked_next": "ĐÃ MỞ KHÓA MÀN %d!",
		"modal_target_needed": "Điểm mục tiêu: %d",
		"modal_final_score": "ĐIỂM ĐẠT ĐƯỢC",
		"modal_best_score": "KỶ LỤC: %d",
		"modal_reward_coins": "THƯỞNG: +%d XU VÀNG",
		"btn_use_extra_life": "DÙNG MẠNG THÊM",
		"btn_watch_ad": "XEM QUẢNG CÁO",
		"btn_main_menu": "MÀN HÌNH CHÍNH",
		"btn_next_level": "MÀN TIẾP THEO (%d)",
		"btn_play_again": "CHƠI LẠI",
		"bonus_item_banner": "NHẬN VẬT PHẨM: %s!",
		"level_complete_banner": "QUA MÀN %d! +%d XU!",
		"energy_empty_toast": "Hết Năng Lượng! Xem quảng cáo (+) hoặc chờ hồi theo giờ.",
		"btn_account": "TÀI KHOẢN",
		"account_title": "TÀI KHOẢN",
		"account_local_title": "CỤC BỘ (LOCAL)",
		"account_local_badge": "ĐANG DÙNG",
		"account_local_desc": "Tài khoản chơi hiện tại được lưu trên thiết bị này.",
		"btn_delete_data": "XÓA DỮ LIỆU",
		"account_providers_title": "LIÊN KẾT / TẠO TÀI KHOẢN",
		"btn_create_email": "TẠO BẰNG EMAIL",
		"btn_apple_id": "APPLE ID",
		"btn_google_play_id": "GOOGLE PLAY ID",
		"btn_google_id": "GOOGLE PLAY ID",
		"account_provider_unavailable": "CHƯA MỞ",
		"delete_confirm_title": "XÓA DỮ LIỆU CỤC BỘ?",
		"delete_confirm_warning": "Cảnh báo: Toàn bộ tiến trình chơi trên máy (màn chơi, sao, xu, điểm cao và vật phẩm) sẽ bị đặt lại về Màn 1.",
		"btn_cancel_delete": "HỦY",
		"btn_confirm_delete": "XÓA",
		"delete_data_reset_toast": "Đã đặt lại dữ liệu trò chơi về Màn 1."
	}
}

# Player Preferences (Independent Music, SFX & Voice)
var music_enabled: bool = true
var sound_enabled: bool = true
var voice_mode: String = "male"
var haptics_enabled: bool = true
var haptic_trigger_count: int = 0
var last_haptic_duration_ms: int = 0
var last_haptic_reason: String = ""
var last_haptic_active: bool = false
var last_haptic_status: String = "idle"
var unsupported_haptic_attempt_count: int = 0
var _simulated_platform: String = ""
var _simulated_web_vibrate_available: Variant = null
var _web_vibration_capability_checked: bool = false
var _web_vibration_capability_supported: bool = false
var _simulated_date_str: String = ""
var lucky_wheel_extra_spins: int = 0
var lucky_wheel_consecutive_extra_spins: int = 0

# Centralized Scoring Constants (Placement itself gives 0 points; score increases ONLY on line clear)
const POINTS_PER_CELL_PLACED: int = 0
const POINTS_PER_LINE_BASE: int = 10
const ROW_COLUMN_COMBO_MULTIPLIER: float = 2.0
const RAINBOW_BLOCK_MULTIPLIER: float = 2.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rewarded_ad_controller = RewardedAdScript.new()
	if last_energy_regen_timestamp <= 0:
		last_energy_regen_timestamp = int(Time.get_unix_time_from_system())
	load_progression()
	check_daily_gift_date_reset()
	check_daily_energy_refill()
	update_energy_regeneration()


# ==============================================================================
# SINGLE-LANGUAGE LOCALIZATION API (EN DEFAULT / VI)
# ==============================================================================

func get_language() -> String:
	return current_language


func set_language(lang: String, save_to_disk: bool = true) -> void:
	var norm := lang.strip_edges().to_lower()
	if norm != "vi":
		norm = "en"
	if current_language == norm:
		return
	current_language = norm
	if save_to_disk:
		save_progression()
	language_changed.emit(current_language)


func toggle_language() -> String:
	var next_lang := "vi" if current_language == "en" else "en"
	set_language(next_lang)
	return current_language


func tr_text(key: String) -> String:
	var lang_dict: Dictionary = TRANSLATIONS.get(current_language, TRANSLATIONS["en"])
	if lang_dict.has(key):
		return String(lang_dict[key])
	return String(TRANSLATIONS["en"].get(key, key))


func get_rules_help_text(mode: int = current_mode, style: int = current_play_style) -> String:
	var is_modern := (mode == GameMode.MODERN_DRAG_AND_DROP)
	var is_falling := (style == PlayStyle.FALLING)
	if current_language == "vi":
		var selected_header := "ĐANG CHỌN: %s + %s (Bảng 12×10)" % [
			"HIỆN ĐẠI" if is_modern else "CỔ ĐIỂN",
			"KHỐI RƠI" if is_falling else "KÉO THẢ"
		]
		return (
			"• %s\n\n" % selected_header +
			"• BẢNG CHƠI 12×10 & KHỐI 4 Ô: Bảng gồm 12 hàng × 10 cột. Mọi khối gạch đều gồm đúng 4 ô.\n" +
			"• CỔ ĐIỂN (Classic): Chỉ xóa hàng ngang đầy (10 ô). Không có vật phẩm bổ trợ.\n" +
			"• HIỆN ĐẠI (Modern): Xóa cả hàng ngang (10 ô) và cột dọc (12 ô). Trang bị 3 vật phẩm bổ trợ:\n" +
			"   - BOM NỔ: Chọn vị trí bất kỳ trên bảng để phá vùng 3×3.\n" +
			"   - ĐỔI KHỐI: Chọn 1 khối hiện có để đổi sang hình dạng 4 ô mới.\n" +
			"   - THÊM MẠNG: Giải cứu bảng chơi và tiếp tục ván đấu.\n" +
			"• KHỐI RƠI (Falling): Khối rơi từ đỉnh bảng, chỉ hiện khối Tiếp Theo. Khi xóa hàng ngang, các ô phía trên tự động rơi xuống lấp chỗ trống.\n" +
			"• KÉO THẢ (Drag & Drop): Khay gồm 3 khối 4 ô. Đặt hết 3 khối sẽ sinh đợt 3 khối mới. Không áp dụng trọng lực.\n" +
			"• ĐIỀU KIỆN KẾT THÚC: Ván đấu kết thúc khi khối mới không thể xuất hiện (Khối Rơi) hoặc không còn vị trí hợp lệ trên bảng 12×10 cho các khối trong khay (Kéo Thả)."
		)
	else:
		var selected_header_en := "SELECTED: %s + %s (12×10 Board)" % [
			"MODERN" if is_modern else "CLASSIC",
			"FALLING" if is_falling else "DRAG & DROP"
		]
		return (
			"• %s\n\n" % selected_header_en +
			"• 12×10 BOARD & 4-CELL PIECES: Play on a 12-row by 10-column grid using strictly 4-cell blocks.\n" +
			"• CLASSIC MODE: Clears completed horizontal rows only (10 cells). No special items.\n" +
			"• MODERN MODE: Clears both completed horizontal rows and vertical columns. Includes 3 boosters:\n" +
			"   - BOMB: Select and confirm any board cell to clear a 3×3 area.\n" +
			"   - CHANGE BLOCK: Select an available piece to replace it with a different 4-cell piece.\n" +
			"   - EXTRA LIFE: Rescue the board and continue your run.\n" +
			"• FALLING STYLE: Pieces fall from the top with Next Piece preview. Clearing a row pulls blocks above downward with gravity.\n" +
			"• DRAG & DROP STYLE: Place 3 tray pieces (4 cells each) freely onto the 12×10 board. Using all 3 spawns a fresh set of 3 pieces. No gravity.\n" +
			"• GAME OVER: Occurs when a falling piece cannot spawn at the top or no remaining tray piece can fit anywhere on the 12×10 board."
		)


# ==============================================================================
# PROGRESSION, MILESTONES & LOCAL PERSISTENCE (LEVELS 1..500)
# ==============================================================================

func get_total_supported_levels() -> int:
	return TOTAL_LEVELS


func get_today_date_string(override_date_str: String = "") -> String:
	if override_date_str != "":
		_simulated_date_str = override_date_str
		return _simulated_date_str
	if _simulated_date_str != "":
		return _simulated_date_str
	return Time.get_date_string_from_system()


func reset_progression(save_to_disk: bool = true) -> void:
	highest_unlocked_level = 1
	selected_map_level = 1
	active_level = 1
	newly_unlocked_level = 0
	last_completed_level = 0
	completed_levels.clear()
	level_stars.clear()
	total_stars = 0
	coins = 250
	daily_reward_claimed = false
	last_daily_gift_date = ""
	_simulated_date_str = ""
	lucky_wheel_free_spins = 1
	lucky_wheel_total_spins = 0
	last_lucky_wheel_result.clear()
	persistent_bonus_items = {
		"bomb": 0,
		"change_block": 0,
		"extra_life": 0
	}
	last_special_item_ad_dates = {
		"bomb": "",
		"change_block": "",
		"extra_life": ""
	}
	_simulated_unix_time = -1
	_claimed_ad_sessions.clear()
	energy = MAX_ENERGY
	last_energy_regen_timestamp = get_current_unix_time()
	last_energy_daily_refill_date = get_today_date_string()
	placement_checkpoints.clear()
	extra_life_used_in_session = false
	extra_life_recovery_count_in_session = 0
	last_extra_life_rewound_placements = 0
	# Brand-new installation / reset save always defaults to CLASSIC + FALLING
	current_mode = GameMode.CLASSIC
	current_play_style = PlayStyle.FALLING
	_play_style_explicit = false
	if save_to_disk:
		save_progression()
	energy_changed.emit(energy, MAX_ENERGY)
	progression_updated.emit(highest_unlocked_level, total_stars, coins)


func set_simulated_platform(platform_name: String) -> void:
	_simulated_platform = platform_name.strip_edges().to_lower()
	_web_vibration_capability_checked = false


func clear_simulated_platform() -> void:
	_simulated_platform = ""
	_web_vibration_capability_checked = false


func set_simulated_web_vibrate_available(available: Variant) -> void:
	_simulated_web_vibrate_available = available
	_web_vibration_capability_checked = false
	_web_vibration_capability_supported = false


func clear_simulated_web_vibrate_available() -> void:
	_simulated_web_vibrate_available = null
	_web_vibration_capability_checked = false
	_web_vibration_capability_supported = false


func get_effective_account_platform(override_platform: String = "") -> String:
	var raw: String = override_platform.strip_edges().to_lower() if override_platform != "" else _simulated_platform
	if raw == "":
		var env_plat: String = OS.get_environment("BLOCK_PUZZLE_PLATFORM").strip_edges().to_lower()
		if env_plat == "":
			env_plat = OS.get_environment("PLATFORM").strip_edges().to_lower()
		if env_plat != "":
			raw = env_plat
	if raw == "":
		for arg in OS.get_cmdline_args() + OS.get_cmdline_user_args():
			var a_str: String = String(arg).strip_edges().to_lower()
			if a_str.begins_with("--platform="):
				raw = a_str.substr("--platform=".length()).strip_edges()
				break
	if raw == "":
		var os_name: String = OS.get_name().strip_edges().to_lower()
		if os_name in ["ios", "iphone", "ipad"] or OS.has_feature("ios") or OS.has_feature("iOS") or OS.has_feature("web_ios"):
			raw = "ios"
		elif os_name == "android" or OS.has_feature("android") or OS.has_feature("Android") or OS.has_feature("web_android"):
			raw = "android"
		elif (os_name == "web" or OS.has_feature("web")) and ClassDB.class_exists("JavaScriptBridge"):
			var js_plat: Variant = JavaScriptBridge.eval("(function(){try{var p=new URLSearchParams(window.location.search).get('platform');if(p)return p.toLowerCase();var ua=navigator.userAgent||'';if(/android/i.test(ua))return 'android';if(/iPad|iPhone|iPod/i.test(ua)||(navigator.platform==='MacIntel'&&navigator.maxTouchPoints>1))return 'ios';}catch(e){}return '';})()", true)
			if typeof(js_plat) == TYPE_STRING and String(js_plat) != "":
				raw = String(js_plat).strip_edges().to_lower()
			else:
				raw = os_name
		else:
			raw = os_name
	if raw in ["ios", "iphone", "ipad", "ipod", "apple", "apple_id", "web_ios"]:
		return "ios"
	if raw in ["android", "google_play", "google_play_id", "web_android"]:
		return "android"
	return "other"


func get_account_providers_for_platform(override_platform: String = "") -> Dictionary:
	var eff: String = get_effective_account_platform(override_platform)
	var providers: Array[String] = ["local"]
	if eff == "ios":
		providers.append("apple_id")
	elif eff == "android":
		providers.append("google_play_id")
	providers.append("create_with_email")
	return {
		"platform": eff,
		"local": true,
		"create_with_email": true,
		"apple_id": eff == "ios",
		"google_play_id": eff == "android",
		"google_id": eff == "android",
		"visible_providers": providers
	}


func delete_local_account_data(save_to_disk: bool = true) -> Dictionary:
	var audio_mgr = get_node_or_null("/root/AudioManager")
	var preserved_music: bool = audio_mgr.music_enabled if audio_mgr else music_enabled
	var preserved_sfx: bool = audio_mgr.sound_enabled if audio_mgr else sound_enabled
	var preserved_voice: String = audio_mgr.get_voice_mode() if (audio_mgr and audio_mgr.has_method("get_voice_mode")) else voice_mode
	var preserved_haptics: bool = haptics_enabled
	var preserved_lang: String = current_language

	reset_progression(false)
	score = 0
	high_score = 0
	lines_cleared_total = 0
	combo_count = 0
	special_item_inventory = {
		"bomb": 0,
		"change_block": 0,
		"extra_life": 0
	}

	# Restore unrelated app settings (Music, SFX, Voice, Haptics, Language)
	music_enabled = preserved_music
	sound_enabled = preserved_sfx
	voice_mode = preserved_voice
	haptics_enabled = preserved_haptics
	current_language = preserved_lang
	if audio_mgr:
		audio_mgr.music_enabled = preserved_music
		audio_mgr.sound_enabled = preserved_sfx
		if audio_mgr.has_method("set_voice_mode"):
			audio_mgr.set_voice_mode(preserved_voice)

	if save_to_disk:
		save_progression()
	energy_changed.emit(energy, MAX_ENERGY)
	progression_updated.emit(highest_unlocked_level, total_stars, coins)
	return {
		"reset_completed": true,
		"highest_unlocked_level": highest_unlocked_level,
		"selected_map_level": selected_map_level,
		"total_stars": total_stars,
		"coins": coins,
		"high_score": high_score,
		"lines_cleared_total": lines_cleared_total,
		"music_enabled": music_enabled,
		"sound_enabled": sound_enabled,
		"voice_mode": voice_mode,
		"haptics_enabled": haptics_enabled,
		"language": current_language
	}


func save_progression(custom_path: String = PROGRESSION_SAVE_PATH) -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("progression", "highest_unlocked_level", highest_unlocked_level)
	cfg.set_value("progression", "selected_map_level", selected_map_level)
	cfg.set_value("progression", "completed_levels", completed_levels.duplicate())
	cfg.set_value("progression", "level_stars", level_stars.duplicate())
	cfg.set_value("progression", "coins", coins)
	cfg.set_value("progression", "high_score", high_score)
	cfg.set_value("progression", "lines_cleared_total", lines_cleared_total)
	cfg.set_value("progression", "daily_reward_claimed", daily_reward_claimed)
	cfg.set_value("progression", "last_daily_gift_date", last_daily_gift_date)
	cfg.set_value("progression", "lucky_wheel_free_spins", lucky_wheel_free_spins)
	cfg.set_value("progression", "lucky_wheel_total_spins", lucky_wheel_total_spins)
	cfg.set_value("progression", "persistent_bonus_items", persistent_bonus_items.duplicate())
	cfg.set_value("progression", "energy", energy)
	cfg.set_value("progression", "last_energy_regen_timestamp", last_energy_regen_timestamp)
	cfg.set_value("progression", "last_energy_daily_refill_date", last_energy_daily_refill_date)
	cfg.set_value("progression", "last_special_item_ad_dates", last_special_item_ad_dates.duplicate())
	cfg.set_value("settings", "language", current_language)
	cfg.set_value("settings", "selected_game_mode", int(current_mode))
	cfg.set_value("settings", "selected_play_style", int(current_play_style))
	cfg.set_value("settings", "music_enabled", music_enabled)
	cfg.set_value("settings", "sound_enabled", sound_enabled)
	cfg.set_value("settings", "voice_mode", voice_mode)
	cfg.set_value("settings", "haptics_enabled", haptics_enabled)
	cfg.save(custom_path)


func load_progression(custom_path: String = PROGRESSION_SAVE_PATH) -> bool:
	var cfg = ConfigFile.new()
	if cfg.load(custom_path) != OK:
		# Brand-new installation / no existing save file: default to CLASSIC + FALLING
		current_mode = GameMode.CLASSIC
		current_play_style = PlayStyle.FALLING
		_play_style_explicit = false
		energy = MAX_ENERGY
		last_energy_regen_timestamp = get_current_unix_time()
		last_energy_daily_refill_date = get_today_date_string()
		_recalculate_total_stars()
		return false
	highest_unlocked_level = clampi(int(cfg.get_value("progression", "highest_unlocked_level", 1)), 1, TOTAL_LEVELS)
	selected_map_level = clampi(int(cfg.get_value("progression", "selected_map_level", highest_unlocked_level)), 1, highest_unlocked_level)
	var loaded_completed = cfg.get_value("progression", "completed_levels", {})
	completed_levels = loaded_completed.duplicate() if loaded_completed is Dictionary else {}
	var loaded_stars = cfg.get_value("progression", "level_stars", {})
	level_stars = loaded_stars.duplicate() if loaded_stars is Dictionary else {}
	coins = int(cfg.get_value("progression", "coins", 250))
	high_score = int(cfg.get_value("progression", "high_score", 0))
	lines_cleared_total = int(cfg.get_value("progression", "lines_cleared_total", 0))
	daily_reward_claimed = bool(cfg.get_value("progression", "daily_reward_claimed", false))
	last_daily_gift_date = String(cfg.get_value("progression", "last_daily_gift_date", ""))
	lucky_wheel_free_spins = int(cfg.get_value("progression", "lucky_wheel_free_spins", 0 if daily_reward_claimed else 1))
	lucky_wheel_total_spins = int(cfg.get_value("progression", "lucky_wheel_total_spins", 0))
	var loaded_bonus = cfg.get_value("progression", "persistent_bonus_items", {})
	if loaded_bonus is Dictionary:
		for k in MODERN_ITEM_TYPES:
			persistent_bonus_items[k] = int(loaded_bonus.get(k, 0))
	energy = clampi(int(cfg.get_value("progression", "energy", MAX_ENERGY)), 0, MAX_ENERGY)
	last_energy_regen_timestamp = int(cfg.get_value("progression", "last_energy_regen_timestamp", get_current_unix_time()))
	last_energy_daily_refill_date = String(cfg.get_value("progression", "last_energy_daily_refill_date", ""))
	var loaded_ad_dates = cfg.get_value("progression", "last_special_item_ad_dates", {})
	if loaded_ad_dates is Dictionary:
		for k in MODERN_ITEM_TYPES:
			last_special_item_ad_dates[k] = String(loaded_ad_dates.get(k, ""))
	var saved_lang = String(cfg.get_value("settings", "language", current_language)).to_lower()
	if saved_lang == "vi" or saved_lang == "en":
		current_language = saved_lang
	var saved_mode: int = int(cfg.get_value("settings", "selected_game_mode", int(GameMode.CLASSIC)))
	var saved_style: int = int(cfg.get_value("settings", "selected_play_style", int(PlayStyle.FALLING)))
	current_mode = GameMode.MODERN_DRAG_AND_DROP if saved_mode == int(GameMode.MODERN_DRAG_AND_DROP) else GameMode.CLASSIC
	current_play_style = PlayStyle.DRAG_AND_DROP if saved_style == int(PlayStyle.DRAG_AND_DROP) else PlayStyle.FALLING
	_play_style_explicit = true
	if cfg.has_section_key("settings", "music_enabled"):
		music_enabled = bool(cfg.get_value("settings", "music_enabled", true))
	if cfg.has_section_key("settings", "sound_enabled"):
		sound_enabled = bool(cfg.get_value("settings", "sound_enabled", true))
	if cfg.has_section_key("settings", "voice_mode"):
		set_voice_mode(String(cfg.get_value("settings", "voice_mode", "male")), false)
	if cfg.has_section_key("settings", "haptics_enabled"):
		haptics_enabled = bool(cfg.get_value("settings", "haptics_enabled", true))
	check_daily_gift_date_reset()
	update_energy_regeneration()
	if last_energy_daily_refill_date == "":
		last_energy_daily_refill_date = _simulated_date_str if _simulated_date_str != "" else get_today_date_string()
	else:
		check_daily_energy_refill()
	_recalculate_total_stars()
	energy_changed.emit(energy, MAX_ENERGY)
	progression_updated.emit(highest_unlocked_level, total_stars, coins)
	return true


func _recalculate_total_stars() -> void:
	var sum_stars: int = 0
	for k in level_stars.keys():
		sum_stars += int(level_stars[k])
	total_stars = sum_stars


func is_level_unlocked(lvl: int) -> bool:
	return lvl >= 1 and lvl <= highest_unlocked_level and lvl <= TOTAL_LEVELS


func is_level_completed(lvl: int) -> bool:
	return bool(completed_levels.get(lvl, false)) or int(level_stars.get(lvl, 0)) > 0


func get_level_best_stars(lvl: int) -> int:
	return int(level_stars.get(lvl, 0))


func select_map_level(lvl: int) -> bool:
	if not is_level_unlocked(lvl):
		return false
	selected_map_level = lvl
	save_progression()
	progression_updated.emit(highest_unlocked_level, total_stars, coins)
	return true


func build_block_puzzle_map_data(total_levels: int = TOTAL_LEVELS) -> MapData:
	return BlockPuzzleMapConfig.build_block_puzzle_map_data(total_levels)


func get_map_data() -> MapData:
	if map_data == null:
		map_data = build_block_puzzle_map_data(TOTAL_LEVELS)
	return map_data


func set_custom_map_data(custom_map: MapData) -> void:
	map_data = custom_map


func get_total_map_pages() -> int:
	return get_map_data().get_page_count()


func get_page_index_for_level(lvl: int) -> int:
	return get_map_data().get_page_index_for_level(lvl)


func get_page_number_for_level(lvl: int) -> int:
	return get_map_data().get_page_number_for_level(lvl)


func get_progression_provider_dict() -> Dictionary:
	return {
		"unlocked_level": highest_unlocked_level,
		"selected_level": selected_map_level,
		"level_stars": level_stars,
		"completed_levels": completed_levels,
		"target_scores": LEVEL_TARGETS
	}


func get_map_page_object(page_index: int, canvas_size: Vector2 = Vector2(390.0, 620.0)) -> MapPage:
	var md: MapData = get_map_data()
	return md.build_page_layout(page_index, canvas_size, get_progression_provider_dict())


func get_chapter_environment(chapter_index: int) -> Dictionary:
	var md: MapData = get_map_data()
	var safe_ch: int = clampi(chapter_index, 0, maxi(0, md.get_page_count() - 1))
	var page: MapPage = md.get_page(safe_ch)
	var theme_obj: MapTheme = page.theme if (page != null and page.theme != null) else MapTheme.from_preset("ocean_islands")
	var pal: Dictionary = theme_obj.palette
	var ch_en: String = page.get_display_title("en") if page != null else theme_obj.name_en
	var ch_vi: String = page.get_display_title("vi") if page != null else theme_obj.name_vi
	var env: Dictionary = {
		"id": theme_obj.theme_id,
		"theme_id": theme_obj.theme_id,
		"world_type": theme_obj.world_type,
		"world_id": theme_obj.world_id,
		"world_name_en": theme_obj.world_name_en,
		"world_name_vi": theme_obj.world_name_vi,
		"country_or_region_en": theme_obj.country_or_region_en,
		"country_or_region_vi": theme_obj.country_or_region_vi,
		"primary_landmark_id": theme_obj.primary_landmark_id,
		"primary_landmark_en": theme_obj.primary_landmark_en,
		"primary_landmark_vi": theme_obj.primary_landmark_vi,
		"gameplay_background_theme": theme_obj.gameplay_background_theme,
		"region_id": theme_obj.region_id,
		"region_name_en": theme_obj.region_name_en,
		"region_name_vi": theme_obj.region_name_vi,
		"subregions": theme_obj.subregions.duplicate(),
		"subregion_names_en": theme_obj.subregion_names_en.duplicate(),
		"subregion_names_vi": theme_obj.subregion_names_vi.duplicate(),
		"gameplay_backgrounds": theme_obj.gameplay_backgrounds.duplicate(),
		"name_en": ch_en,
		"name_vi": ch_vi,
		"world_title_en": ch_en,
		"world_title_vi": ch_vi,
		"chapter_index": safe_ch,
		"chapter_number": safe_ch + 1,
		"page_index": safe_ch,
		"page_number": safe_ch + 1,
		"page_id": page.page_id if page != null else ("page_%d" % (safe_ch + 1)),
		"level_count": page.get_level_count() if page != null else 6,
		"start_level": page.start_level if page != null else 1,
		"end_level": page.end_level if page != null else 6,
		"biome_type": theme_obj.dominant_environment,
		"dominant_environment": theme_obj.dominant_environment,
		"terrain_layout": theme_obj.terrain_style,
		"terrain_style": theme_obj.terrain_style,
		"waterway_type": theme_obj.atmosphere_style,
		"road_style": theme_obj.path_style,
		"path_style": theme_obj.path_style,
		"vegetation_type": theme_obj.landmark_types[0] if not theme_obj.landmark_types.is_empty() else "coastal_palms",
		"architecture_type": theme_obj.destination_styles[0] if not theme_obj.destination_styles.is_empty() else "sandy_cay_island",
		"ambient_particle_type": theme_obj.particle_style,
		"bg_top": pal.get("sky_top", Color(0.14, 0.48, 0.94, 0.98)),
		"bg_bot": pal.get("sky_bottom", Color(0.38, 0.76, 0.98, 0.96)),
		"island_col": pal.get("island_surface", Color(0.28, 0.78, 0.52, 0.92)),
		"cliff_col": pal.get("cliff_color", Color(0.36, 0.44, 0.64, 0.96)),
		"water_col": pal.get("water_color", Color(0.22, 0.78, 0.98, 0.84)),
		"shore_col": pal.get("shore_color", Color(0.98, 0.90, 0.64, 1.0)),
		"path_outer": pal.get("path_outer", Color(0.96, 0.78, 0.28, 0.95)),
		"path_inner": pal.get("path_inner", Color(1.0, 0.96, 0.76, 0.98)),
		"accent_col": pal.get("accent_color", Color(0.26, 0.94, 1.0, 1.0)),
		"path_archetype": page.composition_type if page != null else "sweeping_arc",
		"composition_type": page.composition_type if page != null else "sweeping_arc",
		"is_theme_coherent": page.is_theme_coherent() if page != null else true,
		"has_3d_depth_layers": true,
		"depth_layers": ["background_vista", "midground_terrain_and_waterways", "foreground_canopy_and_cliffs"],
		"milestone_landmarks": {
			"chapter_entry": theme_obj.landmark_types[0] if not theme_obj.landmark_types.is_empty() else "harbor_lighthouse",
			"mid_landmark": theme_obj.landmark_types[1 % maxi(1, theme_obj.landmark_types.size())] if not theme_obj.landmark_types.is_empty() else "coral_arch",
			"page_finale": theme_obj.destination_styles[theme_obj.destination_styles.size() - 1] if not theme_obj.destination_styles.is_empty() else "citadel_harbor"
		}
	}
	return env


const PolyominoLibScript = preload("res://scripts/core/polyomino_library.gd")


func get_country_background_registry() -> Dictionary:
	return BlockPuzzleMapConfig.get_country_background_registry()


func get_canonical_country_background(country_id: String) -> Dictionary:
	return BlockPuzzleMapConfig.get_canonical_country_background(country_id)


func validate_country_background_registry() -> Dictionary:
	return BlockPuzzleMapConfig.validate_country_background_registry(get_map_data())


func get_level_visual_theme(lvl: int = active_level) -> Dictionary:
	var safe_lvl: int = clampi(lvl, 1, TOTAL_LEVELS)
	var md: MapData = get_map_data()
	var page_idx: int = md.get_page_index_for_level(safe_lvl)
	var page_obj: MapPage = md.get_page(page_idx)
	var env: Dictionary = get_chapter_environment(page_idx)
	var base_biome: String = String(env.get("theme_id", "ocean_islands"))
	var biome_cycle: Array[String] = [
		"ocean_islands",
		"desert_dunes",
		"green_forest",
		"hills_mountains",
		"snow_ice",
		"volcano_lava",
		"ancient_ruins",
		"crystal_sanctuary",
		"starlight_highlands"
	]
	var country_id_str: String = page_obj.country_id if page_obj != null else "vietnam"
	var country_en_str: String = page_obj.country_name_en if page_obj != null else String(env.get("country_or_region_en", "Vietnam"))
	var country_vi_str: String = page_obj.country_name_vi if page_obj != null else String(env.get("country_or_region_vi", "Việt Nam"))
	var canonical_bg: Dictionary = BlockPuzzleMapConfig.get_canonical_country_background(country_id_str)
	var canonical_bg_id: String = String(canonical_bg.get("canonical_background_id", "%s_canonical_country_bg" % country_id_str))
	var canonical_lm_id: String = String(canonical_bg.get("canonical_landmark_id", "%s_heritage" % country_id_str))
	var canonical_lm_name: String = String(canonical_bg.get("canonical_landmark_name", country_en_str))
	var canonical_sec_lm_id: String = String(canonical_bg.get("canonical_secondary_landmark_id", ""))
	var canonical_sec_lm_name: String = String(canonical_bg.get("canonical_secondary_landmark_name", ""))

	# Canonical country palette: identical across all levels belonging to the same country
	var sky_top: Color = env.get("bg_top", Color(0.10, 0.44, 0.88, 1.0))
	var sky_bot: Color = env.get("bg_bot", Color(0.28, 0.78, 0.96, 1.0))
	var sky_mid: Color = sky_top.lerp(sky_bot, 0.52)
	var mat_pal_id: String = PolyominoLibScript.get_level_material_palette_id(safe_lvl)
	var accent_col: Color = env.get("accent_col", Color(0.36, 0.94, 1.0, 1.0))
	var grid_tint: Color = accent_col.lerp(sky_bot.lightened(0.25), 0.45)
	grid_tint.a = 1.0

	return {
		"level": safe_lvl,
		"page_index": page_idx,
		"country_id": country_id_str,
		"country_name_en": country_en_str,
		"country_name_vi": country_vi_str,
		"canonical_background_id": canonical_bg_id,
		"background_id": canonical_bg_id,
		"canonical_landmark_id": canonical_lm_id,
		"canonical_landmark_name": canonical_lm_name,
		"canonical_secondary_landmark_id": canonical_sec_lm_id,
		"canonical_secondary_landmark_name": canonical_sec_lm_name,
		"composition_landmarks": canonical_bg.get("composition_landmarks", []),
		"landmark_ids": canonical_bg.get("landmark_ids", []),
		"major_landmark_ids": canonical_bg.get("major_landmark_ids", []),
		"scenery_cue_ids": canonical_bg.get("scenery_cue_ids", []),
		"landmark_count": int(canonical_bg.get("landmark_count", 0)),
		"major_landmark_count": int(canonical_bg.get("major_landmark_count", 0)),
		"scenery_cue_count": int(canonical_bg.get("scenery_cue_count", 0)),
		"has_multiple_landmarks": bool(canonical_bg.get("has_multiple_landmarks", true)),
		"has_visual_hierarchy": bool(canonical_bg.get("has_visual_hierarchy", true)),
		"is_single_landmark_only": false,
		"is_continuous_country_scene": true,
		"resolution_architecture": "level_to_country_to_canonical_background",
		"uses_destination_selection": false,
		"theme_id": base_biome,
		"biome_id": biome_cycle[posmod(safe_lvl - 1, biome_cycle.size())],
		"page_biome_id": base_biome,
		"world_type": String(env.get("world_type", "landmark_region")),
		"world_id": String(env.get("world_id", "ha_long_bay")),
		"world_name_en": country_en_str,
		"world_name_vi": country_vi_str,
		"country_or_region_en": country_en_str,
		"country_or_region_vi": country_vi_str,
		"primary_landmark_en": canonical_lm_name,
		"primary_landmark_vi": canonical_lm_name,
		"gameplay_background_theme": canonical_bg_id,
		"region_id": country_id_str,
		"region_name_en": country_en_str,
		"region_name_vi": country_vi_str,
		"subregion_id": country_id_str,
		"subregion_name_en": country_en_str,
		"subregion_name_vi": country_vi_str,
		"gameplay_background": canonical_bg_id,
		"sky_top": sky_top,
		"sky_mid": sky_mid,
		"sky_bot": sky_bot,
		"horizon_col": env.get("water_col", sky_bot.lightened(0.18)),
		"terrain_primary": env.get("island_col", Color(0.22, 0.76, 0.48, 1.0)),
		"terrain_secondary": env.get("cliff_col", Color(0.32, 0.42, 0.64, 1.0)),
		"accent_col": accent_col,
		"board_border_col": grid_tint,
		"grid_tint": grid_tint,
		"landmark_style": canonical_lm_id,
		"weather_particles": String(env.get("ambient_particle_type", "golden_motes")),
		"material_palette_id": mat_pal_id,
		"level_seed": (page_idx + 1) * 7919
	}


func get_level_environment_spec(lvl: int = active_level) -> Dictionary:
	return get_level_visual_theme(lvl)


func get_level_gameplay_background_manifest(lvl: int = active_level, viewport_size: Vector2 = Vector2(390.0, 844.0)) -> Dictionary:
	var safe_lvl: int = clampi(lvl, 1, TOTAL_LEVELS)
	var page: MapPage = get_map_data().get_page_for_level(safe_lvl)
	var eff_vp := Vector2(maxf(320.0, viewport_size.x), maxf(480.0, viewport_size.y))
	if page == null:
		return {}
	const MapRendererRef = preload("res://scripts/map_core/map_renderer.gd")
	return MapRendererRef.get_gameplay_level_background_manifest(page, safe_lvl, Rect2(Vector2.ZERO, eff_vp), current_language)


func get_level_title(lvl: int = selected_map_level) -> String:
	var page: MapPage = get_map_data().get_page_for_level(lvl)
	if page != null:
		return page.get_display_title(current_language)
	var chapter_idx := int(max(0, lvl - 1) / 8)
	var themes := CHAPTER_THEMES_VI if current_language == "vi" else CHAPTER_THEMES_EN
	return themes[chapter_idx % themes.size()]


func get_level_milestone_type(lvl: int) -> String:
	var page: MapPage = get_map_data().get_page_for_level(lvl)
	if page != null:
		var m_spec: Dictionary = page.get_milestone_spec(lvl)
		var m_raw: String = String(m_spec.get("milestone_type", ""))
		if m_raw == "crown":
			return "major_milestone"
		elif m_raw == "chest":
			return "reward_milestone"
		elif m_raw == "star":
			return "star_milestone"
		elif m_raw != "":
			return m_raw
		if lvl == page.start_level and lvl > 1:
			return "chapter_unlock_milestone"
	return ""


func is_special_milestone_level(lvl: int = active_level) -> bool:
	var safe_lvl: int = clampi(lvl, 1, TOTAL_LEVELS)
	if get_level_milestone_type(safe_lvl) != "":
		return true
	return PolyominoLibScript.is_special_milestone_level(safe_lvl)


func can_level_have_special_board_items(lvl: int = active_level, mode: int = current_mode) -> bool:
	if not has_special_items(mode):
		return false
	return is_special_milestone_level(lvl)


func get_milestone_special_board_item_specs(lvl: int = active_level, mode: int = current_mode) -> Array[Dictionary]:
	if not can_level_have_special_board_items(lvl, mode):
		return []
	var safe_lvl: int = clampi(lvl, 1, TOTAL_LEVELS)
	var chosen_booster: String = MODERN_ITEM_TYPES[posmod(safe_lvl, MODERN_ITEM_TYPES.size())]
	var specs: Array[Dictionary] = [
		{
			"coords": Vector2i(2, 9),
			"item_type": chosen_booster,
			"color_id": ((safe_lvl - 1) % 8) + 1
		},
		{
			"coords": Vector2i(5, 10),
			"item_type": "rainbow",
			"color_id": 9
		},
		{
			"coords": Vector2i(7, 9),
			"item_type": "locked",
			"color_id": ((safe_lvl + 2) % 8) + 1
		}
	]
	return specs


func collect_board_special_item(item_id: String, lvl: int = active_level) -> Dictionary:
	if not can_level_have_special_board_items(lvl, current_mode) or not (item_id in MODERN_ITEM_TYPES):
		return {"collected": false, "discovered": false, "item_id": "", "quantity": get_special_item_count(item_id)}
	var new_qty: int = add_special_item(item_id, 1)
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_special_item"):
		audio_mgr.play_special_item(item_id)
	special_item_discovered.emit(item_id, new_qty)
	return {
		"collected": true,
		"discovered": true,
		"item_id": item_id,
		"quantity": new_qty
	}


func get_level_milestone_icon(lvl: int, is_unlocked: bool = false) -> String:
	var m_type := get_level_milestone_type(lvl)
	match m_type:
		"major_milestone", "crown": return "TROPHY"
		"reward_milestone", "chest": return "GIFT"
		"star_milestone", "star": return "STAR"
		"chapter_unlock_milestone": return "UNLOCK" if is_unlocked else "LOCK"
		_: return ""


## Returns the visual classification & styling specification for level map nodes
func get_milestone_visual_spec(m_type: String) -> Dictionary:
	match m_type:
		"major_milestone":
			return {
				"milestone_type": "major_milestone",
				"scale_mult": 1.28,
				"border_width": 5,
				"halo_radius": 72.0,
				"island_radius": 76.0,
				"badge_radius": 15.0,
				"corner_radius": 20,
				"visual_tier": 4
			}
		"reward_milestone":
			return {
				"milestone_type": "reward_milestone",
				"scale_mult": 1.20,
				"border_width": 4,
				"halo_radius": 62.0,
				"island_radius": 66.0,
				"badge_radius": 13.5,
				"corner_radius": 24,
				"visual_tier": 3
			}
		"chapter_unlock_milestone":
			return {
				"milestone_type": "chapter_unlock_milestone",
				"scale_mult": 1.16,
				"border_width": 4,
				"halo_radius": 58.0,
				"island_radius": 62.0,
				"badge_radius": 13.0,
				"corner_radius": 18,
				"visual_tier": 2
			}
		"star_milestone":
			return {
				"milestone_type": "star_milestone",
				"scale_mult": 1.14,
				"border_width": 4,
				"halo_radius": 56.0,
				"island_radius": 60.0,
				"badge_radius": 12.5,
				"corner_radius": 28,
				"visual_tier": 1
			}
		_:
			return {
				"milestone_type": "normal",
				"scale_mult": 1.00,
				"border_width": 2,
				"halo_radius": 0.0,
				"island_radius": 46.0,
				"badge_radius": 0.0,
				"corner_radius": 38,
				"visual_tier": 0
			}


const CHAPTER_PATH_ARCHETYPES: Array[String] = [
	"winding_valley_route",
	"branching_route",
	"bridge_crossing",
	"island_hopping",
	"mountain_ascent",
	"cave_passage",
	"river_crossing",
	"cliffside_trail",
	"spiral_terrain",
	"multi_platform_route",
	"landmark_approach",
	"chapter_gateway_transition"
]

const DESTINATION_ARCHITECTURE_TYPES: Array[String] = [
	"carved_platform",
	"stone_pedestal",
	"wooden_platform",
	"crystal_platform",
	"bridge_bastion",
	"watchtower",
	"sanctuary_shrine",
	"citadel_gate"
]

const ROUTE_SEGMENT_TYPES: Array[String] = [
	"carved_terrain_road",
	"wooden_suspension_bridge",
	"arched_stone_bridge",
	"cliff_stairway",
	"stepping_stone_causeway",
	"cave_tunnel_passage",
	"elevated_skyway"
]

# 12 Genuinely Distinct Spatial Route Compositions (20 3D waypoints each: x, y, elevation_z)
# Every composition follows actual terrain landmasses, cliffs, islands, caves, bridges, and landmarks.
const ARCHETYPE_3D_WAYPOINTS: Dictionary = {
	"winding_valley_route": [
		Vector3(0.08, 0.04, 0.15), Vector3(0.36, 0.07, 0.22), Vector3(0.64, 0.05, 0.28), Vector3(0.92, 0.09, 0.32),
		Vector3(0.90, 0.24, 0.36), Vector3(0.62, 0.28, 0.30), Vector3(0.34, 0.23, 0.25), Vector3(0.08, 0.27, 0.40),
		Vector3(0.14, 0.45, 0.48), Vector3(0.46, 0.49, 0.55), Vector3(0.78, 0.44, 0.50), Vector3(0.94, 0.54, 0.62),
		Vector3(0.72, 0.69, 0.68), Vector3(0.40, 0.66, 0.72), Vector3(0.10, 0.72, 0.76), Vector3(0.28, 0.84, 0.82),
		Vector3(0.58, 0.81, 0.86), Vector3(0.88, 0.85, 0.90), Vector3(0.66, 0.96, 0.95), Vector3(0.32, 0.95, 1.00)
	],
	"branching_route": [
		Vector3(0.48, 0.04, 0.20), Vector3(0.18, 0.10, 0.28), Vector3(0.80, 0.11, 0.30), Vector3(0.48, 0.20, 0.40),
		Vector3(0.12, 0.28, 0.46), Vector3(0.38, 0.34, 0.52), Vector3(0.68, 0.31, 0.48), Vector3(0.92, 0.36, 0.56),
		Vector3(0.82, 0.48, 0.62), Vector3(0.50, 0.46, 0.70), Vector3(0.16, 0.50, 0.64), Vector3(0.08, 0.64, 0.72),
		Vector3(0.38, 0.63, 0.75), Vector3(0.68, 0.66, 0.78), Vector3(0.94, 0.69, 0.84), Vector3(0.76, 0.81, 0.88),
		Vector3(0.44, 0.79, 0.90), Vector3(0.14, 0.83, 0.92), Vector3(0.36, 0.95, 0.96), Vector3(0.74, 0.95, 1.00)
	],
	"bridge_crossing": [
		Vector3(0.08, 0.05, 0.35), Vector3(0.34, 0.09, 0.38), Vector3(0.66, 0.13, 0.20), Vector3(0.92, 0.16, 0.42),
		Vector3(0.86, 0.30, 0.46), Vector3(0.56, 0.27, 0.22), Vector3(0.26, 0.31, 0.48), Vector3(0.06, 0.38, 0.52),
		Vector3(0.28, 0.47, 0.26), Vector3(0.60, 0.45, 0.58), Vector3(0.90, 0.49, 0.62), Vector3(0.74, 0.62, 0.30),
		Vector3(0.42, 0.61, 0.66), Vector3(0.12, 0.65, 0.70), Vector3(0.22, 0.78, 0.76), Vector3(0.54, 0.76, 0.34),
		Vector3(0.86, 0.79, 0.84), Vector3(0.92, 0.92, 0.90), Vector3(0.58, 0.94, 0.95), Vector3(0.20, 0.95, 1.00)
	],
	"island_hopping": [
		Vector3(0.12, 0.05, 0.12), Vector3(0.42, 0.04, 0.16), Vector3(0.76, 0.08, 0.14), Vector3(0.92, 0.20, 0.22),
		Vector3(0.62, 0.22, 0.18), Vector3(0.28, 0.19, 0.25), Vector3(0.08, 0.30, 0.20), Vector3(0.36, 0.36, 0.30),
		Vector3(0.70, 0.37, 0.28), Vector3(0.94, 0.46, 0.40), Vector3(0.64, 0.52, 0.34), Vector3(0.30, 0.51, 0.38),
		Vector3(0.08, 0.60, 0.44), Vector3(0.38, 0.67, 0.50), Vector3(0.72, 0.66, 0.48), Vector3(0.92, 0.76, 0.60),
		Vector3(0.60, 0.81, 0.68), Vector3(0.24, 0.80, 0.74), Vector3(0.12, 0.94, 0.88), Vector3(0.52, 0.95, 1.00)
	],
	"mountain_ascent": [
		Vector3(0.88, 0.04, 0.10), Vector3(0.56, 0.07, 0.16), Vector3(0.22, 0.10, 0.22), Vector3(0.08, 0.22, 0.30),
		Vector3(0.38, 0.25, 0.36), Vector3(0.70, 0.23, 0.42), Vector3(0.94, 0.32, 0.48), Vector3(0.66, 0.39, 0.54),
		Vector3(0.32, 0.41, 0.60), Vector3(0.08, 0.49, 0.66), Vector3(0.36, 0.56, 0.72), Vector3(0.68, 0.55, 0.76),
		Vector3(0.92, 0.64, 0.80), Vector3(0.62, 0.71, 0.84), Vector3(0.28, 0.72, 0.88), Vector3(0.10, 0.82, 0.91),
		Vector3(0.42, 0.84, 0.94), Vector3(0.76, 0.83, 0.96), Vector3(0.88, 0.95, 0.98), Vector3(0.48, 0.96, 1.00)
	],
	"cave_passage": [
		Vector3(0.10, 0.05, 0.40), Vector3(0.40, 0.08, 0.32), Vector3(0.72, 0.06, 0.24), Vector3(0.92, 0.17, 0.16),
		Vector3(0.68, 0.25, 0.10), Vector3(0.34, 0.24, 0.12), Vector3(0.08, 0.33, 0.18), Vector3(0.26, 0.45, 0.14),
		Vector3(0.58, 0.42, 0.20), Vector3(0.88, 0.44, 0.28), Vector3(0.92, 0.58, 0.22), Vector3(0.60, 0.59, 0.16),
		Vector3(0.28, 0.61, 0.24), Vector3(0.08, 0.72, 0.36), Vector3(0.38, 0.76, 0.48), Vector3(0.70, 0.74, 0.60),
		Vector3(0.92, 0.82, 0.72), Vector3(0.66, 0.92, 0.84), Vector3(0.34, 0.93, 0.92), Vector3(0.08, 0.95, 1.00)
	],
	"river_crossing": [
		Vector3(0.08, 0.06, 0.18), Vector3(0.36, 0.04, 0.20), Vector3(0.66, 0.09, 0.14), Vector3(0.92, 0.14, 0.26),
		Vector3(0.76, 0.27, 0.30), Vector3(0.44, 0.24, 0.16), Vector3(0.12, 0.26, 0.34), Vector3(0.18, 0.40, 0.38),
		Vector3(0.50, 0.39, 0.18), Vector3(0.84, 0.41, 0.44), Vector3(0.90, 0.55, 0.50), Vector3(0.58, 0.56, 0.22),
		Vector3(0.24, 0.55, 0.54), Vector3(0.08, 0.68, 0.60), Vector3(0.40, 0.70, 0.26), Vector3(0.74, 0.69, 0.68),
		Vector3(0.92, 0.81, 0.76), Vector3(0.60, 0.84, 0.82), Vector3(0.26, 0.85, 0.90), Vector3(0.48, 0.96, 1.00)
	],
	"cliffside_trail": [
		Vector3(0.08, 0.04, 0.25), Vector3(0.14, 0.17, 0.34), Vector3(0.44, 0.12, 0.42), Vector3(0.78, 0.08, 0.50),
		Vector3(0.92, 0.20, 0.58), Vector3(0.86, 0.34, 0.64), Vector3(0.54, 0.29, 0.56), Vector3(0.20, 0.33, 0.48),
		Vector3(0.08, 0.47, 0.62), Vector3(0.38, 0.46, 0.70), Vector3(0.72, 0.48, 0.74), Vector3(0.94, 0.58, 0.80),
		Vector3(0.78, 0.70, 0.84), Vector3(0.46, 0.65, 0.78), Vector3(0.14, 0.67, 0.72), Vector3(0.08, 0.81, 0.86),
		Vector3(0.38, 0.82, 0.90), Vector3(0.70, 0.84, 0.94), Vector3(0.92, 0.94, 0.97), Vector3(0.54, 0.96, 1.00)
	],
	"spiral_terrain": [
		Vector3(0.08, 0.05, 0.12), Vector3(0.38, 0.04, 0.18), Vector3(0.70, 0.05, 0.24), Vector3(0.94, 0.12, 0.30),
		Vector3(0.94, 0.29, 0.36), Vector3(0.92, 0.47, 0.42), Vector3(0.92, 0.66, 0.48), Vector3(0.90, 0.84, 0.54),
		Vector3(0.68, 0.94, 0.60), Vector3(0.36, 0.95, 0.66), Vector3(0.08, 0.90, 0.70), Vector3(0.08, 0.72, 0.74),
		Vector3(0.08, 0.52, 0.78), Vector3(0.10, 0.32, 0.82), Vector3(0.34, 0.22, 0.85), Vector3(0.64, 0.23, 0.88),
		Vector3(0.68, 0.42, 0.91), Vector3(0.66, 0.62, 0.94), Vector3(0.38, 0.68, 0.97), Vector3(0.42, 0.46, 1.00)
	],
	"multi_platform_route": [
		Vector3(0.16, 0.05, 0.30), Vector3(0.48, 0.07, 0.45), Vector3(0.84, 0.06, 0.60), Vector3(0.72, 0.21, 0.52),
		Vector3(0.36, 0.20, 0.38), Vector3(0.08, 0.24, 0.55), Vector3(0.24, 0.38, 0.68), Vector3(0.58, 0.36, 0.62),
		Vector3(0.90, 0.37, 0.75), Vector3(0.78, 0.52, 0.82), Vector3(0.44, 0.51, 0.70), Vector3(0.10, 0.53, 0.64),
		Vector3(0.22, 0.68, 0.78), Vector3(0.56, 0.67, 0.85), Vector3(0.90, 0.68, 0.90), Vector3(0.76, 0.82, 0.88),
		Vector3(0.42, 0.81, 0.92), Vector3(0.10, 0.83, 0.86), Vector3(0.30, 0.95, 0.96), Vector3(0.68, 0.95, 1.00)
	],
	"landmark_approach": [
		Vector3(0.08, 0.05, 0.16), Vector3(0.90, 0.06, 0.18), Vector3(0.50, 0.12, 0.28), Vector3(0.16, 0.21, 0.34),
		Vector3(0.82, 0.22, 0.36), Vector3(0.48, 0.29, 0.46), Vector3(0.10, 0.38, 0.50), Vector3(0.88, 0.39, 0.52),
		Vector3(0.50, 0.45, 0.62), Vector3(0.20, 0.55, 0.68), Vector3(0.80, 0.56, 0.70), Vector3(0.48, 0.63, 0.78),
		Vector3(0.10, 0.72, 0.82), Vector3(0.88, 0.73, 0.84), Vector3(0.50, 0.79, 0.90), Vector3(0.22, 0.87, 0.93),
		Vector3(0.78, 0.88, 0.95), Vector3(0.10, 0.95, 0.97), Vector3(0.90, 0.95, 0.98), Vector3(0.50, 0.95, 1.00)
	],
	"chapter_gateway_transition": [
		Vector3(0.50, 0.04, 0.24), Vector3(0.14, 0.09, 0.30), Vector3(0.86, 0.10, 0.32), Vector3(0.32, 0.20, 0.40),
		Vector3(0.68, 0.21, 0.42), Vector3(0.10, 0.32, 0.48), Vector3(0.48, 0.34, 0.55), Vector3(0.88, 0.33, 0.52),
		Vector3(0.68, 0.47, 0.62), Vector3(0.30, 0.48, 0.64), Vector3(0.08, 0.59, 0.70), Vector3(0.48, 0.60, 0.76),
		Vector3(0.88, 0.58, 0.74), Vector3(0.70, 0.72, 0.82), Vector3(0.32, 0.73, 0.84), Vector3(0.10, 0.84, 0.88),
		Vector3(0.48, 0.84, 0.92), Vector3(0.88, 0.83, 0.90), Vector3(0.26, 0.95, 0.96), Vector3(0.68, 0.95, 1.00)
	]
}


const CHAPTER_OCEAN_BIOMES: Array[Dictionary] = [
	{"biome_id": "tropical_islands", "ocean_deep": Color(0.04, 0.34, 0.72, 1.0), "ocean_mid": Color(0.08, 0.56, 0.88, 1.0), "ocean_shallow": Color(0.18, 0.84, 0.94, 1.0), "beach_sand": Color(0.99, 0.90, 0.64, 1.0), "island_turf": Color(0.20, 0.80, 0.44, 1.0), "island_feature": "palm_groves"},
	{"biome_id": "coral_lagoon", "ocean_deep": Color(0.05, 0.38, 0.76, 1.0), "ocean_mid": Color(0.10, 0.64, 0.90, 1.0), "ocean_shallow": Color(0.26, 0.90, 0.92, 1.0), "beach_sand": Color(1.00, 0.86, 0.70, 1.0), "island_turf": Color(0.24, 0.84, 0.62, 1.0), "island_feature": "coral_reefs"},
	{"biome_id": "rocky_coast", "ocean_deep": Color(0.06, 0.28, 0.62, 1.0), "ocean_mid": Color(0.12, 0.48, 0.78, 1.0), "ocean_shallow": Color(0.24, 0.72, 0.88, 1.0), "beach_sand": Color(0.88, 0.82, 0.68, 1.0), "island_turf": Color(0.28, 0.74, 0.48, 1.0), "island_feature": "sea_stacks"},
	{"biome_id": "mangrove_islands", "ocean_deep": Color(0.04, 0.32, 0.58, 1.0), "ocean_mid": Color(0.08, 0.54, 0.72, 1.0), "ocean_shallow": Color(0.20, 0.78, 0.76, 1.0), "beach_sand": Color(0.92, 0.86, 0.58, 1.0), "island_turf": Color(0.14, 0.72, 0.48, 1.0), "island_feature": "mangrove_roots"},
	{"biome_id": "volcanic_islands", "ocean_deep": Color(0.08, 0.22, 0.52, 1.0), "ocean_mid": Color(0.14, 0.40, 0.72, 1.0), "ocean_shallow": Color(0.24, 0.66, 0.84, 1.0), "beach_sand": Color(0.84, 0.66, 0.48, 1.0), "island_turf": Color(0.88, 0.46, 0.20, 1.0), "island_feature": "volcanic_vents"},
	{"biome_id": "crystal_islands", "ocean_deep": Color(0.08, 0.30, 0.74, 1.0), "ocean_mid": Color(0.18, 0.54, 0.92, 1.0), "ocean_shallow": Color(0.38, 0.86, 1.00, 1.0), "beach_sand": Color(0.88, 0.96, 1.00, 1.0), "island_turf": Color(0.32, 0.76, 0.98, 1.0), "island_feature": "crystal_spires"},
	{"biome_id": "misty_islands", "ocean_deep": Color(0.08, 0.28, 0.58, 1.0), "ocean_mid": Color(0.18, 0.48, 0.78, 1.0), "ocean_shallow": Color(0.36, 0.74, 0.90, 1.0), "beach_sand": Color(0.90, 0.88, 0.78, 1.0), "island_turf": Color(0.30, 0.76, 0.64, 1.0), "island_feature": "mist_archipelago"},
	{"biome_id": "ancient_ruins", "ocean_deep": Color(0.05, 0.34, 0.68, 1.0), "ocean_mid": Color(0.12, 0.58, 0.84, 1.0), "ocean_shallow": Color(0.28, 0.82, 0.90, 1.0), "beach_sand": Color(0.96, 0.90, 0.72, 1.0), "island_turf": Color(0.34, 0.78, 0.54, 1.0), "island_feature": "sunken_colonnades"},
	{"biome_id": "stormy_coast", "ocean_deep": Color(0.05, 0.22, 0.50, 1.0), "ocean_mid": Color(0.10, 0.40, 0.70, 1.0), "ocean_shallow": Color(0.22, 0.68, 0.86, 1.0), "beach_sand": Color(0.84, 0.80, 0.70, 1.0), "island_turf": Color(0.24, 0.68, 0.58, 1.0), "island_feature": "tempest_beacons"},
	{"biome_id": "pearl_shallows", "ocean_deep": Color(0.06, 0.38, 0.78, 1.0), "ocean_mid": Color(0.14, 0.64, 0.92, 1.0), "ocean_shallow": Color(0.34, 0.90, 0.96, 1.0), "beach_sand": Color(1.00, 0.94, 0.76, 1.0), "island_turf": Color(0.28, 0.84, 0.54, 1.0), "island_feature": "giant_pearls"},
	{"biome_id": "bioluminescent_reef", "ocean_deep": Color(0.06, 0.24, 0.64, 1.0), "ocean_mid": Color(0.12, 0.48, 0.86, 1.0), "ocean_shallow": Color(0.24, 0.84, 0.98, 1.0), "beach_sand": Color(0.86, 0.92, 1.00, 1.0), "island_turf": Color(0.20, 0.82, 0.74, 1.0), "island_feature": "glow_corals"},
	{"biome_id": "jade_dragon_bay", "ocean_deep": Color(0.04, 0.34, 0.56, 1.0), "ocean_mid": Color(0.08, 0.58, 0.74, 1.0), "ocean_shallow": Color(0.22, 0.82, 0.80, 1.0), "beach_sand": Color(0.94, 0.88, 0.66, 1.0), "island_turf": Color(0.18, 0.76, 0.46, 1.0), "island_feature": "karst_pillars"},
	{"biome_id": "amber_sunset_keys", "ocean_deep": Color(0.08, 0.28, 0.66, 1.0), "ocean_mid": Color(0.16, 0.50, 0.84, 1.0), "ocean_shallow": Color(0.30, 0.78, 0.92, 1.0), "beach_sand": Color(1.00, 0.86, 0.58, 1.0), "island_turf": Color(0.36, 0.78, 0.42, 1.0), "island_feature": "sunset_palms"},
	{"biome_id": "glacier_fjord_isles", "ocean_deep": Color(0.06, 0.30, 0.70, 1.0), "ocean_mid": Color(0.16, 0.56, 0.88, 1.0), "ocean_shallow": Color(0.42, 0.88, 0.98, 1.0), "beach_sand": Color(0.90, 0.96, 1.00, 1.0), "island_turf": Color(0.36, 0.78, 0.88, 1.0), "island_feature": "ice_arches"},
	{"biome_id": "sapphire_trench_atoll", "ocean_deep": Color(0.03, 0.26, 0.68, 1.0), "ocean_mid": Color(0.08, 0.50, 0.86, 1.0), "ocean_shallow": Color(0.20, 0.80, 0.94, 1.0), "beach_sand": Color(0.96, 0.88, 0.66, 1.0), "island_turf": Color(0.22, 0.78, 0.56, 1.0), "island_feature": "whirlpool_rings"},
	{"biome_id": "crimson_hibiscus_cove", "ocean_deep": Color(0.06, 0.34, 0.72, 1.0), "ocean_mid": Color(0.12, 0.58, 0.88, 1.0), "ocean_shallow": Color(0.26, 0.84, 0.94, 1.0), "beach_sand": Color(1.00, 0.88, 0.68, 1.0), "island_turf": Color(0.26, 0.80, 0.48, 1.0), "island_feature": "hibiscus_blooms"},
	{"biome_id": "gilded_compass_strait", "ocean_deep": Color(0.05, 0.30, 0.66, 1.0), "ocean_mid": Color(0.12, 0.52, 0.82, 1.0), "ocean_shallow": Color(0.26, 0.78, 0.90, 1.0), "beach_sand": Color(0.98, 0.88, 0.60, 1.0), "island_turf": Color(0.30, 0.76, 0.46, 1.0), "island_feature": "compass_monuments"},
	{"biome_id": "sea_turtle_sanctuary", "ocean_deep": Color(0.04, 0.36, 0.70, 1.0), "ocean_mid": Color(0.10, 0.62, 0.86, 1.0), "ocean_shallow": Color(0.24, 0.88, 0.90, 1.0), "beach_sand": Color(0.98, 0.92, 0.68, 1.0), "island_turf": Color(0.18, 0.82, 0.50, 1.0), "island_feature": "lagoon_cays"},
	{"biome_id": "basalt_pillar_isles", "ocean_deep": Color(0.06, 0.26, 0.58, 1.0), "ocean_mid": Color(0.12, 0.46, 0.76, 1.0), "ocean_shallow": Color(0.24, 0.72, 0.86, 1.0), "beach_sand": Color(0.86, 0.78, 0.64, 1.0), "island_turf": Color(0.32, 0.72, 0.48, 1.0), "island_feature": "hex_basalt_columns"},
	{"biome_id": "opal_shell_shoals", "ocean_deep": Color(0.06, 0.36, 0.76, 1.0), "ocean_mid": Color(0.14, 0.62, 0.90, 1.0), "ocean_shallow": Color(0.32, 0.88, 0.96, 1.0), "beach_sand": Color(1.00, 0.90, 0.76, 1.0), "island_turf": Color(0.28, 0.82, 0.64, 1.0), "island_feature": "shell_terraces"},
	{"biome_id": "bamboo_lantern_harbor", "ocean_deep": Color(0.04, 0.32, 0.64, 1.0), "ocean_mid": Color(0.10, 0.56, 0.82, 1.0), "ocean_shallow": Color(0.22, 0.82, 0.88, 1.0), "beach_sand": Color(0.96, 0.88, 0.64, 1.0), "island_turf": Color(0.22, 0.78, 0.44, 1.0), "island_feature": "harbor_lanterns"},
	{"biome_id": "amethyst_tide_caverns", "ocean_deep": Color(0.08, 0.26, 0.66, 1.0), "ocean_mid": Color(0.16, 0.48, 0.86, 1.0), "ocean_shallow": Color(0.32, 0.78, 0.96, 1.0), "beach_sand": Color(0.92, 0.86, 0.96, 1.0), "island_turf": Color(0.46, 0.70, 0.94, 1.0), "island_feature": "amethyst_sea_caves"},
	{"biome_id": "sunburst_monolith_isles", "ocean_deep": Color(0.05, 0.32, 0.70, 1.0), "ocean_mid": Color(0.12, 0.56, 0.86, 1.0), "ocean_shallow": Color(0.26, 0.82, 0.92, 1.0), "beach_sand": Color(1.00, 0.88, 0.58, 1.0), "island_turf": Color(0.34, 0.80, 0.46, 1.0), "island_feature": "sun_monoliths"},
	{"biome_id": "celestial_horizon_sea", "ocean_deep": Color(0.06, 0.28, 0.72, 1.0), "ocean_mid": Color(0.14, 0.54, 0.90, 1.0), "ocean_shallow": Color(0.30, 0.84, 0.98, 1.0), "beach_sand": Color(0.96, 0.92, 0.78, 1.0), "island_turf": Color(0.28, 0.80, 0.68, 1.0), "island_feature": "starlight_piers"},
	{"biome_id": "royal_finale_island", "ocean_deep": Color(0.05, 0.30, 0.74, 1.0), "ocean_mid": Color(0.12, 0.56, 0.90, 1.0), "ocean_shallow": Color(0.28, 0.86, 0.98, 1.0), "beach_sand": Color(1.00, 0.92, 0.64, 1.0), "island_turf": Color(0.26, 0.82, 0.52, 1.0), "island_feature": "royal_citadel_harbor"}
]


func get_chapter_ocean_biome_spec(chapter_idx: int = 0) -> Dictionary:
	var md: MapData = get_map_data()
	var page: MapPage = md.get_page(chapter_idx)
	if page != null and page.theme != null:
		var pal: Dictionary = page.theme.palette
		return {
			"biome_id": page.theme.theme_id,
			"ocean_deep": pal.get("ground_primary", Color(0.04, 0.36, 0.74, 1.0)),
			"ocean_mid": pal.get("water_color", Color(0.08, 0.56, 0.88, 1.0)),
			"ocean_shallow": pal.get("ground_secondary", Color(0.16, 0.78, 0.92, 1.0)),
			"beach_sand": pal.get("shore_color", Color(0.99, 0.90, 0.64, 1.0)),
			"island_turf": pal.get("island_surface", Color(0.22, 0.80, 0.46, 1.0)),
			"island_feature": page.theme.landmark_types[0] if not page.theme.landmark_types.is_empty() else "harbor_lighthouse"
		}
	var idx: int = posmod(chapter_idx, CHAPTER_OCEAN_BIOMES.size())
	return CHAPTER_OCEAN_BIOMES[idx].duplicate(true)


func get_chapter_path_archetype(chapter_idx: int = 0) -> String:
	var md: MapData = get_map_data()
	var page: MapPage = md.get_page(chapter_idx)
	if page != null and page.composition_type != "":
		return page.composition_type
	var idx: int = posmod(chapter_idx, CHAPTER_PATH_ARCHETYPES.size())
	return CHAPTER_PATH_ARCHETYPES[idx]


## Returns the world destination specification for a specific level (1..500) from MapData/MapPage/MapNode.
func get_level_world_destination_spec(lvl: int) -> Dictionary:
	var safe_lvl: int = clampi(lvl, 1, TOTAL_LEVELS)
	var md: MapData = get_map_data()
	var page_idx: int = md.get_page_index_for_level(safe_lvl)
	var page: MapPage = get_map_page_object(page_idx)
	var nd: MapNode = page.get_node_for_level(safe_lvl) if page != null else null
	var local_idx: int = nd.local_index if nd != null else 0
	var theme_obj: MapTheme = page.theme if (page != null and page.theme != null) else MapTheme.from_preset("ocean_islands")
	var uv: Vector2 = nd.uv_position if nd != null else Vector2(0.5, 0.5)
	var elev: float = nd.elevation if nd != null else 0.3
	var is_ms: bool = nd.is_milestone_node() if nd != null else false
	var dest_arch: String = String(nd.landmark.get("destination_style", "sandy_cay_island")) if nd != null else "sandy_cay_island"
	var lm_type: String = String(nd.landmark.get("landmark_type", "harbor_lighthouse")) if nd != null else "harbor_lighthouse"
	var seg_style: String = String(nd.route_connection.get("segment_style", theme_obj.path_style)) if nd != null else theme_obj.path_style
	var zone_idx: int = int(local_idx / 2)
	return {
		"level": safe_lvl,
		"level_id": safe_lvl,
		"local_idx": local_idx,
		"page_id": page.page_id if page != null else ("page_%d" % (page_idx + 1)),
		"page_idx": page_idx,
		"chapter_idx": page_idx,
		"path_archetype": page.composition_type if page != null else "sweeping_arc",
		"ocean_biome_id": theme_obj.theme_id,
		"theme_id": theme_obj.theme_id,
		"is_island_destination": true,
		"is_milestone_island": is_ms,
		"island_landmark": lm_type,
		"uv": uv,
		"elevation_z": elev,
		"destination_architecture": dest_arch,
		"route_segment_to_next": seg_style,
		"terrain_host_id": "%s_terrain_mass_%d" % [page.page_id if page != null else "page_1", zone_idx],
		"terrain_surface_type": theme_obj.terrain_style,
		"is_integrated_in_world": true
	}


## Returns the complete connected world geometry specification for a MapPage.
func get_chapter_world_geometry(chapter_idx: int = 0) -> Dictionary:
	var md: MapData = get_map_data()
	var safe_ch: int = clampi(chapter_idx, 0, maxi(0, md.get_page_count() - 1))
	var page: MapPage = get_map_page_object(safe_ch)
	var env: Dictionary = get_chapter_environment(safe_ch)
	var archetype: String = page.composition_type if page != null else "sweeping_arc"
	var destinations: Array = []
	var route_segments: Array = []
	var terrain_masses: Dictionary = {}
	var distinct_dest_arch: Dictionary = {}
	var distinct_route_types: Dictionary = {}

	var lv_list: Array[int] = page.level_ids if page != null else [1, 2, 3, 4, 5, 6]
	for i in range(lv_list.size()):
		var lvl_num: int = lv_list[i]
		var d_spec: Dictionary = get_level_world_destination_spec(lvl_num)
		destinations.append(d_spec)
		distinct_dest_arch[String(d_spec.get("destination_architecture", ""))] = true
		var host_id: String = String(d_spec.get("terrain_host_id", ""))
		if not terrain_masses.has(host_id):
			terrain_masses[host_id] = {
				"id": host_id,
				"surface_type": d_spec.get("terrain_surface_type", "atoll_islands"),
				"elevation_z": d_spec.get("elevation_z", 0.3),
				"hosted_levels": [],
				"center_uv": d_spec.get("uv", Vector2(0.5, 0.5))
			}
		terrain_masses[host_id]["hosted_levels"].append(lvl_num)
		if i < lv_list.size() - 1:
			var next_lvl: int = lv_list[i + 1]
			var next_spec: Dictionary = get_level_world_destination_spec(next_lvl)
			var seg_t: String = String(d_spec.get("route_segment_to_next", "sea_stepping_stones"))
			distinct_route_types[seg_t] = true
			route_segments.append({
				"from_level": lvl_num,
				"to_level": next_lvl,
				"from_uv": d_spec.get("uv", Vector2.ZERO),
				"to_uv": next_spec.get("uv", Vector2.ZERO),
				"from_elevation": d_spec.get("elevation_z", 0.2),
				"to_elevation": next_spec.get("elevation_z", 0.3),
				"segment_type": seg_t,
				"is_physical_3d_structure": true
			})

	return {
		"page_id": page.page_id if page != null else ("page_%d" % (safe_ch + 1)),
		"page_index": safe_ch,
		"page_number": safe_ch + 1,
		"chapter_index": safe_ch,
		"chapter_number": safe_ch + 1,
		"level_count": lv_list.size(),
		"start_level": page.start_level if page != null else 1,
		"end_level": page.end_level if page != null else lv_list.size(),
		"world_title_en": env.get("world_title_en", ""),
		"biome_type": env.get("biome_type", ""),
		"theme_id": env.get("theme_id", ""),
		"is_theme_coherent": page.is_theme_coherent() if page != null else true,
		"path_archetype": archetype,
		"terrain_masses": terrain_masses.values(),
		"water_bodies": [
			{"id": "primary_waterway", "type": env.get("waterway_type", "sunlit_sea_breeze"), "y_band": Vector2(0.18, 0.34)}
		],
		"chapter_gateways": {
			"entry_gateway": {"level": lv_list[0] if not lv_list.is_empty() else 1, "type": "region_entry_archway"},
			"exit_gateway": {"level": lv_list[lv_list.size() - 1] if not lv_list.is_empty() else 1, "type": "page_transition_citadel_gate"}
		},
		"destinations": destinations,
		"route_segments": route_segments,
		"distinct_destination_architectures": distinct_dest_arch.keys(),
		"distinct_route_segment_types": distinct_route_types.keys(),
		"decorative_branches": get_chapter_decorative_branches(safe_ch),
		"is_background_plus_2d_polyline_only": false,
		"levels_exist_inside_world_terrain": true
	}


func get_chapter_decorative_branches(chapter_idx: int = 0) -> Array:
	var md: MapData = get_map_data()
	var safe_ch: int = clampi(chapter_idx, 0, maxi(0, md.get_page_count() - 1))
	var page: MapPage = get_map_page_object(safe_ch)
	if page != null and not page.background_landmarks.is_empty():
		return page.background_landmarks.duplicate(true)
	return []


func get_deterministic_map_node_pos(lvl: int, _local_idx_override: int = -1, _chapter_idx_override: int = -1) -> Vector2:
	var safe_lvl: int = clampi(lvl, 1, TOTAL_LEVELS)
	var md: MapData = get_map_data()
	var p_idx: int = _chapter_idx_override if _chapter_idx_override >= 0 else md.get_page_index_for_level(safe_lvl)
	var page: MapPage = get_map_page_object(p_idx)
	if page != null:
		var nd: MapNode = page.get_node_for_level(safe_lvl)
		if nd == null and _local_idx_override >= 0 and _local_idx_override < page.nodes.size():
			nd = page.nodes[_local_idx_override]
		if nd != null:
			return nd.uv_position
	return Vector2(0.5, 0.5)


func get_next_milestone_level(from_lvl: int = highest_unlocked_level) -> int:
	var start_l := clampi(from_lvl, 1, TOTAL_LEVELS)
	for i in range(start_l, TOTAL_LEVELS + 1):
		var mt := get_level_milestone_type(i)
		if mt != "" and (i > start_l or not is_level_completed(i)):
			return i
	return TOTAL_LEVELS


func get_level_target_score(lvl: int = active_level) -> int:
	var safe_lvl = clampi(lvl, 1, TOTAL_LEVELS)
	if LEVEL_TARGETS.has(safe_lvl):
		return int(LEVEL_TARGETS[safe_lvl])
	return 2300 + (safe_lvl - 5) * 350


## Consistent 3-Star rating calculation against level target score:
##   - 0 stars: score < target
##   - 1 star (★☆☆): score >= target (100% of target)
##   - 2 stars (★★☆): score >= int(target * 1.25) (125% of target)
##   - 3 stars (★★★): score >= int(target * 1.50) (150% of target)
func calculate_stars_for_score(score_val: int, lvl: int = active_level) -> int:
	var target: int = get_level_target_score(lvl)
	if score_val < target:
		return 0
	elif score_val >= int(float(target) * 1.50):
		return 3
	elif score_val >= int(float(target) * 1.25):
		return 2
	return 1


func format_stars_string(stars_count: int) -> String:
	var s := clampi(stars_count, 0, 3)
	match s:
		3: return "* * *"
		2: return "* * -"
		1: return "* - -"
		_: return "- - -"


func get_level_progress_ratio() -> float:
	var target = float(max(1, get_level_target_score(active_level)))
	return clamp(float(score) / target, 0.0, 1.0)


func get_current_session_stars() -> int:
	return calculate_stars_for_score(score, active_level)


## Records level completion, updates best stars (never downgrading), unlocks next level (up to 500), grants reward, and saves locally.
func record_level_completion(lvl: int, achieved_score: int) -> Dictionary:
	var target: int = get_level_target_score(lvl)
	var effective_score: int = max(achieved_score, target)
	var stars_earned: int = calculate_stars_for_score(effective_score, lvl)
	
	completed_levels[lvl] = true
	var prev_best: int = int(level_stars.get(lvl, 0))
	if stars_earned > prev_best:
		level_stars[lvl] = stars_earned
	
	var unlocked_next: int = min(TOTAL_LEVELS, lvl + 1)
	var did_unlock_new: bool = false
	if unlocked_next > highest_unlocked_level:
		highest_unlocked_level = unlocked_next
		newly_unlocked_level = unlocked_next
		did_unlock_new = true
	
	var reward_coins: int = 40 + (stars_earned * 20)
	coins += reward_coins
	last_reward_coins = reward_coins
	last_session_stars = stars_earned
	last_completed_level = lvl
	
	_recalculate_total_stars()
	save_progression()
	
	var result := {
		"level_complete": true,
		"completed_level": lvl,
		"next_level": unlocked_next,
		"did_unlock_new": did_unlock_new,
		"stars": stars_earned,
		"best_stars": int(level_stars.get(lvl, stars_earned)),
		"stars_display": format_stars_string(stars_earned),
		"score": achieved_score,
		"target_score": target,
		"coins_earned": reward_coins,
		"reward_text": "+%d Coins" % reward_coins
	}
	level_completed.emit(lvl, stars_earned, reward_coins)
	progression_updated.emit(highest_unlocked_level, total_stars, coins)
	return result


## Returns level descriptors for any slice of the 500-level progression map
func get_world_map_levels(count: int = 6, start_level: int = 1) -> Array:
	var result: Array = []
	var safe_start: int = clampi(start_level, 1, TOTAL_LEVELS)
	var end_lvl: int = min(TOTAL_LEVELS, safe_start + max(1, count) - 1)
	var md: MapData = get_map_data()
	for i in range(safe_start, end_lvl + 1):
		var is_unlocked: bool = is_level_unlocked(i)
		var is_comp: bool = is_level_completed(i)
		var best_s: int = get_level_best_stars(i)
		var is_curr: bool = (i == highest_unlocked_level)
		var state_label: String = "locked"
		if is_comp:
			state_label = "completed"
		elif is_curr:
			state_label = "current"
		elif is_unlocked:
			state_label = "unlocked"

		var page_idx: int = md.get_page_index_for_level(i)
		var page: MapPage = get_map_page_object(page_idx)
		var nd: MapNode = page.get_node_for_level(i) if page != null else null
		var local_idx: int = nd.local_index if nd != null else (i - safe_start)
		var path_row: int = int(local_idx / 2)
		var col_in_row: int = local_idx % 2
		var winding_col: int = col_in_row if (path_row % 2 == 0) else (1 - col_in_row)
		var m_type: String = get_level_milestone_type(i)
		var m_icon: String = get_level_milestone_icon(i, is_unlocked)
		var env_data: Dictionary = get_chapter_environment(page_idx)
		var organic_uv: Vector2 = nd.uv_position if nd != null else Vector2(0.5, 0.5)
		var visual_spec: Dictionary = get_milestone_visual_spec(m_type)
		var world_dest: Dictionary = get_level_world_destination_spec(i)
		var is_ms: bool = (nd != null and nd.is_milestone_node()) or (m_type != "")

		result.append({
			"level": i,
			"level_id": i,
			"page_id": page.page_id if page != null else ("page_%d" % (page_idx + 1)),
			"page_index": page_idx,
			"page_number": page_idx + 1,
			"local_index": local_idx,
			"title": get_level_title(i),
			"target_score": get_level_target_score(i),
			"stars": best_s,
			"stars_display": format_stars_string(best_s),
			"completed": is_comp,
			"current": is_curr,
			"unlocked": is_unlocked,
			"locked": not is_unlocked,
			"state": state_label,
			"is_selected": (i == selected_map_level),
			"newly_unlocked": (i == newly_unlocked_level),
			"path_row": path_row,
			"winding_col": winding_col,
			"position": nd.position if nd != null else Vector2.ZERO,
			"uv_position": organic_uv,
			"organic_u": organic_uv.x,
			"organic_v": organic_uv.y,
			"elevation_z": float(world_dest.get("elevation_z", 0.25)),
			"node_type": nd.node_type if nd != null else ("milestone" if is_ms else "normal"),
			"milestone": nd.milestone.duplicate(true) if nd != null else {},
			"landmark": nd.landmark.duplicate(true) if nd != null else {},
			"route_connection": nd.route_connection.duplicate(true) if nd != null else {},
			"destination_architecture": String(world_dest.get("destination_architecture", "sandy_cay_island")),
			"route_segment_to_next": String(world_dest.get("route_segment_to_next", "sea_stepping_stones")),
			"terrain_host_id": String(world_dest.get("terrain_host_id", "page_1_terrain_mass_0")),
			"terrain_surface_type": String(world_dest.get("terrain_surface_type", "atoll_islands")),
			"ocean_biome_id": String(world_dest.get("ocean_biome_id", "ocean_islands")),
			"theme_id": String(env_data.get("theme_id", "ocean_islands")),
			"is_island_destination": true,
			"is_milestone_island": is_ms,
			"island_landmark": String(world_dest.get("island_landmark", "harbor_lighthouse")),
			"milestone_type": m_type,
			"milestone_icon": m_icon,
			"is_milestone": is_ms,
			"visual_tier": int(visual_spec.get("visual_tier", 0)),
			"scale_mult": nd.get_scale_multiplier() if nd != null else 1.0,
			"environment_id": String(env_data.get("id", "ocean_islands"))
		})
	return result


## Returns a MapPage's level descriptors (data-driven 5–10 levels per page by default;
## if an explicit custom page_size > 0 is passed, slices by page_size).
func get_level_map_page(page_index: int = 0, page_size: int = -1) -> Array:
	if page_size <= 0:
		var md: MapData = get_map_data()
		var page: MapPage = md.get_page(page_index)
		if page != null:
			return get_world_map_levels(page.get_level_count(), page.start_level)
	var total_pages: int = get_level_map_page_count(page_size)
	var clamped_page: int = clampi(page_index, 0, total_pages - 1)
	var start_lvl: int = clamped_page * page_size + 1
	return get_world_map_levels(page_size, start_lvl)


func get_level_map_page_count(page_size: int = -1) -> int:
	if page_size <= 0:
		return get_map_data().get_page_count()
	return int(ceil(float(TOTAL_LEVELS) / float(max(1, page_size))))


# ==============================================================================
# DAILY GIFT = LUCKY WHEEL (SPECIAL-ITEM REWARDS ONLY, 1 FREE SPIN PER DAY)
# ==============================================================================

func get_lucky_wheel_slices() -> Array:
	return LUCKY_WHEEL_SLICES.duplicate(true)


func get_lucky_wheel_unique_item_wedges() -> Array:
	var seen: Dictionary = {}
	var unique_items: Array = []
	for sl in LUCKY_WHEEL_SLICES:
		var rt: String = String(sl.get("reward_type", ""))
		if rt != "lucky_next_time" and not seen.has(rt):
			seen[rt] = true
			unique_items.append(sl.duplicate(true))
	return unique_items


func get_lucky_wheel_reward_description(reward_type: String, lang: String = current_language) -> Dictionary:
	var use_vi: bool = (lang.to_lower() == "vi")
	match reward_type:
		"bomb":
			return {
				"title": "BOM" if use_vi else "BOMB",
				"quantity_text": "×1",
				"description": "Xóa vùng 3×3 trên bảng" if use_vi else "Clear a 3×3 area"
			}
		"change_block":
			return {
				"title": "ĐỔI KHỐI" if use_vi else "CHANGE BLOCK",
				"quantity_text": "×1",
				"description": "Đổi một khối đang chọn" if use_vi else "Replace one selected block"
			}
		"extra_life":
			return {
				"title": "MẠNG THÊM" if use_vi else "EXTRA LIFE",
				"quantity_text": "×1",
				"description": "Hồi phục sau khi thua" if use_vi else "Recover after Game Over"
			}
		"spin_again", "extra_spin":
			return {
				"title": "QUAY LẠI LẦN NỮA" if use_vi else "SPIN AGAIN",
				"quantity_text": "+1",
				"description": "Nhận thêm 1 lượt quay miễn phí" if use_vi else "Get 1 extra free spin"
			}
		_:
			return {
				"title": "Chúc bạn may mắn lần sau" if use_vi else "LUCKY NEXT TIME",
				"quantity_text": "",
				"description": "Chúc bạn may mắn lần sau" if use_vi else "No reward this time"
			}


## Checks whether a new calendar day has arrived since last_daily_gift_date.
## If so, resets daily_reward_claimed = false and lucky_wheel_free_spins = 1.
func check_daily_gift_date_reset(current_date_str: String = "") -> bool:
	if current_date_str != "":
		_simulated_date_str = current_date_str
	var today: String = current_date_str if current_date_str != "" else (_simulated_date_str if _simulated_date_str != "" else get_today_date_string())
	if last_daily_gift_date != "" and today > last_daily_gift_date:
		daily_reward_claimed = false
		lucky_wheel_free_spins = 1
		lucky_wheel_extra_spins = 0
		lucky_wheel_consecutive_extra_spins = 0
	elif not daily_reward_claimed:
		lucky_wheel_free_spins = 1
	else:
		lucky_wheel_free_spins = lucky_wheel_extra_spins
	return (not daily_reward_claimed) or (lucky_wheel_extra_spins > 0)


func can_claim_daily_gift_today(current_date_str: String = "") -> bool:
	return check_daily_gift_date_reset(current_date_str)


func can_spin_lucky_wheel(current_date_str: String = "") -> bool:
	return check_daily_gift_date_reset(current_date_str)


func spin_daily_gift_wheel(forced_slice_index: int = -1, current_date_str: String = "") -> Dictionary:
	if current_date_str != "":
		_simulated_date_str = current_date_str
	var today: String = current_date_str if current_date_str != "" else (_simulated_date_str if _simulated_date_str != "" else get_today_date_string())
	check_daily_gift_date_reset(today)
	
	if daily_reward_claimed and lucky_wheel_extra_spins <= 0:
		return {
			"success": false,
			"claimed": false,
			"reason": "already_claimed_today",
			"date": today,
			"free_spins": 0,
			"message": tr_text("daily_already_toast")
		}
	
	if lucky_wheel_extra_spins > 0:
		lucky_wheel_extra_spins -= 1
	
	var slice_count: int = LUCKY_WHEEL_SLICES.size()
	var idx: int = forced_slice_index if (forced_slice_index >= 0 and forced_slice_index < slice_count) else (randi() % slice_count)
	var slice: Dictionary = LUCKY_WHEEL_SLICES[idx]
	var r_type: String = String(slice.get("reward_type", "bomb"))
	var amount: int = int(slice.get("amount", 1))
	var is_vi_lang: bool = (current_language == "vi")
	var label_str: String = String(slice.get("label_vi" if is_vi_lang else "label_en", "BOMB"))
	var desc_str: String = String(slice.get("desc_vi" if is_vi_lang else "desc_en", ""))
	
	var is_no_reward: bool = (r_type == "lucky_next_time" or amount <= 0)
	var is_extra_spin: bool = (r_type == "spin_again" or r_type == "extra_spin")
	
	if is_extra_spin:
		# Prevent infinite loop: cap consecutive extra spins to max 2 in a row
		if lucky_wheel_consecutive_extra_spins < 2:
			lucky_wheel_extra_spins += 1
			lucky_wheel_consecutive_extra_spins += 1
			daily_reward_claimed = false
		else:
			# If loop threshold reached, convert to generous 50 coins instead of extra spin
			coins += 50
	else:
		lucky_wheel_consecutive_extra_spins = 0
		if not is_no_reward and (r_type in MODERN_ITEM_TYPES):
			persistent_bonus_items[r_type] = int(persistent_bonus_items.get(r_type, 0)) + amount
			if has_special_items(current_mode):
				special_item_inventory[r_type] = int(special_item_inventory.get(r_type, 0)) + amount
				special_item_inventory_changed.emit(special_item_inventory.duplicate())
		if lucky_wheel_extra_spins <= 0:
			daily_reward_claimed = true
	
	last_daily_gift_date = today
	lucky_wheel_free_spins = lucky_wheel_extra_spins
	lucky_wheel_total_spins += 1
	save_progression()
	
	var reward_display: String = label_str if (is_no_reward or is_extra_spin) else ("%s ×%d" % [label_str, amount])
	var msg_str: String = label_str if is_no_reward else (tr_text("daily_claimed_toast") % reward_display)
	var res := {
		"success": true,
		"claimed": true,
		"slice_index": idx,
		"reward_type": r_type,
		"item_id": r_type,
		"amount": 0 if is_no_reward else amount,
		"is_lucky_next_time": is_no_reward,
		"is_extra_spin": is_extra_spin,
		"label": label_str,
		"description": desc_str,
		"short_text": String(slice.get("short_text", label_str)),
		"used_free_spin": true,
		"remaining_free_spins": lucky_wheel_extra_spins,
		"extra_spins": lucky_wheel_extra_spins,
		"date": today,
		"total_spins": lucky_wheel_total_spins,
		"message": msg_str
	}
	last_lucky_wheel_result = res.duplicate()
	progression_updated.emit(highest_unlocked_level, total_stars, coins)
	reward_claimed.emit(res)
	lucky_wheel_spun.emit(res)
	return res


func spin_lucky_wheel(forced_slice_index: int = -1, current_date_str: String = "") -> Dictionary:
	return spin_daily_gift_wheel(forced_slice_index, current_date_str)


func claim_daily_reward(forced_slice_index: int = -1, current_date_str: String = "") -> Dictionary:
	return spin_daily_gift_wheel(forced_slice_index, current_date_str)


# ==============================================================================
# ENERGY SYSTEM (MAX 24, +1/HOUR REGEN, 1/DAY CALENDAR REFILL, +1 REWARDED AD)
# ==============================================================================

func get_current_unix_time(override_unix_sec: int = -1) -> int:
	if override_unix_sec >= 0:
		_simulated_unix_time = override_unix_sec
		return _simulated_unix_time
	if _simulated_unix_time >= 0:
		return _simulated_unix_time
	return int(Time.get_unix_time_from_system())


func advance_simulated_time_seconds(delta_sec: int) -> int:
	var base_ts: int = get_current_unix_time()
	_simulated_unix_time = base_ts + maxi(0, delta_sec)
	update_energy_regeneration(_simulated_unix_time)
	return _simulated_unix_time


func get_energy() -> int:
	update_energy_regeneration()
	return energy


func get_max_energy() -> int:
	return MAX_ENERGY


func get_energy_status_text() -> String:
	return "%d/%d" % [get_energy(), MAX_ENERGY]


func set_energy(val: int, save_to_disk: bool = true) -> void:
	var now_ts: int = get_current_unix_time()
	var clamped: int = clampi(val, 0, MAX_ENERGY)
	if clamped < MAX_ENERGY and (energy >= MAX_ENERGY or last_energy_regen_timestamp <= 0):
		last_energy_regen_timestamp = now_ts
	elif clamped >= MAX_ENERGY:
		last_energy_regen_timestamp = now_ts
	energy = clamped
	if save_to_disk:
		save_progression()
	energy_changed.emit(energy, MAX_ENERGY)


func check_daily_energy_refill(current_date_str: String = "") -> bool:
	if current_date_str != "":
		_simulated_date_str = current_date_str
	var today: String = current_date_str if current_date_str != "" else (_simulated_date_str if _simulated_date_str != "" else get_today_date_string())
	if last_energy_daily_refill_date == "":
		last_energy_daily_refill_date = today
		if energy < MAX_ENERGY:
			energy = MAX_ENERGY
			last_energy_regen_timestamp = get_current_unix_time()
			save_progression()
			energy_changed.emit(energy, MAX_ENERGY)
			return true
		save_progression()
		return false
	if today > last_energy_daily_refill_date:
		last_energy_daily_refill_date = today
		if energy < MAX_ENERGY:
			energy = MAX_ENERGY
			last_energy_regen_timestamp = get_current_unix_time()
			save_progression()
			energy_changed.emit(energy, MAX_ENERGY)
			return true
		save_progression()
	return false


func update_energy_regeneration(current_unix_sec: int = -1, current_date_str: String = "") -> int:
	if current_date_str != "":
		_simulated_date_str = current_date_str
		check_daily_energy_refill(current_date_str)
	var now_ts: int = get_current_unix_time(current_unix_sec)
	if energy >= MAX_ENERGY:
		energy = MAX_ENERGY
		last_energy_regen_timestamp = now_ts
		return 0
	if last_energy_regen_timestamp <= 0:
		last_energy_regen_timestamp = now_ts
		return 0
	var elapsed: int = now_ts - last_energy_regen_timestamp
	if elapsed < ENERGY_REGEN_INTERVAL_SEC:
		return 0
	var hours_passed: int = int(elapsed / ENERGY_REGEN_INTERVAL_SEC)
	var prev_energy: int = energy
	energy = mini(MAX_ENERGY, energy + hours_passed)
	if energy >= MAX_ENERGY:
		last_energy_regen_timestamp = now_ts
	else:
		last_energy_regen_timestamp += hours_passed * ENERGY_REGEN_INTERVAL_SEC
	var gained: int = energy - prev_energy
	if gained > 0:
		save_progression()
		energy_changed.emit(energy, MAX_ENERGY)
	return gained


func can_start_level_with_energy() -> bool:
	update_energy_regeneration()
	return energy > 0


func can_start_play_session() -> bool:
	return can_start_level_with_energy()


func claim_energy_rewarded_ad(ad_completed: bool = true, ad_session_id: String = "") -> Dictionary:
	return watch_rewarded_ad_for_energy(ad_completed, ad_session_id)


func consume_energy_for_play(amount: int = 1) -> bool:
	update_energy_regeneration()
	if amount <= 0 or energy < amount:
		return false
	var was_at_max: bool = (energy >= MAX_ENERGY)
	energy = maxi(0, energy - amount)
	if was_at_max or last_energy_regen_timestamp <= 0:
		last_energy_regen_timestamp = get_current_unix_time()
	save_progression()
	energy_changed.emit(energy, MAX_ENERGY)
	return true


func open_rewarded_ad_for_energy() -> String:
	if not rewarded_ad_controller:
		rewarded_ad_controller = RewardedAdScript.new()
	return rewarded_ad_controller.open_fullscreen_ad("energy")


func complete_rewarded_ad_for_energy(ad_session_id: String = "") -> Dictionary:
	if not rewarded_ad_controller:
		rewarded_ad_controller = RewardedAdScript.new()
	var sid: String = ad_session_id if ad_session_id != "" else String(rewarded_ad_controller.active_session_id)
	if sid != "" and _claimed_ad_sessions.has(sid):
		return {"granted": false, "reason": "duplicate_ad_session", "energy": energy, "max_energy": MAX_ENERGY}
	var ad_res: Dictionary = rewarded_ad_controller.complete_fullscreen_ad(sid)
	if not bool(ad_res.get("completed", false)):
		return {"granted": false, "reason": String(ad_res.get("reason", "ad_not_completed")), "energy": energy, "max_energy": MAX_ENERGY}
	return watch_rewarded_ad_for_energy(true, String(ad_res.get("session_id", sid)))


func skip_rewarded_ad_for_energy() -> Dictionary:
	if rewarded_ad_controller:
		rewarded_ad_controller.skip_or_close_fullscreen_ad()
	return watch_rewarded_ad_for_energy(false, "")


func watch_rewarded_ad_for_energy(ad_completed: bool = true, ad_session_id: String = "") -> Dictionary:
	update_energy_regeneration()
	if not ad_completed:
		return {
			"granted": false,
			"amount": 0,
			"reason": "ad_skipped_or_closed_early",
			"energy": energy,
			"max_energy": MAX_ENERGY
		}
	if ad_session_id != "" and _claimed_ad_sessions.has(ad_session_id):
		return {
			"granted": false,
			"amount": 0,
			"reason": "duplicate_ad_session",
			"energy": energy,
			"max_energy": MAX_ENERGY
		}
	if energy >= MAX_ENERGY:
		if ad_session_id != "":
			_claimed_ad_sessions[ad_session_id] = true
		return {
			"granted": false,
			"amount": 0,
			"reason": "already_at_max_energy",
			"energy": energy,
			"max_energy": MAX_ENERGY
		}
	if ad_session_id != "":
		_claimed_ad_sessions[ad_session_id] = true
	energy = mini(MAX_ENERGY, energy + 1)
	if energy >= MAX_ENERGY:
		last_energy_regen_timestamp = get_current_unix_time()
	save_progression()
	energy_changed.emit(energy, MAX_ENERGY)
	rewarded_ad_completed.emit("energy", 1)
	return {
		"granted": true,
		"amount": 1,
		"energy": energy,
		"max_energy": MAX_ENERGY
	}


# ==============================================================================
# MODERN SPECIAL ITEMS, DAILY REWARDED ADS & RANDOM DISCOVERY
# ==============================================================================

func should_show_special_item_plus_button(item_id: String) -> bool:
	if not (item_id in MODERN_ITEM_TYPES):
		return false
	return get_special_item_count(item_id) == 0


func has_used_daily_special_item_ad(item_id: String, current_date_str: String = "") -> bool:
	if current_date_str != "":
		_simulated_date_str = current_date_str
	if not (item_id in MODERN_ITEM_TYPES):
		return true
	var today: String = current_date_str if current_date_str != "" else (_simulated_date_str if _simulated_date_str != "" else get_today_date_string())
	var last_d: String = String(last_special_item_ad_dates.get(item_id, ""))
	return last_d != "" and last_d >= today


func can_watch_ad_for_special_item(item_id: String, current_date_str: String = "") -> bool:
	if current_date_str != "":
		_simulated_date_str = current_date_str
	if not has_special_items(current_mode) or not (item_id in MODERN_ITEM_TYPES):
		return false
	if get_special_item_count(item_id) > 0:
		return false
	return not has_used_daily_special_item_ad(item_id, current_date_str)


func open_rewarded_ad_for_special_item(item_id: String, current_date_str: String = "") -> String:
	if not can_watch_ad_for_special_item(item_id, current_date_str):
		return ""
	if not rewarded_ad_controller:
		rewarded_ad_controller = RewardedAdScript.new()
	return rewarded_ad_controller.open_fullscreen_ad(item_id)


func complete_rewarded_ad_for_special_item(item_id: String, current_date_str: String = "", ad_session_id: String = "") -> Dictionary:
	if not rewarded_ad_controller:
		rewarded_ad_controller = RewardedAdScript.new()
	var sid: String = ad_session_id if ad_session_id != "" else String(rewarded_ad_controller.active_session_id)
	if sid != "" and _claimed_ad_sessions.has(sid):
		return {"granted": false, "amount": 0, "reason": "duplicate_ad_session", "item_id": item_id, "quantity": get_special_item_count(item_id)}
	var ad_res: Dictionary = rewarded_ad_controller.complete_fullscreen_ad(sid)
	if not bool(ad_res.get("completed", false)):
		return {"granted": false, "amount": 0, "reason": String(ad_res.get("reason", "ad_not_completed")), "item_id": item_id, "quantity": get_special_item_count(item_id)}
	return watch_rewarded_ad_for_special_item(item_id, true, current_date_str, String(ad_res.get("session_id", sid)))


func skip_rewarded_ad_for_special_item(item_id: String) -> Dictionary:
	if rewarded_ad_controller:
		rewarded_ad_controller.skip_or_close_fullscreen_ad()
	return watch_rewarded_ad_for_special_item(item_id, false, "", "")


func watch_rewarded_ad_for_special_item(item_id: String, ad_completed: bool = true, current_date_str: String = "", ad_session_id: String = "") -> Dictionary:
	if current_date_str != "":
		_simulated_date_str = current_date_str
	var today: String = current_date_str if current_date_str != "" else (_simulated_date_str if _simulated_date_str != "" else get_today_date_string())
	if not (item_id in MODERN_ITEM_TYPES) or not has_special_items(current_mode):
		return {"granted": false, "amount": 0, "reason": "invalid_item_or_mode", "item_id": item_id}
	if not ad_completed:
		return {"granted": false, "amount": 0, "reason": "ad_skipped_or_closed_early", "item_id": item_id, "quantity": get_special_item_count(item_id)}
	if ad_session_id != "" and _claimed_ad_sessions.has(ad_session_id):
		return {"granted": false, "amount": 0, "reason": "duplicate_ad_session", "item_id": item_id, "quantity": get_special_item_count(item_id)}
	if get_special_item_count(item_id) > 0:
		return {"granted": false, "amount": 0, "reason": "inventory_not_zero", "item_id": item_id, "quantity": get_special_item_count(item_id)}
	if has_used_daily_special_item_ad(item_id, today):
		return {"granted": false, "amount": 0, "reason": "daily_ad_allowance_used", "item_id": item_id, "quantity": get_special_item_count(item_id)}
	if ad_session_id != "":
		_claimed_ad_sessions[ad_session_id] = true
	last_special_item_ad_dates[item_id] = today
	var new_qty: int = add_special_item(item_id, 1)
	save_progression()
	rewarded_ad_completed.emit(item_id, 1)
	return {
		"granted": true,
		"amount": 1,
		"item_id": item_id,
		"quantity": new_qty,
		"date": today
	}

func reset_special_item_inventory() -> void:
	if has_special_items(current_mode):
		special_item_inventory = DEFAULT_MODERN_INVENTORY.duplicate()
		for k in MODERN_ITEM_TYPES:
			special_item_inventory[k] = int(special_item_inventory.get(k, 0)) + int(persistent_bonus_items.get(k, 0))
	else:
		special_item_inventory = {}
	moves_since_last_discovery = 0
	special_item_inventory_changed.emit(special_item_inventory.duplicate())


func get_special_item_count(item_id: String) -> int:
	if not has_special_items(current_mode):
		return 0
	return int(special_item_inventory.get(item_id, 0))


func set_special_item_count(item_id: String, count: int) -> void:
	if not has_special_items(current_mode):
		return
	if item_id in MODERN_ITEM_TYPES:
		special_item_inventory[item_id] = max(0, count)
		special_item_inventory_changed.emit(special_item_inventory.duplicate())


func add_special_item(item_id: String, amount: int = 1) -> int:
	if not has_special_items(current_mode) or not (item_id in MODERN_ITEM_TYPES) or amount <= 0:
		return 0
	special_item_inventory[item_id] = int(special_item_inventory.get(item_id, 0)) + amount
	var new_qty: int = int(special_item_inventory[item_id])
	special_item_inventory_changed.emit(special_item_inventory.duplicate())
	return new_qty


func consume_special_item(item_id: String) -> bool:
	if not has_special_items(current_mode) or not (item_id in MODERN_ITEM_TYPES):
		return false
	# Extra Life can ONLY be consumed after a genuine Game Over, never during active gameplay
	if item_id == "extra_life" and current_state != State.GAME_OVER:
		return false
	var cur: int = int(special_item_inventory.get(item_id, 0))
	if cur <= 0:
		return false
	special_item_inventory[item_id] = cur - 1
	if int(persistent_bonus_items.get(item_id, 0)) > 0:
		persistent_bonus_items[item_id] = max(0, int(persistent_bonus_items.get(item_id, 0)) - 1)
		save_progression()
	special_item_inventory_changed.emit(special_item_inventory.duplicate())
	return true


func use_special_item(item_id: String) -> bool:
	return consume_special_item(item_id)


func try_discover_special_item(lines_cleared: int = 0, forced_roll: float = -1.0, forced_item_id: String = "") -> Dictionary:
	if not can_level_have_special_board_items(active_level, current_mode):
		return {"discovered": false, "item_id": "", "quantity": 0, "reason": "not_special_milestone_level"}
	
	moves_since_last_discovery += 1
	if forced_roll < 0.0 and moves_since_last_discovery < 2:
		return {"discovered": false, "item_id": "", "quantity": 0}
	
	var roll: float = forced_roll if forced_roll >= 0.0 else randf()
	var effective_chance: float = special_item_discovery_chance + (0.10 if lines_cleared > 0 else 0.0)
	if roll >= effective_chance:
		return {"discovered": false, "item_id": "", "quantity": 0}
	
	moves_since_last_discovery = 0
	var chosen_item: String = forced_item_id
	if not (chosen_item in MODERN_ITEM_TYPES):
		chosen_item = MODERN_ITEM_TYPES[randi() % MODERN_ITEM_TYPES.size()]
	
	return collect_board_special_item(chosen_item, active_level)


# ==============================================================================
# GAME SESSION LIFECYCLE
# ==============================================================================

func set_game_mode(mode: GameMode, save_to_disk: bool = true) -> void:
	current_mode = mode
	if save_to_disk:
		save_progression()
	mode_changed.emit(current_mode)


func set_play_style(style: PlayStyle, save_to_disk: bool = true) -> void:
	current_play_style = style
	_play_style_explicit = true
	if save_to_disk:
		save_progression()
	play_style_changed.emit(current_play_style)


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and "music_enabled" in audio_mgr and audio_mgr.music_enabled != enabled:
		audio_mgr.music_enabled = enabled
	audio_settings_changed.emit(music_enabled, sound_enabled)


func set_sfx_enabled(enabled: bool) -> void:
	sound_enabled = enabled
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and "sound_enabled" in audio_mgr and audio_mgr.sound_enabled != enabled:
		audio_mgr.sound_enabled = enabled
	audio_settings_changed.emit(music_enabled, sound_enabled)


func get_voice_mode() -> String:
	return voice_mode


func get_voice_state_label() -> String:
	match voice_mode:
		"female":
			return "Female"
		"off":
			return "OFF"
		_:
			return "Male"


func get_voice_button_label() -> String:
	match voice_mode:
		"female":
			return tr_text("voice_female")
		"off":
			return tr_text("voice_off")
		_:
			return tr_text("voice_male")


func set_voice_mode(mode: String, save_to_disk: bool = true) -> void:
	var norm := mode.strip_edges().to_lower()
	if norm in ["female", "nu", "nữ"]:
		norm = "female"
	elif norm in ["off", "none", "mute", "disabled", "tắt", "tat"]:
		norm = "off"
	else:
		norm = "male"
	voice_mode = norm
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("set_voice_mode") and audio_mgr.get_voice_mode() != voice_mode:
		audio_mgr.set_voice_mode(voice_mode, save_to_disk)
	if save_to_disk:
		save_progression()
	voice_settings_changed.emit(voice_mode)


func cycle_voice_mode(save_to_disk: bool = true) -> String:
	var next_mode := "male"
	match voice_mode:
		"male":
			next_mode = "female"
		"female":
			next_mode = "off"
		_:
			next_mode = "male"
	set_voice_mode(next_mode, save_to_disk)
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_voice_selection_confirmation"):
		audio_mgr.play_voice_selection_confirmation(voice_mode)
	return voice_mode


func is_web_runtime(override_platform: String = "") -> bool:
	var raw: String = override_platform.strip_edges().to_lower() if override_platform != "" else _simulated_platform
	if raw in ["web", "web_ios", "web_android", "web_desktop", "html5", "browser"]:
		return true
	if raw in ["ios", "iphone", "ipad", "android", "linux", "windows", "macos"]:
		return false
	return OS.get_name().strip_edges().to_lower() == "web" or OS.has_feature("web")


func _detect_web_vibration_capability() -> bool:
	if _web_vibration_capability_checked:
		return _web_vibration_capability_supported
	_web_vibration_capability_checked = true
	if _simulated_web_vibrate_available != null:
		_web_vibration_capability_supported = bool(_simulated_web_vibrate_available)
		return _web_vibration_capability_supported
	if (OS.get_name().strip_edges().to_lower() == "web" or OS.has_feature("web")) and ClassDB.class_exists("JavaScriptBridge"):
		var js_res: Variant = JavaScriptBridge.eval("(function(){try{return typeof navigator!=='undefined'&&typeof navigator.vibrate==='function';}catch(e){return false;}})()", true)
		_web_vibration_capability_supported = (typeof(js_res) == TYPE_BOOL and bool(js_res))
		return _web_vibration_capability_supported
	_web_vibration_capability_supported = false
	return false


func diagnose_haptic_capability(override_platform: String = "") -> Dictionary:
	var web_mode: bool = is_web_runtime(override_platform)
	if web_mode:
		var has_nav_vib: bool = _detect_web_vibration_capability()
		return {
			"platform": "web",
			"is_web": true,
			"supported": has_nav_vib,
			"navigator_vibrate_available": has_nav_vib,
			"backend": "web_navigator_vibrate" if has_nav_vib else "web_unavailable",
			"reason": "navigator_vibrate_available" if has_nav_vib else "navigator_vibrate_unavailable"
		}
	var eff_plat: String = get_effective_account_platform(override_platform)
	if eff_plat in ["android", "ios"]:
		return {
			"platform": eff_plat,
			"is_web": false,
			"supported": true,
			"navigator_vibrate_available": false,
			"backend": "native_handheld",
			"reason": "godot_vibrate_handheld_supported"
		}
	return {
		"platform": eff_plat,
		"is_web": false,
		"supported": true,
		"navigator_vibrate_available": false,
		"backend": "native_handheld",
		"reason": "godot_vibrate_handheld_supported"
	}


func is_haptic_supported_on_platform(override_platform: String = "") -> bool:
	return bool(diagnose_haptic_capability(override_platform).get("supported", false))


func trigger_haptic_feedback(duration_ms: int = 35, reason: String = "ui") -> bool:
	if not haptics_enabled:
		last_haptic_active = false
		last_haptic_status = "disabled"
		return false
	var cap: Dictionary = diagnose_haptic_capability()
	if not bool(cap.get("supported", false)):
		last_haptic_active = false
		last_haptic_status = String(cap.get("reason", "unsupported"))
		unsupported_haptic_attempt_count += 1
		return false
	var clamped_ms: int = clampi(duration_ms, 10, 200)
	if bool(cap.get("is_web", false)):
		if (OS.get_name().strip_edges().to_lower() == "web" or OS.has_feature("web")) and ClassDB.class_exists("JavaScriptBridge") and _simulated_web_vibrate_available == null:
			var vib_ok: Variant = JavaScriptBridge.eval("(function(){try{return !!(navigator&&typeof navigator.vibrate==='function'&&navigator.vibrate(%d));}catch(e){return false;}})()" % clamped_ms, true)
			if not (typeof(vib_ok) == TYPE_BOOL and bool(vib_ok)):
				_web_vibration_capability_checked = true
				_web_vibration_capability_supported = false
				last_haptic_active = false
				last_haptic_status = "navigator_vibrate_rejected"
				unsupported_haptic_attempt_count += 1
				return false
		haptic_trigger_count += 1
		last_haptic_duration_ms = clamped_ms
		last_haptic_reason = reason
		last_haptic_active = true
		last_haptic_status = "active_web_vibrate"
		return true
	Input.vibrate_handheld(clamped_ms)
	haptic_trigger_count += 1
	last_haptic_duration_ms = clamped_ms
	last_haptic_reason = reason
	last_haptic_active = true
	last_haptic_status = "active_native_handheld"
	return true


func set_haptics_enabled(enabled: bool, trigger_confirmation: bool = false, save_to_disk: bool = true) -> bool:
	haptics_enabled = enabled
	if save_to_disk:
		save_progression()
	if haptics_enabled and trigger_confirmation:
		return trigger_haptic_feedback(35, "haptic_toggle_on")
	return false


func toggle_haptics(save_to_disk: bool = true) -> bool:
	set_haptics_enabled(not haptics_enabled, true, save_to_disk)
	return haptics_enabled


func start_level(lvl: int, mode: GameMode = current_mode, style: int = int(current_play_style)) -> bool:
	if not is_level_unlocked(lvl):
		return false
	if not can_start_level_with_energy():
		return false
	selected_map_level = lvl
	active_level = lvl
	_play_style_explicit = true
	return start_game(mode, style, lvl)


func start_next_level() -> bool:
	var target_next: int = min(TOTAL_LEVELS, max(1, last_completed_level + 1) if last_completed_level > 0 else min(highest_unlocked_level, selected_map_level + 1))
	if not is_level_unlocked(target_next):
		return false
	if not can_start_level_with_energy():
		return false
	return start_level(target_next, current_mode, int(current_play_style))


func start_game_combination(mode: GameMode, style: PlayStyle, lvl: int = -1) -> bool:
	_play_style_explicit = true
	return start_game(mode, int(style), lvl)


func start_game(mode: GameMode = current_mode, style: int = -1, lvl: int = -1) -> bool:
	if not consume_energy_for_play(1):
		return false
	var target_lvl: int = lvl if lvl >= 1 else selected_map_level
	target_lvl = clampi(target_lvl, 1, TOTAL_LEVELS)
	
	var prev_state := current_state
	current_mode = mode
	if style >= 0:
		current_play_style = style as PlayStyle
		_play_style_explicit = true
	elif not _play_style_explicit:
		current_play_style = PlayStyle.FALLING if mode == GameMode.CLASSIC else PlayStyle.DRAG_AND_DROP
	
	current_state = State.PLAYING
	active_level = target_lvl
	selected_map_level = target_lvl
	level = target_lvl
	level_completed_in_session = false
	
	score = 0
	lines_cleared_total = 0
	combo_count = 0
	last_reward_coins = 0
	last_session_stars = 0
	session_stats.clear()
	placement_checkpoints.clear()
	extra_life_used_in_session = false
	extra_life_recovery_count_in_session = 0
	last_extra_life_rewound_placements = 0
	reset_special_item_inventory()
	
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr:
		if "single_line_callout_counter" in audio_mgr:
			audio_mgr.single_line_callout_counter = 0
		if audio_mgr.has_method("select_random_bgm_for_level"):
			audio_mgr.select_random_bgm_for_level(target_lvl, true)
		elif audio_mgr.has_method("select_random_bgm_track_for_new_session"):
			audio_mgr.select_random_bgm_track_for_new_session()
	
	mode_changed.emit(current_mode)
	play_style_changed.emit(current_play_style)
	state_changed.emit(current_state, prev_state)
	game_started.emit(current_mode)
	combination_started.emit(current_mode, current_play_style)
	score_updated.emit(score, 0)
	level_updated.emit(level, 0)
	combo_updated.emit(combo_count)
	return true


func pause_game(pause: bool) -> void:
	if current_state != State.PLAYING and current_state != State.PAUSED:
		return
	
	var prev_state := current_state
	current_state = State.PAUSED if pause else State.PLAYING
	get_tree().paused = pause
	
	state_changed.emit(current_state, prev_state)
	game_paused.emit(pause)


func trigger_level_complete(achieved_score: int = score) -> Dictionary:
	var comp: Dictionary = record_level_completion(active_level, achieved_score)
	level_completed_in_session = true
	level = min(TOTAL_LEVELS, max(level, active_level + 1))
	level_updated.emit(level, lines_cleared_total)
	
	if current_state != State.GAME_OVER:
		var prev_state := current_state
		current_state = State.GAME_OVER
		session_stats = comp.duplicate()
		state_changed.emit(current_state, prev_state)
		game_over_triggered.emit(achieved_score, active_level, session_stats)
	return comp


func trigger_game_over(stats: Dictionary = {}) -> void:
	if current_state == State.GAME_OVER:
		return
	
	if score >= get_level_target_score(active_level):
		trigger_level_complete(score)
		return
	
	var prev_state := current_state
	current_state = State.GAME_OVER
	
	if score > high_score:
		high_score = score
	
	last_session_stars = 0
	last_reward_coins = max(5, int(score / 30)) if score > 0 else 0
	coins += last_reward_coins
	save_progression()
	
	var merged_stats = stats.duplicate()
	merged_stats["level_complete"] = false
	merged_stats["completed_level"] = active_level
	merged_stats["next_level"] = min(TOTAL_LEVELS, active_level + 1)
	merged_stats["stars"] = 0
	merged_stats["stars_display"] = "- - -"
	merged_stats["coins_earned"] = last_reward_coins
	merged_stats["reward_text"] = "+%d Coins" % last_reward_coins
	session_stats = merged_stats
	
	progression_updated.emit(highest_unlocked_level, total_stars, coins)
	state_changed.emit(current_state, prev_state)
	game_over_triggered.emit(score, active_level, session_stats)


func can_use_extra_life_now() -> bool:
	if current_state != State.GAME_OVER:
		return false
	if bool(session_stats.get("level_complete", false)):
		return false
	if extra_life_used_in_session:
		return false
	return get_special_item_count("extra_life") > 0


func record_placement_checkpoint(board_node: Node) -> void:
	if not board_node or not ("grid_data" in board_node):
		return
	var g_data: Array = board_node.grid_data.duplicate(true)
	var g_mats: Array = board_node.grid_materials.duplicate(true) if ("grid_materials" in board_node) else []
	var g_specials: Array = board_node.grid_special_items.duplicate(true) if ("grid_special_items" in board_node) else []
	placement_checkpoints.append({
		"placement_index": placement_checkpoints.size(),
		"grid_data": g_data,
		"grid_materials": g_mats,
		"grid_special_items": g_specials,
		"score": score,
		"level": level,
		"active_level": active_level,
		"lines_cleared_total": lines_cleared_total,
		"combo_count": combo_count,
		"mode": current_mode,
		"play_style": current_play_style
	})


func rewind_extra_life_checkpoint(board_node: Node = null) -> Dictionary:
	if placement_checkpoints.is_empty():
		last_extra_life_rewound_placements = 0
		return {"has_checkpoint": false, "rewound_placements": 0}
	var total_cp: int = placement_checkpoints.size()
	var target_idx: int = maxi(0, total_cp - 3)
	var rewound_cnt: int = total_cp - target_idx
	var cp: Dictionary = placement_checkpoints[target_idx].duplicate(true)
	placement_checkpoints.resize(target_idx)
	last_extra_life_rewound_placements = rewound_cnt
	
	score = int(cp.get("score", score))
	level = int(cp.get("level", level))
	active_level = int(cp.get("active_level", active_level))
	lines_cleared_total = int(cp.get("lines_cleared_total", lines_cleared_total))
	combo_count = int(cp.get("combo_count", 0))
	current_mode = int(cp.get("mode", current_mode)) as GameMode
	current_play_style = int(cp.get("play_style", current_play_style)) as PlayStyle
	
	if board_node and board_node.has_method("restore_checkpoint_state"):
		board_node.restore_checkpoint_state(cp.get("grid_data", []), cp.get("grid_materials", []), cp.get("grid_special_items", []))
	
	score_updated.emit(score, 0)
	level_updated.emit(level, lines_cleared_total)
	combo_updated.emit(combo_count)
	cp["has_checkpoint"] = true
	cp["checkpoint_index"] = target_idx
	cp["rewound_placements"] = rewound_cnt
	return cp


func revive_from_extra_life() -> void:
	if current_state == State.GAME_OVER and not session_stats.get("level_complete", false):
		extra_life_used_in_session = true
		extra_life_recovery_count_in_session += 1
		var prev_state := current_state
		current_state = State.PLAYING
		state_changed.emit(current_state, prev_state)


func revive_from_watch_ad() -> void:
	if current_state == State.GAME_OVER and not session_stats.get("level_complete", false):
		var prev_state := current_state
		current_state = State.PLAYING
		state_changed.emit(current_state, prev_state)


func return_to_menu() -> void:
	var prev_state := current_state
	current_state = State.MENU
	get_tree().paused = false
	state_changed.emit(current_state, prev_state)


func add_score(points: int) -> void:
	if points <= 0:
		return
	score += points
	if score > high_score:
		high_score = score
	score_updated.emit(score, points)


func advance_level(new_level: int, lines: int = 0) -> void:
	level = new_level
	lines_cleared_total += lines
	level_updated.emit(level, lines_cleared_total)


func get_line_clear_multiplier(lines_cleared: int) -> float:
	if lines_cleared <= 0:
		return 0.0
	match lines_cleared:
		1:
			return 1.0
		2:
			return 1.5
		3:
			return 3.0
		4:
			return 4.0
		5:
			return 5.0
		6:
			return 6.0
		_:
			return float(lines_cleared)


func get_row_column_combo_multiplier(row_count: int, col_count: int) -> float:
	if row_count >= 1 and col_count >= 1:
		return ROW_COLUMN_COMBO_MULTIPLIER
	return 1.0


func get_rainbow_block_multiplier(has_rainbow: bool) -> float:
	return RAINBOW_BLOCK_MULTIPLIER if has_rainbow else 1.0


func calculate_line_clear_score(
	lines_cleared: int,
	row_count: int = -1,
	col_count: int = -1,
	cells_cleared: int = -1,
	has_rainbow: bool = false
) -> Dictionary:
	var col_allowed: bool = allows_column_clear(current_mode, current_play_style)
	var eff_cols: int = (maxi(0, col_count) if col_count >= 0 else 0) if col_allowed else 0
	var eff_rows: int = maxi(0, row_count) if row_count >= 0 else maxi(0, lines_cleared if eff_cols <= 0 else lines_cleared - eff_cols)
	var eff_lines: int = eff_rows + eff_cols

	if eff_lines <= 0:
		return {
			"score_delta": 0,
			"cells_cleared": 0,
			"lines_cleared": 0,
			"row_count": 0,
			"col_count": 0,
			"line_multiplier": 0.0,
			"row_column_combo_multiplier": 1.0,
			"rainbow_multiplier": 1.0,
			"applicable_multiplier": 0.0,
			"is_row_col_combo": false,
			"has_rainbow": has_rainbow
		}

	var default_cells: int = (eff_rows * 10) + (eff_cols * 12) - (eff_rows * eff_cols)
	var resolved_cells: int = cells_cleared if (cells_cleared > 0 and (col_allowed or col_count <= 0)) else default_cells
	var line_mult: float = get_line_clear_multiplier(eff_lines)
	var rc_combo_mult: float = get_row_column_combo_multiplier(eff_rows, eff_cols)
	var rainbow_mult: float = get_rainbow_block_multiplier(has_rainbow)
	var applicable_mult: float = line_mult * rc_combo_mult * rainbow_mult
	var score_delta: int = int(round(float(resolved_cells) * applicable_mult))

	return {
		"score_delta": score_delta,
		"cells_cleared": resolved_cells,
		"lines_cleared": eff_lines,
		"row_count": eff_rows,
		"col_count": eff_cols,
		"line_multiplier": line_mult,
		"row_column_combo_multiplier": rc_combo_mult,
		"rainbow_multiplier": rainbow_mult,
		"applicable_multiplier": applicable_mult,
		"is_row_col_combo": (eff_rows >= 1 and eff_cols >= 1),
		"has_rainbow": has_rainbow
	}


func process_move_result(
	placed_cell_count: int,
	lines_cleared: int,
	row_count: int = -1,
	col_count: int = -1,
	cells_cleared: int = -1,
	has_rainbow: bool = false,
	collected_board_items: Array = []
) -> Dictionary:
	# Block placement by itself ALWAYS gives 0 points.
	# Score increases ONLY after the placement causes at least one valid line clear.
	var placement_points: int = 0
	var calc: Dictionary = calculate_line_clear_score(lines_cleared, row_count, col_count, cells_cleared, has_rainbow)
	var eff_lines: int = int(calc.get("lines_cleared", 0))
	var eff_rows: int = int(calc.get("row_count", 0))
	var eff_cols: int = int(calc.get("col_count", 0))
	var line_points: int = int(calc.get("score_delta", 0))

	if eff_lines > 0:
		combo_count += 1
		lines_cleared_total += eff_lines
	else:
		combo_count = 0
		line_points = 0

	var total_points: int = line_points
	if total_points > 0:
		add_score(total_points)

	var callout_key: String = ""
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if eff_lines > 0 and audio_mgr:
		if (eff_rows >= 1 and eff_cols >= 1) and audio_mgr.has_method("play_combo"):
			audio_mgr.play_combo(combo_count)
		if audio_mgr.has_method("trigger_achievement_callout"):
			callout_key = audio_mgr.trigger_achievement_callout(eff_lines, combo_count, eff_rows, eff_cols)

	var discovery_res: Dictionary = {"discovered": false, "item_id": "", "quantity": 0}
	if can_level_have_special_board_items(active_level, current_mode) and placed_cell_count > 0:
		moves_since_last_discovery += 1
		for raw_item in collected_board_items:
			var item_str := String(raw_item)
			if item_str in MODERN_ITEM_TYPES:
				discovery_res = collect_board_special_item(item_str, active_level)

	var target_for_level: int = get_level_target_score(active_level)
	if score >= target_for_level and not level_completed_in_session:
		trigger_level_complete(score)
		if audio_mgr and audio_mgr.has_method("play_level_up"):
			audio_mgr.play_level_up()

	combo_updated.emit(combo_count)

	return {
		"total_points": total_points,
		"score_delta": total_points,
		"placement_points": placement_points,
		"line_points": line_points,
		"cells_cleared": int(calc.get("cells_cleared", 0)),
		"lines_cleared": eff_lines,
		"line_multiplier": float(calc.get("line_multiplier", 0.0)),
		"row_column_combo_multiplier": float(calc.get("row_column_combo_multiplier", 1.0)),
		"rainbow_multiplier": float(calc.get("rainbow_multiplier", 1.0)),
		"applicable_multiplier": float(calc.get("applicable_multiplier", 0.0)),
		"is_row_col_combo": bool(calc.get("is_row_col_combo", false)),
		"has_rainbow": has_rainbow,
		"combo_count": combo_count,
		"level": level,
		"lines_cleared_total": lines_cleared_total,
		"row_count": eff_rows,
		"col_count": eff_cols,
		"callout": callout_key,
		"special_item_discovered": discovery_res.get("discovered", false),
		"discovered_item_id": discovery_res.get("item_id", "")
	}


func allows_column_clear(mode: int = current_mode, style: int = current_play_style) -> bool:
	if style == PlayStyle.DRAG_AND_DROP:
		return true
	return mode == GameMode.MODERN_DRAG_AND_DROP


func has_special_items(mode: int = current_mode) -> bool:
	return mode == GameMode.MODERN_DRAG_AND_DROP


func uses_gravity(_mode: int = current_mode, style: int = current_play_style) -> bool:
	return style == PlayStyle.FALLING


func get_mode_name(mode: GameMode = current_mode) -> String:
	match mode:
		GameMode.CLASSIC:
			return tr_text("mode_classic")
		GameMode.MODERN_DRAG_AND_DROP:
			return tr_text("mode_modern")
		_:
			return "Unknown"


func get_play_style_name(style: PlayStyle = current_play_style) -> String:
	match style:
		PlayStyle.FALLING:
			return tr_text("style_falling")
		PlayStyle.DRAG_AND_DROP:
			return tr_text("style_drag_drop")
		_:
			return "Unknown"


func get_combination_name(mode: GameMode = current_mode, style: PlayStyle = current_play_style) -> String:
	return "%s + %s" % [get_mode_name(mode), get_play_style_name(style)]


func get_combination_description(mode: GameMode = current_mode, style: PlayStyle = current_play_style) -> String:
	return get_rules_help_text(mode, style)


## Returns safe area insets (top, bottom, left, right) in virtual viewport coordinates
## Supports native DisplayServer and Web CSS env(safe-area-inset-*) with graceful tall aspect fallback
func get_safe_area_insets(custom_viewport_size: Vector2 = Vector2.ZERO) -> Dictionary:
	var top_inset: float = 0.0
	var bottom_inset: float = 0.0
	var left_inset: float = 0.0
	var right_inset: float = 0.0

	var vp_sz: Vector2 = custom_viewport_size
	if vp_sz.x <= 0.0 or vp_sz.y <= 0.0:
		if is_inside_tree() and get_viewport():
			vp_sz = get_viewport().get_visible_rect().size
		else:
			vp_sz = Vector2(720.0, 1280.0)

	# 1. Native DisplayServer safe area (iOS / Android native)
	if DisplayServer.has_method("get_display_safe_area") and DisplayServer.has_method("screen_get_size"):
		var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
		var screen_sz: Vector2i = DisplayServer.screen_get_size()
		if screen_sz.x > 0 and screen_sz.y > 0 and safe_rect.size.x > 0 and safe_rect.size.y > 0:
			var scale_y: float = vp_sz.y / float(screen_sz.y)
			var scale_x: float = vp_sz.x / float(screen_sz.x)
			top_inset = maxf(top_inset, float(safe_rect.position.y) * scale_y)
			bottom_inset = maxf(bottom_inset, float(screen_sz.y - (safe_rect.position.y + safe_rect.size.y)) * scale_y)
			left_inset = maxf(left_inset, float(safe_rect.position.x) * scale_x)
			right_inset = maxf(right_inset, float(screen_sz.x - (safe_rect.position.x + safe_rect.size.x)) * scale_x)

	# 2. Web HTML5 safe area via CSS env(safe-area-inset-*) with device-aware notch / Dynamic Island protection
	var os_name := OS.get_name().strip_edges().to_lower()
	if (os_name == "web" or OS.has_feature("web")) and ClassDB.class_exists("JavaScriptBridge"):
		var js_insets: Variant = JavaScriptBridge.eval("""(function(){
			try {
				var div = document.createElement('div');
				div.style.position = 'fixed';
				div.style.top = '0';
				div.style.left = '0';
				div.style.paddingTop = 'env(safe-area-inset-top, 0px)';
				div.style.paddingBottom = 'env(safe-area-inset-bottom, 0px)';
				div.style.paddingLeft = 'env(safe-area-inset-left, 0px)';
				div.style.paddingRight = 'env(safe-area-inset-right, 0px)';
				div.style.visibility = 'hidden';
				div.style.pointerEvents = 'none';
				document.body.appendChild(div);
				var cs = window.getComputedStyle(div);
				var top = parseFloat(cs.paddingTop) || 0;
				var bottom = parseFloat(cs.paddingBottom) || 0;
				var left = parseFloat(cs.paddingLeft) || 0;
				var right = parseFloat(cs.paddingRight) || 0;
				document.body.removeChild(div);
				var h = (document.documentElement && document.documentElement.clientHeight) || window.innerHeight || 1;
				var w = (document.documentElement && document.documentElement.clientWidth) || window.innerWidth || 1;
				var isIOS = /iPhone|iPad|iPod/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
				var isIPhone = /iPhone/.test(navigator.userAgent) || (isIOS && Math.min(window.screen.width, window.screen.height) < 500);
				var scrW = window.screen ? window.screen.width : w;
				var scrH = window.screen ? window.screen.height : h;
				var maxDim = Math.max(scrW, scrH);
				var isDynamicIsland = isIPhone && (maxDim === 852 || maxDim === 932 || maxDim === 874 || maxDim === 956);
				var isNotch = isIPhone && !isDynamicIsland && maxDim >= 780;
				return JSON.stringify({
					top_ratio: top / h,
					bottom_ratio: bottom / h,
					left_ratio: left / w,
					right_ratio: right / w,
					top_px: top,
					bottom_px: bottom,
					left_px: left,
					right_px: right,
					viewport_h: h,
					viewport_w: w,
					is_ios: isIOS,
					is_iphone: isIPhone,
					is_dynamic_island: isDynamicIsland,
					is_notch: isNotch
				});
			} catch(e) { return '{}'; }
		})()""", true)
		if typeof(js_insets) == TYPE_STRING and String(js_insets) != "" and String(js_insets) != "{}":
			var json := JSON.new()
			if json.parse(String(js_insets)) == OK and typeof(json.data) == TYPE_DICTIONARY:
				var top_r: float = float(json.data.get("top_ratio", 0.0))
				var bot_r: float = float(json.data.get("bottom_ratio", 0.0))
				var left_r: float = float(json.data.get("left_ratio", 0.0))
				var right_r: float = float(json.data.get("right_ratio", 0.0))
				if top_r > 0.0:
					top_inset = maxf(top_inset, top_r * vp_sz.y)
				if bot_r > 0.0:
					bottom_inset = maxf(bottom_inset, bot_r * vp_sz.y)
				if left_r > 0.0:
					left_inset = maxf(left_inset, left_r * vp_sz.x)
				if right_r > 0.0:
					right_inset = maxf(right_inset, right_r * vp_sz.x)

				var is_standalone: bool = bool(json.data.get("is_standalone", false))
				var is_dyn_island: bool = bool(json.data.get("is_dynamic_island", false))
				var is_notch: bool = bool(json.data.get("is_notch", false))
				var vh: float = float(json.data.get("viewport_h", 1.0))
				var scale_to_vp: float = vp_sz.y / maxf(1.0, vh)
				if is_standalone:
					if is_dyn_island:
						# iPhone 14/15/16 Pro / Pro Max with Dynamic Island requires ~54-59 CSS px top clearance
						top_inset = maxf(top_inset, 54.0 * scale_to_vp)
						bottom_inset = maxf(bottom_inset, 28.0 * scale_to_vp)
					elif is_notch:
						# iPhones with standard sensor notch require ~44-47 CSS px top clearance
						top_inset = maxf(top_inset, 44.0 * scale_to_vp)
						bottom_inset = maxf(bottom_inset, 24.0 * scale_to_vp)

	# 3. Graceful tall screen (e.g. 19.5:9 or taller) notch buffer for PWA standalone when browser hides insets
	var aspect_ratio: float = vp_sz.y / maxf(1.0, vp_sz.x)
	if aspect_ratio >= 1.95 and top_inset <= 0.0 and is_standalone:
		top_inset = maxf(top_inset, clampf(vp_sz.y * 0.032, 20.0, 48.0))

	return {
		"top": top_inset,
		"bottom": bottom_inset,
		"left": left_inset,
		"right": right_inset
	}

