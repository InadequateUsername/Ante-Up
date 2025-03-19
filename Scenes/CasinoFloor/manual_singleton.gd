extends Node

# Manual singleton helper to ensure proper game cleanup
# Place in res://Scripts/Utils/cleanup_manager.gd

var active_dialogs = []

func _ready():
	print("CleanupManager: Initializing...")
	
	# Connect to the tree exiting signal
	get_tree().root.connect("tree_exiting", _on_tree_exiting)
	
	print("CleanupManager: Initialized and connected to tree_exiting signal")

# Register a dialog with the cleanup manager
func register_dialog(dialog):
	if dialog and not active_dialogs.has(dialog):
		active_dialogs.append(dialog)
		print("CleanupManager: Registered dialog: ", dialog.name)
		
		# Connect to dialog's tree_exiting signal to auto-remove it
		if not dialog.is_connected("tree_exiting", Callable(self, "_on_dialog_exiting")):
			dialog.connect("tree_exiting", _on_dialog_exiting.bind(dialog))

# Remove a dialog from the tracking list
func unregister_dialog(dialog):
	if dialog and active_dialogs.has(dialog):
		active_dialogs.erase(dialog)
		print("CleanupManager: Unregistered dialog: ", dialog.name)

# Called when a specific dialog is exiting the tree
func _on_dialog_exiting(dialog):
	unregister_dialog(dialog)

# Force cleanup all active dialogs
func cleanup_all_dialogs():
	print("CleanupManager: Cleaning up all active dialogs...")
	
	# Create a copy of the array to safely iterate while potentially modifying
	var dialogs_to_cleanup = active_dialogs.duplicate()
	
	for dialog in dialogs_to_cleanup:
		if dialog and is_instance_valid(dialog):
			print("CleanupManager: Cleaning up dialog: ", dialog.name)
			# If dialog has a queue_free method, call it
			if dialog.has_method("queue_free"):
				dialog.queue_free()
	
	# Clear the array
	active_dialogs.clear()
	print("CleanupManager: All dialogs cleaned up")

# Called when the application is about to exit
func _on_tree_exiting():
	print("CleanupManager: Application exiting - performing final cleanup")
	cleanup_all_dialogs()
