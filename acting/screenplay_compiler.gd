extends RefCounted
class_name ScreenplayCompiler

const COMPILE_VERSION := -19750814
const SYNTAX_VERSION := -19750814
const COMPILE_VERSION_COMPATIBLE := COMPILE_VERSION
const SYNTAX_VERSION_COMPATIBLE := SYNTAX_VERSION

func _init():
	run()
	pass

func run():
	var tokenizer = ScreenplayImportTokenizer.new()
	#tokenizer.tokenize_file("res://acting/test_screenplay.txt")
	tokenizer.tokenize_file("res://screenplays/intro_wakeup.txt", "res://screenplays/intro_wakeup+comp.txt")
	pass



class ScreenplayImportTokenizer:
	
	var CompilerToken:=ScreenplayImportToken.CompilerToken
	var token_index:=0
	var char_index:=-1
	var char_current:=' '
	var context_buffer:String=""
	
	var current_line:String=""
	var current_token:ScreenplayImportToken
	var token_buffer:Array[ScreenplayImportToken]
	var tokenized_file:Array[ScreenplayImportToken]
	var token_tree_root:ScreenplayImportToken
	
	var export_token_feed:Array[ScreenplayExportToken]=[]
	var export_header:={}
	
	var source_path
	var export_path:String
	
	func tokenize_file(filepath:String, _export_path:String = "" ):
		source_path = filepath
		export_path = _export_path
		if _export_path == null or _export_path.length() <= 0:
			export_path = str(source_path.rstrip(".txt"), "+comp.txt" )
			print(source_path, export_path)
		var file = FileAccess.open(filepath, FileAccess.READ)
		var line_count = 0
		var is_error_free := true
		
		while !file.eof_reached() && is_error_free:
			current_line = file.get_line() + "  "
			is_error_free = ( 0 == _tokenize_line() )
			is_error_free = ( 0 == _reduce_tokenized_line() ) || is_error_free
			line_count += 1
			#print( current_line )
			if !is_error_free:
				print( "~ SYNTAX ERROR DETECTED ON LINE ", line_count, " ~" )
				return
			#for tkn in token_buffer:
			#	print( line_count, " ", tkn.CompilerToken.find_key(tkn.type), " ", tkn.value )
			token_buffer = []
		#print( "~~~~ begin file summary ~~~~" )
		#for tknf in tokenized_file:
		#		print( tknf.CompilerToken.find_key(tknf.type), " ", tknf.value )
		_treeification()
		tokenized_file = []
		_tree_pre_exporting()
		#print(export_token_feed)
		_export_to_file()
	
	func push_replace_current_token(new_type:ScreenplayImportToken.CompilerToken=CompilerToken.EMPTY):
		push_current_token()
		current_token = ScreenplayImportToken.new( new_type )
		pass
	
	func push_current_token():
		current_token.value = context_buffer
		token_buffer.append( current_token )
	
	func _tokenize_line() -> int:
		char_index = 0
		current_token = ScreenplayImportToken.new(CompilerToken.LINE_START)
		var is_escaped = false;
		var is_escaped_deferred = false;
		
		context_buffer = ""
		
		# run through each character in the string
		while char_index < current_line.length() && current_token.type != CompilerToken.LINE_END:
			# char_current = current character, which may be longer than a char type due to Unicode.
			char_current = current_line.substr(char_index, 1)
			
			is_escaped = is_escaped_deferred
			is_escaped_deferred = false;
			
			if current_token.type == CompilerToken.INVALID:
				return -1;
			
			match char_current:
				'=':
					if is_escaped || current_token.type == CompilerToken.SAY_SEGMENT:
						context_buffer += char_current
					elif current_token.type == CompilerToken.LINE_START:
						current_token.type = CompilerToken.EQ
					elif current_token.type == CompilerToken.EQ:
						current_token.type = CompilerToken.EQEQ
					elif current_token.type == CompilerToken.EQEQ:
						current_token.type = CompilerToken.JUMP_TARGET
					elif current_token.type == CompilerToken.JUMP_TARGET:
						push_replace_current_token(CompilerToken.SYMBOLIC_SPACE)
						context_buffer = ""
					else:
						context_buffer += char_current
				'.':
					
					context_buffer += char_current
					
					if current_token.type == current_token.CompilerToken.INTEGER:
						current_token.type = current_token.CompilerToken.REAL_NUM
					elif current_token.type == current_token.CompilerToken.REAL_NUM:
						push_replace_current_token(current_token.CompilerToken.INVALID)
					elif current_token.type == current_token.CompilerToken.COLON \
					|| current_token.type == current_token.CompilerToken.SAY_SEGMENT \
					|| current_token.type == current_token.CompilerToken.EMPTY:
						
						current_token.type = current_token.CompilerToken.SAY_SEGMENT
						current_token.value = context_buffer
						
					else:
						current_token.value = context_buffer
					
				'1', '2', '3', '4', '5', '6', '7', '8', '9', '0':
					if current_token.type == current_token.CompilerToken.COLON:
						push_replace_current_token(current_token.CompilerToken.SAY_SEGMENT)
						context_buffer = ""
					
					context_buffer += char_current
					
					if (current_token.type == current_token.CompilerToken.SAY_SEGMENT
					|| current_token.type == current_token.CompilerToken.SAY_NAME
					|| current_token.type == current_token.CompilerToken.EFFECT_OPEN
					|| current_token.type == current_token.CompilerToken.COMMAND_OPEN
					|| current_token.type == current_token.CompilerToken.VARIABLE
					|| current_token.type == current_token.CompilerToken.IDENTIFIER
					|| current_token.type == current_token.CompilerToken.INTEGER
					|| current_token.type == current_token.CompilerToken.REAL_NUM
					|| current_token.type == current_token.CompilerToken.QUOTE):
						current_token.value = context_buffer
					else:
						push_replace_current_token(current_token.CompilerToken.INTEGER)
				'*':
					if is_escaped || current_token.type == current_token.CompilerToken.SAY_SEGMENT:
						context_buffer += char_current
					elif current_token.type == current_token.CompilerToken.EMPTY:
						current_token.type = ScreenplayImportToken.CompilerToken.OPTION
					else:
						push_replace_current_token(current_token.CompilerToken.OPTION)
				'"', '“', '”':
					if is_escaped || current_token.type == current_token.CompilerToken.SAY_SEGMENT:
						context_buffer += char_current
					elif current_token.type == current_token.CompilerToken.QUOTE:
						push_replace_current_token()
					else:
						push_replace_current_token(current_token.CompilerToken.QUOTE)
				'$':
					if is_escaped:
						context_buffer += char_current
					elif !(current_token.type == current_token.CompilerToken.SAY_SEGMENT \
					|| current_token.type == current_token.CompilerToken.SAY_NAME) :
						push_replace_current_token(current_token.CompilerToken.VARIABLE)
						context_buffer = ""
						pass
					else:
						context_buffer += '$'
					pass
				'@':
					if is_escaped:
						context_buffer += char_current
					elif !(current_token.type == current_token.CompilerToken.SAY_SEGMENT \
					|| current_token.type == current_token.CompilerToken.SAY_NAME) :
						push_replace_current_token(current_token.CompilerToken.IDENTIFIER)
						context_buffer = ""
						pass
					else:
						context_buffer += '@'
					pass
				'/':
					if is_escaped || current_token.type == current_token.CompilerToken.QUOTE:
						context_buffer += char_current
						if current_token.type == current_token.CompilerToken.SLASH:
							current_token.type = token_buffer[-1].type
					elif current_token.type != current_token.CompilerToken.SLASH:
						push_replace_current_token(current_token.CompilerToken.SLASH)
						context_buffer = ""
					else:
						current_token.type = current_token.CompilerToken.LINE_END
				':':
					if is_escaped || current_token.type == current_token.CompilerToken.SAY_SEGMENT:
						context_buffer += char_current
					elif current_token.type == current_token.CompilerToken.IDENTIFIER \
					|| current_token.type == current_token.CompilerToken.VARIABLE \
					|| current_token.type == current_token.CompilerToken.SAY_NAME \
					|| current_token.type == current_token.CompilerToken.LINE_START:
						
						push_replace_current_token(current_token.CompilerToken.COLON)
						context_buffer = ""
						pass
					else:
						context_buffer += ':'
				' ':
					if (current_token.type == current_token.CompilerToken.EFFECT_OPEN ||
					current_token.type == current_token.CompilerToken.COMMAND_OPEN ||
					current_token.type == current_token.CompilerToken.COMMA ||
					current_token.type == current_token.CompilerToken.SLASH):
						
						push_replace_current_token(current_token.CompilerToken.SYMBOLIC_SPACE)
						context_buffer = ""
					
					elif !( current_token.type == current_token.CompilerToken.SAY_SEGMENT || 
					current_token.type == current_token.CompilerToken.JUMP_TARGET ||
					current_token.type == current_token.CompilerToken.SAY_NAME ||
					current_token.type == current_token.CompilerToken.OPTION ||
					current_token.type == current_token.CompilerToken.EMPTY ||
					current_token.type == current_token.CompilerToken.LINE_START || 
					current_token.type == current_token.CompilerToken.QUOTE):
						
						push_replace_current_token()
						context_buffer = ""
						pass
					else:
						context_buffer += ' '
				'\t':
					if current_token.type == current_token.CompilerToken.LINE_START:
						push_replace_current_token(current_token.CompilerToken.LINE_START)
						token_buffer.append( ScreenplayImportToken.new(current_token.CompilerToken.TAB) )
					elif current_token.type == current_token.CompilerToken.EMPTY:
						token_buffer.append( ScreenplayImportToken.new(current_token.CompilerToken.TAB) )
					else:
						context_buffer += '\t'
				'\\':
					if current_token.type == current_token.CompilerToken.EFFECT_OPEN \
					|| current_token.type == current_token.CompilerToken.COMMAND_OPEN \
					|| current_token.type == current_token.CompilerToken.COMMAND_OPEN \
					|| current_token.type == current_token.CompilerToken.COMMAND_OPEN \
					|| current_token.type == current_token.CompilerToken.COMMAND_OPEN:
						push_replace_current_token()
						context_buffer = ""
						pass
					
					if is_escaped:
						context_buffer += '\\'
					else:
						is_escaped_deferred = true
					pass
				'<':
					if is_escaped:
						context_buffer += "<"
					elif current_token.type == current_token.CompilerToken.EMPTY:
						current_token.type = current_token.CompilerToken.EFFECT_OPEN
						
					
					elif (current_token.type == current_token.CompilerToken.LINE_START
					|| current_token.type == current_token.CompilerToken.SAY_SEGMENT
					|| current_token.type == current_token.CompilerToken.SAY_NAME
					|| current_token.type == current_token.CompilerToken.SYMBOLIC_SPACE):
						
						push_replace_current_token()
						current_token.type = current_token.CompilerToken.EFFECT_OPEN
						context_buffer = ""
						
					elif current_token.type == current_token.CompilerToken.EFFECT_OPEN:
						
						current_token.type = current_token.CompilerToken.COMMAND_OPEN
						
						pass
					else:
						push_replace_current_token(current_token.CompilerToken.EFFECT_OPEN)
						push_replace_current_token()
						context_buffer = ""
				'>':
					if is_escaped:
						context_buffer += ">"
					
					elif current_token.type == current_token.CompilerToken.EMPTY:
						current_token.type = current_token.CompilerToken.EFFECT_CLOSE
						
					elif current_token.type == current_token.CompilerToken.EFFECT_CLOSE:
						
						current_token.type = current_token.CompilerToken.COMMAND_CLOSE
						push_replace_current_token()
						context_buffer = ""
						pass
					
					else:
						push_replace_current_token(current_token.CompilerToken.EFFECT_CLOSE)
						context_buffer = ""
				',':
					if current_token.type == current_token.CompilerToken.SAY_SEGMENT:
						context_buffer = context_buffer + char_current
						pass
					elif is_escaped:
						context_buffer += ","
					else:
						push_replace_current_token()
						token_buffer.append(ScreenplayImportToken.new(current_token.CompilerToken.COMMA))
						#current_token = ScreenplayImportToken.new()
						current_token.type = current_token.CompilerToken.EMPTY
						context_buffer = ""
				_:
					if current_token.type == current_token.CompilerToken.COLON:
						push_replace_current_token()
					elif current_token.type == current_token.CompilerToken.COMMAND_CLOSE \
					|| current_token.type == current_token.CompilerToken.EFFECT_CLOSE:
						
						push_replace_current_token(current_token.CompilerToken.SAY_SEGMENT)
						context_buffer = ""
					
					#elif (current_token.type == current_token.CompilerToken.COMMAND_OPEN
					#|| current_token.type == current_token.CompilerToken.EFFECT_OPEN):
					#	
					
					context_buffer += char_current
					
					if current_token.type == current_token.CompilerToken.LINE_START \
					|| current_token.type == current_token.CompilerToken.SAY_NAME:
						
						current_token.type = current_token.CompilerToken.SAY_NAME
						current_token.value = context_buffer
						
					elif current_token.type == current_token.CompilerToken.EMPTY \
					|| current_token.type == current_token.CompilerToken.SAY_SEGMENT:
						
						current_token.type = current_token.CompilerToken.SAY_SEGMENT
						current_token.value = context_buffer
						
					elif current_token.type == current_token.CompilerToken.COMMAND_OPEN \
					|| current_token.type == current_token.CompilerToken.EFFECT_OPEN:
						
						current_token.value = context_buffer
						
					elif current_token.type == current_token.CompilerToken.SYMBOLIC_SPACE:
						
						push_replace_current_token(current_token.CompilerToken.VARIABLE)
						current_token.value = context_buffer
					
					elif current_token.type == current_token.CompilerToken.COMMA:
						
						push_replace_current_token(current_token.CompilerToken.SYMBOLIC_SPACE)
			
			char_index += 1 # basically a for loop, but cooler
		
		current_token.value = context_buffer
		token_buffer.append(current_token)
		token_buffer.append(ScreenplayImportToken.new(ScreenplayImportToken.CompilerToken.LINE_END))
		current_token = ScreenplayImportToken.new()
		
		return 0
	
	func _reduce_tokenized_line() -> int:
		var i = 0
		var new_token_buffer:=[]
		var previous_token = ScreenplayImportToken.new()
		
		while i < token_buffer.size():
			current_token = token_buffer[i]
			match current_token.type:
				
				ScreenplayImportToken.CompilerToken.LINE_START:
					if previous_token.type == ScreenplayImportToken.CompilerToken.EMPTY \
					|| previous_token.type == ScreenplayImportToken.CompilerToken.LINE_END:
						new_token_buffer.append( current_token )
						previous_token = current_token
				
				ScreenplayImportToken.CompilerToken.OPTION:
					if previous_token.type == ScreenplayImportToken.CompilerToken.TAB \
					|| previous_token.type == ScreenplayImportToken.CompilerToken.LINE_START:
						new_token_buffer.pop_back()
					else:
						return 1
					
					current_token.type = ScreenplayImportToken.CompilerToken.SWITCH
					new_token_buffer.append( current_token )
					previous_token = current_token
				
				ScreenplayImportToken.CompilerToken.COLON:
					if previous_token.type != ScreenplayImportToken.CompilerToken.SAY_NAME:
						new_token_buffer.append( ScreenplayImportToken.new(ScreenplayImportToken.CompilerToken.SAY_NAME) )
					previous_token = current_token
					pass
				
				ScreenplayImportToken.CompilerToken.SYMBOLIC_SPACE, \
				ScreenplayImportToken.CompilerToken.COMMA, \
				ScreenplayImportToken.CompilerToken.EMPTY:
					pass
				
				ScreenplayImportToken.CompilerToken.LINE_END:
					if previous_token.type == ScreenplayImportToken.CompilerToken.LINE_START:
						new_token_buffer.pop_back()
					else:
						new_token_buffer.append( current_token )
						previous_token = current_token
					i = token_buffer.size()
				
				_:
					new_token_buffer.append( current_token )
					previous_token = current_token
			
			i += 1;
			pass
		
		# another pass to turn line-start into tabs, for later scope parsing, due to option nonsense
		i = 0
		while i < new_token_buffer.size():
			current_token = token_buffer[i]
			
			if current_token.type == CompilerToken.LINE_START:
				current_token.type = CompilerToken.TAB
			
			i += 1
		
		tokenized_file.append_array( new_token_buffer )
		#print( tokenized_file.size(), " tokens processed thus far %%%%%%%%" )
		
		return 0;
		#pass
	
	func _treeification():
		var current_scope = 0
		#var current_tkn_line:Array[ScreenplayImportToken]=[]
		var i = 0
		#var new_token_buffer:=[]
		#var previous_token = ScreenplayImportToken.new()
		var current_container:ScreenplayImportToken = ScreenplayImportToken.new(ScreenplayImportToken.CompilerToken.XT_ROOT)
		token_tree_root = current_container
		var scoped = false
		
		current_container.parent = current_container
		
		while i < tokenized_file.size():
			current_token = tokenized_file[i]
			if current_token.type != CompilerToken.QUOTE:
				current_token.value = current_token.value.strip_edges()
			
			# match for scope's sake, so that indented tkns become children of less-indented tkns
			match current_token.type:
				ScreenplayImportToken.CompilerToken.LINE_END:
					current_scope = 0
					scoped = false
				
				ScreenplayImportToken.CompilerToken.LINE_START:
					current_scope = 1
					scoped = false
					
				ScreenplayImportToken.CompilerToken.TAB:
					if !scoped:
						current_scope += 1
					
				_:
					if !scoped:
						while current_container.children.size() > 0 \
						&& current_container.children.back() != null \
						&& current_container.children.back().scope < current_scope \
						&& current_container.children.back().type == ScreenplayImportToken.CompilerToken.SWITCH:
							current_container = current_container.children.back()
						while (current_container.scope >= current_scope and current_container.scope > 0):
							current_container = current_container.parent
							pass
					scoped = true
			
			current_token.scope = current_scope
			
			# match for merging tokens some more
			match current_token.type:
				ScreenplayImportToken.CompilerToken.SAY_NAME:
					current_token.type = ScreenplayImportToken.CompilerToken.XT_SAY_BLANK
					current_container.add_child( current_token )
					
				ScreenplayImportToken.CompilerToken.SAY_SEGMENT:
					if current_container.children.back().type == ScreenplayImportToken.CompilerToken.XT_SAY_BLANK:
						current_container.children.back().add_child(current_token)
						current_container.children.back().type = ScreenplayImportToken.CompilerToken.XT_SAY_PAIRED
					else:
						current_token.type = ScreenplayImportToken.CompilerToken.XT_SAY_CONTINUE
						current_container.add_child(current_token)
						pass
				
				ScreenplayImportToken.CompilerToken.IDENTIFIER, \
				ScreenplayImportToken.CompilerToken.INTEGER, \
				ScreenplayImportToken.CompilerToken.REAL_NUM, \
				ScreenplayImportToken.CompilerToken.VARIABLE, \
				ScreenplayImportToken.CompilerToken.QUOTE, \
				ScreenplayImportToken.CompilerToken.QUOTE:
					if (current_container.children.back().type == ScreenplayImportToken.CompilerToken.XT_COMMAND
					|| current_container.children.back().type == ScreenplayImportToken.CompilerToken.XT_EFFECT):
						current_container.children.back().add_child( current_token )
						pass
					
				ScreenplayImportToken.CompilerToken.EFFECT_OPEN:
					current_token.type = ScreenplayImportToken.CompilerToken.XT_EFFECT
					current_container.add_child( current_token )
					pass
					
				ScreenplayImportToken.CompilerToken.EFFECT_CLOSE:
					current_container.add_child(current_token)
					pass
				
				ScreenplayImportToken.CompilerToken.COMMAND_OPEN:
					current_token.type = ScreenplayImportToken.CompilerToken.XT_COMMAND
					current_container.add_child( current_token )
					pass
				
				ScreenplayImportToken.CompilerToken.COMMAND_CLOSE:
					current_container.add_child(current_token)
					pass
				
				ScreenplayImportToken.CompilerToken.TAB, \
				ScreenplayImportToken.CompilerToken.LINE_END:
					pass
				
				_:
					current_container.add_child(current_token)
			
			i += 1;
		
		print( token_tree_root.print_out() )
		
		pass
	
	# throw Option commands
	func _tree_pre_exporting():
		
		#var opt_return_counter:=1
		var default_suffix:="@1"
		var opt_tracker_suffix:="@8"
		var opt_return_suffix:="@6"
		var opt_goto_counter:=1
		var opt_goto_suffix:="@7"
		var jump_suffix:="@9"
		var opt_queue:Array[ScreenplayImportToken]=[]
		var tail_queue:Array[ScreenplayImportToken]=[]
		#var export_token_feed:Array[ScreenplayExportToken]=[]
		var current_export_token:ScreenplayExportToken
		var current_import_token:ScreenplayImportToken
		var i:int=0
		#var opt_queue_index:int=0
		
		# If the program fails to compile now, then the syntax will be proven wrong.
		# If it does not fail to compile, does it really matter?
		# Yes, it does, actually.
		export_header["syntax_version"] = SYNTAX_VERSION
		# If exported compile version < current compile version, then avoid running.
		# Maybe there could be a safe mode for "earliest compatible version".
		# Also don't run future versions. No futures and no distant pasts.
		export_header["compile_version"] = COMPILE_VERSION
		
		token_tree_root.children.append( \
		ScreenplayImportToken.new(ScreenplayImportToken.CompilerToken.XT_COMMAND, "finish") )
		
		while i < token_tree_root.children.size():
			current_import_token = token_tree_root.children[i]
			current_export_token = ScreenplayExportToken.new()
			
			if current_import_token.type != ScreenplayImportToken.CompilerToken.SWITCH:
				
				var j:int = opt_queue.size()
				while j > 0:
					j -= 1
					token_tree_root.children.insert(i, opt_queue[j])
				#token_tree_root.children.append_array( opt_queue )
				
				if opt_queue.size() > 0:
					opt_queue = []
					var ret_token = ScreenplayExportToken.new()
					ret_token.type = GlobalDirector.Cuecard.JUMP
					ret_token.args["target_from"] = str(opt_goto_counter, opt_tracker_suffix)
					export_token_feed.append( ret_token ) 
				
				opt_goto_counter = i
				current_import_token = token_tree_root.children[i]
			
			
			match current_import_token.type:
				
				ScreenplayImportToken.CompilerToken.XT_COMMAND:
					current_import_token.value = current_import_token.value.replace("-", "_")
					match current_import_token.value:
						"wait":
							current_export_token.type = GlobalDirector.Cuecard.WAIT
							if current_import_token.children.front() == null:
								current_export_token.args["duration"] = 0
							elif current_import_token.children.front().type == ScreenplayImportToken.CompilerToken.INTEGER:
								current_export_token.args["duration"] = current_import_token.children.front().value.to_int()
							elif current_import_token.children.front().type == ScreenplayImportToken.CompilerToken.REAL_NUM:
								current_export_token.args["duration"] = current_import_token.children.front().value.to_float()
							else:
								current_export_token.args["duration"] = current_import_token.children.front().value
							export_token_feed.append( current_export_token )
						"assert", "assign":
							current_export_token.type = GlobalDirector.Cuecard.ASSERT
							if current_import_token.children.size() >= 2:
								current_export_token.args["key"] = current_import_token.children.front().value
								if current_import_token.children[1].type == ScreenplayImportToken.CompilerToken.VARIABLE:
									current_export_token.args["value_from"] = current_import_token.children[1].value
								elif current_import_token.children[1].type == ScreenplayImportToken.CompilerToken.INTEGER:
									current_export_token.args["value_from"] = current_import_token.children[1].value.to_int()
								elif current_import_token.children[1].type == ScreenplayImportToken.CompilerToken.REAL_NUM:
									current_export_token.args["value_from"] = current_import_token.children[1].value.to_float()
								else:
									current_export_token.args["value"] = current_import_token.children[1].value
								export_token_feed.append( current_export_token )
						"walktowards", "walk_towards", "walk_target", "walk_anchor":
							current_export_token.type = GlobalDirector.Cuecard.WALK_TARGET
							if current_import_token.children.size() >= 2:
								current_export_token.args["target"] = current_import_token.children.front().value
								if current_import_token.children[1].type == ScreenplayImportToken.CompilerToken.IDENTIFIER:
									current_export_token.args["actor"] = current_import_token.children[1].value
									export_token_feed.append( current_export_token )
						"jump", "jump_to":
							current_export_token.type = GlobalDirector.Cuecard.JUMP
							if current_import_token.children.size() >= 1:
								if current_import_token.children.front().type == ScreenplayImportToken.CompilerToken.VARIABLE:
									current_export_token.args["target_from"] = current_import_token.children.front().value
								else:
									current_export_token.args["target"] = str(current_import_token.children.front().value, jump_suffix)
								export_token_feed.append( current_export_token )
						"jump_if", "jump_pos":
							current_export_token.type = GlobalDirector.Cuecard.JUMP_IF
							if current_import_token.children.size() >= 2:
								if current_import_token.children.front().type == ScreenplayImportToken.CompilerToken.VARIABLE:
									current_export_token.args["target_from"] = current_import_token.children.front().value
								else:
									current_export_token.args["target"] = str(current_import_token.children.front().value, jump_suffix)
								
								if current_import_token.children[1].type == ScreenplayImportToken.CompilerToken.VARIABLE:
									current_export_token.args["condition_from"] = current_import_token.children[1].value
								else:
									current_export_token.args["condition"] = str(current_import_token.children[1].value, jump_suffix)
								
								export_token_feed.append( current_export_token )
						"alias":
							current_export_token.type = GlobalDirector.Cuecard.ALIAS
							if current_import_token.children.size() >= 2:
								if current_import_token.children.front().type == ScreenplayImportToken.CompilerToken.IDENTIFIER:
									current_export_token.args["actor"] = current_import_token.children.front().value
								else:
									current_export_token.args["actor_from"] = current_import_token.children.front().value
								
								if current_import_token.children[1].type == ScreenplayImportToken.CompilerToken.IDENTIFIER:
									current_export_token.args["alias"] = current_import_token.children[1].value
								else:
									current_export_token.args["alias_from"] = current_import_token.children[1].value
								
								export_token_feed.append( current_export_token )
						"rename":
							current_export_token.type = GlobalDirector.Cuecard.UPDATE_NAME
							if current_import_token.children.size() >= 2:
								if current_import_token.children.front().type == ScreenplayImportToken.CompilerToken.IDENTIFIER:
									current_export_token.args["actor"] = current_import_token.children.front().value
								else:
									current_export_token.args["actor_from"] = current_import_token.children.front().value
								
								if current_import_token.children[1].type == ScreenplayImportToken.CompilerToken.QUOTE:
									current_export_token.args["name"] = current_import_token.children[1].value
								else:
									current_export_token.args["name_from"] = current_import_token.children[1].value
								
								export_token_feed.append( current_export_token )
						"avatar", "set_avatar":
							current_export_token.type = GlobalDirector.Cuecard.UPDATE_AVATAR
							if current_import_token.children.size() >= 2:
								if current_import_token.children.front().type == ScreenplayImportToken.CompilerToken.IDENTIFIER:
									current_export_token.args["actor"] = current_import_token.children.front().value
								else:
									current_export_token.args["actor_from"] = current_import_token.children.front().value
								
								if current_import_token.children[1].type == ScreenplayImportToken.CompilerToken.QUOTE:
									current_export_token.args["avatar"] = current_import_token.children[1].value
								else:
									current_export_token.args["avatar_from"] = current_import_token.children[1].value
								
								export_token_feed.append( current_export_token )
						"icon", "set_icon":
							current_export_token.type = GlobalDirector.Cuecard.UPDATE_AVATAR
							if current_import_token.children.size() >= 2:
								if current_import_token.children.front().type == ScreenplayImportToken.CompilerToken.IDENTIFIER:
									current_export_token.args["actor"] = current_import_token.children.front().value
								else:
									current_export_token.args["actor_from"] = current_import_token.children.front().value
								
								if current_import_token.children[1].type == ScreenplayImportToken.CompilerToken.QUOTE:
									current_export_token.args["icon"] = current_import_token.children[1].value
								else:
									current_export_token.args["icon_from"] = current_import_token.children[1].value
								
								export_token_feed.append( current_export_token )
						"db_read", "sql_read":
							current_export_token.type = GlobalDirector.Cuecard.DB_READ
							if current_import_token.children.size() >= 3:
								if current_import_token.children.front().type == ScreenplayImportToken.CompilerToken.VARIABLE:
									current_export_token.args["key_from"] = current_import_token.children.front().value
								else:
									current_export_token.args["key"] = current_import_token.children.front().value
								
								current_export_token.args["var"] = current_import_token.children[1].value
								
								if current_import_token.children[2].type == ScreenplayImportToken.CompilerToken.VARIABLE:
									current_export_token.args["database_from"] = current_import_token.children[2].value
								else:
									current_export_token.args["database"] = current_import_token.children[2].value
								
								export_token_feed.append( current_export_token )
						"db_write", "sql_write":
							current_export_token.type = GlobalDirector.Cuecard.DB_WRITE
							if current_import_token.children.size() >= 3:
								if current_import_token.children.front().type == ScreenplayImportToken.CompilerToken.VARIABLE:
									current_export_token.args["key_from"] = current_import_token.children.front().value
								else:
									current_export_token.args["key"] = current_import_token.children.front().value
								
								current_export_token.args["var"] = current_import_token.children[1].value
								
								if current_import_token.children[2].type == ScreenplayImportToken.CompilerToken.VARIABLE:
									current_export_token.args["database_from"] = current_import_token.children[2].value
								else:
									current_export_token.args["database"] = current_import_token.children[2].value
								
								export_token_feed.append( current_export_token )
						"create_actor":
							current_export_token.type = GlobalDirector.Cuecard.CREATE
							current_export_token.args["type"] = "gamepiece"
							if current_import_token.children.size() >= 4:
								if current_import_token.children.front().type == ScreenplayImportToken.CompilerToken.VARIABLE:
									current_export_token.args["actor_from"] = current_import_token.children.front().value
								else:
									current_export_token.args["actor"] = current_import_token.children.front().value
								
								if current_import_token.children[1].type == ScreenplayImportToken.CompilerToken.VARIABLE:
									current_export_token.args["umid_from"] = current_import_token.children[1].value
								else:
									current_export_token.args["umid"] = current_import_token.children[1].value
								
								if current_import_token.children[2].type == ScreenplayImportToken.CompilerToken.VARIABLE:
									current_export_token.args["name_from"] = current_import_token.children[2].value
								else:
									current_export_token.args["name"] = current_import_token.children[2].value
								
								if current_import_token.children[3].type == ScreenplayImportToken.CompilerToken.VARIABLE:
									current_export_token.args["avatar_from"] = current_import_token.children[3].value
								else:
									current_export_token.args["avatar"] = current_import_token.children[3].value
								
								export_token_feed.append( current_export_token )
						"recruit_actor":
							current_export_token.type = GlobalDirector.Cuecard.RECRUIT_PIECE
							if current_import_token.children.size() >= 2:
								if current_import_token.children.front().type == ScreenplayImportToken.CompilerToken.IDENTIFIER:
									current_export_token.args["actor"] = current_import_token.children.front().value
								else:
									current_export_token.args["actor_from"] = current_import_token.children.front().value
								
								if current_import_token.children.back().type == ScreenplayImportToken.CompilerToken.VARIABLE:
									current_export_token.args["umid_from"] = current_import_token.children.back().value
								else:
									current_export_token.args["umid"] = current_import_token.children.back().value
								
								export_token_feed.append( current_export_token )
						"create_prop":
							current_export_token.type = GlobalDirector.Cuecard.CREATE
							current_export_token.args["type"] = "gametoken"
							if current_import_token.children.size() >= 2:
								if current_import_token.children.front().type == ScreenplayImportToken.CompilerToken.VARIABLE:
									current_export_token.args["actor_from"] = current_import_token.children.front().value
								else:
									current_export_token.args["actor"] = current_import_token.children.front().value
								
								if current_import_token.children.back().type == ScreenplayImportToken.CompilerToken.VARIABLE:
									current_export_token.args["avatar_from"] = current_import_token.children.back().value
								else:
									current_export_token.args["avatar"] = current_import_token.children.back().value
								
								current_export_token.args["umid"] = -1
								
								if current_import_token.children.size() >= 3:
									if current_import_token.children[1].type == ScreenplayImportToken.CompilerToken.VARIABLE:
										current_export_token.args["name_from"] = current_import_token.children[1].value
									else:
										current_export_token.args["name"] = current_import_token.children[1].value
								else:
									current_export_token.args["name"] = "?"
								
								export_token_feed.append( current_export_token )
						"recruit_prop":
							current_export_token.type = GlobalDirector.Cuecard.RECRUIT_TOKEN
							if current_import_token.children.size() >= 2:
								if current_import_token.children.front().type == ScreenplayImportToken.CompilerToken.IDENTIFIER:
									current_export_token.args["prop"] = current_import_token.children.front().value
								else:
									current_export_token.args["prop_from"] = current_import_token.children.front().value
								
								if current_import_token.children.back().type == ScreenplayImportToken.CompilerToken.VARIABLE:
									current_export_token.args["tokenid_from"] = current_import_token.children.back().value
								else:
									current_export_token.args["tokenid"] = current_import_token.children.back().value
								
								export_token_feed.append( current_export_token )
						"save_actor":
							current_export_token.type = GlobalDirector.Cuecard.SAVE_ACTOR
							if current_import_token.children.size() >= 2:
								if current_import_token.children.front().type == ScreenplayImportToken.CompilerToken.IDENTIFIER:
									current_export_token.args["actor"] = current_import_token.children.front().value
								else:
									current_export_token.args["actor_from"] = current_import_token.children.front().value
								
								if current_import_token.children[2].type == ScreenplayImportToken.CompilerToken.VARIABLE:
									current_export_token.args["database_from"] = current_import_token.children[2].value
								else:
									current_export_token.args["database"] = current_import_token.children[2].value
								
								export_token_feed.append( current_export_token )
						"load_actor":
							current_export_token.type = GlobalDirector.Cuecard.LOAD_ACTOR 
							if current_import_token.children.size() >= 1:
								if current_import_token.children.front().type == ScreenplayImportToken.CompilerToken.IDENTIFIER:
									current_export_token.args["actor"] = current_import_token.children.front().value
								else:
									current_export_token.args["actor_from"] = current_import_token.children.front().value
								
								if current_import_token.children.size() >= 2:
									if current_import_token.children[1].type == ScreenplayImportToken.CompilerToken.VARIABLE \
									|| current_import_token.children[1].type == ScreenplayImportToken.CompilerToken.IDENTIFIER:
										current_export_token.args["umid_from"] = current_import_token.children[1].value
									else:
										current_export_token.args["umid"] = current_import_token.children[1].value
								
								export_token_feed.append( current_export_token )
						"chmod", "chmode", "set_perms", "perms":
							pass
						"chgrp", "chgroup", "set_group", "group":
							pass
						"add_store":
							pass
						"sub_store", "subtract_store":
							pass
						"animate":
							pass
						"set_pos", "position":
							pass
						"set_facing", "face_direction", "direction":
							pass
						"facing_point", "face_point":
							pass
						"facing_actor", "face_actor":
							pass
						"playpad", "play_pad", "auto_key", "autokey":
							pass
						"cam_follow":
							pass
						"cam_effect":
							pass
						"cam_snap":
							pass
						"cinematic", "cine", "play_cine":
							current_export_token.type = GlobalDirector.Cuecard.CINEMATIC
							if current_import_token.children.size() >= 1:
								if current_import_token.children.front().type == ScreenplayImportToken.CompilerToken.VARIABLE:
									current_export_token.args["path_from"] = current_import_token.children.front().value
									export_token_feed.append( current_export_token )
								elif current_import_token.children.front().type == ScreenplayImportToken.CompilerToken.QUOTE:
									current_export_token.args["path"] = current_import_token.children.front().value
									export_token_feed.append( current_export_token )
							
							# if parameter is just a number, watch out! That could be malware.
							# All numbers are malware when put in the right context.
							# .\w/. <("300!")  ("444H!")> 0o0
							# should warn developer if there's no matching 'await_cine', but eh.
						"await_cinematic", "await_cine", "cine_await", "cinematic_await":
							current_export_token.type = GlobalDirector.Cuecard.AWAIT_CINE
							if current_import_token.children.size() >= 1:
								if current_import_token.children.front().type == ScreenplayImportToken.CompilerToken.VARIABLE:
									current_export_token.args["path_from"] = current_import_token.children.front().value
								elif current_import_token.children.front().type == ScreenplayImportToken.CompilerToken.QUOTE:
									current_export_token.args["path"] = current_import_token.children.front().value
								
								# no path/name given = wait for all of them to be over.
								# wrong path = warn the developer, else do nothing
								export_token_feed.append( current_export_token )
						"walk_mode", "traversal_mode", "traverse_mode":
							pass
						"walk_point", "walk_to_point":
							pass
						"walk_path":
							pass
						"follow", "follow_actor":
							pass
						"set_hour":
							pass
						"lock_hour":
							pass
						"unlock_hour":
							pass
						"set_date":
							pass
						"lock_date":
							pass
						"unlock_date":
							pass
						"weather", "set_weather":
							pass
						"finish":
							current_export_token.type = GlobalDirector.Cuecard.FINISH
							export_token_feed.append( current_export_token )
							pass
						"dismiss":
							pass
						"dismiss_all":
							pass
						"free":
							pass
						"say":
							pass
						"push_option":
							pass
						"syntax_version":
							if current_import_token.children.size() >= 1:
								export_header["syntax_version"] = str(current_import_token.children.front().value).to_int()
							else:
								export_header["syntax_version"] = -1
							pass
						_:
							pass
				
				ScreenplayImportToken.CompilerToken.XT_EFFECT:
					current_import_token.value = current_import_token.value.replace("-", "_")
					match current_import_token.value:
						"wait":
							current_export_token.type = GlobalDirector.Cuecard.WAIT
							if current_import_token.children.front() == null:
								current_export_token.args["duration"] = 0
							elif current_import_token.children.front().type == ScreenplayImportToken.CompilerToken.INTEGER:
								current_export_token.args["duration"] = current_import_token.children.front().value.to_int()
							elif current_import_token.children.front().type == ScreenplayImportToken.CompilerToken.REAL_NUM:
								current_export_token.args["duration"] = current_import_token.children.front().value.to_float()
							else:
								current_export_token.args["duration"] = current_import_token.children.front().value
							export_token_feed.append( current_export_token )
						"clear":
							pass
						"more", "contd", "continue":
							pass
						"emote":
							pass
						"clear":
							pass
				
				ScreenplayImportToken.CompilerToken.XT_SAY_PAIRED:
					current_export_token.type = GlobalDirector.Cuecard.DIALOG
					current_export_token.args["actor"] = current_import_token.value
					current_export_token.args["quote"] = str(current_import_token.children.front().value)
					export_token_feed.append( current_export_token )
				
				ScreenplayImportToken.CompilerToken.XT_SAY_BLANK:
					current_export_token.type = GlobalDirector.Cuecard.DIALOG
					current_export_token.args["actor"] = current_import_token.value
					current_export_token.args["quote"] = ""
				
				ScreenplayImportToken.CompilerToken.XT_SAY_CONTINUE:
					current_export_token.type = GlobalDirector.Cuecard.DIALOG_INJECT
					current_export_token.args["quote"] = current_import_token.value
				
				ScreenplayImportToken.CompilerToken.JUMP_TARGET:
					current_export_token.type = GlobalDirector.Cuecard.JUMP_TARGET
					if !current_import_token.value.ends_with(opt_goto_suffix) && \
					!current_import_token.value.ends_with(opt_return_suffix):
						current_export_token.args["target"] = str(current_import_token.value.left(16), i, opt_goto_suffix)
					else:
						current_export_token.args["target"] = current_import_token.value
					export_token_feed.append( current_export_token )
				
				ScreenplayImportToken.CompilerToken.XT_JUMP:
					
					current_export_token.type = GlobalDirector.Cuecard.JUMP
					current_export_token.args["target"] = current_import_token.value
					
					export_token_feed.append( current_export_token )
					pass
				
				ScreenplayImportToken.CompilerToken.SWITCH:
					var subroutine = ScreenplayImportToken.new()
					subroutine.type = ScreenplayImportToken.CompilerToken.JUMP_TARGET
					subroutine.value = str(current_import_token.value.left(16), i, opt_goto_suffix)
					
					var goto_target =  ScreenplayImportToken.new()
					goto_target.type = ScreenplayImportToken.CompilerToken.QUOTE
					goto_target.value = str(current_import_token.value.left(16), i, opt_goto_suffix)
					
					var goto_tkn = ScreenplayImportToken.new()
					goto_tkn.type = ScreenplayImportToken.CompilerToken.XT_COMMAND
					goto_tkn.value = "jump_match"
					goto_tkn.children.append( goto_target )
					
					current_export_token.type = GlobalDirector.Cuecard.DIALOG_CHOICE
					current_export_token.args["quote"] = current_import_token.value
					current_export_token.args["store"] = str(opt_goto_counter, opt_tracker_suffix)
					current_export_token.args["target"] = str(current_import_token.value.left(16), i, opt_goto_suffix)
					
					if opt_queue.size() < 1:
						var ret_target = ScreenplayImportToken.new()
						ret_target.type = ScreenplayImportToken.CompilerToken.JUMP_TARGET
						ret_target.value = str(opt_goto_counter, opt_return_suffix)
						opt_queue.append( ret_target )
					
					export_token_feed.append( current_export_token )
					opt_queue.push_front( goto_tkn )
					tail_queue.append( subroutine )
					tail_queue.append_array( current_import_token.children )
					
					var ret_token = ScreenplayImportToken.new()
					ret_token.type = ScreenplayImportToken.CompilerToken.XT_JUMP
					ret_token.value = str(opt_goto_counter, opt_return_suffix)
					tail_queue.append( ret_token )
					
					pass
				
				_:
					pass
				
			
			token_tree_root.children.append_array(tail_queue)
			tail_queue = []
			
			i+=1
		
		# if switch: queue 'option jump_match queue', queue return marker, ...
			# ... dump in-option @ list end along with a return jump
		# if not switch: dump jump_match queue, then the return marker
		pass
	
	# convert each token cluster into a single command for each token listed
	func _export_to_file():
		var file = FileAccess.open(export_path, FileAccess.WRITE)
		if file != null:
			file.store_line( JSON.stringify( export_header ) )
			
			for tkn in export_token_feed:
				file.store_line( tkn._get_jsoned() )
			pass
		else:
			print( str(export_path, " file is not cooperating. Terminating.") )
	pass

class ScreenplayExportToken extends RefCounted:
	
	var type:GlobalDirector.Cuecard
	var args:Dictionary
	#var parent:ScreenplayExportToken
	#var children:Array[ScreenplayExportToken]
	#
	#func add_child(new_child:ScreenplayExportToken):
	#	children.append(new_child)
	#	new_child.parent = self
	#	pass
	
	func _init(_type:=GlobalDirector.Cuecard.WAIT, _args:={}):
		type = _type
		args = _args
		pass
	
	func _get_jsoned() -> String:
		var argsplus := args.duplicate()
		argsplus["_cuecard"] = type
		return JSON.stringify(argsplus, "", true, true)
	
	pass

class ScreenplayImportToken extends RefCounted:
	
	enum CompilerToken {
		EMPTY = 0,		# got!
		COMMA,			# got!
		COLON,			# got!
		ESCAPE,			# don't got, don't need
		SLASH,			# got! used for division and comments
		IDENTIFIER,		# got? used for character names...
		QUOTE,			# got!
		INTEGER,		# got!
		REAL_NUM,		# got!
		VARIABLE,		# got!
		COMMAND_OPEN,	# got!
		COMMAND_CLOSE,	# got!
		SYMBOLIC_SPACE,	# got?
		EFFECT_OPEN,	# got!
		EFFECT_CLOSE,	# got!
		OPTION,			# got?
		EQ,				# got?
		EQEQ,			# got?
		JUMP_TARGET,		# got!
		SAY_NAME,		# got!
		SAY_SEGMENT,	# got!
		TAB,			# got!
		LINE_START,		# got! used for say-name placement
		LINE_END,		# got! used for comments and debugging
		SWITCH,
		INVALID,
		# XT short for XTree, which means Avoid Using except for Treeification
		XT_ROOT,
		XT_SAY_BLANK,
		XT_SAY_PAIRED,
		XT_SAY_CONTINUE,
		XT_SAY_INTERRUPT,
		XT_COMMAND,
		XT_EFFECT,
		XT_JUMP,
	}
	
	var type:CompilerToken=CompilerToken.EMPTY
	var value:String
	var scope:int
	var parent:ScreenplayImportToken
	var children:Array[ScreenplayImportToken]=[]
	
	func add_child(new_child:ScreenplayImportToken):
		children.append(new_child)
		new_child.parent = self
		pass
	
	func _init(_type:=CompilerToken.EMPTY, _value:=""):
		self.type = _type
		self.value = _value
	
	func print_out() -> String:
		var streng = str(CompilerToken.find_key(type), " / ", scope, " : ", value, "[")
		for child in children:
			for line in child.print_out().split("\n"):
				streng += str( "\n\t", line )
		streng += "]"
		return streng
	
	pass
