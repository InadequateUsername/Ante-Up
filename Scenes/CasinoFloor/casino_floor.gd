extends Control

# Preload game scenes
var blackjack_scene = preload("res://Scenes/Games/Blackjack/blackjack.tscn")
# var poker_scene = preload("res://Scenes/Games/Poker/poker.tscn")
# var slots_scene = preload("res://Scenes/Games/Slots/slots.tscn")
# var cashier_booth_scene = preload("res://Scenes/CashierBooth/cashier_booth.tscn")

# Player chip variables - will be synced with Global
var player_chips = 1000

func _ready():
	# Debug print to check path
	print("CasinoFloor: _ready function started")
	
	# Get chips from Global singleton
	if Engine.has_singleton("Global") or get_node_or_null("/root/Global"):
		var global_node = get_node_or_null("/root/Global")
		if global_node:
			player_chips = global_node.player_chips
			print("Found Global, player chips: ", player_chips)
	
	# Connect button signals
	$GameButtonsContainer/BlackjackButton.connect("pressed", _on_blackjack_button_pressed)
	$GameButtonsContainer/PokerButton.connect("pressed", _on_poker_button_pressed)
	$GameButtonsContainer/SlotsButton.connect("pressed", _on_slots_button_pressed)
	$GameButtonsContainer/CashierBoothButton.connect("pressed", _on_cashier_booth_button_pressed)
	$BackButton.connect("pressed", _on_back_button_pressed)
	
	# Update the chips display
	update_chips_display()

# Function to update the chips display
func update_chips_display():
	$Chips/ChipsHBoxContainer/ChipsAmount.text = str(player_chips)
	print("Updated chips display: ", player_chips)

# Function to go to the Blackjack game
func _on_blackjack_button_pressed():
	print("Blackjack button pressed - saving chips: ", player_chips)
	
	# Save chips to Global singleton first
	var global_node = get_node_or_null("/root/Global")
	if global_node:
		global_node.player_chips = player_chips
		print("Saved chips to Global: ", player_chips)
	
	# Change scene
	get_tree().change_scene_to_file("res://Scenes/Games/Blackjack/blackjack.tscn")

# Function to go to the Poker game
func _on_poker_button_pressed():
	print("Poker button pressed")
	
	# Save chips to Global
	var global_node = get_node_or_null("/root/Global")
	if global_node:
		global_node.player_chips = player_chips
	
	# Navigate to poker scene when implemented
	# get_tree().change_scene_to_file("res://Scenes/Games/Poker/poker.tscn")

# Function to go to the Slots game
func _on_slots_button_pressed():
	print("Slots button pressed")
	
	# Save chips to Global
	var global_node = get_node_or_null("/root/Global")
	if global_node:
		global_node.player_chips = player_chips
	
	# Navigate to slots scene when implemented
	# get_tree().change_scene_to_file("res://Scenes/Games/Slots/slots.tscn")

# Function to go to the Cashier Booth
func _on_cashier_booth_button_pressed():
	print("Cashier Booth button pressed")
	
	# Save chips to Global
	var global_node = get_node_or_null("/root/Global")
	if global_node:
		global_node.player_chips = player_chips
	
	# Navigate to cashier booth scene when implemented
	# get_tree().change_scene_to_file("res://Scenes/CashierBooth/cashier_booth.tscn")

# Return to the title screen
func _on_back_button_pressed():
	print("Back button pressed - returning to title screen")
	
	# Save chips to Global
	var global_node = get_node_or_null("/root/Global")
	if global_node:
		global_node.player_chips = player_chips
		print("Saving chips before returning to title: ", player_chips)
	
	get_tree().change_scene_to_file("res://Scenes/TitleScreen/title_screen.tscn")
