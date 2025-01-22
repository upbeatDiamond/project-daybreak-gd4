extends Node


## These two should not be edited from outside the class, I say.
## They should update in sync using the functions the table readily exposes.
var _entry_selector : ProbabilityTable
var _entry_array := []


func _init() -> void:
	_entry_selector = ProbabilityTable.new(GlobalState.server_random)


func add_entry(species:int, weight:float, min_level:float, max_level:float):
	var index = _entry_array.size()
	_entry_selector.add_row(_entry_array.size(), weight)
	_entry_array.append( EncounterTableEntry.new(species, min_level, max_level) )
	pass


func _dump_entries():
	pass


## TODO: have GlobalMonsterSpawner generate gender/sex ratio based on PatchData,
## and all that other jazz, and compile it here.
func generate_new_monster() -> Monster:
	var rng = GlobalState.server_random
	
	var selection = _entry_selector.next()
	var entry : EncounterTableEntry = _entry_array[selection]
	
	## Calculate level as a float, clamp to an integer
	var level = floori( rng.randf_range(entry.min_level, entry.max_level) )
	
	var umid : int = GlobalMonster.get_fresh_umid()
	var monster = Monster.new()
	monster.umid = umid
	monster.color_base_gene1 = entry.roll_color_gene(rng)
	monster.color_base_gene2 = entry.roll_color_gene(rng)
	monster.color_accent_gene1 = entry.roll_color_gene(rng)
	monster.color_accent_gene2 = entry.roll_color_gene(rng)
	monster.level = level
	monster.species = entry.species
	
	return monster


class EncounterTableEntry:
	
	var species:int = 0
	var max_level:float = 10.0
	var min_level:float = max_level
	
	## Color gene weights
	## Keep in mind that bw/wb often use the cc/cs color palette, skewing phenotype odds
	var base_gene_white_weight:float = 10.0
	var base_gene_black_weight:float = 10.0
	var base_gene_common_weight:float = 10.0
	var base_gene_shiny_weight:float = 0.01
	var accent_gene_white_weight:float = 10.0
	var accent_gene_black_weight:float = 10.0
	var accent_gene_common_weight:float = 10.0
	var accent_gene_shiny_weight:float = 0.01
	
	func _init(_species:int, _min_level:float, _max_level:=_min_level, genes:={}):
		species = _species
		min_level = min(_min_level, _max_level)
		max_level = max(_min_level, _max_level)
		
		#region: base gene 
		if genes.has("base_gene_white"):
			base_gene_white_weight = genes["base_gene_white"]
		elif genes.has("base_gene_white_weight"):
			base_gene_white_weight = genes["base_gene_white_weight"]
		
		if genes.has("base_gene_black"):
			base_gene_black_weight = genes["base_gene_black"]
		elif genes.has("base_gene_black_weight"):
			base_gene_black_weight = genes["base_gene_black_weight"]
		
		if genes.has("base_gene_common"):
			base_gene_common_weight = genes["base_gene_common"]
		elif genes.has("base_gene_common_weight"):
			base_gene_common_weight = genes["base_gene_common_weight"]
		
		if genes.has("base_gene_shiny"):
			base_gene_shiny_weight = genes["base_gene_shiny"]
		elif genes.has("base_gene_shiny_weight"):
			base_gene_shiny_weight = genes["base_gene_shiny_weight"]
		
		#endregion: base gene
		
		#region: accent gene 
		if genes.has("accent_gene_white"):
			accent_gene_white_weight = genes["accent_gene_white"]
		elif genes.has("accent_gene_white_weight"):
			accent_gene_white_weight = genes["accent_gene_white_weight"]
		
		if genes.has("accent_gene_black"):
			accent_gene_black_weight = genes["accent_gene_black"]
		elif genes.has("accent_gene_black_weight"):
			accent_gene_black_weight = genes["accent_gene_black_weight"]
		
		if genes.has("accent_gene_common"):
			accent_gene_common_weight = genes["accent_gene_common"]
		elif genes.has("accent_gene_common_weight"):
			accent_gene_common_weight = genes["accent_gene_common_weight"]
		
		if genes.has("accent_gene_shiny"):
			accent_gene_shiny_weight = genes["accent_gene_shiny"]
		elif genes.has("accent_gene_shiny_weight"):
			accent_gene_shiny_weight = genes["accent_gene_shiny_weight"]
		
		#endregion: accent gene
		
	
	
	func roll_base_color_gene(rng:RandomNumberGenerator) -> int:
		var bwcs_sum = base_gene_black_weight + base_gene_white_weight + \
					base_gene_common_weight + base_gene_shiny_weight
		
		var rng_roll = rng.randf_range(0, bwcs_sum)
		
		## The exact order of these genes is not strictly important
		## However, due to floating point precision, putting shiny last may
		## cause even fewer shiny monsters.
		## Sums are used to simplify the coding/debugging process, not runtime
		## or mathematical efficiency nor showing off.
		if rng_roll <= base_gene_black_weight:
			return GlobalMonster.ColorGene.BLACK
		elif rng_roll <= (base_gene_black_weight + base_gene_white_weight):
			return GlobalMonster.ColorGene.WHITE
		elif rng_roll <= (base_gene_black_weight + base_gene_white_weight + base_gene_common_weight):
			return GlobalMonster.ColorGene.COMMON
		else:
			return GlobalMonster.ColorGene.SHINY
