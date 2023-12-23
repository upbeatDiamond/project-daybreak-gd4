extends Node
# This class is dedicated to the fetching and generation of monsters

var umid_counter:=0
var umid_buffer:Array[int]=[]

const UMID_BUFFER_MAX:=256	# Can never be more than this full.
const UMID_BUFFER_MIN:=128	# Needs to be at least this full at any idle moment
var umid_buffer_index = 0	# The current place in the awway to take from
var umid_buffer_size = 0	# The estimated amount of UMIDs remaining in the buffer
var umid_printed:=false


# Called when the node enters the scene tree for the first time.
func _ready():
	umid_buffer.resize( UMID_BUFFER_MAX )
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if umid_buffer_size < UMID_BUFFER_MIN:
		call_deferred( "fill_umid_buffer" )
	elif umid_buffer.size() > UMID_BUFFER_MAX:
		umid_buffer.slice(umid_buffer.size() - UMID_BUFFER_MIN)

# Checks database for monster. If not found, create a new one.
# MAKE SURE TO STORE IVs AND EVs IN THE DATABASE BEFORE HANDING BACK THE MONSTER IF THESE...
# ... ARE NOT STORED WITHIN THE MONSTER

func spawn_monster( rng_seed: int, spawn_weights: Dictionary ) -> Object:
	return null
	#pass

# Should check the database to ensure there are no duplicate values.
func get_fresh_umid():
	var export = umid_buffer[umid_buffer_index]
	
	while umid_buffer_size <= 0:
		fill_umid_buffer()
	
	umid_buffer_index = (umid_buffer_index - 1) % UMID_BUFFER_MAX	# decrement index, wraparound
	umid_buffer_size = min( umid_buffer_size-1, UMID_BUFFER_MAX )	# decrement size, limit
	return export


func fill_umid_buffer():
	umid_buffer.resize( UMID_BUFFER_MAX )
	
	if umid_buffer_size < UMID_BUFFER_MAX:
		umid_buffer.insert( umid_buffer_index, generate_umid() )
		umid_buffer_index = (umid_buffer_index + 1) % UMID_BUFFER_MAX	# increment index, wraparound
		umid_buffer_size = min( umid_buffer_size+1, UMID_BUFFER_MAX )	# increment size, limit
	pass

## TODO: incorporate the location a monster is found in into the UMID, so long as complexity is not lost.
# Universal/Unique Monster Identification (Document)
func generate_umid() -> int:
	
	# UMID: pronounced like "ju-em ai-dii" / "You am, I Dee"
	# umid: pronounced like UMID or like "humid" but with no 'h'. Same exact meaning.
	# No IPA here because it messes up the character spacing in the Godot editor
	
	# using Twitter, Discord, and Sony as a basis...
	# ...knowing that Discord and Sony used Twitter as a basis...
	# We start with the sign bit, and the time.
	# We'll approximate Sony's way for this part, tracking more time but with less precision.
	
	# Assume a 64 bit integer
	var export_umid:= 0;
	
	var unix_time = Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system())
	unix_time = unix_time * 1000
	var milliseconds = Time.get_ticks_msec() % 1000
	@warning_ignore("integer_division")
	unix_time = int(unix_time + milliseconds) / 10 
	
	export_umid = unix_time << (64-40) # bits in an integer - (1 + timestamp length)
	
	# We now have 24 bits to play with.
	# Let's implement the machine ID next.
	# I absolutely write this before, what?
	var machine_id = OS.get_unique_id().md5_buffer().decode_u64(0)
	export_umid = export_umid | ( machine_id >> 40 )
	
	# Now the entire ID is a timestamp and a computer ID.
	# It did obfuscate the timestamp and computer ID together before, but now it doesn't.
	# Less secure for the wary, but more secure for the gamers because less chance of collisions
	
	# Finally, the incrementor, which allows for more monsters generated per 10 ms.
	# ...per centisecond? It might also slow down the system slightly, making itself useless...
	# ...if it weren't for those RGB 65k CUP core 10M hz computer (doubles as oven)
	# Although... there can still be overflow if over 2048 UMIDs are generated in one centisec.
	# Which would require a generation rate of over 200,000 per second
	
	umid_counter = (umid_counter + 1) % 0b1000_0000_0000
	export_umid = export_umid + umid_counter
	
	# practically impossible to achieve. You need some real TAS to get this.
	# maybe if the game runs for many years, and overlaps with the incrementor?
	if export_umid < 512:
		print( str(export_umid, " is not a valid ID, recalculating...") )
		return generate_umid()
	
	# if UMID does not yet exist, return that it can be used
	# if UMID does exist, keep poking around at new values until an unused UMID is found
	# spare IDs may be stored to avoid loading times when new monsters are generated
	export_umid = GlobalDatabase.validate_umid( export_umid )
	
	return export_umid
