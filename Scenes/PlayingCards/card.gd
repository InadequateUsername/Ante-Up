extends Node2D

# Card properties
var suit = ""
var value = ""
var face_up = true
var back_color = "red"  # or "blue" for the card back color

# Reference to the sprite node - DON'T use @onready here
var sprite = null
var color_rect = null

# Called when the node enters the scene tree for the first time
func _ready():
	# Get references to child nodes
	sprite = get_node_or_null("CardSprite")
	color_rect = get_node_or_null("ColorRect")
	
	if sprite == null:
		print("ERROR: CardSprite node not found!")
	if color_rect == null:
		print("ERROR: ColorRect node not found!")

# Initialize the card
func init(card_suit, card_value, is_face_up = true, card_back_color = "red"):
	suit = card_suit
	value = card_value
	face_up = is_face_up
	back_color = card_back_color
	print("Initializing card: " + card_suit + "_" + value + ", face_up=" + str(is_face_up))
	
	# Initialize references to child nodes if not already done
	if sprite == null:
		sprite = get_node_or_null("CardSprite")
	if color_rect == null:
		color_rect = get_node_or_null("ColorRect")
	
	# Now update the appearance
	update_appearance()
	return self

# Update the card's appearance based on its properties
func update_appearance():
	# Make sure sprite reference is valid
	if sprite == null:
		sprite = get_node_or_null("CardSprite")
		if sprite == null:
			print("ERROR: CardSprite node not found in update_appearance!")
			return
			
	# Make sure color_rect reference is valid
	if color_rect == null:
		color_rect = get_node_or_null("ColorRect")
		if color_rect == null:
			print("ERROR: ColorRect node not found in update_appearance!")
			# Continue anyway, we can still show the sprite
	
	if face_up:
		# Load the front face texture
		var texture_path = "res://Assets/Cards/%s_%s.png" % [suit, value]
		print("Attempting to load texture: " + texture_path)
		
		var texture = load(texture_path)
		if texture:
			sprite.texture = texture
			sprite.visible = true
			if color_rect != null:
				color_rect.visible = false
			print("Loaded face up card texture: " + texture_path)
		else:
			print("Failed to load texture: " + texture_path + " - using color fallback")
			show_color_fallback()
	else:
		# Load the card back texture
		var back_texture_path = "res://Assets/Cards/back_%s.png" % [back_color]
		print("Attempting to load texture: " + back_texture_path)
		
		var back_texture = load(back_texture_path)
		if back_texture:
			sprite.texture = back_texture
			sprite.visible = true
			if color_rect != null:
				color_rect.visible = false
			print("Loaded face down card texture: " + back_texture_path)
		else:
			print("Failed to load back texture: " + back_texture_path + " - using color fallback")
			show_color_fallback()

# Fallback method to show colored rectangles instead of textures
func show_color_fallback():
	# Make sure we have necessary references
	if sprite == null:
		sprite = get_node_or_null("CardSprite")
	if color_rect == null:
		color_rect = get_node_or_null("ColorRect")
	
	# Check again after trying to get references
	if sprite == null or color_rect == null:
		print("ERROR: Required nodes missing for fallback display")
		return
		
	sprite.visible = false
	color_rect.visible = true
	
	if face_up:
		# Show a unique color based on suit and value for face up cards
		var r = 0.5
		var g = 0.5
		var b = 0.5
		
		# Set color based on suit
		if suit == "hearts":
			r = 1.0
			g = 0.2
			b = 0.2
		elif suit == "diamonds":
			r = 1.0
			g = 0.5
			b = 0.0
		elif suit == "clubs":
			r = 0.2
			g = 0.2
			b = 0.2
		elif suit == "spades":
			r = 0.2
			g = 0.2
			b = 0.7
		
		# Adjust brightness based on card value
		var brightness = (float(get_value()) / 11.0) * 0.5
		r = min(r + brightness, 1.0)
		g = min(g + brightness, 1.0)
		b = min(b + brightness, 1.0)
		
		color_rect.color = Color(r, g, b, 1.0)
		
		# Add a label to show what card this is
		var label = get_node_or_null("CardLabel")
		if not label:
			label = Label.new()
			label.name = "CardLabel"
			add_child(label)
		
		label.text = value + " of " + suit.capitalize()
		label.position = Vector2(10, 50)
		
		print("Showing face up card (color fallback): " + label.text)
	else:
		# Use a standard red for card backs
		color_rect.color = Color(0.8, 0.1, 0.1, 1.0)
		
		# Remove or hide the label for face down cards
		var label = get_node_or_null("CardLabel")
		if label:
			label.queue_free()
		
		print("Showing face down card (color fallback)")

# Flip the card
func flip():
	print("Flipping card from " + str(face_up) + " to " + str(!face_up) + " - " + get_card_name())
	face_up = !face_up
	
	# Add animation for flipping
	var flip_tween = create_tween()
	flip_tween.tween_property(self, "scale:x", 0, 0.15)
	flip_tween.tween_callback(func(): update_appearance())
	flip_tween.tween_property(self, "scale:x", 1, 0.15)

# Get the card's value (for scoring)
func get_value():
	match value:
		"A":
			return 11  # Ace can be 1 or 11 in Blackjack (handled by the game logic)
		"K", "Q", "J":
			return 10
		"10":
			return 10
		_:
			return int(value)  # 2-9 are worth their face value

# Get a string representation of the card
func get_card_name():
	return value + " of " + suit.capitalize()

# Set card position with optional animation
func set_position_animated(target_position, animation_time = 0.5):
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, animation_time)
	tween.play()

# Rotate card to a specific angle (in degrees)
func rotate_to(angle_degrees, animation_time = 0.5):
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees", angle_degrees, animation_time)
	tween.play()
