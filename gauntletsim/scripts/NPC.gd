# NPC.gd
extends Node2D

@export var dialogue: String = "Hello!"

@onready var dialogue_label: Label = $DialogueLabel
@onready var area: Area2D = $Area2D

func _ready():
    area.body_entered.connect(_on_body_entered)
    area.body_exited.connect(_on_body_exited)
    dialogue_label.text = dialogue
    dialogue_label.visible = false

func _on_body_entered(body):
    if body.is_in_group("player"):
        dialogue_label.visible = true

func _on_body_exited(body):
    if body.is_in_group("player"):
        dialogue_label.visible = false 