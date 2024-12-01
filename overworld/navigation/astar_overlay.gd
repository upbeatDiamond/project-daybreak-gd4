extends Area2D

@onready var overlay : CollisionShape2D = self.find_child("OverlayCollider", true);
var a_grid : AStarGrid2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _reconfig_grid():
	var _tile_size = GlobalRuntime.DEFAULT_TILE_SIZE
	var _cell_size := Vector2(_tile_size, _tile_size)
	var _region := Rect2i(0,0,0,0)
	
	# NOTE: This code assumes rectangular bounding boxes now
	if overlay.shape is RectangleShape2D:
		_region.position = overlay.position
		_region.size = overlay.shape.size / _tile_size
	
	
	a_grid = AStarGrid2D.new()
	a_grid.region = _region
	a_grid.cell_size = _cell_size
	a_grid.update()
	
	
	pass

func _bake():
	
	var colliders : Array
	await get_tree().physics_frame # Await physics step, for collider register
	colliders.append_array( self.get_overlapping_areas() )
	colliders.append_array( self.get_overlapping_bodies() )
	
	for collider in colliders:
		# Block out regions using void fill_solid_region(region: Rect2i, solid: bool = true) 
		if collider is TileMap:
			pass
		elif collider is CollisionObject2D:
			(collider as CollisionObject2D).col
		# Keep in mind, the size might be referring to the cell count, not absolute size
	
	pass
