extends Node

# A helper class to ensure global state persists
# This class is now updated to work with SceneManager
# Place this in your scenes to ensure Global exists

func _ready():
	print("ManualSingleton: Checking for Global singleton")
	
	# Check if Global singleton already exists
	if not get_node_or_null("/root/Global"):
		print("Creating Global singleton")
		# Create a new Global node
		var global = Node.new()
		global.name = "Global"
		global.set_script(load("res://global.gd"))
		# Add it to the root and make it persistent
		get_tree().root.add_child(global)
		get_tree().root.move_child(global, 0)  # Move to first position
	else:
		print("Global singleton already exists")
	
	# Also check for SceneManager
	if not get_node_or_null("/root/SceneManager"):
		push_warning("WARNING: SceneManager singleton not found! Scene transitions may not work properly.")
		push_warning("Make sure SceneManager is properly set up in your Project Settings > AutoLoad.")

# Helper function to get Global from anywhere
static func get_global():
	# Try to get the node directly first
	var root = Engine.get_main_loop().root
	if root.has_node("Global"):
		return root.get_node("Global")
	
	return null
