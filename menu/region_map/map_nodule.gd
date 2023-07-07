#@tool
extends Sprite2D
class_name MapNodule


@export var outlinks : Array[MapNodule]
@export var outlink_lines : Array[Line2D]
@export var map_index := -1
@export var map_file_id := -1

@export var outlink_insert : MapNodule
@export var lever_insert : bool = false

var last_known_position := self.position

signal map_icon_shifted( map_icon:MapNodule )
signal map_icon_added( map_icon:MapNodule )
signal map_icon_removed( map_icon:MapNodule )



func _init( index:int=-1, file_id:int=-1 ):
	map_file_id = file_id
	map_index = index
	pass



# Called when the node enters the scene tree for the first time.
func _ready():
	map_icon_shifted.connect( Callable(self, "update_outlinks") )
	map_icon_added.connect( Callable(self, "establish_outlink") )
	map_icon_removed.connect( Callable(self, "remove_outlink") )
	
	map_icon_added.emit( self )
	
	print(map_file_id, ";", map_index, " Ready!")
	
	pass



func _process(_delta):
	
	if last_known_position != self.position:
		last_known_position = self.position
		map_icon_shifted.emit( self )
		print("Movin'!")
	
	if lever_insert:
		print(outlink_insert, " insertion upcoming...")
		if outlink_insert != null:
			print("Outlink insertion!")
			establish_outlink( outlink_insert )
			outlink_insert = null
		lever_insert = false
	
	for line in outlink_lines:
		if line != null:
			if !line.is_visible_in_tree():
				line.reparent(self)
				line.visible = true
	
	pass



func establish_outlink( map_icon:MapNodule ):
	
	print(outlink_insert, " will be established")
	
	if map_icon == self || map_icon == null:
		return
	
	if outlinks.has(map_icon):
		update_outlinks(map_icon)
		return
	
	outlinks.append(map_icon)
	
	var outlink_index = outlinks.find( map_icon )
	outlink_lines.resize( outlinks.size() )
	outlink_lines[ outlink_index ] = Line2D.new()
	outlink_lines[ outlink_index ].end_cap_mode = Line2D.LineCapMode.LINE_CAP_ROUND
	outlink_lines[ outlink_index ].begin_cap_mode = Line2D.LineCapMode.LINE_CAP_BOX
	
	outlink_lines[ outlink_index ].texture = load("res://assets/textures/gui/map/landmark_icon.png")
	outlink_lines[ outlink_index ].texture_mode = Line2D.LINE_TEXTURE_TILE
	
	outlink_lines[ outlink_index ].set_curve( Curve.new() )
	outlink_lines[ outlink_index ].add_point( self.position )
	
	add_child( outlink_lines[ outlink_index ] )
	print("Added child ", outlink_lines[ outlink_index ], " at position ", outlink_lines[ outlink_index ].position , "!" )
	
	if map_icon.is_inside_tree():
		outlink_lines[ outlink_index ].add_point( map_icon.position )
	
	pass


func remove_outlink( map_icon:MapNodule ):
	
	if map_icon == self || map_icon == null:
		return
	
	if outlinks.has(map_icon):
		var outlink_index = outlinks.find( map_icon )
		outlink_lines.remove_at( outlink_index )
		outlinks.remove_at( outlink_index )
	pass



func update_outlinks( map_icon:MapNodule ):
	
	var outlink_index = outlinks.find( map_icon )
	
	if map_icon == self || map_icon == null:
		
		var i := 0
		if outlinks.size() > outlink_lines.size():
			outlink_lines.resize( outlinks.size() )
		
		while i < outlinks.size():
			
			if outlink_lines[ i ] != null:
				outlink_lines[ i ].set_point_position( 0, self.position )
			else:
				establish_outlink( outlinks[i] )
			
			i += 1
		
		return
		
	elif outlinks.has(map_icon):
		
		outlink_lines[ outlink_index ].points[1] = map_icon.position
		
	else:
		outlink_lines[ outlink_index ].points.clear()
	
	#outlink_lines[ outlink_index ].set_curve( Curve.new() )
	#outlink_lines[ outlink_index ].add_point( position )
	#if map_icon.is_inside_tree():
	#	outlink_lines[ outlink_index ].add_point( map_icon.position )
	#	add_child( outlink_lines[ outlink_index ] )
	
	pass
