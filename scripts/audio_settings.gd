extends Node

## Autoload: single source of truth for music/sound on-off, shared across scenes.

signal music_enabled_changed(enabled: bool)
signal sound_enabled_changed(enabled: bool)

var music_enabled: bool = true
var sound_enabled: bool = true


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	music_enabled_changed.emit(enabled)


func set_sound_enabled(enabled: bool) -> void:
	sound_enabled = enabled
	sound_enabled_changed.emit(enabled)
