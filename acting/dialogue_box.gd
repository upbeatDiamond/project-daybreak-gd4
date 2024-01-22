extends Control
class_name DialogueBox
# formerly "DialogueBoxMain", but really, non-main can just reimplement the child nodes.

# Text and cutscene separation terms:

# screenplay - list of commands for a cutscene, which may include dialogue
# page - readout of a screenplay, after it has been "compiled" but before it's ready for display
# line - one cue/cuecard/event with storage-friendly format, not ready-for-use format
# cuecard - command/task/event as part of a cutscene timeline
# excerpt - block of text to process and display; may be split
# snippet - split version of excerpt, used to display to textbox

# typewriter - machine used to type one symbol at a time with inked hammers, or a simulation of it.

enum Mood {
	NEUTRAL = 0,
	PROUD,
	HAPPY,
	JOYOUS,
	TOUGH,
	DETERMINED,
	THINKING,	# or, Curious
	CONFUSED,
	SUPRISED,	# or, Shocked
	ASTOUNDED,	# or, Amazed
	TEARY_EYED,	# or, Slightly Sad
	SAD,
	SCARED,
	FRIGHTENED,
	ANGRY,
	FURIOUS,
	DIZZY,
	PAINED,
	AMUSED,
	LAUGHING,
	WEARY,
	SLEEPY,
	AWKWARD,
	GRIN,
	CUTE,
}

enum IconMoodMode{
	SUBTEXTURE_LINEAR_INDEX = 0,
	SUBTEXTURE_DIAGONAL_INDEX,
}

@onready var textbox : RichTextLabel = find_child( "TextBox", true )
@onready var namebox : RichTextLabel = find_child( "NameBox", true )
@onready var icon : TextureRect = find_child( "Avatar", true )
@onready var audio_player : AudioStreamPlayer = find_child( "Speaker", true )
#var vis_char = -1

# the type time constants store different printing speed modes
# the type speed variable basically stores how fast the text should be printed
const TYPE_SPEED_NORMAL = 16.0
const TYPE_SPEED_VERY_SLOW = TYPE_SPEED_NORMAL / 4
const TYPE_SPEED_SLOW = TYPE_SPEED_NORMAL / 2
const TYPE_SPEED_FAST = TYPE_SPEED_NORMAL * 2
const TYPE_SPEED_VERY_FAST = TYPE_SPEED_NORMAL * 4

var type_speed = TYPE_SPEED_VERY_FAST
var punct_multiplier = 1.5

# the type time constants store different talking speed modes
# the type time variable basically stores which mode is currently used
const TYPE_TIME_DEFAULT = 1.0
var type_time = TYPE_TIME_DEFAULT

var speech_sfx : AudioStream

var skip_requested = false
var is_typing = false
# func process input: if is_typing & skip button detected, skip_requested

# for variables to work out before displaying, first priority
#@onready var regex_var := RegEx.create_from_string( "[^\\\\]\\\\{\\$[a-zA-Z_0-9]*\\}" )
# for translations to work out before displaying, second priority (eh, highest priority but last)
#@onready var regex_trx := RegEx.create_from_string( "[^\\\\]\\{&tr[x]?=[a-zA-Z_0-9]*\\}")

var has_started:= false

@export var mood_icon_scale := Vector2i(40, 40)







func _ready():
	textbox.visible_characters = 0
	pass

func _process(delta):
	if !has_started:
		has_started = true
		
		set_mood( 0 )
		set_text( "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."  )
		
		await typewriter_printout()
		var mooder = 4
		var char_timer = Timer.new()
		while true:
			char_timer = get_tree().create_timer( type_time * 20 / type_speed ) # replace this line with waiting for user responsiveness
			await char_timer.timeout
			mooder = (mooder + 1) % 5
			set_mood( mooder )
		
	pass


func typewriter_printout():
	var char_timer = Timer.new()
	var total_chars = textbox.get_total_character_count();
	
	while textbox.visible_characters < total_chars:
		char_timer = get_tree().create_timer( type_time / type_speed ) # replace this line with waiting for user responsiveness
		await char_timer.timeout
		#vis_char += 1
		textbox.visible_characters += 1
	
	print("Ding!")

## TODO: implement this.
func push_choice( quote:String, store_key:String, store_value:String ):
	
	pass

func hide_dialogue_box():
	pass

func clear_textbox():
	textbox.visible_characters = 0
	textbox.text = ""

# Adds text to the end of the current text
# Added text might not be visible immediately, as it should animate into existance
func append_text( suffix ):
	textbox.text += str(suffix)
	pass

func set_text( _text ):
	textbox.text = str(_text)
	pass

func set_display_name( _name ):
	namebox.text = str(_name)
	pass

func set_mood( mood:int ):

	var icon_count = icon.texture.atlas.get_size() / Vector2( mood_icon_scale )
	var max_mood = icon_count.x * icon_count.y
	var new_region
	
	print(mood, max_mood)
	if mood >= 0 && mood < max_mood:
		new_region = Rect2( Vector2( int(mood)%int(icon_count.x), int(mood)/int(icon_count.y)), \
		(icon.texture as AtlasTexture).region.size )
		
		new_region.position = new_region.position * Vector2( mood_icon_scale )
		print( str(new_region, icon.texture.region) )
		
		(icon.texture as AtlasTexture).region  = new_region
	
	pass

func reset_text():
	clear_textbox()
	pass
