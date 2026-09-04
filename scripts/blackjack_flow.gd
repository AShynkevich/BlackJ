extends Node

## Classic session: credit, bet, deal, player turn, dealer, payout.
## Does not spawn CardUI or read the table scene.

enum Phase { CREDIT, BETTING, PLAYER_TURN, DEALER_TURN, RESOLVE }

const STARTING_CREDIT := 100

signal phase_changed(phase: Phase)
signal credit_changed(credit: int)
signal bet_changed(shown_bet: int)
signal card_dealt(is_player: bool, card: CardData, face_up: bool)
signal dealer_revealed
signal hands_cleared
signal round_resolved(message: String)

@export var opening_cards_each: int = 2
@export var hide_dealer_last_card: bool = true

var phase: Phase = Phase.CREDIT
var credit: int = 0
var selected_bet: int = 0
var locked_bet: int = 0
var player_hand: Array[CardData] = []
var dealer_hand: Array[CardData] = []
var dealer_cards_revealed: bool = false

var _deck: Node


func setup(deck_manager: Node) -> void:
	_deck = deck_manager


func start_session() -> void:
	credit = STARTING_CREDIT
	selected_bet = 0
	locked_bet = 0
	_emit_money()
	_set_phase(Phase.BETTING)


func choose_bet(amount: int) -> void:
	if phase != Phase.BETTING or amount > credit:
		return
	selected_bet = amount
	_emit_bet()


func deal() -> void:
	if phase != Phase.BETTING or selected_bet <= 0 or selected_bet > credit:
		return
	locked_bet = selected_bet
	credit -= locked_bet
	selected_bet = 0
	_emit_money()
	_ensure_deck_has_cards()
	_deal_opening_hands()
	_after_opening_deal()


func hit() -> void:
	if phase != Phase.PLAYER_TURN:
		return
	_deal_to(player_hand, true, true)
	if BlackjackRules.is_bust(player_hand):
		_reveal_dealer()
		_finish_round(0, "Bust. You lose.")


func stand() -> void:
	if phase != Phase.PLAYER_TURN:
		return
	_play_dealer()


func next_round() -> void:
	if phase != Phase.RESOLVE or credit <= 0:
		return
	_clear_hands()
	locked_bet = 0
	selected_bet = 0
	_emit_bet()
	_set_phase(Phase.BETTING)


func shown_bet() -> int:
	return locked_bet if locked_bet > 0 else selected_bet


func player_total() -> int:
	return BlackjackRules.hand_total(player_hand)


func dealer_total() -> int:
	return BlackjackRules.hand_total(dealer_hand)


func _set_phase(next: Phase) -> void:
	phase = next
	phase_changed.emit(phase)


func _emit_money() -> void:
	credit_changed.emit(credit)
	_emit_bet()


func _emit_bet() -> void:
	bet_changed.emit(shown_bet())


func _ensure_deck_has_cards() -> void:
	var needed := opening_cards_each * 2 + 12
	if _deck.deck.size() >= needed:
		return
	_deck.generate_deck()
	_deck.shuffle_deck()


func _deal_opening_hands() -> void:
	# One card to the player, then one to the dealer, each pass.
	# The dealer's last card is the hole card when hide_dealer_last_card is set.
	for i in opening_cards_each:
		_deal_to(player_hand, true, true)
		var dealer_face_up := not hide_dealer_last_card or i < opening_cards_each - 1
		_deal_to(dealer_hand, false, dealer_face_up)


func _deal_to(hand: Array[CardData], is_player: bool, face_up: bool) -> void:
	var card_data: CardData = _deck.draw_card()
	if card_data == null:
		return
	hand.append(card_data)
	card_dealt.emit(is_player, card_data, face_up)


func _after_opening_deal() -> void:
	var player_natural := BlackjackRules.is_natural(player_hand)
	var dealer_natural := BlackjackRules.is_natural(dealer_hand)
	if player_natural or dealer_natural:
		_reveal_dealer()
		if player_natural and dealer_natural:
			_finish_round(locked_bet, "Push. Both have Blackjack.")
		elif player_natural:
			_finish_round(locked_bet * 2, "Blackjack. You win $%d." % locked_bet)
		else:
			_finish_round(0, "Dealer has Blackjack.")
		return
	_set_phase(Phase.PLAYER_TURN)


func _play_dealer() -> void:
	_set_phase(Phase.DEALER_TURN)
	_reveal_dealer()
	while BlackjackRules.should_dealer_hit(dealer_hand):
		_deal_to(dealer_hand, false, true)
	_resolve_hands()


func _reveal_dealer() -> void:
	if dealer_cards_revealed:
		return
	dealer_cards_revealed = true
	dealer_revealed.emit()


func _resolve_hands() -> void:
	var player := player_total()
	var dealer := dealer_total()
	if BlackjackRules.is_bust(dealer_hand):
		_finish_round(locked_bet * 2, "Dealer busts. You win $%d." % locked_bet)
	elif player > dealer:
		_finish_round(locked_bet * 2, "You win $%d." % locked_bet)
	elif dealer > player:
		_finish_round(0, "Dealer wins.")
	else:
		_finish_round(locked_bet, "Push.")


func _finish_round(payout: int, message: String) -> void:
	credit += payout
	credit_changed.emit(credit)
	round_resolved.emit(message)
	_set_phase(Phase.RESOLVE)


func _clear_hands() -> void:
	player_hand.clear()
	dealer_hand.clear()
	dealer_cards_revealed = false
	hands_cleared.emit()
