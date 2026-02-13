extends Area2D

var storage_data: StorageModels.Freezer


func _ready():
	if storage_data == null:
		storage_data = StorageModels.Freezer.new("Model-X Freezer")

	input_event.connect(_on_input_event)


func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		GameManager.open_inventory.emit(storage_data)
