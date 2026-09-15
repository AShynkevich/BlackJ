extends Control

@onready var music: AudioStreamPlayer = $%Music
@onready var sfx_click: AudioStreamPlayer = $%SfxClick


func _ready() -> void:
	music.play()
	pass


func _on_start_pressed() -> void:
	sfx_click.play()
	get_tree().change_scene_to_file("res://main_level.tscn")


func _on_exit_pressed() -> void:
	sfx_click.play()
	get_tree().quit()
