extends TextureButton
class_name BattleButtonSubmit

signal action_submit(button:BattleButtonSubmit)

@export var battle_act_type = BattleAction.ActionType.PASS
@export var battle_act_index: int = -1 # Not the same as Core; used to determine Core 
@export var needs_clarify:bool=false # Instantly depricated; Just don't don't use yet. Simple.
var gui:BattleClientGUI
@export var gui_mode_exclusive:=BattleClient.IOMode.MOVE

# Called when the node enters the scene tree for the first time.
func _ready():
	self.disabled = true
	pass # Replace with function body.


func _pressed():
	#action_submit.emit(self)
	if(needs_clarify):
		# Enable clarification interface
		# (Consider switching the boolean for a check if clarification var node is null)
		pass # await clarification response
	
	## We cannot submit anything until the UI says it's our turn.
	if gui.ui_mode == gui_mode_exclusive or gui_mode_exclusive not in BattleClient.IOMode.values():
		gui.submit_action_info(battle_act_type, battle_act_index)


func _link_to_gui(_gui:BattleClientGUI):
	gui = _gui
	gui.enable_buttons.connect(enable_control)
	print(self, " is linked to ", _gui)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func enable_control():
	self.disabled = false
	print("enabled!")
	pass
