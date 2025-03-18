extends Control

# Preload the CasinoFloor scene to use later
var casino_floor_scene = preload("res://Scenes/CasinoFloor/casino_floor.tscn")

func _ready():
	# Connect button signals to functions
	$MainButtonContainer/NewGameButton.connect("pressed", _on_new_game_button_pressed)
	$MainButtonContainer/LoadGameButton.connect("pressed", _on_load_game_button_pressed)
	$MainButtonContainer/SettingsButton.connect("pressed", _on_settings_button_pressed)
	$SocialLinksControl/SocialLinksContainer/DiscordButton.connect("pressed", _on_discord_button_pressed)

# Function called when New Game button is pressed
func _on_new_game_button_pressed():
	# Change to the CasinoFloor scene
	get_tree().change_scene_to_packed(casino_floor_scene)

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
