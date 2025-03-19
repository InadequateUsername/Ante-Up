extends Control

# Preload needed scenes
var card_scene = preload("res://Scenes/PlayingCards/card.tscn")

# Game state variables
var current_bet = 0
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
@onready var chips_label = $UI/ChipsContainer/ChipsAmount
@onready var bet_label = $UI/BetContainer/BetAmount

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
	var back_button = $UI/BackButton
	if back_button:
		# Disconnect any existing connections to avoid duplicates
		if back_button.is_connected("pressed", Callable(self, "_on_back_button_pressed")):
			back_button.disconnect("pressed", Callable(self, "_on_back_button_pressed"))
		# Connect back button directly
		back_button.connect("pressed", _on_back_button_pressed)
		print("Back button connected successfully")
	else:
		print("CRITICAL: Back button not found at UI/BackButton!")
	
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
	var deal_button = $UI/ButtonsContainer/DealButton
	if deal_button:
		if deal_button.is_connected("pressed", Callable(self, "_on_deal_button_pressed")):
			deal_button.disconnect("pressed", Callable(self, "_on_deal_button_pressed"))
		deal_button.connect("pressed", _on_deal_button_pressed)
	
	var hit_button = $UI/ButtonsContainer/HitButton
	if hit_button:
		if hit_button.is_connected("pressed", Callable(self, "_on_hit_button_pressed")):
			hit_button.disconnect("pressed", Callable(self, "_on_hit_button_pressed"))
		hit_button.connect("pressed", _on_hit_button_pressed)
	
	var stand_button = $UI/ButtonsContainer/StandButton
	if stand_button:
		if stand_button.is_connected("pressed", Callable(self, "_on_stand_button_pressed")):
			stand_button.disconnect("pressed", Callable(self, "_on_stand_button_pressed"))
		stand_button.connect("pressed", _on_stand_button_pressed)
	
	var bet_increase_button = $UI/ButtonsContainer/BetIncreaseButton
	if bet_increase_button:
		if bet_increase_button.is_connected("pressed", Callable(self, "_on_bet_increase_pressed")):
			bet_increase_button.disconnect("pressed", Callable(self, "_on_bet_increase_pressed"))
		bet_increase_button.connect("pressed", _on_bet_increase_pressed)
	
	var bet_decrease_button = $UI/ButtonsContainer/BetDecreaseButton
	if bet_decrease_button:
		if bet_decrease_button.is_connected("pressed", Callable(self, "_on_bet_decrease_pressed")):
			bet_decrease_button.disconnect("pressed", Callable(self, "_on_bet_decrease_pressed"))
		bet_decrease_button.connect("pressed", _on_bet_decrease_pressed)

# Update UI to display current chips
func update_chips_display():
	if chips_label and is_instance_valid(chips_label):
		chips_label.text = str(player_chips)
	if bet_label and is_instance_valid(bet_label):
		bet_label.text = str(current_bet)
	print("Chips display updated: " + str(player_chips) + " chips, " + str(current_bet) + " bet")

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
	if has_node("UI/ButtonsContainer/HitButton"):
		get_node("UI/ButtonsContainer/HitButton").disabled = true
	if has_node("UI/ButtonsContainer/StandButton"):
		get_node("UI/ButtonsContainer/StandButton").disabled = true
	if has_node("UI/ButtonsContainer/DealButton"):
		get_node("UI/ButtonsContainer/DealButton").disabled = false
	if has_node("UI/ButtonsContainer/BetIncreaseButton"):
		get_node("UI/ButtonsContainer/BetIncreaseButton").disabled = false
	if has_node("UI/ButtonsContainer/BetDecreaseButton"):
		get_node("UI/ButtonsContainer/BetDecreaseButton").disabled = true
	
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
		
	var dealer_value = 0
	var visible_dealer_cards = []
	
	for card in dealer_hand:
		if card.face_up:
			visible_dealer_cards.append(card)
	
	dealer_value = calculate_hand_value(visible_dealer_cards)
	
	if dealer_hand.size() > 0 and !dealer_hand[0].face_up:
		dealer_score_label.text = "Dealer: ?"
	else:
		dealer_score_label.text = "Dealer: " + str(dealer_value)

# Change bet amount
func _on_bet_increase_pressed():
	if player_chips >= 100 and not game_in_progress:
		current_bet += 100
		player_chips -= 100
		update_chips_display()
		if has_node("UI/ButtonsContainer/BetDecreaseButton"):
			get_node("UI/ButtonsContainer/BetDecreaseButton").disabled = false
		if has_node("UI/ButtonsContainer/DealButton"):
			get_node("UI/ButtonsContainer/DealButton").disabled = false

func _on_bet_decrease_pressed():
	if current_bet >= 100 and not game_in_progress:
		current_bet -= 100
		player_chips += 100
		update_chips_display()
		
		if current_bet <= 0:
			if has_node("UI/ButtonsContainer/BetDecreaseButton"):
				get_node("UI/ButtonsContainer/BetDecreaseButton").disabled = true
			if has_node("UI/ButtonsContainer/DealButton"):
				get_node("UI/ButtonsContainer/DealButton").disabled = true

# Start a new round
func _on_deal_button_pressed():
	if current_bet > 0:
		game_in_progress = true
		
		# Clear any previous cards
		clear_cards()
		
		# Deal initial cards
		add_card_to_hand(player_hand, player_cards_container)
		add_card_to_hand(dealer_hand, dealer_cards_container, false)  # Dealer's first card is face down
		add_card_to_hand(player_hand, player_cards_container)
		add_card_to_hand(dealer_hand, dealer_cards_container)
		
		update_score_display()
		
		# Disable betting buttons during game
		if has_node("UI/ButtonsContainer/BetIncreaseButton"):
			get_node("UI/ButtonsContainer/BetIncreaseButton").disabled = true
		if has_node("UI/ButtonsContainer/BetDecreaseButton"):
			get_node("UI/ButtonsContainer/BetDecreaseButton").disabled = true
		if has_node("UI/ButtonsContainer/DealButton"):
			get_node("UI/ButtonsContainer/DealButton").disabled = true
		
		# Enable game action buttons
		if has_node("UI/ButtonsContainer/HitButton"):
			get_node("UI/ButtonsContainer/HitButton").disabled = false
		if has_node("UI/ButtonsContainer/StandButton"):
			get_node("UI/ButtonsContainer/StandButton").disabled = false
		
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

# Player stands, dealer's turn
func _on_stand_button_pressed():
	if game_in_progress:
		dealer_turn()

# Dealer AI
func dealer_turn():
	# Flip dealer's first card
	dealer_hand[0].flip()
	update_score_display()
	
	# Dealer draws until reaching at least 17
	var dealer_value = calculate_hand_value(dealer_hand)
	while dealer_value < 17:
		add_card_to_hand(dealer_hand, dealer_cards_container)
		dealer_value = calculate_hand_value(dealer_hand)
		
		# Add a slight delay for visual effect (in a real game)
		await get_tree().create_timer(0.5).timeout
	
	# Determine the winner
	determine_winner()

# Check for blackjack at the start of a round
func check_for_blackjack():
	var player_value = calculate_hand_value(player_hand)
	
	if player_value == 21:
		# Flip dealer's first card
		dealer_hand[0].flip()
		update_score_display()
		
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

# End the game with a given result
func end_game(result):
	game_in_progress = false
	
	var winnings = 0
	var message = ""
	
	match result:
		"blackjack":
			winnings = current_bet * 2.5
			message = "Blackjack! You win " + str(winnings) + " chips."
		"win":
			winnings = current_bet * 2
			message = "You win " + str(winnings) + " chips."
		"dealer_bust":
			winnings = current_bet * 2
			message = "Dealer busts! You win " + str(winnings) + " chips."
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
	
	player_chips += winnings
	current_bet = 0
	update_chips_display()
	
	# Show result message
	if result_label and is_instance_valid(result_label):
		result_label.text = message
	
	# Reset buttons for next round
	if has_node("UI/ButtonsContainer/HitButton"):
		get_node("UI/ButtonsContainer/HitButton").disabled = true
	if has_node("UI/ButtonsContainer/StandButton"):
		get_node("UI/ButtonsContainer/StandButton").disabled = true
	if has_node("UI/ButtonsContainer/DealButton"):
		get_node("UI/ButtonsContainer/DealButton").disabled = false
	if has_node("UI/ButtonsContainer/BetIncreaseButton"):
		get_node("UI/ButtonsContainer/BetIncreaseButton").disabled = false
	
	# Emit game ended signal
	emit_signal("game_ended", result, winnings)
	
	# Save to Global and update statistics
	var global = get_node_or_null("/root/Global")
	if global:
		global.player_chips = player_chips
		print("Saved chips to Global: ", player_chips)
		
		# Update game statistics
		global.update_blackjack_stats(result, winnings)

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
