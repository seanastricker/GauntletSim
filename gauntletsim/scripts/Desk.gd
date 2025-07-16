# Desk.gd
extends Area2D

@onready var interaction_prompt: Label = $InteractionPrompt

func _ready():
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body):
    if body.is_in_group("player"):
        interaction_prompt.visible = true

func _on_body_exited(body):
    if body.is_in_group("player"):
        interaction_prompt.visible = false

func _input(event):
    if interaction_prompt.visible and event.is_action_pressed("interact"):
        var bodies = get_overlapping_bodies()
        for body in bodies:
            if body.is_in_group("player") and body.has_method("work_at_desk"):
                body.work_at_desk()
                print("Player is working.")
                # Hide prompt after interaction to avoid spamming
                interaction_prompt.visible = false
                # A timer could be used to show it again after cooldown 