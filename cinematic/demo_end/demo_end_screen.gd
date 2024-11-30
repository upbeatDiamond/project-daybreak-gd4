extends Cinematic

var progress := 0;
const INPUT_COOLDOWN_DEFAULT := 10.0;
const INPUT_COOLDOWN_RATE := 4.0;

const STAGE_MAX = 15

var input_cooldown := INPUT_COOLDOWN_DEFAULT / 2;
var stage_locked := false;
var stage_finished := true;
var cine_finished := false;
@onready var music_layers = [ $Background/AudioIntroHeartbeat, $Background/AudioIntroBrightness, $Background/AudioIntroDarkness, $Background/AudioIntroTheremin, $Background/AudioIntroNewAge ];
@onready var intro_ability = self.find_child("Ability", true);

var volume_test = 99999


var return_code = ""

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
	
	for i in [intro_ability]:
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
	#find_child("Gamepiece").visible = false;
	# set all direct children of Selections to invisible
	
	for n in (self.find_child("Selection", true) as Container).get_children():
		n.visible = false;
		pass
	
	if stage > STAGE_MAX:
		stage = STAGE_MAX
	
	match stage:
		0:
			set_prompt("My sincerest apologies.");
			music_fade_in(0);
			pass
		1:
			set_prompt("It seems our time has run short.");
			music_fade_in(1);
			pass
		2:
			if GlobalDatabase.load_keyval("battle_tutorial") == "win":
				set_prompt("In the end, you managed to stave off the beast.")
				music_fade_in(2);
			else:
				set_prompt("In the end, your team became overwhelmed.");
			pass
		3:
			set_prompt("You were brought to hospital, and your wounds were healed");
			pass
		4:
			set_prompt("Those who fought for you bickered, fighting over which one was the best.");
			pass
		5:
			set_prompt("Green: No, that's wrong. \nBlue: It's on you, Girtab.
Green / Girtab: No, that's Bull! \nRed: My name's not Bull, you know that. Arided, back me up.
Blue / Arided: You can't back up any further without stepping on my tail, Nath.
");
			pass
		6:
			set_prompt("Girtab is a scorpion with a flower bud tail. \nHe seems shy and asocial, but will listen to your guidance.\n
Arided is a capricorn, who seems to be the leader. \nHe prefers to diffuse social conflict using humor and quips.\n
Nath is a bull, who is bold and brash. \nHe doesn't like to be told how to fight, but seems to struggle with strategy.");
			pass
		7:
			set_prompt(str( "The three look at you. Arided asks, 'So? Which of us is gonna fight with you?'"));
			#revise_gender.set_text( str("My friends would say ", parse_pronoun(), " a ", parse_gender()) )
			var ability_grid = (self.find_child("Ability", true) as Container)
			(ability_grid.find_child("BtnFire") as Button).pressed.connect(func(): GlobalDatabase.save_keyval("i_choose_you", "fire"); stage_finished = true)
			(ability_grid.find_child("BtnGrass") as Button).pressed.connect(func(): GlobalDatabase.save_keyval("i_choose_you", "grass"); stage_finished = true)
			(ability_grid.find_child("BtnWater") as Button).pressed.connect(func(): GlobalDatabase.save_keyval("i_choose_you", "water"); stage_finished = true)
			ability_grid.visible = true;
			ability_grid.find_child("Reflect", true).grab_focus()
			
			stage_finished = false;
			pass
		8:
			set_prompt("Excellent. A passcode will generate soon, so you may return to this dream someday");
			music_fade_in(3);
			pass
		9:
			set_prompt("Be ready to write it down.");
			#GlobalDatabase.save_keyval("player_palette_base", find_child("Gamepiece").find_child("SpriteBase").material.get_shader_parameter("palette"))
			#GlobalDatabase.save_keyval("player_palette_accent", find_child("Gamepiece").find_child("SpriteAccent").material.get_shader_parameter("palette"))
			self.return_code = compress_progress()
			pass
		10:
			set_prompt(str( "Excellent. Your code is: ", return_code) );
			#stage_finished = false;
			pass
		11:
			set_prompt(str("So long as you remember this code and your name, ", GlobalDatabase.load_keyval("player_name"), ", you may return someday.") );
			music_fade_in(4);
			pass
		12:
			set_prompt(str("Again, that's ", return_code) );
			music_fade_in(-1);
			pass
		13:
			set_prompt(". . .");
			#music_fade_in(5);
			#parse_goback();
			pass
		14:
			set_prompt("Thank you for dreaming with me.");
			GlobalDatabase.save_keyval("demo_complete", true)
			pass
		15:
			stage_finished = false;
			set_prompt("The End?");
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


func compress_progress():
	
	var pname = str( GlobalDatabase.load_keyval("player_name") )
	pname = pname.substr( 0, min(16, pname.length() ) )
	var data = []; data.resize(8)
	
	## Fitzpatrick scale, with Emoji range (yellow, FITZ-1-2, FITZ-3, FITZ-4, etc)
	match GlobalDatabase.load_keyval("player_sprite_base_palette"):
		"black":
			data[0] = 6
		"dark":
			data[0] = 5
		"shiny":
			data[0] = 1 # Shiny color
		"pale":
			data[0] = 3
		"white":
			data[0] = 2
		_:
			data[0] = 4 # Common color, default in case of null / invalid
	
	match GlobalDatabase.load_keyval("player_sprite_accent_palette"):
		"black":
			data[1] = 6
		"dark":
			data[1] = 5
		"shiny":
			data[1] = 1 # Shiny color
		"pale":
			data[1] = 3
		"white":
			data[1] = 2
		_:
			data[1] = 4 # Common color, default in case of null / invalid
	
	var genderString : String = str(GlobalDatabase.load_keyval("player_gender"))
	var genderByte = 0
	if genderString.contains("m"):
		genderByte += 1
	if genderString.contains("f"):
		genderByte += (1 << 1)
	if genderString.contains("c"):
		genderByte += (1 << 2)
	if genderString.contains("n"):
		genderByte += (1 << 3)
	if genderString.contains("M"):
		genderByte += (1 << 4)
	if genderString.contains("F"):
		genderByte += (1 << 5)
	if genderString.contains("C"):
		genderByte += (1 << 6)
	if genderString.contains("N"):
		genderByte += (1 << 7)
	
	data[2] = genderByte
	
	var cutsceneCounter = 0
	# Intro Dream Complete is assumed to be '1' or greater already, so skip.
	# Knocked is assumed to be 1 specifically, so reuse slot for Ability
	data [4] = str(GlobalDatabase.load_keyval("ch1_hug_init")).to_int()
	data [5] = str(GlobalDatabase.load_keyval("ch1_got_spanner")).to_int()
	data [6] = str(GlobalDatabase.load_keyval("ch1_dismiss_player")).to_int()
	
	match GlobalDatabase.load_keyval("player_ability").strip_edges().to_lower():
		"strong", "strength":
			data[3] = 1
		"wise", "wisdom":
			data[3] = 2
		_:
			data[3] = 3
	
	var battleResult = 0
	if str(GlobalDatabase.load_keyval("battle_tutorial")) == "win":
		battleResult += (1 << 4) # 1 << 4 = 8
	
	var chooseYou = str(GlobalDatabase.load_keyval("i_choose_you") ).to_lower().strip_edges()
	if chooseYou == "fire":
		battleResult += 1 # 1 or 9
	elif chooseYou == "grass":
		battleResult += 2 # 2 or 10
	else:
		battleResult += 3 # 3 or 11
	
	data [7] = battleResult
	
	var packed = PackedByteArray([])
	packed.resize( data.size() + 4 )
	for i in range(  data.size()):
		packed.encode_s8( i, data[i] )
	packed.encode_s64( data.size(), 20241203 )
	
	var encryptor = TrickleDown.new()
	var shape_in : Array[int] = [ 15, 16,  8,  5, 12, 2, 3, 9, 10, 11, 7, 14, 13, 6, 1, 4,]
	var shape_out : Array[int] = [ 3, 6, 12, 11, 8, 4, 5, 9, 13, 16, 10, 7, 1, 15, 14, 2, ]
	return encryptor.encode( shape_in, shape_out, pname, packed.hex_encode().to_lower(), 5 )
	
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
	
	#GlobalRuntime.scene_manager.fade_in(0.25)
	# ... then end the cinematic.
	#cinematic_finished.emit(self)
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
