class_name CardUI
extends Control

signal card_pressed(card: CardUI)

## On-screen card size. Matches the face-sheet cell aspect (~128:237).
const CARD_SIZE := Vector2(120, 223)

@onready var texture_rect: TextureRect = $TextureRect

## One cropped card back. Assign an AtlasTexture after cutting a region
## from assets/cards/cards-back.png in the Godot inspector.
@export var back_texture: Texture2D

var data: CardData:
	set(new_data):
		data = new_data
		_update_visuals()

var is_face_up: bool = true:
	set(value):
		is_face_up = value
		_update_visuals()


func _ready() -> void:
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	_update_visuals()


func _update_visuals() -> void:
	if not is_node_ready() or texture_rect == null or data == null:
		return
	if is_face_up:
		texture_rect.texture = data.texture
	else:
		# Face comes from DeckManager (data.texture). The back is a separate
		# AtlasTexture — do not assign the full cards-back.png sheet here.
		texture_rect.texture = back_texture


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# A mobile tap arrives as a left mouse button as well.
		if event.button_index == MOUSE_BUTTON_LEFT:
			card_pressed.emit(self)
			accept_event()
