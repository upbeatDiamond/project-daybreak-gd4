extends GPUParticles2D

# setget should influence size of image and radius of scattering
@export var cell_size := 16

@export var particle_count := 16

# setget should influence radius and shifting of scattering
@export var flame_bounds := Vector2(1,1) 

func _ready():
	set_flame_dimensions( flame_bounds )

func set_flame_dimensions( dimensions: Vector2 ):
	process_material.emission_box_extents = Vector3( cell_size*dimensions.x, cell_size*dimensions.y, 1 )
