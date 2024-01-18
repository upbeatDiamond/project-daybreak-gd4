extends Node
class_name Enactor
# An actor, such as in a stage play or movie

# This should always be the direct child of a gamepiece (or gametoken??)

# Not called 'actor' to avoid conflicts with other potential classes
# Likewise, they read from scripts, called 'screenplays'

# ev_* scripts are short for 'event', based on a SADX decomp I found
# ent_* scripts are short for 'entity', so that Events call Entities, which can be reimplemented.
	# ent_* is an interface to implement.
	# All implementations must implement all _ent_* funcs, which are called by the ent_* funcs.
	# Any ent_* without a matching _ent_* should not (not "can't") be overloaded by child classes
# ev_* scripts are separated to make inheritance work, or to make rewriting easier.

#var event_queue = []
var event_index = 0

var enactor_id = -1
var enator_group = -1
var enactor_field = 0
var enactor_name = ""
var enactor_iconset:Image 
var enactor_mood: DialogueBox.Mood = DialogueBox.Mood.NEUTRAL

var is_busy = false

func _ready() -> void:
	var director = get_node("/root/Game/Director")
	director.connect("casting_call", self._on_casting_call) 
	# names might be unified later
#	signal assign_actor( umid:int, enactor_id:int )
#	signal assign_prop( token_id:int, enactor_id:int )
#
#	# needs to follow the casting call
#	signal set_field( enactor_id:int, enactor_field:int )
#
#	# outgoing
	director.connect("cue_actor", self._on_actor_cue) # enactor_ref:int, task_id, arguments, thread_id )
	director.connect("cue_group", self._on_group_cue) # enactor_ref:int, task_id, arguments, thread_id )


#func _on_casting_call( umid:int, enactor_id:int) -> void:
#	self.enactor_id = enactor_id


func _on_casting_field( enactor:int, group_field:int ) -> void:
	if self.enactor_id == enactor:
		self.enactor_field = enactor_field | group_field
	pass


func _on_actor_cue( enactor_ref:int, cue:GlobalDirector.Cuecard, arguments, _thread_id:=0 ):
	if ( enactor_ref == enactor_id and enactor_ref >= 0 ):
		run_cue(cue, arguments)
		return


func _on_group_cue( group_ref:int, cue:GlobalDirector.Cuecard, arguments, _thread_id:=0 ):
	if ( group_ref == enator_group and group_ref >= 0 ):
		run_cue(cue, arguments)
	return


func run_cue(cue:GlobalDirector.Cuecard, line:Dictionary):
	
	match cue:
		GlobalDirector.Cuecard.WAIT:
			ent_wait( line )
			pass
		GlobalDirector.Cuecard.CHMOD:
			ent_chmod( line )
			pass
		GlobalDirector.Cuecard.CHGROUP:
			ent_chgrp( line )
			pass
		GlobalDirector.Cuecard.SET_ROTATION:
			ent_set_rot( line )
			pass
		GlobalDirector.Cuecard.SET_POSITION:
			ent_set_pos( line )
			pass
		GlobalDirector.Cuecard.CAM_FOLLOW:
			ent_cam_follow( line )
			pass
		GlobalDirector.Cuecard.FREE:
			ent_free( line )
			pass
		GlobalDirector.Cuecard.DISMISS:
			ent_dismiss( line )
			pass
		GlobalDirector.Cuecard.CAM_SNAP:
			ent_cam_pos( line )
			pass
		GlobalDirector.Cuecard.PLAYSOUND:
			ent_sound( line )
			pass
		GlobalDirector.Cuecard.MUTE:
			ent_mute( line )
			pass
		GlobalDirector.Cuecard.WALK_MODE:
			ent_walk_speed( line )
			pass
		GlobalDirector.Cuecard.WALK_POINT:
			ent_walk_point( line )
			pass
		GlobalDirector.Cuecard.FOLLOW_ACTOR:
			ent_walk_follow( line )
			pass
		GlobalDirector.Cuecard.WALK_PATH:
			ent_walk_path( line )
			pass
		GlobalDirector.Cuecard.WALK_CLEAR:
			ent_walk_clear( line )
			pass
		GlobalDirector.Cuecard.LOOK_ACTOR:
			ent_look_actor( line )
			pass
		#GlobalDirector.Cuecard.STARE_ACTOR:
			#ev_stare_actor( line )
			#pass
		#GlobalDirector.Cuecard.STARE_CLEAR:
			#ev_stare_clear( line )
			#pass
		GlobalDirector.Cuecard.ANIMATE:
			ent_animate( line )
			pass
		GlobalDirector.Cuecard.CAM_EFFECT:
			ent_cam_effect( line )
			pass
		GlobalDirector.Cuecard.EMOTE:
			ent_emote( line )
			pass
		#GlobalDirector.Cuecard.THREAD_SPLIT:
			#ev_thread_split( line )
			#pass
		#GlobalDirector.Cuecard.THREAD_UNIFY:
			#ev_thread_merge( line )
			#pass
		#GlobalDirector.Cuecard.PLAY_PAD:
			#ev_play_pad( line )
			#pass
		#GlobalDirector.Cuecard.PIPE:
		#	ev_pipe( line )
		#	pass
		#GlobalDirector.Cuecard.SET_LOOK:
			#ev_look_at( line )
			#pass
		GlobalDirector.Cuecard.UPDATE_ICON:
			ent_icon( line )
			pass
		#GlobalDirector.Cuecard.INTERACT:
			#ev_interact( line )
			pass
		_:
			pass

#func queue_event( cuecard:GlobalDirector.Cuecard, parameters, feedback ) -> void:
#	event_queue.append( [cuecard, parameters, feedback] )


func _process(_delta: float) -> void:
	pass
	#if !is_busy:
		## Instead of removing the head of the array every time, why not wait until it's done?
		#if event_queue.size() > event_index:
			#do_event( event_queue[ event_index ][0], event_queue[ event_index ][1], event_queue[ event_index ][2] )
			#is_busy = true
			#event_index += 1
		#
		## If the array has reached its end, then make sure it gets queue_freed (if needed).
		#elif event_queue.size() > 0:
			#event_index = 0
			#for act in event_queue:
				#if act is Object:
					#act.queue_free()
			## replace the array, so there aren't random references lying around.
			#event_queue = []


func ent_chmod( parameters ):
	if parameters.has("can_x"):
		pass
	pass


# supposed to free this object and its heaviest objects
# to be overwritten by code ending with super.ev_free()
func ent_free( parameters:Dictionary ):
	_ent_free( parameters)


func _ent_free( _parameters:Dictionary ):
	push_warning(self, "._ent_free(Dictionary) has not been implemented yet!")


func ent_dismiss( parameters:Dictionary ):
	_ent_dismiss( parameters)


func _ent_dismiss( _parameters:Dictionary ):
	push_warning(self, "._ent_dismiss(Dictionary) has not been implemented yet!")


#func ent_camera( parameters:Dictionary ):
	#_ent_camera( parameters)
#
#
#func _ent_camera( _parameters:Dictionary ):
	#push_warning(self, "._ent_camera(Dictionary) has not been implemented yet!")


func ent_wait( parameters:Dictionary ):
	_ent_wait( parameters)


func _ent_wait( _parameters:Dictionary ):
	push_warning(self, "._ent_wait(Dictionary) has not been implemented yet!")


func ent_approach( parameters:Dictionary ):
	_ent_approach( parameters)


func _ent_approach( _parameters:Dictionary ):
	push_warning(self, "._ent_approach(Dictionary) has not been implemented yet!")

# Parameters:
# group -- group id, int ( <0 = invalid/ignore )
func ent_chgrp( parameters:Dictionary ):
	_ent_chgrp( parameters)


func _ent_chgrp( _parameters:Dictionary ):
	enator_group = str(0, _parameters["group"]).to_int()


func ent_set_rot( parameters:Dictionary ):
	_ent_set_rot( parameters)


func _ent_set_rot( _parameters:Dictionary ):
	push_warning(self, "._ent_set_rot(Dictionary) has not been implemented yet!")


func ent_set_pos( parameters:Dictionary ):
	_ent_set_pos( parameters )


func _ent_set_pos( _parameters:Dictionary ):
	push_warning(self, "._ent_set_pos(Dictionary) has not been implemented yet!")


func ent_cam_follow( parameters:Dictionary ):
	_ent_cam_follow( parameters )


func _ent_cam_follow( _parameters:Dictionary ):
	push_warning(self, "._ent_cam_follow(Dictionary) has not been implemented yet!")


func ent_cam_pos( parameters:Dictionary ):
	_ent_cam_pos( parameters)


func _ent_cam_pos( _parameters:Dictionary ):
	push_warning(self, "._ent_cam_pos(Dictionary) has not been implemented yet!")


func ent_sound( parameters:Dictionary ):
	_ent_sound( parameters)


func _ent_sound( _parameters:Dictionary ):
	push_warning(self, "._ent_sound(Dictionary) has not been implemented yet!")


func ent_mute( parameters:Dictionary ):
	_ent_mute( parameters)


func _ent_mute( _parameters:Dictionary ):
	push_warning(self, "._ent_mute(Dictionary) has not been implemented yet!")


func ent_walk_speed( parameters:Dictionary ):
	_ent_walk_speed( parameters )


func _ent_walk_speed( _parameters:Dictionary ):
	push_warning(self, "._ent_walk_speed(Dictionary) has not been implemented yet!")


func ent_walk_point( parameters:Dictionary ):
	_ent_walk_point( parameters)


func _ent_walk_point( _parameters:Dictionary ):
	push_warning(self, "._ent_walk_point(Dictionary) has not been implemented yet!")


func ent_walk_follow( parameters:Dictionary ):
	_ent_walk_follow( parameters)


func _ent_walk_follow( _parameters:Dictionary ):
	push_warning(self, "._ent_walk_follow(Dictionary) has not been implemented yet!")


func ent_walk_path( parameters:Dictionary ):
	_ent_walk_path( parameters)


func _ent_walk_path( _parameters:Dictionary ):
	push_warning(self, "._ent_walk_path(Dictionary) has not been implemented yet!")


func ent_walk_clear( parameters:Dictionary ):
	_ent_walk_clear( parameters)


func _ent_walk_clear( _parameters:Dictionary ):
	push_warning(self, "._ent_walk_clear(Dictionary) has not been implemented yet!")


func ent_walk_actor( parameters:Dictionary ):
	_ent_walk_actor( parameters)


func _ent_walk_actor( _parameters:Dictionary ):
	push_warning(self, "._ent_walk_actor(Dictionary) has not been implemented yet!")


func ent_look_actor( parameters:Dictionary ):
	_ent_look_actor( parameters )


func _ent_look_actor( _parameters:Dictionary ):
	push_warning(self, "._ent_look_actor(Dictionary) has not been implemented yet!")


func ent_stare_actor( parameters:Dictionary ):
	_ent_stare_actor( parameters)


func _ent_stare_actor( _parameters:Dictionary ):
	push_warning(self, "._ent_stare_actor(Dictionary) has not been implemented yet!")


func ent_stare_clear( parameters:Dictionary ):
	_ent_stare_clear( parameters )


func _ent_stare_clear( _parameters:Dictionary ):
	push_warning(self, "._ent_stare_clear(Dictionary) has not been implemented yet!")


func ent_animate( parameters:Dictionary ):
	_ent_animate( parameters )


func _ent_animate( _parameters:Dictionary ):
	push_warning(self, "._ent_animate(Dictionary) has not been implemented yet!")


func ent_cam_effect( parameters:Dictionary ):
	_ent_cam_effect( parameters )


func _ent_cam_effect( _parameters:Dictionary ):
	push_warning(self, "._ent_cam_effect(Dictionary) has not been implemented yet!")


func ent_emote( parameters:Dictionary ):
	_ent_emote( parameters )


func _ent_emote( _parameters:Dictionary ):
	push_warning(self, "._ent_emote(Dictionary) has not been implemented yet!")


func ent_play_pad( parameters:Dictionary ):
	_ent_play_pad( parameters )


func _ent_play_pad( _parameters:Dictionary ):
	push_warning(self, "._ent_play_pad(Dictionary) has not been implemented yet!")


func ent_pipe( parameters:Dictionary ):
	_ent_pipe( parameters )


func _ent_pipe( _parameters:Dictionary ):
	push_warning(self, "._ent_pipe(Dictionary) has not been implemented yet!")


func ent_look_at( parameters:Dictionary ):
	_ent_look_at( parameters )


func _ent_look_at( _parameters:Dictionary ):
	push_warning(self, "._ent_look_at(Dictionary) has not been implemented yet!")


# Parameters:
#  mood -- to change one's mood/vibe/emotion/action
#  iconset -- in case one's "model" changes
func ent_icon( parameters:Dictionary ):
	_ent_icon( parameters )


func _ent_icon( _parameters:Dictionary ):
	push_warning(self, "._ent_icon(Dictionary) has not been implemented yet!")


func ent_interact( parameters:Dictionary ):
	_ent_interact( parameters)


func _ent_interact( _parameters:Dictionary ):
	push_warning(self, "._ent_interact(Dictionary) has not been implemented yet!")
