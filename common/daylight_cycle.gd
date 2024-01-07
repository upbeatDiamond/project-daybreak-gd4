extends CanvasModulate

# Code written with help from https://www.youtube.com/watch?v=j_FMsL_ru1w
# But not enough for proper credit.
# I mean, enough help that I need to give credit at all, thanks so much,
# but the code is different.
# Thank you bitbrain!!!

# This is not part of the Global script, for multiple reasons. Do not merge.

const DAYLIGHT := Color()
const TWILIGHT := Color()
const NIGHTLIGHT := Color()

var hour_sunrise = 6.0
var hour_sunset = 18.0

var current_temp
var current_brightness

var time = 150.0
var current_hour
var day_length = 24


## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time = time + delta # Change this line to use the new Global !!!!!!!!!!!!!
	
	current_hour = fmod((time / 10), 24 )
	#print("Current hour = %f, time = %f, temp = %f" % [current_hour, time, get_daylight_temp(time) ])
	
	#self.color = 
	self.color = fix_daylight_value( current_hour, kelvin_to_color( get_daylight_temp(current_hour) ) )
	pass


func fix_daylight_value( hour, colour ):
	
	var shift = 12
	var stretch = 3.3
	var e = 2.71828
	
	var min_light = 0.25
	
	var exponent = - (pow((hour - shift)/stretch, 2) ) / 2
	
	colour.v = clamp( min_light + 8 * pow(e,exponent), 0, 1)
	
	return colour


func get_daylight_temp2( hour ) -> float:
	
	var temp_max = 8000
	var temp_min = 1500
	
	var daylight_length = ( hour_sunrise - hour_sunset )
	var moonlight_length = day_length - daylight_length + 0.05 # plus a smidge in case of tiny gap
	var light_length = daylight_length
	
	var is_night = false
	
	if hour > hour_sunset:
		is_night = true
	elif hour < hour_sunrise:
		hour = hour + 24
		is_night = true
	
	if is_night:
		light_length = moonlight_length
		pass
	
	return -( abs(temp_max-temp_min)/2.0 ) * cos((hour - hour_sunrise)*PI/light_length) + (temp_min+temp_max)/2.0


func get_daylight_temp( hour ) -> float:
	
	var is_night = false
	#var is_night_ammended = is_night
	
	var daylight_length = ( hour_sunrise - hour_sunset )
	#var daylight_center = ( hour_sunrise + hour_sunset )/2
	var moonlight_length = day_length - daylight_length + 1 # plus 1 so the curve always applies
	#var moonlight_center = abs( fmod(daylight_center - 12, 24) )
	
	var focalpoint_y = 1000
	#var focalpoint_x = daylight_center
	#var radius = daylight_length + 1
	#var scaling = 450
	
	var relative_hour : int
	
	if hour < hour_sunrise:
		hour = hour + day_length
		is_night = true
	
	if is_night:
		#focalpoint_x = moonlight_center
		relative_hour = hour - hour_sunset
		return focalpoint_y + 4500 * abs(sin(PI*relative_hour/moonlight_length))
	else:
		#focalpoint_x = daylight_center
		relative_hour = hour
		return focalpoint_y + 4500 * abs(sin(PI*relative_hour/daylight_length))
		
	#return focalpoint_y + scaling * abs(sin(PI*relative_hour/relative_length))
	#return focalpoint_y + scaling * sqrt( pow(radius,2) - pow(  min( hour - focalpoint_x, 24 - hour - focalpoint_x )  ,2) )

# Adapted from https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html
func kelvin_to_color( temperature ) -> Color:

	var colour = Color()
	temperature = (temperature / 100) as int
	
	# Calculate Red:
	if temperature <= 66:
		colour.r8 = 255
	else:
		colour.r8 = clamp(329.698727446 * pow(temperature - 60, -0.1332047592), 0, 255)
	
	# Calculate Green:
	if temperature <= 66:
		colour.g8 = clamp(99.4708025861 * log(temperature) - 161.1195681661, 0, 255)
	else:
		colour.g8 = clamp(288.1221695283 * pow(temperature - 60, -0.0755148492), 0, 255)
	
	# Calculate Blue:
	if temperature >= 66:
		colour.b8 = 255
	else:
		if temperature <= 19:
			colour.b8 = 0
		else:
			colour.b8 = clamp(138.5177312231 * log(temperature - 10) - 305.0447927307, 0, 255)
	
	return colour;
