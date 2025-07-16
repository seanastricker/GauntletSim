# CharacterCreation.gd
extends Control

@onready var name_edit: LineEdit = $VBoxContainer/NameEdit
@onready var start_button: Button = $VBoxContainer/StartButton

func _ready():
    start_button.pressed.connect(_on_start_button_pressed)
    name_edit.grab_focus()

func _on_start_button_pressed():
    var player_name = name_edit.text
    if player_name.strip_edges().is_empty():
        # Maybe show an error label
        print("Name cannot be empty")
        return

    PlayerData.player_name = player_name
    
    get_tree().change_scene_to_file("res://scenes/Main.tscn") 