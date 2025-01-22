extends Node
# Most of this stuff oughta be static methods.


var umid_counter:=0
var umid_buffer:Array[int]=[]

const UMID_BUFFER_MAX:=256	# Can never be more than this full.
const UMID_BUFFER_MIN:=128	# Needs to be at least this full at any idle moment
#var umid_buffer_index = 0	# The current place in the awway to take from
#var umid_buffer_size = 0	# The estimated amount of UMIDs remaining in the buffer
var umid_printed:=false


const MAX_BATTLE_TECHNIQUES = 4

#region Enums

enum PersonalityFactor {
	WARMTH,   		# Low = detached,	High = outgoing
	REASONING,		# Low = concrete,	High = abstract
	STABILITY,		# Low = easily upset,	High = mature
	DOMINANCE,		# Low = humble,	High = dominant
	LIVELINESS,		# Low = restrained,	High = expressive
	LAWFULNESS,		# Low = expedient,	High = dutiful
	BOLDNESS,		# Low = hesitant,	High = uninhibited
	SENSITIVITY,	# Low = utilitarian,	High = sentimental
	VIGILANCE,		# Low = trusting,	High = skeptical
	ABSTRACTNESS,	# Low = practical,	High = imaginative
	PRIVACY,		# Low = genuine,	High = shrewd
	APPREHENSION,	# Low = guiltless,	High = insecure
	EXPERIMENTAL,	# Low = traditional,	High = open to change
	INDIVIDUALISM,	# Low = affiliative,	High = self-reliant
	PERFECTIONISM,	# Low = fine w/chaos,	High = compulsive
	TENSION,		# Low = patient,	High = frustrated
}

## This is used to enable monster breeding to carry color.
## This should be directly stored in the Monster, used to generate color palette
## The number of genes present is the minimum needed for the goals of the ...
## ... design document, and may be expanded in the future.
enum ColorGene {
	COMMON = 0,	# Default or neutral coloring; 0 because default
	BLACK,	# Dark / Black; might cancel out w/ WHITE
	WHITE,	# Pale / Albino; might cancel out w/ BLACK
	SHINY,	# Recessive; often acts like COMMON
}

## This is used to unify color expression based on color genes
## This should not be directly stored in the Monster database table
## Expression might change based on difficulties faced; genes may only increase
## For example: BW/WB might become GREY, or BC and CB might express differently
## As of the time of writing this comment, this is intended for fetching ...
## ... color palette choices for monster sprites.
enum ColorExpression{
	COMMON,	# CC, CS/SC, BW/WB
	DARK,	# BC/CB, BS/SB
	BLACK,	# BB
	PALE,	# WC/CW, WS/SW
	WHITE,	# WW
	SHINY,	# SS
}

enum RelationshipFactors{
	AFFECTION,		# Influenced by pF Warmth, Sensitivity, Abstractness
	TRUST,   		# Influenced by pF Vigilance, Privacy, Apprehension
	RESPECT,		# Influenced by pF Stability, Abstractness, Perfectionism
	INTIMACY,		# Influenced by pF Experimental, Sensitivity, Boldness
	OBSESSION,		# Influenced by pF Individualism, Boldness, Dominance
	PLAYFULNESS,	# Influenced by pF Warmth, Liveliness, Boldness
}

enum BattleStats{
	HEALTH,			# HP, ability to take damage (like a large jelly)
	SPIRIT,			# Special Health
	ATTACK,			# Ability to do damage
	DEFENSE,		# Ability to resist damage (like a dense jelly)
	SPEED,			# Priority + Velocity
	EVASION,		# Reaction time + difficulty being aimed at
	INTIMIDATION,	# Special Attack
	RESOLVE,		# Special Defense
	MANA,			# PP
}	

# Might be implemented as integer that gets bitshifted and modulo'd
enum BooleanFlags{
	IS_EGG,
	IS_BAD_EGG,
	CAN_ACCESS_DREAMS,
	USE_NICKNAME,
	DISABLE_TRADING,
	
}

# Might be implemented as integer that gets bitshifted and modulo'd
# Sex can change, but not frequently, and not naturally for humans. And yet, you can.
# There are generally 2 gametes in nature, so 2 here, although defining them is rough so...
# ...blorboic and scrungly it is.
# Two integers to track estrogenemia and androgenemia may influence this field
enum SexBitfield{
	IS_SPERMATOGENIC 	= 0b00000_1,	# Produces small/mobile/scrungly cells
	IS_OOGENIC 			= 0b0000_10,	# Produces large/immobile/blorboic cells
	CAN_DEPOSIT_GAMETES = 0b000_100,	# Has a depositor.
	CAN_RECIEVE_GAMETES = 0b00_1000,	# Stores.
	CAN_GESTATE_GAMETES = 0b0_10000,	# can make Egg
}

# This is far from finished, and may be culturally sensitive
enum GenderBitfield{
	PRONOUN_MASC,			# uses/accepts masculine pronouns, he/him
	PRONOUN_FEM,			# uses/accepts feminine pronouns, she/her
	PRONOUN_MAV,			# uses/accepts maverique pronouns, ve/ver
	PRONOUN_NEUT,			# uses/accepts neuter pronouns, it/its
	
	IDENTIFY_MASC,
	IDENTIFY_FEM,
	IDENTIFY_MAV,
	IDENTIFY_NEUT,
	
	ASSOCIATE_MASC,
	ASSOCIATE_FEM,
	ASSOCIATE_MAV,
	ASSOCIATE_NEUT,
}


# ALL THESE WORLDS ARE OURS EXCEPT XXXXXX.
enum LostSoulHints{
	FAMILIAR,		# Represents creature from this game, but is corrupted or unimplemented
	POCKET,			# From a world where electric mice run rampent
	DENJU,			# From a world where the Metaverse can be walked into via phone towers
	DIGI,			# From a world where very round cats can become very curvy vakyries
	CORO,	
	NEXO,
	FREESTENDHAL,	# From Freestendhal
	LUXA,			# From Luxamon
	TUXE,			# From Tuxemon
	DAWNBRINGER,	# From Dawnbringer
	GUARDIAN,		# From Guardian Monsters
	LOYALTYLIES,	# From Loyalty Lies
}

# Used to track when/where this monster was created. Lost Souls may have values that do not correspond.
enum GameOfOrigin{
	SUNNY,
	SHADY,
	ZENITH,
	SKY,
	GROUND,
	SEA,
	WALKER,
	SMOKE,
	FOG,
	SPARK,
	SNAP,
}

#endregion Enums

# Called when the node enters the scene tree for the first time.
func _ready():
	umid_buffer.resize( UMID_BUFFER_MAX )
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if umid_buffer.size() < UMID_BUFFER_MIN:
		fill_umid_buffer.call_deferred()
	elif umid_buffer.size() > UMID_BUFFER_MAX:
		umid_buffer.slice(umid_buffer.size() - UMID_BUFFER_MIN)


func get_fresh_umid() -> int:
	var umid = _get_fresh_umid()
	while GlobalDatabase.exists_monster_umid( umid ):
		umid = _get_fresh_umid()
	return umid

## Should check the database to ensure there are no duplicate values.
func _get_fresh_umid() -> int:
	if umid_buffer.size() <= 0:
		return generate_umid()
	
	var export = umid_buffer.pop_front()
	
	if umid_buffer.size() < UMID_BUFFER_MIN:
		fill_umid_buffer.call_deferred()
	
	return export


func fill_umid_buffer():
	umid_buffer.resize( UMID_BUFFER_MAX )
	
	while umid_buffer.size() < UMID_BUFFER_MAX:
		umid_buffer.append( generate_umid() )
		#umid_buffer_index = (umid_buffer_index + 1) % UMID_BUFFER_MAX	# incr. index, wraparound
		#umid_buffer_size = min( umid_buffer_size+1, UMID_BUFFER_MAX )	# incr. size, limit
	pass


## TODO: incorporate the location a monster is found in into the UMID, so long as complexity is not lost.
## Universal/Unique Monster Identification (Document)
func generate_umid() -> int:
	
	## UMID: pronounced like "ju-em ai-dii" / "You am, I Dee"
	## umid: pronounced like UMID or like "humid" but with no 'h'. Same exact meaning.
	## No IPA here because it messes up the character spacing in the Godot editor
	
	## using Twitter, Discord, and Sony as a basis...
	## ...knowing that Discord and Sony used Twitter as a basis...
	## We start with the sign bit, and the time.
	## We'll approximate Sony's way for this part, tracking more time but with less precision.
	
	## Assume a 64 bit integer
	var export_umid:= 0;
	
	var unix_time = Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system())
	unix_time = unix_time * 1000
	var milliseconds = Time.get_ticks_msec() % 1000
	@warning_ignore("integer_division")
	unix_time = int(unix_time + milliseconds) / 10 
	
	export_umid = unix_time << (64-40) ## bits in an integer - (1 + timestamp length)
	
	## We now have 24 bits to play with.
	## Let's implement the machine ID next.
	## I absolutely wrote this before, what?
	var machine_id = OS.get_unique_id().md5_buffer().decode_u64(0)
	export_umid = export_umid | ( machine_id >> 40 )
	
	## Now the entire ID is a timestamp and a computer ID.
	## It did obfuscate the timestamp and computer ID together before, but now it doesn't.
	## Less secure for the wary, but more secure for the gamers because less chance of collisions
	
	## Finally, the incrementor, which allows for more monsters generated per 10 ms.
	## ...per centisecond? It might also slow down the system slightly, making itself useless...
	## ...if it weren't for those RGB 65k CUP core 10M hz computer (doubles as oven)
	## Although... there can still be overflow if over 2048 UMIDs are generated in one centisec.
	## Which would require a generation rate of over 200,000 per second
	
	umid_counter = (umid_counter + 1) % 0b1000_0000_0000
	export_umid = export_umid + umid_counter
	
	## practically impossible to achieve. You need some real TAS to get this.
	## maybe if the game runs for many years, and overlaps with the incrementor?
	if export_umid < 0:
		export_umid = 0 - export_umid	
	
	if export_umid < 512:
		print( str(export_umid, " is not a valid ID, recalculating...") )
		return generate_umid()
	
	## if UMID does not yet exist, return that it can be used
	## if UMID does exist, keep poking around at new values until an unused UMID is found
	## spare IDs may be stored to avoid loading times when new monsters are generated
	export_umid = GlobalDatabase.validate_umid( export_umid )
	
	return export_umid


func color_expression_from_genes(gene1:ColorGene, gene2:ColorGene) -> ColorExpression:
	match (gene1):
		ColorGene.WHITE:
			match (gene2):
				ColorGene.WHITE:
					return ColorExpression.WHITE
				ColorGene.BLACK:
					return ColorExpression.COMMON
				#ColorGene.SHINY:
					#return ColorExpression.PALE
				_: #ColorGene.COMMON:
					return ColorExpression.PALE
		ColorGene.BLACK:
			match (gene2):
				ColorGene.WHITE:
					return ColorExpression.COMMON
				ColorGene.BLACK:
					return ColorExpression.BLACK
				#ColorGene.SHINY:
					#return ColorExpression.DARK
				_: #ColorGene.COMMON:
					return ColorExpression.DARK
		ColorGene.SHINY:
			match (gene2):
				ColorGene.WHITE:
					return ColorExpression.PALE
				ColorGene.BLACK:
					return ColorExpression.DARK
				ColorGene.SHINY:
					return ColorExpression.SHINY
				_: #ColorGene.COMMON:
					return ColorExpression.COMMON
		_: #ColorGene.COMMON:
			match (gene2):
				ColorGene.WHITE:
					return ColorExpression.PALE
				ColorGene.BLACK:
					return ColorExpression.DARK
				#ColorGene.SHINY:
					#pass
				_: #ColorGene.COMMON:
					return ColorExpression.COMMON
