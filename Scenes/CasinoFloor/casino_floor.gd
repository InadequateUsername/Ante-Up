extends Control

# Preload game scenes here later
# var blackjack_scene = preload("res://Scenes/Games/Blackjack/Blackjack.tscn")
# var poker_scene = preload("res://Scenes/Games/Poker/Poker.tscn")
# var slots_scene = preload("res://Scenes/Games/Slots/Slots.tscn")

func _ready():
	# Connect button signals when the scene is ready
	$GameButtonsContainer/BlackjackButton.connect("pressed", _on_blackjack_button_pressed)
	$GameButtonsContainer/PokerButton.connect("pressed", _on_poker_button_pressed)
	$GameButtonsContainer/SlotsButton.connect("pressed", _on_slots_button_pressed)
	$BackButton.connect("pressed", _on_back_button_pressed)

# Function to go to the Blackjack game
func _on_blackjack_button_pressed():
	# To be implemented
	print("Blackjack button pressed")
	# get_tree().change_scene_to_packed(blackjack_scene)

# Function to go to the Poker game
func _on_poker_button_pressed():
	# To be implemented
	print("Poker button pressed")
	# get_tree().change_scene_to_packed(poker_scene)

# Function to go to the Slots game
func _on_slots_button_pressed():
	# To be implemented
	print("Slots button pressed")
	# get_tree().change_scene_to_packed(slots_scene)

# Function to go back to the title screen
func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/TitleScreen/title_screen.tscn")
