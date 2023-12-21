extends Node
# This class is dedicated to the fetching and manipulation of in-game hours, daylight, and dates


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# The order/number is wrong,,, except ISO says it's right.
# Sounds like French propaganda. Organisation internationale de normalisation...
# A day starts at midnight, but you go to sleep at 2am, 
# just like how a week starts on Sunday but you go to work/class on Monday.
enum DayOfWeek
{
	MONDAY = 1,
	TUESDAY,
	WEDNESDAY,
	THURSDAY,
	FRIDAY,
	SATURDAY,
	SUNDAY
}

# While 24 hours is not necessary, some systems work off that assumption, so...
# ...we need to either commit to defining it here...
# ...or keep it as a constant both in terms of runtime and development.
var day_length := 1200.0;
const hours_per_day := 24

var is_active := true		# Is this system being used at all?
var is_date_locked := true	# Used for in-game date checking
var is_hour_locked := true	# Used for clocks and daylight progression

var current_time: float = 0.0
var current_day: int = 1

# Look honey, the one (1) LLM/ML generated function! I heard it needed to get fixed afterwords!
func _process(delta) -> void:
	current_time += delta
	
	if is_active:
		if current_time >= day_length:
			current_time = 0.0
			current_day += 1
		
		if current_day > DayOfWeek.size():
			current_day = DayOfWeek.MONDAY

func get_current_hour():
	return hours_per_day * current_time / day_length


func get_current_day():
	if is_date_locked:
		return locked_day
	return current_day