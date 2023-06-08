class_name Combatant
extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

var monster : Monster # The entity used for read/write on stats and abilities
# Monster is carried around as a neat container, and to allow for 1 pointer to be passed
# from global to global to class while still editing the same monster (I hope)
var active = false: set = set_active

signal turn_finished


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
	if a.monster.get_stat(GlobalMonster.BattleStats.SPEED) > b.key.monster.get_stat(GlobalMonster.BattleStats.SPEED):
		return true
	if a.monster.get_health() < b.monster.get_health():
		return true
	return false

