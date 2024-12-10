extends Control
class_name InventoryList

var item_slots : Array[TextureButton] = []
const INVENTORY_SLOT = preload("res://inventory/inventory_slot.tscn")
@onready var slot_list = $ScrollContainer/VBoxContainer

## 0-indexed; currently unused. Intended to avoid unneeded focus capture.
var current_selected := 0
var busy := false


signal focus_updated( node:Control )
signal busy_ended


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	focus_entered.connect(_on_focus_entered)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	if Input.is_action_pressed("make"):
		var randix = randi_range(0, 1024)
		set_entry(randix, randi_range(1, 64), str(randix), str(randix) )
	if Input.is_action_pressed("kill"):
		clear_entries()
	
	
	pass


func _on_focus_entered():
	pass


func clear_entries():
	#if busy:
		#await busy_ended
	#busy = true
	
	var children = slot_list.get_children().duplicate()
	for item in children:
		slot_list.remove_child(item)
		item.queue_free()
	
	#busy = false
	#busy_ended.emit()


## If the item cannot be found, add it to the list
## Set the item count to 'count'.
## If 'item' is a tag, change it to the index. If the index cannot be found, use a hash of the tag.
func set_entry(item, count:int, text:String, description:String, icon:String="", stack_size:=999):
	
	## TODO: Replace with database access!!!
	if not item is int:
		item = str(item).hash()
	
	var was_found := false
	
	for slot in slot_list.get_children():
		if str(slot.item) == str(item):
			if stack_size <= 1:
				slot.count_label.visible = false
			slot.count = count
			slot.text = text
			was_found = true
			break
	
	if not was_found:
		_add_entry(item, count, text, description)
	
	pass


func _add_entry(item, count:int, text:String, description:String, icon:String=""):
	
	## Create the item slot
	var entry = INVENTORY_SLOT.instantiate()
	entry.item = item
	entry.count = count
	entry.text = text
	entry.description = description
	if icon.is_valid_filename():
		entry.icon_path = icon
	slot_list.add_child(entry)
	entry._update_labels()
	entry.selected.connect(_on_entry_selected)
	
	_sort_items()


func _sort_items():
	## Re-sort all the slots to ensure that the entry is in the correct position
	var sorted_nodes := slot_list.get_children().duplicate()
	sorted_nodes.sort_custom(_slot_custom_sort)
	
	for node in slot_list.get_children():
		slot_list.remove_child(node)
	
	for node in sorted_nodes:
		slot_list.add_child(node)
	
	#var list_size = slot_list.get_children().size()
	
	## Have the neighbors properly assigned, so if the overall display fails, 
	## the keyboard input still works.
	for node in slot_list.get_children():
		
		node.focus_next = self.focus_next
		node.focus_previous = self.focus_previous
		
		var node_index = slot_list.get_children().find(node)
		var neighbor
		
		if node_index > 0:
			neighbor = slot_list.get_children()[node_index-1]
		else:
			neighbor = slot_list.get_children()[-1]
		node.focus_neighbor_top = neighbor.get_path()
		neighbor.focus_neighbor_bottom = node.get_path()
		
		if node_index + 1 < slot_list.get_children().size():
			neighbor = slot_list.get_children()[node_index+1]
		else:
			neighbor = slot_list.get_children()[0]
		node.focus_neighbor_bottom = neighbor.get_path()
		neighbor.focus_neighbor_top = node.get_path()
	
	if slot_list.get_children().size() >= 1:
		slot_list.get_children()[0].grab_focus()
		slot_list.get_children()[0].grab_click_focus()


# For descending order use > 0
func _slot_custom_sort(a:InventoryListItem, b:InventoryListItem):
	if a.list_index < b.list_index:
		return true
	elif a.list_index > b.list_index:
		return false
	else:
		return a.text < b.text


func set_selection_index(index:int):
	
	item_slots[current_selected].set_pressed_no_signal(false)
	
	if abs(index) < item_slots.size():
		current_selected = index
	else:
		current_selected = index % item_slots.size()
	
	item_slots[current_selected].set_pressed_no_signal(true)


func selection_move_down():
	set_selection_index(current_selected + 1)


func selection_move_up():
	set_selection_index(current_selected - 1)


func _on_entry_selected(node:Control):
	focus_updated.emit(node)
	pass


func _mutex(function:Callable, parameters:=[]):
	## Mutex to reduce chance of list corruption
	if busy:
		await busy_ended
	busy = true
	
	function.callv(parameters)
	
	busy = false
	busy_ended.emit()
