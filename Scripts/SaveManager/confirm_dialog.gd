extends ConfirmationDialog
# A simple confirmation dialog for the save system
# Create a new scene with a ConfirmationDialog and attach this script

signal dialog_cancelled  # Renamed from "cancelled" to avoid conflicts

func _ready():
	# Connect to the built-in signals
	confirmed.connect(_on_confirmed)
	canceled.connect(_on_cancelled)
	close_requested.connect(_on_cancelled)
	
	# We'll center the dialog when showing it instead of here

# Show the confirmation dialog with custom message
func show_dialog(title_text, message_text):
	title = title_text
	dialog_text = message_text
	
	# Center the dialog on screen
	position = get_tree().root.size / 2 - size / 2
	
	# Show the dialog
	popup_centered()

func _on_confirmed():
	# We don't need to emit "confirmed" since it's built-in
	# Just do any additional handling here
	pass

func _on_cancelled():
	emit_signal("dialog_cancelled")
