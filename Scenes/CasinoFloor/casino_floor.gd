extends Control

# Player chip variables - will be synced with Global
var player_chips = 1000

func _ready():
	print("CasinoFloor: _ready function started")
	
	# Get chips from Global singleton
	var global_node = get_node_or_null("/root/Global")
	if global_node:
		player_chips = int(global_node.player_chips)
		print("Found Global, player chips: ", player_chips)
	else:
		print("WARNING: Global singleton not found! Creating it...")
		# Create Global as failsafe if it doesn't exist
		global_node = Node.new()
		global_node.name = "Global"
		global_node.set_script(load("res://global.gd"))
		global_node.player_chips = int(player_chips)
		get_tree().root.add_child(global_node)
		print("Created Global singleton with chips: ", player_chips)
	
	# Connect button signals
	$GameButtonsContainer/BlackjackButton.connect("pressed", _on_blackjack_button_pressed)
	$GameButtonsContainer/PokerButton.connect("pressed", _on_poker_button_pressed)
	$GameButtonsContainer/SlotsButton.connect("pressed", _on_slots_button_pressed)
	$GameButtonsContainer/CashierBoothButton.connect("pressed", _on_cashier_booth_button_pressed)
	$ReturnButtonsContainer/BackButton.connect("pressed", _on_back_button_pressed)
	$ReturnButtonsContainer/ExitButton.connect("pressed", _on_exit_button_pressed)  # Connect the Exit button
	
	# Update the chips display
	update_chips_display()
	
	print("CasinoFloor: Initialization complete")
	
# Function to update the chips display
func update_chips_display():
	$Chips/ChipsHBoxContainer/ChipsAmount.text = str(int(player_chips))
	print("Updated chips display: ", int(player_chips))

# Function to go to the Blackjack game
func _on_blackjack_button_pressed():
	print("Blackjack button pressed - saving chips: ", player_chips)
	
	# Save chips to Global singleton first
	var global_node = get_node_or_null("/root/Global")
	if global_node:
		global_node.player_chips = player_chips
		print("Saved chips to Global: ", player_chips)
	else:
		print("WARNING: Global not found when trying to save chips!")
		# Create global as failsafe
		global_node = Node.new()
		global_node.name = "Global"
		global_node.set_script(load("res://global.gd"))
		global_node.player_chips = player_chips
		get_tree().root.add_child(global_node)
		print("Created Global singleton with chips: ", player_chips)
	
	# Use SceneManager to change to blackjack
	SceneManager.change_scene("blackjack")

# Function to go to the Poker game
func _on_poker_button_pressed():
	print("Poker button pressed")
	
	# Save chips to Global
	var global_node = get_node_or_null("/root/Global")
	if global_node:
		global_node.player_chips = player_chips
	
	# Use SceneManager to change to poker (when implemented)
	# SceneManager.change_scene("poker")

# Function to go to the Slots game
func _on_slots_button_pressed():
	print("Slots button pressed - saving chips: ", player_chips)

	# Save chips to Global
	var global_node = get_node_or_null("/root/Global")
	if global_node:
		global_node.player_chips = player_chips

	# Use SceneManager to change to slots
	SceneManager.change_scene("slots")  # This should match your scene's name

# Function to go to the Cashier Booth
func _on_cashier_booth_button_pressed():
	print("Cashier Booth button pressed")
	
	# Save chips to Global
	var global_node = get_node_or_null("/root/Global")
	if global_node:
		global_node.player_chips = player_chips
	
	# Use SceneManager to change to cashier booth (when implemented)
	# SceneManager.change_scene("cashier_booth")

# Return to the title screen
func _on_back_button_pressed():
	print("Back button pressed - returning to title screen")
	
	# Save chips to Global
	var global_node = get_node_or_null("/root/Global")
	if global_node:
		global_node.player_chips = player_chips
		print("Saving chips before returning to title: ", player_chips)
	
	# Trigger autosave
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager:
		print("Autosaving game before returning to title screen")
		save_manager.save_game()
	
	# Use SceneManager to change to title screen WITH AWAIT
	var success = await SceneManager.change_scene("title_screen")
	if !success:
		print("ERROR: Failed to transition to title screen")
	SceneManager.change_scene("title_screen")

# Function to handle the Exit button press
func _on_exit_button_pressed():
	print("Exit button pressed on casino floor")
	
	# Get the cleanup manager and clean up all dialogs
	var cleanup_manager = get_node_or_null("/root/CleanupManager")
	if cleanup_manager:
		cleanup_manager.cleanup_all_dialogs()
	
	# Save chips to Global singleton first
	var global_node = get_node_or_null("/root/Global")
	if global_node:
		global_node.player_chips = player_chips
		print("Saved " + str(player_chips) + " chips to Global before quitting")
	else:
		print("WARNING: Global not found, creating it")
		global_node = Node.new()
		global_node.name = "Global"
		global_node.set_script(load("res://global.gd"))
		global_node.player_chips = player_chips
		get_tree().root.add_child(global_node)
	
	# Trigger auto-save before quitting
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager:
		print("Auto-saving before quitting...")
		save_manager.save_game()
		print("Save completed")
	
	# Add a slight delay to ensure save completes
	print("Quitting game in 0.5 seconds...")
	await get_tree().create_timer(0.5).timeout
	
	# Quit the game
	print("Exiting application")
	get_tree().quit()
