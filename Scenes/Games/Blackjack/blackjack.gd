extends Control

# Preload needed scenes
var card_scene = preload("res://Scenes/PlayingCards/card.tscn")

# Game state variables
var current_bet = 0
var previous_bet = 0
var game_in_progress = false
var deck = []
var player_chips = 1000  # Default starting chips

# Card containers
@onready var player_cards_container = $GameArea/PlayerArea/PlayerCards
@onready var dealer_cards_container = $GameArea/DealerArea/DealerCards
@onready var player_hand = []
@onready var dealer_hand = []

# UI References
@onready var player_score_label = $GameArea/PlayerArea/PlayerScoreLabel
@onready var dealer_score_label = $GameArea/DealerArea/DealerScoreLabel
@onready var result_label = $UI/ResultLabel
@onready var chips_label = $UI/ButtonsPanelContainer/ButtonsContainer/ChipsAmount
@onready var bet_label = $UI/ButtonsPanelContainer/ButtonsContainer/BetAmount

# Game signals
signal game_ended(result, winnings)

func _ready():
	print("Blackjack scene loading - Beginning _ready function")
	
	# IMPORTANT: Get chips from Global singleton FIRST
	print("Attempting to load player chips from Global singleton")
	var global = get_node_or_null("/root/Global")
	if global:
		print("Global singleton found with chips: ", global.player_chips)
		player_chips = global.player_chips
	else:
		print("WARNING: Global singleton not found! Using default chips: ", player_chips)
		# Create Global as failsafe if it doesn't exist
		var new_global = Node.new()
		new_global.name = "Global"
		new_global.set_script(load("res://global.gd"))
		new_global.player_chips = player_chips
		get_tree().root.add_child(new_global)
		print("Created Global singleton with chips: ", player_chips)
	
	# Connect back button first and directly
	var back_button = $UI/ReturnButtonsContainer/BackButton
	if back_button:
		# Disconnect any existing connections to avoid duplicates
		if back_button.is_connected("pressed", Callable(self, "_on_back_button_pressed")):
			back_button.disconnect("pressed", Callable(self, "_on_back_button_pressed"))
		# Connect back button directly
		back_button.connect("pressed", _on_back_button_pressed)
		print("Back button connected successfully")
	else:
		print("CRITICAL: Back button not found at UI/BackButton!")
	
	
	var exit_button = $UI/ReturnButtonsContainer/ExitButton
	if exit_button:
		# Disconnect any existing connections to avoid duplicates
		if exit_button.is_connected("pressed", Callable(self, "_on_exit_button_pressed")):
			exit_button.disconnect("pressed", Callable(self, "_on_exit_button_pressed"))
		# Connect exit button directly
		exit_button.connect("pressed", _on_exit_button_pressed)
		print("Exit button connected successfully")
	else:
		print("WARNING: Exit button not found at UI/ExitButton!")
	
	
	# Connect other game buttons
	connect_game_buttons()
	
	# Initialize the game
	print("Initializing game with " + str(player_chips) + " chips")
	initialize_game()
	
	# Print final confirmation
	print("Blackjack _ready function complete")

# Connect all gameplay buttons
func connect_game_buttons():
	# Connect all gameplay buttons directly
	var deal_button = $UI/ButtonsPanelContainer/ButtonsContainer/DealButtonContainer/DealButton
	if deal_button:
		if deal_button.is_connected("pressed", Callable(self, "_on_deal_button_pressed")):
			deal_button.disconnect("pressed", Callable(self, "_on_deal_button_pressed"))
		deal_button.connect("pressed", _on_deal_button_pressed)
	
	var hit_button = $UI/ButtonsPanelContainer/ButtonsContainer/GameButtonsContainer/HitButton
	if hit_button:
		if hit_button.is_connected("pressed", Callable(self, "_on_hit_button_pressed")):
			hit_button.disconnect("pressed", Callable(self, "_on_hit_button_pressed"))
		hit_button.connect("pressed", _on_hit_button_pressed)
	
	var stand_button = $UI/ButtonsPanelContainer/ButtonsContainer/GameButtonsContainer/StandButton
	if stand_button:
		if stand_button.is_connected("pressed", Callable(self, "_on_stand_button_pressed")):
			stand_button.disconnect("pressed", Callable(self, "_on_stand_button_pressed"))
		stand_button.connect("pressed", _on_stand_button_pressed)
	
	var bet_increase_button = $UI/ButtonsPanelContainer/ButtonsContainer/BetButtonsContainer/BetIncreaseButton
	if bet_increase_button:
		if bet_increase_button.is_connected("pressed", Callable(self, "_on_bet_increase_pressed")):
			bet_increase_button.disconnect("pressed", Callable(self, "_on_bet_increase_pressed"))
		bet_increase_button.connect("pressed", _on_bet_increase_pressed)
	
	var bet_decrease_button = $UI/ButtonsPanelContainer/ButtonsContainer/BetButtonsContainer/BetDecreaseButton
	if bet_decrease_button:
		if bet_decrease_button.is_connected("pressed", Callable(self, "_on_bet_decrease_pressed")):
			bet_decrease_button.disconnect("pressed", Callable(self, "_on_bet_decrease_pressed"))
		bet_decrease_button.connect("pressed", _on_bet_decrease_pressed)

# Update UI to display current chips
func update_chips_display():
	if chips_label and is_instance_valid(chips_label):
		chips_label.text = str(int(player_chips))  # Convert to integer
	if bet_label and is_instance_valid(bet_label):
		bet_label.text = str(int(current_bet))  # Convert to integer
	print("Chips display updated: " + str(int(player_chips)) + " chips, " + str(int(current_bet)) + " bet")

# Initialize or reset the game
func initialize_game():
	# Reset game state
	game_in_progress = false
	clear_cards()
	current_bet = 0
	
	# Create and shuffle a new deck
	create_deck()
	
	# Update UI
	update_chips_display()
	update_score_display()
	
	# Set initial button states
	if has_node("UI/ButtonsContainer/GameButtonsContainer/HitButton"):
		get_node("UI/ButtonsContainer/GameButtonsContainer/HitButton").disabled = true
	if has_node("UI/ButtonsContainer/GameButtonsContainer/StandButton"):
		get_node("UI/ButtonsContainer/GameButtonsContainer/StandButton").disabled = true
	if has_node("UI/ButtonsContainer/BetButtonsContainer/DealButton"):
		get_node("UI/ButtonsContainer/BetButtonsContainer/DealButton").disabled = false
	if has_node("UI/ButtonsContainer/BetButtonsContainer/BetIncreaseButton"):
		get_node("UI/ButtonsContainer/BetButtonsContainer/BetIncreaseButton").disabled = false
	if has_node("UI/ButtonsContainer/BetButtonsContainer/BetDecreaseButton"):
		get_node("UI/ButtonsContainer/BetButtonsContainer/BetDecreaseButton").disabled = true
	
	if result_label and is_instance_valid(result_label):
		result_label.text = "Place your bet and deal to start"

# Create and shuffle a new deck of cards
func create_deck():
	deck = []
	var suits = ["hearts", "diamonds", "clubs", "spades"]
	var values = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
	
	for suit in suits:
		for value in values:
			deck.append({"suit": suit, "value": value})
	
	# Shuffle deck
	deck.shuffle()

# Draw a card from the deck
func draw_card(is_face_up = true):
	if deck.size() > 0:
		var card_data = deck.pop_back()
		
		# Create the card instance
		var card_instance = card_scene.instantiate()
		card_instance.init(card_data.suit, card_data.value, is_face_up)
		
		return card_instance
	else:
		# If deck is empty, create a new shuffled deck
		create_deck()
		return draw_card(is_face_up)

# Add a card to a hand and container
func add_card_to_hand(hand, container, face_up = true):
	var card = draw_card(face_up)
	hand.append(card)
	container.add_child(card)
	
	# Position the card properly
	var offset = hand.size() * 30  # Overlap cards a bit
	card.position = Vector2(offset, 0)
	
	update_score_display()
	return card

# Clear all cards from the table
func clear_cards():
	player_hand = []
	dealer_hand = []
	
	if player_cards_container and is_instance_valid(player_cards_container):
		for child in player_cards_container.get_children():
			child.queue_free()
	
	if dealer_cards_container and is_instance_valid(dealer_cards_container):
		for child in dealer_cards_container.get_children():
			child.queue_free()

# Calculate the hand value (accounting for aces)
func calculate_hand_value(hand):
	var value = 0
	var num_aces = 0
	
	for card in hand:
		if card.value == "A":
			num_aces += 1
			value += 11
		elif card.value in ["K", "Q", "J", "10"]:
			value += 10
		else:
			value += int(card.value)
	
	# Handle aces (can be 1 or 11)
	while value > 21 and num_aces > 0:
		value -= 10  # Convert an ace from 11 to 1
		num_aces -= 1
	
	return value

# Update the score display
func update_score_display():
	if !player_score_label or !is_instance_valid(player_score_label):
		return
		
	var player_value = calculate_hand_value(player_hand)
	player_score_label.text = "Player: " + str(player_value)
	
	if !dealer_score_label or !is_instance_valid(dealer_score_label):
		return
		
	# Calculate dealer score based on face-up cards only
	var visible_dealer_cards = []
	var all_face_up = true
	
	for card in dealer_hand:
		if card.face_up:
			visible_dealer_cards.append(card)
		else:
			all_face_up = false
	
	var visible_dealer_value = calculate_hand_value(visible_dealer_cards)
	
	# If not all cards are face up, show "?" for dealer score
	if !all_face_up:
		dealer_score_label.text = "Dealer: ?"
	else:
		dealer_score_label.text = "Dealer: " + str(visible_dealer_value)

# Change bet amount
func _on_bet_increase_pressed():
	if player_chips >= 100 and not game_in_progress:
		current_bet += 100
		player_chips -= 100
		update_chips_display()
		if has_node("UI/ButtonsContainer/BetButtonsContainer/BetDecreaseButton"):
			get_node("UI/ButtonsContainer/BetButtonsContainer/BetDecreaseButton").disabled = false
		if has_node("UI/ButtonsContainer/BetButtonsContainer/DealButton"):
			get_node("UI/ButtonsContainer/BetButtonsContainer/DealButton").disabled = false

func _on_bet_decrease_pressed():
	if current_bet >= 100 and not game_in_progress:
		current_bet -= 100
		player_chips += 100
		update_chips_display()
		
		if current_bet <= 0:
			if has_node("UI/ButtonsContainer/BetButtonsContainer/BetDecreaseButton"):
				get_node("UI/ButtonsContainer/BetButtonsContainer/BetDecreaseButton").disabled = true
			if has_node("UI/ButtonsContainer/BetButtonsContainer/DealButton"):
				get_node("UI/ButtonsContainer/BetButtonsContainer/DealButton").disabled = true

# Start a new round
# Start a new round
func _on_deal_button_pressed():
	if current_bet > 0:
		print("=== STARTING NEW BLACKJACK HAND ===")
		game_in_progress = true

		# Clear any previous cards
		clear_cards()

		print("Dealing initial cards...")

		# Deal player's first card (face up)
		var p1 = add_card_to_hand(player_hand, player_cards_container, true)
		print("Player card 1: " + p1.get_card_name() + ", face_up = " + str(p1.face_up))

		# Deal dealer's first card (face DOWN - this is the change)
		var d1 = add_card_to_hand(dealer_hand, dealer_cards_container, false)
		print("Dealer card 1: " + d1.get_card_name() + ", face_up = " + str(d1.face_up))

		# Deal player's second card (face up)
		var p2 = add_card_to_hand(player_hand, player_cards_container, true)
		print("Player card 2: " + p2.get_card_name() + ", face_up = " + str(p2.face_up))

		# Deal dealer's second card (face up)
		var d2 = add_card_to_hand(dealer_hand, dealer_cards_container, true)
		print("Dealer card 2: " + d2.get_card_name() + ", face_up = " + str(d2.face_up))

		update_score_display()
		print("Score display updated")
		
		# Disable betting buttons during game
		if has_node("UI/ButtonsPanelContainer/ButtonsContainer/BetButtonsContainer/BetIncreaseButton"):
			get_node("UI/ButtonsPanelContainer/ButtonsContainer/BetButtonsContainer/BetIncreaseButton").disabled = true
		if has_node("UI/ButtonsPanelContainer/ButtonsContainer/BetButtonsContainer/BetDecreaseButton"):
			get_node("UI/ButtonsPanelContainer/ButtonsContainer/BetButtonsContainer/BetDecreaseButton").disabled = true
		if has_node("UI/ButtonsPanelContainer/ButtonsContainer/DealButtonContainer/DealButton"):
			get_node("UI/ButtonsPanelContainer/ButtonsContainer/DealButtonContainer/DealButton").disabled = true

		# Enable game action buttons
		if has_node("UI/ButtonsPanelContainer/ButtonsContainer/GameButtonsContainer/HitButton"):
			get_node("UI/ButtonsPanelContainer/ButtonsContainer/GameButtonsContainer/HitButton").disabled = false
		if has_node("UI/ButtonsPanelContainer/ButtonsContainer/GameButtonsContainer/StandButton"):
			get_node("UI/ButtonsPanelContainer/ButtonsContainer/GameButtonsContainer/StandButton").disabled = false

		if result_label and is_instance_valid(result_label):
			result_label.text = "Your move - Hit or Stand?"
			
			# Check for blackjack
			check_for_blackjack()

# Player draws another card
func _on_hit_button_pressed():
	if game_in_progress:
		add_card_to_hand(player_hand, player_cards_container)
		
		var player_value = calculate_hand_value(player_hand)
		
		if player_value > 21:
			end_game("bust")
		elif player_value == 21:
			# Auto-stand when player hits and gets exactly 21
			print("Player hit to 21 - automatically standing")
			if result_label and is_instance_valid(result_label):
				result_label.text = "21! Standing automatically..."
			
			# Add a slight delay for visual effect
			await get_tree().create_timer(0.5).timeout
			
			# Call dealer turn (same as standing)
			dealer_turn()

# Player stands, dealer's turn
func _on_stand_button_pressed():
	if game_in_progress:
		dealer_turn()

# Dealer AI
func dealer_turn():
	print("Dealer's turn - revealing all dealer cards")
	
	# First reveal all dealer cards
	reveal_dealer_cards()
	
	# Update the display with the dealer's true score
	update_score_display()
	
	# Dealer draws until reaching at least 17
	var dealer_value = calculate_hand_value(dealer_hand)
	print("Dealer's initial value: " + str(dealer_value))
	
	while dealer_value < 17:
		print("Dealer draws a card (value below 17)")
		add_card_to_hand(dealer_hand, dealer_cards_container, true)
		dealer_value = calculate_hand_value(dealer_hand)
		print("Dealer's new value: " + str(dealer_value))
		
		# Add a slight delay for visual effect
		await get_tree().create_timer(0.5).timeout
	
	# Determine the winner
	determine_winner()

# Check for blackjack at the start of a round
func check_for_blackjack():
	var player_value = calculate_hand_value(player_hand)
	
	if player_value == 21:
		# Flip all dealer cards when checking for blackjack
		reveal_dealer_cards()
		
		var dealer_value = calculate_hand_value(dealer_hand)
		
		if dealer_value == 21:
			end_game("push")  # Both have blackjack, it's a tie
		else:
			end_game("blackjack")  # Player wins with blackjack

# Determine the winner of the round
func determine_winner():
	var player_value = calculate_hand_value(player_hand)
	var dealer_value = calculate_hand_value(dealer_hand)
	
	if player_value > 21:
		end_game("bust")
	elif dealer_value > 21:
		end_game("dealer_bust")
	elif player_value > dealer_value:
		end_game("win")
	elif dealer_value > player_value:
		end_game("lose")
	else:
		end_game("push")  # Tie

func end_game(result):
	game_in_progress = false
	
	reveal_dealer_cards()
	
	var winnings = 0
	var message = ""
	
	match result:
		"blackjack":
			winnings = int(current_bet * 2.5)  # Convert to integer
			message = "Blackjack! You win %d chips." % winnings
		"win":
			winnings = current_bet * 2
			message = "You win %d chips." % winnings
		"dealer_bust":
			winnings = current_bet * 2
			message = "Dealer busts! You win %d chips." % winnings
		"push":
			winnings = current_bet
			message = "Push. Your bet is returned."
		"lose":
			winnings = 0
			message = "Dealer wins. You lose your bet."
		"bust":
			winnings = 0
			message = "Bust! You lose your bet."
		"dealer_blackjack":
			winnings = 0
			message = "Dealer has blackjack. You lose your bet."
	
	# Store the previous bet before resetting current_bet
	previous_bet = current_bet
	
	# Add winnings to player chips
	player_chips += winnings
	
	# Reset current bet to 0 temporarily
	current_bet = 0
	
	# Show result message
	if result_label and is_instance_valid(result_label):
		result_label.text = message
	
	# Reset buttons for next round
	if has_node("UI/ButtonsPanelContainer/ButtonsContainer/GameButtonsContainer/HitButton"):
		get_node("UI/ButtonsPanelContainer/ButtonsContainer/GameButtonsContainer/HitButton").disabled = true
	if has_node("UI/ButtonsPanelContainer/ButtonsContainer/GameButtonsContainer/StandButton"):
		get_node("UI/ButtonsPanelContainer/ButtonsContainer/GameButtonsContainer/StandButton").disabled = true
	if has_node("UI/ButtonsPanelContainer/ButtonsContainer/DealButtonContainer/DealButton"):
		get_node("UI/ButtonsPanelContainer/ButtonsContainer/DealButtonContainer/DealButton").disabled = false
	if has_node("UI/ButtonsPanelContainer/ButtonsContainer/BetButtonsContainer/BetIncreaseButton"):
		get_node("UI/ButtonsPanelContainer/ButtonsContainer/BetButtonsContainer/BetIncreaseButton").disabled = false
	
	# Emit game ended signal
	emit_signal("game_ended", result, winnings)
	
	# Save to Global and update statistics
	var global = get_node_or_null("/root/Global")
	if global:
		global.player_chips = player_chips
		print("Saved chips to Global: ", player_chips)
		
		# Update game statistics
		global.update_blackjack_stats(result, winnings)
	
	# Automatically place the previous bet if the player has enough chips
	await get_tree().create_timer(1.0).timeout  # Short delay for visual effect
	
	if previous_bet > 0 and player_chips >= previous_bet:
		# Place the previous bet automatically
		current_bet = previous_bet
		player_chips -= current_bet
		
		# Update the display
		update_chips_display()
		
		# Enable bet controls (including Decrease button since we have a bet)
		if has_node("UI/ButtonsPanelContainer/ButtonsContainer/BetButtonsContainer/BetDecreaseButton"):
			get_node("UI/ButtonsPanelContainer/ButtonsContainer/BetButtonsContainer/BetDecreaseButton").disabled = false
		
		# Update the message
		if result_label and is_instance_valid(result_label):
			result_label.text = "Previous bet placed: " + str(current_bet) + ". Ready to deal or adjust bet."
	else:
		# If player doesn't have enough chips for the previous bet
		if result_label and is_instance_valid(result_label):
			result_label.text += "\nPlace your bet to start a new hand."
		
		# Make sure Decrease button is disabled (no bet to decrease)
		if has_node("UI/ButtonsPanelContainer/ButtonsContainer/BetButtonsContainer/BetDecreaseButton"):
			get_node("UI/ButtonsPanelContainer/ButtonsContainer/BetButtonsContainer/BetDecreaseButton").disabled = true

# UPDATED back button function to use SceneManager
func _on_back_button_pressed():
	print("Back button pressed - using SceneManager to return to casino floor")
	
	# Save chips to Global singleton first
	var global = get_node_or_null("/root/Global")
	if global:
		global.player_chips = player_chips
		print("Saved " + str(player_chips) + " chips to Global")
	else:
		print("WARNING: Global not found, creating it")
		global = Node.new()
		global.name = "Global"
		global.set_script(load("res://global.gd"))
		global.player_chips = player_chips
		get_tree().root.add_child(global)
	
	# Trigger auto-save before leaving
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager:
		save_manager.save_game()
	
	# Use SceneManager to return to the casino floor - WITH AWAIT
	print("Calling SceneManager.back_to_casino_floor() with await")
	var success = await SceneManager.back_to_casino_floor()
	
	if !success:
		print("ERROR: Failed to return to casino floor using SceneManager")
		# Show error to user
		if result_label and is_instance_valid(result_label):
			result_label.text = "Error returning to casino. Please restart."
	else:
		print("Successfully transitioning to casino floor")
	
	# Function to handle the Exit button press
func _on_exit_button_pressed():
	print("Exit button pressed on blackjack game")
	
	# Save chips to Global singleton first
	var global = get_node_or_null("/root/Global")
	if global:
		global.player_chips = player_chips
		print("Saved " + str(player_chips) + " chips to Global before quitting")
	else:
		print("WARNING: Global not found, creating it")
		global = Node.new()
		global.name = "Global"
		global.set_script(load("res://global.gd"))
		global.player_chips = player_chips
		get_tree().root.add_child(global)
	
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
	
func reveal_dealer_cards():
	print("Revealing all dealer cards")
	# Make sure all dealer cards are face up
	for card in dealer_hand:
		if not card.face_up:
			card.flip()
	# Update score display with all cards now visible
	update_score_display()
