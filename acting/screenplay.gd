extends Node
class_name Screenplay
# Intended to allow for storage/retrieval of larger scripts in a consistant format.
# All parameters should be stored as a stringified JSON of a Dict.

var index = 0
var page = []
var jump_targets := {
	
}
var keys_values := {
	
}

func _init( path:="" ):
	if path.is_valid_filename():
		load_from_path(path)
	pass

func load_from_path( path:="" ):
	jump_targets.clear()
	keys_values.clear()
	page.clear()
	index = 0
	
	var scrypt = FileAccess.open(path, FileAccess.READ)
	var header = JSON.parse_string( scrypt.get_line() )
	
	if header["syntax_version"] < ScreenplayCompiler.SYNTAX_VERSION_COMPATIBLE || \
	header["compile_version"] < ScreenplayCompiler.COMPILE_VERSION_COMPATIBLE:
		print("Invalid screenplay, loading cancelled!")
		return
	
	while !scrypt.eof_reached():
		index += 1
		page.append( JSON.parse_string( scrypt.get_line() ) )
		
		# If the imported line is a jump target, and that target name is not yet stored ...
		# ... then store it now along with the estimated line number.
		if page.back()["_cuecard"] == GlobalDirector.Cuecard.JUMP_TARGET:
			var jt_name = page.back().get("target").strip_edges()
			if jump_targets.get( jt_name ) == null and \
			jt_name != null:
				jump_targets[ jt_name ] = index
	pass


func is_track_target_valid( _target:String ):
	return jump_targets.has( _target.strip_edges() )


func track_to_target( _target:String ):
	# If the pointer exists, then track to its integer value
	if jump_targets.has( _target.strip_edges() ):
		track_to_line( str(0, jump_targets[_target]).to_int() )
	pass


func track_to_line( _line_num:int ):
	index = _line_num - 1
	pass


func peek_next_event():
	if page.size() < index:
		var ret_page = page[index]
		return ret_page
	return null

func read_next_event(): #-> Dictionary:
	var ret = peek_next_event()
	index += 1
	return ret

func read_next_non_blocking_event() -> Dictionary:
	var ret_page = peek_next_event()
	if (ret_page is Dictionary) and cuecard_is_blocking( ret_page["_cuecard"] ):
		ret_page = null
	elif ret_page != null:
		index += 1
	return ret_page

func read_next_non_preblocking_event() -> Dictionary:
	var ret_page = peek_next_event()
	if (ret_page is Dictionary) and cuecard_is_preblocking( ret_page["_cuecard"] ):
		ret_page = null
	elif ret_page != null:
		index += 1
	return ret_page

func import_line( line:String, _index:int=-1 ):
	
	var cuecard = JSON.parse_string(line)
	
	if index >= 0:
		page.insert(_index,cuecard)
	else:
		index = page.size()
		page.append(cuecard)
	
	# to avoid having to later run through the entire script to find the jump targets, ...
	# ... we store it now if one does not already exist.
	# Since the compiler is faulty, some jump targets are cloned **after** intended initial point.
	# ... To compensate, we ignore duplicates, as it shouldn't ever appear **before** intended.
	if cuecard is Dictionary and \
	(cuecard as Dictionary).get("_cuecard") == GlobalDirector.Cuecard.JUMP_TARGET:
		if jump_targets[ cuecard.get("target") ] == null:
			jump_targets[ cuecard["target"] ] = index
	
	pass

# Says whether the player needs to press a button to continue, or otherwise is treated as such
# IMPLEMENTATION INTENTION:
# If current cuecard is blocking, then stop the script just before the next blocking cuecard
# That way, dialog choices and injects can still appear despite being after a blocking line
func cuecard_is_blocking( cuecard:GlobalDirector.Cuecard ) -> bool:
	match cuecard:
		GlobalDirector.Cuecard.DIALOG, GlobalDirector.Cuecard.AWAIT_CINE, \
		GlobalDirector.Cuecard.DIALOG_CLEAR, GlobalDirector.Cuecard.FINISH:
			return true
	return false

# Says whether the command should not play after a blocking cuecard is stopped at.
# IMPLEMENTATION INTENTION:
# If current cuecard is blocking, then stop before the next blocking/preblocking command
# That way, some commands can continue after a blocking.
func cuecard_is_preblocking( cuecard:GlobalDirector.Cuecard ) -> bool:
	# If it's blocking, then it's pre-blocking.
	if cuecard_is_blocking( cuecard ):
		return true
	
	# Exclude these items from being pre-blocking
	match cuecard:
		GlobalDirector.Cuecard.DIALOG_CHOICE, GlobalDirector.Cuecard.SET_MOOD, \
		GlobalDirector.Cuecard.UPDATE_NAME, GlobalDirector.Cuecard.UPDATE_ICON, \
		GlobalDirector.Cuecard.UPDATE_GENDER, GlobalDirector.Cuecard.UPDATE_VOICE, \
		GlobalDirector.Cuecard.DIALOG_INJECT, GlobalDirector.Cuecard.UPDATE_AVATAR:
			return false
	
	# Assume all items are pre-blocking, as dialog should end running by default
	return true
