extends Enactor
class_name EnactorPiece
# must be the child of a gamepiece controller

var gamepiece : Gamepiece
var gamepiece_controller : GamepieceController


func _ent_free( _parameters:Dictionary ):
	GlobalRuntime. clean_up_node_descent( gamepiece )
	queue_free()


func _ent_dismiss( _parameters:Dictionary ):
	
	pass


func _ent_camera( _parameters:Dictionary ):
	gamepiece.my_camera.enabled = true
	pass

# This function shouldn't be able to be called?
# But it may prove useful later.
# Please consider smoothing out if not deleting.
func _ent_wait( _parameters:Dictionary ):
	var gd:=GlobalDirector.new()
	gd.ev_wait(_parameters)


func _ent_approach( _parameters:Dictionary ):
	push_warning(self, "._ent_approach(Dictionary) has not been implemented yet!")


#func _ent_chgrp( _parameters:Dictionary ):
	#push_warning(self, "._ent_chgrp(Dictionary) has not been implemented yet!")


func _ent_set_rot( _parameters:Dictionary ):
	push_warning(self, "._ent_set_rot(Dictionary) has not been implemented yet!")


func _ent_set_pos( _parameters:Dictionary ):
	push_warning(self, "._ent_set_pos(Dictionary) has not been implemented yet!")


func _ent_cam_follow( _parameters:Dictionary ):
	push_warning(self, "._ent_cam_follow(Dictionary) has not been implemented yet!")


func _ent_cam_pos( _parameters:Dictionary ):
	push_warning(self, "._ent_cam_pos(Dictionary) has not been implemented yet!")


func _ent_sound( _parameters:Dictionary ):
	push_warning(self, "._ent_sound(Dictionary) has not been implemented yet!")


func _ent_mute( _parameters:Dictionary ):
	push_warning(self, "._ent_mute(Dictionary) has not been implemented yet!")


func _ent_walk_speed( _parameters:Dictionary ):
	push_warning(self, "._ent_walk_speed(Dictionary) has not been implemented yet!")


func _ent_walk_point( _parameters:Dictionary ):
	gamepiece_controller.set_auto_target( _parameters["position"] )

# set as follower
func _ent_walk_follow( _parameters:Dictionary ):
	push_warning(self, "._ent_walk_follow(Dictionary) has not been implemented yet!")


func _ent_walk_path( _parameters:Dictionary ):
	push_warning(self, "._ent_walk_path(Dictionary) has not been implemented yet!")


func _ent_walk_clear( _parameters:Dictionary ):
	gamepiece_controller.auto_waypoints = []


func _ent_walk_actor( _parameters:Dictionary ):
	push_warning(self, "._ent_walk_actor(Dictionary) has not been implemented yet!")


func _ent_look_actor( _parameters:Dictionary ):
	push_warning(self, "._ent_look_actor(Dictionary) has not been implemented yet!")


func _ent_stare_actor( _parameters:Dictionary ):
	push_warning(self, "._ent_stare_actor(Dictionary) has not been implemented yet!")


func _ent_stare_clear( _parameters:Dictionary ):
	push_warning(self, "._ent_stare_clear(Dictionary) has not been implemented yet!")


func _ent_animate( _parameters:Dictionary ):
	push_warning(self, "._ent_animate(Dictionary) has not been implemented yet!")


func _ent_cam_effect( _parameters:Dictionary ):
	push_warning(self, "._ent_cam_effect(Dictionary) has not been implemented yet!")


func _ent_emote( _parameters:Dictionary ):
	push_warning(self, "._ent_emote(Dictionary) has not been implemented yet!")


func _ent_play_pad( _parameters:Dictionary ):
	push_warning(self, "._ent_play_pad(Dictionary) has not been implemented yet!")


func _ent_pipe( _parameters:Dictionary ):
	push_warning(self, "._ent_pipe(Dictionary) has not been implemented yet!")


func _ent_look_at( _parameters:Dictionary ):
	push_warning(self, "._ent_look_at(Dictionary) has not been implemented yet!")


# Parameters:
#  mood -- to change one's mood/vibe/emotion/action
#  iconset -- in case one's "model" changes
func _ent_icon( _parameters:Dictionary ):
	if _parameters.has("iconset"):
		enactor_iconset = _parameters["iconset"]
	if _parameters.has("mood"):
		if _parameters["mood"] is String:
			_parameters["mood"] =  DialogueBox.Mood.find_key( _parameters["mood"].strip_edges().to_upper().replace(" ", "_") )
		enactor_mood = _parameters["mood"]
	#push_warning(self, "._ent_icon(Dictionary) has not been implemented yet!")


func _ent_interact( _parameters:Dictionary ):
	push_warning(self, "._ent_interact(Dictionary) has not been implemented yet!")
