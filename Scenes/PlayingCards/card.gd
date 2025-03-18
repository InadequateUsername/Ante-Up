extends Node2D

# Card properties
var suit = ""
var value = ""
var face_up = true
var back_color = "red"  # or "blue" for the card back color

# Sprite positions in the spritesheet (will need to be adjusted based on your actual spritesheet)
var sprite_positions = {
	"hearts": {
		"A": Vector2(0, 0),
		"2": Vector2(1, 0),
		"3": Vector2(2, 0),
		"4": Vector2(3, 0),
		"5": Vector2(4, 0),
		"6": Vector2(5, 0),
		"7": Vector2(6, 0),
		"8": Vector2(7, 0),
		"9": Vector2(8, 0),
		"10": Vector2(9, 0),
		"J": Vector2(10, 0),
		"Q": Vector2(11, 0),
		"K": Vector2(12, 0)
	},
	"diamonds": {
		"A": Vector2(0, 1),
		"2": Vector2(1, 1),
		"3": Vector2(2, 1),
		"4": Vector2(3, 1),
		"5": Vector2(4, 1),
		"6": Vector2(5, 1),
		"7": Vector2(6, 1),
		"8": Vector2(7, 1),
		"9": Vector2(8, 1),
		"10": Vector2(9, 1),
		"J": Vector2(10, 1),
		"Q": Vector2(11, 1),
		"K": Vector2(12, 1)
	},
	"clubs": {
		"A": Vector2(0, 2),
		"2": Vector2(1, 2),
		"3": Vector2(2, 2),
		"4": Vector2(3, 2),
		"5": Vector2(4, 2),
		"6": Vector2(5, 2),
		"7": Vector2(6, 2),
		"8": Vector2(7, 2),
		"9": Vector2(8, 2),
		"10": Vector2(9, 2),
		"J": Vector2(10, 2),
		"Q": Vector2(11, 2),
		"K": Vector2(12, 2)
	},
	"spades": {
		"A": Vector2(0, 3),
		"2": Vector2(1, 3),
		"3": Vector2(2, 3),
		"4": Vector2(3, 3),
		"5": Vector2(4, 3),
		"6": Vector2(5, 3),
		"7": Vector2(6, 3),
		"8": Vector2(7, 3),
		"9": Vector2(8, 3),
		"10": Vector2(9, 3),
		"J": Vector2(10, 3),
		"Q": Vector2(11, 3),
		"K": Vector2(12, 3)
	},
	"back": {
		"red": Vector2(13, 0),
		"blue": Vector2(13, 1)
	}
}

# Card dimensions
var card_width = 71  # Adjust based on your spritesheet
var card_height = 96  # Adjust based on your spritesheet

# Reference to the sprite node
@onready var sprite = $CardSprite

# Initialize the card
func init(card_suit, card_value, is_face_up = true, card_back_color = "red"):
	suit = card_suit
	value = card_value
	face_up = is_face_up
	back_color = card_back_color
	update_appearance()
	return self

# Update the card's appearance based on its properties
func update_appearance():
	if sprite and sprite.texture:
		var frame_position
		
		if face_up:
			frame_position = sprite_positions[suit][value]
		else:
			frame_position = sprite_positions["back"][back_color]
		
		# Set the region of the spritesheet to display
		sprite.region_rect = Rect2(
			frame_position.x * card_width,
			frame_position.y * card_height,
			card_width,
			card_height
		)

# Flip the card
func flip():
	face_up = !face_up
	update_appearance()

# Get the card's value (for scoring)
func get_value():
	match value:
		"A":
			return 11  # Ace can be 1 or 11 in Blackjack (handled by the game logic)
		"K", "Q", "J", "10":
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
