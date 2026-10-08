class_name SpecialItemsBar
extends Control

## SpecialItemsBar — Modern Game Mode tactile 3D booster toolbar UI with custom original 4TM visual medallions.
## Contains EXACTLY 3 items:
##   1. "bomb"         -> 💣 BOMB × N (3D spherical bomb medallion + burning fuse spark)
##   2. "change_block" -> 🔄 CHANGE BLOCK × N (Twin 3D crystal blocks + swap arrows medallion)
##   3. "extra_life"   -> ❤️ EXTRA LIFE × N (3D ruby heart shield + golden rescue cross medallion)
## There is NO Rotate item. Visible ONLY in Modern mode; hidden in Classic mode.

signal item_clicked(item_id: String)
signal item_ad_opened(item_id: String, session_id: String)
signal item_ad_completed(item_id: String, new_quantity: int)
signal item_ad_skipped(item_id: String)

const ITEM_TYPES: Array[String] = ["bomb", "change_block", "extra_life"]
const UIIconScript = preload("res://scripts/ui/ui_icon.gd")
const GameTypographyScript = preload("res://scripts/ui/game_typography.gd")

const DEFAULT_INVENTORY: Dictionary = {
	"bomb": 2,
	"change_block": 2,
	"extra_life": 1
}


class BoosterMedallionIcon extends Control:
	var item_type: String = "bomb"
	var is_active_selected: bool = false
	var is_item_disabled: bool = false

	func _init(p_type: String = "bomb") -> void:
		item_type = p_type
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(38, 38)
		size = Vector2(38, 38)

	func set_state(selected: bool, disabled_state: bool) -> void:
		is_active_selected = selected
		is_item_disabled = disabled_state
		queue_redraw()

	func _draw() -> void:
		var c := Vector2(20.0, size.y * 0.5 if size.y > 10.0 else 24.0)
		var r := 15.5
		# Outer 3D medallion ring
		var ring_col := Color(1.0, 0.94, 0.36, 1.0) if is_active_selected else Color(1.0, 1.0, 1.0, 0.88)
		if is_item_disabled:
			ring_col = Color(0.65, 0.68, 0.78, 0.55)
		draw_circle(c + Vector2(0, 2.0), r + 1.5, Color(0.04, 0.06, 0.18, 0.52))
		draw_circle(c, r + 1.5, ring_col)

		match item_type:
			"bomb":
				# Deep crimson-violet medallion backdrop
				draw_circle(c, r - 1.0, Color(0.24, 0.08, 0.26, 0.96))
				# 3D spherical bomb body
				var b_pos := c + Vector2(-1.5, 2.0)
				draw_circle(b_pos, 8.8, Color(0.14, 0.16, 0.28, 1.0))
				draw_circle(b_pos, 7.6, Color(0.22, 0.26, 0.44, 1.0))
				# Gloss highlight on bomb sphere
				draw_circle(b_pos + Vector2(-2.8, -2.8), 2.6, Color(0.85, 0.94, 1.0, 0.85))
				# Fuse cap & golden curved fuse
				draw_rect(Rect2(b_pos + Vector2(3.5, -8.5), Vector2(4.0, 3.5)), Color(0.82, 0.74, 0.48, 1.0), true)
				var spark_pos := b_pos + Vector2(8.2, -9.2)
				draw_line(b_pos + Vector2(5.5, -7.0), spark_pos, Color(1.0, 0.82, 0.28, 1.0), 2.2)
				# Burning 4TM spark star
				draw_circle(spark_pos, 3.6, Color(1.0, 0.48, 0.12, 1.0))
				draw_circle(spark_pos, 2.0, Color(1.0, 0.96, 0.45, 1.0))
			"change_block":
				# Deep sapphire medallion backdrop
				draw_circle(c, r - 1.0, Color(0.08, 0.22, 0.48, 0.96))
				# Two mini 3D bevelled crystal blocks (Cyan top-left, Gold bottom-right)
				var b1 := Rect2(c + Vector2(-9.5, -8.5), Vector2(9.0, 9.0))
				var b2 := Rect2(c + Vector2(0.5, -0.5), Vector2(9.0, 9.0))
				draw_rect(b1, Color(0.12, 0.88, 1.0, 1.0), true)
				draw_rect(b1.grow(-1.8), Color(0.58, 0.98, 1.0, 1.0), true)
				draw_rect(b2, Color(1.0, 0.78, 0.14, 1.0), true)
				draw_rect(b2.grow(-1.8), Color(1.0, 0.94, 0.52, 1.0), true)
				# Curved swap arrows in corners
				draw_arc(c, 11.2, -PI * 0.15, PI * 0.35, 10, Color(1.0, 0.96, 0.42, 1.0), 2.2)
				draw_arc(c, 11.2, PI * 0.85, PI * 1.35, 10, Color(0.48, 1.0, 0.82, 1.0), 2.2)
			"extra_life":
				# Deep emerald-ruby medallion backdrop
				draw_circle(c, r - 1.0, Color(0.08, 0.34, 0.26, 0.96))
				# 3D Ruby Heart shape (2 top lobes + bottom triangle)
				var hc := c + Vector2(0, 1.0)
				var heart_col := Color(0.98, 0.22, 0.46, 1.0)
				draw_circle(hc + Vector2(-4.4, -3.2), 5.2, heart_col)
				draw_circle(hc + Vector2(4.4, -3.2), 5.2, heart_col)
				var tri := PackedVector2Array([
					hc + Vector2(-9.2, -1.2),
					hc + Vector2(9.2, -1.2),
					hc + Vector2(0.0, 9.2)
				])
				draw_colored_polygon(tri, heart_col)
				# Gloss & white-gold rescue cross inside heart
				draw_rect(Rect2(hc + Vector2(-1.4, -4.2), Vector2(2.8, 7.6)), Color(1.0, 0.98, 0.82, 0.95), true)
				draw_rect(Rect2(hc + Vector2(-3.8, -1.8), Vector2(7.6, 2.8)), Color(1.0, 0.98, 0.82, 0.95), true)


@onready var btn_bomb: Button = get_node_or_null("MarginContainer/HBoxContainer/BtnBomb")
@onready var btn_change_block: Button = get_node_or_null("MarginContainer/HBoxContainer/BtnChangeBlock")
@onready var btn_extra_life: Button = get_node_or_null("MarginContainer/HBoxContainer/BtnExtraLife")

var btn_bomb_plus: Button = null
var btn_change_block_plus: Button = null
var btn_extra_life_plus: Button = null
var plus_buttons: Dictionary = {}
var icon_nodes: Dictionary = {}
var fullscreen_ad_modal: Control = null
var _active_ad_item_id: String = ""
var _active_ad_session_id: String = ""

var inventory: Dictionary = {
	"bomb": 2,
	"change_block": 2,
	"extra_life": 1
}

var selected_item: String = ""
var last_reward_animated_item: String = ""


func _get_game_state() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/GameState")
	var main_loop := Engine.get_main_loop() as SceneTree
	if main_loop and main_loop.root:
		return main_loop.root.get_node_or_null("GameState")
	return null


func _exit_tree() -> void:
	var gs = _get_game_state()
	if gs:
		if gs.has_signal("special_item_inventory_changed") and gs.special_item_inventory_changed.is_connected(_on_state_inventory_changed):
			gs.special_item_inventory_changed.disconnect(_on_state_inventory_changed)
		if gs.has_signal("special_item_discovered") and gs.special_item_discovered.is_connected(_on_special_item_discovered):
			gs.special_item_discovered.disconnect(_on_special_item_discovered)


func _ready() -> void:
	_ensure_nodes()
	_ensure_medallion_icons()
	_ensure_plus_buttons()
	_ensure_fullscreen_ad_modal()
	
	if btn_bomb:
		GameTypographyScript.apply_secondary_button_typography(btn_bomb, 18)
		if not btn_bomb.pressed.is_connected(_on_bomb_pressed):
			btn_bomb.pressed.connect(_on_bomb_pressed)
	if btn_change_block:
		GameTypographyScript.apply_secondary_button_typography(btn_change_block, 18)
		if not btn_change_block.pressed.is_connected(_on_change_block_pressed):
			btn_change_block.pressed.connect(_on_change_block_pressed)
	if btn_extra_life:
		GameTypographyScript.apply_secondary_button_typography(btn_extra_life, 18)
		if not btn_extra_life.pressed.is_connected(_on_extra_life_pressed):
			btn_extra_life.pressed.connect(_on_extra_life_pressed)
	
	var gs = _get_game_state()
	if gs:
		if gs.has_signal("special_item_inventory_changed"):
			gs.special_item_inventory_changed.connect(_on_state_inventory_changed)
		if gs.has_signal("special_item_discovered"):
			gs.special_item_discovered.connect(_on_special_item_discovered)
		if gs.has_signal("language_changed"):
			gs.language_changed.connect(func(_l): update_inventory_display())
		if "special_item_inventory" in gs and not gs.special_item_inventory.is_empty():
			inventory = gs.special_item_inventory.duplicate()
	
	update_inventory_display()


func _ensure_nodes() -> void:
	if not btn_bomb:
		btn_bomb = get_node_or_null("MarginContainer/HBoxContainer/BtnBomb")
	if not btn_change_block:
		btn_change_block = get_node_or_null("MarginContainer/HBoxContainer/BtnChangeBlock")
	if not btn_extra_life:
		btn_extra_life = get_node_or_null("MarginContainer/HBoxContainer/BtnExtraLife")


func _ensure_medallion_icons() -> void:
	_ensure_nodes()
	_attach_medallion_icon(btn_bomb, "bomb")
	_attach_medallion_icon(btn_change_block, "change_block")
	_attach_medallion_icon(btn_extra_life, "extra_life")
	_ensure_plus_buttons()


func _make_plus_button_style(bg_col: Color, border_col: Color) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg_col
	st.border_width_left = 2
	st.border_width_top = 2
	st.border_width_right = 2
	st.border_width_bottom = 3
	st.border_color = border_col
	st.set_corner_radius_all(12)
	st.content_margin_left = 2.0
	st.content_margin_right = 2.0
	st.content_margin_top = 0.0
	st.content_margin_bottom = 0.0
	return st


func _ensure_plus_buttons() -> void:
	_ensure_nodes()
	btn_bomb_plus = _attach_plus_button(btn_bomb, "bomb", "BtnBombPlus")
	btn_change_block_plus = _attach_plus_button(btn_change_block, "change_block", "BtnChangeBlockPlus")
	btn_extra_life_plus = _attach_plus_button(btn_extra_life, "extra_life", "BtnExtraLifePlus")


func _attach_plus_button(parent_btn: Button, item_id: String, btn_name: String) -> Button:
	if not parent_btn:
		return null
	var existing := parent_btn.get_node_or_null(btn_name) as Button
	if existing:
		plus_buttons[item_id] = existing
		return existing
	var p_btn := Button.new()
	p_btn.name = btn_name
	p_btn.text = "+"
	p_btn.custom_minimum_size = Vector2(26, 26)
	p_btn.size = Vector2(26, 26)
	p_btn.anchor_left = 1.0
	p_btn.anchor_right = 1.0
	p_btn.anchor_top = 0.5
	p_btn.anchor_bottom = 0.5
	p_btn.offset_left = -30.0
	p_btn.offset_right = -4.0
	p_btn.offset_top = -13.0
	p_btn.offset_bottom = 13.0
	p_btn.add_theme_font_override("font", GameTypographyScript.get_hud_number_font(0.20, 1))
	p_btn.add_theme_font_size_override("font_size", 16)
	p_btn.add_theme_color_override("font_color", Color(1.0, 0.99, 0.90, 1.0))
	var st_norm := _make_plus_button_style(Color(0.12, 0.82, 0.42, 0.98), Color(1.0, 0.94, 0.42, 1.0))
	var st_hov := _make_plus_button_style(Color(0.18, 0.90, 0.48, 1.0), Color(1.0, 0.98, 0.62, 1.0))
	var st_dis := _make_plus_button_style(Color(0.28, 0.32, 0.44, 0.65), Color(0.55, 0.60, 0.72, 0.65))
	p_btn.add_theme_stylebox_override("normal", st_norm)
	p_btn.add_theme_stylebox_override("hover", st_hov)
	p_btn.add_theme_stylebox_override("pressed", st_norm)
	p_btn.add_theme_stylebox_override("disabled", st_dis)
	UIIconScript.remove_focus_outline(p_btn)
	UIIconScript.setup_button_press_feedback(p_btn)
	p_btn.pressed.connect(func(): _on_item_plus_pressed(item_id))
	p_btn.visible = false
	parent_btn.add_child(p_btn)
	plus_buttons[item_id] = p_btn
	return p_btn


func _ensure_fullscreen_ad_modal() -> void:
	if fullscreen_ad_modal and is_instance_valid(fullscreen_ad_modal):
		return
	fullscreen_ad_modal = Control.new()
	fullscreen_ad_modal.name = "SpecialItemFullscreenAdModal"
	fullscreen_ad_modal.top_level = true
	fullscreen_ad_modal.visible = false
	fullscreen_ad_modal.anchor_left = 0.0
	fullscreen_ad_modal.anchor_top = 0.0
	fullscreen_ad_modal.anchor_right = 1.0
	fullscreen_ad_modal.anchor_bottom = 1.0
	fullscreen_ad_modal.custom_minimum_size = Vector2(720, 1280)
	fullscreen_ad_modal.z_index = 120
	add_child(fullscreen_ad_modal)

	var bg := ColorRect.new()
	bg.name = "AdBackdrop"
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.04, 0.06, 0.16, 0.96)
	fullscreen_ad_modal.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.name = "AdContentVBox"
	vbox.anchor_left = 0.1
	vbox.anchor_right = 0.9
	vbox.anchor_top = 0.25
	vbox.anchor_bottom = 0.75
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	fullscreen_ad_modal.add_child(vbox)

	var lbl_ad_title := Label.new()
	lbl_ad_title.name = "LblAdTitle"
	lbl_ad_title.text = "REWARDED ADVERTISEMENT"
	lbl_ad_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_ad_title.add_theme_font_size_override("font_size", 26)
	lbl_ad_title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.34, 1.0))
	vbox.add_child(lbl_ad_title)

	var lbl_ad_desc := Label.new()
	lbl_ad_desc.name = "LblAdDesc"
	lbl_ad_desc.text = "Watch full-screen ad to earn +1 Special Item"
	lbl_ad_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_ad_desc.add_theme_font_size_override("font_size", 18)
	vbox.add_child(lbl_ad_desc)

	var btn_complete := Button.new()
	btn_complete.name = "BtnCompleteAd"
	btn_complete.text = "COMPLETE AD (+1)"
	btn_complete.custom_minimum_size = Vector2(240, 56)
	GameTypographyScript.apply_secondary_button_typography(btn_complete, 20)
	UIIconScript.remove_focus_outline(btn_complete)
	UIIconScript.setup_button_press_feedback(btn_complete)
	btn_complete.pressed.connect(func(): complete_rewarded_ad_for_item(_active_ad_item_id, _active_ad_session_id))
	vbox.add_child(btn_complete)

	var btn_skip := Button.new()
	btn_skip.name = "BtnSkipAd"
	btn_skip.text = "SKIP / CLOSE"
	btn_skip.custom_minimum_size = Vector2(240, 50)
	GameTypographyScript.apply_secondary_button_typography(btn_skip, 18)
	UIIconScript.remove_focus_outline(btn_skip)
	UIIconScript.setup_button_press_feedback(btn_skip)
	btn_skip.pressed.connect(func(): skip_rewarded_ad_for_item(_active_ad_item_id))
	vbox.add_child(btn_skip)


func _attach_medallion_icon(btn: Button, item_id: String) -> void:
	if not btn:
		return
	UIIconScript.remove_focus_outline(btn)
	var existing = btn.get_node_or_null("MedallionIcon_" + item_id)
	if existing:
		icon_nodes[item_id] = existing
		return
	var med := BoosterMedallionIcon.new(item_id)
	med.name = "MedallionIcon_" + item_id
	med.position = Vector2(4, 2)
	med.size = Vector2(38, 46)
	btn.add_child(med)
	icon_nodes[item_id] = med


func has_visual_icon(item_id: String) -> bool:
	_ensure_medallion_icons()
	return icon_nodes.has(item_id) and icon_nodes[item_id] != null and is_instance_valid(icon_nodes[item_id])


func has_custom_medallion_icons() -> bool:
	return has_visual_icon("bomb") and has_visual_icon("change_block") and has_visual_icon("extra_life")


func is_item_selected(item_id: String) -> bool:
	return selected_item == item_id


func is_item_disabled(item_id: String) -> bool:
	var btn := get_button_for_item(item_id)
	return btn.disabled if btn else true


func get_item_types() -> Array[String]:
	return ITEM_TYPES.duplicate()


func reset_inventory() -> void:
	var gs = _get_game_state()
	if gs and "special_item_inventory" in gs and gs.has_special_items() and not gs.special_item_inventory.is_empty():
		inventory = gs.special_item_inventory.duplicate()
	else:
		inventory = DEFAULT_INVENTORY.duplicate()
		if gs and "special_item_inventory" in gs and gs.has_special_items():
			gs.special_item_inventory = inventory.duplicate()
	selected_item = ""
	update_inventory_display()
	_update_selection_visuals()


func _on_state_inventory_changed(new_inv: Dictionary) -> void:
	if new_inv.is_empty():
		inventory = {"bomb": 0, "change_block": 0, "extra_life": 0}
	else:
		inventory = new_inv.duplicate()
	update_inventory_display()


func _on_special_item_discovered(item_id: String, new_qty: int) -> void:
	inventory[item_id] = new_qty
	update_inventory_display()
	animate_reward_acquisition(item_id)


func update_inventory_display() -> void:
	_ensure_nodes()
	_ensure_medallion_icons()
	_ensure_plus_buttons()
	var gs = _get_game_state()
	var lbl_b: String = gs.tr_text("item_bomb") if (gs and gs.has_method("tr_text")) else "BOMB"
	var lbl_c: String = gs.tr_text("item_change_block") if (gs and gs.has_method("tr_text")) else "CHANGE BLOCK"
	var lbl_e: String = gs.tr_text("item_extra_life") if (gs and gs.has_method("tr_text")) else "EXTRA LIFE"
	_update_button_label(btn_bomb, "bomb", lbl_b, int(inventory.get("bomb", 0)))
	_update_button_label(btn_change_block, "change_block", lbl_c, int(inventory.get("change_block", 0)))
	_update_button_label(btn_extra_life, "extra_life", lbl_e, int(inventory.get("extra_life", 0)))
	_update_selection_visuals()


func _update_button_label(btn: Button, item_id: String, label_prefix: String, count: int) -> void:
	if not btn:
		return
	var safe_cnt: int = max(0, count)
	btn.text = "     %s × %d" % [label_prefix, safe_cnt]
	btn.disabled = (safe_cnt <= 0)
	btn.self_modulate.a = 0.52 if safe_cnt <= 0 else 1.0
	btn.modulate = Color.WHITE
	if icon_nodes.has(item_id) and icon_nodes[item_id] != null:
		icon_nodes[item_id].set_state(selected_item == item_id, safe_cnt <= 0)
	var p_btn: Button = plus_buttons.get(item_id, null) as Button
	if p_btn:
		# CRITICAL RULE: The + button must appear ONLY when that item's inventory is 0.
		var show_plus: bool = (safe_cnt == 0)
		p_btn.visible = show_plus
		if show_plus:
			var gs = _get_game_state()
			var used_today: bool = gs.has_used_daily_special_item_ad(item_id) if (gs and gs.has_method("has_used_daily_special_item_ad")) else false
			p_btn.disabled = used_today
			p_btn.modulate = Color(0.68, 0.72, 0.82, 0.72) if used_today else Color(1.0, 1.0, 1.0, 1.0)


func get_plus_button_for_item(item_id: String) -> Button:
	_ensure_plus_buttons()
	return plus_buttons.get(item_id, null) as Button


func is_plus_button_visible(item_id: String) -> bool:
	var p_btn := get_plus_button_for_item(item_id)
	return p_btn != null and p_btn.visible


func is_plus_button_enabled(item_id: String) -> bool:
	var p_btn := get_plus_button_for_item(item_id)
	return p_btn != null and p_btn.visible and not p_btn.disabled


func _on_item_plus_pressed(item_id: String) -> bool:
	if get_item_count(item_id) > 0:
		return false
	var gs = _get_game_state()
	if gs and gs.has_method("has_used_daily_special_item_ad") and gs.has_used_daily_special_item_ad(item_id):
		update_inventory_display()
		return false
	var sid := open_rewarded_ad_for_item(item_id)
	return sid != ""


func open_rewarded_ad_for_item(item_id: String, current_date_str: String = "") -> String:
	if get_item_count(item_id) > 0:
		return ""
	var gs = _get_game_state()
	if not gs or not gs.has_method("open_rewarded_ad_for_special_item"):
		return ""
	var sid: String = gs.open_rewarded_ad_for_special_item(item_id, current_date_str)
	if sid == "":
		update_inventory_display()
		return ""
	_ensure_fullscreen_ad_modal()
	_active_ad_item_id = item_id
	_active_ad_session_id = sid
	if fullscreen_ad_modal:
		fullscreen_ad_modal.visible = true
	item_ad_opened.emit(item_id, sid)
	return sid


func complete_rewarded_ad_for_item(item_id: String = "", arg2: String = "", arg3: String = "") -> Dictionary:
	var target_item: String = item_id if item_id != "" else _active_ad_item_id
	var current_date_str: String = arg2
	var target_sid: String = arg3
	if arg2.begins_with("ad_") or (arg3.length() == 10 and arg3[4] == "-"):
		target_sid = arg2
		current_date_str = arg3
	if target_sid == "":
		target_sid = _active_ad_session_id
	var gs = _get_game_state()
	if not gs or not gs.has_method("complete_rewarded_ad_for_special_item"):
		return {"granted": false, "amount": 0}
	var res: Dictionary = gs.complete_rewarded_ad_for_special_item(target_item, current_date_str, target_sid)
	if fullscreen_ad_modal:
		fullscreen_ad_modal.visible = false
	if bool(res.get("granted", false)):
		var new_qty: int = int(res.get("quantity", 1))
		inventory[target_item] = new_qty
		update_inventory_display()
		animate_reward_acquisition(target_item)
		item_ad_completed.emit(target_item, new_qty)
	else:
		update_inventory_display()
	return res


func skip_rewarded_ad_for_item(item_id: String = "") -> Dictionary:
	var target_item: String = item_id if item_id != "" else _active_ad_item_id
	var gs = _get_game_state()
	var res: Dictionary = {"granted": false, "amount": 0}
	if gs and gs.has_method("skip_rewarded_ad_for_special_item"):
		res = gs.skip_rewarded_ad_for_special_item(target_item)
	if fullscreen_ad_modal:
		fullscreen_ad_modal.visible = false
	update_inventory_display()
	item_ad_skipped.emit(target_item)
	return res


func watch_rewarded_ad_for_item(item_id: String, ad_completed: bool = true, current_date_str: String = "") -> Dictionary:
	var sid := open_rewarded_ad_for_item(item_id, current_date_str)
	if sid == "":
		return {"granted": false, "amount": 0, "reason": "cannot_open_ad"}
	if ad_completed:
		return complete_rewarded_ad_for_item(item_id, current_date_str, sid)
	return skip_rewarded_ad_for_item(item_id)


func get_item_count(item_id: String) -> int:
	return int(inventory.get(item_id, 0))


func set_item_count(item_id: String, count: int) -> void:
	if not (item_id in ITEM_TYPES):
		return
	inventory[item_id] = max(0, count)
	var gs = _get_game_state()
	if gs and "special_item_inventory" in gs and gs.has_special_items():
		gs.special_item_inventory[item_id] = inventory[item_id]
	if inventory[item_id] <= 0 and selected_item == item_id:
		selected_item = ""
	update_inventory_display()


func set_item_selected(item_id: String, selected: bool) -> void:
	if selected and (item_id in ITEM_TYPES):
		selected_item = item_id
	elif selected_item == item_id or not selected:
		selected_item = ""
	_update_selection_visuals()


func get_button_for_item(item_id: String) -> Button:
	_ensure_nodes()
	match item_id:
		"bomb": return btn_bomb
		"change_block": return btn_change_block
		"extra_life": return btn_extra_life
	return null


func animate_activation(item_id: String) -> void:
	var target_btn: Button = get_button_for_item(item_id)
	if target_btn and is_inside_tree():
		target_btn.pivot_offset = target_btn.size * 0.5
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(target_btn, "scale", Vector2(1.14, 1.14), 0.05)
		tw.tween_property(target_btn, "scale", Vector2(1.0, 1.0), 0.07)


func animate_reward_acquisition(item_id: String) -> void:
	last_reward_animated_item = item_id
	var target_btn: Button = get_button_for_item(item_id)
	if target_btn and is_inside_tree():
		target_btn.pivot_offset = target_btn.size * 0.5
		var tw = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(target_btn, "scale", Vector2(1.24, 1.24), 0.16)
		tw.tween_property(target_btn, "scale", Vector2(1.0, 1.0), 0.24)


func _update_selection_visuals() -> void:
	_ensure_nodes()
	_ensure_medallion_icons()
	_ensure_plus_buttons()
	_apply_button_selection(btn_bomb, "bomb", selected_item == "bomb")
	_apply_button_selection(btn_change_block, "change_block", selected_item == "change_block")
	_apply_button_selection(btn_extra_life, "extra_life", selected_item == "extra_life")


func _apply_button_selection(btn: Button, item_id: String, is_selected: bool) -> void:
	if not btn:
		return
	var count_ok := not btn.disabled
	if is_selected and count_ok:
		btn.self_modulate = Color(1.32, 1.30, 0.72, 1.0)
	else:
		btn.self_modulate = Color(1.0, 1.0, 1.0, 0.52 if btn.disabled else 1.0)
	btn.modulate = Color.WHITE
	if icon_nodes.has(item_id) and icon_nodes[item_id] != null:
		icon_nodes[item_id].set_state(is_selected and count_ok, btn.disabled)


func _on_bomb_pressed() -> void:
	_on_item_pressed("bomb")


func _on_change_block_pressed() -> void:
	_on_item_pressed("change_block")


func _on_extra_life_pressed() -> void:
	var gs = _get_game_state()
	# Extra Life must ONLY work at Game Over; while actively playing, pressing it must do nothing.
	if not gs or gs.current_state != 3:
		return
	if gs.has_method("can_use_extra_life_now") and not gs.can_use_extra_life_now():
		return
	_on_item_pressed("extra_life")


func _on_item_pressed(item_id: String) -> void:
	if item_id == "extra_life":
		var gs = _get_game_state()
		if not gs or gs.current_state != 3:
			return
		if gs.has_method("can_use_extra_life_now") and not gs.can_use_extra_life_now():
			return
	item_clicked.emit(item_id)
