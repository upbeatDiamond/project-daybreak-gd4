extends Node
# This class is dedicated to the fetching and manipulation of in-game hours, daylight, and dates

# Order is aligned with ISO, rather than American concencus
enum Weekday {
	MONDAY = 0,
	TUESDAY,
	WEDNESDAY,
	THURSDAY,
	FRIDAY,
	SATURDAY,
	SUNDAY,
	MAX ## The maximum value
}

enum Season {
	SPRING = 0,
	SUMMER,
	AUTUMN,
	WINTER,
	MAX
}

## While 24 hours is not necessary, some systems work off that assumption, so...
## ...we need to either commit to defining it here...
## ...or keep it as a constant both in terms of runtime and development.

## Base ratios
const TICKS_PER_REAL_SECOND = 20
const GAME_MINUTE_PER_GAME_HOUR = 60
const TICKS_PER_GAME_HOUR = 24000
const GAME_HOUR_PER_GAME_DAY = 24
const GAME_DAY_PER_GAME_WEEK = 7
const GAME_WEEK_PER_GAME_SEASON = 4
const GAME_SEASON_PER_GAME_YEAR = 0

## Pre-multiplied
const GAME_DAY_PER_GAME_SEASON = GAME_DAY_PER_GAME_WEEK * GAME_WEEK_PER_GAME_SEASON
const GAME_DAY_PER_GAME_YEAR = GAME_DAY_PER_GAME_SEASON * GAME_SEASON_PER_GAME_YEAR
const TICKS_PER_GAME_DAY = GAME_HOUR_PER_GAME_DAY * TICKS_PER_GAME_HOUR
const TICKS_PER_GAME_MINUTE = TICKS_PER_GAME_HOUR / 60

const YEAR_DISPLAY_MAX = 2000	## 2000 --> Millenium Bug
const YEAR_DISPLAY_MIN = 1970	## 1970 --> UNIX Epoch

var current_day := 1 ## 1, for Monday; use modulo to determine week day
var current_year := YEAR_DISPLAY_MIN ## Should be some small positive integer; not shown to player
var current_world_ticks := 0 ## World Ticks always accumulate when the overworld is active
var current_solar_ticks := 0 ## Solar Ticks are for daylight cycle
## If the current weekday >= max, or < 1, then the database should be asked what to do next

## If stale, GlobalClock should fetch the current time from the database before continuing.
var is_stale := true
## 'Cached Time in ms' stores the previous process frame time
## Operations might want to refer to the millisecond counter Godot has for accurate ticking
var cached_time_in_milliseconds := 0

var daylight_cycle_enabled := true
var world_time_enabled := false
var day_progression_enabled := true

var milliseconds_preserved := 0


## Each process, get the number of milliseconds since the last update, and use the booleans to determine whether to increment the daylight and kinetic tick counter.
## Shave off extra ticks from daylight into hours, hours into days, etc.
func _process(_delta: float) -> void:
	## Store the previous cached time
	var old_ms = cached_time_in_milliseconds
	## If we update the time, it allows for ticks to be skipped; else time jumps on unpause
	cached_time_in_milliseconds = Time.get_ticks_msec()
	
	## Guard clause
	if not is_time_paused():
		return
	## Henceforth, time progresses, except maybe for daylight
	
	var ms_delta = cached_time_in_milliseconds - old_ms + milliseconds_preserved
	var tick_delta = (ms_delta * TICKS_PER_REAL_SECOND) / 1000
	milliseconds_preserved = ms_delta - (tick_delta * 1000 / TICKS_PER_REAL_SECOND)
	
	current_world_ticks += tick_delta
	
	# add section for dealing with background npc tasks
	
	## Guard clause
	if not daylight_cycle_enabled:
		return
	## Henceforth, solar time is enabled
	
	current_solar_ticks += tick_delta
	if current_solar_ticks >= TICKS_PER_GAME_DAY:
		if day_progression_enabled:
			current_day += 1
		current_solar_ticks -= TICKS_PER_GAME_DAY
	
	if day_progression_enabled and current_day >= GAME_DAY_PER_GAME_YEAR:
		current_day -= GAME_DAY_PER_GAME_YEAR
		current_year += 1
	
	## Add ms_delta * ticks per second / 1000 to enabled clocks


#region Overworld Time

func pause_overworld_time():
	world_time_enabled = false


func unpause_overworld_time():
	world_time_enabled = true
	cached_time_in_milliseconds = Time.get_ticks_msec()


func reset_time_cache():
	pass


func is_time_paused() -> bool:
	return world_time_enabled and not is_stale and not GlobalState.should_time_progress()
#endregion Overworld Time
#region Solar Time

func pause_solar_time():
	daylight_cycle_enabled = false


func unpause_solar_time():
	daylight_cycle_enabled = true


func is_solar_time_paused() -> bool:
	return daylight_cycle_enabled

#endregion Solar Time
#region Day Progression

func pause_day_progression():
	day_progression_enabled = false


func unpause_day_progression():
	day_progression_enabled = true


func set_day(day:int, year:int=current_year) -> void:
	current_day = day % GAME_DAY_PER_GAME_YEAR
	current_year = year + (day / GAME_DAY_PER_GAME_YEAR)


func set_year(year:int) -> void:
	current_year = year


## For internal systems only, do not show to the unsavvy user
func get_day() -> int:
	return current_day


## For internal systems only, do not show to the unsavvy user
func get_year() -> int:
	return current_year


## For player menus that show or are modified by a year number.
## Year should not be shown to the player character, as that may cause canon conflicts.
func get_year_display() -> int:
	return max(min(YEAR_DISPLAY_MAX, get_year()), YEAR_DISPLAY_MIN)


## For player menus that show a day of the week, and for NPC schedules
func get_weekday() -> int:
	return posmod(current_day, Weekday.MAX)


## For player menus that show the season, and for map changes NPC systems
func get_season():
	return posmod(current_day / GAME_DAY_PER_GAME_SEASON, Season.MAX)


## For player menus that show the equivalent of a day of the month
func get_day_in_season():
	return posmod(current_day, GAME_DAY_PER_GAME_SEASON)


## Hour count within the day
func get_hour() -> int:
	return (current_solar_ticks % TICKS_PER_GAME_DAY) / TICKS_PER_GAME_HOUR


## Minute count within the day, total
func get_day_minutes():
	return current_solar_ticks % TICKS_PER_GAME_DAY * 60 / TICKS_PER_GAME_MINUTE


## Minute count within the hour
func get_hour_minutes():
	return current_solar_ticks % TICKS_PER_GAME_HOUR * 60 / TICKS_PER_GAME_MINUTE

#endregion Overworld Time
#region Saving

func _save_time_to_db():
	GlobalDatabase.save_keyval("GlobalClock::CurrentWorldTicks", current_world_ticks)
	GlobalDatabase.save_keyval("GlobalClock::CurrentSolarTicks", current_solar_ticks)
	GlobalDatabase.save_keyval("GlobalClock::CurrentDay", current_day)
	GlobalDatabase.save_keyval("GlobalClock::CurrentYear", current_year)
	pass


func _load_time_from_db():
	current_world_ticks = GlobalDatabase.load_keyval("GlobalClock::CurrentWorldTicks", current_world_ticks)
	current_solar_ticks = GlobalDatabase.load_keyval("GlobalClock::CurrentSolarTicks", current_solar_ticks)
	current_day = GlobalDatabase.load_keyval("GlobalClock::CurrentDay", current_day)
	current_year = GlobalDatabase.load_keyval("GlobalClock::CurrentYear", current_year)
	pass

#endregion Saving
