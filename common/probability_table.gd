###############################################################################
## Adapted from the Alias Method as implemented using Vose's algorithm 
## by Keith Schwarz (htiek@cs.stanford.edu)
##
## Please see the article "Darts, Dice, and Coins: Sampling from a Discrete 
## Distribution" at http://www.keithschwarz.com/darts-dice-coins/
##

extends Object
class_name ProbabilityTable

var options_table : Array[ProbabilityTableSlot] = []
var probability_table : Array[float] = []
var alias_table : Array[float] = []
var random : RandomNumberGenerator
## Row = tuple of species, weight, and conditions


func _init(random:RandomNumberGenerator):
	self.random = random


func add_row(value:int, weight:float):
	
	options_table.append( ProbabilityTableSlot.new(value, weight) )
	pass


func _update_tables():
	## Begin by doing basic structural checks on the inputs. */
	if (options_table.size() <= 0):
		options_table.append(null)

	## Allocate space for the probability and alias tables. */
	probability_table = []; probability_table.resize(options_table.size())
	alias_table = []; alias_table.resize(options_table.size())
	
	##Make a copy of the probabilities list, since we will be making
	##changes to it.
	var probabilities = []; probabilities.resize(options_table.size())
	for i in range(options_table.size()):
		probabilities[i] = options_table[i].weight
	
	## Compute the average probability and cache it for later use. */
	var average = _rescale_weights(probabilities)
	
	## Create two stacks to act as worklists as we populate the tables. */
	var small : Array[int] = []
	var large : Array[int] = []

	## Populate the stacks with the input probabilities. */
	for i in range(0, probabilities.size(), +1):
		## If the probability is below the average probability, then we add
		## it to the small list; otherwise we add it to the large list.
		if (probabilities.get(i) >= average):
			large.append(i);
		else:
			small.append(i);
##/* As a note: in the mathematical specification of the algorithm, we
##		 * will always exhaust the small list before the big list.  However,
##		 * due to floating point inaccuracies, this is not necessarily true.
##		 * Consequently, this inner loop (which tries to pair small and large
##		 * elements) will have to check that both lists aren't empty.
##		 */
	while (!small.is_empty() and !large.is_empty()):
		##/* Get the index of the small and the large probabilities. */
		var less : int = small.pop_back()
		var more : int = large.pop_back()

		##/* These probabilities have not yet been scaled up to be such that
		## * 1/n is given weight 1.0.  We do this here instead.
		## */
		probability_table[less] = probabilities.get(less) * probabilities.size();
		alias_table[less] = more;

		##/* Decrease the probability of the larger one by the appropriate
		## * amount.
		## */
		probabilities.set(more, (probabilities.get(more) + probabilities.get(less)) - average);

		##/* If the new probability is less than the average, add it into the
		## * small list; otherwise add it to the large list.
		## */
		if (probabilities.get(more) >= 1.0 / probabilities.size()):
			large.append(more);
		else:
			small.append(more);

	##/* At this point, everything is in one list, which means that the
	## * remaining probabilities should all be 1/n.  Based on this, set them
	## * appropriately.  Due to numerical issues, we can't be sure which
	## * stack will hold the entries, so we empty both.
	while (!small.is_empty()):
		probability_table[small.back()] = 1.0;
	while (!large.is_empty()):
		probability_table[large.back()] = 1.0;


func next() -> int:
	return options_table[_next()].value


## * Samples a value from the underlying distribution.
## *
## * @return A random value sampled from the underlying distribution.
func _next() -> int:
	## Generate a fair die roll to determine which column to inspect.
	var column : int = random.randi_range(0, probability_table.size())

	## Generate a biased coin toss to determine which option to pick.
	var coin_toss : bool = random.randf() < probability_table[column]

	## Based on the outcome, return either the column or its alias.
	return column if coin_toss else alias_table[column]


func remove_row(value:int):
	var options_table2 = options_table.duplicate()
	for option in options_table:
		if option.value == value:
			var index = options_table2.find(option)
			if index >= 0:
				options_table2.remove_at(index)
	options_table = options_table2


func get_rows():
	return options_table.duplicate(true)


func _rescale_weights(weights:Array[float]) -> float:
	
	var sum := 0.0
	for weight in weights:
		sum += weight
	var average = sum / weights.size()
	
	#for i in range(weights.size()):
		#weights[i] = weights[i] / average
	## It is assumed that the array contents are stored by the caller.
	
	return average


class ProbabilityTableSlot:
	
	var value:int
	var weight:float
	
	func _init(value:int, weight:=1.0) -> void:
		self.value = value
		self.weight = weight
