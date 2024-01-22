extends PanelContainer

var edit_mode = false;
@onready var name_edit = self.find_child("NameEdit");
var reflect_target : Node;


# Called when the node enters the scene tree for the first time.
func _ready():
	name_edit.connect('text_changed', self.on_text_changed);
	name_edit.connect('text_submitted', self.on_text_submitted);
	#caret_blink = true;
	#self.connect("focus_entered", on_text_select)
	#self.connect("focus_exited", on_text_deselect)
	pass # Replace with function body.

func on_text_submitted(new_text):
	if reflect_target != null && reflect_target.has_method( 'on_reflect_kv' ):
		reflect_target.on_reflect_kv("player_name", sanitize(new_text));
	pass

func set_reflect_target(n:Node):
	reflect_target = n;

#func on_request_kv():
#	edit_mode = true
#	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass

func on_text_changed(_new_text:String):
	pass#sanitize(new_text);

func sanitize(new_text:String) -> String:
	if edit_mode:
		edit_mode = false;
		new_text = new_text.replace(";", "；").replace('"', "＂").replace("'", "＇").replace("+", "＋");
		new_text = new_text.replace("-", "‐").replace("{", "｛").replace("}", "｝").replace("(", "（");
		new_text = new_text.replace(")", "）").replace("%", "％").replace("=", "＝").replace(">", "＞");
		new_text = new_text.replace("<", "＜").replace("$", "＄").replace("*", "＊").replace("@", "＠");
		name_edit.text = new_text + "!"
		edit_mode = true;
	
	return new_text;
