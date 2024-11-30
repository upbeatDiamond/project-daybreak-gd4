extends HBoxContainer



@onready var btn_strength : Button = self.find_child("Strength", true);
@onready var btn_wisdom : Button = self.find_child("Wisdom", true);
@onready var btn_charisma : Button = self.find_child("Charisma", true);

@onready var btn_reflect = self.find_child("Reflect");
var reflect_target : Node;
var ability = ""
var option_was_selected := false

# Called when the node enters the scene tree for the first time.
func _ready():
	btn_reflect.connect('toggled', self.on_reflect_pressed);
	btn_charisma.pressed.connect(on_charisma_pressed)
	btn_wisdom.pressed.connect(on_wisdom_pressed)
	btn_strength.pressed.connect(on_strength_pressed)
	pass # Replace with function body.


func on_become_visible():
	if self.visible:
		self.grab_focus()
	pass


func on_strength_pressed():
	ability = "strong"
	option_was_selected = true


func on_wisdom_pressed():
	ability = "wise"
	option_was_selected = true


func on_charisma_pressed():
	ability = "charismatic"
	option_was_selected = true


func on_reflect_pressed(_h:=true):
	if option_was_selected:
		print(reflect_target, ability);
		store_ability( str(ability) )
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
