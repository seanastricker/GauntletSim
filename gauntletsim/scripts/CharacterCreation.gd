# CharacterCreation.gd
extends Control

@onready var name_edit: LineEdit = $CenterContainer/VBoxContainer/NameEdit
@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var texture_rect: TextureRect = $CenterContainer/VBoxContainer/HBoxContainer/TextureRect
@onready var previous_button: Button = $CenterContainer/VBoxContainer/HBoxContainer/PreviousButton
@onready var next_button: Button = $CenterContainer/VBoxContainer/HBoxContainer/NextButton

var character_sprites = [
	"res://assets/characters/sean_spritesheet.png",
	"res://assets/characters/matt.png",
	"res://assets/characters/radin.png",
	"res://assets/characters/Character_Generator/0_Premade_Characters/16x16/Premade_Character_01.png",
	"res://assets/characters/Character_Generator/0_Premade_Characters/16x16/Premade_Character_02.png",
	"res://assets/characters/Character_Generator/0_Premade_Characters/16x16/Premade_Character_03.png",
	"res://assets/characters/Character_Generator/0_Premade_Characters/16x16/Premade_Character_04.png",
	"res://assets/characters/Character_Generator/0_Premade_Characters/16x16/Premade_Character_05.png"
]
var current_sprite_index = 0

func _ready():
	start_button.pressed.connect(_on_start_button_pressed)
	previous_button.pressed.connect(_on_previous_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	name_edit.grab_focus()
	
	name_edit.add_theme_font_size_override("font_size", 48)
	start_button.add_theme_font_size_override("font_size", 48)
	
	update_character_sprite()

func _on_start_button_pressed():
	var player_name = name_edit.text
	if player_name.is_empty():
		player_name = "Player"
	
	PlayerData.player_name = player_name
	PlayerData.player_sprite_path = character_sprites[current_sprite_index]
	
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func _on_previous_button_pressed():
	current_sprite_index = (current_sprite_index - 1 + character_sprites.size()) % character_sprites.size()
	update_character_sprite()

func _on_next_button_pressed():
	current_sprite_index = (current_sprite_index + 1) % character_sprites.size()
	update_character_sprite()

func update_character_sprite():
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = load(character_sprites[current_sprite_index])
	atlas_texture.region = Rect2(48, 0, 16, 32)
	texture_rect.texture = atlas_texture