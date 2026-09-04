class_name CardUI
extends Control

signal card_pressed(card: CardUI)

## On-screen slot. Must match tools/generate_face_sheet.py cell size (1:1 pixels).
const CARD_SIZE := Vector2(120, 180)
const DEAL_SECONDS := 0.28
const FLIP_SECONDS := 0.12

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

## After the deal flight, flip this card if it belongs face up.
var reveal_when_dealt: bool = false


func _ready() -> void:
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	pivot_offset = CARD_SIZE * 0.5
	_update_visuals()


## Fly from the shoe to a hand slot. The card is visible only during this flight.
func animate_deal_from(from_global: Vector2, to_global: Vector2) -> void:
	top_level = true
	global_position = from_global
	modulate.a = 1.0
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "global_position", to_global, DEAL_SECONDS)
	await tween.finished
	if not is_inside_tree():
		return
	top_level = false
	global_position = to_global


## Turn the card face up with a short scale flip.
func animate_flip_up() -> void:
	if is_face_up:
		return
	pivot_offset = size * 0.5
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2(0.01, 1), FLIP_SECONDS)
	tween.tween_callback(func() -> void: is_face_up = true)
	tween.tween_property(self, "scale", Vector2.ONE, FLIP_SECONDS)
	await tween.finished


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
