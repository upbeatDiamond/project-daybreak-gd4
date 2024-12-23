extends Node

var entry_selector : ProbabilityTable
var entry_array := []

func _init() -> void:
	#color_table = ProbabilityTable.new(GlobalRuntime.server_random)
	entry_selector = ProbabilityTable.new(GlobalRuntime.server_random)


func add_entry(species:int, weight:float, min_level:float, max_level:float):
	var index = entry_array.size()
	entry_selector.add_row(entry_array.size(), weight)
	entry_array.append( EncounterTableEntry.new(species, min_level, max_level) )
	pass


func _dump_entries():
	pass


func generate_new_monster() -> Monster:
	var rng = GlobalRuntime.server_random
	
	var selection = entry_selector.next()
	var entry = entry_array[selection]
	
	## Calculate level as a float, clamp to an integer
	var level = floori( rng.randf_range(entry.min_level, entry.max_level) )
	
	## Generate the two color genes
	var color1 : int = entry.roll_gene(rng)
	var color2 : int = entry.roll_gene(rng)
	
	var umid : int = GlobalMonsterSpawner.get_fresh_umid()
	var monster = Monster.new()
	monster.umid = umid
	monster.color_gene1 = color1
	monster.color_gene2 = color2
	monster.level = level
	monster.species = entry.species
	
	return monster


class EncounterTableEntry:
	
	var species:int = 0
	var max_level:float = 10.0
	var min_level:float = max_level
	var b_gene_weight:float = 10.0
	var w_gene_weight:float = 10.0
	var c_gene_weight:float = 10.0
	var s_gene_weight:float = 0.01
	
	func _init(_species:int, _min_level:float, _max_level:=_min_level,
			_b_gene_weight:float=b_gene_weight, _w_gene_weight:float=w_gene_weight, 
			_c_gene_weight:float=s_gene_weight, _s_gene_weight:float=s_gene_weight):
		species = _species
		min_level = min(_min_level, _max_level)
		max_level = max(_min_level, _max_level)
	
	
	func roll_gene(rng:RandomNumberGenerator) -> int:
		var bwcs_sum = b_gene_weight + w_gene_weight + c_gene_weight + s_gene_weight
		
		var rng_roll = rng.randf_range(0, bwcs_sum)
		
		## The exact order of these genes is not strictly important
		## However, due to floating point precision, putting shiny last may
		## cause even fewer shiny monsters.
		## Sums are used to simplify the coding/debugging process, not runtime
		## or mathematical efficiency nor showing off.
		if rng_roll <= b_gene_weight:
			return GlobalMonster.ColorGene.BLACK
		elif rng_roll <= (b_gene_weight + w_gene_weight):
			return GlobalMonster.ColorGene.WHITE
		elif rng_roll <= (b_gene_weight + w_gene_weight + c_gene_weight):
			return GlobalMonster.ColorGene.COMMON
		else:
			return GlobalMonster.ColorGene.SHINY
