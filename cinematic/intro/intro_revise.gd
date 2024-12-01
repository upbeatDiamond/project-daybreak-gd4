extends VBoxContainer


@onready var revise_name = self.find_child("*Nam*", true);
@onready var revise_gender = self.find_child("*Gender*", true);
@onready var revise_form = self.find_child("*Form*", true);
@onready var revise_ability = self.find_child("*Ability*", true);

@onready var btn_reflect = self.find_child("Reflect");
var reflect_target : Node;


# Called when the node enters the scene tree for the first time.
func _ready():
	btn_reflect.connect('pressed', self.on_reflect_pressed);
	revise_ability.connect('pressed', self.on_revise_ability);
	revise_form.connect('pressed', self.on_revise_form);
	revise_gender.connect('pressed', self.on_revise_gender);
	revise_name.connect('pressed', self.on_revise_name);
	pass # Replace with function body.


func on_revise_ability(_h:=true):
	store_goback( "ability" )
	pass


func on_revise_form(_h:=true):
	store_goback( "form" )
	pass


func on_revise_gender(_h:=true):
	store_goback( "gender" )
	pass


func on_revise_name(_h:=true):
	store_goback( "name" )
	pass


func on_reflect_pressed(_h:=true):
	var gclass = 'goforth'
	print(reflect_target, gclass);
	store_goback( str(gclass) )
	pass


func store_goback( goback ):
	if reflect_target != null && reflect_target.has_method( 'on_reflect_kv' ):
		reflect_target.on_reflect_kv("goback", goback);
	pass


func set_reflect_target(n:Node):
	reflect_target = n;


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
