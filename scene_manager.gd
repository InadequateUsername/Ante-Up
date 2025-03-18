extends Node

# scene_manager.gd
# A singleton to manage scene transitions throughout the game
# Place this script at res://scene_manager.gd and add it to your AutoLoad in Project Settings

# Dictionary of scene paths for easy reference and maintenance
var scene_paths = {
	"title_screen": "res://Scenes/TitleScreen/title_screen.tscn",
	"casino_floor": "res://Scenes/CasinoFloor/casino_floor.tscn",
	"blackjack": "res://Scenes/Games/Blackjack/blackjack.tscn",
	"poker": "res://Scenes/Games/Poker/poker.tscn", # For future implementation
	"slots": "res://Scenes/Games/Slots/slots.tscn", # For future implementation
	"cashier_booth": "res://Scenes/CashierBooth/cashier_booth.tscn" # For future implementation
}

# Current scene being displayed
var current_scene = null

# Signals for scene transitions
signal scene_changing(from_scene, to_scene)
signal scene_changed(new_scene)
signal transition_failed(error_code, scene_path)

# Initialize the SceneManager
func _ready():
	print("SceneManager: Initializing...")
	
	# Get the current scene as a starting point
	current_scene = get_tree().current_scene
	
	# Validate all scene paths at startup for early error detection
	_validate_scene_paths()
	
	print("SceneManager: Initialized successfully")

# Validate that all scene paths in the dictionary actually exist
func _validate_scene_paths():
	print("SceneManager: Validating scene paths...")
	var missing_scenes = []
	
	for key in scene_paths:
		var path = scene_paths[key]
		if !ResourceLoader.exists(path):
			push_warning("SceneManager: Scene path does not exist: " + path)
			missing_scenes.append(key)
	
	if missing_scenes.size() > 0:
		push_warning("SceneManager: " + str(missing_scenes.size()) + " scenes are missing!")
	else:
		print("SceneManager: All scene paths valid")

# Main function to change scenes by key name
func change_scene(scene_key):
	# Check if the scene key exists
	if !scene_paths.has(scene_key):
		push_error("SceneManager: Unknown scene key: " + scene_key)
		emit_signal("transition_failed", ERR_DOES_NOT_EXIST, scene_key)
		return false
	
	# Get the path
	var scene_path = scene_paths[scene_key]
	
	# Change to the scene using the helper function
	await _change_scene_to_file(scene_path)

# Helper function to change scenes by direct path
func change_scene_by_path(scene_path):
	# Just pass through to the helper function
	await _change_scene_to_file(scene_path)

# Internal function to handle the actual scene change
func _change_scene_to_file(scene_path):
	print("SceneManager: Changing scene to: " + scene_path)
	
	# Check if the scene exists
	if !ResourceLoader.exists(scene_path):
		push_error("SceneManager: Scene does not exist at path: " + scene_path)
		emit_signal("transition_failed", ERR_FILE_NOT_FOUND, scene_path)
		return false
	
	# For future use - emit signal before changing scene
	emit_signal("scene_changing", current_scene, scene_path)
	
	# Attempt to change the scene
	var error = get_tree().change_scene_to_file(scene_path)
	
	if error != OK:
		push_error("SceneManager: Failed to change scene. Error code: " + str(error))
		emit_signal("transition_failed", error, scene_path)
		return false
	
	# Update the current scene reference
	await get_tree().process_frame  # Wait for the scene to change
	current_scene = get_tree().current_scene
	
	# Success - emit signal
	emit_signal("scene_changed", current_scene)
	print("SceneManager: Scene changed successfully to " + scene_path)
	return true

# Add a new scene to the scene_paths dictionary
func register_scene(scene_key, scene_path):
	if scene_paths.has(scene_key):
		push_warning("SceneManager: Overwriting existing scene key: " + scene_key)
	
	scene_paths[scene_key] = scene_path
	print("SceneManager: Registered scene '" + scene_key + "' at path: " + scene_path)
	
	# Validate the new path
	if !ResourceLoader.exists(scene_path):
		push_warning("SceneManager: Newly registered scene path does not exist: " + scene_path)
		return false
	return true

# Get the current scene path
func get_current_scene_path():
	if current_scene:
		return current_scene.scene_file_path
	return ""

# Check if a scene exists before trying to load it
func does_scene_exist(scene_key):
	if !scene_paths.has(scene_key):
		return false
	
	return ResourceLoader.exists(scene_paths[scene_key])

# For debugging - print all available scenes
func print_available_scenes():
	print("SceneManager: Available scenes:")
	for key in scene_paths:
		var exists = ResourceLoader.exists(scene_paths[key])
		var status = "OK" if exists else "MISSING"
		print("  - " + key + ": " + scene_paths[key] + " [" + status + "]")

# Special handler for returning to the previous scene - can be expanded in the future
func back_to_casino_floor():
	print("SceneManager: Returning to casino floor")
	await change_scene("casino_floor")
