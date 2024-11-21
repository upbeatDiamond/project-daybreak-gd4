extends TextureButton
class_name BattleButtonMode

#signal action_submit(button:BattleButtonSubmit)

@export var mode := BattleClientGUI.IOMode.BLANK
var gui


# Called when the node enters the scene tree for the first time.
func _ready():
	self.disabled = true
	pass # Replace with function body.


func _pressed():
	#action_submit.emit(self)
	gui.switch_ui_mode(mode)
	pass


func _link_to_gui(_gui:BattleClientGUI):
	gui = _gui
	gui.enable_buttons.connect(enable_control)
	print(self, " is linked to ", _gui)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func enable_control():
	self.disabled = false
	#print("[mode] enabled!")
	pass
