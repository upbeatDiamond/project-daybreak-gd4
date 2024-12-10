extends TextureButton
class_name InventoryListItem

signal selected( item:InventoryListItem )

var count : int = 0 :
	set(value):
		count = value
		dirty = true

var text : String = "" :
	set(value):
		text = value
		dirty = true

var dirty := true
var item = "null"
var list_index : int = 0
var description : = ""
var icon_path : String = ""

@onready var count_label : Label = $Count
@onready var name_label : Label = $HBoxContainer/Name


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_pressed)
	_update_labels()
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if dirty:
		_update_labels()
	pass


func _update_labels():
	var clean = true
	
	## If the count didn't change, it's still dirty.
	if count_label != null:
		count_label.text = str("x", count)
	else:
		clean = false
	
	if text == null or text == "":
		text = str(item)
	
	## If the name didn't change, it's still dirty.
	if name_label != null:
		name_label.text = text
	else:
		clean = false
	
	dirty = not clean ## If anything failed, the slot remains dirty.


func _on_pressed():
	print("Yippee!")
	


func _on_focus_entered():
	selected.emit(self)
	pass


func _on_focus_exited():
	
	pass


func set_count(_count:int=count):
	count = _count
	count_label.text = str("x", count)
