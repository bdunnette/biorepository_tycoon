extends Node2D

var building_mode = false
var grid_size = 12

@onready var ui_funds_label = $CanvasLayer/UI/Stats
@onready var placement_preview = $PlacementPreview
@onready var tile_map = $TileMap
@onready var inventory_ui = $CanvasLayer/InventoryUI


func _ready():
	setup_floor()
	setup_placement_preview()
	GameManager.funds_changed.connect(_update_ui)
	GameManager.open_inventory.connect(_on_open_inventory)
	_update_ui(GameManager.funds)


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
	if building_mode:
		var mouse_pos = get_global_mouse_position()
		var tile_pos = tile_map.local_to_map(mouse_pos)
		placement_preview.global_position = tile_map.map_to_local(tile_pos)
		placement_preview.visible = true

		# Check if already occupied (simple check)
		placement_preview.modulate = Color(0.5, 1, 0.5, 0.6)  # Green tint

		if (
			Input.is_action_just_pressed("ui_accept")
			or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		):
			place_item(tile_pos)
	else:
		placement_preview.visible = false


func place_item(tile_pos):
	if GameManager.buy_freezer():
		var new_freezer = preload("res://scenes/Freezer.tscn").instantiate()
		add_child(new_freezer)
		new_freezer.position = tile_map.map_to_local(tile_pos)
		building_mode = false
	else:
		print("Not enough funds!")


func _update_ui(funds):
	ui_funds_label.text = "Funds: $" + str(funds)


func _on_buy_freezer_pressed():
	building_mode = !building_mode
