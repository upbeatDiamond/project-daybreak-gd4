extends Node
# Most of this stuff oughta be static methods.

const MAX_BATTLE_TECHNIQUES = 4

enum PersonalityFactor
{
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
	TENSION			# Low = patient,	High = frustrated
}


enum RelationshipFactors
{
	AFFECTION,	# Influenced by pF Warmth, Sensitivity, Abstractness
	TRUST,   	# Influenced by pF Vigilance, Privacy, Apprehension
	RESPECT,	# Influenced by pF Stability, Abstractness, Perfectionism
	INTIMACY,	# Influenced by pF Experimental, Sensitivity, Boldness
	OBSESSION,	# Influenced by pF Individualism, Boldness, Dominance
	PLAYFULNESS	# Influenced by pF Warmth, Liveliness, Boldness
}

enum BattleStats
{
	HEALTH,			# HP, ability to take damage (like a large jelly)
	SPIRIT,			# Special Health
	ATTACK,			# Ability to do damage
	DEFENSE,		# Ability to resist damage (like a dense jelly)
	SPEED,			# Priority + Velocity
	EVASION,		# Reaction time + difficulty being aimed at
	INTIMIDATION,	# Special Attack
	RESOLVE,		# Special Defense
	MANA			# PP
}	

# Might be implemented as integer that gets bitshifted and modulo'd
enum BooleanFlags
{
	IS_EGG,
	IS_LOST_SOUL
	
}

# Might be implemented as integer that gets bitshifted and modulo'd
# Sex can change, but not frequently, and not naturally for humans. And yet, you can.
# There are generally 2 gametes in nature, so 2 here, although defining them is rough so...
# ...blorboic and scrungly it is.
# Two integers to track estrogenemia and androgenemia may influence this field
enum SexBitfield
{
	IS_SPERMATOGENIC,		# Produces small/mobile/scrungly cells
	IS_OOGENIC,				# Produces large/immobile/blorboic cells
	CAN_DEPOSIT_GAMETES,	# orthagonality check: if not a x-gen, it has a depositor.
	CAN_RECIEVE_GAMETES,	# orthagonality check: if not x-gen but can recieve & deposit, then stores.
	CAN_GESTATE_GAMETES,	# can make Egg
	PRODUCES_MILK,			# yeah
	
	# Gene byte has been removed
}

# This is far from finished, and may be culturally sensitive
enum GenderBitfield
{
	PRONOUN_MASC,			# uses/accepts masculine pronouns
	PRONOUN_FEM,			# uses/accepts feminine pronouns
	PRONOUN_MAV,			# uses/accepts maverique pronouns
	PRONOUN_INAN,			# uses/accepts inanimate pronouns
	
	IDENTIFY_MASC,
	IDENTIFY_FEM,
	IDENTIFY_MAV,
	IDENTIFY_INAN,
	
	ASSOCIATE_MASC,
	ASSOCIATE_FEM,
	ASSOCIATE_MAV,
	ASSOCIATE_INAN,
}


# ALL THESE WORLDS ARE OURS EXCEPT XXXXXX.
enum LostSoulHints
{
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
enum GameOfOrigin
{
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
	


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
