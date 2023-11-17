extends Control

const SLOT = preload("res://menu/inventory_slot.tscn")

@onready var item_list = $ScrollContainer/ItemList

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func repopulate_item_list(slot_list : Array[ItemGroupData]) -> void:
	GlobalRuntime.clean_up_descent(item_list)
