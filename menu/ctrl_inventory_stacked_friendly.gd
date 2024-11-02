@tool
extends CtrlInventoryStacked

var is_dirty := false
@export var font_size := 22:
	set(size):
		set_font_size(size)

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	
	is_dirty = true
	#call_deferred("set_font_size")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if is_dirty:
		set_font_size()

func set_font_size(_font_size:=font_size):
	
	var childs = get_children()
	for child in childs:
		if child == null:
			is_dirty = true
			return
		elif child is Label:
			if child.label_settings == null:
				child.label_settings = LabelSettings.new()
			child.label_settings.font_size = _font_size
			print("updated Label font size to ", child.label_settings.font_size)
		elif child is RichTextLabel:
			child.normal_font_size = _font_size
			print("updated RichTextLabel font size to ", child.normal_font_size)
		elif child is ItemList:
			child.theme = Theme.new()
			child.theme.default_font_size = _font_size
			child.fixed_icon_size = Vector2i(_font_size, _font_size)
			child.auto_height = true
			#child.icon_margin = int(font_size / 3)
		
		childs.append_array(child.get_children())
		print(child)
		is_dirty = false
	pass
