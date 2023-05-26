extends GPUParticles2D
# Why is this not working quite right?

@export var cell_size := 16 :
	get:
		return cell_size
	set(value):
		cell_size = value
		set_flame_dimensions( flame_bounds )

@export var particle_count := 16 :
	get:
		return particle_count
	set(value):
		particle_count = value
		amount = particle_count


@export var flame_bounds := Vector2(1,1) :
	get:
		return flame_bounds
	set(value):
		flame_bounds = value
		set_flame_dimensions( flame_bounds )

func _ready():
	set_flame_dimensions( flame_bounds )

func set_flame_dimensions( dimensions: Vector2 ):
	process_material.emission_box_extents = Vector3( cell_size*dimensions.x, cell_size*dimensions.y, 1 )
