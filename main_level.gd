extends Control

const STARTING_CREDIT := 100

var credit: int = 0

@onready var credit_label: Label = $CreditLabel
@onready var credit_dialog: ColorRect = $CreditDialog
@onready var deck_pile: Control = $DeckPile


func _ready() -> void:
	credit = 0
	credit_label.visible = false
	deck_pile.visible = false
	credit_dialog.visible = true


func _on_credit_ok_pressed() -> void:
	credit = STARTING_CREDIT
	_refresh_credit_label()
	credit_label.visible = true
	deck_pile.visible = true
	credit_dialog.visible = false


func _refresh_credit_label() -> void:
	credit_label.text = "Credit: $%d" % credit


func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")
