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

# Function to go to the Slots game
func _on_slots_button_pressed():
	print("Slots button pressed - saving chips: ", Global.player_chips)
	
	# Save chips to Global
	var global_node = get_node_or_null("/root/Global")
	if global_node:
		global_node.player_chips = Global.player_chips
		print("Saved chips to Global: ", Global.player_chips)
	else:
		print("WARNING: Global not found when trying to save chips!")
		# Create global as failsafe
		global_node = Node.new()
		global_node.name = "Global"
		global_node.set_script(load("res://global.gd"))
		global_node.player_chips = Global.player_chips
		get_tree().root.add_child(global_node)
		print("Created Global singleton with chips: ", Global.player_chips)
	
	# Use SceneManager to change to slots
	SceneManager.change_scene("slots")
