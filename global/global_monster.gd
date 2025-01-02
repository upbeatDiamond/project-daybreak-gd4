extends Node
# Most of this stuff oughta be static methods.

const MAX_BATTLE_TECHNIQUES = 4

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
