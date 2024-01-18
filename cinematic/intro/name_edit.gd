extends LineEdit

#var has_bar := false;
#const BLINK_DURATION = 1.0;
#const BLINK_DELTA = 1.0;
#var blink = BLINK_DURATION;
#var is_blinking = true;
#var textwo = "";
var edit_mode = false;
signal update_value(key:String, value);

# Called when the node enters the scene tree for the first time.
func _ready():
	self.connect("text_changed", on_text_changed)
	caret_blink = true;
	#self.connect("focus_entered", on_text_select)
	#self.connect("focus_exited", on_text_deselect)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#if is_blinking:
	#	blinking(delta)
	if edit_mode:
		sanitize(text)
	
	pass

#func blinking(delta:float):
#
#	blink -= BLINK_DELTA*delta;
#
#	if blink < 0:
#		if has_bar:
#			text = textwo;
#			has_bar = false;
#			blink = BLINK_DURATION
#		else:
#			text = textwo + "|";
#			has_bar = true;
#			blink = BLINK_DURATION
#
#	pass
#
#func on_text_select():
#	is_blinking = false;
#	if has_bar:
#		text = text.trim_suffix("|")
#		has_bar = false;
#	pass
#
#func on_text_deselect():
#	textwo = text;
#	is_blinking = true;
#	pass

func on_text_changed(new_text:String):
	sanitize(new_text)

func sanitize(new_text:String):
	if edit_mode:
		edit_mode = false;
		new_text = new_text.replace(";", "；").replace('"', "＂").replace("'", "＇").replace("+", "＋");
		new_text = new_text.replace("-", "‐").replace("{", "｛").replace("}", "｝").replace("(", "（");
		new_text = new_text.replace(")", "）").replace("%", "％").replace("=", "＝").replace(">", "＞");
		new_text = new_text.replace("<", "＜").replace("$", "＄").replace("*", "＊").replace("@", "＠");
		text = new_text + "!"
		edit_mode = true;
	pass
