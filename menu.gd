extends Control

const LOCALES := ["en", "ru"]

@onready var music: AudioStreamPlayer = $%Music
@onready var sfx_click: AudioStreamPlayer = $%SfxClick
@onready var music_group: SoundGroup = $%MusicGroup
@onready var sfx_group: SoundGroup = $%SfxGroup
@onready var settings_dialog: ColorRect = $%SettingsDialog
@onready var music_toggle: CheckButton = $%MusicToggle
@onready var sound_toggle: CheckButton = $%SoundToggle
@onready var language_option: OptionButton = $%LanguageOption


func _ready() -> void:
	music.play()
	language_option.add_item("English")
	language_option.add_item("Русский")
	var current_locale := TranslationServer.get_locale().substr(0, 2)
	var locale_index := LOCALES.find(current_locale)
	language_option.select(maxi(locale_index, 0))
	music_toggle.set_pressed_no_signal(AudioSettings.music_enabled)
	sound_toggle.set_pressed_no_signal(AudioSettings.sound_enabled)
	music_group.set_enabled(AudioSettings.music_enabled)
	sfx_group.set_enabled(AudioSettings.sound_enabled)
	AudioSettings.music_enabled_changed.connect(music_group.set_enabled)
	AudioSettings.sound_enabled_changed.connect(sfx_group.set_enabled)


func _on_start_pressed() -> void:
	sfx_click.play()
	get_tree().change_scene_to_file("res://main_level.tscn")


func _on_exit_pressed() -> void:
	sfx_click.play()
	get_tree().quit()


func _on_settings_pressed() -> void:
	sfx_click.play()
	settings_dialog.visible = true


func _on_settings_close_pressed() -> void:
	sfx_click.play()
	settings_dialog.visible = false


func _on_music_toggled(toggled_on: bool) -> void:
	AudioSettings.set_music_enabled(toggled_on)


func _on_sound_toggled(toggled_on: bool) -> void:
	AudioSettings.set_sound_enabled(toggled_on)


func _on_language_selected(index: int) -> void:
	TranslationServer.set_locale(LOCALES[index])
