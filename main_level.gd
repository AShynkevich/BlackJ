extends Control

const STARTING_CREDIT := 100
const CARD_SCENE := preload("res://card_ui.tscn")

@export var bet_amounts: Array[int] = [10, 25, 50]
@export var bet_button_size := Vector2(100, 64)
@export var opening_cards_each: int = 2
@export var hide_dealer_last_card: bool = true

var credit: int = 0
var selected_bet: int = 0
var locked_bet: int = 0
var player_hand: Array[CardData] = []
var dealer_hand: Array[CardData] = []
var bet_buttons: Array[Button] = []

@onready var credit_label: Label = $CreditLabel
@onready var bet_label: Label = $BetLabel
@onready var credit_dialog: ColorRect = $CreditDialog
@onready var deck_pile: Control = $DeckPile
@onready var bet_panel: HBoxContainer = $BetPanel
@onready var deal_button: Button = $BetPanel/DealButton
@onready var dealer_hand_box: HBoxContainer = $DealerHand
@onready var player_hand_box: HBoxContainer = $PlayerHand
@onready var deck_manager: Node = $DeckManager


func _ready() -> void:
	_build_bet_buttons()
	credit = 0
	selected_bet = 0
	locked_bet = 0
	credit_label.visible = false
	bet_label.visible = false
	deck_pile.visible = false
	bet_panel.visible = false
	credit_dialog.visible = true
	_refresh_bet_buttons()


func _build_bet_buttons() -> void:
	bet_buttons.clear()
	for amount in bet_amounts:
		var button := _make_bet_button(amount)
		button.pressed.connect(_on_bet_chosen.bind(amount))
		bet_panel.add_child(button)
		bet_panel.move_child(button, deal_button.get_index())
		bet_buttons.append(button)


func _make_bet_button(amount: int) -> Button:
	var button := Button.new()
	button.text = "$%d" % amount
	button.custom_minimum_size = bet_button_size
	for style_name in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(
			style_name,
			deal_button.get_theme_stylebox(style_name)
		)
	button.add_theme_color_override("font_color", deal_button.get_theme_color("font_color"))
	button.add_theme_font_size_override("font_size", deal_button.get_theme_font_size("font_size"))
	return button


func _on_credit_ok_pressed() -> void:
	credit = STARTING_CREDIT
	_refresh_credit_label()
	credit_label.visible = true
	bet_label.visible = true
	deck_pile.visible = true
	bet_panel.visible = true
	credit_dialog.visible = false
	_refresh_bet_buttons()


func _on_bet_chosen(amount: int) -> void:
	if amount > credit:
		return
	selected_bet = amount
	_refresh_bet_buttons()


func _on_deal_pressed() -> void:
	if selected_bet <= 0 or selected_bet > credit:
		return
	_lock_bet_and_deal()


func _lock_bet_and_deal() -> void:
	locked_bet = selected_bet
	credit -= locked_bet
	selected_bet = 0
	bet_panel.visible = false
	_refresh_credit_label()
	_refresh_bet_label()
	_deal_opening_hands()


func _deal_opening_hands() -> void:
	# Each round: one card to the player, then one to the dealer.
	# The dealer's last card is the hole card when hide_dealer_last_card is set.
	for i in opening_cards_each:
		_deal_to(player_hand, player_hand_box, true)
		var dealer_face_up := not hide_dealer_last_card or i < opening_cards_each - 1
		_deal_to(dealer_hand, dealer_hand_box, dealer_face_up)


func _deal_to(hand: Array[CardData], hand_box: HBoxContainer, face_up: bool) -> void:
	var card_data: CardData = deck_manager.draw_card()
	if card_data == null:
		return
	hand.append(card_data)
	var card := CARD_SCENE.instantiate() as CardUI
	hand_box.add_child(card)
	card.is_face_up = face_up
	card.data = card_data


func _refresh_credit_label() -> void:
	credit_label.text = "Credit: $%d" % credit


func _refresh_bet_label() -> void:
	var shown_bet := locked_bet if locked_bet > 0 else selected_bet
	bet_label.text = "Bet: $%d" % shown_bet


func _refresh_bet_buttons() -> void:
	for i in bet_buttons.size():
		var amount := bet_amounts[i]
		var button := bet_buttons[i]
		button.disabled = amount > credit
		button.modulate = Color(1.15, 1.1, 0.85, 1) if amount == selected_bet else Color.WHITE
	deal_button.disabled = selected_bet <= 0 or selected_bet > credit
	_refresh_bet_label()


func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")
