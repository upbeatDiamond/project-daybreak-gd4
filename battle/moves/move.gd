extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _init( base_power, accuracy, primary_effect, flag_bitfield, effects, effect_accuracies, type1, type2, priority, cost):
	self.base_power = base_power
	pass


# Only uses functions to expose fields. The Move's functionality is split between its Global and its Effects
# Stores name, types, effects, and flags

var flag_bitfield

var base_power
var accuracy
var primary_effect
	# The overall accuracy. If this misses, no effects are used.

# 2D array, with 2nd dimension being pairs of Effect and Element.
var effects = []
var effect_accuracies = []
	# These two arrays have to be syncronized. Maybe use a Dict.


var type1 # This type is always in play for primary effect
var type2 # This type might be in play anywhere

var priority
var energy_cost
