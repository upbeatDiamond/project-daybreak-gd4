extends Node
class_name Move

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _init( base_power:int, accuracy, primary_effect:MoveEffect, _flag_bitfield:int, effects:Array, effect_accuracies:Array, type1, type2, priority_tier=0, cost=0):
	self.base_power = base_power
	self.flag_bitfield = _flag_bitfield
	self.primary_moveeffect = primary_effect
	self.primary_moveeffect_accuracy = effect_accuracies.pop_front()
	self.priority_tier = priority_tier
	self.type_one = type1
	self.type_two = type2
	self.energy_cost = cost
	pass

func calculate_effect( user, targets : Array, traits : Dictionary ):
	pass
# Only uses functions to expose fields. The Move's functionality is split between its Global and its Effects
# Stores name, types, effects, and flags

var flag_bitfield

var base_power
var primary_moveeffect_accuracy
var primary_moveeffect
	# The overall accuracy. If this misses, no effects are used.


var priority_tier := 0

# 2D array, with 2nd dimension being pairs of Effect and Element.
var secondary_moveeffects = []


var type_one # This type is always in play for primary effect
var type_two # This type might be in play anywhere

var priority
var energy_cost
