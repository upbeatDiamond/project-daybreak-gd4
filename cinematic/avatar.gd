extends TextureRect
# Feel free to remove this script if it isn't used anywhere.


@onready var avatar = ( $Avatar as Sprite2D )

# Called when the node enters the scene tree for the first time.
func _ready():
	avatar.texture = texture
	avatar.region_enabled = true
	avatar.set_global_scale( scale )
	avatar.global_position = global_position
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	avatar.set_global_scale( scale )
	avatar.global_position = global_position
	pass
