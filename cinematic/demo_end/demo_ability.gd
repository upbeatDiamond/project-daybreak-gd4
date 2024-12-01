extends HBoxContainer



@onready var btn_fire : Button = self.find_child("BtnFire", true);
@onready var btn_grass : Button = self.find_child("BtnGrass", true);
@onready var btn_water : Button = self.find_child("BtnWater", true);

@onready var btn_reflect = self.find_child("Reflect");
var reflect_target : Node;
var ability = ""
var option_was_selected := false

# Called when the node enters the scene tree for the first time.
func _ready():
	btn_reflect.connect('toggled', self.on_reflect_pressed);
	btn_water.pressed.connect(on_water_pressed)
	btn_grass.pressed.connect(on_grass_pressed)
	btn_fire.pressed.connect(on_fire_pressed)
	pass # Replace with function body.


func on_become_visible():
	if self.visible:
		self.grab_focus()
	pass


func on_fire_pressed():
	ability = "fire"
	option_was_selected = true


func on_grass_pressed():
	ability = "grass"
	option_was_selected = true


func on_water_pressed():
	ability = "water"
	option_was_selected = true


func on_reflect_pressed(_h:=true):
	if option_was_selected:
		print(reflect_target, ability);
		store_ability( str(ability) )
	pass



func store_ability( ability ):
	if reflect_target != null && reflect_target.has_method( 'on_reflect_kv' ):
		reflect_target.on_reflect_kv("i_choose_you", ability);
	GlobalDatabase.save_keyval("i_choose_you", ability)
	pass


func set_reflect_target(n:Node):
	reflect_target = n;


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
