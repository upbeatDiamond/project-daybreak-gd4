extends Node#2D

#class_name TurnQueue

var combatants : Array
var combatant_index := 0
var active_combatant

func initialize():
	active_combatant = combatants[ combatant_index ]

# 1 turn = 1 combatant or 1 tight cluster of combatants
func play_turn():
	#yield(active_character.play_turn(), "completed")
	await active_combatant.play_turn()
	
	pass

# 1 round = all combatants get 1 turn
func prepare_next_round():
	
	# Need to implement "compare_priority"
	combatants.sort_custom( Callable(active_combatant, "compare_priority") )
	pass

func update_combatants_from_children():
	combatants = get_children()
