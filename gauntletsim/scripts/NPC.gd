# NPC.gd
extends Node2D

@export var dialogue: String = "Hello!"
@export var npc_name: String = "NPC"

@onready var dialogue_label: Label = $DialogueLabel
@onready var name_label: Label = $NameLabel
@onready var interaction_prompt: Label = $InteractionPrompt
@onready var area: Area2D = $Area2D
var dialogue_timer: Timer

func _ready():
    area.body_entered.connect(_on_body_entered)
    area.body_exited.connect(_on_body_exited)
    dialogue_label.text = dialogue
    dialogue_label.visible = false
    name_label.text = npc_name
    interaction_prompt.visible = false
    
    dialogue_timer = Timer.new()
    dialogue_timer.wait_time = 3.0 # Show dialogue for 3 seconds
    dialogue_timer.one_shot = true
    dialogue_timer.timeout.connect(func(): dialogue_label.visible = false)
    add_child(dialogue_timer)

func _on_body_entered(body):
    if body.is_in_group("player"):
        interaction_prompt.visible = true

func _on_body_exited(body):
    if body.is_in_group("player"):
        interaction_prompt.visible = false
        dialogue_label.visible = false # Hide dialogue if player walks away

func _input(event):
    if interaction_prompt.visible and event.is_action_pressed("interact"):
        dialogue_label.visible = true
        dialogue_timer.start() 