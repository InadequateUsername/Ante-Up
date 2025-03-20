extends Control

# Player variables - synced with Global
var player_chips = 1000
var current_bet = 10
var min_bet = 10
var max_bet = 100

# Game state variables
var free_spins = 0
var current_mode = "normal"  # "normal" or "free_spins"

# Auto-spin variables
var is_auto_spinning = false
var auto_spin_count = 0
var auto_spin_max = 10  # Default number of auto spins
var auto_spin_options = [5, 10, 25, 50, 100]  # Available options for auto-spin
var auto_spin_index = 1  # Default to 10 spins (index 1)
var stop_on_feature = true  # Stop auto-spin when free spins are triggered

# Reel variables
var reels = []
var reel_count = 3
var symbols_per_reel = 3
var is_spinning = false
var spin_speed = 0.1
var stopping_delay = 0.2

# Special indicators
var special_indicators = {
	"free_spin": preload("res://Assets/Slots/sauropodskeleton.png"),
	"wild": preload("res://Assets/Slots/dinosaurbones.png")
}
var show_indicators = true

# Symbol definitions (based on the animal images)
var symbols = [
	"penguin",    # Yellow penguin (Image 1)
	"squid",      # Purple squid (Image 2)
	"tortoise",   # Green tortoise (Image 3)
	"axolotl",    # Blue axolotl (Image 4)
	"bear",       # Brown bear (Image 5)
	"bull",       # Red bull (Image 6)
	"goat",       # Gray goat (Image 7)
	"dinosaurbones",  # Wild symbol
	"sauropodskeleton"  # Free spins symbol
]

# Define the goat as a wild symbol
var wild_symbol = "dinosaurbones"

# Symbol weights (probability distribution)
var symbol_weights = {
	"penguin": 20,
	"squid": 15,
	"tortoise": 15,
	"axolotl": 10,
	"bear": 5,
	"bull": 3,
	"goat": 2,
	"dinosaurbones": 2,
	"sauropodskeleton": 2
}

# Payout table (multipliers for different combinations)
var payouts = {
	"penguin": {1: 2, 2: 5, 3: 10},       # Common, low payout
	"squid": {2: 5, 3: 15},
	"tortoise": {2: 5, 3: 15},
	"axolotl": {2: 8, 3: 20},
	"bear": {2: 10, 3: 50},                # Rare, medium payout
	"bull": {2: 20, 3: 100},               # Very rare, high payout
	"goat": {1: 5, 2: 25, 3: 200},         # Wild symbol - highest payout
	"dinosaurbones": {1: 10, 2: 50, 3: 500},  # New wild symbol - highest payout
	"sauropodskeleton": {1: 0, 2: 0, 3: 0}   # Free spins trigger - no direct payout
}

# Statistics tracking
var slots_stats = {
	"games_played": 0,
	"total_winnings": 0,
	"biggest_win": 0,
	"total_free_spins_won": 0,
	"wild_combinations": 0,
	"auto_spins_used": 0  # New stat for tracking auto-spin usage
}

# Current state of the reels
var current_symbols = []

func _ready():
	print("Slots: _ready function started")
	
	# Get chips and stats from Global singleton
	var global_node = get_node_or_null("/root/Global")
	if global_node:
		player_chips = int(global_node.player_chips)
		print("Found Global, player chips: ", player_chips)
		
		# Load slots stats if available (safely check if property exists)
		if global_node.get("slots_stats") != null:
			slots_stats = global_node.slots_stats
			print("Loaded slots stats from Global")
			if not "auto_spins_used" in slots_stats:
				slots_stats["auto_spins_used"] = 0
				print("Added missing auto_spins_used key to stats")
	else:
		print("WARNING: Global singleton not found! Using default chips value.")
	
	# Initialize reels and references
	initialize_reels()
	
	# Connect button signals
	$MainContainer/ControlsContainer/BetControls/BetDownButton.connect("pressed", _on_bet_down_pressed)
	$MainContainer/ControlsContainer/BetControls/BetUpButton.connect("pressed", _on_bet_up_pressed)
	$MainContainer/ControlsContainer/SpinButton.connect("pressed", _on_spin_pressed)
	$MainContainer/ControlsContainer/MaxBetButton.connect("pressed", _on_max_bet_pressed)
	$MainContainer/HeaderContainer/BackButton.connect("pressed", _on_back_pressed)
	$MainContainer/HeaderContainer/ExitGameButton.connect("pressed", _on_exit_game_pressed)
	
	# Connect auto-spin buttons
	$MainContainer/ControlsContainer/AutoSpinControls/AutoSpinButton.connect("pressed", _on_auto_spin_pressed)
	$MainContainer/ControlsContainer/AutoSpinControls/AutoSpinUpButton.connect("pressed", _on_auto_spin_up_pressed)
	$MainContainer/ControlsContainer/AutoSpinControls/AutoSpinDownButton.connect("pressed", _on_auto_spin_down_pressed)
	$MainContainer/ControlsContainer/AutoSpinControls/StopAutoSpinButton.connect("pressed", _on_stop_auto_spin_pressed)
	
	# Set initial auto-spin values
	update_auto_spin_display()
	
	# Hide stop button initially
	$MainContainer/ControlsContainer/AutoSpinControls/StopAutoSpinButton.visible = false
	
	# Update UI
	update_bet_display()
	update_chips_display()
	update_free_spins_display()
	update_winnings_display("Welcome to Animal Slots!")
	
	print("Slots: Initialization complete")

# Initialize the reels with random symbols
func initialize_reels():
	# Clear any existing symbols
	current_symbols = []
	
	# Get references to the reel containers
	reels = [
		$MainContainer/ReelsContainer/Reel1,
		$MainContainer/ReelsContainer/Reel2,
		$MainContainer/ReelsContainer/Reel3
	]
	
	# Initialize each reel with random symbols
	for i in range(reel_count):
		var reel_symbols = []
		for j in range(symbols_per_reel):
			var symbol = get_random_symbol()
			reel_symbols.append(symbol)
			
			# Get existing TextureRect or create new one
			var symbol_rect
			if reels[i].get_child_count() > j:
				symbol_rect = reels[i].get_child(j)
			else:
				symbol_rect = TextureRect.new()
				symbol_rect.expand = true
				symbol_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				symbol_rect.custom_minimum_size = Vector2(100, 100)
				reels[i].add_child(symbol_rect)
			
			# Set the symbol texture
			symbol_rect.texture = load("res://Assets/Slots/" + symbol + ".png")
			
			# Add indicator if needed
			if symbol == "goat":
				add_indicator_overlay(symbol_rect, "wild")
			elif symbol == "bear" and j == 1:  # Only middle row
				add_indicator_overlay(symbol_rect, "free_spin")
		
		current_symbols.append(reel_symbols)

# Get a random symbol based on weights
func get_random_symbol():
	var total_weight = 0
	for symbol in symbols:
		total_weight += symbol_weights[symbol]
	
	var random_value = randi() % total_weight
	var weight_sum = 0
	
	for symbol in symbols:
		weight_sum += symbol_weights[symbol]
		if random_value < weight_sum:
			return symbol
	
	# Fallback (should never reach here)
	return symbols[0]

# Add an indicator overlay to a symbol
func add_indicator_overlay(parent_rect, indicator_type):
	if !show_indicators:
		return
		
	# Remove any existing overlays first
	for child in parent_rect.get_children():
		if child.is_in_group("indicator_overlay"):
			child.queue_free()
	
	var overlay = TextureRect.new()
	overlay.texture = special_indicators[indicator_type]
	overlay.expand = true
	overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	overlay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay.add_to_group("indicator_overlay")
	
	# Set the overlay to be the same size as the parent
	overlay.custom_minimum_size = parent_rect.custom_minimum_size
	
	# Add the overlay as a child of the symbol TextureRect
	parent_rect.add_child(overlay)

# Update the bet display
func update_bet_display():
	$MainContainer/ControlsContainer/BetControls/BetAmountLabel.text = str(current_bet)

# Update the chips display
func update_chips_display():
	$MainContainer/ChipsPanelContainer/ChipsDisplay/ChipsAmount.text = str(player_chips)

# Update the free spins display
func update_free_spins_display():
	$MainContainer/FreeSpinsPanelContainer/FreeSpinsContainer/FreeSpinsCount.text = str(free_spins)
	
	# Adjust button text based on mode
	if current_mode == "free_spins" and free_spins > 0:
		$MainContainer/ControlsContainer/SpinButton.text = "FREE SPIN"
	else:
		$MainContainer/ControlsContainer/SpinButton.text = "SPIN"

# Update the auto-spin display
func update_auto_spin_display():
	auto_spin_max = auto_spin_options[auto_spin_index]
	$MainContainer/ControlsContainer/AutoSpinControls/AutoSpinCountLabel.text = str(auto_spin_max)

# Update the winnings display
func update_winnings_display(text):
	$MainContainer/WinningsContainer/WinningsLabel.text = text

# Decrease the bet amount
func _on_bet_down_pressed():
	if current_bet > min_bet:
		current_bet -= 5
		update_bet_display()

# Increase the bet amount
func _on_bet_up_pressed():
	if current_bet < max_bet and current_bet < player_chips:
		current_bet += 5
		update_bet_display()

# Set to maximum bet
func _on_max_bet_pressed():
	current_bet = min(max_bet, player_chips)
	update_bet_display()

# Handle spin button press
func _on_spin_pressed():
	if is_spinning:
		return
	
	# Perform a single spin and don't continue auto-spinning
	is_auto_spinning = false
	perform_spin()

# Handle auto-spin button press
func _on_auto_spin_pressed():
	if is_spinning or is_auto_spinning:
		return
	
	# If we're in free spins mode, don't allow auto-spin
	if current_mode == "free_spins":
		update_winnings_display("Cannot auto-spin during free spins mode.")
		return
	
	# If we don't have enough chips for at least one spin, exit
	if player_chips < current_bet:
		update_winnings_display("Not enough chips!")
		return
	
	# Start auto-spinning
	is_auto_spinning = true
	auto_spin_count = auto_spin_max
	
	# Show stop button and hide auto-spin button
	$MainContainer/ControlsContainer/AutoSpinControls/AutoSpinButton.visible = false
	$MainContainer/ControlsContainer/AutoSpinControls/StopAutoSpinButton.visible = true
	
	# Update display
	update_winnings_display("Auto-spinning " + str(auto_spin_count) + " times...")
	
	# Perform the first spin
	perform_spin()
	
	# Update statistics (with safety check)
	if not "auto_spins_used" in slots_stats:
		slots_stats["auto_spins_used"] = 0
	slots_stats["auto_spins_used"] += 1

# Increase auto-spin count
func _on_auto_spin_up_pressed():
	auto_spin_index = min(auto_spin_index + 1, auto_spin_options.size() - 1)
	update_auto_spin_display()

# Decrease auto-spin count
func _on_auto_spin_down_pressed():
	auto_spin_index = max(auto_spin_index - 1, 0)
	update_auto_spin_display()

# Stop auto-spinning
func _on_stop_auto_spin_pressed():
	is_auto_spinning = false
	auto_spin_count = 0
	
	# Show auto-spin button and hide stop button
	$MainContainer/ControlsContainer/AutoSpinControls/AutoSpinButton.visible = true
	$MainContainer/ControlsContainer/AutoSpinControls/StopAutoSpinButton.visible = false
	
	update_winnings_display("Auto-spin stopped.")

# Perform a single spin
func perform_spin():
	if is_spinning:
		return
	
	# Check for free spins or normal mode
	if free_spins > 0:
		current_mode = "free_spins"
		free_spins -= 1
		update_free_spins_display()
		# No bet deduction in free spin mode
		update_winnings_display("Using Free Spin...")
	else:
		current_mode = "normal"
		if player_chips < current_bet:
			update_winnings_display("Not enough chips!")
			
			# Stop auto-spinning if we're out of chips
			if is_auto_spinning:
				_on_stop_auto_spin_pressed()
			return
		
		# Deduct bet from chips in normal mode
		player_chips -= current_bet
		update_chips_display()
		
		if is_auto_spinning:
			auto_spin_count -= 1
			update_winnings_display("Auto-spin " + str(auto_spin_max - auto_spin_count) + 
				" of " + str(auto_spin_max) + "...")
		else:
			update_winnings_display("Spinning...")
	
	# Disable buttons during spin
	is_spinning = true
	$MainContainer/ControlsContainer/SpinButton.disabled = true
	$MainContainer/ControlsContainer/AutoSpinControls/AutoSpinButton.disabled = true
	
	# Play spin sound
	$AudioContainer/SpinSound.play()
	
	# Start spinning animation
	spin_reels()
	
	# Update statistics
	slots_stats["games_played"] += 1

# Animate the spinning reels
func spin_reels():
	# Generate new symbols for each reel (but don't show yet)
	var new_symbols = []
	for i in range(reel_count):
		var reel_symbols = []
		for j in range(symbols_per_reel):
			reel_symbols.append(get_random_symbol())
		new_symbols.append(reel_symbols)
	
	# Animate each reel with slight delay between them
	for i in range(reel_count):
		# Use a timer to create delay between reels
		var timer = get_tree().create_timer(i * stopping_delay)
		timer.timeout.connect(func(): animate_reel(i, new_symbols[i]))

# Animate a single reel
func animate_reel(reel_index, new_symbols):
	# Create a simple animation: cycle through symbols rapidly
	var animation_steps = 10
	
	for step in range(animation_steps):
		# Generate random transition symbols
		for j in range(symbols_per_reel):
			var symbol = get_random_symbol()
			var symbol_rect = reels[reel_index].get_child(j)
			symbol_rect.texture = load("res://Assets/Slots/" + symbol + ".png")
			
			# Remove any existing indicator overlay
			for child in symbol_rect.get_children():
				if child.is_in_group("indicator_overlay"):
					child.queue_free()
		
		# Wait a short time
		await get_tree().create_timer(spin_speed).timeout
	
	# Set the final symbols
	for j in range(symbols_per_reel):
		var symbol_rect = reels[reel_index].get_child(j)
		symbol_rect.texture = load("res://Assets/Slots/" + new_symbols[j] + ".png")
		
		# Add special indicator overlays if needed
		if new_symbols[j] == "goat":
			# Add wild indicator
			add_indicator_overlay(symbol_rect, "wild")
		elif new_symbols[j] == "bear" and j == 1:  # Only middle row
			# Add free spin indicator
			add_indicator_overlay(symbol_rect, "free_spin")
	
	# Update the current symbols
	current_symbols[reel_index] = new_symbols
	
	# If this is the last reel, calculate results
	if reel_index == reel_count - 1:
		await get_tree().create_timer(0.5).timeout
		calculate_win()
		is_spinning = false
		$MainContainer/ControlsContainer/SpinButton.disabled = false
		$MainContainer/ControlsContainer/AutoSpinControls/AutoSpinButton.disabled = false
		
		# Check if we should continue auto-spinning
		if is_auto_spinning and auto_spin_count > 0 and current_mode != "free_spins":
			# Wait a brief moment before next spin
			await get_tree().create_timer(1.0).timeout
			
			if is_auto_spinning:  # Check again in case user stopped during delay
				perform_spin()
		elif is_auto_spinning and (auto_spin_count <= 0 or current_mode == "free_spins"):
			# Auto-spinning complete or free spins triggered
			$MainContainer/ControlsContainer/AutoSpinControls/AutoSpinButton.visible = true
			$MainContainer/ControlsContainer/AutoSpinControls/StopAutoSpinButton.visible = false
			is_auto_spinning = false
			
			if current_mode == "free_spins" and stop_on_feature:
				update_winnings_display("Auto-spin stopped: Free spins triggered!")
			else:
				update_winnings_display("Auto-spin complete!")

# Calculate winning combinations
func calculate_win():
	var winnings = 0
	var win_description = ""
	var free_spins_triggered = false
	var has_wild = false
	
	# Extract middle row (visible symbols)
	var visible_row = []
	for i in range(reel_count):
		visible_row.append(current_symbols[i][1])  # Middle symbol
		if current_symbols[i][1] == wild_symbol:
			has_wild = true
	
	# Check for free spins - 3 sauropodskeleton gives free spins
	if visible_row.count("sauropodskeleton") == 3:
		free_spins += 5
		update_free_spins_display()
		win_description += "3 Saurpod Skeletons: 5 FREE SPINS!\n"
		slots_stats["total_free_spins_won"] += 5
		free_spins_triggered = true
	
	# Calculate payouts for each symbol type
	for symbol in symbols:
		# Skip wild symbol for initial check (we'll check it separately)
		if symbol == wild_symbol:
			continue
		
		var consecutive = 0
		var wilds_used = 0
		
		# Count consecutive symbols from left to right, allowing wilds to substitute
		for i in range(reel_count):
			var current = visible_row[i]
			
			# If exact match or wild symbol, count it
			if current == symbol:
				consecutive += 1
			elif current == wild_symbol:
				consecutive += 1
				wilds_used += 1
			else:
				break
		
		# Check if we have winning combinations in payout table
		if symbol in payouts and consecutive in payouts[symbol]:
			var this_win = current_bet * payouts[symbol][consecutive]
			winnings += this_win
			
			if win_description:
				win_description += "\n"
				
			# Show if wilds were used in the win
			if wilds_used > 0:
				win_description += str(consecutive - wilds_used) + " " + symbol + "s + " + str(wilds_used) + " Wild: " + str(this_win)
				slots_stats["wild_combinations"] += 1
			else:
				win_description += str(consecutive) + " " + symbol + "s: " + str(this_win)
	
	# Check for wild symbol combinations (they pay on their own)
	var wild_count = visible_row.count(wild_symbol)
	if wild_count > 0 and wild_symbol in payouts and wild_count in payouts[wild_symbol]:
		var wild_win = current_bet * payouts[wild_symbol][wild_count]
		winnings += wild_win
		
		if win_description:
			win_description += "\n"
		win_description += str(wild_count) + " " + wild_symbol + "s: " + str(wild_win)
	
	# Update chips, stats, and display
	if winnings > 0:
		# Don't add chips for free spin mode wins, just track stats
		if current_mode == "normal":
			player_chips += winnings
			update_chips_display()
		
		# Update statistics
		slots_stats["total_winnings"] += winnings
		if winnings > slots_stats["biggest_win"]:
			slots_stats["biggest_win"] = winnings
		
		# Show win message
		if current_mode == "free_spins":
			update_winnings_display("Free Spin Win: " + str(winnings) + " chips!\n" + win_description)
		else:
			update_winnings_display("You won " + str(winnings) + " chips!\n" + win_description)
		
		# Play win sound
		$AudioContainer/WinSound.play()
	else:
		if current_mode == "free_spins":
			update_winnings_display("No win on free spin.")
		else:
			update_winnings_display("No win. Try again!")
	
	# If free spins were triggered during auto-spin and stop_on_feature is enabled, stop auto-spinning
	if free_spins_triggered and is_auto_spinning and stop_on_feature:
		is_auto_spinning = false
		auto_spin_count = 0
	
	# Save to Global
	save_to_global()

# Save player data to Global singleton
func save_to_global():
	var global_node = get_node_or_null("/root/Global")
	if global_node:
		# Save chips
		global_node.player_chips = player_chips
		
		# Save slots statistics
		global_node.slots_stats = slots_stats
		
		print("Saved " + str(player_chips) + " chips and stats to Global")

# Return to casino floor
func _on_back_pressed():
	print("Back button pressed - returning to casino floor")
	
	# Make sure auto-spinning is stopped
	is_auto_spinning = false
	
	# Save chips to Global
	save_to_global()
	
	# Trigger autosave
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager:
		print("Autosaving game before returning to casino floor")
		save_manager.save_game()
	
	# Use SceneManager to change to casino floor
	var success = await SceneManager.change_scene("casino_floor")
	if !success:
		print("ERROR: Failed to transition to casino floor")
		SceneManager.change_scene("casino_floor")  # Try again


# Handle exit button press
func _on_exit_game_pressed():
	print("Exit button pressed on slots screen")
	
	# Make sure auto-spinning is stopped
	is_auto_spinning = false
	
	# Save chips to Global
	save_to_global()
	
	# Trigger autosave
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager:
		print("Autosaving game before quitting")
		save_manager.save_game()
	
	# Get the cleanup manager and clean up all dialogs
	var cleanup_manager = get_node_or_null("/root/CleanupManager")
	if cleanup_manager:
		cleanup_manager.cleanup_all_dialogs()
	
	# Add a slight delay to ensure save completes
	print("Quitting game in 0.5 seconds...")
	await get_tree().create_timer(0.5).timeout
	
	# Quit the game
	print("Exiting application")
	get_tree().quit()
