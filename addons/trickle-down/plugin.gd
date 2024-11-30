########################
#
# To run this code, download Godot 4.x, preferably from the following URL:
# https://godotengine.org/download/archive/4.2-stable/
# Once Godot is downloaded, it should run with no installation needed.
# Create a new project, and locate the folder in your computer.
# Move this script into the project folder, and in the project, create a 2D scene
# Attach this script to the root node of the scene, and click the play button in the top right folder.
#
# The code might also be runnable in VSCode using...
# 	https://marketplace.visualstudio.com/items?itemName=geequlim.godot-tools
# ... but this has not been tested and should not be relied upon.
#
########################

class_name TrickleDown

const ALPHABET = "-abcdefghijklmnopqrstuvwxyz."
const ALPHA_PAD = "-"
const INT_MAX = 9223372036854775807

var key:String
var shape_in: Array[int]  = [14, 28, 49, 6, 5, 25, 59, 37, 20, 40, 26, 46, 27, 58, 62, 61, 
							33, 44, 36, 42, 39, 15, 16, 31, 29, 21, 47, 2, 17, 54, 51, 1, 
							60, 24, 10, 57, 18, 38, 30, 4, 12, 43, 56, 3, 9, 11, 48, 22, 
							34, 64, 53, 13, 32, 35, 55, 41, 50, 19, 63, 8, 45, 23, 52, 7]
var shape_out: Array[int] = [4, 34, 29, 16, 41, 22, 56, 55, 51, 23, 52, 32, 43, 20, 9, 1, 
							38, 11, 19, 42, 63, 45, 57, 35, 33, 59, 62, 27, 36, 17, 44, 24, 
							7, 14, 46, 64, 31, 18, 26, 15, 58, 21, 50, 8, 30, 10, 28, 40, 
							60, 49, 5, 39, 12, 2, 53, 3, 6, 25, 48, 54, 13, 37, 47, 61]


# Called when the node enters the scene tree for the first time.
func _ready():	
	var plaintext = "shadow the hedgehod is so mean"
	key = "keybind"
	var ciphertext = encode( shape_in, shape_out, key, plaintext, 1)
	print( ciphertext )
	print( decode( shape_in, shape_out, key, ciphertext, 1) )
	
	plaintext = "shadow the hedgehod is so cool"
	key = "keybind"
	ciphertext = encode( shape_in, shape_out, key, plaintext, 15)
	print( ciphertext )
	print( decode( shape_in, shape_out, key, ciphertext, 15) )
	pass # Replace with function body.


func char_at( _str:String, index:int):
	if index >= _str.length():
		return ALPHA_PAD
	return _str.substr(index, 1)


func int_to_char(value:int):
	value = posmod(value, ALPHABET.length())
	return char_at(ALPHABET, value)


func char_to_int( chr:String ):
	chr = chr.to_lower() + 'z'
	var index = ALPHABET.find(char_at(chr, 0))
	if index < 0:
		return ALPHABET.find(char_at(ALPHA_PAD, 0))
	return index


func validate_shape( _shape:Array[int], length:int=INT_MAX ):
	var valid_shape:Array[int] = []
	valid_shape.resize( _shape.size() )
	var valid_shape_index = 0
	
	# If length WAS specified and does NOT match _shape's size, resize _shape
	if _shape.size() > length or (_shape.size() < length and length < INT_MAX):
		_shape.resize( length )
	
	# If it uses INT_MAX, it was invalid anyways. Set to a lower number.
	while _shape.max() >= INT_MAX:
		_shape[ _shape.find(INT_MAX) ] = -1
	
	# While there is a number below INT_MAX, take note of its position using the v_s_i counter.
	while _shape.min() < INT_MAX:
		valid_shape[ _shape.find(_shape.min()) ] = valid_shape_index
		valid_shape_index += 1
		_shape[ _shape.find(_shape.min()) ] = INT_MAX
	
	return valid_shape


func rotate_string( _str:String, rot:int ) -> String:
	var result := ""
	for i in range(0, _str.length(), 1):
		result += int_to_char( char_to_int( char_at(_str, i) ) + rot )
	return result


func encode( _shape_in:Array[int], _shape_out:Array[int], _key:String, plaintext:String, _rotate:int=0 ) -> String:
	
	var output:String = ""
	
	# generate arrays for input shape, output shape, and intermediate storage
	var shape_len = min( _shape_in.size(), _shape_out.size() )
	key = _key
	shape_in = validate_shape( _shape_in, shape_len )
	shape_out = validate_shape( _shape_out, shape_len )
	var shape = []
	shape.resize(shape_len + key.length())
	plaintext = plaintext.rpad( shape_len, ALPHA_PAD )
	
	# rorate the plaintext, as a cheap form of substitution cipher akin to Caesar Cipher.
	#print(" plaintext was '", plaintext, "'")
	plaintext = rotate_string( plaintext.strip_edges().to_lower(), _rotate )
	#print(" plaintext is '", plaintext, "'")
	
	# populate arrays with key and plaintext as individual letters
	for i in range(key.length()):
		shape[ i ] = char_to_int( char_at(key, i) )
	for i in range(shape_in.size()):
		shape[ shape_in[i] + key.length() ] = char_to_int( char_at(plaintext, i) )
	
	# the "trickle down" part: adding the sum of previous rows
	for i in range(key.length(), shape.size(), 1):
		shape[i] = posmod(  (shape[i] + shape[i-key.length()]), ALPHABET.length()  )
	
	# rearranging the result, putting it into a string.
	for i in range(0, shape_out.size(), 1):
		output = str( output, int_to_char( shape[ shape_out[i] + key.length() ] ));
	
	return output


func decode( _shape_in:Array[int], _shape_out:Array[int], _key:String, ciphertext:String, _rotate:int=0  ) -> String:
	
	var output:String = ""
	ciphertext = ciphertext.strip_edges().to_lower()
	
	# generate arrays for input shape, output shape, and intermediate storage
	var shape_len = min( _shape_in.size(), _shape_out.size() )
	key = _key
	shape_in = validate_shape( _shape_in, shape_len )
	shape_out = validate_shape( _shape_out, shape_len )
	var shape = []
	shape.resize(shape_len + key.length())
	
	# populate arrays with key and plaintext as individual letters
	for i in range(key.length()):
		shape[ i ] = char_to_int( char_at(key, i) )
	
	print()
	
	for i in range(shape_in.size()):
		shape[ shape_out[i] + key.length() ] = char_to_int( char_at(ciphertext, i) )
	
	print( shape )
	
	# the "trickle down" part: adding the sum of previous rows
	for i in range(shape.size()-1, key.length()-1, -1):
		shape[i] = posmod(  (shape[i] - shape[i-key.length()]), ALPHABET.length()  )
		var q = int_to_char( shape[i] );
		#print(q)
	
	print( shape_in )
	
	# rearranging the result, putting it into a string.
	for i in range(0, shape_in.size(), 1):
		output = str( output, int_to_char( shape[ shape_in[i] + key.length() ] ));
	
	#print(" plaintext is '", output, "'")
	output = rotate_string( output, -_rotate )
	#print(" plaintext was '", output, "'")
	return output
