extends Node
# This class is dedicated to the fetching and manipulation of in-game hours, daylight, and dates


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# The order/number is wrong,,, except ISO says it's right.
# Sounds like French propaganda. Organisation internationale de normalisation...
# A day starts at midnight, but you go to sleep at 2am, 
# just like how a week starts on Sunday but you go to work/class on Monday.
enum DayOfWeek {
	MONDAY = 1,
	TUESDAY,
	WEDNESDAY,
	THURSDAY,
	FRIDAY,
	SATURDAY,
	SUNDAY,
	MAX ## The maximum value
}

## While 24 hours is not necessary, some systems work off that assumption, so...
## ...we need to either commit to defining it here...
## ...or keep it as a constant both in terms of runtime and development.

## Breaking down
const TICKS_PER_REAL_SECOND = 20
const GAME_MINUTE_PER_GAME_HOUR = 60

## Building up
const TICKS_PER_GAME_HOUR = 24000
const GAME_HOUR_PER_GAME_DAY = 24
const GAME_DAY_PER_GAME_WEEK = 7
const GAME_WEEK_PER_GAME_SEASON = 4
const GAME_SEASON_PER_GAME_YEAR = 0

var ticks_accumulated := 0
var current_weekday := DayOfWeek.MAX
var current_yearday := 0
var current_year := 0
var current_world_ticks := 0 ## World Ticks always accumulate when the overworld is active
var current_solar_ticks := 0 ## Solar Ticks are for daylight cycle
## If the current weekday >= max, or < 1, then the database should be asked what to do next

## If stale, GlobalClock should fetch the current time from the database before continuing.
var is_stale := true
## Operations might want to refer to the millisecond counter Godot has for accurate ticking
var unstaled_time_in_milliseconds := 0

var daylight_cycle_enabled := true
var world_time_enabled := true

##Each process, get the number of milliseconds since the last update, and use the booleans to determine whether to increment the daylight and kinetic tick counter.
##Shave off extra ticks from daylight into hours, hours into days, etc.


#
#var is_active := true		# Is this system being used at all?
#var is_date_locked := true	# Used for in-game date checking
#var is_hour_locked := true	# Used for clocks and daylight progression
#
#var current_time: float = 0.0
#var locked_time:= current_time
#var current_day: int = 1
#var locked_day:= current_day
#
## Look honey, the one (1) LLM/ML generated function! I heard it needed to get fixed afterwords!
#func _process(delta) -> void:
	#current_time += delta
	#
	#if is_active:
		#if current_time >= day_length:
			#current_time = fmod(current_time, day_length)
			#current_day += int(current_time / day_length)
		#
		## Assumes Monday = 1, and no values are skipped.
		## Therefore, length = value of final element
		#if current_day > DayOfWeek.size():
			#current_day = DayOfWeek.MONDAY
#
#
#func get_current_day():
	#if is_date_locked:
		#return locked_day
	#return current_day
#
#
#func get_current_hour():
	#if is_hour_locked:
		#return hours_per_day * locked_time / day_length
	#return hours_per_day * current_time / day_length
#
#
#func set_current_time( new_time:float ):
	#if is_hour_locked:
		#locked_time = new_time
	#current_time = new_time
	#pass
#
## Assumes a 24 hour system, in that the number of hours is vague
#func set_current_hour( new_time:float ):
	#set_current_time( fposmod( new_time, hours_per_day ) * day_length / hours_per_day )
	#pass
#
#
#func lock_hour():
	#locked_time = current_time
	#is_hour_locked = true
	#pass
#
#
#func lock_day():
	#locked_day = current_day
	#is_date_locked = true
	#pass
#
#
#func unlock_hour():
	#current_time = locked_time
	#is_hour_locked = false
	#pass
#
#
#func unlock_day():
	#current_day = locked_day 
	#is_date_locked = false
	#pass
func _process(_delta: float) -> void:
	

func pause_overworld_time():
	pass

func unpause_overworld_time():
	pass

func pause_solar_time():
	pass

func unpause_solar_time():
	pass

func is_solar_time_paused() -> bool:
	return do_daylight_cycle
