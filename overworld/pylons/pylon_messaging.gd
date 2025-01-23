extends Node

const CONTROL_RANGE = [
		"NUL", "SOM", "SOH", "SOT",
		"EOM", "??1", "ACK", "??3", 
		"DEL", "ESC", "??5", "??6",
		"NAK", "SYN", "SFO", "SFI",
]
const GRAPHIC_RANGE_SHIFT_OUT = [
	" ", "!", '"', "#", "$", "%", "&", "'",
	"(", ")", "*", "+", ",", "-", ":", "/",
	"@", "A", "B", "C", "D", "E", "F", "G",
]
const GRAPHIC_RANGE_SHIFT_IN = []
const GRAPHIC_RANGE_METADATA = []
const GRAPHIC_RANGE_INTERNAL = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
