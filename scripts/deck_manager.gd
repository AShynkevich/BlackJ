extends Node

var deck: Array[CardData] = []

const SPRITESHEET = preload("res://assets/cards/card-deck.png")

# Tight 13x4 face sheet: Ace-King columns, Spades-Hearts-Diamonds-Clubs rows.
const COLS := 13
const ROWS := 4


func _ready() -> void:
	generate_deck()
	shuffle_deck()


func generate_deck() -> void:
	deck.clear()

	var suits = ["Spades", "Hearts", "Diamonds", "Clubs"]
	var ranks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
	var card_width := float(SPRITESHEET.get_width()) / COLS
	var card_height := float(SPRITESHEET.get_height()) / ROWS
	print(card_height)

	for row in range(ROWS):
		var current_suit: String = suits[row]
		for col in range(COLS):
			var current_rank: String = ranks[col]
			var val := 0
			if current_rank in ["J", "Q", "K"]:
				val = 10
			elif current_rank == "A":
				val = 11
			else:
				val = current_rank.to_int()

			var atlas_tex := AtlasTexture.new()
			atlas_tex.atlas = SPRITESHEET
			atlas_tex.region = Rect2(col * card_width, row * card_height, card_width, card_height)
			atlas_tex.filter_clip = true

			var card_data := CardData.new()
			card_data.card_name = current_rank
			card_data.suit = current_suit
			card_data.value = val
			card_data.texture = atlas_tex
			deck.append(card_data)

	print("The deck was generated and cut! Cards number: ", deck.size())


func shuffle_deck() -> void:
	deck.shuffle()
	print("Deck is shuffled.")


func draw_card() -> CardData:
	if deck.is_empty():
		push_error("Cannot draw: the deck is empty.")
		return null
	return deck.pop_back()
