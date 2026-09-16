class_name SoundGroup
extends Node

## Composite: turns every AudioStreamPlayer leaf (and nested SoundGroup) on/off as one unit.
## Sfx groups mute via volume (cheap one-shots, instant re-enable at the same volume).
## Music groups (stop_when_disabled) actually stop, so muted music burns no CPU.

const MUTED_VOLUME_DB := -80.0

@export var stop_when_disabled: bool = false

var enabled: bool = true

var _base_volume_db: Dictionary = {}
var _was_playing: Dictionary = {}


func set_enabled(is_enabled: bool) -> void:
	enabled = is_enabled
	for child in get_children():
		if child is SoundGroup:
			child.set_enabled(is_enabled)
		elif child is AudioStreamPlayer:
			if stop_when_disabled:
				_apply_stop(child, is_enabled)
			else:
				_apply_mute(child, is_enabled)


func _apply_mute(player: AudioStreamPlayer, is_enabled: bool) -> void:
	if is_enabled:
		player.volume_db = _base_volume_db.get(player, player.volume_db)
	else:
		_base_volume_db[player] = _base_volume_db.get(player, player.volume_db)
		player.volume_db = MUTED_VOLUME_DB


func _apply_stop(player: AudioStreamPlayer, is_enabled: bool) -> void:
	if is_enabled:
		if _was_playing.get(player, false):
			player.play()
	else:
		_was_playing[player] = player.playing
		player.stop()
