# deck_manager.gd
extends Node

var deck: Array[CardData] = []

# Загружаем наш спрайт-лист
const SPRITESHEET = preload("res://assets/cards/card-deck.png") 

# Размеры картинки, которую мы сгенерировали ранее (1536x1024)
# Сетка 13 колонок (номиналы от 2 до Туза) на 4 ряда (масти)
const COLS := 13
const ROWS := 4

func _ready() -> void:
	generate_deck()
	shuffle_deck()

func generate_deck() -> void:
	deck.clear()
	
	var suits = ["Spades", "Hearts", "Diamonds", "Clubs"]
	var ranks = ["Ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King"]
	
	# Считаем размер одной карты на спрайт-листе
	var card_width: float = float(SPRITESHEET.get_width()) / COLS
	var card_height: float = float(SPRITESHEET.get_height()) / ROWS
	
	for row in range(ROWS):
		var current_suit = suits[row]
		
		for col in range(COLS):
			var current_rank = ranks[col]
			
			# Рассчитываем силу карты для Блекджека
			var val := 0
			if current_rank in ["Jack", "Queen", "King"]:
				val = 10
			elif current_rank == "Ace":
				val = 11
			else:
				val = current_rank.to_int()
			
			# Автоматически вырезаем нужную карту из спрайт-листа
			var atlas_tex := AtlasTexture.new()
			atlas_tex.atlas = SPRITESHEET
			# Задаем область вырезания (X, Y, Ширина, Высота)
			atlas_tex.region = Rect2(col * card_width, row * card_height, card_width, card_height)
			
			# Создаем ресурс карты
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
