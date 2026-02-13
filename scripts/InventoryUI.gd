extends Control
var current_view_level = "freezer"  # "freezer", "rack", "box"
var current_parent_object = null
var history = []

@onready var title_label = $Panel/VBoxContainer/Title
@onready var item_grid = $Panel/VBoxContainer/ScrollContainer/GridContainer
@onready var back_button = $Panel/VBoxContainer/BackButton
@onready var picker_panel = $PickerPanel
@onready var picker_grid = $PickerPanel/VBoxContainer/ScrollContainer/GridContainer
@onready var cancel_picker_button = $PickerPanel/VBoxContainer/CancelPicker

var active_slot_index = -1


func _ready():
	visible = false
	back_button.pressed.connect(_on_back_pressed)
	cancel_picker_button.pressed.connect(func(): picker_panel.visible = false)


func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		_on_back_pressed()


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
			if type == "Vial":
				btn.pressed.connect(_on_retrieve_clicked.bind(i))
				btn.tooltip_text = "Click to retrieve to Bin"
			else:
				btn.pressed.connect(_on_item_clicked.bind(item))
		else:
			btn.pressed.connect(_on_empty_slot_clicked.bind(i))
			if current_view_level == "box":
				btn.tooltip_text = "Click to place from Bin or buy new"


func _on_retrieve_clicked(index):
	var specimen = current_parent_object.vials[index]
	GameManager.bin.append(specimen)
	current_parent_object.vials[index] = null

	GameManager.funds += 50  # Reward for retrieving/processing?

	# Update Main UI Bin
	var main = get_tree().current_scene
	if main and main.has_method("_update_bin"):
		main._update_bin()

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
		if current_parent_object.vials[index] != null:
			print("Slot already occupied!")
			return

		active_slot_index = index
		if GameManager.selected_bin_index != -1:
			_on_bin_item_selected(GameManager.selected_bin_index)
			GameManager.selected_bin_index = -1
		else:
			_show_picker()
			return  # Wait for picker selection

	_show_contents(current_parent_object)


func _show_picker():
	picker_panel.visible = true
	# Clear picker grid
	for child in picker_grid.get_children():
		child.queue_free()

	if GameManager.bin.size() == 0:
		var lbl = Label.new()
		lbl.text = "Bin is empty!"
		picker_grid.add_child(lbl)
		return

	for i in range(GameManager.bin.size()):
		var btn = Button.new()
		var specimen = GameManager.bin[i]
		btn.text = specimen.sample_name
		btn.custom_minimum_size = Vector2(80, 80)
		picker_grid.add_child(btn)
		btn.pressed.connect(_on_bin_item_selected.bind(i))


func _on_bin_item_selected(bin_index):
	var specimen = GameManager.bin[bin_index]
	GameManager.bin.remove_at(bin_index)
	current_parent_object.vials[active_slot_index] = specimen

	picker_panel.visible = false

	# Update Main UI Bin
	var main = get_tree().current_scene
	if main and main.has_method("_update_bin"):
		main._update_bin()

	_show_contents(current_parent_object)
