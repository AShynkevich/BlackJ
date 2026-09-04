extends Control

const CARD_SCENE := preload("res://card_ui.tscn")

@export var bet_amounts: Array[int] = [10, 25, 50]
@export var bet_button_size := Vector2(100, 64)

var bet_buttons: Array[Button] = []

@onready var flow: Node = $BlackjackFlow
@onready var credit_label: Label = $CreditLabel
@onready var bet_label: Label = $BetLabel
@onready var player_score_label: Label = $PlayerScoreLabel
@onready var dealer_score_label: Label = $DealerScoreLabel
@onready var result_label: Label = $ResultLabel
@onready var credit_dialog: ColorRect = $CreditDialog
@onready var deck_pile: Control = $DeckPile
@onready var bet_panel: HBoxContainer = $BetPanel
@onready var deal_button: Button = $BetPanel/DealButton
@onready var decision_panel: HBoxContainer = $DecisionPanel
@onready var result_panel: HBoxContainer = $ResultPanel
@onready var next_button: Button = $ResultPanel/NextButton
@onready var dealer_hand_box: HBoxContainer = $DealerHand
@onready var player_hand_box: HBoxContainer = $PlayerHand
@onready var deck_manager: Node = $DeckManager


func _ready() -> void:
	flow.setup(deck_manager)
	flow.phase_changed.connect(_on_phase_changed)
	flow.credit_changed.connect(_on_credit_changed)
	flow.bet_changed.connect(_on_bet_changed)
	flow.card_dealt.connect(_on_card_dealt)
	flow.dealer_revealed.connect(_on_dealer_revealed)
	flow.hands_cleared.connect(_on_hands_cleared)
	flow.round_resolved.connect(_on_round_resolved)
	_build_bet_buttons()
	credit_label.visible = false
	bet_label.visible = false
	deck_pile.visible = false
	credit_dialog.visible = true
	_on_phase_changed(flow.Phase.CREDIT)


func _build_bet_buttons() -> void:
	bet_buttons.clear()
	for amount in bet_amounts:
		var button := _make_table_button("$%d" % amount, bet_button_size)
		button.pressed.connect(_on_bet_chosen.bind(amount))
		bet_panel.add_child(button)
		bet_panel.move_child(button, deal_button.get_index())
		bet_buttons.append(button)


func _make_table_button(text: String, min_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	for style_name in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(
			style_name,
			deal_button.get_theme_stylebox(style_name)
		)
	button.add_theme_color_override("font_color", deal_button.get_theme_color("font_color"))
	button.add_theme_font_size_override("font_size", deal_button.get_theme_font_size("font_size"))
	return button


func _on_credit_ok_pressed() -> void:
	credit_label.visible = true
	bet_label.visible = true
	deck_pile.visible = true
	credit_dialog.visible = false
	flow.start_session()
	_refresh_bet_buttons()


func _on_bet_chosen(amount: int) -> void:
	flow.choose_bet(amount)
	_refresh_bet_buttons()


func _on_deal_pressed() -> void:
	flow.deal()


func _on_hit_pressed() -> void:
	flow.hit()
	_refresh_scores()


func _on_stand_pressed() -> void:
	flow.stand()
	_refresh_scores()


func _on_next_pressed() -> void:
	flow.next_round()
	_refresh_bet_buttons()


func _on_phase_changed(phase: int) -> void:
	bet_panel.visible = phase == flow.Phase.BETTING
	decision_panel.visible = phase == flow.Phase.PLAYER_TURN
	result_panel.visible = phase == flow.Phase.RESOLVE
	_refresh_scores()


func _on_credit_changed(credit: int) -> void:
	credit_label.text = "Credit: $%d" % credit


func _on_bet_changed(shown_bet: int) -> void:
	bet_label.text = "Bet: $%d" % shown_bet


func _on_card_dealt(is_player: bool, card_data: CardData, face_up: bool) -> void:
	var hand_box := player_hand_box if is_player else dealer_hand_box
	var card := CARD_SCENE.instantiate() as CardUI
	hand_box.add_child(card)
	card.is_face_up = face_up
	card.data = card_data
	_refresh_scores()


func _on_dealer_revealed() -> void:
	for child in dealer_hand_box.get_children():
		var card := child as CardUI
		if card != null:
			card.is_face_up = true
	_refresh_scores()


func _on_hands_cleared() -> void:
	for child in player_hand_box.get_children():
		child.queue_free()
	for child in dealer_hand_box.get_children():
		child.queue_free()
	result_label.text = ""
	_refresh_scores()


func _on_round_resolved(message: String) -> void:
	result_label.text = message
	if flow.credit <= 0:
		result_label.text += " No credit left."
	next_button.disabled = flow.credit <= 0


func _refresh_scores() -> void:
	if flow.player_hand.is_empty():
		player_score_label.text = ""
		dealer_score_label.text = ""
		return
	player_score_label.text = "You: %d" % flow.player_total()
	if flow.dealer_cards_revealed:
		dealer_score_label.text = "Dealer: %d" % flow.dealer_total()
	else:
		dealer_score_label.text = "Dealer: ?"


func _refresh_bet_buttons() -> void:
	for i in bet_buttons.size():
		var amount := bet_amounts[i]
		var button := bet_buttons[i]
		button.disabled = amount > flow.credit
		button.modulate = Color(1.15, 1.1, 0.85, 1) if amount == flow.selected_bet else Color.WHITE
	deal_button.disabled = flow.selected_bet <= 0 or flow.selected_bet > flow.credit
	bet_label.text = "Bet: $%d" % flow.shown_bet()


func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")
