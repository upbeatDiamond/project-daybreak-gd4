extends Cinematic

var progress := 0;
const INPUT_COOLDOWN_DEFAULT := 10.0;
const INPUT_COOLDOWN_RATE := 4.0;


const STAGE_MAX = 15

var input_cooldown := INPUT_COOLDOWN_DEFAULT / 2;
var stage_locked := false;
var stage_finished := true;
var cine_finished := false;
@onready var intro_naming  = self.find_child("Naming",  true);
@onready var intro_gender  = self.find_child("Gender",  true);
@onready var intro_form    = self.find_child("Form",    true);
@onready var intro_ability = self.find_child("Ability", true);
@onready var intro_revise  = self.find_child("Revise",  true);
@onready var music_layers = [ $Background/AudioIntroHeartbeat, $Background/AudioIntroBrightness, $Background/AudioIntroDarkness, $Background/AudioIntroTheremin, $Background/AudioIntroNewAge ];

@onready var revise_name = intro_revise.find_child("*Nam*", true);
@onready var revise_gender = intro_revise.find_child("*Gender*", true);
@onready var revise_form = intro_revise.find_child("*Form*", true);
@onready var revise_ability = intro_revise.find_child("*Ability", true);

var volume_test = 99999

signal reflect_kv(key, value);
#signal request_kv(key, asker);
#signal intro_finished(cutscene);

var kv_bank = {};

# Called when the node enters the scene tree for the first time.
func _ready():
	
	size = Vector2(1152, 648)
	
	$Background/AudioIntroHeartbeat.set_stream( load("res://assets/music/intro_heartbeat.mp3") )
	$Background/AudioIntroBrightness.set_stream( load("res://assets/music/intro_brightness.mp3") )
	$Background/AudioIntroDarkness.set_stream( load("res://assets/music/intro_darkness.mp3") )
	$Background/AudioIntroTheremin.set_stream( load("res://assets/music/intro_theremin.mp3") )
	$Background/AudioIntroNewAge.set_stream( load("res://assets/music/intro_new_age.mp3") )
	
	var music_tween = create_tween()
	music_tween.tween_property(self, "volume_test", 0, 0.5)
	music_tween.pause()
	music_fade_out( -1 )
	for layer in music_layers:
		layer.volume_db = -80
		layer.play()
		pass
	
	print( music_layers[0].playing, " is playing?" )
	
	self.find_child("Survey", true).modulate= Color(1,1,1,0);
	self.reflect_kv.connect( self.on_reflect_kv ) #request_kv
	
	for i in [intro_naming, intro_gender, intro_form, intro_ability, intro_revise]:
		if i.has_method( 'set_reflect_target' ):
			i.set_reflect_target( self );
			pass
	
	music_fade_in(0);
	
	switch_stage(0);
	pass # Replace with function body.


func _on_reflect_kv(key, value):
	on_reflect_kv(key, value)
	pass


func on_reflect_kv(key, value):
	kv_bank[key] = value;
	stage_finished = true;
	play_next_stage();
	#GlobalDatabase.insert_tuple_into_table( "key, value", [str(key), str(value)], GlobalDatabase.SystemData );


# CODE DIRECTLY BELOW IS FOR THE DATABASE MANAGER CLASS TO HOLD/USE.
#func insert_tuple_into_table( columns, attributes, table );
#	var binder = "";
#	for attr in attributes:
#		binder += "?,"
#	binder = binder.trim_suffix(",");
#	return query_with_bindings( 
#		str("INSERT INTO " + table + " (" + columns + ") VALUES (" + binder + ")" ),
#		attributes );

func sanitize(txt) -> String:
	txt = txt.replace('&', '\\&');
	txt = txt.replace(';', '&semi;');
	txt = txt.replace('\\&', '&amp;');
	txt = txt.replace('"', '&quot');
	txt = txt.replace("'", '&apos');
	txt = txt.replace('#', '&num');
	#txt = txt.replace('', '');
	return txt;

func desanitize(txt) -> String:
	txt = txt.replace('"', '&quot');
	txt = txt.replace("'", '&apos');
	txt = txt.replace('#', '&num');

	txt = txt.replace('&semi;', ';');
	txt = txt.replace('&amp;', '&');

	return txt;


func _physics_process(delta):
	if input_cooldown > 0:
		input_cooldown -= 4 * delta;
	input_cooldown = -6;
	
	if Input.is_action_pressed("ui_accept"):
		play_next_stage()


func play_next_stage():
	#print(input_cooldown);
	
	if input_cooldown <= 0 && !stage_locked && stage_finished:
		# Move as long as the key/button is pressed.
		progress = (progress + 1)
		input_cooldown = INPUT_COOLDOWN_DEFAULT;
		switch_stage( progress )


func switch_stage(stage:int):
	
	
	
	# fade out all elements except the background
	stage_locked = true
	var survey = self.find_child("Survey", true);
	var tween = get_tree().create_tween();
	tween.tween_property(survey, "modulate", Color(1, 1, 1, 0), 0.5);
	await tween.finished
	
	survey.visible = false;
	find_child("Gamepiece").visible = false;
	# set all direct children of Selections to invisible
	
	for n in (self.find_child("Selection", true) as Container).get_children():
		n.visible = false;
		pass
	
	if stage > STAGE_MAX:
		stage = STAGE_MAX
	
	match stage:
		0:
			set_prompt(". . .");
			pass
		1:
			set_prompt("Let us imagine a world together.");
			pass
		2:
			set_prompt("A world which is better, yet still flawed at its core.");
			pass
		3:
			set_prompt("A world where you are yet to accept yourself, just as its people are yet to accept each other.");
			pass
		4:
			set_prompt("In this world, what might your name be?");
			(intro_naming as Container).visible = true;
			music_fade_out(2);
			music_fade_out(3);
			music_fade_out(4);
			music_fade_out(5);
			stage_finished = false;
			pass
		5:
			set_prompt(str( "Ah, ", kv_bank["player_name"] ,", a title with great meaning and power.") );
			revise_name.set_text( str("My name is ", kv_bank["player_name"]) )
			GlobalDatabase.save_keyval("player_name", kv_bank["player_name"])
			music_fade_in(1);
			pass
		6:
			set_prompt("In this world, how should people perceive your role?");
			(self.find_child("Gender", true) as Container).visible = true;
			music_fade_out(3);
			music_fade_out(4);
			music_fade_out(5);
			stage_finished = false;
			pass
		7:
			set_prompt(str( "Interesting. This world could always use another ", parse_gender() ," like you."));
			revise_gender.set_text( str("My friends would say ", parse_pronoun(), " a ", parse_gender()) )
			music_fade_in(2);
			pass
		8:
			set_prompt("In this world, how would people perceive your form?");
			var form_meta = (self.find_child("FormMeta", true) as Container)
			form_meta.visible = true;
			find_child("Gamepiece").visible = true;
			music_fade_out(4);
			music_fade_out(5);
			stage_finished = false;
			pass
		9:
			set_prompt("Fascinating. The canvas of life now looks ever more vibrant.");
			#GlobalDatabase.save_keyval("player_palette_base", find_child("Gamepiece").find_child("SpriteBase").material.get_shader_parameter("palette"))
			#GlobalDatabase.save_keyval("player_palette_accent", find_child("Gamepiece").find_child("SpriteAccent").material.get_shader_parameter("palette"))
			music_fade_in(3);
			pass
		10:
			set_prompt("In this world, how could people perceive your abilities?");
			(self.find_child("Ability", true) as Container).visible = true;
			music_fade_out(5);
			#stage_finished = false;
			pass
		11:
			set_prompt("There exists exceptional potential within you.");
			music_fade_in(4);
			pass
		12:
			set_prompt("Would you like to revise your answers? Once submitted, not all of them can be changed.");
			(self.find_child("Revise", true) as Container).visible = true;
			music_fade_in(-1);
			stage_finished = false;
			pass
		13:
			set_prompt(". . .");
			#music_fade_in(5);
			parse_goback();
			pass
		14:
			set_prompt("Thank you for imagining with me.");
			pass
		15:
			stage_finished = false;
			set_prompt("Now I know what kind of monster you are.");
			#(self.find_child("Prompt", true) as Container).visible = true;
			
			cine_finished = true
			
			pass
		_:
			pass
	
	tween.kill();
	tween = get_tree().create_tween();
	tween.tween_property(survey, "modulate", Color(1, 1, 1, 1), 0.5);
	survey.visible = true;
	tween.play();
	await tween.finished
	
	if (cine_finished):
		await music_end()
	else:
		stage_locked = false;
	
	pass


func set_prompt(txt:String):
	var label = self.find_child("Prompt", true)
	if label != null:
		label.text = txt;


func parse_pronoun() -> String:
	var gendre;
	if kv_bank.has("player_gender"):
		gendre = kv_bank["player_gender"]
		if gendre.contains('c'):
			return "ey is";
		elif gendre.contains('m'):
			if gendre.contains('f'):
				if gendre.contains('n'):
					return "he/she is"
				return "she/he is";
			elif gendre.contains('n'):
				return "they are";
			return "he is";
		elif gendre.contains('f'):
			if gendre.contains('n'):
				return "they are";
			return "she is";
		elif gendre.contains('n'):
			return "they are"
	return "th3y are"


func parse_gender() -> String:
	var gendre;
	if kv_bank.has("player_gender"):
		gendre = kv_bank["player_gender"]
		if gendre.contains('C'):
			return "youth";
		elif gendre.contains('M'):
			if gendre.contains('F'):
				if gendre.contains('N'):
					return "youth"
				return "youngling";
			elif gendre.contains('N'):
				return "youth";
			return "boy";
		elif gendre.contains('F'):
			if gendre.contains('N'):
				return "child";
			return "girl";
		elif gendre.contains('N'):
			return "person"
	return "kid"


func parse_goback():
	var goback := progress
	if kv_bank.has("goback"):
		#goback = str(0, kv_bank.get("goback")).to_int()
		match kv_bank.get("goback"):
			"name":
				goback = 4;
			"gender":
				goback = 6;
			"form":
				goback = 8;
			"ability":
				goback = 10;
			_:
				goback = str(0, kv_bank.get("goback")).to_int()
				
		if kv_bank.get("goback") != 'goforth':
			progress -= 2
		
		switch_stage(goback)
	kv_bank.erase("goback")
	pass


"""
	This function ends the entire Cinematic.
	The name represents its primary function: playing the closing musical notes
"""
func music_end():
	$Background/AudioIntroHeartbeat.set_stream( load("res://assets/music/intro_heartbeat_end.mp3") )
	$Background/AudioIntroBrightness.set_stream( load("res://assets/music/intro_brightness_end.mp3") )
	$Background/AudioIntroDarkness.set_stream( load("res://assets/music/intro_darkness_end.mp3") )
	$Background/AudioIntroTheremin.set_stream( load("res://assets/music/intro_theremin_end.mp3") )
	$Background/AudioIntroNewAge.set_stream( load("res://assets/music/intro_new_age_end.mp3") )
	
	for layer in music_layers:
		layer.play()
		pass
	
	# Give the system a moment to adjust
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	
	GlobalRuntime.scene_manager.fade_to_black($Background/AudioIntroHeartbeat.stream.get_length())
	# If the song is not over, wait it out...
	if ($Background/AudioIntroBrightness as AudioStreamPlayer).playing:
		await $Background/AudioIntroBrightness.finished
	
	#await GlobalRuntime.scene_manager.fade_out_finished
	
	GlobalRuntime.scene_manager.fade_in(0.25)
	# ... then end the cinematic.
	cinematic_finished.emit(self)
	return


func music_fade_in(layer:int):
	var another_tween
	
	if layer < 0:
		for music in music_layers:
			if music != null:
				another_tween = get_tree().create_tween()
				another_tween.tween_property(music_layers[layer], "volume_db", -10, 2.5)
				another_tween.play()
				print( music_layers[layer].volume_db, " vol db ++" )
		return;
	
	if layer < music_layers.size() && music_layers[layer] != null:
		another_tween = get_tree().create_tween()
		another_tween.tween_property(music_layers[layer], "volume_db", -10, 2.5)
		another_tween.play()
		print( music_layers[layer].volume_db, " vol db +++" )
		pass
	
	pass


func music_fade_out(layer:int):
	var another_tween
	
	if layer < 0:
		for music in music_layers:
			if music != null:
				another_tween = get_tree().create_tween()
				another_tween.tween_property(music_layers[layer], "volume_db", -80, 1.5)
				another_tween.play()
				print( music_layers[layer].volume_db, " vol db --" )
		return;
	
	if layer < music_layers.size() && music_layers[layer] != null:
		another_tween = get_tree().create_tween()
		another_tween.tween_property(music_layers[layer], "volume_db", -80, 1.5)
		another_tween.play()
		print( music_layers[layer].volume_db, " vol db ---" )
		pass
	
	pass
