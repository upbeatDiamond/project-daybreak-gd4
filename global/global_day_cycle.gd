extends Node

# Note to self: Merge with GlobalRuntime?

# Note to other: like with the Matrix code, this code was started with ChatGPT.
# However, what it gave was so pathetic that it barely deserves credit.
# In case anyone is worried about copyright disputes, 
# just say it's too much AI to be original to the dev team, 
# but too modified to belong to OpenAI,
# this by process of elimination (and not by waiver) it has to be public domain.
# No, this is not how lawyering works.
# But it should be.
# That would be much more fun.

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

var day_length := 1000.0;
var is_active = false;

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
	return 24 * current_time / day_length
