extends Node

enum MapIndex
{
	# All references to these indexes should be through this enum in case of value reassignments

	INVALID_INDEX = -1,
	TOWN_RED,
	TOWN_MAUVE,
	TOWN_SCRATCH,
	TOWN_PORT,

	# From this point forward is enums that are extremely likely to change value.

	FAILSAFE_ROOM,

	# From this point on is backwards compatible aliases (As in, please phase these out, but carefully.)
}

var gamepieces_by_map:=[]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func submit_gamepiece( piece:Gamepiece, target_map_index:MapIndex, target_map_coordinates:Vector2i, origin_map_index:=MapIndex.INVALID_INDEX ):
	if gamepieces_by_map.size() < target_map_index:
		gamepieces_by_map.resize( target_map_index + 1 )
	
	
	pass

#func retrieve_gamepiece( gp_id:int ) -> Gamepiece:
#	return null
#	pass

func eject_gamepieces_for_map( target_map_index:int ): #-> Array[Gamepiece]:
	if target_map_index < 0 || target_map_index >= gamepieces_by_map.size():
		return []
	else:
		return gamepieces_by_map[ target_map_index ]
	#pass
