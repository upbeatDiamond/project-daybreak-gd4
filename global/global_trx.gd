extends Node
## TRX means what?
## TR is the default command for translating text in Godot.
## X symbolizes neutrality, unknown, or shorthand for a word which starts with
## 'ecs', 'ex', or 'chris'.
## So, TRX might mean TRanslation eXtension/eXternal/eXpansion.
## The name should be 3 characters long for clarity and succinctness.

func _init():
	pass


func register_translation_from_path(tr_path:String):
	var tr_file = load(tr_path)
	TranslationServer.add_translation(tr_file)


func register_translation_from_inline(inline:String, locale:String):
	var tr_inline = TranslationFluent.new()
	tr_inline.locale = locale
	tr_inline.append_from_text(inline)
	TranslationServer.add_translation(tr_inline)


## For substituting assets with their local-specific counterparts
func path():
	pass


## For loading substitutes for assets
func load_asset():
	pass


## For translating messages, display text, etc, based on current locale
func text():
	pass


## For updating the current locale
func set_locale():
	pass


#func _notification(what: int) -> void:
	#if what == NOTIFICATION_TRANSLATION_CHANGED:
		## Fluent supports $variables, which can be filled when translating a message.
#
		### Default version: use a wrapper function to pass arguments:
		#$Label.text = atr(TranslationFluent.args("HELLO", { "unreadEmails": $SpinBox.value }))
#
		### The context field is used to retrieve .attributes of a message.
		#$Label2.text = atr("HELLO", "meta") # Default
