class_name BlockPuzzleMapConfig
extends RefCounted

const MapTheme = preload("res://scripts/map_core/map_theme.gd")
const MapRoute = preload("res://scripts/map_core/map_route.gd")
const MapNode = preload("res://scripts/map_core/map_node.gd")
const MapPage = preload("res://scripts/map_core/map_page.gd")
const MapLayoutGenerator = preload("res://scripts/map_core/map_layout_generator.gd")
const MapData = preload("res://scripts/map_core/map_data.gd")

## BlockPuzzleMapConfig — Block Puzzle World Type & Real-World Configuration (Correction 7)
## Maps all 500 Block Puzzle levels into 68 self-contained MapPages (5–10 levels per page).
## Clearly separates the 6 World Types:
##   1. Countryside World     (e.g. Tuscan Countryside, Pastoral Farmland)
##   2. Town World            (e.g. Alpine Village, Venice Canal Town)
##   3. Modern City World     (e.g. Ho Chi Minh City, Tokyo, New York City)
##   4. Country World         (e.g. Italy: Tuscan Countryside -> Pisa -> Venice -> Florence -> Rome)
##   5. Landmark Region World (e.g. Ha Long Bay, Mount Fuji, Great Pyramids of Giza, Grand Canyon, Paris Eiffel District, Swiss Alps)
##   6. Space / Astronomical  (e.g. Mars, Moon, Milky Way Observatory)
## Preserves internal `theme_id` identifiers for 100% compatibility with saves and tests.

const TOTAL_LEVELS: int = 500

## Repeating cycle of 5–10 levels per page (includes 5, 6, 7, 8, 9, and 10)
const LEVEL_COUNT_PATTERN: Array[int] = [6, 7, 8, 9, 5, 8, 7, 10, 6, 8]

## Stable internal theme_id rotation preserved for save/test compatibility
const THEME_ROTATION: Array[String] = [
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

## Semantic World Library rotation per slot across tier cycles
const SLOT_WORLD_CYCLES: Array = [
	["ha_long_bay"],
	["new_york_city", "ho_chi_minh_city"],
	["tuscan_countryside", "rural_countryside"],
	["mount_fuji"],
	["grand_canyon", "giza"],
	["alpine_village", "swiss_alps"],
	["tokyo", "modern_city"],
	["italy", "venice", "rome"],
	["paris"],
	["mars", "moon", "milky_way"]
]


static func build_block_puzzle_map_data(total_levels: int = TOTAL_LEVELS) -> MapData:
	var map_data := MapData.new("block_puzzle_world")
	map_data.world_title_en = "Block Puzzle World Journey"
	map_data.world_title_vi = "Hành Trình Thế Giới Xếp Khối"

	var page_specs: Array[Dictionary] = generate_page_specs(total_levels)
	map_data.configure_from_page_specs(page_specs)
	return map_data


static func generate_page_specs(total_levels: int = TOTAL_LEVELS) -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	var current_level: int = 1
	var page_idx: int = 0

	while current_level <= total_levels:
		var pattern_count: int = LEVEL_COUNT_PATTERN[page_idx % LEVEL_COUNT_PATTERN.size()]
		var remaining: int = total_levels - current_level + 1
		var count: int = pattern_count
		if remaining < count:
			count = remaining
		elif remaining - count > 0 and remaining - count < 5:
			# Ensure the final page also stays within the 5–10 level range
			count = clampi(int(ceil(float(remaining) * 0.5)), 5, 10)
			if remaining <= 10:
				count = remaining

		var lv_ids: Array[int] = []
		for i in range(count):
			lv_ids.append(current_level + i)

		var slot_idx: int = page_idx % THEME_ROTATION.size()
		var tier_cycle: int = int(page_idx / THEME_ROTATION.size())
		var theme_id: String = THEME_ROTATION[slot_idx]
		var world_Variants: Array = SLOT_WORLD_CYCLES[slot_idx]
		var world_id: String = String(world_Variants[tier_cycle % world_Variants.size()])

		var c_spec: Dictionary = get_country_manifest_for_page(page_idx)
		var c_id: String = String(c_spec.get("country_id", "vietnam"))
		var c_en: String = String(c_spec.get("country_name_en", "Vietnam"))
		var c_vi: String = String(c_spec.get("country_name_vi", "Việt Nam"))
		var j_dir: String = String(c_spec.get("journey_direction", "north_to_south"))
		var auth_src: String = String(c_spec.get("authority_source", "National Tourism Board"))
		var lm_density: String = String(c_spec.get("landmark_density", "moderate"))
		var raw_c_dests: Array[Dictionary] = c_spec.get("destinations", [])
		var recon: Dictionary = MapLayoutGenerator.reconcile_country_destinations_with_levels(raw_c_dests, lv_ids)
		var c_dests: Array[Dictionary] = recon.get("country_destinations", [])
		var act_dests: Array[Dictionary] = recon.get("active_level_destinations", [])
		var omit_dests: Array[Dictionary] = recon.get("omitted_destinations", [])
		var c_poi: Dictionary = c_spec.get("independent_poi", {})

		var theme_obj: MapTheme = MapTheme.create_world_for_page(theme_id, world_id)
		theme_obj.country_or_region_en = c_en
		theme_obj.country_or_region_vi = c_vi
		theme_obj.world_name_en = "%s • %s" % [c_en, String(c_dests[0].get("destination_name", "")) if not c_dests.is_empty() else c_en]
		theme_obj.world_name_vi = "%s • %s" % [c_vi, String(c_dests[0].get("destination_name", "")) if not c_dests.is_empty() else c_vi]
		theme_obj.name_en = theme_obj.world_name_en
		theme_obj.name_vi = theme_obj.world_name_vi
		var title_en: String = theme_obj.world_name_en
		var title_vi: String = theme_obj.world_name_vi

		var seed_val: int = 104729 + (page_idx + 1) * 6151 + count * 313
		var comp_type: String = MapLayoutGenerator.get_composition_for_page(page_idx, seed_val)
		var milestones: Dictionary = _build_page_milestones(lv_ids, page_idx)

		specs.append({
			"page_index": page_idx,
			"page_number": page_idx + 1,
			"level_ids": lv_ids,
			"level_count": lv_ids.size(),
			"theme_id": theme_id,
			"world_type": theme_obj.world_type,
			"world_id": theme_obj.world_id,
			"country_id": c_id,
			"country_name_en": c_en,
			"country_name_vi": c_vi,
			"journey_direction": j_dir,
			"authority_source": auth_src,
			"landmark_density": lm_density,
			"country_destinations": c_dests,
			"active_level_destinations": act_dests,
			"omitted_destinations": omit_dests,
			"independent_poi": c_poi,
			"canonical_gameplay_background": c_spec.get("canonical_gameplay_background", {}).duplicate(true),
			"world_name_en": theme_obj.world_name_en,
			"world_name_vi": theme_obj.world_name_vi,
			"country_or_region_en": theme_obj.country_or_region_en,
			"country_or_region_vi": theme_obj.country_or_region_vi,
			"primary_landmark_en": theme_obj.primary_landmark_en,
			"primary_landmark_vi": theme_obj.primary_landmark_vi,
			"gameplay_background_theme": theme_obj.gameplay_background_theme,
			"theme": theme_obj,
			"title_en": title_en,
			"title_vi": title_vi,
			"composition_type": comp_type,
			"seed_value": seed_val,
			"milestones": milestones
		})

		current_level += count
		page_idx += 1

	return specs


static func _build_page_milestones(lv_ids: Array[int], page_idx: int) -> Dictionary:
	var milestones: Dictionary = {}
	var count: int = lv_ids.size()
	if count <= 0:
		return milestones

	# Page entry landmark on pages after Page 1
	if page_idx > 0:
		var first_lv: int = lv_ids[0]
		milestones[first_lv] = {
			"is_milestone": true,
			"milestone_type": "chapter_unlock_milestone",
			"milestone_icon": "⚑",
			"scale_mult": 1.12,
			"halo_radius": 7.0,
			"visual_tier": 1
		}

	# Mid-page scenic landmark on Page 1 (Level 3) and longer pages (7–10 levels)
	if count >= 7 or page_idx == 0:
		var mid_idx: int = (int(count / 2) - 1) if (count % 2 == 0) else int(count / 2)
		var mid_lv: int = lv_ids[mid_idx]
		var is_chest: bool = (page_idx % 2 == 1)
		milestones[mid_lv] = {
			"is_milestone": true,
			"milestone_type": "chest" if is_chest else "star",
			"milestone_icon": "★",
			"scale_mult": 1.14,
			"halo_radius": 8.0,
			"visual_tier": 2
		}

	# Page finale milestone on the final level of the page
	var last_lv: int = lv_ids[count - 1]
	var is_major_boss: bool = ((page_idx + 1) % 3 == 0) or (last_lv == TOTAL_LEVELS)
	milestones[last_lv] = {
		"is_milestone": true,
		"milestone_type": "crown",
		"milestone_icon": "♛" if is_major_boss else "★",
		"scale_mult": 1.22 if is_major_boss else 1.16,
		"halo_radius": 11.0 if is_major_boss else 8.5,
		"visual_tier": 3 if is_major_boss else 2
	}
	return milestones


static func _to_roman(num: int) -> String:
	var romans := [
		[10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]
	]
	var n: int = clampi(num, 1, 39)
	var out: String = ""
	for pair in romans:
		while n >= int(pair[0]):
			out += String(pair[1])
			n -= int(pair[0])
	return out


## Country-specific landmark density ("very_rich" | "rich" | "moderate" | "sparse")
## and researched destination visual contexts ("major_landmark", "landmark_environment",
## "regional_scene", "small_destination_marker").
static func _get_country_landmark_density_profile(c_id: String) -> Dictionary:
	match c_id:
		# VERY RICH (4–6 recognizable landmarks/environments along the journey)
		"italy":
			return {"density": "very_rich", "featured": ["Milan", "Venice", "Florence", "Pisa", "Rome", "Amalfi Coast"], "env": ["Amalfi Coast"]}
		"japan":
			return {"density": "very_rich", "featured": ["Miyajima (Hiroshima)", "Osaka", "Kyoto", "Fujiyoshida", "Tokyo"], "env": ["Fujiyoshida"]}
		"france":
			return {"density": "very_rich", "featured": ["Avignon", "Chambord", "Mont-Saint-Michel", "Versailles", "Paris"], "env": ["Mont-Saint-Michel"]}
		"united_states":
			return {"density": "very_rich", "featured": ["New York City", "Washington, D.C.", "Chicago", "Grand Canyon", "San Francisco"], "env": ["Grand Canyon"]}
		"egypt":
			return {"density": "very_rich", "featured": ["Alexandria", "Cairo & Giza", "Karnak", "Abu Simbel"], "env": ["Cairo & Giza"]}
		"greece":
			return {"density": "very_rich", "featured": ["Heraklion (Crete)", "Santorini (Oia)", "Athens", "Meteora"], "env": ["Santorini (Oia)", "Meteora"]}
		"united_kingdom":
			return {"density": "very_rich", "featured": ["Edinburgh", "York", "Oxford", "London", "Stonehenge (Salisbury)"], "env": ["Stonehenge (Salisbury)"]}
		"china":
			return {"density": "very_rich", "featured": ["Hong Kong", "Guilin & Yangshuo", "Shanghai", "Xi'an", "Beijing"], "env": ["Guilin & Yangshuo"]}
		"spain":
			return {"density": "very_rich", "featured": ["Santiago de Compostela", "Barcelona", "Segovia", "Madrid", "Granada"], "env": []}
		"peru":
			return {"density": "very_rich", "featured": ["Trujillo (Chan Chan)", "Machu Picchu", "Cusco", "Puno (Lake Titicaca)"], "env": ["Machu Picchu", "Puno (Lake Titicaca)"]}
		"mexico":
			return {"density": "very_rich", "featured": ["Guadalajara", "Mexico City & Teotihuacán", "Palenque", "Chichén Itzá & Tulum"], "env": ["Palenque"]}
		"turkey":
			return {"density": "very_rich", "featured": ["Ephesus (Selçuk)", "Istanbul", "Pamukkale", "Cappadocia (Göreme)", "Mount Nemrut"], "env": ["Pamukkale", "Cappadocia (Göreme)"]}
		"india":
			return {"density": "very_rich", "featured": ["Amritsar", "Agra", "Jaipur", "Mumbai", "Alleppey & Kochi (Kerala)"], "env": ["Alleppey & Kochi (Kerala)"]}

		# RICH (3–5 recognizable landmarks/environments + regional scenes)
		"vietnam":
			return {"density": "rich", "featured": ["Hanoi", "Ha Long Bay", "Hue", "Da Nang / Hoi An", "Ho Chi Minh City"], "env": ["Ha Long Bay"]}
		"south_korea":
			return {"density": "rich", "featured": ["Seoul", "Gyeongju", "Busan", "Jeju Island"], "env": ["Jeju Island"]}
		"thailand":
			return {"density": "rich", "featured": ["Chiang Rai", "Chiang Mai", "Bangkok", "Phuket & Krabi"], "env": ["Phuket & Krabi"]}
		"morocco":
			return {"density": "rich", "featured": ["Fes", "Marrakesh", "Merzouga (Erg Chebbi)"], "env": ["Merzouga (Erg Chebbi)"]}
		"indonesia":
			return {"density": "rich", "featured": ["Borobudur (Magelang)", "Yogyakarta (Prambanan)", "Ubud & Tanah Lot (Bali)", "Labuan Bajo (Komodo)"], "env": ["Ubud & Tanah Lot (Bali)", "Labuan Bajo (Komodo)"]}
		"germany":
			return {"density": "rich", "featured": ["Berlin", "Cologne", "Munich", "Neuschwanstein (Füssen)"], "env": []}
		"brazil":
			return {"density": "rich", "featured": ["Manaus", "Brasília", "Rio de Janeiro", "Foz do Iguaçu"], "env": ["Foz do Iguaçu"]}
		"netherlands":
			return {"density": "rich", "featured": ["Kinderdijk", "Rotterdam", "Keukenhof (Lisse)", "Amsterdam"], "env": ["Kinderdijk", "Keukenhof (Lisse)"]}
		"jordan":
			return {"density": "rich", "featured": ["Jerash", "Petra", "Wadi Rum & Aqaba"], "env": ["Wadi Rum & Aqaba"]}
		"austria":
			return {"density": "rich", "featured": ["Innsbruck", "Salzburg", "Hallstatt", "Vienna"], "env": ["Hallstatt"]}
		"portugal":
			return {"density": "rich", "featured": ["Porto & Douro Valley", "Sintra", "Lisbon", "Lagos & Benagil (Algarve)"], "env": ["Lagos & Benagil (Algarve)"]}
		"australia":
			return {"density": "rich", "featured": ["Sydney", "Cairns (Great Barrier Reef)", "Melbourne & Great Ocean Road", "Uluru (Red Centre)"], "env": ["Cairns (Great Barrier Reef)", "Melbourne & Great Ocean Road", "Uluru (Red Centre)"]}
		"united_arab_emirates":
			return {"density": "rich", "featured": ["Al Ain", "Dubai", "Abu Dhabi"], "env": ["Al Ain"]}
		"cambodia":
			return {"density": "rich", "featured": ["Angkor Thom (Bayon)", "Siem Reap (Angkor Wat)", "Tonlé Sap Floating Villages", "Phnom Penh"], "env": ["Tonlé Sap Floating Villages"]}
		"croatia":
			return {"density": "rich", "featured": ["Plitvice Lakes", "Split & Hvar", "Dubrovnik"], "env": ["Plitvice Lakes"]}
		"singapore":
			return {"density": "rich", "featured": ["Chinatown & Buddha Relic", "Marina Bay", "Gardens by the Bay", "Jewel Changi"], "env": ["Gardens by the Bay"]}
		"poland":
			return {"density": "rich", "featured": ["Gdańsk", "Malbork", "Warsaw", "Kraków"], "env": []}
		"sri_lanka":
			return {"density": "rich", "featured": ["Sigiriya", "Kandy", "Nuwara Eliya & Ella", "Galle Fort"], "env": ["Sigiriya", "Nuwara Eliya & Ella"]}
		"belgium":
			return {"density": "rich", "featured": ["Bruges", "Brussels", "Dinant (Ardennes)"], "env": ["Dinant (Ardennes)"]}
		"myanmar":
			return {"density": "rich", "featured": ["Mandalay", "Bagan", "Inle Lake", "Yangon"], "env": ["Bagan", "Inle Lake"]}
		"hungary":
			return {"density": "rich", "featured": ["Tihany (Lake Balaton)", "Esztergom & Visegrád", "Budapest"], "env": ["Tihany (Lake Balaton)"]}
		"taiwan":
			return {"density": "rich", "featured": ["Jiufen & Yehliu", "Taipei", "Taroko Gorge", "Sun Moon Lake"], "env": ["Taroko Gorge", "Sun Moon Lake"]}
		"uzbekistan":
			return {"density": "rich", "featured": ["Khiva (Itchan Kala)", "Bukhara", "Samarkand"], "env": []}

		# MODERATE (2–3 recognizable landmarks/environments + distinctive regional environments)
		"switzerland":
			return {"density": "moderate", "featured": ["Zermatt", "Lucerne", "St. Moritz"], "env": ["Zermatt", "St. Moritz"]}
		"canada":
			return {"density": "moderate", "featured": ["Quebec City", "Toronto", "Banff & Lake Louise"], "env": ["Banff & Lake Louise"]}
		"norway":
			return {"density": "moderate", "featured": ["Bergen", "Geirangerfjord", "Tromsø & North Cape"], "env": ["Geirangerfjord", "Tromsø & North Cape"]}
		"philippines":
			return {"density": "moderate", "featured": ["Banaue", "El Nido (Palawan)"], "env": ["Banaue", "El Nido (Palawan)"]}
		"nepal":
			return {"density": "moderate", "featured": ["Pokhara", "Kathmandu", "Namche & Everest"], "env": ["Pokhara", "Namche & Everest"]}
		"malaysia":
			return {"density": "moderate", "featured": ["George Town (Penang)", "Kuala Lumpur", "Malacca (Melaka)"], "env": []}
		"ireland":
			return {"density": "moderate", "featured": ["Dublin", "Cashel", "Cliffs of Moher"], "env": ["Cliffs of Moher"]}
		"sweden":
			return {"density": "moderate", "featured": ["Visby (Gotland)", "Stockholm", "Kiruna & Jukkasjärvi"], "env": ["Kiruna & Jukkasjärvi"]}
		"new_zealand":
			return {"density": "moderate", "featured": ["Auckland", "Milford Sound", "Queenstown & Wanaka"], "env": ["Milford Sound", "Queenstown & Wanaka"]}
		"czechia":
			return {"density": "moderate", "featured": ["Český Krumlov", "Prague", "Kutná Hora"], "env": []}
		"argentina":
			return {"density": "moderate", "featured": ["Puerto Iguazú", "Buenos Aires", "El Calafate & Ushuaia"], "env": ["Puerto Iguazú", "El Calafate & Ushuaia"]}
		"colombia":
			return {"density": "moderate", "featured": ["Cartagena de Indias", "Guatapé & Medellín", "Ipiales (Las Lajas)"], "env": ["Guatapé & Medellín"]}
		"finland":
			return {"density": "moderate", "featured": ["Suomenlinna & Helsinki", "Savonlinna (Lake Saimaa)"], "env": []}
		"kenya":
			return {"density": "moderate", "featured": ["Maasai Mara", "Amboseli", "Mombasa"], "env": ["Maasai Mara", "Amboseli"]}
		"romania":
			return {"density": "moderate", "featured": ["Hunedoara", "Brașov & Bran", "Bucharest"], "env": []}
		"pakistan":
			return {"density": "moderate", "featured": ["Lahore", "Islamabad", "Hunza Valley (Karimabad)"], "env": ["Hunza Valley (Karimabad)"]}
		"denmark":
			return {"density": "moderate", "featured": ["Odense (Egeskov)", "Copenhagen", "Skagen (Grenen)"], "env": ["Skagen (Grenen)"]}
		"south_africa":
			return {"density": "moderate", "featured": ["Cape Point", "Cape Town", "Blyde River Canyon"], "env": ["Cape Town", "Blyde River Canyon"]}
		"cuba":
			return {"density": "moderate", "featured": ["Viñales Valley", "Havana"], "env": ["Viñales Valley"]}
		"slovenia":
			return {"density": "moderate", "featured": ["Piran", "Lake Bled", "Ljubljana"], "env": ["Lake Bled"]}
		"georgia":
			return {"density": "moderate", "featured": ["Mestia & Ushguli", "Vardzia", "Tbilisi"], "env": ["Mestia & Ushguli", "Vardzia"]}

		# SPARSE (1–2 major landmarks + strong natural/cultural scenery)
		"chile":
			return {"density": "sparse", "featured": ["Paranal Observatory", "Torres del Paine"], "env": ["Torres del Paine"]}
		"saudi_arabia":
			return {"density": "sparse", "featured": ["AlUla (Hegra)", "Riyadh & Diriyah"], "env": ["AlUla (Hegra)"]}
		"tunisia":
			return {"density": "sparse", "featured": ["Tunis & Sidi Bou Said", "El Jem"], "env": []}
		"iceland":
			return {"density": "sparse", "featured": ["Reykjavík", "Jökulsárlón"], "env": ["Jökulsárlón"]}
		"maldives":
			return {"density": "sparse", "featured": ["Baa Atoll (Hanifaru)", "North Malé & Malé"], "env": ["Baa Atoll (Hanifaru)"]}
		"panama":
			return {"density": "sparse", "featured": ["Panama Canal (Miraflores)", "Panama City (Casco Viejo)"], "env": ["Panama Canal (Miraflores)"]}
		"oman":
			return {"density": "sparse", "featured": ["Muscat", "Nizwa & Bahla"], "env": []}
		"costa_rica":
			return {"density": "sparse", "featured": ["Arenal Volcano (La Fortuna)", "San José & Poás"], "env": ["Arenal Volcano (La Fortuna)"]}
		"mongolia":
			return {"density": "sparse", "featured": ["Kharkhorin (Erdene Zuu)", "Tsonjin Boldog (Terelj)"], "env": []}
		"ecuador":
			return {"density": "sparse", "featured": ["Galápagos (Santa Cruz & Bartolomé)", "Quito & Mitad del Mundo"], "env": ["Galápagos (Santa Cruz & Bartolomé)"]}
		"bolivia":
			return {"density": "sparse", "featured": ["La Paz & Tiwanaku", "Salar de Uyuni & Laguna Colorada"], "env": ["Salar de Uyuni & Laguna Colorada"]}
		_:
			return {"density": "moderate", "featured": [], "env": []}


static func derive_destination_grounding_spec(
	c_id: String,
	d_name: String,
	region: String,
	lm_id: String,
	lm_desc: String,
	env_type: String = ""
) -> Dictionary:
	var combined: String = ("%s %s %s %s %s" % [d_name, region, lm_id, lm_desc, env_type]).to_lower()
	var grounding_type: String = "GROUND"
	var water_rel: String = "none"
	var terrain_zone: String = "LAND"

	if lm_id == "pisa_tower" or d_name.to_lower().begins_with("pisa"):
		return {
			"grounding_type": "HISTORIC_SITE",
			"water_relationship": "none",
			"supporting_terrain_zone": "URBAN_GROUND"
		}
	if lm_id == "eiffel_tower" or d_name.to_lower().begins_with("paris"):
		return {
			"grounding_type": "URBAN",
			"water_relationship": "riverbank",
			"supporting_terrain_zone": "URBAN_GROUND"
		}
	if lm_id in [
		"halong_karst_harbor", "halong_harbor", "mont_saint_michel", "statue_of_liberty",
		"itsukushima_torii", "torii_shrine", "tanah_lot_bali", "phang_nga_james_bond",
		"krabi_railay_karsts", "el_nido_lagoons", "raja_ampat_wayag", "komodo_padar_island",
		"bled_island_castle", "trakai_island_castle", "stockholm_archipelago",
		"helsinki_suomenlinna", "pinnacle_rock_bartolome"
	] or combined.find("island") >= 0 or combined.find("archipelago") >= 0 or combined.find("atoll") >= 0 or combined.find("ha long") >= 0 or combined.find("phang nga") >= 0 or combined.find("galápagos") >= 0 or combined.find("galapagos") >= 0:
		grounding_type = "ISLAND"
		water_rel = "island_in_water"
		terrain_zone = "COASTLINE"
	elif lm_id in [
		"venice_canal", "venice_canal_rialto", "rijksmuseum_canals", "giethoorn_canals",
		"bruges_belfry_canals", "kinderdijk_windmills", "nyhavn_harbor",
		"panama_canal_miraflores"
	] or combined.find("canal") >= 0 or combined.find("venice") >= 0:
		grounding_type = "WATERFRONT"
		water_rel = "canal"
		terrain_zone = "WATERFRONT"
	elif lm_id in [
		"mekong_floating_market", "inle_lake_stilt_boats", "kerala_backwaters_houseboat",
		"okavango_delta_mokoro", "amazon_meeting_waters", "guilin_li_river_karsts",
		"ninh_binh_trang_an_karst", "hoian_covered_bridge_lanterns", "hoian_lanterns",
		"hanoi_hoan_kiem_pagoda", "hanoi_pagoda", "wat_arun_grand_palace",
		"chapel_bridge_lucerne", "chain_bridge_danube", "charles_bridge_castle",
		"mostar_stari_most", "victoria_falls_bridge", "tower_bridge_big_ben"
	] or combined.find("river") >= 0 or combined.find("delta") >= 0 or combined.find("floating") >= 0 or combined.find("lake") >= 0 or combined.find("loch") >= 0:
		grounding_type = "WATERFRONT"
		water_rel = "lake_shore" if (combined.find("lake") >= 0 or combined.find("loch") >= 0 or combined.find("hoan kiem") >= 0) else "riverbank"
		terrain_zone = "COASTLINE"
	elif lm_id in [
		"sydney_opera_harbour_bridge", "victoria_harbour_skyline", "bund_pudong_skyline",
		"auckland_sky_tower_harbour", "marina_bay_sands", "golden_gate", "golden_gate_bridge",
		"bosphorus_bridge", "lighthouse_landmark", "cape_of_good_hope", "belem_tower_jeronimos",
		"hercules_tower", "peggys_cove_lighthouse", "bryggen_wharf", "gamla_stan_vasa",
		"bo_kaap_waterfront", "havana_capitolio_malecon", "promenade_des_anglais",
		"dubrovnik_walls", "kotor_bay_fortress", "cartagena_walled_city", "qaitbay_citadel",
		"hassan_ii_mosque", "geirangerfjord_seven_sisters", "lofoten_reinebringen",
		"milford_sound_mitre_peak"
	] or combined.find("harbor") >= 0 or combined.find("harbour") >= 0 or combined.find("fjord") >= 0 or combined.find("bay") >= 0 or combined.find("coast") >= 0 or combined.find("beach") >= 0 or combined.find("port") >= 0:
		grounding_type = "CLIFF" if (combined.find("cliff") >= 0 or combined.find("fjord") >= 0 or combined.find("cape") >= 0) else "WATERFRONT"
		water_rel = "harbor" if (combined.find("harbor") >= 0 or combined.find("harbour") >= 0 or combined.find("port") >= 0 or combined.find("wharf") >= 0) else "bay_coast"
		terrain_zone = "COASTLINE"
	elif lm_id in [
		"amalfi_cliff_village", "cinque_terre_harbor", "oia_blue_domes",
		"meteora_monasteries", "meteora_cliffs", "tiger_nest_paro", "sigiriya_lion_rock",
		"acropolis_lindos", "parthenon_acropolis", "table_mountain", "grand_canyon_rim",
		"zhangjiajie_avatar_peaks", "cappadocia_chimneys", "pamukkale_travertines"
	] or combined.find("cliff") >= 0 or combined.find("canyon") >= 0 or combined.find("gorge") >= 0 or combined.find("acropolis") >= 0:
		grounding_type = "CLIFF"
		water_rel = "bay_coast" if (combined.find("amalfi") >= 0 or combined.find("cinque") >= 0 or combined.find("oia") >= 0 or combined.find("santorini") >= 0 or combined.find("lindos") >= 0) else "none"
		terrain_zone = "MOUNTAIN_HILL"
	elif lm_id in [
		"chureito_pagoda", "wat_phra_that_doi_suthep", "machu_picchu_citadel",
		"sacred_valley_ollantaytambo", "neuschwanstein_castle", "pena_palace_sintra",
		"bran_castle", "peles_castle", "alpine_chalet", "alpine_village",
		"zermatt_sanctuary", "matterhorn_zermatt", "jungfraujoch_sphinx",
		"banff_lake_louise", "jasper_icefields", "torres_del_paine", "fitz_roy_el_chalten",
		"mount_kilimanjaro", "mount_kenya", "kazbegi_gergeti_trinity", "arenal_volcano",
		"cotopaxi_avenue_volcanoes", "bromo_tengger_caldera", "mayon_volcano_cone",
		"christ_redeemer_corcovado"
	] or combined.find("mountain") >= 0 or combined.find("alps") >= 0 or combined.find("peak") >= 0 or combined.find("volcano") >= 0 or combined.find("highland") >= 0 or combined.find("andes") >= 0 or combined.find("himalaya") >= 0:
		grounding_type = "MOUNTAIN"
		water_rel = "none"
		terrain_zone = "MOUNTAIN_HILL"
	elif lm_id in [
		"giza_sphinx", "giza_pyramids_sphinx", "abu_simbel", "abu_simbel_temples",
		"karnak_temple", "luxor_obelisk", "karnak_luxor_temple", "edfu_horus_temple",
		"philae_isis_temple", "petra_treasury", "wadi_rum_arches", "sossusvlei_dunes",
		"sahara_erg_chebbi", "atacama_valle_luna", "uluru_ayers_rock"
	] or combined.find("desert") >= 0 or combined.find("dune") >= 0 or combined.find("sahara") >= 0 or combined.find("wadi") >= 0 or combined.find("giza") >= 0 or c_id == "egypt":
		grounding_type = "DESERT"
		water_rel = "riverbank" if (combined.find("nile") >= 0 or combined.find("luxor") >= 0 or combined.find("karnak") >= 0 or combined.find("aswan") >= 0 or combined.find("abu simbel") >= 0) else "none"
		terrain_zone = "LAND"
	elif lm_id in [
		"tokyo_tower", "cn_tower_toronto", "taipei_101_jiufen", "petronas_twin_towers",
		"burj_khalifa_downtown", "kuwait_towers", "baku_flame_towers",
		"saigon_bitexco_skyline", "saigon_skyline", "manhattan_skyline",
		"cloud_gate_skyline", "las_vegas_strip", "brandenburg_gate",
		"plaza_mayor_palace", "grand_place_atomium", "st_stephens_schoenbrunn",
		"st_basils_red_square", "sagrada_familia", "milan_duomo", "florence_duomo",
		"teatro_colon_obelisco"
	] or combined.find("city") >= 0 or combined.find("tower") >= 0 or combined.find("skyline") >= 0 or combined.find("plaza") >= 0 or combined.find("square") >= 0 or combined.find("metropolitan") >= 0:
		grounding_type = "URBAN"
		water_rel = "none"
		terrain_zone = "URBAN_GROUND"
	elif combined.find("valley") >= 0 or combined.find("loire") >= 0 or combined.find("terrace") >= 0 or combined.find("countryside") >= 0:
		grounding_type = "VALLEY"
		water_rel = "riverbank" if combined.find("loire") >= 0 else "none"
		terrain_zone = "LAND"
	elif combined.find("temple") >= 0 or combined.find("palace") >= 0 or combined.find("castle") >= 0 or combined.find("citadel") >= 0 or combined.find("abbey") >= 0 or combined.find("ruins") >= 0 or combined.find("colosseum") >= 0 or combined.find("pagoda") >= 0 or combined.find("mosque") >= 0 or combined.find("cathedral") >= 0:
		grounding_type = "HISTORIC_SITE"
		water_rel = "none"
		terrain_zone = "LAND"

	return {
		"grounding_type": grounding_type,
		"water_relationship": water_rel,
		"supporting_terrain_zone": terrain_zone
	}


## Builds an ordered destination array from compact [name, region, landmark_id, landmark_desc, lat, lon] tuples
static func _make_country_entry(
	c_id: String,
	c_en: String,
	c_vi: String,
	j_dir: String,
	auth_src: String,
	poi_name: String,
	poi_region: String,
	poi_lat: float,
	poi_lon: float,
	raw_stops: Array
) -> Dictionary:
	var prof: Dictionary = _get_country_landmark_density_profile(c_id)
	var lm_density: String = String(prof.get("density", "moderate"))
	var feat_list: Array = prof.get("featured", [])
	var env_list: Array = prof.get("env", [])
	var dests: Array[Dictionary] = []
	var non_feat_seq: int = 0
	for i in range(raw_stops.size()):
		var st: Array = raw_stops[i]
		var d_name: String = String(st[0])
		var region_str: String = String(st[1])
		var lm_id_str: String = String(st[2])
		var lm_desc_str: String = String(st[3])
		var is_feat: bool = feat_list.has(d_name)
		var is_env: bool = env_list.has(d_name)
		var ms_context: String = "regional_scene"
		if is_feat:
			ms_context = "landmark_environment" if is_env else "major_landmark"
		else:
			ms_context = "regional_scene" if (non_feat_seq % 2 == 0) else "small_destination_marker"
			non_feat_seq += 1
		var g_spec: Dictionary = derive_destination_grounding_spec(c_id, d_name, region_str, lm_id_str, lm_desc_str)
		dests.append({
			"destination_order": i + 1,
			"destination_name": d_name,
			"region": region_str,
			"landmark_id": lm_id_str,
			"landmark": lm_desc_str,
			"lat": float(st[4]),
			"lon": float(st[5]),
			"country_id": c_id,
			"country_name_en": c_en,
			"journey_direction": j_dir,
			"landmark_density": lm_density,
			"milestone_context": ms_context,
			"has_major_landmark": is_feat,
			"grounding_type": String(g_spec.get("grounding_type", "GROUND")),
			"water_relationship": String(g_spec.get("water_relationship", "none")),
			"supporting_terrain_zone": String(g_spec.get("supporting_terrain_zone", "LAND"))
		})
	return {
		"country_id": c_id,
		"country_name_en": c_en,
		"country_name_vi": c_vi,
		"journey_direction": j_dir,
		"authority_source": auth_src,
		"landmark_density": lm_density,
		"independent_poi": {
			"poi_id": "%s_scenic_poi" % c_id,
			"name_en": poi_name,
			"region": poi_region,
			"lat": poi_lat,
			"lon": poi_lon,
			"landmark_classification": "POINT_OF_INTEREST",
			"connected_to_route": false,
			"has_separate_spur_road": false
		},
		"canonical_gameplay_background": _build_canonical_country_background_entry(c_id, c_en, c_vi, j_dir, lm_density, dests),
		"destinations": dests
	}


static var _country_bg_registry_cache: Dictionary = {}


static func _build_canonical_country_background_entry(
	c_id: String,
	c_en: String,
	c_vi: String,
	j_dir: String,
	lm_density: String,
	dests: Array[Dictionary]
) -> Dictionary:
	# Reuse the FULL existing MapPage country artwork (all country_destinations and landmarks)
	# Architecture: Level -> Country -> Full Country MapPage Artwork
	var primary_stop: Dictionary = dests[0] if not dests.is_empty() else {}
	var secondary_stop: Dictionary = dests[1] if dests.size() > 1 else primary_stop
	for d in dests:
		if bool(d.get("has_major_landmark", false)):
			primary_stop = d
			break
	for d in dests:
		if d != primary_stop and bool(d.get("has_major_landmark", false)):
			secondary_stop = d
			break

	var composition_landmarks: Array[Dictionary] = []
	var landmark_ids: Array[String] = []
	var major_landmark_ids: Array[String] = []
	var scenery_cue_ids: Array[String] = []
	var region_names: Array[String] = []

	for idx in range(dests.size()):
		var d: Dictionary = dests[idx]
		var lid: String = String(d.get("landmark_id", ""))
		var m_ctx: String = String(d.get("milestone_context", "regional_scene"))
		var is_major: bool = (m_ctx == "major_landmark" or m_ctx == "landmark_environment")
		var reg_str: String = String(d.get("region", ""))
		if reg_str != "" and not region_names.has(reg_str):
			region_names.append(reg_str)
		if lid != "":
			landmark_ids.append(lid)
			if is_major:
				major_landmark_ids.append(lid)
			else:
				scenery_cue_ids.append(lid)
		var sc_weight: float = 1.00 if m_ctx == "major_landmark" else (0.90 if m_ctx == "landmark_environment" else (0.78 if m_ctx == "regional_scene" else 0.68))
		composition_landmarks.append({
			"landmark_id": lid,
			"landmark_name": String(d.get("landmark", c_en)),
			"destination_name": String(d.get("destination_name", c_en)),
			"region": reg_str,
			"country_id": c_id,
			"milestone_context": m_ctx,
			"environment_type": String(d.get("environment_type", "regional_landscape")),
			"visual_tier": "major_landmark" if is_major else ("architectural_cue" if (idx % 2 == 0) else "regional_scenery"),
			"hierarchy_rank": idx + 1,
			"scale_weight": sc_weight,
			"grounding_type": String(d.get("grounding_type", "GROUND")),
			"water_relationship": String(d.get("water_relationship", "none")),
			"supporting_terrain_zone": String(d.get("supporting_terrain_zone", "LAND"))
		})

	var prim_lm_id: String = String(primary_stop.get("landmark_id", "%s_heritage" % c_id))
	var prim_lm_desc: String = String(primary_stop.get("landmark", c_en))
	var sec_lm_id: String = String(secondary_stop.get("landmark_id", ""))
	var sec_lm_desc: String = String(secondary_stop.get("landmark", ""))
	var tert_lm_id: String = major_landmark_ids[2] if major_landmark_ids.size() >= 3 else (scenery_cue_ids[0] if not scenery_cue_ids.is_empty() else "")

	return {
		"canonical_background_id": "%s_canonical_country_bg" % c_id,
		"background_id": "%s_canonical_country_bg" % c_id,
		"full_map_page_artwork_id": "%s_map_page_artwork" % c_id,
		"reuses_country_map_artwork": true,
		"reuses_full_map_page_artwork": true,
		"render_mode": "GAMEPLAY_BACKGROUND",
		"country_id": c_id,
		"country_name_en": c_en,
		"country_name_vi": c_vi,
		"journey_direction": j_dir,
		"landmark_density": lm_density,
		"canonical_landmark_id": prim_lm_id,
		"canonical_landmark_name": prim_lm_desc,
		"canonical_secondary_landmark_id": sec_lm_id,
		"canonical_secondary_landmark_name": sec_lm_desc,
		"canonical_tertiary_landmark_id": tert_lm_id,
		"composition_landmarks": composition_landmarks,
		"landmark_ids": landmark_ids,
		"major_landmark_ids": major_landmark_ids,
		"scenery_cue_ids": scenery_cue_ids,
		"represented_regions": region_names,
		"map_page_destination_count": dests.size(),
		"landmark_count": composition_landmarks.size(),
		"major_landmark_count": major_landmark_ids.size(),
		"scenery_cue_count": scenery_cue_ids.size(),
		"has_multiple_landmarks": composition_landmarks.size() >= 2,
		"has_visual_hierarchy": major_landmark_ids.size() >= 1 and scenery_cue_ids.size() >= 1,
		"is_single_landmark_only": false,
		"is_continuous_country_scene": true,
		"is_destination_collage": false,
		"grounding_type": String(primary_stop.get("grounding_type", "GROUND")),
		"water_relationship": String(primary_stop.get("water_relationship", "none")),
		"supporting_terrain_zone": String(primary_stop.get("supporting_terrain_zone", "LAND")),
		"secondary_grounding_type": String(secondary_stop.get("grounding_type", "GROUND")),
		"secondary_supporting_terrain_zone": String(secondary_stop.get("supporting_terrain_zone", "LAND")),
		"resolution_architecture": "level_to_country_to_canonical_background",
		"uses_destination_selection": false
	}


static func get_country_background_registry() -> Dictionary:
	if not _country_bg_registry_cache.is_empty():
		return _country_bg_registry_cache
	var all_countries: Array[Dictionary] = _get_all_68_country_manifests()
	var reg: Dictionary = {}
	for page_idx in range(all_countries.size()):
		var c_spec: Dictionary = all_countries[page_idx]
		var c_id: String = String(c_spec.get("country_id", ""))
		if c_id == "":
			continue
		var slot_idx: int = page_idx % THEME_ROTATION.size()
		var tier_cycle: int = int(page_idx / THEME_ROTATION.size())
		var theme_id: String = THEME_ROTATION[slot_idx]
		var world_variants: Array = SLOT_WORLD_CYCLES[slot_idx]
		var world_id: String = String(world_variants[tier_cycle % world_variants.size()])
		var theme_obj: MapTheme = MapTheme.create_world_for_page(theme_id, world_id)
		var bg_entry: Dictionary = c_spec.get("canonical_gameplay_background", {}).duplicate(true)
		bg_entry["page_index"] = page_idx
		bg_entry["page_number"] = page_idx + 1
		bg_entry["theme_id"] = theme_id
		bg_entry["world_id"] = world_id
		bg_entry["world_type"] = theme_obj.world_type
		bg_entry["gameplay_background_theme"] = "%s_canonical_country_bg" % c_id
		reg[c_id] = bg_entry
	_country_bg_registry_cache = reg
	return _country_bg_registry_cache


static func get_canonical_country_background(country_id: String) -> Dictionary:
	var reg: Dictionary = get_country_background_registry()
	if reg.has(country_id):
		return reg[country_id].duplicate(true)
	return reg.get("vietnam", {}).duplicate(true)


static func select_ordered_destinations_for_count(all_dests: Array, count: int) -> Array[Dictionary]:
	return MapLayoutGenerator.select_ordered_destinations_for_count(all_dests, count)


static func get_country_manifest_for_page(page_idx: int) -> Dictionary:
	var all_countries: Array[Dictionary] = _get_all_68_country_manifests()
	var safe_idx: int = posmod(page_idx, all_countries.size())
	return all_countries[safe_idx]


static func _get_country_manifests_part_a() -> Array[Dictionary]:
	return [
		# Page 1 (idx 0, 6 levels): VIETNAM — Real North-to-South Journey (Vietnam National Authority of Tourism)
		_make_country_entry("vietnam", "Vietnam", "Việt Nam", "north_to_south",
			"Vietnam National Authority of Tourism (vietnam.travel) — North-Central-South Heritage Itinerary",
			"Gulf of Tonkin Karsts", "Northern Vietnam", 20.85, 107.35, [
				["Hanoi", "Northern Vietnam", "hanoi_hoan_kiem_pagoda", "Hoan Kiem Lake, Ngoc Son Temple & Old Quarter", 21.0285, 105.8542],
				["Ha Long Bay", "Northern Vietnam", "halong_karst_harbor", "Emerald Bay Limestone Karsts & Vietnamese Boats", 20.9101, 107.1839],
				["Ninh Binh", "Northern Vietnam", "ninh_binh_trang_an_karst", "Trang An & Tam Coc Limestone Karst River", 20.2506, 105.9745],
				["Hue", "Central Vietnam", "hue_imperial_citadel", "Imperial City Citadel & Perfume River", 16.4637, 107.5909],
				["Da Nang / Hoi An", "Central Vietnam", "hoian_covered_bridge_lanterns", "Hoi An Ancient Town Lanterns, Japanese Covered Bridge & Dragon Bridge", 15.8801, 108.3380],
				["Ho Chi Minh City", "Southern Vietnam", "saigon_bitexco_skyline", "Bitexco Financial Tower & Saigon Urban Skyline", 10.7769, 106.7009],
				["Mekong Delta", "Southern Vietnam", "mekong_floating_market", "Cai Rang Floating Market Boats & Delta Waterways", 10.0333, 105.7833]
			]),
		# Page 2 (idx 1, 7 levels): UNITED STATES — East-to-West Transcontinental Route
		_make_country_entry("united_states", "United States", "Hoa Kỳ", "east_to_west",
			"VisitTheUSA (visittheusa.com) — Coast-to-Coast Transcontinental Route",
			"Monument Valley", "Southwest USA", 36.9980, -110.0985, [
				["New York City", "Northeast", "statue_of_liberty", "Statue of Liberty & Manhattan Harbor", 40.7128, -74.0060],
				["Philadelphia", "Mid-Atlantic", "pisa_tower", "Independence Hall Bell Tower", 39.9526, -75.1652],
				["Washington, D.C.", "Mid-Atlantic", "luxor_obelisk", "Capitol Dome & National Mall Monument", 38.8899, -77.0091],
				["Chicago", "Midwest", "manhattan_skyline", "Willis Tower & Lake Michigan Skyline", 41.8781, -87.6298],
				["Grand Canyon", "Southwest", "grand_canyon_rim", "Grand Canyon Red-Rock Buttes & Colorado Gorge", 36.1069, -112.1129],
				["Las Vegas", "Mojave West", "las_vegas_strip", "Las Vegas Strip Resort Skyline", 36.1699, -115.1398],
				["San Francisco", "Pacific Coast", "golden_gate", "Golden Gate Suspension Bridge", 37.8199, -122.4783]
			]),
		# Page 3 (idx 2, 8 levels): FRANCE — South-to-North Mediterranean to Paris Journey
		_make_country_entry("france", "France", "Pháp", "south_to_north",
			"Atout France (france.fr) — Riviera to Paris South-to-North Itinerary",
			"French Alps (Mont Blanc)", "Auvergne-Rhône-Alpes", 45.8326, 6.8652, [
				["Nice", "French Riviera", "tuscany_villa", "Promenade des Anglais & Riviera Villa", 43.7102, 7.2620],
				["Avignon", "Provence", "loire_chateau", "Palais des Papes & Lavender Fields", 43.9493, 4.8055],
				["Lyon", "Rhône Valley", "florence_duomo", "Fourvière Basilica & Rhône Bridges", 45.7640, 4.8357],
				["Annecy", "French Alps", "alpine_chalet", "Alpine Canal Chateau & Mountain Lake", 45.8992, 6.1294],
				["Dijon", "Burgundy", "versailles_palace", "Palace of the Dukes of Burgundy", 47.3220, 5.0415],
				["Chambord", "Loire Valley", "loire_chateau", "Château de Chambord Renaissance Turrets", 47.6161, 1.5172],
				["Mont-Saint-Michel", "Normandy", "mont_saint_michel", "Tidal Island Gothic Abbey Spire", 48.6361, -1.5115],
				["Versailles", "Île-de-France", "versailles_palace", "Palace of Versailles & Royal Gardens", 48.8049, 2.1204],
				["Paris", "Île-de-France", "eiffel_tower", "Eiffel Tower & Seine River Bridges", 48.8584, 2.2945]
			]),
		# Page 4 (idx 3, 9 levels): JAPAN — West-to-East Honshu Golden Corridor
		_make_country_entry("japan", "Japan", "Nhật Bản", "west_to_east",
			"Japan National Tourism Organization (japan.travel) — West-to-East Heritage Corridor",
			"Mount Fuji & Lake Kawaguchi", "Chubu Region", 35.3606, 138.7274, [
				["Miyajima (Hiroshima)", "Chugoku", "torii_shrine", "Itsukushima Floating Vermilion Torii Gate", 34.2960, 132.3198],
				["Himeji", "Kansai", "osaka_castle", "Himeji White Heron Castle Keep", 34.8394, 134.6939],
				["Kobe", "Kansai", "lighthouse_landmark", "Kobe Port Tower & Harbor", 34.6901, 135.1955],
				["Osaka", "Kansai", "osaka_castle", "Osaka Castle Tenshu & Stone Moat", 34.6873, 135.5262],
				["Kyoto", "Kansai", "kyoto_temple", "Kiyomizu-dera Temple & Sakura Hall", 35.0116, 135.7681],
				["Nara", "Kansai", "kyoto_temple", "Todai-ji Great Buddha Wooden Hall", 34.6851, 135.8048],
				["Nagoya", "Chubu", "osaka_castle", "Nagoya Golden Shachihoko Keep", 35.1815, 136.9066],
				["Fujiyoshida", "Chubu", "chureito_pagoda", "Chureito Five-Story Crimson Pagoda", 35.5011, 138.8016],
				["Tokyo", "Kanto", "tokyo_tower", "Tokyo Tower & Metropolis Skyline", 35.6586, 139.7454]
			]),
		# Page 5 (idx 4, 5 levels): EGYPT — North-to-South Nile Valley Journey
		_make_country_entry("egypt", "Egypt", "Ai Cập", "north_to_south",
			"Egyptian Tourism Authority (experienceegypt.eg) — Nile Valley North-to-South Itinerary",
			"Giza Plateau", "Lower Egypt", 29.9792, 31.1342, [
				["Alexandria", "Mediterranean Coast", "lighthouse_landmark", "Citadel of Qaitbay & Pharos Harbor", 31.2001, 29.9187],
				["Cairo & Giza", "Lower Egypt", "giza_sphinx", "Great Pyramids of Giza & Guardian Sphinx", 29.9792, 31.1342],
				["Karnak", "Upper Egypt", "karnak_temple", "Karnak Temple Pylon & Hypostyle Columns", 25.7188, 32.6573],
				["Luxor", "Upper Egypt", "luxor_obelisk", "Luxor Temple Obelisk & Nile Feluccas", 25.6995, 32.6391],
				["Abu Simbel", "Nubia", "abu_simbel", "Great Rock Temple of Ramesses II", 22.3372, 31.6258]
			]),
		# Page 6 (idx 5, 8 levels): SWITZERLAND — West-to-East Alpine Grand Tour
		_make_country_entry("switzerland", "Switzerland", "Thụy Sĩ", "west_to_east",
			"Switzerland Tourism (myswitzerland.com) — West-to-East Grand Train Tour",
			"Matterhorn Peak", "Valais Alps", 45.9766, 7.6585, [
				["Geneva", "Romandy", "alpine_chalet", "Lake Geneva Jet d'Eau & Old Town", 46.2044, 6.1432],
				["Lausanne", "Vaud", "loire_chateau", "Lavaux Terraced Vineyards & Cathedral", 46.5197, 6.6323],
				["Montreux", "Vaud", "loire_chateau", "Château de Chillon Lakeside Castle", 46.4140, 6.9275],
				["Zermatt", "Valais", "zermatt_sanctuary", "Zermatt Timber Chalets & Matterhorn Base", 46.0207, 7.7491],
				["Interlaken", "Bernese Oberland", "alpine_village", "Jungfrau Alpine Valley & Chalet Square", 46.6863, 7.8632],
				["Lucerne", "Central Switzerland", "glacier_bridge", "Chapel Bridge & Octagonal Water Tower", 47.0502, 8.3093],
				["Zurich", "Northern Switzerland", "alpine_village", "Grossmünster Twin Spires & Limmat River", 47.3769, 8.5417],
				["St. Moritz", "Engadin", "zermatt_sanctuary", "Engadin Glacier Sanctuary & Viaduct", 46.4908, 9.8355]
			]),
		# Page 7 (idx 6, 7 levels): SOUTH KOREA — North-to-South Peninsula & Jeju Journey
		_make_country_entry("south_korea", "South Korea", "Hàn Quốc", "north_to_south",
			"Korea Tourism Organization (visitkorea.or.kr) — Seoul to Busan & Jeju Route",
			"Bukhan Mountain Peaks", "Gyeonggi", 37.6584, 126.9770, [
				["Seoul", "Capital Region", "kyoto_temple", "Gyeongbokgung Palace & Gwanghwamun Gate", 37.5796, 126.9770],
				["Suwon", "Gyeonggi", "osaka_castle", "Hwaseong Fortress Stone Ramparts", 37.2804, 127.0152],
				["Andong", "Gyeongbuk", "kyoto_temple", "Hahoe Traditional Tile-Roof Village", 36.5392, 128.5180],
				["Jeonju", "Jeonbuk", "kyoto_temple", "Jeonju Hanok Heritage Quarter", 35.8147, 127.1526],
				["Gyeongju", "Gyeongbuk", "chureito_pagoda", "Bulguksa Temple & Seokgatap Pagoda", 35.7901, 129.3320],
				["Busan", "Yeongnam Coast", "golden_gate", "Gwangan Suspension Bridge & Haeundae Bay", 35.1796, 129.0756],
				["Jeju Island", "Jeju Strait", "torii_shrine", "Seongsan Ilchulbong Volcanic Tuff Cone", 33.3617, 126.5292]
			]),
		# Page 8 (idx 7, 10 levels): ITALY — North-to-South Grand Peninsula Tour
		_make_country_entry("italy", "Italy", "Ý", "north_to_south",
			"ENIT Italian National Tourist Board (italia.it) — North-to-South Grand Tour",
			"Apennine Mountains", "Central Italy", 43.1000, 13.2000, [
				["Milan", "Lombardy", "florence_duomo", "Milan Cathedral Marble Spires", 45.4642, 9.1900],
				["Venice", "Veneto", "venice_canal", "Grand Canal Palazzos, Rialto & Gondola", 45.4408, 12.3155],
				["Verona", "Veneto", "rome_colosseum", "Verona Roman Arena & Adige Bridge", 45.4384, 10.9916],
				["Bologna", "Emilia-Romagna", "pisa_tower", "Asinelli Medieval Brick Towers", 44.4949, 11.3426],
				["Florence", "Tuscany", "florence_duomo", "Brunelleschi Terracotta Duomo", 43.7731, 11.2560],
				["Pisa", "Tuscany", "pisa_tower", "Leaning Tower of Pisa & Piazza dei Miracoli", 43.7230, 10.3966],
				["Siena (Tuscany)", "Tuscany", "tuscany_villa", "Tuscan Hilltop Villa & Cypress Groves", 43.3188, 11.3308],
				["Rome", "Lazio", "rome_colosseum", "Roman Colosseum & Imperial Forum", 41.8902, 12.4922],
				["Naples & Pompeii", "Campania", "karnak_temple", "Pompeii Stone Forum & Mount Vesuvius", 40.7462, 14.4989],
				["Amalfi Coast", "Campania", "tuscany_villa", "Cliffside Amalfi Terraces & Sea", 40.6340, 14.6027]
			]),
		# Page 9 (idx 8, 6 levels): GREECE — South-to-North Aegean to Macedonia Route
		_make_country_entry("greece", "Greece", "Hy Lạp", "south_to_north",
			"Greek National Tourism Organisation (visitgreece.gr) — Islands to Mainland Route",
			"Mount Olympus", "Thessaly", 40.0859, 22.3586, [
				["Heraklion (Crete)", "Crete", "karnak_temple", "Palace of Knossos Minoan Colonnade", 35.2980, 25.1630],
				["Santorini (Oia)", "Cyclades", "florence_duomo", "Oia Blue-Domed Caldera Churches", 36.4618, 25.3753],
				["Athens", "Attica", "karnak_temple", "Parthenon Temple on the Acropolis", 37.9715, 23.7257],
				["Delphi", "Central Greece", "karnak_temple", "Temple of Apollo & Parnassus Sanctuary", 38.4824, 22.5010],
				["Meteora", "Thessaly", "mont_saint_michel", "Clifftop Monasteries on Rock Pillars", 39.7217, 21.6306],
				["Thessaloniki", "Macedonia", "pisa_tower", "White Tower of Thessaloniki", 40.6264, 22.9484]
			]),
		# Page 10 (idx 9, 8 levels): CHILE — North-to-South Atacama Observatory to Patagonia
		_make_country_entry("chile", "Chile", "Chile", "north_to_south",
			"Sernatur (chile.travel) — Atacama Astronomical Plateau to Patagonia",
			"Andes Cordillera", "Central Andes", -32.6532, -70.0109, [
				["San Pedro de Atacama", "Antofagasta", "astral_observatory", "ALMA Deep-Space Radio Observatory", -22.9087, -68.1997],
				["Paranal Observatory", "Atacama Desert", "astral_observatory", "Very Large Telescope Astronomical Domes", -24.6272, -70.4042],
				["La Serena", "Elqui Valley", "lighthouse_landmark", "Faro Monumental & Dark-Sky Sanctuary", -29.9027, -71.2519],
				["Valparaíso", "Pacific Coast", "venice_canal", "Colorful Hillside Funiculars & Port", -33.0472, -71.6127],
				["Santiago", "Metropolitan Region", "manhattan_skyline", "Andean Skyline & Santa Lucía Hill", -33.4489, -70.6693],
				["Pucón", "Araucanía", "grand_canyon_rim", "Villarrica Volcanic Peak & Lake", -39.2822, -71.9543],
				["Puerto Varas", "Los Lagos", "alpine_chalet", "Osorno Volcano & Llanquihue Chalets", -41.3195, -72.9854],
				["Torres del Paine", "Patagonia", "zermatt_sanctuary", "Granite Towers of Patagonia", -50.9423, -73.4068]
			]),
		# Page 11 (idx 10, 6 levels): THAILAND — North-to-South Lanna to Andaman Coast
		_make_country_entry("thailand", "Thailand", "Thái Lan", "north_to_south",
			"Tourism Authority of Thailand (tourismthailand.org) — North-to-South Kingdom Route",
			"Phang Nga Limestone Bay", "Southern Thailand", 8.2740, 98.5012, [
				["Chiang Rai", "Northern Lanna", "kyoto_temple", "Wat Rong Khun Gilded Temple", 19.9071, 99.8309],
				["Chiang Mai", "Northern Highlands", "chureito_pagoda", "Doi Suthep Golden Chedi Sanctuary", 18.7883, 98.9853],
				["Sukhothai", "Lower North", "karnak_temple", "Wat Mahathat Lotus Bud Stupa Ruins", 17.0156, 99.7028],
				["Ayutthaya", "Central Plains", "chureito_pagoda", "Chaiwatthanaram Riverside Prang Towers", 14.3532, 100.5689],
				["Bangkok", "Chao Phraya Delta", "hue_imperial_citadel", "Grand Palace & Wat Arun Spire", 13.7563, 100.5018],
				["Phuket & Krabi", "Andaman Coast", "halong_karst_harbor", "Andaman Limestone Karsts & Longtail Boats", 7.8804, 98.3923]
			]),
		# Page 12 (idx 11, 7 levels): CANADA — East-to-West St. Lawrence to Pacific Coast
		_make_country_entry("canada", "Canada", "Canada", "east_to_west",
			"Destination Canada (destinationcanada.com) — Trans-Canada East-to-West Journey",
			"Canadian Rockies", "Alberta", 52.1469, -117.2273, [
				["Quebec City", "Quebec", "loire_chateau", "Château Frontenac & Old Ramparts", 46.8139, -71.2080],
				["Montreal", "Quebec", "florence_duomo", "Mount Royal & Notre-Dame Basilica", 45.5017, -73.5673],
				["Ottawa", "Ontario", "versailles_palace", "Parliament Hill Peace Tower & Rideau Canal", 45.4215, -75.6972],
				["Niagara Falls", "Ontario", "glacier_bridge", "Horseshoe Falls & Rainbow Bridge", 43.0896, -79.0849],
				["Toronto", "Ontario", "tokyo_tower", "CN Tower & Lake Ontario Harbourfront", 43.6532, -79.3832],
				["Banff & Lake Louise", "Alberta Rockies", "zermatt_sanctuary", "Turquoise Glacial Lake & Alpine Peaks", 51.1784, -115.5708],
				["Vancouver", "British Columbia", "golden_gate", "Lions Gate Bridge & Stanley Park Coast", 49.2827, -123.1207]
			]),
		# Page 13 (idx 12, 8 levels): UNITED KINGDOM — North-to-South Scotland to London
		_make_country_entry("united_kingdom", "United Kingdom", "Vương Quốc Anh", "north_to_south",
			"VisitBritain (visitbritain.com) — Edinburgh to London North-to-South Route",
			"Lake District", "Cumbria", 54.4609, -3.0886, [
				["Edinburgh", "Scotland", "mont_saint_michel", "Edinburgh Castle on Castle Rock", 55.9533, -3.1883],
				["Durham", "North East England", "florence_duomo", "Durham Norman Cathedral & Wear River", 54.7753, -1.5849],
				["York", "Yorkshire", "loire_chateau", "York Minster Gothic Towers & Shambles", 53.9599, -1.0873],
				["Stratford-upon-Avon", "West Midlands", "alpine_chalet", "Tudor Half-Timbered Riverfront", 52.1917, -1.7083],
				["Cotswolds (Bibury)", "Gloucestershire", "tuscany_villa", "Honey-Stone Cottages & Coln Stream", 51.7587, -1.8322],
				["Oxford", "Oxfordshire", "florence_duomo", "Radcliffe Camera Rotunda & Dreaming Spires", 51.7520, -1.2577],
				["London", "Greater London", "pisa_tower", "Elizabeth Tower (Big Ben) & Thames Bridge", 51.5007, -0.1246],
				["Stonehenge (Salisbury)", "Wiltshire", "karnak_temple", "Prehistoric Stonehenge Trilithon Circle", 51.1789, -1.8262]
			]),
		# Page 14 (idx 13, 9 levels): CHINA — South-to-North Karst Rivers to Great Wall
		_make_country_entry("china", "China", "Trung Quốc", "south_to_north",
			"China National Tourist Office — South-to-North Imperial & Landscape Route",
			"Yellow Mountains (Huangshan)", "Anhui", 30.1333, 118.1667, [
				["Hong Kong", "Pearl River Delta", "manhattan_skyline", "Victoria Harbour Skyline & Star Ferry", 22.3193, 114.1694],
				["Guilin & Yangshuo", "Guangxi", "ninh_binh_trang_an_karst", "Li River Limestone Karst Peaks & Rafts", 25.2736, 110.2900],
				["Hangzhou", "Zhejiang", "hanoi_hoan_kiem_pagoda", "West Lake Leifeng Pagoda & Arch Bridge", 30.2741, 120.1551],
				["Shanghai", "Yangtze Delta", "tokyo_tower", "The Bund & Oriental Pearl Tower", 31.2304, 121.4737],
				["Suzhou", "Jiangsu", "hoian_covered_bridge_lanterns", "Classical Scholar Gardens & Canal Bridges", 31.2989, 120.5853],
				["Nanjing", "Jiangsu", "hue_imperial_citadel", "Ming City Wall & Qinhuai Pavilion", 32.0603, 118.7969],
				["Xi'an", "Shaanxi", "chureito_pagoda", "Giant Wild Goose Pagoda & City Wall", 34.3416, 108.9398],
				["Pingyao", "Shanxi", "hue_imperial_citadel", "Ancient Walled City Watchtowers", 37.2022, 112.1764],
				["Beijing", "Northern Capital", "hue_imperial_citadel", "Forbidden City Hall & Great Wall Ridge", 39.9042, 116.4074]
			]),
		# Page 15 (idx 14, 5 levels): MOROCCO — North-to-South Tangier to Marrakesh & Sahara
		_make_country_entry("morocco", "Morocco", "Ma-rốc", "north_to_south",
			"Moroccan National Tourist Office (visitmorocco.com) — North-to-South Imperial Cities",
			"High Atlas Mountains", "Central Morocco", 31.0597, -7.9158, [
				["Tangier", "Strait of Gibraltar", "lighthouse_landmark", "Cap Spartel Lighthouse & Kasbah", 35.7595, -5.8340],
				["Chefchaouen", "Rif Mountains", "venice_canal", "Blue Pearl Medina Terraces", 35.1688, -5.2636],
				["Fes", "Saïss Plain", "hue_imperial_citadel", "Bab Bou Jeloud Blue Gate & Medina", 34.0181, -5.0078],
				["Marrakesh", "Haouz Plain", "pisa_tower", "Koutoubia Minaret & Jemaa el-Fnaa", 31.6295, -7.9811],
				["Merzouga (Erg Chebbi)", "Sahara Desert", "giza_sphinx", "Golden Sahara Sand Dunes & Oasis Kasbah", 31.0801, -4.0134]
			]),
		# Page 16 (idx 15, 8 levels): NORWAY — South-to-North Fjords to Arctic North Cape
		_make_country_entry("norway", "Norway", "Na Uy", "south_to_north",
			"Visit Norway (visitnorway.com) — Coastal & Fjord South-to-North Voyage",
			"Jostedalsbreen Glacier", "Vestland", 61.6761, 6.9858, [
				["Stavanger (Preikestolen)", "Rogaland", "grand_canyon_rim", "Pulpit Rock Cliff above Lysefjord", 58.9700, 5.7331],
				["Oslo", "Oslofjord", "versailles_palace", "Oslo Opera House & Akershus Fortress", 59.9139, 10.7522],
				["Bergen", "Vestland", "venice_canal", "Bryggen Colorful Wooden Hanseatic Wharf", 60.3913, 5.3221],
				["Flåm (Aurlandsfjord)", "Sognefjord", "alpine_chalet", "Stegastein Fjord Viewpoint & Railway", 60.8638, 7.1142],
				["Geirangerfjord", "Møre og Romsdal", "zermatt_sanctuary", "Seven Sisters Waterfall & Fjord Cliffs", 62.1008, 7.2059],
				["Trondheim", "Trøndelag", "florence_duomo", "Nidaros Cathedral & Nidelva River", 63.4305, 10.3951],
				["Lofoten Islands", "Nordland", "alpine_village", "Reine Red Rorbu Cabins & Granite Peaks", 67.9325, 13.0886],
				["Tromsø & North Cape", "Troms og Finnmark", "zermatt_sanctuary", "Arctic Cathedral & Midnight Sun Cliff", 69.6492, 18.9553]
			]),
		# Page 17 (idx 16, 7 levels): INDONESIA — West-to-East Java, Bali & Nusa Tenggara
		_make_country_entry("indonesia", "Indonesia", "Indonesia", "west_to_east",
			"Wonderful Indonesia (indonesia.travel) — Java to Bali & Komodo West-to-East",
			"Indian Ocean Volcanic Arc", "Archipelago", -8.4095, 115.1889, [
				["Jakarta", "West Java Coast", "luxor_obelisk", "Monas National Monument & Old Batavia", -6.1754, 106.8272],
				["Bandung", "Parahyangan Highlands", "tuscany_villa", "Tangkuban Perahu Crater & Tea Hills", -6.9175, 107.6191],
				["Borobudur (Magelang)", "Central Java", "giza_sphinx", "Borobudur Stepped Mandala Stupa", -7.6079, 110.2038],
				["Yogyakarta (Prambanan)", "Central Java", "chureito_pagoda", "Prambanan Towering Hindu Spires", -7.7520, 110.4915],
				["Mount Bromo", "East Java", "grand_canyon_rim", "Tengger Caldera Volcanic Cones", -7.9425, 112.9530],
				["Ubud & Tanah Lot (Bali)", "Bali", "torii_shrine", "Pura Tanah Lot Sea Temple & Rice Terraces", -8.6212, 115.0868],
				["Labuan Bajo (Komodo)", "East Nusa Tenggara", "halong_karst_harbor", "Padar Island Three-Bay Ridge & Phinisi Boats", -8.4964, 119.8877]
			]),
		# Page 18 (idx 17, 10 levels): SPAIN — North-to-South Cantabrian Coast to Andalusia
		_make_country_entry("spain", "Spain", "Tây Ban Nha", "north_to_south",
			"Turespaña (spain.info) — North-to-South Iberian Heritage Journey",
			"Sierra Nevada Peaks", "Andalusia", 37.0544, -3.3114, [
				["Bilbao", "Basque Country", "versailles_palace", "Guggenheim Titanium Curves & Nervión River", 43.2630, -2.9350],
				["Santiago de Compostela", "Galicia", "florence_duomo", "Baroque Twin-Spired Cathedral Plaza", 42.8805, -8.5456],
				["Barcelona", "Catalonia", "mont_saint_michel", "Sagrada Família Soaring Towers", 41.4036, 2.1744],
				["Segovia", "Castile and León", "rome_colosseum", "Roman Aqueduct Arches & Alcázar", 40.9429, -4.1088],
				["Madrid", "Community of Madrid", "versailles_palace", "Royal Palace of Madrid & Retiro Park", 40.4168, -3.7038],
				["Toledo", "Castile-La Mancha", "loire_chateau", "Alcázar Hilltop Citadel & Tagus Bridge", 39.8628, -4.0273],
				["Valencia", "Valencian Coast", "astral_observatory", "City of Arts and Sciences & Serranos Towers", 39.4699, -0.3763],
				["Córdoba", "Andalusia", "karnak_temple", "Mezquita Red-and-White Horseshoe Arches", 37.8789, -4.7794],
				["Seville", "Andalusia", "pisa_tower", "Giralda Bell Tower & Plaza de España", 37.3891, -5.9845],
				["Granada", "Andalusia", "hue_imperial_citadel", "Alhambra Nasrid Palaces & Generalife", 37.1760, -3.5881]
			]),
		# Page 19 (idx 18, 6 levels): GERMANY — North-to-South Hanseatic Coast to Bavarian Alps
		_make_country_entry("germany", "Germany", "Đức", "north_to_south",
			"German National Tourist Board (germany.travel) — North-to-South Romantic Road",
			"Black Forest (Schwarzwald)", "Baden-Württemberg", 48.3000, 8.1500, [
				["Hamburg", "Northern Port", "venice_canal", "Speicherstadt Red-Brick Canal Warehouses", 53.5438, 9.9916],
				["Berlin", "Brandenburg", "karnak_temple", "Brandenburg Neoclassical Gate & Quadriga", 52.5163, 13.3777],
				["Cologne", "Rhineland", "mont_saint_michel", "Cologne Twin Gothic Cathedral Spires", 50.9413, 6.9583],
				["Heidelberg", "Neckar Valley", "loire_chateau", "Heidelberg Sandstone Castle & Old Bridge", 49.4106, 8.7153],
				["Munich", "Bavaria", "versailles_palace", "Marienplatz New Town Hall & Frauenkirche", 48.1372, 11.5755],
				["Neuschwanstein (Füssen)", "Bavarian Alps", "loire_chateau", "Neuschwanstein Fairytale Alpine Castle", 47.5576, 10.7498]
			]),
		# Page 20 (idx 19, 8 levels): PERU — North-to-South Pacific Coast to Andes & Lake Titicaca
		_make_country_entry("peru", "Peru", "Peru", "north_to_south",
			"PromPerú (peru.travel) — Coast to Inca Andes North-to-South Route",
			"Ausangate Rainbow Mountain", "Cusco Andes", -13.8694, -71.3030, [
				["Trujillo (Chan Chan)", "La Libertad", "giza_sphinx", "Chan Chan Adobe Citadel & Huaca del Sol", -8.1116, -79.0288],
				["Huaraz (Cordillera Blanca)", "Áncash", "zermatt_sanctuary", "Huascarán Glaciers & Laguna 69", -9.5261, -77.5288],
				["Lima", "Lima Coast", "versailles_palace", "Plaza Mayor Colonial Balconies & Miraflores", -12.0464, -77.0428],
				["Machu Picchu", "Urubamba Valley", "giza_sphinx", "Inca Stone Citadel & Huayna Picchu Peak", -13.1631, -72.5450],
				["Cusco", "Cusco Highlands", "florence_duomo", "Plaza de Armas & Sacsayhuamán Walls", -13.5320, -71.9675],
				["Paracas & Huacachina", "Ica", "giza_sphinx", "Desert Oasis Lagoon & Coastal Cliffs", -14.0875, -75.7626],
				["Puno (Lake Titicaca)", "Altiplano", "mekong_floating_market", "Uros Floating Reed Islands & Totora Boats", -15.8402, -70.0219],
				["Arequipa", "Southern Andes", "florence_duomo", "White Volcanic Silllar Basilica & Misti Peak", -16.4090, -71.5375]
			]),
		# Page 21 (idx 20, 6 levels): PHILIPPINES — North-to-South Luzon to Visayas & Mindanao
		_make_country_entry("philippines", "Philippines", "Philippines", "north_to_south",
			"Department of Tourism Philippines — Luzon to Mindanao Archipelago Route",
			"Mayon Volcano", "Bicol", 13.2548, 123.6861, [
				["Vigan", "Ilocos Sur", "hoian_covered_bridge_lanterns", "Calle Crisologo Spanish Cobblestone Houses", 17.5747, 120.3869],
				["Banaue", "Cordillera", "tuscany_villa", "Banaue Carved Mountain Rice Terraces", 16.9240, 121.0558],
				["Manila (Intramuros)", "National Capital", "hue_imperial_citadel", "Fort Santiago Gate & San Agustin Church", 14.5896, 120.9747],
				["El Nido (Palawan)", "Mimaropa", "halong_karst_harbor", "Bacuit Bay Limestone Lagoons & Bangka Boats", 11.1956, 119.4079],
				["Bohol & Cebu", "Central Visayas", "grand_canyon_rim", "Chocolate Hills & Magellan Cross Pavilion", 9.8500, 124.1435],
				["Davao (Mount Apo)", "Mindanao", "zermatt_sanctuary", "Mount Apo Highland Sanctuary", 7.0707, 125.6087]
			]),
		# Page 22 (idx 21, 7 levels): BRAZIL — North-to-South Amazon to Rio & Iguaçu Falls
		_make_country_entry("brazil", "Brazil", "Brazil", "north_to_south",
			"Embratur (visitbrasil.com) — Amazon to Iguaçu North-to-South Route",
			"Pantanal Wetlands", "Mato Grosso", -17.7128, -57.3800, [
				["Manaus", "Amazonas", "florence_duomo", "Teatro Amazonas Pink Dome & Rainforest River", -3.1190, -60.0217],
				["Salvador (Pelourinho)", "Bahia", "venice_canal", "Pelourinho Pastel Colonial Plaza & Lacerda Lift", -12.9714, -38.5014],
				["Brasília", "Federal District", "astral_observatory", "Niemeyer Crown Cathedral & National Congress", -15.7975, -47.8919],
				["Ouro Preto", "Minas Gerais", "florence_duomo", "Baroque Hilltop Twin-Tower Churches", -20.3856, -43.5035],
				["Rio de Janeiro", "Southeast Coast", "statue_of_liberty", "Christ the Redeemer on Corcovado & Sugarloaf", -22.9519, -43.2105],
				["São Paulo", "Southeast", "manhattan_skyline", "Paulista Avenue Skyline & Octavio Frias Bridge", -23.5505, -46.6333],
				["Foz do Iguaçu", "Paraná", "grand_canyon_rim", "Iguaçu Thundering Basalt Waterfall Gorge", -25.6953, -54.4367]
			]),
		# Page 23 (idx 22, 8 levels): NETHERLANDS — South-to-North Limburg to Amsterdam & Friesland
		_make_country_entry("netherlands", "Netherlands", "Hà Lan", "south_to_north",
			"Netherlands Board of Tourism (holland.com) — South-to-North Canal & Windmill Route",
			"IJsselmeer Polders", "Flevoland", 52.7000, 5.4000, [
				["Maastricht", "Limburg", "glacier_bridge", "Sint Servaasbrug Stone Arch Bridge", 50.8514, 5.6910],
				["Kinderdijk", "South Holland", "tuscany_villa", "18th-Century Canal Windmill Row", 51.8833, 4.6333],
				["Rotterdam", "South Holland", "golden_gate", "Erasmus Swan Suspension Bridge & Cube Houses", 51.9244, 4.4777],
				["Delft", "South Holland", "pisa_tower", "Nieuwe Kerk Spire & Blue Pottery Canal", 52.0116, 4.3571],
				["The Hague", "South Holland", "versailles_palace", "Binnenhof Lakeside Parliament & Peace Palace", 52.0799, 4.3134],
				["Keukenhof (Lisse)", "Bulb Region", "tuscany_villa", "Blooming Tulip Fields & Historic Windmill", 52.2697, 4.5469],
				["Amsterdam", "North Holland", "venice_canal", "Herengracht Gabled Canal Houses & Rijksmuseum", 52.3676, 4.9041],
				["Giethoorn", "Overijssel", "venice_canal", "Waterway Village Footbridges & Thatched Farms", 52.7402, 6.0789]
			]),
		# Page 24 (idx 23, 9 levels): NEPAL — West-to-East Terai to Kathmandu & Everest
		_make_country_entry("nepal", "Nepal", "Nepal", "west_to_east",
			"Nepal Tourism Board (ntb.gov.np) — Himalayan West-to-East Trail",
			"Annapurna Sanctuary", "Gandaki", 28.5300, 83.8780, [
				["Bardiya", "Far-West Terai", "tuscany_villa", "Karnali River Chisapani Bridge", 28.4310, 81.2800],
				["Lumbini", "Rupandehi", "chureito_pagoda", "Maya Devi White Sanctuary & Ashoka Pillar", 27.4833, 83.2767],
				["Pokhara", "Gandaki Valley", "hanoi_hoan_kiem_pagoda", "Phewa Lake Tal Barahi Pagoda & Machapuchare", 28.2096, 83.9856],
				["Chitwan", "Inner Terai", "tuscany_villa", "Rapti River Jungle Pavilion", 27.5291, 84.3542],
				["Gorkha", "Gandaki Hills", "loire_chateau", "Gorkha Durbar Ridge Fortress", 28.0000, 84.6333],
				["Patan (Lalitpur)", "Kathmandu Valley", "kyoto_temple", "Patan Durbar Multi-Tiered Newari Temples", 27.6727, 85.3253],
				["Kathmandu", "Kathmandu Valley", "chureito_pagoda", "Boudhanath Great White Stupa & Eyes", 27.7215, 85.3620],
				["Bhaktapur", "Kathmandu Valley", "chureito_pagoda", "Nyatapola Five-Tiered Brick Pagoda", 27.6710, 85.4298],
				["Namche & Everest", "Khumbu Himalaya", "zermatt_sanctuary", "Mount Everest Snow Pyramid & Sherpa Monastery", 27.9881, 86.9250]
			])
	]


static func _get_country_manifests_part_b() -> Array[Dictionary]:
	return [
		# Page 25 (idx 24, 5 levels): JORDAN — North-to-South King's Highway
		_make_country_entry("jordan", "Jordan", "Jordan", "north_to_south",
			"Jordan Tourism Board (visitjordan.com) — North-to-South King's Highway",
			"Dead Sea Rift", "Jordan Valley", 31.5000, 35.5000, [
				["Jerash", "Northern Highlands", "karnak_temple", "Oval Plaza & Roman Colonnaded Street", 32.2808, 35.8917],
				["Amman", "Balqa Highlands", "rome_colosseum", "Amman Citadel Temple & Roman Theater", 31.9539, 35.9106],
				["Madaba & Mount Nebo", "Central Plateau", "florence_duomo", "Byzantine Mosaic Basilica & Ridge", 31.7197, 35.7942],
				["Petra", "Ma'an Mountains", "abu_simbel", "Al-Khazneh Rose-Red Rock Treasury", 30.3285, 35.4444],
				["Wadi Rum & Aqaba", "Southern Desert", "grand_canyon_rim", "Wadi Rum Sandstone Arches & Red Sea", 29.5734, 35.4194]
			]),
		# Page 26 (idx 25, 8 levels): AUSTRIA — West-to-East Tyrol to Vienna
		_make_country_entry("austria", "Austria", "Áo", "west_to_east",
			"Austrian National Tourist Office (austria.info) — West-to-East Alpine to Danube Route",
			"Grossglockner High Alps", "Hohe Tauern", 47.0742, 12.6947, [
				["Bregenz", "Vorarlberg", "venice_canal", "Lake Constance Floating Stage & Promenade", 47.5031, 9.7471],
				["Innsbruck", "Tyrol", "alpine_chalet", "Golden Roof Alcove & Nordkette Peaks", 47.2692, 11.4041],
				["Zell am See", "Pinzgau", "zermatt_sanctuary", "Schmittenhöhe Alpine Lake & Chalets", 47.3235, 12.7969],
				["Salzburg", "Salzach Valley", "loire_chateau", "Hohensalzburg Clifftop Fortress & Baroque Domes", 47.8095, 13.0550],
				["Hallstatt", "Salzkammergut", "alpine_village", "Lakeside Timber Village & Spire", 47.5622, 13.6493],
				["Melk (Wachau)", "Danube Valley", "versailles_palace", "Melk Golden Baroque Abbey above Danube", 48.2272, 15.3319],
				["Graz", "Styria", "pisa_tower", "Schlossberg Clock Tower & Red Roofs", 47.0707, 15.4395],
				["Vienna", "Danube Basin", "versailles_palace", "Schönbrunn Palace & St. Stephen's Spire", 48.2082, 16.3738]
			]),
		# Page 27 (idx 26, 7 levels): MEXICO — West-to-East Pacific to Yucatán Peninsula
		_make_country_entry("mexico", "Mexico", "Mexico", "west_to_east",
			"Visit México (visitmexico.com) — Pacific Highlands to Maya Yucatán Route",
			"Popocatépetl Volcano", "Central Valley", 19.0224, -98.6279, [
				["Guadalajara", "Jalisco", "florence_duomo", "Twin-Spired Cathedral & Tlaquepaque Arches", 20.6597, -103.3496],
				["Guanajuato", "Bajío Highlands", "venice_canal", "Colorful Hillside Alleys & Basilica", 21.0190, -101.2574],
				["Mexico City & Teotihuacán", "Valley of Mexico", "giza_sphinx", "Pyramid of the Sun & Palacio de Bellas Artes", 19.4326, -99.1332],
				["Puebla", "Puebla Valley", "florence_duomo", "Talavera Tiled Domes & Cholula Pyramid", 19.0414, -98.2063],
				["Oaxaca", "Oaxaca Valley", "karnak_temple", "Monte Albán Zapotec Acropolis", 17.0732, -96.7266],
				["Palenque", "Chiapas", "giza_sphinx", "Temple of the Inscriptions Jungle Step-Pyramid", 17.4848, -92.0459],
				["Chichén Itzá & Tulum", "Yucatán", "giza_sphinx", "El Castillo Kukulcán Pyramid & Caribbean Cliff", 20.6843, -88.5678]
			]),
		# Page 28 (idx 27, 10 levels): TURKEY — West-to-East Aegean to Cappadocia & Eastern Anatolia
		_make_country_entry("turkey", "Turkey", "Thổ Nhĩ Kỳ", "west_to_east",
			"GoTürkiye (goturkiye.com) — Bosphorus & Aegean to Cappadocia West-to-East Route",
			"Mount Erciyes", "Central Anatolia", 38.5319, 35.4469, [
				["Çanakkale & Troy", "Dardanelles", "karnak_temple", "Ancient Walls of Troy & Strait", 39.9575, 26.2389],
				["Ephesus (Selçuk)", "Aegean Coast", "karnak_temple", "Library of Celsus Two-Story Marble Facade", 37.9396, 27.3417],
				["Istanbul", "Bosphorus", "florence_duomo", "Hagia Sophia Domes, Minarets & Bosphorus Bridge", 41.0082, 28.9784],
				["Bursa", "Marmara", "florence_duomo", "Green Mosque & Uludağ Cableway", 40.1885, 29.0610],
				["Pamukkale", "Denizli", "tuscany_villa", "White Travertine Thermal Pools & Hierapolis", 37.9204, 29.1209],
				["Antalya", "Turkish Riviera", "rome_colosseum", "Hadrian's Gate, Aspendos Theater & Harbor", 36.8969, 30.7133],
				["Konya", "Central Plateau", "florence_duomo", "Mevlana Turquoise Fluted Dome", 37.8746, 32.4932],
				["Cappadocia (Göreme)", "Nevşehir", "grand_canyon_rim", "Fairy Chimneys & Hot Air Balloons", 38.6431, 34.8289],
				["Mount Nemrut", "Adıyaman", "abu_simbel", "Colossal Stone Heads Summit Sanctuary", 37.9808, 38.7408],
				["Mardin", "Upper Mesopotamia", "tuscany_villa", "Golden Limestone Hilltop Citadel", 37.3212, 40.7245]
			]),
		# Page 29 (idx 28, 6 levels): PORTUGAL — North-to-South Douro to Lisbon & Algarve
		_make_country_entry("portugal", "Portugal", "Bồ Đào Nha", "north_to_south",
			"Visit Portugal (visitportugal.com) — Porto to Algarve North-to-South Route",
			"Serra da Estrela", "Beira Interior", 40.3219, -7.6129, [
				["Porto & Douro Valley", "Norte", "glacier_bridge", "Dom Luís I Arch Bridge & Ribeira Wine Boats", 41.1579, -8.6291],
				["Coimbra", "Centro", "pisa_tower", "Hilltop University Clock Tower & Mondego", 40.2033, -8.4103],
				["Nazaré & Óbidos", "Estremadura", "lighthouse_landmark", "Fort of São Miguel Lighthouse & Walled Town", 39.6012, -9.0706],
				["Sintra", "Lisbon Coast", "loire_chateau", "Pena Palace Red-and-Yellow Romantic Turrets", 38.7878, -9.3906],
				["Lisbon", "Tagus Estuary", "pisa_tower", "Belém Tower & 25 de Abril Suspension Bridge", 38.7223, -9.1393],
				["Lagos & Benagil (Algarve)", "Algarve", "halong_karst_harbor", "Golden Sea Arch Cliffs & Atlantic Grottos", 37.0872, -8.4267]
			]),
		# Page 30 (idx 29, 8 levels): AUSTRALIA — East-to-West Coral Sea to Red Centre & Indian Ocean
		_make_country_entry("australia", "Australia", "Úc", "east_to_west",
			"Tourism Australia (australia.com) — Pacific Coast to Outback & Indian Ocean",
			"Blue Mountains", "New South Wales", -33.7126, 150.3119, [
				["Brisbane & Gold Coast", "Queensland", "manhattan_skyline", "Story Bridge & Surfers Paradise Bay", -27.4705, 153.0260],
				["Sydney", "New South Wales", "golden_gate", "Sydney Opera House Sails & Harbour Bridge", -33.8568, 151.2153],
				["Canberra", "Capital Territory", "luxor_obelisk", "Parliament House Spire & Lake Burley Griffin", -35.2809, 149.1300],
				["Cairns (Great Barrier Reef)", "Queensland", "halong_karst_harbor", "Coral Cays & Tropical Reef Lagoon", -16.9186, 145.7781],
				["Melbourne & Great Ocean Road", "Victoria", "halong_karst_harbor", "Twelve Apostles Sea Stacks & Yarra Skyline", -38.6621, 143.1051],
				["Adelaide", "South Australia", "tuscany_villa", "Barossa Valley Vineyards & Torrens River", -34.9285, 138.6007],
				["Uluru (Red Centre)", "Northern Territory", "grand_canyon_rim", "Uluru Sandstone Monolith & Kata Tjuta", -25.3444, 131.0369],
				["Perth & Rottnest", "Western Australia", "lighthouse_landmark", "Swan Bell Tower & Indian Ocean Lighthouse", -31.9505, 115.8605]
			]),
		# Page 31 (idx 30, 6 levels): MALAYSIA — North-to-South Langkawi to Malacca Strait
		_make_country_entry("malaysia", "Malaysia", "Malaysia", "north_to_south",
			"Tourism Malaysia (malaysia.travel) — Peninsula North-to-South Heritage Route",
			"Mount Kinabalu", " Highland Range", 6.0753, 116.5588, [
				["Langkawi", "Kedah", "glacier_bridge", "Langkawi Sky Bridge & Machincang Karsts", 6.3860, 99.6623],
				["George Town (Penang)", "Penang", "chureito_pagoda", "Kek Lok Si Pagoda & Heritage Clan Jetties", 5.4141, 100.3288],
				["Ipoh & Cameron Highlands", "Perak / Pahang", "tuscany_villa", "Emerald Tea Plantations & Cave Temples", 4.4721, 101.3801],
				["Kuala Lumpur", "Klang Valley", "manhattan_skyline", "Petronas Twin Towers & Skybridge", 3.1579, 101.7116],
				["Putrajaya", "Federal Territory", "florence_duomo", "Putra Rose-Dome Lakeside Mosque & Bridge", 2.9364, 101.6892],
				["Malacca (Melaka)", "Malacca Strait", "hoian_covered_bridge_lanterns", "Red Dutch Square Stadthuys & River Jonks", 2.1944, 102.2491]
			]),
		# Page 32 (idx 31, 7 levels): UNITED ARAB EMIRATES — East-to-West Gulf of Oman to Abu Dhabi
		_make_country_entry("united_arab_emirates", "United Arab Emirates", "Các Tiểu Vương Quốc Ả Rập", "east_to_west",
			"UAE Ministry of Economy Tourism — East Coast Mountains to Abu Dhabi Corniche",
			"Hajar Mountains", "Eastern Emirates", 25.3000, 56.1500, [
				["Fujairah", "Gulf of Oman", "loire_chateau", "Fujairah Mud-Brick Fort & Al-Bidyah Mosque", 25.1288, 56.3265],
				["Hatta", "Hajar Enclave", "halong_karst_harbor", "Turquoise Mountain Dam & Watchtowers", 24.8005, 56.1272],
				["Ras Al Khaimah", "Jebel Jais", "grand_canyon_rim", "Dhayah Hilltop Fort & Jebel Jais Ridge", 25.7895, 55.9432],
				["Al Ain", "Garden Oasis", "giza_sphinx", "Al Jahili Fort & Jebel Hafeet Oasis", 24.2075, 55.7447],
				["Sharjah", "Arabian Gulf", "florence_duomo", "Al Noor Island Domes & Khalid Lagoon", 25.3463, 55.4209],
				["Dubai", "Dubai Creek", "tokyo_tower", "Burj Khalifa Spire & Burj Al Arab Sail", 25.1972, 55.2744],
				["Abu Dhabi", "Capital Islands", "florence_duomo", "Sheikh Zayed White Marble Domes & Minarets", 24.4128, 54.4750]
			]),
		# Page 33 (idx 32, 8 levels): IRELAND — East-to-West Dublin to Wild Atlantic Way
		_make_country_entry("ireland", "Ireland", "Ireland", "east_to_west",
			"Tourism Ireland (ireland.com) — Dublin across Ancient East to Wild Atlantic Way",
			"MacGillycuddy's Reeks", "Munster", 51.9994, -9.7427, [
				["Dublin", "Leinster", "glacier_bridge", "Ha'penny Bridge & Trinity Bell Tower", 53.3498, -6.2603],
				["Glendalough (Wicklow)", "Wicklow Mountains", "pisa_tower", "Monastic Round Stone Tower & Lakes", 53.0120, -6.3298],
				["Kilkenny", "Nore Valley", "loire_chateau", "Kilkenny Norman Castle & River Park", 52.6541, -7.2448],
				["Cashel", "Tipperary", "mont_saint_michel", "Rock of Cashel Limestone Hilltop Abbey", 52.5201, -7.8904],
				["Cork & Blarney", "Munster", "loire_chateau", "Blarney Stone Keep & Cobh Harbor", 51.9291, -8.5709],
				["Cliffs of Moher", "Clare", "grand_canyon_rim", "O'Brien's Tower on Atlantic Sea Cliffs", 52.9715, -9.4309],
				["Killarney (Ring of Kerry)", "Kerry", "alpine_chalet", "Ross Castle & Lakes of Killarney", 52.0419, -9.5305],
				["Galway & Connemara", "Connacht", "loire_chateau", "Kylemore Abbey & Galway Spanish Arch", 53.5616, -9.8893]
			]),
		# Page 34 (idx 33, 9 levels): INDIA — North-to-South Himalaya to Kerala Backwaters
		_make_country_entry("india", "India", "Ấn Độ", "north_to_south",
			"Incredible India (incredibleindia.gov.in) — Kashmir to Kerala North-to-South Grand Route",
			"Western Ghats", "Peninsular India", 13.5000, 75.5000, [
				["Amritsar", "Punjab", "hanoi_hoan_kiem_pagoda", "Golden Temple (Harmandir Sahib) in Amrit Sarovar", 31.6200, 74.8765],
				["New Delhi", "National Capital", "karnak_temple", "India Gate Arch, Red Fort & Qutub Minar", 28.6129, 77.2295],
				["Agra", "Uttar Pradesh", "florence_duomo", "Taj Mahal White Marble Dome & Reflecting Pool", 27.1751, 78.0421],
				["Jaipur", "Rajasthan", "hue_imperial_citadel", "Hawa Mahal Pink Sandstone Palace of Winds", 26.9239, 75.8267],
				["Varanasi", "Ganges Plain", "chureito_pagoda", "Dashashwamedh River Ghats & Temple Spires", 25.3069, 83.0104],
				["Udaipur", "Mewar", "versailles_palace", "Lake Pichola White Marble Palace", 24.5764, 73.6835],
				["Mumbai", "Konkan Coast", "rome_colosseum", "Gateway of India Basalt Arch on Arabian Sea", 18.9220, 72.8347],
				["Hampi & Mysore", "Karnataka", "chureito_pagoda", "Virupaksha Gopuram Tower & Stone Chariot", 15.3350, 76.4600],
				["Alleppey & Kochi (Kerala)", "Malabar Coast", "mekong_floating_market", "Kerala Palm Backwaters & Kettuvallam Houseboats", 9.4981, 76.3388]
			]),
		# Page 35 (idx 34, 5 levels): SAUDI ARABIA — North-to-South AlUla to Riyadh & Asir
		_make_country_entry("saudi_arabia", "Saudi Arabia", "Ả Rập Xê Út", "north_to_south",
			"Saudi Tourism Authority (visitsaudi.com) — AlUla to Red Sea & Riyadh Route",
			"Tuwaiq Escarpment", "Najd Plateau", 24.8500, 46.0000, [
				["AlUla (Hegra)", "Medina Province", "abu_simbel", "Qasr al-Farid Nabataean Rock-Cut Tomb", 26.7917, 37.9542],
				["Riyadh & Diriyah", "Najd", "manhattan_skyline", "At-Turaif Mud-Brick Citadel & Kingdom Centre", 24.7136, 46.6753],
				["Medina Region", "Hejaz", "florence_duomo", "Green Dome & Oasis Palm Colonnades", 24.4672, 39.6111],
				["Jeddah (Al-Balad)", "Red Sea Coast", "venice_canal", "Coral-Stone Roshan Houses & Red Sea Fountain", 21.4858, 39.1925],
				["Abha & Rijal Almaa", "Asir Mountains", "loire_chateau", "Multi-Story Stone Watchtowers in Cloud Hills", 18.2164, 42.5053]
			]),
		# Page 36 (idx 35, 8 levels): SWEDEN — South-to-North Scania to Abisko Lapland
		_make_country_entry("sweden", "Sweden", "Thụy Điển", "south_to_north",
			"Visit Sweden (visitsweden.com) — Øresund to Arctic Lapland South-to-North",
			"Kebnekaise Massif", "Swedish Lapland", 67.9000, 18.5167, [
				["Malmö", "Scania", "golden_gate", "Øresund Bridge & Turning Torso Spire", 55.6050, 13.0038],
				["Visby (Gotland)", "Baltic Sea", "loire_chateau", "Medieval Limestone Ringwall & Towers", 57.6348, 18.2948],
				["Gothenburg", "West Coast", "lighthouse_landmark", "Marstrand Island Fortress & Archipelago", 57.7089, 11.9746],
				["Stockholm", "Mälaren Archipelago", "venice_canal", "Gamla Stan Waterfront & City Hall Brick Tower", 59.3293, 18.0686],
				["Uppsala", "Uppland", "florence_duomo", "Uppsala Twin Red-Brick Gothic Spires", 59.8586, 17.6389],
				["Falun & Dalarna", "Siljan Basin", "alpine_chalet", "Falu Red Timber Cottages & Lake Siljan", 60.6065, 15.6355],
				["High Coast (Höga Kusten)", "Ångermanland", "golden_gate", "High Coast Suspension Bridge & Red Granite", 62.7984, 17.9381],
				["Kiruna & Jukkasjärvi", "Lapland", "zermatt_sanctuary", "Arctic Ice Sanctuary & Northern Lights Ridge", 67.8558, 20.2253]
			]),
		# Page 37 (idx 36, 7 levels): NEW ZEALAND — North-to-South Bay of Islands to Milford Sound
		_make_country_entry("new_zealand", "New Zealand", "New Zealand", "north_to_south",
			"Tourism New Zealand (newzealand.com) — North Island to South Island Fiordland",
			"Aoraki / Mount Cook", "Southern Alps", -43.5950, 170.1418, [
				["Bay of Islands", "Northland", "lighthouse_landmark", "Cape Brett Lighthouse & Hole in the Rock", -35.2281, 174.1228],
				["Auckland", "Hauraki Gulf", "tokyo_tower", "Sky Tower & Waitematā Harbour Sails", -36.8485, 174.7633],
				["Matamata & Rotorua", "Waikato / Bay of Plenty", "tuscany_villa", "Green Shire Hills & Geothermal Geysers", -38.1368, 176.2497],
				["Wellington", "Cook Strait", "alpine_village", "Red Cable Car, Beehive & Harbour Hills", -41.2865, 174.7762],
				["Kaikōura & Christchurch", "Canterbury", "alpine_chalet", "Avon River Tramway & Coastal Alps", -43.5321, 172.6362],
				["Milford Sound", "Fiordland", "halong_karst_harbor", "Mitre Peak Fjord & Bowen Falls", -44.6716, 167.9256],
				["Queenstown & Wanaka", "Otago", "zermatt_sanctuary", "Remarkables Range & Lake Wakatipu Steamer", -45.0312, 168.6626]
			]),
		# Page 38 (idx 37, 10 levels): CAMBODIA — West-to-East Cardamom Coast to Angkor & Mekong
		_make_country_entry("cambodia", "Cambodia", "Campuchia", "west_to_east",
			"Ministry of Tourism Cambodia — West-to-East Angkor & Mekong Heritage Route",
			"Phnom Kulen Plateau", "Siem Reap", 13.5667, 104.1167, [
				["Battambang", "Northwest Plains", "chureito_pagoda", "Phnom Sampeau Hilltop Stupa & Bamboo Train", 13.0957, 103.2022],
				["Koh Rong & Sihanoukville", "Gulf of Thailand", "halong_karst_harbor", "Turquoise Island Bays & Wooden Piers", 10.6967, 103.2414],
				["Angkor Thom (Bayon)", "Angkor Park", "abu_simbel", "Bayon Smiling Stone Faces Sanctuary", 13.4412, 103.8589],
				["Siem Reap (Angkor Wat)", "Tonlé Sap Basin", "chureito_pagoda", "Angkor Wat Five Lotus Towers & Moat", 13.4125, 103.8670],
				["Tonlé Sap Floating Villages", "Central Basin", "mekong_floating_market", "Kampong Phluk Stilt Houses & Boats", 13.2100, 104.0100],
				["Kampot & Bokor", "Southern Coast", "tuscany_villa", "Kampot River Bridge & Pepper Hills", 10.6104, 104.1815],
				["Oudong", "Kampong Speu", "chureito_pagoda", "Royal Hilltop Chedis of Oudong", 11.8211, 104.7453],
				["Phnom Penh", "Mekong Confluence", "hue_imperial_citadel", "Royal Palace Golden Spire & Silver Pagoda", 11.5626, 104.9310],
				["Kampong Cham", "Mekong Valley", "glacier_bridge", "Koh Paen Bamboo Bridge & Nokor Bachey", 11.9934, 105.4635],
				["Kratie & Mondulkiri", "Eastern Highlands", "grand_canyon_rim", "Mekong Dolphin Pools & Bousra Falls", 12.4881, 106.0188]
			]),
		# Page 39 (idx 38, 6 levels): CZECHIA — West-to-East Bohemia to Moravia
		_make_country_entry("czechia", "Czechia", "Cộng Hòa Séc", "west_to_east",
			"CzechTourism (visitczechia.com) — West Bohemia Spa Towns to Moravia",
			"Krkonoše Mountains", "Northern Bohemia", 50.7360, 15.7398, [
				["Karlovy Vary", "West Bohemia", "versailles_palace", "Mill Colonnade & Pastel Riverfront", 50.2319, 12.8720],
				["Plzeň", "West Bohemia", "pisa_tower", "St. Bartholomew Tallest Gothic Spire", 49.7475, 13.3776],
				["Český Krumlov", "South Bohemia", "loire_chateau", "Vltava Horseshoe Bend & Painted Castle Tower", 48.8127, 14.3175],
				["Prague", "Central Bohemia", "glacier_bridge", "Charles Bridge Towers & Prague Castle Spires", 50.0865, 14.4114],
				["Kutná Hora", "Central Bohemia", "florence_duomo", "St. Barbara Tent-Roofed Gothic Cathedral", 49.9484, 15.2682],
				["Brno & Lednice", "South Moravia", "loire_chateau", "Lednice Chateau & Moravian Vineyard Hills", 49.1951, 16.6068]
			]),
		# Page 40 (idx 39, 8 levels): ARGENTINA — North-to-South Quebrada to Tierra del Fuego
		_make_country_entry("argentina", "Argentina", "Argentina", "north_to_south",
			"Visit Argentina (argentina.travel) — Ruta 40 & Atlantic North-to-South Journey",
			"Aconcagua Peak", "Mendoza Andes", -32.6532, -70.0109, [
				["Purmamarca (Jujuy)", "Northwest Andes", "grand_canyon_rim", "Hill of Seven Colors & Salt Flats", -23.7465, -65.4991],
				["Salta & Cafayate", "Calchaquí Valleys", "florence_duomo", "San Francisco Red Bell Tower & Vineyards", -24.7821, -65.4232],
				["Puerto Iguazú", "Misiones", "grand_canyon_rim", "Devil's Throat Cataracts & Jungle Gorge", -25.6867, -54.4447],
				["Córdoba", "Sierras Pampeanas", "versailles_palace", "Jesuit Block Domes & Mountain Estancias", -31.4201, -64.1888],
				["Mendoza", "Cuyo Foothills", "tuscany_villa", "Malbec Vineyards under Andean Snow Peaks", -32.8895, -68.8458],
				["Buenos Aires", "Río de la Plata", "luxor_obelisk", "Obelisco, Caminito La Boca & Puente de la Mujer", -34.6037, -58.3816],
				["Bariloche", "Northern Patagonia", "alpine_chalet", "Nahuel Huapi Alpine Lake & Stone Lodge", -41.1335, -71.3103],
				["El Calafate & Ushuaia", "Southern Patagonia", "zermatt_sanctuary", "Perito Moreno Glacier Wall & Les Eclaireurs Lighthouse", -50.3379, -72.2648]
			]),
		# Page 41 (idx 40, 6 levels): CROATIA — North-to-South Zagreb to Dubrovnik Adriatic Coast
		_make_country_entry("croatia", "Croatia", "Croatia", "north_to_south",
			"Croatian National Tourist Board (croatia.hr) — Zagreb to Dubrovnik Route",
			"Velebit Coastal Range", "Dalmatia", 44.4000, 15.3000, [
				["Zagreb", "Central Croatia", "florence_duomo", "St. Mark's Tiled Roof & Twin Cathedral Spires", 45.8150, 15.9819],
				["Rovinj & Pula", "Istria", "rome_colosseum", "Pula Roman Amphitheatre & Hilltop Campanile", 45.0812, 13.6387],
				["Plitvice Lakes", "Lika", "halong_karst_harbor", "Turquoise Travertine Waterfalls & Boardwalks", 44.8654, 15.5820],
				["Zadar", "Northern Dalmatia", "florence_duomo", "Church of St. Donatus Rotunda & Sea Organ", 44.1194, 15.2314],
				["Split & Hvar", "Central Dalmatia", "karnak_temple", "Diocletian's Palace Peristyle & Bell Tower", 43.5081, 16.4402],
				["Dubrovnik", "Southern Dalmatia", "loire_chateau", "Old Town Sea Walls, Fort Lovrijenac & Red Roofs", 42.6507, 18.0944]
			]),
		# Page 42 (idx 41, 7 levels): SINGAPORE — West-to-East Jurong Gardens to Changi Jewel
		_make_country_entry("singapore", "Singapore", "Singapore", "west_to_east",
			"Singapore Tourism Board (visitsingapore.com) — West-to-East Garden City Corridor",
			"Bukit Timah Reserve", "Central Catchment", 1.3547, 103.7764, [
				["Jurong Lake Gardens", "West Region", "chureito_pagoda", "Twin Chinese & Japanese Garden Pagodas", 1.3385, 103.7289],
				["Botanic Gardens", "Tanglin", "tuscany_villa", "Bandstand Gazebo & Orchid Pavilion", 1.3138, 103.8159],
				["Sentosa Island", "Southern Coast", "lighthouse_landmark", "Palawan Suspension Bridge & Harbor Cableway", 1.2494, 103.8303],
				["Chinatown & Buddha Relic", "Outram", "kyoto_temple", "Buddha Tooth Relic Tang-Style Temple", 1.2815, 103.8448],
				["Marina Bay", "Downtown Core", "manhattan_skyline", "Marina Bay Sands SkyPark & Merlion", 1.2834, 103.8607],
				["Gardens by the Bay", "Marina South", "astral_observatory", "Supertree Grove & Glass Cloud Conservatory", 1.2816, 103.8636],
				["Jewel Changi", "East Coast", "astral_observatory", "Rain Vortex Glass Torus Dome", 1.3602, 103.9898]
			]),
		# Page 43 (idx 42, 8 levels): POLAND — North-to-South Baltic Coast to Tatra Mountains
		_make_country_entry("poland", "Poland", "Ba Lan", "north_to_south",
			"Polish Tourism Organisation (poland.travel) — Amber Coast to Tatra Peaks",
			"Masurian Lake District", "Warmia-Masuria", 53.9500, 21.6500, [
				["Gdańsk", "Pomerania", "venice_canal", "Long Market Neptune Fountain & Motława Crane", 54.3520, 18.6466],
				["Malbork", "Vistula Delta", "loire_chateau", "Malbork Red-Brick Teutonic Castle", 54.0397, 19.0278],
				["Toruń", "Kuyavia", "pisa_tower", "Gothic Brick Town Hall & Vistula Bridge", 53.0138, 18.5984],
				["Warsaw", "Mazovia", "versailles_palace", "Royal Castle Square, Sigismund Column & Old Town", 52.2477, 21.0142],
				["Wrocław", "Lower Silesia", "venice_canal", "Market Square & Ostrów Tumski River Bridges", 51.1079, 17.0385],
				["Kraków", "Lesser Poland", "loire_chateau", "Wawel Royal Castle & St. Mary's Trumpet Towers", 50.0619, 19.9368],
				["Wieliczka", "Lesser Poland", "florence_duomo", "Historic Salt Mine Headframe & Chapel", 49.9836, 20.0558],
				["Zakopane", "Tatra Mountains", "alpine_chalet", "Giewont Peak & Timber Highland Chalets", 49.2992, 19.9496]
			]),
		# Page 44 (idx 43, 9 levels): COLOMBIA — North-to-South Caribbean to Andes & Amazon
		_make_country_entry("colombia", "Colombia", "Colombia", "north_to_south",
			"ProColombia (colombia.travel) — Caribbean Coast to Coffee Axis & Andes",
			"Sierra Nevada de Santa Marta", "Magdalena", 10.8675, -73.7219, [
				["Tayrona & Santa Marta", "Magdalena Coast", "halong_karst_harbor", "Cabo San Juan Coastal Boulders & Palms", 11.3142, -73.9570],
				["Cartagena de Indias", "Bolívar", "loire_chateau", "Clock Tower Gate, San Felipe Fort & Balconies", 10.4236, -75.5478],
				["Barichara", "Santander", "tuscany_villa", "Cobblestone Streets & Sandstone Cathedral", 6.6358, -73.2234],
				["Guatapé & Medellín", "Antioquia", "grand_canyon_rim", "Peñol Monolith Staircase & Emerald Reservoir", 6.2219, -75.1783],
				["Villa de Leyva", "Boyacá", "versailles_palace", "Plaza Mayor Whitewashed Colonial Square", 5.6333, -73.5244],
				["Salento (Cocora Valley)", "Quindío", "tuscany_villa", "Towering Quindío Wax Palms & Coffee Fincas", 4.6375, -75.5703],
				["Bogotá & Zipaquirá", "Cundinamarca", "florence_duomo", "Monserrate Sanctuary & Plaza de Bolívar", 4.5981, -74.0758],
				["Cali & Popayán", "Cauca Valley", "florence_duomo", "Ermita Riverfront Spires & White City", 3.4516, -76.5320],
				["Ipiales (Las Lajas)", "Nariño", "glacier_bridge", "Las Lajas Gothic Bridge Sanctuary over Gorge", 0.8055, -77.5858]
			]),
		# Page 45 (idx 44, 5 levels): TUNISIA — North-to-South Mediterranean to Sahara Oasis
		_make_country_entry("tunisia", "Tunisia", "Tunisia", "north_to_south",
			"Tunisian National Tourist Office — Carthage to Sahara North-to-South Route",
			"Chott el Djerid", "Southern Salt Lake", 33.7000, 8.4000, [
				["Tunis & Sidi Bou Said", "Gulf of Tunis", "venice_canal", "Blue-and-White Clifftop Village & Carthage Baths", 36.8687, 10.3417],
				["Kairouan", "Central Steppe", "pisa_tower", "Great Mosque Three-Tiered Square Minaret", 35.6814, 10.1039],
				["El Jem", "Mahdia", "rome_colosseum", "Roman Amphitheatre of Thysdrus", 35.2964, 10.7069],
				["Tozeur & Douz", "Jerid Sahara", "giza_sphinx", "Chebika Mountain Oasis Palms & Sahara Dunes", 33.9197, 8.1335],
				["Matmata", "Dahar Plateau", "grand_canyon_rim", "Sunken Berber Courtyard Dwellings", 33.5444, 9.9669]
			]),
		# Page 46 (idx 45, 8 levels): FINLAND — South-to-North Archipelago to Arctic Lapland
		_make_country_entry("finland", "Finland", "Phần Lan", "south_to_north",
			"Visit Finland (visitfinland.com) — Baltic Coast through Lakeland to Lapland",
			"Koli National Hills", "North Karelia", 63.0950, 29.8080, [
				["Suomenlinna & Helsinki", "Uusimaa", "florence_duomo", "Helsinki White Neoclassical Cathedral & Sea Fortress", 60.1699, 24.9522],
				["Porvoo", "Eastern Uusimaa", "venice_canal", "Red Ocher Wooden Riverfront Shorehouses", 60.3923, 25.6651],
				["Turku", "Southwest Archipelago", "loire_chateau", "Turku Medieval Stone Castle & Aura River", 60.4354, 22.2289],
				["Tampere", "Pirkanmaa", "pisa_tower", "Tammerkoski Rapids & Pyynikki Observation Tower", 61.4978, 23.7610],
				["Savonlinna (Lake Saimaa)", "Lakeland", "mont_saint_michel", "Olavinlinna Three-Tower Island Castle", 61.8638, 28.9011],
				["Oulu", "Bothnian Bay", "lighthouse_landmark", "Nallikari Lighthouse & Toripoliisi Market", 65.0121, 25.4651],
				["Rovaniemi", "Arctic Circle", "alpine_chalet", "Arctic Circle Timber Village & Lumberjack Bridge", 66.5039, 25.7294],
				["Inari & Saariselkä", "Northern Lapland", "zermatt_sanctuary", "Aurora Glass Igloos & Lake Inari Fells", 68.9060, 27.0288]
			])
	]


static func _get_country_manifests_part_c() -> Array[Dictionary]:
	return [
		# Page 47 (idx 46, 7 levels): ICELAND — West-to-East Ring Road & Volcanic Highlands
		_make_country_entry("iceland", "Iceland", "Iceland", "west_to_east",
			"Inspired by Iceland (visiticeland.com) — West-to-East Ring Road & Glacial Lagoons",
			"Vatnajökull Ice Cap", "Southeast Highlands", 64.4000, -16.8000, [
				["Reykjavík", "Capital Peninsula", "pisa_tower", "Hallgrímskirkja Basalt Spire & Harpa", 64.1466, -21.9426],
				["Þingvellir & Geysir", "Golden Circle", "grand_canyon_rim", "Almannagjá Tectonic Gorge & Strokkur Geyser", 64.2559, -21.1299],
				["Gullfoss", "Hvítá Canyon", "halong_karst_harbor", "Two-Tiered Glacial Waterfall", 64.3271, -20.1199],
				["Seljalandsfoss & Skógafoss", "South Coast", "grand_canyon_rim", "Basalt Sea Cliffs & Rainbow Cataracts", 63.5321, -19.5114],
				["Vík (Reynisfjara)", "Mýrdalur", "halong_karst_harbor", "Reynisdrangar Black Basalt Sea Stacks", 63.4186, -19.0060],
				["Jökulsárlón", "Vatnajökull Coast", "zermatt_sanctuary", "Floating Blue Icebergs & Diamond Beach", 64.0784, -16.2306],
				["Seyðisfjörður", "Eastfjords", "alpine_village", "Rainbow Street Timber Church & Fjord", 65.2598, -14.0101]
			]),
		# Page 48 (idx 47, 10 levels): SRI LANKA — North-to-South Jaffna to Cultural Triangle & Galle
		_make_country_entry("sri_lanka", "Sri Lanka", "Sri Lanka", "north_to_south",
			"Sri Lanka Tourism Promotion Bureau (srilanka.travel) — North-to-South Island Heritage Route",
			"Adam's Peak (Sri Pada)", "Central Highlands", 6.8096, 80.4994, [
				["Jaffna", "Northern Peninsula", "chureito_pagoda", "Nallur Kandaswamy Golden Gopuram & Dutch Fort", 9.6615, 80.0255],
				["Trincomalee", "Eastern Bay", "torii_shrine", "Koneswaram Clifftop Sea Temple", 8.5874, 81.2152],
				["Anuradhapura", "North Central Plains", "chureito_pagoda", "Ruwanwelisaya Great White Dagoba", 8.3114, 80.4037],
				["Sigiriya", "Matale District", "grand_canyon_rim", "Lion Rock Sky Citadel & Water Gardens", 7.9570, 80.7603],
				["Polonnaruwa", "North Central", "karnak_temple", "Vatadage Circular Relic House", 7.9403, 81.0188],
				["Dambulla", "Central Province", "abu_simbel", "Golden Cave Temple Murals & Stupas", 7.8567, 80.6492],
				["Kandy", "Hill Country", "kyoto_temple", "Temple of the Sacred Tooth & Kandy Lake", 7.2906, 80.6337],
				["Nuwara Eliya & Ella", "Tea Highlands", "glacier_bridge", "Nine Arch Stone Viaduct & Emerald Tea Hills", 6.8768, 81.0608],
				["Yala Coast", "Southern Plains", "lighthouse_landmark", "Kirinda Rock Temple & Coastal Lagoon", 6.2167, 81.3333],
				["Galle Fort", "Southern Coast", "lighthouse_landmark", "Galle White Lighthouse & Dutch Sea Ramparts", 6.0267, 80.2170]
			]),
		# Page 49 (idx 48, 6 levels): BELGIUM — West-to-East Flanders Canals to Ardennes
		_make_country_entry("belgium", "Belgium", "Bỉ", "west_to_east",
			"Visit Flanders & Wallonia — Bruges to Ardennes West-to-East Route",
			"Meuse River Cliffs", "Wallonia", 50.2600, 4.9100, [
				["Bruges", "West Flanders", "venice_canal", "Belfry of Bruges & Rosary Quay Canals", 51.2093, 3.2247],
				["Ghent", "East Flanders", "loire_chateau", "Gravensteen Moat Castle & Graslei Gilded Gables", 51.0543, 3.7174],
				["Brussels", "Capital Region", "versailles_palace", "Grand-Place Gilded Guildhalls & Atomium Spheres", 50.8467, 4.3525],
				["Antwerp", "Scheldt Port", "florence_duomo", "Cathedral of Our Lady Spire & Grote Markt", 51.2194, 4.4025],
				["Leuven", "Flemish Brabant", "versailles_palace", "Flamboyant Gothic Town Hall Turrets", 50.8798, 4.7005],
				["Dinant (Ardennes)", "Namur", "mont_saint_michel", "Clifftop Citadel & Onion-Dome Collegiate Church", 50.2606, 4.9122]
			]),
		# Page 50 (idx 49, 8 levels): KENYA — West-to-East Rift Valley to Indian Ocean Swahili Coast
		_make_country_entry("kenya", "Kenya", "Kenya", "west_to_east",
			"Magical Kenya (magicalkenya.com) — Lake Victoria & Maasai Mara to Lamu Coast",
			"Mount Kenya", "Central Highlands", -0.1521, 37.3084, [
				["Kisumu (Lake Victoria)", "Nyanza", "mekong_floating_market", "Lake Victoria Fishing Dhows & Papyrus Shore", -0.0917, 34.7680],
				["Maasai Mara", "Narok Rift", "tuscany_villa", "Acacia Savannah & Mara River Crossing", -1.4061, 35.0081],
				["Lake Nakuru & Naivasha", "Great Rift Valley", "halong_karst_harbor", "Flamingo Alkaline Lake & Escarpment", -0.3031, 36.0800],
				["Nairobi", "Central Uplands", "manhattan_skyline", "KICC Helipad Tower & Ngong Hills", -1.2921, 36.8219],
				["Amboseli", "Kilimanjaro Basin", "zermatt_sanctuary", "Savannah Palm Lagoons & Snow-Capped Backdrop", -2.6527, 37.2606],
				["Tsavo", "Coast Hinterland", "grand_canyon_rim", "Mzima Springs & Red-Earth Lava Ridge", -2.9833, 38.4667],
				["Mombasa", "Indian Ocean", "loire_chateau", "Fort Jesus Coral-Stone Ramparts & Old Dhow Port", -4.0628, 39.6775],
				["Lamu Island", "Lamu Archipelago", "venice_canal", "Swahili Coral-Stone Seafront & Lateen Sails", -2.2696, 40.9006]
			]),
		# Page 51 (idx 50, 6 levels): MALDIVES — North-to-South Coral Atoll Chain
		_make_country_entry("maldives", "Maldives", "Maldives", "north_to_south",
			"Visit Maldives (visitmaldives.com) — Northern to Southern Atoll Lagoon Chain",
			"Indian Ocean Barrier Reef", "Laccadive Sea", 3.2028, 73.2207, [
				["Haa Alif (Utheemu)", "Northernmost Atoll", "tuscany_villa", "Utheemu Ganduvaru Timber Palace & Lagoon", 6.8350, 73.1125],
				["Baa Atoll (Hanifaru)", "UNESCO Biosphere", "halong_karst_harbor", "Ring-Shaped Coral Reefs & Overwater Jetty", 5.1667, 73.0500],
				["North Malé & Malé", "Kaafu Atoll", "florence_duomo", "Grand Friday Golden Dome & Dhoni Harbor", 4.1755, 73.5093],
				["Ari Atoll", "Central Atolls", "tuscany_villa", "Overwater Thatch Villas & Sandbank Causeway", 3.8667, 72.8167],
				["Vaavu Atoll", "Felidhoo Lagoon", "lighthouse_landmark", "Shipwreck Reef & Bioluminescent Spit", 3.4667, 73.4667],
				["Addu Atoll", "Southern Equator", "glacier_bridge", "Addu Link Causeway & Equatorial Lagoon", -0.6300, 73.1586]
			]),
		# Page 52 (idx 51, 7 levels): PANAMA — West-to-East Chiriquí Highlands to Panama Canal & San Blas
		_make_country_entry("panama", "Panama", "Panama", "west_to_east",
			"Visit Panama (tourismpanama.com) — Chiriquí Cloud Forest to Panama Canal & Darién",
			"Volcán Barú", "Chiriquí", 8.8080, -82.5430, [
				["Boquete", "Chiriquí Highlands", "alpine_chalet", "Cloud Forest Coffee Estates & Suspension Bridges", 8.7802, -82.4414],
				["Bocas del Toro", "Caribbean West", "mekong_floating_market", "Overwater Wooden Cabins & Starfish Cay", 9.3403, -82.2419],
				["Santa Catalina (Coiba)", "Veraguas", "halong_karst_harbor", "Pacific Volcanic Islets & Coral Bay", 7.6333, -81.2667],
				["El Valle de Antón", "Coclé", "tuscany_villa", "Crater Valley Village & Golden Frog Falls", 8.6008, -80.1306],
				["Panama Canal (Miraflores)", "Canal Zone", "golden_gate", "Centennial Bridge & Miraflores Canal Locks", 8.9969, -79.5911],
				["Panama City (Casco Viejo)", "Panama Bay", "manhattan_skyline", "Casco Viejo Bell Towers & Biomuseo Roofs", 8.9525, -79.5350],
				["San Blas Islands (Guna Yala)", "Caribbean East", "halong_karst_harbor", "Palm-Fringed Coral Cays & Sailboats", 9.5583, -78.8972]
			]),
		# Page 53 (idx 52, 8 levels): ROMANIA — West-to-East Transylvania to Black Sea Delta
		_make_country_entry("romania", "Romania", "Romania", "west_to_east",
			"Romania Tourism (romaniatourism.com) — Transylvania Castles to Black Sea Coast",
			"Carpathian Mountains", "Southern Carpathians", 45.5980, 24.6360, [
				["Timișoara", "Banat", "florence_duomo", "Victory Square Orthodox Spires & Bega Canal", 45.7489, 21.2087],
				["Hunedoara", "Transylvania", "loire_chateau", "Corvin Castle Gothic Towers & Drawbridge", 45.7494, 22.8883],
				["Sibiu", "Transylvania", "pisa_tower", "Council Tower, Bridge of Lies & Eyed Roofs", 45.7983, 24.1256],
				["Sighișoara", "Târnava Valley", "pisa_tower", "Medieval Clock Tower & Covered Staircase", 46.2197, 24.7922],
				["Brașov & Bran", "Burzenland", "loire_chateau", "Bran Clifftop Castle & Black Church", 45.5149, 25.3672],
				["Sinaia (Peleș)", "Prahova Valley", "versailles_palace", "Peleș Neo-Renaissance Alpine Palace", 45.3600, 25.5426],
				["Bucharest", "Wallachia", "versailles_palace", "Romanian Athenaeum Dome & Palace of Parliament", 44.4268, 26.1025],
				["Constanța & Danube Delta", "Dobrogea", "lighthouse_landmark", "Constanța Art Nouveau Seafront Casino & Genoese Lighthouse", 44.1722, 28.6638]
			]),
		# Page 54 (idx 53, 9 levels): PAKISTAN — South-to-North Arabian Sea along Indus to Karakoram
		_make_country_entry("pakistan", "Pakistan", "Pakistan", "south_to_north",
			"Pakistan Tourism Development Corporation (tourism.gov.pk) — Indus Valley to Karakoram Highway",
			"K2 & Baltoro Glacier", "Karakoram Range", 35.8800, 76.5133, [
				["Karachi", "Sindh Coast", "florence_duomo", "Mazar-e-Quaid White Marble Mausoleum & Port", 24.8754, 67.0410],
				["Thatta & Mohenjo-daro", "Lower Indus", "karnak_temple", "Shah Jahan Tiled Mosque & Indus Brick Citadel", 27.3242, 68.1375],
				["Multan", "Southern Punjab", "florence_duomo", "Shrine of Shah Rukn-e-Alam Blue-Tile Dome", 30.1984, 71.4687],
				["Lahore", "Punjab Plains", "hue_imperial_citadel", "Badshahi Red Sandstone Mosque & Lahore Fort", 31.5880, 74.3107],
				["Islamabad", "Margalla Foothills", "astral_observatory", "Faisal Mosque Four Minarets & Tent Roof", 33.7294, 73.0372],
				["Peshawar & Takht-i-Bahi", "Khyber Pakhtunkhwa", "karnak_temple", "Bala Hisar Fort & Gandhara Stone Stupas", 34.0151, 71.5249],
				["Swat Valley (Malam Jabba)", "Hindu Kush", "alpine_chalet", "Emerald Alpine Meadows & Buddhist Stupa", 34.7997, 72.5719],
				["Skardu (Shangrila)", "Baltistan", "loire_chateau", "Kharpocho Rock Fort & Upper Kachura Lake", 35.2971, 75.6333],
				["Hunza Valley (Karimabad)", "Gilgit-Baltistan", "zermatt_sanctuary", "Baltit Fort under Rakaposhi & Passu Cones", 36.3267, 74.6697]
			]),
		# Page 55 (idx 54, 5 levels): OMAN — North-to-South Musandam to Muscat, Nizwa & Salalah
		_make_country_entry("oman", "Oman", "Oman", "north_to_south",
			"Experience Oman (experienceoman.om) — Musandam Fjords to Dhofar Coast",
			"Jebel Akhdar", "Al Hajar Mountains", 23.0725, 57.6619, [
				["Khasab (Musandam)", "Strait of Hormuz", "halong_karst_harbor", "Limestone Fjord Cliffs & Omani Dhows", 26.1799, 56.2477],
				["Muscat", "Gulf of Oman", "florence_duomo", "Sultan Qaboos Grand Mosque Dome & Mutrah Corniche", 23.5880, 58.3829],
				["Nizwa & Bahla", "Ad Dakhiliyah", "loire_chateau", "Nizwa Giant Round Tower Fort & Oasis Palms", 22.9333, 57.5303],
				["Wahiba Sands & Sur", "Ash Sharqiyah", "lighthouse_landmark", "Al Ayjah White Lighthouse & Desert Dunes", 22.5667, 59.5289],
				["Salalah (Dhofar)", "Arabian Sea", "tuscany_villa", "Al Baleed Frankincense Port & Wadi Darbat", 17.0151, 54.0924]
			]),
		# Page 56 (idx 55, 8 levels): DENMARK — South-to-North Jutland & Islands to Skagen
		_make_country_entry("denmark", "Denmark", "Đan Mạch", "south_to_north",
			"VisitDenmark (visitdenmark.com) — Southern Islands & Copenhagen to Skagen Spit",
			"Møns Klint Chalk Cliffs", "Baltic Sea", 54.9653, 12.5522, [
				["Odense (Egeskov)", "Funen", "loire_chateau", "Egeskov Renaissance Water Castle", 55.1764, 10.4894],
				["Ribe", "South Jutland", "pisa_tower", "Ribe Romanesque Cathedral & Viking Marsh", 55.3283, 8.7619],
				["Roskilde", "Zealand", "florence_duomo", "Roskilde Twin-Spired Brick Cathedral & Fjord", 55.6415, 12.0803],
				["Copenhagen", "Øresund", "venice_canal", "Nyhavn Colorful Gables & Little Mermaid Harbor", 55.6761, 12.5683],
				["Helsingør (Kronborg)", "North Zealand", "loire_chateau", "Kronborg Coastal Bastion Castle", 56.0390, 12.6216],
				["Aarhus", "East Jutland", "astral_observatory", "ARoS Rainbow Panorama & Den Gamle By", 56.1629, 10.2039],
				["Aalborg", "Limfjord", "glacier_bridge", "Utzon Center & Limfjord Waterfront", 57.0488, 9.9217],
				["Skagen (Grenen)", "North Jutland", "lighthouse_landmark", "Rubjerg Knude & Skagen Grey Lighthouse", 57.7209, 10.5839]
			]),
		# Page 57 (idx 56, 7 levels): COSTA RICA — West-to-East Nicoya Pacific to Caribbean Tortuguero
		_make_country_entry("costa_rica", "Costa Rica", "Costa Rica", "west_to_east",
			"essential COSTA RICA (visitcostarica.com) — Pacific Coast to Volcanoes & Caribbean",
			"Cordillera de Talamanca", "Central Range", 9.5000, -83.6500, [
				["Tamarindo & Nicoya", "Guanacaste", "lighthouse_landmark", "Pacific Surf Headland & Sunset Cove", 10.2993, -85.8371],
				["Monteverde", "Puntarenas", "glacier_bridge", "Cloud Forest Hanging Canopy Bridges", 10.3009, -84.8089],
				["Arenal Volcano (La Fortuna)", "Alajuela", "grand_canyon_rim", "Symmetrical Arenal Volcanic Cone & Waterfall", 10.4626, -84.7032],
				["Manuel Antonio", "Central Pacific", "halong_karst_harbor", "Cathedral Point Headland & Twin White Bays", 9.3923, -84.1369],
				["San José & Poás", "Central Valley", "florence_duomo", "National Theatre Neoclassical Dome & Crater", 9.9281, -84.0907],
				["Cartago & Irazú", "Central Highlands", "florence_duomo", "Basilica de los Ángeles & Emerald Crater Lake", 9.8644, -83.9194],
				["Tortuguero & Puerto Viejo", "Limón Caribbean", "mekong_floating_market", "Rainforest Canal Boats & Caribbean Reef", 10.5422, -83.5025]
			]),
		# Page 58 (idx 57, 10 levels): MYANMAR — North-to-South Irrawaddy Valley to Mergui Archipelago
		_make_country_entry("myanmar", "Myanmar", "Myanmar", "north_to_south",
			"Myanmar Tourism — Mandalay & Bagan down the Irrawaddy to Yangon & Southern Coast",
			"Shan Plateau", "Eastern Highlands", 21.0000, 97.0000, [
				["Monywa", "Chindwin Valley", "chureito_pagoda", "Thanboddhay Thousand-Spire Golden Stupa", 22.1086, 95.1358],
				["Mingun", "Sagaing", "chureito_pagoda", "Hsinbyume White Wavy-Terrace Pagoda", 22.0519, 96.0178],
				["Pyin Oo Lwin", "Shan Foothills", "pisa_tower", "Purcell Clock Tower & Goteik Viaduct", 22.0350, 96.4568],
				["Mandalay", "Upper Irrawaddy", "glacier_bridge", "U Bein Teakwood Bridge & Royal Moat", 21.9588, 96.0891],
				["Bagan", "Mandalay Plains", "chureito_pagoda", "Ananda Temple & Ancient Red-Brick Stupa Plain", 21.1717, 94.8585],
				["Mount Popa", "Myingyan", "mont_saint_michel", "Taung Kalat Volcanic Plug Golden Monastery", 20.9178, 95.2078],
				["Inle Lake", "Shan State", "mekong_floating_market", "Phaung Daw Oo Pagoda & Leg-Rowing Boats", 20.5500, 96.9167],
				["Kyaiktiyo (Golden Rock)", "Mon State", "chureito_pagoda", "Gilded Boulder Pagoda on Granite Cliff", 17.4817, 97.0981],
				["Bago", "Lower Plains", "chureito_pagoda", "Shwemawdaw Tallest Golden Stupa", 17.3368, 96.4797],
				["Yangon", "Irrawaddy Delta", "chureito_pagoda", "Shwedagon Great Diamond-Tipped Golden Stupa", 16.7983, 96.1496]
			]),
		# Page 59 (idx 58, 6 levels): HUNGARY — West-to-East Lake Balaton to Budapest & Hortobágy
		_make_country_entry("hungary", "Hungary", "Hungary", "west_to_east",
			"Visit Hungary (visithungary.com) — Transdanubia & Balaton to Danube Bend & Eger",
			"Bükk Mountains", "Northern Uplands", 48.0800, 20.5000, [
				["Sopron & Fertőd", "Western Transdanubia", "versailles_palace", "Esterházy Rococo Palace & Firewatch Tower", 47.6214, 16.8722],
				["Tihany (Lake Balaton)", "Balaton Uplands", "florence_duomo", "Tihany Twin-Spire Abbey above Turquoise Lake", 46.9139, 17.8892],
				["Esztergom & Visegrád", "Danube Bend", "florence_duomo", "Esztergom Giant Classical Basilica Dome", 47.7989, 18.7364],
				["Budapest", "Central Danube", "versailles_palace", "Hungarian Parliament Neo-Gothic Dome & Chain Bridge", 47.5071, 19.0457],
				["Eger", "Heves Hills", "loire_chateau", "Eger Hilltop Castle & Baroque Basilica", 47.9025, 20.3772],
				["Debrecen & Hortobágy", "Great Plain", "glacier_bridge", "Nine-Arch Stone Bridge & Great Reformed Church", 47.5836, 21.1517]
			]),
		# Page 60 (idx 59, 8 levels): SOUTH AFRICA — South-to-North Cape Peninsula to Kruger
		_make_country_entry("south_africa", "South Africa", "Nam Phi", "south_to_north",
			"South African Tourism (southafrica.net) — Cape of Good Hope to Drakensberg & Kruger",
			"Drakensberg Amphitheatre", "KwaZulu-Natal", -28.7567, 28.8944, [
				["Cape Point", "Cape Peninsula", "lighthouse_landmark", "Cape of Good Hope Cliffs & Lighthouse", -34.3568, 18.4970],
				["Knysna (Garden Route)", "Western Cape", "halong_karst_harbor", "Knysna Heads Sandstone Lagoon Cliffs", -34.0363, 23.0472],
				["Stellenbosch & Franschhoek", "Cape Winelands", "tuscany_villa", "Cape Dutch White Gables & Vineyards", -33.9321, 18.8602],
				["Cape Town", "Table Bay", "grand_canyon_rim", "Table Mountain Flat-Top Massif & Bo-Kaap", -33.9249, 18.4241],
				["Durban & uShaka", "Indian Ocean Coast", "golden_gate", "Moses Mabhida Sky Arch & Golden Mile", -29.8587, 31.0218],
				["Johannesburg & Pretoria", "Gauteng", "manhattan_skyline", "Union Buildings Terraced Acropolis & Nelson Mandela Bridge", -25.7402, 28.2120],
				["Blyde River Canyon", "Mpumalanga", "grand_canyon_rim", "Three Rondavels Green Canyon Buttes", -24.5611, 30.8069],
				["Kruger National Park", "Lowveld", "tuscany_villa", "Sabie River Safari Bridge & Baobab Ridge", -23.9884, 31.5547]
			]),
		# Page 61 (idx 60, 6 levels): CUBA — West-to-East Viñales to Havana, Trinidad & Santiago
		_make_country_entry("cuba", "Cuba", "Cuba", "west_to_east",
			"Ministerio de Turismo de Cuba — Western Mogotes to Havana & Eastern Oriente",
			"Sierra Maestra", "Granma", 19.9900, -76.8350, [
				["Viñales Valley", "Pinar del Río", "halong_karst_harbor", "Limestone Mogote Domes & Tobacco Bohíos", 22.6169, -83.7078],
				["Havana", "Northwest Coast", "versailles_palace", "El Capitolio Dome, Malecón & Morro Lighthouse", 23.1353, -82.3589],
				["Varadero & Matanzas", "Hicacos Peninsula", "glacier_bridge", "Bacunayagua Gorge Bridge & Turquoise Spit", 23.1536, -81.2514],
				["Cienfuegos", "Jagwa Bay", "versailles_palace", "Palacio de Valle Moorish Turrets", 22.1461, -80.4356],
				["Trinidad", "Sancti Spíritus", "pisa_tower", "Plaza Mayor Yellow Bell Tower & Cobblestones", 21.8022, -79.9842],
				["Santiago de Cuba", "Oriente Coast", "loire_chateau", "San Pedro de la Roca Clifftop Sea Castle", 19.9686, -75.8703]
			]),
		# Page 62 (idx 61, 7 levels): TAIWAN — North-to-South Taipei across Sun Moon Lake to Kenting
		_make_country_entry("taiwan", "Taiwan", "Đài Loan", "north_to_south",
			"Taiwan Tourism Administration (taiwan.net.tw) — North-to-South Island High-Speed & Mountain Route",
			"Yushan (Jade Mountain)", "Central Range", 23.4700, 120.9572, [
				["Jiufen & Yehliu", "North Coast", "hoian_covered_bridge_lanterns", "Red-Lantern Cliffside Teahouses & Queen's Head Rock", 25.1096, 121.8452],
				["Taipei", "Taipei Basin", "tokyo_tower", "Taipei 101 Bamboo-Tiered Skyscraper & Chiang Kai-shek Hall", 25.0339, 121.5645],
				["Taroko Gorge", "Hualien", "grand_canyon_rim", "Eternal Spring Shrine & Marble Canyon Bridge", 24.1611, 121.6025],
				["Sun Moon Lake", "Nantou", "chureito_pagoda", "Ci'en Pagoda & Wenwu Lakeside Temple", 23.8522, 120.9158],
				["Alishan", "Chiayi Highlands", "torii_shrine", "Sacred Red Cypress Forest Railway & Sea of Clouds", 23.5103, 120.8025],
				["Tainan & Kaohsiung", "Southwest Coast", "chureito_pagoda", "Lotus Pond Dragon & Tiger Twin Pagodas", 22.6797, 120.2922],
				["Kenting (Eluanbi)", "Hengchun Peninsula", "lighthouse_landmark", "Eluanbi White Southernmost Lighthouse", 21.9022, 120.8525]
			]),
		# Page 63 (idx 62, 8 levels): SLOVENIA — West-to-East Adriatic & Julian Alps to Ptuj
		_make_country_entry("slovenia", "Slovenia", "Slovenia", "west_to_east",
			"Slovenian Tourist Board (slovenia.info) — Adriatic Coast & Julian Alps to Pannonian East",
			"Mount Triglav", "Julian Alps", 46.3783, 13.8367, [
				["Bovec (Soča Valley)", "Gorizia", "glacier_bridge", "Solkan Turquoise Stone Arch & Emerald Rapids", 46.3381, 13.5525],
				["Piran", "Adriatic Istria", "venice_canal", "Tartini Square Venetian Campanile on Sea Peninsula", 45.5283, 13.5683],
				["Lake Bled", "Upper Carniola", "alpine_village", "Bled Island Church Spire, Pletna Boat & Cliff Castle", 46.3625, 14.0936],
				["Postojna & Predjama", "Inner Carniola", "mont_saint_michel", "Predjama Cave Mouth Cliff Castle", 45.8158, 14.1267],
				["Ljubljana", "Ljubljana Basin", "glacier_bridge", "Triple Bridge, Dragon Bridge & Hilltop Castle", 46.0514, 14.5061],
				["Kamnik & Velika Planina", "Kamnik Alps", "alpine_chalet", "Oval Wooden Herdsmen Huts on Alpine Plateau", 46.2942, 14.6556],
				["Celje", "Styria", "loire_chateau", "Celje Upper Castle Watchtower above Savinja", 46.2225, 15.2697],
				["Maribor & Ptuj", "Drava Valley", "loire_chateau", "Ptuj Red-Roofed Hilltop Castle & Drava Bridge", 46.4203, 15.8697]
			]),
		# Page 64 (idx 63, 9 levels): GEORGIA — West-to-East Black Sea to Caucasus & Kakheti
		_make_country_entry("georgia", "Georgia", "Gruzia", "west_to_east",
			"Georgian National Tourism Administration (georgia.travel) — Batumi to Tbilisi & Kakheti",
			"Mount Kazbek", "Greater Caucasus", 42.6969, 44.5186, [
				["Batumi", "Adjara Black Sea", "tokyo_tower", "Alphabetic Tower, Ali & Nino Pier & Seafront", 41.6558, 41.6394],
				["Kutaisi", "Imereti", "florence_duomo", "Bagrati Turquoise-Roofed Cathedral & Gelati", 42.2772, 42.7044],
				["Mestia & Ushguli", "Svaneti Caucasus", "pisa_tower", "Medieval Svan Stone Defense Towers & Glaciers", 43.0444, 42.7267],
				["Vardzia", "Samtskhe-Javakheti", "abu_simbel", "Multi-Tiered Cave Monastery in Erusheti Cliff", 41.3811, 43.2842],
				["Borjomi & Rabati", "Mtkvari Gorge", "loire_chateau", "Rabati Castle Domes & Mineral Park Pavilion", 41.8419, 43.3831],
				["Gori (Uplistsikhe)", "Shida Kartli", "grand_canyon_rim", "Uplistsikhe Rock-Hewn Town above River", 41.9672, 44.2078],
				["Mtskheta & Ananuri", "Aragvi Valley", "mont_saint_michel", "Jvari Conical Stone Dome & Ananuri Lake Fortress", 41.8383, 44.7336],
				["Tbilisi", "Kura Valley", "glacier_bridge", "Narikala Fortress, Bridge of Peace & Sulfur Baths", 41.6938, 44.8015],
				["Sighnaghi (Kakheti)", "Alazani Valley", "loire_chateau", "Walled Hilltop City of Love & Bodbe Spire", 41.6186, 45.9219]
			]),
		# Page 65 (idx 64, 5 levels): UZBEKISTAN — West-to-East Silk Road Oasis Cities
		_make_country_entry("uzbekistan", "Uzbekistan", "Uzbekistan", "west_to_east",
			"Uzbekistan Tourism Committee (uzbekistan.travel) — Khiva to Tashkent Silk Road",
			"Chimgan Mountains", "Western Tian Shan", 41.5333, 70.0333, [
				["Khiva (Itchan Kala)", "Khorezm Oasis", "pisa_tower", "Kalta Minor Turquoise-Tiled Minaret & Walls", 41.3775, 60.3594],
				["Bukhara", "Zeravshan Delta", "florence_duomo", "Po-i-Kalyan Minaret & Mir-i-Arab Blue Domes", 39.7747, 64.4286],
				["Shakhrisabz", "Kashkadarya", "karnak_temple", "Ak-Saray Mosaic Portal Towers", 39.0578, 66.8342],
				["Samarkand", "Zeravshan Valley", "florence_duomo", "Registan Three Majolica Madrasahs & Azure Domes", 39.6547, 66.9758],
				["Tashkent", "Chirchiq Oasis", "tokyo_tower", "Hazrati Imam Turquoise Domes & Tashkent Tower", 41.2995, 69.2401]
			]),
		# Page 66 (idx 65, 8 levels): MONGOLIA — West-to-East Altai Peaks to Ulaanbaatar & Khentii
		_make_country_entry("mongolia", "Mongolia", "Mông Cổ", "west_to_east",
			"Visit Mongolia (mongolia.travel) — Altai Mountains across Steppe to Khentii",
			"Gobi Gurvansaikhan", "Omnogovi", 43.6167, 104.0167, [
				["Altai Tavan Bogd (Bayan-Ölgii)", "Mongolian Altai", "zermatt_sanctuary", "Snow Peaks & Golden Eagle Kazakh Gers", 49.1458, 87.8189],
				["Khyargas & Uvs Lakes", "Great Lakes Basin", "halong_karst_harbor", "Turquoise Steppe Lake & Sand Spit", 49.1833, 93.3167],
				["Khorgo & Terkhiin Tsagaan", "Arkhangai", "grand_canyon_rim", "Volcanic Basalt Crater & White Lake", 48.1819, 99.8556],
				["Lake Khövsgöl", "Northern Taiga", "alpine_chalet", "Blue Pearl Alpine Lake & Larch Forest", 51.0967, 100.4783],
				["Kharkhorin (Erdene Zuu)", "Orkhon Valley", "chureito_pagoda", "Erdene Zuu 108 White Stupa Walls", 47.2014, 102.8431],
				["Bayan Gobi (Elsen Tasarkhai)", "Ovorkhangai", "giza_sphinx", "Steppe Sand Dunes & Nomadic Ger Camp", 47.3833, 103.6500],
				["Ulaanbaatar", "Tuul Valley", "kyoto_temple", "Gandantegchinlen Golden Roof & Sukhbaatar Square", 47.9184, 106.9177],
				["Tsonjin Boldog (Terelj)", "Khentii Foothills", "statue_of_liberty", "Giant Equestrian Statue & Turtle Rock", 47.8081, 107.5297]
			]),
		# Page 67 (idx 66, 7 levels): ECUADOR — West-to-East Galápagos across Avenue of Volcanoes to Amazon
		_make_country_entry("ecuador", "Ecuador", "Ecuador", "west_to_east",
			"Ministerio de Turismo del Ecuador (ecuador.travel) — Galápagos to Andes & Amazon",
			"Chimborazo Summit", "Central Andes", -1.4693, -78.8169, [
				["Galápagos (Santa Cruz & Bartolomé)", "Pacific Archipelago", "halong_karst_harbor", "Pinnacle Rock Volcanic Cone & Tortoise Bay", -0.2842, -90.5536],
				["Guayaquil", "Guayas River", "lighthouse_landmark", "Santa Ana Hill Lighthouse & Malecón 2000", -2.1894, -79.8891],
				["Cuenca", "Southern Highlands", "florence_duomo", "New Cathedral Three Sky-Blue Tiled Domes", -2.8974, -79.0045],
				["Quito & Mitad del Mundo", "Pichincha Valley", "luxor_obelisk", "Equatorial Monument & Basilica del Voto Nacional", -0.2202, -78.5123],
				["Cotopaxi & Quilotoa", "Avenue of Volcanoes", "zermatt_sanctuary", "Snow-Capped Cotopaxi Cone & Emerald Crater", -0.6838, -78.4372],
				["Baños & Tena", "Amazon Gateway", "grand_canyon_rim", "Pailón del Diablo Gorge Waterfall & Pastaza Bridge", -1.3964, -78.4247],
				["Otavalo (Cuicocha)", "Imbabura", "tuscany_villa", "Crater Lake Islands & Andean Plaza", 0.2343, -78.2611]
			]),
		# Page 68 (idx 67, 6 levels): BOLIVIA — North-to-South Lake Titicaca across Altiplano to Uyuni
		_make_country_entry("bolivia", "Bolivia", "Bolivia", "north_to_south",
			"Viceministerio de Turismo Bolivia — Titicaca to Salar de Uyuni & Laguna Colorada",
			"Illimani Three-Peak Massif", "Cordillera Real", -16.6539, -67.7847, [
				["Copacabana (Isla del Sol)", "Lake Titicaca", "karnak_temple", "Inca Stone Steps & White Moorish Basilica", -16.1664, -69.0861],
				["La Paz & Tiwanaku", "Murillo Canyon", "abu_simbel", "Kalasasaya Sun Gate & Mi Teleférico Cableways", -16.5000, -68.1500],
				["Oruro & Sajama", "Central Altiplano", "zermatt_sanctuary", "Sajama Snow Cone & Socavón Sanctuary", -17.9647, -67.1060],
				["Sucre", "Chuquisaca", "versailles_palace", "Whitewashed Recoleta Arches & House of Liberty", -19.0478, -65.2596],
				["Potosí", "Tomás Frías", "florence_duomo", "Cerro Rico Silver Peak & Casa de la Moneda", -19.5836, -65.7531],
				["Salar de Uyuni & Laguna Colorada", "Southwest Altiplano", "astral_observatory", "Mirror Salt Flats, Incahuasi Cactus Island & Red Lagoon", -20.1338, -67.4891]
			])
	]


static func _get_all_68_country_manifests() -> Array[Dictionary]:
	var all_list: Array[Dictionary] = []
	all_list.append_array(_get_country_manifests_part_a())
	all_list.append_array(_get_country_manifests_part_b())
	all_list.append_array(_get_country_manifests_part_c())
	return all_list


## Recalculates and validates geographic order directly from stored latitude/longitude
## (NEVER uses screen/UV/relaxed positions) and checks manifest-to-level sequence consistency.
static func validate_country_page_geography(page: MapPage) -> Dictionary:
	if page == null:
		return {"valid": false, "error": "null_page"}
	var j_dir: String = page.journey_direction
	var dests: Array[Dictionary] = page.country_destinations
	var act_dests: Array[Dictionary] = page.active_level_destinations
	var omit_dests: Array[Dictionary] = page.omitted_destinations
	var lv_cnt: int = page.get_level_count()
	var errors: Array[String] = []

	if page.country_id == "" or page.country_name_en == "":
		errors.append("missing_country_identity")
	if not (j_dir in ["north_to_south", "south_to_north", "west_to_east", "east_to_west"]):
		errors.append("invalid_journey_direction:%s" % j_dir)
	if page.authority_source.strip_edges().length() < 8:
		errors.append("missing_authority_source")
	if dests.size() < lv_cnt:
		errors.append("insufficient_country_destinations:%d<%d" % [dests.size(), lv_cnt])

	# 1. Validate uniqueness and strict stored latitude/longitude progression across country_destinations
	var seen_dest_names: Dictionary = {}
	var dest_names: Array[String] = []
	var coord_pairs: Array[Dictionary] = []
	var included_count: int = 0
	var omitted_count: int = 0

	for i in range(dests.size()):
		var d: Dictionary = dests[i]
		var d_name: String = String(d.get("destination_name", ""))
		var d_ord: int = int(d.get("destination_order", -1))
		var lat: float = float(d.get("lat", 0.0))
		var lon: float = float(d.get("lon", 0.0))
		dest_names.append(d_name)
		coord_pairs.append({"name": d_name, "lat": lat, "lon": lon, "order": d_ord})
		if d_name == "" or seen_dest_names.has(d_name):
			errors.append("duplicate_or_empty_destination:%s" % d_name)
		seen_dest_names[d_name] = true
		if d_ord != i + 1:
			errors.append("destination_order_mismatch_at_%d:got_%d" % [i, d_ord])
		if not d.has("included_in_level_sequence"):
			errors.append("missing_included_in_level_sequence_flag:%s" % d_name)
		elif bool(d.get("included_in_level_sequence", false)):
			included_count += 1
		else:
			omitted_count += 1
			if String(d.get("omission_reason", "")).strip_edges() == "":
				errors.append("silently_skipped_destination_missing_reason:%s" % d_name)

		if i < dests.size() - 1:
			var d_next: Dictionary = dests[i + 1]
			var lat2: float = float(d_next.get("lat", 0.0))
			var lon2: float = float(d_next.get("lon", 0.0))
			var next_name: String = String(d_next.get("destination_name", ""))
			var coord_ok: bool = false
			match j_dir:
				"north_to_south":
					coord_ok = (lat > lat2)
				"south_to_north":
					coord_ok = (lat < lat2)
				"west_to_east":
					coord_ok = (lon < lon2)
				"east_to_west":
					coord_ok = (lon > lon2)
			if not coord_ok:
				errors.append("coord_order_violation:%s(%.4f,%.4f)->%s(%.4f,%.4f)_for_%s" % [
					d_name, lat, lon, next_name, lat2, lon2, j_dir
				])

	# 2. Validate Manifest / Level Sequence Reconciliation (zero silent omissions!)
	var level_consistent: bool = true
	if act_dests.size() != lv_cnt:
		level_consistent = false
		errors.append("active_level_destinations_size_mismatch:%d!=%d" % [act_dests.size(), lv_cnt])
	if act_dests.size() + omit_dests.size() != dests.size():
		level_consistent = false
		errors.append("unreconciled_destinations:active(%d)+omitted(%d)!=total(%d)" % [
			act_dests.size(), omit_dests.size(), dests.size()
		])
	if included_count != lv_cnt or omitted_count != omit_dests.size():
		level_consistent = false
		errors.append("included_omitted_flag_mismatch:included=%d,omitted=%d" % [included_count, omitted_count])

	# 3. Validate active level nodes match active_level_destinations and strictly follow lat/lon order
	var featured_lm_cnt: int = 0
	var milestone_contexts: Array[String] = []
	if not page.nodes.is_empty():
		if page.nodes.size() != lv_cnt:
			level_consistent = false
			errors.append("page_nodes_count_mismatch:%d!=%d" % [page.nodes.size(), lv_cnt])
		for n_i in range(page.nodes.size()):
			var nd: MapNode = page.nodes[n_i]
			var lm: Dictionary = nd.landmark
			var nd_name: String = String(lm.get("destination_name", ""))
			var exp_name: String = String(act_dests[n_i].get("destination_name", "")) if n_i < act_dests.size() else ""
			if nd_name != exp_name:
				level_consistent = false
				errors.append("node_%d_destination_mismatch:got_%s_expected_%s" % [n_i, nd_name, exp_name])
			var m_ctx: String = String(lm.get("milestone_context", ""))
			milestone_contexts.append(m_ctx)
			if not ["major_landmark", "landmark_environment", "regional_scene", "small_destination_marker"].has(m_ctx):
				errors.append("invalid_milestone_context_at_%d:%s" % [n_i, m_ctx])
			if m_ctx == "major_landmark" or m_ctx == "landmark_environment":
				featured_lm_cnt += 1
			if n_i < page.nodes.size() - 1:
				var lm_next: Dictionary = page.nodes[n_i + 1].landmark
				var n_lat1: float = float(lm.get("lat", 0.0))
				var n_lon1: float = float(lm.get("lon", 0.0))
				var n_lat2: float = float(lm_next.get("lat", 0.0))
				var n_lon2: float = float(lm_next.get("lon", 0.0))
				var n_ok: bool = false
				match j_dir:
					"north_to_south": n_ok = (n_lat1 > n_lat2)
					"south_to_north": n_ok = (n_lat1 < n_lat2)
					"west_to_east": n_ok = (n_lon1 < n_lon2)
					"east_to_west": n_ok = (n_lon1 > n_lon2)
				if not n_ok:
					errors.append("active_node_coord_violation_at_%d" % n_i)
		if not ["very_rich", "rich", "moderate", "sparse"].has(page.landmark_density):
			errors.append("invalid_landmark_density:%s" % page.landmark_density)
		if featured_lm_cnt >= lv_cnt:
			errors.append("excessive_1_to_1_landmark_density:%d_of_%d" % [featured_lm_cnt, lv_cnt])

	var geo_ok: bool = errors.is_empty()
	return {
		"page_number": page.page_number,
		"country_id": page.country_id,
		"country": page.country_name_en,
		"journey_direction": j_dir,
		"landmark_density": page.landmark_density,
		"featured_landmark_count": featured_lm_cnt,
		"milestone_contexts": milestone_contexts,
		"destination_count": dests.size(),
		"active_level_count": lv_cnt,
		"omitted_destination_count": omit_dests.size(),
		"destination_names": dest_names,
		"coordinates": coord_pairs,
		"geographic_order_valid": geo_ok,
		"level_sequence_consistent": level_consistent and errors.is_empty(),
		"landmark_density_consistent": errors.is_empty(),
		"research_source_status": "VERIFIED (%s)" % page.authority_source if page.authority_source != "" else "MISSING",
		"errors": errors,
		"valid": geo_ok and level_consistent
	}


static func audit_all_68_country_journeys(map_data: MapData) -> Dictionary:
	var reports: Array[Dictionary] = []
	var seen_countries: Dictionary = {}
	var duplicate_countries: Array[String] = []
	var invalid_pages: Array[int] = []
	for p_i in range(map_data.get_page_count()):
		var pg: MapPage = map_data.get_page(p_i)
		if seen_countries.has(pg.country_id):
			duplicate_countries.append(pg.country_id)
		seen_countries[pg.country_id] = true
		var rep: Dictionary = validate_country_page_geography(pg)
		if not bool(rep.get("valid", false)):
			invalid_pages.append(pg.page_number)
		reports.append(rep)
	return {
		"total_pages": map_data.get_page_count(),
		"unique_countries": seen_countries.size(),
		"duplicate_countries": duplicate_countries,
		"invalid_pages": invalid_pages,
		"all_valid": invalid_pages.is_empty() and duplicate_countries.is_empty() and seen_countries.size() == 68,
		"page_reports": reports
	}


static func validate_country_background_registry(map_data: MapData = null) -> Dictionary:
	var md: MapData = map_data if map_data != null else build_block_puzzle_map_data(TOTAL_LEVELS)
	var reg: Dictionary = get_country_background_registry()
	var missing_countries: Array[String] = []
	var cross_country_refs: Array[String] = []
	var missing_levels: Array[int] = []
	var destination_selections: int = 0
	var inconsistent_countries: Array[String] = []
	var single_landmark_countries: Array[String] = []
	var missing_hierarchy_countries: Array[String] = []
	var canonical_ids_seen: Dictionary = {}
	var distinct_landmark_counts: Dictionary = {}

	for c_id in reg.keys():
		var entry: Dictionary = reg[c_id]
		var bg_id: String = String(entry.get("canonical_background_id", ""))
		var entry_cid: String = String(entry.get("country_id", ""))
		if bg_id == "" or bg_id != "%s_canonical_country_bg" % c_id:
			missing_countries.append(c_id)
		if entry_cid != c_id or not bg_id.begins_with(c_id + "_"):
			cross_country_refs.append(c_id)
		if bool(entry.get("uses_destination_selection", false)):
			destination_selections += 1
		var comp_lms: Array = entry.get("composition_landmarks", [])
		var lm_cnt: int = comp_lms.size()
		distinct_landmark_counts[lm_cnt] = true
		if lm_cnt < 2 or bool(entry.get("is_single_landmark_only", false)):
			single_landmark_countries.append(c_id)
		if not bool(entry.get("has_visual_hierarchy", false)):
			missing_hierarchy_countries.append(c_id)
		for clm in comp_lms:
			if String(clm.get("country_id", "")) != c_id:
				cross_country_refs.append("%s:%s" % [c_id, String(clm.get("landmark_id", ""))])
		canonical_ids_seen[bg_id] = true

	var vn_entry: Dictionary = reg.get("vietnam", {})
	var vn_lms: Array = vn_entry.get("landmark_ids", [])
	var vn_required_lms: Array[String] = [
		"halong_karst_harbor",
		"hanoi_hoan_kiem_pagoda",
		"hue_imperial_citadel",
		"hoian_covered_bridge_lanterns",
		"saigon_bitexco_skyline",
		"mekong_floating_market"
	]
	var vn_has_all_rich_landmarks: bool = true
	for req_vn_lm in vn_required_lms:
		if not vn_lms.has(req_vn_lm):
			vn_has_all_rich_landmarks = false
			break

	for p_i in range(md.get_page_count()):
		var pg: MapPage = md.get_page(p_i)
		if not reg.has(pg.country_id):
			missing_countries.append(pg.country_id)
			continue
		var expected_bg_id: String = String(reg[pg.country_id].get("canonical_background_id", ""))
		for lv in pg.level_ids:
			var lv_page: MapPage = md.get_page_for_level(lv)
			if lv_page == null or lv_page.country_id != pg.country_id:
				inconsistent_countries.append(pg.country_id)
				continue
			var lv_bg: Dictionary = get_canonical_country_background(lv_page.country_id)
			var lv_bg_id: String = String(lv_bg.get("canonical_background_id", ""))
			if lv_bg_id != expected_bg_id:
				inconsistent_countries.append(pg.country_id)

	for lv in range(1, TOTAL_LEVELS + 1):
		var pg_lv: MapPage = md.get_page_for_level(lv)
		if pg_lv == null or not reg.has(pg_lv.country_id):
			missing_levels.append(lv)
			continue
		var bg_entry: Dictionary = reg[pg_lv.country_id]
		if String(bg_entry.get("country_id", "")) != pg_lv.country_id:
			cross_country_refs.append("%d:%s" % [lv, pg_lv.country_id])
		if bool(bg_entry.get("uses_destination_selection", false)):
			destination_selections += 1

	return {
		"valid": (
			reg.size() == 68 and
			canonical_ids_seen.size() == 68 and
			missing_countries.is_empty() and
			cross_country_refs.is_empty() and
			missing_levels.is_empty() and
			inconsistent_countries.is_empty() and
			single_landmark_countries.is_empty() and
			missing_hierarchy_countries.is_empty() and
			vn_has_all_rich_landmarks and
			distinct_landmark_counts.size() >= 3 and
			destination_selections == 0
		),
		"country_count": reg.size(),
		"unique_canonical_background_count": canonical_ids_seen.size(),
		"resolved_level_count": TOTAL_LEVELS - missing_levels.size(),
		"missing_country_backgrounds": missing_countries,
		"cross_country_references": cross_country_refs,
		"missing_levels": missing_levels,
		"inconsistent_countries": inconsistent_countries,
		"single_landmark_countries": single_landmark_countries,
		"missing_hierarchy_countries": missing_hierarchy_countries,
		"vietnam_has_rich_multi_landmark_composition": vn_has_all_rich_landmarks,
		"vietnam_landmark_ids": vn_lms,
		"distinct_landmark_count_tiers": distinct_landmark_counts.size(),
		"destination_specific_selections": destination_selections
	}





