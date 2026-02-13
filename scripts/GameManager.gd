extends Node

signal funds_changed(new_funds)
signal open_inventory(object)

var funds: int = 5000:
	set(value):
		funds = value
		funds_changed.emit(funds)


func buy_freezer() -> bool:
	if funds >= 1000:
		funds -= 1000
		return true
	return false


# For testing retrieval reward
func add_funds(amount: int):
	funds += amount
