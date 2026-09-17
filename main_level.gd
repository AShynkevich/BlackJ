extends Control

const CARD_SCENE := preload("res://card_ui.tscn")

## Outcome -> localization key for the result label.
const RESULT_KEYS := {
	BlackjackFlow.Outcome.PLAYER_BLACKJACK: "RESULT_BLACKJACK_WIN",
	BlackjackFlow.Outcome.DEALER_BLACKJACK: "RESULT_DEALER_BLACKJACK",
	BlackjackFlow.Outcome.PUSH_BLACKJACK: "RESULT_PUSH_BLACKJACK",
	BlackjackFlow.Outcome.BUST: "RESULT_BUST",
	BlackjackFlow.Outcome.DEALER_BUST: "RESULT_DEALER_BUST",
	BlackjackFlow.Outcome.PLAYER_WINS: "RESULT_PLAYER_WINS",
	BlackjackFlow.Outcome.DEALER_WINS: "RESULT_DEALER_WINS",
	BlackjackFlow.Outcome.PUSH: "RESULT_PUSH",
}
const WIN_OUTCOMES := [BlackjackFlow.Outcome.PLAYER_BLACKJACK, BlackjackFlow.Outcome.DEALER_BUST, BlackjackFlow.Outcome.PLAYER_WINS]
const PUSH_OUTCOMES := [BlackjackFlow.Outcome.PUSH_BLACKJACK, BlackjackFlow.Outcome.PUSH]

@export var bet_amounts: Array[int] = [10, 25, 50]
@export var bet_button_size := Vector2(100, 64)

var bet_buttons: Array[Button] = []
var _playing_anims: bool = false
var _anim_queue: Array[Dictionary] = []
var _has_pending_result: bool = false
var _pending_outcome: BlackjackFlow.Outcome
var _pending_amount: int = 0
var _flight_layer: Control

@onready var flow: Node = $BlackjackFlow
@onready var credit_label: Label = $%CreditLabel
@onready var bet_label: Label = $%BetLabel
@onready var player_score_label: Label = $%PlayerScoreLabel
@onready var dealer_score_label: Label = $%DealerScoreLabel
@onready var result_label: Label = $%ResultLabel
@onready var credit_dialog: ColorRect = $%CreditDialog
@onready var session_message: Label = $%Message
@onready var confirm_leave_dialog: ColorRect = $%ConfirmLeaveDialog
@onready var confirm_leave_message: Label = $%ConfirmMessage
@onready var deck_pile: Control = $%DeckPile
@onready var bet_panel: HBoxContainer = $%BetPanel
@onready var deal_button: Button = $%DealButton
@onready var decision_panel: HBoxContainer = $%DecisionPanel
@onready var result_panel: HBoxContainer = $%ResultPanel
@onready var dealer_hand_box: HBoxContainer = $%DealerHand
@onready var player_hand_box: HBoxContainer = $%PlayerHand
@onready var deck_manager: Node = $DeckManager
@onready var music: AudioStreamPlayer = $%Music
@onready var sfx_click: AudioStreamPlayer = $%SfxClick
@onready var sfx_bet: AudioStreamPlayer = $%SfxBet
@onready var sfx_deal: AudioStreamPlayer = $%SfxDeal
@onready var sfx_flip: AudioStreamPlayer = $%SfxFlip
@onready var sfx_win: AudioStreamPlayer = $%SfxWin
@onready var sfx_lose: AudioStreamPlayer = $%SfxLose
@onready var sfx_push: AudioStreamPlayer = $%SfxPush
@onready var music_group: SoundGroup = $%MusicGroup
@onready var sfx_group: SoundGroup = $%SfxGroup


func _ready() -> void:
	flow.setup(deck_manager)
	flow.phase_changed.connect(_on_phase_changed)
	flow.credit_changed.connect(_on_credit_changed)
	flow.bet_changed.connect(_on_bet_changed)
	flow.card_dealt.connect(_on_card_dealt)
	flow.dealer_revealed.connect(_on_dealer_revealed)
	flow.hands_cleared.connect(_on_hands_cleared)
	flow.round_resolved.connect(_on_round_resolved)
	_flight_layer = Control.new()
	_flight_layer.name = "FlightLayer"
	_flight_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flight_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_flight_layer)
	move_child(_flight_layer, credit_dialog.get_index())
	_build_bet_buttons()
	credit_label.visible = false
	bet_label.visible = false
	deck_pile.visible = false
	session_message.text = tr("CREDIT_MESSAGE")
	credit_dialog.visible = true
	_on_phase_changed(flow.Phase.CREDIT)
	music.play()
	music_group.set_enabled(AudioSettings.music_enabled)
	sfx_group.set_enabled(AudioSettings.sound_enabled)


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
	if flow.phase != flow.Phase.CREDIT:
		_go_to_main_menu()
		return
	sfx_click.play()
	credit_label.visible = true
	bet_label.visible = true
	deck_pile.visible = true
	credit_dialog.visible = false
	flow.start_session()
	_refresh_bet_buttons()


func _on_bet_chosen(amount: int) -> void:
	sfx_bet.play()
	flow.choose_bet(amount)
	_refresh_bet_buttons()


func _on_deal_pressed() -> void:
	if _playing_anims:
		return
	sfx_click.play()
	flow.deal()


func _on_hit_pressed() -> void:
	if _playing_anims:
		return
	sfx_click.play()
	flow.hit()


func _on_stand_pressed() -> void:
	if _playing_anims:
		return
	sfx_click.play()
	flow.stand()


func _on_next_pressed() -> void:
	if _playing_anims:
		return
	sfx_click.play()
	flow.next_round()
	_refresh_bet_buttons()


func _on_phase_changed(_phase: int) -> void:
	if _playing_anims:
		_hide_action_panels()
		return
	_apply_phase_panels()


func _on_credit_changed(credit: int) -> void:
	credit_label.text = tr("CREDIT_LABEL") % credit


func _on_bet_changed(shown_bet: int) -> void:
	bet_label.text = tr("BET_LABEL") % shown_bet


func _on_card_dealt(is_player: bool, card_data: CardData, face_up: bool) -> void:
	var hand_box := player_hand_box if is_player else dealer_hand_box
	var card := CARD_SCENE.instantiate() as CardUI
	card.is_face_up = false
	card.reveal_when_dealt = face_up
	card.data = card_data
	card.modulate.a = 0.0
	_flight_layer.add_child(card)
	_anim_queue.append({&"kind": &"deal", &"card": card, &"hand": hand_box})
	_kick_anims()


func _on_dealer_revealed() -> void:
	_anim_queue.append({&"kind": &"flip"})
	_kick_anims()


func _on_hands_cleared() -> void:
	_anim_queue.clear()
	_has_pending_result = false
	for child in player_hand_box.get_children():
		child.queue_free()
	for child in dealer_hand_box.get_children():
		child.queue_free()
	for child in _flight_layer.get_children():
		child.queue_free()
	result_label.text = ""
	_refresh_scores()


func _on_round_resolved(outcome: BlackjackFlow.Outcome, amount: int) -> void:
	_has_pending_result = true
	_pending_outcome = outcome
	_pending_amount = amount
	if not _playing_anims:
		_apply_pending_result()


func _kick_anims() -> void:
	if _playing_anims:
		return
	_play_anim_queue()


func _play_anim_queue() -> void:
	_playing_anims = true
	_hide_action_panels()
	while not _anim_queue.is_empty():
		var job: Dictionary = _anim_queue.pop_front()
		if job.kind == &"deal":
			var card: CardUI = job.card
			var hand_box: HBoxContainer = job.hand
			if is_instance_valid(card) and is_instance_valid(hand_box):
				await _fly_card_into_hand(card, hand_box)
			if _anim_queue.is_empty() or _anim_queue[0].kind != &"deal":
				await _reveal_pending_faces()
				_refresh_scores()
		elif job.kind == &"flip":
			await _flip_hole_cards()
			_refresh_scores()
	_playing_anims = false
	_apply_phase_panels()
	_apply_pending_result()


func _fly_card_into_hand(card: CardUI, hand_box: HBoxContainer) -> void:
	var slot := Control.new()
	slot.custom_minimum_size = CardUI.CARD_SIZE
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand_box.add_child(slot)
	await get_tree().process_frame
	if not is_instance_valid(card) or not is_instance_valid(slot):
		return
	
	sfx_deal.play()
	await card.animate_deal_from(deck_pile.global_position, slot.global_position)
	if not is_instance_valid(card) or not is_instance_valid(slot):
		return
	var idx := slot.get_index()
	hand_box.remove_child(slot)
	slot.free()
	if card.get_parent() != null:
		card.get_parent().remove_child(card)
	hand_box.add_child(card)
	hand_box.move_child(card, idx)


func _reveal_pending_faces() -> void:
	var pending: Array[CardUI] = []
	for hand_box in [player_hand_box, dealer_hand_box]:
		for child in hand_box.get_children():
			var card := child as CardUI
			if card != null and card.reveal_when_dealt and not card.is_face_up:
				pending.append(card)
	if pending.is_empty():
		return
	sfx_flip.play()
	for i in pending.size():
		if i == pending.size() - 1:
			await pending[i].animate_flip_up()
		else:
			pending[i].animate_flip_up()


func _flip_hole_cards() -> void:
	# sfx_flip.play()
	for child in dealer_hand_box.get_children():
		var card := child as CardUI
		if card == null or card.is_face_up:
			continue
		await card.animate_flip_up()


func _hide_action_panels() -> void:
	bet_panel.visible = false
	decision_panel.visible = false
	result_panel.visible = false


func _apply_phase_panels() -> void:
	var phase: int = flow.phase
	bet_panel.visible = phase == flow.Phase.BETTING
	decision_panel.visible = phase == flow.Phase.PLAYER_TURN
	result_panel.visible = phase == flow.Phase.RESOLVE and flow.credit > 0
	_refresh_scores()


func _apply_pending_result() -> void:
	if not _has_pending_result:
		return
	_has_pending_result = false
	var template := tr(RESULT_KEYS[_pending_outcome])
	result_label.text = template % _pending_amount if "%d" in template else template
	if _pending_outcome in WIN_OUTCOMES:
		sfx_win.play()
	elif _pending_outcome in PUSH_OUTCOMES:
		sfx_push.play()
	else:
		sfx_lose.play()
	
	if flow.credit > 0:
		return
	session_message.text = tr("LOSE_MESSAGE")
	credit_dialog.visible = true


func _refresh_scores() -> void:
	if flow.player_hand.is_empty():
		player_score_label.text = ""
		dealer_score_label.text = ""
		return
	player_score_label.text = tr("PLAYER_SCORE") % flow.player_total()
	if flow.dealer_cards_revealed:
		dealer_score_label.text = tr("DEALER_SCORE") % flow.dealer_total()
	else:
		dealer_score_label.text = tr("DEALER_SCORE_HIDDEN")


func _refresh_bet_buttons() -> void:
	for i in bet_buttons.size():
		var amount := bet_amounts[i]
		var button := bet_buttons[i]
		button.disabled = amount > flow.credit
		button.modulate = Color(1.15, 1.1, 0.85, 1) if amount == flow.selected_bet else Color.WHITE
	deal_button.disabled = flow.selected_bet <= 0 or flow.selected_bet > flow.credit
	bet_label.text = tr("BET_LABEL") % flow.shown_bet()


func _on_main_menu_pressed() -> void:
	sfx_click.play()
	confirm_leave_message.text = tr("LEAVE_TABLE_MESSAGE")
	confirm_leave_dialog.visible = true


func _on_confirm_leave_yes_pressed() -> void:
	sfx_click.play()
	_go_to_main_menu()


func _on_confirm_leave_cancel_pressed() -> void:
	sfx_click.play()
	confirm_leave_dialog.visible = false


func _go_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")
