class_name StorageModels
extends Node


class Freezer:
	var name: String
	var racks: Array = []

	func _init(_name: String):
		name = _name
		racks.resize(10)
		racks.fill(null)


class Rack:
	var name: String
	var boxes: Array = []

	func _init(_name: String):
		name = _name
		boxes.resize(25)
		boxes.fill(null)


class Box:
	var name: String
	var vials: Array = []

	func _init(_name: String):
		name = _name
		vials.resize(81)
		vials.fill(null)


class Vial:
	var sample_name: String

	func _init(_name: String):
		sample_name = _name
