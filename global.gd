extends Node
# Global variables
var player_chips = 1000  # Default starting chips
var save_data = null  # Will hold the full save data when loaded
var games_played = 0  # Counter for total games played

# Statistics for individual games
var blackjack_stats = {
	"games_played": 0,
	"wins": 0,
	"losses": 0,
	"pushes": 0,
	"blackjacks": 0,
	"biggest_win": 0
}

# Statistics for slots game
var slots_stats = {
	"games_played": 0,
	"total_winnings": 0,
	"biggest_win": 0,
	"total_free_spins_won": 0,
	"wild_combinations": 0
}

# Debug information printing
func _ready():
	print("Global singleton initialized with " + str(player_chips) + " chips")
	
	# Connect to SceneManager signals (if applicable)
	if get_node_or_null("/root/SceneManager"):
		SceneManager.connect("scene_changed", _on_scene_changed)

# Called when a scene change happens
func _on_scene_changed(new_scene):
	print("Global: Scene changed notification received")
	
	# Auto-save when leaving a game scene
	if new_scene and new_scene.scene_file_path.contains("casino_floor"):
		print("Global: Detected return to casino floor, triggering autosave")
		
		# If SaveManager exists, trigger an autosave
		var save_manager = get_node_or_null("/root/SaveManager")
		if save_manager:
			# Add stats to the save
			var additional_data = {
				"games_played": games_played,
				"blackjack_stats": blackjack_stats,
				"slots_stats": slots_stats
			}
			save_manager.save_game(additional_data)

# Function to modify player chips
func add_chips(amount):
	player_chips += amount
	player_chips = int(player_chips)  # Ensure it's an integer
	print("Added " + str(int(amount)) + " chips, new total: " + str(int(player_chips)))
	return player_chips

# Function to set player chips to a specific value
func set_chips(amount):
	player_chips = int(amount)  # Convert to integer
	print("Set chips to " + str(int(player_chips)))
	return player_chips

# Update blackjack game statistics
func update_blackjack_stats(result, winnings):
	blackjack_stats["games_played"] += 1
	
	match result:
		"win", "dealer_bust":
			blackjack_stats["wins"] += 1
		"blackjack":
			blackjack_stats["wins"] += 1
			blackjack_stats["blackjacks"] += 1
		"push":
			blackjack_stats["pushes"] += 1
		"lose", "bust", "dealer_blackjack":
			blackjack_stats["losses"] += 1
	
	# Track biggest win (convert to integer)
	winnings = int(winnings)
	if winnings > blackjack_stats["biggest_win"]:
		blackjack_stats["biggest_win"] = winnings
	
	# Update total games played
	games_played += 1
	
	print("Updated blackjack stats: ", blackjack_stats)

# Update slots game statistics
func update_slots_stats(_result, winnings, free_spins=0, wilds_used=0):
	# Initialize slots_stats if it doesn't exist yet
	if !slots_stats:
		slots_stats = {
			"games_played": 0,
			"total_winnings": 0,
			"biggest_win": 0,
			"total_free_spins_won": 0,
			"wild_combinations": 0
		}
	
	slots_stats["games_played"] += 1
	slots_stats["total_winnings"] += winnings
	
	if winnings > slots_stats["biggest_win"]:
		slots_stats["biggest_win"] = winnings
	
	if free_spins > 0:
		slots_stats["total_free_spins_won"] += free_spins
	
	if wilds_used > 0:
		slots_stats["wild_combinations"] += wilds_used
	
	# Update total games played
	games_played += 1
	
	print("Updated slots stats: ", slots_stats)
