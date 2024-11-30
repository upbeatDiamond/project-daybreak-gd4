extends HBoxContainer



@onready var btn_strength = self.find_child("Strength", true);
@onready var btn_wisdom = self.find_child("Wisdom", true);
@onready var btn_charisma = self.find_child("Charisma", true);

@onready var btn_reflect = self.find_child("Reflect");
var reflect_target : Node;


# Called when the node enters the scene tree for the first time.
func _ready():
	btn_reflect.connect('toggled', self.on_reflect_pressed);
	pass # Replace with function body.

func on_become_visible():
	if self.visible:
		self.grab_focus()
	pass

func on_reflect_pressed(_h:=true):
	var gender = ''
	if btn_strength.button_pressed:
		gender = 'strong'
	if btn_wisdom.button_pressed:
		gender = 'wise'
	if btn_charisma.button_pressed:
		gender = 'charismatic'
	
	print(reflect_target, gender);
	
	store_ability( str(gender) )
	pass

func store_ability( ability ):
	if reflect_target != null && reflect_target.has_method( 'on_reflect_kv' ):
		reflect_target.on_reflect_kv("player_ability", ability);
	GlobalDatabase.save_keyval("player_ability", ability)
	pass

func set_reflect_target(n:Node):
	reflect_target = n;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
