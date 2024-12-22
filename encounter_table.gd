extends Node

var species_table : ProbabilityTable
var color_table : ProbabilityTable
var species_table_meta : Dictionary = {}

func _init() -> void:
	color_table = ProbabilityTable.new(GlobalRuntime.server_random)
	species_table = ProbabilityTable.new(GlobalRuntime.server_random)


func add_species(species:int, weight:float, avg_level:float, sd_level:float):
	species_table.add_row(species, weight)
	species_table_meta[species] = {"avg_level" = avg_level, "sd_level" = sd_level}
	pass


func add_color(gene:int, weight:float):
	pass


func next_monster():
	var rng = GlobalRuntime.server_random
	
	var species = species_table.next()
	var avg_level = species_table_meta[species]["avg_level"]
	var sd_level = species_table_meta[species]["sd_level"]
	
	## Calculate level as a float, clamp to an integer no more than 2 standard
	## deviations off, to avoid absurdly difficult monsters at random.
	var level = rng.randfn(avg_level, sd_level)
	level = floori( clamp(level, avg_level - 2*sd_level, avg_level + 2*sd_level ) )
	
	## Generate the two color genes
	var color1 = color_table.next()
	var color2 = color_table.next()
