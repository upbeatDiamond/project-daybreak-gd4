extends Node
class_name Technique

var flag_bitfield

var base_power
var moveeffect_accuracy
var moveeffect
	# The overall accuracy. If this misses, no effects are used.

var priority_tier := 0

var type_one # This type is always in play for primary effect
var type_two # This type might be in play anywhere
var moveeffect_mods := {}

var priority
var energy_cost
var accuracy

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _init( _base_power:int, _accuracy, primary_effect:TechniqueEffect, _flag_bitfield:int, \
effect_accuracy, type1, type2, _priority_tier:=0, cost:=0.0):
	self.base_power = _base_power
	self.accuracy = _accuracy
	self.flag_bitfield = _flag_bitfield
	self.moveeffect = primary_effect
	self.moveeffect_accuracy = effect_accuracy
	self.priority_tier = _priority_tier
	self.type_one = type1
	self.type_two = type2
	self.energy_cost = cost


# Only uses functions to expose fields. 
# The Move's functionality is split between its Global and its Effects
# Stores name, types, effects, and flags
func calculate_effect( _user:Combatant, _targets:Array[Combatant], _traits:Dictionary ):
	pass
