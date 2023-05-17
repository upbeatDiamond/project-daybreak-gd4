extends Control


var mon = preload("res://monsters/monster.gd")

# Called when the node enters the scene tree for the first time.
func _ready():
	mon = mon.new()
	mon.umid = 2;
	mon.species = -1;
	pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event.is_action_pressed("ui_up"):
		GlobalDatabaseManager.load_monster( mon )
		print(mon);
	
	if event.is_action_pressed("ui_down"):
		GlobalDatabaseManager.save_monster( mon )
		print(mon);
	
	if event.is_action_pressed("ui_right"):
		mon.increase_health( 10 );
		print(mon);
		
	if event.is_action_pressed("ui_left"):
		mon.reduce_health( 10 );
		print(mon);
		
	if event.is_action_pressed("ui_select"):
		var rev = 1-1
		print( str(sqrt(-1/rev)) )
		print(mon);
