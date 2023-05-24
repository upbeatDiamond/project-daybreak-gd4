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
	print("Current hour = %f, time = %f" % [current_hour, time])
	
	self.color = kelvin_to_color( get_daylight_temp( current_hour ) )
	self.color = fix_daylight_value( current_hour, self.color )
	pass



func fix_daylight_value( hour, color ):
	
	var shift = 12
	var stretch = 3.3
	var e = 2.71828
	
	var min_light = 0.1
	
	var exponent = - (pow((hour - shift)/stretch, 2) ) / 2
	
	color.v = clamp( min_light + 8 * pow(e,exponent), 0, 1)
	return color


func get_daylight_temp( hour ) -> float:
	
	var is_night = false
	
	var daylight_length = ( hour_sunrise - hour_sunset )
	var daylight_center = ( hour_sunrise + hour_sunset )/2
	var moonlight_length = day_length - daylight_length + 1
	var moonlight_center = (24.0 + hour_sunrise + hour_sunset)/2
	
	var focalpoint_y = 1000
	var focalpoint_x = daylight_center
	var radius = daylight_length + 1
	var scaling = 450
	
	if hour < hour_sunrise:
		hour = hour + day_length
		is_night = true
	
	if is_night:
		focalpoint_x = moonlight_center

	return focalpoint_y + scaling * sqrt( pow(radius,2) - pow(hour - focalpoint_x,2) )


# Adapted from https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html

func kelvin_to_color( temperature ) -> Color:

	var color = Color()
	temperature = (temperature / 100) as int
	
	# Calculate Red:
	if temperature <= 66:
		color.r8 = 255
	else:
		color.r8 = clamp(329.698727446 * pow(temperature - 60, -0.1332047592), 0, 255)

	# Calculate Green:
	if temperature <= 66:
		color.g8 = clamp(99.4708025861 * log(temperature) - 161.1195681661, 0, 255)
	else:
		color.g8 = clamp(288.1221695283 * pow(temperature - 60, -0.0755148492), 0, 255)

	# Calculate Blue:
	if temperature >= 66:
		color.b8 = 255
	else:
		if temperature <= 19:
			color.b8 = 0
		else:
			color.b8 = clamp(138.5177312231 * log(temperature - 10) - 305.0447927307, 0, 255)
	
	return color;
