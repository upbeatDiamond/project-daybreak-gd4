extends Sprite2D
class_name MapNodule

var outlinks : Array[MapNodule]
var outlink_lines : Array[Line2D]
var map_index : int
var map_file_id := -1

var last_known_position := self.position

signal map_icon_shifted( map_icon:MapNodule )
signal map_icon_added( map_icon:MapNodule )
signal map_icon_removed( map_icon:MapNodule )



func _init( index:int, file_id:int ):
	map_file_id = file_id
	map_index = index
	pass



# Called when the node enters the scene tree for the first time.
func _ready():
	map_icon_shifted.connect( update_outlinks )
	map_icon_added.connect( establish_outlink )
	map_icon_removed.connect( remove_outlink )
	
	map_icon_added.emit( self )
	
	pass # Replace with function body.



func _process(_delta):
	
	if last_known_position != self.position:
		last_known_position = self.position
		map_icon_shifted.emit( self )
	
	pass



func establish_outlink( map_icon:MapNodule ):
	
	if map_icon == self || map_icon == null:
		return
	
	if !outlinks.has(map_icon):
		outlinks.append(map_icon)
	
	var outlink_index = outlinks.find( map_icon )
	outlink_lines.resize( outlinks.size() )
	outlink_lines[ outlink_index ] = Line2D.new()
	outlink_lines[ outlink_index ].end_cap_mode = Line2D.LineCapMode.LINE_CAP_ROUND
	outlink_lines[ outlink_index ].begin_cap_mode = Line2D.LineCapMode.LINE_CAP_BOX
	
	outlink_lines[ outlink_index ].set_curve( Curve.new() )
	outlink_lines[ outlink_index ].add_point( position )
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
	if map_icon == self || map_icon == null:
		
		var i := 0
		while i < outlinks.size():
			
			if outlink_lines[ i ] != null:
				outlink_lines[ i ].set_point_position( 0, self.position )
			
			i += 1
			pass
		
	elif outlinks.has(map_icon):
		
		var outlink_index = outlinks.find( map_icon )
		
		outlink_lines[ outlink_index ] = Line2D.new()
	
		outlink_lines[ outlink_index ].set_curve( Curve.new() )
		outlink_lines[ outlink_index ].add_point( position )
		if map_icon.is_inside_tree():
			outlink_lines[ outlink_index ].add_point( map_icon.position )
		
	pass

#- Array of outlinks
#    - Links have unique ID (to display) and map index (for linking)
#- Array of Raycasts programmatically generated for outlinks
#- Position stored in the editor
