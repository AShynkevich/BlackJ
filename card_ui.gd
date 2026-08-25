class_name CardUI
extends Control

signal card_pressed(card: CardUI)

@onready var texture_rect: TextureRect = $TextureRect # Нод для отображения лица карты

var data: CardData:
	set(new_data):
		data = new_data
		_update_visuals()

var is_face_up: bool = true

func _update_visuals() -> void:
	if not is_node_ready() or not data:
		return
	if is_face_up:
		texture_rect.texture = data.texture
	else:
		texture_rect.texture = preload("res://assets/cards/cards-back.png") 

# Обработка нажатий на мобильном экране
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT: # На мобилках тап тоже считывается как левая кнопка мыши
			card_pressed.emit(self)
			accept_event() 
