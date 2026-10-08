class_name MapTheme
extends RefCounted

## MapTheme — Data-Driven World Type & Real-World Theme Specification for 4TM Map Core (Correction 7)
## Strictly separates and models the 6 distinct World Types:
##   1. "countryside"        — Countryside World (e.g. Tuscan Countryside, Rural Countryside)
##   2. "town"               — Town World (e.g. Alpine Village, Venice Canal Town)
##   3. "modern_city"        — Modern City World (e.g. Tokyo, Ho Chi Minh City, New York City)
##   4. "country"            — Country World (e.g. Italy: Tuscan Countryside -> Pisa -> Venice -> Florence -> Rome)
##   5. "landmark_region"    — Landmark Region World (e.g. Ha Long Bay, Mount Fuji, Grand Canyon, Giza, Swiss Alps, Paris Eiffel District)
##   6. "space_astronomical" — Space / Astronomical World (e.g. Mars, Moon, Milky Way)
##
## Preserves internal `theme_id` identifiers for 100% save/progression & test compatibility
## while providing rich semantic `world_type`, `world_id`, `world_name`, `country_or_region`,
## `subregions`, `primary_landmark`, and `gameplay_background_theme` metadata.

const WORLD_TYPE_COUNTRYSIDE: String = "countryside"
const WORLD_TYPE_TOWN: String = "town"
const WORLD_TYPE_MODERN_CITY: String = "modern_city"
const WORLD_TYPE_COUNTRY: String = "country"
const WORLD_TYPE_LANDMARK_REGION: String = "landmark_region"
const WORLD_TYPE_SPACE: String = "space_astronomical"

const SUPPORTED_WORLD_TYPES: Array[String] = [
	WORLD_TYPE_COUNTRYSIDE,
	WORLD_TYPE_TOWN,
	WORLD_TYPE_MODERN_CITY,
	WORLD_TYPE_COUNTRY,
	WORLD_TYPE_LANDMARK_REGION,
	WORLD_TYPE_SPACE
]

## Stable internal theme_id preserved for saves & legacy lookups
var theme_id: String = "ocean_islands"

## Explicit World Type & Real-World Identity (Correction 7)
var world_type: String = WORLD_TYPE_LANDMARK_REGION
var world_id: String = "ha_long_bay"
var world_name_en: String = "Ha Long Bay • Vietnam"
var world_name_vi: String = "Vịnh Hạ Long • Việt Nam"
var name_en: String = "Ha Long Bay • Vietnam"
var name_vi: String = "Vịnh Hạ Long • Việt Nam"

var region_id: String = "ha_long_bay_vietnam"
var region_name_en: String = "Ha Long Bay • Vietnam"
var region_name_vi: String = "Vịnh Hạ Long • Việt Nam"
var country_or_region_en: String = "Quang Ninh, Vietnam"
var country_or_region_vi: String = "Quảng Ninh, Việt Nam"

var subregions: Array[String] = ["bai_chay_harbor", "emerald_karst_lagoon", "cua_van_floating_village", "titop_lighthouse_peak"]
var subregion_names_en: Array[String] = ["Bai Chay Harbor", "Emerald Karst Lagoon", "Cua Van Floating Village", "Ti Top Island Peak"]
var subregion_names_vi: Array[String] = ["Cảng Bãi Cháy", "Đầm Đá Vôi Ngọc Bích", "Làng Chài Cửa Vạn", "Đỉnh Đảo Ti Tốp"]

var primary_landmark_id: String = "halong_karst_lighthouse"
var primary_landmark_en: String = "Limestone Karst Pillars, Traditional Junk Sails & Island Lighthouse"
var primary_landmark_vi: String = "Quần Đảo Đá Vôi, Thuyền Buồm Hạ Long & Hải Đăng Đảo Cao"

var gameplay_background_theme: String = "landmark_halong_emerald_karst_bay"
var gameplay_backgrounds: Array[String] = ["halong_harbor_coast", "halong_karst_lagoon", "halong_fishing_village", "halong_lighthouse_point"]

var dominant_environment: String = "open_ocean_archipelago"
var terrain_style: String = "atoll_islands"
var path_style: String = "sea_stepping_stones"
var atmosphere_style: String = "sunlit_sea_breeze"
var particle_style: String = "sea_bubbles"
var landmark_types: Array[String] = ["harbor_lighthouse", "coral_arch", "sailboat_pier"]
var destination_styles: Array[String] = ["sandy_cay_island", "coral_lagoon_isle", "lighthouse_bastion"]

var palette: Dictionary = {
	"sky_top": Color(0.24, 0.68, 0.92, 1.0),
	"sky_bottom": Color(0.78, 0.94, 0.98, 1.0),
	"ground_primary": Color(0.08, 0.54, 0.72, 1.0),
	"ground_secondary": Color(0.24, 0.76, 0.84, 1.0),
	"island_surface": Color(0.36, 0.74, 0.36, 1.0),
	"cliff_color": Color(0.54, 0.50, 0.44, 1.0),
	"water_color": Color(0.10, 0.68, 0.84, 1.0),
	"shore_color": Color(0.96, 0.88, 0.66, 1.0),
	"path_outer": Color(0.82, 0.66, 0.42, 1.0),
	"path_inner": Color(0.98, 0.92, 0.76, 1.0),
	"accent_color": Color(1.0, 0.82, 0.26, 1.0)
}

var lighting_spec: Dictionary = {
	"sun_color": Color(1.0, 0.96, 0.84, 1.0),
	"sun_energy": 1.25,
	"ambient_color": Color(0.78, 0.90, 1.0, 1.0),
	"ambient_energy": 0.88,
	"horizon_glow": Color(1.0, 0.95, 0.70, 0.42)
}

## Legacy 10 preset IDs preserved so existing saves and automated tests remain 100% compatible
const PRESET_THEME_IDS: Array[String] = [
	"ocean_islands",
	"tropical_coast",
	"green_forest",
	"hills_mountains",
	"desert",
	"snow_ice",
	"volcano",
	"ancient_ruins",
	"crystal_sanctuary",
	"starlight_highlands"
]

## Semantic Real-World Library IDs (Correction 7 Section 10)
const WORLD_LIBRARY_IDS: Array[String] = [
	"tuscan_countryside",
	"rural_countryside",
	"alpine_village",
	"tokyo",
	"ho_chi_minh_city",
	"new_york_city",
	"modern_city",
	"italy",
	"venice",
	"rome",
	"paris",
	"ha_long_bay",
	"mount_fuji",
	"grand_canyon",
	"giza",
	"swiss_alps",
	"moon",
	"mars",
	"milky_way"
]

## Complete World Specifications keyed by stable internal IDs
const PRESET_SPECS: Dictionary = {
	# --------------------------------------------------------------------------
	# 1. LANDMARK REGION WORLD: HA LONG BAY • VIETNAM
	# --------------------------------------------------------------------------
	"ocean_islands": {
		"theme_id": "ocean_islands",
		"world_type": WORLD_TYPE_LANDMARK_REGION,
		"world_id": "ha_long_bay",
		"world_name_en": "Ha Long Bay • Vietnam",
		"world_name_vi": "Vịnh Hạ Long • Việt Nam",
		"name_en": "Ha Long Bay • Vietnam",
		"name_vi": "Vịnh Hạ Long • Việt Nam",
		"region_id": "ha_long_bay_vietnam",
		"region_name_en": "Ha Long Bay • Vietnam",
		"region_name_vi": "Vịnh Hạ Long • Việt Nam",
		"country_or_region_en": "Quang Ninh, Vietnam",
		"country_or_region_vi": "Quảng Ninh, Việt Nam",
		"subregions": ["bai_chay_harbor", "emerald_karst_lagoon", "cua_van_floating_village", "titop_lighthouse_peak"],
		"subregion_names_en": ["Bai Chay Harbor", "Emerald Karst Lagoon", "Cua Van Floating Village", "Ti Top Island Peak"],
		"subregion_names_vi": ["Cảng Bãi Cháy", "Đầm Đá Vôi Ngọc Bích", "Làng Chài Cửa Vạn", "Đỉnh Đảo Ti Tốp"],
		"primary_landmark_id": "halong_karst_lighthouse",
		"primary_landmark_en": "Limestone Karst Pillars, Traditional Junk Sails & Island Lighthouse",
		"primary_landmark_vi": "Quần Đảo Đá Vôi, Thuyền Buồm Hạ Long & Hải Đăng Đảo Cao",
		"gameplay_background_theme": "landmark_halong_emerald_karst_bay",
		"gameplay_backgrounds": ["halong_harbor_coast", "halong_karst_lagoon", "halong_fishing_village", "halong_lighthouse_point"],
		"dominant_environment": "open_ocean_archipelago",
		"terrain_style": "atoll_islands",
		"path_style": "sea_stepping_stones",
		"atmosphere_style": "sunlit_sea_breeze",
		"particle_style": "sea_bubbles",
		"landmark_types": ["harbor_lighthouse", "coral_arch", "sailboat_pier"],
		"destination_styles": ["sandy_cay_island", "coral_lagoon_isle", "lighthouse_bastion", "citadel_harbor"],
		"palette": {
			"sky_top": Color(0.24, 0.68, 0.92, 1.0),
			"sky_bottom": Color(0.78, 0.94, 0.98, 1.0),
			"ground_primary": Color(0.08, 0.54, 0.72, 1.0),
			"ground_secondary": Color(0.22, 0.76, 0.84, 1.0),
			"island_surface": Color(0.36, 0.74, 0.36, 1.0),
			"cliff_color": Color(0.52, 0.48, 0.42, 1.0),
			"water_color": Color(0.10, 0.68, 0.84, 1.0),
			"shore_color": Color(0.96, 0.88, 0.64, 1.0),
			"path_outer": Color(0.82, 0.66, 0.42, 1.0),
			"path_inner": Color(0.98, 0.92, 0.76, 1.0),
			"accent_color": Color(1.0, 0.82, 0.26, 1.0)
		}
	},

	# --------------------------------------------------------------------------
	# 2. MODERN CITY WORLD: HO CHI MINH CITY • VIETNAM
	# --------------------------------------------------------------------------
	"tropical_coast": {
		"theme_id": "tropical_coast",
		"world_type": WORLD_TYPE_MODERN_CITY,
		"world_id": "ho_chi_minh_city",
		"world_name_en": "Ho Chi Minh City • Vietnam",
		"world_name_vi": "TP. Hồ Chí Minh • Việt Nam",
		"name_en": "Ho Chi Minh City • Vietnam",
		"name_vi": "TP. Hồ Chí Minh • Việt Nam",
		"region_id": "ho_chi_minh_city_vietnam",
		"region_name_en": "Ho Chi Minh City • Saigon River",
		"region_name_vi": "TP. Hồ Chí Minh • Sông Sài Gòn",
		"country_or_region_en": "Southern Vietnam",
		"country_or_region_vi": "Miền Nam, Việt Nam",
		"subregions": ["bach_dang_wharf", "nguyen_hue_boulevard", "ben_thanh_plaza", "saigon_skyline_tower"],
		"subregion_names_en": ["Bach Dang Riverfront", "Nguyen Hue Boulevard", "Ben Thanh Plaza", "Saigon Skyline Tower"],
		"subregion_names_vi": ["Bến Bạch Đằng", "Phố Đi Bộ Nguyễn Huệ", "Quảng Trường Bến Thành", "Tháp Cao Tầng Sài Gòn"],
		"primary_landmark_id": "saigon_skyline_tower",
		"primary_landmark_en": "Saigon Riverfront Skyline, Bitexco Lotus Tower & Modern Boulevards",
		"primary_landmark_vi": "Đường Chân Trời Sài Gòn, Tháp Hoa Sen & Đại Lộ Hiện Đại",
		"gameplay_background_theme": "modern_city_saigon_riverfront",
		"gameplay_backgrounds": ["saigon_river_wharf", "saigon_walking_street", "saigon_central_plaza", "saigon_skyline_vista"],
		"dominant_environment": "tropical_sandy_coastline",
		"terrain_style": "coastal_cays",
		"path_style": "coastal_boardwalk",
		"atmosphere_style": "golden_lagoon_warmth",
		"particle_style": "sun_motes",
		"landmark_types": ["palm_beach_pavilion", "lagoon_totem", "sunset_pier"],
		"destination_styles": ["palm_beach_terrace", "wooden_boardwalk_deck", "coral_shrine_pad", "tropical_fortress"],
		"palette": {
			"sky_top": Color(0.22, 0.58, 0.88, 1.0),
			"sky_bottom": Color(0.94, 0.84, 0.72, 1.0),
			"ground_primary": Color(0.26, 0.58, 0.44, 1.0),
			"ground_secondary": Color(0.46, 0.70, 0.54, 1.0),
			"island_surface": Color(0.84, 0.84, 0.88, 1.0),
			"cliff_color": Color(0.52, 0.54, 0.60, 1.0),
			"water_color": Color(0.14, 0.58, 0.82, 1.0),
			"shore_color": Color(0.90, 0.86, 0.78, 1.0),
			"path_outer": Color(0.48, 0.52, 0.58, 1.0),
			"path_inner": Color(0.88, 0.90, 0.94, 1.0),
			"accent_color": Color(1.0, 0.76, 0.24, 1.0)
		}
	},

	# --------------------------------------------------------------------------
	# 3. COUNTRYSIDE WORLD: TUSCAN COUNTRYSIDE
	# --------------------------------------------------------------------------
	"green_forest": {
		"theme_id": "green_forest",
		"world_type": WORLD_TYPE_COUNTRYSIDE,
		"world_id": "tuscan_countryside",
		"world_name_en": "Tuscan Countryside",
		"world_name_vi": "Đồng Quê Tuscany",
		"name_en": "Tuscan Countryside",
		"name_vi": "Đồng Quê Tuscany",
		"region_id": "tuscan_countryside_hills",
		"region_name_en": "Tuscan Countryside • Rolling Hills",
		"region_name_vi": "Đồng Quê Tuscany • Đồi Nho & Bách Xanh",
		"country_or_region_en": "Tuscany, Italy",
		"country_or_region_vi": "Vùng Tuscany, Ý",
		"subregions": ["sunflower_farmland", "olive_grove_stream", "cypress_vineyard_ridge", "hilltop_stone_windmill"],
		"subregion_names_en": ["Sunflower Farmland", "Olive Grove Stream", "Cypress Vineyard Ridge", "Hilltop Stone Windmill"],
		"subregion_names_vi": ["Cánh Đồng Hoa Hướng Dương", "Suối Rừng Ô Liu", "Đồi Nho & Hàng Bách", "Cối Xay Gió Đồi Cao"],
		"primary_landmark_id": "countryside_windmill_villa",
		"primary_landmark_en": "Rustic Tuscan Farmhouse Villa, Traditional Windmill & Cypress Groves",
		"primary_landmark_vi": "Trang Trại Đá Tuscany, Cối Xay Gió Cổ Điển & Hàng Cây Bách",
		"gameplay_background_theme": "countryside_tuscan_pastoral_hills",
		"gameplay_backgrounds": ["tuscan_sunflower_fields", "tuscan_olive_stream", "tuscan_vineyard_hills", "tuscan_windmill_crest"],
		"dominant_environment": "lush_emerald_woodland",
		"terrain_style": "forest_clearings",
		"path_style": "mossy_forest_trail",
		"atmosphere_style": "canopy_sunbeams",
		"particle_style": "fireflies",
		"landmark_types": ["ancient_oak_tree", "woodland_shrine", "moss_lantern_gazebo"],
		"destination_styles": ["mossy_glade_pedestal", "timber_treehouse_deck", "woodland_shrine", "emerald_world_tree"],
		"palette": {
			"sky_top": Color(0.32, 0.68, 0.94, 1.0),
			"sky_bottom": Color(0.88, 0.96, 0.84, 1.0),
			"ground_primary": Color(0.28, 0.64, 0.26, 1.0),
			"ground_secondary": Color(0.54, 0.78, 0.32, 1.0),
			"island_surface": Color(0.68, 0.84, 0.38, 1.0),
			"cliff_color": Color(0.56, 0.46, 0.34, 1.0),
			"water_color": Color(0.18, 0.68, 0.86, 1.0),
			"shore_color": Color(0.88, 0.82, 0.62, 1.0),
			"path_outer": Color(0.76, 0.62, 0.42, 1.0),
			"path_inner": Color(0.95, 0.88, 0.72, 1.0),
			"accent_color": Color(1.0, 0.84, 0.22, 1.0)
		}
	},

	# --------------------------------------------------------------------------
	# 4. LANDMARK REGION WORLD: MOUNT FUJI • JAPAN
	# --------------------------------------------------------------------------
	"hills_mountains": {
		"theme_id": "hills_mountains",
		"world_type": WORLD_TYPE_LANDMARK_REGION,
		"world_id": "mount_fuji",
		"world_name_en": "Mount Fuji • Japan",
		"world_name_vi": "Núi Phú Sĩ • Nhật Bản",
		"name_en": "Mount Fuji • Japan",
		"name_vi": "Núi Phú Sĩ • Nhật Bản",
		"region_id": "mount_fuji_japan",
		"region_name_en": "Mount Fuji • Japan",
		"region_name_vi": "Núi Phú Sĩ • Nhật Bản",
		"country_or_region_en": "Yamanashi, Japan",
		"country_or_region_vi": "Yamanashi, Nhật Bản",
		"subregions": ["kawaguchi_cherry_shore", "red_torii_river_bridge", "maple_onsen_terrace", "chureito_pagoda_overlook"],
		"subregion_names_en": ["Lake Kawaguchi Shore", "Crimson Torii Bridge", "Maple Onsen Terrace", "Chureito Pagoda Overlook"],
		"subregion_names_vi": ["Bờ Hồ Kawaguchi", "Cầu Gỗ Cổng Torii Đỏ", "Thềm Lá Phong Suối Khoáng", "Đài Ngắm Chùa Chureito"],
		"primary_landmark_id": "fuji_chureito_pagoda",
		"primary_landmark_en": "Snow-Capped Mount Fuji Cone, Five-Story Crimson Pagoda & Cherry Blossoms",
		"primary_landmark_vi": "Đỉnh Phú Sĩ Tuyết Trắng, Tháp Chùa 5 Tầng Đỏ & Hoa Anh Đào",
		"gameplay_background_theme": "landmark_mount_fuji_cherry_blossom",
		"gameplay_backgrounds": ["fuji_lake_reflection", "fuji_torii_crossing", "fuji_maple_ridge", "fuji_pagoda_summit"],
		"dominant_environment": "alpine_mountain_highlands",
		"terrain_style": "stepped_mountain_peaks",
		"path_style": "carved_mountain_switchback",
		"atmosphere_style": "crisp_alpine_ridge",
		"particle_style": "wind_motes",
		"landmark_types": ["alpine_watchtower", "mountain_arch", "ridge_waterfall"],
		"destination_styles": ["stone_outcrop_ledge", "cliff_bastion", "alpine_watchtower", "summit_citadel"],
		"palette": {
			"sky_top": Color(0.32, 0.62, 0.90, 1.0),
			"sky_bottom": Color(0.92, 0.88, 0.94, 1.0),
			"ground_primary": Color(0.30, 0.56, 0.36, 1.0),
			"ground_secondary": Color(0.46, 0.68, 0.42, 1.0),
			"island_surface": Color(0.56, 0.74, 0.44, 1.0),
			"cliff_color": Color(0.44, 0.48, 0.58, 1.0),
			"water_color": Color(0.20, 0.68, 0.88, 1.0),
			"shore_color": Color(0.86, 0.84, 0.78, 1.0),
			"path_outer": Color(0.72, 0.66, 0.58, 1.0),
			"path_inner": Color(0.94, 0.90, 0.84, 1.0),
			"accent_color": Color(0.92, 0.26, 0.22, 1.0)
		}
	},

	# --------------------------------------------------------------------------
	# 5. LANDMARK REGION WORLD: GREAT PYRAMIDS OF GIZA • EGYPT
	# --------------------------------------------------------------------------
	"desert": {
		"theme_id": "desert",
		"world_type": WORLD_TYPE_LANDMARK_REGION,
		"world_id": "giza",
		"world_name_en": "Great Pyramids of Giza • Egypt",
		"world_name_vi": "Kim Tự Tháp Giza • Ai Cập",
		"name_en": "Great Pyramids of Giza • Egypt",
		"name_vi": "Kim Tự Tháp Giza • Ai Cập",
		"region_id": "giza_nile_egypt",
		"region_name_en": "Giza Plateau & Nile Oasis • Egypt",
		"region_name_vi": "Kim Tự Tháp Giza & Sông Nile • Ai Cập",
		"country_or_region_en": "Giza & Nile Valley, Egypt",
		"country_or_region_vi": "Cao Nguyên Giza & Sông Nile, Ai Cập",
		"subregions": ["nile_palm_oasis", "sphinx_causeway", "golden_sand_dunes", "great_pyramids_plateau"],
		"subregion_names_en": ["Nile Palm Oasis", "Sphinx Causeway", "Golden Sand Dunes", "Great Pyramids Plateau"],
		"subregion_names_vi": ["Ốc Đảo Cọ Sông Nile", "Đại Lộ Nhân Sư", "Đồi Cát Vàng Sahara", "Cao Nguyên Đại Kim Tự Tháp"],
		"primary_landmark_id": "giza_pyramids_sphinx",
		"primary_landmark_en": "Great Pyramids of Khufu & Khafre, Guardian Sphinx & Nile Oasis",
		"primary_landmark_vi": "Đại Kim Tự Tháp Giza, Tượng Nhân Sư & Ốc Đảo Sông Nile",
		"gameplay_background_theme": "landmark_giza_pyramids_desert",
		"gameplay_backgrounds": ["egypt_nile_oasis", "egypt_sphinx_avenue", "egypt_golden_dunes", "egypt_great_pyramids"],
		"dominant_environment": "golden_sand_dunes",
		"terrain_style": "sand_dune_oases",
		"path_style": "desert_caravan_stones",
		"atmosphere_style": "amber_sun_mirage",
		"particle_style": "golden_sand_motes",
		"landmark_types": ["oasis_palm_spring", "sandstone_obelisk", "pyramid_gate"],
		"destination_styles": ["sandstone_plaza", "dune_oasis_pad", "sun_obelisk_shrine", "pharaoh_citadel"],
		"palette": {
			"sky_top": Color(0.90, 0.58, 0.28, 1.0),
			"sky_bottom": Color(1.0, 0.88, 0.62, 1.0),
			"ground_primary": Color(0.84, 0.58, 0.28, 1.0),
			"ground_secondary": Color(0.92, 0.72, 0.40, 1.0),
			"island_surface": Color(0.96, 0.80, 0.50, 1.0),
			"cliff_color": Color(0.72, 0.42, 0.22, 1.0),
			"water_color": Color(0.12, 0.68, 0.78, 1.0),
			"shore_color": Color(1.0, 0.90, 0.62, 1.0),
			"path_outer": Color(0.80, 0.56, 0.30, 1.0),
			"path_inner": Color(0.97, 0.88, 0.66, 1.0),
			"accent_color": Color(1.0, 0.86, 0.24, 1.0)
		}
	},

	# --------------------------------------------------------------------------
	# 6. TOWN WORLD: ALPINE VILLAGE • SWISS ALPS
	# --------------------------------------------------------------------------
	"snow_ice": {
		"theme_id": "snow_ice",
		"world_type": WORLD_TYPE_TOWN,
		"world_id": "alpine_village",
		"world_name_en": "Alpine Village • Swiss Alps",
		"world_name_vi": "Làng Núi Tuyết • Dãy Alps Thụy Sĩ",
		"name_en": "Alpine Village • Swiss Alps",
		"name_vi": "Làng Núi Tuyết • Dãy Alps Thụy Sĩ",
		"region_id": "zermatt_swiss_alps",
		"region_name_en": "Zermatt Alpine Village • Switzerland",
		"region_name_vi": "Thị Trấn Zermatt • Dãy Alps Thụy Sĩ",
		"country_or_region_en": "Valais, Switzerland",
		"country_or_region_vi": "Valais, Thụy Sĩ",
		"subregions": ["timber_chalet_lane", "village_clock_square", "stone_viaduct_crossing", "glacier_bell_chapel"],
		"subregion_names_en": ["Timber Chalet Lane", "Village Clock Square", "Alpine Viaduct Crossing", "Matterhorn Bell Chapel"],
		"subregion_names_vi": ["Phố Nhà Gỗ Chalet", "Quảng Trường Tháp Đồng Hồ", "Cầu Đá Vòm Qua Suối", "Nhà Nguyện Chân Đỉnh Matterhorn"],
		"primary_landmark_id": "matterhorn_alpine_clocktower",
		"primary_landmark_en": "Alpine Village Clocktower, Timber Chalets & Matterhorn Peak",
		"primary_landmark_vi": "Tháp Đồng Hồ Thị Trấn, Nhà Gỗ Tuyết & Đỉnh Matterhorn",
		"gameplay_background_theme": "town_swiss_alpine_chalet_village",
		"gameplay_backgrounds": ["alps_chalet_meadow", "alps_village_square", "alps_viaduct_gorge", "alps_matterhorn_summit"],
		"dominant_environment": "glacial_snow_fjord",
		"terrain_style": "ice_floe_terraces",
		"path_style": "frosted_ice_bridge",
		"atmosphere_style": "aurora_frost_glow",
		"particle_style": "snowflakes",
		"landmark_types": ["ice_arch", "aurora_beacon", "frost_citadel_spire"],
		"destination_styles": ["snow_terrace", "glacier_crystal_pad", "frost_watchtower", "ice_crown_palace"],
		"palette": {
			"sky_top": Color(0.26, 0.56, 0.86, 1.0),
			"sky_bottom": Color(0.82, 0.92, 0.98, 1.0),
			"ground_primary": Color(0.36, 0.64, 0.44, 1.0),
			"ground_secondary": Color(0.68, 0.82, 0.90, 1.0),
			"island_surface": Color(0.90, 0.95, 0.98, 1.0),
			"cliff_color": Color(0.46, 0.54, 0.66, 1.0),
			"water_color": Color(0.18, 0.66, 0.88, 1.0),
			"shore_color": Color(0.86, 0.84, 0.78, 1.0),
			"path_outer": Color(0.58, 0.56, 0.54, 1.0),
			"path_inner": Color(0.86, 0.84, 0.80, 1.0),
			"accent_color": Color(0.92, 0.24, 0.24, 1.0)
		}
	},

	# --------------------------------------------------------------------------
	# 7. MODERN CITY WORLD: TOKYO • MODERN METROPOLIS
	# --------------------------------------------------------------------------
	"volcano": {
		"theme_id": "volcano",
		"world_type": WORLD_TYPE_MODERN_CITY,
		"world_id": "tokyo",
		"world_name_en": "Tokyo • Modern Metropolis",
		"world_name_vi": "Tokyo • Đô Thị Hiện Đại",
		"name_en": "Tokyo • Modern Metropolis",
		"name_vi": "Tokyo • Đô Thị Hiện Đại",
		"region_id": "tokyo_metropolis_japan",
		"region_name_en": "Tokyo Bay & Skyline • Japan",
		"region_name_vi": "Đô Thị Tokyo • Nhật Bản",
		"country_or_region_en": "Tokyo, Japan",
		"country_or_region_vi": "Thủ Đô Tokyo, Nhật Bản",
		"subregions": ["shibuya_avenue_plaza", "sumida_river_bridge", "imperial_garden_park", "tokyo_tower_skyline"],
		"subregion_names_en": ["Shibuya Avenue Plaza", "Sumida River Bridge", "Imperial Garden Park", "Tokyo Tower Skyline"],
		"subregion_names_vi": ["Quảng Trường Giao Lộ Shibuya", "Cầu Qua Sông Sumida", "Công Viên Hoàng Cung", "Tháp Tokyo & Đường Chân Trời"],
		"primary_landmark_id": "tokyo_tower_skyline",
		"primary_landmark_en": "Tokyo Tower, Illuminated High-Rise Skyline & Sumida River Bridges",
		"primary_landmark_vi": "Tháp Tokyo Đỏ Trắng, Tòa Nhà Chọc Trời & Cầu Sông Sumida",
		"gameplay_background_theme": "modern_city_tokyo_neon_skyline",
		"gameplay_backgrounds": ["tokyo_avenue_plaza", "tokyo_sumida_bridge", "tokyo_urban_park", "tokyo_tower_vista"],
		"dominant_environment": "volcanic_caldera",
		"terrain_style": "basalt_lava_ledges",
		"path_style": "basalt_causeway",
		"atmosphere_style": "ember_caldera_glow",
		"particle_style": "ember_sparks",
		"landmark_types": ["magma_vent", "obsidian_monolith", "flame_citadel_arch"],
		"destination_styles": ["basalt_platform", "obsidian_bastion", "ember_shrine", "volcano_fortress"],
		"palette": {
			"sky_top": Color(0.16, 0.26, 0.52, 1.0),
			"sky_bottom": Color(0.88, 0.56, 0.48, 1.0),
			"ground_primary": Color(0.28, 0.34, 0.44, 1.0),
			"ground_secondary": Color(0.38, 0.46, 0.56, 1.0),
			"island_surface": Color(0.76, 0.80, 0.86, 1.0),
			"cliff_color": Color(0.32, 0.36, 0.46, 1.0),
			"water_color": Color(0.16, 0.52, 0.78, 1.0),
			"shore_color": Color(0.82, 0.84, 0.88, 1.0),
			"path_outer": Color(0.42, 0.46, 0.54, 1.0),
			"path_inner": Color(0.84, 0.86, 0.92, 1.0),
			"accent_color": Color(0.96, 0.32, 0.26, 1.0)
		}
	},

	# --------------------------------------------------------------------------
	# 8. COUNTRY WORLD: ITALY • TUSCANY TO ROME
	# --------------------------------------------------------------------------
	"ancient_ruins": {
		"theme_id": "ancient_ruins",
		"world_type": WORLD_TYPE_COUNTRY,
		"world_id": "italy",
		"world_name_en": "Italy • Tuscany to Rome",
		"world_name_vi": "Đất Nước Ý • Tuscany Đến Rome",
		"name_en": "Italy • Tuscany to Rome",
		"name_vi": "Đất Nước Ý • Tuscany Đến Rome",
		"region_id": "italy_country_journey",
		"region_name_en": "Italy • Tuscany, Pisa, Venice, Florence & Rome",
		"region_name_vi": "Hành Trình Nước Ý • Tuscany, Pisa, Venice, Florence & Rome",
		"country_or_region_en": "Italian Peninsula, Italy",
		"country_or_region_vi": "Cộng Hòa Ý (Italy)",
		"subregions": ["tuscan_countryside", "pisa_miracoli", "venice_canals", "florence_duomo", "rome_colosseum"],
		"subregion_names_en": ["Tuscan Hills", "Pisa Piazza", "Venice Canals", "Florence Duomo", "Ancient Rome"],
		"subregion_names_vi": ["Đồi Nho Tuscany", "Tháp Nghiêng Pisa", "Kênh Đào Venice", "Nhà Thờ Florence", "Đấu Trường La Mã Rome"],
		"primary_landmark_id": "roman_colosseum_pisa_venice",
		"primary_landmark_en": "Roman Colosseum, Leaning Tower of Pisa, Venice Canals & Florence Duomo",
		"primary_landmark_vi": "Đấu Trường La Mã, Tháp Nghiêng Pisa, Kênh Đào Venice & Mái Vòm Florence",
		"gameplay_background_theme": "country_italy_regional_journey",
		"gameplay_backgrounds": ["italy_tuscan_hills", "italy_pisa_plaza", "italy_venice_canal", "italy_florence_duomo", "italy_rome_colosseum"],
		"dominant_environment": "sunlit_temple_ruins",
		"terrain_style": "stone_temple_plazas",
		"path_style": "temple_flagstone_road",
		"atmosphere_style": "sacred_valley_haze",
		"particle_style": "golden_pollen",
		"landmark_types": ["sunken_colonnade", "stepped_pyramid", "ancient_arch"],
		"destination_styles": ["chiseled_temple_pad", "colonnade_pedestal", "sun_altar_shrine", "grand_temple_gate"],
		"palette": {
			"sky_top": Color(0.32, 0.66, 0.90, 1.0),
			"sky_bottom": Color(0.92, 0.93, 0.82, 1.0),
			"ground_primary": Color(0.42, 0.64, 0.32, 1.0),
			"ground_secondary": Color(0.76, 0.68, 0.48, 1.0),
			"island_surface": Color(0.86, 0.78, 0.58, 1.0),
			"cliff_color": Color(0.70, 0.56, 0.42, 1.0),
			"water_color": Color(0.14, 0.66, 0.78, 1.0),
			"shore_color": Color(0.92, 0.84, 0.68, 1.0),
			"path_outer": Color(0.76, 0.66, 0.52, 1.0),
			"path_inner": Color(0.95, 0.90, 0.78, 1.0),
			"accent_color": Color(0.88, 0.44, 0.24, 1.0)
		}
	},

	# --------------------------------------------------------------------------
	# 9. LANDMARK REGION WORLD: PARIS • EIFFEL TOWER & SEINE
	# --------------------------------------------------------------------------
	"crystal_sanctuary": {
		"theme_id": "crystal_sanctuary",
		"world_type": WORLD_TYPE_LANDMARK_REGION,
		"world_id": "paris",
		"world_name_en": "Paris • Eiffel Tower & Seine",
		"world_name_vi": "Paris • Tháp Eiffel & Sông Seine",
		"name_en": "Paris • Eiffel Tower & Seine",
		"name_vi": "Paris • Tháp Eiffel & Sông Seine",
		"region_id": "paris_seine_france",
		"region_name_en": "Paris • Eiffel Tower & Seine",
		"region_name_vi": "Paris • Tháp Eiffel & Sông Seine",
		"country_or_region_en": "Paris, France",
		"country_or_region_vi": "Thủ Đô Paris, Pháp",
		"subregions": ["latin_quarter_boulevard", "pont_alexandre_seine", "champ_de_mars_gardens", "eiffel_tower_esplanade"],
		"subregion_names_en": ["Haussmann Boulevard", "Pont Alexandre III", "Champ de Mars Gardens", "Eiffel Tower Esplanade"],
		"subregion_names_vi": ["Đại Lộ Kiến Trúc Pháp", "Cầu Cổ Qua Sông Seine", "Vườn Champ de Mars", "Quảng Trường Tháp Eiffel"],
		"primary_landmark_id": "eiffel_tower_seine",
		"primary_landmark_en": "Eiffel Tower Lattice Spire, Seine River Bridges & Haussmann Mansard Roofs",
		"primary_landmark_vi": "Tháp Eiffel, Cầu Vòm Sông Seine & Phố Kiến Trúc Cổ Điển Paris",
		"gameplay_background_theme": "landmark_paris_eiffel_seine",
		"gameplay_backgrounds": ["paris_haussmann_street", "paris_seine_bridge", "paris_champ_de_mars", "paris_eiffel_promenade"],
		"dominant_environment": "amethyst_crystal_cavern",
		"terrain_style": "crystal_geode_platforms",
		"path_style": "quartz_light_bridge",
		"atmosphere_style": "prismatic_shimmer",
		"particle_style": "crystal_motes",
		"landmark_types": ["prism_obelisk", "amethyst_spire", "crystal_cluster"],
		"destination_styles": ["crystal_platform", "quartz_pedestal", "geode_shrine", "crystal_cathedral"],
		"palette": {
			"sky_top": Color(0.32, 0.56, 0.86, 1.0),
			"sky_bottom": Color(0.90, 0.86, 0.92, 1.0),
			"ground_primary": Color(0.38, 0.60, 0.42, 1.0),
			"ground_secondary": Color(0.68, 0.66, 0.62, 1.0),
			"island_surface": Color(0.86, 0.82, 0.74, 1.0),
			"cliff_color": Color(0.54, 0.52, 0.58, 1.0),
			"water_color": Color(0.18, 0.62, 0.84, 1.0),
			"shore_color": Color(0.88, 0.86, 0.80, 1.0),
			"path_outer": Color(0.70, 0.66, 0.60, 1.0),
			"path_inner": Color(0.94, 0.92, 0.86, 1.0),
			"accent_color": Color(0.96, 0.78, 0.32, 1.0)
		}
	},

	# --------------------------------------------------------------------------
	# 10. SPACE / ASTRONOMICAL WORLD: MARS • OLYMPUS MONS
	# --------------------------------------------------------------------------
	"starlight_highlands": {
		"theme_id": "starlight_highlands",
		"world_type": WORLD_TYPE_SPACE,
		"world_id": "mars",
		"world_name_en": "Mars • Olympus Mons",
		"world_name_vi": "Sao Hỏa • Đỉnh Olympus Mons",
		"name_en": "Mars • Olympus Mons",
		"name_vi": "Sao Hỏa • Đỉnh Olympus Mons",
		"region_id": "mars_olympus_space",
		"region_name_en": "Mars • Valles Marineris & Olympus Mons",
		"region_name_vi": "Sao Hỏa • Hẻm Valles Marineris & Đỉnh Olympus",
		"country_or_region_en": "Solar System • Mars",
		"country_or_region_vi": "Hệ Mặt Trời • Hành Tinh Đỏ Sao Hỏa",
		"subregions": ["jezero_crater_basin", "valles_marineris_canyon", "ares_rover_outpost", "olympus_mons_observatory"],
		"subregion_names_en": ["Jezero Crater Basin", "Valles Marineris Canyon", "Rover Science Outpost", "Olympus Mons Observatory"],
		"subregion_names_vi": ["Hố Va Chạm Jezero", "Hẻm Núi Valles Marineris", "Trạm Tự Hành Sao Hỏa", "Đài Quan Sát Đỉnh Olympus"],
		"primary_landmark_id": "mars_olympus_observatory",
		"primary_landmark_en": "Olympus Mons Shield Volcano, Mars Science Rover & Deep-Space Array",
		"primary_landmark_vi": "Núi Lửa Olympus Mons, Xe Tự Hành Sao Hỏa & Trạm Thiên Văn",
		"gameplay_background_theme": "space_mars_planetary_surface",
		"gameplay_backgrounds": ["mars_jezero_crater", "mars_valles_canyon", "mars_rover_ridge", "mars_olympus_horizon"],
		"dominant_environment": "celestial_starlight_ridge",
		"terrain_style": "starlight_sanctuary_terraces",
		"path_style": "starlight_constellation_path",
		"atmosphere_style": "astral_night_sky",
		"particle_style": "stardust_sparks",
		"landmark_types": ["star_obelisk", "astral_observatory", "celestial_gate"],
		"destination_styles": ["starlight_terrace", "lunar_pedestal", "astral_rotunda", "cosmic_citadel"],
		"palette": {
			"sky_top": Color(0.14, 0.12, 0.22, 1.0),
			"sky_bottom": Color(0.78, 0.46, 0.30, 1.0),
			"ground_primary": Color(0.68, 0.32, 0.20, 1.0),
			"ground_secondary": Color(0.80, 0.42, 0.26, 1.0),
			"island_surface": Color(0.88, 0.52, 0.32, 1.0),
			"cliff_color": Color(0.46, 0.20, 0.14, 1.0),
			"water_color": Color(0.52, 0.24, 0.16, 1.0),
			"shore_color": Color(0.92, 0.62, 0.42, 1.0),
			"path_outer": Color(0.62, 0.34, 0.22, 1.0),
			"path_inner": Color(0.92, 0.68, 0.48, 1.0),
			"accent_color": Color(0.46, 0.90, 1.0, 1.0)
		}
	}
}

## Semantic World Overrides for the full 19-world Real-World & Astronomical Library (Correction 7)
const SEMANTIC_WORLD_OVERRIDES: Dictionary = {
	"tuscan_countryside": {
		"base_preset": "green_forest",
		"world_type": WORLD_TYPE_COUNTRYSIDE,
		"world_id": "tuscan_countryside"
	},
	"rural_countryside": {
		"base_preset": "green_forest",
		"world_type": WORLD_TYPE_COUNTRYSIDE,
		"world_id": "rural_countryside",
		"world_name_en": "Pastoral Countryside • Watermill Valley",
		"world_name_vi": "Đồng Quê Thanh Bình • Thung Lũng Cối Xay Nước",
		"country_or_region_en": "Loire & Cotswold Countryside",
		"country_or_region_vi": "Vùng Đồng Quê Xanh Mát",
		"subregions": ["meadow_pasture", "wooden_barn_farm", "miller_stream_crossing", "hilltop_windmill"],
		"subregion_names_en": ["Golden Meadow Pasture", "Timber Barn Farmstead", "Watermill Stream Crossing", "Hilltop Windmill"],
		"subregion_names_vi": ["Đồng Cỏ Vàng", "Nông Trại Nhà Gỗ", "Suối Cối Xay Nước", "Cối Xay Gió Đồi Cao"],
		"primary_landmark_id": "countryside_windmill_villa",
		"primary_landmark_en": "Countryside Windmill, Timber Farmstead & Meadow Stream",
		"primary_landmark_vi": "Cối Xay Gió Đồng Quê, Trang Trại Gỗ & Suối Xanh",
		"gameplay_background_theme": "countryside_pastoral_farmland"
	},
	"alpine_village": {
		"base_preset": "snow_ice",
		"world_type": WORLD_TYPE_TOWN,
		"world_id": "alpine_village"
	},
	"tokyo": {
		"base_preset": "volcano",
		"world_type": WORLD_TYPE_MODERN_CITY,
		"world_id": "tokyo"
	},
	"ho_chi_minh_city": {
		"base_preset": "tropical_coast",
		"world_type": WORLD_TYPE_MODERN_CITY,
		"world_id": "ho_chi_minh_city"
	},
	"new_york_city": {
		"base_preset": "tropical_coast",
		"world_type": WORLD_TYPE_MODERN_CITY,
		"world_id": "new_york_city",
		"world_name_en": "New York City • Manhattan Skyline",
		"world_name_vi": "New York • Đường Chân Trời Manhattan",
		"country_or_region_en": "New York, USA",
		"country_or_region_vi": "New York, Hoa Kỳ",
		"subregions": ["battery_park_harbor", "brooklyn_bridge_span", "central_park_terrace", "midtown_empire_skyline"],
		"subregion_names_en": ["Battery Park Harbor", "Brooklyn Bridge Span", "Central Park Terrace", "Midtown Skyline Plaza"],
		"subregion_names_vi": ["Cảng Battery Park", "Nhịp Cầu Brooklyn", "Công Viên Central Park", "Quảng Trường Midtown"],
		"primary_landmark_id": "nyc_empire_skyline",
		"primary_landmark_en": "Empire State Spire, Brooklyn Suspension Bridge & Central Park",
		"primary_landmark_vi": "Tháp Empire State, Cầu Treo Brooklyn & Công Viên Trung Tâm",
		"gameplay_background_theme": "modern_city_new_york_skyline"
	},
	"modern_city": {
		"base_preset": "volcano",
		"world_type": WORLD_TYPE_MODERN_CITY,
		"world_id": "modern_city",
		"world_name_en": "Metropolis • Modern Bay City",
		"world_name_vi": "Thành Phố Hiện Đại • Vịnh Đô Thị",
		"country_or_region_en": "Metropolitan Bay District",
		"country_or_region_vi": "Đặc Khu Đô Thị Hiện Đại",
		"primary_landmark_id": "tokyo_tower_skyline",
		"primary_landmark_en": "Glass Skyscraper Towers, Suspension Bridge & Waterfront Promenade",
		"primary_landmark_vi": "Tháp Kính Cao Tầng, Cầu Dây Văng & Đại Lộ Ven Sông",
		"gameplay_background_theme": "modern_city_metropolitan_skyline"
	},
	"italy": {
		"base_preset": "ancient_ruins",
		"world_type": WORLD_TYPE_COUNTRY,
		"world_id": "italy"
	},
	"venice": {
		"base_preset": "ancient_ruins",
		"world_type": WORLD_TYPE_TOWN,
		"world_id": "venice",
		"world_name_en": "Venice • Grand Canal & Rialto",
		"world_name_vi": "Venice • Kênh Đào & Cầu Rialto",
		"country_or_region_en": "Veneto, Italy",
		"country_or_region_vi": "Veneto, Ý",
		"subregions": ["gondola_lagoon_quay", "rialto_arch_bridge", "campanile_canal_square", "st_marks_piazzetta"],
		"subregion_names_en": ["Gondola Lagoon Quay", "Rialto Arch Bridge", "Canal Piazza", "St. Mark's Piazzetta"],
		"subregion_names_vi": ["Bến Thuyền Gondola", "Cầu Vòm Rialto", "Quảng Trường Kênh Đào", "Quảng Trường San Marco"],
		"primary_landmark_id": "venice_rialto_campanile",
		"primary_landmark_en": "Rialto Canal Bridge, Venetian Campanile & Gondola Waterways",
		"primary_landmark_vi": "Cầu Kênh Đào Rialto, Tháp Chuông Venice & Thuyền Gondola",
		"gameplay_background_theme": "town_venice_canal_lagoon"
	},
	"rome": {
		"base_preset": "ancient_ruins",
		"world_type": WORLD_TYPE_LANDMARK_REGION,
		"world_id": "rome",
		"world_name_en": "Rome • Colosseum & Roman Forum",
		"world_name_vi": "Rome • Đấu Trường La Mã",
		"country_or_region_en": "Lazio, Italy",
		"country_or_region_vi": "Thủ Đô Rome, Ý",
		"subregions": ["appian_stone_way", "tiber_arch_bridge", "imperial_forum_columns", "colosseum_arena_plaza"],
		"subregion_names_en": ["Appian Stone Way", "Tiber Arch Bridge", "Roman Forum Columns", "Colosseum Arena Plaza"],
		"subregion_names_vi": ["Đường Đá Cổ Appia", "Cầu Đá Sông Tiber", "Hàng Cột Quảng Trường La Mã", "Đấu Trường Colosseum"],
		"primary_landmark_id": "roman_colosseum_pisa_venice",
		"primary_landmark_en": "Roman Colosseum Arches, Imperial Forum Columns & Stone Pines",
		"primary_landmark_vi": "Vòm Đấu Trường Colosseum, Cột Đá La Mã & Thông Địa Trung Hải",
		"gameplay_background_theme": "landmark_rome_colosseum_forum"
	},
	"paris": {
		"base_preset": "crystal_sanctuary",
		"world_type": WORLD_TYPE_LANDMARK_REGION,
		"world_id": "paris"
	},
	"ha_long_bay": {
		"base_preset": "ocean_islands",
		"world_type": WORLD_TYPE_LANDMARK_REGION,
		"world_id": "ha_long_bay"
	},
	"mount_fuji": {
		"base_preset": "hills_mountains",
		"world_type": WORLD_TYPE_LANDMARK_REGION,
		"world_id": "mount_fuji"
	},
	"giza": {
		"base_preset": "desert",
		"world_type": WORLD_TYPE_LANDMARK_REGION,
		"world_id": "giza"
	},
	"grand_canyon": {
		"base_preset": "desert",
		"world_type": WORLD_TYPE_LANDMARK_REGION,
		"world_id": "grand_canyon",
		"world_name_en": "Grand Canyon • Colorado River",
		"world_name_vi": "Đại Vực Grand Canyon • Hoa Kỳ",
		"country_or_region_en": "Arizona, USA",
		"country_or_region_vi": "Arizona, Hoa Kỳ",
		"subregions": ["red_rock_trailhead", "colorado_river_gorge", "horseshoe_bend_terrace", "eagle_point_mesa"],
		"subregion_names_en": ["Red Rock Trailhead", "Colorado River Gorge", "Horseshoe Bend Terrace", "Grand Butte Overlook"],
		"subregion_names_vi": ["Đường Mòn Đá Đỏ", "Hẻm Sông Colorado", "Khúc Cua Móng Ngựa", "Đài Ngắm Đại Vực"],
		"primary_landmark_id": "grand_canyon_buttes",
		"primary_landmark_en": "Layered Red-Rock Buttes, Terraced Canyon Cliffs & Colorado River",
		"primary_landmark_vi": "Vách Đá Đỏ Phân Tầng, Đại Vực Hùng Vĩ & Dòng Sông Colorado",
		"gameplay_background_theme": "landmark_grand_canyon_red_rock",
		"palette": {
			"sky_top": Color(0.24, 0.56, 0.88, 1.0),
			"sky_bottom": Color(0.98, 0.78, 0.56, 1.0),
			"ground_primary": Color(0.76, 0.36, 0.22, 1.0),
			"ground_secondary": Color(0.88, 0.50, 0.30, 1.0),
			"island_surface": Color(0.92, 0.60, 0.36, 1.0),
			"cliff_color": Color(0.58, 0.24, 0.16, 1.0),
			"water_color": Color(0.14, 0.58, 0.68, 1.0),
			"shore_color": Color(0.94, 0.70, 0.46, 1.0),
			"path_outer": Color(0.68, 0.34, 0.20, 1.0),
			"path_inner": Color(0.94, 0.68, 0.44, 1.0),
			"accent_color": Color(1.0, 0.82, 0.28, 1.0)
		}
	},
	"swiss_alps": {
		"base_preset": "snow_ice",
		"world_type": WORLD_TYPE_LANDMARK_REGION,
		"world_id": "swiss_alps",
		"world_name_en": "Swiss Alps • Matterhorn Peak",
		"world_name_vi": "Dãy Alps Thụy Sĩ • Đỉnh Matterhorn",
		"country_or_region_en": "Swiss Alps, Switzerland",
		"country_or_region_vi": "Dãy Alps, Thụy Sĩ",
		"subregions": ["pine_valley_meadow", "glacial_melt_bridge", "high_snow_saddle", "matterhorn_horn_summit"],
		"subregion_names_en": ["Alpine Pine Meadow", "Glacial Melt Bridge", "High Snow Saddle", "Matterhorn Horn Overlook"],
		"subregion_names_vi": ["Thung Lũng Thông Xanh", "Cầu Đá Suối Băng", "Đèo Tuyết Cao", "Đỉnh Chóp Matterhorn"],
		"primary_landmark_id": "matterhorn_alpine_clocktower",
		"primary_landmark_en": "Pyramidal Matterhorn Peak, Glacial Ridges & Alpine Pines",
		"primary_landmark_vi": "Đỉnh Chóp Matterhorn Tuyết Trắng, Sống Núi Băng & Rừng Thông",
		"gameplay_background_theme": "landmark_swiss_alps_matterhorn"
	},
	"mars": {
		"base_preset": "starlight_highlands",
		"world_type": WORLD_TYPE_SPACE,
		"world_id": "mars"
	},
	"moon": {
		"base_preset": "starlight_highlands",
		"world_type": WORLD_TYPE_SPACE,
		"world_id": "moon",
		"world_name_en": "Moon • Sea of Tranquility",
		"world_name_vi": "Mặt Trăng • Biển Tĩnh Lặng",
		"country_or_region_en": "Earth-Moon System • Luna",
		"country_or_region_vi": "Hệ Trái Đất – Mặt Trăng",
		"subregions": ["tranquility_landing_pad", "rille_canyon_bridge", "tycho_crater_rim", "earthrise_lunar_dome"],
		"subregion_names_en": ["Tranquility Landing Pad", "Hadley Rille Crossing", "Tycho Crater Rim", "Earthrise Lunar Dome"],
		"subregion_names_vi": ["Bãi Đáp Biển Tĩnh Lặng", "Khe Nứt Mặt Trăng", "Vành Hố Va Chạm Tycho", "Trạm Vòm Ngắm Trái Đất"],
		"primary_landmark_id": "lunar_lander_earthrise",
		"primary_landmark_en": "Apollo Lunar Lander, Sculpted Crater Rims & Blue Earthrise",
		"primary_landmark_vi": "Tàu Đổ Bộ Mặt Trăng, Hố Va Chạm & Trái Đất Xanh Trên Đường Chân Trời",
		"gameplay_background_theme": "space_lunar_tranquility_crater",
		"palette": {
			"sky_top": Color(0.03, 0.05, 0.12, 1.0),
			"sky_bottom": Color(0.12, 0.16, 0.28, 1.0),
			"ground_primary": Color(0.38, 0.42, 0.48, 1.0),
			"ground_secondary": Color(0.52, 0.56, 0.62, 1.0),
			"island_surface": Color(0.66, 0.70, 0.76, 1.0),
			"cliff_color": Color(0.24, 0.27, 0.34, 1.0),
			"water_color": Color(0.28, 0.32, 0.40, 1.0),
			"shore_color": Color(0.76, 0.80, 0.86, 1.0),
			"path_outer": Color(0.46, 0.50, 0.58, 1.0),
			"path_inner": Color(0.82, 0.86, 0.92, 1.0),
			"accent_color": Color(0.38, 0.86, 1.0, 1.0)
		}
	},
	"milky_way": {
		"base_preset": "starlight_highlands",
		"world_type": WORLD_TYPE_SPACE,
		"world_id": "milky_way",
		"world_name_en": "Milky Way • Deep-Space Observatory",
		"world_name_vi": "Dải Ngân Hà • Đài Thiên Văn Vũ Trụ",
		"country_or_region_en": "Milky Way Galactic Core",
		"country_or_region_vi": "Dải Ngân Hà",
		"subregions": ["starlight_terrace", "nebula_bridge", "radio_telescope_array", "galactic_core_dome"],
		"subregion_names_en": ["Starlight Terrace", "Nebula Bridge", "Radio Telescope Array", "Galactic Core Observatory"],
		"subregion_names_vi": ["Thềm Ánh Sao", "Cầu Tinh Vân", "Hệ Kính Thiên Văn", "Đài Quan Sát Ngân Hà"],
		"primary_landmark_id": "milky_way_observatory_dome",
		"primary_landmark_en": "Galactic Core Band, Deep-Space Observatory Dome & Radio Array",
		"primary_landmark_vi": "Dải Ngân Hà Rực Rỡ, Đài Thiên Văn Mái Vòm & Ăng-ten Không Gian",
		"gameplay_background_theme": "space_milky_way_observatory",
		"palette": {
			"sky_top": Color(0.05, 0.09, 0.24, 1.0),
			"sky_bottom": Color(0.20, 0.28, 0.56, 1.0),
			"ground_primary": Color(0.18, 0.26, 0.46, 1.0),
			"ground_secondary": Color(0.28, 0.38, 0.62, 1.0),
			"island_surface": Color(0.36, 0.48, 0.72, 1.0),
			"cliff_color": Color(0.12, 0.18, 0.34, 1.0),
			"water_color": Color(0.26, 0.60, 0.90, 1.0),
			"shore_color": Color(0.68, 0.82, 0.96, 1.0),
			"path_outer": Color(0.68, 0.64, 0.46, 1.0),
			"path_inner": Color(0.94, 0.90, 0.76, 1.0),
			"accent_color": Color(1.0, 0.88, 0.36, 1.0)
		}
	}
}


static func create_preset(p_theme_id: String, hue_variation: float = 0.0) -> MapTheme:
	var legacy_alias := {
		"desert_dunes": "desert",
		"mountain_peaks": "hills_mountains",
		"snow_ice_kingdom": "snow_ice",
		"volcano_caldera": "volcano",
		"volcano_lava": "volcano"
	}
	var lookup_id: String = String(legacy_alias.get(p_theme_id, p_theme_id))

	if SEMANTIC_WORLD_OVERRIDES.has(lookup_id):
		var ov: Dictionary = SEMANTIC_WORLD_OVERRIDES[lookup_id]
		var base_key: String = String(ov.get("base_preset", "ocean_islands"))
		var spec_merged: Dictionary = PRESET_SPECS[base_key].duplicate(true)
		for k in ov.keys():
			if k == "base_preset":
				continue
			if k == "palette" and ov[k] is Dictionary:
				for pk in ov[k].keys():
					spec_merged["palette"][pk] = ov[k][pk]
			else:
				spec_merged[k] = ov[k]
		if ov.has("world_name_en"):
			spec_merged["name_en"] = ov["world_name_en"]
		if ov.has("world_name_vi"):
			spec_merged["name_vi"] = ov["world_name_vi"]
		var semantic_theme := from_dict(spec_merged)
		_apply_hue_variation(semantic_theme, hue_variation)
		return semantic_theme

	var key: String = lookup_id if PRESET_SPECS.has(lookup_id) else "ocean_islands"
	var spec: Dictionary = PRESET_SPECS[key].duplicate(true)
	if PRESET_SPECS.has(lookup_id):
		spec["theme_id"] = p_theme_id
	var theme := from_dict(spec)
	_apply_hue_variation(theme, hue_variation)
	return theme


static func create_world_for_page(p_theme_id: String, p_world_id: String, hue_variation: float = 0.0) -> MapTheme:
	var theme := create_preset(p_world_id if p_world_id != "" else p_theme_id, hue_variation)
	# Preserve stable internal theme_id for save/progression & test compatibility
	if p_theme_id != "":
		theme.theme_id = p_theme_id
	return theme


static func _apply_hue_variation(theme: MapTheme, hue_variation: float) -> void:
	if absf(hue_variation) > 0.001:
		for col_key in ["sky_top", "sky_bottom", "ground_primary", "ground_secondary", "island_surface", "water_color"]:
			if theme.palette.has(col_key):
				var c: Color = theme.palette[col_key]
				theme.palette[col_key] = Color.from_hsv(
					fposmod(c.h + hue_variation, 1.0),
					clampf(c.s, 0.18, 0.96),
					clampf(c.v, 0.12, 0.98),
					c.a
				)


static func from_preset(p_theme_id: String, hue_variation: float = 0.0) -> MapTheme:
	return create_preset(p_theme_id, hue_variation)


static func from_dict(spec: Dictionary) -> MapTheme:
	var t := new()
	t.theme_id = String(spec.get("theme_id", "ocean_islands"))
	t.world_type = String(spec.get("world_type", WORLD_TYPE_LANDMARK_REGION))
	t.world_id = String(spec.get("world_id", "ha_long_bay"))
	t.world_name_en = String(spec.get("world_name_en", spec.get("name_en", "Ha Long Bay • Vietnam")))
	t.world_name_vi = String(spec.get("world_name_vi", spec.get("name_vi", "Vịnh Hạ Long • Việt Nam")))
	t.name_en = String(spec.get("name_en", t.world_name_en))
	t.name_vi = String(spec.get("name_vi", t.world_name_vi))
	t.region_id = String(spec.get("region_id", "ha_long_bay_vietnam"))
	t.region_name_en = String(spec.get("region_name_en", t.name_en))
	t.region_name_vi = String(spec.get("region_name_vi", t.name_vi))
	t.country_or_region_en = String(spec.get("country_or_region_en", "Vietnam"))
	t.country_or_region_vi = String(spec.get("country_or_region_vi", "Việt Nam"))
	t.primary_landmark_id = String(spec.get("primary_landmark_id", "halong_karst_lighthouse"))
	t.primary_landmark_en = String(spec.get("primary_landmark_en", "Ha Long Limestone Karsts"))
	t.primary_landmark_vi = String(spec.get("primary_landmark_vi", "Quần Đảo Đá Vôi Hạ Long"))
	t.gameplay_background_theme = String(spec.get("gameplay_background_theme", "landmark_halong_emerald_karst_bay"))

	t.dominant_environment = String(spec.get("dominant_environment", "open_ocean_archipelago"))
	t.terrain_style = String(spec.get("terrain_style", "atoll_islands"))
	t.path_style = String(spec.get("path_style", "sea_stepping_stones"))
	t.atmosphere_style = String(spec.get("atmosphere_style", "sunlit_sea_breeze"))
	t.particle_style = String(spec.get("particle_style", "sea_bubbles"))

	var subs: Array = spec.get("subregions", ["coastal_bay", "karst_lagoon", "fishing_harbor", "lighthouse_cape"])
	t.subregions.clear()
	for s_item in subs:
		t.subregions.append(String(s_item))

	var sub_en: Array = spec.get("subregion_names_en", t.subregions)
	t.subregion_names_en.clear()
	for item in sub_en:
		t.subregion_names_en.append(String(item))

	var sub_vi: Array = spec.get("subregion_names_vi", t.subregion_names_en)
	t.subregion_names_vi.clear()
	for item in sub_vi:
		t.subregion_names_vi.append(String(item))

	var bgs: Array = spec.get("gameplay_backgrounds", ["halong_harbor_coast", "halong_karst_lagoon", "halong_fishing_village", "halong_lighthouse_point"])
	t.gameplay_backgrounds.clear()
	for bg_item in bgs:
		t.gameplay_backgrounds.append(String(bg_item))

	var lms: Array = spec.get("landmark_types", ["harbor_lighthouse", "coral_arch", "sailboat_pier"])
	t.landmark_types.clear()
	for item in lms:
		t.landmark_types.append(String(item))

	var dsts: Array = spec.get("destination_styles", ["sandy_cay_island", "coral_lagoon_isle", "lighthouse_bastion"])
	t.destination_styles.clear()
	for item in dsts:
		t.destination_styles.append(String(item))

	if spec.has("palette") and spec["palette"] is Dictionary:
		for k in spec["palette"].keys():
			t.palette[k] = spec["palette"][k]
	if spec.has("lighting_spec") and spec["lighting_spec"] is Dictionary:
		for k in spec["lighting_spec"].keys():
			t.lighting_spec[k] = spec["lighting_spec"][k]
	return t


func get_world_type_label(lang: String = "en") -> String:
	if lang == "vi":
		match world_type:
			WORLD_TYPE_COUNTRYSIDE: return "Đồng Quê"
			WORLD_TYPE_TOWN: return "Thị Trấn"
			WORLD_TYPE_MODERN_CITY: return "Thành Phố Hiện Đại"
			WORLD_TYPE_COUNTRY: return "Quốc Gia"
			WORLD_TYPE_LANDMARK_REGION: return "Kỳ Quan & Danh Thắng"
			WORLD_TYPE_SPACE: return "Không Gian & Thiên Văn"
			_: return "Thế Giới"
	match world_type:
		WORLD_TYPE_COUNTRYSIDE: return "Countryside"
		WORLD_TYPE_TOWN: return "Town"
		WORLD_TYPE_MODERN_CITY: return "Modern City"
		WORLD_TYPE_COUNTRY: return "Country"
		WORLD_TYPE_LANDMARK_REGION: return "Landmark Region"
		WORLD_TYPE_SPACE: return "Astronomical World"
		_: return "World"


func is_single_coherent_biome() -> bool:
	return (
		theme_id != ""
		and SUPPORTED_WORLD_TYPES.has(world_type)
		and world_id != ""
		and not subregions.is_empty()
		and dominant_environment != ""
		and terrain_style != ""
		and path_style != ""
		and not landmark_types.is_empty()
		and not destination_styles.is_empty()
	)


func is_coherent() -> bool:
	return is_single_coherent_biome()


func to_dict() -> Dictionary:
	return {
		"theme_id": theme_id,
		"world_type": world_type,
		"world_id": world_id,
		"world_name_en": world_name_en,
		"world_name_vi": world_name_vi,
		"name_en": name_en,
		"name_vi": name_vi,
		"region_id": region_id,
		"region_name_en": region_name_en,
		"region_name_vi": region_name_vi,
		"country_or_region_en": country_or_region_en,
		"country_or_region_vi": country_or_region_vi,
		"subregions": subregions.duplicate(),
		"subregion_names_en": subregion_names_en.duplicate(),
		"subregion_names_vi": subregion_names_vi.duplicate(),
		"primary_landmark_id": primary_landmark_id,
		"primary_landmark_en": primary_landmark_en,
		"primary_landmark_vi": primary_landmark_vi,
		"gameplay_background_theme": gameplay_background_theme,
		"gameplay_backgrounds": gameplay_backgrounds.duplicate(),
		"dominant_environment": dominant_environment,
		"terrain_style": terrain_style,
		"path_style": path_style,
		"atmosphere_style": atmosphere_style,
		"particle_style": particle_style,
		"landmark_types": landmark_types.duplicate(),
		"destination_styles": destination_styles.duplicate(),
		"palette": palette.duplicate(true),
		"lighting_spec": lighting_spec.duplicate(true),
		"is_single_coherent_biome": is_single_coherent_biome()
	}
