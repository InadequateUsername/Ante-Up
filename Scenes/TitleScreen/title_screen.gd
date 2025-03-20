extends Control

var confirm_dialog_scene = preload("res://Scripts/SaveManager/confirm_dialog.tscn")
var confirm_dialog = null
var cleanup_manager = null

func _ready():
	print("Title Screen: Initializing...")
	
	# Initialize cleanup manager first
	cleanup_manager = get_node_or_null("/root/CleanupManager")
	if not cleanup_manager:
		cleanup_manager = Node.new()
		cleanup_manager.name = "CleanupManager"
		cleanup_manager.set_script(load("res://Scripts/Utils/cleanup_manager.gd"))
		get_tree().root.add_child.call_deferred(cleanup_manager)
	
	# Connect button signals to functions
	$MainButtonContainer/NewGameButton.connect("pressed", _on_new_game_button_pressed)
	$MainButtonContainer/LoadGameButton.connect("pressed", _on_load_game_button_pressed)
	$MainButtonContainer/SettingsButton.connect("pressed", _on_settings_button_pressed)
	$MainButtonContainer/QuitGameButton.connect("pressed", _on_quit_game_button_pressed)
	$SocialLinksControl/SocialLinksContainer/DiscordButton.connect("pressed", _on_discord_button_pressed)
	
	# Create the confirmation dialog
	confirm_dialog = confirm_dialog_scene.instantiate()
	add_child(confirm_dialog)
	confirm_dialog.confirmed.connect(_on_new_game_confirmed)
	
	# Make sure SaveInfoLabel is hidden by default
	if has_node("MainButtonContainer/SaveInfoContainer/SaveInfoLabel"):
		$MainButtonContainer/SaveInfoContainer/SaveInfoLabel.visible = false
	
	# Check if save exists and update Load Game button accordingly
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager:
		$MainButtonContainer/LoadGameButton.disabled = !save_manager.has_save()
		
		# If a save exists, display save info in a label
		if save_manager.has_save():
			var save_info = save_manager.get_save_info()
			if save_info:
				# Ensure save_info is not null before trying to use it
				print("Save info found: ", save_info)
				
				var date_str = save_manager.format_timestamp(save_info["timestamp"])
				# Convert chips to integer before displaying
				var chips_str = str(int(save_info["player_chips"]))
				
				# Create the info text
				var info_text = "Last save: " + date_str + "\nChips: " + chips_str
				
				# Find and update the SaveInfoLabel
				if has_node("MainButtonContainer/SaveInfoContainer/SaveInfoLabel"):
					var save_label = $MainButtonContainer/SaveInfoContainer/SaveInfoLabel
					save_label.text = info_text
					save_label.visible = true
					print("Updated SaveInfoLabel: " + info_text)
				else:
					print("ERROR: SaveInfoLabel not found in MainButtonContainer")
					
					# Try to find it by class type as a fallback
					for child in $MainButtonContainer.get_children():
						if child is Label:
							child.text = info_text
							child.visible = true
							print("Found and updated alternate label: " + child.name)
							break
			else:
				print("WARNING: Save info is null even though has_save() returned true")
		else:
			print("No save file exists according to has_save()")
	else:
		print("WARNING: SaveManager singleton not found")
	
	print("Title Screen: Initialization complete")

# Function called when New Game button is pressed
func _on_new_game_button_pressed():
	print("New Game button pressed")
	
	# Check if save exists and confirm overwrite
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager and save_manager.has_save():
		# Show confirmation dialog
		confirm_dialog.show_dialog(
			"Overwrite Save?", 
			"Starting a new game will overwrite your existing save. Are you sure you want to continue?"
		)
	else:
		# No save exists, proceed directly
		_on_new_game_confirmed()

# Called when user confirms new game
func _on_new_game_confirmed():
	print("New game confirmed - transitioning to casino floor")
	
	# Initialize Global singleton with default values
	var global = get_node_or_null("/root/Global")
	if not global:
		global = Node.new()
		global.name = "Global"
		global.set_script(load("res://global.gd"))
		get_tree().root.add_child(global)
	else:
		# Reset Global to default values
		global.player_chips = 1000
		global.games_played = 0
		global.blackjack_stats = {
			"games_played": 0,
			"wins": 0,
			"losses": 0,
			"pushes": 0,
			"blackjacks": 0,
			"biggest_win": 0
		}
	
	print("Created/reset Global singleton with default chips")
	
	# Delete existing save if needed
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager and save_manager.has_save():
		save_manager.delete_save()
	
	# Use SceneManager to change to the casino floor
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager:
		var success = await scene_manager.change_scene("casino_floor")
		if !success:
			print("ERROR: Failed to transition to casino floor")

func _on_new_game_cancelled():
	print("New game cancelled")

# Function called when Load Game button is pressed
func _on_load_game_button_pressed():
	print("Load Game button pressed")
	
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager and save_manager.has_save():
		var success = save_manager.load_game()
		
		if success:
			print("Save loaded successfully, transitioning to casino floor")
			var scene_manager = get_node_or_null("/root/SceneManager")
			if scene_manager:
				var scene_success = await scene_manager.change_scene("casino_floor")
				if !scene_success:
					print("ERROR: Failed to transition to casino floor after loading save")
		else:
			print("Failed to load save")
			# Show error dialog
			confirm_dialog.show_dialog(
				"Error Loading Save", 
				"There was a problem loading your saved game. Please try again."
			)
	else:
		print("No save file exists")
		$MainButtonContainer/LoadGameButton.disabled = true

# Function called when Settings button is pressed
func _on_settings_button_pressed():
	# To be implemented later
	print("Settings button pressed")

# Function called when Discord button is pressed
func _on_discord_button_pressed():
	# Open Discord link in browser
	OS.shell_open("https://discord.gg/BKc3EWexgB")

# Function called when Quit Game button is pressed
func _on_quit_game_button_pressed():
	print("Quit Game button pressed")

	# Get the cleanup manager and clean up all dialogs
	if cleanup_manager:
		cleanup_manager.cleanup_all_dialogs()

	# Check if save exists and should be updated
	var global = get_node_or_null("/root/Global")
	var save_manager = get_node_or_null("/root/SaveManager")

	if global and save_manager:
		# Make sure any current game state is saved
		print("Auto-saving before quitting...")
		save_manager.save_game()
		print("Save completed")
	
	# Add a slight delay to ensure save completes
	print("Quitting game in 0.5 seconds...")
	await get_tree().create_timer(0.5).timeout

	# Quit the game
	print("Exiting application")
	get_tree().quit()
	
