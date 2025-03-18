extends Node

# Global variables
var player_chips = 1000  # Default starting chips
var game_saves = {}  # For future save game functionality

# Debug information printing
func _ready():
	print("Global singleton initialized with " + str(player_chips) + " chips")
	
	# Connect to SceneManager signals (if applicable)
	if get_node_or_null("/root/SceneManager"):
		SceneManager.connect("scene_changed", _on_scene_changed)

# Function to modify player chips
func add_chips(amount):
	player_chips += amount
	print("Added " + str(amount) + " chips, new total: " + str(player_chips))
	return player_chips

# Function to set player chips to a specific value
func set_chips(amount):
	player_chips = amount
	print("Set chips to " + str(player_chips))
	return player_chips

# Function called when scene changes (for future use)
func _on_scene_changed(_new_scene):
	print("Global: Scene changed notification received")
	# This could be used to trigger auto-saves or other global behavior
	# when scenes change
