extends HBoxContainer



@onready var pronoun_m = self.find_child("MascPron", true);
@onready var pronoun_f = self.find_child("FemnPron", true);
@onready var pronoun_n = self.find_child("NeutPron", true);
@onready var pronoun_c = self.find_child("ComnPron", true);

@onready var class_m = self.find_child("MascClass", true);
@onready var class_f = self.find_child("FemnClass", true);
@onready var class_n = self.find_child("NeutClass", true);
@onready var class_c = self.find_child("ComnClass", true);

@onready var btn_reflect = self.find_child("Reflect");
var reflect_target : Node;


# Called when the node enters the scene tree for the first time.
func _ready():
	btn_reflect.connect('toggled', self.on_reflect_pressed);
	#name_edit.connect('text_submitted', self.on_text_submitted);
	print( str("pronoun_m -- ",pronoun_m) );
	pass # Replace with function body.

func on_become_visible():
	if self.visible:
		pronoun_n.grab_focus()
	pass

func on_reflect_pressed(_h:=true):
	var gender = ''
	var gclass = ''
	if pronoun_m.button_pressed:
		gender += 'm'
	if pronoun_f.button_pressed:
		gender += 'f'
	if pronoun_n.button_pressed:
		gender += 'n'
	if pronoun_c.button_pressed or gender == '':
		gender += 'c'
	if class_m.button_pressed:
		gclass += 'M'
	if class_f.button_pressed:
		gclass += 'F'
	if class_n.button_pressed:
		gclass += 'N'
	if class_c.button_pressed or gclass == '':
		gclass += 'C'
	
	print(reflect_target, gender, gclass);
	
	store_gender( str(gender, gclass) )
	pass

func store_gender( gender ):
	if reflect_target != null && reflect_target.has_method( 'on_reflect_kv' ):
		reflect_target.on_reflect_kv("player_gender", gender);
	pass

func set_reflect_target(n:Node):
	reflect_target = n;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
