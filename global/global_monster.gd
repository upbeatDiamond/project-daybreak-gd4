extends Node
# Most of this stuff oughta be static methods.

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


const max_battle_moves = 4

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
enum Sex
{
	IS_SPERMATOGEN,			# Kids, ask your biology teacher about this. And maybe etymology...
	IS_OOGEN,
	CAN_DEPOSIT_GAMETES,	# orthagonality check: if not a x-gen, it has a depositor.
	CAN_RECIEVE_GAMETES,	# orthagonality check: if not x-gen but can recieve & deposit, then stores.
	# Gene byte has been removed
}


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
	ZENITH
}
	
