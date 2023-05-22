extends CanvasModulate

# Code written with help from https://www.youtube.com/watch?v=j_FMsL_ru1w

const DAYLIGHT := Color()
const TWILIGHT := Color()
const NIGHTLIGHT := Color()

var hour_sunrise = 6.0
var hour_sunset = 18.0

var current_temp
var current_brightness

var time = 150.0
var current_hour

## Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time = time + delta # Change this line to use the new Global !!!!!!!!!!!!!
	
	current_hour = fmod((time / 10), 24 )
	print("Current hour = %f, time = %f" % [current_hour, time])
	
	#self.color = TWILIGHT.lerp(DAYLIGHT, absf(sin(time)) ) # Update this line to use all the lights !!!!!!!!!!!!!
	self.color = kelvin_to_color( daylight_temp_curve( current_hour ) )
	self.color = curve_daylight_value( current_hour, self.color )
	pass

# notice the 'curve' is in front here, but not on the temp function.
# 'curve' here is a verb, and there is a noun.
func curve_daylight_value( hour, color ):
	
	# Approximation of a normal distribution curve
	var shift = 12
	var stretch = 3.3
	#var scaled_oneoversqrttwopi = 0.3989422804014327   # m * 1 / sqrt( 2pi )  # wait, this is just 1...
	var e = 2.71828
	#var scale = 2.52
	
	var min_light = 0.1
	
	var exponent = - (pow((hour - shift)/stretch, 2) ) / 2
	#var phi 
	
	color.v = clamp( min_light + 8 * pow(e,exponent), 0, 1)
	return color


# returns temperature at given hour, and is hard coded because...?
# each hour = 1.0
func daylight_temp_curve( hour ) -> float:
	
	var theta = 0 # unused?
	var daylight_length = ( hour_sunrise - hour_sunset )
	var daylight_center = ( hour_sunrise + hour_sunset )/2
	var moonlight_center = (24.0 + hour_sunrise + hour_sunset)/2
	
	# If the equation is symmetrical, then everything's cool.
	if hour > daylight_center:
		hour = daylight_center - abs( daylight_center - hour )
		print("hr: %f" % [hour])
	
	# This is supposed to be a cycloid, but cycloids are hard to make into a function of x
	# Try using cubic splines in the future!
	if hour >= hour_sunrise && hour <= hour_sunset:
		
		var temp_max = 5750
		var temp_min = 3500
		#var arc_center = ( hour_sunrise + hour_sunset )/2
		
		
		var f = (temp_min - temp_max)/daylight_length
		
		return f * pow(hour - daylight_center , 2) + temp_max
		
	# This part is broken severely, so it might be bypassed, but let me shove it into the repo first.
	elif hour-1 >= hour_sunrise || hour+1 <= hour_sunset:
		
		# The scale is all wrong, so let's force it to be okay again, within fp precision...
		#var stretched_hour = -42 * abs(hour_sunrise - hour)
		var stretched_hour = -28 * abs(hour_sunrise - hour) # shifted (heh) for testing
		
		# transition from between night peak and start/end of day
		var parabola_a_extrema = 3500
		var parabola_a_width = 6.3
		var parabola_a_depth = -22.4
		var parabola_a_focal = -3.571
		
		var y_a = pow(parabola_a_width*stretched_hour - parabola_a_depth, 2) + parabola_a_extrema + pow(parabola_a_depth,2)
		
		# night peak
		var parabola_b_extrema = 3500
		var parabola_b_shift = -28
		var parabola_b_depth = 147
		var parabola_b_squeeze = -100
		var parabola_b_focal = -28
		
		var y_b = parabola_b_squeeze * pow(stretched_hour - parabola_b_shift, 2) + parabola_b_extrema + pow(parabola_b_depth,2)
		
		return y_a + (y_b - y_a) * ( (stretched_hour - parabola_a_focal) / ( parabola_b_focal - parabola_a_focal))
		# y = y_a + (y_b - y_a)(x - x_a / x_b - x_a)
		
	else:
		
#		var shift = 6.7
#		var a = 1
#		var b = 1000
#
#		return (a * b * (hour - shift)) / ( pow(hour - shift, 2) + pow(a,2)) + 5000
		return 25109	# All the math is bypassed because night looks better blue I guess
	
	pass



# Adapted from https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html
# Note, to avoid rights issues, and to make code easier to read, consider removing the if color<0 checks.
# Also note that a color going out of bounds might not be corrected by Godot. Maybe clamp it?

func kelvin_to_color( temperature ) -> Color:

	var color = Color()
	temperature = (temperature / 100) as int
	
	# Calculate Red:
	
	if temperature <= 66:
		color.r8 = 255
	else:
		#color.r8 = temperature - 60
		color.r8 = 329.698727446 * pow(temperature - 60, -0.1332047592)
		if color.r8 < 0:
			print("color.r8 = ", color.r8)
			color.r8 = 0
		if color.r8 > 255: 
			print("color.r8 = ", color.r8)
			color.r8 = 255

	# Calculate Green:

	if temperature <= 66:
		#color.g8 = temperature
		color.g8 = 99.4708025861 * log(temperature) - 161.1195681661
		if color.g8 < 0: 
			print("color.g8 = ", color.g8)
			color.g8 = 0
		if color.g8 > 255:
			print("color.g8 = ", color.g8) 
			color.g8 = 255
	else:
		#color.g8 = temperature - 60
		color.g8 = 288.1221695283 * pow(temperature - 60, -0.0755148492)
		if color.g8 < 0: 
			print("color.g8 = ", color.g8)
			color.g8 = 0
		if color.g8 > 255:
			print("color.g8 = ", color.g8)
			color.g8 = 255

	# Calculate Blue:

	if temperature >= 66:
		color.b8 = 255
	else:
		
		if temperature <= 19:
			color.b8 = 0
		else:
			#color.b8 = temperature - 10
			color.b8 = 138.5177312231 * log(temperature - 10) - 305.0447927307
			if color.b8 < 0: 
				print("color.b8 = ", color.b8)
				color.b8 = 0
			if color.b8 > 255: 
				print("color.b8 = ", color.b8)
				color.b8 = 255
	
	return color;
