extends Node2D

var grid_size = 12

@onready var ui_funds_label = $CanvasLayer/UI/Stats
@onready var placement_preview = $PlacementPreview
@onready var tile_map = $TileMap
@onready var inventory_ui = $CanvasLayer/InventoryUI
@onready var bin_list = $CanvasLayer/UI/Bin/VBoxContainer/ScrollContainer/BinList


func _ready():
	setup_floor()
	setup_placement_preview()
	GameManager.funds_changed.connect(_update_ui)
	GameManager.open_inventory.connect(_on_open_inventory)
	_update_ui(GameManager.funds)

	# Start with some freezers
	setup_starting_world()


func setup_starting_world():
	# Freezer 1: Empty
	_spawn_freezer(Vector2i(-2, 0), StorageModels.Freezer.new("Starter Freezer A"))

	# Freezer 2: Partially filled
	var f2 = StorageModels.Freezer.new("Main Biorepository")
	var r1 = StorageModels.Rack.new("Rack-01")
	var b1 = StorageModels.Box.new("Blood Samples")
	b1.vials[0] = StorageModels.Vial.new("Patient-A-001")
	b1.vials[1] = StorageModels.Vial.new("Patient-A-002")
	r1.boxes[0] = b1
	f2.racks[0] = r1
	_spawn_freezer(Vector2i(0, 0), f2)

	# Freezer 3: High Priority
	var f3 = StorageModels.Freezer.new("Cryo-Vault")
	var r_hp = StorageModels.Rack.new("HP-Rack")
	var b_hp = StorageModels.Box.new("Rare Specimen")
	b_hp.vials[40] = StorageModels.Vial.new("OMEGA-99")
	r_hp.boxes[12] = b_hp
	f3.racks[5] = r_hp
	_spawn_freezer(Vector2i(2, 0), f3)

	# Initial Bin contents
	GameManager.bin.append(StorageModels.Vial.new("New Arrival-01"))
	GameManager.bin.append(StorageModels.Vial.new("Pending-A-4"))
	_update_bin()


func _update_bin():
	for child in bin_list.get_children():
		child.queue_free()

	for i in range(GameManager.bin.size()):
		var btn = Button.new()
		var specimen = GameManager.bin[i]
		if specimen == null:
			continue
		btn.text = specimen.sample_name
		btn.theme_type_variation = "Button"
		btn.add_theme_font_size_override("font_size", 12)

		if GameManager.selected_bin_index == i:
			btn.modulate = Color(1.5, 1.5, 0.5)  # Highlight yellow

		btn.pressed.connect(_on_bin_item_pressed.bind(i))
		bin_list.add_child(btn)


func _on_bin_item_pressed(index):
	if GameManager.selected_bin_index == index:
		GameManager.selected_bin_index = -1
	else:
		GameManager.selected_bin_index = index
	_update_bin()


func setup_placement_preview():
	var preview_scene = preload("res://scenes/Freezer.tscn").instantiate()
	# Strip logic for preview
	preview_scene.set_script(null)
	for child in preview_scene.get_children():
		if child is CollisionPolygon2D:
			child.queue_free()
	placement_preview.add_child(preview_scene)
	placement_preview.modulate = Color(1, 1, 1, 0.6)


func setup_floor():
	var floor_node = Node2D.new()
	floor_node.name = "VisualFloor"
	add_child(floor_node)
	move_child(floor_node, 0)

	for x in range(-grid_size, grid_size):
		for y in range(-grid_size, grid_size):
			var tile = Polygon2D.new()
			tile.polygon = PackedVector2Array(
				[Vector2(0, -32), Vector2(64, 0), Vector2(0, 32), Vector2(-64, 0)]
			)
			# Laboratory tile pattern
			var base_color = Color(0.1, 0.12, 0.15)
			if (x + y) % 2 == 0:
				base_color = Color(0.12, 0.14, 0.18)

			tile.color = base_color
			tile.position = tile_map.map_to_local(Vector2i(x, y))
			floor_node.add_child(tile)

			# Add subtle grid lines
			var line = Line2D.new()
			line.points = tile.polygon
			line.add_point(tile.polygon[0])  # Close the loop
			line.width = 1.0
			line.default_color = Color(1, 1, 1, 0.05)
			tile.add_child(line)


func _on_open_inventory(object):
	inventory_ui.open(object)


func _process(_delta):
	if GameManager.building_mode:
		var mouse_pos = get_global_mouse_position()
		var tile_pos = tile_map.local_to_map(mouse_pos)
		placement_preview.global_position = tile_map.map_to_local(tile_pos)
		placement_preview.visible = true
		placement_preview.modulate = Color(0.5, 1, 0.5, 0.8)
	else:
		placement_preview.visible = false


func _unhandled_input(event):
	if GameManager.building_mode and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = get_global_mouse_position()
			var tile_pos = tile_map.local_to_map(mouse_pos)
			place_item(tile_pos)
			get_viewport().set_input_as_handled()


func place_item(tile_pos):
	if GameManager.buy_freezer():
		_spawn_freezer(tile_pos, StorageModels.Freezer.new("Model-X Freezer"))
		GameManager.building_mode = false


func _spawn_freezer(tile_pos: Vector2i, storage_data: StorageModels.Freezer):
	var new_freezer = preload("res://scenes/Freezer.tscn").instantiate()
	new_freezer.storage_data = storage_data
	add_child(new_freezer)
	new_freezer.global_position = tile_map.map_to_local(tile_pos)


func _update_ui(funds):
	ui_funds_label.text = "Funds: $" + str(funds)


func _on_buy_freezer_pressed():
	GameManager.building_mode = !GameManager.building_mode
	if GameManager.building_mode:
		# Ensure we're not accidentally opening inventory when clicking the button
		get_viewport().set_input_as_handled()
