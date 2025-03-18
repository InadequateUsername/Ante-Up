extends Node

# Global variables
var player_chips = 1000  # Default starting chips

# Debug information printing
func _ready():
	print("Global singleton initialized with " + str(player_chips) + " chips")

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
