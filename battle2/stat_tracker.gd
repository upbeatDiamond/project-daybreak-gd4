extends Control
class_name BattleStatTracker

const NICKNAME_LENGTH : int = 10

@onready var overlay = find_child("MeterFrame") # technically an "underlay"?
@onready var hp_bar = find_child("HealthBar")
@onready var fs_bar = find_child("SpiritBar")
@onready var hp_rational = find_child("HealthCounter")
@onready var fs_rational = find_child("SpiritCounter")
@onready var name_field = find_child("NameField")
@onready var lvl_field = find_child("LevelField")
#@onready var xp_bar = find_child("XPBar")
var is_ready: bool = false
var combatant : Combatant
var update_duration : float = 0.5

var is_processed:=false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Initializes the initialization.
func _init():
	pass


func _process(_delta:float):
	#if(!is_processed and combatant != null):
		#link_combatant(combatant)
		#print(combatant.name, " is processed (tracker)")
		#is_processed = true
	pass


# Initializes the node.
func link_combatant( link_to: Combatant ):
	combatant = link_to
	combatant.hp_changed.connect(update_health)
	combatant.fs_changed.connect(update_spirit)
	
	_update_hp_range()
	hp_bar.value = clampi(combatant.get_hp(), hp_bar.min_value, hp_bar.max_value);
	_update_hp_rational()
	
	_update_fs_range()
	fs_bar.value = clampi(combatant.get_fs(), fs_bar.min_value, fs_bar.max_value);
	_update_fs_rational()
	
	_update_nickname()
	
	is_ready = true


func update_spirit( fs, fs_old = fs ):
	_update_fs_range()
	fs_bar.value = clampi(fs_old, fs_bar.min_value, fs_bar.max_value);
	if (fs_bar is TextureProgressBar):
		var tween = get_tree().create_tween()
		tween.tween_property(fs_bar, "value", fs, update_duration)
	_update_fs_rational()
	pass


func update_health( hp, hp_old = hp):
	_update_hp_range()
	hp_bar.value = clampi(hp_old, hp_bar.min_value, hp_bar.max_value);
	if (hp_bar is TextureProgressBar):
		var tween = get_tree().create_tween()
		tween.tween_property(hp_bar, "value", hp, update_duration)
	_update_hp_rational()
	pass


func _update_hp_range():
	if (combatant != null and hp_bar != null and hp_bar is TextureProgressBar):
		(hp_bar as TextureProgressBar).max_value = combatant.get_max_hp()
		(hp_bar as TextureProgressBar).min_value = 0


func _update_hp_rational():
	if (hp_rational is Label or hp_rational is RichTextLabel):
		if (combatant != null):
			hp_rational.text = str(combatant.get_hp(), "/", combatant.get_max_hp())
		else:
			hp_rational.text = str(0, "/", 0)


func _update_fs_range():
	if (combatant != null and fs_bar != null and fs_bar is TextureProgressBar):
		(fs_bar as TextureProgressBar).max_value = combatant.get_max_fs()
		(fs_bar as TextureProgressBar).min_value = 0


func _update_fs_rational():
	if (fs_rational is Label or fs_rational is RichTextLabel):
		if (combatant != null):
			fs_rational.text = str(combatant.get_fs(), "/", combatant.get_max_fs())
		else:
			fs_rational.text = str(0, "/", 0)


func update_status( status_condition ):
	
	pass


func _update_nickname():
	if (combatant != null and (name_field is Label or name_field is RichTextLabel)):
		# Change nickname to be up to the character limit in length.
		name_field.text = combatant.nickname.substr(0, min(NICKNAME_LENGTH, combatant.nickname.length()) )
		name_field.text = str( name_field.text, "♀" )
	pass


func _update_level():
	if (combatant != null and (lvl_field is Label or lvl_field is RichTextLabel)):
		# Change nickname to be up to the character limit in length.
		if (combatant.monster == null or combatant.monster.level == INF):
			lvl_field.text = ".."
		elif (combatant.monster.level <= -INF):
			lvl_field.text = "-.."
		else:
			lvl_field.text = combatant.monster.level
		lvl_field.text = str( "⍼", lvl_field.text )
	pass
