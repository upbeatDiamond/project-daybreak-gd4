extends GridContainer



@onready var form_node = self.get_parent().find_child("Form", true);
@onready var btn_grp_skin = form_node.find_child("SkinBtn", true);
@onready var btn_grp_hair = form_node.find_child("HairBtn", true);
@onready var btn_grp_shape = form_node.find_child("ShapeBtn", true);
#@onready var proXnoun_c = self.find_chilXd("ComnPron", true);

@onready var skin_white 	= btn_grp_skin.find_child("SkinColorWhite", true);
@onready var skin_pale 		= btn_grp_skin.find_child("SkinColorPale", true);
@onready var skin_shiny 	= btn_grp_skin.find_child("SkinColorShiny", true);
@onready var skin_common 	= btn_grp_skin.find_child("SkinColorNeutral", true);
@onready var skin_dark 		= btn_grp_skin.find_child("SkinColorDark", true);
@onready var skin_black 	= btn_grp_skin.find_child("SkinColorBlack", true);

@onready var hair_white 	= btn_grp_hair.find_child("HairColorWhite", true);
@onready var hair_pale 		= btn_grp_hair.find_child("HairColorPale", true);
@onready var hair_shiny 	= btn_grp_hair.find_child("HairColorShiny", true);
@onready var hair_common 	= btn_grp_hair.find_child("HairColorNeutral", true);
@onready var hair_dark 		= btn_grp_hair.find_child("HairColorDark", true);
@onready var hair_black 	= btn_grp_hair.find_child("HairColorBlack", true);

@onready var style_masc		= btn_grp_shape.find_child("ShapeStyleMasc");
@onready var style_neut		= btn_grp_shape.find_child("ShapeStyleNeut");
@onready var style_fem		= btn_grp_shape.find_child("ShapeStyleFem");

@onready var btn_reflect = self.find_child("Reflect");
var reflect_target : Node;

@onready var form_meta 		= self.get_parent()

# Called when the node enters the scene tree for the first time.
func _ready():
	btn_reflect.connect('toggled', self.on_reflect_pressed);
	#name_edit.connect('text_submitted', self.on_text_submitted);
	print( str("btn_grp_shape -- ",btn_grp_shape) );
	
	skin_black.connect("pressed", on_skin_black_pressed)
	skin_dark.connect("pressed", on_skin_dark_pressed)
	skin_common.connect("pressed", on_skin_common_pressed)
	skin_pale.connect("pressed", on_skin_pale_pressed)
	skin_white.connect("pressed", on_skin_white_pressed)
	skin_shiny.connect("pressed", on_skin_shiny_pressed)
	hair_black.connect("pressed", on_hair_black_pressed)
	hair_dark.connect("pressed", on_hair_dark_pressed)
	hair_common.connect("pressed", on_hair_common_pressed)
	hair_pale.connect("pressed", on_hair_pale_pressed)
	hair_white.connect("pressed", on_hair_white_pressed)
	hair_shiny.connect("pressed", on_hair_shiny_pressed)
	
	pass # Replace with function body.

func on_reflect_pressed(_h:=true):
	var color_primary = 'n'
	var hormone = 'n'
	var color_secondary = 'n'
	#var gclass = ''
	if skin_pale.button_pressed:
		color_primary = 'p'
	elif skin_dark.button_pressed:
		color_primary = 'd'
	elif skin_shiny.button_pressed:
		color_primary = 's'
	elif skin_black.button_pressed:
		color_primary = 'b'
	elif skin_white.button_pressed:
		color_primary = 'w'
	else:#if skin_white.button_pressed:
		color_primary = 'n'
	
	if hair_pale.button_pressed:
		color_secondary = 'p'
	elif hair_dark.button_pressed:
		color_secondary = 'd'
	elif hair_shiny.button_pressed:
		color_secondary = 's'
	elif hair_black.button_pressed:
		color_secondary = 'b'
	elif hair_white.button_pressed:
		color_secondary = 'w'
	else:#if skin_white.button_pressed:
		color_secondary = 'n'
	
	if style_fem.button_pressed:
		hormone = 't'
	elif style_masc.button_pressed:
		hormone = 'e'
	else:#if skin_white.button_pressed:
		hormone = 'b'
	
	print(reflect_target, color_primary, hormone, color_secondary);
	
	store_form( color_primary, hormone, color_secondary )
	pass

func store_form( color_primary, hormone, color_secondary ):
	if reflect_target != null && reflect_target.has_method( 'on_reflect_kv' ):
		reflect_target.on_reflect_kv("player_color_primary", color_primary);
		reflect_target.on_reflect_kv("player_hormone", hormone); 
		reflect_target.on_reflect_kv("player_color_secondary", color_secondary);
	pass

func set_reflect_target(n:Node):
	reflect_target = n;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func on_skin_white_pressed():
	reflect_target.find_child("Gamepiece").find_child("SpriteBase").material.set_shader_parameter("palette", load("res://assets/textures/monsters/overworld/human/human_palette_white.png") )
	GlobalDatabase.save_keyval("player_sprite_base_palette", "white")
	pass

func on_skin_pale_pressed():
	reflect_target.find_child("Gamepiece").find_child("SpriteBase").material.set_shader_parameter("palette", load("res://assets/textures/monsters/overworld/human/human_palette_pale.png") )
	GlobalDatabase.save_keyval("player_sprite_base_palette", "pale")
	pass

func on_skin_common_pressed():
	reflect_target.find_child("Gamepiece").find_child("SpriteBase").material.set_shader_parameter("palette", load("res://assets/textures/monsters/overworld/human/human_palette_common.png") )
	GlobalDatabase.save_keyval("player_sprite_base_palette", "common")
	pass

func on_skin_dark_pressed():
	reflect_target.find_child("Gamepiece").find_child("SpriteBase").material.set_shader_parameter("palette", load("res://assets/textures/monsters/overworld/human/human_palette_dark.png") )
	GlobalDatabase.save_keyval("player_sprite_base_palette", "dark")
	pass

func on_skin_black_pressed():
	reflect_target.find_child("Gamepiece").find_child("SpriteBase").material.set_shader_parameter("palette", load("res://assets/textures/monsters/overworld/human/human_palette_black.png") )
	GlobalDatabase.save_keyval("player_sprite_base_palette", "black")
	pass

func on_skin_shiny_pressed():
	reflect_target.find_child("Gamepiece").find_child("SpriteBase").material.set_shader_parameter("palette", load("res://assets/textures/monsters/overworld/human/human_palette_shiny.png") )
	GlobalDatabase.save_keyval("player_sprite_base_palette", "shiny")
	pass

func on_hair_white_pressed():
	reflect_target.find_child("Gamepiece").find_child("SpriteAccent").material.set_shader_parameter("palette", load("res://assets/textures/monsters/overworld/human/human_palette_hair_white.png") )
	GlobalDatabase.save_keyval("player_sprite_accent_palette", "white")
	pass

func on_hair_pale_pressed():
	reflect_target.find_child("Gamepiece").find_child("SpriteAccent").material.set_shader_parameter("palette", load("res://assets/textures/monsters/overworld/human/human_palette_hair_pale.png") )
	GlobalDatabase.save_keyval("player_sprite_accent_palette", "pale")
	pass

func on_hair_common_pressed():
	reflect_target.find_child("Gamepiece").find_child("SpriteAccent").material.set_shader_parameter("palette", load("res://assets/textures/monsters/overworld/human/human_palette_hair_common.png") )
	GlobalDatabase.save_keyval("player_sprite_accent_palette", "common")
	pass

func on_hair_dark_pressed():
	reflect_target.find_child("Gamepiece").find_child("SpriteAccent").material.set_shader_parameter("palette", load("res://assets/textures/monsters/overworld/human/human_palette_hair_dark.png") )
	GlobalDatabase.save_keyval("player_sprite_accent_palette", "dark")
	pass

func on_hair_black_pressed():
	reflect_target.find_child("Gamepiece").find_child("SpriteAccent").material.set_shader_parameter("palette", load("res://assets/textures/monsters/overworld/human/human_palette_hair_black.png") )
	GlobalDatabase.save_keyval("player_sprite_accent_palette", "black")
	pass

func on_hair_shiny_pressed():
	reflect_target.find_child("Gamepiece").find_child("SpriteAccent").material.set_shader_parameter("palette", load("res://assets/textures/monsters/overworld/human/human_palette_hair_shiny.png") )
	GlobalDatabase.save_keyval("player_sprite_accent_palette", "shiny")
	pass
