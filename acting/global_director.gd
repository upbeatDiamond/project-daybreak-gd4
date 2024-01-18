extends Node
class_name GlobalDirector 
# A director, such as for a stage play or movie
# Curious, as the class name was called GlobalCutsceneDirector for a while...
# It would have stuck if the file name also changed to match ...
# ... but I got too used to the current name.

var current_screenplay#: Screenplay
var director_avatar : EnactorDirector
var key_values := {}
var registered_things := {}	# Stores actor ids, referenced by (key)name
var registered_names := {} 	# Stores displayed name, ref'd by keyname
var registered_alias := {}	# Stores actor pseudonyms

# spritesheet?
var iconsets : Dictionary

#var arr_threads : Array

# names might be unified later
signal assign_actor( umid:int, enactor_id:int )
signal assign_prop( token_id:int, enactor_id:int )

# needs to follow the casting call
signal set_field( enactor_id:int, enactor_field:int )

# outgoing
signal cue_actor( enactor_ref:int, task_id, arguments, thread_id )
signal cue_group( enactor_ref:int, task_id, arguments, thread_id )

# incoming
signal actor_feedback( line_completed, enactor_ref:int, thread_id )

enum STAGE {
	FITUP = 1,
	PERFORMANCE,
}

enum REF_MODE {
	ACTOR = 0,
	GROUP,
}

# Assignment is loosely based on ASCII, HTTP status, and Videotex, in that order
# Aim to keep all values to the 1 byte integer (unsigned) range
# Once an assignment has been used in a script, it cannot be revalued.
# A used assignment can be replaced, but the replacement must be able to use the same parameters.
# Safety is top priority, followed by backwards compatibility, then ease of use.
enum Cuecard {
	WAIT 			= 0, # NUL
	CREATE			= 1, # SOH
	RECRUIT_PIECE	= 2,
	RECRUIT_TOKEN	= 3,
	ASSERT			= 4,	# local variable creation
	ALIAS			= 5,	# more pointers means more safety, right?
	UPDATE_GENDER	= 6,	# for languages beyond English, I suppose.
	UPDATE_VOICE	= 7,	# BEL, talksound
	UPDATE_NAME		= 8,	# BS
	UPDATE_ICON		= 9,	# set this actor's chat icon
	UPDATE_AVATAR	= 10,	# change name, icon, etc from Director
	JUMP			= 11,	# jump unconditional
	JUMP_IF			= 12,	# jump if value/size/length of num/array/str is greater than zero
	JUMP_MATCH		= 13,	# jump if value is similar enough (depends on type; int needs exact)
	CAM_SNAP		= 14,	# camera stops moving, links to current tile position
	CAM_FOLLOW		= 15,	# camera follows an actor
	CAM_EFFECT		= 16,
	SET_POSITION	= 17,
	SET_ROTATION	= 18,
	SET_LOOK		= 19,	# look at point, not actor
	SET_MOOD		= 20,	# set the emotional state; similar to Emote and UpdateIcon
	INTERACT		= 21,	# gamepiece doing something to/with a gametoken (or vice versa?)
	FETCH			= 22,	# transfering data from, say, local gamepiece
	SAVE_ACTOR		= 23,
	LOAD_ACTOR		= 24,
	
	CHMOD			= 28, # FS
	CHGROUP			= 29, # GS
	
	# a very big gap. 
	
	DISMISS			= 127, # DEL
	FREE			= 128,
	#reserved for dismiss/free-type action
	THREAD_SPLIT	= 130,
	THREAD_UNIFY	= 131, # likely interpreted as End This Thread
	JUMP_TARGET		= 132,
	
	STARE_ACTOR		= 134,
	STARE_CLEAR		= 135,
	LOOK_ACTOR		= 136,
	WALK_MODE		= 137, # manually switch between walk, run; adjust speed
	WALK_POINT		= 138, # goal location to walk/swim/run/fly to
	WALK_SPEED		= 139,
	FOLLOW_ACTOR 	= 140,
	WALK_TARGET		= 141, # walk to or very close to a thing.
	WALK_PATH		= 142,
	WALK_CLEAR		= 143,
	
	DB_READ			= 145,
	DB_WRITE		= 146,
	EVAL			= 147,	# assigned depricated at birth
	
	DIALOG			= 203,	# have the gamepiece say this thing
	DIALOG_HIDE		= 204,	# hide the dialog box off-schedule
	DIALOG_CLEAR	= 205,	# clear the contents of the dialog box off-schedule
	DIALOG_INJECT	= 206,	# for continuous dialogue by one speaker
	DIALOG_CHOICE	= 207,	# append a choice; similar to JumpMatch but with buttons!
	
	
	MUSIC			= 210,
	PLAYSOUND		= 211,
	MUTE			= 212,
	
	ANIMATE			= 214,
	PLAY_PAD		= 215,
	
	EMOTE			= 218,	# a little emotion bubble should appear, or change icon. Maybe both.
	
	WEATHER			= 220,
	SET_HOUR		= 221,
	LOCK_HOUR		= 222,
	SET_DATE		= 223,
	LOCK_DATE		= 224,
	
	CINEMATIC		= 230,	# starts a cinematic
	AWAIT_CINE		= 231,	# waits for a cinematic to end
	
	VERSION			= 254,	# Metadata, but as a command... should always be value 254
	FINISH			= 255,	# Ends the entire cutscene, not just a thread. Always maximum value
	
	# And now, aliases:
	#IF				= JUMP_IF,
	#SWITCH			= JUMP_MATCH,
}


func _ready() -> void:
	#actor_feedback.connect(_on_actor_feedback)
	pass


#func _on_actor_feedback( line_completed, enactor_ref:int, thread_id:=0):
	#pass


func load_screenplay_from_file( path:="" ):
	GlobalRuntime.clean_up_node_descent(current_screenplay)
	current_screenplay = Screenplay.new( path )
	pass


func run_next_sequence():
	# Run the next line, no matter what it is
	var next_line = current_screenplay.read_next_event()
	run_event( next_line )
	
	## Run the next line unless it's dialogue or similar
	#while next_line != null:
	#	next_line = current_screenplay.read_next_non_blocking_event()
	#	run_event( next_line )
	#next_line = current_screenplay.read_next_non_preblocking_event()
	#run_event( next_line )
	while next_line != null:
		next_line = current_screenplay.read_next_non_preblocking_event()
		run_event( next_line )


func run_event( line, _thread:int=0 ):
	if line == null:
		return
	
	match line["_cuecard"]:
		Cuecard.CREATE:
			ev_create( line )
			pass
		Cuecard.RECRUIT_PIECE:
			ev_recruit_piece( line )
			pass
		Cuecard.RECRUIT_TOKEN:
			ev_recruit_token( line )
			pass
		Cuecard.JUMP_IF:
			ev_jump_if( line )
			pass
		Cuecard.JUMP_MATCH:
			ev_jump_match( line )
			pass
		Cuecard.DB_READ:
			ev_db_read( line )
			pass
		Cuecard.DB_WRITE:
			ev_db_write( line )
			pass
		Cuecard.EVAL:
			ev_eval( line )
			pass
		Cuecard.MUSIC:
			ev_music( line )
			pass
		Cuecard.WEATHER:
			ev_weather( line )
			pass
		Cuecard.SET_HOUR:
			ev_hour_set( line )
			pass
		Cuecard.LOCK_HOUR:
			ev_hour_lock( line )
			pass
		Cuecard.SET_DATE:
			ev_date_set( line )
			pass
		Cuecard.LOCK_DATE:
			ev_date_lock( line )
			pass
		Cuecard.CINEMATIC:
			ev_cinematic( line )
			pass
		Cuecard.FINISH:
			ev_finish( line )
			pass
		Cuecard.WAIT:
			ev_wait( line )
			pass
		Cuecard.CHMOD:
			ev_chmod( line )
			pass
		Cuecard.CHGROUP:
			ev_chgrp( line )
			pass
		Cuecard.ASSERT:
			ev_declare( line )
			pass
		Cuecard.SET_ROTATION:
			ev_set_rot( line )
			pass
		Cuecard.SET_POSITION:
			ev_set_pos( line )
			pass
		Cuecard.CAM_FOLLOW:
			ev_cam_follow( line )
			pass
		Cuecard.FREE:
			ev_free( line )
			pass
		Cuecard.DISMISS:
			ev_dismiss( line )
			pass
		Cuecard.CAM_SNAP:
			ev_cam_pos( line )
			pass
		Cuecard.PLAYSOUND:
			ev_sound( line )
			pass
		Cuecard.MUTE:
			ev_mute( line )
			pass
		Cuecard.WALK_MODE:
			ev_walk_speed( line )
			pass
		Cuecard.WALK_POINT:
			ev_walk_point( line )
			pass
		Cuecard.FOLLOW_ACTOR:
			ev_walk_follow( line )
			pass
		Cuecard.WALK_PATH:
			ev_walk_path( line )
			pass
		Cuecard.WALK_CLEAR:
			ev_walk_clear( line )
			pass
		Cuecard.LOOK_ACTOR:
			ev_look_actor( line )
			pass
		#Cuecard.STARE_ACTOR:
			#ev_stare_actor( line )
			#pass
		#Cuecard.STARE_CLEAR:
			#ev_stare_clear( line )
			#pass
		Cuecard.ANIMATE:
			ev_animate( line )
			pass
		Cuecard.CAM_EFFECT:
			ev_cam_effect( line )
			pass
		Cuecard.EMOTE:
			ev_emote( line )
			pass
		#Cuecard.THREAD_SPLIT:
			#ev_thread_split( line )
			#pass
		#Cuecard.THREAD_UNIFY:
			#ev_thread_merge( line )
			#pass
		#Cuecard.PLAY_PAD:
			#ev_play_pad( line )
			#pass
		#Cuecard.PIPE:
		#	ev_pipe( line )
		#	pass
		#Cuecard.SET_LOOK:
			#ev_look_at( line )
			#pass
		Cuecard.DIALOG:
			ev_dialog( line )
			pass
		Cuecard.DIALOG_INJECT:
			ev_dialog_inject( line )
			pass
		Cuecard.DIALOG_CLEAR:
			ev_dialog_clear( line )
			pass
		Cuecard.DIALOG_CHOICE:
			ev_dialog_choice( line )
			pass
		#Cuecard.UPDATE_ICON:
			#ev_icon( line )
			#pass
		#Cuecard.INTERACT:
			#ev_interact( line )
			pass
		_:
			cue_actor.emit( actor_id_from_name(line["_actor"]), line["_cuecard"], line, _thread )
	pass


func actor_id_from_name( actor_name:String ):
	if registered_things.has(actor_name):
		return registered_things[actor_name]
	elif registered_alias.has(actor_name):
		return registered_things[ registered_alias[actor_name] ]
	else:
		return -1;


func ev_cue_actor( enactor_id: int, cue:Cuecard, parameters, thread_id:=0 ):
	#if is_group:
	#	cue_group.emit( enactor_id, cue, parameters, thread_id )
	#	return
	cue_actor.emit( enactor_id, cue, parameters, thread_id )

# Parameters:
# target -- target to jump to
# line -- line number to jump to (if target is invalid)
func ev_jump( parameters:Dictionary ):
	if current_screenplay == null:
		return
	if parameters.has["target"] and current_screenplay.is_track_target_valid(parameters["target"]):
		current_screenplay.track_to_target(parameters["target"])
		return
	if parameters.has["line"]:
		current_screenplay.track_to_line(parameters["line"])
	return

# Parameters:
# condition -- statement to evaluate
# true_jump -- jump on eval = true, positive
# false (opt) -- jump on eval = false, 0, negative
func ev_jump_if( parameters:Dictionary ):
	if !parameters.has("condition"):
		return
	
	if ev_eval( parameters["condition"] ) and parameters.has("true_jump"):
		ev_jump( parameters["true_jump"] )
	elif parameters.has("false_jump"):
		ev_jump( parameters["false_jump"] )
	return

# Parameters:
# compare -- variable to compare
# match -- variable match conditions
func ev_jump_match( parameters:Dictionary ):
	if parameters.has(""):
		pass
	#run_task(  parameters["options"][ ev_eval(parameters["compare"]) ]  )

# Parameters:
# name -- a known name for the actor/prop
# rename -- a new alias used for the actor/prop
func ev_alias( parameters:Dictionary ):
	# If the actor exists, register the alias
	if registered_things.has[ parameters["name"] ]:
		registered_alias[ parameters["rename"] ] = parameters["name"]
	# If the actor does not exist BUT this is a nickname, link to nick's source
	elif registered_alias.has [ parameters["name"] ]:
		registered_alias[ parameters["rename"] ] = registered_alias[  parameters["name"]  ]
	else:
		print("Warning! Alias asserted to no known actor. Was she dropped?")
		registered_alias[ parameters["rename"] ] = parameters["name"]


func ev_eval( parameters:Dictionary ):
	pass

# Parameters:
# type -- piece or token? Maybe encode variety of token/piece?
# actor_id -- yeah
# path -- if loading something from file, use its scene path (can be absent)
func ev_create( parameters:Dictionary ):
	#if !registered_things.has( registered_things[ parameters["name"] ] ):
		#registered_things[ parameters["name"] ] = {}
	#
	#if parameters.has("path"):
		#registered_things[ parameters["name"] ]["path"] = parameters["path"]
	#
	#if parameters["type"] == "prop" || parameters["type"] == "token":
		#return
	#
	#if parameters.has("umid"):
		#registered_things[ parameters["name"] ] = parameters["umid"]
		## If database has that UMID character, load that character
		## Else register a new one
	
	return

# Parameters:
# umid -- select which monster to use. If UMID is cloned, clean up. If UMID not in scene, spawn it.
# actor_id -- yeah
func ev_recruit_piece( parameters:Dictionary ):

	pass

# Parameters:
# token_id -- select which token(s) to use. If not in scene, create new one.
# actor_id -- yeah
func ev_recruit_token( parameters:Dictionary ):
	
	pass

# Parameters:
# database -- db to search in ("session" or "system")
# key -- key to search for
# value (opt) -- default value
func ev_db_read( parameters:Dictionary ):
	
	pass

# Parameters:
# database -- db to search in ("session" or "system")
# key -- key to search for
# value -- value to set key's data to
func ev_db_write( parameters:Dictionary ):
	
	pass


func ev_music( parameters:Dictionary ):
	
	pass


func ev_weather( parameters:Dictionary ):
	
	pass

# Takes one parameter: "date", which is converted to a float
# If "date" > 0, change the hour
# To set the hour to zero, set it to the max hour, which I hope is 24.
# Larger numbers are handled by the other function, likely set with modulus
func ev_date_set( parameters:Dictionary ):
	if parameters["date"] != null && float(parameters["date"]) > 0:
		GlobalDayCycle.set_current_date( float(parameters["date"]) )

# Takes one parameter: "hour", which is converted to a float
# If "hour" > 0, change the hour
# To set the hour to zero, set it to the max hour, which I hope is 24.
# Larger numbers are handled by the other function, likely set with modulus
func ev_hour_set( parameters:Dictionary ):
	if parameters["hour"] != null && float(parameters["hour"]) > 0:
		GlobalDayCycle.set_current_hour( float(parameters["hour"]) )

# Takes one parameter: "locked", which is converted to an integer
# If "locked" > 0, lock the current date.
func ev_date_lock( parameters:Dictionary ):
	var bln_lock := false
	
	if parameters["locked"] != null:
		#if parameters["locked"] is bool and (parameters["locked"] == true):
		#	bln_lock = true
		#el
		if int(parameters["date"]) > 0:
			bln_lock = true
	
	if bln_lock:
		GlobalDayCycle.lock_day()
	else:
		GlobalDayCycle.unlock_day()

# Takes one parameter: "locked", which is converted to an integer
# If "locked" > 0, lock the current time.
func ev_hour_lock( parameters:Dictionary ):
	var bln_lock := false
	
	if parameters["locked"] != null:
		#if parameters["locked"] is bool and (parameters["locked"] == true):
		#	bln_lock = true
		#el
		if int(parameters["date"]) > 0:
			bln_lock = true
	
	if bln_lock:
		GlobalDayCycle.lock_hour()
	else:
		GlobalDayCycle.unlock_hour()


func ev_cinematic( parameters:Dictionary ):
	pass


func ev_finish( parameters:Dictionary ):
	pass

# return the value for a key
func get_key_value( key:String ):
	if key_values.has(key):
		return key_values[key]
	return null


func set_key_value( key:String, value ):
	key_values[key] = value


func task_done( return_value: int) -> void:
	pass

# supposed to free this object and its heaviest objects
# to be overwritten by code ending with super.ev_free()
func ev_free( parameters ):
	pass


func ev_chmod( parameters ):
	var chmod_perms:String
	#var char:String
	var char_index:int=0
	#var phase:int=0
	
	if parameters.get("permissions") != null:
		chmod_perms = parameters.get("permissions")
	elif parameters.get("perms") != null:
		chmod_perms = parameters.get("permissions")
	else:
		chmod_perms = ""
	
	#while chmod_perms != "" && chmod_perms != null:
	#	char = chmod_perms.substr(char_index, 1)
	#	if char.is_valid_int():
	#		phase = 7;
	pass


func ev_dismiss( parameters ):
	#enactor_id = -1
	ev_chmod( {"permissions":"0777"} )
	pass


func ev_camera( parameters ):
	pass

# Parameters:
# duration - length in seconds to wait for
func ev_wait( parameters ):
	if parameters.has("duration"):
		await get_tree().create_timer( parameters["duration"] ).timeout


func ev_approach( parameters ):
	pass


func ev_chgrp( parameters ):
	pass


func ev_declare( parameters ):
	pass


func ev_set_rot( parameters ):
	pass


func ev_set_pos( parameters ):
	pass


func ev_cam_follow( parameters ):
	pass


func ev_cam_pos( parameters ):
	pass


func ev_sound( parameters ):
	pass

func ev_mute( parameters ):
	pass

func ev_walk_speed( parameters ):
	
	pass

func ev_walk_point( parameters ):
	pass

func ev_walk_follow( parameters ):
	pass

func ev_walk_path( parameters ):
	pass

func ev_walk_clear( parameters ):
	pass

func ev_walk_actor( parameters ):
	pass

func ev_look_actor( parameters ):
	# signal cue_actor( enactor_ref:int, task_id, arguments, thread_id )
	cue_actor.emit( actor_id_from_name(parameters["_actor"]), Cuecard.LOOK_ACTOR, parameters, 1 )
	pass

#func ev_stare_actor( parameters ):
#	pass

#func ev_stare_clear( parameters ):
#	pass

func ev_animate( parameters ):
	pass

func ev_cam_effect( parameters ):
	pass

func ev_emote( parameters ):
	pass

#func ev_thread_split( parameters ):
#	pass

#func ev_thread_merge( parameters ):
#	pass

#func ev_play_pad( parameters ):
#	pass

#func ev_pipe( parameters ):
#	pass

#func ev_look_at( parameters ):
#	pass

# Parameters:
#  text -- the dialog to say
#  mood -- to change one's icon mood, 0 for default, <0 for no override
func ev_dialog( parameters ):
	ev_dialog_clear( parameters )
	ev_dialog_inject( parameters )
	pass

# Parameters: none. 
func ev_dialog_close( parameters ):
	for dialogue_box in get_tree().get_nodes_in_group("dialog"):
		if dialogue_box.has_method("hide_dialogue_box"):
			dialogue_box.hide_dialogue_box()
	pass

# Parameters:
#  text -- the dialog to say
#  mood -- to change one's icon mood, 0 for default, <0 for no override
func ev_dialog_inject( parameters ):
	var dialog_windows = get_tree().get_nodes_in_group("dialog")
	
	for dialog_box in dialog_windows:
		dialog_box.set_display_name( parameters["_actor"] )
		if dialog_box.has_method("append_text") and parameters.has("text"):
			dialog_box.append_text( parameters["text"] )
		if parameters.has("mood"):
			ev_mood( parameters )
	pass

# Parameters:
# quote -- text associated with the option
# store -- variable to store the result in
# target -- value to set the 'store' variable to.
func ev_dialog_choice( parameters ):
	var dialog_windows = get_tree().get_nodes_in_group("dialog")
	
	for dialog_box in dialog_windows:
		if dialog_box.has_method("push_choice") and parameters.has("quote") \
		and parameters.has("store") and parameters.has("target"):
			dialog_box.push_choice( parameters["quote"], parameters["store"], parameters["target"] )
	pass

# Parameters:
# Implicit:
func ev_dialog_clear( parameters ):
	var dialog_windows = get_tree().get_nodes_in_group("dialog")
	
	for dialog_box in dialog_windows:
		if dialog_box.has_method("reset_text"):
			dialog_box.reset_text()
	pass

# Parameters:
#  actor -- actor ID
#  iconset -- in case one's "model" changes
func ev_icon( parameters ):
	pass

# Parameters:
#  mood -- to change one's mood/vibe/emotion/action
func ev_mood( parameters ):
	pass


#func ev_interact( parameters ):
#	pass
