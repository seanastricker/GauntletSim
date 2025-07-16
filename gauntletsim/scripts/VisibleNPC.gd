extends Node2D

@export var npc_name: String = "NPC"
@export var dialogue: String = "Hello, player!"

@onready var name_label = $NameLabel
@onready var dialogue_label = $DialogueLabel
@onready var interaction_prompt = $InteractionPrompt
@onready var area = $Area2D
var player_in_range = false
var dialogue_timer = Timer.new()

func _ready():
    name_label.text = npc_name
    dialogue_label.text = dialogue
    interaction_prompt.visible = false
    dialogue_label.visible = false
    
    # Add outlines
    name_label.add_theme_color_override("font_color", Color(1, 1, 1))
    name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
    name_label.add_theme_constant_override("outline_size", 2)
    
    dialogue_label.add_theme_color_override("font_color", Color(1, 1, 1))
    dialogue_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
    dialogue_label.add_theme_constant_override("outline_size", 2)

    interaction_prompt.add_theme_color_override("font_color", Color(1, 1, 1))
    interaction_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0))
    interaction_prompt.add_theme_constant_override("outline_size", 2)

    area.body_entered.connect(_on_body_entered)
    area.body_exited.connect(_on_body_exited)
    
    dialogue_timer.wait_time = 3.0
    dialogue_timer.one_shot = true
    dialogue_timer.timeout.connect(_on_dialogue_timer_timeout)
    add_child(dialogue_timer)

func _on_body_entered(body):
    if body.is_in_group("player"):
        player_in_range = true
        interaction_prompt.visible = true

func _on_body_exited(body):
    if body.is_in_group("player"):
        player_in_range = false
        interaction_prompt.visible = false
        dialogue_label.visible = false
        dialogue_timer.stop()

func _unhandled_input(_event):
    if player_in_range and Input.is_action_just_pressed("interact"):
        dialogue_label.visible = true
        dialogue_timer.start()

func _on_dialogue_timer_timeout():
    dialogue_label.visible = false 