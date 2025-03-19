extends Node

# Save system for casino game
# Add this script to AutoLoad as "SaveManager"

signal save_completed(success, message)
signal save_loaded(success, message)

const SAVE_FILE_PATH = "user://ante_up_save.dat"
const BACKUP_SAVE_PATH = "user://ante_up_save_backup.dat"

# Basic structure of save data
var default_save_data = {
	"player_chips": 1000,
	"timestamp": 0,
	"last_scene": "title_screen",
	"games_played": 0,
	"blackjack_stats": {
		"games_played": 0,
		"wins": 0,
		"losses": 0,
		"pushes": 0,
		"blackjacks": 0,
		"biggest_win": 0
	},
	"version": "1.0"
}

# Save game data - simplified without threading
func save_game(additional_data = {}):
	print("SaveManager: Saving game...")
	var success = _perform_save(additional_data)
	if success:
		print("SaveManager: Game saved successfully")
	else:
		push_warning("SaveManager: Save failed")
	
	return success

# Actual save function
func _perform_save(additional_data):
	# Get the current Global data
	var global_node = get_node_or_null("/root/Global")
	if not global_node:
		push_error("SaveManager: Cannot save - Global singleton not found")
		emit_signal("save_completed", false, "Global singleton not found")
		return false
	
	# Create save data dictionary
	var save_data = default_save_data.duplicate(true)
	
	# Update with current values from Global
	save_data["player_chips"] = global_node.player_chips
	save_data["timestamp"] = Time.get_unix_time_from_system()
	
	# Get current scene if available
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager and scene_manager.current_scene:
		var scene_path = scene_manager.get_current_scene_path()
		for key in scene_manager.scene_paths.keys():
			if scene_manager.scene_paths[key] == scene_path:
				save_data["last_scene"] = key
				break
	
	# Add any additional data passed to the save function
	for key in additional_data:
		save_data[key] = additional_data[key]
	
	# Before writing new save, create a backup of the existing save if it exists
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var existing_save = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if existing_save:
			var backup_save = FileAccess.open(BACKUP_SAVE_PATH, FileAccess.WRITE)
			if backup_save:
				var content = existing_save.get_buffer(existing_save.get_length())
				backup_save.store_buffer(content)
				backup_save.close()
			existing_save.close()
	
	# Now write the actual save file
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if not file:
		var error = FileAccess.get_open_error()
		push_error("SaveManager: Failed to open save file. Error code: " + str(error))
		emit_signal("save_completed", false, "Failed to open save file")
		return false
	
	# Convert save_data to JSON and write to file
	var json_string = JSON.stringify(save_data)
	
	file.store_string(json_string)
	file.close()
	
	print("SaveManager: Game saved successfully")
	emit_signal("save_completed", true, "Game saved successfully")
	return true

# Load the saved game
func load_game():
	print("SaveManager: Loading saved game...")
	
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		push_warning("SaveManager: No save file found")
		emit_signal("save_loaded", false, "No save file found")
		return false
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		var error = FileAccess.get_open_error()
		push_error("SaveManager: Failed to open save file. Error code: " + str(error))
		emit_signal("save_loaded", false, "Failed to open save file")
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("SaveManager: Failed to parse save file JSON. Error: " + json.get_error_message() + " at line " + str(json.get_error_line()))
		emit_signal("save_loaded", false, "Failed to parse save file")
		return false
	
	var save_data = json.get_data()
	
	# Apply the loaded data to Global
	var global_node = get_node_or_null("/root/Global")
	if not global_node:
		push_error("SaveManager: Cannot load - Global singleton not found")
		emit_signal("save_loaded", false, "Global singleton not found")
		return false
	
	# Apply loaded data
	global_node.player_chips = save_data.get("player_chips", default_save_data["player_chips"])
	
	# Store any additional save data in Global for other systems to access
	global_node.save_data = save_data
	
	print("SaveManager: Game loaded successfully")
	emit_signal("save_loaded", true, "Game loaded successfully")
	return true

# Check if a save file exists
func has_save():
	return FileAccess.file_exists(SAVE_FILE_PATH)

# Get save info without loading the whole save
func get_save_info():
	if not has_save():
		return null
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		return null
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return null
	
	var save_data = json.get_data()
	
	# Return just the essential info for displaying
	return {
		"player_chips": save_data.get("player_chips", 0),
		"timestamp": save_data.get("timestamp", 0),
		"games_played": save_data.get("games_played", 0),
		"last_scene": save_data.get("last_scene", "title_screen")
	}

# Delete the save file
func delete_save():
	if has_save():
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove(SAVE_FILE_PATH)
			print("SaveManager: Save file deleted")
			return true
	
	return false

# Format a Unix timestamp for display
func format_timestamp(unix_time):
	var datetime = Time.get_datetime_dict_from_unix_time(unix_time)
	return "%02d/%02d/%d %02d:%02d" % [
		datetime["month"], 
		datetime["day"], 
		datetime["year"], 
		datetime["hour"], 
		datetime["minute"]
	]
