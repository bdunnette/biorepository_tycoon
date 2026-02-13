extends Control

@onready var title_label = $Panel/VBoxContainer/Title
@onready var item_grid = $Panel/VBoxContainer/ScrollContainer/GridContainer
@onready var back_button = $Panel/VBoxContainer/BackButton

var current_view_level = "freezer" # "freezer", "rack", "box"
var current_parent_object = null
var history = []

func _ready():
	visible = false
	back_button.pressed.connect(_on_back_pressed)

func open(object):
	visible = true
	history = []
	_show_contents(object)

func _show_contents(object):
	current_parent_object = object
	# Clear grid
	for child in item_grid.get_children():
		child.queue_free()
	
	if object is StorageModels.Freezer:
		title_label.text = "Freezer: " + object.name
		current_view_level = "freezer"
		_populate_grid(object.racks, "Rack")
	elif object is StorageModels.Rack:
		title_label.text = "Rack: " + object.name
		current_view_level = "rack"
		_populate_grid(object.boxes, "Box")
	elif object is StorageModels.Box:
		title_label.text = "Box: " + object.name
		current_view_level = "box"
		_populate_grid(object.vials, "Vial")

func _populate_grid(items, type):
	for i in range(items.size()):
		var btn = Button.new()
		var item = items[i]
		if item == null:
			btn.text = "[ Empty Slot " + str(i) + " ]"
			btn.modulate = Color(0.5, 0.5, 0.5)
		else:
			btn.text = type + ": " + (item.name if "name" in item else item.sample_name)
		
		btn.custom_minimum_size = Vector2(100, 100)
		item_grid.add_child(btn)
		
		if item != null:
			btn.pressed.connect(_on_item_clicked.bind(item))
			if type == "Vial":
				var retrieve_btn = Button.new()
				retrieve_btn.text = "X"
				retrieve_btn.modulate = Color(1, 0.3, 0.3)
				btn.add_child(retrieve_btn)
				retrieve_btn.pressed.connect(_on_retrieve_clicked.bind(i))
		else:
			btn.pressed.connect(_on_empty_slot_clicked.bind(i))

func _on_retrieve_clicked(index):
	current_parent_object.vials[index] = null
	GameManager.funds += 50 # Reward for retrieving/processing?
	_show_contents(current_parent_object)

func _on_item_clicked(item):
	history.append(current_parent_object)
	_show_contents(item)

func _on_back_pressed():
	if history.size() > 0:
		var last = history.pop_back()
		_show_contents(last)
	else:
		visible = false

func _on_empty_slot_clicked(index):
	# Logic to "buy" or "place" a rack/box/vial here
	if current_view_level == "freezer":
		current_parent_object.racks[index] = StorageModels.Rack.new("New Rack")
	elif current_view_level == "rack":
		current_parent_object.boxes[index] = StorageModels.Box.new("New Box")
	elif current_view_level == "box":
		current_parent_object.vials[index] = StorageModels.Vial.new("Specimen-X")
	
	_show_contents(current_parent_object)
