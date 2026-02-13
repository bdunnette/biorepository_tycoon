extends Area2D

@onready var visual = $Visual

var storage_data: StorageModels.Freezer


func _ready():
	z_index = 1
	if storage_data == null:
		storage_data = StorageModels.Freezer.new("Model-X Freezer")

	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered():
	visual.modulate = Color(1.2, 1.2, 1.5)


func _on_mouse_exited():
	visual.modulate = Color.WHITE


func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		handle_click(event)
		get_viewport().set_input_as_handled()


func _input(event):
	# Fallback if pickable system is blocked but event reaches node
	# Only process if the event wasn't already handled
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.is_pressed():  # Event was consumed
			return
		var local_pos = to_local(get_global_mouse_position())
		if Geometry2D.is_point_in_polygon(local_pos, $CollisionPolygon2D.polygon):
			handle_click(event)
			get_viewport().set_input_as_handled()


func handle_click(event):
	if GameManager.building_mode:
		return

	if event.button_index == MOUSE_BUTTON_LEFT:
		GameManager.open_inventory.emit(storage_data)
