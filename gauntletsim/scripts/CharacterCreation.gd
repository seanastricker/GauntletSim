# CharacterCreation.gd
extends Control

@onready var name_edit: LineEdit = $CenterContainer/VBoxContainer/NameEdit
@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var label: Label = $CenterContainer/VBoxContainer/Label

func _ready():
	start_button.pressed.connect(_on_start_button_pressed)
	name_edit.grab_focus()
	
	label.add_theme_font_size_override("font_size", 48)
	name_edit.add_theme_font_size_override("font_size", 48)
	start_button.add_theme_font_size_override("font_size", 48)

func _on_start_button_pressed():
	var player_name = name_edit.text
	if player_name.strip_edges().is_empty():
		# Maybe show an error label
		print("Name cannot be empty")
		return

	PlayerData.player_name = player_name
	
	get_tree().change_scene_to_file("res://scenes/Main.tscn")