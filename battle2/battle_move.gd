extends Node
class_name BattleMove

var mname:String
var damage:= 3
var energy_cost:= 0

func _init(_mname:String, _damage:=damage, _energy_cost:=energy_cost):
	mname = str(_mname); #str wrapping in case of null
	damage = _damage
	energy_cost = _energy_cost
	pass


## TODO: add connection to Database, to pull from PatchData.
static func new_from_index(index) -> BattleMove:
	if index is String:
		pass
	elif index is int:
		pass
	else:
		push_error("Invalid type for BattleMove.new_from_index(). Must be int or String")
	
	return BattleMove.new("Struggle")


func _to_string() -> String:
	return mname
