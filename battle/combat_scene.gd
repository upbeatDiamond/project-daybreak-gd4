extends Node#2D

# Code copied and modded from GDQuest tutorials
# as well as a Godot Engine v3.5 JRPG demo

var combatants : Array
var teams : Array # 2D array
var combatant_index := 0
var active_combatant

# I'll keep the symbol, but change it to represent different teams.
signal combat_finished(winner, loser)

func initialize(combat_combatants):
	for combatant in combat_combatants:
		combatant = combatant.instantiate()
		if combatant is Combatant:
			$Combatants.add_combatant(combatant)
			#combatant.get_node("HUD").connect("dead", Callable(self, "_on_combatant_death").bind(combatant))
		else:
			combatant.queue_free()
	$UI.initialize()
	$TurnQueue.initialize()
#func initialize():
	active_combatant = combatants[ combatant_index ]

func play_round():
	var i := 0;
	while(i < combatants.size()):
		play_turn()
		i = i + 1;

# 1 turn = 1 combatant or 1 tight cluster of combatants
func play_turn():
	#yield(active_character.play_turn(), "completed")
	active_combatant = combatants[ combatant_index ]
	await active_combatant.play_turn()
	combatant_index = (combatant_index + 1) % combatants.size();
	
	pass

# 1 round = all combatants get 1 turn
func prepare_next_round():
	
	for combatant in combatants:
		combatant.select_next_move()
	# Need to have everyone select a new move on this line or above
	# Need to revise "compare_priority" to account for queued moves
	combatants.sort_custom( Callable(active_combatant, "compare_priority") )
	pass

func update_combatants_from_children():
	combatants = get_children()

func clear_combat():
	for n in $Combatants.get_children():
		n.queue_free()



func finish_combat(winner, loser):
	emit_signal("combat_finished", winner, loser)



# Needs a lot of changes
# Needs to check if any team is completely defeated, then finish_combat(...)
func _on_combatant_death(combatant):
	var winner
	if not combatant.name == "Player":
		winner = $Combatants/Player
	else:
		for n in $Combatants.get_children():
			if not n.name == "Player":
				winner = n
				break
	finish_combat(winner, combatant)
