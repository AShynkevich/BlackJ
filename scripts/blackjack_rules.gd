class_name BlackjackRules
extends Object

## Soft Ace: count 11, then drop to 1 while the hand is bust.
static func hand_total(cards: Array[CardData]) -> int:
	var total := 0
	var aces := 0
	for card in cards:
		total += card.value
		if card.value == 11:
			aces += 1
	while total > 21 and aces > 0:
		total -= 10
		aces -= 1
	return total


static func is_bust(cards: Array[CardData]) -> bool:
	return hand_total(cards) > 21


## Natural is Ace + 10-value on the first two cards only.
static func is_natural(cards: Array[CardData]) -> bool:
	return cards.size() == 2 and hand_total(cards) == 21


## House rule: hit below 17, stand on 17+ (including soft 17).
static func should_dealer_hit(dealer_cards: Array[CardData]) -> bool:
	return hand_total(dealer_cards) < 17
