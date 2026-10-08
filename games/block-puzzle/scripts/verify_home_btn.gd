
extends SceneTree

func _init() -> void:
	var MainMenuScene = load("res://scenes/ui/main_menu.tscn")
	var menu = MainMenuScene.instantiate()
	root.add_child(menu)
	
	var gs = root.get_node_or_null("GameState")
	if gs == null:
		var gs_class = load("res://scripts/autoload/game_state.gd")
		gs = gs_class.new()
		gs.name = "GameState"
		root.add_child(gs)

	# Test 1: Open Level Map in EN
	gs.set_language("en", false)
	menu._refresh_all_ui()
	menu._on_btn_open_level_map_pressed()
	
	if not menu.modal_level_map.visible:
		printerr("FAIL: Level Map modal not visible after open")
		quit(1)
		return
		
	var home_btn: Button = menu.btn_close_level_map
	if home_btn == null:
		printerr("FAIL: btn_close_level_map is null")
		quit(1)
		return
		
	print("EN Level Map Home button text: ", home_btn.text)
	if home_btn.text != "HOME":
		printerr("FAIL: Expected HOME, got: ", home_btn.text)
		quit(1)
		return
		
	if "<" in home_btn.text:
		printerr("FAIL: < character still present in home button text!")
		quit(1)
		return

	# Test 2: Switch to VI
	gs.set_language("vi", false)
	menu._refresh_all_ui()
	print("VI Level Map Home button text: ", home_btn.text)
	if home_btn.text != "TRANG CHỦ":
		printerr("FAIL: Expected TRANG CHỦ, got: ", home_btn.text)
		quit(1)
		return
		
	if "<" in home_btn.text:
		printerr("FAIL: < character still present in VI home button text!")
		quit(1)
		return

	# Test 3: Press Home button and verify it closes modal
	home_btn.pressed.emit()
	if menu.modal_level_map.visible:
		printerr("FAIL: Pressing HOME button did not close modal_level_map!")
		quit(1)
		return

	print("ALL LEVEL MAP HOME BUTTON VERIFICATIONS PASSED PERFECTLY!")
	menu.queue_free()
	quit(0)
