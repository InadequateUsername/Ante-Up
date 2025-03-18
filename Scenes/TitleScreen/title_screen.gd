extends Control

func _ready():
	print("Title Screen: Initializing...")
	
	# Connect button signals to functions
	$MainButtonContainer/NewGameButton.connect("pressed", _on_new_game_button_pressed)
	$MainButtonContainer/LoadGameButton.connect("pressed", _on_load_game_button_pressed)
	$MainButtonContainer/SettingsButton.connect("pressed", _on_settings_button_pressed)
	$SocialLinksControl/SocialLinksContainer/DiscordButton.connect("pressed", _on_discord_button_pressed)
	
	print("Title Screen: Initialization complete")

# Function called when New Game button is pressed
func _on_new_game_button_pressed():
	print("New Game button pressed - transitioning to casino floor")
	
	# Initialize Global singleton if needed
	if not get_node_or_null("/root/Global"):
		var global = Node.new()
		global.name = "Global"
		global.set_script(load("res://global.gd"))
		get_tree().root.add_child(global)
		print("Created Global singleton with default chips")
	
	# Use SceneManager to change to the casino floor
	SceneManager.change_scene("casino_floor")

# Function called when Load Game button is pressed
func _on_load_game_button_pressed():
	# To be implemented later
	print("Load Game button pressed")

# Function called when Settings button is pressed
func _on_settings_button_pressed():
	# To be implemented later
	print("Settings button pressed")

# Function called when Discord button is pressed
func _on_discord_button_pressed():
	# Open Discord link in browser
	OS.shell_open("https://discord.gg/BKc3EWexgB")
