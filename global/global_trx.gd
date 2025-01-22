extends Node
## TRX means what?
## TR is the default command for translating text in Godot.
## X symbolizes neutrality, unknown, or shorthand for a word which starts with
## 'ecs', 'ex', or 'chris'.
## So, TRX might mean TRanslation eXtension/eXternal/eXpansion.
## The name should be 3 characters long for clarity and succinctness.

func _init():
	## Four ways to load FTL translations:
	## 1. load(path) with locale in file name (Portuguese).
	var tr_filename = load("res://test.pt_PT.ftl")

	## 2. load(path) with locale in folder name (German).
	var tr_foldername = load("res://de/german-test.ftl")

	## 3. Manually create a TranslationFluent resource.
	var tr_inline = TranslationFluent.new()
	## Ensure that you fill the locale before adding any contents (English).
	tr_inline.locale = "en"

	## Godot automatically converts spaces to tabs for multi-line strings, but tabs are invalid in
	## FTL syntax. So convert tabs to four spaces. Returns an error that you should handle.
	var err_inline = tr_inline.append_from_text("""
-term = email
HELLO =
	{ $unreadEmails ->
		[one] You have one unread { -term }.
	   *[other] You have { $unreadEmails } unread { -term }s.
	}
	.meta = An attr.
""".replace("\t", "    "))

	# Define custom functions to use in messages.
	# positional is an array, named is a dictionary.
	tr_filename.add_function("STRLEN", func(positional, named):
		if positional.is_empty():
			return 0
		return len(str(positional[0]))
	)

	# Register via TranslationServer.
	TranslationServer.add_translation(tr_filename)
	TranslationServer.add_translation(tr_foldername)
	TranslationServer.add_translation(tr_inline)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		# Fluent supports $variables, which can be filled when translating a message.

		# Default version: use a wrapper function to pass arguments:
		$Label.text = atr(TranslationFluent.args("HELLO", { "unreadEmails": $SpinBox.value }))

		# Forked version: pass arguments directly to tr() and friends:
		#$Label.text = atr("HELLO", { "unreadEmails": $SpinBox.value })

		# The context field is used to retrieve .attributes of a message.
		$Label2.text = atr("HELLO", "meta") # Default
		#$Label2.text = atr("HELLO", {}, "meta") # Forked
