class_name Combatant
extends Node



var monster : Monster # The entity used for read/write on stats and abilities
# Monster is carried around as a neat container, and to allow for 1 pointer to be passed
# from global to global to class while still editing the same monster (I hope)
var active = false: set = set_active

# Why not use a class? Because running out of unique class names is a concern.
var previous_move = {
	"move" : GlobalMove.default_move,
	"targets" : [],
}
var queued_move = {
	"move" : GlobalMove.default_move,
	"targets" : [],
}

# Hold the various info moves might use.
# A dumb hacky solution to something I'm years from coding.
var combat_data = {
	
}

signal turn_finished

# Bitfield is for boolean. for values that can persist...
# ...indefinately if needed

# Battle Status doesn't persist after battle, but *might* transfer on switch-in.
enum BitfieldStatusBattle
{
	BOUND,		# Also called 'tangled' in the dev notes
	PETRIFIED,
	AIRBORNE,
	GROUNDED,
	UNDERGROUND,
	ROOTED,				# Resist being moved around, enable healing
	MUST_USE_UNIQUE,	# A tormenting fate
	UNIMMUNE, 			# Allows all types to hit this combatant.
}

# Status Effects might persist out of battle, but not Battle Effects.
enum BitfieldStatusCondition
{
	ASLEEP,
}

# Bytefield is for countdowns
# Counts down to effect ending/changing
# 1 effect byte may transfer to a bit.
# Since each effect is special, some bytes get special dedicated code.
enum BytefieldStatusBattle
{
	NIGHTMARE,
	TELEKINESIS, 	# Being lifted by another's accord
	CHARGING, 		# How to tell which move is charging? Easy, you can't choose a new move while charging.
}


enum BytefieldStatusCondition
{
	SCORCH,
	FROSTBITE,
	POISONED,
	DROWSY,
	DIZZY,
	CURSED,
	ON_LOOP,			# A performance was demanded of them, now they must deliver.
	LIMELIGHT,			# Detection, identitification, and spotlight
	STICKY,
	FLINCH,
	OBSCURED,
	SHIELD_MAGIC,		# Protects from spells
	SHIELD_PHYSICAL,	# Protects HP, sometimes
	SHIELD_FS,			# Protects FS, quite often
	SEMIINVULNERABLE,	
}



func _init(monster, _name):
	self.monster = monster
	$HUD/Name.set_text( _name )
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_active(value):
	active = value
	set_process(value)
	set_process_input(value)
	if not active:
		return


# Used to show hurt/heal animation
func apply_damage( damage ):
		monster.reduce_health( damage );


# Used to show de/buff animation
func apply_stat_change( stat_type:GlobalMonster.BattleStats, delta:int ):
		monster.set_stat(stat_type, delta)


func consume(item):
	item.use(self)
	emit_signal("turn_finished")


func flee():
	emit_signal("turn_finished")


# Used in combat_scene, might be used for moves later
# Sorts high to low speed, otherwise compares other stats
func compare_priority( a:Combatant, b:Combatant ):
	if a.queued_move == null || b.queued_move == null || a.queued_move["move"].priority_tier == b.queued_move["move"].priority_tier:
		if a.monster.get_stat(GlobalMonster.BattleStats.SPEED) > b.key.monster.get_stat(GlobalMonster.BattleStats.SPEED):
			return true
		if a.monster.get_health() < b.monster.get_health():
			return true
	else:
		return a.queued_move["move"].priority_tier > b.queued_move["move"].priority_tier 
	return false


func get_priority():
	pass

# Ignores STAB, applies a preprocessed effect
# This is why the categories of end results of a move are "moveeffect" and not "move effect"
func apply_move_effects():
	pass

# Applies STAB, used for move queuing 
func preprocess_move_effects():
	pass

# Applies STAB, used for AI calculations and priority sorting
func anticipate_move_effects():
	pass
