# represents creatures in a Battle
extends Node
class_name Combatant

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
	CHARGING, 		# How to tell which move is charging? ...
					# ... Easy, you can't choose a new move while charging.
}


enum BytefieldStatusCondition
{
	SCORCH,
	FROSTBITE,
	POISONED,
	DROWSY,
	DIZZY,
	CURSED,
	ON_LOOP,		# A performance was demanded of them, now they must deliver.
	LIMELIGHT,			# Detection, identitification, and spotlight
	STICKY,
	FLINCH,
	OBSCURED,
	SHIELD_MAGIC,		# Protects from spells
	SHIELD_PHYSICAL,	# Protects HP, sometimes
	SHIELD_FS,			# Protects FS, quite often
	SEMIINVULNERABLE,	
}

var controller:BattleController
var speed:=10
var moves:Array[BattleMove]
var team:BattleTeam
var nickname:String
var monster:Monster

var front_sprite_path : String = "res://assets/textures/monsters/zoonami_grimlit_front.png"
var back_sprite_path : String = "res://assets/textures/monsters/zoonami_grimlit_back.png"

# TODO RANGE /// replace with function to reduce data duplication with Monster
#var hp : int = 30
#var maxhp : int = 30
#var fs : int = 30
#var maxfs : int = 30
# END TODO RANGE \\\ replace with function to reduce data duplication with Monster

## Psych Up regenerates HP or FS partially upon one or the other reaching 0.
## False = is spent (or never could), while true is expected for fresh threats.
var can_psych_up = false


signal hp_changed(hp, prior_hp)
signal fs_changed(fs, prior_fs)
signal status_changed(statuses_apply, statuses_remove)


func _init(_controller:BattleController, _team:BattleTeam, _index:int, _nname:String):
	controller = _controller
	if (controller == null):
		controller = BattleController.new();
	team = _team;
	nickname = _nname;
	monster = Monster.new()
	monster.species = _index
	_set_sprites_to_monster()
	#monster = _monster #_monster:Monster, 
	
	# If the team is invalid, the combatant cannot be effectively used.
	# Make the combatant after the team is created.
	assert(team != null)
	pass


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# returns effective speed: the modifiers upon the monster's speed stat
func get_speed():
	return monster.speed


# returns effective attack: the modifiers upon the monster's attack stat
func get_attack():
	return monster.attack


# returns effective charisma: the modifiers upon the monster's charisma stat
func get_charisma():
	return monster.charisma


func get_hp():
	return monster.get_health()


func get_max_hp():
	return monster.get_max_health()


func set_hp(health) -> int:
	var old_hp = get_hp()
	hp_changed.emit(health, old_hp)
	return monster.set_health(health)


func set_max_hp(maximum:int):
	return monster.set_max_health(maximum)


func get_fs():
	return monster.get_spirit()


func get_max_fs():
	return monster.get_max_spirit()


func set_fs(fs):
	var old_fs = get_fs()
	fs_changed.emit(fs, old_fs)
	return monster.set_spirit(fs)


func set_max_fs(maximum:int):
	return monster.set_max_spirit(maximum)# monster.max_spirit


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func poll_action() -> BattleAction:
	
	var battle_action_option : Array[BattleAction] = []
	
	for move in moves:
		battle_action_option.append(BattleAction.new( BattleAction.ActionType.MOVE, self, move ))
	
	return team.get_leader().decide( self, battle_action_option )


func run_turn() -> BattleAction:
	#The code sometimes breaks if I don't have an await
	@warning_ignore("redundant_await") 
	return await controller.run_turn(self)


func get_front_sprite() -> Texture2D:
	return load(front_sprite_path)


func get_back_sprite() -> Texture2D:
	return load(back_sprite_path)


func apply_health_change(change:float):
	var old_hp = get_hp()
	var hp = set_hp( old_hp + change )
	hp_changed.emit(hp, old_hp)


## TODO: replace with calls to PatchData for sprite addresses, via GlobalDatabase
func _set_sprites_to_monster():
	match monster.species:
		1:
			front_sprite_path = "res://assets/textures/monsters/zoonami_kackaburr_front.png"
			back_sprite_path = "res://assets/textures/monsters/zoonami_kackaburr_back.png"
		4:
			front_sprite_path = "res://assets/textures/monsters/zoonami_ruffalo_front.png"
			back_sprite_path = "res://assets/textures/monsters/zoonami_ruffalo_back.png"
		7:
			front_sprite_path = "res://assets/textures/monsters/zoonami_maluga_front.png"
			back_sprite_path = "res://assets/textures/monsters/zoonami_maluga_back.png"
		229:
			front_sprite_path = "res://assets/textures/monsters/zoonami_grimlit_front.png"
			back_sprite_path = "res://assets/textures/monsters/zoonami_grimlit_back.png"
	
	pass



func _to_string() -> String:
	return nickname
