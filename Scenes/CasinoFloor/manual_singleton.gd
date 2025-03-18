extends Node

# A helper class to ensure global state persists
# Add this to your main scene (title_screen or casino_floor)

func _ready():
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

# Helper function to get Global from anywhere
static func get_global():
	# Try to get the node directly first
	var root = Engine.get_main_loop().root
	if root.has_node("Global"):
		return root.get_node("Global")
	
	return null
